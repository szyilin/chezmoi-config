M = {}
-----------------------------------------------------------
-- 定义简化版映射函数                                    --
-----------------------------------------------------------
local default_opts = { noremap = true, silent = true } -- 定义默认选项

-- 封装快捷键映射函数
local function map(mode, lhs, rhs, opts)
  -- 合并默认选项，除非手动覆盖值
  opts = vim.tbl_deep_extend("force", default_opts, opts or {})
  vim.keymap.set(mode, lhs, rhs, opts)
end

-- 定义简化版映射函数
M.map = function(lhs, rhs, opts) map("", lhs, rhs, opts) end -- 所有模式
M.nmap = function(lhs, rhs, opts) map("n", lhs, rhs, opts) end
M.imap = function(lhs, rhs, opts) map("i", lhs, rhs, opts) end
M.vmap = function(lhs, rhs, opts) map("v", lhs, rhs, opts) end
M.tmap = function(lhs, rhs, opts) map("t", lhs, rhs, opts) end -- 命令行模式

return M
