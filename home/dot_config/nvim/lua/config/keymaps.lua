-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
-----------------------------------------------------------
-- 原生键位个人习惯快捷键配置                            --
-----------------------------------------------------------
local util = require("utils")

-- 通用快捷键加载
require("general.keymaps")

-- 切换 buffer 窗口
util.nmap("<C-n>", ":bn<CR>")
util.nmap("<C-p>", ":bp<CR>")
-- 设置打开窗口行为，取消文件跟随行为
util.nmap("<leader>o", function()
  require("snacks").explorer.open({
    follow_file = false,
    hidden = true
  })
end, { desc = "Explorer Open" })

-- Grep (Root Dir) NOTE: remap 表示映射当作正常按键，而非字符串去触发
util.nmap("<leader>fa", "<leader>/", { remap = true })
-- 映射 == 为全文格式化
vim.keymap.set("n", "==", function() vim.lsp.buf.format({ async = true }) end)


-----------------------------------------------------------
-- lazyvim 占用个人习惯键位适配                          --
-----------------------------------------------------------
-- 停止使用 HL 切换 tab 窗口
vim.keymap.del("n", "H")
vim.keymap.del("n", "L")
-- 停止 <C-hjkl> 切换窗口的行为
vim.keymap.del("n", "<C-h>")
vim.keymap.del("n", "<C-j>")
vim.keymap.del("n", "<C-k>")
-- vim.keymap.del("n", "<C-l>") 前面有顶替

-----------------------------------------------------------
-- 快捷键配置后加载内容                                  --
-----------------------------------------------------------
require("config.other.which-key")
