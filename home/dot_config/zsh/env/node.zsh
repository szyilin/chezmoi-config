#!/usr/bin/env zsh
# =============================================================================
# Node.js 交互增强（保留 nvm 懒加载）
# =============================================================================

[[ -n ${__XKD_ZSH_ENV_NODE_LOADED:-} ]] && return
typeset -g __XKD_ZSH_ENV_NODE_LOADED=1

source "${${(%):-%x}:A:h}/node-path.zsh"

# 定义 nvm 加载函数
_load_nvm() {
    load_if_exists "$BREW_HOME/opt/nvm/nvm.sh"
    load_if_exists "$BREW_HOME/opt/nvm/etc/bash_completion.d/nvm"
}

# 懒加载 nvm 本体；node/npm 由 node-path.zsh 直接提供
lazy_load_command nvm '_load_nvm'
