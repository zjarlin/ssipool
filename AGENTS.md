# SSIPool 开发约定

- 重点是同一个 Linux 客体跨多台物理机使用 CPU、内存和存储。构建任务调度与应用多副本不能替代该目标。
- 先读 README.md、docs/CONTINUING.md 和 features/110-pooled-linux.feature；保持已验证、部分完成与研究状态准确。
- docs/evidence 中的历史记录、压缩归档和已绑定摘要的探针保持原字节。新实验用新文件，保留失败与不确定结果，不能放宽已有门槛来制造通过。
- 内核版本、协议字段、远端路径和汇编符号中的 sshpool 是历史实验标识，不做批量品牌替换。
- 真实实验只使用已授权的专用节点；操作前核对当前状态，完成后恢复原版内核、配置和本轮资源。普通 CI 不连接现场、不重启或安装实验内核。
- 修改 Rust 后运行 cargo fmt --check、cargo clippy --locked --all-targets -- -D warnings 和相关测试；研究脚本运行 scripts/ssi-lab 的相关测试，拆分和协议变更跑完整套件。
- 更新 feature 标签后运行 python3 scripts/feature-status.py，并用 --check 核对索引。
- 新增代码注释使用中文。不要在仓库保存现场密码、SSH 私钥、token 或私有连接配置。
