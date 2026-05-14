#!/usr/bin/env zsh
# =============================================================================
# Python 交互增强
# python 命令本身依赖 python-path.zsh 中的 shims 立即可用；
# 完整的 pyenv shell integration 仅在真正调用 pyenv 时再加载。
# =============================================================================

[[ -n ${__XKD_ZSH_ENV_PYTHON_LOADED:-} ]] && return
typeset -g __XKD_ZSH_ENV_PYTHON_LOADED=1

if [[ -d "$PYENV_ROOT" ]]; then
    _load_pyenv() {
        eval "$(pyenv init - zsh)"
    }

    lazy_load_command pyenv '_load_pyenv'
fi
