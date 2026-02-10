#!/usr/bin/env zsh
# =============================================================================
# macOS 专用配置
# =============================================================================

# rm 命令替换为 trash（如果 trash 命令存在）
if command -v trash &>/dev/null; then
    alias rm-real='/bin/rm'
    
    rm() {
        local files=()
        
        # 只收集不是以 - 开头的参数
        for arg in "$@"; do
            if [[ "$arg" != -* ]]; then
                files+=("$arg")
            fi
        done
        
        if [[ ${#files[@]} -eq 0 ]]; then
            echo "⚠️  未检测到有效的文件路径（所有参数均为选项）"
            return 1
        fi
        
        # 调用 trash 删除
        command trash "${files[@]}"
    }
fi
