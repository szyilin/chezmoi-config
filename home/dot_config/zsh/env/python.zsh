#!/usr/bin/env zsh
# =============================================================================
# Python 交互增强（保留 pyenv 懒加载）
# =============================================================================

[[ -n ${__XKD_ZSH_ENV_PYTHON_LOADED:-} ]] && return
typeset -g __XKD_ZSH_ENV_PYTHON_LOADED=1

source "${${(%):-%x}:A:h}/python-path.zsh"

if [[ -d "$PYENV_ROOT" ]] && command -v pyenv >/dev/null 2>&1; then
    eval "$(pyenv init - zsh)"
fi
