#!/usr/bin/env zsh
# =============================================================================
# 键位绑定配置
# =============================================================================

# 启用 Vim 模式
bindkey -v

# 插入模式下恢复 Ctrl 系列快捷键（保持 Emacs 行编辑体验）
bindkey -M viins '^A' beginning-of-line
bindkey -M viins '^E' end-of-line
bindkey -M viins '^F' forward-char
bindkey -M viins '^B' backward-char
bindkey -M viins '^K' kill-line
bindkey -M viins '^U' backward-kill-line
bindkey -M viins '^W' backward-kill-word
bindkey -M viins '^H' backward-delete-char
bindkey -M viins '^D' delete-char
bindkey -M viins '^N' down-line-or-history
bindkey -M viins '^P' up-line-or-history
