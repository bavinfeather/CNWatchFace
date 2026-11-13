# CNWatchFace

Garmin Connect IQ 中文山景数据表盘。

[English](README.en.md)

## 功能

- 显示时间、日期、天气和可自定义数据字段
- 趋势图支持折线和柱状图；部分 AMOLED 设备可将图表区改为数据字段
- 可调整天空和山峰配色
- 支持中文、英文设置及 AMOLED 常亮显示
- 部分设备支持和风天气和中文位置查询，需使用自己的 API Host 和 Key

支持设备和不同机型的功能差异见 [设备清单](SUPPORTED_DEVICES.md)。和风天气配置和使用限制见 [配置说明](QWEATHER.md)。

## 构建

安装 Garmin Connect IQ SDK 和 VS Code 的 Monkey C 扩展，打开本项目后运行 **Monkey C: Run Without Debugging**。发布包可通过 **Monkey C: Export Project** 生成。

## 许可

本项目保留所有权利。第三方素材和许可见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。
