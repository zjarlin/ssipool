Feature: SSI 客体计时信息保持跨节点一致
  TSC、KVM 纳秒时钟和客体共享的 pvclock 页面必须分别验证。

  @partial @p0
  Scenario: 冷启动同步 TSC 偏移和 KVM 时钟
    Given 两节点提供可靠的 KVM 时钟快照与一致的原生 TSC 频率
    When 从多次请求中选择往返时间最短的快照
    Then 在启动客体 CPU 前设置并读回每个 vCPU 的 TSC offset
    And 用同一份时间快照初始化目标 KVM 时钟
    And 报告往返时间和估计的不确定范围
    And 客体跨 CPU 时钟探针和 watchdog 同时通过

  @partial @p0
  Scenario: 不满足时钟协议前提时明确失败
    Given 节点频率被缩放或不一致能力缺失协议不匹配或采样误差过大
    When 尝试启动分布式客体
    Then 明确失败而不退回未经同步的时钟
    And 每种拒绝路径都有真实接口或故障注入证据

  @partial @p0
  Scenario: pvclock 页面更新参与 DSM 一致性
    Given 两个执行节点更新位于同一共享页的 vCPU 时钟记录
    When 客体线程跨 CPU 读取记录且页面所有权反复转移
    Then 宿主缓存指针写入不能绕过 DSM 授权或覆盖新版本
    And 奇偶版本协议保证读取者不接受撕裂记录
    And 不出现已启用时钟返回零或单调时钟倒退

  @research @p0
  Scenario: 长期漂移与生命周期变更有同步协议
    Given 客体跨不同物理机运行且时钟存在频率漂移
    When 长时间负载暂停恢复重置或执行节点重连
    Then 时钟误差受明确界限约束且不会倒退
    And 未实现这些协议的冷启动候选不能被视为可用替代

  # evidence: docs/ssi-clock-resume.md
  @partial @p0
  Scenario: 全局暂停恢复建立新的时钟同步边界
    Given 两端已分别暂停且实际 vCPU 和设备生产者均已停止
    When 请求恢复同一客体
    Then 以新代际重新同步时间并协调释放执行许可
    And 跨 CPU 计时在多轮暂停恢复后仍不倒退或提前到期
    And 现有冷启动限制触发的真实失败保持可见直到协议完成
    And 不以删除 cold start only 检查替代实现

