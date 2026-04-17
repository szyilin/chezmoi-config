#!/usr/bin/env zsh
# =============================================================================
# Oh My Zsh 模块 - Oh My Zsh Module
# 
# 负责安装 Oh My Zsh 基础框架，配置通过 chezmoi 管理
# 基于官方安装脚本，但保持现有 .zshrc 配置不变
# =============================================================================

##
# 检查是否需要执行 Oh My Zsh 安装
##
oh-my-zsh_check() {
    log_debug "检查 Oh My Zsh 环境..."
    
    # 检查 zsh 是否可用
    if ! command_exists zsh; then
        log_error "Oh My Zsh 需要 zsh，请先安装 zsh"
        return 1  # 跳过执行
    fi
    
    # 严格检查 Oh My Zsh 是否已安装 (确保幂等性)
    local ohmyzsh_installed=false
    
    # 1. 检查安装目录和核心文件
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        log_debug "发现 Oh My Zsh 安装目录: $HOME/.oh-my-zsh"
        
        # 2. 检查核心文件
        if [[ -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]]; then
            log_debug "发现 Oh My Zsh 核心文件"
            ohmyzsh_installed=true
        else
            log_debug "Oh My Zsh 目录存在但核心文件缺失"
        fi
    fi
    
    if [[ "$ohmyzsh_installed" == "true" ]]; then
        # 检查版本信息
        local ohmyzsh_version=""
        if [[ -f "$HOME/.oh-my-zsh/tools/upgrade.sh" ]]; then
            ohmyzsh_version="(可升级版本)"
        else
            ohmyzsh_version="(已安装)"
        fi
        
        log_info "Oh My Zsh 已安装并配置 $ohmyzsh_version"
        log_info "跳过重复安装"
        return 1  # 跳过执行
    fi
    
    # 特殊情况：目录存在但核心文件缺失 (可能是不完整的安装)
    if [[ -d "$HOME/.oh-my-zsh" ]] && [[ ! -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]]; then
        log_warn "检测到不完整的 Oh My Zsh 安装"
        
        if ask_yes_no "是否自动清理并重新安装?" "y"; then
            log_info "清理不完整的 Oh My Zsh 安装..."
            if rm -rf "$HOME/.oh-my-zsh" 2>/dev/null; then
                log_success "清理完成，将重新安装"
                return 0  # 需要执行
            else
                log_error "清理失败，请手动执行: rm -rf ~/.oh-my-zsh"
                return 1  # 跳过执行
            fi
        else
            log_info "用户选择跳过，请手动清理: rm -rf ~/.oh-my-zsh"
            return 1  # 跳过执行
        fi
    fi
    
    log_info "需要安装 Oh My Zsh 框架"
    return 0  # 需要执行
}

##
# 执行 Oh My Zsh 安装
##
oh-my-zsh_install() {
    log_info "开始安装 Oh My Zsh 框架..."
    
    # 1. 尝试开启代理加速 (如果可用) - 使用 core.zsh 提供的通用函数
    local proxy_enabled=false
    if try_enable_proxy; then
        proxy_enabled=true
        log_info "已开启代理加速下载"
    fi
    
    # 2. 执行官方安装脚本 (保持现有配置)
    if ! _run_oh_my_zsh_installer; then
        log_error "Oh My Zsh 安装失败"
        return 1
    fi
    
    # 3. 安装必要的插件 (如果不存在)
    if ! _install_required_plugins; then
        log_warn "插件安装失败，但 Oh My Zsh 基础框架已安装"
    fi
    
    # 4. 关闭代理 (如果之前开启了) - 使用 core.zsh 提供的通用函数
    if [[ "$proxy_enabled" == "true" ]]; then
        try_disable_proxy
        log_info "已关闭代理"
    fi
    
    log_success "Oh My Zsh 框架安装完成"
    log_info "配置文件 (.zshrc, .p10k.zsh) 请通过 chezmoi apply 管理"
    return 0
}

##
# 验证 Oh My Zsh 安装
##
oh-my-zsh_verify() {
    log_debug "验证 Oh My Zsh 安装..."
    
    # 验证安装目录
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        log_error "验证失败: Oh My Zsh 安装目录不存在"
        return 1
    fi
    
    # 验证核心文件
    if [[ ! -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]]; then
        log_error "验证失败: Oh My Zsh 核心文件不存在"
        return 1
    fi
    
    # 验证 git 仓库
    if [[ -d "$HOME/.oh-my-zsh/.git" ]]; then
        log_success "Oh My Zsh git 仓库正常"
    else
        log_warn "Oh My Zsh git 仓库不存在"
    fi
    
    # 检查重要插件是否存在
    local required_plugins=("zsh-autosuggestions" "zsh-syntax-highlighting")
    local missing_plugins=()
    
    for plugin in "${required_plugins[@]}"; do
        if [[ ! -d "$HOME/.oh-my-zsh/custom/plugins/$plugin" ]]; then
            missing_plugins+=("$plugin")
        fi
    done
    
    if [[ ${#missing_plugins[@]} -gt 0 ]]; then
        log_warn "缺少插件: ${missing_plugins[*]}"
        log_info "这些插件会在应用 .zshrc 配置时自动安装"
    else
        log_success "必需插件已安装"
    fi
    
    # 检查 Powerlevel10k 主题
    if [[ -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]]; then
        log_success "Powerlevel10k 主题已安装"
    else
        log_warn "Powerlevel10k 主题未安装"
        log_info "需要手动安装或通过 chezmoi 配置"
    fi
    
    log_success "Oh My Zsh 框架验证通过"
    log_info "现在可以通过 'chezmoi apply' 应用个性化配置"
    return 0
}

# =============================================================================
# 内部辅助函数
# =============================================================================
# 注: 代理管理函数已移至 core.zsh 中，使用 try_enable_proxy() 和 try_disable_proxy()

##
# 执行 Oh My Zsh 官方安装脚本
##
_run_oh_my_zsh_installer() {
    log_info "执行 Oh My Zsh 官方安装脚本..."
    
    # 确保在有效目录中执行
    local safe_dir="$HOME"
    if [[ ! -d "$PWD" ]]; then
        log_debug "当前目录无效，切换到 $safe_dir"
        cd "$safe_dir" || return 1
    fi
    
    # 检查并处理目录冲突 (Oh My Zsh 脚本无法处理已存在的目录)
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        log_warn "检测到 Oh My Zsh 目录已存在，官方安装脚本无法处理"
        log_info "尝试备份现有目录..."
        
        local backup_dir="$HOME/.oh-my-zsh.backup.$(date +%s)"
        if mv "$HOME/.oh-my-zsh" "$backup_dir" 2>/dev/null; then
            log_success "已备份到: $backup_dir"
        else
            log_error "备份失败，请手动处理: mv ~/.oh-my-zsh ~/.oh-my-zsh.backup"
            return 1
        fi
    fi
    
    # 设置环境变量控制安装行为
    export CHSH=no                    # 不改变默认 shell (已由 linux-zsh 处理)
    export RUNZSH=no                  # 不启动新的 zsh (避免进程替换)
    export KEEP_ZSHRC=yes             # 保持现有 .zshrc (重要！)
    export OVERWRITE_CONFIRMATION=no  # 不询问覆盖确认
    
    # 在安全目录中执行官方安装脚本
    if (cd "$safe_dir" && sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended); then
        log_success "Oh My Zsh 基础框架安装完成"
        return 0
    else
        log_error "Oh My Zsh 安装脚本执行失败"
        
        # 如果安装失败且有备份，尝试恢复
        if [[ -n "$backup_dir" ]] && [[ -d "$backup_dir" ]]; then
            log_info "尝试恢复备份..."
            mv "$backup_dir" "$HOME/.oh-my-zsh" 2>/dev/null || true
        fi
        
        return 1
    fi
}

##
# 安装必要的插件
##
_install_required_plugins() {
    log_info "安装必要的插件..."
    
    # 确保在有效目录中执行
    local safe_dir="$HOME"
    if [[ ! -d "$PWD" ]]; then
        log_debug "当前目录无效，切换到 $safe_dir"
        cd "$safe_dir" || return 1
    fi
    
    local plugins_dir="$HOME/.oh-my-zsh/custom/plugins"
    local themes_dir="$HOME/.oh-my-zsh/custom/themes"
    
    # 创建目录
    mkdir -p "$plugins_dir" "$themes_dir" || return 1
    
    # 安装 zsh-autosuggestions
    if [[ ! -d "$plugins_dir/zsh-autosuggestions" ]]; then
        log_info "安装 zsh-autosuggestions 插件..."
        if (cd "$safe_dir" && git clone https://github.com/zsh-users/zsh-autosuggestions "$plugins_dir/zsh-autosuggestions" 2>/dev/null); then
            log_success "zsh-autosuggestions 安装完成"
        else
            log_warn "zsh-autosuggestions 安装失败"
        fi
    else
        log_debug "zsh-autosuggestions 插件已存在"
    fi
    
    # 安装 zsh-syntax-highlighting
    if [[ ! -d "$plugins_dir/zsh-syntax-highlighting" ]]; then
        log_info "安装 zsh-syntax-highlighting 插件..."
        if (cd "$safe_dir" && git clone https://github.com/zsh-users/zsh-syntax-highlighting "$plugins_dir/zsh-syntax-highlighting" 2>/dev/null); then
            log_success "zsh-syntax-highlighting 安装完成"
        else
            log_warn "zsh-syntax-highlighting 安装失败"
        fi
    else
        log_debug "zsh-syntax-highlighting 插件已存在"
    fi
    
    # 安装 Powerlevel10k 主题
    if [[ ! -d "$themes_dir/powerlevel10k" ]]; then
        log_info "安装 Powerlevel10k 主题..."
        if (cd "$safe_dir" && git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$themes_dir/powerlevel10k" 2>/dev/null); then
            log_success "Powerlevel10k 主题安装完成"
        else
            log_warn "Powerlevel10k 主题安装失败"
        fi
    else
        log_debug "Powerlevel10k 主题已存在"
    fi
    
    return 0
}

log_debug "Oh My Zsh 模块已加载"
