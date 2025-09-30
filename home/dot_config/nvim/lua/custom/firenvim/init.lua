--[[
浏览器还需要安装一个插件，这部分浏览 firenvim 可以找到
]]
-- 定义 <leader> 按键，需要在 lazy 之前加载
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("utils").initLazy()

require("lazy").setup({
  spec = {
    { import = "custom.firenvim.plugins" },
  },
  defaults = {
    -- By default, only LazyVim plugins will be lazy-loaded. Your custom plugins will load during startup.
    -- If you know what you're doing, you can set this to `true` to have all your custom plugins lazy-loaded by default.
    lazy = false,
    -- It's recommended to leave version=false for now, since a lot the plugin that support versioning,
    -- have outdated releases, which may break your Neovim install.
    version = false, -- always use the latest git commit
    -- version = "*", -- try installing the latest stable version for plugins that support semver
  },
  checker = {
    enabled = true, -- check for plugin updates periodically
    notify = false, -- notify on update
  }, -- automatically check for plugin updates
})

-- 加载配置
require("custom.firenvim.options")
require("custom.firenvim.keymaps")
