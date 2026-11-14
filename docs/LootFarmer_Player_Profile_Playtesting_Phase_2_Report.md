# LootFarmer Player-Profile Playtesting: Phase 2 Report

Date: 2026-11-14. Game: Change 79 (`c050d99`), game version and Android version code 41 unchanged.
Batch: `tests/tmp/player_profiles/phase2/` (generated reports: `profile_comparison.md`, `findings.md`,
`comparison.md`, `measurements.md`). How to run and extend the system: `docs/LootFarmer_Player_Profile_Playtesting.md`.

This report keeps **measurements** (what the bots did in the real game, with numbers) apart from
**interpretations** (what that may mean). Bots measure progression, spending, timing and failure. They cannot
measure enjoyment, frustration, UI comprehension or whether a real player would notice an opportunity.
Three seeds per profile and horizon are three bot runs, not a population of players.

---

## 1. What Phase 2 added

| Part | File | What it does |
|---|---|---|
| Session schedule | `tests/playtest/session_schedule.gd` (new) | Deterministic calendar of play sessions per seed and profile: session length range, daily slots with a probability, start jitter, minimum gap, end grace, cold or warm return. Has its own random stream, so it never shifts the game's RNG. |
| Driver | `tests/playtest/playtest_driver.gd` | Optional schedule. At the end of a session it lets the policy finish (no boss fight or Prestige in progress), then leaves the game, advances only the virtual clock by the absence, and returns. Tracks active, offline and calendar time separately. New stop `calendar_reached`; horizons `duration`, `calendar`, `first-prestige`. Without a schedule the loop is exactly Phase 1. |
| Adapter | `tests/playtest/lootfarmer_adapter.gd` | Leave = the real pause notice (saves and stamps the offline snapshot). Return = a cold load of the isolated save (`SaveService.load_and_apply`, the same path a relaunch takes) or a warm resume notice. The game settles the absence with its own rules (cap, rates, Offline Skills, only owned item identities). The adapter checks that the save restored the same progression it left with, then records the settlement. Claims go through `campaign.claim_offline()`. Also: offline accounting, milestone clock (active and calendar), daily mission roll-over, automation purchase times, savings goals (want/close with a lapse rule), and new actions for Merge All, Auto Use, Auto Buy, automatic skills and mission Auto-Claim. |
| Policies | `tests/playtest/policies/profile_policy.gd`, `casual_policy.gd`, `idle_policy.gd` (new) | Casual (`casual-1`) and Idle (`idle-1`). Both extend the frozen Active policy and only change decisions: attention, spending plan, resting, boss readiness, exploration, Prestige timing. |
| Profiles | `tests/playtest/profiles.json` (new) | Registry: policy file plus default schedule per profile. Active stays continuous by default and has a `calendar` schedule for calendar horizons. |
| Runner | `tests/playtest/player_profile_run.gd`, `tools/player_profile_run.py` | Several profiles in one command, run one after another. Calendar and first-Prestige horizons, schedule overrides from the command line, summary schema 2, and four reports (comparison, profile comparison, findings, measurements). |
| Probe | `tests/player_profile_probe.gd` | Sections G-J added (schedule, sessions, warm return, Active unchanged). 78 checks. |

**Not changed:** game balance, equipment stats, Prestige rewards, enemy behaviour and every other gameplay
system. `active_policy.gd` (`active-1`) is untouched. A 20-minute continuous Active seed 1 run is byte-identical
to the Phase 1 baseline: 272 events, events SHA `b55ce99d5aa0c1ca…`, state SHA `6a7a953b2a5425da…`.

### How Casual and Idle differ from Active

| | Active (`active-1`) | Casual (`casual-1`) | Idle (`idle-1`) |
|---|---|---|---|
| Sessions | continuous (1 h horizon); 55-65 min at ~08:00 and ~19:00 for calendar horizons | 16-24 min at ~08:30 and ~20:00, plus ~13:00 half the days | 5-10 min at ~08:00, plus ~21:00 on 60 % of days |
| Attention | decides every tick | management pass every 60 s, loot every 1.5 s, casts every 3 s | management pass every 120 s and before leaving, loot every 3 s, no manual casting outside bosses |
| Resting | Active's rule | rests below 30 % HP (checks every tick) | only notices HP at management passes, rests below 35 % |
| Spending | Active's list | buys what it wants when affordable, no saving, at most 3 buys a pass; combat and farm first, then offline and automation | strict savings plan: automation and offline upgrades first, then the farm; uses all owned automation |
| Bosses | Active's margin | +0.25 margin, 2 attempts a session, no retry after a loss | +0.35 margin, 1 attempt a session |
| Prestige | as soon as it is offered | at session start, at most once every 20 calendar h | same as Casual |
| Missions | Active's rule | farms the mission target | ignores them (Auto-Claim once bought) |
| Deaths | — | two deaths to one type in 15 min: farms elsewhere until 3 levels gained | same |

---

## 2. Runs completed

All runs were sequential (one Godot process at a time).

| Horizon | Profiles | Seeds | Result |
|---|---|---|---|
| Smoke + probe | all | — | `player_profile_probe` 78 checks, 0 failures (~21 s) |
| 1 active hour | Active, Casual, Idle | 1, 2, 3 | 9/9 `duration_reached` |
| 24 calendar hours | Active, Casual, Idle | 1, 2, 3 | 9/9 `calendar_reached` |
| 7 calendar days | Active, Casual, Idle | 1, 2, 3 | 9/9 `calendar_reached` |
| Determinism (repeat) | Casual 24 h, Idle 24 h, Active 60 min | 1 | events and final state IDENTICAL (599, 205 and 684 events) |

### Execution time (wall clock, this PC)

| Run | Wall time per seed | Speed (game time / wall time) |
|---|---|---|
| Active 1 active h | 68-73 s | ~50x |
| Casual 1 active h (24-29 calendar h) | 42-44 s | ~83x |
| Idle 1 active h (95-109 calendar h) | 41-43 s | ~87x |
| Active 24 h calendar (~2 active h) | 146-165 s | ~48x |
| Casual 24 h calendar | 27-43 s | ~86x |
| Idle 24 h calendar | 3-10 s | ~116x |
| Active 7 days (~14 active h) | 1650-2460 s | 20-31x |
| Casual 7 days (~5.9 active h) | 273-330 s | ~67x |
| Idle 7 days (~1.5 active h) | 61-77 s | ~85x |

Offline time costs nothing: the game settles an absence in one step. Wall time follows active time and the
amount of content on screen. Late Active runs slow down to 20-31x because there are more entities and kills.
The whole Phase 2 batch takes about 2.5 hours, and the three Active 7-day runs account for ~1.6 h of it.

---

## 3. Comparison (measurements)

Median [range] across seeds 1-3. Full tables: `profile_comparison.md`.

### 3.1 Equal active time: 1 active hour

| Metric | Active | Casual | Idle |
|---|---|---|---|
| Calendar time spanned (h) | 1 | 24.6 [24.2..29.3] | 95.9 [95.4..108.9] |
| Sessions | 1 | 4 | 8 [8..9] |
| Player level | 22 | 22 [21..23] | 22 [22..23] |
| Highest map | 3 | 2 | 2 |
| First boss defeat (active min / calendar h) | 10.8 / 0.18 | 15.4 / 0.26 | 19.8 / 24.5 |
| First Prestige (active min / calendar h) | 10.9 / 0.18 | 17.7 / 4.7 | 24.0 / 37.6 |
| Prestiges | 2 | 1 [1..2] | 3 [2..3] |
| Deaths | 0 | 0 | 5 [5..5] |
| Coins earned / of which offline | 5 318 / 0 | 10 138 / 4 700 (46 %) | 83 702 / 77 069 (93 %) |
| Gems earned / of which offline | 103 / 0 | 109 / 28 (25 %) | 241 / 146 (62 %) |
| Upgrade levels bought | 67 | 88 | 132 |
| Automation/offline levels owned | 2 | 8 | 26 |
| Offline hours past the cap (unpaid) | 0 | 13.0 | 28.4 |

**Limitation:** at equal active time, Casual and Idle also get 1-4 calendar days of offline income that Active
never receives. Idle's 16x higher Coin income here is calendar time turned into Coins, not a better use of
the hour.

### 3.2 Equal calendar time: 24 hours

| Metric | Active | Casual | Idle |
|---|---|---|---|
| Active time (h) | 2.06 | 0.93 [0.65..0.97] | 0.26 [0.09..0.32] |
| Sessions | 3 [2..3] | 3 [2..3] | 2 [1..2] |
| Player level | 33 | 21 [17..22] | 10 [5..11] |
| Highest map | 3 | 2 | 1 |
| Prestiges | 4 | 1 | 0 |
| First boss defeated within the day | 3/3 seeds | 3/3 | 0/3 |
| Coins earned (offline share) | 12 255 (8 %) | 6 679 (26 %) | 1 917 (60 %) |
| Offline hours past the cap | 11.8 | 5.3 | 7.2 |

### 3.3 Equal calendar time: 7 days

| Metric | Active | Casual | Idle |
|---|---|---|---|
| Active time (h) | 14.0 | 5.9 [5.4..6.1] | 1.47 [1.44..1.81] |
| Sessions | 14 | 18 | 12 |
| Player level | 104 [104..121] | 66 [62..68] | 28 [28..30] |
| Highest map | 4 [4..5] | 4 | 2 [2..3] |
| Prestiges | 8 [6..8] | 4 [4..6] | 5 [4..5] |
| Boss attempts = victories | 23 | 10 | 7 |
| Deaths | 0 [0..3] | 0 [0..1] | 13 [6..15] |
| Gear identities owned | 8 [3..11] | 9 [9..12] | 2 [2..9] |
| Merge levels total | 654 | 504 | 148 |
| Coins earned / spent | 130 351 / 8 081 | 169 871 / 165 888 | 194 730 / 184 019 |
| Gems earned / spent | 848 / 210 | 733 / 357 | 501 / 453 |
| Offline share of Coins / Gems | 8 % / 15 % | 50 % / 46 % | 93 % / 74 % |
| Offline item copies claimed | 0 | 0 | 244 [108..281] |
| Offline hours past the cap (unpaid) | 77 | 43 | 52 |
| Automation/offline levels owned | 4 | 13 | 33 |
| Longest active stretch without progress (min) | 15 | 3 | 2 |

Every offline settlement was claimed exactly once (earned = claimed in every run). Nothing was pending at
the end of any run.

### 3.4 Milestones: active minutes / calendar hours (seed medians)

| Milestone | Active | Casual | Idle |
|---|---|---|---|
| First boss / map 2 | 11 min / 0.2 h | 15 min / 0.3 h | 20 min / 24.5 h |
| Level 20 | 45 min / 0.8 h | 49 min / 11.8 h | 50 min / 72.5 h |
| Map 3 | 54 min / 0.9 h | 84 min / 36.3 h | 76 min / 143.7 h |
| Map 4 | 157 min / 24.4 h | 157 min / 72.3 h | not reached |
| Prestige 2 | 41 min / 0.7 h | 77 min / 36.1 h | 40 min / 72.3 h |

In active minutes the three profiles move at similar speeds up to level 20 and map 3. Their calendar times
differ by up to two orders of magnitude.

---

## 4. Individual evaluations

### Active (`active-1`, frozen Phase 1 policy)
- **Measured:** fastest by every calendar measure. First Prestige at 9-12 active min, a boss win on every
  attempt (69/69 over 7 days), 0-3 deaths. It spends only 8 081 of 130 351 Coins and 210 of 848 Gems in 7 days. From map 4
  on, it has long stretches without progress: 89 active min median in gaps of 10 min or more, and 334-412 min
  with no new boss defeat at the end.
- **Interpretation:** the 7-day Active result is a lower bound on what an engaged player reaches. Its policy
  stops spending and does not explore enough on late maps (findings P1, P2). Its first ~3 hours are reliable
  evidence; its late game is not.

### Casual (`casual-1`)
- **Measured:** about 20 active min a session, 2-3 sessions a day. First Prestige at 17-23 active min but
  0.9-11.6 calendar h, because Prestige waits for the next session start. Spends almost everything (166k of
  170k Coins), buys combat and farm upgrades first, and buys `collect` (Auto-Collect) only at 79-170 active min
  (29-72 calendar h). No deaths, no boss losses, no gaps without progress. Ends 7 days at level 62-68, map 4,
  4-6 Prestiges. Half of its Coins and Gems come from offline income. 24-31 % of its time away is past the
  8-hour cap and unpaid.
- **Interpretation:** the casual path works. Progress is steady, with no stalls caused by the game inside
  maps 1-3. On map 4 it hits the same exploration problem as Active (P1). Its offline cap rises slowly because
  the policy puts combat first, so a large part of each night is lost.

### Idle (`idle-1`)
- **Measured:** 5-10 active min, 1-2 sessions a day. Day 1 is very thin: level 5-11, map 1, no boss defeat
  on any seed, and seed 2 played a single 5-minute session. The first boss falls at 24.4-37.4 calendar h and
  the first Prestige at 36-47 calendar h. Offline income then dominates: 93 % of Coins, 74 % of Gems, and
  108-281 offline item copies by day 7. At equal active time (1 h) it is level 22 like the others. It dies
  far more often: 6-15 deaths in 7 days, mostly on maps 2-3 to `unit-calico-cat-hood`, `unit-golden-crown`
  and `unit-straw-hat`. Its automation purchases are spread over days: Focused Farming at 10 active min /
  12.3 calendar h, Auto-Collect at 33 min / 47.6 h, Offline Weapons at 55 min / 95.8 h, Auto-Merge at
  71 min / 120 h. It ends 7 days at level 28-30, map 2-3, with 4-5 Prestiges.
- **Interpretation:** the idle design pays as intended once the player is past the first boss. Offline
  income alone carries the economy. The barrier is the first day: before the first boss the idle player
  cannot use the economy it saves up, and a 5-10 minute session is not long enough to reach the boss
  (finding G1). The deaths come mostly from the policy (P3).

---

## 5. Findings, by severity

Codes: **G** = may need a game or balance decision, **P** = player-policy defect (bot behaviour, not the game),
**T** = testing-system defect. Severity: 1 critical, 2 high, 3 medium, 4 informational.
Nothing here was changed in the game. All balance items are recommendations for the developer to decide.

### Severity 2

**P1. Late-map exploration never finds the remaining bosses (policy, inherited from `active-1`)**
- Where: Active s2/s3 and Casual s1/s3 on map 4 (7 days). Active s1 on map 5.
- Evidence: `findings.md` lists `stuck_on_map` for 148-412 active min with no new boss defeat or Prestige.
  Exploration bursts end as soon as an enemy aggroes. The map-4 farm spot is next to a waypoint at (585, 855),
  so bursts last about 1.5 s. Active s1 on map 5 made 75 bursts totalling 184 s in 330 minutes. Explored area
  on map 4: Active s2 37 %, Casual 31 %. Teal Dinosaur (and, for Casual, Elephant) was never sighted.
- Cause: the exploration continuation rule in `active_policy.gd`, shared by Casual and Idle.
- Not a game problem: Active s1 found and beat Teal Dinosaur and reached map 5, so the boss can be found and
  beaten.
- Recommendation: in a Phase 3 policy version (`active-2`), let an exploration burst fight through aggro and
  keep a frontier target. Then measure maps 4-5 again. Changing `active-1` now would break the Phase 1
  baseline, so it was left alone.

**G1. The idle player's first day: no boss win in 24 calendar hours**
- Where: Idle, all three seeds, 24 h horizon.
- Measured: 0.09-0.32 active h on day 1; level 5-11; map 1; the first boss at 24.4-37.4 calendar h. Casual
  beats it at 15-18 active min, Idle at 19-21 active min. The Snowman needs about 20 active minutes of play,
  which an idle player spreads over 2-3 real days. Offline income on day 1 is 1 200-1 500 Coins and 10 Gems
  (base cap 5 h).
- Interpretation: an idle player sees no boss, Prestige or second map for 1-2 days. This may be the design
  intent (offline income is meant to reward return visits), or it may be an early retention risk. It is a
  design decision. Measurable levers, should the developer choose any: shorter time to the first boss, a
  larger offline cap or rate before the first Prestige, or a day-1 objective that pays toward the boss.
- Caution: the Idle policy rests and fights less well than a person would (P3). A human idle player may be
  slightly faster, but not by enough to fit 20 minutes of play into one 5-10 minute session.

**P3. Idle deaths come mostly from the policy**
- Measured: 13 [6..15] deaths in 7 days, against 0 for Casual on the same maps. They cluster on
  `unit-calico-cat-hood` (map 2, levels 12-14), `unit-golden-crown` (map 2, levels 15-28) and
  `unit-straw-hat` (map 3, levels 26-30).
- Cause: the Idle policy checks its HP only at a management pass every 2 minutes. That is the intended
  "few decisions" behaviour, but it is harsher than a player glancing at the screen. An earlier version that
  never rested died 14 times in 72 h; resting at a glance and avoiding a type after two deaths brought that
  down. A real idle player buys Auto Use for potions, and this policy buys it late in its plan.
- Recommendation: treat the death count as a ceiling. If idle players dying while auto-farming is a design
  concern, measure with Auto Use moved earlier in the plan before changing combat numbers.

### Severity 3

**G2. Offline time past the cap is a large share of every absence**
- Measured (7 days): unpaid hours past the cap: Casual 43 h of ~162 h away, Idle 52 h of ~167 h, Active 77 h
  of ~154 h. On day 1 it is 49-60 % of the time away, because the base cap is 5 h against a night of 11-12 h.
- Interpretation: the cap does its job (it rewards returning), but a player with an ordinary sleep schedule
  loses roughly half of each night until they buy Offline Time 3 or higher. Idle reaches an 18-hour cap only
  around day 6. This is a design question about how much a night should pay.

**G3. Auto-Collect is bought per enemy type, which delays automation**
- Measured: Idle spent 115 Gems on `collect` across 4 enemy types in 7 days. Casual bought its first `collect`
  at 79-170 active min (29-72 calendar h). Each farm change (a new map, or avoiding a type after deaths)
  needs another purchase, and savings goals for an older farm type expire by the lapse rule.
- Interpretation: per-type automation makes the idle player re-buy it on each new map. Expected from the
  current design; flagged so the developer can confirm it is intended.

**G4. Offline item rewards arrive late for idle players**
- Measured: Offline Weapons (50 Gems) was bought at 55 active min / 95.8 calendar h (day 4), and Offline
  Outfits at day 4-5. 0 offline item copies were earned in the 1-hour and 24-hour horizons for every
  profile.
- Interpretation: the Change 79 offline item and Offline Skills rewards only matter for players who stay
  past day 4. Information for any future review of offline pacing; no defect.

**P2. Active underspends at long horizons (policy)**
- Measured: Active spends 6 % of its Coins and 25 % of its Gems in 7 days. Its automation levels stop at 4.
- Cause: the frozen `active-1` spending list. Casual and Idle spend 94-97 %.
- Impact: Active's late progression is a lower bound, and Active vs Casual comparisons after ~3 active h
  understate Active. Recommendation: add a surplus tail, as Casual and Idle have, in a future `active-2`.

**G5. Prestige at session start delays the first Prestige by calendar hours**
- Measured: Casual is Prestige-ready at 12-15 active min but takes it at 0.9-11.6 calendar h. Idle s1 was
  ready at 12.5 h and had still not Prestiged at the 24 h horizon (`prestige_not_taken`).
- Interpretation: this is the policy's choice, made to mimic a player who decides at the start of a session.
  The game offered Prestige correctly every time. No game defect.

### Severity 4 (information)

- **No boss losses anywhere**, in 182 attempts across the 27 runs. The policies only fight with
  a stat margin, so this measures their caution, not boss difficulty. Boss difficulty below the margin was not
  tested.
- **Daily missions roll over at virtual midnight**, and both Casual and Idle claimed them (Idle through
  Auto-Claim once bought).
- **Offline accounting:** earned = claimed in all 27 runs; pending rewards paid at Prestige are counted as
  claimed; the cap was always honoured.

### Testing-system defects found and fixed during Phase 2

| Code | Defect | Fix |
|---|---|---|
| T1 | First-session events were stamped 1970 | the recorder takes the virtual clock in scheduled runs |
| T2 | The persistence check compared opportunity entries by key order, then by int/float type | the comparison uses sorted `id=ready` pairs |
| T3 | Casual never Prestiged: the session-start window closed while the cold-loaded game was still "in combat" | the window stays open until a non-combat reason blocks it; the skip is recorded |
| T4 | Active 7-day runs stopped on `coins 18121.292 -> 18121.293` after a save round trip | the numeric comparison tolerates 0.0011 |
| T5 | Savings goals stayed "open" for 155 calendar h after the policy stopped wanting them | goals lapse after 600 active s without renewal and are not reported as unaffordable |
| T6 | The first policy versions hoarded Coins | surplus wish tails (Casual/Idle only); runs re-measured |

---

## 6. Validation

| Requirement | How it is checked | Result |
|---|---|---|
| Scheduling deterministic, lengths/gaps honoured | probe G | pass |
| Offline advances only the calendar; active + offline = calendar | probe H, every run summary | pass |
| Cap and unlocks respected | probe H (an absence longer than the cap pays only the cap), adapter records rates at leave | pass |
| Claimed exactly once, second claim pays nothing | probe H/I, 27 runs earned = claimed | pass |
| Persistence across sessions (cold load) | adapter compares level, XP, currencies, items, upgrades, Prestiges, stages, cards, gear, missions, camps, kills, Focus, skills, opportunities after every return | pass (0 `action_error` in all runs after T4) |
| Daily missions roll over | probe H, `missions_refreshed` events | pass |
| Several Prestige cycles | 7-day runs: 4-8 Prestiges per run | pass |
| Determinism | repeat runs: Casual 24 h, Idle 24 h, Active 60 min | identical events and state |
| No interference with real saves | runs use an isolated `--profile` save folder; probe checks it | pass |
| No regression to Active | Active 20 min seed 1 byte-identical to Phase 1 | pass |
| Maintained suite | `python tools/run_probes.py` | 53/69; `player_profile_probe` passes (78 checks); the 16 failures are the known baseline set (export_manifest, change_57/55/54/52/51/41, localization_batch01/sweep/progression, change_27/24/20/17/13/7), unchanged from Change 79 |

Long playthroughs are not gating checks; only `player_profile_probe` is part of the suite.

---

## 7. Limitations

- **No combat or farming while away.** The game pays offline rewards by its own rules; the bots get nothing
  else. That is correct for this game, and it is why Idle depends on the cap.
- **Bots see the game state, not the screen.** They read values that a player would have to find in the UI,
  such as boss readiness margins and exact prices. They do not miss notifications, misread icons or forget
  goals, so the results cannot judge UI clarity or onboarding.
- **The policies are cautious.** No boss losses means the boss difficulty curve was not tested below the
  margin. Death counts for Idle reflect its attention model.
- **The late game is under-measured** for all profiles because of P1 (exploration) and P2 (Active spending).
- **Three seeds** each; the ranges show that seed variation matters (Idle 24 h: one seed played a single session).
- **Fixed schedules.** Real players skip days, play irregularly and change behaviour; the schedules are
  regular with jitter.
- **Equal-active and equal-calendar comparisons each favour one side.** Read them together (section 3).

## 8. Recommendations

1. **Policy (next):** create `active-2` with exploration that fights through aggro and a spending surplus
   tail, keep `active-1` for baseline checks, and re-measure maps 4-5 (P1, P2).
2. **Design decision:** decide whether an idle player should defeat the first boss on day 1 (G1). If yes,
   use the Idle 24-hour horizon as the acceptance test: first boss < 24 calendar h on 3/3 seeds.
3. **Design decision:** decide how much of a night offline income should pay at the start (G2). The
   measured unpaid share on day 1 is 49-60 %.
4. **Policy:** move Auto Use earlier for Idle and re-measure deaths before treating them as a combat issue (P3).
5. **Tooling:** a scheduled "missed day" option in `session_schedule.gd` (a probability that a whole day has
   no session) would test longer absences and the 36-48 h caps.
