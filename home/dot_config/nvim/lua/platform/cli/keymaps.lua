local M = {}

local util = require("utils")
local snacks = require("snacks")

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

  -- 移除 LazyVim 默认配置
  vim.keymap.del("n", "L")
  vim.keymap.del("n", "H")
end
M.plugins_bufferline = {
  -- 切换 buffer
  { "<C-p>", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
  { "<C-n>", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
  { "<S-h>", false },
  { "<S-l>", false },
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
end

-- ============================================================
-- 查找相关 find
-- ============================================================
local function _fun_finder()
  -- 项目目录查找所有文字
  util.nmap("<leader>fa", function()
    snacks.picker.grep()
  end, { desc = "Grep find all" })
  vim.keymap.del("n", "<leader>/") -- snacks grep default command
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
      pcall(vim.keymap.del, mode, item[1])
    end
  end
end

-- =========================================================
-- which key 适配
-- =========================================================
local function _fun_which_key()
  require("which-key").add({
    -- { "<leader>fa", desc = "Grep (Root Dir)" },
  })
end

function M.setup()
  _fun_win_keys()
  _fun_editor()
  _fun_finder()
  _disable_cwd_keys()

  _fun_which_key()
end

return M
