#!/usr/bin/env zsh
# =============================================================================
# Zsh 配置入口文件
# .zshrc 中只需要一行： [[ -f ~/.config/zsh/init.zsh ]] && source ~/.config/zsh/init.zsh
# =============================================================================

# 获取脚本所在目录的绝对路径
ZSH_CONFIG_DIR="${${(%):-%x}:A:h}"

# 加载 Oh My Zsh 配置
source "$ZSH_CONFIG_DIR/omz.zsh"

# 加载个人配置
source "$ZSH_CONFIG_DIR/config.zsh"
