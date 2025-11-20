return {
  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    opts = require "profiles.desktop.configs.conform",
  },

  {
    "neovim/nvim-lspconfig",
    config = function()
      require "profiles.desktop.configs.lspconfig"
    end,
  },

  -- 特殊标签高亮
  {
    "folke/todo-comments.nvim",
    lazy = false,
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = require("profiles.desktop.configs.other").todo_comments,
  },

  -- nvim-tree 配置
  {
    "nvim-tree/nvim-tree.lua",
    opts = require("profiles.desktop.configs.other").nvim_tree,
  },
}
