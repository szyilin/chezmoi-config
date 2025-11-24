vim.o.laststatus = 0 -- 去除底部状态栏

local opt = vim.opt
opt.clipboard = vim.env.SSH_TTY and "" or "unnamedplus" -- 使用系统剪贴板


