#!/usr/bin/env zsh
# =============================================================================
# 用户函数定义
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
        echo "✓ 代理已开启 ($host:$http_port)"
        return 0
    else
        echo "✗ 代理服务未运行 ($host:$http_port)"
        return 1
    fi
}

# 代理关闭函数
proxy_off() {
    unset http_proxy https_proxy all_proxy
    echo "✓ 代理已关闭"
}

# =============================================================================
# 自动启动配置
# =============================================================================

# 只在交互式 TTY 且不是脚本/IDE 调用时自动进入 tmux
if [[ -t 1 ]] && [[ $- == *i* ]] && [ -z "$TMUX" ] && [[ "$TERM_PROGRAM" == "iTerm.app" ]]; then
    tmux attach -t ${tmux_session:-main} || tmux new -s ${tmux_session:-main}
fi

# 启动时自动开启代理
proxy_on
