# Change 6 validation

**Environment.** Godot 4.7.2.stable.official.ed1daf0bf on Windows 10 (i5-10300H, 32 GB, GeForce GTX 1650). Windowed captures and timings use the Vulkan Forward Mobile renderer at a 540×960 window (exact 9:16) and 432×960 (≈20:9); probes run headless. No Android device was available: **no handset frame time, touch, safe-area or lifecycle result is claimed.** Evidence types below: A automated probe, B pacing bot (simulated play, not a human), R rendered capture, T desktop timing.

## Automated checks (A)

| Check | Result | Log |
|---|---:|---|
| change_6_probe (layout on all 8 stages, idle farming through respawns, prestige gate vs four early routes, card values and effects, rest, save/reload incl. layout revision and re-homing, content-sized sheet, browsing/boundaries/stale actions, refresh identity, fixed height, toast arbitration, card selection, node baseline, full camp route, suspension, no-input guide, out-of-order lessons) | 196 checks, 0 failures | Change_6_Evidence/logs/change_6_probe.log |
| change_5_probe | 137, 0 | logs/change_5_probe.log |
| campaign_probe (expected `save_read_only` warning from an injected write failure) | 260, 0 | logs/campaign_probe.log |
| campaign_content_probe | 655, 0 (ceiling: final boss 2.16M HP, 46 s basic TTK, 281 s survival) | logs/campaign_content_probe.log |
| Static validator incl. layout and tuning `--check` | 1,884, 0 | Change_6_Evidence/static_checks.json |

Contract changes in existing probes, not deletions: Heal tier-1 value 6 → 10; the winter challenge test now uses the Cyan Robot. Historical pre-campaign probes (ui, gameplay, targeting, progression, inventory) still call removed systems (`sell`, old HUD nodes) and are not acceptance criteria (as recorded since Change 5).

## Reported faults: reproduction and result

| Report | Reproduced on the Change 5 baseline | After Change 6 |
|---|---|---|
| First boss beside the player | Arrival (480, 883) to Snowman (691, 730): 261 units, the same as the nearest normal type; the weakest type 650 away. Same inversion on all 8 stages. | Weakest nearest, bosses farthest on every stage (A); Snowman at (800, 160), 791 units away in its moved arena (R `compare/encounter_layouts_all_stages.png`, `after/stage_*_layout.png`). |
| First boss too easy | Bot killed it at **1.0 min at level 2** in all 6 baseline runs (`pacing/before_*`). | 23.2–29.2 min ordinary, 14.7–22.2 rush, 9.7–18.5 expert (B). |
| Prestige in under ten minutes | Baseline allowed a reset at **16.3 min** via the Mission Specialist chain (seed 3); the user's challenge route was not reproduced in 30 min because the bot drank potions, which correctly voids that challenge. | Opportunities still become ready at 14–17 min, but **no reset before Winter is cleared**: prestige-hunter runs stayed in Winter I for 150 min with no reset allowed (`pacing/after_prestige_hunter_*`). |
| Tiny prestige rewards; text-button choices | +1–5% values, one duplicate effect; plain buttons (R `before/07`). | 10–30% values, distinct effects, real cards with selection and keep/reset summary (A, R `after/20–21`). |
| Lost after opening World | Camp purchase below six navigation rows; outline only (R `before/03`). | Pointer route World → Unlock, with explore/earn alternatives (A, R `after/12–16`). |
| Accidental neighbouring farming | Spots 116–146 apart with acquisition 140. | Closest actors of different spots > 150 on every stage (A); 180 s of idle farming targets only its own spot (A). |
| White text on snow | Toast and loot numbers unreadable (R `before/06`). | Dark backing, outlines; captured on winter, summer, autumn and spring (R `after/17`, `after/30_*`). |
| Wasted item-detail height | Sheet filled the map (R `before/04`). | Content-sized, bottom-anchored, pinned actions with ◀ ▶ (A, R `after/07–08`, `compare/item_details.png`). |
| Upgrades opening delay | T below. | T below. |

## Pacing (B)

`tests/pacing_bot.gd`, 0.1 s simulated steps, real simulation, no injected state; three seeds per configuration, 150 simulated minutes max, stopping at the first possible prestige. Times are active simulated play (no pause or menus; panels do not pause the game).

| Configuration (second runs carry the listed card) | Snowman (min) | Level 20 (min) | First possible prestige (min) | Reached gate |
|---|---|---|---|---|
| Ordinary, no cards | 23.2 / 23.8 / 29.2 | 72.2–86.4 | 91.7, 112.8 | 2/3 |
| Rush, no cards | 14.7 / 18.2 / 22.2 | 80.8 (one run) | **76.3** | 1/3 |
| Expert, no cards | 9.7 / 11.0 / 18.5 | 56.9–58.0 | 144.7 | 1/3 |
| Armor Reserve (+20% HP) | 14.1 / 16.9 / 18.3 | 83.9 | 73.3, 76.9, 133.2 | 3/3 |
| Weapon Training (+15% damage) | 16.9 / 17.9 / 18.0 | 80.6–82.3 | 89.9, 97.1, 98.5 | 3/3 |
| Trail Learning (+30% normal XP) | 16.2 / 19.7 / 21.4 | 63.5–73.7 | 91.2, 111.1 | 2/3 |
| Precision (+15 pts crit) | 16.0 / 18.2 / 20.4 | 75.4–89.9 | 84.4 | 1/3 |
| Giant Slayer (+25% boss damage) | 19.7 / 21.6 / 22.6 | 81.4–83.0 | 100.3 | 1/3 |
| Mission Coins (+50%) | 19.8 / 21.8 / 22.7 | 81.0–83.4 | 109.8 | 1/3 |
| Typical batch: Armor Reserve + Mission Coins + Resolve | 14.4 / 16.9 / 17.8 | 74.7–75.4 | 81.2, 97.2 | 2/3 |

**Interpretation.** Every first-run route that reached the gate took at least **76.3 minutes**; earlier bot versions measured 76.1 at the fastest. The one-hour minimum holds for every measured route. A perfect human route was not measured; with no manual dodging in combat, the human advantage is mainly better boss timing and upgrade choices. Every card shortened the next run's first boss by 15–40% and the combat cards the gate as well (Armor Reserve completed all three seeds, two at 73–77 min against 92–113 without cards). Mission and boss-only cards help least in Winter, as their descriptions imply; they pay off later. **Limitation:** 13 of 30 runs never reached the gate at levels 26–33, although the bot's own estimate said they could win. Traces show route failures (walking through proximity-aggro spots toward the far-corner boss, then retreating to rest), not balance walls. These are reported, not hidden, and they make the upper ranges unreliable; the lower bound is unaffected.

## Performance (T)

Desktop only, same machine, idle CPU, two passes each (`before/timings_idle.txt`, `after/timings_pass1.txt`, `after/timings_pass2.txt`; the earlier contended-CPU baseline is kept as `before/timings_contended_cpu.txt`). Method: `tests/change_6_before.gd` on the pristine Change 5 copy and `tests/change_6_capture.gd --shots=timing`, 540×960 window, 30 extra items in the inventory. Frame budget: 16.7 ms (60 FPS).

| Measurement | Before | After |
|---|---|---|
| Upgrades, first open (build / to first frame) | 6–9 / 56–62 ms | 11–12 / 17–19 ms |
| Upgrades, warm open (build) | 37–48 ms | 4–6 ms |
| Upgrades refresh while open (median / p95) | 40–41 / 46–49 ms, at every state change (≥1 per second and per kill) | 1.5–2.0 / 2.7 ms, at most 4 per second |
| Buy + refresh (median / p95) | not separately measured | 1.9–2.1 / 3.1–3.6 ms |
| Enemy upgrades, first frame | 196–202 ms | 25–27 ms (warm 23–30) |
| World / travel, first frame | 20–21 ms | 14–16 ms |
| Item details open / browse next (p95) | 8–14 ms / — | 8–11 ms / 7.4–7.5 ms |
| 30 open/close cycles | — | node count returns exactly to baseline (617 → 617) |
| Simulation step, Winter I (median / p95) | 0.85–1.01 / 1.87–2.08 ms | 0.49–0.50 / 1.12–1.24 ms |
| Gameplay frame (vsync-bound, median / p95) | 16.66 / 16.73 ms | 16.66 / 16.73 ms |

Causes fixed: the panel host rebuilt and re-synced every control (walking every property and theme override) on every state revision; enemy definitions were deep-copied for every enemy several times per physics tick; per-frame size assignments on the toast and guide card; first-open glyph shaping and icon cropping (now done at load). Startup gains the cropping and font warm-up (tens of milliseconds); not separately timed. **No Android or Moto G Power measurement exists.**

## Rendered evidence (R)

`Change_6_Evidence/after/` (9:16, and `_20x9` variants): chooser, each guided lesson including HUD → World → Unlock, item comparison and browsing, high tier and large numbers, upgrades, enemy upgrades, missions, settings, prestige overview, cards and selection, milestone banner, toast on snow, contrast on four seasons, opening and boss arena, eight stage layouts. `before/`: the same key surfaces on the Change 5 copy. `compare/`: side-by-side sheets and all-stage layout schematics. Fixture amounts (coins, items, readiness) are set directly where labelled in `tests/change_6_capture.gd`; they show presentation, not pacing.

## Reproduce

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . tests/change_6_probe.tscn -- --probe --profile=probe-change6 --no-autosave
godot --headless --path . tests/change_5_probe.tscn -- --probe --profile=probe-change5 --no-autosave
godot --headless --path . tests/campaign_probe.tscn -- --probe --profile=probe-campaign --no-autosave
godot --headless --path . tests/campaign_content_probe.tscn -- --probe --profile=probe-content --no-autosave
python tools/validate_campaign_source.py
godot --headless --path . tests/pacing_bot.tscn -- --probe --no-autosave --policy=ordinary --minutes=150 --seed=1 [--cards=arsenal_c1]
godot --path . --resolution 540x960 tests/change_6_capture.tscn -- --probe --profile=capture-change6 --no-autosave --shots=all
```

## Still open

Physical Android touch, safe areas, frame time and lifecycle; a human first-run playthrough with a stopwatch (the one-hour evidence is bot-based); Summer II onward natural pacing and late-game card stacking; 19 release locales; release signing and template QA.
