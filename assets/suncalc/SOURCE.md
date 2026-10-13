# SunCalc moon phase calculation

Upstream: https://github.com/mourner/suncalc
Pinned commit: ecb6bb0b0f3a5003298cfb536e46176117caf4e5
License: BSD 2-Clause, Copyright (c) 2026 Volodymyr Agafonkin.
The complete upstream notice is retained in LICENSE.

index.js is the unmodified reference source. tools/port-moon-phase.py converts only the lunar longitude/latitude periodic terms, delta T, solar coordinates, nutation/obliquity, lunar coordinates and illumination phase calculation into source/MoonPhase.mc. It does not execute the JavaScript. Double arithmetic, an explicit atan2, a clamped dot product and subtraction of the J2000 Unix epoch preserve the calculation in Monkey C.

The port supplies a phase number, cached hourly. The displayed artwork is still the 28 original Weather Icons glyphs under their separate OFL license; SunCalc supplies no artwork. This does not implement moonrise, moonset, sky direction, southern hemisphere mirroring, or a complete ephemeris.

tests/MoonReference.mc checks the nearest 28-frame phase at all 50 official USNO primary phase times for 2026. Source timestamps remain in evidence/moon-usno-review-2026.json. This validates these samples and this display resolution, not all dates or precise event timing.
