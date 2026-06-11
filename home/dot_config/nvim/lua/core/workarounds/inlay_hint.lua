--[[
  UPSTREAM-WORKAROUND — Neovim inlay hint "Invalid 'col': out of range"

  Issues:
    https://github.com/neovim/neovim/issues/36318  (multi LSP client)
    https://github.com/neovim/neovim/issues/39772  (stale col, no bounds check)

  Remove: delete lua/core/workarounds/ and the require line in init.lua when fixed
  in your Neovim stable build. See workarounds/README.md for verification steps.

  A) patch_extmark — keep after upstream fix (harmless no-op); optional to remove with folder
  B) refresh on edit — remove after upstream fix (extra LSP traffic)
]]

local M = {}

local augroup = "workaround_inlay_hint"
local extmark_patched = false

--- A) Skip inline virt_text when col is past line end (prevents decoration provider crash).
function M.patch_extmark()
  if extmark_patched then
    return
  end
  extmark_patched = true

  local api = vim.api
  local set_extmark = api.nvim_buf_set_extmark
  api.nvim_buf_set_extmark = function(bufnr, ns_id, row, col, opts)
    if type(col) == "number" and opts and opts.virt_text_pos == "inline" then
      local line = api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
      if col > #line then
        return
      end
    end
    return set_extmark(bufnr, ns_id, row, col, opts)
  end
end

local refresh_timers = {} ---@type table<integer, integer>

--- B) Debounced refresh after edits (shrinks stale-hint race; remove when upstream fixes sync).
function M.setup_refresh_autocmd()
  if not vim.lsp.inlay_hint then
    return
  end

  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = vim.api.nvim_create_augroup(augroup, { clear = true }),
    callback = function(args)
      local buf = args.buf
      local timer = refresh_timers[buf]
      if timer then
        vim.fn.timer_stop(timer)
      end
      refresh_timers[buf] = vim.fn.timer_start(150, function()
        refresh_timers[buf] = nil
        if not vim.api.nvim_buf_is_valid(buf) then
          return
        end
        if not vim.lsp.inlay_hint.is_enabled({ bufnr = buf }) then
          return
        end
        vim.lsp.inlay_hint.enable(false, { bufnr = buf })
        vim.lsp.inlay_hint.enable(true, { bufnr = buf })
      end)
    end,
  })
end

function M.setup()
  M.patch_extmark()
  M.setup_refresh_autocmd()
end

return M
