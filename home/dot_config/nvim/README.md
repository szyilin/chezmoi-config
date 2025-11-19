**This repo is supposed to be used as config by NvChad users!**

- The main nvchad repo (NvChad/NvChad) is used as a plugin by this repo.
- So you just import its modules , like `require "nvchad.options" , require "nvchad.mappings"`
- So you can delete the .git from this repo ( when you clone it locally ) or fork it :)

# Layout Overview

```
nvim/
├─ init.lua
│   └─ 入口：检测 profile → core.bootstrap → profiles/{scene}/setup
│
├─ lua/
│  ├─ chadrc.lua
│  │   └─ 全局 UI/主题配置（profiles 可覆盖）
│  │
│  ├─ core/                      ← 通用基础配置（不依赖 NvChad）
│  │   ├─ bootstrap.lua         | lazy.nvim 自举、runtimepath 设置
│  │   ├─ options.lua           | 通用 vim 选项（所有 profile 共享）
│  │   ├─ autocmds.lua           | 通用自动命令（所有 profile 共享）
│  │   └─ mappings.lua           | 通用按键映射（所有 profile 共享）
│  │
│  │
│  ├─ configs/                   ← 全局通用配置
│  │   └─ lazy.lua              | lazy.nvim 全局配置
│  │
│  ├─ plugins/
│  │   └─ init.lua              | 真正通用的插件（所有 profile 都需要）
│  │
│  ├─ profiles/                  ← 不同运行场景的独立入口
│  │   ├─ desktop/
│  │   │   ├─ init.lua          | 加载 core + nvchad.* + desktop 配置
│  │   │   ├─ options.lua       | 桌面场景特定选项
│  │   │   ├─ autocmds.lua      | 桌面场景特定自动命令
│  │   │   ├─ keymaps.lua        | 桌面场景特定快捷键
│  │   │   ├─ plugins.lua        | 桌面场景插件（LSP、格式化等）
│  │   │   └─ configs/           | 桌面场景插件配置
│  │   │       ├─ lspconfig.lua | LSP 配置
│  │   │       └─ conform.lua   | 格式化配置
│  │   ├─ vscode/
│  │   │   ├─ init.lua          | 只加载 core + vscode 配置（不加载 NvChad）
│  │   │   ├─ plugins.lua        | VSCode 特定插件
│  │   │   └─ configs/           | VSCode 特定插件配置
│  │   ├─ firenvim/
│  │   │   ├─ init.lua          | 只加载 core + firenvim 配置（不加载 NvChad）
│  │   │   ├─ plugins.lua        | Firenvim 特定插件
│  │   │   └─ configs/           | Firenvim 特定插件配置
│  │   └─ ... (ssh / tui 等继续扩展)
│  │
│  └─ utils/
│      ├─ init.lua               | 快捷函数、setNodeVersion 等
│      └─ profile.lua            | detect()：返回当前 profile
```

## Architecture Principles

- **`core/`**: 真正通用的配置，不依赖 NvChad，所有 profile 都会加载
- **`plugins/init.lua`**: 所有 profile 都需要的通用插件
- **`profiles/*`**: 每个 profile 独立管理自己的：
  - `plugins.lua`: 该 profile 特定的插件列表
  - `configs/`: 该 profile 特定插件的配置（如 LSP、格式化器等）
  - `options.lua`, `autocmds.lua`, `keymaps.lua`: 该 profile 的配置覆盖
- **加载顺序**:
  1. `core.*`（必须）
  2. `nvchad.*`（可选，如 desktop）
  3. `profiles.{name}.*`（可选，可覆盖/扩展配置）

# Credits

1) Lazyvim starter https://github.com/LazyVim/starter as nvchad's starter was inspired by Lazyvim's . It made a lot of things easier!
