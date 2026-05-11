#!/usr/bin/env zsh
# =============================================================================
# Python 交互增强（保留 pyenv 懒加载）
# =============================================================================

[[ -n ${__XKD_ZSH_ENV_PYTHON_LOADED:-} ]] && return
typeset -g __XKD_ZSH_ENV_PYTHON_LOADED=1

source "${${(%):-%x}:A:h}/python-path.zsh"

if [[ -d "$PYENV_ROOT" ]]; then
    # 定义 pyenv 加载函数
    _load_pyenv() {
        eval "$(pyenv init - zsh)"
    }

    # 懒加载 pyenv 本体；python/pip 由 python-path.zsh 直接提供
    lazy_load_command pyenv '_load_pyenv'
fi
