# LootFarmer 0.5.3 — Persistent loot notifications

Apply over version 0.5.2 at the folder containing project.godot. Signing/export presets are not included or changed. Increment your Android version code when uploading a new AAB.

- Removed the five-second timeout from the top-left loot list. It displays up to three recent item/gem entries from saved history, without a background panel. Newer entries replace older ones. Tap a row for full history.
- Rows show the actual item or gem icon beside +quantity. Coins and sales are excluded from this display.
- Gem acquisition also produces a separate four-second icon/+quantity pulse below the persistent list. Rapid gem pickups accumulate and restart that pulse. Expiring the pulse does not hide the loot list.
- Damage and healing numbers last 1.8 seconds: readable for 1.1 seconds, then fade over 0.7 seconds. Each hit has an independent label and continues after actor death/removal.

Validation: Godot 4.5.1 headless feedback probe 13 checks and UI probe 24 checks, all passed. Includes persistence beyond 30 seconds, icons, transparent styles, pulse timing and accumulation, coin exclusion, history interaction, overlapping hits, actor deletion and label cleanup. Phone rendering still needs visual verification.
