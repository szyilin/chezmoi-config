# Zsh 配置

分层式组织的 Zsh 配置，清晰的依赖关系，易于维护和扩展。

## 目录结构

```txt
~/.config/zsh/
├── init.zsh              # 入口文件（控制加载顺序）
├── core/                 # 核心层（无依赖）
│   ├── platform.zsh     # 平台检测
│   ├── path.zsh         # PATH 管理
│   └── loader.zsh       # 加载机制
├── env/                  # 环境层（依赖 core）
│   ├── base.zsh         # 基础环境
│   ├── homebrew.zsh     # Homebrew
│   ├── node.zsh         # Node.js (nvm 懒加载)
│   ├── python.zsh       # Python (pyenv 懒加载)
│   ├── rust.zsh         # Rust
│   ├── java.zsh         # Java
│   └── editor.zsh       # 编辑器
├── plugins/              # 插件层（依赖 env）
│   └── omz.zsh          # Oh My Zsh
├── shell/                # Shell 层（依赖 plugins）
│   ├── keybindings.zsh  # 键位绑定
│   ├── completions.zsh  # 补全
│   ├── aliases.zsh      # 别名
│   └── functions.zsh    # 用户函数
├── platform/             # 平台特定（依赖 shell）
│   ├── macos.zsh        # macOS 专用
│   └── linux.zsh        # Linux 专用
└── local.zsh            # 本地配置（git ignore）
```

## 加载顺序

1. **core/** - 核心工具（平台检测、PATH 管理、加载机制）
2. **env/** - 环境变量（base → homebrew → 开发工具 → editor）
3. **shell/** - Shell 行为配置
4. **platform/** - 平台特定配置
5. **local.zsh** - 本地配置（可选）
6. **plugins/** - Oh My Zsh 及插件（最后加载，避免干扰环境）

## 依赖关系

```
core (无依赖)
  ↓
env (依赖 core)
  ├─ base (基础)
  ├─ homebrew (依赖 base)
  ├─ node/python/rust/java (依赖 homebrew)
  └─ editor (依赖开发工具)
  ↓
shell (依赖 env)
  ↓
platform (依赖 shell)
  ↓
local (可选)
  ↓
plugins (最后加载，避免干扰)
  └─ omz (Oh My Zsh)
```

## 性能优化

- **PATH 自动去重**：避免重复路径
- **nvm 懒加载**：首次调用 `nvm`/`node`/`npm` 时才加载
- **pyenv 懒加载**：首次调用 `pyenv`/`python` 时才加载
- **平台检测缓存**：避免重复判断操作系统

## 本地配置

复制 `local.zsh.example` 为 `local.zsh` 添加机器特定配置：

```bash
cp local.zsh.example local.zsh
```

`local.zsh` 会被 `.gitignore` 忽略，不会提交到版本控制。

## 添加新工具

在 `env/` 目录添加新文件，然后在 `init.zsh` 中按依赖顺序加载：

```bash
# 1. 创建配置文件
vim env/golang.zsh

# 2. 在 init.zsh 中添加加载语句
source "$ZSH_CONFIG_DIR/env/golang.zsh"
```
