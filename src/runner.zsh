#!/usr/bin/env zsh
# =============================================================================
# 模块执行器 - Module Runner
# 
# 负责模块管理、执行流程控制、依赖关系处理
# =============================================================================

# 避免重复加载
[[ -n "${RUNNER_LOADED:-}" ]] && return 0
readonly RUNNER_LOADED=1

# =============================================================================
# 模块配置
# =============================================================================

# 默认模块执行顺序
DEFAULT_MODULES=(
    "linux-zsh"     # Linux zsh 环境配置 (仅 Linux)
    "linux-clash"   # Linux clash 代理配置 (仅 Linux)  
    "homebrew"      # Homebrew 包管理器 (所有系统)
    "homebrew-init" # Homebrew 软件包安装 (所有系统)
    "chezmoi-setup" # Chezmoi 完整设置流程 (所有系统)
    "oh-my-zsh"     # Oh My Zsh 终端美化 (所有系统)
    "tmux-tpm"      # Tmux Plugin Manager (所有系统)
)

# 获取模块描述 (通用函数，完全兼容 bash 和 zsh)
get_module_description() {
    case "$1" in
        "linux-zsh") echo "Linux zsh 环境配置" ;;
        "linux-clash") echo "Linux clash 代理配置" ;;
        "homebrew") echo "Homebrew 包管理器" ;;
        "homebrew-init") echo "Homebrew 软件包安装" ;;
        "chezmoi-setup") echo "Chezmoi 完整设置流程" ;;
        "oh-my-zsh") echo "Oh My Zsh 终端美化" ;;
        "tmux-tpm") echo "Tmux Plugin Manager" ;;
        *) echo "$1" ;;
    esac
}

# =============================================================================
# 模块管理
# =============================================================================

##
# 列出可用模块
##
list_modules() {
    echo "可用模块："
    
    for module in "${DEFAULT_MODULES[@]}"; do
        local module_file="$CHEZMOI_PROJECT_ROOT/src/modules/${module}.zsh"
        local status_icon="✅"
        local desc="$(get_module_description "$module")"
        
        # 检查模块文件是否存在
        if [[ ! -f "$module_file" ]]; then
            status_icon="❌"
            desc="$desc (文件不存在)"
        fi
        
        printf "  %s %-12s - %s\n" "$status_icon" "$module" "$desc"
    done
}

##
# 验证模块是否存在
##
validate_module_exists() {
    local module="$1"
    local module_file="$CHEZMOI_PROJECT_ROOT/src/modules/${module}.zsh"
    
    if [[ ! -f "$module_file" ]]; then
        log_error "模块文件不存在: $module_file"
        return 1
    fi
    
    return 0
}

##
# 验证模块列表
##
validate_modules() {
    local modules=("$@")
    local invalid_modules=()
    
    for module in "${modules[@]}"; do
        # 检查模块是否在默认列表中
        if [[ ! " ${DEFAULT_MODULES[*]} " =~ " $module " ]]; then
            invalid_modules+=("$module")
            continue
        fi
        
        # 检查模块文件是否存在
        if ! validate_module_exists "$module"; then
            invalid_modules+=("$module")
        fi
    done
    
    if [[ ${#invalid_modules[@]} -gt 0 ]]; then
        log_error "无效的模块: ${invalid_modules[*]}"
        log_info "使用 --list 查看可用模块"
        return 1
    fi
    
    return 0
}

# =============================================================================
# 模块执行
# =============================================================================

##
# 执行单个模块
##
run_module() {
    local module="$1"
    local module_file="$CHEZMOI_PROJECT_ROOT/src/modules/${module}.zsh"
    local module_desc="$(get_module_description "$module")"
    
    log_debug "开始执行模块: $module"
    
    # 验证模块文件存在
    if ! validate_module_exists "$module"; then
        return 1
    fi
    
    # 加载模块文件
    log_debug "加载模块文件: $module_file"
    if ! source "$module_file"; then
        log_error "加载模块文件失败: $module_file"
        return 1
    fi
    
    # 验证模块接口
    if ! validate_module_interface "$module"; then
        return 1
    fi
    
    # 1. 检查是否需要执行
    log_debug "检查模块状态: $module"
    if ! ${module}_check; then
        log_info "跳过模块: $module_desc (已完成)"
        return 0
    fi
    
    # 2. 执行安装
    log_info "🚀 执行模块: $module_desc"
    if ! ${module}_install; then
        log_error "模块执行失败: $module_desc"
        return 1
    fi
    
    # 3. 验证结果 (如果实现了验证函数)
    if declare -f "${module}_verify" >/dev/null; then
        log_debug "验证模块结果: $module"
        if ! ${module}_verify; then
            log_error "模块验证失败: $module_desc"
            return 1
        fi
    fi
    
    log_success "模块完成: $module_desc"
    return 0
}

##
# 执行模块列表
##
run_modules() {
    local modules=("$@")
    local success_count=0
    local failure_count=0
    
    # 如果没有指定模块，使用默认模块
    if [[ ${#modules[@]} -eq 0 ]]; then
        modules=("${DEFAULT_MODULES[@]}")
        log_info "使用默认模块: ${modules[*]}"
    fi
    
    # 处理续传逻辑：如果设置了 --continue-after，过滤掉该模块及之前的模块
    if [[ -n "${INSTALLER_CONTINUE_AFTER:-}" ]]; then
        local continue_modules=()
        local should_skip=true
        
        # 如果续传模块不在当前模块列表中，说明需要执行所有模块
        if [[ ! " ${modules[*]} " =~ " $INSTALLER_CONTINUE_AFTER " ]]; then
            log_info "续传模块 $INSTALLER_CONTINUE_AFTER 不在当前列表中，执行所有模块"
            should_skip=false
        fi
        
        if [[ "$should_skip" == "true" ]]; then
            local found_continue_point=false
            
            for module in "${modules[@]}"; do
                if [[ "$module" == "$INSTALLER_CONTINUE_AFTER" ]]; then
                    found_continue_point=true
                elif [[ "$found_continue_point" == "true" ]]; then
                    continue_modules+=("$module")
                fi
            done
            
            modules=("${continue_modules[@]}")
            log_info "续传执行模块 (从 $INSTALLER_CONTINUE_AFTER 之后): ${modules[*]}"
        fi
    fi
    
    # 验证模块
    if ! validate_modules "${modules[@]}"; then
        return 1
    fi
    
    # 显示执行计划
    log_header "开始安装"
    echo "计划执行的模块："
    local i=1
    for module in "${modules[@]}"; do
        local desc="$(get_module_description "$module")"
        printf "  %d. %s - %s\n" "$i" "$module" "$desc"
        ((i++))
    done
    echo
    
    # 确认执行
    if ! ask_yes_no "确认执行以上模块?" "y"; then
        log_info "用户取消安装"
        return 1
    fi
    
    # 执行模块
    local i=1
    for module in "${modules[@]}"; do
        log_step "$i" "${#modules[@]}" "处理模块: $module"
        
        # 执行模块并统计结果
        if run_module "$module"; then
            ((success_count++))
        else
            ((failure_count++))
            # 询问是否继续
            if ! ask_yes_no "模块 $module 失败，是否继续执行其他模块?" "y"; then
                log_info "用户选择停止安装"
                break
            fi
        fi
        echo
        ((i++))
    done
    
    # 显示结果汇总
    log_header "安装结果"
    local total_modules=${#modules[@]}
    
    echo "模块执行统计："
    printf "  总计: %d | 成功: %d | 失败: %d\n" \
           "$total_modules" "$success_count" "$failure_count"
    echo
    
    if [[ $failure_count -eq 0 ]]; then
        log_success "🎉 所有模块处理完成!"
    else
        log_warn "⚠️  部分模块执行失败"
        log_info "💡 重新运行此脚本可以继续未完成的配置"
    fi
    
    # 返回成功当且仅当没有失败
    if [[ $failure_count -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}

# =============================================================================
# 初始化
# =============================================================================

log_debug "模块执行器已加载 ($(get_timestamp))"
