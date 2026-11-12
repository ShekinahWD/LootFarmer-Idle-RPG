# LootFarmer — Change 62: Boss Damage, Attack Frequency, Skills & Aggression

**Status:** Developer-approved implementation brief for Claude  
**Scope:** Eight-stage combat balance and proximity-aggression rules only.  
**Authority:** The **current repository** (not an older uploaded ZIP), the canonical game GDD, and `docs/Reusable_Game_Development_Playbook.md`.  
**Validation ownership:** Claude performs short smoke checks; the developer personally playtests and decides subsequent balance adjustments.  
**No push or publication.**

## 1. Problem and intended result

Boss health feels acceptable, but bosses hit too softly and use abilities too rarely. In Summer I, the developer observed **three normal enemies dealing 9.22 Attack each** against a boss dealing roughly **15 Attack**, while the player had **33.85 Damage** at level 16. This is a player-observed example, not an authoritative source for every stage or save.

Adjust **boss basic damage, basic attack interval, and standard skill cooldowns** so bosses feel more dangerous than a regular three-enemy encounter. Separately correct proximity aggro: normal enemies stay passive through stage 3, while bosses become aggressive starting at stage 3. **Do not retune boss HP.**

## 2. Approved combat values

### 2.1 Boss basic attack intervals

Attack speed here means **seconds between normal attacks**; **smaller numbers = faster attacks**. Across successive bosses, the interval decreases progressively from **2.00 s** in Winter I to **1.30 s** at the last boss in Spring II.

The following is the target schedule for the boss order reported in the previous audit. Confirm live boss IDs/order in current content before applying; if names differ, retain the ordering and the endpoints rather than guessing or modifying unrelated enemies.

| Map (stage) | Boss | Target normal-attack interval |
|---|---|---:|
| Winter I (1) | Snowman | **2.00 s** |
| Winter II (2) | Cyan Robot | **1.90 s** |
| Summer I (3) | Gray Cat | **1.80 s** |
| Summer II (4) | Elephant | **1.70 s** |
| Summer II (4) | Teal Dinosaur | **1.65 s** |
| Autumn I (5) | Squirrel | **1.60 s** |
| Autumn I (5) | Red Fox | **1.55 s** |
| Autumn II (6) | Black Cat | **1.50 s** |
| Autumn II (6) | Grim Reaper | **1.45 s** |
| Spring I (7) | Bee | **1.40 s** |
| Spring I (7) | Orange Tabby Cat | **1.35 s** |
| Spring II (8) | Red Panda | **1.33 s** |
| Spring II (8) | Sunflower | **1.32 s** |
| Spring II (8) | Green Alien (final boss) | **1.30 s** |

Keep all movement, range, attack animation and non-boss attack-speed behavior intact unless a minimal technical correction is necessary to make these intervals actually effective. Don't change skill animation duration or the existing attack-warning duration as a substitute for attack cadence.

### 2.2 Boss basic attack damage

For **each** boss, set the **pre-defense normal-hit attack value** to **at least 90% of the combined normal-hit attack of a representative three-normal-enemy group from that boss's own stage**:

`boss_basic_attack >= 0.90 × (normal_attack_A + normal_attack_B + normal_attack_C)`

Use actual stage content and the same damage/stat basis for boss and normal enemies; do not compare a post-defense value to a raw catalog value. The reference is the normal **three-enemy encounter**, not six enemies from the optional Spawn Amount upgrade. Where regular enemy types/groups vary, choose and document a **representative real group** from the stage, showing the calculation; don't invent a generic multiplier or silently change enemy attack values.

**Illustrative Summer I example:** `3 × 9.22 × 0.90 = 24.894` boss basic Attack minimum (approximately **24.90**). The observed 9.22 is an example to compare against, not a hardcoded target if the current catalog computes a different value.

- **Do not lower** any boss attack that is already above its stage threshold.
- Do **not** alter normal enemy attack, boss HP, player stats, Defense formulas, or skill multipliers.
- Keep existing boss-specific mechanics, vulnerabilities, and attack patterns.
- In the final report, include current → new boss Attack values and the corresponding three-enemy reference. This is an **initial balance pass**, not a claim that boss difficulty is final.

### 2.3 Standard boss skill cooldowns

- Set **standard boss combat-skill cooldowns to 10 seconds** (previously commonly 20 seconds; if Winter II Heal is still 12 seconds, reduce it to 10 as well).
- Keep the **skill effect** (Heal/Focus/Lightning/Fire/Frost/Strike), damage multipliers, eligibility conditions, telegraphs, warnings and animations unchanged.
- A cooldown is a **minimum interval between successful uses**, not a guarantee of a cast if a skill's targeting/eligibility conditions are not met. Do not force skills through invalid conditions just to hit 10 s.
- **Final Green Alien:** inspect its existing 11-second special-action rotation and independent skill cooldowns. Preserve the distinct rotation unless its ordinary skills demonstrably use the standard 20-second cooldown; apply 10 seconds to standard skills without breaking the separate action/rotation timer. Report any special-case values retained and why.
- **Summon schedules** (e.g., Grim Reaper, Sunflower, Green Alien) are separate from standard combat skill cooldowns. Leave initial summon delay, summon interval, helper count and behavior unchanged.
- Snowman has no skill: do not invent one.

## 3. Approved proximity aggression (exact behavior)

| Stages | Normal enemies | Bosses |
|---|---|---|
| **1–2** — Winter I, Winter II | **Retaliate only once attacked** | **Retaliate only once attacked** |
| **3** — Summer I | **Retaliate only once attacked** | **Auto-aggro on player proximity, before being attacked** |
| **4–8** — Summer II through Spring II | **Auto-aggro on player proximity, before being attacked** | **Auto-aggro on player proximity, before being attacked** |

**Critical:** "On proximity" means **the player enters the enemy's actual detection range without attacking first**. It does **not** mean "after the player attacks." "Passive" means enemies can still fight/retaliate normally once the player attacks; it does not mean they cannot defend themselves. Keep existing target range/leash behavior and any deliberate special exception only if it does not contradict the stage rules above. Check actual code and data for old individual/group aggro settings overriding the new policy.

Stage 3 normal enemies must **not** auto-aggro; stage 3 bosses **must** auto-aggro. From stage 4 onward retain existing group response where implemented; this change does not introduce a simultaneous-attacker cap or globally change spawn count.

## 4. Implementation boundaries

- Inspect the current boss catalog, ability definitions, AI/aggro code, boss attack timing logic, and any shared multipliers before editing. Change the authoritative data/logic, not only displayed tooltips or test expectations. Ensure effective intervals reflect the configured values in gameplay.
- Preserve existing saves, map access, missions, Prestige progression, loot, previously approved upgrade systems and developer modifications.
- **Do not touch** the ongoing Guided tutorial UI findings (misleading pointers, Camp Found overlap, optional Map Mastery teaching); those are a separate follow-up.
- **Do not change** the GDD or Reusable Playbook in this batch; do not reorganize the untracked Cartoon Coffee asset pack.
- If a newly revised player-facing English value/string requires localization, record the changed key in the existing pending-handoff mechanism. **Do not regenerate or rewrite any of the 19 previously approved non-English `.po` catalogs.**

## 5. Minimal, focused validation — developer owns balance verdict

**Keep this quick: target at most 10 minutes of validation per pass; repeat a quick pass only when an implementation defect requires a fix.** No long playthroughs, pacing bots, full balance simulations, or full regression suite. Do not introduce a large new test harness for this small balancing batch.

Perform only:

1. **Data/code sanity:** all boss basic attack intervals monotonically reduce in order to 1.30 s; basic Attack meets each documented 90% three-enemy threshold; standard skill cooldowns are 10 s (except clearly documented final-boss special timers); boss HP values are unchanged.
2. **Aggro smoke:** in stages 2, 3 and 4, check untouched player proximity versus retaliating after damage, separately for normal enemies and bosses. Include stage 1 if the smoke setup permits easily.
3. **Boss smoke:** observe or quickly simulate a few valid normal hits at the requested interval and at least one standard skill reuse after about 10 s. Confirm no obvious errors or invalid trigger spam.
4. **Existing-data integrity:** lightweight parse/config and directly relevant targeted checks. If an old test still expects previous aggression or cooldown values, update **only the affected expectations**, without weakening unrelated tests. State anything not run.

The developer will evaluate boss lethality, ability feel, HP and difficulty in normal play afterward. **Do not self-rebalance beyond the numbers approved here** or repeatedly run multi-hour simulations to chase an arbitrary difficulty metric.

## 6. Git and completion report

- First inspect `git status --short`, protect the dirty working tree, and stage only paths actually owned by this change. Do not stage the untracked Cartoon Coffee folder, existing developer edits to `project.godot`/`export_presets.cfg`, Playbook, marketing scripts, or unrelated files.
- Once the short verification passes, create one **local** commit (unless the current branch already uses the next sequential change number; in that case report the conflict before inventing another):

  `balance(change-62): strengthen bosses and correct stage aggression`

- Report changed files, a **per-boss before/after table** (Attack, attack interval, skill cooldown, reference three-enemy combined attack), confirmed aggression by stage, exact short checks performed and failures, commit hash and outstanding Android/player balance verification.
- **Do not push, publish or run Android release/export workflows. Stop after this batch.**
