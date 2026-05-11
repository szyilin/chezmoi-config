#!/usr/bin/env zsh
# =============================================================================
# Node.js 基础 PATH 配置（非交互 shell 可用）
# =============================================================================

[[ -n ${__XKD_ZSH_ENV_NODE_PATH_LOADED:-} ]] && return
typeset -g __XKD_ZSH_ENV_NODE_PATH_LOADED=1

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

_xkd_resolve_nvm_default_bin() {
    local alias_file="$NVM_DIR/alias/default"
    local default_alias=""
    local version_dir=""
    local -a matches=()

    [[ -r "$alias_file" ]] || return 1
    IFS= read -r default_alias < "$alias_file"
    default_alias="${default_alias%%[[:space:]]*}"

    case "$default_alias" in
        ""|system)
            return 1
            ;;
        v*)
            version_dir="$NVM_DIR/versions/node/$default_alias"
            ;;
        *)
            matches=("$NVM_DIR"/versions/node/v${default_alias}*(N))
            if (( ${#matches[@]} > 0 )); then
                version_dir="${matches[-1]}"
            else
                version_dir="$NVM_DIR/versions/node/v$default_alias"
            fi
            ;;
    esac

    [[ -d "$version_dir/bin" ]] || return 1
    printf '%s\n' "$version_dir/bin"
}

if [[ -d "$NVM_DIR/versions/node" ]]; then
    add_to_path "$(_xkd_resolve_nvm_default_bin 2>/dev/null)"
fi
