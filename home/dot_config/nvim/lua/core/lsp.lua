--[[
  LSP 通用操作（语言无关，由 LSP server 能力决定）
]]
local M = {}

--- 优化导包：source.organizeImports
--- Java / Go / TS 等 LSP 支持时均可使用
function M.organize_imports()
  local ok, lsp = pcall(require, "lazyvim.util.lsp")
  if ok then
    lsp.action["source.organizeImports"]()
    return
  end

  vim.lsp.buf.code_action({
    apply = true,
    context = {
      only = { "source.organizeImports" },
      diagnostics = {},
    },
  })
end

return M
