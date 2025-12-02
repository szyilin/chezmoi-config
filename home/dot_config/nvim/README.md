# 💤 LazyVim

A starter template for [LazyVim](https://github.com/LazyVim/LazyVim).
Refer to the [documentation](https://lazyvim.github.io/installation) to get started.

# 目录说明

```txt
lua
  |-core/                : 通用配置层（options/keymaps/autocmds/configs/plugins）
  |-platform/            : 平台差异层（cli/vscode/firenvim）
      |-<platform>/      : 每个平台与 core 同结构，可只覆写差异
  |-utils/               : 工具函数（按需拆分 env/path 等模块）
```

# 疑难问题

1. 使用 `Mason` 下载语言服务器的时 **语言服务器不生效**：检查让默认 `node>=18`(这个问题已经在配置文件中解决)
2. VSCode Neovim `ctrl` **开头快捷键不生效**：在 `lua/platform/vscode/keymaps.lua` 文件中记录了解决方法
