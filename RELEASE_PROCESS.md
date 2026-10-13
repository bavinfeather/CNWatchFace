# 发布归档流程

## 每次发布

1. 在 `VERSION` 中确定商店版本号，例如 `1.2.1`。
2. 运行：

   ```powershell
   .\scripts\archive-release.ps1 -Version 1.2.1
   ```

3. 脚本会先校验项目内 `keys\CNWatchFace-release.der` 的 SHA-256，再导出并归档：IQ 包、完整构建日志、IQ SHA-256、Manifest、Jungle、版本和更新说明。
4. 只上传 `releases\<版本>\CNWatchFace-<版本>.iq`，绝不上传测试任务生成的 `.iq`。
5. 在 Connect IQ Developer Portal 填写同一版本号和更新说明后上传。

## 密钥恢复

- 主副本：`keys\CNWatchFace-release.der`，不进入 Git。
- 备份：`D:\Watch Face\Backups\CNWatchFace\CNWatchFace-release-key.dpapi`，仅当前 Windows 用户可解密。
- 若两个副本都丢失，不能再更新当前 Connect IQ Store 应用，只能使用新的应用 ID 重新发布。
