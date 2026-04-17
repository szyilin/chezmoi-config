#!/usr/bin/env zsh
# =============================================================================
# Homebrew 模块 - Homebrew Module
# 
# 负责在 macOS 和 Linux 系统上安装和配置 Homebrew 包管理器
# 基于 Homebrew 官方安装脚本，支持自动化安装
# =============================================================================

##
# 检查是否需要执行 Homebrew 安装
##
homebrew_check() {
    log_debug "检查 Homebrew 环境..."
    
    # 严格检查 Homebrew 是否已安装 (多重验证确保幂等性)
    local homebrew_installed=false
    
    # 1. 检查当前用户是否可以访问 Homebrew
    local homebrew_paths=()
    if is_macos; then
        homebrew_paths=("/opt/homebrew" "/usr/local")
    elif is_linux; then
        homebrew_paths=("/home/linuxbrew/.linuxbrew")
    fi
    
    for prefix in "${homebrew_paths[@]}"; do
        # 检查 brew 可执行文件和基本目录结构
        if [[ -x "$prefix/bin/brew" ]] && [[ -d "$prefix/lib" ]] && [[ -d "$prefix/bin" ]]; then
            # 检查当前用户是否可以执行 brew
            if "$prefix/bin/brew" --version >/dev/null 2>&1; then
                log_debug "发现可用的 Homebrew 安装: $prefix"
                homebrew_installed=true
                
                # 立即加载到当前环境
                if eval "$($prefix/bin/brew shellenv)" 2>/dev/null; then
                    log_debug "Homebrew 环境已加载到当前进程"
                fi
                break
            else
                log_debug "发现 Homebrew 但当前用户无法访问: $prefix"
            fi
        fi
    done
    
    # 2. 如果检测到 Homebrew 已安装，跳过重复安装
    if [[ "$homebrew_installed" == "true" ]]; then
        # 尝试加载环境并验证命令
        local brew_available=false
        
        if command_exists brew; then
            brew_available=true
            log_debug "brew 命令已在当前环境中"
        else
            log_debug "brew 命令不在当前环境中，尝试加载..."
            if _ensure_brew_in_current_env; then
                brew_available=true
                log_debug "brew 环境已加载到当前进程"
            fi
        fi
        
        if [[ "$brew_available" == "true" ]]; then
            local brew_version="$(brew --version 2>/dev/null | head -n1 || echo 'unknown')"
            log_info "Homebrew 已安装并配置: $brew_version"
        else
            log_info "Homebrew 已安装，但当前进程尚未加载环境"
        fi
        
        log_info "跳过重复安装"
        return 1  # 跳过执行
    fi
    
    log_info "需要安装 Homebrew 包管理器"
    return 0  # 需要执行
}

##
# 执行 Homebrew 安装
##
homebrew_install() {
    log_info "开始安装 Homebrew 包管理器..."
    
    # 1. 检查系统兼容性
    if ! _check_system_compatibility; then
        log_error "系统兼容性检查失败"
        return 1
    fi
    
    # 2. 尝试开启代理加速 (如果可用) - 使用 core.zsh 提供的通用函数
    local proxy_enabled=false
    if try_enable_proxy; then
        proxy_enabled=true
        log_info "已开启代理加速下载"
    fi
    
    # 3. 执行官方安装脚本
    if ! _run_homebrew_installer; then
        log_error "Homebrew 安装失败"
        return 1
    fi
    
    # 4. 配置环境变量
    if ! _setup_homebrew_environment; then
        log_error "Homebrew 环境配置失败"
        return 1
    fi
    
    # 5. 验证安装并加载到当前环境
    if ! _verify_and_load_homebrew; then
        log_error "Homebrew 验证或加载失败"
        return 1
    fi
    
    # 6. 关闭代理 (如果之前开启了) - 使用 core.zsh 提供的通用函数
    if [[ "$proxy_enabled" == "true" ]]; then
        try_disable_proxy
        log_info "已关闭代理"
    fi
    
    # 7. 使用环境管理策略 - Homebrew 是轻量级环境变化，使用环境重载
    refresh_environment "homebrew"
    
    log_success "Homebrew 安装配置完成"
    log_info "brew 命令可在当前脚本和后续模块中使用"
    return 0
}

##
# 验证 Homebrew 安装
##
homebrew_verify() {
    log_debug "验证 Homebrew 安装..."
    
    # 验证 brew 命令可用性
    if ! command_exists brew; then
        log_error "验证失败: brew 命令不可用"
        return 1
    fi
    
    # 验证 brew 版本
    local brew_version="$(brew --version 2>/dev/null | head -n1)"
    if [[ -n "$brew_version" ]]; then
        log_success "Homebrew 版本: $brew_version"
    else
        log_error "验证失败: 无法获取 brew 版本"
        return 1
    fi
    
    # 验证 brew 环境
    local brew_prefix="$(brew --prefix 2>/dev/null)"
    if [[ -n "$brew_prefix" ]]; then
        log_success "Homebrew 安装路径: $brew_prefix"
    else
        log_error "验证失败: 无法获取 brew 安装路径"
        return 1
    fi
    
    # 验证平台特定配置
    if is_macos; then
        if [[ "$brew_prefix" == "/opt/homebrew" ]] || [[ "$brew_prefix" == "/usr/local" ]]; then
            log_success "macOS Homebrew 路径正确"
        else
            log_warn "非标准 macOS Homebrew 路径: $brew_prefix"
        fi
    elif is_linux; then
        if [[ "$brew_prefix" == "/home/linuxbrew/.linuxbrew" ]]; then
            log_success "Linux Homebrew 路径正确"
        else
            log_warn "非标准 Linux Homebrew 路径: $brew_prefix"
        fi
    fi
    
    log_success "Homebrew 验证通过"
    return 0
}

# =============================================================================
# 内部辅助函数
# =============================================================================

##
# 检查系统兼容性
##
_check_system_compatibility() {
    log_info "检查系统兼容性..."
    
    if is_macos; then
        log_info "当前系统支持 Homebrew: macOS"
        log_info "安装过程中可能需要管理员权限"
        
        # 检查 macOS 版本 (可选)
        local macos_version="$(sw_vers -productVersion 2>/dev/null || echo 'unknown')"
        log_debug "macOS 版本: $macos_version"
        
    elif is_linux; then
        log_info "当前系统支持 Homebrew: Linux"
        
        # 检查必要工具
        local missing_tools=()
        if ! command_exists curl; then
            missing_tools+=("curl")
        fi
        if ! command_exists git; then
            missing_tools+=("git")
        fi
        
        if [[ ${#missing_tools[@]} -gt 0 ]]; then
            log_error "缺少必要工具: ${missing_tools[*]}"
            log_info "请先安装: sudo apt-get install ${missing_tools[*]} (Ubuntu)"
            return 1
        fi
        
    else
        log_error "不支持的操作系统，Homebrew 仅支持 macOS 和 Linux"
        return 1
    fi
    
    return 0
}

# 注: 代理管理函数已移至 core.zsh 中，使用 try_enable_proxy() 和 try_disable_proxy()

##
# 执行 Homebrew 官方安装脚本
##
_run_homebrew_installer() {
    log_info "执行 Homebrew 官方安装脚本..."
    
    # 确保在有效的工作目录中执行
    local safe_dir="$HOME"
    [[ ! -d "$PWD" ]] && cd "$safe_dir"
    
    # 根据权限情况设置模式
    if /usr/bin/sudo -n true 2>/dev/null; then
        # 有无密码 sudo，可以使用非交互模式
        export NONINTERACTIVE=1
        export CI=1
        log_debug "使用非交互模式 (无密码 sudo)"
    else
        # 需要密码，使用交互模式但设置自动确认
        export NONINTERACTIVE=""
        export CI=""
        log_debug "使用交互模式 (需要密码确认)"
        log_info "安装过程中可能需要输入管理员密码"
    fi
    
    # 执行官方安装脚本
    log_debug "当前工作目录: $(pwd)"
    if (cd "$safe_dir" && /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"); then
        log_success "Homebrew 官方安装脚本执行完成"
        return 0
    else
        log_error "Homebrew 官方安装脚本执行失败"
        return 1
    fi
}

##
# 配置 Homebrew 环境变量
##
_setup_homebrew_environment() {
    log_info "配置 Homebrew 环境变量..."
    
    # 确定 Homebrew 安装路径
    local homebrew_prefix=""
    if is_macos; then
        # macOS 路径检测
        if [[ -x "/opt/homebrew/bin/brew" ]]; then
            homebrew_prefix="/opt/homebrew"
        elif [[ -x "/usr/local/bin/brew" ]]; then
            homebrew_prefix="/usr/local"
        fi
    elif is_linux; then
        # Linux 路径
        if [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
            homebrew_prefix="/home/linuxbrew/.linuxbrew"
        fi
    fi
    
    if [[ -z "$homebrew_prefix" ]]; then
        log_error "无法确定 Homebrew 安装路径"
        return 1
    fi
    
    log_info "Homebrew 安装路径: $homebrew_prefix"
    
    # 配置 shell 环境文件
    local shell_configs=()
    [[ -f "$HOME/.bashrc" ]] && shell_configs+=("$HOME/.bashrc")
    [[ -f "$HOME/.zshrc" ]] && shell_configs+=("$HOME/.zshrc")
    
    local shellenv_command="eval \"\$($homebrew_prefix/bin/brew shellenv)\""
    
    for config_file in "${shell_configs[@]}"; do
        if ! grep -q "brew shellenv" "$config_file" 2>/dev/null; then
            echo "" >> "$config_file"
            echo "# Homebrew environment setup" >> "$config_file"
            echo "$shellenv_command" >> "$config_file"
            log_info "已写入环境配置: $config_file"
        else
            log_debug "brew shellenv 已存在于 $config_file"
        fi
    done
    
    return 0
}

##
# 验证并加载 Homebrew 到当前环境
##
_verify_and_load_homebrew() {
    log_info "验证并加载 Homebrew 到当前环境..."
    
    # 确定 Homebrew 路径
    local homebrew_prefix=""
    if is_macos; then
        if [[ -x "/opt/homebrew/bin/brew" ]]; then
            homebrew_prefix="/opt/homebrew"
        elif [[ -x "/usr/local/bin/brew" ]]; then
            homebrew_prefix="/usr/local"
        fi
    elif is_linux; then
        if [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
            homebrew_prefix="/home/linuxbrew/.linuxbrew"
        fi
    fi
    
    if [[ -z "$homebrew_prefix" ]]; then
        log_error "Homebrew 安装验证失败"
        return 1
    fi
    
    # 立即加载 Homebrew 环境到当前进程
    log_debug "加载 Homebrew 环境: $homebrew_prefix"
    
    # 确保在有效目录中执行
    local current_dir="$PWD"
    if [[ ! -d "$current_dir" ]]; then
        log_debug "当前目录无效，切换到 HOME"
        cd "$HOME" || cd /
    fi
    
    # 执行 shellenv 并捕获输出
    local shellenv_output=""
    if shellenv_output="$($homebrew_prefix/bin/brew shellenv 2>/dev/null)"; then
        log_debug "Homebrew shellenv 输出获取成功"
        
        # 应用环境变量
        if eval "$shellenv_output"; then
            log_success "Homebrew 环境已加载到当前进程"
        else
            log_warn "Homebrew 环境变量应用失败"
            return 1
        fi
    else
        log_error "无法获取 Homebrew shellenv 输出"
        return 1
    fi
    
    # 验证 brew 命令现在可用
    if command_exists brew; then
        local brew_version="$(brew --version 2>/dev/null | head -n1 || echo 'unknown')"
        log_success "brew 命令现在可用: $brew_version"
        return 0
    else
        log_error "brew 命令仍不可用，可能需要重新加载 shell"
        log_info "可手动执行: eval \"\$($homebrew_prefix/bin/brew shellenv)\""
        return 1
    fi
}

##
# 确保 brew 命令在当前环境中可用 (用于已安装的情况)
##
_ensure_brew_in_current_env() {
    # 如果 brew 已经可用，无需处理
    if command_exists brew; then
        return 0
    fi
    
    log_debug "尝试加载 Homebrew 环境到当前进程..."
    
    # 尝试不同的 Homebrew 路径
    local homebrew_paths=()
    if is_macos; then
        homebrew_paths=("/opt/homebrew" "/usr/local")
    elif is_linux; then
        homebrew_paths=("/home/linuxbrew/.linuxbrew")
    fi
    
    for prefix in "${homebrew_paths[@]}"; do
        if [[ -x "$prefix/bin/brew" ]]; then
            log_debug "找到 Homebrew: $prefix"
            if eval "$($prefix/bin/brew shellenv)" 2>/dev/null; then
                log_debug "Homebrew 环境已加载"
                return 0
            fi
        fi
    done
    
    log_debug "无法加载 Homebrew 环境到当前进程"
    return 1
}

log_debug "Homebrew 模块已加载"
