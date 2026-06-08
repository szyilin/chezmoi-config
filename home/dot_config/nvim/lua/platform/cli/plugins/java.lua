--[[
  Java LSP 入口：挂载 LazyVim lang.java extra 的覆盖项。
  具体配置见 platform/cli/java/settings.lua
]]
local settings = require("platform.cli.java.settings")

return {
  {
    "mfussenegger/nvim-jdtls",
    opts = vim.tbl_extend("force", settings.plugin_opts(), {
      jdtls = function(opts)
        return settings.merge_jdtls(opts)
      end,
    }),
  },
}
