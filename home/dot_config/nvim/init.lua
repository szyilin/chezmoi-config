-- 统一定义按键前缀，需在任何插件加载前设置
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.g.lazyvim_platform = require("platform").detect()

-- UPSTREAM-WORKAROUND: inlay hint col out of range — see core/workarounds/README.md
require("core.workarounds.inlay_hint").setup()

require("config.lazy")
