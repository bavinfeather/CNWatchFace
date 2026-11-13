# 更新记录 / What's New

## 1.5.10

**中文：** AMOLED 常亮模式扩充了三个位置的自定义选项，可选步数、心率、身体电量、气温等数据。每个字段都有名称，仍可选择简洁模式。

**English:** AMOLED always-on mode expands the choices for three customizable slots, with data such as steps, heart rate, Body Battery, and temperature. Each field has a label, and the simple layout is still available.

## 1.5.9

**中文：** 仅高内存机型支持和风天气与和风中文位置查询，需自行填写 API Host 和 Key。低内存机型不支持和风天气，继续使用 Garmin 天气，通过手机调整设置。AMOLED 图表区支持上下两排独立自定义数据，字段名称与单位跟随表盘语言。精简手表菜单并修复超长文字越界。

**English:** QWeather weather and Chinese location lookup are supported only on high-memory watch models and require your own API Host and Key. Low-memory models do not support QWeather; they retain Garmin weather and use phone settings. AMOLED watches can replace the chart with two independently selectable data rows, with labels and units matching the watch face language. Simplified on-watch menus and fixed overflowing text.

## 1.5.8

**中文：** 修复运动距离字段可能导致表盘崩溃的问题，改善旧机型身体电量、恢复时间等字段的兼容性，并提升天气数据异常时的启动稳定性。为节约内存，月相显示已移除。

**English:** Fixed a potential watch face crash when displaying activity distance fields, improved compatibility of Body Battery, recovery time and related fields on older watches, and improved startup stability when weather data is invalid. Moon phase display has been removed to conserve memory.

## 1.5.7

**中文：** 为节约内存，再次移除月相显示。优化数据字段的字号与清晰度，增大部分机型的日期行；顶部文字默认普通粗细，字体选项显示实际字体名称。

**English:** Removed moon phase display again to conserve memory. Improved data field sizing and clarity, enlarged the date row on selected watches, and set the top label to Regular by default with actual font names shown in settings.

## 1.5.6

**中文：** 修复显示农历数据项时可能出现感叹号或表盘崩溃的问题，提升 Forerunner 570 等机型的稳定性。

**English:** Fixed a potential exclamation-mark error or watch face crash when displaying a lunar date data field, improving stability on Forerunner 570 and other watches.

## 1.5.5

**中文：** 新增顶部月相显示，可在设置中开启，默认关闭。调整山景轮廓，优化亮屏响应和数据缓存。

**English:** Added an optional moon phase at the top, off by default. Refined the mountain landscape and optimized wake-up responsiveness and data caching.

## 1.5.4

**中文：** 顶部自定义文字新增标准、紧凑、斜体、中等字体，仅显示手表支持的选项；保留当前字体，并新增独立的“加粗／普通”设置，默认加粗，普通模式不左右偏移。中文文字保留兼容字体回退。优化趋势图与日期行的避让，保留现有日期宽度选项及时间、PM 的自动布局。改进天气部分字段缺失时的处理：有效的零值正常显示，缺失字段可沿用当天缓存，跨天统一失效。新增紫外线指数自定义字段。减少重复加载字体和图标，增加当天农历结果缓存，并优化 AMOLED 常亮模式的绘制及近山渐变颜色缓存。

**English:** Added Standard, Condensed, Italic and Medium fonts for the custom top label, showing only options supported by each watch. The current font remains available, with a separate Bold/Regular setting (Bold by default); Regular draws without horizontal offsets. Chinese text retains a compatible font fallback. Improved spacing between the trend chart and date row while preserving date-width options and automatic time/AM-PM placement. Improved handling of partially missing weather data: valid zero values are retained, missing fields can reuse same-day cached values, and the entire weather cache expires at the next local day. Added a UV Index custom field. Reduced repeated font/icon loading, cached daily lunar-date results, and refined AMOLED always-on rendering and near-mountain gradient-color caching.

**Connect IQ update:** Device-aware top-label fonts and Bold/Regular controls, improved chart/date spacing, more reliable partial-weather handling with same-day cache expiry, a UV Index field, and font/icon/lunar-date caching improvements.

## 1.5.3

**中文：** 删除独立的“背景颜色”设置，山景下半部分统一跟随“近山颜色”；A 屏天空保留渐变，MIP 屏天空改为纯色以避免明显色阶横线；微调心率与电池的垂直间距。

**English:** Removed the separate Background Color setting and unified the lower landscape with Mountain Near Color. AMOLED watches keep the sky gradient, while MIP watches use a solid sky color to avoid visible banding. Slightly increased the vertical spacing between heart rate and battery.

**Connect IQ update:** Unified lower landscape coloring, removed the redundant Background Color setting, kept the AMOLED sky gradient, changed MIP skies to solid color to reduce banding, and refined heart rate/battery spacing.

## 1.5.2

**中文：** 新增摄氏/华氏温度切换，天气当前温度、最高/最低温、体感温度、温度字段和趋势数据会统一按所选单位显示；恢复 `°C`/`°F` 显示，并由表盘内置字形绘制度数符号，避免 fēnix 6 等机型或语言字体缺少 `°` 时单位消失。增强身体电量、健康数据和天气数据在系统数据源短暂为空或设置切换后的保留与回退，提升旧设备兼容性。

**English:** Added a Celsius/Fahrenheit selector for current, high/low, feels-like, field, and trend temperatures. Restored `°C`/`°F` labels with an app-bundled degree glyph, so units remain visible when built-in device or locale fonts (such as fēnix 6) omit the degree character. Improved retention and fallback for Body Battery, health, and weather data across transient nulls and setting changes, including legacy-device compatibility.

**Connect IQ update:** Added Celsius/Fahrenheit temperature selection with reliable `°C`/`°F` labels across device fonts, and improved Body Battery, health/weather cache retention and legacy fallback reliability.

## 1.5.1

**中文：** 新增六种时间字体并优化 fēnix 6、fēnix 7S 及其他矢量字体机型的时间与日期排版，同时精简自定义字段并增强天气与 GPS 地名缓存稳定性。

**English:** Added six time font styles and refined time and date layouts for fēnix 6, fēnix 7S, and other vector-font devices, while streamlining custom fields and improving weather and GPS location cache reliability.

**Connect IQ update:** Added six time font styles, refined time and date layouts across supported devices, streamlined custom fields, and improved weather and GPS location cache reliability.

## 1.5

**中文：** 大幅调整表盘样式与信息层级：现代布局将趋势图移至右侧，心率与电池改为左侧上下排列并让趋势最高柱贴合山景下沿；旧设备山景改为圆角景框。补充现代天气持久化缓存、设置变更后的数据缓存刷新和 MIP 颜色映射，并为全部现有自定义颜色加入纯黑与纯白选项。

**English:** Major watch-face style update: the modern layout now places the trend chart on the right, stacks heart rate and battery on the left, and brings the highest trend bar up to the landscape edge; legacy landscape scenes now use a rounded frame. Added persistent weather caching on modern devices, cache refresh after settings changes, improved MIP color mapping, and pure black and white options for all existing custom colors.

**Connect IQ update:** Major layout and style refresh with clearer status/trend placement, rounded legacy landscape framing, improved weather and cache behavior, MIP color handling, and black/white choices for all custom colors.

## 1.4

**中文：** 修复颜色设置恢复默认，并改善抬腕和秒数显示时的心率刷新。

**English:** Fixed color settings reverting to default and improved heart-rate refresh during wrist raises and second display.

**Connect IQ update:** Fixed color settings reverting to default and improved heart-rate refresh during wrist raises and second display.

## 1.3.8

**中文：** 修正周数为 ISO 周数；恢复时间、身体电量、心率、海拔、气压和血氧现在会在系统数据源暂时不可用时使用兼容回退，减少部分设备上的空值显示。

**English:** Corrected week numbers to ISO weeks and added compatible fallback data sources for recovery time, Body Battery, heart rate, altitude, pressure, and Pulse Ox to reduce missing values on some devices.

**Connect IQ update:** Improved health data reliability with ISO week numbers and fallback sources for recovery time, Body Battery, heart rate, altitude, pressure, and Pulse Ox.

## 1.3.7

**中文：** 汇总 1.3.3–1.3.6 的全部更新：新增跑步和骑行的当天、本周、本月、本年距离统计（本周从周一开始，数据来自手表本机活动历史）；新增 GPS 位置字段，可显示 Garmin 天气提供的城市或观测地点名称并自动省略过长文本；身体电量改用独立的闪电电池图标。优化全设备的数据读取与缓存周期，现代设备的天气和日出日落约每 15 分钟更新、趋势历史每 5 分钟更新、个人资料每 6 小时更新；旧版 240×240 设备移除常驻秒级定时器，默认按分钟绘制，开启秒数时只刷新时间显示。修复中文星期回退成英文、fēnix 5 系列等旧版 240×240 设备的时间和字段位置，以及 Approach S60 缺少心率历史接口时的启动崩溃。移除常驻山景离屏缓冲和图标位图缓存，降低 Enduro 3、Venu 3、fēnix 8 等设备的图形内存压力，并为图标加载或绘制失败提供程序化回退。改进退出低功耗模式时的完整重绘流程，并修复部分新设备抬腕亮屏闪烁、闪一下后黑屏或直接黑屏的问题；系统请求的每个全屏更新现在都会完整绘制，同时保留传感器、天气和个人资料的缓存策略。已完成 SDK 9.2.0 清单中 167 款设备的完整构建验证。

**本次补充：** 日期行现在会跟随系统语言切换；英文环境显示英文星期、紧凑农历格式和英文节气，简体中文环境继续显示完整中文日期行。

**English:** Consolidates all updates from 1.3.3–1.3.6: added daily, weekly, monthly, and yearly running and cycling distance statistics, with weeks starting on Monday and data sourced from on-device activity history; added a GPS location field that displays the city or observation location supplied by Garmin Weather and truncates long names; and introduced a distinct lightning-battery icon for Body Battery. Improved data refresh and cache scheduling across all devices: modern devices refresh weather and sunrise/sunset data about every 15 minutes, trend history every 5 minutes, and profile data every 6 hours; legacy 240×240 devices no longer use a persistent second-level timer, draw once per minute by default, and update only the clock when seconds are enabled. Fixed Chinese weekdays falling back to English, time and field positioning on legacy 240×240 devices including the fēnix 5 series, and the Approach S60 startup crash when heart-rate history is unavailable. Removed persistent mountain off-screen and icon bitmap caches to reduce graphics-memory pressure on devices including Enduro 3, Venu 3, and fēnix 8, with procedural fallbacks for icon loading or drawing failures. Improved full redraws when leaving low-power mode and fixed wrist-raise flashing, flash-then-black, and direct black-screen issues on some newer devices; every full-screen update requested by the system is now rendered while sensor, weather, and profile caching remains in place. All 167 devices in the SDK 9.2.0 manifest passed full build verification.

**Additional fix:** The calendar row now follows the system language: English uses English weekdays, compact lunar dates, and English solar-term text, while Simplified Chinese retains the full Chinese calendar row.

**Connect IQ update:** Added running and cycling totals, GPS location names, and a distinct Body Battery icon; improved caching, localized calendar rows, legacy 240×240 layouts, and Approach S60 compatibility; reduced graphics-memory usage and fixed wrist-raise flashing and black screens on newer devices.

## 1.3.6

**中文：** 修复部分新设备在抬腕进入高功耗模式后闪一下并黑屏的问题。表盘现在会完整绘制系统请求的每一帧，不再因数据未变化而跳过整帧；传感器、天气和个人资料仍按原周期缓存，不会每秒重新读取。

**English:** Fixed an issue where the watch face could flash once and then turn black after a wrist raise on some newer devices. Every full-screen update requested by the system is now rendered instead of being skipped when data is unchanged; sensor, weather, and profile data remain cached at their existing intervals.

**Connect IQ update:** Fixed wrist-raise flashing and black screens caused by skipped full-screen updates on some newer devices.

## 1.3.5

**中文：** 紧急稳定性修复：移除运行时常驻的山景离屏缓冲和图标位图缓存，降低 Enduro 3、Venu 3、fēnix 8 等设备上的图形内存压力；图标加载或绘制失败时自动使用程序化图标回退；退出低功耗模式时立即请求完整重绘，改善抬腕亮屏闪烁。已完成 SDK 9.2.0 清单中 167 款设备的构建验证，并通过 Venu 3 模拟器常亮与高功耗模式切换测试。

**English:** Emergency stability fix: removed persistent mountain off-screen and icon bitmap caches to reduce graphics-memory pressure on devices including Enduro 3, Venu 3, and fēnix 8; icon load or draw failures now fall back to procedural icons; exiting low-power mode now requests an immediate full redraw to reduce wrist-raise flashing. All 167 devices in the SDK 9.2.0 manifest passed build verification, including Venu 3 simulator transitions between always-on and high-power modes.

**Connect IQ update:** Reduced graphics-memory usage to address black screens on Enduro 3, Venu 3, and fēnix 8, with an immediate redraw when leaving low-power mode.

## 1.3.4

**中文：** 优化全设备刷新与缓存策略，减少不必要的重绘和数据读取：现代设备的天气/日出日落约每 15 分钟更新，趋势历史每 5 分钟更新，个人资料每 6 小时更新；旧版 240×240 设备移除常驻秒级定时器，默认按分钟绘制，开启秒数时只刷新时间显示。修复现代设备星期行回退成英文的问题，中文星期不再依赖设备或模拟器的资源回退；修复 fēnix 5、fēnix 5X、fēnix 5 Plus 等旧版 240×240 设备的时间、日期和心率行位置；修复 Approach S60 在设备不提供心率历史接口时的启动崩溃。已对 SDK 9.2.0 清单中的 98 款设备完成构建验证。

**English:** Improved refresh and cache scheduling across the device lineup to reduce unnecessary drawing and data reads: modern devices refresh weather and sunrise/sunset data about every 15 minutes, trend history every 5 minutes, and profile data every 6 hours; legacy 240×240 devices no longer use a persistent second-level timer and draw once per minute by default, while second display updates refresh only the clock. Fixed modern calendar weekdays falling back to English by keeping this Chinese watch face's weekday mapping independent of device resource fallback. Fixed time, date, and status-row positioning on legacy 240×240 devices including fēnix 5, fēnix 5X, and fēnix 5 Plus; fixed the Approach S60 startup crash when heart-rate history is unavailable. All 98 devices in the SDK 9.2.0 manifest passed the build verification.

**Connect IQ update:** Improved power-related refresh scheduling, fixed legacy 240×240 layout positioning, fixed Approach S60 compatibility, and verified all 98 supported devices.

## 1.3.3

**中文：** 新增跑步和骑行的当天、本周、本月、本年距离统计，本周按周一开始，数据来自手表本机活动历史；新增 GPS 位置字段，显示 Garmin 天气提供的城市或观测地点名称，过长时自动省略；身体电量改用独立的闪电电池图标，与普通电量清晰区分。

**English:** Added daily, weekly, monthly, and yearly running and cycling distance statistics, with weeks starting on Monday and values sourced from on-device activity history; added a GPS location field showing the city or observation location supplied by Garmin Weather, with automatic truncation for long names; Body Battery now uses a distinct lightning-battery icon to differentiate it from watch battery level.

**Connect IQ update:** Added daily, weekly, monthly, and yearly running and cycling distance statistics, GPS location names, and a distinct Body Battery icon.

## 1.3.2

**中文：** 重构多机型字体与坐标布局：时间、秒和 AM/PM 作为完整组件选择最大可用字体，日期按屏幕中心槽位自动适配字号，并恢复独立的状态行和趋势图空间；顶部两个字段整体下移。fēnix 7S / 7S Pro 启用完整现代 Round240 样式，支持顶部字段、农历、节气、天气和高级数据；其他低 API 240×240 设备继续使用精简兼容布局。

**English:** Reworked multi-device typography and positioning: time, seconds, and AM/PM now form one measured component using the largest fitting font; the calendar row fits its font within a centered screen slot while preserving separate status and trend-chart space; the two top fields were moved lower. fēnix 7S / 7S Pro now use the full modern Round240 layout with top fields, lunar date, solar terms, weather, and advanced data, while lower-API 240×240 devices retain the compact compatibility layout.

**Connect IQ update:** Improved multi-device font and layout scaling, including time, date, top fields, and trend chart positioning, with the full modern style now available on the fēnix 7S series.

## 1.3.1

**中文：** 紧急修复：恢复步数、楼层、消耗、周活动分钟、电池剩余天数、湿度、跑步最大摄氧量、太阳能强度等自定义字段的数值显示；所有自定义字段位置同步修复。

**English:** Hotfix: restored value rendering for steps, floors, calories, weekly active minutes, battery days remaining, humidity, running VO2 max, solar intensity, and other custom fields across all field positions.

## 1.3.0

**中文：** 新增月跑量、周数、通知数量、高低温、降水概率、昼夜状态、剩余日照、心率区间、月相、下一次日出/日落、移动条、静息心率、充电状态、手机连接、闹钟数量、呼吸率和天气状况等自定义字段。日期行可分别显示日期、星期、农历和节气，并提供居中标准、居中紧凑、居中宽间距布局。底部自定义字段可选 2 或 3 个，天气行可选 1 或 2 个；AMOLED 常亮精简表盘支持显示 3 个缓存字段。优化 fēnix、Enduro 等大屏设备的日期行与底部字段排版。

**English:** Added custom fields for monthly running distance, week number, notifications, high/low temperature, precipitation chance, day/night status, daylight remaining, heart-rate zone, moon phase, next sunrise/sunset, move bar, resting heart rate, charging, phone connection, alarm count, respiration rate, and weather condition. The calendar row now supports independent date, weekday, lunar date, and solar-term visibility plus centered standard, compact, and wide layouts. Choose two or three bottom data fields and one or two weather fields; the compact AMOLED always-on display now supports three cached fields. Improved calendar and bottom-field layouts for large fēnix and Enduro displays.

## 1.2.9

**中文：** 日期行现可分别显示或隐藏日期、星期、农历和节气；新增“分散 / 居中紧凑”布局。260×260 fēnix 与 280×280 Enduro 3 采用独立日期行位置和字号，改善不同屏幕尺寸上的排版。

**English:** The calendar row now lets you show or hide the date, weekday, lunar date, and solar term independently, with Spread and Centered compact layouts. 260×260 fēnix and 280×280 Enduro 3 displays now use independent calendar positioning and typography for improved fit.

## 1.2.8

**中文：** 为 Forerunner 245 Music 增加独立 legacy 布局源，可单独调整时间、秒数和 AM/PM 高度；Fenix 5 等旧设备保持独立坐标。

**English:** Added a dedicated legacy layout source for the Forerunner 245 Music, allowing independent vertical adjustment of the time, seconds, and AM/PM; older Fenix devices keep their own coordinates.

## 1.2.7

**中文：** 新增 280×280 MIP 布局；扩大 fēnix、Enduro 和 Descent 设备支持；修复 Forerunner 245 Music 字段崩溃；统一 280×280 日历中文字体。

**English:** Added 280×280 MIP layouts; expanded fēnix, Enduro, and Descent support; fixed a Forerunner 245 Music field crash; unified Chinese calendar typography on 280×280 displays.

## 1.2.4

**中文：** 新增八项自定义字段；明确活动/静息消耗为估算值，并改善旧设备的数据回退。

**English:** Added eight custom fields; clarified active/resting calories as estimates; improved fallback handling on older devices.

## 1.2.3

**中文：** 稳定性更新：修复秒数刷新、数据更新频率、节气当天判断和主题覆盖自定义颜色的问题；优化长字段对齐及 240×240 布局。节气仅用于现代布局。

**English:** Stability update: fixed second refresh, data-update frequency, solar-term date detection, and theme overrides of custom colors; improved long-field alignment and the 240×240 layout. Solar terms are available only on modern layouts.
