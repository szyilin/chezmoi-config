M = {}

-----------------------------------------------------------
-- 定义简化版映射函数                                    --
-----------------------------------------------------------
local default_opts = { noremap = true, silent = true } -- 定义默认选项

-- 封装快捷键映射函数
local function map(mode, lhs, rhs, opts)
  -- 合并默认选项，除非手动覆盖值
  opts = vim.tbl_deep_extend("force", default_opts, opts or {})
  vim.keymap.set(mode, lhs, rhs, opts)
end

-- 定义简化版映射函数
M.nmap = function(lhs, rhs, opts) map("n", lhs, rhs, opts) end
M.imap = function(lhs, rhs, opts) map("i", lhs, rhs, opts) end
M.vmap = function(lhs, rhs, opts) map("v", lhs, rhs, opts) end
M.tmap = function(lhs, rhs, opts) map("t", lhs, rhs, opts) end

-----------------------------------------------------------
-- 初始化 lazy.nvim 添加到 lua 上下文等待使用            --
-----------------------------------------------------------
M.initLazy = function()
  local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
  if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
    if vim.v.shell_error ~= 0 then
      vim.api.nvim_echo({
        { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
        { out,                            "WarningMsg" },
        { "\nPress any key to exit..." },
      }, true, {})
      vim.fn.getchar()
      os.exit(1)
    end
  end
  vim.opt.rtp:prepend(lazypath)
end

-----------------------------------------------------------
-- 为 Neovim 运行环境始终指定 node version = 18          --
-----------------------------------------------------------
---@param n_v nil | string 想要设置的 node 版本
M.setNodeVersion = function(n_v)
  -- 默认使用 Node 18
  n_v = n_v or "18"

  -- 使用 pcall 捕获可能的错误
  local success, err = pcall(function()
    -- 获取 NVM 目录
    local nvm_dir = vim.fn.expand("$HOME") .. "/.nvm"

    -- 运行 shell 命令，找到 nvm 中的最新指定版本
    local cmd = string.format("ls -v %s/versions/node/ | grep '^v%s' | tail -n1", nvm_dir, n_v)
    local handle = io.popen(cmd)

    if not handle then
      vim.print("Failed to execute command: " .. cmd .. "\n")
      return
    end

    local node_version = handle:read("*a"):gsub("\n", "") -- 读取并去掉换行符
    handle:close()

    -- 确保找到了版本
    if node_version ~= "" then
      local node_path = string.format("%s/versions/node/%s/bin", nvm_dir, node_version)
      vim.env.PATH = node_path .. ":" .. vim.env.PATH
      vim.env.NODE_VERSION = n_v
    else
      vim.print("No Node.js version found for v" .. n_v)
      vim.print("Try to execute `nvm install " .. n_v .. "`\n")
    end
  end)

  -- 如果发生错误，打印错误日志，但不影响后续代码执行
  if not success then
    vim.print("Error in setNodeVersion: " .. err .. "\n")
  end
end

return M
