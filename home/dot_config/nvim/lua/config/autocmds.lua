-- Autocmds are automatically loaded on the VeryLazy event (CLI via LazyVim).
-- Default autocmds: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- 具体配置见 lua/core/autocmds.lua 与 lua/platform/<platform>/autocmds.lua

require("config.dispatch").load_section("autocmds")
