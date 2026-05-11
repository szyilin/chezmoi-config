#!/usr/bin/env zsh
# =============================================================================
# 加载机制工具
# =============================================================================

[[ -n ${__XKD_ZSH_CORE_LOADER_LOADED:-} ]] && return
typeset -g __XKD_ZSH_CORE_LOADER_LOADED=1

# 文件存在时加载
load_if_exists() {
    local file="$1"
    [[ -f "$file" ]] && source "$file" 2>/dev/null
}

# 命令存在时执行
load_if_command() {
    local cmd="$1"
    shift
    command -v "$cmd" >/dev/null 2>&1 && eval "$@"
}

# 命令存在时执行并 source 其输出
load_if_command_source_result() {
    local cmd="$1"
    shift
    command -v "$cmd" >/dev/null 2>&1 && source <("$cmd" "$@")
}

# 懒加载命令（用于 nvm, pyenv 等重量级工具）
lazy_load_command() {
    local cmd="$1"
    local load_func="$2"
    
    eval "$cmd() {
        unset -f $cmd
        $load_func
        $cmd \"\$@\"
    }"
}
