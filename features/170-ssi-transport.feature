Feature: SSI 传输等待与启动资源生命周期
  先在真实 KVM 监听器和独占实验 VM 中验证，不将同一 ESXi 的结果当作跨物理机性能。

  # evidence: docs/evidence/ssi-host-timers-20261106.json
  @partial @p0
  Scenario: KVM 返回路径兑现宿主定时器延期重装
    Given PF15 研究内核在重新开启中断前调用已有重装函数
    When 两个独占节点运行相同客体与定时器负载
    Then 完整跟踪核查延期缩短并独立执行三轮无跟踪测试
    And 普通单节点虚拟机仍须单独通过回归
    And RTC 与 watchdog 告警和 DSM 关闭错误仍阻止完整工作区验收
    And 本项不代表持久 I/O 容器数据库或跨物理机故障接管已经完成

  # evidence: docs/evidence/ssi-vcpu-residency-20261106.json
  @partial @p0
  Scenario: 无 PLE 实验宿主可显式强制 DSM 客体从 PAUSE 返回
    Given 默认关闭的实验开关和缺少 PLE 的两个独占 x86 VMX 节点
    When 对同一候选内核分别开启和关闭该开关
    Then 仅开启时捕获真实 PAUSE 退出且四个客体 vCPU 的用户态探针能继续执行
    And 记录开关对 KVM 区间和调度等待的影响及额外退出开销
    And 仍需解决剩余时钟关闭与性能问题后才能通过完整 SSI 验收

  @partial @p0
  Scenario: 完整客体的慢取页可以定位但尚未消除
    Given 两个实验 VM 上运行同一未经修改的 Linux 客体
    When 在应用时钟采样期间同时记录页面获取网络与锁调用
    Then 报告热点页面与函数等待并区分测量窗口边缘的不完整调用
    And 两侧窗口在导出任一大文件之前同时停止避免导出污染对端
    And 仍须在无跟踪运行中消除秒级停顿与 watchdog 告警后才通过完整工作区验收

  @partial @p0
  Scenario: 等待改动保留事务分流和页面交接正确性
    Given 多个 vCPU 共用同一 DSM 连接并有不同事务编号
    When 指定事务尚未收到数据或者已收到半帧
    Then 空缓冲区时让出接收锁给其他事务
    And 半帧由同一读者接收完整后再解析
    And 跨节点 pvclock 探针与完整客体内存和 SFTP 校验分别通过

  # evidence: docs/evidence/ssi-router-drain-20261106.json
  @partial @p0
  Scenario: 显式关闭协议区分任务结束与节点故障
    Given 请求仍在传输或者对端已退出
    When 客体正常关机或某个节点失联
    Then 正常关闭须完成双方确认和在途请求排空
    And 故障退出必须传递给客体管理层且不能伪装成干净关机
    And 正在处理的页面请求与缺失内存槽重试都应响应停止信号

  @research @p0
  Scenario: 封闭入口之前验证其余跨调用资源和后台生产者已经停止
    Given 设备持有 DMA 固定页面或存在 device fd irqfd 定时器及后台任务
    When 管理器准备封闭 VM 与 vCPU ioctl 入口
    Then 所有需要后续 ioctl 的设备清理和 unpin 须先完成并有真实证据
    And 补齐其余入口和三十二位兼容路径的动态故障及并发验证
    And ioctl 计数为零不能冒充固定页面归零或所有异步任务已结束

  # evidence: docs/evidence/ssi-transport-fence-20261108.json
  @research @p0
  Scenario: 整机关闭协调外部入口反向请求和所有连接
    Given 入站流屏障已完成而其他连接仍可能产生反向取页
    When 管理端开始关闭整个分布式 VM
    Then 原子停止新外部操作并等待此前操作真正返回及全部响应被消费
    And 各节点的瞬时零计数仍需与新入站请求的准入和协议世代原子协调
    And PF25 本地封闭须保留反向请求及缓存消费并优先返回故障且不能代替全局确认
    And 保留反向请求所需连接直到所有节点确认没有未完成的请求链
    And 对尚未读到标记的八线程占满半帧建连和确认发送分别验证取消及期限
    And 最终双方确认和故障优先级通过后才能将连接 EOF 视为正常结束
    And 设备清理产生的内存访问须在内核最终关闭之前完成

  @research @p0
  Scenario: 更多异常事务与内部不变量分支也能安全回收
    Given 事务缓存中的超长响应或超长失效确认或内部页面状态不一致
    When 请求被取消或协议校验失败
    Then 独立故障注入应证明所有 SRCU 和页面锁均被释放
    And 响应复制不能越过实际目标缓冲区且临时页面必须被回收
    And 错误保留给调用者而不伪装为成功

  @partial @p0
  Scenario: 重启实验时处理端口占用与监听失败
    Given 上一实例已经退出但 TCP 连接尚未完全回收
    When 尝试再次创建分布式客体
    Then 前置检查拒绝仍占用实验端口的所有 TCP 状态
    And 内核监听失败应向整个实例传播而不留下半启动节点
    And 退出失败的实例无需重置宿主即可完整回收

  @research @p0
  Scenario: 多物理机性能有可重复的负载对照
    Given 实际部署在不同物理机且网络和资源配额明确
    When 运行相同输入的编译内存和磁盘负载
    Then 分别报告单节点与分布式吞吐和尾延迟
    And 区分有用计算传输等待与采样工具开销
    And 不把客体显示更多 CPU 当作性能相加的证据
