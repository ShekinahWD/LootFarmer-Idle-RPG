# Change 80 evidence

Report: `docs/LootFarmer_Change_80_Report.md`. Brief: `docs/LootFarmer_Change_80_XP_Critical_Camp_Stage_Progression.md`.

## XP measurements (non-gating)

- `xp_farm_builds.json`: six build fixtures from the Change 78 boss audit (`docs/Change_78_Boss_Balance_Evidence/builds_c78.json`): Autumn II boss-ready L135 with supplies and skills, Spring I arrival L137 (no supplies or skills), Spring I boss-ready L190 (supplies and skills), Spring II arrival L192 and the same build at L165 (no supplies or skills), Spring II boss-ready L235 (supplies and skills). Each build Focus-farms every normal type of its stage for 5 minutes (standard spot, 3 enemies, real respawns), seeds 1-3. The levels, merges and kills are seeded fixtures, not a playthrough. The builds have no XP upgrades or XP cards, so these are base-XP rates. Every multiplier applies on top, unchanged.
- `tests/change_80_xp_audit.tscn` is `tests/player_feedback_audit.gd` with one change: Focused Farming is set directly as a fixture, because the old per-type purchase is refused since Change 65. Before = HEAD 80c0bf4, run in a clean worktree. After = Change 80.
  `godot --headless --path . res://tests/change_80_xp_audit.tscn -- --probe --profile=probe-c80xp --no-autosave --first-run-complete --builds=res://docs/Change_80_Evidence/xp_farm_builds.json --csv=<out.csv>`
- `xp_farm_before.csv` / `xp_farm_after.csv`: raw rows, 84 each, all valid. The three seeds gave identical rows (the farm loop is deterministic for these fixtures).
- `xp_tables.py` turns the CSVs into `xp_tables.md`: base XP before/after, measured kills/min and deaths, XP/min and minutes per level at the build's level, levels gained in the 5 minutes, exact boss level jumps and XP per level.
- The arrival builds without supplies (S7_arrive_raw, S8_arrive_raw*) die 5-10 times in 5 minutes on the harder types. Their kill rates are a lower bound and not typical play. The supplied boss-ready builds have 0 deaths.

## Screenshots (desktop renders at Android portrait sizes, not device captures)

`tests/change_80_capture.tscn` at 432x960 and 540x960 (English), 432x960 Russian and 540x960 German. The new strings show the English fallback in those two languages until the translations arrive. Every stage-list shot passed the bounds audit (8 cards, labels inside cards, no overlap, tap height >= 56, list inside the sheet).

| File suffix | State |
|---|---|
| `01_stages_fresh` | Fresh save in Winter I: Winter I HERE, Winter II NEXT and locked |
| `02_stages_unlocked5_at_winter1` | Autumn I reached this run, player in Winter I: NEXT = Autumn II; followed Mastery icon on Winter II |
| `03_stages_unlocked5_scrolled` | Same state, list scrolled |
| `04_stages_all_unlocked` | All eight unlocked, player in Spring I: "All stages unlocked this run", no NEXT |
| `05_camp_supplies_toast` | "Camp Supplies: +3 supplies" in the toast lane |
| `06_camp_panel_cooldown` | Camp panel: "Camp Supplies: next in 7m 47s" |
| `07_prestige_choice_camp_supplies` | Regional Prestige choice: Camp Supplies +3, the new description |
