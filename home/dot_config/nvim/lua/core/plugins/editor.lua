return {
  -- flash.nvim 跳转（键位见 core/keymaps.lua；覆盖 LazyVim 默认 s/S）
  {
    "folke/flash.nvim",
    priority = 1000,
    opts = {},
    keys = require("core.keymaps").flash_keys,
    config = function(_, opts)
      require("flash").setup(opts)
      -- 合并 LazyVim spec 后，再用 API 兜底移除默认 flash 键位
      local disable = {
        { "s", { "n", "x", "o" } },
        { "S", { "n", "o", "x" } },
        { "r", { "o" } },
        { "R", { "o", "x" } },
        { "<c-s>", { "c" } },
        { "<c-space>", { "n", "o", "x" } },
      }
      for _, item in ipairs(disable) do
        for _, mode in ipairs(item[2]) do
          pcall(vim.keymap.del, mode, item[1])
        end
      end
    end,
  },
}

