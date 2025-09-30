# Chezmoi 环境初始化工具

🚀 一键部署 dotfiles 和开发环境的自动化工具

## 快速开始

```bash
# 完整安装（默认自动确认）
./install.zsh

# 手动确认每个步骤
./install.zsh --confirm

# 只安装特定模块
./install.zsh homebrew oh-my-zsh
```

## 核心特性

- **模块化架构** - 所有功能封装为独立模块，支持选择性安装
- **跨平台支持** - 自动适配 macOS 和 Linux（apt/yum/pacman）
- **幂等性设计** - 可重复执行，自动跳过已完成配置
- **代理加速** - 智能检测并使用 Clash 代理加速下载
- **环境管理** - 自动处理 Shell 环境更新，无需手动重载

## 可用模块

| 模块 | 说明 | 平台 |
|------|------|------|
| `linux-zsh` | Zsh 环境配置 | Linux |
| `linux-clash` | Clash 代理配置 | Linux |
| `homebrew` | Homebrew 包管理器 | 全平台 |
| `homebrew-init` | Homebrew 软件包安装 | 全平台 |
| `chezmoi-setup` | Chezmoi 配置管理 | 全平台 |
| `oh-my-zsh` | 终端美化 | 全平台 |

## 命令选项

```bash
./install.zsh [选项] [模块...]

选项:
  -h, --help      显示帮助
  -v, --version   显示版本
  --list          列出可用模块
  --debug         调试模式
  --confirm       手动确认模式
```

## 项目结构

```
chezmoi/
├── install.zsh           # 主入口
├── src/
│   ├── core.zsh         # 核心功能（日志、平台检测、代理管理）
│   ├── runner.zsh       # 模块调度器
│   └── modules/         # 功能模块
│       ├── *.zsh        # 跨平台模块
│       └── linux-*.zsh  # Linux 专用模块
├── resources/           # 配置资源
└── home/                # Dotfiles
```

## 开发指南

### 新增模块

在 `src/modules/` 创建 `模块名.zsh`，实现以下接口：

```zsh
# 必需：检查是否需要执行（返回 0=需要执行, 1=跳过）
模块名_check() {
    # 检查平台适配和安装状态
}

# 必需：执行安装逻辑（返回 0=成功, 1=失败）
模块名_install() {
    # 实现安装逻辑
}

# 可选：验证安装结果
模块名_verify() {
    # 验证安装是否成功
}
```

### 架构原则

- **模块独立** - 所有功能必须封装为模块，禁止例外
- **统一接口** - 所有模块使用 `check/install/verify` 标准接口
- **简洁优先** - 避免过度设计，保持代码简单清晰
- **跨平台兼容** - 使用 bash 兼容的 zsh 语法

## 常见问题

**Q: 安装失败怎么办？**  
A: 重新运行 `./install.zsh`，已完成的模块会自动跳过

**Q: 如何只更新某个模块？**  
A: 运行 `./install.zsh 模块名`，如 `./install.zsh oh-my-zsh`

**Q: 支持哪些 Linux 发行版？**  
A: 支持 Ubuntu/Debian (apt)、CentOS/RHEL (yum)、Arch (pacman) 等主流发行版

## 许可证

MIT License - 个人使用工具，简洁为上 ⚡
