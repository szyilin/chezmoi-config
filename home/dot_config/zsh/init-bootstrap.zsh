#!/usr/bin/env zsh
# =============================================================================
# Zsh 共享基础入口
# 所有 zsh 场景都可安全加载：interactive / non-interactive / login / script
# 这里只放所有 shell 都需要的能力，且必须满足：
# - 安静：不输出内容
# - 幂等：重复 source 不产生副作用
# - 非交互安全：不依赖 TTY / prompt / ZLE / completion
# =============================================================================

[[ -n ${__XKD_ZSH_INIT_BOOTSTRAP_LOADED:-} ]] && return
typeset -g __XKD_ZSH_INIT_BOOTSTRAP_LOADED=1

ZSH_CONFIG_DIR="${${(%):-%x}:A:h}"

# -----------------------------------------------------------------------------
# 核心工具（无依赖，必须最先加载）
# -----------------------------------------------------------------------------
source "$ZSH_CONFIG_DIR/core/platform.zsh"
source "$ZSH_CONFIG_DIR/core/path.zsh"
source "$ZSH_CONFIG_DIR/core/loader.zsh"

# -----------------------------------------------------------------------------
# 共享基础环境（要求安静、快速、无交互副作用）
# -----------------------------------------------------------------------------
source "$ZSH_CONFIG_DIR/env/base.zsh"
source "$ZSH_CONFIG_DIR/env/homebrew.zsh"
source "$ZSH_CONFIG_DIR/env/node-path.zsh"
source "$ZSH_CONFIG_DIR/env/python-path.zsh"
source "$ZSH_CONFIG_DIR/env/rust.zsh"
source "$ZSH_CONFIG_DIR/env/java.zsh"
source "$ZSH_CONFIG_DIR/env/editor.zsh"
