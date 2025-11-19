local M = {}

-- 初始化 lazy.nvim
local function ensure_lazy()
  local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
  if not vim.uv.fs_stat(lazypath) then
    local repo = "https://github.com/folke/lazy.nvim.git"
    vim.fn.system { "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath }
  end
  vim.opt.rtp:prepend(lazypath)
end

function M.setup()
  vim.g.base46_cache = vim.fn.stdpath "data" .. "/base46/"
  vim.g.mapleader = " "
  vim.g.maplocalleader = "\\"

  ensure_lazy()
end

return M



