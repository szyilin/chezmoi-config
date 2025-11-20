-- Core mappings (universal, not NvChad-specific)
-- Add shared keymaps that work across all profiles

local util = require("utils")

-- =======================================================
-- 窗口操作相关                                          --
-- =======================================================
-- 切换 buffer 窗口
util.nmap("<C-n>", ":bn<CR>")
util.nmap("<C-p>", ":bp<CR>")

-- =======================================================
-- 个人使用习惯快捷键配置                                  --
-- =======================================================
-- <C-c> 按键完全配对 <Esc>
util.map("<C-c>", "<Esc>")
-- 视觉模式下不选中换行符
util.vmap("$", "$<Left>")
-- 让 & :s 重复命令可以保留标识位
util.nmap("&", ":&&<CR>")
util.vmap("&", ":&&<CR>")
-- * 和 # 不自动跳到下一个位置
util.nmap("#", [[:let @/='\<<C-R><C-W>\>'<CR>:set hlsearch<CR>]])
util.nmap("*", [[:let @/='\<<C-R><C-W>\>'<CR>:set hlsearch<CR>]])
-- 清空高亮
util.nmap("<C-l>", ":noh<CR>")
-- 输入时候更方便
util.imap("<C-e>", "<END>")
util.imap("<C-a>", "<Esc>^i")
util.imap("<C-b>", "<Left>")
util.imap("<C-f>", "<Right>")
util.imap("<C-n>", "<Down>")
util.imap("<C-p>", "<Up>")
-- 视觉模式下缩进继续选中
util.vmap("<", "<gv")
util.vmap(">", ">gv")

