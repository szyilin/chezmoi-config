local M = {}

-- ===========================================================
-- snacks.nvim 配置
-- ===========================================================
M.snacks = {
  picker = {
    -- picker 窗口分为三种： input、result list、preview
    win = {
      -- input window
      input = {
        keys = {
          ["<C-c>"] = { "cancel", mode = { "i", "n" } },
          ["<C-h>"] = { "preview_scroll_left", mode = { "i", "n" } },
          ["<C-l>"] = { "preview_scroll_right", mode = { "i", "n" } },
        }
      },
      -- result list window
      list = {
        keys = {
          ["<C-c>"] = "cancel",
          ["<C-h>"] = "preview_scroll_left",
          ["<C-l>"] = "preview_scroll_right",
        }
      },
      -- preview window
      preview = {
        keys = {
          ["<C-c>"] = "cancel",
        }
      }
    },
    sources = {
      explorer = {
        follow_file = false,                               -- 跟随文件
        hidden = true, -- 显示隐藏文件
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
}

return M
