use std::collections::HashMap;
use std::env;
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};

use anyhow::{Context, Result, anyhow};
use clap::{ArgAction, Args, CommandFactory, Parser, Subcommand, value_parser};
use clap_complete::{Shell, generate};
use serde::Deserialize;

#[derive(Debug, Deserialize)]
struct Profile {
    src: Option<String>,
    dst: Option<String>,
    #[serde(default)]
    flags: Vec<String>,
}

#[derive(Debug, Deserialize)]
struct Config {
    #[serde(flatten)]
    profiles: HashMap<String, Profile>,
}

#[derive(Parser, Debug)]
#[command(name = "msync", version, about = "基于配置的 rsync 上传工具")]
struct Cli {
    /// 配置文件路径（默认：$XDG_CONFIG_HOME/msync/profiles.json）
    #[arg(short, long, value_name = "FILE", value_parser = value_parser!(PathBuf))]
    config: Option<PathBuf>,

    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand, Debug)]
enum Commands {
    /// 使用指定 profile 上传
    Upload(UploadArgs),
    /// 列出可用的 profile
    List,
    /// 查看 profile 详细信息
    Show {
        /// profile 名称（省略则显示全部）
        profile: Option<String>,
    },
    /// 生成 shell 补全脚本
    Completion {
        #[arg(value_enum)]
        shell: Shell,
    },
}

#[derive(Args, Debug)]
struct UploadArgs {
    /// 要使用的 profile 名称
    #[arg(short = 'u', long = "profile")]
    profile: String,
    /// 覆盖源路径
    #[arg(long, value_name = "PATH")]
    src: Option<PathBuf>,
    /// 覆盖目标路径（如 user@host:/path/）
    #[arg(long, value_name = "DEST")]
    dst: Option<String>,
    /// 透传给 rsync 的附加参数，写在 `--` 之后，如 -- --delete --exclude node_modules
    #[arg(trailing_var_arg = true, action = ArgAction::Append)]
    rsync_args: Vec<String>,
}

fn main() -> Result<()> {
    let cli = Cli::parse();
    match cli.command {
        Commands::Completion { shell } => {
            let mut cmd = Cli::command();
            generate(shell, &mut cmd, "msync", &mut std::io::stdout());
            Ok(())
        }
        _ => {
            let cfg_path = resolve_config_path(cli.config.as_deref())?;
            let cfg = load_config(&cfg_path)?;
            run_command(cli.command, cfg)
        }
    }
}

fn resolve_config_path(override_path: Option<&Path>) -> Result<PathBuf> {
    if let Some(p) = override_path {
        return Ok(p.to_path_buf());
    }
    if let Ok(xdg) = env::var("XDG_CONFIG_HOME") {
        let p = Path::new(&xdg).join("msync").join("profiles.json");
        return Ok(p);
    }
    let home = env::var("HOME").context("HOME not set and no config path provided")?;
    Ok(Path::new(&home)
        .join(".config")
        .join("msync")
        .join("profiles.json"))
}

fn load_config(path: &Path) -> Result<Config> {
    let content = std::fs::read_to_string(path)
        .with_context(|| format!("failed to read config file {}", path.display()))?;
    let cfg: Config = serde_json::from_str(&content)
        .with_context(|| format!("invalid JSON in {}", path.display()))?;
    Ok(cfg)
}

fn run_command(command: Commands, cfg: Config) -> Result<()> {
    match command {
        Commands::Upload(args) => do_upload(args, cfg),
        Commands::List => {
            for key in cfg.profiles.keys() {
                println!("{key}");
            }
            Ok(())
        }
        Commands::Show { profile } => {
            if let Some(name) = profile {
                let Some(p) = cfg.profiles.get(&name) else {
                    return Err(anyhow!("profile `{name}` not found"));
                };
                println!("{name}:");
                println!("  src: {}", p.src.as_deref().unwrap_or("<unset>"));
                println!("  dst: {}", p.dst.as_deref().unwrap_or("<unset>"));
                if p.flags.is_empty() {
                    println!("  flags: <none>");
                } else {
                    println!("  flags: {}", p.flags.join(" "));
                }
            } else {
                for (k, p) in cfg.profiles.iter() {
                    println!(
                        "{k}: src={} dst={}",
                        p.src.as_deref().unwrap_or("<unset>"),
                        p.dst.as_deref().unwrap_or("<unset>")
                    );
                }
            }
            Ok(())
        }
        Commands::Completion { .. } => unreachable!("handled earlier"),
    }
}

fn do_upload(args: UploadArgs, cfg: Config) -> Result<()> {
    let profile = cfg
        .profiles
        .get(&args.profile)
        .ok_or_else(|| anyhow!("profile `{}` not found", args.profile))?;

    let src = args
        .src
        .map(|p| p.to_string_lossy().to_string())
        .or_else(|| profile.src.clone())
        .ok_or_else(|| anyhow!("profile `{}` has no src; provide --src", args.profile))?;
    let dst = args
        .dst
        .or_else(|| profile.dst.clone())
        .ok_or_else(|| anyhow!("profile `{}` has no dst; provide --dst", args.profile))?;

    let progress_arg = pick_progress_arg();

    let mut base_args = vec!["-avz".to_string(), progress_arg.clone()];
    base_args.extend(profile.flags.clone());
    base_args.extend(args.rsync_args.clone());
    base_args.push(src);
    base_args.push(dst);

    run_rsync(base_args, progress_arg)
}

fn pick_progress_arg() -> String {
    match rsync_supports_progress2() {
        true => "--info=progress2".to_string(),
        false => "-P".to_string(), // 等价于 --partial 和 --progress
    }
}

fn rsync_supports_progress2() -> bool {
    let output = Command::new("rsync").arg("--version").output().ok();
    if let Some(out) = output {
        if let Ok(text) = String::from_utf8(out.stdout) {
            if let Some(first) = text.lines().next() {
                // 例如："rsync  version 3.2.7  protocol version 31"
                let tokens: Vec<&str> = first.split_whitespace().collect();
                let ver = tokens.iter().find_map(|t| parse_version(t));
                if let Some((major, minor)) = ver {
                    return major > 3 || (major == 3 && minor >= 1);
                }
            }
        }
    }
    false
}

fn parse_version(token: &str) -> Option<(u32, u32)> {
    let mut parts = token.split('.');
    let major = parts.next()?.parse::<u32>().ok()?;
    let minor = parts.next()?.parse::<u32>().ok()?;
    Some((major, minor))
}

fn run_rsync(args: Vec<String>, progress_arg: String) -> Result<()> {
    let mut cmd = Command::new("rsync");
    cmd.args(&args);
    cmd.stdin(Stdio::inherit())
        .stdout(Stdio::inherit())
        .stderr(Stdio::inherit());

    let status = cmd.status().context("failed to invoke rsync")?;
    if status.success() {
        return Ok(());
    }

    // 如果 progress2 失败，退回到 --progress
    if progress_arg == "--info=progress2" {
        let mut fallback_args = args
            .into_iter()
            .map(|a| {
                if a == "--info=progress2" {
                    "--progress".to_string()
                } else {
                    a
                }
            })
            .collect::<Vec<_>>();
        // 确保有进度参数
        if !fallback_args.iter().any(|a| a == "--progress" || a == "-P") {
            fallback_args.insert(1, "--progress".to_string());
        }
        let mut fallback = Command::new("rsync");
        fallback
            .args(&fallback_args)
            .stdin(Stdio::inherit())
            .stdout(Stdio::inherit())
            .stderr(Stdio::inherit());
        let status2 = fallback
            .status()
            .context("failed to invoke rsync (fallback)")?;
        if status2.success() {
            return Ok(());
        }
    }

    Err(anyhow!("rsync failed"))
}
