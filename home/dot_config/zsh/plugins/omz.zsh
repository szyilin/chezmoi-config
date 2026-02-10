#!/usr/bin/env zsh
# =============================================================================
# Oh My Zsh 配置
# =============================================================================

# 启用 Powerlevel10k 的即时提示功能
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Oh My Zsh 安装路径
export ZSH="$HOME/.oh-my-zsh"

# 设置主题
ZSH_THEME="powerlevel10k/powerlevel10k"

# 加载插件
plugins=(
  git
  colored-man-pages      # man 命令文档自动语法高亮
  zsh-autosuggestions    # 语法补全
  zsh-syntax-highlighting # 语法高亮
)

# 加载 Oh My Zsh
[[ -f $ZSH/oh-my-zsh.sh ]] && source $ZSH/oh-my-zsh.sh

# 加载 Powerlevel10k 配置
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# =============================================================================
# Powerlevel10k 自定义覆盖配置
# =============================================================================
# 执行时间精度：3 = 毫秒级
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_PRECISION=3
# 执行时间阈值：只有超过 0.1 秒才显示
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=0.1
