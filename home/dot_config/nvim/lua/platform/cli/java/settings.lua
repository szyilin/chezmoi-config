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
      -- LSP 侧声明（真正生效须配合 patch_cmd 的 JVM 参数）
      generatesMetadataFilesAtProjectRoot = false,
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
---@param target table 含 cmd: string[] 的对象
function M.patch_cmd(target)
  target.cmd = target.cmd or {}
  for _, arg in ipairs(target.cmd) do
    if arg:find(METADATA_AT_ROOT_FLAG, 1, true) then
      return
    end
  end
  table.insert(target.cmd, "--jvm-arg=" .. METADATA_AT_ROOT_FLAG)
end

--- 包装 LazyVim 的 full_cmd，确保 JVM 参数进入最终 jdtls 启动命令
---@param orig_full_cmd function
---@return function
function M.wrap_full_cmd(orig_full_cmd)
  return function(opts)
    M.patch_cmd(opts)
    local cmd = orig_full_cmd(opts)
    M.patch_cmd({ cmd = cmd })
    return cmd
  end
end

---@param opts table nvim-jdtls plugin opts（LazyVim lang.java 合并后）
---@return table
function M.apply_plugin_opts(opts)
  opts = vim.tbl_deep_extend("force", opts or {}, M.plugin_opts())

  if opts.cmd then
    M.patch_cmd(opts)
  end

  if type(opts.full_cmd) == "function" then
    opts.full_cmd = M.wrap_full_cmd(opts.full_cmd)
  end

  local previous_jdtls = opts.jdtls
  opts.jdtls = function(jdtls_opts)
    if type(previous_jdtls) == "function" then
      jdtls_opts = previous_jdtls(jdtls_opts) or jdtls_opts
    elseif type(previous_jdtls) == "table" then
      jdtls_opts = vim.tbl_deep_extend("force", jdtls_opts, previous_jdtls)
    end
    return M.merge_jdtls(jdtls_opts)
  end

  return opts
end

---@param opts table jdtls attach config
---@return table
function M.merge_jdtls(opts)
  M.patch_cmd(opts)
  opts.settings = vim.tbl_deep_extend("force", opts.settings or {}, M.lsp_settings())
  return opts
end

return M
