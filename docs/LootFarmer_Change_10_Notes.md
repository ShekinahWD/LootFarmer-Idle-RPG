# LootFarmer — Change 10 Notes

Baseline: Change 9 (`6238f86`). Implementation commit: `4dcc7d4`. Brief: docs/LootFarmer_Change_10_Instructions.md.

## What changed

| # | Area | Change | Where |
|---|---|---|---|
| 1 | Equipment slots | Exactly 70: 3 initial + 67 purchases. 68 reachable identities fit. Supplies unchanged (separate pool). Max reads "70 / 70 · maxed"; dock heading shows MAX. Load clamps level and row. | catalog `upgrades.gear_slots.cap`, `tools/change10_catalog.py`, `campaign.clamp_equipment_slots`, `valid_snapshot` |
| 2 | Outfit slots | Frame per ^100 milestone (bronze, silver, gold, aqua, rose owned Kenney borders), small tier-colour lift, tinted `qty · ^merge`. Visual only. Dock grid, dock equipped outfit, item details, Inventory panel. | `resources/game/outfit_slot_styles.tres` (inspector), `scripts/game/outfit_slot_styles.gd`, `slot.tscn/MilestoneFrame` |
| 3 | Boss Gems | Boss payout = (3 × normal amount + Boss Gem Amount levels) × (1 + boss Gem card). Chances unchanged. One authority: `sim.gem_amount`; reward, enemy panel and upgrade card read it. | `simulation.gd`, catalog `progression.gem_limits.boss_amount_multiplier` |
| 4 | Farming Guide | World → Farming guide. Per map: opens at Map Details 3/3 + Stats & Drops on every type (bosses included); locked maps list what is missing. Shows discovered types/spots only; undiscovered ones are placeholders. Directions from the nearest known camp; Details opens the enemy panel. No markers, fog reveal or travel. | `game_ui._farming_panel`, `campaign.farming_guide_status`, `campaign.spot_bearing` |
| 5 | Stat sources | Stats shows "Where your HP / damage comes from": base, levels, equipped, stored (15% / 30%), worn-outfit milestones, prestige ×, total used in combat; per-hit damage modifiers and guard cards listed apart. | `sim.stat_breakdown`, `game_ui._breakdown_section` |
| 6 | Level panel | Tap the level/XP bar (flat 44 px overlay, second tap closes). Level, XP to next, +5 HP / +0.5 damage per level, now → next level (combat getter at both levels), breakdowns, Stats button. Max level shows no next level. | `main.tscn Meters/XP/Open`, `game_ui._level_panel`, `sim.stats_at_level` |
| 7A | Prestige | Button always opens the panel (no gated label). Reset action shows a ✓/✗ checklist; the locked button names the first missing condition. | `game_ui._nav`, `_prestige_requirements` |
| 7B | Centring | Hard Reset (and every) confirmation centred on the safe-area X axis from its real size; the onboarding chooser shown after a reset was drawn 600 px wide but placed by its smaller minimum width (sat right of centre) and is fixed too. Vertical placement unchanged. | `game_ui._layout_confirm`, `centered_x`, `tutorial_guide._process` |

Text: English only exists in this project (other languages are gated until release), so no Spanish strings were added. New/changed keys are in localization/en.po.

## Player level growth (actual formulas)

HP = 100 + 5 × (L − 1); damage = 5 + 0.5 × (L − 1); XP for the next level = ceil(12 × L^1.35). Each level adds +5 HP and +0.5 damage before prestige cards (a ×1.2 HP card makes it +6).

| Level | Base HP | Base damage | HP from levels | Damage from levels | XP to next level | Total XP to reach |
|---|---|---|---|---|---|---|
| 1 | 100 | 5 | 0 | 0 | 12 | 0 |
| 5 | 120 | 7 | 20 | 2 | 106 | 174 |
| 11 | 150 | 10 | 50 | 5 | 306 | 1,283 |
| 20 | 195 | 14.5 | 95 | 9.5 | 685 | 5,496 |
| 50 | 345 | 29.5 | 245 | 24.5 | 2,360 | 49,043 |
| 100 | 595 | 54.5 | 495 | 49.5 | 6,015 | 252,966 |

Level 11 with no gear and no prestige: **150 HP, 10 damage** (probe-checked).

## Where extra HP comes from at level 11

Inspection found no bug: no double count, the equipped item counts once at full value and is never also stored, the next-level gain is exactly +5 HP, and the stat cache is invalidated on every state change. Level growth is unchanged.

A realistic level-11 fixture (Snowman outfit ^40 worn, Wood Sword ^30, six stored Tier 1 outfits at ^25) has **204 HP**: base 100 + levels 50 + equipped 43.2 + stored 10.8. Additional HP sources:

- **Equipped outfit** (largest): a boss outfit is 3× a normal one (Snowman 24 base HP), and merges add 2% of base per copy (×1.8 at ^40, ×3 at ^100). A random extra roll can add 5–15 HP.
- **Stored outfits at 15%** of their core HP (random extras included at the same share); stored weapons at 30%.
- **Worn outfit milestones**: ^200 adds 10% of that outfit's core HP (and Guard/Recovery at other steps).
- **Prestige HP cards** multiply the whole sum.
- Out of combat, camp rest and Recovery refill HP faster, which can read as "more HP" but does not raise max HP.

The Level panel and Stats now show these lines with the totals combat uses.

## Tests (focused)

- `tests/change_10_probe` — 90 checks, 0 failures. It covers the slot cap and purchases, load clamps, a real disk save/load and Hard Reset; ^100–^500 frames; boss Gem chance vs amount and stacking, including the real reward path; Farming Guide unlock rules and privacy; growth and breakdown consistency; XP bar tap and toggle; Prestige access vs reset gate; and dialog X centring.
- `tests/change_10_smoke` and `tests/change_10_capture` produce the screenshots in docs/Change_10_Evidence/ui/.
- Regression: change_9_probe 51/0, change_9_balance 35/0, change_8_probe 73/0, change_7_probe 78/0 (two checks updated for the new Prestige button and slot cap), change_6_probe 200/0, change_5_probe 137/0, campaign_probe 262/0, validate_campaign_source 0 failures.
- The legacy probes change_1, ui, inventory, progression and gameplay fail or time out identically on the Change 9 baseline, so those failures predate Change 10.

## Android verification

- Outfit frames on device: are ^100 (bronze, thin) and ^300/^400 readable at the phone's slot size? Tune colours or frames in outfit_slot_styles.tres.
- XP bar tap: target size next to the HP bar and Pause, and no interference with the joystick.
- Farming Guide scroll length on later maps with many spots.
- Hard Reset dialog and chooser centring with real notch/gesture insets (desktop insets are zero).
- The confirmation panel's background looks faint over busy panels (pre-existing styling, unchanged).
