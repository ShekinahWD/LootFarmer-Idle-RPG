# LootFarmer — Change 12 Notes

Baseline: Change 11 (`7081d18`, tests/docs `2684e85`). Brief: docs/LootFarmer_Change_12_Instructions.md.

Build commits: `5297bdc` (implementation), `2ffa8fb` (the Merge All button uses the primary style; found in the rendered capture). **Build from `2ffa8fb` or later.** The tests/docs commit after it does not change the game.

## What changed

| # | Area | Change | Where |
|---|---|---|---|
| 1 | Cyan Robot Heal | **The bug:** a boss telegraphed every skill 0.6 s before casting it and emitted the skill's effect at the telegraph, but only checked Heal's rule (HP below 80%) when it resolved. At 80%+ HP the Heal effect and sound played, nothing was healed, the boss retried 1 s later and repeated, about every 1.6 s for the whole fight. Because a failed skill kept its place, a boss with Heal first in its rotation also never used its other skills until it was wounded. A real heal did restore 8% of max HP, but its effect played twice (telegraph and success), detached from the boss. **Fix:** self-cast eligibility (`campaign.skill_ready`: Heal below 80%, Focus in combat) is checked before the telegraph; an ineligible skill passes its turn to the next one; Heal and Focus play one effect, on success, as a child of the caster's view (it follows movement); `_kill` clears the telegraph. The heal amount (8% enemy, min(power, 12%) player, clamped to missing HP) and the 18 s cooldown are unchanged. Healing numbers are centred above the head and 1.3× larger than damage numbers. | `campaign.skill_ready`, `apply_skill`, `step`; `world._spell`; `actor_view.show_hit` |
| 2 | Map explored | "Map explored: n%" in the lower-right corner of the map, from the saved explored cells ÷ the map's fog grid, rounded down. Momentary sight and panning never count. The Regional opportunities read the same helper. The label reads an O(1) count every HUD tick and writes only when the text changes; it never takes touches. | `campaign.explore_area`, `explored_fraction`, `explored_percent`; `main.tscn Map/Explored`; `game_ui._refresh_explored` |
| 3 | Settings text | The credits line drops "Font: DejaVu Sans. Premium game · no ads, purchases or tracking." No other Settings text mentioned fonts or "premium". | `CREDITS` string |
| 4 | Audio controls | Music volume and Sound effects volume sliders (0–100%), Mute gameplay sounds and Mute special sounds (independent). Saved with the settings; Prestige and Hard Reset keep them (existing policy: settings survive Hard Reset). The single "Sound effects: On/Off" toggle is gone. | `settings_state.gd`, `game_ui._settings_panel`, `_volume_row` |
| 4 | Audio service | One editable cue set (`resources/game/audio_cues.tres`: `AudioCueSet` with `AudioCue` entries: id, stream, category, priority, cooldown, volume). All requests in a frame resolve to the single highest-priority **audible** cue, so a click under a confirm or a step cue under Prestige ready never stack. Per-cue real-time cooldowns. The service runs while paused (clicks in the pause menu); the music player pauses with the game and keeps its position. Background music starts with the game. Headless runs keep the routing state but do not decode the music. | `audio_service.gd`, `audio_cue.gd`, `audio_cue_set.gd` |
| 5 | Special sounds | Prestige opportunity discovered; a completed step of the followed opportunity (Expedition/Specialist chain steps, Collection outfits, Trophy bosses; one cue per step at the transition, never on load, re-follow or continued farming; the final step plays Prestige ready instead); a mission reaching its goal when it will be claimed by hand (silent while auto-claim is bought and on); new map unlocked; Prestige performed. The milestone banner no longer plays its own sound (it used to play `prestige.wav` when shown, possibly later and on top of the transition's sound). | `sim.notice`, `campaign.check_follow_step`, `follow_steps_done`, `missions_auto_claimed`; `game_ui._notice`, `_milestone` |
| 6 | Merge All | One-time 5,000-Gem global unlock (Upgrades → Inventory), kept by Prestige, cleared by Hard Reset. Filters then shows "Merge All · n spare copies" (primary style). One tap runs the ordinary "merge spare copies" for every weapon, outfit and skill that can merge: one copy kept, never past ^100 (weapons) / ^500 (outfits, skills), never an evolution, never supplies (their stock and mastery are untouched). One aggregate notice ("Merged n copies across m items"), one confirm sound; "Nothing to merge" disables it. Free to use. Unrelated to the timed per-type gear auto-merge. | `sim.merge_all`, `merge_all_copies`; `game_ui._merge_all_action`; catalog `merge_all` |
| 7 | Stone-tier swing | The Winter I Snowman carries and drops the **Stone Axe** (`stone_axe`, tier 2), not the Iron Axe. Its icon is the gray stone-and-wood axe of the PixelPlains item sheet, but its swing used the animation pack's **Onix** set (navy/black). The pack has no Stone set. Stone Axe and Stone Sword now swing with the **Iron** set sheet tinted warm gray (`attack_tint` [0.9, 0.84, 0.84], on the swing sprite only); the Iron tier keeps the plain Iron sheet. The Snowman's own swing uses the same mapping. The other tiers already matched their icons (Wood, Iron, Gold, Diamond, Emerald, Ruby for Obsidian). Presentation only: timing, range, contact and damage unchanged. | `tools/change12_catalog.py`, `world.attack_tint`, `actor_view.attack_tint` |
| 8 | Camera after Prestige | Performing a Prestige cancels any drag, releases the joystick and restores follow on the newly spawned player (the new profile is committed before the PRESTIGED event, so no older state moves it back). Zoom is kept. Opening the Prestige panel does nothing to the camera. Revival and joystick follow are unchanged. | `game_ui._recenter_on_player` |
| 9 | Gem chance | Base 5% (was 8%) for normal and boss rolls; Gem Chance 20 levels × +0.5 points (was 12 × +1); Gem Wisdom +5 points (was +3); the 20% normal / 60% boss caps removed, also from `upgrade_maxed` (which used to stop Gem Chance early when Gem Wisdom was owned). Only 0–100% clamping remains. Gem amounts, the boss 3× amount, Boss Gem Amount and every other drop chance are unchanged. | `sim.gem_chance`, `gem_base_chance`, `upgrade_maxed`; catalog |

## Gem chance formula and prices

chance = clamp(5% + 0.5 pt × Gem Chance level + Gem Wisdom 5 pt + kill achievements (0.5 pt × milestones, 8 milestones = 4 pt) + [boss] 5 pt × Boss Gem Chance level, 0%, 100%).

Audit of the live code: no other contributor exists. The only card with the `gem_chance` effect is Gem Wisdom (no combo grants it); the legacy prototype `state.cards` bonus can only come from pre-Change 6 saves. The drop roll, enemy research, the Farming Guide and the upgrade cards all read `gem_chance()` / `gem_base_chance()`. Fully stacked: **24% normal, 64% boss**, matching the brief.

| Gem Chance level | 1–12 (unchanged) | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 |
|---|---|---|---|---|---|---|---|---|---|
| Price (gems) | 25, 40, 58, 80, 105, 135, 170, 210, 260, 320, 390, 470 | 560 | 660 | 770 | 890 | 1,020 | 1,160 | 1,310 | 1,470 |

The existing steps grow 15, 18, 22, 25, 30, 35, 40, 50, 60, 70, 80; levels 13–20 continue with +90 … +160 (each step 10 more than the one before). Levels 1–20 cost 10,103 gems in all (levels 1–12: 2,263; levels 13–20: 7,840).

Boss Gem Chance (8 × 5 points, 50 … 530 gems) and kill achievements are unchanged.

## Audio assignments

| Cue | Category | Asset | When |
|---|---|---|---|
| music | music | assets/sounds/background_music.wav (−8 dB) | the whole session, looping |
| ui_click | gameplay | assets/Audio/button.wav | panel and navigation taps |
| ui_confirm | gameplay | assets/sounds/ui_confirm.wav | a successful manual purchase, claim, merge, Merge All, evolution, card |
| spell_heal / frost / fire / lightning / focus / strike | gameplay | magic-spells-sfx-lite heal, ice_shatter, fire_impact, zap, cast, impact (−4 dB, 0.25 s cooldown) | a visible cast |
| mission_ready | special | assets/sounds/mission_ready.wav | a manually claimed mission is ready |
| prestige_step | special | assets/sounds/reveal_unlock.wav | a step of the followed Prestige completed |
| prestige_discovered | special | assets/Audio/prestige.wav | a new Prestige opportunity |
| stage_unlocked | special | assets/sounds/stage_clear.wav | a new map |
| prestige_ready | special | assets/Audio/prestige.wav | an opportunity becomes ready |
| prestiged | special | assets/Audio/prestige.wav | Prestige performed |

Priority: click 0 < spells 10 < confirm 20 < mission 50 < step 60 < discovered 70 < new map 75 < ready 80 < Prestige 90. Hits, kills, pickups, gem drops and automation stay silent (Playbook §85). Unused existing files: Castle_Damage ×6, defeat, move_command ×2, ui_error. The `assets/sounds` files are the developer's own cue set (used by Growing Kingdom and Everfort) but the repository holds no licence record for them; see the Asset Registry.

## Tests (focused)

- `tests/change_12_probe`: **149 checks, 0 failures**: Heal (full HP and 85% HP show nothing for several seconds, the 0.6 s telegraph has no effect, exactly 8% restored with one effect and one number, 18 s cooldown, no second heal, death during the telegraph, player Heal clamp, a refused cast keeps the cooldown free, the effect on the caster's feet follows it, heal number style); map explored (denominator, label text, vision and panning unchanged, new cells raise it, same as Regional, 100% / 99% / 0%, map switch, Hard Reset, placement against the joystick, minimap, follower, zoom and enemy buttons); Settings copy, sliders and mutes; audio categories, priority, cooldown, disk save/load, Prestige and Hard Reset; notices once per transition (expedition steps, reload, final step = one sound, unfollowed silence, collection steps, missions with and without auto-claim, discovery cue); Merge All (locked, price, buy once, same result as manual merges, capped weapons and singles untouched, no evolution, supplies untouched, free, one notice and cue, idle state, save/load, Prestige, Hard Reset); stone swing (live Snowman weapon, sheet, warm hue versus the blue Onix sheet, every tier's set, player and Snowman views, the held icon untinted, Iron unchanged); camera after Prestige (panel open does nothing, follow and drag cleared, centred frames later, zoom kept); gem chance (prices 1–12 and 13–20, monotone, base 5%, level 20 = 15%, Gem Wisdom = 20%, achievements +4, 24% / 64%, observed roll rate, no ceiling, 3× boss amount, texts, upgrade card preview and level 20/20).
- `tests/change_12_smoke` (build readiness) and `tests/change_12_capture` (desktop screenshots in docs/Change_12_Evidence/ui/).
- **Maintained suite** `python tools/run_probes.py`: **21 / 21 passed** on the final code (validate_campaign_source now 1,343 checks; see docs/LootFarmer_Test_Suite.md). change_10_probe (base 8% → 5%) and change_7_probe (heal effect read from the caster's view; it crashed on the moved node) were updated for intended Change 12 behaviour.
- No balance simulations or pacing bots (per the brief).

## Android-only checks (not tested on a phone)

- **Audio:** whether every cue is audible and well mixed on the device speaker; music level (−8 dB) against the cues; that `reveal_unlock`, `mission_ready` and `prestige` are distinct enough; Mute gameplay / Mute special behaviour; the sliders' touch feel inside the scrolling Settings panel; music pausing with the game and on app background.
- **Cyan Robot fight:** the robot now shows Heal only when it actually heals (below 80% HP), with a larger green number. Check the number's readability at the boss's 2× scale, and how the fight feels now that it is not "casting" every 1.6 s.
- **Boss rotations (balance note):** bosses whose rotation starts with Heal (Squirrel: Heal, Focus; Sunflower: Heal, Focus) or reaches it (Bee: Lightning, Heal; Red Panda: Frost, Heal) no longer stall on Heal while above 80% HP, so they now use their other skill on schedule. This is the defect fix, not a retune, but it makes those four bosses somewhat stronger than before. Please judge them on the device.
- **Map explored** label: size (17 px, outlined) and its place in the lower right on real aspect ratios and insets, over light snow and dark fog.
- **Stone-tier swing:** whether the warm-gray Iron swing reads as the Stone Axe's metal on the phone at normal zoom, for the player and the Snowman; the same for Stone Sword.
- **Merge All:** the Filters panel length with the new button; the 5,000-Gem pace.
- **Camera after Prestige** with a real drag in progress.
- **Gem chance balance:** the lower base (5%) slows early gems, and 24% / 64% fully stacked raise late gems; not simulated.

## Saves

No save-schema change and no migration. Current saves keep loading. The old `sfx_enabled` / `music_enabled` settings keys are ignored, so both mutes start off. Gem Chance levels above 12 did not exist before, so no level needs capping.
