# LootFarmer — Test Suite (current, 2026-11-13, Change 78)

## Change 78: enemy skill priority, merge stat preview, text filtering, boss outfit attributes, boss automation prices (13 November 2026)

- `change_78_probe` (new, in the suite): a respawned enemy starts with a fresh skill turn (no leftover cooldown, telegraph or rotation); its first eligible skill comes before its first normal attack after every respawn, out of reach it waits without spending the turn, Heal above its threshold is passed over, cooldowns hold (20 s normal, 10 s boss), a boss telegraph holds back normal attacks. `sim.merge_preview` equals the real stat change of one merge for weapons and outfits (stock bonus at the cap, one copy), empty at the cap; the item panel shows the green gain beside each stat and no Next merge line for gear (skills keep theirs), inside the sheet on the comparison card. Every label draws linear, theme pixel frames stay nearest through CanvasTexture, the world supply name uses the MSDF theme font. Boss outfit drops get two boss attributes (first copy only, ranges, no repeated stat, merge, reroll, equipped stats, disk save/reload); the one-time `boss_outfit_extras` migration; boss Auto-Collect and Auto-Merge at least 70% cheaper on every boss, normal types and other automation unchanged, bought levels kept.
- `change_52_probe` updated: a boss's outfit drop is now enhanced too.

## Change 77: Camp Supplies replaces Camp Survey (13 November 2026)

- `change_77_probe` (new, in the suite): regional_c3 keeps its id, path, string keys and Regional set membership with effect camp_supplies; a released schema 8 save owning the card gets the effect and no discount; one free random supply per owned camp per Prestige run (from the map's supply pool), never repeated by staying, leaving and returning, teleporting, respawning or reloading; different camps and maps reward independently; nothing without the card, at an unowned camp, while defeated, during a Prestige choice or on a map beyond the run's reach; a full inventory leaves the camp unmarked with one waiting notice and gives the supply once there is room; disk save/reload; Prestige clears the record while camps and cards stay; Hard Reset; older and damaged saves; the card and toast in the UI.
- `change_6_probe` updated: the card no longer discounts camps.
- `change_77_capture` (windowed evidence, not in the suite): docs/Change_77_Evidence.

## Change 76: permanent camps, boss weapon notice, Auto Buy Supplies (13 November 2026)

- `change_76_probe` (new, in the suite, 145 checks): Prestige keeps owned camps and each map's respawn choice while map access, items and run kills reset; the kept camps stay the live camp list (a camp bought after Prestige joins them); travel works once a map is reached again; disk save/reload; Hard Reset clears them; the one-time `camps_permanent` migration restores camps lost to earlier Prestiges from Map Mastery and never repeats. The boss weapon notice (ITEM_ENHANCED) through the real toast queue: >= 8 s alone and with other notices queued around it, all notices still shown in order, held and resumed with its remaining time when a panel opens. Auto Buy Supplies: 100 / 160 / 250 Gem unlocks, duplicate and locked-slot refusal, 0 / 1 / 2 / 3 / 7 owned, no repeat purchases, insufficient Coins and no free supply slot (waits, stays enabled, buys once possible), three supplies in one simulation step, paused and Prestige-choice locks, Prestige / reload / Hard Reset, older and damaged saves. Supplies tab UI at 720x1280, 720x1600, 720x1080 and 960x1280.
- `change_76_capture` (windowed evidence, not in the suite): docs/Change_76_Evidence.

## Change 75: Next Stage on two lines, compact zoom slider (13 November 2026)

- `change_74_probe` extended to 166 checks: the Next Stage chip as caption over count at the minimap's width in all 20 languages (World clear too, a text without separator stays one line, the count capitalised), the open zoom slider one 220x48 row hiding only the Mastery chip, a round grabber, zoom still works and closes.

## Change 74: HUD enlargement, Prestige touch scrolling, objective names (13 November 2026)

- **Registered** `change_74_probe` (138 checks, about 30 s): Prestige scrolling with Android-style touch (ScreenTouch/ScreenDrag plus the emulated mouse events, through the viewport) while the game keeps changing state: no structural refresh of an open Prestige panel, a 300 px drag starting over an opportunity card, a Follow button or an owned card scrolls 300 px and flings on, a structural refresh waits for the gesture and keeps the offset, a tap still follows, owned cards still grow to their text; sizes (minimap 220, Achievements 162x81, Upgrades and Auto Farm 76x81, icons 37, enemy name 24 px: each at least 30% over Change 72); Map Explored under the minimap; no fight form (a blow and a locked target change nothing; the three short strings retired); pill names (outfit, enemy, boss, Mastery target; follows progress; de_DE); no overlaps at 720x1280, 720x1600, 720x1440 and 960x1280 with every joystick position; toast lanes (bottom free side on phones, top lane at 960, over the joystick, never over the HUD, the banner or the fight); the longest enemy name of 20 languages whole at 24 px; map buttons with follow icons (World Travel two-column grid, Teleport); toast reading time (ITEM_ENHANCED 4.4 s); long pill titles wrap and the pill grows in English, German and Russian.
- **Updated:** `change_72_probe` (fight form replaced by "a fight changes nothing", toast lanes, Explored under the minimap), `change_71_probe`, `change_16_probe`, `change_14_probe`, `change_13_probe`, `change_12_probe`. `tests/hud_audit_capture` gained 07 World travel and 08 Prestige after a touch drag.

## Change 72: HUD declutter, edge rails (13 November 2026)

- **Registered** `change_72_probe` (112 checks, about 20 s; Change 72, HUD declutter): the edge-rail HUD at 720x1280, 720x1600, 720x1440 and 960x1280 with every joystick position (enemy controls in one row, three one-line objective pills under them, the 168 minimap carrying Map Explored, the zoom button, Mastery then Next Stage, both rails in the upper half and clear of the joystick, touch sizes); the fight form (a blow or a locked target; 3 s hold frozen by a pause; pills keep place and height and show icon and progress; chips read the short strings and return; German grows the chip leftward at the full font); pill progress per kind, the green Claim and the tooltip sentence; `campaign.follow_progress`; the zoom button's slider (open, move, 4 s close, second tap); the recent-finds feed leaving after 8 s with the Gem counter hidden; a toast in the lane between the rails and under a banner, never in the lower map; both chips tappable; the three short strings in the translation handoff. Updated for the approved layout: `change_8`, `change_11` (minimap 168, markers at least 12 px), `change_12`, `change_13`, `change_14`, `change_16`, `change_69`, `change_71` probes and `camera_probe` (the slider is opened from its button first).

## Change 71: implementation audit and polish (12 November 2026)

- **Registered** `change_71_probe` (237 checks, about 60 s): every Coin upgrade on every map and level steps at most x1.8 (the Enemy XP Winter II sample 10, 14, 19, 34, 60, 105, 184, 325, 572), one price for card, purchase and deduction, kept by Prestige; the main inventory's category and sort reorder the dock through `gear_view` only (taps, holds, browse and the guide reach the shown item; owned slots never move), persist through close, disk reload, older settings, Prestige, and Hard Reset returns All / Default; the Supplies shop's atomic bulk purchase (exact Coins and copies or no change; invalid, unaffordable and full requests refused; no Supply Mastery from buying), the saved shared quantity, the shop rows and Custom bounds; one Follow / Unfollow size and colour in Mastery, Missions and Prestige; no "Next:" line on the compact tracker; the HUD stack order and three trackers clear of the left controls and each other at 720x1280, 720x1600, 960x1280 and 720x1080 with every joystick position in English and German, toasts clear of the HUD columns; boss respawn to 15 s for every boss and boss item rolls 25/35/50/100 Gems; daily missions through Prestige and the next calendar day (clock seam); bulk evolution; the Prestige celebration after the committed Prestige, bounded, restartable and stopped by Hard Reset.
- **Not in the suite:** `tests/change_71_capture.tscn` (windowed before/after captures into `tests/tmp/change_71_capture/`, see its header).

## Player-profile playtesting, Phase 1 (12 November 2026)

How-to: [LootFarmer_Player_Profile_Playtesting.md](LootFarmer_Player_Profile_Playtesting.md).

- **Registered** `player_profile_probe` (45 checks, about 10 s): the clock seam is off by default and production calls read the system clock; with the seam a simulated day boundary refreshes the daily missions; a simulated three-hour absence is settled once and claimed exactly once; boss-respawn settlement and the Prestige transaction id follow the seam; a 240-second natural Active playthrough gives the same event-log digest and state digest twice from fresh profiles and a different one for another seed; a save snapshot survives a JSON round trip and restore. Its clock sections seed labelled fixture values and are not playthrough evidence.
- **Not in the suite (non-gating, run deliberately, one Godot process at a time):** the playthrough audits, `python tools/player_profile_run.py run|determinism|report --batch <id> …` (scene `tests/playtest/player_profile_run.tscn`). Output goes to `tests/tmp/player_profiles/<batch>/` (git-ignored, with a `.gdignore`).
- **Production change covered:** `LootSimulation.clock_override` / `now_unix()` / `today()` (default: the system clock). No save field, schema, rule or balance value changed.
- **Full run in the working tree: 45/62 passed.** The new probe passes. The 17 failing entries (`export_manifest`, `change_57`, `change_56`, `change_55`, `change_54`, `change_52`, `change_51`, `change_41`, `localization_batch01`, `localization_progression`, `change_36`, `change_27`, `change_24`, `change_20`, `change_17`, `change_13`, `change_7`) fail with the same failure counts when the three tracked files this batch touched are restored to commit `77b532f`, so they predate it and were left alone (Playbook 60: classify before changing anything).

## Change 69 — quick Auto Farm, walking countdown, ON/OFF toggles (11 November 2026)

- **Registered** `change_69_probe` (73 checks): the contextual stack order, column, touch size and single button; Locked → explanation + Player Upgrades without a charge, purchase, OFF → ON → OFF, the 0.4 s settle guard; group A ON / group B OFF while walking, switching, the enemy panel Farm reading and stopping the same state, another spot of the same type; the countdown at 1 s / 4.85 s, release + walk back, two 3 s walks, one 5 s walk stopping once, jitter, 3× game speed (15 simulated = 5 real seconds), pause / held / background resets, auto-navigation, held stick while dead + respawn, reload mid-countdown, explicit stop and switch, manual targeting; the countdown label above the joystick, under a toast, hidden by a panel, the stop toast; a source audit that every ON/OFF button in `game_ui.gd` / `help_viewer.gd` goes through `_toggle_style`, rendered Settings mutes, Missions Automatic Claiming (incl. paused = still ON), Help Auto-Advance; the Guided pointer on the quick button and Basic without one. `--realtime` adds a wall-clock run (held stick at 3×: 5.00 s).
- **Updated expectations:** `gameplay_probe` and `change_65_probe` (a short walk keeps focus; 5 s stops it), `change_14_probe` (panel line `FOCUS_HINT_PANEL_WALK`; closed panel → pointer on the quick button).
- **Not in the suite:** `tests/change_69_capture.tscn` (extends the Change 65 capture; windowed at 432×960 / 540×960, `--out=<dir>`): stack Locked / OFF / ON, group B OFF with the countdown, countdown + toast, release, after 5 s, enemy Farm ON / OFF, Settings mutes, Missions auto OFF / ON, Guided pointer, Advanced Farming card, Godot pseudolocalization (+40%). Its audit reports world-actor nodes inside the map's SubViewport (not UI) and, under pseudolocalization, the existing dock/HUD chips widening the layout; no overlap, small-target or truncation report on the new controls.

## Change 66 — Enemy achievements, Gem Chance price, Guided Map Mastery, Focused Farming copy (11 November 2026)

- **Registered** `change_66_probe` (77 checks): kill achievements at 0 / intermediate / full progress for a normal type and a boss (damage unchanged and type-specific, zero achievement Gem Chance, 3,000 real reward rolls at the 5% base, other sources intact, the Achievements tab text), save/load and Prestige of an earned profile (no refund or drift); Gem Chance 10 → 40 → 58, refusals without spending, an owned level 1 kept, the Gems tab button; the Guided `map_mastery` lesson (position, chip arrow, the five goals, Close arrow, World → Map Mastery → Details route, early close, reload, other panels, version-61 migration at / past / finished, the old hint record, Prestige, Hard Reset, 100% explored with no hint and the Explore goal still counting, Basic/None); the Focused Farming copy (Player Upgrades locked/owned, Help cards, 25 Gems) and a death → respawn → walk-back run.
- **Not in the suite:** `tests/change_66_capture.tscn` (extends the Change 65 capture: same bounds / truncation / clipped-line audit; 0 problems at 432×960 and 540×960).
- **Updated:** change_63 (the optional hint checks become "never shown"; the banner-vs-chip checks use the Guided lesson), change_12 (level 1 price 10, no achievement Gem Chance: 20% / 60% fully stacked), change_25 (36 Guided steps), `tools/validate_campaign_source.py`.

## Change 65 — Global Focused Farming, tutorial cards, Guided first attack (11 November 2026)

- **Registered** `change_65_probe` (143 checks): the global 25-Gem Focus purchase and its locked/owned enemy panel, migration of 0 / 1 / 3 / hybrid legacy records (repeat load, Prestige keeps, Hard Reset clears), the 14-card registry (keys, word caps, categories, loops), all 14 demonstrations (animate, restart, stop when hidden, no game-state change), Help navigation / Auto-Advance / Viewed / reload, the three modes, and the Guided first manual attack (no unattended attack, real hit completes, dead target, movement, reload, death, escape, older saves, Basic/None ungated).
- **Not in the suite:** `tests/change_65_capture.tscn`, windowed (`--resolution 432x960` / `540x960`, `--out=<dir>`, `--only=`), with a bounds / truncation / clipped-line audit (0 problems at both sizes). Evidence: `docs/Change_65_Evidence/`.
- **Updated for the approved behaviour:** change_14 (the Focus purchase is in Player Upgrades), change_15 / change_16 / change_21 / change_25 / change_35 / change_63 / localization_sweep (the Basic opening and Help are the card viewer; the targeting lesson completes on the first real hit), change_8 / change_16 / change_25 / change_41 / gameplay (global `focus` fixtures). Pre-existing failures left as they were: change_41 (Winter II is all passive since Change 62, so its stranger fixture cannot be built), change_57 (2), localization_progression `prestige_cards8`, localization_batch01 (pending-key count), export_manifest (the developer's version-code bump).

## Change 58 — Progression update localization, Batch 01 (7 November 2026)

Command: `python tools/run_probes.py`. Details: [batch report](changeDocs/localization/Progression_Batch01_Report.md).

- **Registered** `localization_progression_probe` (extends `localization_sweep`; 492 checks by default: en + es_419/es_ES/pt_BR/fr_FR/de_DE × 432x960/540x960). It covers 14 screens that show the Change 50–55 keys: the World Map Detail hint, welcome-back offline hint, Upgrades > Offline, boss-enhanced weapon + reroll confirmation, boss bonus hint, evolution rule, legacy copy, evolution-ready toast, Prestige with 48 opportunities, Prestige confirmation and the eight-card choice. On top of the sweep's checks it verifies that each listed progression key is actually on screen in the current language, adds a new `word_split` check (a wrapping label narrower than one of its words), checks the plate and sheet stay inside the screen, and switches language live with the card choice and item panel open. Pre-existing language-independent patterns (Prestige card-chip ellipsis, 40-unit History feed buttons) are counted as `known`, not failed. Windowed: `--resolution 432x960 ... --shots=<dir>/ --shape=432`.
- **Updated** `localization_batch01_probe`: `translated_english(BATCH)` now covers all 2,027 keys (delivered pending keys are no longer excluded), plus an es_419/es_ES regional check on the new keys. `localization_sweep.translated_english/pending_keys` take the languages and exclude only keys not yet delivered to them.
- **`validate_localization`**: a pending key is exempt only for locales not in its `translated` list; a delivered key that goes missing fails.
- **Outside the suite:** `tools/integrate_translation_batch.py --check --baseline-rev=<rev>` (approved-entry integrity against a git revision).

**Final run in the working tree:** **56/56 passed**, no script errors or timeouts (57 entries incl. the 3 Python checks; the developer's uncommitted `project.godot` / `export_presets.cfg` edits no longer break `export_manifest`, `change_26_probe`, `change_27_probe`).


## Change 42 — Localization Batch 03 (29 October 2026)

Command: `python tools/run_probes.py`. **46 entries:** `validate_campaign_source`, `export_manifest`, `validate_localization` and 43 Godot scenes. Details: [Batch 03 report](LootFarmer_Localization_Batch_03_Report.md).

- **Registered** `localization_batch03_probe` (135 checks): availability before/after activation, Batch 04 drafts and `batch04` refused; routing and all 1,951 keys × 5 through Godot's PO loader; per-locale theme font (Thai/Devanagari chains, plain DejaVu elsewhere) and glyph coverage with system fallback off; Devanagari conjunct, pre-base matra and ligatures; Thai mark stacking, dictionary word breaks and no line starting with a following vowel/ๆ/mark; dropdown draws every native name; Automatic for tr/id/in/vi/th/hi and English for neighbours; formatting, durations, Turkish İ/ı, Hindi count lines; live switching with panels open; persistence and old saves.
- **`localization_sweep`:** defaults now pseudo + English + 15 languages × 3 shapes; new `missing_glyph` (Font.has_char on the control's own font) and `clipped_y` checks (world-space labels excluded); timeout 900 s.
- **Updated for 16 languages / 4 drafts:** `localization_batch01_probe`, `localization_batch02_probe`, `change_40_probe` (dropdown size from the enabled list), `change_35_probe`, `ui_probe`, `bootstrap_probe`. `validate_localization` compares `%%` by count and enforces the Hindi count rule; `validate_campaign_source` reads UTF-8.
- **Outside the suite:** `change_40_capture` now also renders Thai/Hindi dropdowns and Automatic on a Thai device; `verify_export.py` accepts and, with `include_text_server_data`, requires `icudt_godot.dat`.

**Final run in the working tree: 43/46**, no script errors or timeouts; the 3 failures (`export_manifest`, `change_27_probe`, `change_26_probe`) are the pre-existing ones from the developer's uncommitted `project.godot` / `export_presets.cfg` edits. In a clean worktree of `7ff484f` + the Change 42 files all three pass (10/10 with the localization probes). Export: signed AAB and the itch.io Android / Windows packs `verify_export.py` PASS, 264/264 files, en + 15 catalogs, both Noto fonts and the ICU data.

## Change 41 — Playtest corrections (29 October 2026)

Command: `python tools/run_probes.py`. **45 entries:** `validate_campaign_source`, `export_manifest`, `validate_localization` and 42 Godot scenes. Details: [Change 41 report](LootFarmer_Change_41_Report.md).

- **Registered** `change_41_probe` (193 checks):
  - Collection contracts: 21 / 31 / 41 required, 20 / 30 / 40 handed in; the reported exact case (20 of each reads 20/21 on the follower, card and tracker, Submit refuses and spends nothing); 21 of each completes and keeps one; one short, one over, an older copy as the kept one, the worn copy stays worn, a merged copy lowers the count, save/reload before and after Submit, all three contracts.
  - Focus Farming: focused enemy before a closer attacker; attacker when the focused enemies respawn (auto-attack and skills); calm and leashing strangers and attackers beyond acquisition ignored; nearest of several attackers and roster-order ties; the focus regains priority; manual target overrides; no-Focus behaviour unchanged; a stepped Winter II fight (aggro on the way, attacker defeated, calm stranger untouched, the hero walks on with Focus on).
  - Joystick: Left / Center / Right inside the map band at the same size and height, clear of the skill bar and dock, trackers above it; save/reload, Hard Reset keeps it, missing / malformed / out-of-range saved values; the Settings row (highlight, immediate move); a touch on the stick never reaches the map, moving it releases a held stick, the vacated centre is map again.
  - Chooser at 720x1280, 576x1280 and 1024x1366: three cards in order, settled and on screen, ≥ 112 px, name and detail inside, whole card is the target, Guided primary and None not; each card chooses its mode.
  - Guided movement lesson at all three positions: the stick framed, the ghost knob toward the path, input-transparent, following a mid-lesson move, hidden under the thumb, gone after the path is walked; Basic and None never point; the Basic card names the joystick's place.
  - Drops: gear vs supply, arrival above the actors then resting on the exact simulation spot, no pickup or RNG change, per-drop sparkle phase, collectible mid-arrival, older drops do not hop.
  - Discord: exact URL from one resource, one button beside Stats, no Community heading, reachable at 720x1280, repeat guard, failure message with Settings still open and no game-state change.
  - Localization: German redraw of the new row and button; every Change 41 key present in all 10 enabled catalogs.
- **Updated to the corrected rule, coverage kept:** `change_11_probe` (collection follower stages now own the kept copy, expect `/21`), `change_12_probe` (a collection step completes at 21), `change_16_probe` (Winter collection follower `0/21`; the next outfit after 21).
- **Outside the suite:** `change_41_capture` (windowed: `--shape`, `--lang`, `--drops-only`; `docs/Change_41_Evidence/`).

**Final run in the working tree (once, at the end): 42/45**, no script errors or timeouts. The 3 failures are `export_manifest` ("Android itch.io APK version/code 27 != project config/version 26"), `change_27_probe` (project version 27, Android Release code 27, project icon) and `change_26_probe` (core file `uid://drj4h6jnqymfy` ships). All three come from the developer's uncommitted `project.godot` / `export_presets.cfg` edits that predate this change (the same three as Changes 39 and 40); they were left untouched. In a clean worktree of the previous commit with the Change 41 files applied, `export_manifest`, `change_27_probe`, `change_26_probe` and `change_41_probe` all pass. Export packs of Android Release, Android itch.io APK and Windows itch.io from that worktree: `verify_export.py` PASS (254 / 254 files, no draft catalogs).

## Change 40 — Progressive localization activation and language dropdown (29 October 2026)

Command: `python tools/run_probes.py`. **44 entries:** `validate_campaign_source`, `export_manifest`, `validate_localization` and 41 Godot scenes. Details: [Change 40 report](LootFarmer_Change_40_Localization_Activation_Report.md).

- **Registered** `change_40_probe` (86 checks):
  - readiness and the Automatic device-locale matcher (no draft language is ever reached);
  - dropdown content and native names;
  - placement at 432x960, 540x960 and 768x1024 with Settings scrolled to the top and the bottom;
  - keyboard/controller, Escape, Android Back, outside tap, panel refreshes, resize, and closing Settings.
- **Rewritten for progressive activation** (they no longer assert "English only" or "19 disabled"):
  - `localization_batch01_probe` (87) and `localization_batch02_probe` (107): availability, the real dropdown path, Automatic per device locale, a stored draft choice shown as English and kept, restart without a test switch. Both reset the probe profile's stored language first.
  - `ui_probe`: the dropdown offers Automatic + 11.
  - `bootstrap_probe`: a draft locale is blocked; device locale pinned.
  - `change_35_probe`: the manifest ships exactly en + 10 catalogs; drafts are neither packaged nor selectable.
  - `change_16_probe`: message only.
- `localization_sweep`: the pseudo-locale check ignores native language names.
- `validate_localization` now checks every enabled catalog and the readiness table.
- `export_manifest`: family `language_catalogs` (10 catalogs, from `ENABLED_LANGUAGES`).
- `tools/verify_export.py` reads `.pck` files.
- **Outside the suite:** `change_40_capture` (windowed, `docs/Change_40_Evidence/`).

## Change 39 — Localization Batch 02 (29 October 2026)

Command: `python tools/run_probes.py`. **43 entries:** `validate_campaign_source`, `export_manifest`, the new `validate_localization` static check and 40 Godot scenes. Details: [Batch 02 report](LootFarmer_Localization_Batch_02_Report.md).

**Final run in the working tree: 40/43.** The 3 failures are `export_manifest`, `change_27_probe` and `change_26_probe`. All three come from uncommitted local edits to `project.godot` and `export_presets.cfg` that predate this change (version 27 → 26, launcher icon path → uid). Those edits are not part of the commit. On a clean worktree of the final commit the three pass (5/5 static + those probes).

- **Registered** `localization_batch02_probe` (101 checks). Covers:
  - the gate, and refusal outside probes;
  - it/nl/pl/ru/uk routing and device matches;
  - the Godot loader returning every key, and glyph coverage including Ukrainian і ї є ґ;
  - Russian and Ukrainian being written independently;
  - both batches registered together;
  - every placeholder string formatting, durations, count-neutral lines;
  - live switching, persistence, old settings.
- **Registered** `validate_localization` as a static suite step. It adds a pl/ru/uk count-agreement rule.
- **Extended** `localization_sweep`: defaults are now pseudo + English + Batch 01 + Batch 02 at three shapes, 2,114 screen checks, 0 findings, about 3 minutes.

## Change 38 — Localization Batch 01 (29 October 2026)

Command: `python tools/run_probes.py`. **41 entries (validator + export_manifest + 39 Godot scenes): 41/41 pass on the final run, no script errors, no timeouts.** Details: [Batch 01 report](LootFarmer_Localization_Batch_01_Report.md).

- **Registered** `localization_batch01_probe` (77 checks): production language gate, test-only override refused outside probes, es-419/es-ES/pt-BR/fr-FR/de-DE routing, Godot loader returns every key, glyph coverage, live switch from Settings and with panels open, save/reload persistence, old and foreign settings.
- **Registered** `localization_sweep` (1,231 screen checks): pseudo-locale plus English plus Batch 01 at 432x960, 540x960 and 768x1024. It looks for raw keys, English leaks, text that did not come from the catalog, clipped single-line text, horizontal overflow and small buttons. Windowed with `--shots=` it writes the evidence screenshots.
- **Outside the suite:** `python tools/validate_localization.py` (catalog structure, placeholder order, copy-through allowlist `tools/localization_allowlist.json`). Run it whenever a catalog or `en.po` changes.
- **Updated contracts:** `change_35_probe` checks selectable languages and `project.godot` registration instead of the file count in `localization/`, which fixes the Change 36 failure. `ui_probe` checks that the 19 languages are listed disabled. `change_16_probe` message only.
- `export_manifest`: new empty family `test_language_catalogs`, so the test catalogs never ship.

## Change 36 — supply mastery every 3 uses; final-boss audit (28 October 2026)

Command: `python tools/run_probes.py`. **39 entries (validator + export_manifest + 37 Godot scenes, new `change_36_probe`): 38/39 on the single final run, no script errors, no timeouts.**

- The one failure is `change_35_probe` "Only English is shipped and selectable". That assertion requires `localization/` to hold exactly one file. During this change the developer placed an untracked `localization/LootFarmer_Runtime_19_Languages_Partial_Drafts.zip` there. It is not part of this change and was left in place. `en.po` is still the only catalog and English the only selectable language.
- New: `change_36_probe` 180/0 (uses 0–6 for every supply type, cap, milestones, auto/blocked use, saves, Prestige, panel text, English copy).
- Updated fixtures: change_5/11/13/16/17 (uses = mastery × catalog divisor).
- Non-gating audit: `change_36_final_boss_audit` 280/0 and farm 14/0. Details: [Change 36 report](LootFarmer_Change_36_Report.md).

## Change 35 — review invitation and targeting lesson (28 October 2026)

Command: `python tools/run_probes.py`. **38 entries (validator + export_manifest + 36 Godot scenes): 38/38 pass on the final run of Change 35, no script errors, no timeouts.** Details: [Change 35 report](LootFarmer_Change_35_Report.md).

- **Registered** `change_35_probe` (144 checks): storefront matrix (Play/itch.io Android/itch.io desktop, untagged, ambiguous, unknown, the real `export_presets.cfg` presets, same Android package with two channels, no OS-based store logic); eligibility at 3,599/3,600 s; 20 never-interrupt cases (boss near/engaging, HP 49%, enemy and player wind-ups, death, Guided, Basic, chooser, panel, confirmation, Prestige confirmation and choice, offline claim, pause, background, banner, joystick, moving, map touch) and attack gaps; missing channel keeps pending; first-frame completeness and size at six screen sizes plus 40% longer text; world held while open; Back/Escape = Maybe Later; persistence across JSON and disk reload, Prestige and storefront change; exact URLs; launch failure and retry; Settings action; Hard Reset; old and malformed saves; the play-time clock; Basic card 2/6, Help, None; Guided real gesture vs pan, empty release, tap, joystick, auto-acquisition, refused selection, automatic kill; once only; Basic records no step; recovery (target dies, none in sight, reload, pause, panel, three screen sizes, old saves, finished tutorial); English catalog.
- **Updated stale contracts:** `change_25_probe` deck size 3–6 and 29 Guided steps; `change_16_probe` expects `target` after the path; index-based `STEPS.slice(0,N)` fixtures in `change_16_probe`, `change_6_probe` and the Change 20/21 captures now name their step.
- **export_manifest** now also mirrors the allowlist to `Android itch.io APK` and `Windows itch.io` and fails on any wrong or extra store tag.
- **Evidence (outside the suite):** `tests/change_35_capture.tscn` windowed at 540x960, 432x960, 768x1024 → `docs/Change_35_Evidence/`. Export-pack inspection of all four presets (see the report).

## Change 34 — Google Play screenshot redesign (28 October 2026)

Command: `python tools/run_probes.py`. **37 entries (validator + export_manifest + 35 Godot scenes): 37/37 pass on the single final run of Change 34, no script errors, no timeouts.** Details: [Change 34 report](LootFarmer_Change_34_Report.md).

- **Registered** `change_34_probe` (138 static checks): `marketing/screenshots/manifest.json` has 24 portrait jobs (Phone 1080x1920, Tablet_7 1440x2560, Tablet_10 1800x3200, Desktop 1620x2880, all 9:16), expected raw outputs, the same scene/options/frame on every class, no toolkit overlay, isolated capture profile without autosave; every scenario has an adapter branch and a pinned seed; every worn or merged item is a real enemy drop; four seasons and rain/leaves/snow maps shown; never the final boss; the Change 27 manifest no longer captures screenshots; the adapter refuses a probe profile.
- **Store media check (outside the suite, needs captures):** `python marketing/screenshots/finalize_screenshots.py --check` (Play format, 9:16, raster, log postconditions, cross-device consistency, scene distinctness, alt text). `python marketing/finalize_store_assets.py --check` now re-checks the Change 34 screenshots.

## Change 27 — Google Play assets and first Snowman weapon (28 October 2026)

Command: `python tools/run_probes.py`. **36 entries (validator + export_manifest + 34 Godot scenes): 36/36 pass on the single final run of Change 27, no script errors, no timeouts.** Validator 1,574 checks; Godot probes 5,883 checks plus two smoke runs. Details: [Change 27 report](LootFarmer_Change_27_Report.md).

- **Registered** `change_27_probe` (51 checks, Change 27): first lifetime Snowman defeat drops its catalog weapon once (gear chance 0 fixture, ground pickup, no second grant, natural drop not duplicated, same-seed equivalence of every other reward and signal, disk reload, snapshot round trip, real Prestige, Hard Reset, Guided/Basic/None, fixture catalog weapon, unlisted boss, Change 15 guarantee untouched, no player-facing copy); version 27 exact; launcher icons set, loading and shipping; nothing from marketing/, store_assets/, addons/, the toolkit or docs ships; the marketing adapter refuses non-capture profiles. `change_26_probe` now checks version ≥ 26 and the configured project icon.
- **Store media checks (outside the suite, need captures):** `python marketing/brand/icon/compose_icon.py --check` (Change 30: icon format, safe zone, byte-identical re-render), `python marketing/brand/compose_brand.py --check`, `python marketing/finalize_store_assets.py --check` (24 screenshots, trailer ffprobe, icon/feature rules) and `python Godot-Marketing-Toolkit/tools/marketing.py status --project .`.

## Change 26 — Android export allowlist and ABIs (28 October 2026)

Command: `python tools/run_probes.py`. **35 entries (validator + export_manifest + 33 Godot scenes): 35/35 pass on the first full run, no script errors, no timeouts.** Validator 1,574 checks; Godot probes 5,832 checks plus two smoke runs. Details: [Change 26 report](LootFarmer_Change_26_Report.md).

- **Registered** `export_manifest` (static, runs after the validator): `python tools/export_manifest.py --check` regenerates the allowlist in memory and fails if `tools/export_manifest.json` or the Release preset's `export_files` is stale. It also fails on any unregistered dynamic load site, missing dependency, forbidden path, ABI selection other than arm64-v8a + armeabi-v7a, or Release `version/code` different from the project version. After changing code or data that loads assets, run `python tools/export_manifest.py` (writes both) and commit the result.
- **Registered** `change_26_probe` (49 checks): every manifest file loads from source; eight stages ship and instantiate; runtime recorder (catalog icons, actor body/swing sheets for every group and item, effect sheets, the UI art cache after 16 panels, guide pictures and Prestige path icons) finds nothing outside the manifest; the Release preset is selected resources, 229 files, ARM only, version 26.
- **Updated** change_25_probe version check: "at least 25 and Release code = project version" (the exact value is checked by the newest probe).
- **Non-gating artifact check** (needs an export): `godot --headless --path . --export-release "Android Release" builds/LootFarmerIdleRPG.<N>.aab`, then `python tools/verify_export.py builds/LootFarmerIdleRPG.<N>.aab [--baseline <older.aab>]`. It reads the AAB/APK itself (sparse PCK directory with MD5, packed source paths against the manifest, import/remap targets, forbidden content, ABIs, manifest identity) and writes `tests/tmp/export/<artifact>.json`. Change 26: PASS, 58,948,378 bytes, arm64-v8a + armeabi-v7a, 229/229 sources, 0 missing, 0 unexpected.


## Change 25 — onboarding modes and mobile UI (28 October 2026)

Command: `python tools/run_probes.py`. **33 entries (validator + 32 Godot scenes): 33/33 pass, no script errors, no timeouts.** Validator 1,574 checks; Godot probes 5,783 checks plus two smoke runs. Details: [Change 25 report](LootFarmer_Change_25_Report.md).

- **Registered** `change_25_probe` (113 checks): Basic/None menu access through every navigation button, 11 panels and the direct paths; opening grants nothing (snapshot comparison, locked Prestige reset, no travel to unopened maps, enemy chips by discovery); silent opening; one Prestige announcement; slot-size first choice vs reload/Prestige/Hard Reset; Basic deck (3–5 cards, Skip, auto-advance, non-blocking, no later cards, Help, reload, Prestige); None (nothing after The Road Ahead); Guided (28 steps, 15 s waits, partial progress saved); Back priority, de-duplication, notification and Escape; HUD/sheet/confirmation layout at 540×960, 432×960 and 360×640; versions 25.
- **Updated stale contracts to the approved modes** (no assertion weakened): change_15, change_16, change_14, change_21, change_22 (Basic has no pointer; Guided keeps them), change_24 (version ≥ 24), change_6 (the Skip button is the second intended input on the guide card).
- **Not gating:** `change_25_capture` (windowed, `docs/Change_25_Evidence/ui/`), `change_16_audio` (11/11), `tools/run_benchmark.py`.


## Change 24 — restored maintained suite (28 October 2026)

Command: `python tools/run_probes.py` (Godot 4.7.2-stable official, Windows console build, headless, sequential, isolated `probe-suite-*` profiles, `--no-autosave`). **32 entries: the source validator plus 31 Godot scenes.** Final result: **32/32 pass, no script errors, no timeouts** — 5,689 probe checks plus 1,570 validator checks, all passing (two smoke scenes and the bootstrap probe report pass/fail only).

Changes to the suite in this batch:

- **Registered** `change_22_probe` (40 checks) and the new `change_24_probe` (53 checks: Sight equals `can_see` over thousands of points on Winter I and Spring II, alive and dead; explored masks and their save encoding; the save path's size/digest check, backup rule, version-2 reset and both coalescing tiers; the SceneState obstacle reader equals instantiating all eight stages; the bounded stage scene cache; off-screen actor views paused but current; the view pool and flat node count across stage switches; the fog shader parameters; the inventory layout key; the retained panel; version 24).
- **TEST-01 (stale clock and Road Ahead contracts):** `change_20_probe`, `change_15_probe` and `change_5_probe` drive the real-time Guided clock with `guided.advance_waits()` and `TutorialGuide._process(dt)` instead of `playtime_total`, check that paused, suspended and Prestige-choice time does not count and that playtime alone never opens Missions, walk every Guided step to `tutorial_final` (`change_20_probe` asserts all 28 steps completed), and expect The Road Ahead once in Basic and None. `change_20_probe` 84/0, `change_15_probe` 172/0, `change_5_probe` 161/0.
- **UI-04/UI-05:** `change_22_probe` expects "Automatic Claiming: OFF" then "…: ON", no Auto-Claim pointer in None (with the Missions panel text present) and the pointer in Basic.
- **Stale fixtures updated for the new representations (no behaviour assertion weakened):** explored-cell fixtures and counts use `campaign.explore_cells/explored_count` (campaign, change_5/6/7/12/15/16 probes); malformed-save checks feed a wrong-size and a non-0/1 mask; probes that inspect an enemy's overhead visuals point the camera at it first (off-screen views pause their animation by design; change_8/16); probes that judge an in-memory `restore()` clear the boot-time `last_load_result` first (change_8/9/10/16; the isolated probe profiles on disk were written at save version 2 and now reset at boot, as intended); `change_6_probe` takes its node-count baseline after one warm-up round because one closed panel stays retained (bounded).
- **TEST-03:** `tools/validate_campaign_source.py` writes `tests/tmp/static_checks.json` (ignored) by default, `--output PATH` otherwise; `docs/Change_21_Evidence/static_checks.json` is no longer touched.
- **TEST-04:** `python tools/run_benchmark.py` runs `tests/performance_benchmark.gd` windowed (non-gating; never in `run_probes.py`) and writes `tests/tmp/benchmark/report.txt`. Results: `LootFarmer_Change_24_Performance_Report.md`.

The first full run of this batch gave 25/32: the seven failures were the fixture issues above plus one real defect introduced by the retained panel (replacing it added controls while same-named old siblings were still present, so Godot renamed them, e.g. "Tabs" → "Tabs2"; `_sync_panel_children` now clears first on a full replacement). After the fixes the seven entries passed on a targeted rerun and the **full suite was run again: 32/32**.

## Production audit run — 28 October 2026 (revision b51a209)

Command: `python tools/run_probes.py` (Godot 4.7.2-stable official, Windows console build, headless, sequential). Result: **27/30 entries pass**. No script errors or timeouts.

| Entry | Result |
|---|---|
| validate_campaign_source | PASS 1,570 / 0 |
| change_20_probe | **FAIL 81 checks / 17 failures** |
| change_15_probe | **FAIL 172 / 13** |
| change_5_probe | **FAIL 159 / 1** |
| every other maintained entry | PASS (counts in the audit report, section 7) |

**Classification (Playbook 60): stale contracts, not production regressions.** Change 22/23 moved the Guided waits to an active real-time clock (`tutorial.flow.wait_seconds`, 15 s) that only `TutorialGuide._process` advances. These probes still advance `playtime_total` through simulation steps and expect 60 s, so "Missions appear at delay boundary" fails and every later Guided assertion cascades. The Road Ahead (approved for Basic and None) makes the old "None has no instruction" and Basic card-list assertions fail. Consequence: **the Guided flow after the mission wait has no passing automated coverage until these probes are updated.**

Also found:

- `change_22_probe` is **not registered** in `tools/run_probes.py`. Run by hand it gives 38 checks / 1 failure: it expects the toggle text to contain "OFF", while the string renders "Automatic claiming: Off". `tests/change_22_static.py` passes 18 / 0.
- `tools/validate_campaign_source.py` writes its report into the tracked `docs/Change_21_Evidence/static_checks.json`, so every run modifies the worktree. The audit restored the file.
- There is no non-gating performance scenario in `tests/`; the audit used a scratch desktop harness (audit report section 5).

Required before the next build: update the three probes, register `change_22_probe`, and move the validator output to an ignored path. Android device acceptance remains outstanding for everything since Change 20.

## Change 21 validation — 27 October 2026

Final combined maintained result: **30/30 entries pass** (static validator plus 29 Godot probes). The full run passed 26/30 initially; the obsolete Change 16/8 tracker placement and Change 11 five-slot migration assertions were updated to the requested behavior. The inventory interaction fixture now waits for container layout before tapping, and the runtime ignores inventory sizing until both column widths exist. All four affected probes pass on the targeted rerun. The new Change 21 probe passes **104 checks, zero failures**; the static validator passes **1,568 checks, zero failures**.

Raw initial run: `Change_21_Evidence/suite_summary.txt`. Final targeted run: `Change_21_Evidence/final_targeted_summary.txt` (6/6 entries, including static and Change 21). Per-probe logs reflect the most recent execution. Existing Change 20 tests still pass 81/0, including real Prestige level/XP retention and mastery reset. Android hardware validation remains outstanding.


## Change 20 current result

**29/29 maintained entries passed in one full run** on Godot 4.7.2 Linux headless: one source validator and 28 Godot scenes, run sequentially. Source validation: **1,567 checks, zero failures**. That full run included **79 checks** in `change_20_probe`. A final targeted rerun after adding dormant automatic-assignment clearing passed **81 checks, zero failures**, plus the source validator. The existing proximity probe passes **133**, original Change 17 gameplay **679**, and weather equivalence **60** checks. No maintained test failures, timeouts or script errors. Exact output: `Change_20_Evidence/suite_summary.txt` and `final_targeted_summary.txt`; per-scene logs and static JSON are beside it.

The new probe drives the real item toggle, automatic-slot assignment and travel APIs, checks saved state with JSON and actual disk reloads, executes Prestige, verifies level/XP retention and mastery reset, checks 3/4/6-column slot density with fixed enclosing height, checks settings through Hard Reset, verifies boss reveal/countdown and marker priority, tests camp touch/drag/combat behavior, and walks the ordered Guided flow including both waits and delayed final confirmation. Existing Change 6/7/8/11/13/14/15/16/17 assertions were updated where the approved tutorial, layout, combat or Prestige rules changed; their interaction coverage remains in the maintained suite.

Rendered evidence is in `Change_20_Evidence/ui/`. `change_20_capture` is a separate desktop OpenGL Compatibility capture at 540×960, not a headless gate or Android test. It has no script errors, but its renderer reports unsupported V-Sync and shutdown resource warnings. Physical-device visual, touch, background and performance checks remain open; use the checklist in `LootFarmer_Change_20_Report.md`. Earlier late-game balance failures are still documented and are not part of the maintained gating suite.

| New/retained probe | Scope |
|---|---|
| `change_20_probe` | Remaining-features/UI/tutorial acceptance, persistence, resets and interactive controls |
| `skill_proximity_probe` | Manual/automatic activation boundaries, eligible targets, failed-cast side effects and effective Gem chance |
| `change_17_probe` | Prior 17 gameplay changes, their saves and current Prestige contracts |
| `change_17_weather` | Weather output equivalence |

## Historical Change 19 result

**28/28 maintained entries passed in one full run**, Godot 4.7.2 Linux headless. Source validation: 1,557 checks; new `skill_proximity_probe`: 133 checks; original Change 17 gameplay: 679 checks; weather equivalence: 60 checks. No failures or script errors. Current evidence is in `Change_19_Evidence/`; see `LootFarmer_Change_19_Report.md` for scope and pending device/UI acceptance. The following Change 17 results are historical.

## Historical Change 17 result

27/27 maintained entries passing on Godot 4.7.2 (full run plus the targeted wall-clock-tolerance correction). Source validator 1,557/1,557; `change_17_probe` 679/679; `change_17_weather` 60/60 exact original-output comparisons. See [Change 17 validation](LootFarmer_Change_17_Validation.md) and `Change_17_Evidence/` for raw logs and the precise run/rerun history.

New gates cover gameplay/save/Prestige APIs and particle equivalence. `change_17_performance` is a non-gating eight-map simulation CPU sampler; `change_9_balance` was run separately and remains **33/35, two failures**, compared with 34/35 in the untouched supplied project. These balance failures are not suppressed; developer review is required. UI/tutor integration and physical Android GPU testing remain pending.

Changed legacy fixtures assert use-based mastery, the 20-second bases, below-full-HP healing and the approved prices. The old supply-slot membership fixture now owns its automation purchase. `change_16_probe` checks numeric skill-description wiring only; Claude still owns the stale eligibility prose and new effect/cap descriptions.

## Maintained regression suite (gating)

Run: `python tools/run_probes.py` (all) or `python tools/run_probes.py <name> …`. It starts with `tools/validate_campaign_source.py`, then runs each probe headless and **sequentially** (playbook 60.1), each with a hard timeout. Since Change 15 the runner passes `--first-run-complete` to every probe except `change_15_*`: fresh profiles in probes of ordinary play start with every menu revealed and the early equipment guarantee spent (Playbook 18.10); the Change 15 probe covers the progression itself. When running another probe by hand, add the flag. A run fails on a non-zero exit, a timeout, any `SCRIPT ERROR` line or a missing summary line: a runtime script error aborts a probe's coroutine before it can quit, so without the runner it looks like a hang. Set `GODOT` to the console executable on another machine.

| Probe | Covers |
|---|---|
| change_35_probe | Review invitation (eligibility, quiet-moment arbitration, hold, persistence, storefront routing from the real export presets) and the Basic/Guided targeting lesson (Change 35) |
| change_27_probe | First Snowman weapon (once per lifetime profile), Release version 27, launcher icons shipped, marketing excluded (Change 27) |
| export_manifest (Change 26) | Export allowlist and Release preset current; ARM ABIs; version code = project version |
| change_26_probe | Manifest files load, eight stages, runtime-resolved art inside the manifest, Release preset (Change 26) |
| validate_campaign_source.py | Catalog and source contracts, translations (code, scene keys and dynamic keys), every catalog tool's `--check` including change16_catalog (1,554 checks) |
| change_25_probe | Onboarding mode authority (Basic/None menus open at once, Guided staged), menus never grant content, Basic overview deck, None silence, slot-size first choice, Android Back / Escape, portrait HUD layout (Change 25) |
| change_16_probe | Map economy on all 8 maps (income ×1.5, every map-tied Coin purchase ×1.55, global and Gem prices unchanged, rising cost/income), Gem Auto-Collect / Collect Batch (prices, Prestige, older Coin levels), save migration of the new records, boss discovery (once, sound, banner order, Prestige on discovery without a kill, Prestige, Hard Reset), boss names and skill icons (stacking, contrast), the Winter I objective, mission + Prestige trackers together, followers of all 33 opportunities, Prestige keeping Gems and exploration, the Health Potion 10% → 20% and external HP bonuses, Drop All (slot, pile, Auto-Collect, exploit loops, credit, equipped, save, expiry, red UI), Map Mastery reward swap and chip, Cyan Robot Heal interval, skill descriptions, the Prestige confirmation screen, music hold rules, the Guided path opening, View Camp, Help and no development UI (197 checks) |
| change_15_probe | Early equipment guarantee (3 modes × 3 Winter I types × 4 seeds with natural drops; exact kills 5 and 10 per type and loadout; type switch; natural drops first; supplies and non-matching gear; expiry; bosses; full row; once per profile), menu reveal (hidden HUD and refused panels from every path, the chain, level backstops, full row, Snowman first and banner order, silent opportunities before the reveal, save/load, Prestige, Hard Reset, validation, Show all menus now), Guided sequence to Prestige, Basic cards, None without guidance, notification sounds (streams, triggers, hidden systems silent, shared cooldown, same frame, mutes), Map Mastery (content, records, shared items, latches and notices, percentages, rewards exactly once, Prestige, save/load, Hard Reset, optional), reachable exploration on all eight maps, panels (World entry, list, map page, unnamed unmet enemies, Stats), World map dot through panel refreshes (177 checks) |
| change_14_probe | Top-right map cluster (order, chips, contrast, insets, gate count, explored percent), Missions badge against the Claim rules (ready objectives listed first, auto-claim, waiting slots, Hard Reset), rain splashes frozen at impact, the six skill effects for player and enemy casts (placement, layer, scale, real effect, cooldowns, one effect per boss attack), Reveal Stats / Reveal Drops on both enemy tabs, joystick contrast layers and unchanged input, one-time Focused Farming guidance (modes, exits, suspension) |
| change_13_probe | Exact-identity Auto-Merge (sword and axe Wood→Stone, shared drops, outfits, skills, supplies), Auto Evolution (flat price, manual rule, one tier, own droppers, full inventory, save/Prestige/Hard Reset, panel), potion 12 s and floor, skill prices and cooldowns, next-stage guidance and discovery-only boss markers, currency format across surfaces, rainy-map overcast and world-anchored rain, summoned helpers (cap, no rewards, cleanup, never saved), final boss (Heal priority below 50%, attack pool, pace, summons) |
| change_12_probe | Cyan Robot Heal (real HP, telegraph, cooldown, death, effects on the caster, heal numbers), map explored percent (source, rounding, vision/panning, map switch, placement), Settings copy and audio controls, audio categories/priority/cooldown/persistence, followed-step and mission cues once per transition, Merge All (purchase, rules, UI, save, Prestige, Hard Reset), stone-tier swing mapping, camera after Prestige, gem chance formula and prices |
| change_12_smoke | Every Change 12 panel and action once on the real main scene |
| change_11_probe | Collection follower, minimap markers, Teleport picker, loot speech, supplies and mastery, supply save/load/reset, Filters close paths, gem upgrades kept by Prestige, spawn prices |
| change_11_smoke | Every Change 11 panel and action once on the real main scene |
| change_10_probe … change_5_probe | Each change's approved contracts (stale supply checks updated in Change 11) |
| campaign_probe, campaign_content_probe | Campaign rules and authored content |
| gameplay_probe | Core rules: inventory identity and evolution, supply use, attack timing and single contact, reload safety, respawn, pause and suspension, Prestige retention, invalid saves, leash, regeneration, automation, spawn upgrades, focus, variant loadouts, XP, **ground loot expiry** |
| ui_probe | HUD layout, enemy-panel purchase, supply use, tap-to-collect, joystick, actor frames, zoom and camera |
| inventory_probe | Dock slot tap, hold and scroll, and slot layout |
| targeting_probe | Target lock, manual selection, aim and release, pinch cancel, idle acquisition |
| camera_probe | Map touch routing, pan and pinch |
| attack_timing_probe | Attack windup and contact timing |
| bootstrap_probe | Boot, profile isolation and save-container basics |
| change_8_walk_probe | Movement around solid scenery on every stage |

Change 11 final run: 19 / 19 passed. **Change 16 run: 25 / 25** (24 probes and the source validator). Change 12 run: 21 / 21. Change 13 run: 22 / 22. Change 14 run: 23 / 23. **Change 15 run: 24 / 24** (`tools/run_probes.py`; stale contracts updated first, see below).

`tools/fog_reachability.gd` (run with `godot --headless --path . -s tools/fog_reachability.gd`) checks the stored unreachable fog cells against a fresh flood fill (8 / 8 maps match).

## Change 16 test updates

First full run after the implementation: 16 / 24. Every failure was a contract this change replaces on purpose, one date-dependent fixture and one test artefact; each was updated with the same intent. No production regression.

| Test | Change | Reason |
|---|---|---|
| change_15_probe | Settings checks: Help present, no Show all menus; `reveal_all(true)` checked directly; MAIN_4 names Winter II only | Change 16 removes Show all menus / Choose guidance again; Prestige opens on finding the Snowman |
| change_13_probe | Potion ^0 10%; camp-price formatting fixture moved to Spring II (first camp price ≥ 1,000 at 1.55 per map) | Change 16 potion and map pricing |
| change_12_probe | Cyan Robot Heal timer 12 s; Prestige keeps Gems; the followed-step notice section counts `follow_step` only | Change 16 Robot and retention. The notice failures were date-dependent: the day's daily missions (chosen by a hash of the date) included a Blue Cap hunt that the section's 200 kills completed |
| change_11_probe | Collection follower names the exact outfit and shows its icon; tracker bottom-right; potion 11% / 20%; Gems kept, coins reset | Change 16 follower, trackers, potion, retention |
| change_8_probe | Camp approach: no pop-up, View Camp opens it; Collect Batch is a Gem upgrade (50); tracker text first line; tracker bottom-right | Change 16 camps, Gem collection, trackers |
| change_5_probe | Potion vs Heal role checked for the droppable Heal (tier 1) at every mastery and the legacy tiers at ^100; tier-one potion 10% | Change 16 potion 10% → 20%; legacy Heal tiers 2–7 reach the 12% cap at level 1000 |
| campaign_probe | Prestige keeps explored cells | Change 16 retention |
| gameplay_probe | Prestige keeps Gems | Change 16 retention |
| ui_probe | Unreleased languages are not offered and are refused (were disabled buttons) | Change 16 removes development notices |
| change_16_probe | New, in the suite (197 checks) | Change 16 contracts |
| change_16_audio | New, windowed, not in the headless suite (11 checks) | Real music playback |
| change_16_capture | New, rendered | docs/Change_16_Evidence/ui/ (desktop evidence only) |

## Change 15 test updates

First full run after the implementation: 17 / 23. Every failure was a stale contract or a test artefact, and was updated with the same intent. The run also exposed one production bug, fixed in `e52054a`.

| Test | Change | Reason |
|---|---|---|
| change_12_probe | "three different sounds" → the three share the mission-ready sound; notices filtered to follow_step / mission_ready; Merge All fixture marks "Merge a duplicate" claimed | Change 15 notification sound family; the new `main_ready` notice (a main objective that becomes ready outranks the confirm click, by design) |
| change_5_probe, campaign_content_probe | `schema==7` → `schema==8` | Change 15 save schema |
| change_8 / 9 / 10_probe | none (passed on rerun) | Their probe profiles on disk were schema 7, so `last_load_result` read `development_reset` once; the same one-time reset happens to a device save |
| change_6_probe | the node-count baseline excludes the world viewport | A damage number expiring during the open/close cycles made the check flaky; the check is about panels |
| change_6_probe (script error) | — | **Production bug:** the panel reconciler pruned the World map's player dot on an in-place refresh. Fixed in `e52054a`; change_15_probe has a regression check that fails without the fix |
| change_15_probe | New, in the suite (177 checks) | Change 15 contracts |
| change_15_capture | New, rendered | docs/Change_15_Evidence/ui/ (desktop evidence only; run without `--first-run-complete`) |

## Change 14 test updates

One full maintained-suite run after the implementation: **23 / 23**. The three contracts below changed on purpose and were updated with the same intent before that run; none was a production regression.

| Test | Change | Reason |
|---|---|---|
| change_5_probe | "Spell renders beneath actors" → Frost beneath, Lightning above, per `skill_effects.tres` | Change 14 per-effect layers (Lightning no longer hidden under its target). |
| change_12_probe | Explored label placement: top-right cluster between zoom and minimap; "Map Explored"; Heal ring values read from the Heal style | Change 14 map cluster; self-effect values moved from `world.gd` exports to the resource (same numbers). |
| change_13_probe | Gate label path `Row/Label`, "Next Stage"; boss wind-ups counted from `sim.skill_warning` | Change 14 chip and the separate wind-up signal (one warning plus one hit per action, as before). |
| change_14_probe | New, in the suite (202 checks) | Change 14 contracts. |
| change_14_capture | New, rendered | docs/Change_14_Evidence/ui/ (desktop evidence only). |

## Change 13 test updates

One full maintained-suite run after the implementation: 18 / 22 passed. The four failures were stale contracts for intended Change 13 rules (no production regression) and were updated with the same intent; all four then passed (**22 / 22**).

| Test | Change | Reason |
|---|---|---|
| change_7_probe | Auto-Merge covers the type's own outfit, not `unit-blue-cap_outfit_t3` | Change 13 exact-identity Auto-Merge (evolved or legacy tiers follow their own droppers). |
| change_8_probe | First skill-slot price 50 → 300 gems | Change 13 skill prices. |
| change_10_probe | Enemy-panel boss payout read with `fmt_currency` | Change 13 currency format ("×15", not "×15.00"). |
| change_11_probe | Potion ^100 cooldown 4 s → 10 s | Change 13 12 s base with a 10 s floor. |
| change_13_probe | New, in the suite (154 checks) | Change 13 contracts. |
| change_13_capture | New, rendered | docs/Change_13_Evidence/ui/ (desktop evidence only). |
| change_9_balance | Not changed; run once | Non-gating. Now fails "final boss ^300 with 4 cards" (boss at 3%) because of the slower player skills; log in docs/Change_13_Evidence/balance.log. |

## Change 12 test updates

| Test | Change | Reason |
|---|---|---|
| change_10_probe | 2 checks: base gem chance 8% → 5% | Change 12 gem chance rules (same intent: amount upgrades never change the chance; Boss Gem Chance adds 5 points per level). |
| change_7_probe | Heal-effect position read from the caster's view | Self effects are now children of the caster's view so they follow it; the check (ring on the feet, at the actor's scale) is unchanged in intent. Before, the probe crashed on the type change (script error). |
| audit, camera, evolution_farming, inspector, ui probes | `SettingsState.set_sfx_enabled(false)` → `SettingsState.mute_all_sfx()` | The single sound toggle became two category mutes. |
| change_12_capture | New, rendered | docs/Change_12_Evidence/ui/ (desktop evidence only). |

## Not in the default suite (non-gating)

| Item | Status | Why |
|---|---|---|
| change_36_final_boss_audit | 280 / 0 (duels), 14 / 0 (farm), Change 36 | Final-boss audit: obtainability-checked builds (real Prestige transaction, bought upgrades), 140 duels with 5 seeds each (≈6 min), `--mode=farm` Stage 8 farm rates (≈2 min). Builds and CSVs: `docs/Change_36_Evidence/`. Run deliberately when combat, supply or card values change. |
| change_9_balance | Historical for the final boss | Deterministic duels; its final-boss rows seed fake key ids and no supplies, upgrades or Prestige. Superseded for the final boss by change_36_final_boss_audit. |
| change_16_audio | Passes (11 / 11), windowed | Real music playback through volume 0, the game pause and a scene re-entry. The audio service never decodes music headless, so this runs with a window: `godot --path . res://tests/change_16_audio.tscn -- --probe --profile=probe-c16-audio --no-autosave --first-run-complete`. |
| tools/verify_export.py | PASS on `LootFarmerIdleRPG.26.aab` | Inspects an exported AAB/APK against the allowlist; needs an export (Change 26). |
| pacing_bot | Not run | Natural-pace benchmark (minutes per run); for pacing questions only. |
| change_*_capture (change_16_capture added), change_6_before, change_8_stage_capture, stage_overview_capture | Not gating | Rendered evidence (screenshots); run with a window. |
| change_7_smoke, change_10_smoke | Pass | Superseded for build readiness by change_11_smoke; kept as history. |
| audit_probe | Historical, fails | Calls the removed `sim.sell` (hangs on the script error). |
| balance_probe | Historical, fails | Reads removed legacy items (`dinosaur`); superseded by change_9_balance. |
| evolution_farming_probe | Historical, fails | Asserts Change 1–4 gem prices and outfit evolution (removed in Change 8). |
| farming_ui_probe | Historical, fails | Reads the removed flat potion `heal` stat. |
| feedback_probe, group_progress_probe, inspector_probe | Historical, fail | Assert pre-Change 6 presentation, unlock and drop-rate contracts that later changes replaced. |

The historical probes are kept as records of their era and are not maintained. Their current contracts are covered by the suite above. Delete them in a later cleanup, or repair one if it turns out to cover something the suite does not.

## Change 11 legacy disposition (brief section 7)

| Test | Disposition | Reason / replacement coverage |
|---|---|---|
| change_1_probe | Deleted | Asserted contracts replaced on purpose: Change 1 gem prices, a schema-4 refund migration, the 4-type world, the victory/offer Prestige (87 of 131 checks failed). Its still-current contracts (per-type collection, spawn upgrades) moved to gameplay_probe; gem payouts are in change_10_probe. |
| progression_probe | Deleted, consolidated | Called the removed `sim.sell()` (script error, so it hung) and assumed removed items, the old Prestige and 28 enemies. Variant loadouts, worn-loot rolls and the XP threshold moved to gameplay_probe; stored shares and level growth are in change_9 and change_10. |
| gameplay_probe | Fixed and consolidated | Core combat and timing rules live only here. Harness fixed: `sim.step` clamps to 0.1 s, so a stepping helper was added; fog fixture; current Prestige batch and invalid-save rule. **Found a genuine bug: ground loot never expired. Fixed in `a047048`.** |
| ui_probe | Fixed | The pending onboarding chooser suspended the simulation; enemy panels need a discovered type; Use is a pinned action; navigation includes Upgrades again; the HP fill is textured (the old `hp_fill` check hung the run). |
| inventory_probe | Kept | Fixture updated (onboarding; 5 supply slots). |
| targeting_probe, camera_probe | Fixed, added to suite | Same onboarding fixture; fog-explored ground for chasing; a stepping helper; marker texture; merge gain from the catalog getter. |
| change_5/6/7/8/10 probes | Updated | Stale supply assertions (potion tiers, `potion_cooldown`, the Coin Tonic text key, `merge_supplies` price, supply cap 13) moved to the Change 11 rules with the same intent. |
