#!/usr/bin/env zsh
# =============================================================================
# Rust 环境配置
# =============================================================================
#
# 官方推荐入口仍是 ~/.cargo/bin（见 rust-lang.org / rustup book）。
# 本机 rustup 由 Homebrew 安装；chezmoi 将 ~/.cargo/bin/rustup 绝对链接到
# $(brew --prefix rustup)/libexec/bin/rustup，以修复公式去掉 rustup-init 后的断链。
# 其余 rustc/cargo 等代理仍相对指向同目录下的 rustup，无需改动。
# =============================================================================

[[ -n ${__XKD_ZSH_ENV_RUST_LOADED:-} ]] && return
typeset -g __XKD_ZSH_ENV_RUST_LOADED=1

# 加载 Rust 环境（将 ~/.cargo/bin 加入 PATH）
load_if_exists "$HOME/.cargo/env"
