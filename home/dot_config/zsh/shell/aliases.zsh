#!/usr/bin/env zsh
# =============================================================================
# 别名配置
# =============================================================================

# 通用别名
alias ll='ls -lF'

# Vim/Neovim 别名
if command -v nvim &>/dev/null; then
    alias vim='nvim'
    alias vi='nvim'
fi

# Tmux 别名
load_if_command tmux 'alias tmux="tmux -f ~/.config/tmux/tmux.conf"'
