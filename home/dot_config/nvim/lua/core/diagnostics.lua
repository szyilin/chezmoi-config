--[[
  诊断跳转（语言无关）

  [e / ]e：按 severity 优先级循环跳转（ERROR → WARN → INFO → HINT），
  同级再按行号、列号排序；处理完所有高优先级后再进入低优先级。
]]
local M = {}

---@param a vim.Diagnostic
---@param b vim.Diagnostic
---@return boolean
local function cmp_diag(a, b)
  if a.severity ~= b.severity then
    return a.severity < b.severity
  end
  if a.lnum ~= b.lnum then
    return a.lnum < b.lnum
  end
  return a.col < b.col
end

---@param diagnostics vim.Diagnostic[]
---@return vim.Diagnostic[]
local function sort_by_priority(diagnostics)
  table.sort(diagnostics, cmp_diag)
  return diagnostics
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
  local diagnostics = sort_by_priority(vim.diagnostic.get(buf))
  if #diagnostics == 0 then
    vim.notify("No diagnostics", vim.log.levels.INFO)
    return
  end

  local cursor = vim.api.nvim_win_get_cursor(0)
  local lnum, col = cursor[1] - 1, cursor[2]
  local n = #diagnostics

  local on_idx, upcoming_idx = locate(diagnostics, lnum, col)
  local idx ---@type integer

  if next then
    if on_idx then
      idx = on_idx
    elseif upcoming_idx then
      idx = upcoming_idx - 1
    else
      idx = 0
    end
    idx = (idx + count - 1) % n + 1
  else
    if on_idx then
      idx = on_idx
    else
      local last_before = 0
      for i, d in ipairs(diagnostics) do
        if before_in_file(d, lnum, col) then
          last_before = i
        end
      end
      idx = last_before + 1
    end
    idx = ((idx - count - 1) % n + n) % n + 1
  end

  jump_to(diagnostics[idx])
end

return M
