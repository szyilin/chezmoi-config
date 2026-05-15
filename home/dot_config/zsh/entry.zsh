#!/usr/bin/env zsh
# =============================================================================
# Zsh 统一入口
# 由 ~/.zshenv / ~/.zprofile / ~/.zshrc 作为薄 wrapper 调入，并传入 phase。
# 本文件从上到下描述完整启动流程，让启动叙事保持连续：
# 1. 识别上下文
# 2. 加载所有 shell 共享的最小基础层
# 3. 在 login 阶段修正 macOS PATH
# 4. 在 interactive 阶段加载交互增强
# 5. 收尾（例如启动耗时打印）
# =============================================================================

typeset -g __XKD_ZSH_ENTRY_DIR="${${(%):-%x}:A:h}"
typeset -g __XKD_ZSH_PHASE="${1:-${__XKD_ZSH_PHASE:-}}"

[[ -n "$__XKD_ZSH_PHASE" ]] || return 0

_xkd_zsh_source() {
    local file="$1"
    [[ -f "$file" ]] && source "$file"
}

_xkd_zsh_bootstrap_shared() {
    [[ -n ${__XKD_ZSH_SHARED_BOOTSTRAP_DONE:-} ]] && return
    typeset -g __XKD_ZSH_SHARED_BOOTSTRAP_DONE=1

    _xkd_zsh_source "$__XKD_ZSH_ENTRY_DIR/core/platform.zsh"
    _xkd_zsh_source "$__XKD_ZSH_ENTRY_DIR/core/path.zsh"
    _xkd_zsh_source "$__XKD_ZSH_ENTRY_DIR/core/loader.zsh"

    _xkd_zsh_source "$__XKD_ZSH_ENTRY_DIR/env/base.zsh"
    _xkd_zsh_source "$__XKD_ZSH_ENTRY_DIR/env/homebrew.zsh"
    _xkd_zsh_source "$__XKD_ZSH_ENTRY_DIR/env/wireshark.zsh"
    _xkd_zsh_source "$__XKD_ZSH_ENTRY_DIR/env/node-path.zsh"
    _xkd_zsh_source "$__XKD_ZSH_ENTRY_DIR/env/python-path.zsh"
    _xkd_zsh_source "$__XKD_ZSH_ENTRY_DIR/env/rust.zsh"
    _xkd_zsh_source "$__XKD_ZSH_ENTRY_DIR/env/java.zsh"
    _xkd_zsh_source "$__XKD_ZSH_ENTRY_DIR/env/editor.zsh"
}

_xkd_zsh_run_zshenv() {
    [[ -n ${__XKD_ZSH_PHASE_ZSHENV_DONE:-} ]] && return
    typeset -g __XKD_ZSH_PHASE_ZSHENV_DONE=1

    if [[ -z ${__XKD_ZSH_BOOT_START:-} ]]; then
        zmodload zsh/datetime
        typeset -g __XKD_ZSH_BOOT_START=$EPOCHREALTIME
    fi

    _xkd_zsh_bootstrap_shared
}

_xkd_zsh_run_zprofile() {
    [[ -n ${__XKD_ZSH_PHASE_ZPROFILE_DONE:-} ]] && return
    typeset -g __XKD_ZSH_PHASE_ZPROFILE_DONE=1

    _xkd_zsh_bootstrap_shared

    if is_macos; then
        unset __XKD_ZSH_ENV_PYTHON_PATH_LOADED
        _xkd_zsh_source "$__XKD_ZSH_ENTRY_DIR/env/python-path.zsh"
    fi
}

_xkd_zsh_run_zshrc() {
    [[ $- == *i* ]] || return 0
    [[ -n ${__XKD_ZSH_PHASE_ZSHRC_DONE:-} ]] && return
    typeset -g __XKD_ZSH_PHASE_ZSHRC_DONE=1

    _xkd_zsh_bootstrap_shared

    if [[ -t 1 ]] && [[ -z "$TMUX" ]] && [[ "$TERM_PROGRAM" == "iTerm.app" ]]; then
        command tmux attach -t ${tmux_session:-main} || command tmux new -s ${tmux_session:-main} -n def
    fi

    _xkd_zsh_source "$__XKD_ZSH_ENTRY_DIR/env/node.zsh"
    _xkd_zsh_source "$__XKD_ZSH_ENTRY_DIR/env/python.zsh"

    _xkd_zsh_source "$__XKD_ZSH_ENTRY_DIR/plugins/omz.zsh"
    _xkd_zsh_source "$__XKD_ZSH_ENTRY_DIR/shell/history.zsh"
    _xkd_zsh_source "$__XKD_ZSH_ENTRY_DIR/shell/keybindings.zsh"
    _xkd_zsh_source "$__XKD_ZSH_ENTRY_DIR/shell/completions.zsh"
    _xkd_zsh_source "$__XKD_ZSH_ENTRY_DIR/shell/aliases.zsh"
    _xkd_zsh_source "$__XKD_ZSH_ENTRY_DIR/shell/proxy.zsh"
    _xkd_zsh_source "$__XKD_ZSH_ENTRY_DIR/shell/functions.zsh"

    if is_macos; then
        _xkd_zsh_source "$__XKD_ZSH_ENTRY_DIR/platform/macos.zsh"
    elif is_linux; then
        _xkd_zsh_source "$__XKD_ZSH_ENTRY_DIR/platform/linux.zsh"
    fi

    _xkd_zsh_source "$__XKD_ZSH_ENTRY_DIR/local.zsh"

    if [[ -n "${__XKD_ZSH_BOOT_START:-}" ]]; then
        zmodload zsh/datetime
        typeset -g __XKD_ZSH_BOOT_END=$EPOCHREALTIME
        printf "Block cost: %.4f seconds\n" "$(( __XKD_ZSH_BOOT_END - __XKD_ZSH_BOOT_START ))"
    fi
}

case "$__XKD_ZSH_PHASE" in
    zshenv)
        _xkd_zsh_run_zshenv
        ;;
    zprofile)
        _xkd_zsh_run_zprofile
        ;;
    zshrc)
        _xkd_zsh_run_zshrc
        ;;
esac
