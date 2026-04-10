#!/usr/bin/env zsh
# =============================================================================
# 历史命令配置
# =============================================================================

export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=1000000
export SAVEHIST=1000000

setopt EXTENDED_HISTORY
setopt APPEND_HISTORY
setopt SHARE_HISTORY

# 保留唯一命令，避免历史文件和内存历史中充满重复项。
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_SPACE
