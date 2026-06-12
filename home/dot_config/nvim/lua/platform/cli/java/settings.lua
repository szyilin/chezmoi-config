--[[
  Java / jdtls 集中配置（CLI）

  所有 jdtls 数据均在 Neovim stdpath 下，不写入项目仓库、不散落系统其它目录：

    stdpath("data")/jdtls/<项目名>/config       每项目 LSP 配置
    stdpath("data")/jdtls/<项目名>/workspace    每项目源码索引与 workspace 元数据
    stdpath("cache")/jdtls/shared-index/        跨项目共享的外部 jar 索引（按 jar 路径复用）

  macOS 默认约为：
    ~/.local/share/nvim/jdtls/...
    ~/.cache/nvim/jdtls/shared-index/...
]]
local M = {}

local METADATA_AT_ROOT_FLAG = "-Djava.import.generatesMetadataFilesAtProjectRoot=false"

--- IDEA Default 导出（Eclipse XML Profile），见 nvim/formatter/intellij-default-java-format.xml
local FORMATTER_PROFILE = "Default"

---@return string
function M.formatter_url()
  return vim.fn.stdpath("config") .. "/formatter/intellij-default-java-format.xml"
end

--- jdtls 数据根目录（Neovim data，非 cache）
---@return string
function M.jdtls_base()
  return vim.fn.stdpath("data") .. "/jdtls"
end

--- 跨项目共享的外部 jar 索引目录（Neovim cache，非 workspace 内）
---@return string
function M.shared_index_dir()
  return vim.fn.stdpath("cache") .. "/jdtls/shared-index"
end

---@return string[]
function M.jvm_perf_args()
  return {
    METADATA_AT_ROOT_FLAG,
    "-Djava.ls.doNotSetDefaultJVM=true",
    "-Djdt.core.sharedIndexLocation=" .. M.shared_index_dir(),
    "-Xms1g",
    "-Xmx4g",
  }
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
    format = {
      enabled = true,
      settings = {
        url = M.formatter_url(),
        profile = FORMATTER_PROFILE,
      },
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

--- 向 jdtls 启动命令注入 JVM 性能参数（须通过 --jvm-arg 传递）
---@param target table 含 cmd: string[] 的对象
function M.patch_cmd(target)
  target.cmd = target.cmd or {}
  local existing = {}
  for _, arg in ipairs(target.cmd) do
    existing[arg] = true
  end
  for _, jvm_arg in ipairs(M.jvm_perf_args()) do
    local flag = "--jvm-arg=" .. jvm_arg
    if not existing[flag] then
      table.insert(target.cmd, flag)
      existing[flag] = true
    end
  end
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

--- Spring Boot jdtls extension jars（依赖 spring-boot.nvim + Mason vscode-spring-boot-tools）
---@return string[]
function M.spring_boot_bundles()
  local ok, spring_boot = pcall(require, "spring_boot")
  if not ok then
    return {}
  end
  -- 不在此调用 setup()：避免抢在 plugin config 之前初始化，导致高级配置被忽略
  return spring_boot.java_extensions() or {}
end

---@param opts table jdtls attach config
---@return table
function M.merge_jdtls(opts)
  M.patch_cmd(opts)
  opts.settings = vim.tbl_deep_extend("force", opts.settings or {}, M.lsp_settings())

  opts.init_options = opts.init_options or {}
  opts.init_options.bundles = opts.init_options.bundles or {}
  local spring_bundles = M.spring_boot_bundles()
  if #spring_bundles > 0 then
    vim.list_extend(opts.init_options.bundles, spring_bundles)
  end

  return opts
end

return M
