--[[
  Java LSP 入口：挂载 LazyVim lang.java extra 的覆盖项。
  具体配置见 platform/cli/java/settings.lua
  格式化：jdtls + IDEA 导出的 Eclipse XML Profile（非 google-java-format）
]]
local settings = require("platform.cli.java.settings")

return {
  {
    "mfussenegger/nvim-jdtls",
    opts = function(_, opts)
      return settings.apply_plugin_opts(opts)
    end,
  },
}
