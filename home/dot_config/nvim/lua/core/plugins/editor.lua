return {
  -- flash.nvim 跳转（键位见 core/keymaps.lua）
  {
    "folke/flash.nvim",
    opts = {},
    keys = require("core.keymaps").flash_keys,
  },

}

