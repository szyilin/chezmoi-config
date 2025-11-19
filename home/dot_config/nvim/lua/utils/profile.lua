local M = {}

local available = {
  desktop = true,
  vscode = true,
  firenvim = true,
}

function M.detect()
  if vim.g.vscode then
    return available.vscode and "vscode" or "desktop"
  end

  if vim.g.started_by_firenvim then
    return available.firenvim and "firenvim" or "desktop"
  end

  return "desktop"
end

return M



