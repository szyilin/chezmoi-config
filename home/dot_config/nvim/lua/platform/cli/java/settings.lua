--[[
  Java / jdtls 集中配置（CLI）
  工作区：stdpath("data")/jdtls/<项目名>/{config,workspace}
  阶段二在此追加 downloadSources、反编译等文档相关项
]]
local M = {}

local METADATA_AT_ROOT_FLAG = "-Djava.import.generatesMetadataFilesAtProjectRoot=false"

--- jdtls 数据根目录（Neovim data，非 cache）
---@return string
function M.jdtls_base()
  return vim.fn.stdpath("data") .. "/jdtls"
end

---@param project_name string
---@param kind "config" | "workspace"
---@return string
function M.jdtls_path(project_name, kind)
  return M.jdtls_base() .. "/" .. project_name .. "/" .. kind
end

---@return table[]|nil
function M.runtimes()
  local java_home = vim.env.JAVA_HOME
  if not java_home or java_home == "" then
    return nil
  end

  return {
    {
      name = "JavaSE-21",
      path = java_home,
      default = true,
    },
  }
end

---@return table
function M.lsp_settings()
  local java = {
    import = {
      maven = { enabled = true },
      gradle = { enabled = false },
    },
  }

  local runtimes = M.runtimes()
  if runtimes then
    java.configuration = { runtimes = runtimes }
  end

  return { java = java }
end

--- nvim-jdtls 顶层 opts（轻量默认，阶段四再开调试/单测）
---@return table
function M.plugin_opts()
  return {
    dap = false,
    dap_main = false,
    test = false,
    jdtls_config_dir = function(project_name)
      return M.jdtls_path(project_name, "config")
    end,
    jdtls_workspace_dir = function(project_name)
      return M.jdtls_path(project_name, "workspace")
    end,
  }
end

--- 禁止在项目根生成 .project / .classpath / .settings（须通过 --jvm-arg 传递）
---@param opts table jdtls attach config（含 cmd）
function M.patch_cmd(opts)
  opts.cmd = opts.cmd or {}
  for _, arg in ipairs(opts.cmd) do
    if arg:find(METADATA_AT_ROOT_FLAG, 1, true) then
      return
    end
  end
  table.insert(opts.cmd, "--jvm-arg=" .. METADATA_AT_ROOT_FLAG)
end

---@param opts table
---@return table
function M.merge_jdtls(opts)
  M.patch_cmd(opts)
  opts.settings = vim.tbl_deep_extend("force", opts.settings or {}, M.lsp_settings())
  return opts
end

return M
