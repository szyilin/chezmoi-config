#!/usr/bin/env zsh
# =============================================================================
# Chezmoi 环境初始化工具 v3.0.0
# 
# 简化的高质量 dotfiles 环境自动化部署工具
# =============================================================================

# 版本信息
readonly INSTALLER_VERSION="3.0.0"
readonly INSTALLER_NAME="Chezmoi Environment Installer"

# 获取脚本目录
readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 设置项目根目录
export CHEZMOI_PROJECT_ROOT="$SCRIPT_DIR"

# 加载核心库
if ! source "$SCRIPT_DIR/src/core.zsh"; then
    echo "致命错误: 无法加载核心库" >&2
    exit 1
fi

# 加载模块执行器
if ! source "$SCRIPT_DIR/src/runner.zsh"; then
    echo "致命错误: 无法加载模块执行器" >&2
    exit 1
fi

# =============================================================================
# CLI 处理
# =============================================================================

show_help() {
    cat << EOF
$INSTALLER_NAME v$INSTALLER_VERSION

用法: ./install.zsh [选项] [模块...]

选项:
  -h, --help              显示帮助信息
  -v, --version           显示版本信息
  --list                  列出可用模块
  --debug                 启用调试模式
  --confirm               启用手动确认模式

模块:
  linux-zsh               Linux zsh 环境配置
  linux-clash             Linux clash 代理配置
  homebrew                Homebrew 包管理器
  oh-my-zsh               Oh My Zsh 终端美化

示例:
  ./install.zsh                   完整安装 (自动确认)
  ./install.zsh --confirm         完整安装 (手动确认)
  ./install.zsh homebrew          只安装 Homebrew
  ./install.zsh --debug           调试模式安装
EOF
}

show_version() {
    echo "$INSTALLER_NAME v$INSTALLER_VERSION"
    echo "系统: $(detect_os) $(get_architecture)"
}

# =============================================================================
# 主程序
# =============================================================================

main() {
    local specified_modules=()
    
    # 保存原始模块参数供环境切换使用
    export INSTALLER_ORIGINAL_MODULES=""
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help) show_help; exit 0 ;;
            -v|--version) show_version; exit 0 ;;
            --list) list_modules; exit 0 ;;
            --debug) export DEBUG=true ;;
            --confirm) export MANUAL_CONFIRM=true ;;
            --continue-after=*) 
                # 续传参数：从指定模块之后开始执行
                local continue_after="${1#--continue-after=}"
                export INSTALLER_CONTINUE_AFTER="$continue_after"
                log_debug "设置续传标记: 从 $continue_after 之后开始"
                ;;
            -*) 
                log_error "未知选项: $1"
                echo "使用 $0 --help 查看帮助"
                exit 1
                ;;
            *)
                specified_modules+=("$1")
                ;;
        esac
        shift
    done
    
    # 保存用户指定的模块列表
    INSTALLER_ORIGINAL_MODULES="${specified_modules[*]}"
    
    # 显示启动信息
    show_banner "$INSTALLER_NAME" "$INSTALLER_VERSION"
    show_summary "系统信息" \
        "操作系统:$(detect_os)" \
        "架构:$(get_architecture)" \
        "项目根目录:$CHEZMOI_PROJECT_ROOT"
    
    # 执行安装
    if run_modules "${specified_modules[@]}"; then
        echo
        log_success "🎉 安装完成!"
        log_info "建议: 重启终端或运行 'exec zsh' 使配置生效"
        return 0
    else
        echo
        log_error "❌ 安装失败"
        log_info "提示: 使用 --debug 查看详细日志"
        return 1
    fi
}

# 清理和启动
cleanup() {
    show_cursor 2>/dev/null || true
}

trap cleanup EXIT INT TERM

# 确保在有效的工作目录中
if [[ ! -d "$SCRIPT_DIR" ]]; then
    echo "错误: 脚本目录不存在: $SCRIPT_DIR" >&2
    exit 1
fi

cd "$SCRIPT_DIR" || exit 1

main "$@"
