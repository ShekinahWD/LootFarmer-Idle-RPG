# LootFarmer Change 34: Google Play screenshot creative redesign

Brief: `docs/LootFarmer_Google_Play_Screenshots_Creative_Redesign.md`. Screenshots only: the icon, adaptive
icons, feature graphic, trailer, music, store copy, gameplay and the Playbook are untouched.

## Why the Change 27 set failed

Critique of the 24 old images (`store_assets/screenshots_change_27/`, sheet in `docs/Change_34_Evidence/before_after_overview.jpg`):

- **Same background six times:** every image is Spring II (green grass, rain). No Winter, Summer or Autumn.
- **Same look six times:** the player wears the Sprout outfit + Emerald Sword in all six. The gear row
  (40% of each image) is identical in all six, so the images read as one screen.
- **Enemy repetition:** Sprout-type enemies in 01, 02 and 04; the Bee (02) appears only as a name.
- **Huge damage numbers over the boss** in 01; 02 shows a 58 s respawn timer, a single sword pickup and
  no loot story; 04 is a tiny clump of fighters in an empty field.
- **Panels:** 03 is a weapon panel with "+8.63 damage" (no visible improvement), 05 a text list with a
  tiny minimap, and 06 a requirements page ("A new beginning") rather than rewards.
- **No equipment link:** nothing shows that defeated enemies drop the gear they carry and that wearing it
  changes the player.

## The new set (order unchanged)

| # | Concept | Map / weather | Player gear | What the frame shows |
|---|---|---|---|---|
| 01 | Late-game summoning boss | Spring II, rain | Red Panda outfit + Emerald Sword | Sunflower centred, two Sprouts rising from real summon portals, the player's Lightning Strike flash on the boss |
| 02 | Steal and wear enemy gear | Summer II, rain | Teal Dinosaur outfit + Iron Sword | The player, dressed in the gear the Teal Dinosaur dropped, fights the respawned Teal Dinosaur: boss and player wear the same outfit and sword |
| 03 | Merge and improve | Winter I, snow | Red Scarf outfit + Wood Axe | Item panel after a real "Merge 100 spare copies": ^0 to ^100, Guard +3 Defense milestone active, ^100 tile frame |
| 04 | Late-game farming and loot | Autumn II, magenta canopies, leaves | Grim Reaper outfit (T3) + Gold Sword | Orange Screen Helmet pack attacking the player; a dropped Recovery Salve and the helmet outfit on the ground |
| 05 | World exploration | Winter II, snow | Cyan Robot outfit + Stone Sword | Wide view (1.0x) at the fog edge, 21% explored, the game's own "Camp spotted!" notice |
| 06 | Prestige and permanent upgrades | Prestige panel | Bee outfit + Diamond Axe | "Choose a reward 1 of 4": Precision +15 pts, Resolve +5%, Hard Hit +75% (selected) |

Seasons: Spring (01), Summer (02), Winter (03, 05), Autumn (04). Five distinct worn looks and five
weapons; five enemy types on screen (Sunflower and its Sprouts in 01, Teal Dinosaur in 02, Orange
Screen Helmet in 04, Reindeer Antlers in 05). The final Green Alien boss is never shown.

**Selection:** about 60 draft candidates at 540x960 (boss: 14 framings and timings; gear: seed search;
merge: Cyan Robot, Snowman, Reindeer Antlers and Red Scarf; farming: four packs, three zooms, skill
timings and loot runs; exploration: Summer I, Spring I, Autumn I, Winter I and Winter II; Prestige:
regional, arsenal and challenge batches). Rejected and why:

- Bosses with Fire Burst, Arcane Strike or Lightning hitting the boss mid-effect: the effect covers it.
- Farming frames with skill effects: Fire Burst hides the pack and the player.
- Reindeer and Snowman merges: combat behind the panel and a damage number over the snow.
- A weapon merge: only +8.63 damage, no visible milestone.
- Exploration on Summer I and Spring I: Spring I would repeat a season shown in 01.
- The exploration-only Prestige cards (Explorer, Far Sight, Camp Survey): they are not combat power.

## Authenticity

Real simulation everywhere: the summon is the boss's own call (cooldown moved to 0.9 s before);
the 02 drops come from a real kill (seed 3402, found by searching from 3401, logged, never forced);
equip, collect, Merge All, `begin_prestige` and the card tap go through the game's own calls and buttons.
Every worn or merged item is in some enemy's loot table (`tests/change_34_probe`). That check corrected
one draft: the tier-1 Grim Reaper outfit (used by the Change 33 trailer) is not a drop, so 04 uses the
dropped tier 3. No fake UI, no overlays, no added text, no AI imagery.

Each capture's `.log` proves the event: `SUMMON ... helpers=2`, `PLAYER_SKILL lightning`,
`GEAR collect iron_sword ok=true`, `GEAR respawn after 60.05s alive=true`,
`MERGE_ALL 'Merge 100 spare copies' ... ^0 -> ^100`, `farm drops near=[...]`,
`PRESTIGE card selected challenge_c3`. `finalize_screenshots.py` refuses a set whose logs lack any of these.

## Files and validation

- **Delivered (local only, `store_assets/` is ignored):** `store_assets/screenshots/{Phone,Tablet_7,Tablet_10,Desktop}/<Device>_01..06.png`.
  Phone 1080x1920, Tablet_7 1440x2560, Tablet_10 1800x3200, Desktop 1620x2880. Every file is 24-bit RGB PNG
  without alpha, exactly 9:16, 128-335 KB, and byte-identical to its raw master in `store_assets/raw/screenshots/`.
- **Provenance:** `store_assets/screenshots/screenshots_manifest.json` (copy in `docs/Change_34_Evidence/`).
- **Review sheets:** `store_assets/review/change_34/` (24-image sheet by scene and device, 360 px store-card
  sheet per class, six before/after pairs, overview). Reduced copies are in `docs/Change_34_Evidence/`.
- **`finalize_screenshots.py`:** PASS. Checks: 6 per folder in sequence; size, 9:16 and RGB; no flat frame
  or four-sided border band; postconditions; the same moment across classes (largest mean difference
  3.3/255); clearly different scenes (smallest difference between two scenes 29.1/255); alt text at most
  140 characters.
- **Determinism:** the six Phone shots were re-rendered. 02-06 are byte-identical; 01 differs only in the
  stacking of floating damage numbers above the boss (the presentation's frame timing; the same scene).
- **Live Play rules** (help page 9866151, read 2026-10-28) are met:
  - JPEG or 24-bit PNG without alpha; sides 320-3840 px, and 1,080-7,680 px for large screens.
  - 9:16 portrait; 4-8 images for tablets and Chromebook.
  - Games: three or more portrait screenshots at 1080x1920 or larger for recommendation formats.
- **Unchanged-asset proof:** before the work, 297 files were hashed: branding, icons, feature graphic,
  trailer and video, `assets/sounds`, `marketing/brand`, `marketing/trailer` and the evidence of Changes 27-33.
  All are identical afterwards except `marketing/manifest.json`, whose Change 27 screenshot jobs were
  removed on purpose so its pipeline can no longer overwrite this set.
- **Export:** `python tools/export_manifest.py --check` PASS (232 files, unchanged). `marketing/*` stays in the
  Release `exclude_filter`.
- **Toolkit:** `marketing.py status` reports 1.0.2 installed, identical to the lock and the toolkit source.
  No toolkit file changed.
- **Suite:** `python tools/run_probes.py`: **37/37 pass** on one complete final run (validator 1,574 checks, export manifest, 35 Godot scenes including the new `change_34_probe` with 138 checks), no script errors, no timeouts.

## Code and documentation

- `marketing/game_scenarios.gd`:
  - New scenarios `shot_gear`, `shot_merge`, `shot_explore` and `shot_prestige`.
  - `_late_profile` accepts `wear`; `trailer_farm` accepts `auto_collect` and `skill_at` (defaults unchanged).
  - The development-only `explore` scenario accepts `travel_stage` and `scroll`.
- `marketing/screenshots/`: manifest generator, `manifest.json`, `manifest_draft.json`, finalizer and README.
- `marketing/make_manifest.py` and `manifest.json`: no screenshot jobs; the Change 27 table is kept as a record.
- `marketing/finalize_store_assets.py`: re-checks the Change 34 screenshots without copying them, and no
  longer overwrites `docs/Change_27_Evidence/screenshots_contact_sheet.png`.
- `tests/change_34_probe` (registered in `tools/run_probes.py`): 138 static checks.
- Docs updated: `marketing/README.md`, `docs/LootFarmer_Asset_Registry.md` and `docs/LootFarmer_Test_Suite.md`.
- The Playbook is not edited; screenshot lessons wait for the developer's review.

## Alt-text drafts (listing metadata, at most 140 characters, never drawn on images)

1. A Sunflower boss summons two Sprout helpers in the rain while the hero strikes it with lightning.
2. The hero wears the Teal Dinosaur outfit and Iron Sword it dropped, fighting the dinosaur again.
3. Merging 100 spare Red Scarf Outfit copies raises it to level 100 and unlocks a Guard bonus.
4. The hero in a Grim Reaper outfit farms a pack of helmeted enemies among autumn trees, with loot dropped.
5. Exploring a snowy map: the fog lifts along the path and a new camp is spotted.
6. Prestige reward choice: three permanent cards, with Hard Hit +75% critical damage selected.

## Limits and open items

- **02** is a single frame, so it cannot show the whole before-to-after action. The matching boss and
  player outfit and sword carry the link; no collage or caption was added.
- **04** has no skill VFX in frame (every effect at this zoom hides the fight). Its leaves are authored but
  subtle on the orange ground; none were painted in.
- **03**'s Winter is the strip above the panel plus the gear row (Winter fills 05).
- **01** and **06** share the late-game profile, so their gear rows list the same first tiles.
- **Not verified or approved:**
  - Chromebook listing eligibility is unverified; no desktop build is claimed.
  - REL-02 (licence records for Pixel Plains and `assets/sounds`) is still open.
  - The developer's review of the 24 images is pending. Nothing is uploaded or pushed.
