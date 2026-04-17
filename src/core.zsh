#!/usr/bin/env zsh
# =============================================================================
# 核心功能库 - Core Library
# 
# 包含所有基础功能：平台检测、日志系统、工具函数、用户界面
# =============================================================================

# 避免重复加载
[[ -n "${CORE_LOADED:-}" ]] && return 0
readonly CORE_LOADED=1

# =============================================================================
# 基础常量
# =============================================================================

# 系统类型
readonly OS_DARWIN="Darwin"
readonly OS_LINUX="Linux"

# 退出码
readonly EXIT_SUCCESS=0
readonly EXIT_FAILURE=1

# 颜色代码
readonly COLOR_RESET='\033[0m'
readonly COLOR_RED='\033[91m'
readonly COLOR_GREEN='\033[92m'
readonly COLOR_YELLOW='\033[93m'
readonly COLOR_BLUE='\033[94m'
readonly COLOR_MAGENTA='\033[95m'
readonly COLOR_CYAN='\033[96m'
readonly COLOR_BOLD='\033[1m'

# 全局变量
CURRENT_OS=""

# =============================================================================
# 平台检测
# =============================================================================

##
# 检测操作系统
##
detect_os() {
    if [[ -n "$CURRENT_OS" ]]; then
        echo "$CURRENT_OS"
        return 0
    fi
    
    case "$(uname -s)" in
        Darwin*) CURRENT_OS="$OS_DARWIN" ;;
        Linux*) CURRENT_OS="$OS_LINUX" ;;
        *) CURRENT_OS="Unknown" ;;
    esac
    
    echo "$CURRENT_OS"
}

##
# 获取系统架构
##
get_architecture() {
    uname -m
}

##
# 检查是否为 macOS
##
is_macos() {
    [[ "$(detect_os)" == "$OS_DARWIN" ]]
}

##
# 检查是否为 Linux
##
is_linux() {
    [[ "$(detect_os)" == "$OS_LINUX" ]]
}

##
# 获取 Linux 包管理器
##
get_package_manager() {
    if ! is_linux; then
        echo "none"
        return 1
    fi
    
    if command_exists apt; then
        echo "apt"
    elif command_exists yum; then
        echo "yum"
    elif command_exists pacman; then
        echo "pacman"
    elif command_exists dnf; then
        echo "dnf"
    else
        echo "unknown"
    fi
}

# =============================================================================
# 工具函数
# =============================================================================

##
# 检查命令是否存在
##
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

##
# 检查是否有 sudo 权限
##
has_sudo() {
    [[ $EUID -eq 0 ]] || sudo -n true 2>/dev/null
}

##
# 检查网络连接
##
check_network() {
    local timeout="${1:-5}"
    ping -c 1 -W "$timeout" 8.8.8.8 >/dev/null 2>&1
}

##
# 获取时间戳
##
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

##
# 获取资源文件路径
##
get_resource_path() {
    local resource_name="$1"
    echo "$CHEZMOI_PROJECT_ROOT/resources/$resource_name"
}

# =============================================================================
# 日志系统
# =============================================================================

##
# 彩色输出
##
print_colored() {
    local color="$1"
    local text="$2"
    local bold="${3:-false}"
    
    if [[ -t 1 && "${TERM:-}" != "dumb" ]]; then
        local style=""
        [[ "$bold" == "true" ]] && style="$COLOR_BOLD"
        echo -e "${style}${color}${text}${COLOR_RESET}"
    else
        echo "$text"
    fi
}

##
# 日志函数
##
log_info() {
    print_colored "$COLOR_BLUE" "[INFO] $*"
}

log_success() {
    print_colored "$COLOR_GREEN" "[ OK ] $*" true
}

log_warn() {
    print_colored "$COLOR_YELLOW" "[WARN] $*"
}

log_error() {
    print_colored "$COLOR_RED" "[ERR ] $*" true
}

log_debug() {
    if [[ "${DEBUG:-false}" == "true" ]]; then
        echo "[DEBUG] $*" >&2
    fi
    return 0
}

log_step() {
    local step="$1"
    local total="$2"
    local message="$3"
    print_colored "$COLOR_CYAN" "[$step/$total] $message" true
}

log_header() {
    local title="$*"
    echo
    print_colored "$COLOR_MAGENTA" "$(printf '=%.0s' {1..60})" true
    print_colored "$COLOR_MAGENTA" "  $title" true
    print_colored "$COLOR_MAGENTA" "$(printf '=%.0s' {1..60})" true
    echo
}

# =============================================================================
# 用户界面
# =============================================================================

##
# 显示横幅
##
show_banner() {
    local title="$1"
    local version="$2"
    
    echo
    echo "$(printf '=%.0s' {1..80})"
    printf "%*s\n" $(((${#title} + 80) / 2)) "$title"
    [[ -n "$version" ]] && printf "%*s\n" $(((${#version} + 80) / 2)) "版本 $version"
    echo "$(printf '=%.0s' {1..80})"
    echo
}

##
# 显示摘要信息
##
show_summary() {
    local title="$1"
    shift
    
    log_header "$title"
    
    for item in "$@"; do
        if [[ "$item" == *:* ]]; then
            local key="${item%%:*}"
            local value="${item#*:}"
            printf "  %-20s: %s\n" "$key" "$value"
        fi
    done
    echo
}

##
# 询问是否继续
##
ask_yes_no() {
    local prompt="$1"
    local default="${2:-}"
    
    # 默认自动确认，除非明确要求手动确认
    if [[ "${MANUAL_CONFIRM:-false}" != "true" ]]; then
        log_info "$prompt [auto: yes]"
        return 0
    fi
    
    local choice
    while true; do
        if [[ -n "$default" ]]; then
            case "$default" in
                y|Y) printf "[?] %s [Y/n]: " "$prompt" ;;
                n|N) printf "[?] %s [y/N]: " "$prompt" ;;
                *) printf "[?] %s [y/n]: " "$prompt" ;;
            esac
        else
            printf "[?] %s [y/n]: " "$prompt"
        fi
        
        read -r choice
        
        [[ -z "$choice" && -n "$default" ]] && choice="$default"
        
        case "$choice" in
            [Yy]|[Yy][Ee][Ss]) return 0 ;;
            [Nn]|[Nn][Oo]) return 1 ;;
            *) echo "请输入 y 或 n" ;;
        esac
    done
}

##
# 显示/隐藏光标
##
show_cursor() { 
    printf '\033[?25h'
}

hide_cursor() { 
    printf '\033[?25l'
}

# =============================================================================
# 模块接口验证
# =============================================================================

##
# 验证模块是否实现了标准接口
##
validate_module_interface() {
    local module="$1"
    
    # 检查必需函数是否存在
    if ! declare -f "${module}_check" >/dev/null; then
        log_error "模块 $module 缺少 ${module}_check() 函数"
        return 1
    fi
    
    if ! declare -f "${module}_install" >/dev/null; then
        log_error "模块 $module 缺少 ${module}_install() 函数"
        return 1
    fi
    
    log_debug "模块 $module 接口验证通过"
    return 0
}

# =============================================================================
# 代理管理 (带连接测试和保底机制)
# =============================================================================

##
# 测试代理连接是否正常
##
test_proxy_connection() {
    # 测试是否能通过代理连接到 GitHub API
    # 使用短超时时间，避免长时间等待
    if curl -sSf --connect-timeout 5 --max-time 10 https://api.github.com >/dev/null 2>&1; then
        log_debug "代理连接测试成功 (GitHub API 可达)"
        return 0
    fi
    
    # 如果 GitHub API 失败，尝试 raw.githubusercontent.com (Oh My Zsh 下载需要)
    if curl -sSf --connect-timeout 5 --max-time 10 https://raw.githubusercontent.com >/dev/null 2>&1; then
        log_debug "代理连接测试成功 (raw.githubusercontent.com 可达)"
        return 0
    fi
    
    # 如果 GitHub 都失败，尝试其他常见站点
    if curl -sSf --connect-timeout 5 --max-time 10 https://www.google.com >/dev/null 2>&1; then
        log_debug "代理连接测试成功 (Google 可达)"
        return 0
    fi
    
    log_debug "代理连接测试失败 (无法连接到测试站点)"
    return 1
}

##
# 尝试开启代理加速 (带保底机制)
##
try_enable_proxy() {
    # 检查是否有 clash 代理可用
    if ! declare -f clashon >/dev/null; then
        log_debug "未检测到可用的代理"
        return 1
    fi
    
    log_debug "检测到 clash 代理，尝试开启..."
    
    # 保存原始环境变量 (保底措施)
    local original_http_proxy="$http_proxy"
    local original_https_proxy="$https_proxy"
    local original_all_proxy="$all_proxy"
    
    # 尝试开启代理
    if ! clashon 2>/dev/null; then
        log_debug "代理开启失败 (clashon 命令执行失败)"
        return 1
    fi
    
    # 验证代理是否真的工作 (保底措施：测试实际连接)
    log_debug "验证代理连接..."
    if ! test_proxy_connection; then
        log_warn "⚠️  代理连接测试失败，恢复原始网络环境"
        
        # 恢复原始环境变量
        export http_proxy="$original_http_proxy"
        export https_proxy="$original_https_proxy"
        export all_proxy="$original_all_proxy"
        
        # 如果原始环境是空的，则 unset
        [[ -z "$original_http_proxy" ]] && unset http_proxy
        [[ -z "$original_https_proxy" ]] && unset https_proxy
        [[ -z "$original_all_proxy" ]] && unset all_proxy
        
        log_info "💡 已恢复原始网络环境，将使用直连方式下载"
        return 1
    fi
    
    log_debug "代理连接测试通过"
    return 0
}

##
# 尝试关闭代理
##
try_disable_proxy() {
    if declare -f clashoff >/dev/null; then
        clashoff 2>/dev/null || true
    fi
}

# =============================================================================
# 环境管理策略 (混合策略)
# =============================================================================

##
# 重启脚本到新环境 - 用于重大环境变化
##
restart_in_new_environment() {
    local trigger_module="$1"
    local target_shell="${2:-zsh}"
    
    log_info "🔄 $trigger_module 完成，切换到 $target_shell 环境继续执行后续模块..."
    
    # 构建重启命令参数
    local restart_args=("--continue-after=$trigger_module")
    
    # 传递用户原始选择的模块，如果为空则让 runner 使用默认模块
    if [[ -n "${INSTALLER_ORIGINAL_MODULES:-}" ]]; then
        # 有指定模块，传递给新进程
        restart_args+=($INSTALLER_ORIGINAL_MODULES)
    fi
    # 如果没有指定模块，不传递任何模块参数，让 runner 使用默认模块
    
    log_debug "重启命令: $target_shell $CHEZMOI_PROJECT_ROOT/install.zsh ${restart_args[*]}"
    
    # 重启脚本
    exec "$target_shell" "$CHEZMOI_PROJECT_ROOT/install.zsh" "${restart_args[@]}"
}

##
# 环境重载 - 用于轻量级环境变化
##
refresh_environment() {
    local trigger_module="$1"
    
    log_info "🔄 重载环境配置 (触发模块: $trigger_module)"
    
    case "$trigger_module" in
        "homebrew")
            # 重载 Homebrew 环境
            if [[ -x "/opt/homebrew/bin/brew" ]]; then
                eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || true
                log_debug "已重载 Homebrew 环境 (macOS)"
            elif [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
                eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" 2>/dev/null || true
                log_debug "已重载 Homebrew 环境 (Linux)"
            fi
            ;;
        "oh-my-zsh")
            # 重载 Oh My Zsh 环境
            if [[ -f "$HOME/.zshrc" ]]; then
                source "$HOME/.zshrc" 2>/dev/null || true
                log_debug "已重载 .zshrc 配置"
            fi
            ;;
        *)
            # 通用环境重载
            if [[ -f "$HOME/.zshrc" ]]; then
                source "$HOME/.zshrc" 2>/dev/null || true
                log_debug "已重载 .zshrc 配置"
            fi
            ;;
    esac
    
    log_success "✅ 环境重载完成"
    return 0
}

# =============================================================================
# 初始化
# =============================================================================

log_debug "核心库已加载 ($(get_timestamp))"
