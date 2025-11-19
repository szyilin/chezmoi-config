local M = {}

local function setup_lazy()
  local lazy_config = require "configs.lazy"

  -- VSCode profile: minimal plugins, no NvChad
  local spec = {
    { import = "plugins" },
    { import = "profiles.vscode.plugins" },
  }

  require("lazy").setup(spec, lazy_config)
end

function M.setup()
  setup_lazy()

  -- Load core (universal) configurations only
  -- No NvChad UI/configs for VSCode environment
  require "core.options"
  require "core.autocmds"
  require "core.mappings"

  -- Load VSCode profile-specific configurations
  require("profiles.vscode.options").setup()
  require("profiles.vscode.autocmds").setup()
  require("profiles.vscode.keymaps").setup()
end

return M

