--[[
  core/ 与 platform/ 配置分发器。
  config/options|keymaps|autocmds 通过此模块加载，保证 core 先执行、platform 后覆盖。
]]
local M = {}

function M.platform()
  return vim.g.lazyvim_platform or require("platform").detect()
end

---@param section "options" | "keymaps" | "autocmds"
function M.load_section(section)
  local ok, mod = pcall(require, "core." .. section)
  if ok and type(mod) == "table" and type(mod.setup) == "function" then
    mod.setup()
  end

  local platform = M.platform()
  ok, mod = pcall(require, string.format("platform.%s.%s", platform, section))
  if ok and type(mod) == "table" and type(mod.setup) == "function" then
    mod.setup()
  end
end

return M
