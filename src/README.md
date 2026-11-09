# 代码阅读顺序

1. main.rs：四个 CLI 入口 preflight、launch、storage-admission、storage-plan。
2. ssi.rs → ssi_probe.py：通过已有 SSH 创建空 KVM 对象，采集原生频率与接口，完整保留两端结果。
3. ssi_launch.rs → ssi_launch/model.rs → ssi_launch/session.rs：双端计划校验、输入封存、准备/许可、心跳和失败回收。
4. ssi_launch_worker.py：专用 PF24 节点上的远端 helper，已绑定历史证据，修改时需建立新来源身份。
5. storage.rs / placement.rs：只读整盘准入与物理故障域容量核算。
6. config.rs / transport.rs：仅用于本次实验的 SSH 目标和统一系统 OpenSSH 传输。
7. digest.rs：镜像和设备身份的 SHA-256 表示。

Rust struct 可按 Kotlin data class 理解：模型负责承载输入/报告，模块函数负责一次明确操作。本仓库没有任务调度器、HTTP 控制面或插件注册层。
