--[[
  诊断跳转（语言无关）

  [e / ]e：只在当前 buffer 中「最高 severity」的诊断间循环跳转
  （例如仍有 ERROR 时只跳 ERROR，全部消除后才跳 WARN，以此类推）；
  同级按行号、列号排序。
]]
local M = {}

---@param a vim.Diagnostic
---@param b vim.Diagnostic
---@return boolean
local function cmp_diag(a, b)
  if a.lnum ~= b.lnum then
    return a.lnum < b.lnum
  end
  return a.col < b.col
end

---@param diagnostics vim.Diagnostic[]
---@return vim.Diagnostic[]
local function sort_by_position(diagnostics)
  table.sort(diagnostics, cmp_diag)
  return diagnostics
end

--- 只保留 buffer 中最高 severity（数字最小）的诊断
---@param diagnostics vim.Diagnostic[]
---@return vim.Diagnostic[]
local function filter_top_severity(diagnostics)
  if #diagnostics == 0 then
    return diagnostics
  end

  local top = diagnostics[1].severity
  for i = 2, #diagnostics do
    local s = diagnostics[i].severity
    if s < top then
      top = s
    end
  end

  local filtered = {}
  for _, d in ipairs(diagnostics) do
    if d.severity == top then
      filtered[#filtered + 1] = d
    end
  end

  return sort_by_position(filtered)
end

---@param d vim.Diagnostic
---@param lnum integer 0-based
---@param col integer
---@return boolean
local function on_diagnostic(d, lnum, col)
  if d.lnum ~= lnum then
    return false
  end
  local end_col = d.end_col or d.col
  return col >= d.col and col <= end_col
end

---@param d vim.Diagnostic
---@param lnum integer 0-based
---@param col integer
---@return boolean
local function before_in_file(d, lnum, col)
  return d.lnum < lnum or (d.lnum == lnum and d.col < col)
end

---@param sorted vim.Diagnostic[]
---@param lnum integer 0-based
---@param col integer
---@return integer|nil on_diag_idx
---@return integer|nil upcoming_idx 光标前无诊断时，文件中下一个待处理项
local function locate(sorted, lnum, col)
  local on_idx = nil
  for i, d in ipairs(sorted) do
    if on_diagnostic(d, lnum, col) then
      on_idx = i
      break
    end
  end

  local upcoming_idx = nil
  for i, d in ipairs(sorted) do
    if not before_in_file(d, lnum, col) then
      upcoming_idx = i
      break
    end
  end

  return on_idx, upcoming_idx
end

---@param diagnostic vim.Diagnostic
local function jump_to(diagnostic)
  vim.diagnostic.jump({
    diagnostic = diagnostic,
    float = true,
  })
end

---@param next boolean true = ]e, false = [e
---@param count? integer
function M.jump(next, count)
  count = count or vim.v.count1
  if count < 1 then
    return
  end

  local buf = vim.api.nvim_get_current_buf()
  local diagnostics = filter_top_severity(vim.diagnostic.get(buf))
  if #diagnostics == 0 then
    vim.notify("No diagnostics", vim.log.levels.INFO)
    return
  end

  local cursor = vim.api.nvim_win_get_cursor(0)
  local lnum, col = cursor[1] - 1, cursor[2]
  local n = #diagnostics

  local on_idx, upcoming_idx = locate(diagnostics, lnum, col)
  local base ---@type integer
  local idx ---@type integer

  if next then
    if on_idx then
      base = on_idx
    elseif upcoming_idx then
      base = upcoming_idx - 1
    else
      base = 0
    end
    idx = (base + count) % n
    if idx == 0 then
      idx = n
    end
  else
    if on_idx then
      base = on_idx
    else
      local last_before = 0
      for i, d in ipairs(diagnostics) do
        if before_in_file(d, lnum, col) then
          last_before = i
        end
      end
      base = last_before + 1
    end
    idx = ((base - count - 1) % n + n) % n + 1
  end

  jump_to(diagnostics[idx])
end

return M
