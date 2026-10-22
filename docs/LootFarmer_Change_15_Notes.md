# LootFarmer — Change 15 Notes

Baseline: Change 14 (`3ea93cb`, tests/docs `0999c15`). Design: the approved Change 15 evaluation (early equipment guarantee, progressive menu reveal for Guided / Basic / None, notification sounds, Map Mastery). This is the final major gameplay addition before release preparation.

Build commits: `416c579` (implementation) and `e52054a` (fixes found by the tests: the World map's player dot, the guarantee latch at pickup, the audio hint text). **Build from `e52054a` or later.** The tests/docs commit after it does not change the game.

## What changed

| # | Area | Change | Where |
|---|---|---|---|
| 1 | Early equipment guarantee | Two merge-compatible items within 10 eligible normal kills, whichever Winter I enemy is farmed: the first weapon or outfit by the 5th kill (weapon first), a matching copy by the 5th kill after it (a copy of an owned item the enemy carries, else two copies of its own item, else a copy of an owned item when the row is full). Natural drops count first and restart the count; supplies and non-matching gear never satisfy it; expired drops are replaced on the next eligible kill. Once per profile, every mode; drop chances unchanged. | `scripts/game/onboarding.gd` (`loot_kill`, `loot_state`), `simulation._reward`, `resources/game/onboarding_rules.tres` |
| 2 | Menu reveal | One reveal table for all modes: Missions → enemy information/upgrades → World, minimap and camps → Player Upgrades and Filters → Defeat the Snowman objective → (Snowman) Prestige, Map Mastery and the rest. Demonstrated actions with player-level backstops (3/4/5/6/7), never timers; a full equipment row reveals up to Upgrades. Latched in `state.onboarding.reveal`. Hidden navigation buttons keep their place (invisible, untouchable); `_open` refuses hidden panels from every path; ✦ on a newly revealed menu until opened. Settings → Tutorial and help → Show all menus now. | `onboarding.gd` (`evaluate`, `reveal_all`), `game_ui` (`panel_allowed`, `_refresh_reveal`, `_refresh_badges`, `_settings_panel`) |
| 3 | Guided / Basic / None | Guided: pointer lessons for each revealed system (claim, Loot Chance, camp, slot or potion, Snowman objective, Prestige Follow). Basic: concrete opening card, equip/merge tips, one card per revealed system, retiring after 20 s or Got it. None: no guide; badges, objectives and milestone banners only. MAIN_4 is "Defeat the Snowman · unlocks Winter II and Prestige". | `tutorial_guide.gd` (`LESSONS`, `LESSON_FEATURE`, `_basic_card`), `en.po` |
| 4 | Notification sounds | `mission_ready.wav` for mission/main-objective ready, Prestige discovered/ready, followed step, feature unlocked, Mastery category and map. `stage_clear` for a new map and 100% completion; `prestige` for the reset. Cues sharing a stream share its cooldown. `reveal_unlock.wav` is no longer used. | `resources/game/audio_cues.tres`, `audio_service.flush` |
| 5 | Map Mastery | Five categories per map (Explore, Hunt, Research, Collect, Forge), permanent records and latches, per-map and game percent, rewards through `campaign.bonus`, World → Map Mastery panel and map pages, Stats lines. | `scripts/game/mastery.gd`, `resources/game/mastery_rules.tres`, `game_ui._mastery_panel`, `_mastery_map` |
| 6 | Reachable exploration | Explored percent excludes four unreachable Summer II cells (inside solid scenery). | `fog_rules.tres unreachable_cells`, `campaign.explored_fraction`, `compute_unreachable_cells`, `tools/fog_reachability.gd` |
| 7 | Save | Schema 8 (onboarding and mastery records); schema 7 development saves reset. | `simulation`, `campaign.valid_snapshot` |

## Adjustments to the approved design

- **Navigation buttons keep their slot** while hidden (transparent and untouchable) instead of collapsing, so Settings does not move and each button appears where it will stay.
- **The guarantee's fallback** when the farmed enemy carries nothing the player owns drops two copies of that enemy's own item (weapon first), so the pair never depends on which Winter I type is farmed. With a full equipment row it drops a copy of an owned item instead (no slot needed).
- **Guided's Player Upgrades lesson** buys an equipment slot when the Gems allow it (5 Gems, covered by the first objectives), otherwise a Health Potion (10 coins).
- **Probe fixtures:** suite probes of ordinary play run with `--first-run-complete` (every menu revealed, guarantee spent; Playbook 18.10). The Change 15 probes run without it.

## Fixes found by the tests (`e52054a`)

- **World map player dot (existing bug, surfaced by the suite):** the panel reconciler rebuilds off-tree descriptions and reconciles their children into the live panel. The World map adds its player dot in `_ready`, which an off-tree description never runs, so an in-place refresh of the open World panel deleted the live dot; `map_view` then errored every frame and the dot vanished. Controls that build their own children now carry `own_children` and are reconciled by properties only.
- **Guarantee latch:** the guarantee was marked done at the next eligible kill after the pair was picked up; it now ends at the pickup (and on the one-second tick). No drop changed.
- **Audio hint:** the Settings line under the mutes lists the Change 15 notification sounds.

## Tests

| Claim | Static / headless | Rendered on desktop | Needs a phone |
|---|---|---|---|
| Guarantee within 5 + 5 kills, any Winter I type, every mode | change_15_probe (36 seeded runs, exact kills 5/10 for all 9 type/loadout pairs, edge cases) | — | Feel of the first minutes |
| Reveal chain, backstops, unexpected orders, persistence | change_15_probe | CAP 01, 02, 06 | Button appearance |
| Guided / Basic / None | change_15_probe | CAP 03, 04 | Arrow and card legibility, 20 s timing |
| Notification sounds | change_15_probe (routing, streams, cooldown, mutes) | — | Mix and frequency |
| Map Mastery records, latches, rewards once, Prestige | change_15_probe | CAP 07–10 | Panel length, thresholds |
| 100% exploration reachable | change_15_probe (walks every reachable point of all eight maps to 100%), tools/fog_reachability.gd | — | — |

- `tests/change_15_probe`: 177 checks, 0 failures. Maintained suite: **24 / 24**. Source validator: 1,443 checks.
- `tests/change_15_capture` (desktop renders, `docs/Change_15_Evidence/ui/`): 01 fresh HUD, 02 Missions revealed with ✦, 03 Basic card, 04 Guided Snowman objective, 05 Settings → Tutorial and help, 06 Prestige unlocked banner, 07 World with Map Mastery, 08 Map Mastery list, 09 Winter I page, 10 Stats.
- Category totals per map (Explore, Hunt, Research, Collect, Forge): Winter I 3/4/8/7/5, Winter II 4/7/14/11/8, Summer I 4/4/8/10/5, Summer II 4/8/16/14/9, Autumn I 4/5/10/12/6, Autumn II 4/6/12/13/7, Spring I 4/5/10/13/6, Spring II 4/9/18/18/10.

## Open device checks

Readability of the ✦ badges and the faded navigation slots; Basic card timing (20 s); the Guided Snowman card pointing at the Next Stage chip; Map Mastery panel length on a phone; whether Mastery thresholds feel achievable; the shared mission-ready sound frequency.
