use anyhow::Result;
use clap::{Parser, Subcommand};
use ssipool::{placement, ssi, ssi_launch, storage};
use std::{fs, path::PathBuf};

/// 研究同一个 Linux 客体如何使用多台物理机；当前只提供有限实验入口。
#[derive(Parser)]
#[command(version, about)]
struct Cli {
    #[command(subcommand)]
    command: Action,
}

#[derive(Subcommand)]
enum Action {
    /// 通过已有 SSH 检查两个节点的原生时钟；不执行客体、不安装软件。
    Preflight {
        #[arg(required = true, num_args = 2)]
        ssh: Vec<String>,
        #[arg(long)]
        ssh_config: Option<PathBuf>,
    },
    /// 按显式计划启动专用 PF24 双端实验；不提供生产 SSI。
    Launch {
        #[arg(long)]
        plan: PathBuf,
        #[arg(long)]
        output: PathBuf,
        #[arg(long)]
        ssh_config: Option<PathBuf>,
        /// 记录原生系统调用，供启动拒绝取证。
        #[arg(long)]
        trace_syscalls: bool,
    },
    /// 只读检查候选整盘的现有用途；不格式化、不挂载。
    StorageAdmission {
        #[arg(long)]
        ssh: String,
        #[arg(long)]
        ssh_config: Option<PathBuf>,
        #[arg(long)]
        device: String,
        #[arg(long)]
        new_dedicated_device: bool,
    },
    /// 按显式物理故障域核算存储副本与恢复预留；不修改设备。
    StoragePlan {
        #[arg(long)]
        topology: PathBuf,
    },
}

async fn dispatch(cli: Cli) -> Result<bool> {
    match cli.command {
        Action::Preflight { ssh, ssh_config } => {
            let report = ssi::preflight(&ssh, ssh_config.as_deref()).await?;
            println!("{}", serde_json::to_string_pretty(&report)?);
            Ok(report.native_tsc_precheck_passed)
        }
        Action::Launch {
            plan,
            output,
            ssh_config,
            trace_syscalls,
        } => {
            let plan = serde_json::from_slice(&fs::read(plan)?)?;
            let report =
                ssi_launch::launch(plan, ssh_config.as_deref(), &output, trace_syscalls).await?;
            println!("{}", serde_json::to_string_pretty(&report)?);
            Ok(ssi_launch::processes_exited_successfully(&report))
        }
        Action::StorageAdmission {
            ssh,
            ssh_config,
            device,
            new_dedicated_device,
        } => {
            storage::validate_requested_device(&device)?;
            let probe = storage::probe(&ssh, ssh_config.as_deref()).await?;
            let report = storage::assess(&device, new_dedicated_device, probe);
            println!("{}", serde_json::to_string_pretty(&report)?);
            Ok(report.eligible_for_future_initialization)
        }
        Action::StoragePlan { topology } => {
            let topology = placement::read_topology(&topology)?;
            let report = placement::plan(&topology);
            println!("{}", serde_json::to_string_pretty(&report)?);
            Ok(report.fault_tolerance_claim_allowed)
        }
    }
}

#[tokio::main]
async fn main() {
    let code = match dispatch(Cli::parse()).await {
        Ok(true) => 0,
        Ok(false) => 2,
        Err(error) => {
            eprintln!("{error:#}");
            1
        }
    };
    std::process::exit(code);
}
