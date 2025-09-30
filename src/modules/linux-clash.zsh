#!/usr/bin/env zsh
# =============================================================================
# Linux Clash 模块 - Linux Clash Module
# 
# 负责在 Linux 系统上安装和配置 clash/mihomo 代理环境
# 基于 nelvko/clash-for-linux-install 项目，但避免进程替换问题
# =============================================================================

##
# 检查是否需要执行 Linux clash 配置
##
linux-clash_check() {
    log_debug "检查 Linux clash 环境..."
    
    # 平台检查 - 只在 Linux 系统执行
    if ! is_linux; then
        log_debug "跳过 linux-clash 模块: 非 Linux 系统"
        return 1  # 跳过执行
    fi
    
    # 检查是否已安装 clash (严格检查，确保幂等性)
    local clash_installed=false
    
    # 1. 检查安装目录
    if [[ -d "/opt/clash" ]]; then
        log_debug "发现 clash 安装目录: /opt/clash"
        
        # 2. 检查核心文件
        if [[ -x "/opt/clash/bin/mihomo" ]] || [[ -x "/opt/clash/bin/clash" ]]; then
            log_debug "发现 clash 核心文件"
            
            # 3. 检查配置文件 (关键检查)
            if [[ -f "/opt/clash/config.yaml" ]]; then
                log_debug "发现 clash 配置文件"
                
                # 4. 检查系统服务
                local service_name="mihomo"
                [[ -x "/opt/clash/bin/clash" ]] && service_name="clash"
                
                if systemctl list-unit-files | grep -q "$service_name.service"; then
                    log_debug "发现 clash 系统服务: $service_name"
                    clash_installed=true
                fi
            fi
        fi
    fi
    
    # 5. 检查 shell 集成 (函数或命令)
    if [[ "$clash_installed" == "true" ]]; then
        # 确保 clash 函数在当前环境中可用 (关键：为后续模块提供代理功能)
        if ! declare -f clashctl >/dev/null; then
            if [[ -f "/opt/clash/script/common.sh" ]] && [[ -f "/opt/clash/script/clashctl.sh" ]]; then
                log_info "加载现有的 clash 函数到当前环境..."
                if source "/opt/clash/script/common.sh" 2>/dev/null && source "/opt/clash/script/clashctl.sh" 2>/dev/null; then
                    log_success "✅ clash 函数已加载，后续模块可使用代理功能"
                else
                    log_warn "⚠️  clash 函数加载失败，后续模块无法直接使用代理"
                fi
            fi
        else
            log_debug "clash 函数已在当前环境中"
        fi
        
        # 验证关键函数可用性
        if declare -f clashon >/dev/null; then
            log_info "💡 后续模块可使用: clashon (开启代理), clashoff (关闭代理)"
        fi
        
        log_info "✅ clash 已完整安装并配置，跳过重复安装"
        log_info "💡 如需重新配置，请先手动卸载: sudo bash /opt/clash/script/uninstall.sh"
        return 1  # 跳过执行
    fi
    
    log_info "需要安装配置 clash 代理环境"
    return 0  # 需要执行
}

##
# 执行 Linux clash 安装和配置
##
linux-clash_install() {
    log_info "开始配置 Linux clash 代理环境..."
    
    # 1. 下载原项目
    if ! _download_clash_installer; then
        log_error "下载 clash 安装脚本失败"
        return 1
    fi
    
    # 2. 修补脚本避免进程替换
    if ! _patch_installer_script; then
        log_error "修补安装脚本失败"
        return 1
    fi
    
    # 3. 执行安装脚本
    if ! _run_clash_installer; then
        log_error "执行 clash 安装脚本失败"
        return 1
    fi
    
    # 4. 加载 clash 函数到当前环境
    if ! _load_clash_functions; then
        log_warn "无法加载 clash 函数，但安装已完成"
    fi
    
    # 5. 清理临时文件
    _cleanup_temp_files
    
    log_success "Linux clash 代理环境配置完成"
    log_info "💡 使用 'clashctl' 或 'clashon' 命令来控制代理"
    return 0
}

##
# 验证 Linux clash 配置
##
linux-clash_verify() {
    log_debug "验证 Linux clash 配置..."
    
    # 验证安装目录
    if [[ ! -d "/opt/clash" ]]; then
        log_error "验证失败: clash 安装目录不存在"
        return 1
    fi
    
    # 验证核心组件 (默认安装 mihomo 内核)
    local kernel_found=false
    if [[ -x "/opt/clash/bin/mihomo" ]]; then
        log_success "✅ mihomo 内核已安装"
        kernel_found=true
    elif [[ -x "/opt/clash/bin/clash" ]]; then
        log_success "✅ clash 内核已安装"
        kernel_found=true
    fi
    
    if [[ "$kernel_found" != "true" ]]; then
        log_error "验证失败: 未找到 clash/mihomo 内核"
        return 1
    fi
    
    # 验证配置文件
    if [[ -f "/opt/clash/config.yaml" ]]; then
        log_success "✅ 配置文件存在"
    else
        log_warn "⚠️  配置文件不存在，可能需要手动配置"
    fi
    
    # 验证命令可用性
    local functions_available=false
    
    # 检查函数是否在当前环境中可用
    if declare -f clashctl >/dev/null && declare -f clashon >/dev/null; then
        log_success "✅ clash 函数在当前环境中可用"
        functions_available=true
    elif command_exists clashctl; then
        log_success "✅ clashctl 命令可用 (通过 PATH)"
        functions_available=true
    else
        log_warn "⚠️  clash 函数不可用，可能需要重新加载 shell"
    fi
    
    if [[ "$functions_available" == "true" ]]; then
        log_info "💡 可用命令: clashon, clashoff, clashui, clashctl, clashtun, clashmixin"
        log_info "💡 Web 控制台: clashui (端口 9090)"
    fi
    
    # 验证系统服务
    local service_name="mihomo"
    [[ -x "/opt/clash/bin/clash" ]] && service_name="clash"
    
    if systemctl is-enabled "$service_name" >/dev/null 2>&1; then
        log_success "✅ 系统服务已配置: $service_name"
    else
        log_warn "⚠️  系统服务未配置"
    fi
    
    log_success "Linux clash 配置验证通过"
    log_info "💡 重新加载 shell 以使用完整功能: source ~/.zshrc"
    return 0
}

# =============================================================================
# 内部辅助函数
# =============================================================================

##
# 下载 clash 安装脚本
##
_download_clash_installer() {
    log_info "下载 clash 安装脚本 (基于 nelvko/clash-for-linux-install)..."
    
    # 检查网络连接
    if ! _check_network_connectivity; then
        log_error "网络连接检查失败"
        return 1
    fi
    
    local temp_dir="/tmp/clash-installer-$$"
    mkdir -p "$temp_dir" || return 1
    
    # 使用项目文档推荐的下载命令
    local download_urls=(
        "https://gh-proxy.com/https://github.com/nelvko/clash-for-linux-install.git"
        "https://github.com/nelvko/clash-for-linux-install.git"
    )
    
    local download_success=false
    for url in "${download_urls[@]}"; do
        log_info "尝试从 $url 下载..."
        
        # 使用项目推荐的参数
        if timeout 60 git clone --branch master --depth 1 "$url" "$temp_dir" 2>/dev/null; then
            download_success=true
            log_success "✅ 下载成功: $url"
            break
        else
            log_warn "下载失败: $url"
            rm -rf "$temp_dir"
            mkdir -p "$temp_dir"
        fi
    done
    
    if [[ "$download_success" != "true" ]]; then
        log_error "所有下载源都失败"
        log_info "可能的解决方案:"
        log_info "  1. 检查网络连接: ping github.com"
        log_info "  2. 手动安装 (推荐命令):"
        log_info "     git clone --branch master --depth 1 https://gh-proxy.com/https://github.com/nelvko/clash-for-linux-install.git \\"
        log_info "       && cd clash-for-linux-install && sudo bash install.sh"
        log_info "  3. 稍后重试: ./install.zsh linux-clash"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # 设置全局变量供其他函数使用
    CLASH_INSTALLER_DIR="$temp_dir"
    
    log_success "✅ clash 安装脚本下载完成"
    return 0
}

##
# 检查网络连接
##
_check_network_connectivity() {
    log_info "检查网络连接..."
    
    # 检查基本网络连接
    if ! ping -c 1 -W 5 8.8.8.8 >/dev/null 2>&1; then
        log_error "基本网络连接失败"
        return 1
    fi
    
    # 检查 GitHub 连接
    if ! curl -sSf --connect-timeout 10 https://api.github.com >/dev/null 2>&1; then
        log_warn "GitHub API 连接测试失败，但继续尝试"
    fi
    
    log_info "✅ 网络连接检查完成"
    return 0
}

##
# 修补安装脚本避免进程替换
##
_patch_installer_script() {
    log_info "修补安装脚本..."
    
    local common_script="$CLASH_INSTALLER_DIR/script/common.sh"
    
    if [[ ! -f "$common_script" ]]; then
        log_error "找不到 common.sh 脚本"
        return 1
    fi
    
    # 修补 _quit 函数，移除 exec 调用
    sed -i.bak 's/exec sudo -u "$user" -- "$_SHELL" -i/echo "😼 clash 安装完成，请重新加载 shell 环境"/' "$common_script"
    
    # 修补 _error_quit 函数，移除 exec 调用  
    sed -i.bak2 's/exec $_SHELL -i/echo "😼 发生错误，请检查日志"/' "$common_script"
    
    log_success "✅ 脚本修补完成"
    return 0
}

##
# 执行 clash 安装脚本
##
_run_clash_installer() {
    log_info "执行 clash 安装脚本..."
    
    cd "$CLASH_INSTALLER_DIR" || return 1
    
    # 检查权限
    if [[ $EUID -ne 0 ]] && ! sudo -n true 2>/dev/null; then
        log_info "需要 sudo 权限来安装 clash"
        sudo true || return 1
    fi
    
    # 执行安装脚本
    if sudo bash install.sh; then
        log_success "✅ clash 安装脚本执行完成"
        return 0
    else
        log_error "clash 安装脚本执行失败"
        return 1
    fi
}

##
# 加载 clash 函数到当前环境
##
_load_clash_functions() {
    log_info "加载 clash 函数到当前环境..."
    
    # 检查 clash 脚本是否存在
    local clash_common="/opt/clash/script/common.sh"
    local clash_ctl="/opt/clash/script/clashctl.sh"
    
    if [[ ! -f "$clash_common" ]] || [[ ! -f "$clash_ctl" ]]; then
        log_error "clash 脚本文件不存在，无法加载函数"
        return 1
    fi
    
    # 加载 clash 函数到当前 shell 环境
    log_debug "加载 $clash_common"
    if ! source "$clash_common" 2>/dev/null; then
        log_error "加载 common.sh 失败"
        return 1
    fi
    
    log_debug "加载 $clash_ctl"
    if ! source "$clash_ctl" 2>/dev/null; then
        log_error "加载 clashctl.sh 失败"
        return 1
    fi
    
    # 验证关键函数是否可用
    if declare -f clashctl >/dev/null && declare -f clashon >/dev/null; then
        log_success "✅ clash 函数已加载到当前环境"
        log_info "💡 现在可以在当前脚本中使用 clashon, clashoff, clashctl 等命令"
        return 0
    else
        log_error "clash 函数加载失败"
        return 1
    fi
}

##
# 清理临时文件
##
_cleanup_temp_files() {
    if [[ -n "$CLASH_INSTALLER_DIR" ]] && [[ -d "$CLASH_INSTALLER_DIR" ]]; then
        log_debug "清理临时文件: $CLASH_INSTALLER_DIR"
        sudo rm -rf "$CLASH_INSTALLER_DIR"
        unset CLASH_INSTALLER_DIR
    fi
}

log_debug "Linux clash 模块已加载"
