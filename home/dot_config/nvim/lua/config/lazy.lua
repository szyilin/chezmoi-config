local utils = require("utils")

local platform = vim.g.lazyvim_platform or require("platform").detect()
vim.g.lazyvim_platform = platform

local ok, lazy_config = pcall(require, string.format("platform.%s.configs.lazy", platform))
if not ok or type(lazy_config) ~= "table" then
  vim.notify(
    string.format("[config.lazy] failed to load platform.%s.configs.lazy: %s", platform, lazy_config),
    vim.log.levels.ERROR
  )
  return
end

utils.setupLazy(lazy_config)

-- CLI 由 LazyVim 自动 require config.options/keymaps/autocmds
-- vscode / firenvim 不加载 LazyVim，需在此显式加载
if platform ~= "cli" then
  require("config.options")
  require("config.keymaps")
  require("config.autocmds")
end
