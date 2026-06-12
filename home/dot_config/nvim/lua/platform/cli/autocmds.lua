local M = {}

function M.setup()
  -- jdtls 格式化时 LSP tabSize 来自 buffer 的 tabstop/shiftwidth（见 eclipse.jdt.ls #2942）
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("platform_cli_java", { clear = true }),
    pattern = "java",
    callback = function()
      vim.opt_local.expandtab = true
      vim.opt_local.tabstop = 4
      vim.opt_local.shiftwidth = 4
      vim.opt_local.softtabstop = 4
    end,
  })
end

return M
