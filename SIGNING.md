# 发布签名记录

Connect IQ Store 的同一个应用 ID，所有更新必须使用首次发布时相同的开发者私钥。

- 原始密钥来源：`D:\AI\developer_key`
- 项目内发布密钥：`keys\CNWatchFace-release.der`（被 `.gitignore` 排除）
- 当前 Windows 用户加密备份：`D:\Watch Face\Backups\CNWatchFace\CNWatchFace-release-key.dpapi`
- 密钥文件 SHA-256：`51D8BE964D98E7DC32EF6BCD529E8DA3165E43BCCC0986EB150F9453A88F8FB9`
- 应用 ID：`91e0edba-23f5-4d6e-b8da-b42dac9c16db`

## 强制规则

- 发布、更新和商店验证只能使用上述密钥。
- 测试任务不得生成临时密钥后把对应 `.iq` 当作发布包。
- 密钥文件不得提交到源码仓库、聊天附件或公开网盘。
- 每次导出前检查构建命令的 `-y` 参数；必须指向项目内发布密钥，且 SHA-256 必须与本文件一致。
- DPAPI 备份只能由当前 Windows 用户配置文件恢复；它不是跨电脑备份。换电脑前需要另行制作加密离线备份。

## 2026-07-19 故障记录

临时审计任务使用 `audit-key.der` 生成 `CNWatchFace-1.2.1.iq`，商店因此提示：

`Signature check has failed. All app versions must be signed with the same key pair.`

处理方式：保留修复后的源码，使用正式发布密钥重新执行完整商店导出。正确重签包为：

`C:\Users\bavin\Documents\Codex\2026-07-19\jie\outputs\CNWatchFace-1.2.1-original-key.iq`
