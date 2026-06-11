--[[
  <leader>fu 智能路由

  1. 当前 filetype 注册了 LSP URL 查找，且相关 LSP 已就绪 → 走 LSP
  2. 否则 → endpoint.nvim 兜底（多框架 AST 扫描，不依赖 LSP 索引）

  注意：每次按键都会重新检测 LSP 状态，不会「用过 endpoint 就锁定」。
  endpoint.nvim 的 session cache 只缓存扫描结果，不影响路由决策。
]]
local M = {}

---@class FindUrlHandler
---@field lsp fun()
---@field lsp_clients string[]

--- filetype → LSP URL 查找（后续可为 ts/js 等扩展）
local handlers = {
  java = {
    lsp = function()
      require("platform.cli.java.spring_boot").find_url_lsp()
    end,
    lsp_clients = { "jdtls", "spring-boot" },
  },
}

---@param ft string
---@param handler FindUrlHandler
function M.register(ft, handler)
  handlers[ft] = handler
end

---@param buf number
---@param wanted table<string, boolean>
---@return vim.lsp.Client[]
local function collect_clients(buf, wanted)
  local clients = {}
  local seen = {}

  local function add(client)
    if wanted[client.name] and not seen[client.id] then
      seen[client.id] = true
      clients[#clients + 1] = client
    end
  end

  -- 优先 buffer 级 client
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
    add(client)
  end

  -- 补充 workspace 级 client（jdtls 有时不在 bufnr 过滤结果里）
  for _, client in ipairs(vim.lsp.get_clients()) do
    add(client)
  end

  return clients
end

---@param buf number
---@param handler FindUrlHandler
---@return boolean
local function lsp_url_ready(buf, handler)
  if not handler.lsp_clients then
    return false
  end

  local wanted = {}
  for _, name in ipairs(handler.lsp_clients) do
    wanted[name] = true
  end

  for _, client in ipairs(collect_clients(buf, wanted)) do
    -- Neovim 0.11 使用 client.initialized，无 server_initialized 字段
    if client.initialized and client:supports_method("workspace/symbol", buf) then
      return true
    end
  end

  return false
end

local function endpoint_find()
  require("endpoint").find()
end

--- 按 URL 查找（IDEA GotoUrlAction）
function M.find_url()
  local buf = vim.api.nvim_get_current_buf()
  local handler = handlers[vim.bo[buf].filetype]

  if handler and handler.lsp and lsp_url_ready(buf, handler) then
    handler.lsp()
    return
  end

  endpoint_find()
end

return M
