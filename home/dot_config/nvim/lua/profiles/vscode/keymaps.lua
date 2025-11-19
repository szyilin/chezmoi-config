local M = {}

local vscode = require("vscode") -- vscode neovim api
local util = require("utils")

local function setup_all_keymaps()
    --[[
  NOTE: 有些快捷键并不能在依靠 vscode neovim 插件中的 lua 进行配置；
  因此只能将这种 `lua` 配置不了的交给 vscode 配置文件，这里将所有相关快捷键记录在：
  './keybindings.json' 文件中
  ]]

  -----------------------------------------------------------
  -- 窗口操作相关                                          --
  -----------------------------------------------------------
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

  -----------------------------------------------------------
  -- 搜索相关                                              --
  -----------------------------------------------------------
  -- 🔍 搜索文件，适配 lazyvim 按键习惯
  util.nmap("<leader><space>", "<cmd>Find<cr>") -- 设置命令相关需要按照下面这种格式，否则不生效
  util.nmap("<leader>/", function() vscode.call("workbench.action.findInFiles") end)
  util.nmap("<leader>ss", function() vscode.call("workbench.action.gotoSymbol") end)

  -----------------------------------------------------------
  -- 代码相关                                              --
  -----------------------------------------------------------
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

  -----------------------------------------------------------
  -- other config                                          --
  -----------------------------------------------------------
  -- 修复 vscode neovim 中的一些奇怪行为
  util.nmap("H", "H")
  util.nmap("M", "M")
  util.nmap("L", "L")
  util.vmap("H", "H")
  util.vmap("M", "M")
  util.vmap("L", "L")

end

function M.setup()
  setup_all_keymaps()
end

return M



