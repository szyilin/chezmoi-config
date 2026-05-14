# Zsh 配置

这套配置保留 zsh 原生的三个启动钩子，但把内部控制面统一到一个入口文件：

- `~/.zshenv`
- `~/.zprofile`
- `~/.zshrc`

它们都只做一件事：把当前 phase 传给 `~/.config/zsh/entry.zsh`。

## 目录结构

```txt
~/.config/zsh/
├── entry.zsh            # 唯一主流程入口
├── core/                # 核心工具（无依赖）
│   ├── loader.zsh
│   ├── path.zsh
│   └── platform.zsh
├── env/                 # 运行时环境
│   ├── base.zsh
│   ├── editor.zsh
│   ├── homebrew.zsh
│   ├── java.zsh
│   ├── node-path.zsh
│   ├── node.zsh
│   ├── python-path.zsh
│   ├── python.zsh
│   └── rust.zsh
├── plugins/             # 插件层
│   └── omz.zsh
├── platform/            # 平台特定交互配置
│   ├── linux.zsh
│   └── macos.zsh
├── shell/               # 交互行为配置
│   ├── aliases.zsh
│   ├── completions.zsh
│   ├── functions.zsh
│   ├── history.zsh
│   ├── keybindings.zsh
│   └── proxy.zsh
└── local.zsh            # 本地覆盖（可选）
```

## 启动顺序

zsh 的生命周期仍然由系统决定：

1. `~/.zshenv`
2. `~/.zprofile`（仅 login shell）
3. `~/.zshrc`（仅 interactive shell）

但内部逻辑始终走同一条主线：`entry.zsh`。

## 主流程

`entry.zsh` 从上到下只表达一条连续的启动叙事：

1. 识别当前 phase
2. 加载所有 shell 共享的最小基础层
3. 如果当前处于 login 阶段，执行 login 修正
4. 如果当前处于 interactive 阶段，加载交互增强
5. 收尾

这样读启动过程时，不需要在多个入口文件之间来回切换。

## Phase 职责

### `zshenv`

所有 zsh 都会进入这个阶段，因此这里只允许放：

- 所有 shell 都需要的基础 PATH
- 运行时环境变量
- 不依赖 TTY / prompt / completion 的轻量逻辑

### `zprofile`

只在 login shell 中执行。当前保留它的唯一原因是：

- macOS 的 `/etc/zprofile` 会运行 `/usr/libexec/path_helper`
- `path_helper` 会把系统默认 PATH 放到前面
- 因此需要在 login 阶段重新扶正 `pyenv` shim 的优先级

### `zshrc`

只在 interactive shell 中执行，用于加载：

- tmux 自动 attach
- `nvm` / `pyenv` 的交互增强
- Oh My Zsh / Powerlevel10k
- completion / alias / keybindings / functions
- 本地交互覆盖

## Python 策略

Python 现在采用混合模式：

- `python` 命令的可用性来自 `python-path.zsh` 里的 `pyenv shims`
- `pyenv` 的完整 shell integration 继续保留，但改成按需懒加载

这样既能让非交互 shell 正确命中项目 Python，又避免每次交互启动都执行 `pyenv init - zsh`。

## 放置原则

- 需要所有 shell 共享的能力：放在 `entry.zsh` 的 shared bootstrap 段中，并拆到 `core/`、`env/` 下实现
- 只属于 login 阶段的修正：放在 `entry.zsh` 的 `zprofile` 分支
- 只属于 interactive 体验的内容：放在 `entry.zsh` 的 `zshrc` 分支
- 复杂实现放模块，执行规则只放在 `entry.zsh`

## 本地配置

复制 `local.zsh.example` 为 `local.zsh` 添加机器特定配置：

```bash
cp local.zsh.example local.zsh
```

`local.zsh` 会被 `.gitignore` 忽略，不会提交到版本控制。
