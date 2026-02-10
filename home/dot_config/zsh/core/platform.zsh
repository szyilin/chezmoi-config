#!/usr/bin/env zsh
# =============================================================================
# 平台检测工具
# =============================================================================

# 平台检测缓存（避免重复判断）
_platform_cache=""

# 检测是否为 macOS
is_macos() {
    [[ -z "$_platform_cache" ]] && _platform_cache="$OSTYPE"
    [[ "$_platform_cache" == darwin* ]]
}

# 检测是否为 Linux
is_linux() {
    [[ -z "$_platform_cache" ]] && _platform_cache="$OSTYPE"
    [[ "$_platform_cache" == linux* ]]
}
