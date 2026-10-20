# Everfort — Complete Chat Continuity Handoff

> Purpose: preserve the full working context of the Everfort project so a future ChatGPT/Claude/GPT session can continue without access to the original conversation.
>
> This document is intentionally detailed. It records the game's current design, implemented systems, balance decisions, UI decisions, asset usage, development workflow, known constraints, lessons learned, current pending work, and the reasoning behind major decisions.
>
> **Last continuity synchronization:** 2026-09-26, after the Castle Damage Report, Automation Timers HUD, and Defeat-screen readability patches were applied on top of the latest full-project baseline.

---

## 1. Project identity

**Project name:** Everfort  
**Former working name:** TinyKingdoms (older source/docs/patch filenames may still use this name)  
**Engine:** Godot 4.7.2  
**Language:** GDScript  
**Renderer:** Mobile renderer  
**Primary target:** Android / Google Play  
**Secondary target:** Desktop QA / itch.io  
**Business model:** Premium, inexpensive game; target launch price discussed around **US$1.99**, with US$2.99 worth testing after complete playtesting.

**Core direction:** fast 2D incremental / roguelite / idle-defense game built primarily from the Tiny Swords asset pack.

**Player color:** Blue  
**Enemy color:** Red

The project was intentionally scoped as a small premium game that can be completed quickly, with the broader goal of creating a reusable process for future games.

## 1.1 Current checkpoint — 2026-09-26

Everfort is no longer in feature-development, cleanup, UI-audit, or broad balance-QA mode. The project is in **release-candidate stabilization** while the Android release is already uploaded to Google Play Console and awaiting review. The user is validating the **actual exported Android release build**, and recent work has been limited to concrete release-build bugs, readability issues, and final economy tuning discovered through that playtest.

**Continuity reconciliation note:** on 2026-09-26 this handoff was rechecked not only against the latest full ZIP, but also against the retrievable Everfort/TinyKingdoms project conversations across the prototype, checkpoint, cleanup, UI, Android, store, and release-stabilization phases. The ZIP remains implementation authority; the conversation sweep is used to preserve design intent, historical decisions, workflow rules, and reusable lessons that code alone does not explain.

Completed / accepted before this checkpoint:

- C0 aggressive read-only cleanup audit;
- C1-A low-risk cleanup;
- C1-B legacy/current-schema cleanup;
- C2 persistence/lifecycle audit;
- C2-A lifecycle corrections;
- C2-B exact runtime snapshot fidelity;
- current save schema: **`SAVE_VERSION = 3`**;
- A7.1A Environment;
- A7.1B HUD;
- A7.1C Run Upgrades;
- A7.1D Gameplay Interaction;
- A7.2 Main Panels;
- A7.3 Secondary Panels, Modals & Endgame UI;
- A7.4 physical-Android UI acceptance;
- long-form gameplay/balance validation;
- store listing/setup and Play Console publishing setup;
- release AAB generation/upload;
- privacy/store-support infrastructure.

Current version information from the latest full project baseline referenced by this handoff (`EverFort(20260926-035248).zip`). The current working tree then received the approved changed-files patches for Castle Damage Report/balance, Automation Timers HUD, and Defeat-screen readability; until a fresh full ZIP is supplied, continuity should treat that baseline + applied patch chain as the current source state:

```text
project.godot application/config/version: 2.1.1
Android export version code:              18
Android export version name:              <blank; inherits project version>
package ID:                               com.shekinahwelefuldesigns.everfort
```

Versioning rule established during release stabilization:

> `application/config/version` is the single player-facing/version-name source of truth. Android `version/name` stays blank so Godot inherits the project version. Android `version/code` is still incremented separately for every Play Console upload.

Final C2 probe evidence remains:

```text
CHECKPOINT_C2B_PROBE_RESULT pass=49 fail=0
POST_CP6_PROBE_RESULT      pass=78 fail=0
RESTART_LIFECYCLE_PROBE_RESULT pass=110 fail=0
```

Recent release-build stabilization work includes:

- Castle-healing mission tracking centralized so Health Regen, Lifesteal and Second Wind all report actual HP restored;
- continuous Mission progress changed to preserve/display fractional values where appropriate;
- Mission completion now uses an explicit `0.005` tolerance and snaps sub-cent final remainders to the exact target, fixing cases such as `169 / 169` still reading **In Progress**;
- Lancer speed increased to **45 px/s regular / 47.25 px/s Elite**;
- Miner Skill Point discovery mission moved to **Special-only** because its completion depends heavily on RNG/player agency;
- mission SP economy, Special Mission progression, automation costs, first-clear SP, Gold Gain, Manual Mining, Sheep Gold, and offline-SP progression rebalanced;
- Offline Reward UI now shows Gold and SP as auditable calculation receipts rather than only final totals;
- New Enemy Incoming text was enlarged for phone readability;
- Settings/version drift removed by the single-source version rule above;
- Auto Upgrade Amount, Starting Gold, Offline Coin Efficiency, Sheep Gold Bonus, and Manual Mining received the final approved release-balance pass;
- the Defeat screen gained a persisted Castle Damage Report that attributes actual Castle HP loss by enemy/stage since the most recent full-heal reset, while also showing healing so cumulative damage can legitimately exceed one health bar;
- the Defeat layout now keeps the Skill Point reward summary first and permanently visible, keeps the Top Threat / Damage / Healing / Net summary visible, and moves long reward/damage receipts into independent scroll areas with larger phone-readable text;
- an optional persisted **Automation Timers** HUD was added below Stage, showing only meaningful deterministic automation countdowns/statuses such as Auto Upgrade, Auto Claim Mission, and Next Mine.

**2026-10-14 localization pass (uncommitted, awaiting review):** all player-visible text now uses semantic keys in 20 `localization/*.po` catalogs, with Automatic/manual language selection in Settings, live refresh, and CJK/Thai/Devanagari font fallbacks. See section 52. Gameplay, balance and the save schema did not change.

**Immediate continuation:** continue testing the exact release candidate on Android. Specifically validate the final Defeat-screen layout, Castle Damage Report attribution/reset/healing behavior, and Automation Timers HUD on-device. Fix only concrete release blockers/regressions or balance issues demonstrated by release play. After any runtime-code change, rebuild with a higher Android version code, regression-check the affected system in the exported build, and update the Play Console release as necessary. Once the patched tree is accepted, create/upload a fresh full-project ZIP so future patches no longer depend on reconstructing this patch chain. Do not reopen broad cleanup, UI redesign, or new-feature scope without a real release need.

---

# 2. Critical workflow rules for future chats

These rules were established through experience and should be treated as project-level instructions.

## 2.1 Code authorization

Do **not** write or modify project code unless the user explicitly says:

- “write code”, or
- clearly authorizes implementation.

If the user is discussing design, balance, architecture, hierarchy, or next steps, stay in analysis/planning mode.

### 2.1.1 UI/environment iteration cap

For UI/environment sections, use a **maximum of 4 implementation iterations** before stopping and handing the exact remaining visual adjustments to the user for manual editor tuning. This exists to prevent endless AI pixel-pushing and regression loops.

If a 5th AI implementation attempt would be needed:

1. stop and explain the remaining adjustment precisely;
2. prefer editor-visible controls/nodes when practical so the user can tune visually;
3. only attempt another code iteration if the user explicitly approves going beyond the cap **twice**.

This does not prevent small parser/runtime fixes caused by the implementation itself; it limits repeated subjective visual redesign attempts.

## 2.2 Latest full ZIP is authoritative

When implementing substantial work:

1. Ask for / use the latest full project ZIP.
2. Treat that ZIP as the source of truth.
3. Do not rely on an old local working tree or remembered patch.
4. Compare against the latest full ZIP before packaging changes.

## 2.3 Changed-files-only delivery

Unless explicitly asked for a full project package:

- produce a ZIP containing **only changed/new files**;
- preserve exact project-relative paths;
- do not include the whole project;
- report whether files must be deleted;
- give clear application order when multiple ZIPs exist.

Whenever possible, consolidate patch chains into one current replacement ZIP before a commit.

## 2.4 Commit checkpoints

The workflow that worked best:

1. Implement a coherent batch.
2. User imports into Godot.
3. Fix parser/runtime regressions.
4. User validates.
5. Commit.
6. Start the next batch.

Recommended Git Bash sequence:

```bash
git status --short
git add -A
git diff --cached --stat
git commit -m "feat: descriptive batch summary"
```

Always inspect staged changes for unwanted Godot-generated files before committing.

## 2.5 Godot validation limitation

In the current ChatGPT execution environment there was **no Godot executable available**.

Confirmed commands such as:

```bash
godot
godot4
```

were unavailable.

Therefore:

- ChatGPT can perform static validation;
- ChatGPT can inspect `.gd`, `.tscn`, `.tres`, resource paths, scene references, callbacks, and ZIP integrity;
- ChatGPT can build probes/tests for the user;
- **actual Godot parser/runtime/editor/device validation must be performed by the user** unless a future environment explicitly includes a working Godot binary.

Do not pretend a Godot runtime test occurred if it did not.

## 2.5.1 Text punctuation rule

Never use double dashes (`--`) in player-facing text, documentation, prompts, release notes, or other authored prose. Use normal punctuation appropriate to the sentence instead.

## 2.6 Best static checks before delivery

Before creating a patch ZIP, perform as many of these as possible:

- all quoted `res://` paths exist;
- all `.tscn/.tres` `ExtResource` IDs resolve;
- all `SubResource` IDs resolve;
- all `.connect(_on_...)` callbacks exist;
- duplicate function names are absent;
- obvious GDScript bracket/string structure is valid;
- scene node paths referenced in scripts exist;
- new save/profile keys are initialized and serialized;
- Hard Reset paths include new systems;
- ZIP contents byte-match final working files.

---

# 3. High-level gameplay loop

The final game loop evolved into:

1. Castle automatically attacks enemies.
2. Enemy waves attack the Castle.
3. Enemies drop physical Gold pickups.
4. Player taps Gold or Sheep collect it.
5. Gold purchases **Run Upgrades**.
6. When the Castle dies, the run restarts.
7. Skill Points are earned from progression/rewards.
8. Skill Points purchase **Permanent Skills**.
9. Mandatory Prestige checkpoints gate later campaign stages.
10. Towers, Sheep, Mines, Miners, missions, offline rewards, and automation progressively reduce manual input.
11. Stage 100 is the real campaign completion point.

This was deliberately designed so older content becomes easier as the permanent/meta layer grows.

---

# 4. Campaign structure

## 4.1 Stage count and chapter gates

The authored campaign runs to **Stage 100**.

Mandatory chapter Prestiges occur after the player **beats**:

- Stage 10
- Stage 20
- Stage 30
- Stage 40
- Stage 50
- Stage 60
- Stage 70
- Stage 80
- Stage 90

Stage 100 is the authored campaign ending.

Progression language should use **Beat Stage X**, not Reach Stage X. Merely entering a milestone stage does not count as clearing it and must not complete its progression mission.

## 4.2 Prestige gate rule

Before campaign completion, campaign cap is:

```text
max_stage = 10 * (prestige_count + 1)
```

capped at 100.

Prestige does **not** make a given absolute stage intrinsically harder. Absolute stage controls enemy composition and scaling. Prestige unlocks access to later chapters.

Stage 20 should therefore represent the same authored difficulty/composition whenever it is played.

## 4.3 Stage 100 / post-campaign loop

The first Stage-100 clear is special:

1. Stage 100 is beaten.
2. The run is banked and its SP receipt is shown.
3. Show **CAMPAIGN COMPLETE** / thank-you messaging.
4. Offer **Join Discord** and **Choose Prestige**.
5. Show only counts for remaining Prestige progression:
   - Prestige boons not fully mastered;
   - Prestige picks remaining.
6. Pressing **Choose Prestige** opens one **mandatory, persisted** three-card Prestige choice earned by beating Stage 100.
7. After the boon is chosen, the post-campaign loop begins at Stage 1.

After campaign completion, later Stage-100 clears become repeatable optional endgame Prestige opportunities:

```text
Stage 1 -> ... -> Beat Stage 100
-> bank run rewards
-> Keep Playing OR Prestige (when an eligible boon exists)
-> new Stage-1 run
```

If unmastered boons remain but all currently eligible ones depend on systems the player has not unlocked, the UI should say that more Prestige paths remain without revealing which specific locked boons they are.

When every selectable Prestige boon reaches max stacks, show a one-time **END OF CURRENT CONTENT** thank-you screen with **Join Discord** and **Keep Playing**. After that acknowledgement, the player may continue normal runs/Permanent Skills; future Stage-100 clears do not repeatedly show the full end-of-content thank-you.

## 4.4 Enemy introduction schedule

Absolute-stage composition:

- Stage 1–9: Warrior
- Stage 10: Archer introduced
- Stage 20: Lancer introduced
- Stage 30: Monk introduced
- Stage 40: Elite Warrior introduced
- Stage 50: Elite Archer introduced
- Stage 60: Elite Lancer introduced
- Stage 70: Elite Monk introduced
- Stage 80–89: all except regular Warrior
- Stage 90–99: all except regular Warrior and regular Archer
- Stage 100: elites only

Milestone reveal popups appear on first introduction.

A milestone popup should appear only once, but the milestone enemy remains part of the stage on retries.

---

# 5. Enemy archetypes

## 5.1 Warrior

Role: basic melee enemy.

Current base HP after rebalance:

```text
20
```

## 5.2 Archer

Role: ranged enemy.

Current base HP:

```text
15
```

Regular Archer stand-off range used as reference for Monk:

```text
260
```

Elite Archer reference range:

```text
270
```

## 5.3 Lancer

Role: tank/heavy enemy.

Current base HP:

```text
50
```

Current movement speed after release-build balance testing:

```text
Regular Lancer: 45.0 px/s
Elite Lancer:   47.25 px/s
```

The Lancer remains slower than Warrior/Archer/Monk, but is no longer dramatically slower than every other archetype. The Elite keeps roughly the same +5% speed relationship.

## 5.4 Monk

Role: ranged support/healer.

Important final behavior:

- Monk is a rear-line support unit and stays roughly **40 px behind the Archer line**.
- Regular Monk preferred stand-off range: **300**.
- Elite Monk preferred stand-off range: **310**.
- Effective stopping positions remain inside the Castle attack range so the Monk is always targetable once it reaches its support line.
- Monk does **not** attack the Castle.
- Base damage is 0.
- Normal support action heals **one wounded allied enemy**.
- Targeting priority: lowest health ratio within heal range; distance breaks ties.
- While walking, the Monk continuously checks for wounded allies in heal range. If one becomes eligible, the Monk stops advancing, heals, then reevaluates whether to heal again or resume movement.
- These roaming heals still participate in the normal support-action cadence.
- Special/charged action performs an AoE healing pulse.
- Pulse should reach allies attacking the Castle on the same side.
- Regular heal radius: **280**
- Elite heal radius: **300**
- Heal animation is used for support actions.

Base healing:

- Regular Monk: 8
- Elite Monk: 14

Healing no longer stays flat forever. It scales with stage.

### Monk healing scaling

The selected model:

- the Monk starts with the intended base heal at its introduction stage;
- after introduction, healing follows **75% of the relative enemy-HP growth**;
- this keeps healing relevant without making late-game enemies excessively regenerative.

Approximate regular Monk heal:

| Stage | Heal |
|---:|---:|
| 30 | 8 |
| 50 | 10.63 |
| 70 | 12.16 |
| 100 | 14.46 |

Approximate Elite Monk heal:

| Stage | Heal |
|---:|---:|
| 70 | 14 |
| 100 | 16.38 |

## 5.5 Elite HP rebalance

After lowering the regular archetypes, elites were adjusted accordingly:

- Warrior Elite: **40**
- Archer Elite: **26**
- Lancer Elite: **93**
- Monk / Elite Monk HP were not part of that HP reduction pass.

---

# 6. Enemy HP scaling

Enemy HP scales with stage.

Originally:

- early growth: +6% per stage step
- late growth: +3.5% per stage step

For the Android polish/balance pass, the **growth component was increased by 20%**:

- early growth: **+7.2%**
- late growth: **+4.2%**

This increased Stage 100 HP from approximately:

```text
5.69x base HP
```

to approximately:

```text
6.63x base HP
```

Damage scaling was not changed in that pass.

Important distinction:

- changing base HP affects the whole curve;
- changing growth affects how quickly later stages become durable.

---

# 7. Wave count rebalance

Every stage was changed to spawn:

```text
+1 enemy
```

relative to the previous StageGenerator count curve.

This preserves:

- milestone introductions;
- elite-wave bonuses;
- Stage 100 bonus;
- authored composition logic.

The intention was to increase Gold availability and activity while compensating with lower base HP on core enemies.

---

# 8. Castle

The Castle:

- auto-attacks enemies;
- has HP;
- can receive permanent/run upgrades;
- can gain shield;
- can receive Second Wind protection;
- can unlock target priority.

## 8.1 Castle target priority

Permanent one-time skill:

```text
50 SP
```

Visible name should be:

```text
Castle Targeting
```

Target options:

- Auto / Nearest
- Warrior
- Archer
- Lancer
- Monk

Elite enemies count as their base archetype.

Behavior:

- preferred archetype in range is targeted first;
- if none exists, Castle falls back to normal targeting;
- Castle must never idle simply because the preferred archetype is unavailable.

This skill originally existed under a less discoverable name (“Targeting Orders”) and was moved into Automation.

---

# 9. Run Upgrades

Run upgrades reset on death/new run.

Core run stats include:

- Health
- Damage
- Attack Speed
- Attack Cooldown / cadence
- Crit Chance
- Crit Damage
- Lifesteal
- Health Regen

The bottom dock was heavily redesigned for mobile.

Important UI decisions:

- dock height reduced during visual pass;
- cards kept readable;
- bottom padding had to be tuned to prevent cards clipping off-screen;
- gameplay values should be readable without modal-scale text.

---

# 10. Permanent Skills

Permanent Skills survive runs.

The Skills screen evolved into grouped sections with a **3-card-per-row mobile layout**.

This was specifically chosen because cards were becoming too small when too many columns were used.

Recommended rule:

```text
3 cards per section row on the 1920x1080 reference layout
```

Cards should be large enough for:

- icon;
- title;
- current effect;
- next effect;
- cost;
- purchase button.

## 10.1 Statistics screen is separate from Skills

The earlier compact **Current Stats** block was removed from the top of Permanent Skills. The Skills panel is now purchase-focused only.

A separate **Pause -> Statistics** screen owns the broader player/account readout. It includes organized sections for:

- Overview;
- Combat History;
- Economy & Rewards;
- Mining & Automation;
- Current Power;
- Permanent Skill levels;
- Prestige Boon stacks.

Persistent lifetime counters include foreground play time, restarts, Gold collected by source, SP earned by source, missions claimed, Run/Permanent upgrades purchased, critical hits, Tower kills, elite/archetype kills, Mines spawned/depleted, manual Mine taps, Miner strikes, and Miner extractions.

Older saves remain compatible, but source-specific historical counters cannot be reconstructed retroactively.

---


## 10.2 Run-end Skill Point rewards

The old automatic/global `+40%` SP multiplier was removed. Run-end SP should be understandable from the result screen.

Current formula:

```text
Repeatable Run Progress
+ First-time Stage Clears
+ one-time first-run floor adjustment when needed
= reward base

+ Permanent Skill SP bonus
+ Scholar's Legacy Prestige SP bonus
= final SP earned
```

### Repeatable Run Progress

Every stage actually **cleared** during the run awards:

```text
0.5 SP
```

The stage where the Castle dies does not count as cleared.

### First-time Stage Clear bonus

Every stage also has a one-time first-clear reward. The per-stage amount rises every 10-stage chapter:

| First-clear stages | SP per newly cleared stage |
|---|---:|
| 1–10 | 1.0 |
| 11–20 | 1.5 |
| 21–30 | 2.0 |
| 31–40 | 2.5 |
| 41–50 | 3.0 |
| 51–60 | 3.5 |
| 61–70 | 4.0 |
| 71–80 | 4.5 |
| 81–90 | 5.0 |
| 91–100 | 5.5 |

The old overlapping 5-stage milestone bonuses and special Stage 10/25/50/75/100 first-clear bonuses were retired.

The first banked run retains a **2 SP minimum base** so onboarding cannot strand the player without enough SP for the required first Permanent Attack purchase.

The Defeat/Chapter/Stage-100 result UI should present SP as a reward receipt, including:

- Run Progress;
- First-time Stage Clears (grouped by stage bracket when useful);
- first-run floor adjustment, if any;
- Permanent Skill percentage and its actual SP contribution;
- Prestige Legacy percentage and its actual SP contribution;
- final **Skill Points Earned** total.

Mission SP rewards are authored final payouts and are not multiplied again by these run-end modifiers.

---

# 11. Automation section

Automation-related permanent upgrades were consolidated into a dedicated section instead of being scattered across Economy/Utility.

Final relevant Automation cards include:

- Auto Collect Coins
- Sheep Gold Bonus
- Auto Restart
- Castle Targeting
- Auto Run Upgrades
- Auto Upgrade Amount
- Auto Claim Missions
- Mission Capacity
- Mission Expertise
- Special Missions

Mining/worker automation remains in its own Mining section because it is a full subsystem.

Game Speed stays under Utility rather than Automation.

---

# 12. Auto Collect / Sheep

Visible name should be:

```text
Auto Collect Coins
```

Sheep collect loose resource pickups.

Costs for the four Sheep/Auto Collect levels:

```text
10 / 15 / 25 / 40 SP
```

Sheep idle positions were deliberately changed to prevent them disappearing behind the Castle:

- 2 on the left side;
- 2 on the upper-right side.

Sheep should use y-sort correctly.

Sheep Gold bonuses must apply only to Sheep-collected Gold, not manually collected Gold.

Current Permanent Skill **Sheep Gold Bonus** is **+15% Sheep-collected Gold per level**, 10 levels, for **+150% max** before Prestige effects.

---

# 13. Gold pickups

Gold is a physical battlefield pickup.

Important final rules:

- Gold should **not despawn because of time**.
- Unclaimed Gold remains on the battlefield for the duration of the current run.
- Gold is cleared on:
  - new run;
  - death/restart;
  - Hard Reset.
- Gold participates in active-run save persistence.

## 13.1 Gold pickup visuals

The project originally enlarged coins too much.

Final lesson:

- do not scale tiny source sprites aggressively;
- enlarged pixel art quickly becomes visibly blurry/pixelated.

The coin visual was enlarged, then reduced again by 35%.

The animation uses:

```text
Gold_Resource_Highlight.png
```

rather than a static tiny frame.

Gold pickup collision radius should scale consistently with the displayed sprite.

## 13.2 Floating Gold text

Gameplay floating text was intentionally made much larger for phone readability.

The following categories were increased to approximately **2x previous size**:

- damage;
- Gold pickup/reward;
- healing;
- lifesteal;
- reflected damage;
- other combat floating values;
- Mine/resource feedback.

Enemy special/charge text was increased about **25%**.

HUD values were increased more conservatively, approximately **15–20%**.

Important lesson:

> World-space/combat text and menu/modal text should not share the same scale rules.

---

# 14. HUD

The top HUD went through several layout passes.

Final direction:

- Stage and Castle HP pushed farther left;
- Gold shown prominently;
- Skill Points displayed **next to Gold on the same row**, not underneath;
- Skills/Missions/other buttons follow.

Skill Points listen to:

```text
ProfileState.skill_points_changed
```

so:

- mission rewards;
- purchases;
- debug additions;
- Hard Reset

should update immediately.

## 14.1 Warning indicators

A visible `!` appears on:

### Missions button

When at least one Mission is ready to claim.

### Skills button

When the player has enough SP to buy at least one currently unlocked/non-maxed Permanent Skill.

Warnings should refresh after:

- mission progress;
- mission claims;
- rewards;
- skill purchases;
- run resets;
- wallet changes.

## 14.2 Automation timer readout

A compact **Automation Timers** readout now sits directly below the Stage block in the upper-left HUD. It is intentionally small, noninteractive, safe-area-aware, and collapses completely when no useful timer is active.

Current meaningful statuses are:

- `Buy upgrade in Ns` for Auto Run Upgrades;
- `Upgrade: Waiting for Gold` when an Auto Run Upgrade batch matured but cannot yet afford a purchase;
- `Claim mission in Ns` while Auto Claim Missions has at least one claimable mission and is counting down;
- `Next mine in Ns` while the recurring Mine spawn timer is active.

Auto Restart keeps its existing countdown on the Defeat screen instead of duplicating it in the battle HUD. Per-Miner work timers, Sheep movement, Castle/Tower attack cooldowns, and other nondeterministic/noisy internal timers are deliberately excluded.

The HUD reads countdowns from the systems that actually own them (`AutoRunUpgradeController`, `AutoClaimMissionController`, `MiningGroup`) rather than recreating timer math. This prevents display/runtime drift.

The readout is controlled by the persisted Settings option **Automation Timers**, which defaults to **On** for new/existing saves that have never stored the setting. Turning it off hides the complete readout immediately without changing automation behavior.

---

# 15. Missions

The mission system is now dynamic rather than a fixed 16-mission / three-slot model.

Core board rules:

- base capacity: **3 total slots**;
- slot 0 is reserved for the next **Beat Stage** progression mission until Beat Stage 100 is claimed;
- remaining slots are rotating missions generated from objective families;
- Permanent Skill **Mission Capacity** adds one rotating slot per level, growing the board from 3 to **6 total slots**; current costs are **60 / 120 / 180 SP**;
- progression/reward scaling is keyed to the highest **Beat Stage mission actually claimed**, not merely the current run stage;
- mission rewards are snapshotted when assigned;
- duplicate objective families should not occupy the board simultaneously when avoidable;
- missions for Towers/Sheep/Miners/Elites/etc. enter the pool only when their underlying content is available.

The current rotating objective catalogue includes 18 families:

- Defeat enemies
- Collect Gold
- Buy Run Upgrades
- Spend Gold on Run Upgrades
- Land Critical Hits
- Deal Damage
- Clear Stages
- Defeat a specific enemy archetype
- Defeat Elite enemies
- Clear stages with Castle at least 50% HP
- Restore Castle HP
- Tower kills
- Gold collected by Sheep
- Manual Gold extracted from Mines
- Deplete Mines
- Gold delivered by Miners
- SP discovered by Miners
- Run Upgrades bought automatically

## 15.0 Current mission-panel presentation and stability

The redundant **Active Missions** subsection ribbon was removed. The main **Missions** title is sufficient, and mission cards begin directly below it.

Mission progress values use the centralized number formatter consistently. Values above 999 should abbreviate with the normal suffix ladder, for example:

```text
26356 / 48919 -> 26.36K / 48.92K
```

A runtime UI bug was traced to repeatedly calling a scale-based `UiFx.punch()` on the mission progress-bar container. Overlapping updates could use an already enlarged scale as the new baseline and compound indefinitely. The mission progress bar no longer receives that punch, and shared `UiFx.punch()` / `UiFx.flash()` behavior was hardened so overlapping animations restore the true base state rather than accumulating scale or tint.

## 15.1 Beat Stage progression missions

Progression missions are:

```text
Beat Stage 10
Beat Stage 20
...
Beat Stage 100
```

They complete only when the target stage is **cleared**. Entering/jumping to the stage must not award progress.

Fixed SP payouts:

| Beat Stage | SP |
|---:|---:|
| 10 | 10 |
| 20 | 20 |
| 30 | 35 |
| 40 | 50 |
| 50 | 65 |
| 60 | 90 |
| 70 | 110 |
| 80 | 130 |
| 90 | 145 |
| 100 | 160 |

These are final authored mission payouts and do not receive the normal run-end SP multipliers.

## 15.2 Rotating mission reward generation

For each rotating mission:

1. choose difficulty;
2. independently roll reward currency;
3. choose a compatible objective family.

Difficulty roll:

- Easy: **45%**
- Standard: **35%**
- Hard: **20%**

Reward-currency roll starts at:

- SP: **10%**
- Gold: **90%**

Permanent Skill **Mission Expertise** increases SP reward probability by +5 percentage points per level, from a 10% base up to 30% total. Current costs are **100 / 180 / 300 / 450 SP**.

Gold difficulty payout uses:

- Easy: **50%** of current Gold ceiling
- Standard: **75%**
- Hard: **100%**

Ordinary SP missions use the **next unclaimed Beat Stage reward** as their ceiling and pay:

- Easy: **20%**
- Standard: **40%**
- Hard: **60%**

After Beat Stage 100 is claimed, the ordinary SP ceiling is **200 SP**.

Gold ceilings by claimed progression tier remain:

| Claimed progression tier | Gold ceiling |
|---|---:|
| before 10 | 100 |
| 10 | 160 |
| 20 | 250 |
| 30 | 375 |
| 40 | 550 |
| 50 | 750 |
| 60 | 1000 |
| 70 | 1300 |
| 80 | 1650 |
| 90 | 2050 |
| 100 | 2500 |

Existing missions keep their snapshotted reward when progression advances.

## 15.3 First-run tutorial mission isolation

This isolation applies only to the **Hand Holding** tutorial mode.

Before the first intended Castle death, the normal mission board is suppressed so extra missions cannot inject Gold or distract onboarding.

When Missions are introduced, the board contains only the tutorial mission **First Defense**. After it is completed and claimed, no normal replacement is generated until the first guided run ends. Normal Beat Stage + rotating mission generation resumes after the first death/permanent-Skill transition.

The **Basic** and **No Tutorial** modes bypass the guided mission isolation and use normal mission behavior immediately.

## 15.4 Special Missions

Permanent Skill **Special Missions** adds a rare roll whenever a new rotating mission is generated.

Progression:

| Level | Special Mission chance | Cost |
|---:|---:|---:|
| 1 | 2% | 100 SP |
| 2 | 4% | 125 SP |
| 3 | 6% | 160 SP |
| 4 | 8% | 200 SP |
| 5 | 10% | 250 SP |

When the roll succeeds:

- the mission uses Special difficulty/presentation and an appropriately demanding target for its family;
- reward currency is always Skill Points;
- reward is **progression-based**, not random: Special Missions pay **100% of the active SP mission ceiling**;
- ordinary SP missions at the same progression point pay 20% / 40% / 60% for Easy / Standard / Hard;
- mission target/reward/state persist normally through save/reload;
- authored Mission SP is a final payout and is not re-multiplied by run-end SP modifiers.

The active SP ceiling follows the next unclaimed Beat Stage milestone: **10 / 20 / 35 / 50 / 65 / 90 / 110 / 130 / 145 / 160 SP**, then **200 SP** after Beat Stage 100 is claimed.

The **Find Skill Points with Miners** objective is **Special-only**. Miner SP discovery is intentionally rare and RNG-driven, so it is not eligible for the ordinary Easy/Standard/Hard rotating pool.

Special Missions have a deliberately distinct presentation: warm dark-gold card treatment, thicker gold frame/glow, brighter gold header/reward treatment, and a gold progress fill. The goal is that the rare contract reads differently at a glance without changing the normal mission layout.

---

# 16. Auto Claim Missions

New permanent Automation skill.

Goal:

> Automatically claim completed missions one at a time.

Final progression:

| Level | Claim delay | Cost |
|---:|---:|---:|
| 1 | 30 s | 90 SP |
| 2 | 22 s | 150 SP |
| 3 | 15 s | 240 SP |

Behavior:

- timer only matters when at least one mission is complete;
- claims **one mission at a time**;
- after claiming one, the countdown restarts for the next completed mission;
- if multiple are ready, it does not claim all at once;
- no offline auto-claim simulation.

---

# 17. Auto Run Upgrades

A major new Automation subsystem.

## 17.1 Auto Run Upgrades

Purchases random affordable/non-maxed Run Upgrades.

Progression:

| Level | Interval | Cost |
|---:|---:|---:|
| 1 | 30 s | 60 SP |
| 2 | 25 s | 90 SP |
| 3 | 20 s | 135 SP |
| 4 | 15 s | 195 SP |
| 5 | 10 s | 270 SP |

Rules:

- if no upgrade is currently affordable, automation waits for Gold;
- it does not waste the cycle;
- as soon as enough Gold exists, it purchases;
- cycle resets on new run;
- automation does not simulate purchases while offline.

## 17.2 Auto Upgrade Amount

Separate permanent skill.

Requires Auto Run Upgrades.

Progression:

- default: 1 Run Upgrade per batch
- level 1: 2 different upgrades per batch — 150 SP
- level 2: 3 different upgrades per batch — 300 SP

Rules:

- a batch does not buy the same stat twice;
- if only part of the batch can be afforded, it buys what it can and waits for Gold to finish the pending batch before starting a new cooldown.

A future enhancement could allow the player to select preferred Run Upgrades instead of purely random selection.

---

# 18. Towers

Towers are permanent/meta unlockable combat helpers.

Important tuning:

### Unlock

```text
35 SP
```

### Tower Amount

```text
50 / 90 / 150 SP
```

### Attack interval

Base:

```text
2.0 s
```

5 speed levels:

- Lv0 2.00
- Lv1 1.84
- Lv2 1.68
- Lv3 1.52
- Lv4 1.36
- Lv5 1.20

Costs:

```text
10 / 15 / 20 / 25 / 30 SP
```

### Tower Damage costs

Increasing by 10 each level:

```text
10 / 20 / 30 / ... / 100
```

## 18.1 Tower targeting

Tap a Tower to choose:

- Auto
- Warrior
- Archer
- Lancer
- Monk

Elite enemies classify as their base archetype.

Fallback to Auto behavior if no preferred target is valid.

Per-slot priority is saved.

There is a first-unlock tutorial with visual emphasis/pulse.

The Tower-targeting tutorial modal was enlarged substantially because the original was too small on phone.

---

# 19. Game Speed

Permanent Game Speed purchases:

```text
1.5x — 50 SP
2.0x — 150 SP
2.5x — 350 SP
3.0x — 700 SP
```

Total investment to reach 3x is **1,250 SP**. Game Speed is intentionally one of the most expensive permanent tracks because it accelerates combat, stage progression, Mines, Miners, Sheep, regeneration and gameplay automation cooldowns together.

Game speed should scale gameplay systems consistently.

When designing future time-based economy systems, explicitly decide whether timers use:

- gameplay-scaled time;
- real-world time.

Do not leave that ambiguous.

---

# 20. Prestige

Before campaign completion, Prestige is mandatory after beating each 10-stage chapter cap through Stage 90.

The selectable pool currently contains **22 active boons**, normally with **max 3 stacks each**.

Context-specific boons must not occupy a Prestige choice slot before their subsystem exists. Eligibility rules currently include:

- **Master Builder** and **Tower Barrage** -> require at least one active Tower;
- **Shepherd's Blessing** -> requires Sheep/Auto Collect;
- **Foreman's Legacy**, **Prospector's Legacy**, **Deep Insight** -> require Miner House / Miners.

This prevents the player from being offered a boon that currently does nothing.

## 20.1 Active Prestige options

### Warlord’s Legacy
+15% Castle/Tower Damage per stack.

### Stone Legacy
+20% Castle Max HP per stack.

### Swift Legacy
+8% Attack Speed per stack.

### Deadeye Legacy
+5 percentage points Crit Chance per stack.

Current Crit design intentionally has no arbitrary hard 75% cap; the authored Run + Permanent + Prestige maxima naturally remain below 90%.

### Brutal Legacy
+20% Crit Damage per stack.

### Bloodbound Legacy
+5% Lifesteal per stack.

### Living Walls
+25% Health Regen effectiveness per stack.

### Fortune Legacy
+40% enemy Gold per stack.

### Scholar’s Legacy
+20% Skill Points per stack.

Applies to multiplier-aware SP sources such as run/offline rewards, but authored Mission SP remains final and is not re-multiplied.

### Master Builder
+20% Tower Damage per stack.

Requires Towers.

### Shepherd’s Blessing
+15% Sheep speed and +40% Sheep Gold per stack.

Requires Sheep. The Gold bonus stacks additively by stack and applies only to Sheep-collected Gold.

### Quartermaster
-10% Run Upgrade costs per stack.

### Second Wind
+1 lethal-save charge per stack.

Each charge prevents lethal Castle damage and restores 20% HP. Charges reset per run.

### Spiked Walls
+10% Damage Return per stack.

Use actual Castle HP damage received; reflected damage must not recursively trigger itself.

### Double Volley
+10% chance Castle fires an extra projectile per stack.

Extra shot must not recursively proc Double Volley.

### Golden Touch
+10% chance enemy Gold drop is doubled per stack.

### Tower Barrage
+10% chance a Tower immediately fires a second shot per stack.

Requires Towers. It affects Towers only, not the Castle. Extra shots must not recursively proc Tower Barrage.

### Iron Fortress
-10% Castle damage received per stack, max 30% from this boon.

### Aegis Legacy
+5% Max HP rechargeable shield per stack (5% / 10% / 15%).

After 10 seconds without taking damage, shield begins recharging. Health Regen/Lifesteal restore HP rather than shield; shield-absorbed damage does not trigger Spiked Walls.

### Foreman’s Legacy
+15% Miner movement speed and +15% Miner mining speed per stack.

Requires Miner House / Miners.

### Prospector’s Legacy
+20% Gold delivered by Miners per stack.

Requires Miner House / Miners.

### Deep Insight
+20% Skill Points received when Miners discover SP per stack.

This increases the **amount** of SP on a successful Miner SP discovery, not the discovery probability. Requires Miner House / Miners.

## 20.2 Retired options

Removed from future rolls but retained for old-save compatibility:

- Elite Hunter
- Royal Treasury
- Collector’s Legacy
- Prepared Kingdom
- Siege Master

These retired definitions and their compatibility-only runtime branches were removed during C1-B. Pre-release development-save compatibility is intentionally not supported; incompatible saves reset to the current clean schema.

## 20.3 Post-campaign Prestige

The first Stage-100 clear ends the authored campaign **and earns one mandatory Prestige choice**. The Campaign Complete screen appears first; pressing **Choose Prestige** opens the persisted non-cancellable boon choice, and selecting one begins the first post-campaign Stage-1 run.

Afterward, each later Stage-100 clear may offer an optional Prestige choice. The player may also choose **Keep Playing** instead.

If all eligible choices are exhausted but locked subsystem-specific boons remain, communicate that more Prestige paths exist without naming them.

When every selectable boon reaches max stacks, show the one-time **END OF CURRENT CONTENT** message, offer Discord/Keep Playing, and allow unrestricted continuation without further Prestige rewards.

## 20.4 Prestige offer persistence / anti-reroll rule

The exact Prestige cards offered for a given opportunity are now persistent state.

Rules:

- the first Stage-100 completion's earned Prestige becomes mandatory when **Choose Prestige** is pressed and uses the same persisted pending-choice state as chapter Prestiges;
- roll the eligible choices **once** when the Prestige opportunity begins;
- save those exact boon IDs before/while the choice UI is presented;
- closing and reopening the app restores the same choices in the same order;
- closing/canceling and reopening the optional post-campaign Prestige UI does not reroll that opportunity;
- a normal selection must be one of the persisted offered boon IDs;
- choosing a boon consumes the offer;
- abandoning the optional post-campaign opportunity via **Keep Playing** clears that opportunity;
- the next legitimate Prestige opportunity may then roll a new set;
- Hard Reset clears any pending offer.

This prevents save/relaunch reroll farming for a preferred Prestige boon.

---

# 21. Second Wind clarification

This caused confusion because the original card description said:

> Gain 1 Second Wind charge per run

but the intended stack behavior is:

- 1 stack = 1 charge
- 2 stacks = 2 charges
- 3 stacks = 3 charges

The final wording should always communicate both:

- what the charge does;
- that each stack adds a charge.

---

# 22. Mining system

This became a substantial secondary economy/automation loop.

## 22.1 Mine spawning

Base behavior:

- Gold Mine appears every X seconds;
- player can manually tap it;
- Mine contains shared reserve;
- Miners can automate extraction later.

### Active Mine cap

Base:

```text
1
```

Mine Amount upgrades:

```text
1 -> 2 -> 3 active mines
```

Costs:

```text
60 / 120 SP
```

### Spawn Time

Base:

```text
30 s
```

Progression:

```text
30 -> 25 -> 20 -> 15 -> 10 s
```

Costs:

```text
20 / 35 / 55 / 80 SP
```

Important rule:

- if the Mine cap is full, do **not** secretly accumulate spawn timers;
- when a slot becomes available, begin the normal countdown again.

New run/reset should:

- remove active Mines;
- clear Miner carried resources;
- stop mining actions;
- restart full Mine spawn timer.

## 22.2 Mine reserve

Each Mine:

```text
100 base reserve
```

Manual tapping starts intentionally inefficient at **20% extraction efficiency**, but it can now be improved with the Permanent Skill **Manual Mining**.

Efficiency progression:

| Manual Mining level | Manual efficiency | Gold from a full 100-reserve Mine | Cost |
|---:|---:|---:|---:|
| 0 | 20% | 20 Gold | — |
| 1 | 50% | 50 Gold | 8 SP |
| 2 | 80% | 80 Gold | 12 SP |
| 3 | 110% | 110 Gold | 18 SP |
| 4 | 140% | 140 Gold | 26 SP |

The skill is available in the Mining section and does **not** require Miner House. At max level, manual extraction slightly exceeds the normal 100%-efficient Miner baseline.

Manual and automated extraction still consume the same finite Mine reserve. The early-game tradeoff therefore remains, while a player can deliberately invest in a manual-mining play style later.

## 22.3 Mine visuals

A key asset lesson:

The first Mine implementation scaled a small Gold resource image too much, causing ugly pixelation.

Corrected approach:

- use the larger Tiny Swords assets:
  - **Gold Stone 5**
  - **Gold Stone 6**
- keep closer to native PNG size;
- use their corresponding `_Highlight` spritesheets for animation.

Mine was later increased **15%** in visual size.

Both:

- manual tap;
- Pawn mining hit

should trigger a visible spring/squash/rebound feedback animation.

This is important because automated mining otherwise looks disconnected from the resource.

## 22.4 Mine placement

Mines were initially too close to Towers, causing accidental Tower menu openings.

Final direction:

- spawn Mines farther toward the top of the battlefield;
- avoid Castle/Tower interaction zones;
- avoid HUD/dock;
- avoid existing Mines/buildings;
- keep click area clear.

## 22.5 Mine discovery prompt

Before Miner House is unlocked:

- Mine shows `TAP ME`;
- text must not be visually larger than the Mine;
- approximately 112 px wide against ~128 px Mine art;
- visible for 3 seconds;
- hidden for 5 seconds;
- repeats;
- disappears when Miner House unlocks or Mine depletes;
- prompt must not intercept Mine clicks.

---

# 23. Miner House

Permanent one-time skill:

```text
40 SP
```

Adds the Miner House using:

```text
House2.png
```

Placement requirement:

- House should appear up near/behind the upper tree line;
- if necessary move trees farther out and place House there;
- the building should feel integrated into the battlefield, not dropped on top of combat.

Starts with:

```text
1 Pawn Miner
```

## 23.1 Miner Amount

Maximum:

```text
4 total Pawns
```

Additional miner costs:

```text
50 / 90 / 150 SP
```

## 23.1.1 Miner target distribution

When a Miner needs a new Mine target:

1. collect all active, non-depleted Mines;
2. prefer Mines that no other Miner currently targets;
3. if several free Mines exist, choose randomly between them;
4. if every Mine already has a Miner, choose randomly among all valid Mines.

A Miner keeps the chosen target while traveling/mining instead of rerolling continuously. Save/resume must preserve the exact current Mine target and phase. After that assignment ends, the next target uses the distribution logic above.

This preserves natural spreading while still supporting up to four Miners when the Mine cap is three.

## 23.2 Pawn loop

Core worker loop:

```text
House
-> travel to Mine
-> play mining animation
-> extract
-> fill carry
-> return House
-> deposit
-> repeat
```

Pawns directly carry their resource output.

They do **not** spawn loose Gold pickups during automated mining.

Sheep collect only loose pickups.

---

# 24. Miner skills

## 24.1 Carry Capacity

Chosen baseline:

```text
20
```

Carry Capacity upgrades exist.

The system was designed so Miners can perform several extractions before returning.

## 24.2 Movement Speed

5 levels.

```text
+15% per level
```

Costs:

```text
8 / 12 / 18 / 26 / 38 SP
```

## 24.3 Mining Speed

Originally much too fast.

Final intended timing:

```text
Base: 15 seconds/extraction
Max upgrade: 5 seconds/extraction
```

Progression:

```text
15 -> 13 -> 11 -> 9 -> 7 -> 5 seconds
```

Costs remain the existing Mining Speed costs:

```text
10 / 15 / 22 / 32 / 46 SP
```

## 24.4 Miner Gold Yield

5 levels.

```text
+20% per level
```

Costs:

```text
12 / 18 / 27 / 40 / 60 SP
```

The player-facing name is **Miner Gold Yield**.

It increases **Gold extracted by Miners by 20% per level**. It does **not** increase Skill Point finds.

Yield increases Gold reward, not reserve. Reserve consumption stays consistent. A successful Skill Find extraction still yields SP instead of Gold, and its SP amount is governed by the SP-specific systems rather than Miner Gold Yield.

## 24.5 Skill Find Chance

Miner House grants base:

```text
1%
```

Then +1 percentage point per upgrade until 10%.

Costs:

| Chance | Cost |
|---:|---:|
| 2% | 30 |
| 3% | 40 |
| 4% | 50 |
| 5% | 65 |
| 6% | 80 |
| 7% | 100 |
| 8% | 125 |
| 9% | 155 |
| 10% | 190 |

Each mining extraction rolls once.

On success:

- extraction yields SP instead of Gold;
- reserve is still consumed;
- SP is carried separately.

Pawn SP carry cap:

```text
5 SP
```

Scholar’s Legacy should apply to mined SP because it is a normal SP source.

---

# 25. Offline rewards

Offline rewards are available after the player has meaningfully started progression.

Activation logic included:

- complete at least one run/death, or
- reach Stage 5.

No offline-reward modal for absences under roughly:

```text
60 seconds
```

## 25.1 Offline Gold

Original base rate:

```text
2 Gold/min
```

Rebalanced base rate:

```text
1 Gold/min
```

Formula:

```text
Offline Gold =
1 Gold/min
× stage multiplier
× offline minutes
× Offline Coin Efficiency
```

Stage multiplier:

```text
1 + (highest_stage_ever × 0.15)
```

Offline Coin Efficiency:

```text
1 + (level × 0.10)
```

Offline time cap:

- base: 4 hours
- +1 hour per level
- max: 8 hours

Permanent Gold Gain still applies to final credited Gold.

The popup was fixed to display the **actual final amount after Gold Gain**, rather than showing the pre-Gold-Gain amount.

## 25.2 Offline SP

Offline SP is a deliberate permanent-progression branch.

Unlock:

```text
Offline Skill Rewards: 30 SP one-time unlock
```

After unlock, the base rate is fixed and **does not scale with highest stage**:

```text
2 SP/hour
```

Offline Skill Efficiency is the only direct rate upgrade:

```text
+40% per level, 10 levels
```

Current costs:

```text
20 / 25 / 32 / 40 / 50 / 62 / 76 / 92 / 115 / 145 SP
```

Resulting base offline-SP rate:

| Efficiency level | Rate before earned SP bonuses |
|---:|---:|
| 0 | 2.0 SP/h |
| 1 | 2.8 SP/h |
| 2 | 3.6 SP/h |
| 3 | 4.4 SP/h |
| 4 | 5.2 SP/h |
| 5 | 6.0 SP/h |
| 6 | 6.8 SP/h |
| 7 | 7.6 SP/h |
| 8 | 8.4 SP/h |
| 9 | 9.2 SP/h |
| 10 | 10.0 SP/h |

The shared 4–8 hour Offline Time cap still applies. After base offline SP is calculated, normal **earned** SP modifiers such as Permanent Skill Reward and Scholar's Legacy are applied through the shared SP reward path.

## 25.3 Offline modal

The original Welcome Back panel was too small on phone and was enlarged to the current mobile-readable presentation.

The release-build QA pass added a second requirement: the modal must behave like a **reward receipt**, not an opaque total. It shows both total Gold and total SP, with the actual inputs/multipliers used below each value.

Current Gold presentation concept:

```text
Base: 60 Gold/h × 4.00h = 240 Gold
Bonuses: Stage ×1.75 · Offline ×1.00 · Gold Gain ×1.00
Total: 420 Gold
```

Current SP presentation concept:

```text
Base: 2 SP/h × rewarded hours = base SP
Bonuses: Efficiency ×N · Skill Reward ×N · Prestige ×N
Total: final SP
```

The formula text must describe the same calculation that produced the credited value. Do not display an approximate/explanatory formula that differs from runtime math.

---

# 26. Save / resume / offline persistence

The project uses one clean pre-release JSON save schema:

```text
user://everfort_save.json
SAVE_VERSION = 3
```

**Probe save isolation (mandatory, 2026-10-14):** no automated probe may read, write, delete, rename or restore `user://everfort_save.json`. Processes launched on a `res://tests/` entry point (or with `--probe-save-sandbox`) persist only to `user://probe_sandbox/everfort_probe_save.json`. Any other path makes `SaveService` exit with code 2 before touching a file. Every probe starts `_ready()` with `SaveService.assert_probe_save_isolated()`, and `tests/probes/save_isolation_probe.tscn` enforces this. Full rule: `docs/README.md`, "Probe save isolation".

Pre-release development-save compatibility was deliberately removed during C1-B. Missing, corrupt, or version-mismatched saves reset to fresh current defaults instead of running a migration ladder. C2-A bumped the schema from 1 -> 2 and C2-B from 2 -> 3; no compatibility migrations were added because the game has not entered its public-save compatibility window. Defensive `.get(key, default)` handling remains for missing fields inside the current schema.

Autoloads include:

- Balance;
- RunState;
- MissionState;
- EncyclopediaState;
- SaveService;
- SettingsState.

Active-run persistence includes:

- Gold;
- Run Upgrades;
- current stage;
- Castle HP;
- exact StageSpawner progress;
- pending Gold pickups;
- Mine positions/reserve/timers;
- exact surviving-enemy snapshots;
- exact Miner/Pawn runtime snapshots;
- Prestige run-state mechanics such as Second Wind/Aegis where applicable;
- guided-tutorial gate state needed to prevent reload bypasses;
- ordinary stage-clear transition state so relaunch cannot replay the same clear.

### Exact enemy resume contract

C2-B replaced aggregate-only survivor reconstruction. Every living enemy that must survive close/reopen is snapshotted with:

- exact definition/archetype ID (Elite vs regular is part of the ID);
- exact current HP;
- world position.

On resume the same survivors are reconstructed. They must not be rerolled, full-healed, duplicated, or re-credit kill/mission progress merely because they were restored. Already-spawned dead enemies remain dead; the unspawned remainder of the stage continues normally. Attack/charge/Monk-heal cycle timers are intentionally allowed to restart conservatively rather than over-serializing ephemeral combat animation/timing state.

### Exact Miner resume contract

C2-B persists each Miner/Pawn's meaningful runtime state rather than only carry:

- slot;
- Gold carry;
- SP carry;
- phase (`IDLE`, traveling to Mine, mining, returning home);
- world position;
- target Mine slot when applicable;
- remaining extraction time while mining.

`MiningGroup.force_sync_runtime()` pulls a fresh live snapshot at the save boundary so movement/mining position is not serialized from a stale cached Dictionary. Relaunch must not teleport a Miner home, instantly deposit carry, skip travel, or finish extraction sooner than uninterrupted play.

The C2-B probe initially reported a dangling Mine reference, but investigation showed the probe had created an impossible production state: Miner House progression was injected while `tutorial_mode` was still unselected, causing the tutorial Mine gate to remove the restored Mine during boot. Production code was left unchanged; the probe was corrected to establish a legitimate deterministic tutorial mode before `Main` initializes.

### C2-A lifecycle guarantees

C2-A closed four additional reload/lifecycle gaps:

- **Death -> close -> relaunch:** stale Mine/Miner carry state cannot leak into the fresh Stage-1 run.
- **Offline Reward before Claim:** an unresolved Welcome Back reward is persisted until actually claimed, so background/kill/relaunch cannot consume the offline interval without preserving the reward.
- **Stage Clear during transition:** an already-processed ordinary stage clear is persisted so force-close/relaunch cannot increment Clear Stages / healthy-clear mission progress repeatedly for the same clear.
- **Settings:** SettingsState changes participate in the dirty-save path rather than relying only on an unrelated later save.

Persistent profile/meta data also includes:

- first-cleared-stage records for one-time SP rewards;
- tutorial mode and Hand Holding tutorial step/hard-gate state;
- manual Gold-pickup tutorial count;
- campaign-completed state;
- persisted Stage-100 / Prestige-offer state;
- end-of-current-content acknowledgement;
- optional post-tutorial Bestiary hint state;
- panel-pause preferences;
- interaction-lock preference;
- audio/settings preferences.

Castle HP is saved clamped between:

```text
1 .. max HP
```

Dead runs are not valid active resumable runs.

Important persistence principle:

> Closing/reopening must not restore value, reroll valuable state, duplicate progression, skip meaningful travel/work, reset a tutorial grace period, or allow the player to bypass a mandatory interaction.

Examples:

- Gold tutorial manual pickup count persists;
- Gold/Mission wave-grace boundaries persist;
- if a mandatory Gold interaction restores without a pickup, the tutorial must recreate a solvable pickup state;
- pending Prestige choices persist in the same order and cannot be rerolled by force-close;
- Stage-100 pending/replay state must not duplicate run rewards;
- unresolved Offline Reward value persists until Claim;
- surviving enemies resume with the same identity/HP/position;
- Miners resume the same meaningful travel/mining/return state.

Hard Reset must reset:

- profile;
- SP;
- Permanent Skills;
- Prestige;
- Towers;
- Sheep;
- Castle visual evolution/tint;
- Mines;
- Miners and runtime snapshots;
- carried Gold/SP;
- tutorial mode/completion/gates;
- first-cleared-stage records;
- campaign/end-content flags;
- target preferences;
- interaction lock;
- game speed;
- active run and enemy snapshots;
- save state.

A previous bug reset SP internally but left the UI stale because the wallet signal was not emitted. The reset flow was updated to emit `skill_points_changed`.

Lesson:

> Resetting serialized data is not enough. Live runtime objects, pending transitions, UI listeners, and save-boundary snapshots must all agree on the same lifecycle state.

---

# 27. New Enemy Incoming milestone popup

A recurring visual bug occurred because the popup used the entire enemy spritesheet strip as one image.

Correct approach:

- extract one representative frame;
- crop transparent padding;
- scale the actual enemy, not the full strip;
- reuse generic sprite-sheet extraction logic;
- apply to all regular and Elite enemies.

Target visible portrait size was roughly:

```text
180–250 px visible enemy height
```

depending on proportions.

This should not require separate portrait assets if the gameplay spritesheets are already suitable.

---

# 28. Enemy / Castle render ordering

A bug occurred when enemies died or fought near the Castle and appeared behind it.

Lesson:

- combat actors should render above major static buildings when they overlap;
- use `y_sort_enabled` where appropriate;
- ensure consistent y-sort on:
  - Entities
  - Towers
  - Sheep
  - Pawns / workers
- resource pickups may need explicit higher draw priority so they remain visible near the Castle.

Do not solve all overlap problems with arbitrary `z_index` values. Prefer coherent y-sort groups.

---

# 29. Tiny Swords asset usage

The project uses Tiny Swords assets extensively.

## 29.1 Buildings

Buildings are commonly static PNGs.

Examples used:

- Castle building
- Tower buildings
- `House2.png` for Miner House

## 29.2 Units

Units generally come as spritesheets.

Never display an entire spritesheet directly in UI.

For portraits / Bestiary / reveal cards:

1. determine frame layout;
2. extract one representative frame;
3. crop transparent padding;
4. scale the cropped result;
5. preserve pixel-art filtering settings.

## 29.3 Gold/resource assets

Important files/asset families:

- Gold Resource
- `Gold_Resource_Highlight.png`
- Gold Stone 5
- Gold Stone 6
- their `_Highlight` versions

The highlight sheets were better for making resource objects feel alive.

## 29.4 Pawn

A known uploaded/reference asset:

```text
Pawn_Idle Gold.png
```

Pawn units also have relevant mining animations in the asset set.

## 29.5 Asset rule learned

Do not enlarge a small PNG aggressively just because it is the easiest file to use.

Before implementing:

1. inspect the asset pack for larger variants;
2. inspect `_Highlight`, `_Idle`, `_Attack`, `_Run`, `_Mine`, `_Gold`, etc.;
3. use the largest native asset appropriate for the desired on-screen size;
4. crop transparency before scaling.

This single decision materially improves visual quality.

---

# 30. UI reference resolution and responsiveness

The UI moved toward a **1920 × 1080 reference layout**.

This worked well for:

- desktop QA;
- predictable mobile downscaling;
- clear sizing relationships.

Important:

- reference resolution is not the actual phone resolution;
- UI must still use anchors/containers and respond to aspect ratios.

## 30.1 Mobile-first design principles learned

### Touch targets

Every interactive gameplay element should have:

- larger hit area than visible sprite when appropriate;
- enough spacing from adjacent interactive systems;
- no overlapping click zones.

Mine/Tower misclicks demonstrated why this matters.

### Text

Phone gameplay text needs to be much larger than desktop intuition suggests.

Do not wait until final polish to test actual device readability.

### Bottom UI

Avoid placing critical buttons exactly against the bottom edge.

Cards were clipped when:

- dock was too tall;
- parent containers pushed content below viewport;
- modal controls were laid out outside the parchment background.

### Scrolling

Touch-scroll areas need explicit testing.

A desktop mouse wheel does not reveal all mobile scroll issues.

### Three-column skill grid

Three cards per row was the best compromise between:

- enough cards visible;
- large card text/icons;
- mobile tap comfort.

More columns made cards too small.

---

# 31. Tutorial / onboarding

Fresh profiles now begin with a **tutorial mode chooser**. The player decides how much onboarding they want:

1. **Basic Tutorial** — five concise cards that explain the core game;
2. **Hand Holding Tutorial** — the full state-driven guided first-run experience;
3. **No Tutorial** — immediately use normal gameplay with no tutorial restrictions.

The selection is persisted. Hard Reset returns the profile to an unselected state so the chooser appears again.

Current-schema persistence rule:

- `tutorial_mode` is saved directly as Basic / Hand Holding / None / unselected;
- Hard Reset returns it to unselected so the chooser appears again;
- compatibility inference for pre-chooser development saves was removed in C1-B.

## 31.1 Basic Tutorial

The Basic Tutorial pauses gameplay only while its five cards are being read:

1. **DEFEND THE CASTLE**
2. **COLLECT GOLD**
3. **RUN UPGRADES**
4. **PERMANENT SKILLS**
5. **BEAT STAGE 100**

It is informational only. After the fifth card, normal gameplay begins with no special Gold budget, mission isolation, forced tutorial Mine, required Permanent Skill purchase, or other Hand Holding gates.

## 31.2 Hand Holding tutorial rules

The Hand Holding tutorial is the existing state-driven onboarding sequence.

Only the three-card opening story blocks/pauses gameplay. After that, guidance is non-blocking and the tutorial controls progression using only two combat modes:

```text
Normal
Hard gate
```

There is deliberately **no Castle invulnerability/protected mode**. The tutorial must not change combat balance or allow the Castle to become an artificial invincible fort.

A hard gate pauses future enemy spawning/stage progression at a safe wave boundary; it does not alter Castle HP, enemy damage, or existing combat rules.

## 31.3 Current Hand Holding sequence

Opening story cards:

1. **THE KINGDOM IS UNDER SIEGE**
2. **THE CASTLE MUST HOLD**
3. **THE CASTLE STILL STANDS**

The story uses the blue ribbon/header treatment and manual Continue progression so the opening cannot disappear before it is read.

Core flow:

```text
Opening story
-> Defend Castle / defeat first enemies
-> Collect Gold
-> Buy first Run Attack/Damage upgrade
-> finish the current enemy wave so the player feels the improvement
-> introduce Missions
-> complete + claim First Defense
-> introduce forced tutorial Mine
-> Keep Defending
-> first natural Castle death
-> SP reward / Permanent Skills lesson
-> buy required Permanent Attack
-> show real Attack old -> new
-> restart
-> Beat Stage 10 goal
-> first mandatory Prestige
-> final tutorial message
-> optional Bestiary discovery hint
```

## 31.4 Gold tutorial / first-run economy

The Gold lesson requires:

- at least **3 manually tapped Gold pickups**;
- enough current Gold to afford the required first Run Attack/Damage purchase.

The player gets up to **2 completed wave clears** before the next wave is hard-gated if the requirement is still unfinished.

The first guided run has an invisible total Gold-earn budget of:

```text
170 Gold
```

This budget tracks **total Gold earned**, not current wallet balance, so spending Gold does not reopen the budget.

Enemy drops, the tutorial Mission payout, and the first tutorial Mine payout count toward the same budget. Mandatory tutorial rewards are reserved so ordinary enemy drops cannot consume the whole budget first.

When the cap is exhausted, Gold generation is silently limited rather than disabling the player's upgrade choices. The cap disappears when the first run is banked.

## 31.5 Mission tutorial gating

Before the first intended death:

- normal rotating missions are suppressed;
- Beat Stage progression missions are suppressed;
- only **First Defense** is shown when Missions are introduced;
- after First Defense is claimed, no replacement mission appears until the first run ends.

If the completed tutorial mission is not claimed, allow up to 2 more wave clears, then hard-gate future progression until Claim is pressed.

This avoids extra Mission Gold and keeps the first run focused.

## 31.6 Mine tutorial

Before the Mine lesson, normal Mines must not appear.

The tutorial Mine is forced into the **far-right authored Mine slot** so it stays visually clear and is not obstructed by the Castle/trees/UI.

During the first-run Gold cap, this is the only Mine that may spawn. After the first run is banked and the 170-Gold cap is removed, normal random Mine spawning resumes even though later tutorial steps may still be active.

After the player manually taps the tutorial Mine:

- release the Mine hard gate;
- resume normal combat;
- show **KEEP DEFENDING** for **15 real-time seconds** only.

## 31.7 First defeat / Permanent Skills

The first intended Castle death is allowed to happen naturally; no scripted Stage-8 death and no tutorial invulnerability are used.

On that first Defeat screen:

- normal SP reward receipt remains visible;
- Restart is disabled;
- the existing reward-area tutorial text explains permanent progression;
- a yellow tutorial circle/arrow points to **Permanent Skills**;
- no extra overlapping tutorial message is shown.

When Permanent Skills opens for the first time:

- Permanent Attack/Damage is automatically the guided choice;
- all other Permanent Skills remain visible but are temporarily disabled so the player cannot spend the tutorial SP elsewhere by mistake;
- a yellow target marker points to Damage;
- after the required purchase, normal Skill choices are restored;
- show the real base Attack increase (`old -> new`) for about 5 seconds;
- then Restart becomes available.

## 31.8 Prestige / Bestiary messaging

After the restart, the tutorial communicates:

> **BEAT STAGE 10** to unlock your first Prestige.

The Stage-10 goal message lasts **15 seconds** and then dismisses automatically.

The first Prestige/chapter guidance also lasts **15 seconds**; it should not remain permanently on screen.

After the player completes the first Prestige:

- show the final core tutorial message (Automation/future build direction);
- mark the core tutorial complete;
- then reveal Bestiary with a lightweight optional hint such as “Check enemy details here whenever you want.”

Bestiary does **not** gate combat and does **not** require clicking Warrior anymore. The hint may remain until the player eventually opens Bestiary.

## 31.9 Tutorial panel layout / modal priority

Non-blocking guide panels live in the **upper-center battlefield band immediately below the HUD**, not over the Castle, top menus, run-upgrade dock, or Mine interaction area.

The panel is viewport-relative and ignores mouse/touch input outside its actual controls.

UI priority:

```text
Pause / Defeat / Prestige / other full-screen modal
-> tutorial guide
-> normal HUD
```

Unrelated tutorial messages must hide/suspend while a full-screen modal is active and resume afterward when still relevant.

Action-required messages may remain until their condition is met. Pure informational messages should use a finite duration (typically ~15 seconds for important guidance).

---

# 32. Settings, pause behavior, zoom, and audio

Settings includes infrastructure for:

- SFX toggle/volume;
- Music toggle/volume;
- **Panel Pause Options**;
- Hard Reset;
- debug section;
- **Join Discord**;
- current game version display (read from `application/config/version`).

Current mobile-control presentation:

- SFX and Music **volume** use the same visual language as the gameplay Zoom slider, with a large grabber and generous touch area;
- binary SFX/Music enabled state uses a large checkbox, not a draggable slider;
- Panel Pause Options also use large checkboxes with the whole row easy to tap;
- continuous controls should be easy to drag precisely, while binary controls should remain one-tap decisions.

## 32.1 Player-configurable panel pausing

The player may independently choose whether opening each normal battle-HUD panel pauses gameplay:

- Permanent Skills;
- Missions;
- Bestiary;
- Prestige;
- Statistics.

Each preference is persisted and defaults to **off**, preserving the original real-time behavior unless the player opts in.

The Pause menu itself always pauses. Settings remains part of the Pause flow. Statistics now has a direct battle-HUD button and follows its own player-configurable pause preference.

Any interactive modal that can appear while another panel owns `SceneTree.paused` must remain input-responsive while paused. The current pause-safe blocking modal set includes:

- first Tower targeting tutorial;
- generic feature-unlock popup (including Miner House and Castle Targeting);
- New Enemy milestone reveal;
- Offline Reward;
- Chapter Complete;
- Campaign Complete;
- Prestige boon selection.

This was required after a soft-lock where buying the first Tower/Miner from a player-paused Skills screen opened a popup that could not process its Continue button.

## 32.2 Gameplay zoom

Gameplay zoom is controlled only by the **right-side HUD slider**.

```text
100% -> 150%
```

Pinch/magnify gesture zoom is intentionally disabled. HUD/modals remain screen-space UI while the battlefield Camera2D changes zoom.

## 32.3 Castle/Tower interaction lock

A persistent icon-only **target interaction lock** sits directly above the zoom slider. It uses only an open/closed padlock; the tooltip explains that it controls Castle/Tower target-menu interaction without consuming HUD space with a permanent text label.

- unlocked (default): tapping a Tower or an unlocked Castle opens its target-priority selector;
- locked: Tower/Castle taps do not open targeting selectors;
- Gold, Mines, HUD buttons, and other gameplay interactions remain unaffected;
- existing Tower/Castle priority choices and combat targeting continue normally;
- turning the lock on closes any selector already open;
- the open/closed padlock communicates the current state, the button background remains fully transparent in every interaction state, and a brief visual pulse confirms changes; the tooltip explains the control's purpose;
- visual language: warm Everfort gold/cream with a dark-brown outline; **locked** uses the stronger gold state, **unlocked** uses a lighter cream/gold state with a clearly open shackle and large visible gap; no reticle/target graphic remains;
- the preference persists through save/reload and Hard Reset returns it to unlocked.

## 32.4 Settings layout/version

The Settings body is scroll-safe and uses compact rows: SFX and Music each share one row with their volume slider and toggle, while Join Discord and Panel Pause Options share a two-column action row. The Panel Pause subpanel also uses a 2-column option grid. This prevents later Settings additions from overflowing the parchment/panel.

The player-facing version label reads `application/config/version`. Current project version is **2.1.1**. Android `version/name` is intentionally blank so the exporter inherits this same value; Android `version/code` is **18** in the current ZIP and must be incremented separately for each Play Console upload.

Community Discord is centralized as:

```text
https://discord.gg/kc2zbe9Y4h
```

The same centralized community-link helper is used by Settings and the Stage-100/end-of-content screens rather than duplicating the URL in several UI scripts.

AudioService is now populated with the selected sparse shipping audio set.

Current mapping:

```text
background_music.wav -> looping gameplay music
ui_click.wav         -> normal UI navigation/close/toggle actions
ui_confirm.wav       -> successful manual purchases and claims
ui_error.wav         -> rejected manual actions
mission_ready.wav    -> a Mission first reaches its target
stage_clear.wav      -> every legitimately processed stage clear
reveal_unlock.wav    -> New Enemy Incoming and feature-unlock reveals
defeat.wav           -> Castle defeat/run loss
```

Prestige and Campaign Complete do not currently have dedicated selected assets. Campaign completion still receives the ordinary Stage Clear cue because Stage 100 was cleared, but there is no second campaign-specific sound. Prestige remains silent beyond ordinary UI clicks.

Audio is intentionally sparse. Enemy hits/deaths, Castle attacks/hits, projectiles, Gold pickups, Mine taps, Miner work, Sheep collection and other high-frequency automation remain silent. Automatic Run Upgrade purchases and automatic Mission claims also stay silent. The audio layer should emphasize player decisions and meaningful state changes rather than narrating every simulation tick.

---

# 33. Debug tools

Debug panel includes support for:

- Coins;
- Skill Points;
- jump to stage;
- reset run;
- save now;
- complete active Missions;
- discover all Bestiary entries;
- **Spawn Special Mission**;
- campaign/chapter/Prestige QA controls.

**Spawn Special Mission** deterministically replaces the first available rotating slot with a Special Mission. It bypasses the normal 2–10% Special Mission probability for QA, but does not replace the Beat Stage progression slot or the Hand Holding tutorial mission.

A Stage 10 “freeze” was diagnosed as a modal layering/pause issue, not an Archer logic freeze.

Cause:

- Debug opened from paused Settings;
- milestone reveal triggered;
- Debug CanvasLayer sat above the milestone popup;
- game appeared frozen.

Fix pattern:

- close Debug before milestone reveal;
- unpause appropriately;
- do not allow hidden modal state to block milestone interaction.

Lesson:

> Many apparent gameplay freezes are actually UI modal/layer/pause-state bugs.

---

# 34. Hard Reset

Hard Reset had several issues throughout development.

Final expectations:

- reset profile/SP;
- immediately remove Towers;
- remove Sheep;
- remove Mines;
- reset Miners and carried resources;
- clear Castle evolution/tint;
- reset target priorities;
- reset game speed to 1x;
- reset tutorial completion;
- reset active run to Stage 1;
- save the new clean state;
- refresh every visible UI value.

Hard Reset should be tested after every new persistent/meta system is added.

---

# 35. Visual polish pass

A major visual pass improved:

- HUD scale
- dock size
- Castle size
- Tower size
- enemy size
- Sheep size
- coin/projectile size
- Bestiary grid
- Settings panel
- water band
- trees/rocks/foam
- y-sort
- battlefield composition

Representative changes included:

- Castle scale: 1.7 → 2.0
- Towers: 0.6 → 0.7
- enemies: ~+22%
- Sheep: ~+20%
- projectiles: ~+20%

Coins later needed a separate correction because their enlargement became too much.

The Bestiary evolved from a very large-card selector toward a denser mobile-readable layout.

---

# 36. Bestiary

Bestiary functionality remains:

- enemy selector grid;
- selected-enemy detail area;
- discovered/undiscovered state;
- HP;
- damage or heal amount;
- behavior/special description;
- encounter stage;
- combat/reward information.

For Monk, display **HEAL** rather than fake damage and describe its support/heal behavior accurately.

## 36.1 Final A7.2 visual direction

The supplied Tiny Swords **Enemy Pack** reference is now the visual authority for the selector-board portion of the Bestiary.

Required look/behavior:

- parchment/paper board similar to the owner reference;
- large gold/yellow title ribbon across the top;
- decorative **double swords behind the title**;
- grid of enemy slots below the selected-enemy information region;
- undiscovered enemies use a simple `?` treatment similar to the unknown cells in the reference;
- discovered enemies show the real enemy **animated in place**;
- discovered-cell animation cycles authored states such as `Idle -> Walk -> Attack -> repeat`;
- Monk uses its appropriate Heal/support action animation instead of pretending to have a normal attack when necessary;
- do not reproduce the lower decorative portion of the reference image; focus on its title + board/grid language.

The current Everfort information architecture stays useful: **selected-enemy data remains above, enemy selector grid remains below**.

The selected detail area may be improved more freely than the grid. Current intended presentation includes readable exact values plus quick relative-strength bars for concepts such as:

- Vitality;
- Power / Heal strength;
- Speed;
- Special cadence/impact.

Colored comparison bars are supplemental only: exact meaningful numbers/behavior must remain visible. They must not become hidden gameplay formulas or alter balance.

Sprite handling rules:

- never show an entire spritesheet in a portrait/cell;
- use authored animation frames;
- crop transparent padding for UI display when needed;
- keep gameplay spritesheets untouched;
- preserve pixel-art filtering/scaling discipline.

---

# 37. Floating numbers

A reusable floating-number system exists.

The project uses it for:

- damage;
- healing;
- lifesteal;
- reflected damage;
- Gold;
- SP/resource feedback;
- Mine/resource feedback.

Current phone-readability direction:

- normal world-space feedback such as damage, healing and resource pickup remains large;
- display lifetime was doubled from the earlier short timing so values remain readable on a phone;
- crit/charged feedback keeps its longer relative lifetime as well;
- overlap/grouping timing was extended with the display lifetime so repeated values do not immediately pile on top of one another;
- do not increase travel distance merely because font size/lifetime increased.

Sheep Gold feedback should expose the Prestige contribution without delaying the actual wallet credit. With Shepherd's Blessing, the wallet receives the fractional amount immediately and the floating text can show the total plus the explicit bonus contribution.

---

# 38. Enemy HP and special-action indicator

The old segmented special/charge indicator was replaced during A7.1D.

Current presentation:

```text
[ special/action SmallBar, no tiny text ]
[ HP SmallBar, no tiny numeric text ]
[ enemy sprite ]
```

Both use the Tiny Swords SmallBar visual language. The special/action bar uses a distinct cyan/blue fill so it cannot be confused with HP. Numeric text was intentionally removed because it became too small to read reliably on the phone. The bar progression itself remains tied to the truthful action-count mechanic rather than a fake timer. Current cadence:

| Archetype | Special/support trigger |
|---|---:|
| Warrior | every 3rd attack |
| Archer | every 4th attack |
| Lancer | every 4th attack |
| Monk | every 3rd support action |

Elite variants keep the same cadence as their base archetype; elites become stronger through authored stats/effects rather than secretly changing the learned rhythm.

Do not reintroduce tiny HP/special text simply to expose exact counts. If exact values are needed elsewhere, present them in a readable panel such as the Bestiary rather than overloading combat sprites.

---

# 39. Damage return / shields / survivability interactions

Important combat interaction rules:

## Spiked Walls

- reflect based on actual Castle HP damage received;
- non-recursive.

## Iron Fortress

- reduces incoming Castle damage before shield/HP.

## Aegis

- shield absorbs after damage reduction;
- shield does not count as HP damage for Spiked Walls;
- health regen does not refill shield;
- lifesteal restores HP only.

## Second Wind

- only triggers on otherwise-lethal damage;
- restores Castle to 20% HP;
- one charge consumed.

These order-of-operations rules must remain explicit in future refactors.

---

# 40. Numbers / formatting

Displayed numbers use two decimals where appropriate.

Gold is now a real fractional wallet value rather than an integer-only currency. Normal purchases may still have whole-number costs, but fractional remainder is preserved. Example: 10.40 Gold minus a 10 Gold purchase leaves 0.40 Gold. Save/load and mission/stat tracking must not silently cast Gold back to an integer.

Abbreviation ladder includes:

- K
- M
- B
- T
- Qa
- Qi
- Sx
- Sp
- Oc
- No
- De
- Un
- Du
- Tr
- Qu
- Qd
- sd
- Sd
- Od
- Nd
- V
- etc.

Keep number formatting centralized.

Do not duplicate formatting logic across HUD, Skills, Missions, offline rewards, floating text, and stats.

---

# 41. Current publishing direction

Everfort has reached **Google Play release-candidate review/stabilization**.

Current publishing state:

- premium;
- no ads;
- store listing/setup completed by the user;
- release AAB already generated and uploaded to Play Console;
- current release is awaiting Google review / release processing;
- ongoing QA is being performed against the **actual exported Android release build**, not only the editor/debug environment.

Current project/export identity:

```text
Project version:            2.1.1
Android version code:       18
Android version name:       blank -> inherits project version
Package ID:                 com.shekinahwelefuldesigns.everfort
Primary target:             Android / Google Play
Orientation:                landscape
```

Store/support references recorded for continuity:

```text
Website:        https://shekinahandroidapps.web.app/
Privacy repo:   https://github.com/yobonill/GamesPrivacyPolicies/tree/master
```

The project already contains the Android/export/store asset preparation used for publishing, including launcher/adaptive/Play Store icons, feature graphic and reusable screenshot-capture tooling.

## 41.1 Branding and store-art continuity

The **Everfort** name is locked. The launcher/store icon family was deliberately derived from the game's own Tiny Swords sword artwork rather than from generic fantasy iconography. The current project includes the joined-sword source/preview plus launcher, adaptive foreground/background/monochrome, 512 px Play Store, and 1024 px master icon assets.

Store graphics currently present include:

```text
assets/icons/store_graphics/Everfort_Feature_Graphic_v2_1024x500.png
assets/icons/store_graphics/Everfort_Screenshot_01_Left_2560x1440.png
assets/icons/store_graphics/Everfort_Screenshot_02_Right_2560x1440.png
```

A separate official logo/wordmark direction was also established in the project conversations: exact text **EverFort**, highly readable at small sizes, chunky/stylized 2D medieval treatment, and visual language derived from the actual Everfort/Tiny Swords world rather than a generic RPG/fantasy logo. Crossed-sword/battlement motifs were explored. The latest full ZIP does **not** contain a standalone committed runtime asset with `logo`/`wordmark` in its filename, so future chats must not assume a generated chat image is already integrated. Verify the ZIP before wiring any logo candidate into the game or store art.

Reusable branding lesson: when the game is built from a strong asset family, derive iconography, wordmark weight, palette, borders, and decorative motifs from that authored language first. Genre conventions are secondary.

Release rule now:

> Do not create a new broad development phase. Continue release-build playtesting, fix only demonstrated release blockers/regressions or deliberately approved balance corrections, rebuild with a higher Android version code, and re-upload/update the Play Console release when runtime code changes.

---

# 42. Current tentative / intentionally NOT implemented

## Special attacks / lightning

Tentative idea:

> unlock special attacks such as lightning every X seconds against a random enemy.

This was explicitly **not implemented**.

Do not assume it is approved.

Possible future direction:

- permanent unlock;
- cooldown upgrades;
- damage/effect upgrades;
- target selection;
- visually distinctive VFX.

But evaluate whether it improves the game or just adds system bloat before committing.

---

# 43. Current finalization status

Everfort's planned implementation/QA phases are effectively complete. The project is now in **release stabilization**, not another feature phase.

Completed:

- final feature synchronization;
- C0/C1 cleanup;
- C2 persistence/lifecycle work;
- save schema v3 and exact runtime snapshot fidelity;
- A7 environment/HUD/run-upgrade/gameplay-interaction/main-panel/secondary-panel work;
- physical Android UI acceptance;
- long-form gameplay/balance testing;
- store setup and Play Console submission;
- actual exported release-build testing.

C2 final probe evidence remains:

```text
checkpoint_c2b_probe:       49 pass / 0 fail
post_cp6_probe:             78 pass / 0 fail
restart_lifecycle_probe:   110 pass / 0 fail
```

Current remaining work is intentionally narrow:

- continue playing the exact release build;
- fix concrete crashes, softlocks, progression blockers, persistence regressions, misleading UI, or balance defects actually observed in release play;
- regression-test adjacent systems after each fix;
- increment Android version code and upload a replacement AAB whenever runtime code changes;
- once the corrected release candidate is stable, stop changing it and allow the store release/review process to finish.

Do **not** reopen C3/C4-style broad architecture cleanup, another A7 visual redesign, or a new gameplay feature phase merely because an older plan listed one. Structural/refactor work is now evidence-driven only.

---

# 44. Most important lessons from this project

1. **Mobile readability must be designed early.**
   Desktop-looking “reasonable” text was often too small on phone.

2. **Use native-size assets whenever possible.**
   Tiny pixel sprites enlarged too much look bad. Search the asset pack first.

3. **Keep UI systems grouped by player mental model.**
   Automation became clearer after moving into one section.

4. **Every permanent system needs Hard Reset integration.**
   Missing reset paths repeatedly caused confusing behavior.

5. **Every runtime system needs save/resume semantics.**
   Miners carrying Gold across a run restart was a real example.

6. **Visual feedback matters for automation.**
   Mine spring, Pawn animation, floating values, warning badges all make automated systems feel real.

7. **Layering/pause bugs can look like gameplay freezes.**
   Inspect UI state before assuming combat logic is stuck.

8. **Do not over-front-load tutorials.**
   Teach current mechanics first; reveal future systems contextually.

9. **Keep gameplay/world text separate from modal UI scaling.**
   They need different sizing strategies.

10. **Use changed-files-only patches and commit checkpoints.**
    This kept AI-assisted iteration manageable.

11. **Consolidate patch chains before major milestones.**
    Too many dependent ZIPs become error-prone.

12. **AI static validation helps, but runtime validation belongs in Godot.**
    Never confuse the two.

13. **Tutorials should gate progression, not rewrite combat rules.**
    Use Normal play or a safe-boundary Hard Gate. Avoid invulnerability/HP floors that create a different game during onboarding.

14. **Control tutorial economy at the source instead of disabling player choices.**
    Everfort's first run silently caps total Gold earned while still letting the player spend it however they want.

15. **Reward screens should explain valuable currencies.**
    Show a receipt for Run Progress, one-time first clears, Permanent Skill bonuses, Prestige bonuses, and the final SP total.

16. **Context-specific Prestige choices must wait for their content.**
    Tower/Sheep/Miner boons should not appear before those systems exist.

17. **Finite games need an explicit post-campaign contract.**
    Thank the player, expose community links, explain what remains, and allow continued play without pretending there is authored content that does not exist.

18. **Persist random offers before showing them.**
    Any valuable random choice (Prestige, rare shop roll, reward draft) should survive relaunch unchanged until the opportunity is consumed, otherwise force-close becomes a reroll exploit.

19. **Pause ownership must include child modals.**
    If a player-configurable panel can pause the tree, every interactive popup it can trigger must still process input while paused or the UI can soft-lock.

20. **Offer onboarding depth instead of assuming one tutorial style fits everyone.**
    A concise overview, a fully guided path, and a no-tutorial path can coexist as long as each mode has explicit persistence/reset semantics.

21. **Do a dedicated UI consistency audit before long-form gameplay QA.**
    Panel sizing, content overlap, spacing, selected states, scrolling and modal layering are easier to fix systematically before a Stage 1–100 playthrough.

22. **Persist the result of a transition, not only the inputs that caused it.**
    Stage-clear replay showed that saving the stage/enemy counts alone was insufficient; the game also needs to remember that the clear was already processed so relaunch cannot award mission progress twice.

23. **Snapshot volatile runtime actors exactly when approximation changes value.**
    Reconstructing enemies from an alive count rerolled archetypes and healed them. Persist exact identity/HP/position when a reload would otherwise materially change combat.

24. **Pull live worker state at the save boundary.**
    Cached worker dictionaries can be stale while actors move every frame. Save-time synchronization should capture current position/phase/carry/timer without writing profile state every frame.

25. **Automated probes need legitimate deterministic world state.**
    A test that creates an impossible profile combination can manufacture false production failures. Establish tutorial/progression state before child scenes initialize, and make unknown test phases fail loudly instead of hanging.

26. **Do not change production code just to satisfy a stale probe.**
    First compare a failing assertion with the current documented contract. Update outdated test expectations when the game intentionally changed; reserve production fixes for genuine behavior defects.

27. **Turn successful human corrections into reusable specifications.**
    A manual visual/audio/UI correction should not remain tribal knowledge. Record the asset mapping, interaction rule, layout contract, sound policy, or implementation recipe so the next AI session starts from the validated pattern instead of guessing again.

28. **Changed-files ZIPs are not automatically safe to stack in arbitrary order.**
    Everfort had a real regression where an older overlapping patch reintroduced obsolete Stage-100 behavior. Every new patch must be based on the latest full project state; overlapping files must be merged, and long patch chains should be consolidated before commits/releases.

29. **Treat a design reversal as a cross-system migration.**
    The first Stage-100 completion contract changed during development. Once a core rule changes, update every dependent surface: runtime logic, UI copy/buttons, debug triggers, save/pending-state semantics, probes/tests, and continuity documentation. Fixing only the obvious screen leaves stale behavior elsewhere.

30. **Prepared save/debug presets are production tooling, not throwaway hacks.**
    Mature Panels, Post-Campaign, Tutorial Choice, Hand Holding and Offline Reward presets made rare UI states reproducible for screenshots and acceptance testing. Future small games should maintain deterministic presets for expensive/rare states rather than replaying hours of content for every UI pass.

31. **Brand from the game's real art language.**
    Everfort's icon/logo direction became stronger when it reused the Tiny Swords sword shapes, palette and chunky 2D treatment instead of defaulting to generic fantasy/RPG branding. Store art should feel like the game before it feels like the genre.

---

# 45. Recommended next-chat startup prompt

A future GPT chat should begin with something like:

> We are continuing Everfort, a Godot 4.7.2 Android-first incremental/roguelite defense game using Tiny Swords assets. Treat the attached `Everfort_Chat_Continuity_Handoff.md` as the current design/process handoff and the latest full project ZIP as implementation authority. C0-C2 cleanup/persistence, A7 UI/UX, Android UI acceptance, long-form gameplay/balance QA, store setup, and Play Console publishing are complete. The game is now in release-candidate stabilization while the actual exported Android build is being tested. Current versioning uses `project.godot application/config/version` as the single version-name source; Android `version/name` stays blank and version code increments per upload. Recent stabilization includes the Restore Castle HP mission completion/tolerance fix, fractional mission progress display, Lancer speed 45/47.25, Special-only Miner SP mission, progression-based Special Mission SP rewards, the final SP/economy rebalance, fixed 2 SP/h offline-SP base with +40% efficiency levels, and offline reward formula receipts. Do not write code unless I explicitly authorize it. Start substantial implementation from the latest full ZIP, preserve save/lifecycle/release contracts, deliver changed-files-only ZIPs, and leave Godot/editor/device runtime validation to me. Fix only concrete release issues unless I explicitly reopen feature scope.

---

# 46. Final continuity note

This project evolved through many small visual, balance, persistence, and automation corrections.

The most dangerous assumption for a future session would be:

> “I understand the game from the concept, so I can rewrite systems freely.”

Do not do that.

The implementation now contains many deliberately coupled behaviors:

- Stage 100 campaign ending + post-campaign Prestige loop;
- Prestige unlock cadence and subsystem eligibility gates;
- stage-based enemy composition;
- Beat Stage mission semantics and mission reward snapshots;
- run-end SP first-clear accounting;
- tutorial-mode chooser (Basic / Hand Holding / None) and current-schema persistence semantics;
- Hand Holding tutorial Gold budget / hard gates;
- player-configurable pause ownership for Skills/Missions/Bestiary/Prestige/Statistics;
- slider-only 100–150% battlefield zoom;
- persisted Prestige offers that cannot be rerolled by relaunching;
- Special Mission probability/reward snapshot/visual treatment;
- Manual Mining efficiency progression;
- offline multipliers;
- fractional Gold persistence and non-truncating reward paths;
- Mine reserve economics;
- exact enemy survivor identity/HP/position resume semantics;
- exact Miner position/phase/target/carry/extraction-time resume semantics;
- free-Mine-first randomized Miner target distribution for new assignments;
- unresolved Offline Reward persistence until Claim;
- processed stage-clear persistence that prevents replay credit;
- worker carry/reset rules;
- target-priority fallback;
- 3-column mobile Skills layout;
- contextual tutorials;
- warning indicators;
- save/resume behavior;
- Hard Reset behavior.

Future changes should preserve those semantics unless the user explicitly changes the design.

Also preserve the **patch authority rule**: do not apply an older changed-files ZIP on top of a newer project merely because it contains a desired file. Rebuild/merge the change against the latest full ZIP first, especially when `main.gd`, state autoloads, shared UI helpers, save code, or endgame flow are involved.

# 47. A7 visual implementation registry and Android device-test workflow

This section records concrete implementation decisions from the A7 visual pass so future AI sessions **inspect and reuse the existing implementation before inventing another asset treatment**. The latest full project ZIP remains implementation authority if any numeric value below has since been manually adjusted in Godot.

## 47.1 Asset implementation rule

Before changing or reusing a Tiny Swords asset, first inspect:

1. the original source sheet;
2. how that asset is already used in current scenes/scripts;
3. any owner/reference image showing the intended assembly;
4. whether the source is a finished sprite, animation sheet, 3-slice, 9-slice, or compositional tile sheet;
5. the authored fixed regions versus repeatable/stretchable regions.

Do **not** replace an existing proven implementation merely because a different crop/stretch is easier to code. Preserve the project's current visual treatment unless the user explicitly changes it.

For visual compositions that require artistic adjustment, prefer **editor-visible scene nodes** over procedural drawing constants. The user should be able to move/resize meaningful visual pieces directly in Godot when practical.

## 47.2 Run Upgrades / Tiny Swords Wood Table — final direction

The Run Upgrade dock uses the Tiny Swords Wood Table family:

```text
assets/tiny_swords/UI Elements/UI Elements/Wood Table/WoodTable.png
assets/tiny_swords/UI Elements/UI Elements/Wood Table/WoodTable_Slots.png
```

`WoodTable.png` is an **authored compositional/tiled frame**, not a flat rectangle.

A stretched version was built only as a comparison. It visibly distorted the grain, weakened the turquoise corner hardware and made manual alignment harder. The final approved direction is **tiled/repeated composition**, and the user removed the stretched variant after validating the tiled version on both desktop and Android.

Conceptually:

```text
TopLeft | Top | Top | Top | ... | TopRight
Left    | Center repeated       | Right
Left    | Center repeated       | Right
...     | ...                   | ...
BottomLeft | Bottom repeated    | BottomRight
```

Important rules:

- preserve authored corner/edge pieces;
- repeat/tile the middle pieces rather than stretching when stretching deforms the art;
- keep meaningful pieces editor-visible when practical so the user can visually move/resize them;
- `WoodTable_Slots.png` is appropriate for card/inset language, not as a replacement for the outer table;
- manual edits in the latest full project ZIP override older numeric values in documentation.

This Wood Table episode is the canonical example for future games: **classify an asset before using it**. A compositional sheet may require repetition/assembly, not `TextureRect` stretching or arbitrary 9-slice assumptions.

## 47.3 Current Run Upgrade card readability direction

During A7.1C, the card layout was compacted horizontally **without changing card height**. The design direction is:

- keep the card height unchanged;
- make cards narrower so more useful content fits in the dock;
- increase icon/text readability;
- place current -> next value and level on the same row;
- use the reclaimed vertical space for a taller Buy button;
- apply the layout consistently to every Run Upgrade type, not just Damage;
- preserve horizontal swipe/scroll behavior and update paging distance when card width changes.

The implementation pass used these target values as a starting point:

```text
card width:      ~330 px
card height:     146 px (do not change unless explicitly requested)
icon:            ~40 px
name font:       ~24 px
value font:      ~19 px
level font:      ~17 px
Buy height:      ~50 px
Buy font:        ~22 px
Gold icon:       ~26 px
```

These are **implementation-history values**, not immutable design tokens. If the user has manually tuned them in a newer full ZIP, the ZIP wins.

## 47.4 Android USB deployment — confirmed project workflow

Godot one-click Android deployment did not expose the connected phone even though ADB detected it successfully. Do not waste repeated UI-debugging time trying to force the Godot device button to appear if ADB itself works.

Current local paths:

```text
Android SDK: D:\Android\Sdk
JDK:         D:\Programs\Eclipse Adoptium\jdk-17
Builds:      D:\Godot\EverFort\builds
Package ID:  com.shekinahwelefuldesigns.everfort
```

Device verification:

```bat
"D:\Android\Sdk\platform-tools\adb.exe" devices
```

The device was detected as authorized, and the user **successfully installed/updated Everfort on the physical phone using ADB**.

Standard fallback/device-test flow:

```text
Export debug APK from Godot
-> adb install -r APK
-> launch/test on phone
```

Install/update command:

```bat
"D:\Android\Sdk\platform-tools\adb.exe" install -r "D:\Godot\EverFort\builds\<current-apk-name>.apk"
```

Optional launch command:

```bat
"D:\Android\Sdk\platform-tools\adb.exe" shell monkey -p com.shekinahwelefuldesigns.everfort -c android.intent.category.LAUNCHER 1
```

`-r` updates the installed package instead of requiring manual transfer/uninstall/reinstall and normally keeps app data when package/signature compatibility is unchanged.

This workflow is now **confirmed**, not experimental. A later convenience improvement may wrap export/install/launch in a `.bat`, but the raw command is already the accepted fallback.


## 47.5 Visual-authoring preference

When a visual element can be represented reliably as editor-visible Godot nodes/resources, the user prefers that over code-only positioning because it allows immediate manual correction and visual inspection. This applies especially to artistic placement/composition such as terrain decorations, shoreline effects, and UI pieces.

This is not mandatory: use procedural/code-driven layout whenever that is better for responsiveness, correctness, runtime behavior, scalability, or maintainability. Project quality takes precedence over editor convenience.

## 47.6 A7.1D asset/system registry

Important implementations that future AI work should reuse rather than rediscover:

### Target selection / interaction

- Castle/Tower selection moved away from procedural yellow circles toward the Tiny Swords **four-corner selector/cursor** language.
- Target-priority contextual UI uses the established paper + blue-button vocabulary.
- Selectors must close/suppress behind Defeat, tutorial blockers, Pause and major panels/modals.
- World selectors must be converted correctly into screen/UI space under battlefield zoom.

### Stage Clear

- ordinary Stage Clear feedback uses the Tiny Swords ribbon language instead of plain floating text;
- normal clear = blue treatment;
- milestone/elite/major clear = gold treatment where appropriate;
- ordinary clears remain lightweight feedback, not full-screen result modals.

### Prestige Castle

Do not tint the Blue Castle to fake Prestige tiers. Use the authored building palettes:

```text
Prestige 0      Blue
Prestige 1-3    Yellow / Gold
Prestige 4-6    Purple
Prestige 7-9    Black
Red             enemy-only; never player Prestige
```

This preserves the artist's palette/detail work and gives Prestige a more meaningful visual reward.

### Enemy bars / specials

- HP number sits inside the HP bar;
- special meter is a real Tiny Swords SmallBar with distinct cyan/blue fill;
- text shows action progress such as `0/4`;
- special cadence: Warrior 3, Archer 4, Lancer 4, Monk 3;
- Elite variants keep their archetype cadence.

### Water foam / shoreline

The first code-generated side foam placement repeatedly landed as isolated rectangles in open water. Final lesson:

- automatic/repeated shoreline behavior can remain procedural where it follows stable terrain rules;
- artistically sensitive side/corner foam should use **editor-visible marker nodes** when practical;
- the side/corner implementation was refactored to `WaterFoamMarker`-style editor nodes under a manual shoreline group so the user can drag them directly;
- manual foam composition should still follow responsive settlement/world positioning, so editor control does not mean abandoning layout correctness;
- reuse the existing Tiny Swords `Water Foam.png` animation rather than inventing a second water style.

### Terrain cliff trim

When a cliff needs grass edge/corners, reuse the authored cliff/grass tiles already present elsewhere in the same terrain set. Do not paint/reconstruct a fake grass line. A small center-access cliff follow-up specifically reused the same authored top/grass edge/corner language used by the other cliffs.

## 47.7 Safe-area/mobile findings

Real-phone testing caught issues that looked correct on desktop:

- the Run Upgrade left rail had been aligned through a desktop-width compensation and disappeared on the wider phone viewport;
- top HUD content sat too close to the physical edge/cutout;
- right-side zoom/interaction controls also need safe placement.

Reusable rules:

- anchor structural UI to its real parent edge rather than compensating with a large hard-coded offset;
- use Android/display safe-area information for interactive HUD content;
- background bands may remain full-width while actual controls receive safe-area padding;
- validate every major HUD/panel change once on the 1920x1080 reference and once on a physical Android device.

Godot API note from the parser fix in this project:

```gdscript
DisplayServer.get_display_safe_area()
```

uses the zero-argument form in the project's Godot version.

## 47.8 A7.2 main-panel design contract

The five main panels should feel like one authored Tiny Swords UI family, not five unrelated redesigns.

Shared direction:

- standard information/progression panels use the established **paper/parchment** language;
- use consistent title/header placement, close/back treatment, padding and touch targets;
- large screen titles may use the authored **Big Ribbon** assembly with decorative **Swords** behind it;
- preserve authored ends/corners and repeat/stretch only regions that are actually safe to repeat/stretch;
- small ribbons can identify sections;
- do not overdecorate every card just because more assets exist.

Panel-specific constraints:

### Skills

- preserve the intentional **3 cards per row** structure;
- panel remains purchase-focused;
- do not reintroduce the removed Current Stats block;
- preserve tutorial gating/required first Damage purchase behavior.

### Missions

- ordinary missions remain clean/readable;
- Special Missions retain their distinct warm/dark-gold identity;
- preserve claim/replacement/tutorial mission semantics.

### Bestiary

- mimic the supplied Tiny Swords **Enemy Pack** owner reference for title + selector board;
- gold/yellow title ribbon with decorative double swords behind;
- unknown entries show `?`;
- discovered entries animate in-place using authored unit animations;
- selected-enemy information remains above the grid;
- exact values + behavior remain visible, with optional colored relative-strength bars as a quick comparison aid.

### Prestige

- use stronger premium/rare visual language than ordinary paper panels where appropriate (dark/gold / SpecialPaper family);
- do not change unlock timing, offer persistence or choice semantics;
- visual rarity must not imply an unavailable action is available.

### Statistics

- keep it information-dense but organized/readable;
- it remains separate from Skills and is reached directly from the battle HUD;
- include Manual Mining where the audit identified it as missing;
- no need to reinvent its data model for visual polish.

Pause ownership now includes Statistics: Skills/Missions/Bestiary/Prestige/Statistics each respect the user's per-panel pause preference.

## 47.9 A7.2 implementation state at handoff

A changed-files-only package named:

```text
Everfort_A7_2_Main_Panels_Patch_v1.zip
```

was prepared against the latest full ZIP. It contains shared title/banner/paper resources plus updates for Skills, Missions, Bestiary, Prestige and Statistics.

**Do not call A7.2 finished until the user validates it in Godot and on Android.** Treat this package as an implementation candidate awaiting runtime/visual acceptance. If a newer full ZIP exists in a future chat, that ZIP supersedes this package.

## 47.10 Visual iteration discipline

A repeated lesson from Environment, HUD and especially Run Upgrades:

> AI is good at establishing structure and first-pass composition; repeated subjective 1-3 pixel tuning is often faster and safer in the editor.

Therefore:

- maximum 4 AI implementation iterations per UI/environment section;
- after that, stop and hand exact editor adjustments to the user;
- prefer editor-visible composition for artistic tuning when robust;
- if another AI implementation attempt is still desired after the cap, require explicit approval twice;
- preserve the user's manual Godot changes in every later patch by starting from the latest full ZIP.
---

# 48. 2026-09-24 gameplay/UI implementation findings

This section captures the newest concrete behavior discovered during A7.4 phone testing. It supersedes older presentation notes elsewhere when they conflict.

## 48.1 Fractional Gold is the canonical run-currency model

Gold should support fractions directly. Do not simulate fractional bonuses with a hidden remainder accumulator. Reward paths must preserve decimals from calculation through wallet, persistence, missions, statistics and UI formatting.

**Shepherd's Blessing** applies only when Sheep collect loose Gold. Example with one stack and a 1 Gold pickup:

```text
wallet credit = 1.40 Gold
```

The visual may show the total plus the Prestige contribution, for example `+1.40 G (+0.40)`, without delaying the 0.40.

## 48.2 World-space feedback timing

Damage, healing, Gold/resource pickup and similar in-game floating text now remains visible roughly twice as long as the earlier implementation. This was a phone-readability correction. Preserve the longer timing unless later device testing gives a specific reason to reduce it.

## 48.3 Battlefield/mobile-space rebalance

The playable battlefield, Castle, Towers, Sheep, Mines and enemy lane were pushed upward and the top sea band reduced. The reclaimed lower area is intentionally reserved for larger Run Upgrade cards/buttons and more readable mobile interaction. Do not move the world back down without rechecking the entire bottom-dock acceptance.

## 48.4 Run Upgrade UI

Run Upgrade cards/buttons are larger and use more of the Wood Table background. The Wood Table remains a tiled/authored composition. Purchase feedback must not tint the whole card. Repeated full-card `UiFx.flash()` calls previously compounded tint during rapid purchases and could leave cards orange/yellow. Purchase feedback is localized to a safe element such as the Buy button.

## 48.5 `UiFx` overlap safety

Shared UI scale/tint effects must restore a stable original/base transform or modulation. Never use an already animated current scale/modulate as the next animation's new baseline. This caused both permanent upgrade-card tinting and runaway Mission progress-bar growth.

When modifying `UiFx`, preserve all existing public helpers such as `style_button()` and `style_button_group()`. A partial replacement caused a broad parse-error cascade across Pause, Defeat, Settings, tutorials and endgame screens until those helpers were restored.

## 48.6 Mobile Settings control contract

Use the Zoom slider visual language for continuous SFX/Music volume, but keep binary decisions as large checkboxes. Dragging a two-state slider for Mute or Pause Panel was annoying in practice. Continuous sliders need a large grabber, tall touch region and fine movement.

## 48.7 Statistics HUD placement and layering

Statistics is now a direct HUD panel placed before Speed and Pause/Settings. It has a persisted Pause/No Pause preference like the other main battle panels.

When Defeat opens Permanent Skills, the Defeat state remains logically active underneath, but the Skills panel renders above it. Closing Skills returns to the Defeat screen. Do not dismiss or weaken the death state merely to solve layering.

## 48.8 New Enemy Incoming

Enemy reveal portraits must use a bounded portrait area independent of source sprite proportions. Tall Lancer variants exposed the failure mode where sprite height pushed descriptive text outside the paper. Scale every reveal portrait proportionally inside the fixed area and reserve wrapped text space below it.

## 48.9 Mission panel runtime stability

Mission progress can update while the panel is closed. UI animations attached to progress updates therefore must be safe under repeated background updates. The progress-bar container no longer receives a scale punch. Mission numbers must use centralized abbreviations consistently, including K/M/etc. above 999.

## 48.10 Mine Gold visual boundary

Manual Mine Gold tosses should remain below the settlement cliff/mountain boundary instead of visually flying over the mountains. Constrain both landing target and arc apex. This is a presentation constraint only and should not change reward value.

## 48.11 Miner assignment

New Miner assignments prefer unclaimed/free Mines first and randomize among them. When all Mines are already targeted, randomize among all valid Mines. Keep an existing assignment stable while traveling/mining and preserve it through save/resume.

## 48.12 Miner Gold Yield wording

The former player-facing **Mining Yield** name was ambiguous because Miners can discover SP. The current name is **Miner Gold Yield**. It increases Miner Gold only and does not affect Skill Point finds.

## 48.13 Phase gate — completed

This was the intended gate on 2026-09-24 and has now been completed: physical Android UI acceptance, long-form gameplay/balance QA, store setup and release upload all happened afterward.

Current gate is narrower:

```text
actual Android release-build testing
-> concrete release blocker/regression fixes only
-> rebuild with higher Android version code when runtime code changes
-> regression-test corrected release artifact
-> update Play Console release if required
-> freeze candidate again
```

Do not use the old A7 -> Phase D -> Phase E -> Phase F sequence as pending work; it is historical context only.

---

# 49. Store screenshot capture workflow — reusable Godot addon

During Play Store finalization, a reusable **Store Screenshot Capture** Godot addon was created so store screenshots can be generated from controlled live game states without manually resizing/cropping every image. The addon is intentionally **not Everfort-specific** and should be reused in future Godot games.

Current reusable package/version produced during this workflow:

```text
Store_Screenshot_Capture_Addon_v1.0.2.zip
addons/store_screenshot_capture/
```

## 49.1 Intended capture workflow

Run the game from the Godot editor, prepare the exact scene/gameplay/menu state, then use the runtime capture overlay to generate the selected store variants from the same moment.

Supported capture dimensions/categories:

- Phone;
- 7-inch tablet;
- 10-inch tablet;
- Desktop.

Supported orientation presets:

- Landscape / 16:9;
- Portrait / 9:16.

The per-target resolutions are project-editable. Current defaults are:

| Target | Landscape | Portrait |
|---|---:|---:|
| Phone | 1920x1080 | 1080x1920 |
| 7-inch tablet | 1920x1080 | 1080x1920 |
| 10-inch tablet | 2560x1440 | 1440x2560 |
| Desktop | 2560x1440 | 1440x2560 |

The tool resizes the **actual game viewport** before capture and waits for the layout/render to settle. It must not generate alternate sizes by resizing an already captured screenshot, because the purpose is also to validate the game's responsive UI at those target shapes.

The capture set is paused while the selected target resolutions are generated so Phone/Tablet/Desktop variants represent the same gameplay moment rather than several seconds of different simulation state. Window size/mode and prior pause state are restored afterward.

## 49.2 UI capture rule

`Capture UI` is **enabled by default**. Normal Play Store screenshots therefore include the game's HUD/UI unless explicitly disabled for a clean gameplay/environment shot.

When `Capture UI` is disabled, the addon hides only nodes explicitly registered in the project UI group:

```text
store_screenshot_ui
```

Do not implement UI-free capture by hiding every `Control` or `CanvasLayer`. Games may use those node types for enemy HP bars, world labels, targeting markers and other world-space presentation that should remain visible.

## 49.3 Screenshot organization and naming contract

Generated screenshots live under a `.gdignore`-protected store-assets directory so Godot does not import them as gameplay assets. The current default root is:

```text
res://store_assets/screenshots/
```

with orientation and target folders below it.

Default automatic names are based on the **destination folder/category name plus the shared screenshot number**:

```text
Phone      -> Phone_01.png
Tablet_7   -> Tablet_7_01.png
Tablet_10  -> Tablet_10_01.png
Desktop    -> Desktop_01.png
```

This naming rule is deliberate and should be preserved: **the screenshot name should clearly mirror the destination folder/category it belongs to**. That makes Play Store upload organization much easier because the device class is visible directly in the filename, reducing the chance of mixing Phone, 7-inch, 10-inch and Desktop images while uploading. Internal folder keys may be normalized to lower-case (`phone`, `tablet_7`, `tablet_10`, `desktop`), but the human-facing filename prefix must remain the same destination/category name.

Examples of the current output organization:

```text
store_assets/screenshots/
  landscape/
    phone/
      Phone_01.png
      Phone_02.png
    tablet_7/
      Tablet_7_01.png
      Tablet_7_02.png
    tablet_10/
      Tablet_10_01.png
      Tablet_10_02.png
    desktop/
      Desktop_01.png
      Desktop_02.png
```

If `Capture UI` is off, append `_no_ui` so the clean and normal versions cannot collide:

```text
Desktop_01_no_ui.png
```

A manual filename override is the intentional exception. If the user types a name such as:

```text
PrestigeChoice
```

that exact basename is used in each selected destination folder instead of the automatic `Destination_#` naming:

```text
phone/PrestigeChoice.png
tablet_7/PrestigeChoice.png
tablet_10/PrestigeChoice.png
desktop/PrestigeChoice.png
```

Use the manual override only when a semantic screenshot name is genuinely more useful than the normal Play Store organization rule.

## 49.4 Export safety lesson

The first addon version gated the runtime overlay with:

```gdscript
OS.is_debug_build()
```

That was incorrect for this purpose because Android debug exports are also debug builds, so the Store Screenshot Capture panel appeared on the physical phone.

The corrected runtime gate uses the Godot editor-runtime feature instead:

```gdscript
OS.has_feature("editor_runtime") and not OS.has_feature("template")
```

Resulting behavior:

- project launched from the Godot editor -> capture overlay available;
- Android debug export -> overlay does not appear;
- Desktop debug export -> overlay does not appear;
- release export -> overlay does not appear.

Important distinction: suppressing runtime behavior is not automatically the same as proving that every addon resource is absent from the exported PCK. The current addon uses an autoload while enabled. If a future release process requires **zero screenshot-tool resources packaged in production**, either disable/remove the addon/autoload before the final export or evolve the tool into an editor-only capture architecture/export-exclusion workflow. Never rely on `debug` alone as the production-safety boundary.

## 49.5 Godot embedded-game caveat

Godot's fixed embedded-game viewport can prevent the real viewport from changing to the requested resolution. The capture tool verifies the rendered image size and should fail rather than silently save a wrongly sized screenshot.

For reliable multi-resolution capture, use:

- a floating/unembedded game window; or
- an editor embedded-game sizing mode that actually allows the viewport to resize.

Reusable principle:

> Store screenshots should be generated from the real responsive game state, automatically organized by destination, and kept completely out of the player's runtime experience.



---

# 50. 2026-09-25/26 release stabilization and final balance state

This section is the newest continuity authority for late release-build tuning. When it conflicts with older balance notes elsewhere in this document, **this section and the latest full ZIP win**.

## 50.1 Release-build mission fixes

`Restore Castle HP` exposed two separate defects during real Android release testing.

First, every legitimate Castle-healing source must route through one tracked restoration path. `Health Regen`, `Lifesteal`, and `Second Wind` now report the **actual HP restored** (excluding overheal) through `health_restored`, which Main forwards to `MissionState.record_castle_healed()`. Save/load HP restoration is not gameplay healing and must not award mission progress.

Second, float accumulation produced a state where UI could show `169 / 169` while the mission remained **In Progress** because the internal value was marginally below the target. Current contract:

```text
MISSION_PROGRESS_EPSILON = 0.005
continuous progress near target -> snap to exact target
completion check              -> progress + epsilon >= target
UI refresh                    -> when displayed hundredth changes or completion occurs
```

Continuous/fractional objective families such as Restore Castle HP, Gold collection/spending, manual mining and Miner Gold delivery preserve fractional presentation; discrete objectives remain whole-number goals.

Reusable lesson: displayed precision and completion precision must agree. Never allow the UI to present a completed-looking number while the state machine disagrees.

## 50.2 Final mission/SP economy

Rotating Mission difficulty remains:

```text
Easy 45% / Standard 35% / Hard 20%
```

Normal reward-currency chance remains **10% SP base**, with Mission Expertise adding +5 percentage points per level to **30% max**. Mission Expertise costs are:

```text
100 / 180 / 300 / 450 SP
```

Normal SP Mission payout is now:

```text
Easy     = 20% of current SP ceiling
Standard = 40%
Hard     = 60%
```

Special Missions:

```text
chance per level: +2 percentage points
max chance:       10% at level 5
costs:            100 / 125 / 160 / 200 / 250 SP
reward:           100% of current SP ceiling
```

Current SP ceiling follows the next unclaimed Beat Stage reward:

```text
10 / 20 / 35 / 50 / 65 / 90 / 110 / 130 / 145 / 160
then 200 after Beat Stage 100 is claimed
```

`Find Skill Points with Miners` is **Special-only**. Its reliance on the rare Miner SP-find roll made it disproportionately hard as an ordinary mission.

Mission Capacity costs:

```text
60 / 120 / 180 SP
```

Auto Claim Missions costs:

```text
90 / 150 / 240 SP
```

Auto Run Upgrades costs:

```text
60 / 90 / 135 / 195 / 270 SP
```

## 50.3 Final SP acquisition tuning

Repeatable run progress stays **0.5 SP per stage actually cleared**.

One-time first-clear SP is:

```text
Stages  1-10  = 1.0 SP each
Stages 11-20  = 1.5 SP each
Stages 21-30  = 2.0 SP each
Stages 31-40  = 2.5 SP each
Stages 41-50  = 3.0 SP each
Stages 51-60  = 3.5 SP each
Stages 61-70  = 4.0 SP each
Stages 71-80  = 4.5 SP each
Stages 81-90  = 5.0 SP each
Stages 91-100 = 5.5 SP each
```

Mission SP rewards remain authored final payouts; they are not multiplied again by run-end Skill Reward/Scholar modifiers.

## 50.4 Gold/economy tuning

Permanent **Gold Gain** now gives **+15% per level**, 20 levels, up to +300%. Current costs:

```text
10 / 12 / 15 / 18 / 22 / 27 / 33 / 40 / 48 / 58 /
70 / 84 / 100 / 120 / 145 / 175 / 210 / 250 / 300 / 360 SP
```

Permanent **Starting Gold** is now **+50 Gold per level**, 10 levels, with costs:

```text
5 / 6 / 8 / 10 / 13 / 17 / 22 / 29 / 38 / 50 SP
```

Permanent **Offline Coin Efficiency** is **+20% offline Gold per level**, 10 levels, max +200% / ×3 offline Gold. Costs:

```text
6 / 8 / 10 / 13 / 17 / 22 / 29 / 38 / 50 / 65 SP
```

Permanent **Sheep Gold Bonus** is **+15% per level**, 10 levels, max +150% Sheep-collected Gold.

Manual Mining efficiency is:

```text
Lv0 20%
Lv1 50%
Lv2 80%
Lv3 110%
Lv4 140%
```

Costs are `8 / 12 / 18 / 26 SP`.

## 50.5 Offline progression

Offline Skill Rewards unlock:

```text
30 SP
```

Offline SP base:

```text
2 SP/hour
```

Highest stage no longer affects offline SP. Offline Skill Efficiency is **+40% per level** with costs:

```text
20 / 25 / 32 / 40 / 50 / 62 / 76 / 92 / 115 / 145 SP
```

This produces `2.0 SP/h` at Lv0, `6.0 SP/h` at Lv5 and `10.0 SP/h` at Lv10 before normal earned SP modifiers.

Offline Gold retains its stage multiplier and Offline Coin Efficiency. Both Gold and SP share the 4–8 hour Offline Time cap.

The Welcome Back modal must show the credited totals and the actual formula inputs below each reward. Example Gold receipt:

```text
Base: 60 Gold/h × 4.00h = 240 Gold
Bonuses: Stage ×1.75 · Offline ×1.00 · Gold Gain ×1.00
Total: 420 Gold
```

## 50.6 Defeat-screen Castle Damage Report

The Defeat screen now includes a **Castle Damage Report** designed to tell the player which enemy type was the biggest practical threat in the final uninterrupted damage window.

Tracking contract:

- the window starts/restarts whenever the Castle is at full HP;
- actual Castle HP damage is tracked after mitigation and Shield absorption;
- Shield-only damage is not Castle HP damage;
- damage is attributed to the exact enemy definition, so regular and Elite variants remain distinct;
- partial healing remains in the window and is shown by stage;
- healing that reaches full HP clears the whole previous window immediately;
- cumulative damage may exceed 100% because partial healing can let the Castle absorb more than one full health bar before defeat;
- each stage row shows the enemy that dealt the most HP damage that stage, that enemy's damage, total stage damage, and stage healing;
- the report also shows the overall Top Threat plus total Damage, Healing, and Net HP loss;
- in-flight enemy projectiles carry their source identity, so a ranged attacker is still credited even if it dies before the projectile lands;
- the report is part of the active-run checkpoint and survives save/resume;
- fresh runs and debug stage jumps clear it.

This is a diagnostic/decision-support feature, not merely a death recap: the player should be able to identify which archetype/Elite variant is creating the pressure that their build fails to answer.

Defeat-screen presentation contract:

- the **Skill Point Reward summary appears before the Castle Damage Report** so the primary run reward is immediately visible;
- the SP total plus compact Base/Bonuses summary remain fixed and readable; the detailed reward receipt scrolls independently when it is long;
- the Castle Damage Report keeps Top Threat and Damage/Healing/Net totals fixed; per-stage rows scroll independently;
- both sections use the available panel area for larger phone-readable text instead of shrinking all content to force every detail on screen simultaneously.

## 50.7 Enemy/reveal tuning

Current movement-speed reference:

```text
Warrior regular/Elite: 60 / 65 px/s
Archer regular/Elite:  50 / 55 px/s
Monk regular/Elite:    55 / 58 px/s
Lancer regular/Elite:  45 / 47.25 px/s
```

The New Enemy Incoming reveal was also adjusted for final phone readability: the heading uses a larger 34 px authored heading and behavior/body copy was increased from the earlier small presentation. Preserve the bounded portrait/text layout introduced in A7.4.

## 50.7 Versioning/release discipline

Do not independently maintain the in-game version label and Android version name. Current contract:

```text
project.godot application/config/version -> player-facing Settings version
                                          -> Android version name fallback
export_presets.cfg version/name          -> intentionally blank
export_presets.cfg version/code          -> monotonically increment per Play upload
```

The release build itself is the final validation authority. Static checks, Godot editor tests, probes and debug builds are useful gates, but they did not expose every issue found in production-style Android play.

---

# 51. 2026-10-14 Google Play marketing assets and social videos

Produced with the reusable Godot Marketing Capture Toolkit (`Godot-Marketing-Toolkit/`, 1.0.0-rc1 plus documented fixes; addons installed under `addons/`, pinned by `marketing_capture_toolkit.lock.json`). Game-owned pieces: `marketing/game_scenarios.gd` (capture adapter, save-sandboxed), `marketing/manifest.json` (capture jobs, screenshots, videos, approved copy), `marketing/feature_graphic.py`, `marketing/package_store_screenshots.py`, `marketing/package_social_videos.py`, `marketing/MUSIC_EVIDENCE.md`. Generated media live in the git-ignored `marketing_output/`; the full record is `marketing_output/review/PRODUCTION_REPORT.md`.

- **Screenshots:** 32 language-neutral PNGs (8 each for Phone, 7-inch, 10-inch, Desktop), each a real Godot render at its size, no added text.
- **Feature graphic:** 1024×500, EVERFORT / IDLE CASTLE DEFENSE wordmark (subtitle vs turret overlap still for developer review).
- **Play trailer:** 30.000 s 1920×1080, licensed Pixabay track, late-game final shot.
- **TikTok:** `marketing_output/social/tiktok/Everfort_TikTok_01.mp4` (hook "HOW LONG CAN YOUR CASTLE SURVIVE?", late-game combat) and `_02.mp4` (hook "BUILD. AUTOMATE. SURVIVE. REPEAT.", economy → upgrades → skills → prestige → late combat): 15.000 s 1080×1920 30 fps, both cut from the trailer's approved raw clips with per-shot reframes (no new capture), ending on the icon + EVERFORT card.
- Nothing was uploaded to Google Play, YouTube or TikTok. Player save hash unchanged by every capture run. Release exports exclude `marketing/*`, the toolkit, the capture addons and `docs/*`.
- `docs/promotion_codes.csv` (real codes, recipients) stays local and git-ignored, as do the `.translation` files Godot generated from it; builds exported before the `docs/*` export exclusion may contain those codes.

---

# 52. 2026-10-14 In-game localization (20 locales, playbook section 132)

Everfort ships all 20 approved locales through Godot's native `TranslationServer`. English is the reference catalog and the fallback. Nothing in this pass changed gameplay, balance, save schema (`SAVE_VERSION = 3`) or the marketing capture output (marketing runs are forced to `en-US`).

## 52.1 Architecture

- **`Localization` autoload** (`scripts/autoload/localization.gd`, registered right after `SettingsState`). It resolves the preference, applies the locale, sets the font fallback chain, and offers `Localization.t(key, {named placeholders})` and `Localization.duration(seconds)` for text built in code.
- **Catalogs:** `localization/<godot locale>.po`, one per locale, each with the same 528 keys. They are registered in `project.godot` → `[internationalization] locale/translations`, with `locale/fallback="en"` and `locale/include_text_server_data=true` (needed for Thai/CJK line breaking in exports).
- **Preference:** `SettingsState.language` stores `"auto"` (default) or a locale id such as `"de-DE"`. It is saved with the other player settings. Hard Reset, run reset, Prestige and save restore do not change it, and `reset_to_defaults()` leaves it alone. Choosing Automatic again turns device detection back on.
- **Settings UI:** Settings → Language opens a picker with Automatic (showing the detected language) plus all 20 languages. Each language is listed by its own name (endonym) in every locale.
- **Live refresh:** switching languages needs no restart.
  - Scene text authored as keys re-translates itself through Godot auto-translate.
  - Scripts that build text in code redraw it on `NOTIFICATION_TRANSLATION_CHANGED`.
  - Already-open panels, popups and HUD readouts update in place.
- **Data resources** (`data/**/*.tres`) store keys in `display_name`/`description`, not English. Examples: `ENEMY.ARCHER.NAME`, `MILESTONE.STAGE_10.DESCRIPTION`, `BOON.SECOND_WIND.NAME`, `STAT.DAMAGE.NAME`.
  - Mission descriptions are built when shown, from `MissionState.GOAL_DESCRIPTION_KEYS` / `ARCHETYPE_GOAL_KEYS`; saved mission slots no longer store English text.
  - Damage-report entries store enemy name keys, so old reports display in the current language.
  - Saves from before this pass still load. Their stale English fields are ignored.

### Locale mapping

| Store locale | Godot catalog | Device locales that resolve to it |
|---|---|---|
| en-US | `en` | any `en_*`, and any unsupported language |
| es-419 | `es` | `es`, `es_MX`, `es_AR`, `es_US`, every non-Spain `es_*` |
| es-ES | `es_ES` | `es_ES` |
| pt-BR | `pt_BR` | every `pt_*` (including `pt_PT`, nearest supported) |
| fr-FR, de-DE, it-IT, nl-NL, pl-PL, ru-RU, uk-UA, tr-TR, id-ID, vi-VN, th-TH, hi-IN, ja-JP, ko-KR | bare language code (`fr`, `de`, …) | every regional variant of the language |
| zh-CN | `zh_CN` | `zh`, `zh_CN`, `zh_SG`, `zh_Hans*` |
| zh-TW | `zh_TW` | `zh_TW`, `zh_HK`, `zh_MO`, `zh_Hant*` |

Godot folds `es_419` into plain `es`. That is why Latin-American Spanish is the generic `es` catalog and Spain gets `es_ES`.

## 52.2 Key conventions

- Keys are semantic and stable, organized by namespace:

  | Namespace | Covers | Keys |
  |---|---|---|
  | `UI.*` | panels, HUD, buttons, settings, end screens | 304 |
  | `TUTORIAL.*` | Basic cards, Hand Holding guide, story cards | 60 |
  | `BOON.*` | Prestige boons | 44 |
  | `STAT.*` | Run Upgrades and Permanent Skills | 39 |
  | `MISSION.*` | mission goals, categories, difficulty | 32 |
  | `MILESTONE.*` | New Enemy Incoming | 20 |
  | `ENEMY.*` | enemies | 17 |
  | `FEATURE.*` | feature unlock popups | 6 |
  | `FX.*` | floating combat text | 5 |
  | `WORLD.*` | world-space prompts | 1 |

- Placeholders are always **named** (`{stage}`, `{value}`, `{seconds}`), so translators can reorder them. Never assemble a sentence from fragments.
- Each `.po` entry carries the English reference as a `#.` extracted comment.
- New player-visible text must get a key in all 20 catalogs within the same change (playbook 132.4).

## 52.3 Intentional exceptions (not translated)

- **Everfort** (game name) and **Discord** (brand) are never translated.
- Language endonyms in the picker appear the same in every locale.
- **Numbers:** the existing Everfort notation stays the same in every locale.
  - Decimal point and two decimals, K/M/B/T suffixes, `%`, `×`/`x` multipliers.
  - ISO-style dates in Statistics.
  - This keeps long-number layouts and balance receipts identical across languages.
- **Abbreviations:** short `HP` / `SP` stay where the locale commonly uses them (Hindi, Thai, Japanese, Korean, Chinese, among others). Other locales use their own abbreviation, for example `FP` (de), `ОН` (ru), `PU` (pl), `ĐKN` (vi). Vietnamese Run Upgrade cards use `s` for seconds so the cards don't widen.
- **Developer-only text** stays English: the Debug panel, the *Developer / Debug* settings section and its *Open Debug Tools* button, probe output and console logs. This is permitted by playbook 132.4.
- The English `description` fields still present on `UpgradeDefinition` resources are unused developer notes; the UI shows `STAT.*` keys instead.

## 52.4 Fonts

- The primary face is still Godot's built-in Open Sans SemiBold, which covers Latin, Vietnamese and Cyrillic.
- `Localization` sets a `FontVariation` as the project theme's `default_font`. It chains subsetted Noto Sans fallbacks pinned to weight 600: Devanagari, Thai, JP, KR, SC, TC. They live in `assets/fonts/localization/`, about 1.3 MB in total, under the OFL 1.1 licence (see `licenses/`).
- The Han font order changes per locale, so shared code points use the correct regional glyph shapes:

  | Locale | Han font order |
  |---|---|
  | ja | JP first |
  | zh-CN | SC first |
  | zh-TW | TC first |
  | ko | KR first |

- **After editing any `.po` text**, run `pip install fonttools` and then `python tools/localization/build_font_subsets.py`. The script rebuilds the CJK subsets from the full Noto sources in `Godot-Marketing-Toolkit/assets/fonts/`. The localization probe fails with the missing characters if you skip this step.

## 52.5 Layout fixes made for translated text

These fixes are generic. Text size was not reduced anywhere.

- `TinyPaperPanel` re-lays out its paper pieces when it resizes, so panels can grow taller for longer text.
- `UiFx.keep_title_above_panel()` keeps end-screen title ribbons (Defeat, Chapter Complete, Campaign Complete, Prestige choice) above their panel and on screen when the panel grows.
- `BannerHeading` widens past its authored width when a translated heading would run into the ribbon tails.
- The Castle/Tower priority selector titles wrap. The popup is positioned using its combined minimum size.
- Body text in the popups (New Enemy Incoming, feature unlock, tower-targeting tutorial, exit confirm) has side padding so wrapped lines clear the paper border.
- Target-priority buttons wrap. A few overlong translations were shortened at the source (de/ru/uk/pl/fr/pt/it/es *Second Wind*, Indonesian HUD lines, ru/vi bestiary speed).

## 52.6 Promotion codes stay separate

`docs/promotion_codes.csv` is private developer data, not game localization. It and the `.translation` files Godot generates from it are git-ignored (`/docs/promotion_codes.*`), never listed in `internationalization/locale/translations`, and excluded from exports by the `docs/*` filter.

The localization probe checks all three conditions: git-ignored, not registered, and absent from `TranslationServer` keys.

Known issue: one CSV column header (*"Did he add a comment?"*) makes Godot's CSV importer report an invalid file name. This is harmless, and the file was left untouched.

## 52.7 Validation and tests

- **`tests/probes/localization_probe.tscn`**, run headless, checks:
  - registration and isolation;
  - the 20 catalogs and identical key sets;
  - no untranslated values;
  - placeholder parity;
  - every data-resource key resolves;
  - device-locale resolution;
  - preference persistence and reset immunity;
  - glyph coverage of every catalog character through the fallback chain;
  - live refresh of open UI.
- **`tests/probes/localization_layout_probe.tscn`** opens about 60 screens in every locale at the 1920×1080 reference. Screens include the HUD, every panel, settings sub-dialogs, tutorials, guides, story cards, end screens, offline reward, milestone reveals and selectors.
  - It compares each locale against the English geometry baseline and checks absolute rules: panels on screen, title ribbons visible, no text past its control.
  - Pass `-- --locales=de-DE,ja-JP` to limit the locales (English is always included).
  - Pass `--shots=<absolute dir>` from a **windowed** run to save PNG screenshots for visual review.
  - Headless runs force a 1920×1080 KEEP canvas, because the 64×64 headless window would otherwise produce a 1920×1920 canvas.
- How to run the probes (from the project directory):

  ```text
  Godot_v4.7.2-stable_win64_console.exe --headless --path . res://tests/probes/localization_probe.tscn
  Godot_v4.7.2-stable_win64_console.exe --headless --path . res://tests/probes/localization_layout_probe.tscn
  ```

- Two older probes compared against English literals. They now compare against `Localization.t(...)`:
  - `final_feature_core_probe`: the Beat Stage description;
  - `checkpoint6_probe`: the HUD Prestige label.
- The localization probe now also checks Spanish catalog resolution:
  - device locales `es_419`, `es-419`, `es`, `es_MX`, `es-MX` and `es_CO` resolve to es-419;
  - `es_ES` and `es-ES` resolve to es-ES;
  - es-419 loads `es.po` (engine locale `es`) and es-ES loads `es_ES.po` (engine locale `es_ES`);
  - each catalog is served for all 52 keys whose text differs between the two.
- `tests/probes/save_isolation_probe.tscn` enforces probe save isolation (section 26 and `docs/README.md`).

## 52.8 Correction pass results (2026-10-14)

- Probes:
  - `localization_probe` 188 / 0;
  - `localization_layout_probe` 20 / 0;
  - `save_isolation_probe` 55 / 0;
  - `checkpoint_c2b_probe` 49 / 0;
  - `post_cp6_probe` 78 / 0;
  - `restart_lifecycle_probe` 110 / 0;
  - `checkpoint4_probe` 62 / 0;
  - `checkpoint8_balance_simulation` completes.
- After the full suite, `user://everfort_save.json` was still absent and only `user://probe_sandbox/` had been written.
- Known legacy probe failures. They are identical at the pre-localization commit `f7ed49b` (run from a HEAD snapshot with its own user dir), so they are not regressions:
  - failures: `checkpoint1` (4), `checkpoint5` (2), `checkpoint6` (12), `final_feature_core` (4);
  - hangs (no watchdog): `checkpoint2`, `3`, `8` and `9`;
  - all of these are stale balance/flow expectations and still need modernizing.
- Release export check (`--export-release "Android"`, AAB inspected entry by entry):
  - all 20 `.po` catalogs are exported with full content and registered in `project.binary`;
  - all six Noto subsets (Devanagari, Thai, JP, KR, SC, TC) are exported as imported fontdata;
  - ICU text-server data (`icudt_godot.dat`) is exported;
  - nothing named `promotion*` and no `docs/` folder is in the bundle;
  - none of the promotion codes and not the CSV header appear in any bundle file.
- The export also ships `tests/probes/*` scenes, because `tests/*` is not in the exclude filter. This is harmless, since the probe sandbox only triggers when the engine is launched on a test scene, but it is worth excluding before release.
- **Remaining release QA gate:** no Android device or emulator was available, so the physical non-English smoke test has not been done. Before the next release upload, test German, Russian, Hindi, Thai, Japanese and Simplified Chinese on a device: live switching, persistence across relaunch, glyph shaping (Thai/Hindi), CJK line breaking and wrapping, and the major screens.
