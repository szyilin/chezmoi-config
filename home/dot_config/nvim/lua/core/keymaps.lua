local M = {}

local util = require("utils")

-----------------------------------------------------------
-- 原生键位个人习惯快捷键配置                            --
-----------------------------------------------------------
local function _my_keys()
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
end

-- ============================================================
-- editor 相关
-- ============================================================
local function flash_jump()
  require("flash").jump()
end

-- LazyVim 自带 flash.nvim 键位（s/S/r/R 等），须用 lazy.nvim 的 false 显式卸载，
-- 否则合并 spec 后仍会占用 s，且与原生 substitute 冲突。
M.flash_keys = {
  { "s", mode = { "n", "x", "o" }, false },
  { "S", mode = { "n", "o", "x" }, false },
  { "r", mode = "o", false },
  { "R", mode = { "o", "x" }, false },
  { "<c-s>", mode = { "c" }, false },
  { "<c-space>", mode = { "n", "o", "x" }, false },
  {
    "<C-;>",
    flash_jump,
    desc = "Flash",
    mode = { "n", "x", "o" },
  },
}

-- 使用模块函数加载，防止 require 缓存机制，导致运行顺序错误
function M.setup()
  _my_keys()
end

return M
