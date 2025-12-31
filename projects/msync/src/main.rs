use std::fs;
use std::io::{self, Write};
use std::path::PathBuf;

use clap::{Arg, Command};
use clap_complete::{
    generate,
    shells::{Bash, Fish, Zsh},
};

/// 构建顶层 CLI 定义
fn build_cli() -> Command {
    Command::new("msync")
        .about("A simple sync/upload helper tool")
        .subcommand_required(false)
        .arg_required_else_help(true)
        // 示例子命令：未来可以在这里扩展 upload / config 等
        .subcommand(
            Command::new("upload")
                .about("Upload/sync project artifacts")
                .arg(
                    Arg::new("profile")
                        .short('p')
                        .long("profile")
                        .help("Profile name defined in config")
                        .required(false)
                        .num_args(1),
                ),
        )
        // 用于生成补全脚本的子命令： msync completions <shell>
        .subcommand(
            Command::new("completions")
                .about("Generate shell completion script")
                .arg(
                    Arg::new("shell")
                        .help("Shell type: bash / zsh / fish")
                        .required(true)
                        .value_parser(["bash", "zsh", "fish"]),
                ),
        )
        // 自动安装补全脚本的子命令： msync install-completions
        .subcommand(
            Command::new("install-completions")
                .about("Automatically install shell completion script for current shell")
                .arg(
                    Arg::new("shell")
                        .help("Shell type: bash / zsh / fish (auto-detect if not specified)")
                        .required(false)
                        .value_parser(["bash", "zsh", "fish"]),
                ),
        )
        // 卸载补全脚本的子命令： msync uninstall-completions
        .subcommand(
            Command::new("uninstall-completions")
                .about("Remove installed shell completion scripts")
                .arg(
                    Arg::new("shell")
                        .help("Shell type: bash / zsh / fish (remove all if not specified)")
                        .required(false)
                        .value_parser(["bash", "zsh", "fish"]),
                ),
        )
}

/// 检测当前 shell 类型
fn detect_shell() -> Option<&'static str> {
    // 优先检查 SHELL 环境变量
    if let Ok(shell) = std::env::var("SHELL") {
        if shell.contains("zsh") {
            return Some("zsh");
        } else if shell.contains("bash") {
            return Some("bash");
        } else if shell.contains("fish") {
            return Some("fish");
        }
    }
    
    // 检查父进程名称（备用方案）
    if let Ok(ppid) = std::process::Command::new("ps")
        .args(["-p", &std::os::unix::process::parent_id().to_string(), "-o", "comm="])
        .output()
    {
        let parent = String::from_utf8_lossy(&ppid.stdout).trim().to_lowercase();
        if parent.contains("zsh") {
            return Some("zsh");
        } else if parent.contains("bash") {
            return Some("bash");
        } else if parent.contains("fish") {
            return Some("fish");
        }
    }
    
    None
}

/// 获取补全脚本的目标路径
fn get_completion_path(shell: &str) -> anyhow::Result<PathBuf> {
    let home = std::env::var("HOME")
        .map_err(|_| anyhow::anyhow!("HOME environment variable not set"))?;
    
    let path = match shell {
        "zsh" => {
            // zsh: ~/.zsh/completions/ 或 ~/.zfunc/
            let dirs = [
                format!("{}/.zsh/completions", home),
                format!("{}/.zfunc", home),
                format!("{}/.local/share/zsh/site-functions", home),
            ];
            
            // 找到第一个存在的目录，或使用第一个目录
            let dir = dirs.iter()
                .find(|d| PathBuf::from(d).exists())
                .unwrap_or(&dirs[0]);
            
            PathBuf::from(dir).join("_msync")
        }
        "bash" => {
            // bash: ~/.bash_completion.d/ 或系统目录
            let dirs = [
                format!("{}/.bash_completion.d", home),
                format!("{}/.local/share/bash-completion/completions", home),
            ];
            
            let dir = dirs.iter()
                .find(|d| PathBuf::from(d).exists())
                .unwrap_or(&dirs[0]);
            
            PathBuf::from(dir).join("msync")
        }
        "fish" => {
            // fish: ~/.config/fish/completions/
            PathBuf::from(format!("{}/.config/fish/completions", home)).join("msync.fish")
        }
        _ => return Err(anyhow::anyhow!("Unsupported shell: {}", shell)),
    };
    
    Ok(path)
}

/// 安装补全脚本
fn install_completions(cmd: &mut Command, shell: Option<&str>) -> anyhow::Result<()> {
    let shell = shell
        .or_else(detect_shell)
        .ok_or_else(|| anyhow::anyhow!("Cannot detect shell. Please specify with --shell option"))?;
    
    println!("Detected shell: {}", shell);
    
    let completion_path = get_completion_path(shell)?;
    let completion_dir = completion_path.parent()
        .ok_or_else(|| anyhow::anyhow!("Invalid completion path"))?;
    
    // 创建目录（如果不存在）
    fs::create_dir_all(completion_dir)?;
    
    // 生成补全脚本内容
    let mut buffer = Vec::new();
    match shell {
        "bash" => generate(Bash, cmd, "msync", &mut buffer),
        "zsh" => generate(Zsh, cmd, "msync", &mut buffer),
        "fish" => generate(Fish, cmd, "msync", &mut buffer),
        _ => return Err(anyhow::anyhow!("Unsupported shell: {}", shell)),
    }
    
    // 写入文件
    fs::write(&completion_path, buffer)?;
    
    println!("✓ Completion script installed to: {}", completion_path.display());
    
    // 给出后续提示
    match shell {
        "zsh" => {
            println!("\nTo enable completions, add this to your ~/.zshrc:");
            println!("  fpath=({} $fpath)", completion_dir.display());
            println!("  autoload -Uz compinit && compinit");
            println!("\nOr restart your shell and run: compinit");
        }
        "bash" => {
            println!("\nTo enable completions, add this to your ~/.bashrc:");
            println!("  source {}", completion_path.display());
            println!("\nOr restart your shell.");
        }
        "fish" => {
            println!("\nFish completions are automatically loaded. Restart your shell to use them.");
        }
        _ => {}
    }
    
    Ok(())
}

fn main() -> anyhow::Result<()> {
    let mut cmd = build_cli();
    let matches = cmd.clone().get_matches();

    match matches.subcommand() {
        Some(("completions", sub_m)) => {
            let shell = sub_m
                .get_one::<String>("shell")
                .expect("shell is required")
                .as_str();

            let mut stdout = io::stdout();
            match shell {
                "bash" => generate(Bash, &mut cmd, "msync", &mut stdout),
                "zsh" => generate(Zsh, &mut cmd, "msync", &mut stdout),
                "fish" => generate(Fish, &mut cmd, "msync", &mut stdout),
                _ => unreachable!("clap value_parser 保证了只会是三种之一"),
            }
        }
        Some(("install-completions", sub_m)) => {
            let shell = sub_m.get_one::<String>("shell").map(|s| s.as_str());
            install_completions(&mut cmd, shell)?;
        }
        Some(("upload", _sub_m)) => {
            // 之后在这里实现真正的 upload 逻辑
            println!("upload command is not implemented yet");
        }
        _ => {
            // 没有子命令时，打印帮助
            cmd.print_help()?;
            println!();
        }
    }

    Ok(())
}

