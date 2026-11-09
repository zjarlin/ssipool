Feature: 从普通 SSH 登录真实的共享 Linux 客体
  这里的 shell 必须属于跨节点客体，不能连接入口宿主后冒充 SSI。

  # evidence: docs/ssi-workspace.md
  @verified @p0
  Scenario: 单节点对照先验证发行版与 OpenSSH 客体
    Given 固定哈希的官方 Linux 内核和隔离 initramfs
    When 用普通 KVM 启动并提供回环 SSH 入口
    Then 使用已核对主机密钥与显式导入的公钥完成登录
    And 密码登录关闭且未挂载宿主目录
    And 能执行命令和通过 SFTP 收发实验文件

  # evidence: docs/evidence/ssi-clock-baseline-20261105.txt
  @verified @p0
  Scenario: 实验文件系统与宿主数据没有共享挂载
    Given SSH 客体只使用自身 initramfs 和内存文件系统
    When 通过 SFTP 创建读取和删除测试文件
    Then 操作只发生在客体内存中
    And 明确告知关机即丢失且尚不支持持久化工作区
    And 不将该结果视为 Docker 和数据库验收
