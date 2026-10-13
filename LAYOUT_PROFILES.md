# 多机型字体与坐标 Profile

更新日期：2026-08-03

## 架构

现代源码在 `CNWatchFaceView.mc` 中提供六个同名、带注解的 `loadLayoutProfile()`：

| 注解 | 主时间候选 | 侧栏 | 顶部字段 Y | 时间中心 Y | 日期中心 Y | 秒/AMPM 行距 | 中文日历最大字号 |
|---|---|---|---:|---:|---:|---:|---:|
| `Round240` | `HOT → MEDIUM → MILD` | `FONT_TINY` | `16%` | `34%` | `50%` | 1px | 22px |
| `Round260` | `HOT → MEDIUM → MILD` | `FONT_TINY` | `16%` | `34%` | `50%` | 1px | 24px |
| `Round280` | `HOT → MEDIUM → MILD` | `FONT_TINY` | `16%` | `34%` | `50%` | 1px | 26px |
| `Round390` | `HOT → MEDIUM → MILD` | `FONT_TINY` | `16%` | `34%` | `50%` | 4px | 34px |
| `Round416` | `HOT → MEDIUM → MILD` | `FONT_TINY` | `16%` | `34%` | `50%` | 4px | 36px |
| `Round454` | `HOT → MEDIUM → MILD` | `FONT_TINY` | `16%` | `34%` | `50%` | 4px | 39px |

`monkey.jungle` 根据 SDK 9.2 `compiler.json.deviceFamily` 为每个现代产品排除其他四个实现。每个 PRG 只保留自己的 profile；新增产品时必须先确认官方 device family，再补 Jungle 映射。

240 MIP 按能力分流：API 5.2、128KB 且具备 NotoSansSC/Weather/SensorHistory 的 fēnix 7S / 7S Pro 使用现代 `Round240`；其余 240 MIP 与 Approach S62 继续使用低 API/低内存 `source-legacy`。legacy 使用同一套测量布局，由设备自己的系统字体度量吸收 Bionic、Roboto、Chronos 等差异。

## 时间组件依赖

```text
最坏时间字符串宽度 + 侧栏最坏宽度
                ↓
       居中的完整时间组件
       profile 日期中心槽（50%）
                ↓ 横向弦宽 + 状态行上界双约束
          趋势值 / 状态行（61%）
                ↓
            趋势图（64%–74%）
```

- 主时间使用固定的最坏字符串槽位，当前时间变化不会导致 X 抖动。
- 秒和 AM/PM 是同一个侧栏块；两行高度为 `2 × fontHeight + lineGap`。
- 日期不直接累加系统数字字体的 line box；该 line box 在部分设备含较大的不可见 leading。日期使用 profile 的 50% 视觉中心槽。
- 日期字体从 profile 上限逐级缩小，必须同时满足圆屏弦宽和不进入 61% 状态行；只把字段间距压到零不算成功。
- 趋势行至少位于日历底边加一个小字体半高之后。
- 趋势图保持 64%–74% 的设计区间，不能再由日期二次下压成零高度。
- legacy 的日期、状态、趋势和底部字段同样逐行派生。

## 调整规则

1. 字体档位、时间中心和间距只在对应 `loadLayoutProfile()` 中修改。
2. 不得在共享绘制流程添加 `if (device)` 或独立 `+/-px` 修补。
3. 改字体后必须重新检查该分辨率内至少两个不同字体签名。
4. 修改 profile 后至少复测 12/24 小时、秒开关、AM/PM、最长中文日历和睡眠/AOD。
5. 新分辨率先新增注解 profile 和 Jungle 排除，再加入 Manifest。

## 2026-08-03 验证状态

- 先前把“无明显重合”记录成 profile 通过属于错误验收，已撤销。
- 用户截图确认旧实现中 fēnix 7 Pro、Enduro 3、fēnix 8 的日期过低并压缩趋势图；fēnix 8 时间还因临时改成 32% 而过高。
- 当前修订完成 SDK 9.2 代表目标编译及完整导出：`167/167 DEVICES BUILT`，`BUILD SUCCESSFUL`。
- 视觉结果待用户复测，不在没有用户截图确认时标记通过。
