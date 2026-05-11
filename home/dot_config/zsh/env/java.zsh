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
    
    # Maven
    if [[ -d "/Applications/IntelliJ IDEA.app/Contents/plugins/maven/lib/maven3" ]]; then
        export MAVEN_HOME="/Applications/IntelliJ IDEA.app/Contents/plugins/maven/lib/maven3"
        append_to_path "$MAVEN_HOME/bin"
    fi
    
    # MySQL Client
    if [[ -d "$BREW_HOME/Cellar/mysql-client@8.0/8.0.41" ]]; then
        export MYSQL_HOME="$BREW_HOME/Cellar/mysql-client@8.0/8.0.41"
        append_to_path "$MYSQL_HOME/bin"
    fi
fi
