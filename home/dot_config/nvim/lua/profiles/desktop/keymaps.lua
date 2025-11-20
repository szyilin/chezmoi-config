local M = {}

local util = require("utils")
local nvim_tree_api = require("nvim-tree.api")

function M.setup()
  -- nvim-tree 相关快捷键
  -- 使用包装函数确保在调用时才加载 API（因为 nvim-tree 是 lazy 加载的）
  util.nmap("<leader>o", function()
    nvim_tree_api.tree.toggle()
  end, { desc = "Toggle NvimTree" })
  
  -- 聚焦到当前文件
  util.nmap("<leader>e", function()
    nvim_tree_api.tree.open()
  end, { desc = "Find File in NvimTree" })
end

return M
