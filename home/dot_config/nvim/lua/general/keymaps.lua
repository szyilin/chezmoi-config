--[[
neovim 不同使用场景相同的 keymaps 配置
]]
local util = require("utils")

-- <C-c> 按键完全配对 <Esc>
util.nmap("<C-c>", "<Esc>")
util.imap("<C-c>", "<Esc>")
util.vmap("<C-c>", "<Esc>")
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
