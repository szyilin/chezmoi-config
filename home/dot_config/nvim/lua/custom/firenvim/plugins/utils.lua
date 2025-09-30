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
  -- 同 easymotion
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    -- stylua: ignore
    keys = {
      { "<C-;>", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
    },
  },
  -- 切换中英文
  {
    "keaising/im-select.nvim",
    opts = {
      defaualt_im_select = "com.apple.keylayout.ABC",
      default_command = "im-select",
    },
  }
}
