local M = {}

function M.setup()
  -- 相对行号，此配置需要在 settings.json 声明
  vim.o.relativenumber = true
  -- 距离屏幕相对行号，settings.json 中添加配置
  vim.o.scrolloff = 6
end

return M
