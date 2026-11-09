# SSIPool

**研究一个 Linux 客体直接使用多台物理机的 CPU、内存和存储。**

目标是让未修改的多线程程序、Docker、PostgreSQL、Redis 等运行在同一个系统映像里。开发重心是分布式虚拟化、共享内存一致性、时钟、设备 I/O 与故障恢复。

本仓库于 2026-11-09 从 [zjarlin/sshpool](https://github.com/zjarlin/sshpool) 独立拆出。SSH 构建任务调度留在原仓库；这里集中维护 SSI 研究。来源提交、文件摘要和保留的历史标识见 [迁入记录](docs/PROVENANCE.md)。

## 当前进度

- 基于 GiantVM 的定制 Linux KVM 与 QEMU，已在同一物理 ESXi 的两个实验节点上启动同一 Linux 客体，取得共享内存、SSH、文件传输以及若干设备/关闭协议的有限证据。
- PF32 软件 TSC 缩放通过了单 vCPU 短窗口检查。最新双 vCPU 交替实验的最终矩阵速率通过，50 ms 错位对照检出；±100 微秒对齐仍因测量区间不确定而未验收。
- 跨物理同一客体、超过单节点的驻留内存、未修改业务容器、持久化和故障接管尚未交付。Apple Silicon 与 x86 共同承载同一客体也没有支持证据。

逐项验收在 [features/README.md](features/README.md)。CI 重放证据通过不等于完整 SSI 可用；失败记录与测量不确定性一并保留。

## 开始修改

需要 Rust 1.89+、Python 3、系统 OpenSSH；普通开发和证据测试不需要 ESXi 或实验内核。

```sh
git clone https://github.com/zjarlin/ssipool.git
cd ssipool
cargo build --locked
cargo run --locked -- --help
cargo test --locked
python3 scripts/feature-status.py --check
python3 -m unittest discover -s scripts/ssi-lab -p 'test_*.py'
```

先看 [接续开发说明](docs/CONTINUING.md)，再按 [源码入口](src/README.md) 修改。研究路线和验收定义在 [严格 SSI 可行性](docs/ssi-feasibility.md) 与 [同一客体规格](features/110-pooled-linux.feature)。

## CLI

```sh
# 只读预检两个已有 SSH 目标；会创建并关闭空 KVM 对象，不执行客体
cargo run --locked -- preflight lab-a lab-b --ssh-config /path/to/lab-ssh-config

# 按已核验的显式 PF24 计划运行专用实验
cargo run --locked -- launch --plan /path/to/plan.json --output /path/to/new-run

# 只读存储候选检查与故障域容量核算
cargo run --locked -- storage-admission --ssh lab-a --device /dev/sdb
cargo run --locked -- storage-plan --topology /path/to/topology.json
```

这些命令不会安装分布式操作系统，也不会把电脑自动加入资源池。`launch` 仍只接受已有 PF24 准入协议；PF32 时钟研究由 `scripts/ssi-lab/` 的独立探针完成，不能把其镜像直接填入 PF24 计划。

| 历史文档命令 | 本仓库命令 |
| --- | --- |
| `sshpool ssi-preflight` | `ssipool preflight` |
| `sshpool ssi-launch` | `ssipool launch` |
| `sshpool storage-admission` | `ssipool storage-admission` |
| `sshpool storage-plan` | `ssipool storage-plan` |

研究节点目前要求 x86_64 Linux 与匹配的 KVM 接口。它们可以是支持 KVM 的物理 Linux，也可以是已开放嵌套虚拟化的专用 VM；同一物理宿主里的多个 VM 不构成多物理机汇聚证据。

## 目录

| 路径 | 内容 |
| --- | --- |
| `src/` | 独立 Rust CLI、原生时钟预检、双端启动准入、存储核算 |
| `scripts/ssi-lab/` | KVM/QEMU 构建入口、客体探针、采集器、证据检查和测试 |
| `scripts/ssi-lab/experiments/` | 尚未进入默认运行时的内核/QEMU 候选补丁 |
| `docs/evidence/` | 原始读数、失败记录、源码与实际运行二进制归档 |
| `features/` | SSI 目标与逐项验收状态 |

Rust 控制程序沿用 MIT；Linux 补丁为 GPL-2.0-only，QEMU 补丁为 GPL-2.0-or-later。具体来源与许可证见 [迁入记录](docs/PROVENANCE.md)。
