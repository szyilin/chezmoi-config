local M = {}
-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- 使用模块函数加载，防止 require 缓存机制，导致运行顺序错误
function M.setup()
  -- 取消换行自动添加注释
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "*",
    callback = function()
      vim.opt.formatoptions:remove({ "r", "o" })
    end,
  })
end

return M
