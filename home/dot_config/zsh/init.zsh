#!/usr/bin/env zsh
# =============================================================================
# Zsh 配置入口文件
# .zshrc 中只需要一行： [[ -f ~/.config/zsh/init.zsh ]] && source ~/.config/zsh/init.zsh
# =============================================================================

# 获取脚本所在目录的绝对路径
ZSH_CONFIG_DIR="${${(%):-%x}:A:h}"

# =============================================================================
# 分层架构配置
# =============================================================================

# -----------------------------------------------------------------------------
# 第一层：核心工具（无依赖，必须最先加载）
# -----------------------------------------------------------------------------
source "$ZSH_CONFIG_DIR/core/platform.zsh"
source "$ZSH_CONFIG_DIR/core/path.zsh"
source "$ZSH_CONFIG_DIR/core/loader.zsh"

# -----------------------------------------------------------------------------
# 第二层：环境变量（依赖 core，按依赖顺序显式加载）
# -----------------------------------------------------------------------------
# 基础环境（必须最先）
source "$ZSH_CONFIG_DIR/env/base.zsh"

# Homebrew（其他工具依赖它）
source "$ZSH_CONFIG_DIR/env/homebrew.zsh"

# 开发工具（依赖 Homebrew）
source "$ZSH_CONFIG_DIR/env/node.zsh"      # Node.js (nvm 懒加载)
source "$ZSH_CONFIG_DIR/env/python.zsh"    # Python (pyenv 懒加载)
source "$ZSH_CONFIG_DIR/env/rust.zsh"      # Rust
source "$ZSH_CONFIG_DIR/env/java.zsh"      # Java (macOS only)

# 编辑器配置（依赖开发工具）
source "$ZSH_CONFIG_DIR/env/editor.zsh"

# -----------------------------------------------------------------------------
# 第三层：插件（依赖环境变量）
# -----------------------------------------------------------------------------
source "$ZSH_CONFIG_DIR/plugins/omz.zsh"

# -----------------------------------------------------------------------------
# 第四层：Shell 配置（依赖插件）
# -----------------------------------------------------------------------------
source "$ZSH_CONFIG_DIR/shell/keybindings.zsh"
source "$ZSH_CONFIG_DIR/shell/completions.zsh"
source "$ZSH_CONFIG_DIR/shell/aliases.zsh"
source "$ZSH_CONFIG_DIR/shell/functions.zsh"

# -----------------------------------------------------------------------------
# 第五层：平台特定配置（依赖 Shell 配置）
# -----------------------------------------------------------------------------
if is_macos; then
    source "$ZSH_CONFIG_DIR/platform/macos.zsh"
elif is_linux; then
    source "$ZSH_CONFIG_DIR/platform/linux.zsh"
fi

# -----------------------------------------------------------------------------
# 第六层：本地配置（可选，最后加载以便覆盖任何配置）
# -----------------------------------------------------------------------------
[[ -f "$ZSH_CONFIG_DIR/local.zsh" ]] && source "$ZSH_CONFIG_DIR/local.zsh"
