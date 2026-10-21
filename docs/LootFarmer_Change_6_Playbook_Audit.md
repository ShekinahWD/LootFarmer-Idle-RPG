# LootFarmer — Playbook audit — Change 6

Based on the complete current reusable file (sections 0–137 plus the Change 6 additions in 3.5, 14.4, 16.3, 87.7, 110, 112 and 117.9), the current source and the Change 6 evidence. Every section was re-read; the table lists each section Change 6 changed or re-verified, with the implementation and evidence type (S = source inspection, A = automated probe, R = rendered capture, B = pacing bot, D = physical device). Sections not listed keep their Change 5 disposition in LootFarmer_Change_5_Playbook_Audit.md unchanged (worker, city-builder, army, store and video sections remain not applicable or release gates for the reasons given there). No physical-device evidence (D) exists for this change.

| § | Topic | Change 6 disposition | Evidence |
|---:|---|---|---|
| 3 / 3.5 | Progression layers; progress toward prestige | Prestige now requires a run milestone (Winter cleared). Discovery/readiness stay early; the panel states the gate and shows readiness/card counts. New reusable rule added in 3.5. | A (gate vs four early routes), B (fastest first gate 76.3 min; ordinary 92–113), R |
| 5 | Introduce archetypes one at a time | Unchanged order (passive → proximity → assistance), now spatially ordered too: weakest type nearest arrival, bosses farthest on every stage. | A (all 8 stages), R (stage layouts) |
| 6 | Stage scaling and base stats | Enemy formula gained an early ramp that plateaus at L40; boss multipliers retuned; constants live in the catalog and a tool applies them. | S, A (tune --check), B |
| 7 | Percentage-aware support | Heal 10 HP (12% cap) vs potion 25 HP with 5 s cooldown; out-of-combat rest added so Heal is in-combat sustain only. | A (role ratio all tiers), B |
| 13 | Feedback for automated action | Floating numbers outlined, spread, sign/glyph semantics (−, +, !). | R |
| 14 | Mobile UI | 76 px minimum actions in the pinned bar and dock; captures at 9:16 and ≈20:9 windows that fit the monitor. Reusable rule 14.4 (encounter spacing from targeting) added. | R, A |
| 16 | Management surfaces | One job per surface: World (camps, map, travel), Missions, Prestige, Stats, Settings; player upgrades on the character tap (v0.4 decision kept). Panels content-sized, bottom-anchored, pinned actions, scroll only on overflow, in-place value refresh (16.3 lesson added). | A (height, anchoring, identity, no resize on reason), R |
| 17 | Effective stats | Item details show the exact equip delta from the gameplay stat getter (`stats_with`). | A, R |
| 18 | Teaching | State-driven route with sub-steps (HUD → tab → button), owned arrow pointer and frame on the live control, scroll-into-view after the claim, attainable alternatives (explore / earn N coins), suspension by unrelated panels, confirmations, pause, prestige choice and celebrations; no input taken. Basic and None kept. | A (camp route, suspension, ahead-of-tutorial, no-input), R (17 lesson frames) |
| 19 / 20 | Do not shrink UI; modal sizing | Item details fixed by removing a 500 px flow artifact and content sizing, not by smaller fonts; confirmation sized width-first to its text. | R, A |
| 21 | Badges | Green ! for claimable missions and ready prestige, gold ✦ for unseen discoveries. | R |
| 22 / 63 | Pixel-art assets; registry | Only owned art: PixelPlains arrow/star/sparks/path icons (cropped), Kenney panel-011 and border-011, existing prestige sound. Registry updated. | S, R |
| 26 | Pause and modal state | Banner and guide hold under pause/panels/confirmations; batch choice controls exempt from their own lock (bug found and fixed; 110 lesson). | A |
| 27 / 29 / 61 | Reset, save, compatibility | Fog layout revision 2 resets discovery once; saved actors re-homed; hard-coded revision bug fixed; current saves reload without Hard Reset. | A (disk roundtrip, old-revision load stays writable) |
| 41–43 / 59 / 60 | Probes and validation | New change_6_probe (196 checks), pacing bot, capture/timing fixture, extended static validator; stale probe expectations updated only where the contract changed (Heal value, challenge boss). | A |
| 48 | Android performance | Measured and fixed the Upgrades stall (structure-preserving refresh, explicit-property sync, 0.25 s refresh cap) and the per-tick enemy-definition deep copies. Desktop only. | A/timing (desktop), no D |
| 54 | Rare content identity | Bosses in their own landmark arenas at the far end of each stage. | R |
| 56 | UI consistency audit | Panel coverage matrix below; all surfaces captured in at least one state, many in several. | R |
| 66 / 70 | Asset classification; one panel family | Kenney nine-slices; Card, Backing, Primary and PrestigeCard variations of one family. | R |
| 67 | Editor-visible composition | New prestige_card.tscn and milestone_banner.tscn are editor scenes; dynamic lists remain code-built rows. | S |
| 76 | Idempotent tweens | Banner tween killed before restart; no structural scale punches. | S |
| 81 | Name upgrades by what they modify | Five labels corrected to the implemented effect (loot +1 point, collect +50, intervals −1 s, coins +50%). | S, R |
| 87.7 | Validate the rendered image | Monitor-clamped capture found and fixed; lesson added. | R |
| 92 | Sources and sinks as one economy | Enemy curve, boss multipliers, recovery, potion cooldown and card values tuned together and measured by bot; mission/late economy not re-measured. | B |
| 96 / 97 / 108 | Documentation sync; reusable lessons | GDD, Content and Balance, Prestige Catalog (generated), State Contracts, Asset Registry, status docs updated; seven lessons added to owning sections. | S |
| 110 | Irreversible transitions | Celebrations fire after the durable save; batch lock no longer blocks Keep. | A |
| 112 | Pacing bots | Implemented: tests/pacing_bot.gd with ordinary/rush/expert policies, seeds, card comparisons; two bot artifacts found and documented. | B |
| 117.9 / 124.12 / 127.6 | Fog | Discovery-only mode unchanged; layout revision bump for moved sites; regional 90% unit bug fixed; markers still only at discovered sites; the guide never points at undiscovered camps. | A |
| 121 / 122 | Touch arbitration; picking | Camp tap opens a panel with separate Unlock / Respawn here / Travel actions (no silent selection). Gesture code unchanged; no device test. | A, no D |
| 123 | Contextual panels | Structure key (panel context) plus in-place value sync; reason in a fixed status line; buttons keep identity. | A |
| 124.7 | Toasts | Queued (max 4), deduplicated, shorter hold when busy, dark backing, placed in the map's free band, never over an open panel (panel notice line instead). | A, R |
| 125 | World readability | Outlines on numbers, labels and camp names; spark celebration readable on snow. | R |
| 128 / 129 | Card anatomy; controls | Computed values large, one support line, fixed status rows, one primary action place, previous/next arrows in the pinned bar, prestige cards selected then kept with confirmation. | A, R |
| 132 | Localization | All new strings are English PO keys; static check covers dynamic guide/combo/tab keys. 19 locales still outstanding. | A |
| 136 / 137 | Whole-project review | This document, the validation report and coverage matrix; gaps listed below. | S |

## Panel and system coverage matrix

| Surface | Issue found | Decision | Implementation | Evidence | Remaining limitation |
|---|---|---|---|---|---|
| Main HUD | Loot history numbers, zoom value and type label unreadable on snow; dead Hint/Status nodes updated every tick | Dark backing and outlines; remove dead nodes | game_ui.gd, main.tscn | R 01–02, 17 | Phone readability not verified on device |
| Navigation | Six pages hidden inside "World"; prestige/missions not reachable from the dock | Five icon buttons with badges | main.tscn Navigation | R all | Icons are item art, not dedicated UI glyphs |
| Inventory dock | Slot styles duplicated every revision | Cached tier styles, per-slot change signature | `_refresh_slots` | A (timing) | — |
| Item details | ~60% wasted height; no comparison; no browsing | Content-sized sheet, equip delta, ◀ ▶ in pinned bar, no wrap at ends, neighbour shown when item runs out, actions guarded by the shown id | `_item_panel`, `_browse` | A (8 checks), R 07–08, 29 | — |
| Player upgrades | 82 ms per refresh, refreshed every revision | In-place sync, 0.25 s cap; compact one-row cards | `_group_upgrade_card`, `_sync_panel_children` | A, timing | Device frame time unmeasured |
| Enemy panel / upgrades | Gem automation first; locked sub-upgrades shown; 392 ms first frame | Rewards first, automation refinements after unlock | `_enemy_panel` | R 10–11, 24, timing | — |
| Achievements | Large cards for one number each | One line per milestone with bar | `_group_achievements_panel` | S | — |
| Missions | Tall info cards | Compact task cards with bar, rewards, claim | `_task_card` | R 22 | 15–60 min mission pacing not re-measured |
| World / camps / travel | Camp purchase buried below navigation; buy also selected | Camps first; Unlock, Respawn here, Travel separate | `_world_panel`, `_camp_row` | A (route), R 14–15 | — |
| Minimap / expanded map | — (unchanged contract) | Kept; embedded in World | map_view.gd | R 14 | — |
| Skills / supplies | Heal negligible, potions chainable | Heal 10, potion cooldown 5 s, rest out of combat | catalog, simulation | A, B | Late-tier skill balance not measured |
| Prestige / cards | Text buttons; tiny/duplicate rewards; no gate; Keep blocked by lock | Visual cards, retuned values, gate, keep/reset summary | `_prestige_panel`, prestige_card.tscn | A, R 19–21, B | Long-term card stacking unmeasured beyond single cards |
| Celebrations | Plain text toast for discovery | Queued banner with star/sparks/sound after commit; persistent badge | milestone_banner.tscn | R 18 | No reduced-motion setting exists to honour |
| Stats | Long label list | Two-column effective stats, sources one line each, link to upgrades | `_stats_panel` | S | — |
| Settings / reset | Mixed list | Grouped actions, language, danger zone with confirmation | `_settings_panel` | R 25 | — |
| Tutorial | Lost after opening World; outline only | Full state-driven route with pointer | tutorial_guide.gd | A, R 01–16 | Real-touch walkthrough on a phone not performed |
| Notifications | White on snow; over panels | Backing, queue, panel notice line | `_update_toast` | A, R 17 | — |
| Offline receipt | In World list | Upgrades → Offline tab | `_upgrades_panel` | S | Not re-captured |
| Death / respawn | Only recovery was dying | Rest recovery; HP bar shows "Resting" | simulation, HUD | A, R | — |
