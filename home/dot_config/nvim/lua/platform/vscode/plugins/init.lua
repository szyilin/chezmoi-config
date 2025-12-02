return {
  -- 增添文本对象
  {
    "echasnovski/mini.ai",
    event = "VeryLazy",
    opts = function()
      local ai = require("mini.ai")
      return {
        n_lines = 500,
        custom_textobjects = {
          -- 这三个依赖 treesitter lsp 在 vscode 中不存在因此不考虑
          -- o = ai.gen_spec.treesitter({ -- code block
          --   a = { "@block.outer", "@conditional.outer", "@loop.outer" },
          --   i = { "@block.inner", "@conditional.inner", "@loop.inner" },
          -- }),
          -- f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }), -- function
          -- c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),       -- class
          -- NOTE: 这里是根据匹配符号进行配对，可以参考这里的代码进行自定义文本对象
          t = { "<([%p%w]-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" },     -- tags 优化标签配对
          d = { "%f[%d]%d+" },                                                    -- digits
          e = {                                                                   -- Word with case
            { "%u[%l%d]+%f[^%l%d]", "%f[%S][%l%d]+%f[^%l%d]", "%f[%P][%l%d]+%f[^%l%d]", "^[%l%d]+%f[^%l%d]" },
            "^().*()$",
          },
          u = ai.gen_spec.function_call(),                           -- u for "Usage"
          U = ai.gen_spec.function_call({ name_pattern = "[%w_]" }), -- without dot in function name
        },
      }
    end
  }
}
