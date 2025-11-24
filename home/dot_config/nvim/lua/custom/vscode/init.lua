--[[
NOTE: vscode 高度可定制，配置都保存在 json 文件中，这里也定期备份
vscode 中的两个配置文件他们放在当前文件夹下：
'./settins.json','./keybindings.json' 文件中
]]
-- 定义 <leader> 按键，需要在 lazy 之前加载
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- require("vscode").notify("Hello VSCode Neovim!")
require("utils").initLazy()

require("lazy").setup({
  spec = {
    { import = "custom.vscode.plugins" },
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
require("custom.vscode.options")
require("custom.vscode.keymaps")
