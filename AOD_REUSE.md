# 独立 AMOLED AOD

CNWatchFace 一至四代共用 `source/SharedAod.mc`（绘制）和 `source/SharedAodFields.mc`（字段和取数）。一代保留主副本，其他三代各带一份相同源码及设置资源，以便独立编译。改动后运行 `python scripts/sync-aod-module.py --write` 同步，去掉 `--write` 可核对。每代的 `aod-properties.xml` 保留各自的默认值。

## 复用方式

AMOLED 低功耗 `onUpdate` 入口调用：

```monkeyc
var fields = SharedAodFields.collect(simple, defaults, dateText, dayOfWeek, batteryFallback);
renderer.draw(dc, hour * 60 + minute, timeText, dateText, fields);
```

- `timeText`：已按该表盘的 12／24 小时设置格式化的 `HH:MM`。
- `dateText`：已按该表盘语言格式化的日期。
- `defaults`：左、中、右三个字段的默认 ID。`fields` 为 0～3 对 `[数值, 名称]`，隐藏项已经收拢。
- 普通显示和 MIP 显示仍走各自原来的绘制路径。
- 保留各项目自己的应用 ID、数据来源和设置编号，不直接复制一代整个 View。

绘制模块只接收格式化文本。字段模块每分钟按所选字段读取系统数据，同一组合的重复回调直接复用。简洁模式跳过字段取数。同一帧里多个活动字段共用一次 `ActivityMonitor.getInfo()`，重复选择同一字段也只取一次。字段更新走 `onUpdate`，没有额外定时器或 `onPartialUpdate` 刷新。

心率优先取系统当前值，其次取最近一条 60 秒内的记录。身体电量和压力使用设备提供的系统复杂功能值。气温读取 Garmin 的天气缓存，超过两小时或缺少观测时间时显示 `--`，和风的后台查询不参与息屏取数。距离和气温使用系统单位。

参考 [Segment34 mkII 的取数与常亮绘制](https://github.com/ludw/Segment34mkII/blob/main/source/Segment34View.mc)、[Garmin 表盘低功耗指南](https://developer.garmin.com/connect-iq/articles/user-experience-guidelines/Watch_Faces.html)及 [Garmin 天气缓存接口](https://developer.garmin.com/connect-iq/api-docs/Toybox/Weather.html)。

## 常亮显示

手机设置仅在 AMOLED 机型显示常亮选项。简洁模式显示时间、日期和山形。选择“显示自定义字段”后可配置左、中、右位置，字段名称显示在数值上方，隐藏位置自动收拢。

时间放在上方，日期和可选数据在中间，下方保留两条山脊和一块暗铜色三角切面。山脊沿用一代正常表盘远山／中山的折线比例，压缩到屏幕下方的安全范围。本模块没有增加数据读取。山脊坐标只创建一次，描边后恢复默认笔宽。

这是一套固定的系列 AOD 图案：坐标保存在 `SharedAod` 内部，不调用任何表盘的背景绘制函数，也不读取当前背景的形状或颜色。其他表盘复制此文件即可显示同一套山形；只需提供时间、日期与缓存数据，不需要重新适配各自的山景。

时间使用独立的 Regular 矢量字体，支持不足时回退到系统数字字体。字体按屏幕尺寸缓存，并检查最宽数字及字高。软件亮度预算加入完整文字矩形、加宽的线段面积和切面包围盒，并用颜色最大通道估计亮度上界，再统一缩放文字和装饰颜色，预算为圆形屏幕面积的 8%。这个估算不是 Garmin 的精确亮度算法、热图测试或电池续航测量。时间采用固定的最宽数字估算，以避免分钟变化导致灰度变化。

模块面向本项目已支持的圆形 AMOLED 机型。初代 Venu 的连续像素限制未验证，后续如新增该机型需要另做适配；小幅位移本身不能证明通过其三分钟保护规则。

## 验证边界

初版结果保存在 `work/aod-20261003`；几何版的修改前备份、范围指纹、构图预览与代表编译结果保存在 `work/aod-geometry-20261003`。构图预览是本地字体绘制的设计图，不是模拟器或真机截图。正常表盘绘制、设置资源和其他三个表盘源码保持原样。

本轮未中断已经运行的模拟器会话。实际低功耗显示、24 小时热图、抬腕恢复和真机可读性仍待验证；不要将编译成功等同于这些项目已通过。未生成发布包。
