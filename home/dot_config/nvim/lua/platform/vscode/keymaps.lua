--[[
NOTE: 有些快捷键并不能在依靠 vscode neovim 插件中的 lua 进行配置；
因此只能将这种 `lua` 配置不了的交给 vscode 配置文件，这里将所有相关快捷键记录在：
'./keybindings.json' 文件中
]]
local M = {}

local vscode = require("vscode")
local util = require("utils")

-----------------------------------------------------------
-- 窗口操作相关
-----------------------------------------------------------
local function _fun_win_keys()
  -- 切换 buffer 窗口
  util.nmap("<C-n>", function() vscode.call("workbench.action.nextEditor") end)
  util.nmap("<C-p>", function() vscode.call("workbench.action.previousEditor") end)
  -- 打开资源管理器
  util.nmap("<leader>o", function() vscode.call("workbench.view.explorer") end)
  util.nmap("<leader>e", function() vscode.call("workbench.files.action.showActiveFileInExplorer") end)
  -- 关闭标签（适配 lazyvim 使用习惯）
  util.nmap("<leader>bd", function() vscode.call("workbench.action.closeActiveEditor") end)
  -- 打开终端管理器
  util.nmap("<C-/>", function() vscode.call("workbench.action.terminal.toggleTerminal") end)
end

-----------------------------------------------------------
-- 搜索相关
-----------------------------------------------------------
local function _fun_search_keys()
  -- 🔍 搜索文件，适配 lazyvim 按键习惯
  util.nmap("<leader><space>", "<cmd>Find<cr>") -- 设置命令相关需要按照下面这种格式，否则不生效
  util.nmap("<leader>/", function() vscode.call("workbench.action.findInFiles") end)
  util.nmap("<leader>ss", function() vscode.call("workbench.action.gotoSymbol") end)
end

-----------------------------------------------------------
-- 代码相关
-----------------------------------------------------------
local function _fun_code_keys()
  -- vscode 默认格式化代码
  util.nmap("==", function() vscode.call("editor.action.formatDocument") end)
  -- eslint 自动修复整篇
  util.nmap("=e", function () vscode.call("eslint.executeAutofix") end)
  -- 自动优化导包
  util.nmap("=i", function () vscode.call("editor.action.organizeImports") end)
  -- 使用 vscode 撤销和反撤销
  util.nmap("u", "<Cmd>call VSCodeNotify('undo')<CR>")
  util.nmap("<C-r>", "<Cmd>call VSCodeNotify('redo')<CR>")
  -- 跳转错误
  util.nmap("]e", function() vscode.call("editor.action.marker.next") end)
  util.nmap("[e", function() vscode.call("editor.action.marker.prev") end)
end

-----------------------------------------------------------
-- other config
-----------------------------------------------------------
local function _fun_other_keys()
-- 修复 vscode neovim 中的一些奇怪行为
  util.nmap("H", "H")
  util.nmap("M", "M")
  util.nmap("L", "L")
  util.vmap("H", "H")
  util.vmap("M", "M")
  util.vmap("L", "L")
end

function M.setup()
  _fun_win_keys()
  _fun_search_keys()
  _fun_code_keys()
  _fun_other_keys()
end

return M