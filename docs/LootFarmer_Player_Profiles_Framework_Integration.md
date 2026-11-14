# LootFarmer — Reusable Player Profiles Framework: audit, architecture, migration and validation

Date: 14 November 2026. Brief: `docs/Godot_Reusable_Player_Profiles_Framework.md`. Starting point: commit `41eef3d`
(Phase 2), developer's uncommitted version-42 edits in `project.godot` / `export_presets.cfg` left untouched and
uncommitted. No gameplay, balance, save schema, store version or player save was changed.

## 1. Audit of Phases 1 and 2

| Code (at 41eef3d) | Classification | Problem for reuse |
|---|---|---|
| `tests/playtest/playtest_driver.gd`, `playtest_recorder.gd`, `session_schedule.gd` | game-independent framework | Sound; one LootFarmer leak in the driver: the stop name `first_prestige_completed` |
| `tests/playtest/lootfarmer_adapter.gd` | LootFarmer runtime adapter (actions, observations, evidence) | Sound; game-specific by design |
| `tests/playtest/policies/active_policy.gd` (`active-1`) | **mixed**: universal behaviour (cadence, risk margins, spending style) hard-coded together with LootFarmer tactics (movement, boss attempt, exploration, estimates) | Behaviour cannot be reused without the game |
| `policies/profile_policy.gd`, `casual_policy.gd`, `idle_policy.gd` | profile behaviour **as a subclass of `active_policy.gd`**, with per-profile LootFarmer wish lists | The cross-layer dependency the brief names: Casual and Idle inherit Active's code and know LootFarmer upgrade ids |
| `tests/playtest/profiles.json` | registry of policy scripts | Profiles defined by script paths, not behaviour data |
| `tools/player_profile_run.py` | runner + LootFarmer reports | Reusable process control; reports LootFarmer-only |

Known Phase 1/2 policy defects (kept visible in the legacy set): P1 exploration bursts ended on any aggro (map 4/5
bosses never found by Active); P2 Active spent about 6% of its Coins.

## 2. Architecture now

```
addons/player_profiles/              (package 1.0.0; canonical copy in D:\Godot\ReusableKitForNewGames\Godot-Player-Profiles\)
  core/profiles.json                 A. seven universal presets (data)
  core/profile_library.gd            A. overrides, derived values, profile hash
  core/decision_engine.gd            A. the one universal policy
  core/driver.gd recorder.gd session_schedule.gd run_session.gd    A. framework (from Phase 1/2, generalized)
  core/adapter_base.gd contract_check.gd                            B. capability/intent contract
  runner/, tools/, tests/ (Farmstead fixture + self-test)
tests/playtest/lootfarmer/           C. LootFarmer integration
  lf_adapter.gd                      intent mapping, player-observable signals, Prestige card choice by intent weights
  lf_tactics.gd                      farming, exploration, boss attempt, rest, reflexes (parameters from traits)
  lf_integration.gd                  probe-pp-* isolation, simulation creation, fingerprint, cleanup
tests/playtest/lootfarmer_adapter.gd runtime layer, unchanged, used by both policy sets
tests/playtest/policies/, profiles.json, playtest_driver.gd, playtest_recorder.gd, session_schedule.gd
                                     legacy policy set, unchanged (byte-identical): the historical baseline
```

Dependency breaks made:
1. No profile inherits another profile or any game code: the seven profiles are data; one engine plays all of them.
2. The engine reads only `observe()` / `options()`; telemetry is report-only (proved by a spy adapter in the self-test).
3. LootFarmer tactics no longer contain profile constants: rest/potion/loot/cast/explore parameters derive from traits.
4. Upgrade and card knowledge moved from profile wish lists into the adapter as intent mappings with benefit priors.
5. The core lost its only game term (`first_prestige_completed` → generic `goal_reached`).
6. The package declares no `class_name`, references nothing outside itself (isolation scan: 0 problems) and runs its
   self-test in an empty project containing only the package.

## 3. LootFarmer mapping (summary; full table in `lf_adapter.gd`)

claim_rewards: missions, main objectives, hunt, offline receipt · recover: rest (urgency from HP), walk away from an
unchosen boss · progress_main: travel to the next map, Prestige · attempt_challenge: the gate boss (confidence from the
survival estimate incl. potions) · strengthen: XP farming, best gear pair, merge, evolve, skills, XP/crit/slot upgrades,
potions for a boss · improve_economy: Loot/Coin/Gem/Movement/Respawn/spawn upgrades, camps · invest_automation: Focused
Farming, Auto-Collect/Merge/Use/Buy, automatic skills, Auto-Claim, Merge All, Offline upgrades, switching them on ·
explore: bursts, Map Details and reveal upgrades · complete_optional: daily "defeat" mission targets, next kill
achievement · collect: farming types that drop unowned gear · wait.

Bottleneck signals a player can see: a refused pickup (slot), potions that would make the boss beatable, "the found
gate boss is not beatable yet" (marks XP/crit upgrades and the best XP farms), nothing farmable or the gate boss
not found (exploration).

**Oracle limitations (explicit):** combat estimates read enemy HP/damage/defense and loot lists from the catalog even
before Reveal Stats / Reveal Drops are bought. Everything else (fog, discovered spots, found bosses, prices, refusal
reasons) is what the screen shows.

LootFarmer-specific tactic changes versus `active-1` (so framework and legacy numbers are **not comparable** as the
same policy): exploration fights an ambush and continues (fixes P1); the XP estimate weights raw XP/s by sustainability
margin/(margin+1); a boss attempt is a commitment not interrupted by resting (as in active-1); spending is decided by the
engine (fixes P2: 81-100% of Coins spent); Prestige timing and cards come from profile weights (no fixed 30-minute gap).

## 4. Results

Commands, all sequential, one Godot process at a time. Outputs in `tests/tmp/player_profiles/` (ignored).

**Equal active exposure** — `python tools/player_profile_run.py run --batch pp-framework-v1 --player-profile active,casual,idle,beginner,collector,speedrunner,completionist --seeds 1,2,3 --active-minutes 30 --schedule continuous`
(21 runs, 21 sound, about 10 minutes wall). Medians over seeds 1-3, 30 active minutes each:

| profile | first boss (active min) | boss wins/attempts | deaths | Coins spent | gear identities | map explored | deliberations / active h | mistakes | automation levels | time collecting | time on optional | time exploring |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| active | 11.4 | 6/6 | 0 | 97% | 2 | 83% | 1230 | 2 | 1 | 0% | 0% | 11% |
| casual | 14.5 | 6/6 | 0 | 99% | 4 | 72% | 288 | 1 | 0 | 0% | 0% | 15% |
| idle | 29.3 (1 of 3 seeds) | 1/1 | 0 | 97% | 3 | 64% | 80 | 1 | 11 | 0% | 0% | 4% |
| beginner | 15.8 | 5/5 | 0 | 98% | 5 | 67% | 236 | 8 | 0 | 12% | 0% | 11% |
| collector | 15.6 | 6/6 | 0 | 99% | 6 | 49% | 484 | 2 | 0 | 48% | 0% | 13% |
| speedrunner | 8.9 | 6/6 | 0 | 95% | 4 | 32% | 1504 | 0 | 1 | 0% | 0% | 7% |
| completionist | 28.5 | 4/4 | 0 | 99% | 0 | 88% | 574 | 0 | 2 | 15% | 12% | 6% |

**Equal calendar time** — `... --seeds 1 --until calendar --calendar-hours 24 --max-wall-seconds 1800` (7 runs, 7 sound, about 12 minutes wall):

| profile | active h | offline h | sessions | level | highest map | Prestiges | first boss (active min / calendar h) | offline claims | offline Coins claimed | automation levels |
|---|---|---|---|---|---|---|---|---|---|---|
| active | 2.20 | 21.8 | 3 | 32 | 3 | 4 | 10.0 / 0.2 | 2 | 3600 | 12 |
| casual | 0.97 | 23.0 | 3 | 21 | 2 | 1 | 13.2 / 0.2 | 2 | 1997 | 4 |
| idle | 0.32 | 23.7 | 2 | 13 | 1 | 0 | not reached | 1 | 900 | 8 |
| beginner | 0.82 | 23.2 | 2 | 20 | 2 | 1 | 14.1 / 0.2 | 1 | 600 | 3 |
| collector | 1.45 | 22.6 | 3 | 24 | 2 | 3 | 16.4 / 0.3 | 2 | 719 | 3 |
| speedrunner | 3.69 | 20.3 | 3 | 49 | 4 | 5 | 8.9 / 0.1 | 2 | 2017 | 5 |
| completionist | 1.59 | 22.4 | 2 | 26 | 3 | 3 | 23.7 / 0.4 | 1 | 1200 | 3 |

Read the two tables together: the calendar table gives each profile the same day but very different play time.
Idle again has no boss win in 24 calendar hours with 19 active minutes (Phase 2 finding G1, now from a profile that
no longer shares Active's code): a candidate gameplay bottleneck for very low-attention players, not a policy defect
(diagnosis column: no stall signal; it simply plays little). Single-seed calendar rows are smoke evidence, not medians.

**Determinism** — `determinism --batch pp-framework-det --player-profile beginner --seeds 2 --until calendar --calendar-hours 12`:
996 = 996 events, events and state digests identical across sessions, cold reloads and offline settlement.

**Legacy baseline** — `run --batch pp-legacy-check --player-profile active --seeds 1 --active-minutes 60 --policy-set legacy`
reproduces the Phase 2 evidence `phase2/active_s1_60m` exactly: policy hash `0d7d1913…`, events `590fb131…`, state
`403db944…`, content fingerprint `bbd3a5de…`.

**Cross-game fixture** — `addons/player_profiles/tests/selftest.tscn`: 387/387 checks in about 13 s, in this project
and in an empty project containing only the package (`tools/player_profiles.py selftest --blank`). Farmstead has no
combat, health, loot or resets; its `plain` model also has no automation or offline rewards. All seven unchanged
profiles run in both models; unsupported intents are reported as `unsupported`; Idle in `plain` makes no automation
decisions and receives nothing while away. A fixture proves interface flexibility, not another shipped game's integration.

**LootFarmer framework probe** — `tests/player_profiles_framework_probe.tscn`: 64/64 checks in about 33 s.

## 5. Shared kit and versioning

- Canonical package: `D:\Godot\ReusableKitForNewGames\Godot-Player-Profiles\` (new folder; existing kit contents untouched),
  `VERSION` 1.0.0, `PACKAGE_FILES.sha256`, plus the snapshot `D:\Godot\ReusableKitForNewGames\Godot-Player-Profiles_1.0.0.zip`.
  The kit folder is **not** a Git repository, so the LootFarmer commit holds the tracked copy: `addons/player_profiles/`
  plus `player_profiles.lock.json` (sha256 per file). `tools/player_profiles.py status --project . --source <kit>` proves
  installed == lock == kit.
- Not done, by design: the shared Playbook. The repository's `docs/Reusable_Game_Development_Playbook.md` is a regular
  tracked file that differs from the master `D:\Godot\ReusableKitForNewGames\Reusable_Game_Development_Playbook.md`
  (the 0.2.6 symlink migration has not been performed here), so neither copy was edited. `New_Game_Project_Startup_Prompt.md`
  was not edited either.

**Proposed Playbook addition (for the master, after review):** *Automated player-profile playtesting.* Install the
pinned Godot Player Profiles package instead of writing per-game bots. Profiles are fixed behaviour data; a game
contributes only an adapter that maps its legal actions to the generic intents with player-observable signals, and
declares unsupported mechanics instead of faking them. Validate contract, determinism and sessions before comparing
profiles; keep active, offline and calendar time separate; classify a stall as tool, adapter signal, policy behaviour
or gameplay bottleneck before proposing a game change; list oracle limitations. Long runs stay outside the gating suite.

## 6. Limitations

- Behaviour presets, not populations; nothing here measures UI comprehension or fun.
- LootFarmer signals are hand-written estimates (benefit priors per upgrade, boss confidence mapping). They decide how
  sensible each profile looks; they were tuned only to remove artificial stalls (boss attempts aborted by resting,
  farming that ignored rest downtime, saving with no visible bottleneck), never to manufacture wins.
- Completionist's area completion uses explored share, first kill achievement per normal type and loot identities;
  other optional content (Map Mastery, collections contracts) is not modelled. Collector does not keep copies for
  collection contracts.
- Beginner's mistakes are runner-up choices and unfamiliar-feature avoidance; it does not model misreading the UI.
- Seven-day horizons were not re-run for the framework profiles in this batch (Phase 2 took about 2.5 h).
- New scripts have no `.gd.uid` files yet; Godot creates them on the next editor open (the editor was deliberately not
  run here because it has rewritten `export_presets.cfg` before).
