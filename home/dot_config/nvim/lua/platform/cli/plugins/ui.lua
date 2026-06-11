--[[
  UI 相关插件配置
]]
return {
  -- lazy.nvim snacks.nvim 配置(这是一个众多插件的集合)
  {
    "folke/snacks.nvim",
    opts = require("platform.cli.configs.ui").snacks,
    -- 必须 extend 合并后的 keys，勿只返回 false 项（会覆盖 LazyVim 默认键，如 <leader>n）
    keys = function(_, keys)
      local km = require("platform.cli.keymaps")
      return vim.list_extend(
        keys,
        vim.list_extend(vim.deepcopy(km.disable_lazyvim_keys), km.disable_cwd_keys)
      )
    end,
  },
  {
    "akinsho/bufferline.nvim",
    keys = require("platform.cli.keymaps").plugins_bufferline,
  }
}