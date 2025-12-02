local M = {}
-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- 使用模块函数加载，防止 require 缓存机制，导致运行顺序错误
function M.setup()
  -- 使用系统剪贴板
  vim.opt.clipboard = vim.env.SSH_TTY and "" or "unnamedplus"
  -- 关闭自动格式化
  vim.g.autoformat = false
  -- 自动保存
  vim.o.autowriteall = true
  -- 显示相对行号
  vim.opt.relativenumber = true
  -- 边输入边搜索
  vim.opt.incsearch = true
  -- 搜索大小写不敏感，除非包含大写
  vim.opt.ignorecase = true
  vim.opt.smartcase = true
end

return M
