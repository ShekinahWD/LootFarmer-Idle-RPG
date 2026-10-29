# LootFarmer Change 41 — Playtest corrections: Prestige collections, Focus Farming defence, joystick position, onboarding, drops, Discord

Date: 2026-10-29. Brief: [LootFarmer_Playtest_Corrections_Prestige_Focus_Joystick_Tutorial_Drops_Discord.md](LootFarmer_Playtest_Corrections_Prestige_Focus_Joystick_Tutorial_Drops_Discord.md). Previous change: 9175683 (Change 40).

Save schema 8 and save file version 3 are unchanged. No new profile field. One new setting (`joystick_position`). No drop rate, rarity, seed, pickup rule, combat number, economy value or tutorial progression changed. Localization Batch 03 was not started; the nine draft catalogs are untouched, hidden and unpackaged.

## 1. Prestige collection requirement

**Cause.** A Collection contract hands in 20 / 30 / 40 copies of each outfit and keeps one (the game-wide "one copy kept" rule, as for merges). `campaign.submit` checked `quantity >= count + 1`, but the Prestige card, the HUD tracker, the follower ("All found! Hand them in"), the follow-step notices and the outfit descriptions all counted to 20. A player with exactly 20 of each was told to hand them in and then refused ("Collect the required copies online and keep one of each.").

**Decision.** The retained copy is intentional (wearing or equipping the outfit never leaves the player without it), so the requirement became visible instead of being dropped: the contracts ask for **21 / 31 / 41** from the start and Submit still hands in 20 / 30 / 40.

**Fix.** One count per outfit, `campaign.collection_counts(id)`, reaches `collection_required(n)` exactly when Submit accepts: copies picked up online this run since discovery (capped at the hand-in amount; spent copies lower it) plus the one kept copy when the inventory holds one more than those (any origin: older, equipped or offline). The panel, tracker, follower, follow focus, step notices, readiness and `submit` all read it (`collection_complete`). Descriptions now say "Pick up 21 each … Submit hands in 20 of each and you keep one"; the panel line reads "Progress: …" (the kept copy need not be found this run).

**Behaviour, same script on both commits** ([before_after_behaviour.json](Change_41_Evidence/before_after_behaviour.json)): before, 20 of each showed "All found! Hand them in" and "20/20" while Submit refused; after, "Collect Blue Cap Outfit …: 20/21". With 21 of each both accept and leave one copy each.

## 2. Focus Farming defends the hero

**Cause.** `sim._combat_target` (auto-attack) and `campaign.skill_activation_target` (skills) dropped every enemy not of the focused type. An aggressive stranger picked up on the way to the spot, or at the spot while the focused enemies respawned, could hit the hero indefinitely: no target, so the hero walked to or stood at the spot. Same script on both commits, 10 s at the spot with the focused enemies respawning: before, the attacker stayed at 57/57 HP; after, it was down to 12/57 (the level-1 hero fights back).

**Fix (shared decision path).** `sim.auto_target(radius)` is used by both callers:

1. the nearest eligible enemy of the focused type and loadout;
2. only when none is eligible, the nearest enemy **actively attacking the player** (`sim.threatens_player`: alive, aggro, not leashing home; aggro only ever targets the player);
3. nothing, so the existing step walks back to or waits at the farming spot.

A defensive lock is kept only while no focused enemy is eligible (`_keeps_lock`), so the focus regains priority as soon as one is. Calm or passive strangers, leashing enemies and attackers beyond acquisition range are never chosen. Ties keep roster order (deterministic). Unchanged: manual targeting (overrides and ends Focus, as before), movement cancelling Focus, the 0.5 s idle, acquisition and reach ranges, travel rules, behaviour without a Focus, and saves (nothing new is saved).

## 3. Joystick position

Settings → **Joystick position: Left / Center / Right** (new row under Inventory slot size, the current choice highlighted). `SettingsState.joystick_position` (0/1/2, default 1 = Center, the old place) is saved with the settings, survives Hard Reset like every setting, and older saves or malformed values read as Center. The stick moves at once (`joystick.place`): it is anchored to the bottom-left, bottom-centre or bottom-right of the map with editable `edge_margin` / `bottom_margin` (16 px) inside the safe-area layout; its size, height, radius and feel never change. A thumb on the stick is released when it moves (no stuck direction). The followed trackers, toasts and tutorial cards already stack above the stick's top edge, so nothing else moved. The gesture surface sits under the stick: touches on the stick never reach the map, and with the stick at the side the old centre spot is ordinary map (pan, pinch, drag-to-target).

## 4. Onboarding

- **Mode chooser:** three large cards (≥ 112 px, the whole card is the touch target), each with its own art (pointer, card deck, sword), the mode's name in its own colour and one line on what it gives: Guided "Step-by-step lessons with pointers. Menus open as you learn them."; Basic "A few short cards on controls and goals. Every menu is open."; None "No lessons or tips. Every menu is open from the start." A subline says "Every mode plays the same game. Only the amount of help changes." Guided, the beginner path, uses the primary style; None is never styled as a recommendation. Mode semantics are unchanged. The chooser appears only at its settled size.
- **Guided movement lesson:** the real joystick is framed (the guide's existing frame) and a ghost knob plays the drag on it toward the path arrow, both recomputed from the stick's live rectangle every frame, so they follow Left / Center / Right and a change made mid-lesson. They take no input, step aside while the thumb is on the stick, and end with the lesson (walking the path, its existing real completion). The card says "Drag the glowing joystick toward the arrow." No permanent text was added.
- **Basic (and Help, the same deck):** the first card now says where the joystick is and what releasing it does: "Drag the joystick at the bottom of the map to walk. Let go and your hero fights nearby enemies. Tap loot to pick it up." The Change 35 targeting card is unchanged. Basic and None still never point.

## 5. Equipment drops

**Audit.** Drops appeared instantly at full size under the defeated enemy's death animation (actors draw above pickups), 14 px whatever the item, with the pack sparkle on a shared 4 s clock (1.2 s visible) that made many drops flash in unison; equipment looked like supplies.

**Change (presentation only, `resources/game/pickup_style.tres`).** A drop made moments ago (ground time ≥ 299.5 of 300 s) hops out over 0.34 s (rises 11 px, grows from 35% with a small overshoot), drawn above the actors only during the hop, then rests exactly on its simulation position beneath them. Supplies hop lower. Weapons and outfits render at 16 px (supplies 14) on a thin ring in their tier colour (the inventory slot colour, lightened, over a dark edge). The sparkle plays once on landing (larger for equipment), then periodically at a per-drop phase. Drops already on the ground after a load or a map change are simply there. Every drop is collectible from its first frame (a tap or Auto-Collect during the hop works); the view never changes a pickup or draws a random number. Evidence: [drops_before_after_540x960.png](Change_41_Evidence/drops_before_after_540x960.png) (100, 330 and 1,500 ms after the drop) and the `06`–`08` captures per shape.

## 6. Discord

One **Discord** button in Settings, in the first button row beside Stats, Loot history and Save now. No section or heading. The invite `https://discord.gg/zbr9RH6QWa` lives only in `resources/game/external_links.tres` (`scripts/game/external_links.gd`, Playbook 52). It opens with `OS.shell_open` (Windows: the default browser; Android: a view intent, the Discord app when installed, else the browser). A second press within 1.5 s opens nothing. A failed launch shows "The link couldn't be opened. Check your connection and try again." in the panel's notice line and changes nothing else. "Discord" is a brand kept as is in every catalog (allowlisted).

## Localization

- English catalog 1,941 → **1,951 keys**. New: `JOYSTICK_POSITION`, `JOYSTICK_LEFT/CENTER/RIGHT`, `DISCORD`, `LINK_OPEN_FAILED`, `GUIDE_CHOOSE_DETAIL`, `GUIDE_MODE_GUIDED/BASIC/NONE_DETAIL`. Changed: `GUIDE_MODE_GUIDED/BASIC/NONE` (now the names only), `GUIDE_MOVE_DETAIL`, `GUIDE_OVERVIEW_DETAIL`, `CONTRACT_NEEDS`, `CONTENT_COLLECTION_O1/O2/O3_DESCRIPTION`, `PROGRESS_COLLECTION`. Source: `tools/change41_strings.json`.
- All 20 keys written for es-419, es-ES, pt-BR, fr-FR, de-DE, it-IT, nl-NL, pl-PL, ru-RU and uk-UA (`tools/change41_translations.json`, applied with `tools/po_set.py --translations=`), following each catalog's glossary and typography (NBSP and French NNBSP, pl/ru/uk number agreement, uk "мапа"). Not native-speaker reviewed.
- `validate_localization`: 10 catalogs × 1,951 keys, 0 problems. `localization_sweep`: 2,114 screen checks, 0 findings. Enabled set, Automatic, dropdown and packaging unchanged; the nine drafts stay hidden and unpackaged.

## Validation

- `change_41_probe` (new, 193 checks, registered): every case listed in the brief for the six items (Prestige exact, one short, one over, older copy, equipped copy, merged copy, save/reload, all three contracts; Focus priority, respawn fallback, calm and leashing strangers, range, multiple attackers and ties, priority restoration, manual override, no-Focus behaviour, a stepped travel fight; joystick placement at all positions, trackers, persistence, Hard Reset, malformed saves, Settings row, touch on the stick versus the map, release on move; chooser at three window shapes; the lesson frame and demo at three positions and after a mid-lesson change; drops; Discord routing, repeat guard, failure, no Community heading; German redraw and every enabled catalog).
- Older probes updated to the corrected rule, coverage kept: `change_11_probe`, `change_12_probe`, `change_16_probe` (collection fixtures now own the kept copy and expect `/21`).
- Export: allowlist regenerated in a clean worktree (254 files, +4: the two resources and their scripts; chooser art 273 registered). `--export-pack` for Android Release, Android itch.io APK and Windows itch.io: `verify_export.py` PASS for each (254/254, no draft catalogs).
- Full suite, once at the end in the working tree: **42/45**, no script errors or timeouts. The 3 failures (`export_manifest`, `change_27_probe`, `change_26_probe`) are caused by the developer's uncommitted `project.godot` / `export_presets.cfg` edits (version 26 vs 27, icon uid), as in Changes 39 and 40; all three pass in a clean worktree with the Change 41 files. See [Test Suite](LootFarmer_Test_Suite.md).
- Evidence (desktop renders at 432x960, 540x960, 768x1024; German, Russian and French at 432x960): [docs/Change_41_Evidence/](Change_41_Evidence/), contact sheets `contact_sheet_*.png`.

## Still needs a device

Not tested on a phone: thumb comfort at each joystick position (especially Left/Right on small phones and with a case), notch and gesture-bar devices, the Discord link on Android (app installed and not) and Windows, the drop arrival and ring at real phone density and frame rate, and the chooser's readability at arm's length.
