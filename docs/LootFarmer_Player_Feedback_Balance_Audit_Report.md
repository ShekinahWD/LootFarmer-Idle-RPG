# LootFarmer — Player-Feedback Balance & Discoverability Audit (Report)

**Date:** 2026-11-06 · **Mode:** investigation only (no gameplay, balance, UI, localization, test or save change) · **Brief:** `docs/LootFarmer_Player_Feedback_Balance_Audit_Brief.md`

**Source of truth audited**

| Item | Value |
|---|---|
| Commit | `0edbae2` (Change 47), branch `main` |
| Game version | `project.godot` `config/version="27"` |
| Catalog / save | `data/game/catalog.json` (unchanged since 2026-10-28, no working-tree diff); save schema 8, file version 3 |
| Engine | Godot 4.7.2 stable, headless |
| Uncommitted files present (not mine) | `project.godot` (setting order + icon uid), `export_presets.cfg` (Windows preset), `marketing/match_cut_v4/add_speed_blur.py`, `docs/Reusable_Game_Development_Playbook.md` (developer edit, 2026-11-05, +613/−185 lines, CRLF), untracked localization drafts in `localization/`. **None touches combat, economy or catalog data → no effect on these conclusions.** The Playbook was read from the working copy. |
| Doc conflicts found (runtime treated as authority) | (1) GDD *Prestige* (`LootFarmer_GDD.md:199`) says Prestige resets **player level**; runtime keeps `player_level`/`xp` (`campaign.gd:1266`, intentional since Change 20). (2) *Content and Balance* says supply mastery is kept by Prestige; runtime clears it (Change 20). (3) *Content and Balance* lists Potion price 10 coins; catalog `price` is **100**. (4) Its Change 13 cooldown list (Lightning 8 s …) is historical; catalog cooldowns are 20 s (Change 17 table). |

Evidence class (Playbook 112.2): every fight below is a **constructed fixture** — legal, every item obtainable and actually equipped, Prestige cards granted by the game's real Prestige transaction, but level, merge levels, lifetime kills, supply mastery/stock and currency are **seeded stand-ins for play time**. Nothing here is a natural playthrough. Economy timelines are **projections** from measured kill rates.

---

## 1. Executive verdict

**The complaint is reproduced from Summer I onward, and it is structural, not a tuning accident of one map.** Winter I and Winter II behave as intended (the boss is the hardest thing on the map). From Summer I (the player's third boss) on, at the same build:

- a normal spot deals **2.0–3.0×** the boss's damage per second with its 3 actors, and **4.6–5.8×** with the 6 actors that the Gem upgrade *Spawn Amount* produces (catalog-exact, every stage);
- in real fights, a level-35 boss-level build with no Prestige beats the Gray Cat with **51 % HP left** but dies in **14 s** to a 6-actor Yellow Cap skill spot, and **sustained farming of that spot costs 22 deaths per 10 minutes**;
- one Prestige moves the Gray Cat result from 20 % → 63 % HP left (three Prestiges: 92 %) while the hardest normal spot moves only 46 % → 72 %.

**Main causal chain**

1. **Enemy design concentrates burst in normal groups.** Boss damage is only ×1.55 of a normal at a slower 2.0 s swing (≈ 1.16 normals per second) but ×14.5 HP; spots attack together (proximity aggro from Winter II, group assist from Summer I), skill variants are ×1.35 and cast **without the boss telegraph**, and Spawn Amount doubles the attackers. Bosses are long, low-burst fights; spots are short, high-burst fights.
2. **All sustain is time-based** (potion 12 s, Heal 20 s, lifesteal, Recovery): it wins long boss fights and cannot answer a 10-second burst. Boss readiness is a potion cliff (no potions → loss at the same build), so an attentive player beats bosses far earlier than they can farm.
3. **Prestige amplifies boss fights only.** Boss-only cards reach +45 % damage (+65 % with combos) and −20 % damage taken; normals get one +20 % damage card and no defensive card. Prestige also **keeps player level**, so each cycle re-enters early maps over-levelled, with boss achievements (1/3/10 kills) accruing far faster than normal-type achievements (25/100/250).
4. **Boss gear runs ahead of normal drops**: every boss weapon is the tier normals reach 1–2 maps later, boss outfits have 3× base stats, and the Winter II, Summer II and Autumn II normals never drop a weapon better than the one the previous boss gave. Its combat effect is smaller than items 1–3 (measured below), but it removes the reward for farming.
5. **Switching farming targets resets income**: every coin/XP/loot upgrade and kill achievement is per enemy type, so a switch costs **78–86 % of coin income** and 20–36 % of XP income at once, inside the slowest XP stretch of the game (110–150 kills per level in Summer I–II).

Net incentive: rush bosses with potions, Prestige, and carry boss gear; farm only the weakest spots. That is exactly the reported experience.

---

## 2. Reproduction / evidence matrix

| # | Claim | Scenario / build | Measured result | Severity | Confidence | Source |
|---|---|---|---|---|---|---|
| C1 | Normal groups harder than bosses | Summer I L35, Stone Axe ^100, Snowman ^80, Heal ^15, 20 potions, P0 | Gray Cat 3/3, 51 % HP left, 41 s, 9.2 dmg/s in · Yellow Cap skill ×6: **0/3, dead in 13.7 s, 38.8 dmg/s in** | **High** | High (3 seeds, deterministic within ±1 s) | `baseline_trials_main.csv` S3_L35_snow; `simulation.gd:99, 526-527`; catalog `progression.balance` |
| C2 | Same under sustained play | Summer I 6-actor spots, Focus, real 9 s respawns, 5 min × 2 seeds | L28: **18–24 deaths / 10 min**; L35: **10–22 deaths / 10 min**. 3-actor spot (both-loadout) at L30: 2 deaths, at L22 arrival: 7 deaths per 10 min | High | High | `baseline_trials_supplementary.csv` FARM_S3v*, `baseline_trials_main.csv` FARM_S3 / FARM_SW_S3 |
| C3 | Boss beatable before its own map's normals are farmable | Gray Cat ladder (attentive, P0) | Boss reliable from **L22**; at L22 the same build loses every 6-actor Yellow Cap spot and dies 7× per 10 min farming its 3-actor spot | High | High | `baseline_trials_main.csv` LAD_S3_snow, S3_L22_arrive |
| C4 | Prestige favours bosses | L30 neighbour build | Boss: 20 % → **63 %** (P1) → **92 %** (P3) HP left, 51 → 36 → 28 s. Skill spot ×3: 46 → 72 → 74 % | High | High | `baseline_trials_main.csv` NB_S3_*; `campaign.gd:443-448`; catalog `campaign.cards` |
| C5 | Prestige keeps level → over-levelled re-runs | Runtime keep list | `player_level`, `xp`, `group_kills`, `owned_cards`, `gems`, gem upgrades kept | Medium | Certain (code) | `campaign.gd:1266-1272` |
| C6 | Boss shortcut skips a map | Summer II arrival L38, previous boss gear, Heal by hand, potions, **P1** | Elephant (L60) 3/3, 50 % left; Teal Dinosaur (L65) 3/3, 50 % left. P0 same build: 0/3 | Medium | High | `baseline_trials_supplementary.csv` S4_L38_arrive_manual_P1 |
| C7 | Early boss gear stays best | Catalog ladder | Snowman Stone Axe (tier 2) = Summer I/II normal tier; Winter II normals drop tier 1 only; Snowman outfit ^0 (24 HP) = Winter II outfit **^100**; no Winter II outfit can reach Snowman ^100 even at ^500 | Medium (reward feel) | Certain | `baseline_gear_table.txt`; `onboarding.gd:163-169` |
| C8 | …but gear is not what wins the fights | L30 neighbours | Snowman ^0 instead of ^60: boss still 3/3 (22 % vs 20 % left); Chef t1 ^20 instead: 3/3 (16 %). Stone Axe ^0 instead of ^60: **0/3** (weapon damage matters, outfit HP barely) | Informational | High | `baseline_trials_main.csv` NB_S3_* |
| C9 | Switching targets is punishing | Measured kill rates + catalog prices | −78 % to −86 % coins/min, −20 % to −36 % XP/min at once; old coin rate regained after 24–72 min of reinvestment; cumulative coins catch up after 107–123 min (next map) or > 240 min (same map) | **High** (feel) | Medium (projected) | `baseline_economy_projection.txt` |
| C10 | Boss readiness is a potion cliff | L30 neighbour without potions; ladders by policy | No potions → loss with boss at 1 % HP. Casual (no potions, no casts) needs Snowman L13 vs L10, Robot L16 vs L8, **Gray Cat L42 vs L22** | Medium | High | NB_S3_nopotion, LAD_*_casual |
| C11 | Late maps: normal spots worse still | Spring I L195 P1; Spring II L240 P1 | Spring I bosses 3/3 (72 %/49 % left); Elf Ears ×6 **dead in 7–9 s** (327–421 dmg/s). Spring II: Red Panda 3/3, but **4 of 22 spots lost**, including a 3-actor skill spot | High | High | `baseline_trials_main.csv` S7_/S8_ ready |
| C12 | Map markers undiscoverable | Code trace | No Guided step, Basic card or Help card mentions markers; rank-0 map draws none; card says "Map detail · 0 → 1"; Map Details resets every Prestige | Medium (UX) | Certain | §7 |
| C13 | Offline gear undiscoverable | Code trace | Welcome-back panel never mentions gear; unlock lives in the 5th Upgrades tab as "Off → On" without saying grants are copies of owned gear | Medium (UX) | Certain | §7 |
| C14 | Inventory too generous | — | Not measured; player marked it as preference → **no change proposed** | Low | — | — |

---

## 3. Eight-stage difficulty matrix

Each spot fight: one variant spot of N actors attacking together, no respawn during the fight, 3 seeds, the real simulation at 0.1 s. "Attentive" = potion below 40 % HP and every skill cast when ready (stages 4–8 *ready* builds use purchased auto-cast and auto-supplies). Columns: wins/trials, median HP left, median incoming damage per second. Full rows: `docs/Player_Feedback_Audit_Evidence/baseline_summary_main.txt`.

### 3.1 Structural ratios (catalog, exact)

| Map | Top normal (L) | 3-actor skill/weapon spot dps | 6-actor weapon spot dps | Boss (L) dps | Spot×3 / boss | Spot×6 / boss | Boss HP / spot×3 HP | Aggro |
|---|---|---|---|---|---|---|---|---|
| Winter I | Chef Hat 5 | 6.9 | 13.9 | Snowman 7: 4.0 | 1.4 (fought one at a time) | 3.5 | 5.9 | passive |
| Winter II | Space Helmet 16 | 13.3 | 24.6 | Cyan Robot 20: 4.5 | 2.9 | 5.4 | 5.9 | individual |
| **Summer I** | Yellow Cap 30 | 23.2 | 43.0 | Gray Cat 35: 7.9 | **2.9** | **5.4** | 5.9 | group |
| Summer II | Straw Hat Swimmer 52 | 35.6 | 71.1 | Elephant 60: 12.3 / Teal 65: 13.2 | 2.2–2.3 | 5.4–5.8 | 5.8–6.4 | group |
| Autumn I | Pumpkin Head 80 | 56.7 | 105.0 | Squirrel 90 / Red Fox 95 | 2.8–3.0 | 5.2–5.6 | 6.0–6.7 | group |
| Autumn II | Top Hat 120 | 91.5 | 183.1 | Black Cat 135 / Grim Reaper 140 | 2.0–2.1 | 4.9–5.2 | 6.7–7.5 | group |
| Spring I | Elf Ears 170 | 198.1 | 366.8 | Bee 190 / Orange Tabby 195 | 2.5–2.6 | 4.6–4.9 | 7.5–8.3 | group |
| Spring II | Sprout 225 | 425.6 | 788.1 | Red Panda 235 / Sunflower 240 | 2.8–3.0 | 5.2–5.6 | 6.0–6.7 | group |

### 3.2 Measured outcomes (spots ×3 / worst ×3 / worst ×6 / bosses)

| Map · build | Level · Prestige · dmg/HP | 3-actor spots won | Worst 3-actor spot | Worst 6-actor spot | Boss(es): result, HP left, time, dmg/s in |
|---|---|---|---|---|---|
| W1 arrival (bare) | L1 P0 · 5/100 | 9/9 | Chef both 63 % | Chef both 30 % | Snowman 0/3 |
| W1 boss-ready, attentive | L9 P0 · 13/168 | 9/9 | 90 % | 82 % | Snowman 3/3, 6 %, 48 s |
| W1 boss-ready, casual | L9 P0 | 9/9 | 90 % | 82 % | Snowman **0/3** |
| W2 arrival (Stone Axe ^0) | L10 P0 · 19/192 | 19/19 | Space Helmet skill 55 % | Space Helmet skill **0/3** | Robot 0/3 |
| W2 farmed normal path | L16 P0 · 26/234 | 19/19 | 72 % | 27 % | Robot 3/3, 29 %, 60 s |
| W2 Snowman carry | L16 P0 · 27/269 | 19/19 | 78 % | 44 % | Robot 3/3, 36 %, 58 s |
| W2 Snowman carry, casual | L16 P0 | 19/19 | 75 % | 21 % | Robot 3/3, **2 %** |
| W2 boss-level + 1 Prestige | L20 P1 · 31/360 | 19/19 | 94 % | 75 % | Robot 3/3, **91 %, 30 s** |
| **S3 arrival, guaranteed gear only** | L22 P0 · 25/252 | 11/12 | Yellow Cap skill **0/3** | **0/3** (dead 4.7 s) | Gray Cat 0/3 |
| **S3 arrival, Snowman ^30** | L22 P0 · 33/299 | 12/12 | Yellow skill 31 % | Yellow weapon **0/3** | Gray Cat 0/3 |
| **S3 farmed, Snowman ^60** | L28 P0 · 43/363 | 12/12 | 44 % | skill **0/3** (8.9 s, 50 dmg/s) | Gray Cat 3/3, 17 %, 52 s, 9.2 |
| S3 farmed, normal outfit | L28 P0 · 43/347 | 12/12 | 42 % | **0/3** | Gray Cat 3/3, 23 % |
| S3 farmed, casual | L28 P0 | 12/12 | 35 % | **0/3** | Gray Cat **0/3** |
| **S3 farmed + 3 Prestiges** (reported pattern) | L28 P3 · 46/464 | 12/12 | 73 % | skill 3/3, **17 %** | Gray Cat 3/3, **89 %, 29 s** |
| **S3 boss-level** | L35 P0 · 54/432 | 12/12 | 67 % | skill **0/3** (13.7 s, 39 dmg/s) | Gray Cat 3/3, **51 %**, 41 s, 9.2 |
| S3 boss-level + 1 / 3 Prestige | L35 P1 / P3 | 12/12 | 76 / 78 % | 17 / 23 % | Gray Cat **79 % / 95 %**, 29 / 22 s |
| S4 arrival, hand play, P0 / **P1** | L38 · 53/480–576 | 20/20 | Snorkeler skill 19 / 44 % | **0/3** / 1/3 | Elephant + Teal 0/3 / **3/3 50 %** |
| S4 boss-level, auto | L60 P0 · 80/701 | 20/20 | 70 % | 54 % | Elephant 87 %, Teal 59 % |
| S5 arrival, hand P0 / P1 | L65 · 79/530–636 | 10–11/11 | Pumpkin skill 0/3 / 19 % | **0/3** | Squirrel 0/3 / 39 %; Red Fox 0/3 |
| S5 boss-level, auto P0 | L95 · 114/919 | 11/11 | 60 % | skill **0/3** (130 dmg/s) | Squirrel 57 %, Red Fox 59 % |
| S5 boss-level, auto P1 | L95 P1 · 114/1102 | 11/11 | 86 % | 44 % | 94 % / 100 % |
| S6 arrival, hand P0 / P1 | L95 · 145/820–984 | 13–14/14 | TV Head skill 0/3 / 24 % | **0/3** | Black Cat, Reaper 0/3 |
| S6 boss-level, auto P0 / P1 | L140 · 247/1201–1441 | 14/14 | 64 / 79 % | 29 / 63 % | Black Cat 56 / 98 %; Reaper 15 / 71 % |
| S7 arrival, auto P1 | L140 P1 · 247/1366 | 9/11 | Elf weapon **0/3** | **0/3** | Bee, Tabby 0/3 |
| S7 boss-level, auto P0 | L195 · 261/1959 | 10/11 | Elf skill **0/3** | **0/3** | Bee, Tabby 0/3 |
| S7 boss-level, auto P1 | L195 P1 · 261/2351 | 11/11 | Elf weapon 55 % | **0/3** (dead 7–9 s, 327–421 dmg/s) | Bee 72 %, 205 s; Tabby 49 %, 174 s |
| S8 arrival, auto P1 | L195 P1 · 318/3118 | 11/22 | **0/3** | **0/3** | Red Panda, Sunflower 0/3 |
| S8 boss-level, auto P1 | L240 P1 · 632/2447 | 18/22 | Pink Flower skill **0/3** | **0/3** (4 s) | Red Panda 3/3 54 %, 235 s; Sunflower 0/3 |

**Reading.** Winter I–II: bosses are the gate, as intended. Summer I is the first map where the boss is beaten (L22, attentive) **before** its normals can be farmed safely; with any Prestige the inversion is large. Summer II's bosses fall to a level-38 arrival with one Prestige (a skipped map). Autumn I–II repeat the Summer pattern. Spring I–II normals are lethal at boss-ready builds that beat the bosses. (Limitation: the Spring II boss-level build wears a Diamond **Sword**, so it has less HP than the arrival build; Spring II needs its own build ladder before tuning.)

### 3.3 First three bosses — readiness ladders (3 seeds per rung)

| Boss | Build family | Reliable win from | One-variable weaker neighbour | Hardest spot, reliable from (same family) |
|---|---|---|---|---|
| Snowman (L7) | **MIN** L10, Wood Axe ^10, Chef ^10, 5 potions by hand | **L10** (L9: 0/3) | casual, no potions: needs **L13** | Chef ×3 / ×6: L3 (passive, fought one by one) → boss harder ✔ intended |
| Snowman | **REC** L13 same gear, no potions needed | L13 | — | — |
| Cyan Robot (L20) | **MIN** L8, Stone Axe ^30, Snowman ^30, Heal ^0, 10 potions | **L8** | normal path (Stone Axe ^0, Santa ^60): L10; casual: **L16** | all ×3 and weapon ×6: L8; skill ×6 lost at L10 arrival |
| Cyan Robot | **REC** L16 casual-proof (2 % left casual, 36 % attentive) | L16 | +1 Prestige at L20: 91 % left, 30 s | — |
| Gray Cat (L35) | **MIN** L22, Stone Axe ^60, Snowman ^60, Heal ^10, 15 potions | **L22** (L20: 0/3) | normal outfit (Yellow ^40): L26 (2/3 at L24); no potions at L30: **0/3**; Stone Axe ^0 at L30: 0/3; casual: **L42** | 3-actor spots: ≤ L20 in a single engagement; weapon ×6: L24; **skill ×6: lost at L35 P0**, won only with ≥1 Prestige; sustained farming: deaths at every level tested |
| Gray Cat | **REC** L35 (51 % left) or L28 + 1 Prestige (79 %+) | — | Snowman ^0 / Chef ^20 / no Heal at L30: still 3/3 (22 / 16 / 6 % left) | — |

Cliffs: potions (Gray Cat, Snowman, Robot flip from win to loss without them); weapon merges (Stone Axe ^0 → loss); Prestige (Gray Cat skill ×6 spot 0/3 → 3/3).

---

## 4. Equipment effectiveness

Runtime formulas (`simulation.gd` `normal()`, `merge_levels()`, `stat_sources()`): equipped item at full value; stored weapons 30 %, stored outfits 15 %; ^m costs m+1 copies; **evolution needs ^100 plus 101 copies on hand (201 copies per tier step)**; outfits grow by copies to ^500 and never evolve. Full table: `baseline_gear_table.txt`.

### 4.1 Tier timeline: boss drops versus normal drops

| Map | Normal weapon tier | Boss weapon tier (that map's boss) | Normal outfit base HP | Boss outfit base HP |
|---|---|---|---|---|
| Winter I | 1 (Wood) | **2 (Stone Axe; guaranteed on first kill)** | 8 | 24 |
| Winter II | **1** | 2 (Stone Sword) | 8 | 24 |
| Summer I | 2 | **3 (Iron Axe)** | 20.4 | 61.2 |
| Summer II | **2** | 3 | 20.4 | 61.2 |
| Autumn I | 3 | **4 (Gold)** | 52.0 | 156.1 |
| Autumn II | **3** | 4 | 52.0 | 156.1 |
| Spring I | 4 | **5 (Diamond Axe)** | 132.7 | 398.0 |
| Spring II | 5 | 6 (Emerald) | 338.3 | 1014.8 |

On **Winter II, Summer II and Autumn II no normal weapon drop can ever be an upgrade**: the best normal weapon is one tier below the weapon the previous boss already gave, and fully evolving it (201 copies ≈ 4,000 kills of weapon-carrying actors at the 5 % base roll) produces a ^0 copy of the item the player already owns.

### 4.2 Snowman gear versus Winter II and Summer I alternatives

| Item | ^0 | ^30 | ^60 | ^100 | Equal to |
|---|---|---|---|---|---|
| Stone Axe (Snowman; tier 2) | 8.2 dmg / 30.6 HP | 13.1 / 49.0 | 18.0 / 67.3 | 24.5 / 91.8 | Wood Axe ^100 + 100 spare evolves into **Stone Axe ^0** |
| Wood Axe (Winter II normals) | 3.2 / 12 | — | — | 9.6 / 36 | Stone Axe ^0 at ^78 |
| Stone Sword (Robot; Summer I Straw Hat) | 10.2 dmg | 16.3 | 22.4 | 30.6 | +25 % dmg, no HP vs Stone Axe |
| Snowman outfit (tier 1) | 24 HP | 38.4 | 52.8 | 72.0 | Santa Hat **^100** / ^280 / ^460 / never |
| Yellow Cap outfit (Summer I, tier 2) | 20.4 | 32.6 | 44.9 | 61.2 | matches Snowman ^0 at ^9, ^100 at **^153** |

Share of total power at boss level (gear vs level): Winter II L20 — weapon+outfit ≈ 36 % of damage, 26 % of HP; Summer I L35 — 53 % damage, 36 % HP; Spring II L240 — 77–80 % damage. **Early on, level dominates**, which is why the outfit choice barely moves outcomes (C8) while the weapon's merge level and Prestige cards do.

### 4.3 Verdict on the gear complaint

- **True** (confirmed): Snowman Stone Axe is the best weapon available from normal drops through Summer II; the Snowman outfit is never matched by any Winter outfit and beats Summer I/II normal outfits at equal merge until about ^150; boss outfits are 3× base by design, so every boss outfit outlives the next map's normal outfits. Boss copies arrive faster: a boss respawns every 60 s and rolls 30 % per item (≈ 15–18 copies/h each when killed in ~10–20 s, projected), versus 5 % per item for normals (≈ 0.7–1.3 copies/min of the matching id at 14–26 kills/min measured).
- **Not true / overstated** for survival: at equal merge level the Snowman outfit and a Summer I normal outfit produce the same fight outcomes (S3_L35 normal vs snow: 49 % vs 51 % boss HP left, identical spot results). It is untrue on odd maps (Summer I, Autumn I, Spring I), whose normals drop copies of the boss-tier weapon (Stone Axe copies from Sunglasses/Yellow Cap), so merging there is rewarding.
- Intentional vs unintentional: the +1 tier boss weapon is a documented Change 8 decision and the first-kill Stone Axe a Change 27 decision; the **even-map dead zone and the 3× boss outfit lasting two maps are side effects**, not documented intent.

---

## 5. Economy: switching farming targets

Inputs measured: kills/min and XP/min per type (`baseline_trials_main.csv` FARM_*, Focus, 10 simulated minutes, real respawns). Prices and rewards from catalog (`coins × (1 + 0.5·Coin Amount)`, `XP × (1 + 0.1·XP level)`, `price = base × growth^n × 1.55^(map−1)`). The reinvesting policy puts every coin into the farmed type's Coin Amount, then XP. **Timelines are projections.**

### 5.1 Measured farm rates (attentive build, no type upgrades)

| Map · level | Types (kills/min · XP/min · deaths per 10 min) |
|---|---|
| Winter I L9 | Blue Cap 25.9 · 78 · 2 — Red Scarf 22.6 · 90 · 3 — Chef 16.6 · 66 · 4 |
| Winter II L16 | first four 21.0 · 84–105 · 0 — Santa 19.5 · 98 · 0 — Space Helmet 16.8 · 101 · **2** |
| Winter II L10 (arrival) | 9.4–17.1 · 56–80 · **4–9** |
| Summer I L30 | Straw 15.5 · 109 · 0 — Sunglasses 15.0 · 120 · 1 — Yellow 14.4 · 130 · **2** |
| Summer I L22 (arrival) | 10.3–14.6 · 93–102 · **2–7** |
| Summer II L52 | 13.2–13.5 · 149–238 · 0 |

Kill rates fall from 26 to 13 per minute across the first four maps while base coins rise 3.4× and XP per level rises ~7×, so **time per level rises from ~1 min (Winter I) to ~10 min (Summer I–II)**; kills per level are 50–85 (Winter II), 110–130 (Summer I), 140–150 (Summer II), 43–120 (Autumn), 12–26 (Spring I), 1–5 (Spring II). The mid game is the slowest stretch.

### 5.2 Policies at identical progression points (PROJECTED)

| Scenario | Stay (invested type) | Switch (new type, no upgrades) | Immediate change | New type regains old coin rate | Cumulative coins catch up |
|---|---|---|---|---|---|
| B1 Winter II, Santa (^10/^5) → Space Helmet | 176 c/min, 146 XP/min | 25 c/min, 101 XP/min | **−86 % coins, −31 % XP** | 72 min | > 240 min |
| B2 Winter II Space Helmet → Summer I Straw Hat (arrival) | 151 / 151 | 33 / 102 | −78 %, −32 % | 25 min | 107 min |
| B3 Summer I Straw (^10/^5) → Yellow Cap | 209 / 163 | 32 / 130 | −85 %, −20 % | 72 min | > 240 min |
| B4 Summer I Yellow (^12/^8) → Summer II Cowboy | 227 / 233 | 46 / 149 | −80 %, −36 % | 28 min | 123 min |
| C Alternate 3 Summer I types vs one (same kills) | 202 c/min at 60 min | 152 c/min | −25 % at 60 min, −29 % at 180 min | — | never within 3 h |

Kills per next Coin Amount level stay ~30 up to ^3, then 46 (^5), 145 (^10), 549 (^15), 1,708 (^19) — identical in "base kills" on every map. There is **no reset-like price wall**; the stall is entirely the per-type reset. Missions pay in "normal kills of the highest map" and offline pays 120 coins/h base, so neither offsets a switch materially.

### 5.3 Candidate remedies (none applied)

| Option | Effect (B3, PROJECTED) | Benefits | Damage to strategy / risks |
|---|---|---|---|
| **Current** | 32 c/min at switch; parity 72 min | Per-type specialisation is a real choice | Punishes trying new spots; drives "farm one weak spot" |
| **R6 Stage floor (recommended)**: effective level of Coin Amount, XP, Loot Chance, Supply/Skill Drop on a normal type = max(own, ⌊0.5 × best level of that upgrade on any normal type of the same map⌋) | 113 c/min at switch (−46 %), parity 60 min | Keeps per-type purchases meaningful (the top half still has to be bought); no save change (derived at run time); purchases retain exact value | Slightly faster coin sinks; per-type UI must show "floor from map" in the benefit line |
| R6b floor 75 % | 146 c/min (−30 %), parity 51 min | Smoother | Specialisation nearly irrelevant |
| **Player proposal: stage-wide normal upgrades** (bosses separate), priced ×2.5 | ~194 c/min, no switch cost inside a map | Simplest to understand; directly answers the complaint | Removes the per-type choice; Summer II (6 types) becomes 2.4× cheaper than buying each type; needs a save migration (`id:group` → `id:stage`), refund policy, UI rework of Overview/enemy panels and the Farming Guide; still resets at every new map |
| Cheaper first levels (e.g. first 5 levels ×0.5) | Parity ~−10 min | Trivial | Does not address the 6–11× gap after ^10 |
| Carry kill achievements across types | +5 % damage per milestone kept | Helps feel | Small; mixes identity rules |

---

## 6. Prestige sensitivity

| Effect of Prestige (runtime) | Bosses | Normals |
|---|---|---|
| Damage cards | Hunter I +25 %, Trophy II +20 %, Boss Specialist combo +10 %, Challenge set +10 % (max **+65 %**) | Expedition I +20 % only |
| Defence cards | Hunter II **−20 % damage taken** from bosses | none (Arsenal III −10 % applies to both) |
| Achievements (kept) | +5 % damage at 1, 3, 10, 25 … kills | +5 % at 25, 100, 250, 500 … kills |
| Level / XP | kept | kept |
| Reset | coins, items, coin upgrades, map access, Map Details, supply mastery | same |

Measured (L30 Gray Cat neighbour, same gear): P0 20 % HP left / 51 s → P1 63 % / 36 s → P3 92 % / 28 s; hardest 3-actor spot 46 → 72 → 74 %. Summer I L35: P0 cannot clear the 6-actor skill spot, P1/P3 can (17–23 % left). Summer II: P1 lets a level-38 arrival beat both L60–65 bosses (P0: 0/3). The first boss alone makes three opportunities ready (Hunter, Challenge, Trophy — all boss paths), so the cheapest cards to obtain are the boss cards.

**Dominant strategy confirmed** for the first three maps: kill the Snowman, Prestige for boss cards, return over-levelled with a re-farmed Stone Axe/Snowman outfit, take bosses with potions, farm only the weakest spots. Time invested for P1 was not measured (the pacing bot is stale, Change 36 note); the opportunities used are reachable within Winter I–Summer I by their definitions (`campaign.gd:1020-1092`).

---

## 7. Discoverability findings

### 7.1 What the code actually teaches

| Surface | What it shows today | Source |
|---|---|---|
| Guided flow (29 steps) | move → target → kill → collect → equip → merge → missions → Player Upgrade → camp → boss find/preparation/farm → inventory → potion buy/use → Prestige intro → boss win → World intro → travel → milestones → Winter II → The Road Ahead. **No step covers Map Details, markers, Reveal Drops, offline earnings or offline gear.** | `guided_progress.gd:8` |
| Basic deck = Help (6 cards) | Overview, Target, Gear, "Upgrades and Missions", "Explore, camps and stages" (fog, minimap, camps), Prestige. **No card mentions markers, Map Details or offline.** | `tutorial_guide.gd:22`, `en.po:5093-5115` |
| World panel at Map Details rank 0 | **No enemy or boss markers at all**; caption `MAP_LEGEND` talks only about fog and camps. The purchase is in **"Map upgrades", the last section**, below camps, map, Farming guide, Map Mastery and Travel. | `game_ui.gd:2128-2158`, `map_view.gd:82-86` |
| Map Details card | Title "Map detail", benefit **"0 → 1"** (generic numeric transition). | `game_ui.gd:1879, 1941-1949` |
| Main objective 6 | "Upgrade map detail" — no purpose, no location; shown only while among the first three unclaimed objectives. | `campaign.gd:916-922`, `en.po:1177` |
| Prestige | `map_detail` is a coin upgrade with `keep: false`: **every Prestige removes all markers** over ground the player still has explored. | catalog, `campaign.gd:1270` |
| Offline welcome panel | "Welcome back! · Away X · Y rewarded hours", coins, gems, items received, Claim. With no gear unlock: no items, no explanation. | `game_ui.gd:2616-2634` |
| Offline gear unlocks | Upgrades → **5th tab "Offline"**: "Unlock offline weapon drops / outfit drops / consumables" (50 / 50 / 38 Gems), benefit **"Off → On"**. Nothing says the grants are **copies of gear you already own** (`offline_snapshot`: owned ids at departure, uniform pick, 1/h base). | `game_ui.gd:1816-1832, 1939`, `campaign.gd:1315-1344` |

**Why a full-training player missed both:** neither is in any tutorial mode; both appear only as a bare title with a numeric or On/Off benefit at the bottom of a panel or in its last tab; the moments they matter (an empty map over explored ground; an offline claim without gear) show nothing; Prestige removes the markers again each run. Classification: **UX gap, confirmed by code trace**; retention impact is the player's report, not measured.

### 7.2 Proposed contextual messages (non-blocking; nothing implemented)

All reuse the existing one-time notice pattern (`focus_unlocked`: a `tutorial.seen` latch, kept by Prestige, cleared by Hard Reset) and Playbook 18.6–18.8: Basic/None or after Guided, never over a modal or Prestige choice, never pausing, never naming an undiscovered enemy, spot or item, at most 3 shows, retired on the demonstrated action.

| # | Trigger | Placement and English wording (proposed keys) | Route | Hide / retire |
|---|---|---|---|---|
| M1 | World panel open on map *s*; `map_detail:s` = 0; ≥1 discovered spot on *s* | Replaces `MAP_LEGEND` under the map: **"Enemies and bosses you have found can be marked here. Buy Map Detail in Map upgrades below."** (`MAP_MARKERS_HINT`) + small button **"Map upgrades"** (`MAP_UPGRADES_JUMP`) | Scrolls the same panel to `SECTION_MAP_UPGRADES` | Hidden while `map_detail:s` ≥ 1; retired after the first purchase ever or 3 shows. After a Prestige, short form once per run: **"Map Detail resets with Prestige. Buy it again to restore your markers."** (`MAP_DETAIL_RESET_HINT`) |
| M2 | Map Detail card | Benefit by next rank: **"Next: markers for enemies and bosses you have found"** / **"Next: enemy names; tap a marker to inspect it"** / **"Next: loadout icons (weapon, outfit, skill)"** (`MAP_DETAIL_NEXT_1..3`, from GDD ranks, `LootFarmer_GDD.md:159, 238`) | — | Permanent copy |
| M3 | Main objective 6 | **"Upgrade map detail (World → Map upgrades)"** (edit `MAIN_6`) | Follow-mission can point at World | Permanent copy |
| O1 | Offline reward panel open; `offline_weapon` or `offline_outfit` = 0; owns ≥1 weapon/outfit; Gems ≥ cheaper missing unlock (18.7: never a hint you cannot afford) | Above Claim: **"While you are away you can also receive copies of the weapons and outfits you own. Unlock it in Upgrades → Offline."** (`OFFLINE_GEAR_HINT`) + **"Offline upgrades"** (`OFFLINE_UPGRADES_JUMP`): claims, then opens Upgrades on the Offline tab | `player_tab = 4` | Hidden once both owned; retired after 3 shows or first unlock |
| O2 | Offline tab cards | **"Off → On · copies of gear you own, about 1 per hour each"** (`OFFLINE_GEAR_BENEFIT`, rate from `offline_snapshot`) | — | Permanent copy |

Localization cost (132.4–132.5): all 20 languages ship, so the ~9 new keys need 19 translations via the ChatGPT handoff (or must stay hidden until then); editing `MAIN_6` changes one existing key's meaning in 19 catalogs. Each hint needs a probe (shows, does not pause, routes, retires).

---

## 8. Ranked remediation options

Measured with the same harness, builds and seeds as the baseline (in-memory what-ifs, labelled; production untouched). Cells: wins/3, median HP left.

| What-if | S3 L28 Yellow skill ×6 | S3 L35 Yellow skill ×6 | S5 L95 Pumpkin skill ×6 | S6 L140 Top Hat weapon ×6 | S7 L195 P1 Elf weapon ×6 / skill ×6 | S8 L240 P1 Sprout skill ×3 | Bosses (all) |
|---|---|---|---|---|---|---|---|
| Baseline | 0/3 | 0/3 | 0/3 | 3/3 29 % | 0/3 / 0/3 | 0/3 | — |
| **cap3**: ≤ 3 normal attackers on the player at once | 0/3 (30.6 dmg/s, was 49.9) | **3/3 9 %** | **3/3 12 %** | 3/3 40 % | **3/3 30 %** / 0/3 | 0/3 | **unchanged** |
| desync: first normal skill cast 2–8 s after aggro | 0/3 | 0/3 | 0/3 | 29 % | 0/3 / 0/3 | 0/3 | unchanged |
| **v3 ×1.15** (skill variant, was ×1.35) | 0/3 | **3/3 18 %** | 0/3 | 29 % | 0/3 / 0/3 | 0/3 | unchanged |
| cap3 + desync + v3 ×1.15 | 0/3 | 3/3 20 % | **3/3 35 %** | 40 % | 3/3 30 % / 0/3 | 0/3 | unchanged |
| **Spring normals damage ×0.60** + cap3 | — | — | — | — | **3/3 80 % / 3/3 68 %** | **3/3 50 %** (×6 still 0/3) | unchanged |
| Spring normals ×0.75 | — | — | — | — | 1/3 / 0/3 | 0/3 | unchanged |

Three-actor spots are unaffected by cap3 (only extras wait). All what-ifs leave every boss result identical (bosses are not normals), so **the Change 36 final-boss verdict is unaffected** by R1–R3.

### Ranked proposals (exact values only where measured)

1. **R1 — Attacker cap for normal enemies (High).** At most **3** normal enemies attack the player at once; the others hold at reach until a slot frees (rule in `simulation.step`, not data). Turns Spawn Amount back into a farming-speed upgrade instead of a 2× difficulty multiplier. Measured: Summer I L35 6-actor skill spot 0/3 → 3/3; Autumn I 0/3 → 3/3; Spring I weapon ×6 0/3 → 3/3. Alternative: Spawn Amount extras stay passive until hit. Re-simulate: this whole matrix, sustained farm rates (kills/min must not drop), Change 36 ladder (helpers are boss summons, should be unaffected).
2. **R3 — Skill-variant multiplier 1.35 → 1.15 (High, data-only).** Lowers the hardest spot of each map 5–10 HP points at ×3 and decides several ×6 cases; combined with R1, Autumn I ×6 reaches 35 % left. Optionally give normal skill casts the boss's 0.6 s telegraph for fairness (desync alone measured no gain). Re-simulate: same matrix; Reveal Stats text reads the definition (no copy change).
3. **R8 — Spring I/II normal damage (High, needs its own ladder).** Spring normals are lethal at boss-ready builds even after R1+R3. A **×0.60 normal damage factor on maps 7–8** (with R1) makes every tested Spring I spot winnable (68–80 %) and Spring II 3-actor skill spots winnable (50 %), with bosses unchanged; ×0.75 is not enough. Treat 0.60 as the starting value for a dedicated Spring ladder (build families with HP-bearing weapons), not as final.
4. **R5 — Prestige card symmetry (Medium; changes owned cards' meaning).** Pair the boss-only defensive card with a normal-enemy one, e.g. Hunter II "−20 % boss damage taken" → **"−12 % damage taken from all enemies"**, and Trophy II +20 % boss damage → +12 % all. Must re-run the Change 36 ladder (MIN needs one Prestige). Requires an explicit decision on existing owners (same ids, new effect) and copy updates in 20 languages.
5. **R6 — Stage floor for per-type coin upgrades (Medium).** Effective level = max(own, ⌊0.5 × best level on that map's normal types⌋) for Coin Amount, XP, Loot Chance, Supply Drop, Skill Drop. Projected switch cost −85 % → −46 %. No save migration. The player's stage-wide proposal is viable but costs a schema migration, refunds and the per-type choice (§5.3).
6. **R4 — Close the even-map weapon dead zone (Medium, data-only).** On Winter II, Summer II and Autumn II the **last two normal types carry the next weapon tier** (Winter II Santa Hat / Space Helmet → Stone Sword / Stone Axe; Summer II Snorkeler / Straw Hat Swimmer → Iron; Autumn II TV Head / Top Hat → Gold). Normal drops then feed the boss weapon's ^100/evolution. Existing items keep their meaning. Re-check Arsenal/Masterwork opportunity pacing.
7. **R7 — Mid-game XP (Low–Medium, after R1–R3).** Kills per level peak at 110–150 on Summer I–II versus 1–5 on Spring II. Candidate: normal XP ×1.5 on maps 2–5. Not measured; tune only after R1–R3 because faster levels make boss rushing stronger.
8. **UX — M1–M3, O1–O2 (§7.2) (High value, low risk).**
9. **Docs** — fix GDD Prestige keep list (level kept), Content & Balance supply-mastery reset, Potion price 100, cooldown text.

Not proposed: inventory cap (no evidence), nerfing the Stone Axe or boss outfits (owned-item meaning changes; measured gear effect is smaller than burst and Prestige), retuning Winter I/II bosses (they behave as gates).

### Regression / save-meaning review

| Proposal | Could regress | Existing-save meaning | Migration |
|---|---|---|---|
| R1 cap | Farming throughput with Spawn Amount; Guided boss/farm steps | Spawn Amount keeps its value (more actors) | No |
| R3 / R8 enemy numbers | Reveal Stats numbers (data-driven); mission difficulty | Enemy-only | No |
| R5 cards | Final-boss MIN build (needs Prestige) | **Owned cards change effect** | Text + owner decision |
| R6 floor | Coin sinks finish sooner; late coin prices must still bind | Purchases keep exact value | No |
| Stage-wide alternative | Per-type UI, Farming Guide | Per-type levels must be folded | **Yes (schema)** |
| R4 drops | Evolution/opportunity pacing; Farming Guide drop lists | Same ids | No |
| R7 XP | Faster Prestige loop | Future pace only | No |
| UX hints | 432×960 / 540×960 layouts, 20-language length, guide arbitration | New `tutorial.seen` keys only | No |

---

## 9. Validation record

| Item | Detail |
|---|---|
| Harness | Preserved (2026-11-06) as `tests/player_feedback_audit.tscn` (non-gating), with `tools/player_feedback_audit_builds.py` (build files), `tools/player_feedback_audit_run.py` (batches + baseline comparison + Change 36 cross-check) and `tools/player_feedback_audit_analyze.py`. Steps the unmodified `LootSimulation` at 0.1 s (basic attacks, real aggro/assist, enemy skills, boss telegraphs/heals/summons, supplies, auto-cast). Legitimacy rules follow Change 36 (obtainable non-legacy ids, asserted equips, real Prestige transaction, labelled seeds). Commands and layout: `docs/Player_Feedback_Audit_Evidence/README.md`. The original runs used the same script from a temporary folder; the preserved copy reproduces all four baselines field for field. |
| Profiles / seeds | Isolated `user://profiles/probe-audit48*`; seeds 1, 2, 3 per fight (farm runs: 1, or 1–2). |
| Trials | Main 4,136 rows (774 s); supplementary 690 (158 s); what-ifs 360 (125 s) + 63 (47 s). Total **5,249**. 5 invalid rows (boss "farm" entries: Focus cannot target bosses), excluded. No script errors. |
| Determinism | Seeds move durations by ≤ 1–2 s; 3/3 means reliable under the stated policy, **not a player win rate**. |
| Cross-checks (project harnesses, output redirected) | `tests/change_36_final_boss_audit --only=MIN,REC`: MIN 5/5 256–263 s, REC 5/5 156–160 s, 20 checks 0 failures — **reproduces the recorded Change 36 cells exactly**. `tests/change_9_balance`: 33/35, the same 2 known failures as recorded (Content & Balance header). |
| Evidence (data, in repo) | `docs/Player_Feedback_Audit_Evidence/`: build definitions `builds_<batch>.json`, per-trial `baseline_trials_<batch>.csv`, `baseline_summary_main.txt`, `baseline_gear_table.txt`, `baseline_economy_projection.txt`, cross-check logs. Reruns write only to git-ignored `tests/tmp/player_feedback_audit/`. |
| Known limitations | Spot fights block respawns (understates difficulty; sustained farm rows cover respawn). The supplementary "3-actor" sustained farm duplicated the 6-actor entry (generator bug), so the 3-actor sustained figure comes from the main FARM rows (both-loadout variant). No manual dodging exists, so bots and humans differ mainly in potion/skill timing (the attentive policy). Prestige time cost, gem income, mission/offline coins and full-journey pacing not measured (pacing bot stale). Spring II boss-level build wears a sword (less HP than arrival). Late-map builds are representative, not exhaustive. Device feel untested. |
| Project state after audit | The audit changed no gameplay, balance, UI, localization or save code. The harness, tools, evidence and this report were committed afterwards as test infrastructure only. |

---

## 10. Developer decisions required

- [ ] **R1** — Accept a cap of **3 simultaneous normal attackers** (or alternative: Spawn Amount extras passive until hit)?
- [ ] **R3** — Lower the skill-variant multiplier **1.35 → 1.15**? Add the 0.6 s telegraph to normal skill casts?
- [ ] **R8** — Start a Spring I/II normal-damage retune at **×0.60** (with R1), verified by a dedicated Spring ladder?
- [ ] **R5** — Rebalance boss-only Prestige cards (proposed −12 % all-enemy guard / +12 % all damage)? Decide treatment of existing owners.
- [ ] **R6 vs stage-wide** — Economy: 50 % map floor (recommended, no migration) or the player's stage-wide upgrades (migration + refunds)?
- [ ] **R4** — Let the last two normal types of Winter II, Summer II and Autumn II carry the next weapon tier?
- [ ] **R7** — Revisit mid-game XP (maps 2–5) after R1–R3 are measured?
- [ ] **UX** — Approve hints M1–M3 and O1–O2 and their wording; accept ~9 new keys for the 19-language handoff?
- [ ] **Docs** — Correct the four documentation conflicts listed at the top.
- [ ] Re-simulation gate for the implementation batch: this matrix and ladders (same seeds), sustained farm rates, the Change 36 final-boss ladder, `change_9_balance`, and an Android feel check of Summer I spots.
