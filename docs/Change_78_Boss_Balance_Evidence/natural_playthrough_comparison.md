# Player-profile comparison: batch `c78boss`

Objective measurements recorded by the game during natural fresh-save playthroughs. One row per run; aggregate rows give the median and range across seeds of the same bot policy and are not a distribution of real players. `not_measured` means the run did not reach or record that value.

Game commit `8f110ef3e5f00f557e0346d7eac53f17edd0c0fd` with uncommitted tracked changes: data/game/catalog.json, docs/LootFarmer_Test_Suite.md, localization/de_DE.po, localization/en.po, localization/es_419.po, localization/es_ES.po, localization/fr_FR.po, localization/pt_BR.po, scripts/game/campaign.gd, scripts/game/game_ui.gd, scripts/game/simulation.gd, scripts/game/supply_fx.gd, scripts/game/world.gd, tests/change_52_probe.gd, tools/localization_pending.json, tools/run_probes.py.
Content fingerprint `b2c5758d88dde541`.

| profile | policy_version | seed | label | actual_active_hours | stop_reason | final_map | highest_stage_unlocked | player_level | first_boss_time_min | first_prestige_ready_time_min | first_prestige_completed_time_min | prestiges | deaths | boss_attempts | boss_wins | kills | upgrades_bought | coins_earned | coins_spent | gems_earned | gems_spent | longest_stall_minutes | wall_seconds | speed_x |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| active | active-1 | 1 | long | 5.0 | duration_reached | 4 | 4 | 55 | 9.08 | 9.08 | 9.14 | 4 | 2 | 11 | 11 | 4666 | 93 | 34216.24 | 6781.0 | 322.0 | 210.0 | 2.88 | 500.22 | 36.0 |
| active | active-1 | 2 | long | 5.0 | duration_reached | 4 | 4 | 56 | 11.98 | 11.98 | 12.05 | 6 | 0 | 15 | 15 | 4239 | 93 | 35231.38 | 6981.0 | 300.0 | 210.0 | 5.73 | 648.52 | 27.8 |
| active | active-1 | median[min..max] of seeds 1,2 | long | not_measured | duration_reached | not_measured | not_measured | 55.5 [55..56] | 10.53 [9.08..11.98] | 10.53 [9.08..11.98] | 10.595 [9.14..12.05] | not_measured | 1 [0..2] | not_measured | not_measured | 4452.5 [4239..4666] | 93 [93..93] | 34723.8 [34216.2..35231.4] | 6881 [6781..6981] | 311 [300..322] | 210 [210..210] | 4.305 [2.88..5.73] | 574.37 [500.22..648.52] | 31.9 [27.8..36] |

## Gear at the end of each run

| run | gear (weapon ^merge tier | outfit ^merge tier) | cards | evidence |
|---|---|---|---|
| active s1 long | diamond_sword^2 T5 | unit-straw-hat_outfit_t2^236 T2 | hunter_c1 specialist_c1 arsenal_c2 masterwork_c1 masterwork_c2 trophy_c2 challenge_c1 | `tests/tmp/player_profiles/c78boss/active_s1_long/summary.json` |
| active s2 long | gold_sword^20 T4 | unit-cowboy-bandana_outfit_t2^132 T2 | hunter_c1 specialist_c1 trophy_c2 arsenal_c2 masterwork_c1 masterwork_c2 challenge_c1 | `tests/tmp/player_profiles/c78boss/active_s2_long/summary.json` |

All columns, including digests, are in `comparison.csv`.
