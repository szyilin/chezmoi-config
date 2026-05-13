#!/usr/bin/env zsh
# =============================================================================
# Python 基础 PATH 配置（非交互 shell 可用）
# =============================================================================

[[ -n ${__XKD_ZSH_ENV_PYTHON_PATH_LOADED:-} ]] && return
typeset -g __XKD_ZSH_ENV_PYTHON_PATH_LOADED=1

export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"

if [[ -d "$PYENV_ROOT" ]]; then
    path=("$PYENV_ROOT/shims" ${path:#$PYENV_ROOT/shims})
    path=("$PYENV_ROOT/bin" ${path:#$PYENV_ROOT/bin})
fi
