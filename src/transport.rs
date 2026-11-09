use crate::config::Node;
use anyhow::{Context, Result, bail, ensure};
use std::{process::Stdio, time::Duration};
use tokio::{
    io::{AsyncRead, AsyncReadExt},
    process::Command,
};

/// 所有节点命令都通过系统 OpenSSH；保留已有密钥、跳板与主机校验。
pub fn command(node: &Node, script: &str) -> Command {
    let mut command = Command::new("ssh");
    command.args([
        "-T",
        "-oBatchMode=yes",
        "-oStrictHostKeyChecking=yes",
        "-oConnectTimeout=5",
        "-oServerAliveInterval=10",
        "-oServerAliveCountMax=3",
    ]);
    if let Some(config) = &node.ssh_config {
        command.arg("-F").arg(config);
    }
    let script = format!(
        "export PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin; {script}"
    );
    command
        .arg(&node.ssh)
        .arg(format!("sh -c {}", quote(&script)));
    command.kill_on_drop(true);
    command
}
pub fn quote(value: &str) -> String {
    format!("'{}'", value.replace('\'', "'\\''"))
}
async fn bounded(mut reader: impl AsyncRead + Unpin, limit: usize) -> Result<Vec<u8>> {
    let mut bytes = Vec::new();
    let mut chunk = [0; 8192];
    loop {
        let count = reader.read(&mut chunk).await?;
        if count == 0 {
            return Ok(bytes);
        }
        ensure!(
            bytes.len() + count <= limit,
            "remote output exceeded {} bytes",
            limit
        );
        bytes.extend_from_slice(&chunk[..count]);
    }
}
/// 短命令只保留有界输出，并对整个 SSH 子进程设置超时。
pub async fn capture(node: &Node, script: &str, seconds: u64) -> Result<(i32, Vec<u8>, Vec<u8>)> {
    let mut child = command(node, script)
        .stdin(Stdio::null())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()?;
    let stdout = child.stdout.take().context("missing stdout")?;
    let stderr = child.stderr.take().context("missing stderr")?;
    let result = tokio::time::timeout(Duration::from_secs(seconds), async {
        let (status, stdout, stderr) = tokio::try_join!(
            child.wait(),
            async {
                bounded(stdout, 1024 * 1024)
                    .await
                    .map_err(std::io::Error::other)
            },
            async { bounded(stderr, 65536).await.map_err(std::io::Error::other) }
        )?;
        Ok::<_, anyhow::Error>((status.code().unwrap_or(255), stdout, stderr))
    })
    .await;
    match result {
        Ok(value) => value,
        Err(_) => {
            child.kill().await?;
            bail!("SSH command timed out after {seconds}s on {}", node.name)
        }
    }
}
pub async fn checked(node: &Node, script: &str, seconds: u64) -> Result<Vec<u8>> {
    let (code, stdout, stderr) = capture(node, script, seconds).await?;
    ensure!(
        code == 0,
        "{}: command exited {code}: {}",
        node.name,
        String::from_utf8_lossy(&stderr)
    );
    Ok(stdout)
}
