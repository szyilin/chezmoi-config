#!/usr/bin/env zsh
# =============================================================================
# 编辑器配置
# =============================================================================

# 设置默认编辑器
if command -v nvim >/dev/null 2>&1; then
    export EDITOR=nvim
    export VISUAL=nvim
else
    export EDITOR=vim
    export VISUAL=vim
fi
