# 迁入来源与许可证

本仓库独立于 SSHPool，初始研究快照来自：

- 仓库：https://github.com/zjarlin/sshpool
- 提交：a85dc03e74dc873b59bc075a6c752ab95e0a5cc3
- 拆分日期：2026-11-09
- 原始路径和文件 SHA-256：[import-manifest.json](import-manifest.json)

迁入 SSI 研究脚本、全部 SSI 证据、相关文档与功能规格，以及时钟预检、双端启动、存储检查/放置的 Rust 源码和测试。原始历史仍可在来源提交查询；新仓库从独立导入提交开始。

独立化改动仅整理入口与依赖：crate / CLI 改为 ssipool；提取实验所需的 SSH 连接、摘要计算；不携带原 HTTP 控制面、构建任务队列、容器调度器或工作台转发功能。Cargo.lock 从原版本收窄依赖，不主动升级已有版本。当前启动模型仍为 PF24。

docs/evidence、src/ssi_probe.py、src/ssi_launch_worker.py 以及 scripts/ssi-lab 中已绑定证据的内容保留原字节。旧版本名、脚本路径、字段、汇编符号和日志中的 sshpool 均属于历史身份，不能批量改名。原始 source_sha256 指向实际运行过的内容。

历史文档中的命令使用原二进制名称；当前命令映射见根 README。未迁入的外围工具/资料链接固定到来源提交，避免把旧工具当成本仓库入口。原任务调度器与同机数据库迁移演练不列为本仓库已完成的 SSI 能力。

LICENSE 保留原 MIT 声明。GiantVM / Linux 内核补丁沿用 GPL-2.0-only，QEMU 补丁沿用 GPL-2.0-or-later；GPL 正文位于 scripts/ssi-lab/COPYING.GPL-2.0。原始补丁上下文、源码归档与二进制证据保留各自来源和许可证，不因拆仓改成 MIT。
