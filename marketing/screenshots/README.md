# LootFarmer Google Play screenshots (Change 34)

Six screenshots in the approved order (boss combat, equipment collection, merging, late-game farming,
world exploration, Prestige), each rendered separately for four portrait device classes: 24 genuine
renders of `res://scenes/game/main.tscn`, staged by `../game_scenarios.gd` through the pinned
**Godot Marketing Capture Toolkit 1.0.2**. No added text, frames or overlays; the native HUD is on.
Nothing here ships (`marketing/*` is in the Release `exclude_filter`; `store_assets/` is ignored by Git
and Godot).

## Files

| Path | Tracked | What |
|---|---|---|
| `make_screenshot_manifest.py` -> `manifest.json` | yes | Device classes, the six scenes (scenario, options, capture frame, notes) and the alt-text drafts. `--draft` writes `manifest_draft.json` (the six scenes at 540x960 into `store_assets/raw/screenshots_draft/`) for staging. |
| `finalize_screenshots.py` | yes | Byte copies raw -> upload, Play-rule and raster checks, log postconditions, provenance manifest, review sheets, evidence copies. `--check` validates only. |
| `../game_scenarios.gd` | yes | Scenarios `shot_gear`, `shot_merge`, `shot_explore`, `shot_prestige` (Change 34), plus `boss_sunflower` and `trailer_farm` with new options (`wear`, `auto_collect`, `skill_at`). |
| `store_assets/raw/screenshots/<Device>/<Device>_NN.png` (+ `.log`) | no | Untouched Godot captures (masters) and their event logs. |
| `store_assets/screenshots/<Device>/<Device>_NN.png` | no | Upload files, byte-identical to the masters; `screenshots_manifest.json` beside them (sizes, SHA-256, options, log events, similarity, alt text). |
| `store_assets/review/change_34/` | no | `contact_sheet_24.png`, `store_cards_<Device>.png` (360 px store-card size), `before_after_NN.png`, `before_after_overview.png`. Reduced copies in `docs/Change_34_Evidence/`. |
| `store_assets/screenshots_change_27/` | no | The replaced Change 27 set (raw + final + its manifest), kept for comparison. |

Device classes: Phone 1080x1920, Tablet_7 1440x2560, Tablet_10 1800x3200, Desktop 1620x2880 (the
Chromebook/desktop listing slot, portrait; no separate desktop build or Chromebook certification is claimed).

## Commands (project root, Windows)

```powershell
$G = "D:/Programs/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe"
python Godot-Marketing-Toolkit/tools/marketing.py status --project .                 # toolkit 1.0.2 pinned
python marketing/screenshots/make_screenshot_manifest.py                             # manifest.json
python Godot-Marketing-Toolkit/tools/marketing.py pipeline --project . --manifest marketing/screenshots/manifest.json --godot $G --locales en-US --overwrite   # all 24 (about 2 min)
python Godot-Marketing-Toolkit/tools/marketing.py record --project . --manifest marketing/screenshots/manifest.json --job Phone_04 --godot $G --overwrite      # one image
python marketing/screenshots/finalize_screenshots.py                                 # copy, validate, sheets
```

## The six scenes

Every scene uses the isolated `capture-store` profile with `--no-autosave` and starts from
`sim.new_profile()`. Fixtures stand in for play time only (a profile at a map, owned gear and merge
levels, earlier boss defeats, a cooldown moved to just before the real event); combat, summons, drops,
pickups, equipping, merging and Prestige are the game's own code. Every worn or merged item is a real
drop of some enemy's loot table (checked by `tests/change_34_probe`).

| # | Season / map | Player gear | Moment |
|---|---|---|---|
| 01 | Spring II, rain | Red Panda outfit (T5) + Emerald Sword | The Sunflower's real summon: two Sprouts rising from their portals as the player's Lightning Strike lands on it. Player straight above the boss so the boss sits in the clear centre of the map view. Frame 55 (1.83 s); summon at 1.49 s. |
| 02 | Summer II, rain | Teal Dinosaur outfit (T2) + Iron Sword | Plain body + Wood Sword defeats the Teal Dinosaur; seed 3402 is the first seed from 3401 whose kill drops both of its loot items (found by `seed_search`, never forced). Both are collected (`sim.collect`) and worn (`sim.equip`); after the boss's real 60 s respawn the player, now dressed as it, fights it again. The frame shows the boss and its own outfit and sword on the player; the gear row shows Wood Sword ^100, Iron Sword and the outfit equipped. |
| 03 | Winter I, snow | Red Scarf outfit + Wood Axe | 100 spare Red Scarf copies (fixture: farmed from that pack) merged with the item panel's own "Merge 100 spare copies" button: ^0 -> ^100, the Guard +3 Defense milestone active, the tile's ^100 frame. Player away from the pack, so no fight behind the panel. |
| 04 | Autumn II, magenta canopies | Grim Reaper outfit (T3) + Gold Sword, three auto skills | 12 s of real farming with Auto-Collect off: the Orange Screen Helmet pack fights the player; a dropped Recovery Salve and Orange Screen Helmet outfit lie on the ground. |
| 05 | Winter II, snow | Cyan Robot outfit + Stone Sword | A first-run player exploring: the route from Camp 1 past Camp 2 revealed (21%), fog over the rest, the game's own "Camp spotted!" notice. |
| 06 | Prestige panel | Bee outfit (T4) + Diamond Axe | Late-game profile (one Prestige redeemed); four ready opportunities redeemed through `begin_prestige`; "Choose a reward 1 of 4" (Unassisted winter) offers Precision +15 pts, Resolve +5%, Hard Hit +75%; Hard Hit tapped (selected, not kept). |

## Known limits

- **01 is reproducible but not byte-identical:** a second render of Phone_01 matched except the stacking
  of the floating damage numbers above the boss (presentation timing); 02-06 re-render byte-identical.
- **04 shows no skill VFX:** a Fire Burst or Lightning Strike at this zoom covers the pack and the
  player, so the chosen frame is between casts (skill cooldowns visible in the HUD). The authored autumn
  leaves are present but subtle on the orange ground in a still; nothing is painted in.
- **03's Winter** is the strip above the item panel plus the gear row; Winter is shown in full in 05.
- 01 and 06 use the shared late-game profile, so their gear rows list the same first tiles (the
  equipped outfit differs: Red Panda vs Bee).
