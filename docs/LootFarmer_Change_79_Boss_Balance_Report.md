# LootFarmer — Boss Balance (Change 79, implemented)

Date: 2026-11-14. Code: Change 79 working tree on top of `1cde5b5`. Game version 41, Android version code 41. This report replaces the recommendations of the Change 78 investigation (`docs/LootFarmer_Change_78_Boss_Balance_Report.md`, kept as the historical "before" audit). Every number below comes from the real `LootSimulation` stepped at 0.1 s through the Change 78 ladder harness. All runs used the same builds and seeds before and after the change. Evidence and scripts: `docs/Change_79_Boss_Balance_Evidence/`.

## 1. What changed

Only bosses from Summer II on and the boss-only Prestige effects changed. Normal enemies, rewards, attack intervals, boss cooldowns (10 s plus a 0.6 s telegraph) and the final boss's kit rules are unchanged. HP and hit come from `progression.balance.boss_tuning` (`[HP ×, hit ×]`). `tools/tune_campaign.py` applies them after the Change 62 spot floor, so the catalog stays generated and a re-run of the tool keeps them. Kits and card values are written by `tools/change79_catalog.py`.

| Stage | Boss | HP before → after | Hit before → after | Interval | Skills before → after | Why |
|---|---|---|---|---|---|---|
| Winter I | Snowman | 600 (unchanged) | 8.00 (unchanged) | 2.0 | none | Already the most dangerous encounter of its map by about 2×. Liked in play. |
| Winter II | Cyan Robot | 1,096 (unchanged) | 13.30 (unchanged) | 1.9 | Heal | Same as Snowman. |
| Summer I | Gray Cat | 2,089 (unchanged) | 23.23 (unchanged) | 1.8 | Lightning | Same as Snowman. |
| Summer II | Elephant | 3,927 → **3,141** (×0.80) | 38.41 → **44.17** (×1.15) | 1.7 | Focus → **Strike, Focus** | The weakest boss per second on its map (0.56× a 6-spot), with no damaging skill. Won at or below farming power with Prestige. |
| Summer II | Teal Dinosaur | 4,378 → **3,721** (×0.85) | 38.41 → **44.17** (×1.15) | 1.65 | Fire | 0.70× a 6-spot. With Prestige it was won before the map was farmable. |
| Autumn I | Squirrel | 7,543 → **6,035** (×0.80) | 56.68 → **73.69** (×1.30) | 1.6 | Heal, Focus → **Strike, Heal** | 0.50× a 6-spot, no damaging skill. Easier than farming the map even without Prestige (won one rung before 6-spots). |
| Autumn I | Red Fox | 8,410 → **7,149** (×0.85) | 56.68 → **65.19** (×1.15) | 1.55 | Fire, Strike | 0.65× a 6-spot. With Prestige it was won two rungs below farming power. |
| Autumn II | Black Cat | 20,084 → **18,076** (×0.90) | 98.85 → **108.74** (×1.10) | 1.5 | Lightning, Focus | With Prestige it was won below farming power with 40% HP to spare. |
| Autumn II | Grim Reaper | 22,393 → **20,153** (×0.90) | 98.85 → **86.99** (×0.88) | 1.45 | Frost, Strike (+2 helpers) | The opposite problem: without Prestige it needed 4 rungs past farming power. Slightly softened. |
| Spring I | Bee | 66,474 (unchanged) | 150.18 (unchanged) | 1.4 | Lightning, Heal | Already about 1.0× a 6-spot without Prestige. Only the card trim tightens it for Prestiged players. |
| Spring I | Orange Tabby Cat | 74,114 (unchanged) | 160.99 (unchanged) | 1.35 | Fire, Focus | Same as Bee. |
| Spring II | Red Panda | 176,986 → **79,644** (×0.45) | 280.74 → **379.01** (×1.35) | 1.33 | Frost, Heal | An HP sponge: 304–370 s and 15–24 potions at the first win. |
| Spring II | Sunflower | 197,330 → **88,799** (×0.45) | 300.95 → **346.10** (×1.15) | 1.32 | Heal, Focus → **Fire, Heal** (+2 helpers) | An HP sponge (281–406 s, 15–26 potions at the first win) with no damaging skill. |
| Spring II (final) | Green Alien | 304,514 → **137,031** (×0.45) | 345.84 → **415.01** (×1.20) | 1.3 | Final kit unchanged (Heal below 50%, random Fire / Strike / Frost / Lightning / Focus, 3 helpers) | 354–365 s and 21–22 potions at the first win with Prestige. No build without Prestige ever won it. |

Boss-only Prestige effects (same ids, owners and set rules; the value is read from the catalog at runtime):

| Card / combo | Before | After |
|---|---|---|
| Giant Slayer (`hunter_c1`) | +25% damage against bosses | **+15%** |
| Trophy Power (`trophy_c2`) | +20% damage against bosses | **+10%** |
| Boss Guard (`hunter_c2`) | 20% less damage from bosses | **10%** |
| Challenge set combo (`challenge_set`) | +10% damage against bosses | **+5%** |
| Boss Specialist combo (`boss_specialist`) | +10% damage against bosses | **+5%** |

Persistence: there is no save migration. Card ownership, ids, combos and Prestige history are untouched. A player who owns these cards gets the new values at once, because `campaign.bonus` reads the catalog. The five English descriptions changed through `tools/localization_handoff.py change`. Their 19 stale translations were removed, so players see the correct English until the translators deliver.

Giant Slayer and Trophy Power together still give +25% against bosses, more than the +20% from Expedition's normal-damage card. The cards still matter. They just no longer decide every boss fight.

## 2. Root causes (re-verified in this batch)

1. **Bosses lag behind their own maps from Summer II.** From Summer II normals aggro as groups. A 6-enemy spot dealt 1.4–2.0× a boss's damage per second there (Table B, "before"). The boss floor (0.9 × a 3-enemy spot) was sized for one attacker at a time.
2. **Prestige pulled bosses away from the rest of the stage.** The first Prestige's boss picks (+45% boss damage, 5% lifesteal) and Boss Guard (−20%) apply to bosses only. With one or three Prestiges, every Summer II and Autumn I boss was won one to three rungs *before* the player could farm the map's strongest spots (Table A, "before"). The Change 78 natural playthroughs reached Summer II after 2–6 Prestiges holding Giant Slayer and Trophy Power, so that is the realistic player.
3. **Three bosses had no damaging skill.** Elephant (Focus), Squirrel (Heal, Focus) and Sunflower (Heal, Focus) threatened only with basic hits. Their skills were cast on time (5.7–6.8 casts per minute, after the Change 78 priority fix), but none of them hurt.
4. **Spring II and the final boss were attrition.** First wins took 281–406 s and 15–26 potions (Green Alien 354–365 s and 21–22 potions). They were lost by running out of potions, not by danger per second.
5. **Not causes** (checked): skill activation and frequency, attack intervals, and player Defense (≤11% mitigation in every build). Combat order and post-respawn skill state also behave as Change 78 fixed them: bosses respawn with a fresh skill turn.

## 3. Method

- **Harness:** `boss_audit.gd.txt` is the Change 78 harness with an in-memory boss patch, a labelled 13-key fixture so Green Alien can be fought, and in-memory card values for what-if runs. Run in the real `LootSimulation`: real aggro and assist, telegraphs, helpers, heals, auto potions, Guard Tonic and Recovery Salve, and auto skills.
- **Builds:** the Change 78 power ladder (`docs/Change_78_Boss_Balance_Evidence/ladder_c78.json`), 10 rungs per stage from arrival to 25% past the boss level, unchanged. Each rung was run with 0, 1 and 3 Prestiges, taken through the real Prestige transaction with the boss-leaning picks of Change 78. Stages 4–8, bosses plus the two most dangerous variant spots at 3 and 6 enemies, plus Green Alien on Spring II. Seeds 1 and 2: 1,860 fights before and 1,860 after.
- **Evidence class:** constructed fixtures (Playbook 112.2 class 1). Level, merges, kills, supply mastery and stock are seeded and labelled. Prestige cards come from the real transaction. This is not a natural playthrough, and no player profile was run or changed.
- **Determinism:** before anything else, two recorded Change 78 cells were reproduced exactly (`repro.csv`: Elephant at L4_r3, 59.9 s, 43% left).
- **Iteration:** candidates 1 → 2 → 3 (`cand*.json`, `cand*_*.csv`), bosses only. Spots are untouched by these levers: all 1,200 spot trials are bit-identical before and after. Candidate 1 made Elephant a wall without Prestige (+3 rungs), so its hit went from ×1.30 to ×1.15. Grim Reaper ×0.92 / ×0.88 / HP-only variants all left the no-Prestige gate at +3 (see §6). The final set equals candidate 3, re-measured from the written catalog with no in-memory patch (`after_*.csv`).
- **Reading the tables:** "R6" is each profile's own farming power: the first rung where both of the stage's most dangerous 6-enemy spots are won with ≥25% HP. A good boss gate is won 0–2 rungs after R6, with real danger (lowest HP well under 50%) and a fight of 40–120 s (Spring II and the final boss a little longer).

## 4. Results in brief

- **Summer II and Autumn I** were won at or before the rung where the map could be farmed with Prestige (gaps 0 to −3) and lagged their 6-spots per second. Now no Prestige: +1 rung for all four bosses. One Prestige: 0. Three Prestiges: −1, with the lowest HP at farming power down to 25–39% (was 35–67%). Boss damage per second rose to 0.77–0.85× a 6-spot (was 0.50–0.70×).
- **Autumn II:** Black Cat now gates at +2 / +1 / 0 (was +2 / −1 / −1). Grim Reaper +3 / +1 / +1 (was +4 / +2 / +1).
- **Spring I:** stats unchanged. The card trim tightens it with Prestige: the lowest HP at farming power for 3 Prestiges fell from 40–50% to 23–25%.
- **Spring II:** fights at the first win dropped from 281–406 s with 15–26 potions to 80–101 s with 5–9 potions. Boss pressure is now 1.06–1.23× a 6-spot (was 0.77–0.99×). Gates +0 / +1 for every profile.
- **Green Alien:** without Prestige it is now winnable at the top rung (L300: 152 s, 14 potions, lowest HP 7%). It was never won before. With one Prestige, 122 s and 10 potions (was 354 s and 21). With three, 106 s and 6 (was 365 s and 22). It stays the hardest fight in the game: it needs two rungs past farming power for every profile and deals 1.46× a Spring II 6-spot per second.

## 5. Before and after

### 5.1 Table A — first winning rung and the fight at farming power (R6), before → after

R6 = the first rung where both of the stage's two most dangerous variant spots are won at 6 enemies with ≥25% HP left (both seeds), per Prestige profile. "Gap" = first winning rung − R6. Cells: result (both seeds), lowest HP during the fight, duration, Health Potions used, damage taken per second. 6-spot = the worse of the two 6-enemy spots at R6.

| Stage | Boss | Prestiges | R6 (level) | 6-spot taken/s | First win: before → after (gap) | At R6 before | At R6 after | At R6+1 before | At R6+1 after |
|---|---|---|---|---|---|---|---|---|---|
| Summer II | Elephant | 0 | r2 (L48) | 33 | r2 (+0) → r3 (+1) | Win, low 31%, 63 s, 4 pot., 19/s | Loss, low 0%, 44 s, 3 pot., 28/s | Win, low 35%, 60 s, 3 pot., 18/s | Win, low 9%, 47 s, 4 pot., 27/s |
| Summer II | Teal Dinosaur | 0 | r2 (L48) | 33 | r3 (+1) → r3 (+1) | Loss, low 0%, 55 s, 4 pot., 23/s | Loss, low 0%, 44 s, 3 pot., 27/s | Win, low 32%, 66 s, 5 pot., 22/s | Win, low 7%, 57 s, 4 pot., 25/s |
| Summer II | Elephant | 1 | r1 (L43) | 36 | r0 (-1) → r1 (+0) | Win, low 41%, 47 s, 2 pot., 19/s | Win, low 29%, 43 s, 3 pot., 27/s | Win, low 42%, 43 s, 2 pot., 19/s | Win, low 37%, 40 s, 3 pot., 27/s |
| Summer II | Teal Dinosaur | 1 | r1 (L43) | 36 | r1 (+0) → r1 (+0) | Win, low 35%, 52 s, 4 pot., 23/s | Win, low 6%, 51 s, 4 pot., 27/s | Win, low 37%, 48 s, 3 pot., 24/s | Win, low 35%, 48 s, 3 pot., 27/s |
| Summer II | Elephant | 3 | r1 (L43) | 38 | r0 (-1) → r0 (-1) | Win, low 60%, 42 s, 2 pot., 16/s | Win, low 39%, 39 s, 3 pot., 25/s | Win, low 77%, 40 s, 2 pot., 15/s | Win, low 54%, 37 s, 2 pot., 25/s |
| Summer II | Teal Dinosaur | 3 | r1 (L43) | 38 | r0 (-1) → r0 (-1) | Win, low 41%, 47 s, 2 pot., 19/s | Win, low 34%, 46 s, 3 pot., 25/s | Win, low 58%, 43 s, 2 pot., 18/s | Win, low 40%, 43 s, 2 pot., 24/s |
| Autumn I | Red Fox | 0 | r5 (L95) | 58 | r6 (+1) → r6 (+1) | Loss, low 0%, 61 s, 5 pot., 38/s | Loss, low 0%, 38 s, 3 pot., 45/s | Win, low 12%, 61 s, 4 pot., 37/s | Win, low 10%, 52 s, 4 pot., 42/s |
| Autumn I | Squirrel | 0 | r5 (L95) | 58 | r4 (-1) → r6 (+1) | Win, low 26%, 72 s, 4 pot., 29/s | Loss, low 0%, 44 s, 3 pot., 49/s | Win, low 39%, 69 s, 4 pot., 28/s | Win, low 4%, 51 s, 4 pot., 46/s |
| Autumn I | Red Fox | 1 | r3 (L83) | 58 | r2 (-1) → r3 (+0) | Win, low 33%, 49 s, 3 pot., 38/s | Win, low 17%, 49 s, 4 pot., 44/s | Win, low 47%, 47 s, 2 pot., 39/s | Win, low 20%, 46 s, 3 pot., 45/s |
| Autumn I | Squirrel | 1 | r3 (L83) | 58 | r0 (-3) → r3 (+0) | Win, low 46%, 52 s, 3 pot., 29/s | Win, low 3%, 48 s, 4 pot., 47/s | Win, low 56%, 49 s, 2 pot., 29/s | Win, low 24%, 45 s, 4 pot., 48/s |
| Autumn I | Red Fox | 3 | r2 (L77) | 62 | r0 (-2) → r1 (-1) | Win, low 35%, 47 s, 2 pot., 32/s | Win, low 29%, 47 s, 3 pot., 42/s | Win, low 53%, 43 s, 2 pot., 31/s | Win, low 35%, 43 s, 2 pot., 40/s |
| Autumn I | Squirrel | 3 | r2 (L77) | 62 | r0 (-2) → r1 (-1) | Win, low 67%, 49 s, 2 pot., 24/s | Win, low 25%, 46 s, 3 pot., 45/s | Win, low 79%, 46 s, 2 pot., 23/s | Win, low 34%, 42 s, 2 pot., 41/s |
| Autumn II | Black Cat | 0 | r3 (L122) | 81 | r5 (+2) → r5 (+2) | Loss, low 0%, 53 s, 4 pot., 56/s | Loss, low 0%, 38 s, 3 pot., 62/s | Loss, low 0%, 75 s, 6 pot., 56/s | Loss, low 0%, 58 s, 5 pot., 61/s |
| Autumn II | Grim Reaper | 0 | r3 (L122) | 81 | r7 (+4) → r6 (+3) | Loss, low 0%, 29 s, 2 pot., 72/s | Loss, low 0%, 35 s, 3 pot., 67/s | Loss, low 0%, 35 s, 3 pot., 75/s | Loss, low 0%, 38 s, 3 pot., 68/s |
| Autumn II | Black Cat | 1 | r2 (L113) | 88 | r1 (-1) → r3 (+1) | Win, low 17%, 68 s, 5 pot., 61/s | Loss, low 0%, 55 s, 4 pot., 67/s | Win, low 38%, 62 s, 3 pot., 55/s | Win, low 33%, 65 s, 4 pot., 60/s |
| Autumn II | Grim Reaper | 1 | r2 (L113) | 88 | r4 (+2) → r3 (+1) | Loss, low 0%, 35 s, 3 pot., 82/s | Loss, low 0%, 40 s, 3 pot., 72/s | Loss, low 0%, 58 s, 4 pot., 74/s | Win, low 14%, 74 s, 6 pot., 66/s |
| Autumn II | Black Cat | 3 | r1 (L104) | 81 | r0 (-1) → r1 (+0) | Win, low 40%, 62 s, 3 pot., 47/s | Win, low 27%, 65 s, 5 pot., 58/s | Win, low 44%, 60 s, 3 pot., 49/s | Win, low 30%, 60 s, 4 pot., 60/s |
| Autumn II | Grim Reaper | 3 | r1 (L104) | 81 | r2 (+1) → r2 (+1) | Loss, low 0%, 58 s, 4 pot., 66/s | Loss, low 0%, 55 s, 4 pot., 66/s | Win, low 12%, 65 s, 5 pot., 65/s | Win, low 6%, 69 s, 5 pot., 66/s |
| Spring I | Bee | 0 | r5 (L198) | 95 | r6 (+1) → r6 (+1) | Loss, low 0%, 38 s, 3 pot., 96/s | Loss, low 0%, 38 s, 3 pot., 96/s | Win, low 12%, 83 s, 8 pot., 88/s | Win, low 12%, 83 s, 8 pot., 88/s |
| Spring I | Orange Tabby Cat | 0 | r5 (L198) | 95 | r7 (+2) → r7 (+2) | Loss, low 0%, 40 s, 3 pot., 103/s | Loss, low 0%, 40 s, 3 pot., 103/s | Loss, low 0%, 60 s, 5 pot., 98/s | Loss, low 0%, 60 s, 5 pot., 98/s |
| Spring I | Bee | 1 | r2 (L163) | 102 | r3 (+1) → r3 (+1) | Loss, low 0%, 98 s, 8 pot., 99/s | Loss, low 0%, 60 s, 5 pot., 101/s | Win, low 35%, 81 s, 4 pot., 92/s | Win, low 27%, 101 s, 5 pot., 92/s |
| Spring I | Orange Tabby Cat | 1 | r2 (L163) | 102 | r3 (+1) → r3 (+1) | Loss, low 0%, 53 s, 4 pot., 111/s | Loss, low 0%, 48 s, 4 pot., 112/s | Win, low 36%, 75 s, 4 pot., 100/s | Win, low 29%, 86 s, 6 pot., 99/s |
| Spring I | Bee | 3 | r2 (L163) | 106 | r1 (-1) → r1 (-1) | Win, low 50%, 80 s, 4 pot., 80/s | Win, low 25%, 100 s, 6 pot., 90/s | Win, low 82%, 68 s, 3 pot., 74/s | Win, low 57%, 80 s, 4 pot., 83/s |
| Spring I | Orange Tabby Cat | 3 | r2 (L163) | 106 | r1 (-1) → r2 (+0) | Win, low 40%, 73 s, 4 pot., 88/s | Win, low 23%, 84 s, 6 pot., 97/s | Win, low 77%, 60 s, 3 pot., 80/s | Win, low 45%, 72 s, 4 pot., 91/s |
| Spring II | Red Panda | 0 | r7 (L277) | 195 | r6 (-1) → r7 (+0) | Win, low 32%, 351 s, 22 pot., 150/s | Win, low 24%, 94 s, 8 pot., 207/s | Win, low 37%, 334 s, 19 pot., 149/s | Win, low 31%, 85 s, 6 pot., 208/s |
| Spring II | Sunflower | 0 | r7 (L277) | 195 | r9 (+2) → r8 (+1) | Loss, low 0%, 356 s, 31 pot., 194/s | Loss, low 0%, 60 s, 5 pot., 241/s | Loss, low 0%, 378 s, 27 pot., 192/s | Win, low 14%, 101 s, 9 pot., 237/s |
| Spring II | Green Alien | 0 | r7 (L277) | 195 | none → r9 (+2) | Loss, low 0%, 60 s, 5 pot., 243/s | Loss, low 0%, 42 s, 4 pot., 285/s | Loss, low 0%, 98 s, 8 pot., 248/s | Loss, low 0%, 40 s, 3 pot., 280/s |
| Spring II | Red Panda | 1 | r4 (L242) | 204 | r3 (-1) → r4 (+0) | Win, low 41%, 240 s, 12 pot., 159/s | Win, low 12%, 85 s, 7 pot., 218/s | Win, low 41%, 205 s, 10 pot., 152/s | Win, low 41%, 78 s, 4 pot., 217/s |
| Spring II | Sunflower | 1 | r4 (L242) | 204 | r4 (+0) → r5 (+1) | Win, low 27%, 305 s, 24 pot., 205/s | Loss, low 0%, 60 s, 5 pot., 250/s | Win, low 34%, 240 s, 14 pot., 198/s | Win, low 29%, 85 s, 6 pot., 240/s |
| Spring II | Green Alien | 1 | r4 (L242) | 204 | r6 (+2) → r6 (+2) | Loss, low 0%, 57 s, 4 pot., 255/s | Loss, low 0%, 38 s, 3 pot., 300/s | Loss, low 0%, 375 s, 29 pot., 232/s | Loss, low 0%, 70 s, 6 pot., 281/s |
| Spring II | Red Panda | 3 | r3 (L230) | 202 | r2 (-1) → r3 (+0) | Win, low 51%, 220 s, 11 pot., 129/s | Win, low 27%, 81 s, 5 pot., 199/s | Win, low 81%, 184 s, 9 pot., 126/s | Win, low 42%, 72 s, 4 pot., 199/s |
| Spring II | Sunflower | 3 | r3 (L230) | 202 | r3 (+0) → r4 (+1) | Win, low 32%, 281 s, 15 pot., 174/s | Loss, low 0%, 78 s, 6 pot., 231/s | Win, low 39%, 226 s, 12 pot., 173/s | Win, low 23%, 80 s, 5 pot., 230/s |
| Spring II | Green Alien | 3 | r3 (L230) | 202 | r4 (+1) → r5 (+2) | Loss, low 0%, 107 s, 8 pot., 225/s | Loss, low 0%, 39 s, 3 pot., 276/s | Win, low 22%, 365 s, 22 pot., 205/s | Loss, low 0%, 68 s, 5 pot., 267/s |

### 5.2 Table B — boss pressure against the same stage's dangerous normal groups (no Prestige, at R6)

| Stage | R6 | Strongest 3-spot taken/s | Strongest 6-spot taken/s | Boss | Boss taken/s before → after | ÷ 6-spot before → after | Boss casts/min after |
|---|---|---|---|---|---|---|---|
| Summer II | r2 | 18 | 33 | Elephant | 19 → 28 | 0.56 → 0.85 | 6.8 |
| Summer II | r2 | 18 | 33 | Teal Dinosaur | 23 → 27 | 0.70 → 0.82 | 6.8 |
| Autumn I | r5 | 39 | 58 | Red Fox | 38 → 45 | 0.65 → 0.77 | 6.3 |
| Autumn I | r5 | 39 | 58 | Squirrel | 29 → 49 | 0.50 → 0.84 | 6.8 |
| Autumn II | r3 | 46 | 81 | Black Cat | 56 → 62 | 0.70 → 0.77 | 6.3 |
| Autumn II | r3 | 46 | 81 | Grim Reaper | 72 → 67 | 0.90 → 0.82 | 6.8 |
| Spring I | r5 | 56 | 95 | Bee | 96 → 96 | 1.01 → 1.01 | 6.3 |
| Spring I | r5 | 56 | 95 | Orange Tabby Cat | 103 → 103 | 1.09 → 1.09 | 6.1 |
| Spring II | r7 | 112 | 195 | Red Panda | 150 → 207 | 0.77 → 1.06 | 5.7 |
| Spring II | r7 | 112 | 195 | Sunflower | 194 → 241 | 0.99 → 1.23 | 6.0 |
| Spring II | r7 | 112 | 195 | Green Alien | 243 → 285 | 1.25 → 1.46 | 6.4 |

### 5.3 Table C — fight length and potions at the first winning rung, before → after

| Stage | Boss | Prestiges | Before: rung, s, potions, low HP | After: rung, s, potions, low HP |
|---|---|---|---|---|
| Summer II | Elephant | 0 | r2: 63 s, 4, 31% | r3: 47 s, 4, 9% |
| Summer II | Teal Dinosaur | 0 | r3: 66 s, 5, 32% | r3: 57 s, 4, 7% |
| Summer II | Elephant | 1 | r0: 51 s, 3, 34% | r1: 43 s, 3, 29% |
| Summer II | Teal Dinosaur | 1 | r1: 52 s, 4, 35% | r1: 51 s, 4, 6% |
| Summer II | Elephant | 3 | r0: 46 s, 2, 41% | r0: 42 s, 3, 27% |
| Summer II | Teal Dinosaur | 3 | r0: 51 s, 3, 33% | r0: 50 s, 4, 6% |
| Autumn I | Red Fox | 0 | r6: 61 s, 4, 12% | r6: 52 s, 4, 10% |
| Autumn I | Squirrel | 0 | r4: 76 s, 6, 20% | r6: 51 s, 4, 4% |
| Autumn I | Red Fox | 1 | r2: 53 s, 4, 29% | r3: 49 s, 4, 17% |
| Autumn I | Squirrel | 1 | r0: 67 s, 5, 17% | r3: 48 s, 4, 3% |
| Autumn I | Red Fox | 3 | r0: 54 s, 4, 27% | r1: 49 s, 4, 5% |
| Autumn I | Squirrel | 3 | r0: 60 s, 3, 44% | r1: 48 s, 4, 2% |
| Autumn II | Black Cat | 0 | r5: 81 s, 6, 12% | r5: 74 s, 6, 6% |
| Autumn II | Grim Reaper | 0 | r7: 84 s, 7, 27% | r6: 80 s, 6, 21% |
| Autumn II | Black Cat | 1 | r1: 73 s, 6, 4% | r3: 65 s, 4, 33% |
| Autumn II | Grim Reaper | 1 | r4: 66 s, 5, 20% | r3: 74 s, 6, 14% |
| Autumn II | Black Cat | 3 | r0: 68 s, 5, 34% | r1: 65 s, 5, 27% |
| Autumn II | Grim Reaper | 3 | r2: 65 s, 5, 12% | r2: 69 s, 5, 6% |
| Spring I | Bee | 0 | r6: 83 s, 8, 12% | r6: 83 s, 8, 12% |
| Spring I | Orange Tabby Cat | 0 | r7: 75 s, 7, 26% | r7: 75 s, 7, 26% |
| Spring I | Bee | 1 | r3: 81 s, 4, 35% | r3: 101 s, 5, 27% |
| Spring I | Orange Tabby Cat | 1 | r3: 75 s, 4, 36% | r3: 86 s, 6, 29% |
| Spring I | Bee | 3 | r1: 106 s, 5, 33% | r1: 140 s, 10, 26% |
| Spring I | Orange Tabby Cat | 3 | r1: 90 s, 5, 33% | r2: 84 s, 6, 23% |
| Spring II | Red Panda | 0 | r6: 370 s, 24, 25% | r7: 94 s, 8, 24% |
| Spring II | Sunflower | 0 | r9: 406 s, 26, 29% | r8: 101 s, 9, 14% |
| Spring II | Green Alien | 0 | no win up to r9 | r9: 152 s, 14, 7% |
| Spring II | Red Panda | 1 | r3: 312 s, 17, 31% | r4: 85 s, 7, 12% |
| Spring II | Sunflower | 1 | r4: 305 s, 24, 27% | r5: 85 s, 6, 29% |
| Spring II | Green Alien | 1 | r6: 354 s, 21, 34% | r6: 122 s, 10, 30% |
| Spring II | Red Panda | 3 | r2: 304 s, 15, 40% | r3: 81 s, 5, 27% |
| Spring II | Sunflower | 3 | r3: 281 s, 15, 32% | r4: 80 s, 5, 23% |
| Spring II | Green Alien | 3 | r4: 365 s, 22, 22% | r5: 106 s, 6, 34% |

Reading notes:

- Without Prestige, no boss became a wall. The worst gate is Grim Reaper at +3 (was +4). Only Elephant and Squirrel moved later, by 1–2 rungs, and both were previously won at or before farming power.
- The narrowest wins are thin on purpose: Squirrel (2–4% lowest HP at its first win) and Teal Dinosaur (6–7%). One rung later the margin is 17–40%.
- Spring I Bee with 3 Prestiges at r1 now takes 140 s and 10 potions (was 106 s and 5). That rung is below its farming power, and at farming power it takes 100 s and 6 potions.

## 6. Alternatives considered

| Option | Measured / reasoned outcome | Decision |
|---|---|---|
| Stats only (Change 78's Prestige-calibrated +20–60% hits) | Change 78 §7: no-Prestige players win 2 of 10 bosses, while 3 Prestiges still win all 10 with 65–98% HP. | Rejected: stats alone cannot close the gap that boss-only cards open. |
| Card trim only | Leaves the Summer II / Autumn I bosses below their maps per second without Prestige, the three non-damaging kits, and the Spring II attrition. | Rejected on its own; part of the chosen set. |
| Prestige-scaled boss threat (boss damage grows with completed Prestiges) | Hidden difficulty that punishes progression and is hard to explain in the UI. It needs a new rule, save field or display, and its own tuning. | Rejected as not the simplest robust fix. |
| Spread boss cards to all enemies | Changes card identity and the Hunter / Trophy paths, and needs new copy everywhere. | Rejected. |
| Blanket damage multiplier | Spring I bosses are already about 1.0× a 6-spot and Grim Reaper was already a +4 wall without Prestige. A blanket raise would overshoot both. | Rejected. |
| **Chosen:** per-boss HP and hit tuning (HP down where fights were sponges), a damaging skill on the three bosses without one, and a moderate trim of only the boss-only Prestige effects | Gates land at 0 to +2 rungs for every profile (Grim Reaper +3 without Prestige). Danger rose in every Summer II–Spring II fight, and Spring II and final-boss fights are about 3× shorter. | Implemented. |

Grim Reaper variants tried: hit ×0.92 / HP ×0.90, hit ×0.88 / HP ×0.90, hit ×0.92 / HP ×0.80, and HP ×0.75 alone (`cand3*_s6.csv`). None moved the no-Prestige gate below +3. A no-Prestige build at r3–r5 dies within 29–55 s to Strike, Frost and two helpers, before the boss's HP matters. This is a burst cliff, not a stat problem (see §7).

## 7. Risks and what to watch on Android

- **Constructed ladder, not a player.** It uses one weapon line, the previous boss's outfit, stored outfits, auto potions, Guard Tonic, Recovery Salve and auto skills. A hand player who steps out of telegraphs takes less skill damage. The pressure figures are an upper bound for skill-heavy bosses (Elephant and Squirrel Strike, Sunflower Fire).
- **Prestige profiles:** 0, 1 and 3 Prestiges with boss-leaning picks. Two or four Prestiges, or non-boss picks, were not run separately. The natural playthroughs were not re-run (player profiles are out of scope for this batch).
- **Thin first wins:** Squirrel and Teal Dinosaur first wins end at 2–7% HP. Watch whether these feel fair or sudden. Elephant's and Squirrel's new Strike is 2.8× their hit (124 and 206), telegraphed for 0.6 s and dodgeable.
- **Grim Reaper without Prestige** stays a +3 gate through burst (Strike, Frost and two helpers). If players without Prestige stall there, the next lever is its helpers (`resources/game/enemy_abilities.tres`: 2 helpers at 40% damage), not its HP.
- **Green Alien without Prestige** is now winnable at the top level with 7% HP left, a deliberately narrow win. With Prestige it needs two rungs past Spring II farming power.
- **Owned cards lose value:** players who own Giant Slayer, Trophy Power or Boss Guard see the new numbers at once. Release 40 is on Internal Testing only, so this is ordinary tuning, but testers may notice.
- **On device:** check Summer II fights (Elephant Strike + Focus, Teal Fire), Autumn I (Squirrel Strike + Heal), Spring II length (target 1–2 minutes) and Green Alien with 1–3 Prestiges. Record deaths, potions used and fight time per boss.

## 8. Reproduce

From the repository root with Godot 4.7.2 (each full ladder takes about 7 minutes as two processes):

```text
mkdir -p tests/tmp/c78 tests/tmp/c79
cp docs/Change_78_Boss_Balance_Evidence/ladder_c78.json tests/tmp/c78/
cp docs/Change_79_Boss_Balance_Evidence/*.py docs/Change_79_Boss_Balance_Evidence/*.json docs/Change_79_Boss_Balance_Evidence/run.sh tests/tmp/c79/
cp docs/Change_79_Boss_Balance_Evidence/boss_audit.gd.txt tests/tmp/c79/boss_audit.gd
sed 's#res://tests/player_feedback_audit.gd#res://tests/tmp/c79/boss_audit.gd#' tests/player_feedback_audit.tscn > tests/tmp/c79/boss_audit.tscn
python tests/tmp/c79/gen_ladder.py tests/tmp/c79/base_ladder.json      # P0/P1/P3 x 10 rungs x stages 4-8 (+ Green Alien)
sh tests/tmp/c79/run.sh tests/tmp/c79/base_ladder.json after            # current catalog -> tests/tmp/c79/after_a.csv, after_b.csv
python tests/tmp/c79/report_tables.py docs/Change_79_Boss_Balance_Evidence/base_a.csv,docs/Change_79_Boss_Balance_Evidence/base_b.csv tests/tmp/c79/after_a.csv,tests/tmp/c79/after_b.csv
```

The "before" CSVs were produced the same way on commit `1cde5b5`. A candidate set is `python tests/tmp/c79/gen_cand.py tests/tmp/c79/cand3.json out.json` (bosses only, with in-memory patches and card values) followed by `run.sh`. Catalog: `python tools/change79_catalog.py`, then `python tools/tune_campaign.py`. Both have `--check`.
