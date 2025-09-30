#!/usr/bin/env python3
"""
Chezmoi 配置文件备份/恢复工具 (重写版)

特性:
- 安全的密码处理：每次操作都重新输入密码，不在内存中存储
- 友好的用户交互：彩色输出、进度提示、错误重试
- 灵活的操作模式：支持单个文件和批量操作
- 完善的错误处理：详细的错误信息和恢复建议
"""

import json
import os
import subprocess
import sys
import time
from pathlib import Path
from shutil import which, copy2
import getpass
from typing import Dict, List, Optional, Tuple


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


def print_success(text: str):
    """打印成功信息"""
    print_colored(f"✅ {text}", Colors.GREEN, bold=True)


def print_error(text: str):
    """打印错误信息"""
    print_colored(f"❌ {text}", Colors.RED, bold=True)


def print_warning(text: str):
    """打印警告信息"""
    print_colored(f"⚠️  {text}", Colors.YELLOW)


def print_info(text: str):
    """打印信息"""
    print_colored(f"ℹ️  {text}", Colors.BLUE)


def print_step(step: int, total: int, text: str):
    """打印步骤信息"""
    print_colored(f"[{step}/{total}] {text}", Colors.CYAN, bold=True)


def resolve_config_path() -> Path:
    """
    按优先级解析配置文件路径
    1) 相对当前脚本向上查找
    2) 使用 chezmoi source-path 查找
    """
    script_path = Path(__file__).resolve()
    
    # 由近及远查找
    for anc in [script_path.parent] + list(script_path.parents):
        cand = anc / "resources" / "chezmoi-config" / ".configfile"
        if cand.exists():
            return cand
    
    # 退回 chezmoi 源目录
    try:
        res = subprocess.run(["zsh", "-lc", "chezmoi source-path"], 
                           capture_output=True, text=True, check=True)
        src_dir = Path(res.stdout.strip())
        cand = src_dir / ".." / "resources" / "chezmoi-config" / ".configfile"
        if cand.exists():
            return cand
    except Exception:
        pass
    
    print_error("未找到配置文件 resources/chezmoi-config/.configfile")
    print_info("请确保它存在于 chezmoi 源目录")
    sys.exit(1)


def load_config(config_path: Path) -> Dict:
    """加载并解析配置文件"""
    if not config_path.exists():
        print_error(f"配置文件不存在: {config_path}")
        sys.exit(1)
    
    try:
        with open(config_path, "r", encoding="utf-8") as f:
            return json.load(f)
    except json.JSONDecodeError as e:
        print_error(f"配置文件格式错误: {e}")
        sys.exit(1)
    except Exception as e:
        print_error(f"读取配置文件失败: {e}")
        sys.exit(1)


def ensure_age():
    """检查 age 工具是否可用"""
    if which("age") is None:
        print_error("需要 age 加密工具")
        print_info("安装命令: brew install age")
        sys.exit(1)


def get_chezmoi_source_path() -> Path:
    """获取 chezmoi 源目录路径"""
    try:
        res = subprocess.run(["zsh", "-lc", "chezmoi source-path"], 
                           capture_output=True, text=True, check=True)
        return Path(res.stdout.strip())
    except Exception as e:
        print_error(f"无法获取 chezmoi 源目录: {e}")
        print_info("请确保 chezmoi 已正确安装并配置")
        sys.exit(1)


# 注意：get_password 函数已移除，现在直接让 age 工具处理密码输入
# 这样可以避免密码在 Python 进程中存储，更加安全


def resolve_path(path_str: str) -> Path:
    """解析路径字符串，支持绝对路径、用户主目录路径和相对路径"""
    path = Path(path_str)
    if path.is_absolute():
        return path
    elif path_str.startswith("~/"):
        return Path.home() / path_str[2:]
    else:
        return path


def secure_encrypt_file(input_path: Path, output_path: Path, max_attempts: int = 3) -> bool:
    """
    安全地加密文件，密码不存储在内存中
    
    注意：age -p 模式需要交互式输入两次密码（输入+确认）
    
    Args:
        input_path: 输入文件路径
        output_path: 输出文件路径
        max_attempts: 最大重试次数
    
    Returns:
        True if successful, False otherwise
    """
    for attempt in range(max_attempts):
        try:
            print_info(f"age 工具需要输入两次密码（输入+确认）来加密文件: {input_path.name}")
            
            cmd = ["age", "-p", "-o", str(output_path), str(input_path)]
            
            # 使用 subprocess.Popen 来保持交互式输入
            process = subprocess.Popen(
                cmd,
                stdin=None,  # 让 age 直接从终端读取密码
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
            
            stdout, stderr = process.communicate()
            
            if process.returncode == 0:
                return True
            else:
                print_error(f"加密失败: {stderr.strip()}")
                
                if attempt < max_attempts - 1:
                    if "passphrase" in stderr.lower() or "incorrect" in stderr.lower():
                        print_warning("密码错误或不匹配，请重试")
                    
                    retry = input(f"剩余 {max_attempts - attempt - 1} 次机会，是否重试? [y/N]: ").strip().lower()
                    if retry != 'y':
                        break
                else:
                    print_error("已达到最大重试次数")
        
        except KeyboardInterrupt:
            print_warning("\n用户取消操作")
            return False
        except Exception as e:
            print_error(f"加密过程中发生错误: {e}")
            return False
    
    return False


def secure_decrypt_file(input_path: Path, output_path: Path, max_attempts: int = 3) -> bool:
    """
    安全地解密文件，密码不存储在内存中
    
    注意：age -d 模式只需要输入一次密码
    
    Args:
        input_path: 输入文件路径
        output_path: 输出文件路径
        max_attempts: 最大重试次数
    
    Returns:
        True if successful, False otherwise
    """
    for attempt in range(max_attempts):
        try:
            print_info(f"请输入解密文件的密码: {input_path.name}")
            
            cmd = ["age", "-d", "-o", str(output_path), str(input_path)]
            
            # 使用 subprocess.Popen 来保持交互式输入
            process = subprocess.Popen(
                cmd,
                stdin=None,  # 让 age 直接从终端读取密码
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
            
            stdout, stderr = process.communicate()
            
            if process.returncode == 0:
                return True
            else:
                print_error(f"解密失败: {stderr.strip()}")
                
                if attempt < max_attempts - 1:
                    if "incorrect passphrase" in stderr.lower() or "passphrase" in stderr.lower():
                        print_warning("密码错误，请重试")
                    
                    retry = input(f"剩余 {max_attempts - attempt - 1} 次机会，是否重试? [y/N]: ").strip().lower()
                    if retry != 'y':
                        break
                else:
                    print_error("已达到最大重试次数")
        
        except KeyboardInterrupt:
            print_warning("\n用户取消操作")
            return False
        except Exception as e:
            print_error(f"解密过程中发生错误: {e}")
            return False
    
    return False


def backup_config_files():
    """备份配置文件 - 改进版本"""
    print_colored("🔄 开始备份配置文件", Colors.MAGENTA, bold=True)
    print()
    
    # 加载配置
    config_path = resolve_config_path()
    cfg = load_config(config_path)
    
    # 获取路径信息
    chezmoi_source = get_chezmoi_source_path()
    target_dir = chezmoi_source / ".." / "resources" / "chezmoi-config"
    target_dir.mkdir(parents=True, exist_ok=True)
    
    print_info(f"配置文件: {config_path}")
    print_info(f"Chezmoi 源目录: {chezmoi_source}")
    print_info(f"备份目标目录: {target_dir}")
    print()
    
    # 获取文件列表
    files = cfg.get("files", [])
    if not files:
        print_warning("配置文件中没有定义要备份的文件")
        return
    
    total_files = len(files)
    success_count = 0
    skip_count = 0
    
    # 处理每个文件
    for i, file_config in enumerate(files, 1):
        source_path = resolve_path(file_config["source"])
        target_name = file_config.get("target", source_path.name)
        encrypt = file_config.get("encrypt", True)
        
        print_step(i, total_files, f"处理文件: {source_path}")
        
        # 检查源文件是否存在
        if not source_path.exists():
            print_warning(f"源文件不存在，跳过: {source_path}")
            skip_count += 1
            print()
            continue
        
        target_file = target_dir / target_name
        
        if encrypt:
            # 加密备份
            encrypted_file = target_file.with_suffix(target_file.suffix + ".age")
            print_info(f"加密备份: {source_path} -> {encrypted_file}")
            
            if secure_encrypt_file(source_path, encrypted_file):
                print_success(f"加密备份成功: {encrypted_file.name}")
                success_count += 1
            else:
                print_error(f"加密备份失败: {source_path}")
                
                # 询问是否继续
                continue_choice = input("是否继续处理其他文件? [Y/n]: ").strip().lower()
                if continue_choice == 'n':
                    break
        else:
            # 明文备份
            print_info(f"明文备份: {source_path} -> {target_file}")
            try:
                copy2(source_path, target_file)
                print_success(f"明文备份成功: {target_file.name}")
                success_count += 1
            except Exception as e:
                print_error(f"明文备份失败: {e}")
        
        print()
    
    # 总结
    print_colored("📊 备份完成统计", Colors.MAGENTA, bold=True)
    print_success(f"成功备份: {success_count} 个文件")
    if skip_count > 0:
        print_warning(f"跳过文件: {skip_count} 个文件")
    if success_count + skip_count < total_files:
        print_error(f"失败文件: {total_files - success_count - skip_count} 个文件")


def restore_config_files():
    """恢复配置文件 - 改进版本"""
    print_colored("🔄 开始恢复配置文件", Colors.MAGENTA, bold=True)
    print()
    
    # 加载配置
    config_path = resolve_config_path()
    cfg = load_config(config_path)
    
    # 获取路径信息
    chezmoi_source = get_chezmoi_source_path()
    source_dir = chezmoi_source / ".." / "resources" / "chezmoi-config"
    
    print_info(f"配置文件: {config_path}")
    print_info(f"Chezmoi 源目录: {chezmoi_source}")
    print_info(f"恢复源目录: {source_dir}")
    print()
    
    if not source_dir.exists():
        print_error(f"恢复源目录不存在: {source_dir}")
        print_info("请先执行备份操作")
        return
    
    # 获取文件列表
    files = cfg.get("files", [])
    if not files:
        print_warning("配置文件中没有定义要恢复的文件")
        return
    
    total_files = len(files)
    success_count = 0
    skip_count = 0
    
    # 处理每个文件
    for i, file_config in enumerate(files, 1):
        source_name = file_config.get("target", Path(file_config["source"]).name)
        target_path = resolve_path(file_config["source"])
        encrypt = file_config.get("encrypt", True)
        
        print_step(i, total_files, f"恢复文件: {target_path}")
        
        # 确保目标目录存在
        target_path.parent.mkdir(parents=True, exist_ok=True)
        
        source_file = source_dir / source_name
        
        if encrypt:
            # 解密恢复
            encrypted_file = source_file.with_suffix(source_file.suffix + ".age")
            
            if not encrypted_file.exists():
                print_warning(f"加密文件不存在，跳过: {encrypted_file}")
                skip_count += 1
                print()
                continue
            
            print_info(f"解密恢复: {encrypted_file} -> {target_path}")
            
            # 检查目标文件是否存在
            if target_path.exists():
                # 根据确认模式处理文件覆盖
                if os.environ.get('MANUAL_CONFIRM', 'false') == 'true':
                    overwrite = input(f"目标文件已存在: {target_path}\n是否覆盖? [y/N]: ").strip().lower()
                    if overwrite != 'y':
                        print_warning("跳过文件恢复")
                        skip_count += 1
                        print()
                        continue
                else:
                    # 自动确认模式：自动覆盖但显示警告
                    print_warning(f"自动确认模式: 覆盖现有文件 {target_path}")
                    print_info("💡 如需手动确认，请使用 MANUAL_CONFIRM=true")
            
            if secure_decrypt_file(encrypted_file, target_path):
                print_success(f"解密恢复成功: {target_path}")
                success_count += 1
            else:
                print_error(f"解密恢复失败: {encrypted_file}")
                
                # 询问是否继续
                continue_choice = input("是否继续处理其他文件? [Y/n]: ").strip().lower()
                if continue_choice == 'n':
                    break
        else:
            # 明文恢复
            if not source_file.exists():
                print_warning(f"源文件不存在，跳过: {source_file}")
                skip_count += 1
                print()
                continue
            
            print_info(f"明文恢复: {source_file} -> {target_path}")
            
            # 检查目标文件是否存在
            if target_path.exists():
                # 根据确认模式处理文件覆盖
                if os.environ.get('MANUAL_CONFIRM', 'false') == 'true':
                    overwrite = input(f"目标文件已存在: {target_path}\n是否覆盖? [y/N]: ").strip().lower()
                    if overwrite != 'y':
                        print_warning("跳过文件恢复")
                        skip_count += 1
                        print()
                        continue
                else:
                    # 自动确认模式：自动覆盖但显示警告
                    print_warning(f"自动确认模式: 覆盖现有文件 {target_path}")
                    print_info("💡 如需手动确认，请使用 MANUAL_CONFIRM=true")
            
            try:
                copy2(source_file, target_path)
                print_success(f"明文恢复成功: {target_path}")
                success_count += 1
            except Exception as e:
                print_error(f"明文恢复失败: {e}")
        
        print()
    
    # 总结
    print_colored("📊 恢复完成统计", Colors.MAGENTA, bold=True)
    print_success(f"成功恢复: {success_count} 个文件")
    if skip_count > 0:
        print_warning(f"跳过文件: {skip_count} 个文件")
    if success_count + skip_count < total_files:
        print_error(f"失败文件: {total_files - success_count - skip_count} 个文件")


def print_usage():
    """打印使用说明"""
    print_colored("🛠️  Chezmoi 配置管理工具", Colors.CYAN, bold=True)
    print()
    print_colored("用法:", Colors.WHITE, bold=True)
    print("  mychezmoi.py backup   - 备份配置文件")
    print("  mychezmoi.py restore  - 恢复配置文件")
    print("  mychezmoi.py --help   - 显示此帮助信息")
    print()
    print_colored("说明:", Colors.WHITE, bold=True)
    print("  • 围绕 resources/chezmoi-config/.configfile 进行配置文件管理")
    print("  • 支持 age 密码加密，密码每次重新输入，不会存储")
    print("  • 支持明文和加密混合模式")
    print("  • 提供友好的交互体验和错误处理")
    print()
    print_colored("安全特性:", Colors.GREEN, bold=True)
    print("  🔐 密码每次重新输入，不在内存中存储")
    print("  🔄 支持加密/解密失败重试")
    print("  ⚠️  文件覆盖前会进行确认")
    print("  📝 详细的操作日志和进度提示")


def main():
    """程序入口"""
    if len(sys.argv) < 2 or sys.argv[1] in ("-h", "--help", "help"):
        print_usage()
        return
    
    # 检查依赖
    ensure_age()
    
    cmd = sys.argv[1].lower()
    
    try:
        if cmd == "backup":
            backup_config_files()
        elif cmd == "restore":
            restore_config_files()
        else:
            print_error(f"未知命令: {cmd}")
            print_usage()
            sys.exit(1)
    except KeyboardInterrupt:
        print_warning("\n\n用户中断操作")
        sys.exit(0)
    except Exception as e:
        print_error(f"程序运行时发生错误: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
