local M = {}
local cached_platform

function M.detect()
  if cached_platform then
    return cached_platform
  end

  if vim.g.vscode then
    cached_platform = "vscode"
  elseif vim.g.started_by_firenvim then
    cached_platform = "firenvim"
  else
    cached_platform = "cli"
  end

  return cached_platform
end

return M
