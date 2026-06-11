--[[
  Spring Boot 辅助函数（CLI）
]]
local M = {}

--- Spring Boot LSP workspace symbols 查找（需 jdtls / spring-boot 已就绪）
function M.find_url_lsp()
  require("snacks.picker").lsp_workspace_symbols({
    title = "Find URL",
    filter = { default = true, java = true },
    live = true,
  })
end

return M
