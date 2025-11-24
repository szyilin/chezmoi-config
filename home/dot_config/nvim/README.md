# 💤 LazyVim

A starter template for [LazyVim](https://github.com/LazyVim/LazyVim).
Refer to the [documentation](https://lazyvim.github.io/installation) to get started.

# 目录说明

```txt
lua
  |-config: lazyvim 提供结构
  |-plugins: lazyvim 提供结构
  |-custom: neovim 在非终端的运行配置(例如：vscode, firenvim(浏览器))
    并且子文件夹遵循 lazyvim 提供结构
  |-general: 所有运行环境均适用的配置（通用配置）
  |-utils: 自己封装的工具包
```

# 疑难问题

1. 使用 `Mason` 下载语言服务器的时 **语言服务器不生效**：检查让默认 `node >= 18`(这个问题已经在配置文件中解决)
2. VSCode Neovim `ctrl` **开头快捷键不生效**：在 `lua/custom/vscode/keymaps.lua` 文件中记录了解决方法
