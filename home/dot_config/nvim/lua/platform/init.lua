local utils = require("utils")

local M = {}
local cached_platform

local function detect_platform()
  if cached_platform then
    return cached_platform
  end

  if vim.g.vscode then
    cached_platform = "vscode"
  elseif vim.g.started_by_firenvim then
    cached_platform = "firenvim"
  else
    cached_platform = "cli"
  end

  return cached_platform
end

function M.detect()
  return detect_platform()
end

-- 按平台初始化 lazy.nvim（必须在 core.setup 之前执行）
function M.setup_lazy(name)
  local target = name or detect_platform()
  local ok, lazy_config = pcall(require, string.format("platform.%s.configs.lazy", target))
  if not ok then
    -- 如果当前平台未提供 lazy 配置，则跳过
    return
  end

  if type(lazy_config) ~= "table" then
    vim.notify(string.format("[platform] invalid lazy config for %s", target), vim.log.levels.WARN)
    return
  end

  utils.setupLazy(lazy_config)
end

-- 手动加载对应平台模块，并调用其 setup
function M.setup(name)
  local target = name or detect_platform()
  local ok, mod = pcall(require, string.format("platform.%s", target))
  if not ok then
    vim.notify(string.format("[platform] failed to load %s: %s", target, mod), vim.log.levels.WARN)
    return
  end

  if type(mod) == "table" and type(mod.setup) == "function" then
    mod.setup()
  end
end

return M
