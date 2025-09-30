#!/usr/bin/env zsh
# =============================================================================
# Homebrew Init 模块 - Homebrew Initialization Module
# 
# 负责使用 mybrew.py 脚本安装和管理 Homebrew 软件包
# 基于 resources/mybrew.json 配置文件进行智能包管理
# =============================================================================

##
# 检查是否需要执行 Homebrew 包安装
##
homebrew-init_check() {
    log_debug "检查 Homebrew 包管理环境..."
    
    # 检查 Homebrew 是否可用
    if ! command_exists brew; then
        log_error "需要先安装 Homebrew，请先运行 homebrew 模块"
        return 1  # 跳过执行
    fi
    
    # 检查 mybrew.py 脚本是否可用
    if ! _find_mybrew_script >/dev/null; then
        log_error "mybrew.py 脚本不可用，请先运行 'chezmoi apply' 应用配置"
        return 1  # 跳过执行
    fi
    
    # 检查配置文件是否存在
    if ! _find_mybrew_config >/dev/null; then
        log_error "mybrew.json 配置文件不存在"
        return 1  # 跳过执行
    fi
    
    # 简单检查是否有需要安装的包 (不深度检查，让 mybrew.py 处理)
    log_info "准备使用 mybrew.py 管理 Homebrew 软件包"
    return 0  # 需要执行
}

##
# 执行 Homebrew 包安装
##
homebrew-init_install() {
    log_info "开始使用 mybrew.py 管理 Homebrew 软件包..."
    
    # 1. 定位 mybrew.py 脚本
    local mybrew_script=""
    if ! mybrew_script="$(_find_mybrew_script)"; then
        log_error "无法找到 mybrew.py 脚本"
        return 1
    fi
    
    # 2. 验证脚本可执行
    if ! _verify_mybrew_script "$mybrew_script"; then
        log_error "mybrew.py 脚本验证失败"
        return 1
    fi
    
    # 3. 尝试开启代理加速 (如果可用) - 使用 core.zsh 提供的通用函数
    local proxy_enabled=false
    if try_enable_proxy; then
        proxy_enabled=true
        log_info "🚀 已开启代理加速下载"
    fi
    
    # 4. 执行 mybrew.py 安装命令
    if ! _run_mybrew_install "$mybrew_script"; then
        log_error "mybrew.py 包安装失败"
        return 1
    fi
    
    # 5. 关闭代理 (如果之前开启了) - 使用 core.zsh 提供的通用函数
    if [[ "$proxy_enabled" == "true" ]]; then
        try_disable_proxy
        log_info "📴 已关闭代理"
    fi
    
    log_success "Homebrew 软件包安装完成"
    log_info "💡 使用 'mybrew.py backup' 备份当前安装的包"
    return 0
}

##
# 验证 Homebrew 包安装
##
homebrew-init_verify() {
    log_debug "验证 Homebrew 包安装..."
    
    # 验证 Homebrew 可用性
    if ! command_exists brew; then
        log_error "验证失败: brew 命令不可用"
        return 1
    fi
    
    # 验证 mybrew.py 脚本可用性
    local mybrew_script=""
    if mybrew_script="$(_find_mybrew_script)" 2>/dev/null; then
        log_success "✅ mybrew.py 脚本可用: $mybrew_script"
    else
        log_warn "⚠️  mybrew.py 脚本不可用，请运行 'chezmoi apply'"
    fi
    
    # 验证配置文件
    local config_file=""
    if config_file="$(_find_mybrew_config)" 2>/dev/null; then
        log_success "✅ 配置文件可用: $config_file"
    else
        log_warn "⚠️  mybrew.json 配置文件不可用"
    fi
    
    # 显示已安装包的统计信息
    local installed_count=""
    if installed_count="$(brew list --formula 2>/dev/null | wc -l | tr -d ' ')"; then
        log_info "已安装 Homebrew 包: $installed_count 个"
    fi
    
    log_success "Homebrew 包管理验证通过"
    log_info "💡 使用 'mybrew.py install' 可管理软件包"
    return 0
}

# =============================================================================
# 内部辅助函数
# =============================================================================

##
# 查找 mybrew.py 脚本
##
_find_mybrew_script() {
    # 1. 优先使用 CHEZMOI_PROJECT_ROOT
    if [[ -n "${CHEZMOI_PROJECT_ROOT:-}" ]]; then
        local script_path="$CHEZMOI_PROJECT_ROOT/home/dot_zsh-config/bin/executable_mybrew.py"
        if [[ -f "$script_path" ]]; then
            echo "$script_path"
            return 0
        fi
    fi
    
    # 2. 在 PATH 中查找
    if command_exists mybrew.py; then
        echo "mybrew.py"
        return 0
    fi
    
    # 3. 在用户主目录查找
    local home_script="$HOME/.zsh-config/bin/mybrew.py"
    if [[ -f "$home_script" ]]; then
        echo "$home_script"
        return 0
    fi
    
    log_debug "未找到 mybrew.py 脚本"
    return 1
}

##
# 查找 mybrew.json 配置文件
##
_find_mybrew_config() {
    # 1. 优先使用 CHEZMOI_PROJECT_ROOT
    if [[ -n "${CHEZMOI_PROJECT_ROOT:-}" ]]; then
        local config_path="$CHEZMOI_PROJECT_ROOT/resources/mybrew.json"
        if [[ -f "$config_path" ]]; then
            echo "$config_path"
            return 0
        fi
    fi
    
    # 2. 相对当前脚本查找
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local config_path="$script_dir/../../resources/mybrew.json"
    if [[ -f "$config_path" ]]; then
        echo "$config_path"
        return 0
    fi
    
    log_debug "未找到 mybrew.json 配置文件"
    return 1
}

##
# 验证 mybrew.py 脚本
##
_verify_mybrew_script() {
    local script_path="$1"
    
    # 检查文件存在性和可执行性
    if [[ ! -f "$script_path" ]]; then
        log_error "脚本文件不存在: $script_path"
        return 1
    fi
    
    if [[ ! -x "$script_path" ]]; then
        log_info "脚本不可执行，尝试添加执行权限..."
        if chmod +x "$script_path" 2>/dev/null; then
            log_success "✅ 已添加执行权限"
        else
            log_warn "⚠️  无法添加执行权限，将使用 python3 执行"
        fi
    fi
    
    # 验证脚本可用性
    if python3 -c "import sys; sys.path.insert(0, '$(dirname "$script_path")'); exec(open('$script_path').read())" --help >/dev/null 2>&1; then
        log_debug "mybrew.py 脚本验证通过"
        return 0
    else
        log_error "mybrew.py 脚本验证失败"
        return 1
    fi
}

# 注: 代理管理函数已移至 core.zsh 中，使用 try_enable_proxy() 和 try_disable_proxy()

##
# 执行 mybrew.py 安装命令
##
_run_mybrew_install() {
    local script_path="$1"
    
    log_info "执行 mybrew.py 包安装..."
    log_info "💡 使用自动确认模式安装默认软件包"
    
    # 设置环境变量 (与主脚本保持一致)
    export CHEZMOI_PROJECT_ROOT="${CHEZMOI_PROJECT_ROOT}"
    
    # 使用自动确认模式 (不设置 MANUAL_CONFIRM，默认为 false)
    local confirm_mode=""
    if [[ "${MANUAL_CONFIRM:-false}" == "true" ]]; then
        confirm_mode="手动确认模式"
        log_info "将使用手动确认模式执行安装"
    else
        confirm_mode="自动确认模式"
        log_info "将使用自动确认模式执行安装"
    fi
    
    # 执行安装命令
    log_debug "执行命令: python3 $script_path install"
    if python3 "$script_path" install; then
        log_success "✅ mybrew.py 包安装完成"
        return 0
    else
        log_error "mybrew.py 包安装失败"
        log_info "💡 可以手动运行查看详细信息: python3 $script_path install"
        return 1
    fi
}

log_debug "Homebrew Init 模块已加载"
