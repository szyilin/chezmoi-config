#!/usr/bin/env zsh
# =============================================================================
# Tmux TPM 模块 - Tmux Plugin Manager Module
# 
# 负责安装 Tmux Plugin Manager (TPM)，配置通过 chezmoi 管理
# =============================================================================

##
# 检查是否需要执行 TPM 安装
##
tmux-tpm_check() {
    log_debug "检查 Tmux TPM 环境..."
    
    # 检查 tmux 是否可用
    if ! command_exists tmux; then
        log_debug "tmux 命令不存在，跳过 TPM 安装"
        return 1  # 跳过执行
    fi
    
    # 检查 tmux 版本 (需要 1.9 或更高)
    local tmux_version
    if tmux_version=$(tmux -V 2>/dev/null | grep -oE '[0-9]+\.[0-9]+'); then
        log_debug "检测到 tmux 版本: $tmux_version"
        
        # 简单的版本比较 (只比较主版本号)
        local major_version="${tmux_version%%.*}"
        if [[ -z "$major_version" ]] || [[ "$major_version" -lt 1 ]]; then
            log_warn "tmux 版本过低 (需要 1.9+)，跳过 TPM 安装"
            return 1  # 跳过执行
        fi
    else
        log_debug "无法检测 tmux 版本，假设版本满足要求"
    fi
    
    # 检查 git 是否可用 (TPM 安装需要 git)
    if ! command_exists git; then
        log_error "TPM 安装需要 git，请先安装 git"
        return 1  # 跳过执行
    fi
    
    # 检查 TPM 是否已安装
    local tpm_dir="$HOME/.tmux/plugins/tpm"
    if [[ -d "$tpm_dir" ]]; then
        # 检查核心文件是否存在
        if [[ -f "$tpm_dir/tpm" ]]; then
            log_info "✅ Tmux TPM 已安装"
            log_info "💡 配置文件由 chezmoi 管理，无需重复安装"
            return 1  # 跳过执行
        else
            log_warn "检测到不完整的 TPM 安装"
            log_info "将重新安装 TPM"
            return 0  # 需要执行
        fi
    fi
    
    log_info "需要安装 Tmux TPM"
    return 0  # 需要执行
}

##
# 执行 TPM 安装
##
tmux-tpm_install() {
    log_info "开始安装 Tmux TPM..."
    
    local tpm_dir="$HOME/.tmux/plugins/tpm"
    local tpm_repo="https://github.com/tmux-plugins/tpm"
    
    # 1. 尝试开启代理加速 (如果可用)
    local proxy_enabled=false
    if try_enable_proxy; then
        proxy_enabled=true
        log_info "🚀 已开启代理加速下载"
    fi
    
    # 2. 创建目录
    log_info "创建 TPM 安装目录..."
    if ! mkdir -p "$HOME/.tmux/plugins" 2>/dev/null; then
        log_error "创建目录失败: $HOME/.tmux/plugins"
        if [[ "$proxy_enabled" == "true" ]]; then
            try_disable_proxy
        fi
        return 1
    fi
    
    # 3. 如果目录已存在但不完整，先清理
    if [[ -d "$tpm_dir" ]] && [[ ! -f "$tpm_dir/tpm" ]]; then
        log_info "清理不完整的 TPM 安装..."
        rm -rf "$tpm_dir" 2>/dev/null || true
    fi
    
    # 4. 克隆 TPM 仓库
    log_info "克隆 TPM 仓库..."
    if (cd "$HOME" && git clone "$tpm_repo" "$tpm_dir" 2>/dev/null); then
        log_success "✅ TPM 克隆完成"
    else
        log_error "TPM 克隆失败"
        if [[ "$proxy_enabled" == "true" ]]; then
            try_disable_proxy
        fi
        return 1
    fi
    
    # 5. 关闭代理 (如果之前开启了)
    if [[ "$proxy_enabled" == "true" ]]; then
        try_disable_proxy
        log_info "📴 已关闭代理"
    fi
    
    log_success "Tmux TPM 安装完成"
    log_info "💡 配置文件 (~/.tmux.conf) 请通过 chezmoi apply 管理"
    log_info "💡 安装插件后运行 'tmux source ~/.tmux.conf' 或按 <prefix> + I"
    return 0
}

##
# 验证 TPM 安装
##
tmux-tpm_verify() {
    log_debug "验证 TPM 安装..."
    
    local tpm_dir="$HOME/.tmux/plugins/tpm"
    
    # 验证安装目录
    if [[ ! -d "$tpm_dir" ]]; then
        log_error "验证失败: TPM 安装目录不存在"
        return 1
    fi
    
    # 验证核心文件
    if [[ ! -f "$tpm_dir/tpm" ]]; then
        log_error "验证失败: TPM 核心文件不存在"
        return 1
    fi
    
    # 验证 git 仓库
    if [[ -d "$tpm_dir/.git" ]]; then
        log_success "✅ TPM git 仓库正常"
    else
        log_warn "⚠️  TPM git 仓库不存在"
    fi
    
    log_success "TPM 验证通过"
    return 0
}

log_debug "Tmux TPM 模块已加载"

