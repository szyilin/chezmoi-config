local M = {}

local util = require("utils")
local snacks = require("snacks")

--- LazyVim / 插件版本变化时目标键可能未注册，del 须容错
local function safe_del(mode, lhs)
  pcall(vim.keymap.del, mode, lhs)
end

-- ============================================================
-- 窗口操作相关 window
-- ============================================================
local function _fun_win_keys()
  -- 设置打开窗口行为，取消文件跟随行为
  util.nmap("<leader>o", function()
    -- 获取当前已打开的 explorer (如果有的话)
    local explorer = snacks.picker.get({ source = "explorer" })[1]
    if explorer then
      -- 如果已经打开，则关闭它
      explorer:close()
    else
      -- 如果当前没打开，先检查是否有历史状态可以恢复
      if require("snacks.picker.resume").state["explorer"] then
        snacks.picker.resume({ source = "explorer" })
      else
        -- 如果没有历史状态（第一次打开），则直接打开
        snacks.explorer.open()
      end
    end
  end, { desc = "Explorer Open" })

  util.nmap("<leader>e", function()
    -- 获取当前已打开的 explorer
    local explorer = snacks.picker.get({ source = "explorer" })[1]
    -- 如果 explorer 打开了，并且光标当前就在 explorer 窗口里
    if explorer and explorer:is_focused() then
      -- 什么都不做，直接返回，保持状态
      return
    end
    -- 否则（在文件 buffer 中），执行定位操作
    snacks.explorer.reveal()
  end, { desc = "Explorer Reveal" })

  -- 调整窗口大小
  util.nmap("<c-=>", "<cmd>resize +2<cr>", { desc = "Increase Window Height" })
  util.nmap("<c-->", "<cmd>resize -2<cr>", { desc = "Decrease Window Height" })
  util.nmap("<c-,>", "<cmd>vertical resize -2<cr>", { desc = "Decrease Window Width" })
  util.nmap("<c-.>", "<cmd>vertical resize +2<cr>", { desc = "Increase Window Width" })

  -- 移除 LazyVim 默认 buffer 跳转（若存在）
  safe_del("n", "L")
  safe_del("n", "H")
end
M.plugins_bufferline = {
  -- 切换 buffer
  { "<C-p>", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
  { "<C-n>", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
  { "<S-h>", false },
  { "<S-l>", false },
}

-- LazyVim 默认窗口/缓冲区/查找快捷键
M.disable_lazyvim_keys = {
  { "<leader>-", false },
  { "<leader>|", false },
  { "<leader>`", false },
  { "<leader><space>", false },
}

-- LazyVim / Snacks 默认 (cwd) 快捷键，统一禁用，仅保留 Root Dir 版本
M.disable_cwd_keys = {
  { "<leader>E", false },
  { "<leader>fE", false },
  { "<leader>fF", false },
  { "<leader>fR", false },
  { "<leader>sG", false },
  { "<leader>sW", mode = { "n", "x" }, false },
  { "<leader>gG", false },
  { "<leader>gL", false },
  { "<leader>fT", false },
}

-- ============================================================
-- 编写相关 edit
-- ============================================================
local function _fun_editor()
  -- 映射 == 为全文格式化
  vim.keymap.set("n", "==", function()
    vim.lsp.buf.format({ async = true })
  end)

  -- 优化导包（LSP source.organizeImports，语言无关）
  util.nmap("=i", function()
    require("core.lsp").organize_imports()
  end, { desc = "Organize Imports" })

  -- 按 severity 优先级跳转诊断（IDEA [e / ]e：ERROR 优先，再到 WARN 等）
  util.nmap("]e", function()
    require("core.diagnostics").jump(true)
  end, { desc = "Next Problem (severity order)" })
  util.nmap("[e", function()
    require("core.diagnostics").jump(false)
  end, { desc = "Prev Problem (severity order)" })
end

-- ============================================================
-- 查找相关 find
-- ============================================================
local function _fun_finder()
  -- 项目目录查找所有文字
  util.nmap("<leader>fa", function()
    snacks.picker.grep()
  end, { desc = "Grep find all" })
  safe_del("n", "<leader>/") -- snacks grep default command

  -- URL 查找：LSP 优先，endpoint.nvim 兜底
  util.nmap("<leader>fu", function()
    require("platform.cli.find_url").find_url()
  end, { desc = "Find URL" })
end

-- =========================================================
-- 禁用 LazyVim 默认快捷键
-- =========================================================
local function _disable_lazyvim_keys()
  local keys = {
    { "<leader>-", { "n" } },
    { "<leader>|", { "n" } },
    { "<leader>`", { "n" } },
    { "<leader><space>", { "n" } },
  }
  for _, item in ipairs(keys) do
    for _, mode in ipairs(item[2]) do
      safe_del(mode, item[1])
    end
  end
end

-- =========================================================
-- 禁用 (cwd) 快捷键
-- =========================================================
local function _disable_cwd_keys()
  local keys = {
    { "<leader>E", { "n" } },
    { "<leader>fE", { "n" } },
    { "<leader>fF", { "n" } },
    { "<leader>fR", { "n" } },
    { "<leader>sG", { "n" } },
    { "<leader>sW", { "n", "x" } },
    { "<leader>gG", { "n" } },
    { "<leader>gL", { "n" } },
    { "<leader>fT", { "n" } },
  }
  for _, item in ipairs(keys) do
    for _, mode in ipairs(item[2]) do
      safe_del(mode, item[1])
    end
  end
end

-- =========================================================
-- which key 适配
-- =========================================================
local function _fun_which_key()
  require("which-key").add({
    { "=i", desc = "Organize Imports" },
    { "[e", desc = "Prev Problem (severity order)" },
    { "]e", desc = "Next Problem (severity order)" },
    { "<leader>fu", desc = "Find URL" },
  })
end

function M.setup()
  _fun_win_keys()
  _fun_editor()
  _fun_finder()
  _disable_lazyvim_keys()
  _disable_cwd_keys()

  _fun_which_key()
end

return M
