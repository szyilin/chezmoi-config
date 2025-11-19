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

-- =======================================================
-- 剪贴板相关配置                                          --
-- =======================================================
-- 智能粘贴：如果用户指定了寄存器（如 "1p），使用用户指定的寄存器
-- 否则使用 "0 寄存器（总是粘贴最后一次主动复制的内容，不受删除影响）
-- 
-- 注意：由于设置了 clipboard = "unnamedplus"，" 和 + 寄存器会同步
-- 所以直接按 p 时，vim.v.register 可能返回 '+' 而不是 '"'
-- 两种情况都应该使用 "0 寄存器
local function smart_paste(register)
  return function()
    -- vim.v.register 包含用户指定的寄存器名称（不带 " 前缀）
    -- 例如：用户输入 "1p，vim.v.register 为 '1'
    --       用户输入 "ap，vim.v.register 为 'a'
    --       用户直接按 p，由于 unnamedplus，vim.v.register 可能是 '"' 或 '+'
    local reg = vim.v.register
    -- 如果是默认寄存器（" 或 +），使用 "0（最后一次 yank 的内容）
    if reg == '"' or reg == '+' then
      return '"0' .. register
    else
      -- 用户指定了寄存器，使用用户指定的寄存器
      return '"' .. reg .. register
    end
  end
end

util.vmap("p", smart_paste("p"), { expr = true })
util.vmap("P", smart_paste("P"), { expr = true })
util.nmap("p", smart_paste("p"), { expr = true })
util.nmap("P", smart_paste("P"), { expr = true })

