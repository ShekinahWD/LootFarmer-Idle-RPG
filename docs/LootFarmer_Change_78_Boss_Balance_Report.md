# LootFarmer — Boss Balance Investigation (Change 78, report only)

> **Status (2026-11-14, Change 79):** historical "before" audit. Change 79 implemented a measured boss balance that differs from §6–7 here (per-boss HP and hit tuning, damaging skills for Elephant, Squirrel and Sunflower, and a trim of the boss-only Prestige effects): see `docs/LootFarmer_Change_79_Boss_Balance_Report.md`. The numbers below describe commit `1cde5b5`.

Date: 2026-11-13. Code: commit `1cde5b5` (Change 78's five fixes included, so enemy skills already follow the new priority rule). Game version 41, Android version code 41. **Nothing in this report has been implemented.** Every boss stat is unchanged in the repository.

## 1. Summary

The reported problem is real, but its main causes are not "boss damage is too low" across the board.

1. **From Summer II on, normal enemies fight as a group, but boss damage is still sized against a 3-enemy spot.** The boss basic-hit floor (`progression.balance.boss_spot_share` 0.9, applied by `tools/tune_campaign.py`) is 0.9 × 3 × the stage's strongest normal hit. On Winter I–Summer I the normals are *passive*: one attacks at a time, so the boss hits about 2× harder per second than anything else (measured 1.9–2.5×). From Summer II they *aggro as a group*. A standard 3-enemy spot then deals about as much per second as the boss (0.76–1.18×), and a 6-enemy spot (Spawn Amount upgrades) deals 1.4–1.9× it on Summer II and Autumn I. A player who farms those spots has already survived more pressure than the boss applies.
2. **Prestige boss cards decide most boss fights.** One Prestige with the boss-leaning picks (+25% and +20% boss damage, 5% lifesteal, +20% HP) cuts boss fight time by 30–50%. With three Prestiges (adds −20% boss damage taken), every boss from Summer II to Spring II is won with **85–99% HP left** at the power where its stage's 6-enemy spots become farmable. Normal enemies get none of the boss-only bonuses. In the natural playthroughs, the bot reached Summer II only after 2–4 Prestiges, so these cards are what a realistic player brings.
3. **Three bosses have no damaging skill.** Elephant (Focus), Squirrel (Heal, Focus) and Sunflower (Heal, Focus) threaten only with basic attacks. They are the weakest per second in their stages.
4. **Spring II bosses are HP sponges, not threats.** At farm-capable power, Red Panda and Sunflower fights last 5½–7 minutes and cost 17–31 Health Potions. They are lost by attrition, not by danger.
5. **Not causes:** player Defense (the attribute rolls 1–4 at every tier; measured builds carry 0–12 Defense, ≤11% mitigation), attack interval (tuned in Change 62), and boss skill activation (one cast every 10.6 s, as designed; the respawn bug fixed in Change 78 delayed only the first skill after a boss respawn).

Verdicts (no-Prestige player at the power where the stage's 6-enemy spots become farmable):

| Boss | Verdict | Recommendation |
|---|---|---|
| Snowman, Cyan Robot, Gray Cat | Appropriate (about 2× any other threat per second; winnable at natural levels) | No change |
| Elephant (Summer II) | **Underpowered**: 0.56× a 6-spot per second, no damaging skill | Damage +20%, HP −25%, add Strike |
| Teal Dinosaur (Summer II) | **Underpowered**: 0.70× a 6-spot per second | Damage +20%, HP −25% |
| Squirrel (Autumn I) | **Underpowered**: 0.54× a 6-spot per second, no damaging skill | Damage +15%, HP −25%, Strike replaces Focus |
| Red Fox (Autumn I) | Slightly underpowered per second (0.70×), long fight | Damage +15%, HP −25% |
| Black Cat, Grim Reaper (Autumn II) | Appropriate without Prestige (need 2–4 ladder rungs beyond farming) | No stat change; see §7 (Prestige) |
| Bee, Orange Tabby Cat (Spring I) | Appropriate without Prestige (1.1–1.2× a 6-spot per second) | No stat change; see §7 (Prestige) |
| Red Panda (Spring II) | **HP sponge** (6-minute fights, 22–24 potions) | HP −50%, damage +20% |
| Sunflower (Spring II) | **HP sponge**, no damaging skill | HP −50%, damage +10%, Fire replaces Focus |
| Green Alien (final) | Not measured (needs all 13 keys and its own kit harness) | No recommendation yet (§8) |

The recommended set leaves Snowman to Gray Cat and the Autumn II and Spring I bosses untouched. Where tested, it keeps each boss winnable within one ladder rung of where it is winnable today, shortens fights by 25–72%, and raises the damage taken per second by 17–61%. On its own it does **not** make bosses dangerous for a 3-Prestige player (§7).

## 2. Method and evidence

All runs use the real `LootSimulation` stepped at 0.1 s: real aggro and assist, boss telegraphs, enemy skills, heals, Focus, potions, auto-cast and auto-supplies. Evidence classes follow Playbook 112.2.

| Evidence | What it is | Where |
|---|---|---|
| **Theoretical** | Catalog values through the game's own formulas (variants, Spring ×0.60 normal scale, boss cooldown 10 s + 0.6 s telegraph, skill powers) | §3, `theory_table.txt` |
| **Measured, constructed builds** (class 1 fixtures) | `tests/player_feedback_audit.tscn` (the Change 48 harness, unchanged). Builds via real game calls: level, merges, stored items, skills, supplies and auto-use, and Prestige cards through the real Prestige transaction. A 10-rung **power ladder** per stage, from stage arrival to 25% past the boss's level: tier-N weapon (H24: stage N drops tier N; ^0→^20, Obsidian ^0→^100), the previous boss's outfit ^10→^300, the stage's outfits stored ^5→^120, skills ^0→^60, supply mastery rising, auto Potion/Guard Tonic/Recovery Salve, auto skills. 1,326 ladder trials; 540 single-build trials; 574 what-if trials | §4–6 |
| **Measured, natural playthrough** (class 3) | The Phase 1 Active-policy bot, two fresh profiles, 300 active minutes each | §5 |

"Rung where 6-spots become farmable" = the first rung that wins both of the stage's two most dangerous variant spots at 6 enemies with ≥25% HP, in every seed. On Winter I–Summer I spots are passive and farmable from arrival, so the boss's first winning rung is used instead.

What-ifs (§6–7) patch one boss's definition in memory for one fight (`boss_audit.gd.txt`, a copy of the harness with a `patch` field) and restore it after. No game file changes.

## 3. Theoretical boss and spot output (pre-Defense)

Normal-attack DPS = hit ÷ interval. Skill DPS = sum of attack-skill hits ÷ (number of skills × 10.6 s). Focus adds +15% for 5 s of each rotation. Effective DPS = (normal + skill) × Focus factor. The "strongest spot" is the normal type and variant with the highest per-enemy DPS, including its skill.

| Stage | Boss | HP | Hit | Interval | Normal DPS | Skills (per cast; cooldown 10 s + 0.6 s telegraph) | Skill DPS | Effective DPS | Strongest spot (type, variant) | Per-enemy DPS | 3-enemy DPS | 6-enemy DPS | Normals attacking at once | Boss ÷ spot at once |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 Winter I | Snowman | 600 | 8.0 | 2.0 | 4.0 | — | 0 | 4.0 | Chef Hat v1 | 2.31 | 6.9 | 13.9 | 1 (passive) | 1.73 |
| 2 Winter II | Cyan Robot | 1,096 | 13.3 | 1.9 | 7.0 | Heal 8% HP | 0 | 7.0 | Space Helmet v1 | 4.11 | 12.3 | 24.6 | 1 (passive) | 1.71 |
| 3 Summer I | Gray Cat | 2,089 | 23.2 | 1.8 | 12.9 | Lightning 33 | 3.1 | 16.0 | Yellow Cap v3 | 7.29 | 21.9 | 43.7 | 1 (passive) | 2.19 |
| 4 Summer II | Elephant | 3,927 | 38.4 | 1.7 | 22.6 | Focus | 0 | 24.2 | Snorkeler v3 | 12.66 | 38.0 | 75.9 | all (group) | 0.64 (3) / 0.32 (6) |
| 4 Summer II | Teal Dinosaur | 4,378 | 38.4 | 1.65 | 23.3 | Fire 61 | 5.8 | 29.1 | Snorkeler v3 | 12.66 | 38.0 | 75.9 | all | 0.77 / 0.38 |
| 5 Autumn I | Squirrel | 7,543 | 56.7 | 1.6 | 35.4 | Heal 8%, Focus | 0 | 36.7 | Pumpkin Head v3 | 18.03 | 54.1 | 108.2 | all | 0.68 / 0.34 |
| 5 Autumn I | Red Fox | 8,410 | 56.7 | 1.55 | 36.6 | Fire 91, Strike 159 | 11.8 | 48.3 | Pumpkin Head v3 | 18.03 | 54.1 | 108.2 | all | 0.89 / 0.45 |
| 6 Autumn II | Black Cat | 20,084 | 98.9 | 1.5 | 65.9 | Lightning 138, Focus | 6.5 | 75.0 | Top Hat v1 | 30.51 | 91.5 | 183.1 | all | 0.82 / 0.41 |
| 6 Autumn II | Grim Reaper | 22,393 | 98.9 | 1.45 | 68.2 | Frost 119, Strike 277 | 18.7 | 86.8 | Top Hat v1 | 30.51 | 91.5 | 183.1 | all | 0.95 / 0.47 |
| 7 Spring I | Bee | 66,474 | 150.2 | 1.4 | 107.3 | Lightning 210, Heal 8% | 9.9 | 117.2 | Elf Ears v1 | 36.68 | 110.1 | 220.1 | all | 1.06 / 0.53 |
| 7 Spring I | Orange Tabby Cat | 74,114 | 161.0 | 1.35 | 119.3 | Fire 258, Focus | 12.2 | 136.0 | Elf Ears v1 | 36.68 | 110.1 | 220.1 | all | 1.24 / 0.62 |
| 8 Spring II | Red Panda | 176,986 | 280.7 | 1.33 | 211.1 | Frost 337, Heal 8% | 15.9 | 227.0 | Sprout v1 | 78.81 | 236.4 | 472.8 | all | 0.96 / 0.48 |
| 8 Spring II | Sunflower | 197,330 | 301.0 | 1.32 | 228.0 | Heal 8%, Focus | 0 | 236.1 | Sprout v1 | 78.81 | 236.4 | 472.8 | all | 1.00 / 0.50 |
| 8 Spring II | Green Alien (final) | 304,514 | 345.8 | 1.3 | 266.0 | Final kit: Heal 4% below 50% HP; else random Fire 553 / Strike 968 / Frost / Lightning / Focus, 11 s gap | ≈42 | ≈312 | Sprout v1 | 78.81 | 236.4 | 472.8 | all | 1.32 / 0.66 |

Where the numbers come from: from Summer I to Autumn II every boss hit equals the floor exactly (2.70 × the strongest normal's hit). Spring bosses come from the level formula (`boss_damage` 1.55): their floor includes Spring's ×0.60 normal scale, so it is lower than the formula. Bosses have 0 Defense. Skill hits are a small share of boss damage: 0% (Elephant, Squirrel, Sunflower), 7–9% (Black Cat, Bee, Tabby, Red Panda), 20–24% (Teal, Red Fox, Grim Reaper).

## 4. Measured: boss fights and ordinary encounters at the same power (no Prestige)

Build at the rung where 6-enemy spots become farmable (Winter I–Summer I: the boss's first winning rung). Auto supplies and auto skills. "Taken/s" is the measured damage the player received per second of the fight. It includes the player's own kill speed, Frost slows and Guard Tonic.

| Stage | Boss | Rung (level / damage / HP) | Result | Fight (s) | Boss taken/s | Potions | Boss casts/min | Strongest 3-spot taken/s | Strongest 6-spot taken/s | Boss ÷ 3-spot | Boss ÷ 6-spot | First winning rung |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 Winter I | Snowman | r6 (L6 / 13 / 152) | Win, 5% HP | 50 | 4.0 | 3 | 0 | 1.7 | 1.6 | 2.34 | 2.44 | r6 |
| 2 Winter II | Cyan Robot | r4 (L16 / 24 / 279) | Win, 20% | 74 | 6.8 | 5 | 4.9 | 2.8 | 2.7 | 2.45 | 2.53 | r4 |
| 3 Summer I | Gray Cat | r3 (L29 / 40 / 344) | Win, 23% | 58 | 13.4 | 4 | 6.2 | 7.1 | 6.3 | 1.88 | 2.12 | r3 |
| 4 Summer II | Elephant | r2 (L48 / 66 / 531) | Win, 41% | 63 | 18.8 | 4 | 5.7 | 17.8 | 33.4 | 1.06 | **0.56** | r2 |
| 4 Summer II | Teal Dinosaur | r2 | Loss | 55 | 23.4 | 4 | 6.6 | 17.8 | 33.4 | 1.32 | **0.70** | r3 |
| 5 Autumn I | Squirrel | r5 (L95 / 134 / 896) | Win, 43% | 72 | 28.7 | 4 | 5.8 | 33.9 | 53.3 | 0.85 | **0.54** | r4 |
| 5 Autumn I | Red Fox | r5 | Loss | 61 | 37.6 | 5 | 5.9 | 33.9 | 53.3 | 1.11 | **0.70** | r6 |
| 6 Autumn II | Black Cat | r3 (L122 / 208 / 1,286) | Loss | 53 | 56.3 | 4 | 5.6 | 46.1 | 80.8 | 1.22 | 0.70 | r5 |
| 6 Autumn II | Grim Reaper | r3 | Loss | 29 | 72.3 | 2 | 6.2 | 46.1 | 80.8 | 1.57 | 0.90 | r7 |
| 7 Spring I | Bee | r4 (L186 / 714 / 1,747) | Loss | 37 | 97.8 | 3 | 6.5 | 43.7 | 89.5 | 2.24 | 1.09 | r6 |
| 7 Spring I | Orange Tabby Cat | r4 | Loss | 30 | 105.0 | 2 | 6.1 | 43.7 | 89.5 | 2.40 | 1.17 | r7 |
| 8 Spring II | Red Panda | r7 (L277 / 982 / 4,908) | Win, 72% | **351** | 149.9 | **22** | 5.6 | 111.0 | 194.8 | 1.35 | 0.77 | r6 |
| 8 Spring II | Sunflower | r7 | Loss | **356** | 193.9 | **31** | 5.6 | 111.0 | 194.8 | 1.75 | 1.00 | r9 |

Readings:

- **Winter I–Summer I:** the boss is the most dangerous encounter by about 2× and is beaten at the natural level (the bot: Snowman at L8–10, Robot at L21, Gray Cat at L36–47).
- **Summer II, Autumn I:** the boss applies about the pressure of a 3-enemy spot and half of a 6-enemy spot, and is beaten within one rung of the power where 6-spots become farmable. The boss is the slowest fight on the map but not the most dangerous one.
- **Autumn II, Spring I:** the boss is 0.7–1.2× a 6-spot per second and needs 2–4 rungs beyond 6-spot farming. Without Prestige it is the stage's gate. Grim Reaper and Orange Tabby Cat are the strongest gates.
- **Spring II:** both bosses are 6-minute fights and lean on 20–30 potions. Sunflower needs the top rung (L300).
- **Boss skills:** bosses with skills cast 4.9–6.6 times per minute, matching the 10 s cooldown plus telegraph. Every skill is telegraphed for 0.6 s and can be dodged by leaving its reach. No measured case of a skill that is never used.

## 5. Survivability, Prestige and natural pace

| Stage | Boss | Time to die, boss-level build without potions or skills (taken/s on HP) | Same build vs worst 6-spot | No Prestige at r6 | 1 Prestige at r6 | 3 Prestiges at r6 |
|---|---|---|---|---|---|---|
| 1 | Snowman | 40 s (4.1/s on 164) | Win 87% | Win 5%, 50 s | Win 63%, 30 s | — |
| 2 | Cyan Robot | 36 s (6.9/s on 249) | Win 79% | Win 42%, 68 s | Win 90%, 39 s | — |
| 3 | Gray Cat | 23 s (17.5/s on 397) | Win 59% | Win 43%, 50 s | Win 72%, 35 s | — |
| 4 | Elephant | 24 s (23.3/s on 568) | Loss in 10 s | Win 59%, 50 s | Win 95%, 35 s | Win 98%, 31 s |
| 4 | Teal Dinosaur | 20 s (27.9/s on 568) | Loss in 10 s | Win 48%, 56 s | Win 72%, 39 s | Win 94%, 35 s |
| 5 | Squirrel | 20 s (37.6/s on 763) | Loss in 8 s | Win 56%, 69 s | Win 84%, 43 s | Win 87%, 40 s |
| 5 | Red Fox | 16 s (49.2/s on 763) | Loss in 8 s | Win 25%, 61 s | Win 63%, 42 s | Win 85%, 38 s |
| 6 | Black Cat | 16 s (76.4/s on 1,252) | Loss in 8 s | Win 47%, 80 s | Win 74%, 54 s | Win 94%, 44 s |
| 6 | Grim Reaper | 12 s (105.2/s on 1,252) | Loss in 8 s | Loss, 80 s | Win 48%, 60 s | Win 92%, 51 s |
| 7 | Bee | 26 s (114.7/s on 2,924) | Loss in 18 s | Win 36%, 83 s | Win 93%, 54 s | Win 99%, 41 s |
| 7 | Orange Tabby Cat | 24 s (121.3/s on 2,924) | Loss in 18 s | Loss, 60 s | Win 96%, 52 s | Win 96%, 40 s |
| 8 | Red Panda | 14 s (217.1/s on 2,974) | Loss in 8 s | Win 43%, 370 s | Win 88%, 181 s | Win 96%, 129 s |
| 8 | Sunflower | 14 s (217.1/s on 2,974) | Loss in 8 s | Loss, 156 s | Win 75%, 214 s | Win 90%, 160 s |

1 Prestige = the real transaction over 7 opportunities with boss-leaning picks (boss damage +25% and +20%, lifesteal 5%, HP +20%, normal damage +20%, movement, coins). 3 Prestiges = 13 cards, adding boss damage taken −20%, equipped item +20%, skills +25% and economy cards.

Natural playthroughs (Active bot, 300 active minutes, seeds 1–2): Summer II was first reached at 222.6 and 138.9 minutes, after 2 and 4 Prestiges. Each Prestige gave 1–4 cards; seed 2 arrived holding both boss-damage cards, seed 1 one of them (the second came with its next Prestige). At the end the bot was L55–56 with 96–125 damage and 477–513 HP, farming Summer II's weakest types. It never judged a Summer II boss beatable (its own margin estimate 0.9–1.49 against the 1.5 it needs). Deaths: one to the Gray Cat group at L21, one to a Summer II normal spot (Straw-Hat Swimmers) at L47. This sits between ladder rungs r2 and r3 with 2–4 Prestiges, so the Prestige columns above are the realistic ones.

Player Defense is not a lever today: outfit Defense rolls 1–4 at every tier; weapons roll none. Milestones add 3 × tier at ^100. Measured builds carry 0–12 Defense (up to 11% mitigation). Survival comes from HP (5 per level, outfit copy growth, stored outfits at 15%), lifesteal (cards and rolls), Health Potions and Recovery Salve.

## 6. Recommendations (stat and kit changes)

Each patch below was measured as an in-memory what-if at the same rungs, seeds and policy as the baseline. "Rung" is the stage ladder in §2. HP left is the mean of the seeds.

### Elephant — Summer II

| | HP | Hit | Interval | Skills |
|---|---|---|---|---|
| Current | 3,926.74 | 38.41 | 1.70 | Focus (+15% for 5 s) |
| Recommended | **2,945.05 (−25%)** | **46.09 (+20%)** | 1.70 (0%) | **Strike (2.8× = 129.1 per hit), Focus** |

Reason: the weakest boss per second in its stage (0.56× a 6-spot), with no damaging skill. A telegraphed Strike adds a dodgeable spike; the lower HP keeps the fight from turning into attrition.
Measured impact: no Prestige, first win moves from r2 to r3 (Win 21%, 44 s; was Win 43%, 60 s), damage taken +61% (17.8 → 28.6/s, ≈0.9× a 6-spot). 1 Prestige: r3 65% → 50% HP left, r6 95% → 72%. 3 Prestiges: r6 98% → 93%.

### Teal Dinosaur — Summer II

| | HP | Hit | Interval | Skills |
|---|---|---|---|---|
| Current | 4,378.11 | 38.41 | 1.65 | Fire (61.5) |
| Recommended | **3,283.58 (−25%)** | **46.09 (+20%)** | 1.65 (0%) | Fire (73.7) |

Reason: 0.70× a 6-spot per second and a long fight.
Measured impact: no Prestige, first win stays r3 (Win 17%, 49 s; was 50%, 66 s); taken +23% (21.7 → 26.6/s). 1 Prestige: r3 51% → 52%, r6 72% → 66%. 3 Prestiges: r6 94% → 92%.

### Squirrel — Autumn I

| | HP | Hit | Interval | Skills |
|---|---|---|---|---|
| Current | 7,543.26 | 56.68 | 1.60 | Heal 8%, Focus |
| Recommended | **5,657.44 (−25%)** | **65.19 (+15%)** | 1.60 (0%) | **Strike (182.5), Heal 8%** (Strike replaces Focus) |

Reason: the weakest boss per second in its stage (0.54× a 6-spot), with no damaging skill.
Measured impact: no Prestige, first win moves r4 → r5 (Win 6%, 50 s; r6 Win 37%; was r5 Win 43%, 72 s); taken +45% (28.7 → 41.7/s). 1 Prestige: r3 70% → 44%, r6 84% → 60%. 3 Prestiges: r6 87% → 83%.

### Red Fox — Autumn I

| | HP | Hit | Interval | Skills |
|---|---|---|---|---|
| Current | 8,410.34 | 56.68 | 1.55 | Fire (90.7), Strike (158.7) |
| Recommended | **6,307.75 (−25%)** | **65.19 (+15%)** | 1.55 (0%) | Fire (104.3), Strike (182.5) |

Reason: 0.70× a 6-spot per second; already the harder Autumn I boss, so a smaller change.
Measured impact: no Prestige, first win stays r6 (Win 26%, 46 s; was 25%, 61 s); taken +18% (37.5 → 44.1/s). 1 Prestige: r3 50% → 33%, r6 63% → 63%. 3 Prestiges: r6 85% → 81%.

### Red Panda — Spring II

| | HP | Hit | Interval | Skills |
|---|---|---|---|---|
| Current | 176,986 | 280.74 | 1.33 | Frost (336.9), Heal 8% (14,159) |
| Recommended | **88,493 (−50%)** | **336.89 (+20%)** | 1.33 (0%) | Frost (404.3), Heal 8% (7,079) |

Reason: a 6-minute attrition fight that leans on potions. Pressure per second is 0.77× a 6-spot.
Measured impact: no Prestige, r6 Win 43% in 370 s with 24 potions → Win 43% in 105 s with 9; r7 72% / 351 s / 22 → 56% / 103 s / 7. First win stays r6. Taken +24% (151 → 187/s). 1 Prestige r6: 88% / 181 s / 9 → 79% / 68 s / 3. 3 Prestiges r6: 96% / 129 s → 99% / 53 s.

### Sunflower — Spring II

| | HP | Hit | Interval | Skills |
|---|---|---|---|---|
| Current | 197,330 | 300.95 | 1.32 | Heal 8%, Focus |
| Recommended | **98,665 (−50%)** | **331.05 (+10%)** | 1.32 (0%) | **Fire (529.7), Heal 8%** (Fire replaces Focus) |

Reason: the hardest Spring II gate, but only through length (356–406 s, 26–31 potions), with no damaging skill.
Measured impact: no Prestige, first win moves **earlier**, r9 → r8 (r8: Loss after 378 s and 27 potions → Win 41%, 120 s, 11 potions; r9: 77% / 406 s / 26 → 54% / 120 s / 8). Taken +17% (192 → 225/s). 1 Prestige r6: 75% / 214 s / 11 → 62% / 80 s / 5. 3 Prestiges r6: 90% / 160 s → 89% / 61 s.

### Bosses with no stat recommendation

- **Snowman, Cyan Robot, Gray Cat:** about 2× the pressure of anything else on their maps, beaten at natural levels with 5–43% HP left. Leave them as they are, and do not use them as references for later stages.
- **Black Cat, Grim Reaper, Bee, Orange Tabby Cat:** without Prestige they are already gates that need 2–4 rungs beyond 6-spot farming. A tested +30% / +20% / +30% / +25% hit cut no-Prestige r6 results sharply (Black Cat Win 47% → 19%, Bee Win 36% → loss) and barely moved 3-Prestige results (Bee 99% → 98%, Grim Reaper 92% → 94%). Their weakness is a Prestige problem (§7), not a stat problem.

### Implementation notes (for when this is approved)

- `tools/tune_campaign.py` recomputes every boss's HP and hit from the level formula and the floor, and would revert hand edits. The per-boss values above fit its existing `progression.balance.boss_overrides` ([HP multiplier, damage multiplier], as for the Snowman). For floor-bound bosses the damage multiplier must be raised far enough to clear the floor. Example: Elephant's formula hit is about 24.6, so 46.09 needs a multiplier of about 2.90 against the default 1.55.
- Skill kits are catalog data (`groups[].skills`); boss skill cooldown stays 10 s (`EnemyAbilityRules.boss_skill_cooldown`).
- HP changes do not change rewards (coins, XP and gems are separate catalog values).
- Re-run this ladder (`docs/Change_78_Boss_Balance_Evidence/`) after implementing, and compare cell by cell.

## 7. The Prestige factor (system recommendation, needs its own approval)

The stat set in §6 makes bosses fairer and more dangerous for first-run and 1-Prestige players. It cannot make them dangerous for the 3+ Prestige players who actually reach Summer II. A stronger, Prestige-calibrated stat set was tested to show why (damage +60% / +60% / +50% / +40% / +30% / +20% / +30% / +25% / +50% / +40% from Elephant to Sunflower, with the HP cuts above):

| Result at r6 (6-spot farming power) | No Prestige | 3 Prestiges |
|---|---|---|
| Current | 7 of 10 won (Grim Reaper, Orange Tabby Cat, Sunflower lost) | 10 of 10 won with 85–99% HP left |
| Prestige-calibrated stats | **2 of 10 won** (Elephant 14%, Black Cat 19%) | 10 of 10 won with 65–98% HP left |

Stats alone would make bosses walls for first runs and still leave them easy for Prestiged players. The spread comes from boss-only Prestige bonuses (+45% boss damage on the first Prestige, −20% boss damage taken later, plus lifesteal) that normal encounters do not see. Options for a separate decision, each needing its own measurement before numbers are chosen:

1. **Lower the boss-only card values** (for example boss damage +25/+20 → +15/+10, boss guard −20% → −10%), so Prestige stops pulling bosses away from the rest of the stage.
2. **Prestige-scaled boss threat** from Summer II on: bosses gain a small, capped share of damage per completed Prestige (the run count is already in the save). Prestige still helps, but bosses keep pace.
3. **Spread boss cards to all enemies at a reduced rate**, so a Prestiged player's power rises evenly instead of only against bosses.

## 8. Final boss (Green Alien)

Not measured: it needs all 13 keys and runs its own kit (`_final_turn`), which the duel harness does not enter. Theoretical effective DPS is about 312 (1.32× a 3-spot, 0.66× a 6-spot), and HP is 304,514. If Spring II's HP is halved, the final boss would have 3.4× Red Panda's HP. Recommendation: rebuild the Change 36 final-boss harness for the H24 weapon ladder and measure before changing anything. No values proposed.

## 9. Limitations

- Ladder builds are constructed fixtures. Random item attributes are stripped for comparability (Defense would add at most a few percent); boss attributes on gear are not included.
- The auto-supply policy drinks potions on the game's auto rules. A hand player who dodges telegraphs takes less skill damage, so measured boss pressure is an upper bound for skill-heavy bosses.
- Two to three seeds per cell. Results are deterministic per seed. Narrow wins (under 10% HP) can flip with a seed.
- The natural bot is validated on maps 1–3 only, and it plays conservatively (it never attacked a Summer II boss).
- Spring II normals are scaled ×0.60 (Change 53). Any change there moves the 6-spot reference for Spring II.
- Time to die without supplies is measured at one boss-level build per stage (`S*_ready_raw`), not across the ladder.

## 10. Reproduce

Everything is in `docs/Change_78_Boss_Balance_Evidence/`. The scripts locate the repository from `tests/tmp/c78/` (git-ignored), so copy them there first. From the repository root, with Godot 4.7.2:

```text
mkdir -p tests/tmp/c78 && cp docs/Change_78_Boss_Balance_Evidence/*.py tests/tmp/c78/
cp docs/Change_78_Boss_Balance_Evidence/boss_audit.gd.txt tests/tmp/c78/boss_audit.gd
sed 's#res://tests/player_feedback_audit.gd#res://tests/tmp/c78/boss_audit.gd#' tests/player_feedback_audit.tscn > tests/tmp/c78/boss_audit.tscn
python tests/tmp/c78/theory.py                                   # section 3
python tests/tmp/c78/ladder.py tests/tmp/c78/ladder_c78.json     # the power ladder builds
godot --headless --path . res://tests/player_feedback_audit.tscn -- --probe --profile=probe-audit78 --no-autosave       --first-run-complete --builds=res://tests/tmp/c78/ladder_c78.json --csv=res://tests/tmp/c78/ladder_c78.csv
python tests/tmp/c78/ladder_an.py tests/tmp/c78/ladder_c78.csv tests/tmp/c78/ladder_c78.json
godot --headless --path . res://tests/tmp/c78/boss_audit.tscn -- --probe --profile=probe-audit78 --no-autosave       --first-run-complete --builds=res://docs/Change_78_Boss_Balance_Evidence/whatif3_c78.json --csv=res://tests/tmp/c78/whatif3.csv
```

The natural playthroughs: `python tools/player_profile_run.py run --batch c78boss --seeds 1,2 --active-minutes 300 --max-wall-seconds 2400 --stall-minutes 45 --trace --label long` (about 20 minutes).
