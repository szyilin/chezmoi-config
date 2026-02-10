#!/usr/bin/env zsh
# =============================================================================
# Python (pyenv) 环境配置 - 懒加载
# =============================================================================

if [[ -d "$HOME/.pyenv" ]]; then
    export PYENV_ROOT="$HOME/.pyenv"
    add_to_path "$PYENV_ROOT/bin"
    
    # 定义 pyenv 加载函数
    _load_pyenv() {
        eval "$(pyenv init - zsh)"
    }
    
    # 懒加载 pyenv 和 python
    lazy_load_command pyenv '_load_pyenv'
    lazy_load_command python '_load_pyenv'
fi
