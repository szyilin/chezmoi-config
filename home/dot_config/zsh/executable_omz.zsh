# 启用 Powerlevel10k 的即时提示功能，应当放在 ~/.zshrc 文件的顶部附近。
# 需要进行控制台交互（如密码输入、[y/n] 确认等）的初始化代码必须写在这个代码块之前；其它初始化内容可以写在它之后。
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# 设置主题，powerlevel10k
ZSH_THEME="powerlevel10k/powerlevel10k"

# 加载插件
plugins=(
  git
  colored-man-pages # man 命令文档自动语法高亮（自带插件，无需安装）
  zsh-autosuggestions # 语法补全 -> 箭头选中提示的补全内容
  zsh-syntax-highlighting # 语法高亮
)

# 加载 Oh My Zsh
[[ -f $ZSH/oh-my-zsh.sh ]] && source $ZSH/oh-my-zsh.sh

# 加载 Powerlevel10k 配置
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# =============================================================================
# Powerlevel10k 自定义覆盖配置
# =============================================================================
# 执行时间配置
# 精度：3 = 毫秒级（0 = 秒，1 = 十分之一秒，2 = 百分之一秒，3 = 毫秒）
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_PRECISION=3
# 阈值：只有超过此秒数才显示执行时间（例如：0.1 表示 100 毫秒以上才显示）
# 如果设置为 0，则所有命令都会显示执行时间（可能导致提示行过长）
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=0.1