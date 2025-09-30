#!/usr/bin/env python3
"""
Homebrew 包管理工具 - Chezmoi 环境专用版

这是 Chezmoi 环境初始化工具的组成部分，专门负责 Homebrew 软件包的管理。
设计遵循 Chezmoi 项目的模块化架构和风格规范。

🎯 核心功能:
- 智能包管理: 自动检测已安装包，避免重复安装
- 配置同步: 基于 resources/mybrew.json 的包配置管理
- 跨平台支持: 支持 macOS (Darwin) 和 Linux 平台的包列表
- 备份恢复: 双向同步，支持包列表的备份和恢复

🏗️ 架构集成:
- 资源定位: 优先使用 CHEZMOI_PROJECT_ROOT 环境变量
- 日志风格: 与主脚本保持一致的输出格式
- 环境变量: 遵循 MANUAL_CONFIRM 约定
- 错误处理: 返回错误码而非直接退出

🚀 使用方式:
- 通过模块调用: ./install.zsh packages (自动模式)
- 独立命令使用: mybrew.py install (交互模式)
- 配置备份: mybrew.py backup (将当前安装的包备份到配置)

💡 设计理念:
这个工具体现了"模块内分层实现"的设计思想 - 模块对外提供统一接口，
内部可以调用专业化的脚本来处理复杂逻辑，既保持了模块的简洁性，
又获得了专业工具的强大功能。
"""

import json
import platform
import subprocess
import sys
import time
import os
from pathlib import Path
from shutil import which
from typing import Dict, List, Tuple, Set


# ANSI 颜色代码
class Colors:
    RED = '\033[91m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    MAGENTA = '\033[95m'
    CYAN = '\033[96m'
    WHITE = '\033[97m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'
    END = '\033[0m'


def print_colored(text: str, color: str = Colors.WHITE, bold: bool = False):
    """打印彩色文本"""
    style = Colors.BOLD if bold else ""
    print(f"{style}{color}{text}{Colors.END}")


def log_success(text: str):
    """打印成功信息 (与主脚本风格一致)"""
    print_colored(f"✅ {text}", Colors.GREEN, bold=True)


def log_error(text: str):
    """打印错误信息 (与主脚本风格一致)"""
    print_colored(f"❌ {text}", Colors.RED, bold=True)


def log_warn(text: str):
    """打印警告信息 (与主脚本风格一致)"""
    print_colored(f"⚠️  {text}", Colors.YELLOW)


def log_info(text: str):
    """打印信息 (与主脚本风格一致)"""
    print_colored(f"ℹ️  {text}", Colors.BLUE)


# 兼容性别名 (保持向后兼容)
print_success = log_success
print_error = log_error
print_warning = log_warn
print_info = log_info


def print_step(step: int, total: int, text: str):
    """打印步骤信息"""
    print_colored(f"[{step}/{total}] {text}", Colors.CYAN, bold=True)


def print_header(text: str):
    """打印标题"""
    print_colored(f"\n🍺 {text}", Colors.MAGENTA, bold=True)
    print_colored("=" * (len(text) + 4), Colors.MAGENTA)


def resolve_config_path() -> Tuple[Path, bool]:
    """
    解析配置文件路径 (优化版)
    
    优先级:
    1) CHEZMOI_PROJECT_ROOT 环境变量 (与主脚本架构一致)
    2) 相对当前脚本向上查找
    3) 使用 chezmoi source-path 查找
    
    Returns:
        (config_path, success)
    """
    # 1. 优先使用主脚本设置的环境变量
    if chezmoi_root := os.environ.get('CHEZMOI_PROJECT_ROOT'):
        config_path = Path(chezmoi_root) / "resources" / "mybrew.json"
        if config_path.exists():
            return config_path, True
        log_warn(f"CHEZMOI_PROJECT_ROOT 已设置但配置文件不存在: {config_path}")
    
    # 2. 相对脚本路径查找
    script_path = Path(__file__).resolve()
    for anc in [script_path.parent] + list(script_path.parents):
        config_path = anc / "resources" / "mybrew.json"
        if config_path.exists():
            return config_path, True
    
    # 3. 退回 chezmoi 源目录查找
    try:
        result = subprocess.run(["zsh", "-lc", "chezmoi source-path"], 
                               capture_output=True, text=True, check=True)
        src_dir = Path(result.stdout.strip())
        config_path = src_dir / ".." / "resources" / "mybrew.json"
        if config_path.exists():
            return config_path, True
    except Exception:
        pass
    
    log_error("未找到配置文件 resources/mybrew.json")
    log_info("请确保它存在于以下位置之一:")
    log_info("  1. $CHEZMOI_PROJECT_ROOT/resources/mybrew.json")
    log_info("  2. chezmoi 源目录的 resources/mybrew.json")
    return Path(), False


def load_config(config_path: Path) -> Tuple[Dict, bool]:
    """
    加载并解析配置文件 (优化版)
    
    Returns:
        (config_dict, success)
    """
    if not config_path.exists():
        log_error(f"配置文件不存在: {config_path}")
        return {}, False
    
    try:
        with open(config_path, "r", encoding="utf-8") as f:
            config = json.load(f)
            return config, True
    except json.JSONDecodeError as e:
        log_error(f"配置文件格式错误: {e}")
        log_info(f"请检查 JSON 语法: {config_path}")
        return {}, False
    except Exception as e:
        log_error(f"读取配置文件失败: {e}")
        return {}, False


def save_config(config_path: Path, cfg: Dict) -> bool:
    """
    原子性保存配置文件 (优化版)
    
    Returns:
        success: bool
    """
    try:
        tmp = config_path.with_suffix(".tmp.json")
        with open(tmp, "w", encoding="utf-8") as f:
            json.dump(cfg, f, ensure_ascii=False, indent=2)
        tmp.replace(config_path)
        return True
    except Exception as e:
        log_error(f"保存配置文件失败: {e}")
        log_info(f"请检查文件权限: {config_path}")
        return False


def detect_os_key() -> Tuple[str, bool]:
    """
    检测操作系统 (优化版)
    
    Returns:
        (os_key, success)
    """
    sysname = platform.system()
    if sysname == "Darwin":
        return "Darwin", True
    if sysname == "Linux":
        return "Linux", True
    
    log_error(f"不支持的系统: {sysname}")
    log_info("支持的系统: macOS (Darwin), Linux")
    return "", False


def ensure_brew() -> bool:
    """
    检查 Homebrew 是否可用 (优化版)
    
    Returns:
        success: bool
    """
    if which("brew") is None:
        log_error("需要 Homebrew 包管理器")
        log_info("请先安装 Homebrew:")
        log_info("  1. 运行初始化脚本: ./install.zsh homebrew")
        log_info("  2. 或手动安装: /bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"")
        log_info("  3. 官方网站: https://brew.sh/")
        return False
    return True


def get_brew_info() -> Dict:
    """获取 brew 版本和环境信息"""
    try:
        result = subprocess.run(["brew", "--version"], capture_output=True, text=True, check=True)
        version = result.stdout.strip().split('\n')[0]
        
        result = subprocess.run(["brew", "--prefix"], capture_output=True, text=True, check=True)
        prefix = result.stdout.strip()
        
        return {"version": version, "prefix": prefix}
    except Exception:
        return {"version": "未知", "prefix": "未知"}


def check_package_status(package_name: str) -> Tuple[bool, str]:
    """
    检查包的安装状态
    
    Returns:
        (is_installed, status_detail)
    """
    try:
        # 检查是否在 PATH 中
        if which(package_name.split('/')[-1]):
            return True, "已安装 (PATH 可用)"
        
        # 检查 brew list
        result = subprocess.run(["brew", "list", package_name], 
                              capture_output=True, text=True)
        if result.returncode == 0:
            return True, "已安装 (brew)"
        else:
            return False, "未安装"
    except Exception:
        return False, "状态未知"


def display_package_summary(packages: Dict, os_key: str):
    """显示包概览"""
    print_info(f"系统: {os_key}")
    print_info(f"总包数: {len(packages)}")
    
    default_count = sum(1 for pkg in packages.values() if pkg.get("default", False))
    print_info(f"默认安装: {default_count} 个")
    print_info(f"可选安装: {len(packages) - default_count} 个")


def interactive_package_selection(packages: Dict) -> Tuple[List[str], List[str]]:
    """
    交互式包选择，支持分组显示和智能选择
    
    Returns:
        (selected_packages, skipped_packages)
    """
    print_header("包选择模式")
    
    # 按状态分组
    installed = []
    not_installed = []
    unknown = []
    
    print_info("正在检查包状态...")
    for name in packages.keys():
        is_installed, status = check_package_status(name)
        if is_installed:
            installed.append((name, status))
        elif "未知" in status:
            unknown.append((name, status))
        else:
            not_installed.append((name, status))
    
    # 显示状态概览
    print()
    if installed:
        print_success(f"已安装包 ({len(installed)} 个):")
        for name, status in installed:
            print(f"  • {name} - {status}")
    
    if not_installed:
        print_warning(f"未安装包 ({len(not_installed)} 个):")
        for name, status in not_installed:
            is_default = packages[name].get("default", False)
            default_marker = " [默认]" if is_default else ""
            print(f"  • {name} - {status}{default_marker}")
    
    if unknown:
        print_info(f"状态未知包 ({len(unknown)} 个):")
        for name, status in unknown:
            print(f"  • {name} - {status}")
    
    print()
    
    # 选择模式
    print_colored("选择安装模式:", Colors.WHITE, bold=True)
    print("1. 仅安装默认包 (推荐)")
    print("2. 跳过已安装，安装剩余默认包")
    print("3. 交互式选择所有包")
    print("4. 安装所有未安装的包")
    print("5. 取消安装")
    
    # 检查确认模式 (与主脚本环境变量一致)
    if os.environ.get('MANUAL_CONFIRM', 'false') != 'true':
        log_info("自动确认模式: 选择模式 2 (跳过已安装，安装剩余默认包)")
        choice = "2"
    else:
        choice = input("\n请选择模式 [1-5]: ").strip()
    
    while True:
        if choice == "1":
            # 仅默认包
            selected = [name for name, meta in packages.items() 
                       if meta.get("default", False)]
            break
        elif choice == "2":
            # 跳过已安装的默认包
            selected = [name for name, meta in packages.items() 
                       if meta.get("default", False) and not check_package_status(name)[0]]
            break
        elif choice == "3":
            # 交互式选择
            selected = []
            print_info("交互式选择包 (输入 y=选择, n=跳过, q=退出选择):")
            for name in not_installed + unknown:
                pkg_name = name[0] if isinstance(name, tuple) else name
                is_default = packages[pkg_name].get("default", False)
                default_hint = " [默认]" if is_default else ""
                
                while True:
                    ans = input(f"  安装 {pkg_name}{default_hint}? [y/n/q]: ").strip().lower()
                    if ans in ['y', 'yes', '']:
                        selected.append(pkg_name)
                        break
                    elif ans in ['n', 'no']:
                        break
                    elif ans in ['q', 'quit']:
                        print_warning("退出选择")
                        return selected, []
                    else:
                        print_warning("请输入 y, n 或 q")
            break
        elif choice == "4":
            # 安装所有未安装的包
            selected = [name[0] if isinstance(name, tuple) else name 
                       for name in not_installed + unknown]
            break
        elif choice == "5":
            print_warning("取消安装")
            return [], []
        else:
            if os.environ.get('MANUAL_CONFIRM', 'false') != 'true':
                # 自动确认模式下，默认选择模式2并跳出循环
                break
            print_warning("请输入 1-5 之间的数字")
            choice = input("\n请选择模式 [1-5]: ").strip()
    
    # 过滤已安装的包
    final_selected = []
    skipped = []
    
    for name in selected:
        is_installed, status = check_package_status(name)
        if is_installed:
            skipped.append(name)
        else:
            final_selected.append(name)
    
    return final_selected, skipped


def install_packages(packages: List[str]) -> Tuple[List[str], List[str]]:
    """
    安装包列表
    
    Returns:
        (successful_packages, failed_packages)
    """
    if not packages:
        print_warning("没有需要安装的包")
        return [], []
    
    print_header(f"开始安装 {len(packages)} 个包")
    
    successful = []
    failed = []
    
    for i, package in enumerate(packages, 1):
        print_step(i, len(packages), f"安装 {package}")
        
        try:
            cmd = ["brew", "install", package]
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
            
            if result.returncode == 0:
                print_success(f"安装成功: {package}")
                successful.append(package)
            else:
                error_msg = result.stderr.strip() or result.stdout.strip()
                print_error(f"安装失败: {package}")
                print_info(f"错误信息: {error_msg}")
                failed.append(package)
        
        except subprocess.TimeoutExpired:
            print_error(f"安装超时: {package} (5分钟)")
            failed.append(package)
        except Exception as e:
            print_error(f"安装异常: {package} - {e}")
            failed.append(package)
        
        print()
    
    return successful, failed


def install_cmd() -> bool:
    """
    安装命令主入口 (优化版)
    
    Returns:
        success: bool
    """
    print_header("Homebrew 包安装工具")
    
    # 检查环境
    if not ensure_brew():
        return False
    
    brew_info = get_brew_info()
    log_info(f"Homebrew: {brew_info['version']}")
    log_info(f"安装路径: {brew_info['prefix']}")
    print()
    
    # 加载配置
    config_path, config_success = resolve_config_path()
    if not config_success:
        return False
    
    cfg, load_success = load_config(config_path)
    if not load_success:
        return False
    
    os_key, os_success = detect_os_key()
    if not os_success:
        return False
    
    packages = cfg.get(os_key, {}).get("package", {})
    if not packages:
        log_error("配置文件中没有定义包")
        log_info(f"请检查 {config_path} 中的 {os_key}.package 配置")
        return False
    
    print_info(f"配置文件: {config_path}")
    display_package_summary(packages, os_key)
    print()
    
    # 包选择
    selected_packages, skipped_packages = interactive_package_selection(packages)
    
    if not selected_packages and not skipped_packages:
        log_info("没有选择任何包，退出安装")
        return True
    
    # 显示安装计划
    if selected_packages:
        print_info(f"计划安装: {len(selected_packages)} 个包")
        for pkg in selected_packages:
            print(f"  • {pkg}")
    
    if skipped_packages:
        print_warning(f"跳过已安装: {len(skipped_packages)} 个包")
        for pkg in skipped_packages:
            print(f"  • {pkg}")
    
    if selected_packages:
        print()
        # 使用统一的确认逻辑
        if os.environ.get('MANUAL_CONFIRM', 'false') == 'true':
            confirm = input("确认开始安装? [Y/n]: ").strip().lower()
            if confirm == 'n':
                log_warn("用户取消安装")
                return True
        else:
            log_info("自动确认模式: 开始安装")
        
        # 执行安装
        successful, failed = install_packages(selected_packages)
        
        # 安装总结
        print_header("安装完成统计")
        
        success_overall = True
        
        if successful:
            log_success(f"成功安装: {len(successful)} 个包")
            for pkg in successful:
                print(f"  ✅ {pkg}")
        
        if failed:
            log_error(f"安装失败: {len(failed)} 个包")
            for pkg in failed:
                print(f"  ❌ {pkg}")
            log_info("建议手动检查失败的包或重新运行安装")
            success_overall = False
        
        if skipped_packages:
            log_info(f"跳过已安装: {len(skipped_packages)} 个包")
        
        return success_overall
    else:
        log_success("所有相关包都已安装")
        return True


def dump_brewfile_text() -> str:
    """生成 Brewfile 文本"""
    try:
        cmd = [
            "bash", "-c",
            "tmp=$(mktemp -d) && cd \"$tmp\" && "
            "brew bundle dump --describe --file=Brewfile --force >/dev/null 2>&1 && "
            "cat Brewfile"
        ]
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
        return result.stdout if result.returncode == 0 else ""
    except Exception:
        return ""


def parse_brewfile_formulae(brewfile_text: str) -> List[str]:
    """从 Brewfile 解析 formula 列表"""
    formulae = []
    for line in brewfile_text.splitlines():
        line = line.strip()
        if line.startswith('brew "'):
            try:
                name = line.split('"', 2)[1]
                if name:
                    formulae.append(name)
            except Exception:
                continue
    return sorted(set(formulae))


def get_installed_packages() -> List[str]:
    """获取已安装的包列表"""
    brewfile_text = dump_brewfile_text()
    if not brewfile_text:
        print_warning("无法获取已安装包列表")
        return []
    return parse_brewfile_formulae(brewfile_text)


def backup_cmd() -> bool:
    """
    备份命令主入口 (优化版)
    
    Returns:
        success: bool
    """
    print_header("Homebrew 包备份工具")
    
    # 检查环境
    if not ensure_brew():
        return False
    
    brew_info = get_brew_info()
    log_info(f"Homebrew: {brew_info['version']}")
    log_info(f"安装路径: {brew_info['prefix']}")
    print()
    
    # 加载配置
    config_path, config_success = resolve_config_path()
    if not config_success:
        return False
    
    cfg, load_success = load_config(config_path)
    if not load_success:
        return False
    
    os_key, os_success = detect_os_key()
    if not os_success:
        return False
    
    log_info(f"配置文件: {config_path}")
    log_info(f"目标系统: {os_key}")
    print()
    
    # 获取已安装包
    print_info("正在扫描已安装的包...")
    installed_packages = get_installed_packages()
    
    if not installed_packages:
        log_warn("没有发现已安装的包")
        return True
    
    log_success(f"发现 {len(installed_packages)} 个已安装的包")
    
    # 当前配置中的包
    current_packages = cfg.get(os_key, {}).get("package", {})
    
    # 分析差异
    new_packages = []
    existing_packages = []
    
    for pkg in installed_packages:
        if pkg in current_packages:
            existing_packages.append(pkg)
        else:
            new_packages.append(pkg)
    
    print()
    if existing_packages:
        print_info(f"配置中已存在: {len(existing_packages)} 个包")
    
    if new_packages:
        print_warning(f"新发现的包: {len(new_packages)} 个")
        for pkg in new_packages:
            print(f"  • {pkg}")
        print()
        
        # 询问是否合并
        merge = input("是否将新包合并到配置文件? [Y/n]: ").strip().lower()
        if merge != 'n':
            # 合并新包
            node = cfg.setdefault(os_key, {})
            packages = node.setdefault("package", {})
            
            for pkg in new_packages:
                packages[pkg] = {"default": False}
            
            # 保存配置
            if save_config(config_path, cfg):
                log_success(f"成功合并 {len(new_packages)} 个新包到配置文件")
                log_info("新包默认设置为 default: false")
                log_info("如需设为默认安装，请手动编辑配置文件")
                return True
            else:
                log_error("保存配置文件失败")
                return False
        else:
            log_info("跳过合并操作")
            return True
    else:
        log_success("没有发现新包，配置文件已是最新")
        return True


def print_usage():
    """打印使用说明 (优化版)"""
    print_colored("🍺 Homebrew 包管理工具 - Chezmoi 环境专用版", Colors.CYAN, bold=True)
    print()
    print_colored("用法:", Colors.WHITE, bold=True)
    print("  mybrew.py install  - 安装配置文件中的包")
    print("  mybrew.py backup   - 备份当前已安装的包到配置文件")
    print("  mybrew.py --help   - 显示此帮助信息")
    print()
    print_colored("🏗️ 架构集成:", Colors.WHITE, bold=True)
    print("  • 与 Chezmoi 环境初始化工具深度集成")
    print("  • 支持通过模块调用: ./install.zsh packages")
    print("  • 配置文件通过 chezmoi 进行版本控制")
    print("  • 遵循统一的日志格式和环境变量约定")
    print()
    print_colored("🎯 功能特性:", Colors.WHITE, bold=True)
    print("  • 智能包状态检测，避免重复安装")
    print("  • 友好的彩色交互界面")
    print("  • 详细的安装进度和统计信息")
    print("  • 支持多种安装模式选择")
    print("  • 自动备份已安装包到配置文件")
    print("  • 跨平台支持 (macOS/Linux)")
    print()
    print_colored("📋 安装模式:", Colors.GREEN, bold=True)
    print("  1️⃣  仅安装默认包 (推荐新环境)")
    print("  2️⃣  跳过已安装，安装剩余默认包 (推荐)")
    print("  3️⃣  交互式选择包")
    print("  4️⃣  安装所有未安装的包")
    print("  5️⃣  取消安装")
    print()
    print_colored("🔧 环境变量:", Colors.BLUE, bold=True)
    print("  MANUAL_CONFIRM=true   - 启用手动确认模式")
    print("  CHEZMOI_PROJECT_ROOT  - 指定 chezmoi 项目根目录")
    print()
    print_colored("💡 使用示例:", Colors.YELLOW, bold=True)
    print("  # 自动安装默认包")
    print("  mybrew.py install")
    print()
    print("  # 手动确认模式")
    print("  MANUAL_CONFIRM=true mybrew.py install")
    print()
    print("  # 备份当前安装的包")
    print("  mybrew.py backup")


def main() -> int:
    """
    程序入口 (优化版)
    
    Returns:
        exit_code: int (0=成功, 1=失败)
    """
    if len(sys.argv) < 2 or sys.argv[1] in ("-h", "--help", "help"):
        print_usage()
        return 0
    
    cmd = sys.argv[1].lower()
    
    try:
        success = False
        
        if cmd == "install":
            success = install_cmd()
        elif cmd == "backup":
            success = backup_cmd()
        else:
            log_error(f"未知命令: {cmd}")
            print_usage()
            return 1
        
        # 根据执行结果返回相应的退出码
        return 0 if success else 1
        
    except KeyboardInterrupt:
        log_warn("\n\n用户中断操作")
        return 0
    except Exception as e:
        log_error(f"程序运行时发生错误: {e}")
        log_info("请检查网络连接和 Homebrew 环境")
        return 1


if __name__ == "__main__":
    sys.exit(main())


