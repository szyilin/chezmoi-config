-- bootstrap lazy.nvim, LazyVim and your plugins
if vim.g.vscode then
  -- VSCode 内的 Neovim 插件配置
  require("custom.vscode")
elseif vim.g.started_by_firenvim == true then
  -- require("custom.firenvim")
  -- TODO: 临时使用 Neovim 配置
  require("config.lazy")
else
  -- 设置 neovim 中的 node 版本
  require("utils").setNodeVersion()
  -- 普通 Neovim 配置
  require("config.lazy")
  -- vim.notify("Hello Neovim")
end
