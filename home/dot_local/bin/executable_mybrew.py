#!/usr/bin/env python3
"""
Homebrew 包管理工具 - Chezmoi 环境专用版

这是 Chezmoi 环境初始化工具的组成部分，专门负责 Homebrew 软件包的管理。
设计遵循 Chezmoi 项目的模块化架构和风格规范。

🎯 核心功能:
- 智能包管理: 自动检测已安装包，避免重复安装
- 配置同步: 基于 resources/mybrew.json 的包配置管理
- 跨平台支持: 支持 macOS (Darwin) 和 Linux 平台的 formula 列表
- Cask 管理: macOS 桌面应用通过独立 cask 配置区块管理
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
import os
from pathlib import Path
from shutil import which
from typing import Dict, List, Tuple, Set

# 包类型常量
PACKAGE_FORMULA = "formula"
PACKAGE_CASK = "cask"
PackageRef = Tuple[str, str]  # (name, kind)


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


def get_installed_formulae() -> Tuple[Set[str], bool]:
    """
    一次性获取已安装的 Homebrew formula 集合

    Returns:
        (installed_formulae, success)
    """
    try:
        result = subprocess.run(
            ["brew", "list", "--formula", "--versions"],
            capture_output=True,
            text=True,
            check=True
        )
    except Exception as e:
        log_warn(f"无法获取 Homebrew 已安装包缓存: {e}")
        return set(), False

    installed = set()
    for line in result.stdout.splitlines():
        line = line.strip()
        if not line:
            continue

        formula = line.split(maxsplit=1)[0]
        if formula:
            installed.add(formula)

    return installed, True


def get_installed_casks() -> Tuple[Set[str], bool]:
    """
    一次性获取已安装的 Homebrew cask 集合 (仅 macOS 有效)

    Returns:
        (installed_casks, success)
    """
    if platform.system() != "Darwin":
        return set(), True

    try:
        result = subprocess.run(
            ["brew", "list", "--cask", "--versions"],
            capture_output=True,
            text=True,
            check=True
        )
    except Exception as e:
        log_warn(f"无法获取 Homebrew 已安装 cask 缓存: {e}")
        return set(), False

    installed = set()
    for line in result.stdout.splitlines():
        line = line.strip()
        if not line:
            continue

        cask = line.split(maxsplit=1)[0]
        if cask:
            installed.add(cask)

    return installed, True


def check_package_status(
    package_name: str,
    package_kind: str,
    installed_formulae: Set[str],
    installed_casks: Set[str],
    cache_ready_formulae: bool,
    cache_ready_casks: bool
) -> Tuple[bool, str]:
    """
    检查包的安装状态

    Returns:
        (is_installed, status_detail)
    """
    if package_kind == PACKAGE_CASK:
        if not cache_ready_casks:
            return False, "状态未知 (cask 缓存不可用)"
        if package_name in installed_casks:
            return True, "已安装 (cask)"
        return False, "未安装"

    if not cache_ready_formulae:
        return False, "状态未知 (formula 缓存不可用)"
    if package_name in installed_formulae:
        return True, "已安装 (formula)"
    return False, "未安装"


def _kind_label(package_kind: str) -> str:
    return "cask" if package_kind == PACKAGE_CASK else "formula"


def display_package_summary(
    formulae: Dict,
    casks: Dict,
    os_key: str
):
    """显示 formula 与 cask 包概览"""
    print_info(f"系统: {os_key}")

    if formulae:
        default_count = sum(1 for pkg in formulae.values() if pkg.get("default", False))
        print_info(f"Formula 总数: {len(formulae)} (默认安装 {default_count} 个)")
    else:
        print_info("Formula: 未配置")

    if os_key == "Darwin":
        if casks:
            default_count = sum(1 for pkg in casks.values() if pkg.get("default", False))
            print_info(f"Cask 总数: {len(casks)} (默认安装 {default_count} 个)")
        else:
            print_info("Cask: 未配置")
    elif casks:
        print_warn(f"当前系统 {os_key} 不支持 cask，已忽略 {len(casks)} 个 cask 配置")


def _categorize_packages(
    packages: Dict,
    package_kind: str,
    installed_formulae: Set[str],
    installed_casks: Set[str],
    cache_ready_formulae: bool,
    cache_ready_casks: bool
) -> Tuple[List[Tuple[str, str]], List[Tuple[str, str]], List[Tuple[str, str]]]:
    """按安装状态分组"""
    installed = []
    not_installed = []
    unknown = []

    for name in packages.keys():
        is_installed, status = check_package_status(
            name,
            package_kind,
            installed_formulae,
            installed_casks,
            cache_ready_formulae,
            cache_ready_casks
        )
        entry = (name, status)
        if is_installed:
            installed.append(entry)
        elif "未知" in status:
            unknown.append(entry)
        else:
            not_installed.append(entry)

    return installed, not_installed, unknown


def _display_package_group(
    title: str,
    installed: List[Tuple[str, str]],
    not_installed: List[Tuple[str, str]],
    unknown: List[Tuple[str, str]],
    packages: Dict,
    package_kind: str
):
    """分组显示某一类包的状态"""
    kind_label = _kind_label(package_kind)
    print_colored(f"\n[{kind_label.upper()}]", Colors.MAGENTA, bold=True)

    if installed:
        print_success(f"已安装 ({len(installed)} 个):")
        for name, status in installed:
            print(f"  • {name} - {status}")

    if not_installed:
        print_warning(f"未安装 ({len(not_installed)} 个):")
        for name, status in not_installed:
            is_default = packages[name].get("default", False)
            default_marker = " [默认]" if is_default else ""
            print(f"  • {name} - {status}{default_marker}")

    if unknown:
        print_info(f"状态未知 ({len(unknown)} 个):")
        for name, status in unknown:
            print(f"  • {name} - {status}")

    if not installed and not not_installed and not unknown:
        print_info("无配置项")


def _collect_package_refs(
    packages: Dict,
    package_kind: str,
    mode: str,
    not_installed: List[Tuple[str, str]],
    unknown: List[Tuple[str, str]],
    installed_formulae: Set[str],
    installed_casks: Set[str],
    cache_ready_formulae: bool,
    cache_ready_casks: bool
) -> List[PackageRef]:
    """根据安装模式收集候选包"""
    if mode == "1":
        return [(name, package_kind) for name, meta in packages.items() if meta.get("default", False)]

    if mode == "2":
        refs = []
        for name, meta in packages.items():
            if not meta.get("default", False):
                continue
            is_installed, _ = check_package_status(
                name,
                package_kind,
                installed_formulae,
                installed_casks,
                cache_ready_formulae,
                cache_ready_casks
            )
            if not is_installed:
                refs.append((name, package_kind))
        return refs

    if mode == "3":
        refs = []
        print_info(f"交互式选择 {_kind_label(package_kind)} (输入 y=选择, n=跳过, q=退出选择):")
        for name, _status in not_installed + unknown:
            is_default = packages[name].get("default", False)
            default_hint = " [默认]" if is_default else ""
            while True:
                ans = input(f"  安装 {name}{default_hint}? [y/n/q]: ").strip().lower()
                if ans in ['y', 'yes', '']:
                    refs.append((name, package_kind))
                    break
                if ans in ['n', 'no']:
                    break
                if ans in ['q', 'quit']:
                    print_warning("退出选择")
                    return refs
                print_warning("请输入 y, n 或 q")
        return refs

    if mode == "4":
        return [(name, package_kind) for name, _status in not_installed + unknown]

    return []


def interactive_package_selection(
    formulae: Dict,
    casks: Dict,
    installed_formulae: Set[str],
    installed_casks: Set[str],
    cache_ready_formulae: bool,
    cache_ready_casks: bool
) -> Tuple[List[PackageRef], List[PackageRef]]:
    """
    交互式包选择，formula 与 cask 分开展示

    Returns:
        (selected_packages, skipped_packages) 元素为 (name, kind)
    """
    print_header("包选择模式")

    print_info("正在检查包状态...")
    formula_groups = _categorize_packages(
        formulae,
        PACKAGE_FORMULA,
        installed_formulae,
        installed_casks,
        cache_ready_formulae,
        cache_ready_casks
    )
    cask_groups = _categorize_packages(
        casks,
        PACKAGE_CASK,
        installed_formulae,
        installed_casks,
        cache_ready_formulae,
        cache_ready_casks
    )

    _display_package_group("Formula", *formula_groups, formulae, PACKAGE_FORMULA)
    _display_package_group("Cask", *cask_groups, casks, PACKAGE_CASK)

    print()
    print_colored("选择安装模式:", Colors.WHITE, bold=True)
    print("1. 仅安装默认包 (推荐)")
    print("2. 跳过已安装，安装剩余默认包")
    print("3. 交互式选择所有包")
    print("4. 安装所有未安装的包")
    print("5. 取消安装")

    if os.environ.get('MANUAL_CONFIRM', 'false') != 'true':
        log_info("自动确认模式: 选择模式 2 (跳过已安装，安装剩余默认包)")
        choice = "2"
    else:
        choice = input("\n请选择模式 [1-5]: ").strip()

    while True:
        if choice == "5":
            print_warning("取消安装")
            return [], []

        if choice in {"1", "2", "3", "4"}:
            selected = []
            selected.extend(_collect_package_refs(
                formulae, PACKAGE_FORMULA, choice, formula_groups[1], formula_groups[2],
                installed_formulae, installed_casks, cache_ready_formulae, cache_ready_casks
            ))
            selected.extend(_collect_package_refs(
                casks, PACKAGE_CASK, choice, cask_groups[1], cask_groups[2],
                installed_formulae, installed_casks, cache_ready_formulae, cache_ready_casks
            ))
            break

        if os.environ.get('MANUAL_CONFIRM', 'false') != 'true':
            choice = "2"
            continue

        print_warning("请输入 1-5 之间的数字")
        choice = input("\n请选择模式 [1-5]: ").strip()

    final_selected = []
    skipped = []

    for name, package_kind in selected:
        is_installed, _status = check_package_status(
            name,
            package_kind,
            installed_formulae,
            installed_casks,
            cache_ready_formulae,
            cache_ready_casks
        )
        if is_installed:
            skipped.append((name, package_kind))
        else:
            final_selected.append((name, package_kind))

    return final_selected, skipped


def _run_single_package_install(package: str, package_kind: str = PACKAGE_FORMULA) -> Tuple[bool, str]:
    """逐个安装单个包，用于批量失败后的诊断和补救"""
    install_cmd = ["brew", "install"]
    if package_kind == PACKAGE_CASK:
        install_cmd.append("--cask")
    install_cmd.append(package)

    try:
        result = subprocess.run(
            install_cmd,
            capture_output=True,
            text=True,
            timeout=300
        )
    except subprocess.TimeoutExpired:
        return False, "安装超时: 5分钟"
    except Exception as e:
        return False, f"安装异常: {e}"

    if result.returncode == 0:
        return True, ""

    error_msg = result.stderr.strip() or result.stdout.strip() or "未知错误"
    return False, error_msg


def install_packages(
    packages: List[PackageRef]
) -> Tuple[List[PackageRef], List[PackageRef], bool]:
    """
    安装包列表，formula 与 cask 分组批量安装，失败后逐个补救

    Returns:
        (successful_packages, failed_packages, used_batch_install)
    """
    if not packages:
        return [], [], False

    formulae = [name for name, kind in packages if kind == PACKAGE_FORMULA]
    casks = [name for name, kind in packages if kind == PACKAGE_CASK]

    successful: List[PackageRef] = []
    failed: List[PackageRef] = []
    used_batch = False

    for group_name, group_packages, package_kind in (
        ("formula", formulae, PACKAGE_FORMULA),
        ("cask", casks, PACKAGE_CASK),
    ):
        if not group_packages:
            continue

        used_batch = True
        print_header(f"开始安装 {len(group_packages)} 个 {group_name}")
        print_info("优先使用批量安装模式，减少重复依赖解析和网络请求")

        install_cmd = ["brew", "install"]
        if package_kind == PACKAGE_CASK:
            install_cmd.append("--cask")
        install_cmd.extend(group_packages)

        try:
            batch_result = subprocess.run(
                install_cmd,
                capture_output=True,
                text=True,
                timeout=1800
            )
        except subprocess.TimeoutExpired:
            batch_result = None
            batch_error = "批量安装超时: 30分钟"
        except Exception as e:
            batch_result = None
            batch_error = f"批量安装异常: {e}"
        else:
            batch_error = ""

        if batch_result is not None and batch_result.returncode == 0:
            log_success(f"{group_name} 批量安装成功")
            successful.extend((name, package_kind) for name in group_packages)
            continue

        log_warn(f"{group_name} 批量安装失败，开始逐个诊断并补救")
        if batch_result is None:
            log_info(batch_error)
        else:
            error_msg = batch_result.stderr.strip() or batch_result.stdout.strip() or "未知错误"
            log_info(f"批量安装错误信息: {error_msg}")

        for i, package in enumerate(group_packages, 1):
            print_step(i, len(group_packages), f"补装 {package} ({group_name})")
            is_success, error_msg = _run_single_package_install(package, package_kind)
            ref = (package, package_kind)
            if is_success:
                print_success(f"安装成功: {package}")
                successful.append(ref)
            else:
                print_error(f"安装失败: {package}")
                print_info(f"错误信息: {error_msg}")
                failed.append(ref)
            print()

    return successful, failed, used_batch


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
    
    os_node = cfg.get(os_key, {})
    formulae = os_node.get("package", {})
    casks = os_node.get("cask", {}) if os_key == "Darwin" else {}

    if not formulae and not casks:
        log_error("配置文件中没有定义包")
        log_info(f"请检查 {config_path} 中的 {os_key}.package / {os_key}.cask 配置")
        return False

    print_info(f"配置文件: {config_path}")
    display_package_summary(formulae, casks, os_key)
    print()

    installed_formulae, cache_ready_formulae = get_installed_formulae()
    installed_casks, cache_ready_casks = get_installed_casks()

    if cache_ready_formulae:
        log_info(f"已加载 formula 缓存: {len(installed_formulae)} 个")
    else:
        log_warn("formula 缓存不可用，将把 formula 状态标记为未知")

    if os_key == "Darwin":
        if cache_ready_casks:
            log_info(f"已加载 cask 缓存: {len(installed_casks)} 个")
        else:
            log_warn("cask 缓存不可用，将把 cask 状态标记为未知")
    print()

    selected_packages, skipped_packages = interactive_package_selection(
        formulae,
        casks,
        installed_formulae,
        installed_casks,
        cache_ready_formulae,
        cache_ready_casks
    )

    if not selected_packages and not skipped_packages:
        log_info("没有选择任何包，退出安装")
        return True

    if selected_packages:
        formula_selected = [name for name, kind in selected_packages if kind == PACKAGE_FORMULA]
        cask_selected = [name for name, kind in selected_packages if kind == PACKAGE_CASK]
        print_info(f"计划安装: {len(selected_packages)} 个包")
        if formula_selected:
            print_colored("  [FORMULA]", Colors.MAGENTA, bold=True)
            for pkg in formula_selected:
                print(f"    • {pkg}")
        if cask_selected:
            print_colored("  [CASK]", Colors.MAGENTA, bold=True)
            for pkg in cask_selected:
                print(f"    • {pkg}")

    if skipped_packages:
        print_warning(f"跳过已安装: {len(skipped_packages)} 个包")
        for pkg, kind in skipped_packages:
            print(f"  • {pkg} [{_kind_label(kind)}]")

    if selected_packages:
        print()
        if os.environ.get('MANUAL_CONFIRM', 'false') == 'true':
            confirm = input("确认开始安装? [Y/n]: ").strip().lower()
            if confirm == 'n':
                log_warn("用户取消安装")
                return True
        else:
            log_info("自动确认模式: 开始安装")

        successful, failed, used_batch_install = install_packages(selected_packages)

        print_header("安装完成统计")

        success_overall = True

        if successful:
            log_success(f"成功安装: {len(successful)} 个包")
            for pkg, kind in successful:
                print(f"  ✅ {pkg} [{_kind_label(kind)}]")

        if failed:
            log_error(f"安装失败: {len(failed)} 个包")
            for pkg, kind in failed:
                print(f"  ❌ {pkg} [{_kind_label(kind)}]")
            if used_batch_install:
                log_info("已自动执行逐个补救，仍失败的包建议手动检查或重新运行安装")
            else:
                log_info("建议手动检查失败的包或重新运行安装")
            success_overall = False

        if skipped_packages:
            log_info(f"跳过已安装: {len(skipped_packages)} 个包")

        return success_overall

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


def parse_brewfile(brewfile_text: str) -> Tuple[List[str], List[str]]:
    """从 Brewfile 解析 formula 与 cask 列表"""
    formulae = []
    casks = []
    for line in brewfile_text.splitlines():
        line = line.strip()
        prefix = None
        if line.startswith('brew "'):
            prefix = "brew"
        elif line.startswith('cask "'):
            prefix = "cask"
        if prefix is None:
            continue
        try:
            name = line.split('"', 2)[1]
            if not name:
                continue
            if prefix == "brew":
                formulae.append(name)
            else:
                casks.append(name)
        except Exception:
            continue
    return sorted(set(formulae)), sorted(set(casks))


def get_installed_packages_from_brewfile() -> Tuple[List[str], List[str]]:
    """通过 Brewfile 获取已安装的 formula 与 cask 列表"""
    brewfile_text = dump_brewfile_text()
    if not brewfile_text:
        print_warning("无法通过 Brewfile 获取已安装包列表，将改用 brew list")
        return [], []
    return parse_brewfile(brewfile_text)


def get_installed_packages_for_backup(os_key: str) -> Tuple[List[str], List[str], bool]:
    """获取备份用的已安装 formula 与 cask 列表"""
    formulae, casks = get_installed_packages_from_brewfile()
    if formulae or casks:
        return formulae, casks, True

    installed_formulae, formula_ok = get_installed_formulae()
    installed_casks: Set[str] = set()
    cask_ok = True
    if os_key == "Darwin":
        installed_casks, cask_ok = get_installed_casks()

    if formula_ok or cask_ok:
        formula_list = sorted(installed_formulae)
        cask_list = sorted(installed_casks)
        return formula_list, cask_list, bool(formula_list or cask_list)

    return [], [], False


def ask_default_install_strategy(new_items: List[PackageRef]) -> Dict[PackageRef, bool]:
    """
    询问新备份包的默认安装策略

    Returns:
        (name, kind) -> default，用户取消时返回 None
    """
    if not new_items:
        return {}

    print()
    print_colored("新包默认安装策略:", Colors.WHITE, bold=True)
    print("1. 全部设为默认安装 (default: true)")
    print("2. 全部不设默认安装 (default: false)")
    print("3. 逐项确认是否默认安装")

    while True:
        choice = input("\n请选择策略 [1-3]: ").strip()
        if choice == "1":
            return {(name, kind): True for name, kind in new_items}
        if choice == "2":
            return {(name, kind): False for name, kind in new_items}
        if choice == "3":
            results: Dict[PackageRef, bool] = {}
            for name, kind in new_items:
                kind_label = _kind_label(kind)
                while True:
                    ans = input(f"  {name} [{kind_label}] 设为默认安装? [y/n]: ").strip().lower()
                    if ans in ['y', 'yes']:
                        results[(name, kind)] = True
                        break
                    if ans in ['n', 'no', '']:
                        results[(name, kind)] = False
                        break
                    print_warning("请输入 y 或 n")
            return results
        print_warning("请输入 1-3 之间的数字")


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
    
    print_info("正在扫描已安装的包...")
    installed_formulae, installed_casks, scan_ok = get_installed_packages_for_backup(os_key)

    if not scan_ok:
        log_warn("没有发现已安装的包")
        return True

    total_count = len(installed_formulae) + len(installed_casks)
    log_success(f"发现 {total_count} 个已安装的包 (formula {len(installed_formulae)}, cask {len(installed_casks)})")

    os_node = cfg.setdefault(os_key, {})
    current_formulae = os_node.get("package", {})
    current_casks = os_node.get("cask", {}) if os_key == "Darwin" else {}

    new_formulae = [pkg for pkg in installed_formulae if pkg not in current_formulae]
    new_casks = [pkg for pkg in installed_casks if pkg not in current_casks]
    existing_count = (
        len(installed_formulae) - len(new_formulae)
        + len(installed_casks) - len(new_casks)
    )

    print()
    if existing_count:
        print_info(f"配置中已存在: {existing_count} 个包")

    new_items: List[PackageRef] = (
        [(name, PACKAGE_FORMULA) for name in new_formulae]
        + [(name, PACKAGE_CASK) for name in new_casks]
    )

    if not new_items:
        log_success("没有发现新包，配置文件已是最新")
        return True

    if new_formulae:
        print_warning(f"新发现的 formula: {len(new_formulae)} 个")
        for pkg in new_formulae:
            print(f"  • {pkg}")

    if new_casks:
        print_warning(f"新发现的 cask: {len(new_casks)} 个")
        for pkg in new_casks:
            print(f"  • {pkg}")

    print()
    merge = input("是否将新包合并到配置文件? [Y/n]: ").strip().lower()
    if merge == 'n':
        log_info("跳过合并操作")
        return True

    default_map = ask_default_install_strategy(new_items)

    packages_node = os_node.setdefault("package", {})
    for name, kind in new_items:
        if kind != PACKAGE_FORMULA:
            continue
        packages_node[name] = {"default": default_map[(name, kind)]}

    if os_key == "Darwin" and any(kind == PACKAGE_CASK for _, kind in new_items):
        casks_node = os_node.setdefault("cask", {})
        for name, kind in new_items:
            if kind != PACKAGE_CASK:
                continue
            casks_node[name] = {"default": default_map[(name, kind)]}

    if save_config(config_path, cfg):
        default_true = sum(1 for value in default_map.values() if value)
        default_false = len(default_map) - default_true
        log_success(f"成功合并 {len(new_items)} 个新包到配置文件")
        log_info(f"默认安装: {default_true} 个, 非默认: {default_false} 个")
        return True

    log_error("保存配置文件失败")
    return False


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
    print("  • 支持 formula 与 cask 分开展示和管理")
    print("  • 友好的彩色交互界面")
    print("  • 详细的安装进度和统计信息")
    print("  • 支持多种安装模式选择")
    print("  • 备份时可选择新包的默认安装策略")
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
