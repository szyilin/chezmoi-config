#!/usr/bin/env zsh
# =============================================================================
# 基础环境变量配置
# =============================================================================

# 基础路径
export LOCAL_HOME="$HOME/.local"
add_to_path "$LOCAL_HOME/bin"

# XDG 规范路径
export XDG_CONFIG_HOME="${HOME}/.config"
export XDG_CACHE_HOME="${HOME}/.cache"
export XDG_DATA_HOME="${HOME}/.local/share"
