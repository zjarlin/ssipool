Feature: SSI 远端设备操作具有可验证的完成边界
  一个客体的本地与远端 vCPU 访问同一设备模型。
  不把设备模拟完成确认等同于磁盘持久化、PCI 总线屏障或数据库事务提交。

  # evidence: docs/evidence/ssi-device-order-20261106.json
  @verified @p0
  Scenario: 远端 MMIO 写入完成后才允许客体继续
    Given 四个客体 CPU 分布在两个专用实验 VM
    And CPU 在同一互斥锁下访问未绑定驱动的 EDU 测试设备
    When 在接收端设备锁之外为每次远端寄存器写入注入五十毫秒延迟
    Then 基线记录可复核的旧值读取
    And 完成确认候选通过相同客体的全部二百五十六次检查
    And 检查器从每次失败明细重算结果并拒绝缺失轮次

  # evidence: docs/evidence/ssi-launch-admission-20261108.json
  # implementation: docs/ssi-launch.md (通过 ssi-launch；直接调用旧 QEMU 的失败记录保留)
  @verified @p0
  Scenario: 不兼容的设备完成协议在客体启动前失败
    Given 两端的路由协议版本不一致
    When 启动握手校验版本
    Then 双方在首次 KVM_RUN 前返回协议错误
    And 不把旧数据当作 MMIO 完成确认
    And 保留失败日志及实验实例清理证据

