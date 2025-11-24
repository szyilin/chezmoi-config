--[[
适配非主分类插件，例如 flash（类似 easymotion 的插件）等其他插件的适配工作
]]
return {

  -- 类似 easymotion 插件适配
  {
    "folke/flash.nvim",
    keys = function()
      return {
        {
          "<C-;>",
          mode = { "n", "x", "o" },
          function()
            require("flash").jump()
          end,
          desc = "Flash",
        },
      }
    end,
  },

  -- lazy.nvim snacks.nvim 配置(这是一个众多插件的集合)
  {
    "folke/snacks.nvim",
    opts = {
      explorer = {
        -- 自定义文件浏览器配置
        tree = true,                                      -- 启用文件树视图
        watch = true,                                     -- 启用文件变动监视
        diagnostics = true,                               -- 显示诊断信息
        git_status = true,                                -- 显示 Git 状态
        follow_file = true,                               -- 跟随当前文件
        layout = { preset = "sidebar", preview = false }, -- 侧边栏布局，关闭预览
        exclude = { "*.git", "node_modules" },            -- 排除某些目录或文件
      },
      picker = {
        sources = {
          explorer = {
            -- 自定义 picker 配置
            finder = "explorer",                              -- 设置为文件浏览器
            sort = { fields = { "sort" } },                   -- 设置排序字段
            supports_live = true,                             -- 启用实时更新
            tree = true,                                      -- 启用文件树
            watch = true,                                     -- 启用文件监视
            diagnostics = true,                               -- 启用诊断
            git_status = true,                                -- 启用 Git 状态
            follow_file = true,                               -- 跟随文件
            focus = "list",                                   -- 默认焦点为文件列表
            layout = { preset = "sidebar", preview = false }, -- 侧边栏布局
            formatters = {
              file = { filename_only = true },
              severity = { pos = "right" },
            },
            win = {
              list = {
                keys = {
                  ["<BS>"] = false,                                 -- 上一级目录
                  ["<c-[>"] = "explorer_up",                        -- 上一级目录
                  ["l"] = "confirm",                                -- 确认选择
                  ["h"] = "explorer_close",                         -- 关闭目录
                  ["a"] = "explorer_add",                           -- 添加文件或目录
                  ["d"] = "explorer_del",                           -- 删除文件或目录
                  ["r"] = "explorer_rename",                        -- 重命名文件或目录
                  ["c"] = "explorer_copy",                          -- 复制文件
                  ["m"] = "explorer_move",                          -- 移动文件
                  ["o"] = "confirm",                                -- 确认选择
                  ["<CR>"] = "explorer_open",                       -- 使用系统应用打开
                  ["P"] = "toggle_preview",                         -- 切换预览
                  ["y"] = { "explorer_yank", mode = { "n", "x" } }, -- 复制文件路径
                  ["p"] = "explorer_paste",                         -- 粘贴文件
                  ["u"] = "explorer_update",                        -- 更新文件浏览器
                  ["<c-c>"] = false,                                -- 切换目录
                  ["."] = "tcd",                                    -- 切换工作目录
                  ["<leader>/"] = "picker_grep",                    -- 搜索文件
                  ["<c-/>"] = "terminal",                           -- 打开终端
                  ["<c-]>"] = "explorer_focus",                     -- 聚焦到文件浏览器
                  ["I"] = false,                                    -- 切换忽略文件
                  ["<c-i>"] = "toggle_ignored",                     -- 切换忽略文件
                  -- ["H"] = "toggle_hidden",                          -- 切换显示隐藏文件
                  ["H"] = false,                                    -- 切换显示隐藏文件
                  ["<c-h>"] = "toggle_hidden",                      -- 切换显示隐藏文件
                  ["Z"] = "explorer_close_all",                     -- 关闭所有目录
                  ["]g"] = "explorer_git_next",                     -- 下一个 Git 状态
                  ["[g"] = "explorer_git_prev",                     -- 上一个 Git 状态
                  ["]d"] = "explorer_diagnostic_next",              -- 下一个诊断
                  ["[d"] = "explorer_diagnostic_prev",              -- 上一个诊断
                  ["]w"] = "explorer_warn_next",                    -- 下一个警告
                  ["[w"] = "explorer_warn_prev",                    -- 上一个警告
                  ["]e"] = "explorer_error_next",                   -- 下一个错误
                  ["[e"] = "explorer_error_prev",                   -- 上一个错误
                },
              },
            },
          },
        },
      },
    },
  },
}
