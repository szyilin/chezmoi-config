#!/usr/bin/env zsh
# =============================================================================
# 代理管理
# 跨平台自动探测终端代理配置，优先复用系统已开启的代理能力
# =============================================================================

# 默认本地代理地址
: "${PROXY_DETECT_HOST:=127.0.0.1}"

# 常见本地代理端口候选
typeset -ga PROXY_HTTP_PORT_CANDIDATES
typeset -ga PROXY_SOCKS_PORT_CANDIDATES

if [[ ${#PROXY_HTTP_PORT_CANDIDATES[@]} -eq 0 ]]; then
    PROXY_HTTP_PORT_CANDIDATES=(7890 7897 20171 1080)
fi

if [[ ${#PROXY_SOCKS_PORT_CANDIDATES[@]} -eq 0 ]]; then
    PROXY_SOCKS_PORT_CANDIDATES=(7891 7897 20170 1086 1087 1080)
fi

_proxy_port_open() {
    local host="$1"
    local port="$2"

    if command -v nc >/dev/null 2>&1; then
        nc -z "$host" "$port" >/dev/null 2>&1
        return $?
    fi

    if command -v lsof >/dev/null 2>&1; then
        lsof -nP -iTCP:"$port" -sTCP:LISTEN 2>/dev/null | grep -q LISTEN
        return $?
    fi

    return 1
}

_proxy_has_env() {
    [[ -n "${http_proxy:-}${https_proxy:-}${all_proxy:-}${HTTP_PROXY:-}${HTTPS_PROXY:-}${ALL_PROXY:-}" ]]
}

_proxy_parse_url() {
    local raw="$1"
    local default_scheme="${2:-http}"
    local scheme host port

    raw="${raw#*://}"
    if [[ "$1" == *"://"* ]]; then
        scheme="${1%%://*}"
    else
        scheme="$default_scheme"
    fi

    host="${raw%%:*}"
    port="${raw##*:}"

    [[ -n "$host" && -n "$port" && "$host" != "$port" ]] || return 1
    print -r -- "$scheme|$host|$port"
}

_proxy_detect_from_env() {
    local parsed=""

    if [[ -n "${http_proxy:-}" ]]; then
        parsed="$(_proxy_parse_url "$http_proxy" "http")" || return 1
        print -r -- "$parsed|env"
        return 0
    fi

    if [[ -n "${https_proxy:-}" ]]; then
        parsed="$(_proxy_parse_url "$https_proxy" "http")" || return 1
        print -r -- "$parsed|env"
        return 0
    fi

    if [[ -n "${all_proxy:-}" ]]; then
        parsed="$(_proxy_parse_url "$all_proxy" "socks5")" || return 1
        print -r -- "$parsed|env"
        return 0
    fi

    return 1
}

_proxy_detect_macos() {
    command -v scutil >/dev/null 2>&1 || return 1

    local proxy_info
    proxy_info="$(scutil --proxy 2>/dev/null)" || return 1

    local http_enabled http_host http_port
    local https_enabled https_host https_port
    local socks_enabled socks_host socks_port

    http_enabled="$(echo "$proxy_info" | awk '/HTTPEnable/ {print $3; exit}')"
    http_host="$(echo "$proxy_info" | awk '/HTTPProxy/ {print $3; exit}')"
    http_port="$(echo "$proxy_info" | awk '/HTTPPort/ {print $3; exit}')"
    https_enabled="$(echo "$proxy_info" | awk '/HTTPSEnable/ {print $3; exit}')"
    https_host="$(echo "$proxy_info" | awk '/HTTPSProxy/ {print $3; exit}')"
    https_port="$(echo "$proxy_info" | awk '/HTTPSPort/ {print $3; exit}')"
    socks_enabled="$(echo "$proxy_info" | awk '/SOCKSEnable/ {print $3; exit}')"
    socks_host="$(echo "$proxy_info" | awk '/SOCKSProxy/ {print $3; exit}')"
    socks_port="$(echo "$proxy_info" | awk '/SOCKSPort/ {print $3; exit}')"

    if [[ "$http_enabled" == "1" && -n "$http_host" && -n "$http_port" ]]; then
        print -r -- "http|$http_host|$http_port|system"
        return 0
    fi

    if [[ "$https_enabled" == "1" && -n "$https_host" && -n "$https_port" ]]; then
        print -r -- "http|$https_host|$https_port|system"
        return 0
    fi

    if [[ "$socks_enabled" == "1" && -n "$socks_host" && -n "$socks_port" ]]; then
        print -r -- "socks5|$socks_host|$socks_port|system"
        return 0
    fi

    return 1
}

_proxy_detect_linux() {
    command -v gsettings >/dev/null 2>&1 || return 1

    local mode http_host http_port socks_host socks_port
    mode="$(gsettings get org.gnome.system.proxy mode 2>/dev/null | tr -d "'")" || return 1
    [[ "$mode" == "manual" ]] || return 1

    http_host="$(gsettings get org.gnome.system.proxy.http host 2>/dev/null | tr -d "'")"
    http_port="$(gsettings get org.gnome.system.proxy.http port 2>/dev/null)"
    socks_host="$(gsettings get org.gnome.system.proxy.socks host 2>/dev/null | tr -d "'")"
    socks_port="$(gsettings get org.gnome.system.proxy.socks port 2>/dev/null)"

    if [[ -n "$http_host" && -n "$http_port" && "$http_port" != "0" ]]; then
        print -r -- "http|$http_host|$http_port|system"
        return 0
    fi

    if [[ -n "$socks_host" && -n "$socks_port" && "$socks_port" != "0" ]]; then
        print -r -- "socks5|$socks_host|$socks_port|system"
        return 0
    fi

    return 1
}

_proxy_detect_local_ports() {
    local host="${PROXY_DETECT_HOST}"
    local port

    for port in "${PROXY_HTTP_PORT_CANDIDATES[@]}"; do
        if _proxy_port_open "$host" "$port"; then
            print -r -- "http|$host|$port|port-scan"
            return 0
        fi
    done

    for port in "${PROXY_SOCKS_PORT_CANDIDATES[@]}"; do
        if _proxy_port_open "$host" "$port"; then
            print -r -- "socks5|$host|$port|port-scan"
            return 0
        fi
    done

    return 1
}

proxy_detect() {
    local detected=""

    if detected="$(_proxy_detect_from_env)"; then
        print -r -- "$detected"
        return 0
    fi

    if is_macos && detected="$(_proxy_detect_macos)"; then
        print -r -- "$detected"
        return 0
    fi

    if is_linux && detected="$(_proxy_detect_linux)"; then
        print -r -- "$detected"
        return 0
    fi

    if detected="$(_proxy_detect_local_ports)"; then
        print -r -- "$detected"
        return 0
    fi

    return 1
}

_proxy_export_uppercase() {
    [[ -n "${http_proxy:-}" ]] && export HTTP_PROXY="$http_proxy"
    [[ -n "${https_proxy:-}" ]] && export HTTPS_PROXY="$https_proxy"
    [[ -n "${all_proxy:-}" ]] && export ALL_PROXY="$all_proxy"
}

proxy_on() {
    local detected protocol host port source

    if _proxy_has_env; then
        echo "✓ 代理环境变量已存在，保持当前配置"
        return 0
    fi

    detected="$(proxy_detect)" || {
        echo "✗ 未检测到可用代理"
        return 1
    }

    IFS='|' read -r protocol host port source <<<"$detected"

    case "$protocol" in
        http)
            export http_proxy="http://$host:$port"
            export https_proxy="http://$host:$port"
            unset all_proxy ALL_PROXY
            ;;
        socks5)
            export all_proxy="socks5://$host:$port"
            unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
            ;;
        *)
            echo "✗ 不支持的代理协议: $protocol"
            return 1
            ;;
    esac

    _proxy_export_uppercase
    echo "✓ 代理已开启 ($protocol://$host:$port, source=$source)"
}

proxy_off() {
    unset http_proxy https_proxy all_proxy
    unset HTTP_PROXY HTTPS_PROXY ALL_PROXY
    echo "✓ 代理已关闭"
}

proxy_refresh() {
    proxy_off >/dev/null
    proxy_on
}

proxy_status() {
    local detected=""

    echo "Proxy env:"
    echo "  http_proxy=${http_proxy:-<empty>}"
    echo "  https_proxy=${https_proxy:-<empty>}"
    echo "  all_proxy=${all_proxy:-<empty>}"

    if detected="$(proxy_detect 2>/dev/null)"; then
        local protocol host port source
        IFS='|' read -r protocol host port source <<<"$detected"
        echo "Detected:"
        echo "  protocol=$protocol"
        echo "  host=$host"
        echo "  port=$port"
        echo "  source=$source"
    else
        echo "Detected:"
        echo "  <none>"
    fi
}

# 交互式 shell 启动时自动尝试启用代理，但不覆盖已有环境变量
if [[ $- == *i* ]]; then
    proxy_on >/dev/null 2>&1 || true
fi
