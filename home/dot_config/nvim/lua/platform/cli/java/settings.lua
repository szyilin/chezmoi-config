--[[
  Java / jdtls 集中配置（CLI）
  阶段二在此追加 downloadSources、反编译等文档相关项
]]
local M = {}

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
  }
end

---@param opts table
---@return table
function M.merge_jdtls(opts)
  opts.settings = vim.tbl_deep_extend("force", opts.settings or {}, M.lsp_settings())
  return opts
end

return M
