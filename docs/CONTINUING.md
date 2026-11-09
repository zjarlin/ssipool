# 接续开发

2026-11-09 从 SSHPool 的 a85dc03e74dc873b59bc075a6c752ab95e0a5cc3 拆出，已有实验不重跑、不改写。

## 建议阅读顺序

1. ../features/110-pooled-linux.feature：同一个未修改客体的 CPU、内存、容器与性能目标。
2. ssi-feasibility.md：GiantVM 路线、同 ISA / KVM 前提和物理容量约束。
3. ssi-tsc-multivcpu.md：最新测量、全部失败与未完成边界。
4. ../src/README.md：代码入口。
5. ../scripts/ssi-lab/README.md：实验与证据检查入口。

## 当前可接续点

PF32 是显式启用的软件 TSC 缩放候选。单 vCPU 的 RDTSC、RDTSCP、TSC MSR 和 pvclock 已有短窗口证据；双 vCPU 实验仍为同一 VM 内交替执行。

最后的 handshake-c 矩阵使用 12 轮、500 ms 轮间等待：五次运行的速率区间全部满足 ±0.1%，50 ms 偏移对照在三条 TSC 路径全部检出。但四次共同偏移运行的误差区间只部分落入 ±100 微秒允许范围，属于不确定，不能解释为已确认的内核偏差。

先减少跨 vCPU 测量不确定性，保持原门槛重做完整矩阵；再验证同时执行、定时器、暂停恢复和跨物理运行。跨物理验收要看到同一进程线程在两台物理机实际执行、驻留内存超过任一节点配额，而不依靠 swap 或两个独立任务。

存储与故障恢复继续遵守 features/120-stateful-recovery.feature 和 features/190-ssi-physical-storage.feature。容量核算通过不代表分布式存储已经实现；数据库需要自己的持久化和故障证据。

## 已完成的现场收尾

最新一轮已恢复实验 VM 到原版 6.8.0-147-generic，移除本轮实验启动项、模块和探针，配置及缓存摘要与实验前一致。不要把历史运行脚本当成待执行清单。新仓库不携带现场 SSH 凭据，连接前先核对用户提供的目标与当前状态。

## 运行时版本

默认构建与 CLI 准入没有切换到 PF32。src/ssi_launch/model.rs 和远端 helper 仍绑定 PF24，允许的配置范围有实际封存及拒绝证据；新版内核实验由 scripts/ssi-lab/experiments 下独立补丁和探针进行。升级启动器需要新的协议、输入身份和回归证据，不能只修改版本常量。
