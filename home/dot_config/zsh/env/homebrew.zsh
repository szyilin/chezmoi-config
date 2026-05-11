#!/usr/bin/env zsh
# =============================================================================
# Homebrew 环境配置
# =============================================================================

[[ -n ${__XKD_ZSH_ENV_HOMEBREW_LOADED:-} ]] && return
typeset -g __XKD_ZSH_ENV_HOMEBREW_LOADED=1

# Homebrew 路径（根据平台自动选择）
if is_macos; then
    export BREW_HOME="/opt/homebrew"
elif is_linux; then
    export BREW_HOME="/home/linuxbrew/.linuxbrew"
fi

# 添加 Homebrew 到 PATH
[[ -n "$BREW_HOME" ]] && add_to_path "$BREW_HOME/bin"
