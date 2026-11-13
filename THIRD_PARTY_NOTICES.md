# Third-party notices

## eviltransform coordinate conversion

`source/QWeatherCoordinates.mc` ports the WGS-84-to-GCJ-02 calculation from
[googollee/eviltransform](https://github.com/googollee/eviltransform/blob/master/javascript/transform.js).
The upstream BSD-2-Clause license and copyright notice are retained in
[`licenses/BSD-2-Clause-eviltransform.txt`](licenses/BSD-2-Clause-eviltransform.txt).
Only modern-layout builds include this module.

## Material Design Icons

`resources/drawables/body_battery_handsup.svg` and every
`resources/drawables/mdi_*.svg` file are derived from the corresponding SVG
in Pictogrammers' [Material Design Icons repository](https://github.com/Templarian/MaterialDesign/tree/master/svg).
The icon name and origin are retained in each SVG comment; fills were changed
to white so Connect IQ can tint the resource at runtime. They are licensed
under Apache License 2.0. The full license is provided in
[`licenses/Apache-2.0.txt`](licenses/Apache-2.0.txt).

Copyright Pictogrammers.

Licensed under the Apache License, Version 2.0 (the "License"); you may not
use this file except in compliance with the License. You may obtain a copy of
the License at <https://www.apache.org/licenses/LICENSE-2.0>.

## Segment34mkII color palette

The soft-AMOLED and RGB222-safe MIP color pairs exposed by the individual
color settings are adapted from
[ludw/Segment34mkII](https://github.com/ludw/Segment34mkII), licensed under
the MIT License. The full license is provided in
[`licenses/MIT-Segment34mkII.txt`](licenses/MIT-Segment34mkII.txt).

Copyright (c) 2025 Ludvig Wadenstein

Top moon phase reuses the independent CNWatchFace4 port of
[mourner/suncalc](https://github.com/mourner/suncalc), pinned at
ecb6bb0b0f3a5003298cfb536e46176117caf4e5. Copyright (c) 2026 Volodymyr
Agafonkin, BSD-2-Clause; full notice: assets/suncalc/LICENSE.
The 28 moon glyphs are from [Weather Icons](https://github.com/erikflowers/weather-icons)
2.0.12, Lukas Bischoff / Erik Flowers, SIL OFL 1.1; provenance and full license
are retained in assets/moon/SOURCE.md and assets/moon/OFL-1.1.txt.
