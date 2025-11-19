return {
  -- 浏览器使用调用 neovim 的插件，还需要在 浏览器安装 firenvim 插件
  {
    'glacambre/firenvim',
    build = ":call firenvim#install(0)",
    config = function()
      vim.g.firenvim_config = {
        globalSettings = { alt = "all" },
        localSettings = {
          [".*"] = {
            -- 不自动接管输入框使用 <cmd-e> 启动
            takeover = "never",
            priority = 0,
          },
        },
      }
    end,
  }
}
