return {
    -- 浏览器使用 neovim
  {
    'glacambre/firenvim',
    build = ":call firenvim#install(0)",
    config = function()
      vim.g.firenvim_config = {
        globalSettings = { alt = "all" },
        localSettings = {
          [".*"] = {
            -- 不自动接管输入框使用 <cmd-e> 启动
            takeover = "never",
            priority = 0,
          },
        },
      }
    end,
  },
  -- 自动切换中英文
  {
    "keaising/im-select.nvim",
    opts = {
      defaualt_im_select = "com.apple.keylayout.ABC",
      default_command = "im-select",
    }
  }
}
