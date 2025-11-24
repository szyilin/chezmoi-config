--[[
配置自定义按键的提示
]]
local wk = require("which-key")

wk.add({
  { "<leader>o", icon = { icon = "󰝰", color = "azure" } },
  { "<leader>fa", desc = "Grep (Root Dir)" },
})
