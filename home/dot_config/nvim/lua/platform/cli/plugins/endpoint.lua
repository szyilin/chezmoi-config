--[[
  endpoint.nvim：多框架 URL/路由查找兜底（Spring / NestJS / Express / FastAPI 等）
]]
return {
  {
    "zerochae/endpoint.nvim",
    dependencies = { "folke/snacks.nvim" },
    cmd = { "Endpoint", "EndpointRefresh" },
    config = function()
      require("endpoint").setup({
        picker = { type = "snacks" },
        cache = { mode = "session" },
      })
    end,
  },
}
