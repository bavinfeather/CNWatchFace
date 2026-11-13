# CNWatchFace

Garmin Connect IQ 中文山景数据表盘。

[English](#english)

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

## English

A mountain-themed Garmin Connect IQ watch face with Chinese and English settings.

- Time, date, weather, and configurable data fields
- Line or bar charts; on supported AMOLED devices, the chart area can show data fields instead
- Configurable sky and mountain colors
- AMOLED always-on display
- QWeather and Chinese location names on supported devices, using your own API host and key

See [supported devices](SUPPORTED_DEVICES.md) and the [QWeather setup notes](QWEATHER.md) (Chinese) for device limitations.

To build, install the Garmin Connect IQ SDK and Monkey C extension for VS Code, open this project, and run **Monkey C: Run Without Debugging**. Use **Monkey C: Export Project** to create an IQ package.

All rights reserved. See [third-party notices](THIRD_PARTY_NOTICES.md) for included assets and licenses.
