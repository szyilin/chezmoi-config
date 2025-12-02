--[[
  UI 相关插件配置
]]
return {
  -- lazy.nvim snacks.nvim 配置(这是一个众多插件的集合)
  {
    "folke/snacks.nvim",
    opts = require("platform.cli.configs.ui").snacks,
  },
  {
    "akinsho/bufferline.nvim",
    keys = require("platform.cli.keymaps").plugins_bufferline,
  }
}