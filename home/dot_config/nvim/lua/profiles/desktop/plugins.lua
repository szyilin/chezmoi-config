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
}
