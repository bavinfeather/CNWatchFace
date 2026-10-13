# Weather Icons 月相来源

- 仓库：https://github.com/erikflowers/weather-icons
- 原始版本：2.0.12，commit `bb80982bf1f43f2d57f9dd753e7413bf88beb9ed`。
- 取自资料库：`D:\Watch Face\Assets\icons\weather\erikflowers-weather-icons`。
- 原始字体：`font/weathericons-regular-webfont.ttf`，本目录保存未修改副本。
- 原始阶段表：`_builder/csv/moon.csv`，本目录保存副本，使用前 28 行非 alt 图标。
- 署名：图标设计 Lukas Bischoff；v1.1 之后图标、美术及代码 Erik Flowers。
- 图标和字体许可：SIL Open Font License 1.1，完整文本见 `OFL-1.1.txt`；上游声明见仓库 README 的 License 和 Credit。

2026-10-03 通过 `tools/build-moon-assets.py` 将原字形栅格化为 28 张透明图片，仅缩放、阈值化和着色，不自行设计轮廓，不复制 CSS 或上游说明文档。新月阶段隐藏。来源、映射及图片指纹见 `evidence/moon-asset-source.json`。

发布表盘时保留来源、署名和 OFL 文本。此为原素材的格式转换，不暗示上游对本表盘背书。
