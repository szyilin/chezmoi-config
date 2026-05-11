#!/usr/bin/env zsh
# =============================================================================
# PATH 管理工具
# =============================================================================

[[ -n ${__XKD_ZSH_CORE_PATH_LOADED:-} ]] && return
typeset -g __XKD_ZSH_CORE_PATH_LOADED=1

# 自动去重 PATH
typeset -U path

# 添加目录到 PATH 开头（如果目录存在）
add_to_path() {
    local dir="$1"
    [[ -d "$dir" ]] && path=("$dir" $path)
}

# 添加目录到 PATH 末尾（如果目录存在）
append_to_path() {
    local dir="$1"
    [[ -d "$dir" ]] && path+=("$dir")
}

# 添加目录到 PATH 并可选导出环境变量
add_dir_with_env() {
    local dir="$1"
    local var_name="$2"  # 可选：环境变量名
    
    if [[ -d "$dir" ]]; then
        [[ -n "$var_name" ]] && export "$var_name"="$dir"
        append_to_path "$dir/bin"
        return 0
    fi
    return 1
}
