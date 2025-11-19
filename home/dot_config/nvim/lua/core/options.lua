-- Core options (universal, not NvChad-specific)
-- Add shared options that work across all profiles (desktop, vscode, firenvim, etc.)

-- 关闭自动格式化
vim.g.autoformat = false
-- 取消换行自动添加注释
vim.api.nvim_create_autocmd("FileType", {
  pattern = "*",
  callback = function()
    vim.opt.formatoptions:remove({ "r", "o" })
  end,
})
