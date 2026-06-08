-- Keymaps are automatically loaded on the VeryLazy event (CLI via LazyVim).
-- Default keymaps: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- 具体配置见 lua/core/keymaps.lua 与 lua/platform/<platform>/keymaps.lua

require("config.dispatch").load_section("keymaps")
