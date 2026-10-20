# LootFarmer 0.5.0 — clean UI and progression

Apply this patch directly over the complete 0.4.0 project. Paths are project-relative at the ZIP root. Reopen Godot and let assets reimport. Keep a backup of the previous project/save before updating.

## Export and signing

The patch deliberately does NOT replace export_presets.cfg: your local release key path, alias, password, package identity and export destinations remain yours. Project version is now 0.5.0. Before uploading to Play, set the Android preset version code above the last uploaded code (8 if the last was 7). Leave version name blank to inherit 0.5.0, or update a manually set version name. Export a release-signed AAB with Export With Debug off. No signing key, password or AAB is included.

## Interface

Gameplay is above the compact status area: red HP and blue XP/LEVEL bars, currency row, then gear and supplies side by side. Pause, World, Stats and Settings remain accessible. Camera drag, pinch, slider and bottom-center joystick behavior are preserved.

All active UI surfaces now use Kenney Fantasy UI Borders; smooth DejaVu Sans replaces the former font. The Kenney CC0 license and font license are included. Legacy GUIPackCartoon and derived resources/game/art directories have .gdignore markers; there are no active references to either. They can be deleted after applying the patch. Original synthesized button/prestige tones replace their old sound dependencies.

Slots use muted brown, gray, blue and violet tints for the four existing/new tiers. No rarity system was introduced. Item cards show icon/merge level at left, name/main stats/extras at right, and Equip/Use, Merge, Sell actions below. More options contains bulk merge/sell, reroll and automation. Evolution appears when the merge requirement is reached. No comparison interface was added.

Pixel Plains supplies the currency and item icons. Healing uses its heart symbol; coin tonic uses its gold-coin symbol because the supplied Pixel Plains sheets do not contain a potion-bottle replacement. UI sizes are bounded independently of source resolution. Recent finds appear briefly at top left; full history is in Settings. Coins remain excluded from notifications.

## Player progression

XP comes from normal enemy and boss kills. Cats grant no XP or rewards. LEVEL 1–1000. Each level adds 5 base HP and 0.5 base damage; starting values remain 100 HP and 5 damage. Next-level XP is ceil(12 * current_level^1.35). Overflow carries across levels; XP stops at the cap. Level-up heals only the newly gained max-HP amount, never revives a dead player. Prestige resets level and XP, retaining the existing permanent upgrades/cards/reveals.

Every owned unique unequipped weapon contributes 30% of its current fixed and extra stats. Merge increases the fixed stats used by this contribution. Duplicate quantities do not multiply it. Equipped weapon contributes 100%, never 130%. Stored outfits do not contribute. Selling the last stored copy removes its bonus. Existing stat caps and prestige multipliers still apply.

## Enemy layout and tuning

World movement width is 1080 units. Regular tiers have three columns centered at X 180 / 540 / 900: Outfit, Weapon, Both. Each column contains three enemies. The boss is a separate single encounter. Camps select respawn points without teleporting.

| Tier | Outfit-only HP / damage | Weapon-only HP / damage | Both HP / damage | XP single / both |
|---|---|---|---|---|
| Sprout | 42 / 1.95 | 21 / 4.5 | 42 / 4.5 | 6 / 9 |
| Robot | 330 / 9.1 | 165 / 21 | 330 / 21 | 30 / 45 |
| Dinosaur | 1425 / 27.3 | 712.5 / 63 | 1425 / 63 | 110 / 165 |
| Boss | — | — | 6500 / 95 | 600 |

Tier upgrades/reveals are shared across its three variants. Enemy panels select the tapped variant, with tabs to inspect the others. Dinosaur alerts are restricted to its own column. Leashes are measured from each spawn, preventing enemies from being tethered to the wrong column.

Base gear chances remain 10% / 9% / 8% / 30%; the chance upgrade remains +2 percentage points. Outfit-only enemies drop only their outfit; weapon-only enemies only their weapon; combined enemies choose one of their two items equally after the gear roll. Existing independent currency/consumable drops remain. The boss now drops its actually worn Onyx Scythe or Reaper Outfit (40 damage +0.25 per merge; outfit 75 HP +0.3 per merge and 8 defense +0.03 per merge), replacing unrelated dinosaur/iron rewards. Its displayed scythe remains the supplied Onyx animation.

These are an initial progression curve, not a completed natural-play balance certification. A full run remains the acceptance task on the phone; level 1000 is a cap, not a requirement to beat this map.

## Combat presentation

All player/enemy variants share actor.tscn. Existing 24x24 character sheets: idle row 0 / 8 frames, walk row 1 / 4 frames, death row 2 / 9 frames at 12 FPS, effort pose row 3 / first cell. Existing effort pose and a short visual-child hop/lunge present unarmed attacks, peaking at authoritative contact. Weapon sprites are hidden while unarmed. Armed strikes retain real eight-frame tool/hands sheets, with first slash frame 2 aligned to simulation contact and a matching effort pose. Outfit/body sprites remain the supplied composed sheets; no unsupported modular expression layer is fabricated.

Hit flash, bounded recoil and floating numbers respond to contact; critical hits have a distinct gold number and exclamation. Healing uses green numbers. Reused feedback tweens are canceled before restart. Logical death cancels attacks/movement immediately; the nine death frames finish and fade before hiding. Player/enemy health bars are red. Cats dismissed by boss resolution finish their death presentation. The boss's prestige panel waits one second so death is not covered immediately. All combat/death timing follows paused simulation time.

## Save migration

Schema 1 migrates to schema 2. Inventory, merge levels, resources, upgrades, cards, unlocked camps and prestige are retained. The new level starts at 1 with zero XP. Actors are rebuilt for the new map and the player returns to the starting area with full HP. Existing pickup records remain. Schema 2 preserves its new level/XP and enemy variants through save/reopen. Hard reset removes all progression as before.

## Verification

Godot 4.5.1 compatibility testing; project retains its declared Godot 4.7 baseline.

- Progression/layout probe: 88 checks passed.
- Gameplay regression: 52 passed.
- UI integration: 24 passed.
- Camera gesture integration: 17 passed.
- Inspector/camp integration: 32 passed.
- Save/reset/bootstrap probe: PASS.
- 213 assertions total, plus bootstrap. Import and startup parse checks passed.
- Layout checks cover all ten items and three portrait viewport sizes, plus all main panels.

Logs are in docs/Progression_UI_Evidence. No rendered GPU screenshot or physical Android review was possible in this environment. On the phone, check text/slot contrast, attack timing, wide-map panning, and progression pacing. No signed Android export or Play upload was performed.
