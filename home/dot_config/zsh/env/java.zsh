#!/usr/bin/env zsh
# =============================================================================
# Java 开发环境配置（仅 macOS）
# =============================================================================

[[ -n ${__XKD_ZSH_ENV_JAVA_LOADED:-} ]] && return
typeset -g __XKD_ZSH_ENV_JAVA_LOADED=1

if is_macos; then
    # JDK
    if [[ -d "$HOME/.local/share/java/jdk21/Contents/Home" ]]; then
        export JAVA_HOME="$HOME/.local/share/java/jdk21/Contents/Home"
        append_to_path "$JAVA_HOME/bin"
    fi

    # Maven：用 Homebrew opt 软链，避免 Cellar 版本号升级后失效
    # 安装由 mybrew.json 的 maven formula 负责；此处只导出 M2_HOME
    _xkd_setup_maven_home() {
        local maven_home=""
        local maven_prefix=""
        if [[ -n "${BREW_HOME:-}" && -d "$BREW_HOME/opt/maven/libexec" ]]; then
            maven_home="$BREW_HOME/opt/maven/libexec"
        elif command -v brew >/dev/null 2>&1; then
            maven_prefix="$(brew --prefix maven 2>/dev/null)" || maven_prefix=""
            if [[ -n "$maven_prefix" && -d "$maven_prefix/libexec" ]]; then
                maven_home="$maven_prefix/libexec"
            fi
        fi
        if [[ -n "$maven_home" ]]; then
            export M2_HOME="$maven_home"
            append_to_path "$M2_HOME/bin"
        fi
    }
    _xkd_setup_maven_home
    unset -f _xkd_setup_maven_home

    # MySQL Client
    if [[ -d "$BREW_HOME/Cellar/mysql-client@8.0/8.0.41" ]]; then
        export MYSQL_HOME="$BREW_HOME/Cellar/mysql-client@8.0/8.0.41"
        append_to_path "$MYSQL_HOME/bin"
    fi
fi
