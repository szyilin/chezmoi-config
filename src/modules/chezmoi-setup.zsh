#!/usr/bin/env zsh
# =============================================================================
# Chezmoi Setup 模块 - Chezmoi Complete Setup Module
# 
# 负责完整的 chezmoi 配置管理设置流程:
# 1. 初始化 git 仓库 (chezmoi init)
# 2. 恢复加密配置文件 (mychezmoi.py restore)
# 3. 应用所有配置 (chezmoi apply)
# =============================================================================

##
# 检查是否需要执行 chezmoi 完整设置
##
chezmoi-setup_check() {
    log_debug "检查 chezmoi 完整设置环境..."
    
    # 检查必要工具
    local missing_tools=()
    if ! command_exists chezmoi; then
        missing_tools+=("chezmoi")
    fi
    if ! command_exists git; then
        missing_tools+=("git")
    fi
    if ! command_exists age; then
        missing_tools+=("age")
    fi
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_error "缺少必要工具: ${missing_tools[*]}"
        log_info "请先安装这些工具 (通过 homebrew-init 模块)"
        return 1  # 跳过执行
    fi
    
    # 检查是否已完全配置
    if _is_chezmoi_fully_configured; then
        log_info "✅ chezmoi 已完全配置，无需重复设置"
        return 1  # 跳过执行
    fi
    
    log_info "需要进行 chezmoi 完整设置"
    return 0  # 需要执行
}

##
# 执行 chezmoi 完整设置
##
chezmoi-setup_install() {
    log_info "开始 chezmoi 完整设置流程..."
    
    # 1. 尝试开启代理加速 (如果可用) - 使用 core.zsh 提供的通用函数
    local proxy_enabled=false
    if try_enable_proxy; then
        proxy_enabled=true
        log_info "🚀 已开启代理加速 git 操作"
    fi
    
    # 2. 初始化 chezmoi git 仓库
    if ! _initialize_chezmoi_repo; then
        log_error "chezmoi 仓库初始化失败"
        return 1
    fi
    
    # 3. 恢复加密配置文件 (如果存在)
    if ! _restore_encrypted_configs; then
        log_error "加密配置文件恢复失败"
        return 1
    fi
    
    # 4. 应用所有配置
    if ! _apply_chezmoi_config; then
        log_error "chezmoi 配置应用失败"
        return 1
    fi
    
    # 5. 关闭代理 (如果之前开启了) - 使用 core.zsh 提供的通用函数
    if [[ "$proxy_enabled" == "true" ]]; then
        try_disable_proxy
        log_info "📴 已关闭代理"
    fi
    
    log_success "chezmoi 完整设置流程完成"
    log_info "💡 所有 dotfiles 和配置已应用到系统"
    return 0
}

##
# 验证 chezmoi 完整设置
##
chezmoi-setup_verify() {
    log_debug "验证 chezmoi 完整设置..."
    
    # 验证基础工具
    local missing_tools=()
    if ! command_exists chezmoi; then missing_tools+=("chezmoi"); fi
    if ! command_exists git; then missing_tools+=("git"); fi
    if ! command_exists age; then missing_tools+=("age"); fi
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_error "验证失败: 缺少工具 ${missing_tools[*]}"
        return 1
    fi
    
    # 验证 chezmoi 初始化
    local source_dir="$(chezmoi source-path 2>/dev/null)"
    if [[ -n "$source_dir" ]] && [[ -d "$source_dir" ]]; then
        log_success "✅ chezmoi 源目录: $source_dir"
    else
        log_error "验证失败: chezmoi 源目录不存在"
        return 1
    fi
    
    # 验证 chezmoi 配置 (检查用户的实际 chezmoi 目录)
    local user_chezmoi_dir="$HOME/.local/share/chezmoi"
    if [[ -d "$user_chezmoi_dir/.git" ]]; then
        local remote_url="$(cd "$user_chezmoi_dir" && git remote get-url origin 2>/dev/null || echo 'unknown')"
        log_success "✅ 用户 chezmoi git 仓库已连接: $remote_url"
        
        # 检查 SSH 配置 (非必需，只是警告)
        if [[ "$remote_url" == git@* ]]; then
            if _check_ssh_access "$remote_url"; then
                log_success "✅ SSH 访问权限已配置"
            else
                log_warn "⚠️  SSH 访问权限未配置，推送时需要用户名密码"
                log_info "💡 如需配置 SSH 密钥，请参考: https://gitee.com/profile/sshkeys"
            fi
        fi
    else
        log_warn "⚠️  用户 chezmoi git 仓库未找到，可能使用的是当前项目目录"
        log_info "💡 这不影响配置应用，但无法推送更改到远程仓库"
    fi
    
    # 验证关键配置文件
    local key_files=(".zshrc" ".gitconfig" ".ssh/config")
    local applied_files=0
    
    for file in "${key_files[@]}"; do
        if [[ -f "$HOME/$file" ]]; then
            ((applied_files++))
        fi
    done
    
    log_success "✅ 已应用配置文件: $applied_files 个"
    
    # 验证脚本可用性
    if command_exists mybrew.py; then
        log_success "✅ mybrew.py 脚本可用"
    fi
    
    if command_exists mychezmoi.py; then
        log_success "✅ mychezmoi.py 脚本可用"
    fi
    
    log_success "chezmoi 完整设置验证通过"
    log_info "💡 环境配置完成，可以开始使用"
    return 0
}

# =============================================================================
# 内部辅助函数
# =============================================================================

##
# 检查 chezmoi 是否已完全配置
##
_is_chezmoi_fully_configured() {
    # 检查 chezmoi 是否已初始化
    local source_dir="$(chezmoi source-path 2>/dev/null)"
    if [[ -z "$source_dir" ]] || [[ ! -d "$source_dir" ]]; then
        log_debug "chezmoi 未初始化"
        return 1
    fi
    
    # 检查 git 仓库是否已配置
    if [[ ! -d "$source_dir/.git" ]]; then
        log_debug "git 仓库未配置"
        return 1
    fi
    
    # 检查是否有未应用的更改
    if chezmoi diff --no-pager >/dev/null 2>&1; then
        local diff_count="$(chezmoi diff --no-pager 2>/dev/null | wc -l | tr -d ' ')"
        if [[ "$diff_count" -gt 0 ]]; then
            log_debug "检测到 $diff_count 行配置差异，需要应用"
            return 1
        fi
    fi
    
    log_debug "chezmoi 已完全配置"
    return 0
}

##
# 初始化 chezmoi git 仓库
##
_initialize_chezmoi_repo() {
    log_info "🔧 第1步: 初始化 chezmoi git 仓库..."
    
    # 检查是否已经初始化
    local source_dir="$(chezmoi source-path 2>/dev/null)"
    if [[ -n "$source_dir" ]] && [[ -d "$source_dir/.git" ]]; then
        log_info "✅ chezmoi git 仓库已初始化"
        return 0
    fi
    
    # chezmoi 仓库 URL (优先 SSH，失败时自动回退 HTTPS)
    local repo_url="git@gitee.com:szyilin/chezmoi-config.git"
    local https_url="https://gitee.com/szyilin/chezmoi-config.git"
    
    log_info "克隆 chezmoi 配置仓库..."
    
    # 检查 SSH 访问 (非阻塞)
    if _check_ssh_access "$repo_url"; then
        log_info "✅ SSH 访问可用，使用 SSH 方式: $repo_url"
    else
        log_warn "⚠️  SSH 访问不可用，回退到 HTTPS 方式"
        repo_url="$https_url"
        log_info "使用 HTTPS 方式: $repo_url"
    fi
    
    # 执行 chezmoi init
    if chezmoi init "$repo_url"; then
        log_success "✅ chezmoi 仓库初始化完成"
        return 0
    else
        log_error "chezmoi 仓库初始化失败"
        log_info "💡 可能的原因:"
        log_info "  1. 网络连接问题"
        log_info "  2. SSH 密钥未配置 (会自动回退到 HTTPS)"
        log_info "  3. 仓库访问权限问题"
        log_info "💡 请检查网络连接后重试"
        return 1
    fi
}

##
# 恢复加密配置文件
##
_restore_encrypted_configs() {
    log_info "🔐 第2步: 恢复加密配置文件..."
    
    # 检查是否有加密文件
    if ! _has_encrypted_files_to_restore; then
        log_info "没有发现加密配置文件，跳过恢复"
        return 0
    fi
    
    # 执行配置恢复 (无论什么模式都需要执行)
    local mychezmoi_script=""
    if ! mychezmoi_script="$(_find_mychezmoi_script)"; then
        log_warn "未找到 mychezmoi.py 脚本，跳过配置恢复"
        log_info "💡 如需恢复加密配置，请稍后手动运行: mychezmoi.py restore"
        return 0
    fi
    
    log_info "发现加密配置文件，开始恢复..."
    log_info "💡 请准备输入解密密码"
    
    # 设置环境变量
    export CHEZMOI_PROJECT_ROOT="${CHEZMOI_PROJECT_ROOT}"
    export MANUAL_CONFIRM="${MANUAL_CONFIRM:-false}"
    
    echo
    
    if python3 "$mychezmoi_script" restore; then
        echo
        log_success "✅ 加密配置文件恢复完成"
        return 0
    else
        echo
        log_error "加密配置文件恢复失败"
        log_info "💡 这会导致 chezmoi apply 失败，因为无法解密 .age 文件"
        log_info "💡 请重新运行此模块: ./install.zsh chezmoi-setup"
        return 1  # 这是致命错误，必须成功才能继续
    fi
}

##
# 应用 chezmoi 配置
##
_apply_chezmoi_config() {
    log_info "📋 第3步: 应用 chezmoi 配置到系统..."
    
    # 显示将要应用的更改
    log_info "检查配置差异..."
    if chezmoi diff --no-pager 2>/dev/null | head -20 | grep -q .; then
        log_info "发现配置差异，将应用以下更改:"
        chezmoi diff --no-pager 2>/dev/null | head -10 || true
        echo "..."
        echo
    fi
    
    # 根据确认模式处理应用
    if [[ "${MANUAL_CONFIRM:-false}" == "true" ]]; then
        # 手动确认模式
        log_info "手动确认模式: 将询问每个文件的应用确认"
        if chezmoi apply; then
            log_success "✅ chezmoi 配置应用完成"
            return 0
        fi
    else
        # 自动确认模式
        log_info "自动确认模式: 自动应用所有配置"
        if chezmoi apply --force; then
            log_success "✅ chezmoi 配置应用完成"
            return 0
        fi
    fi
    
    log_error "chezmoi 配置应用失败"
    log_info "💡 可以手动运行: chezmoi apply"
    return 1
}

##
# 查找 mychezmoi.py 脚本
##
_find_mychezmoi_script() {
    # 1. 优先使用 CHEZMOI_PROJECT_ROOT
    if [[ -n "${CHEZMOI_PROJECT_ROOT:-}" ]]; then
        local script_path="$CHEZMOI_PROJECT_ROOT/home/dot_zsh-config/bin/executable_mychezmoi.py"
        if [[ -f "$script_path" ]]; then
            echo "$script_path"
            return 0
        fi
    fi
    
    # 2. 在用户主目录查找 (chezmoi apply 后)
    local home_script="$HOME/.zsh-config/bin/mychezmoi.py"
    if [[ -f "$home_script" ]]; then
        echo "$home_script"
        return 0
    fi
    
    # 3. 在 PATH 中查找
    if command_exists mychezmoi.py; then
        echo "mychezmoi.py"
        return 0
    fi
    
    log_debug "未找到 mychezmoi.py 脚本"
    return 1
}

##
# 检查是否有加密文件需要恢复
##
_has_encrypted_files_to_restore() {
    # chezmoi init 后，源目录应该已存在
    local source_dir="$(chezmoi source-path 2>/dev/null)"
    if [[ -z "$source_dir" ]]; then
        log_debug "chezmoi 源目录不存在"
        return 1
    fi
    
    local backup_dir="$source_dir/../resources/chezmoi-config"
    
    # 查找 .age 加密文件
    if [[ -d "$backup_dir" ]] && find "$backup_dir" -name "*.age" -type f 2>/dev/null | grep -q .; then
        log_debug "发现加密配置文件"
        return 0
    fi
    
    log_debug "未发现加密配置文件"
    return 1
}

##
# 检查 SSH 访问权限
##
_check_ssh_access() {
    local repo_url="$1"
    
    # 提取主机名
    local host="$(echo "$repo_url" | sed 's/.*@\([^:]*\):.*/\1/')"
    
    if [[ -z "$host" ]]; then
        log_debug "无法解析 SSH 主机名"
        return 1
    fi
    
    log_debug "检查 SSH 访问权限: $host"
    
    # 测试 SSH 连接
    if ssh -o ConnectTimeout=10 -o BatchMode=yes -T git@"$host" 2>/dev/null; then
        log_debug "✅ SSH 访问权限验证通过"
        return 0
    else
        log_debug "❌ SSH 访问权限验证失败"
        return 1
    fi
}

# 注: 代理管理函数已移至 core.zsh 中，使用 try_enable_proxy() 和 try_disable_proxy()

log_debug "Chezmoi Setup 模块已加载"
