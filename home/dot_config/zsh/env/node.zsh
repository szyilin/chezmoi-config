#!/usr/bin/env zsh
# =============================================================================
# Node.js (nvm) 环境配置 - 懒加载
# =============================================================================

export NVM_DIR="$HOME/.nvm"

# 定义 nvm 加载函数
_load_nvm() {
    load_if_exists "$BREW_HOME/opt/nvm/nvm.sh"
    load_if_exists "$BREW_HOME/opt/nvm/etc/bash_completion.d/nvm"
}

# 懒加载 nvm, node, npm（首次调用时才加载）
lazy_load_command nvm '_load_nvm'
lazy_load_command node '_load_nvm'
lazy_load_command npm '_load_nvm'
