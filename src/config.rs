//! 实验 SSH 连接的输入校验；不创建工作台或调度器配置。
use anyhow::{Result, ensure};
use std::path::PathBuf;

/// 一个显式实验目标；由预检、启动或存储检查入口构造。
pub struct Node {
    pub name: String,
    pub ssh: String,
    pub ssh_config: Option<PathBuf>,
}

/// 在调用 OpenSSH 前拒绝空目标、选项注入与 shell 语法。
pub fn validate_node(node: &Node) -> Result<()> {
    ensure!(
        !node.name.is_empty()
            && node
                .name
                .chars()
                .all(|c| c.is_ascii_alphanumeric() || "-_".contains(c)),
        "invalid node name"
    );
    ensure!(
        !node.ssh.is_empty()
            && !node.ssh.starts_with('-')
            && node
                .ssh
                .chars()
                .all(|c| c.is_ascii_alphanumeric() || "-_.@:+[]".contains(c)),
        "use an SSH alias or user@host, without shell syntax"
    );
    Ok(())
}
