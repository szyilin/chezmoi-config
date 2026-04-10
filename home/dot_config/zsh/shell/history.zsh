#!/usr/bin/env zsh
# =============================================================================
# 历史命令配置
# =============================================================================

# 历史文件路径，所有会话最终都会把命令写入这个文件。
export HISTFILE="$HOME/.zsh_history"

# 当前 shell 进程内存中最多保留多少条历史命令，值越大越不容易在当前会话里丢失旧记录。
export HISTSIZE=1000000

# 写入历史文件时最多持久化多少条记录，决定重启终端后还能检索到多少历史命令。
export SAVEHIST=1000000

# 以 `: 时间戳:耗时;命令` 的格式保存历史，便于保留执行时间等元信息。
setopt EXTENDED_HISTORY

# 退出 shell 时将新历史追加到历史文件末尾，而不是整文件覆盖。
setopt APPEND_HISTORY

# 在多个终端之间共享历史记录，让新命令尽快出现在其他 shell 的历史中。
setopt SHARE_HISTORY

# 如果新命令和上一条完全相同，则忽略这次记录，避免连续重复刷屏。
setopt HIST_IGNORE_DUPS

# 如果某条命令再次出现，删除旧副本并只保留最新这一条，实现全局去重。
setopt HIST_IGNORE_ALL_DUPS

# 写入历史文件时不保存重复命令，进一步减少历史文件中的重复项。
setopt HIST_SAVE_NO_DUPS

# 当历史达到上限需要裁剪时，优先删除重复命令，把空间留给唯一命令。
setopt HIST_EXPIRE_DUPS_FIRST

# 以空格开头的命令不进入历史，适合临时命令或不想保存的敏感输入。
setopt HIST_IGNORE_SPACE
