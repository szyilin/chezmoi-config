#!/usr/bin/env zsh
# =============================================================================
# Wireshark CLI PATH 配置（非交互 shell 可用）
# =============================================================================

[[ -n ${__XKD_ZSH_ENV_WIRESHARK_LOADED:-} ]] && return
typeset -g __XKD_ZSH_ENV_WIRESHARK_LOADED=1

if is_macos; then
    export WIRESHARK_CLI_HOME="/Applications/Wireshark.app/Contents/MacOS"

    if [[ -d "$WIRESHARK_CLI_HOME" ]] \
        && [[ -x "$WIRESHARK_CLI_HOME/tshark" ]] \
        && [[ -x "$WIRESHARK_CLI_HOME/capinfos" ]]; then
        add_to_path "$WIRESHARK_CLI_HOME"
    fi
fi
