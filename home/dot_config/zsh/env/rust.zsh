#!/usr/bin/env zsh
# =============================================================================
# Rust 环境配置
# =============================================================================

[[ -n ${__XKD_ZSH_ENV_RUST_LOADED:-} ]] && return
typeset -g __XKD_ZSH_ENV_RUST_LOADED=1

# 加载 Rust 环境
load_if_exists "$HOME/.cargo/env"
