# LootFarmer — Change 16 Notes

Baseline: Change 15 (`e52054a`, tests/docs `fd7dd45`), the project ZIP of 2026-10-22 (identical to that working tree). Design: the Change 16 brief "Gameplay Improvements and Corrections" (14 items). Two open choices were answered by the developer before implementation: the Health Potion heals **10% at ^0 → 20% at ^100**, and **camp unlock prices and the Map Details floor follow the same 1.55 per map** as the other map-tied Coin prices.

Save schema stays **8**: the new records default on load (`campaign.normalize_snapshot`), so existing development saves keep their progress. Application version and Android codes are unchanged by this change (the working tree already carried version 16 / code 16 from the developer).

## What changed

| # | Area | Change | Where |
|---|---|---|---|
| 1 | Coin income | Base Coin reward of a normal enemy = 1.5^(map−1) (was 1.25^(map−1)); Winter I stays 1, bosses keep 8×. Coin Amount and every bonus multiply the new base. | `data/game/catalog.json` (groups `coins`), `tools/change16_catalog.py` |
| 1 | Coin prices | Every Coin price tied to an enemy type, a map or a camp scales 1.55^(map−1) (was 2^(map−1)): all enemy Coin upgrades, Reveal Radius, Camp Radius, camp unlocks and the Map Details floor. Level-based growth unchanged; global Coin upgrades and Gem prices unchanged. | `campaign.map_cost_factor`, `upgrade_cost`, `camp_price`; `progression.map_cost_growth` |
| 2 | Auto-Collect | Gems: 20 on Winter I (Gem map scaling 1 + 0.25 per map). | catalog `collect` |
| 2 | Collect Batch | Gems: 50 / 150 / 450 / 1,350 / 4,050 on Winter I (×3 per level as before; batch 1 → 6). | catalog `collect_batch`, `tools/change8_catalog.py` |
| 3 | Music volume | Fixed: a paused Godot player reports `playing == false`, so after the volume touched 0 the old code never unpaused it. One `_sync_music` now starts the track only once, holds it (keeps its position) at volume 0 or while the game is paused, and resumes it in place. | `scripts/autoload/audio_service.gd`, `game_ui._pause` |
| 4 | Boss discovery | The first time the living player sees a living boss within 160 units it is found for good (`bosses_found`, kept by Prestige): "!WARNING BOSS FOUND!" (red banner, ahead of the queue) and the mission-ready sound (`boss_found` cue), once. | `campaign.sight_bosses`, `fog_rules.boss_sight_radius`, `milestone_banner.push_warning`, `audio_cues.tres` |
| 4 | Prestige unlock | Prestige opens when the Snowman is **found** (or was ever defeated). Finding it never defeats it or opens Winter II. | `campaign.prestige_unlocked` |
| 4 | Boss names, skill icons | Bosses show their name in red (dark outline) above the HP bar; any enemy with skills shows one small icon per skill. Name, icons, World banner and HP bar stack upward without overlap. | `actor_view._stack_overhead`, `actor.tscn`, `world._skill_icons` |
| 5 | Winter I objective | "KEEP FARMING UNTIL YOU CAN BEAT THE BOSS TO ADVANCE." on a dark chip in the map cluster, on Winter I until the Snowman has been defeated once (lifetime). | `main.tscn` `Objective`, `game_ui._refresh_objective` |
| 6 | Tracking | Follow / Unfollow on every daily mission and main objective (one at a time), independent of the followed Prestige opportunity. Both trackers sit bottom-right (mission above Prestige). A claim or a refresh that replaces the mission ends the follow. | `campaign.toggle_follow_mission`, `mission_follow_summary`, `main_progress`; `main.tscn` `MissionTracker`; `game_ui._refresh_mission_tracker`, `_layout_trackers` |
| 6 | Opportunity clarity | All 33 followers rewritten: what to do now, the enemy / item / map, current/required, and "Next:" or "Then:" for the following requirement. Collections name the exact item and show its icon. The Prestige panel shows the same line. All 33 descriptions rewritten to be actionable and name their maps. | `campaign.follow_summary`, `follow_focus`, `en.po` |
| 7 | Prestige keeps | Gem balance, explored cells, sighted camps, found encounter spots and found bosses. Coins, owned camps, map upgrades and the run's online Gem credit (Offering) still reset. | `campaign.choose_card` keep list |
| 8 | Mastery chip | "Mastery n% · k/5" above Map Explored; a tap opens the current map's Mastery page. | `main.tscn` `Mastery`, `game_ui._refresh_mastery_chip` |
| 8 | Reward swap | Autumn II: +2 pts Gem Chance; Spring II: +15% max HP. Rewards derive from latched completions, so existing saves pick it up with no migration. | `resources/game/mastery_rules.tres` |
| 9 | Cyan Robot | Heal every 12 s (catalog Heal 18 s; +50% frequency). Every other enemy unchanged. | `EnemyAbilityRules.skill_cooldowns`, `campaign.enemy_skill_cooldown` |
| 9 | Health Potion | 10% of max HP at ^0, 20% at ^100, before external bonuses (supply rule base + 1% of base per level kept). Max-HP bonuses still raise the HP restored; no cap. | catalog `potion`, `tools/change11_catalog.py` |
| 10 | Drop All | Red Drop All in item and supply details → red confirmation naming item, ^level and quantity → the whole stack becomes one ground pile (×n) at the player's feet; its slot frees at once. Picking it up restores it exactly with no mission, Prestige, Mastery, recent-find or supply-mastery gain; Auto-Collect never takes it (group −1); it expires after 300 s like loot. Equipped items must be unequipped first. | `simulation.discard`, `discard_block_reason`, `collect`, `_restore_credit`; `game_ui._drop_action`; `pickup.tscn` |
| 11 | Guided opening | "Follow the path to your left." with the guide's arrow beside the player, turned toward the path (`OnboardingRules.path_target`). Done within 110 units of it, or at the first defeat anywhere. | `tutorial_guide._path_followed`, `_point_path` |
| 11 | Camps | No pop-up on approach. A View Camp button under the camp's name (within 64 units) opens it; tapping the camp still works; the Guided camp lesson points at View Camp when standing there. | `game_ui._refresh_view_camp`, `tutorial_guide` `camp_view` |
| 12 | Skills | Item details describe each skill with today's numbers: multiplier × attack damage (and the result), targets, area or range, duration, slow, cooldown; Heal amount and its 12% cap; Focus %. Merges, cards and the cooldown upgrade show at once. | `game_ui.skill_description`, `campaign.FROST_RADIUS`/`FIRE_RADIUS`/… |
| 13 | Prestige confirmation | A milestone screen in the discovery banner's style (gold frame, star, sparks): opportunities redeemed, a green "PERMANENT · YOU KEEP" card and an orange "THIS RUN RESETS" card with live values, Cancel / Begin Prestige. | `scenes/game/prestige_confirm.tscn`, `scripts/game/prestige_confirm.gd`, `game_ui._open_prestige_confirm` |
| 14 | Development UI | Show all menus and Choose guidance again removed from Settings; Help opens the Basic tutorial as a read-only page (opening card, tips, one card per revealed system, situational cards met). No development-save toast; the language list shows Automatic and English only. `onboarding.reveal_all` stays for probes. | `game_ui._settings_panel`, `_help_panel`, `LocalizationService.available_languages` |

## Economy per map (base values, no upgrades or cards)

| Map | Normal coins old → new | Boss old → new | Loot Chance L1 old → new | Coin Amount L1 old → new | Camp 2 unlock old → new | Map Details floor old → new | Loot price ÷ income old → new |
|---|---|---|---|---|---|---|---|
| Winter I | 1.0 → 1.0 | 8.0 → 8.0 | 20 → 20 | 30 → 30 | 50 → 50 | 40 → 40 | 20.0 → 20.0 |
| Winter II | 1.25 → 1.5 | 10.0 → 12.0 | 40 → 31 | 60 → 47 | 100 → 78 | 80 → 62 | 32.0 → 20.7 |
| Summer I | 1.562 → 2.25 | 12.5 → 18.0 | 80 → 49 | 120 → 73 | 200 → 121 | 160 → 97 | 51.2 → 21.8 |
| Summer II | 1.953 → 3.375 | 15.62 → 27.0 | 160 → 75 | 240 → 112 | 400 → 187 | 320 → 149 | 81.9 → 22.2 |
| Autumn I | 2.441 → 5.062 | 19.53 → 40.5 | 320 → 116 | 480 → 174 | 800 → 289 | 640 → 231 | 131.1 → 22.9 |
| Autumn II | 3.052 → 7.594 | 24.41 → 60.75 | 640 → 179 | 960 → 269 | 1,600 → 448 | 1,280 → 358 | 209.7 → 23.6 |
| Spring I | 3.815 → 11.391 | 30.52 → 91.12 | 1,280 → 278 | 1,920 → 417 | 3,200 → 694 | 2,560 → 555 | 335.5 → 24.4 |
| Spring II | 4.768 → 17.086 | 38.15 → 136.69 | 2,560 → 430 | 3,840 → 645 | 6,400 → 1,075 | 5,120 → 860 | 536.9 → 25.2 |

The last column is the requested property: each map is slightly more expensive relative to its income (×1.033 per map). It also shows the size of the change: on Spring II a Coin upgrade now costs about 25 kills' base income instead of about 537. Coin upgrades on later maps become far easier to afford than in Change 15. That is the brief's rule applied as written, not separately tuned; device play decides whether Coin Amount, Loot Chance and the other ladders now max out too quickly on the later maps.

Auto-Collect costs 20, 25, 30 … 55 Gems on maps 1 to 8. Collect Batch on Spring II: 138 / 413 / 1,238 / 3,713 / 11,138 Gems (Winter I 50 … 4,050). The ×3 per level was kept as instructed; with 48 enemy types the late batch levels are a large Gem sink.

## Adjustments and interpretations

- **"Regular or special mission"** is read as a daily mission or a main objective. Main objectives show concrete progress where one exists (5 defeats, 4 / 6 skills) and an instruction otherwise (`MAIN_HINT_*`).
- **The Winter I objective** shows from the first second of a profile on Winter I (before the Change 15 objective reveal) and leaves at the first Snowman defeat ever, not each run.
- **Boss discovery** needs the boss alive and in sight (explored or within momentary vision) within 160 units. Vision still never discovers an encounter spot (Change 8 rule); the found-boss record is separate. A boss already defeated in an existing save counts as found, without a warning.
- **Prestige keeps the found encounter spots and sighted camps** with the explored cells (they are derived from them; keeping only the cells would leave known land without its markers).
- **Help** is a read-only page of the Basic cards rather than replaying them on the HUD, so it changes nothing in the profile; it never describes a system the player has not revealed.
- **Equipped items cannot be dropped** (unequip first): dropping the worn weapon by accident would silently weaken the character. Supplies can be dropped; a dropped stack keeps its merge level, extras and supply mastery.
- **The Prestige confirmation is a new scene**, not the ordinary confirm dialog restyled, so the gold frame, star and sparks are inspector-editable like the discovery banner.
- **Collect Batch levels bought with Coins** keep their level after the switch to Gems (no refund, no reset).
- **Guided Snowman card:** finding the Snowman before the Guided "defeat the Snowman" card has shown completes that lesson (Prestige is then already open), and the Prestige lesson follows.

## Consequences to watch on a device

- **Potion vs Heal at ^0:** a ^0 potion (10%) now heals less than a Heal cast that reaches its 12% cap. With the droppable Heal (tier 1) this needs a very low max HP and does not happen in normal play; legacy Heal tiers 2–7 (older saves only) reach the cap at high levels. change_5_probe now checks the role separation for tier 1 at every mastery and for the legacy tiers at ^100.
- **Late-map Coin economy:** see the table above.
- **Robot Heal:** 12 s cooldown plus the 0.6 s wind-up: measured 12.8 s between heals in the probe (18.8 s before).
- **Regional opportunities** become easier on later runs, because exploration is now kept by Prestige; bosses and camps still have to be done in the run.

## Tests

| Claim | Evidence |
|---|---|
| Economy on all 8 maps, every map-tied Coin purchase, global and Gem prices unchanged, rising cost/income | change_16_probe (economy) |
| Gem Auto-Collect / Collect Batch, Prestige, older Coin levels | change_16_probe (collect) |
| Save migration (no reset, derived bosses_found, upgrades kept, disk round trip) | change_16_probe (migration) |
| Boss warning once, sound, banner order, unlock without a kill, Prestige, Hard Reset | change_16_probe (boss) |
| Names / icons stacking and contrast | change_16_probe (overhead), CAP 02, 03 |
| Trackers together, positions, taps, follow lifecycle | change_16_probe (trackers), CAP 04, 09 |
| 33 followers, collection item and icon | change_16_probe (follower text) |
| Prestige keeps Gems and exploration | change_16_probe, campaign_probe, gameplay_probe |
| Potion 10% → 20%, external HP bonus, no cap | change_16_probe (potion) |
| Drop All, Auto-Collect, exploit loops, credit, save, expiry, UI | change_16_probe (drop), CAP 06, 07 |
| Mastery swap and chip | change_16_probe (mastery), CAP 04 |
| Robot interval | change_16_probe (robot) |
| Skill descriptions | change_16_probe (skills), CAP 06 |
| Prestige confirmation | change_16_probe (confirm), CAP 08 |
| Music | change_16_probe (hold rules), **tests/change_16_audio (windowed, real playback: 11 / 11)**; the old service was reproduced leaving the track paused after 0 → 40% |
| Guided path, View Camp, Help, no development UI | change_16_probe (guide, settings), CAP 01, 05, 10, 11 |

`tests/change_16_probe`: 197 checks, 0 failures. Maintained suite and stale-contract updates: see docs/LootFarmer_Test_Suite.md (Change 16 section). Rendered evidence: `docs/Change_16_Evidence/ui/` (desktop, 540 × 960).

## Open device checks

Readability of the red boss names on every season (contrast against the outline is 4.5:1 or better, checked; against the ground it depends on the map); the 15 px uppercase Winter I objective (three lines in the 230 px column); two trackers plus toast and guide card in the lower half on a 20:9 phone; View Camp following the camp while the camera moves; the Prestige confirmation's length on a small phone (it scrolls); whether the late-map Coin economy now feels too fast; the Collect Batch Gem prices.
