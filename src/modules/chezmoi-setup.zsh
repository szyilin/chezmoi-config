#!/usr/bin/env zsh
# =============================================================================
# Chezmoi Setup 模块 - Chezmoi Complete Setup Module
#
# 负责完整的 chezmoi 配置管理设置流程:
# 1. 初始化 git 仓库 (chezmoi init)
# 2. 应用所有配置 (chezmoi apply，含官方 age bootstrap 脚本解密身份密钥)
# =============================================================================

##
# 检查是否需要执行 chezmoi 完整设置
##
chezmoi-setup_check() {
    log_debug "检查 chezmoi 完整设置环境..."

    # 检查必要工具（age 由 chezmoi 内置 age 子命令提供，bootstrap 不依赖系统 age）
    local missing_tools=()
    if ! command_exists chezmoi; then
        missing_tools+=("chezmoi")
    fi
    if ! command_exists git; then
        missing_tools+=("git")
    fi

    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_error "缺少必要工具: ${missing_tools[*]}"
        log_info "请先安装这些工具 (通过 homebrew-init 模块，或 curl -fsLS get.chezmoi.io)"
        return 1
    fi

    if _is_chezmoi_fully_configured; then
        log_info "chezmoi 已完全配置，无需重复设置"
        return 1
    fi

    log_info "需要进行 chezmoi 完整设置"
    return 0
}

##
# 执行 chezmoi 完整设置
##
chezmoi-setup_install() {
    log_info "开始 chezmoi 设置流程"

    local proxy_enabled=false
    if try_enable_proxy; then
        proxy_enabled=true
        log_info "已开启代理加速 git 操作"
    fi

    if ! _initialize_chezmoi_repo; then
        log_error "chezmoi 仓库初始化失败"
        return 1
    fi

    if ! _apply_chezmoi_config; then
        log_error "chezmoi 配置应用失败"
        return 1
    fi

    if [[ "$proxy_enabled" == "true" ]]; then
        try_disable_proxy
        log_info "已关闭代理"
    fi

    log_success "chezmoi 设置完成"
    return 0
}

##
# 验证 chezmoi 完整设置
##
chezmoi-setup_verify() {
    log_debug "验证 chezmoi 完整设置..."

    local missing_tools=()
    if ! command_exists chezmoi; then missing_tools+=("chezmoi"); fi
    if ! command_exists git; then missing_tools+=("git"); fi

    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_error "验证失败: 缺少工具 ${missing_tools[*]}"
        return 1
    fi

    local source_dir="$(chezmoi source-path 2>/dev/null)"
    if [[ -n "$source_dir" ]] && [[ -d "$source_dir" ]]; then
        log_success "chezmoi 源目录: $source_dir"
    else
        log_error "验证失败: chezmoi 源目录不存在"
        return 1
    fi

    if [[ -f "$HOME/.config/chezmoi/age.key" ]]; then
        log_success "age 身份密钥已就绪: ~/.config/chezmoi/age.key"
    else
        log_warn "age 身份密钥未找到，加密文件将无法解密"
        log_info "首次 apply 时会提示输入 key.txt.age 的口令"
    fi

    local user_chezmoi_dir="$HOME/.local/share/chezmoi"
    if [[ -d "$user_chezmoi_dir/.git" ]]; then
        local remote_url="$(cd "$user_chezmoi_dir" && git remote get-url origin 2>/dev/null || echo 'unknown')"
        log_success "用户 chezmoi git 仓库已连接: $remote_url"

        if [[ "$remote_url" == git@* ]]; then
            if _check_ssh_access "$remote_url"; then
                log_success "SSH 访问权限已配置"
            else
                log_warn "SSH 访问权限未配置，推送时需要用户名密码"
                log_info "如需配置 SSH 密钥，请参考: https://gitee.com/profile/sshkeys"
            fi
        fi
    else
        log_warn "用户 chezmoi git 仓库未找到，可能使用的是当前项目目录"
    fi

    local key_files=(".zshrc" ".gitconfig" ".ssh/config")
    local applied_files=0
    for file in "${key_files[@]}"; do
        if [[ -f "$HOME/$file" ]]; then
            applied_files=$((applied_files + 1))
        fi
    done

    log_success "已应用配置文件: $applied_files 个"

    if command_exists mybrew.py; then
        log_success "mybrew.py 脚本可用"
    fi

    log_success "chezmoi 完整设置验证通过"
    return 0
}

# =============================================================================
# 内部辅助函数
# =============================================================================

_is_chezmoi_fully_configured() {
    local source_dir="$(chezmoi source-path 2>/dev/null)"
    if [[ -z "$source_dir" ]] || [[ ! -d "$source_dir" ]]; then
        log_debug "chezmoi 未初始化"
        return 1
    fi

    local repo_root="$(dirname "$source_dir")"
    if [[ ! -d "$repo_root/.git" ]]; then
        log_debug "git 仓库未配置"
        return 1
    fi

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

_initialize_chezmoi_repo() {
    log_info "[1/2] 初始化 chezmoi 仓库"

    local source_dir="$(chezmoi source-path 2>/dev/null)"
    if [[ -n "$source_dir" ]] && [[ -d "$(dirname "$source_dir")/.git" || -d "$source_dir/.git" ]]; then
        log_info "chezmoi 仓库已初始化"
        return 0
    fi

    local repo_url="git@gitee.com:szyilin/chezmoi-config.git"
    local https_url="https://gitee.com/szyilin/chezmoi-config.git"

    log_info "克隆 chezmoi 配置仓库..."

    if _check_ssh_access "$repo_url"; then
        log_info "SSH 访问可用，使用 SSH 方式: $repo_url"
    else
        log_warn "SSH 访问不可用，回退到 HTTPS 方式"
        repo_url="$https_url"
        log_info "使用 HTTPS 方式: $repo_url"
    fi

    if chezmoi init "$repo_url"; then
        log_success "chezmoi 仓库初始化完成"
        return 0
    fi

    log_error "chezmoi 仓库初始化失败"
    return 1
}

_apply_chezmoi_config() {
    log_info "[2/2] 应用 chezmoi 配置"

    if [[ ! -f "$HOME/.config/chezmoi/age.key" ]]; then
        log_info "首次部署: apply 将运行 bootstrap 脚本解密 age 身份密钥 (key.txt.age)"
        log_info "请准备输入 key.txt.age 的口令"
        echo
    fi

    log_info "检查配置差异..."
    if chezmoi diff --no-pager 2>/dev/null | head -20 | grep -q .; then
        log_info "发现配置差异，将应用以下变更:"
        chezmoi diff --no-pager 2>/dev/null | head -10 || true
        echo "..."
        echo
    fi

    if [[ "${MANUAL_CONFIRM:-false}" == "true" ]]; then
        log_info "手动确认模式: 将逐项确认"
        if chezmoi apply; then
            log_success "chezmoi 配置应用完成"
            return 0
        fi
    else
        log_info "自动确认模式: 直接应用所有配置"
        if chezmoi apply --force; then
            log_success "chezmoi 配置应用完成"
            return 0
        fi
    fi

    log_error "chezmoi 配置应用失败"
    log_info "可以手动运行: chezmoi apply"
    return 1
}

_check_ssh_access() {
    local repo_url="$1"
    local host="$(echo "$repo_url" | sed 's/.*@\([^:]*\):.*/\1/')"

    if [[ -z "$host" ]]; then
        return 1
    fi

    if ssh -o ConnectTimeout=10 -o BatchMode=yes -T git@"$host" 2>/dev/null; then
        return 0
    fi

    return 1
}

log_debug "Chezmoi Setup 模块已加载"
