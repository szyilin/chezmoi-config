#!/usr/bin/env zsh
# =============================================================================
# 兼容入口文件
# 旧配置仍可 source 本文件，实际会转发到 bootstrap + interactive
# =============================================================================

[[ -n ${__XKD_ZSH_INIT_LOADED:-} ]] && return
typeset -g __XKD_ZSH_INIT_LOADED=1

ZSH_CONFIG_DIR="${${(%):-%x}:A:h}"

source "$ZSH_CONFIG_DIR/init-bootstrap.zsh"

if [[ $- == *i* ]]; then
    source "$ZSH_CONFIG_DIR/init-interactive.zsh"
fi
