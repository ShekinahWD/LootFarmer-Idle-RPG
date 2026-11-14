# Godot Player Profiles 1.0.0

A reusable, game-independent automated playtesting framework for Godot 4 games. Seven universal player-behaviour
presets play the game's **real** simulation through a small game-specific adapter, on a virtual calendar with sessions,
offline time and persistence. Each run produces a deterministic event log and a stable-schema summary, so the same
seven profiles can be compared across games without redefining them for each project.

- **Canonical source:** `D:\Godot\ReusableKitForNewGames\Godot-Player-Profiles\` (this folder, versioned by `VERSION`,
  `CHANGELOG.md` and `PACKAGE_FILES.sha256`; a zip snapshot `Godot-Player-Profiles_<version>.zip` sits beside it).
- **Install location in a game:** `res://addons/player_profiles/` (pinned by `player_profiles.lock.json` at the project root).
- **Start here when integrating a new game:** [`INTEGRATION_FOR_CLAUDE.md`](INTEGRATION_FOR_CLAUDE.md).
- First integration and regression case: LootFarmer (its integration lives in that game's repository, not here).

## Three layers

| Layer | Lives in | Knows about the game? |
|---|---|---|
| **A. Universal profiles and decision framework** | `core/` (this package) | No. No game mechanic, node path or class is referenced. |
| **B. Capability / intent contract** | `core/adapter_base.gd`, `core/contract_check.gd` | Defines the vocabulary; the game fills it in. |
| **C. Game adapter and strategy** | the game's repository (e.g. `tests/playtest/<game>/`) | Yes. It maps real player actions to intents and owns tactics. |

The rule: **profiles describe tendencies; the adapter describes what is possible and how to do it.** Game tactics (how
to fight a boss, which upgrade helps) never enter a profile; profile values never enter a game's code except through
the resolved profile handed to `adapter.configure()`.

## Package layout

```
addons/player_profiles/
  VERSION  CHANGELOG.md  README.md  INTEGRATION_FOR_CLAUDE.md  PACKAGE_FILES.sha256
  core/framework.gd          versions, the 11 generic intents, stop classes
  core/profiles.json         the seven presets (data) and the documented parameter scale
  core/profile_library.gd    load / validate / override / derive engine values / profile hash
  core/decision_engine.gd    the single universal policy
  core/adapter_base.gd       the contract (player-profiles.contract/1) with "unsupported" defaults
  core/contract_check.gd     adapter and option validation
  core/driver.gd             step loop, active/offline/calendar clocks, sessions, stops, stalls, budgets
  core/session_schedule.gd   seeded virtual-calendar session plans
  core/recorder.gd           events.jsonl (digested) and trace.jsonl
  core/run_session.gd        one complete run -> summary.json (player-profiles.summary/1)
  runner/run_scene.tscn      generic command-line runner (--integration=res://...)
  tools/player_profiles.py   manifest / verify / install / status / isolation / selftest / run / report
  tests/selftest.tscn        the cross-game acceptance test
  tests/fixture/             Farmstead: a tiny NON-combat production/building game + its adapter
```

No `class_name` is declared (no global names to collide with a game's); every internal reference is a relative
`preload`. Nothing is an editor plugin and nothing is autoloaded. The folder must be excluded from release exports
(test-only content).

## The generic intents

`recover`, `claim_rewards`, `progress_main`, `attempt_challenge`, `strengthen`, `improve_economy`, `invest_automation`,
`explore`, `complete_optional`, `collect`, `wait`. A game declares each as supported or unsupported. Unsupported intents
are reported as `unsupported`, never as zero. The engine additionally records `save_for_goal` decisions and session
leave/return events.

## The seven universal profiles

Behaviour (what choices the person tends to make) is separate from the game strategy (how those tendencies become
this game's actions). Traits are normalized 0..1; the session patterns are **editable simulation defaults, not measured
player statistics**.

| Profile | Universal behaviour | Distinctive constraint |
|---|---|---|
| `active` | Plays often and long, decides frequently, explores and progresses, uses the tools available. | Engaged ≠ optimal; no permanent hoarding or aimless grinding. |
| `casual` | Short, intermittent sessions; moderate decisions; understandable goals; spends when the benefit is clear. | Less optimized; interruptions and missed opportunities are plausible. |
| `idle` | Brief, infrequent interaction; prefers passive/automation systems **if offered**. | Without them it is low attention only; never invents passive rewards. |
| `beginner` | New to systems: tentative, slower, less consistent; some understandable mistakes. | Bounded, explainable mistakes that fade with experience. |
| `collector` | Seeks unowned items, discoveries, variety; delays main progression for collection. | Not 100% completion of everything. |
| `speedrunner` | Milestones first; skips optional content; calculated risk; spends to remove bottlenecks. | Not omniscient; failures cost real simulated time. |
| `completionist` | Finishes accessible goals and optional objectives before advancing. | Respects accessibility; gives up unreachable targets (patience). |

Traits:

| trait | active | casual | idle | beginner | collector | speedrunner | completionist |
|---|---|---|---|---|---|---|---|
| attention | 0.9 | 0.5 | 0.15 | 0.45 | 0.65 | 0.95 | 0.7 |
| efficiency | 0.75 | 0.45 | 0.5 | 0.3 | 0.55 | 0.9 | 0.6 |
| exploration | 0.6 | 0.35 | 0.15 | 0.45 | 0.75 | 0.3 | 0.7 |
| main_goal_urgency | 0.7 | 0.5 | 0.35 | 0.45 | 0.35 | 1 | 0.3 |
| risk_tolerance | 0.6 | 0.45 | 0.3 | 0.35 | 0.5 | 0.8 | 0.35 |
| spending | 0.75 | 0.65 | 0.35 | 0.7 | 0.6 | 0.45 | 0.55 |
| preparation | 0.3 | 0.5 | 0.6 | 0.55 | 0.5 | 0.15 | 0.7 |
| side_goal_preference | 0.4 | 0.55 | 0.2 | 0.45 | 0.35 | 0.05 | 0.85 |
| collection_drive | 0.3 | 0.3 | 0.15 | 0.35 | 0.95 | 0.05 | 0.6 |
| completion_drive | 0.25 | 0.3 | 0.1 | 0.3 | 0.35 | 0 | 0.95 |
| automation_preference | 0.5 | 0.45 | 0.95 | 0.3 | 0.4 | 0.45 | 0.45 |
| setback_tolerance | 0.7 | 0.45 | 0.35 | 0.4 | 0.55 | 0.85 | 0.6 |
| revisit_tendency | 0.6 | 0.35 | 0.15 | 0.5 | 0.45 | 0.75 | 0.3 |
| mastery | 0.8 | 0.55 | 0.6 | 0.1 | 0.65 | 0.9 | 0.65 |
| learning_rate | 0.7 | 0.5 | 0.4 | 0.55 | 0.6 | 0.8 | 0.6 |
| mistake_rate | 0.02 | 0.04 | 0.03 | 0.25 | 0.03 | 0.01 | 0.02 |

Derived engine values (formulas in `core/profile_library.gd`; seconds of active time, multiplied by the adapter's
`time_scale()`):

| derived | active | casual | idle | beginner | collector | speedrunner | completionist |
|---|---|---|---|---|---|---|---|
| deliberation every (s) | 2.93 | 13.42 | 50.85 | 16.23 | 7.58 | 2.42 | 6.27 |
| urgent reaction threshold | 0.5 | 0.7 | 0.88 | 0.72 | 0.62 | 0.47 | 0.6 |
| quick actions per pass | 4 | 2 | 2 | 2 | 3 | 5 | 3 |
| switch hysteresis | 0.26 | 0.36 | 0.44 | 0.3 | 0.32 | 0.2 | 0.38 |
| switches per 10 min (limit) | 8 | 6 | 4 | 7 | 7 | 10 | 6 |
| confidence needed for a risky attempt | 0.53 | 0.65 | 0.71 | 0.68 | 0.65 | 0.44 | 0.77 |
| retry cooldown after a failure (s, x failures) | 96 | 126 | 138 | 132 | 114 | 78 | 108 |
| minimum purchase score | 0.2 | 0.22 | 0.32 | 0.21 | 0.24 | 0.29 | 0.26 |
| saves for its top goal | no | no | yes | no | no | yes | no |
| completion patience (s) | 1200 | 1320 | 840 | 1320 | 1440 | 600 | 2880 |
| quick-action pass before leaving | no | no | yes | no | no | no | no |

Default sessions (`sessions` in `profiles.json`; `default_schedule` applies to active-time horizons):
active 55-65 min at 08:00 and 19:00 (continuous by default); casual 16-24 min at 08:30, 13:00 (50%), 20:00; idle 5-10 min at
08:00 and 21:00 (60%); beginner 15-30 min at 12:30 (40%) and 18:30; collector 25-40 min at 09:00 (70%) and 20:00;
speedrunner 60-90 min at 10:00 and 21:00 (80%) (continuous by default); completionist 40-60 min at 09:00 (80%) and 19:00.
For games with very short rounds, override the session block or return a `time_scale()` from the adapter; the
profile identity (traits) does not change.

**Overrides** never edit a preset: `--override=attention=0.3,weight.explore=0.9,derived.instant_budget=6` (traits,
intent weights or derived values). Overrides are part of the profile hash.

## How the engine decides

One engine plays every profile. Every engine tick (`adapter.tick_seconds()`): the current activity and reflexes advance;
an urgent option at or above the reaction threshold interrupts; otherwise it deliberates every `deliberation_s`
(sooner after an activity ends). A deliberation validates options, classifies refusals (`ineligible`, `cooldown`,
`not_ready` = below the confidence needed, `unaffordable`), scores the rest, performs up to N quick actions (a saver
keeps a resource for its top unaffordable goal unless an option is a `bottleneck`) and keeps or switches the
activity under a commitment hold, hysteresis and a switch limit.

```
s  = W[intent] * (0.25 + lerp(0.5, benefit, efficiency))
   + novelty*(0.6*collection_drive + 0.3*exploration) + milestone*0.5*urgency + bottleneck*(0.3 + 0.3*urgency)
s *= optional  ? 0.3 + 0.7*side_goal_preference : 1
s *= advances  ? hold_back : 1         hold_back = (1-0.85*completion*(1-area_completion))*(1-0.6*collection*(1-collection_completion)),
                                       lifted after patience_s without progress
s *= 1 - 0.8*risk*(1 - risk_tolerance)
s *= 1 - unfamiliar_penalty*(1 - familiarity[feature])          unfamiliar_penalty = 0.6*(1-mastery)
s *= 1 - satiation*share[intent]       activities only; share = exponential moving share of recent time (600 s)
s += 2*urgency
s *= 1 + noise*U(-1,1)                 noise = 0.3*(1-efficiency), seeded
W: recover 1, claim_rewards 1, wait 0.05, progress_main 0.3+0.7u, attempt_challenge 0.25+0.45u+0.3r,
   strengthen 0.35+0.35p+0.3e, improve_economy 0.25+0.5e+0.25(1-u), invest_automation 0.1+0.9a,
   explore 0.1+0.9x, complete_optional 0.05+0.95s, collect 0.05+0.95c
```

Ties break by score, then intent order, then option id. **Mistakes** (Beginner mostly): with probability
`mistake_rate*exp(-experience/mistake_decay)` the plausible runner-up (≥ half the best score, never an ineligible,
unaffordable or unready option) is chosen and recorded `mistake: true`. **Learning:** familiarity grows by use and
exposure; failures add caution (`caution_step`) and a cooldown to that option family.

The engine reads only `observe()` and `options()`. It never calls telemetry methods (`progress_signature`,
`game_summary`, `generic_metrics`, `state_digest`, `trace_sample`); the self-test proves this with a spy adapter.

## Runner arguments (`core/run_session.gd options_from_args`)

`--player-profile=<id> --seed=N --output=<abs folder>` and one horizon: `--active-minutes=M` (default 60) |
`--until=calendar --calendar-hours=H [--max-active-minutes=M]` | `--until=<goal> --max-active-minutes=M`.
Schedule: `--schedule=default|continuous|sessions`, `--session-minutes=a-b`, `--slots=8.5,13@0.5,20`,
`--jitter-minutes`, `--min-gap-minutes`, `--grace-seconds`, `--return-mode=cold|warm`. Also `--override=...`,
`--max-wall-seconds=600`, `--stall-minutes=N` (default 30 continuous, record-only with sessions), `--trace`.
The generic runner adds `--integration=res://...`. Result line: `PLAYTEST_RESULT ok=... stop=...`; exit 0 = sound run.

## Outputs

`events.jsonl` (deterministic; its SHA-256 is the events digest), `trace.jsonl` (optional), `summary.json`
(`player-profiles.summary/1`): profile id/version/hash/traits/derived, framework and contract versions, adapter and
strategy versions and capabilities, seed, content fingerprint, **active / offline / calendar seconds kept separate**,
sessions, stops, stalls, `decisions` (by intent, by status, refusals, mistakes, switches, holds, urgent interrupts,
saves, time by intent, familiarity, caution), `generic` (milestones, economy, automation, decisions per hour; `unsupported`
where declared), `game` (the game's own measurements) and volatile `process` facts (excluded from determinism).
`tools/player_profiles.py report --runs <folder>` writes `framework_comparison.md/.csv` with a starting diagnosis
(tool/adapter failure, contract problem, rejected actions, no activity offered, possible gameplay bottleneck).

## Determinism

Three independent seeded streams: the game's own RNG (seeded by the adapter), the schedule (`seed|profile|schedule`)
and the engine (`seed|profile|decisions`). The same seed, game data, profile, overrides and package version replay to
identical events and state digests (volatile wall-clock fields are excluded).

## Validation

`tests/selftest.tscn` (about 15 s): presets, overrides and hashing; contract validation including malformed options
and invalid actions; no-telemetry spy; all seven profiles on Farmstead in two capability models (`full` with
automation and offline production, `plain` with neither) at equal active exposure; same-state different choices;
deterministic replay; sessions with cold and warm returns and offline settlement; failures, cooldowns, commitments.
`python tools/player_profiles.py selftest --blank --godot <exe>` runs it in an empty project containing only this
package. **A fixture proves interface flexibility, not the integration of any real shipped game.**

## Limitations

- Profiles are behavioural tendencies, not player populations; results say nothing about UI comprehension or fun.
- Benefit, confidence and risk signals are the adapter's estimates. Their quality decides how sensible a profile
  looks in a game; review them like game code, and list any oracle limitation (estimates a real player could not make).
- Real-time steering, combat micro-play and input timing belong to the game's tactics, not to the engine.
- Long horizons are slow in heavy games; run them sequentially and outside the gating suite.
