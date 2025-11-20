local M = {}

M.todo_comments = {
  -- keywords recognized as todo comments
  keywords = {
    FIX = {
      icon = " ", -- icon used for the sign, and in search results
      color = "error", -- can be a hex color, or a named color (see below)
      -- 映射到这个FIX关键字的一组其他关键字
      alt = { "FIXME", "BUG", "FIXIT", "ISSUE" },
      -- signs = false, -- 个别关键字配置符号
    },
    TODO = { icon = " ", color = "info", alt = { "todo" } },
    HACK = { icon = " ", color = "warning" },
    WARN = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
    PERF = { icon = " ", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
    NOTE = { icon = " ", color = "hint", alt = { "INFO" } },
    TEST = { icon = "⏲ ", color = "test", alt = { "TESTING", "PASSED", "FAILED" } },
  },

}

return M
