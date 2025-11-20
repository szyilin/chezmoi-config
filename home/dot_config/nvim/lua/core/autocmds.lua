-- Core autocmds (universal, not NvChad-specific)
-- Add shared autocmds that work across all profiles

-- Example:
-- vim.api.nvim_create_autocmd("BufWritePre", {
--   pattern = "*",
--   callback = function()
--     -- universal save hook
--   end,
-- })

-- 取消换行自动添加注释
vim.api.nvim_create_autocmd("FileType", {
  pattern = "*",
  callback = function()
    vim.opt.formatoptions:remove({ "r", "o" })
  end,
})


