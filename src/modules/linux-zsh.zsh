#!/usr/bin/env zsh
# =============================================================================
# Linux Zsh 模块 - Linux Zsh Module
# 
# 负责在 Linux 系统上安装和配置 zsh 作为默认 shell
# 这是 Linux 环境下的第一优先级模块，确保后续操作在 zsh 环境下进行
# =============================================================================

##
# 检查是否需要执行 Linux zsh 配置
##
linux-zsh_check() {
    log_debug "检查 Linux zsh 环境..."
    
    # 平台检查 - 只在 Linux 系统执行
    if ! is_linux; then
        log_debug "跳过 linux-zsh 模块: 非 Linux 系统"
        return 1  # 跳过执行
    fi
    
    # 检查当前执行环境
    if [[ -n "${ZSH_VERSION:-}" ]]; then
        log_debug "已在 zsh 环境中执行，无需处理"
        return 1  # 跳过执行
    fi
    
    # 检查 zsh 是否已安装
    if ! command_exists zsh; then
        log_info "需要安装 zsh"
        return 0  # 需要执行
    fi
    
    # 检查用户的默认 shell 是否已经是 zsh
    if [[ "$SHELL" == *"zsh" ]]; then
        # 用户默认 shell 是 zsh，但当前在非 zsh 环境执行
        # 只需要切换环境，不需要重新配置
        log_info "用户默认 shell 已是 zsh，仅需切换执行环境"
        export LINUX_ZSH_ONLY_SWITCH=true
        return 0  # 需要执行（但只是切换环境）
    fi
    
    # 检查 zsh 是否在 /etc/shells 中
    local zsh_path="$(which zsh)"
    if ! grep -q "^$zsh_path$" /etc/shells 2>/dev/null; then
        log_info "需要将 zsh 添加到 /etc/shells"
        return 0  # 需要执行
    fi
    
    # 检查 .zshrc 文件是否存在
    local user_home="$HOME"
    if [[ -n "$SUDO_USER" ]]; then
        user_home="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
    fi
    
    if [[ ! -f "$user_home/.zshrc" ]]; then
        log_info "需要创建 .zshrc 文件"
        return 0  # 需要执行
    fi
    
    log_debug "Linux zsh 环境已正确配置"
    return 1  # 跳过执行
}

##
# 执行 Linux zsh 安装和配置
##
linux-zsh_install() {
    # 检查是否只需要切换环境
    if [[ "${LINUX_ZSH_ONLY_SWITCH:-false}" == "true" ]]; then
        log_info "用户默认 shell 已是 zsh，切换到 zsh 环境"
        
        # 确保 .zshrc 存在 (避免 zsh 首次启动向导)
        _ensure_zshrc_exists_quick
        
        # 直接切换环境
        restart_in_new_environment "linux-zsh" "zsh"
        return 0
    fi
    
    log_info "开始配置 Linux zsh 环境..."
    
    # 1. 安装 zsh (如果未安装)
    if ! command_exists zsh; then
        if ! _install_zsh; then
            log_error "zsh 安装失败"
            return 1
        fi
    else
        log_info "zsh 已安装: $(zsh --version | head -n1)"
    fi
    
    # 2. 将 zsh 添加到 /etc/shells (如果需要)
    if ! _ensure_zsh_in_shells; then
        log_error "无法将 zsh 添加到 /etc/shells"
        return 1
    fi
    
    # 3. 设置 zsh 为默认 shell (如果需要)
    if ! _set_zsh_as_default; then
        log_error "无法设置 zsh 为默认 shell"
        return 1
    fi
    
    # 4. 确保 .zshrc 文件存在
    if ! _ensure_zshrc_exists; then
        log_error "无法创建 .zshrc 文件"
        return 1
    fi
    
    # 5. 如果当前不是 zsh 环境，切换到 zsh 继续执行
    if [[ -z "${ZSH_VERSION:-}" ]]; then
        # 使用通用的环境管理策略 - 重大环境变化需要进程重启
        restart_in_new_environment "linux-zsh" "zsh"
    fi
    
    log_success "Linux zsh 环境配置完成"
    return 0
}

##
# 验证 Linux zsh 配置
##
linux-zsh_verify() {
    log_debug "验证 Linux zsh 配置..."
    
    # 验证 zsh 已安装
    if ! command_exists zsh; then
        log_error "验证失败: zsh 未安装"
        return 1
    fi
    
    # 验证 zsh 在 /etc/shells 中
    local zsh_path="$(which zsh)"
    if ! grep -q "^$zsh_path$" /etc/shells 2>/dev/null; then
        log_error "验证失败: zsh 不在 /etc/shells 中"
        return 1
    fi
    
    # 验证当前 shell 环境
    if [[ "$SHELL" == *"zsh" ]]; then
        log_success "zsh 已设置为默认 shell: $SHELL"
    else
        log_warn "zsh 未设置为默认 shell，当前: $SHELL"
        log_info "重新登录后将使用 zsh 作为默认 shell"
    fi
    
    # 验证 .zshrc 文件
    local user_home="$HOME"
    if [[ -n "$SUDO_USER" ]]; then
        user_home="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
    fi
    
    if [[ -f "$user_home/.zshrc" ]]; then
        log_success ".zshrc 文件存在: $user_home/.zshrc"
    else
        log_error "验证失败: .zshrc 文件不存在"
        return 1
    fi
    
    # 显示版本信息
    local zsh_version="$(zsh --version 2>/dev/null || echo 'unknown')"
    log_info "zsh 版本: $zsh_version"
    
    log_success "Linux zsh 配置验证通过"
    return 0
}

# =============================================================================
# 内部辅助函数
# =============================================================================

##
# 安装 zsh
##
_install_zsh() {
    log_info "安装 zsh..."
    
    local pkg_manager="$(get_package_manager)"
    
    case "$pkg_manager" in
        "apt")
            log_info "使用 apt 安装 zsh..."
            if ! sudo apt-get update >/dev/null 2>&1; then
                log_warn "apt 更新失败，继续安装"
            fi
            sudo apt-get install -y zsh
            ;;
        "yum")
            log_info "使用 yum 安装 zsh..."
            sudo yum install -y zsh
            ;;
        "dnf")
            log_info "使用 dnf 安装 zsh..."
            sudo dnf install -y zsh
            ;;
        "pacman")
            log_info "使用 pacman 安装 zsh..."
            sudo pacman -S --noconfirm zsh
            ;;
        "unknown")
            log_error "无法识别包管理器，请手动安装 zsh"
            log_info "尝试以下命令之一:"
            log_info "  Ubuntu/Debian: sudo apt-get install zsh"
            log_info "  CentOS/RHEL:   sudo yum install zsh"
            log_info "  Fedora:        sudo dnf install zsh"
            log_info "  Arch:          sudo pacman -S zsh"
            return 1
            ;;
        *)
            log_error "不支持的包管理器: $pkg_manager"
            return 1
            ;;
    esac
    
    # 验证安装
    if command_exists zsh; then
        log_success "zsh 安装成功"
        return 0
    else
        log_error "zsh 安装失败"
        return 1
    fi
}

##
# 确保 zsh 在 /etc/shells 中
##
_ensure_zsh_in_shells() {
    local zsh_path="$(which zsh)"
    
    if [[ -z "$zsh_path" ]]; then
        log_error "无法找到 zsh 可执行文件"
        return 1
    fi
    
    # 检查是否已在 /etc/shells 中
    if grep -q "^$zsh_path$" /etc/shells 2>/dev/null; then
        log_info "zsh 已在 /etc/shells 中: $zsh_path"
        return 0
    fi
    
    log_info "添加 zsh 到 /etc/shells: $zsh_path"
    
    # 添加到 /etc/shells
    if echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null; then
        log_success "已将 zsh 添加到 /etc/shells"
        return 0
    else
        log_error "无法添加 zsh 到 /etc/shells"
        return 1
    fi
}

##
# 设置 zsh 为默认 shell
##
_set_zsh_as_default() {
    local zsh_path="$(which zsh)"
    
    # 检查当前 shell
    if [[ "$SHELL" == *"zsh" ]]; then
        log_info "zsh 已是默认 shell"
        return 0
    fi
    
    log_info "设置 zsh 为默认 shell..."
    
    # 更改默认 shell
    if chsh -s "$zsh_path"; then
        log_success "已设置 zsh 为默认 shell: $zsh_path"
        log_info "重新登录后生效，或运行 'exec zsh' 立即切换"
        return 0
    else
        log_error "无法设置 zsh 为默认 shell"
        log_info "您可以手动运行: chsh -s $zsh_path"
        return 1
    fi
}

##
# 确保 .zshrc 文件存在
##
_ensure_zshrc_exists() {
    local user_home=""
    local user_name=""
    
    # 确定用户主目录和用户名
    if [[ -n "$SUDO_USER" ]]; then
        # 如果是通过 sudo 运行，使用原用户
        user_name="$SUDO_USER"
        user_home="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
    else
        # 直接运行
        user_name="$USER"
        user_home="$HOME"
    fi
    
    local zshrc_path="$user_home/.zshrc"
    
    # 检查 .zshrc 是否存在
    if [[ -f "$zshrc_path" ]]; then
        log_info ".zshrc 文件已存在: $zshrc_path"
        return 0
    fi
    
    log_info "创建空的 .zshrc 文件: $zshrc_path"
    
    # 创建空的 .zshrc 文件
    if [[ -n "$SUDO_USER" ]]; then
        # 使用 sudo 创建并设置正确的所有者
        sudo touch "$zshrc_path" || return 1
        sudo chown "$user_name:$(id -gn "$user_name")" "$zshrc_path" || return 1
        sudo chmod 644 "$zshrc_path" || return 1
    else
        # 直接创建
        touch "$zshrc_path" || return 1
        chmod 644 "$zshrc_path" || return 1
    fi
    
    log_success "已创建空的 .zshrc 文件"
    log_info "避免 zsh 首次启动配置向导"
    
    return 0
}

##
# 快速确保 .zshrc 文件存在 (仅用于环境切换)
##
_ensure_zshrc_exists_quick() {
    local user_home="$HOME"
    if [[ -n "$SUDO_USER" ]]; then
        user_home="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
    fi
    
    local zshrc_path="$user_home/.zshrc"
    
    # 如果 .zshrc 已存在，直接返回
    if [[ -f "$zshrc_path" ]]; then
        log_debug ".zshrc 文件已存在"
        return 0
    fi
    
    log_info "快速创建空的 .zshrc 文件"
    
    # 快速创建空文件
    if [[ -n "$SUDO_USER" ]]; then
        sudo touch "$zshrc_path" && sudo chown "$SUDO_USER:$(id -gn "$SUDO_USER")" "$zshrc_path"
    else
        touch "$zshrc_path"
    fi
    
    log_debug "已创建 .zshrc 文件"
    return 0
}

log_debug "Linux zsh 模块已加载"
