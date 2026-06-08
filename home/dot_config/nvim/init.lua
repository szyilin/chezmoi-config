-- 统一定义按键前缀，需在任何插件加载前设置
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.g.lazyvim_platform = require("platform").detect()

require("config.lazy")
