# CNWatchFace 1.2.7 更新说明

## 中文

- 新增 280×280 MIP 专用布局，覆盖 fēnix 6X/7X、fēnix 8 Solar 51mm、Enduro、Enduro 3、Descent Mk2 及对应产品族。
- 修复 Forerunner 245 Music 在读取设备不提供的 `floorsClimbed` 字段时崩溃的问题。
- 为旧版和现代路径的动态活动字段增加能力检查；不支持的字段显示 `--`，不再因缺少运行时符号崩溃。
- 保留 260×260 MIP 与 390/416/454 AMOLED 的独立布局逻辑。
- 280×280 日期/农历字体使用独立字号分支。

## English

- Added a dedicated 280×280 MIP layout for the fēnix 6X/7X family, fēnix 8 Solar 51 mm, Enduro, Enduro 3, Descent Mk2, and related product groups.
- Fixed the Forerunner 245 Music crash caused by reading the unavailable `floorsClimbed` symbol.
- Added capability guards for dynamic activity fields in legacy and modern paths; unavailable values show `--` instead of causing a runtime symbol error.
- Preserved independent layouts for 260×260 MIP and 390/416/454 AMOLED families.
- Added an independent calendar/lunar font-size branch for 280×280.

## 验证边界 / Validation boundary

- SDK 9.2.0 全设备导出用于构建验证；尚不等于每个设备完成视觉模拟器验证。
- 未进行真机验证。
