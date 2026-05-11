#!/usr/bin/env zsh
# =============================================================================
# 编辑器配置
# =============================================================================

[[ -n ${__XKD_ZSH_ENV_EDITOR_LOADED:-} ]] && return
typeset -g __XKD_ZSH_ENV_EDITOR_LOADED=1

# 设置默认编辑器
if command -v nvim >/dev/null 2>&1; then
    export EDITOR=nvim
    export VISUAL=nvim
else
    export EDITOR=vim
    export VISUAL=vim
fi
