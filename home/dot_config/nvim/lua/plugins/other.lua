return {
-- =======================================================
-- 工具类型插件
-- =======================================================
  -- 自动切换中英文
  {
    "keaising/im-select.nvim",
    lazy = false, -- 确保启动时加载
    opts = {
      default_im_select = "com.apple.keylayout.ABC",
      default_command = "im-select",
    }
  }
}