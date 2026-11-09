Feature: 隔离的同 ISA 双节点 GiantVM 实验
  实验 VM 不等于独立物理机，实验进展不计作生产 SSI 完成。

  @research @p0
  Scenario: 冷启动重复性和宿主内存安全
    Given 已记录上游与本地补丁的精确版本
    When 重复冷启动并交错执行缺页失效和关闭流程
    Then 排除页引用重复释放以及未经 DSM 授权的预取映射
    And 通过内存压力并发原子操作与长时间运行验证
    And 未完成该门槛前不迁移生产数据库

