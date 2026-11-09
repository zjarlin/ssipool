Feature: 物理主机准入与独立磁盘冗余
  KVM 预检不等于加入 SSI，存储冗余不等于客体内存恢复。

  # evidence: docs/ssi-physical-storage.md
  @partial @p0
  Scenario: 不同物理机时钟频率有可验证的共同语义
    Given 某执行节点不提供 KVM TSC 频率缩放能力
    When 将其与另一台物理机组成同一客体
    Then 先验证 CPU 能力交集和实际 TSC 频率是否兼容
    And 频率不同时拒绝启动或使用经过验证的时间转换
    And 不通过删除频率检查掩盖长期漂移
    And 同一进程的跨宿主执行归属和时钟测试都有原始证据

  @partial @p0
  Scenario: 即将重装的主机先通过只读存储准入
    Given 一台计划清除原系统并安装 ESXi 的物理主机
    When 查询其磁盘分区、文件系统、挂载和存储管理层
    Then 只执行不写设备的硬件归属与占用检查
    And 重装意图不授予格式化、挂载或接管既有数据的权限
    And 只有重装完成、专用盘归属和稳定硬件身份重新确认后才可登记
    And 同一 ESXi 宿主上的多个 VM 不增加独立故障域数

  @research @p0
  Scenario: 存储故障恢复与 SSI 状态恢复分别验收
    Given 只含演示数据的持久卷与同一 SSI 客体
    When 分别注入掉盘整机故障和网络分区
    Then 校验已确认写入的重启持久性和唯一有效写入方
    And 单独验证失效主机上内存状态的恢复协议
    And PostgreSQL Redis 的数据丢失上限和恢复时间可测量
    And 不以 Ceph 健康或挂载成功替代数据库与 SSI 验收
