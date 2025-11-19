local M = {}

local function setup_lazy()
  local lazy_config = require "configs.lazy"

  -- Firenvim profile: minimal plugins, no NvChad
  local spec = {
    { import = "plugins" },
    { import = "profiles.firenvim.plugins" },
  }

  require("lazy").setup(spec, lazy_config)
end

function M.setup()
  setup_lazy()

  -- Load core (universal) configurations only
  -- No NvChad UI/configs for Firenvim environment
  require "core.options"
  require "core.autocmds"
  require "core.mappings"

  -- Load Firenvim profile-specific configurations
  if pcall(require, "profiles.firenvim.options") then
    require("profiles.firenvim.options").setup()
  end

  if pcall(require, "profiles.firenvim.autocmds") then
    require("profiles.firenvim.autocmds").setup()
  end

  if pcall(require, "profiles.firenvim.keymaps") then
    require("profiles.firenvim.keymaps").setup()
  end
end

return M

