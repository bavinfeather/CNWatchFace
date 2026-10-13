# Release readiness

## Required before submitting an update

- [x] Restore and verify the original release `.der` private key. Connect IQ
  accepts updates only when their signature matches the already-published version.
- [x] Create a project-local ignored key copy and a current-user encrypted
  external backup.
- [x] Archive the IQ file, SHA-256, SDK version, and build log alongside the
  release notes using `scripts/archive-release.ps1`.

## Visual and device validation

Record each item as **simulator passed**. A successful export alone is not
visual validation; this project currently has no physical-device test claim.

- [ ] AMOLED 390 simulator: active screen, AOD Heat Map, wake, minute movement, midnight.
- [ ] AMOLED 416 simulator: active screen, AOD Heat Map, wake, minute movement, midnight.
- [~] AMOLED 454 simulator: active screen checked on 2026-07-19; AOD Heat Map,
  wake, minute movement, and midnight remain to be run before the next update.
- [ ] MIP 240 and 260: active/sleep, second-hand setting, all three bottom fields.
- [ ] Chinese and English: longest date, weekday, lunar text, weather, five-digit steps.
- [ ] Data fallbacks: no weather, no location, no heart rate, no activity record.
- [ ] Settings: change every field, trend type/style, theme, and AOD right field.

## AOD acceptance criteria

- Black background; no second hand, mountain scene, weather, trend, or progress ring.
- Only clock, date, cached heart-rate indicator, and the optional cached/date AOD field.
- The static group moves each minute and the heat map does not reveal an excessive
  static-pixel footprint.
