Feature: SSI 设备访问的脏页和反向映射
  这些是实际 KVM 接口实验，不代表完整设备一致性或数据库恢复已经通过。

  @partial @p0
  Scenario: 短 DMA 传输释放完整映射范围
    Given 设备映射长度大于实际传输长度
    When 完成短传输或取消零字节传输
    Then 取消固定的页面范围与最初固定范围一致
    And 在双节点上验证远端可重新取得所有页面
    And 核对重复取消和设备复位后的引用计数

  @planned @p0
  Scenario: 所有地址别名和异常路径都正确记录设备写入
    Given 同一用户页对应多个开启脏页记录的客体内存槽
    When 设备写入以及用户缓冲区出现部分复制失败
    Then 每个受影响的客体映射都被标脏
    And 未映射范围不会被当成可信内核缓冲区访问
    And 并发删除内存槽也不会遗漏或重复释放映射

  # evidence: docs/evidence/ssi-rtc-20261106.json
  @research @p0
  Scenario: 页所有权与副本集合在并发交接中一致
    Given 双节点客体交错进行 vCPU 读写和设备访问
    When 页所有者转移并降级共享权限
    Then 本地仍可读的页面保留正确的副本集合成员
    And 读页请求不会因缺失本地副本标志退出服务线程
    And 检查失败会终止相关请求而不让另一端无限等待
    And 不通过删除 WARN 或盲目补位掩盖未定位的一致性问题

  @research @p0
  Scenario: 固定操作与设备后台清理在截止时间内完成
    Given 设备持有跨调用的页面引用且其他固定操作等待远端页面或共享锁
    When 执行设备复位正常关闭或遇到无响应的远端
    Then 解除路径不因其他固定操作的反向依赖而永久等待
    And 取消与超时释放本次资源但保留既有引用和首次错误
    And 全部设备后台任务停止后才允许最终 DSM 关闭确认

  # evidence: docs/ssi-virtio-dsm-pins.md
  @research @p0
  Scenario: I/O 错误暂停后的待完成设备请求在关闭前有明确归宿
    Given 真实 virtio 块设备因错误停止并保留尚未完成的请求
    When 分别执行暂停复位销毁和整机关闭
    Then 核对待完成描述符与 DSM 读写固定引用的真实生命周期
    And 保留首次 I/O 错误而不是只检查最后一次刷盘返回
    And 请求被取消或恢复后引用才可清零且不能重复释放
    And 不以直接 HMP BlockBackend 写入代替客体设备请求验收

  # evidence: docs/ssi-reset-router.md
  @partial @p0
  Scenario: 复位后的路由继续处理对端故障和关闭
    Given EIO 请求经过复位且真实队列与 DSM 引用已清零
    When 主节点随后关闭或断开连接
    Then 副节点在截止时间内自行失败退出或完成协调关闭
    And 不让复位终止必要的路由接收和故障通知
    And 保留副节点退出超时并被强制清理的现有失败记录

  # evidence: docs/ssi-qemu-map-failure.md
  @partial @p0
  Scenario: 设备映射不能把固定失败当作可用内存
    Given QEMU 的设备映射已经找到 RAM 但真实 KVM 固定返回错误
    When 设备申请映射或清理时解除固定失败
    Then 固定失败不返回可供设备读写的成功映射
    And 平衡内存区域引用并向调用者保留失败状态
    And 解除失败阻止正常关闭通过而不是只打印日志
    And 用真实设备接口对照验证失败回滚与普通映射成功路径

