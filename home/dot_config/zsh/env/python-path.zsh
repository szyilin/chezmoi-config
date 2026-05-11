#!/usr/bin/env zsh
# =============================================================================
# Python 基础 PATH 配置（非交互 shell 可用）
# =============================================================================

[[ -n ${__XKD_ZSH_ENV_PYTHON_PATH_LOADED:-} ]] && return
typeset -g __XKD_ZSH_ENV_PYTHON_PATH_LOADED=1

export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"

if [[ -d "$PYENV_ROOT" ]]; then
    add_to_path "$PYENV_ROOT/bin"

    if [[ -r "$PYENV_ROOT/version" ]]; then
        pyenv_default=""
        IFS= read -r pyenv_default < "$PYENV_ROOT/version"
        pyenv_default="${pyenv_default%%[[:space:]]*}"

        if [[ -n "$pyenv_default" ]] && [[ -d "$PYENV_ROOT/versions/$pyenv_default/bin" ]]; then
            add_to_path "$PYENV_ROOT/versions/$pyenv_default/bin"
        fi
    fi
fi
