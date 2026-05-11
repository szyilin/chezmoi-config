# Zsh 配置

分层式组织的 Zsh 配置，清晰的依赖关系，易于维护和扩展。

## 目录结构

```txt
~/.config/zsh/
├── init-bootstrap.zsh    # 所有 zsh 场景共享的基础入口
├── init-interactive.zsh  # 仅交互式 shell 的增量入口
├── core/                 # 核心层（无依赖）
│   ├── platform.zsh     # 平台检测
│   ├── path.zsh         # PATH 管理
│   └── loader.zsh       # 加载机制
├── env/                  # 环境层（依赖 core）
│   ├── base.zsh         # 基础环境
│   ├── homebrew.zsh     # Homebrew
│   ├── node-path.zsh    # Node.js 基础 PATH（非交互 shell 可用）
│   ├── node.zsh         # Node.js 交互增强（nvm 懒加载）
│   ├── python-path.zsh  # Python 基础 PATH（非交互 shell 可用）
│   ├── python.zsh       # Python 交互增强（pyenv 懒加载）
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

## 入口职责

- `~/.zshenv` -> `init-bootstrap.zsh`
- `~/.zshrc` -> `init-interactive.zsh`

## 加载顺序

1. **init-bootstrap.zsh**
2. **core/** - 核心工具（平台检测、PATH 管理、加载机制）
3. **env/** - 共享基础环境（base → homebrew → node-path/python-path → rust/java → editor）
4. **init-interactive.zsh**
5. **env/node.zsh + env/python.zsh** - 交互式懒加载增强
6. **plugins/** - Oh My Zsh 及插件
7. **shell/** - Shell 行为配置
8. **platform/** - 平台特定配置
9. **local.zsh** - 本地交互覆盖（可选）

## 依赖关系

```
init-bootstrap
  ↓
core (无依赖)
  ↓
env shared base (依赖 core)
  ├─ base (基础)
  ├─ homebrew (依赖 base)
  ├─ node-path/python-path (提供非交互 PATH 可用性)
  ├─ rust/java
  └─ editor
  ↓
init-interactive
  ├─ node/python (交互懒加载)
  ├─ plugins
  ↓
shell (依赖 env)
  ↓
platform (依赖 shell)
  ↓
local (可选)
```

## 性能优化

- **PATH 自动去重**：避免重复路径
- **基础命令前置可用**：`node`/`npm`/`python` 在非交互 shell 中也能通过 PATH 找到
- **nvm 懒加载**：交互式 shell 首次调用 `nvm` 时才加载完整 shell 集成
- **pyenv 懒加载**：交互式 shell 首次调用 `pyenv` 时才加载完整 shell 集成
- **平台检测缓存**：避免重复判断操作系统
- **共享模块 guard**：重复 source 时直接 return，减少双入口副作用

## 放置原则

- 放进 `init-bootstrap.zsh` 的内容：
  所有 shell 都需要，且重复执行必须安全。典型包括 PATH、基础环境变量、平台探测、默认编辑器、语言运行时基础路径。
- 放进 `init-interactive.zsh` 的内容：
  只对交互体验有价值，或者依赖 TTY / prompt / completion / ZLE。典型包括 OMZ、p10k、keybindings、completion、alias、tmux 自动 attach、本地交互覆盖。
- 不要在 `init-interactive.zsh` 里重复 source `init-bootstrap.zsh` 的模块：
  交互 shell 已经先经过 `.zshenv`，这里只允许加载 delta。
- 需要在两个阶段都被引用的共享模块：
  模块自身必须加 guard，并保持幂等。

## 重复加载与副作用控制

- 交互式 zsh 的真实顺序是：先 `.zshenv`，后 `.zshrc`。
- 因此共享基础层默认会先执行一次，交互层只允许做增量，不做共享初始化重放。
- `init-interactive.zsh` 开头会先检查当前 shell 是否交互；如果不是，会直接 `return`，防止误把 OMZ、compinit、tmux 等逻辑带进脚本环境。
- `init-bootstrap.zsh`、`init-interactive.zsh` 以及核心共享模块都带 guard，因此重复 source 也只会短路返回。
- `node/npm/python` 的命令可用性来自 `node-path.zsh` / `python-path.zsh`，不依赖交互懒加载，所以 bootstrap 先执行不会妨碍后续交互层继续挂载 `nvm` / `pyenv` 的 shell 集成。

## 本地配置

复制 `local.zsh.example` 为 `local.zsh` 添加机器特定配置：

```bash
cp local.zsh.example local.zsh
```

`local.zsh` 会被 `.gitignore` 忽略，不会提交到版本控制。

## 添加新工具

在 `env/` 目录添加新文件后，根据职责接入：

```bash
# 1. 创建配置文件
vim env/golang.zsh

# 2. 如果是所有 shell 都需要的基础能力，接到 init-bootstrap.zsh
# 3. 如果只属于交互体验，接到 init-interactive.zsh
```
