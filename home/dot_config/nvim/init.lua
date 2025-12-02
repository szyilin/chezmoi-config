-- 统一定义按键前缀，需在任何插件加载前设置
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local platform = require("platform")
local current_platform = platform.detect()
vim.g.lazyvim_platform = current_platform

local section_order = { "options", "keymaps", "autocmds" }

local function load_platform_section(section)
  local ok, mod = pcall(require, string.format("platform.%s.%s", current_platform, section))
  if not ok then
    return nil
  end

  if type(mod) == "table" and type(mod.setup) == "function" then
    mod.setup()
  end

  return mod
end

local function load_core_section(section)
  local ok, mod = pcall(require, string.format("core.%s", section))
  if not ok then
    return nil
  end

  if type(mod) == "table" and type(mod.setup) == "function" then
    mod.setup()
  end

  return mod
end

local function load_section(section)
  load_core_section(section)

  load_platform_section(section)

  return {}
end

local function load_all_sections()
  for _, section in ipairs(section_order) do
    load_section(section)
  end
end

--[[
LazyVim 会在 VeryLazy 事件里依次 require config.options|keymaps|autocmds。
我们通过 package.preload 把这些虚拟模块映射到 core/ 与 platform/ 的实现，
这样既沿用 LazyVim 的默认懒加载机制，又能保证 core 先执行、platform 后覆盖。
]]

local lazy_module_alias = {
  options = "config.options",
  keymaps = "config.keymaps",
  autocmds = "config.autocmds",
}

local function register_lazy_aliases()
  for section, alias in pairs(lazy_module_alias) do
    package.preload[alias] = function()
      load_section(section)
    end
  end
end

-- 先注册别名，避免 LazyVim 在 lazy.nvim 初始化阶段 require 旧路径时报错
register_lazy_aliases()

platform.setup_lazy(current_platform)

local ok, Config = pcall(require, "lazy.core.config")

local function has_lazyvim()
  if not ok or not Config or not Config.spec or not Config.spec.plugins then
    return false
  end

  return Config.spec.plugins.LazyVim ~= nil
end

if not has_lazyvim() then
  -- 没装 LazyVim，直接跑自定义逻辑
  load_all_sections()
end
