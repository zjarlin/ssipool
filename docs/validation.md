# 独立仓库验证

开发机和 CI 运行 Rust 测试、Clippy、格式检查、feature 索引和 scripts/ssi-lab 全量 Python 证据测试。Linux CI 额外编译客体探针并检查错误内核拒绝。这些检查不启动现场实验。

真实链路的每次验收均以 docs/ssi-*.md 及 docs/evidence 中对应记录为准。证据重放成功只代表记录完整、分析一致；被保留的实测失败仍然失败。

## storage-placement

src/placement.rs 和 tests/storage_placement.rs 已迁入，继续测试真实 CLI 的 JSON 与退出码：同一物理机的多 VM 合并为一个故障域、已有宿主与其 VM 容量不能重复计算、副本/仲裁条件不足时拒绝给出可用容量。

这只核算显式拓扑，不创建 RAID、Ceph 或分布式磁盘，也不证明持久化及节点故障恢复。

原项目的完整历史验证文档见 [SSHPool 固定来源](https://github.com/zjarlin/sshpool/blob/a85dc03e74dc873b59bc075a6c752ab95e0a5cc3/docs/validation.md)。
