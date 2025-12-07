#!/usr/bin/env zsh
# ~/.config/zsh/init.zsh
# =============================================================================
# vim model config
# =============================================================================
bindkey -v # 将默认 emacs 模式变为 vim 模式
# 插入模式下恢复 Ctrl 系列快捷键（保持 Emacs 行编辑体验）
bindkey -M viins '^A' beginning-of-line
bindkey -M viins '^E' end-of-line
bindkey -M viins '^F' forward-char
bindkey -M viins '^B' backward-char
bindkey -M viins '^K' kill-line
bindkey -M viins '^U' backward-kill-line
bindkey -M viins '^W' backward-kill-word
bindkey -M viins '^H' backward-delete-char
bindkey -M viins '^D' delete-char
bindkey -M viins '^N' down-line-or-history
bindkey -M viins '^P' up-line-or-history

# =============================================================================
# 私有辅助函数
# =============================================================================

# 平台检测（只检测一次）
_is_macos() { [[ "$OSTYPE" == darwin* ]]; }
_is_linux() { [[ "$OSTYPE" == linux* ]]; }

# 按需加载：目录存在时导出并添加到 PATH
_load_dir_to_path() {
    local dir="$1"
    local var_name="$2"  # 可选：环境变量名
    
    if [[ -d "$dir" ]]; then
        [[ -n "$var_name" ]] && export "$var_name"="$dir"
        export PATH="$PATH:$dir/bin"
        return 0
    fi
    return 1
}

# 按需加载：文件存在时 source
_load_file() {
    local file="$1"
    [[ -f "$file" ]] && source "$file" 2>/dev/null
}

# 按需加载：命令存在时执行
_load_if_command() {
    local cmd="$1"
    shift
    command -v "$cmd" >/dev/null 2>&1 && eval "$@"
}

# 如果命令存在运行命令，并运行命令的返回结果
_load_if_command_source_result() {
    local cmd="$1"
    shift
    command -v "$cmd" >/dev/null 2>&1 && source <("$cmd" "$@")
}

# =============================================================================
# 环境变量配置
# =============================================================================

# 基础路径
export LOCAL_HOME=~/.local
export PATH="$HOME/.local/bin:$PATH"

# Homebrew 路径（根据平台自动选择）
if _is_macos; then
    export BREW_HOME="/opt/homebrew"
elif _is_linux; then
    export BREW_HOME="/home/linuxbrew/.linuxbrew"
fi
[[ -n "$BREW_HOME" ]] && export PATH="$PATH:$BREW_HOME/bin"

# Node.js (nvm) - 按需加载
export NVM_DIR="$HOME/.nvm"
_load_file "$BREW_HOME/opt/nvm/nvm.sh"
_load_file "$BREW_HOME/opt/nvm/etc/bash_completion.d/nvm"

# Rust 环境 - 按需加载
_load_file "$HOME/.cargo/env"

# Java 开发环境（仅 macOS，按需加载）
if _is_macos; then
    _load_dir_to_path "/usr/local/java/jdk8/Contents/Home" "JAVA_HOME"
    _load_dir_to_path "/Applications/IntelliJ IDEA.app/Contents/plugins/maven/lib/maven3" "MAVEN_HOME"
    _load_dir_to_path "/opt/homebrew/Cellar/mysql-client@8.0/8.0.41" "MYSQL_HOME"
fi

# Python (pyenv) - 按需加载
if [[ -d "$HOME/.pyenv" ]]; then
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    _load_if_command pyenv 'eval "$(pyenv init - zsh)"'
fi

# 编辑器
if command -v nvim >/dev/null 2>&1; then
    export EDITOR=nvim
else
    export EDITOR=vim
fi

# 确保 PATH 导出
export PATH

# =============================================================================
# Clash 代理配置 (Linux)
# =============================================================================

if _is_linux; then
    _load_file "/opt/clash/script/common.sh"
    _load_file "/opt/clash/script/clashctl.sh"
fi

# =============================================================================
# 别名配置
# =============================================================================

# 通用别名
alias ll='ls -lF'

# Vim/Neovim 别名
if command -v nvim &>/dev/null; then
    alias vim='nvim'
    alias vi='vi'
else
    alias vim='vim'
    alias vi='vi'
fi

# Tmux 别名
_load_if_command tmux 'alias tmux="tmux -f ~/.config/tmux/tmux.conf"'

# =============================================================================
# 函数定义
# =============================================================================

# 代理开启函数
proxy_on() {
    local host="127.0.0.1"
    local http_port=7897
    local socks5_port=7897
    
    # 端口检测
    if nc -z $host $http_port >/dev/null 2>&1; then
        export https_proxy="http://$host:$http_port"
        export http_proxy="http://$host:$http_port"
        export all_proxy="socks5://$host:$socks5_port"
        return 0
    fi
    
    return 1
}

# 代理关闭函数
proxy_off() {
    unset http_proxy https_proxy all_proxy
}

# =============================================================================
# macOS 专用配置
# =============================================================================

if _is_macos; then
    # rm 命令替换为 trash（如果 trash 命令存在）
    if command -v trash &>/dev/null; then
        alias rm-real='/bin/rm'
        
        rm() {
            local files=()
            
            # 只收集不是以 - 开头的参数
            for arg in "$@"; do
                if [[ "$arg" != -* ]]; then
                    files+=("$arg")
                fi
            done
            
            if [[ ${#files[@]} -eq 0 ]]; then
                echo "⚠️  未检测到有效的文件路径（所有参数均为选项）"
                return 1
            fi
            
            # 调用 trash 删除
            command trash "${files[@]}"
        }
    fi
fi

# =============================================================================
# TODO: 待整理内容
# =============================================================================

# fzf 终端搜索配置
_load_if_command_source_result fzf --zsh

# 只在交互式 TTY 且不是脚本/IDE 调用时自动进入 tmux
if [[ -t 1 ]] && [[ $- == *i* ]] && [ -z "$TMUX" ] && [[ "$TERM_PROGRAM" == "iTerm.app" ]]; then
  tmux attach -t ${tmux_session:-main} || tmux new -s ${tmux_session:-main}
fi

# 启动时自动开启代理
proxy_on
