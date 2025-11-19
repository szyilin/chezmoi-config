local M = {}

local function setup_lazy()
  local lazy_config = require "configs.lazy"

  local spec = {
    {
      "NvChad/NvChad",
      lazy = false,
      branch = "v2.5",
      import = "nvchad.plugins",
    },
    { import = "plugins" },
    { import = "profiles.desktop.plugins" },
  }

  require("lazy").setup(spec, lazy_config)
end

function M.setup()
  setup_lazy()

  -- Load NvChad UI (theme, statusline, etc.)
  local function safe_dofile(path)
    if vim.fn.filereadable(path) == 1 then
      dofile(path)
    end
  end
  local cache = vim.g.base46_cache
  if cache then
    safe_dofile(cache .. "defaults")
    safe_dofile(cache .. "statusline")
  end

  -- Load core (universal) configurations
  require "core.options"
  require "core.autocmds"
  require "core.mappings"

  -- Load NvChad-specific configurations
  require "nvchad.options"
  require "nvchad.autocmds"
  require "nvchad.mappings"

  -- Load desktop profile-specific configurations
  require("profiles.desktop.options").setup()
  require("profiles.desktop.autocmds").setup()
  require("profiles.desktop.keymaps").setup()
end

return M



