#!/usr/bin/env zsh
# =============================================================================
# Zsh 交互入口
# 只负责 interactive delta：
# - 不重复执行 init-bootstrap.zsh 里的共享基础逻辑
# - 不在非交互 shell 中生效
# - 可以依赖 prompt / completion / ZLE / TTY
# =============================================================================

[[ $- == *i* ]] || return 0

[[ -n ${__XKD_ZSH_INIT_INTERACTIVE_LOADED:-} ]] && return
typeset -g __XKD_ZSH_INIT_INTERACTIVE_LOADED=1

ZSH_CONFIG_DIR="${${(%):-%x}:A:h}"

# .zshenv 理论上会先加载 init-bootstrap。这里只在兼容旧入口时兜底。
if [[ -z ${__XKD_ZSH_INIT_BOOTSTRAP_LOADED:-} ]]; then
    source "$ZSH_CONFIG_DIR/init-bootstrap.zsh"
fi

# -----------------------------------------------------------------------------
# 交互式自动启动逻辑
# 保持旧配置的触发条件与执行时机：尽早进入 tmux，避免后续交互组件干扰。
# 显式使用 command 绕过后续 alias 污染。
# -----------------------------------------------------------------------------
if [[ -t 1 ]] && [[ $- == *i* ]] && [[ -z "$TMUX" ]] && [[ "$TERM_PROGRAM" == "iTerm.app" ]]; then
    command tmux attach -t ${tmux_session:-main} || command tmux new -s ${tmux_session:-main} -n def
fi

# -----------------------------------------------------------------------------
# 交互式开发工具初始化
# 这里只保留需要 shell 集成的增强逻辑；基础 PATH 已由 bootstrap 提供。
# -----------------------------------------------------------------------------
source "$ZSH_CONFIG_DIR/env/node.zsh"
source "$ZSH_CONFIG_DIR/env/python.zsh"

# -----------------------------------------------------------------------------
# 交互式体验层
# -----------------------------------------------------------------------------
source "$ZSH_CONFIG_DIR/plugins/omz.zsh"
source "$ZSH_CONFIG_DIR/shell/history.zsh"
source "$ZSH_CONFIG_DIR/shell/keybindings.zsh"
source "$ZSH_CONFIG_DIR/shell/completions.zsh"
source "$ZSH_CONFIG_DIR/shell/aliases.zsh"
source "$ZSH_CONFIG_DIR/shell/proxy.zsh"
source "$ZSH_CONFIG_DIR/shell/functions.zsh"

# -----------------------------------------------------------------------------
# 平台特定交互配置
# -----------------------------------------------------------------------------
if is_macos; then
    source "$ZSH_CONFIG_DIR/platform/macos.zsh"
elif is_linux; then
    source "$ZSH_CONFIG_DIR/platform/linux.zsh"
fi

# -----------------------------------------------------------------------------
# 本地覆盖（保留在交互层，避免脚本环境引入未知副作用）
# -----------------------------------------------------------------------------
[[ -f "$ZSH_CONFIG_DIR/local.zsh" ]] && source "$ZSH_CONFIG_DIR/local.zsh"
