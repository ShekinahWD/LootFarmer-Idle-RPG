# LootFarmer — Consolidated Progression, Prestige & Combat Audit (Report)

**Date:** 2026-11-07 · **Mode:** audit / investigation only. Nothing in gameplay, balance, catalog, UI, localization, save code, tests, the GDD or the Playbook was changed, and nothing was committed. · **Brief:** `docs/LootFarmer_Consolidated_Progression_and_Prestige_Audit_Brief.md` · **Evidence:** `docs/Consolidated_Audit_Evidence/` (README lists every file and command)

**How to read the evidence labels (Playbook 112.2, 140).** **MEASURED** means a real `LootSimulation` fight or farm stepped at 0.1 s, with real aggro, assist, enemy skills, boss telegraphs, heals, summons, supplies and auto-cast. Every item was legally obtainable and actually equipped, and Prestige cards came from the game's real Prestige transaction. Every build is still a **constructed fixture**: level, merge levels, lifetime kills, supply mastery and stock are seeded stand-ins for play time. **WHAT-IF** means the same harness ran with an in-memory catalog change (never written to disk), labelled in the CSV `whatif` column. **PROJECTED** means arithmetic from catalog formulas and measured kill rates. **CODE** means read from source or proven by the Prestige diff probe. Nothing here is a natural playthrough. The pacing bot is still stale (Change 36 note).

---

## 0. Executive summary

1. **The approved decisions are workable**, with **four technical conflicts** that need a ruling (§1.3):
   - **(a)** Evolution at ^20 with the current ^100 weapon cap means Merge, Merge All and Auto-Merge eat the 10 spare copies, so Auto Evolution can never fire. **Fix:** non-final weapons stop merging at ^20, and Obsidian keeps ^100.
   - **(b)** Arsenal and Masterwork Prestige objectives require weapons at ^50 or ^100, so they must be re-thresholded.
   - **(c)** Today's ×2.55 per-tier step cannot survive one tier per stage. Measured from Stage 4 on, the player is 1.5–5.7× stronger than today and every boss falls in 20–40 s. Weapon stats must be re-based, and that changes what existing high-tier weapons are worth.
   - **(d)** Pending offline item grants survive Prestige and can be claimed into the fresh inventory. With merge levels retained, that becomes a free re-acquisition path.
2. **Weapon tiers (MEASURED, 3 tables × 40 builds × 2,346 trials each).**
   - Recommended stats: **×1.9 per tier from Wood to Emerald**, then a larger final step into Obsidian (**Obsidian = Emerald × 2.4**, sword base 237.7 ("H24")).
   - With these, every stage has the intended shape: the arrival build loses the boss (0/3), the mid/ready build wins it, every 3-actor spot is won at the ready build, and 6-actor spots stay a real risk.
   - Each evolution gives **+36 %** over the source at ^20. A first drop of the next tier is worth the current tier at ^45.
3. **Evolution at ^20 + 10 spares (31 copies) is confirmed as a good target.** It costs **28–85 min** of focus farming at base loot (11–34 min with Loot ^15). That is **a fifth to two thirds of a first-run stage stay on Winter II–Spring I**, so it is a real but optional farming route to break a boss gate. The current 201-copy rule takes 3–10 h per evolution and is out of reach on most first-run stages.
4. **Combat.**
   - Removing group assist on Summer I (Stage 3) is decisive. The L35 6-actor skill spot goes from **0/3 to 3/3**, and sustained farming of 6-actor spots drops from **10–24 to 6–18 deaths per 10 min**. If Stage 3 is made fully passive instead (only the enemy you hit fights), it drops to **0–4**.
   - Bosses are unchanged in every row. No attacker cap is used or recommended.
   - From Stage 4 on, the ×1.9 tiers need **no enemy retune on Summer II–Autumn II**. Every 3- and 6-actor spot is won at the ready build; the one exception is the Autumn I Pumpkin 6-skill spot, which **skill variant ×1.15** fixes (0/3 → 2/3). **Spring I/II normal damage ×0.60** is the only measured way to make Spring 6-actor Elf Ears spots winnable (P1: 0/3 → 3/3 69 %; Obsidian ^50 P0: 3/3 50 %). Staggered group joining changes ±5 points and is not recommended.
5. **Prestige retention (CODE + PROJECTED).**
   - Keeping Coins and every Coin upgrade creates **no instant skip**. Coins cannot buy access, gear or levels, and the finite Coin sink is **54.5 M**, so it is not exhausted for many runs.
   - Two real risks: (i) missions are priced at the kept `reward_stage`, so a repeat-run Winter I mission pays late-map coins; (ii) unclaimed missions, main objectives and offline items get lost or duplicated at the reset.
   - A field-by-field keep/reset matrix with recommendations is in §2.
6. **Prestige variety (CODE).**
   - **Winter II, Summer II, Autumn I, Autumn II and Spring II have no normal-farming Prestige objective at all.** Spring I and II have no boss objective except Regional.
   - The Prestige panel shows Trophy II and III under the wrong maps.
   - Recommended: **Design A, "map ladders"**. Expedition and Collection on all 8 maps, Hunter, Challenge, Trophy and Regional extended to Spring, and Masterwork IV. That is **33 → 48 opportunities and 33 → 48 cards**: 15 new effects, 11 of them aimed at normal farming and survival, with no new currency.
7. **Save risk is manageable** with a **schema 9** migration (§9). Merge memory is seeded from items and Map Mastery. Weapons above the new caps keep their level. Old-stat weapons stay as legacy items until the next Prestige. Every owned card and consumed opportunity id is kept.

---

## 1. Source, version and decision compliance

### 1.1 Baseline recorded

| Item | Value |
|---|---|
| Branch / commit | `main` @ `3dd2eab` (Change 48: audit harness preserved) |
| Game version | `project.godot` `config/version="27"` |
| Catalog | `data/game/catalog.json`: no working-tree diff. 397 items (14 weapons, 336 outfits, 42 skills, 5 supplies), 48 groups, 56 upgrades, 33 opportunities, 33 cards, 17 combos |
| Save | state `schema` 8, file `SAVE_VERSION` 3 (`save_service.gd:15`) |
| Engine | Godot 4.7.2 stable, headless |
| Uncommitted files (not mine, not read as gameplay) | `project.godot` (setting order and icon uid), `export_presets.cfg`, `marketing/match_cut_v4/add_speed_blur.py`, `docs/Reusable_Game_Development_Playbook.md` (developer edit, read from the working copy), untracked localization drafts and older docs. **None touches combat, economy or catalog data.** |
| Harness | **Present** in this working tree, unlike the ZIP the brief describes: `tests/player_feedback_audit.gd/.tscn`, `tools/player_feedback_audit_{builds,run,analyze}.py`. `builds-check`: PASS (4/4 identical) |
| Baseline reproduction (Rule 2) | `python tools/player_feedback_audit_run.py --crosscheck` on the unchanged tree: main 4,136 rows, supplementary 690, whatif 360, whatif_spring 63. **COMPARE PASS on all four, 0 differing fields.** Change 36 MIN 5/5 (256–263 s), REC 5/5 (156–160 s), `AUDIT36_CHECKS 20 FAILURES 0`. **PLAYER_FEEDBACK_AUDIT PASS.** |

### 1.2 Docs versus runtime (runtime treated as the authority)

| # | Document says | Runtime does | Source |
|---|---|---|---|
| D1 | GDD "Reset ownership": Prestige resets player level and item progress | Keeps `player_level` and `xp` (since Change 20) | `campaign.gd:1266` |
| D2 | `PRESTIGE_CONFIRM_SUMMARY` (dead function `_prestige_summary`) says level and map exploration reset | Both are kept | `game_ui.gd:3228`, `en.po:3924` |
| D3 | `PRESTIGE_RESET` (Prestige overview) says Map upgrades and coin upgrades reset | True today; **wrong after the approved redesign** | `en.po:3942` |
| D4 | Challenge I catalog discovery note: "Defeat boss-snowman once" | Discovers on defeating the **Cyan Robot** | `campaign.gd:1041-1042` |
| D5 | Prestige panel shows Trophy II under Summer I, Summer II **and Autumn I**, and Trophy III under **Autumn II, Spring I and Spring II** | Trophy II is performed on Summer I–II and Trophy III on **Autumn I–II** | `game_ui.gd:3115` versus `campaign.gd:1086-1089` |
| D6 | Masterwork descriptions: "tier 2 drops from Summer I on" | Becomes false with one tier per stage | `en.po:3331-3337` |
| D7 | Content & Balance (from the previous audit): supply mastery kept, Potion 10 coins, old cooldown list | Supply mastery resets, Potion costs 100 | previous report §1 |

### 1.3 Compliance with the approved decisions

| Decision | Live state | Conflict? | Recommendation |
|---|---|---|---|
| A. Keep level/XP, Coins/Gems, every purchased upgrade, per-ID merge level, cards, discoveries, fog | Level, XP, Gems, Gem upgrades, coin upgrades marked `keep`, cards, fog and discoveries are kept. **Coins, 13 coin upgrades and every merge level reset.** | No | §2 |
| A. Camps reset while upgrades persist | `camp_radius` is a camp-scoped upgrade (`upgrade_cost` scope "camp") whose effect only applies to owned camps (`campaign.gd:434`) | No: a kept level stays inert until the camp is bought again | Keep the level; say so in the Camp card ("radius upgrade returns when you rebuy this camp") |
| A. Hard Reset unchanged | `new_profile()` rebuilds the whole state | No, **provided** the new merge memory lives in `state` | Add it to `state` |
| B. One tier per stage; boss drops the same tier | Normals drop tiers 1,1,2,2,3,3,4,5 and bosses one tier higher. The Snowman's first kill always drops a Stone Axe (`onboarding_rules.tres` `first_kill_weapon_bosses`). | **(c)** with the old ×2.55 stats (§3.3) | Re-base the tier stats. The guaranteed Snowman drop becomes the **Wood Axe (enhanced)**. |
| C. Boss copy gets two extra random attributes from the live pool, each rerollable | One extra per item **ID** (`record()` rolls `mini(1,pool)`), stored on the ID record. `reroll()` erases the record and rolls the whole set again. | No | §4: ID-level `boss_extras` |
| D. Evolution makes one copy of the next ID and keeps the target's merge record | `evolve()`: removes `spare_cost`, `add_item(target,1)`. The target keeps its record. The source keeps its merge level and its last copy. | **(a)** with cap ^100 and requirement ^20 | §3.4: non-final weapons stop merging at ^20 |
| E. No group aggression on Stages 1–3; group from Stage 4; no attacker cap | Winter I `passive`, Winter II `individual`, **Summer I `group`** | No | Summer I normals become `individual` (§5) |
| F. Expand opportunities and cards on every map | 33/33, with coverage gaps (§7.1) | **(b)**: Arsenal and Masterwork thresholds are weapon ^50/^100 | §7 |
| G. Contextual hints | None exist for Map Detail or offline gear (previous audit §7) | No | §8 |

---

## 2. Prestige keep/reset matrix (from actual save fields)

**Method (CODE + probe).** `tests/tmp/c49/c49_prestige_diff.gd` (evidence copy `c49_prestige_diff.gd`) fills every field: level 30, 1 M coins, 100 K gems, Wood Axe ^20, owned camp 1, eleven coin upgrades and nine gem upgrades, a mission half done, supply uses, buffs, a boss respawn timer, ground loot, a pending offline claim with 2 Wood Axes, a followed mission and seven earned-but-unclaimed main objectives. It then runs the **real** `begin_prestige()` and `choose_card()` and classifies each field. Output: `prestige_diff.log`.

Columns: **Now** = measured behaviour. **Approved** = the brief's rule. **Recommended layer** = P (profile, kept), R (run, reset), or **DEC** (developer decision, with my recommendation).

| Field(s) | What it is | Now | Approved | Recommended layer / action |
|---|---|---|---|---|
| `player_level`, `xp` | Level and progress | KEPT | Keep | P (no change) |
| `coins` | Coin balance | **RESET** | **Keep** | **P: change** |
| `gems` | Gem balance | KEPT | Keep | P |
| `online_coins`, `online_gems` | Run-earned credit for Offering | reset (fresh profile) | — | R (Offering stays "earned this run") |
| `upgrades` (gems, plus coin with `keep:true`: reveal_stats/drops, collect_range/speed, offline_* rates) | Permanent upgrades | KEPT | Keep | P |
| `upgrades` coin, `keep:false`: coin_amount, loot, group_xp, supply_drop, skill_drop, respawn, movement, cooldown_* (6), map_detail, reveal_radius, camp_radius | Run upgrades | **RESET** | **Keep** | **P: change** (`upgrade_kept()` returns true for all; set `keep:true` on every entry, or drop the field) |
| `items[id].qty`, `gear`, `supplies`, `weapon`, `outfit`, `skills`, `auto_slots` | Inventory and loadout | RESET | Reset | R |
| `items[id].merge` | Per-ID merge level | **RESET** | **Keep per ID, without ownership** | **P: new `merge_memory {id: level}`** (§2.2) |
| `items[id].extras` (+ new `boss_extras`) | Rolled attributes | RESET | Not specified | **DEC: R recommended.** Rolls belong to the copy you hold; the Gem cost of a reroll is small (3–192). |
| `supply_uses`, `supply_mastery_credit` | Supply Mastery (shown as ^ on supplies) | RESET | Not listed (the approved merge rule names weapons, outfits and skills) | **DEC: R recommended** (current behaviour, Change 36 verdict depends on it). If kept, the Change 36 MIN needs a rerun. |
| `camps` / `spawns` | Owned camps | RESET | Reset | R |
| `camps_known`, `explored`, `discovered`, `discovered_spots`, `bosses_found` | Discovery | KEPT | Keep | P |
| `unlocked_stage`, `stage`, `run_kills`, `stage_worlds`, `world_complete`(*) | Access and run clears | unlocked/run_kills/stage_worlds RESET; `world_complete` **stays false in a fresh profile but is not in the keep list** | Reset | R. (*) `world_complete` is a run flag. Main objective 15 is protected by `main_claimed`. |
| `missions` (regular) | Daily missions | **REGENERATED; finished but unclaimed rewards are lost** | Incomplete progress resets | **DEC: auto-claim completed missions inside the Prestige transaction**, then reset. Unfinished ones reset (approved). |
| `main_ready` | Earned but unclaimed main objectives | **RESET** (7 lost in the probe) | Not specified | **DEC: P recommended.** Keep `main_ready` (the objectives are permanent), or auto-claim at reset. |
| `main_claimed` | Claimed main objectives | KEPT | Keep | P |
| `opportunities`, `consumed`, `owned_cards`, `cards` (legacy) | Prestige records | Opportunities kept but their progress reset (offline ones keep progress); consumed and cards kept | Incomplete progress resets | P (no change) |
| `prestige_batch` | Transaction in progress | Saved between `begin_prestige` and the last card | — | P (interrupted-reset protection, §2.3) |
| `offline_pending` | Unclaimed offline earnings | **KEPT, including item copies chosen before the reset** | Not specified | **DEC: auto-claim inside the transaction before the inventory wipe.** Coins and gems are paid and kept; the item copies vanish with the inventory. Alternative: block Prestige until claimed. |
| `offline_snapshot`, `offline_remainders` | Departure snapshot | snapshot RESET, remainders kept | — | R / P (no change) |
| `offline_total/longest/income` | Offline path counters | KEPT | Keep (lifetime opportunities) | P |
| `reward_stage` | Highest stage for pricing mission rewards | **KEPT** (probe: a new Winter I kill mission is priced at Stage 3: 90 coins instead of 40) | Not specified | **DEC.** Kept Coins make this compound (§6.3). Recommend pricing at `max(1, unlocked_stage)` of the current run. |
| `counters` | Run counters (kills, merges, …) | RESET | — | R |
| `group_kills` | Lifetime kills (achievements) | KEPT | Keep | P |
| `mastery` | Map Mastery records (incl. `merge`: best merge per ID) | KEPT | Keep | P. **Usable as the migration seed**, §9 |
| `buffs`, `boost_*`, `skill_cooldowns`, `boss_respawns`, `pickups`, `history`, `merge_timers`, `follow_mission`, `follow` | Transient run state | RESET | Reset | R |
| `skill_auto`, `tutorial`, `onboarding`, `review`, `skills_seen`, `supply_found`, `keys`, `final_*`, `prestige_collapsed`, `playtime_total` | Preferences and history | KEPT | Keep | P |

### 2.2 Merge memory design (simplest safe)

- New profile-layer field `state.merge_memory: {item_id: int}`. It is written whenever `merge()` raises a record (`max(memory, record.merge)`) and when an item is created.
- `record(id)` initialises `merge` from `merge_memory.get(id, 0)` when it creates the run record. That gives: re-obtaining an item restores its level; an evolution target keeps its level; nothing applies while you own no copy (`stat_sources()` and `normal()` already skip `quantity < 1`).
- **Why not keep qty-0 records in `items`:** at least six readers treat any record with `merge > 0` as "merged this run" or "owned". These are the Guided "merge" step (`guided_progress.gd:104`), `tutorial_guide.gd:256`, Masterwork I discovery (`campaign.gd:1033`), Map Mastery records, the onboarding loot guarantee and the mission candidate list. Keeping zero-quantity records there would silently complete objectives on a fresh run.
- Evolution: the source keeps its record (^20 plus the last copy). The target gains `qty + 1` and keeps its memory. The source's level is **never** copied to the target (approved). Repeat evolution needs another 10 spares each time.
- Hard Reset clears it (it is part of `state`).

### 2.3 Atomic reset (already sound; extend, don't replace)

- `begin_prestige()` saves `prestige_batch` first. Each `choose_card()` saves at once, and the last card builds the whole new state in memory and commits it in **one** `SaveService.save_now()`. A failed write restores `before`.
- A reload during the batch resumes the choice (`valid_snapshot` checks the batch shape). Step stops while a batch is open.
- **Add, inside the final choice and before `new_profile()`:**
  1. auto-claim completed missions (DEC);
  2. auto-claim `offline_pending` (DEC);
  3. fold the run's merges into `merge_memory`;
  4. copy `coins`.
- These happen in the same in-memory state and the same single write, so there is no half-applied reset.
- Tests: kill the process between cards, after the final card and before the write, and on a write failure (the `SaveService.write_blocked` hook); a reload must show either the old run or the new one, never a mix.

### 2.4 After Prestige: seen versus visitable

- Fog, sighted camps, found spots and found bosses stay drawn on every map.
- Travel and camp use follow `unlocked_stage` and `camps` (both reset), so a later map can be **seen** on the world map but not entered until its gate boss is beaten again. Its camps show as known but unowned (purchasable again at that map's price).
- With Map Detail kept (approved), markers over explored ground stay visible from the first second of the new run. The Farming Guide stays open once fully researched; it is no longer "per run" (`farming_guide_status` comment, `campaign.gd:1166`).
- Objective progress restarts from zero (`baseline` reset). Discovered-but-unconsumed opportunities stay listed.

---

## 3. Weapon tiers and evolution

### 3.1 Live model (CODE)

- Weapon damage = `base + merge_gain × level`, with `merge_gain` = 2 % of base (so ^20 = ×1.4, ^50 = ×2.0, ^100 = ×3.0).
- Axe = 0.8 × the sword's damage plus HP = 3.0 × the sword's base damage.
- Stored, unequipped weapons count at 30 %. At the merge cap, each spare copy adds +0.05 %.
- Tier base ×2.55 per tier (= ^100 × the evolution `base_multiplier` 0.85).
- Evolution: `required_merge` 100, `spare_cost` 100, so **1 + 100 + 100 = 201 copies acquired per tier step**.
- Drops: every item in a kill's loot rolls independently at `gear_chance` (5 % normals, 30 % bosses) + 0.5 points per Loot Chance level (cap 15 levels) + Collection II card 3 points. Variant v0 drops only the outfit, v1 only the weapon, v2/v3 both.

### 3.2 Eight-stage, two-family table: current versus proposed

| Map | Normal weapon now (Sword types / Axe types) | Boss weapon now | **Proposed normal and boss** | Proposed sword dmg ^0 / ^20 (Obsidian ^100) | Axe dmg / HP ^20 | Reroll (gems) |
|---|---|---|---|---|---|---|
| 1 Winter I | Wood (Blue Cap, Red Scarf / Chef Hat) | Stone Axe (+ guaranteed first kill) | **Wood** (+ boss-enhanced Wood Axe, guaranteed first kill) | 4.0 / 5.6 | 4.5 / 16.8 | 3 |
| 2 Winter II | Wood (3 / 3) | Stone Sword | **Stone** | 7.6 / 10.6 | 8.5 / 31.9 | 6 |
| 3 Summer I | Stone (1 / 2) | Iron Axe | **Iron** | 14.4 / 20.2 | 16.2 / 60.6 | 12 |
| 4 Summer II | Stone (4 / 2) | Iron Sword | **Gold** | 27.4 / 38.4 | 30.7 / 115 | 24 |
| 5 Autumn I | Iron (1 / 2) | Gold Sword | **Diamond** | 52.1 / 73.0 | 58.4 / 219 | 48 |
| 6 Autumn II | Iron (2 / 2) | Gold Sword | **Emerald** | 99.0 / 138.7 | 111 / 416 | 96 |
| 7 Spring I | Gold (1 / 2) | Diamond Axe | **Obsidian** | 237.7 / 332.8 (H24); ^50 475 | | 192 |
| 8 Spring II | Diamond (4 / 2) | Emerald Sword | **Obsidian** (merge to ^100) | ^100: 713 (axe 571 dmg / 2,139 HP) | | 192 |

Families stay as they are per type: each type keeps its own sword or axe and only the tier changes. The final boss (Green Alien) also drops Obsidian. Whether it drops a boss-enhanced Obsidian Sword is listed in §12.

**Table comparison at ^0 / ^20 / ^50 / ^100 (sword base, PROJECTED from the formulas):**

| Table | T1 | T2 | T3 | T4 | T5 | T6 | T7 ^0 / ^20 / ^50 / ^100 |
|---|---|---|---|---|---|---|---|
| Current ×2.55 | 4.0 | 10.2 | 26.0 | 66.3 | 169 | 431 | 1,100 / 1,540 / 2,200 / 3,299 |
| A ×1.9 | 4.0 | 7.6 | 14.4 | 27.4 | 52.1 | 99.0 | 188 / 263 / 376 / 565 |
| H24 (×1.9, then ×2.4 into Obsidian) | 4.0 | 7.6 | 14.4 | 27.4 | 52.1 | 99.0 | 238 / 333 / 475 / 713 |
| H28 (×1.9, then ×2.8) | 4.0 | 7.6 | 14.4 | 27.4 | 52.1 | 99.0 | 277 / 388 / 555 / 832 |
| B ×2.2 | 4.0 | 8.8 | 19.4 | 42.6 | 93.7 | 206 | 454 / 635 / 907 / 1,361 |

### 3.3 Measured: which tier step works (WHAT-IF, 2,346 trials per table)

Builds: 40 fixtures that take the baseline builds' levels, outfits, skills, supplies, kills and Prestige sets **unchanged** and swap only the weapon to the proposed ladder. Arrival = previous tier ^20, mid = this tier ^10, ready = this tier ^20, evo = next tier ^0 with this tier ^20 stored, plus Spring Obsidian ^50/^60/^100. All runs use Summer I `individual` aggro and the same seeds 1–3. Full rows: `lad_*.csv`; summary: `ladder_summary.txt`.

| Map · build | Baseline twin (today) | Current ×2.55 on new ladder | **A ×1.9** | B ×2.2 |
|---|---|---|---|---|
| W2 ready (L20) | Robot 3/3 51 % | 3/3 43 % | **3/3 41 %** | 3/3 45 % |
| W2 arrival (L10) | Robot 0/3 | 0/3 | **0/3** | 0/3 |
| S3 arrival (L22) | Gray Cat 0/3 | 0/3 | **0/3** | 0/3 |
| S3 ready (L35) | Gray Cat 3/3 50 %; Yellow ×6 skill 0/3 | 3/3 49 %; ×6 3/3 39 % | **3/3 23 %; ×6 3/3 23 %** | 3/3 44 %; ×6 3/3 29 % |
| S3 evolved (Gold ^0) | — | 3/3 70 % | **3/3 44 %** | 3/3 47 % |
| S4 arrival hand P0 (L38) | Elephant/Teal 0/3 | Elephant 3/3 9 % | **0/3, 0/3** | 0/3, 0/3 |
| S4 ready (L60) | 86 % / 58 % | 92 % / 77 % | **70 % / 69 %** | 84 % / 71 % |
| S5 arrival hand P0 (L65) | 0/3, 0/3 | Squirrel 3/3 | **0/3, 0/3** | 0/3, 0/3 |
| S5 mid P1 | Squirrel 38 %, Fox 0/3 | 98 % / 89 % | **50 % / 40 %** | 90 % / 60 % |
| S5 ready (L95) | 57 % / 58 %, ×6 0/3 | 98 % / 95 % | **66 % / 60 %, ×6 0/3** | 85 % / 62 %, ×6 3/3 |
| S6 arrival P0 (L95) | 0/3, 0/3 | Black Cat 3/3 | **0/3, 0/3** | 0/3, 0/3 |
| S6 ready (L140) | 55 % / 14 % | 91 % / 97 % | **59 % / 71 %** | 90 % / 69 % |
| S7 arrival P0 (L140) | 0/3; 3/11 spots | 0/3; 11/11 | **0/3; 4/11** | 0/3; 10/11 |
| S7 ready (L195) | **Bee/Tabby 0/3** (256 s) | 90 % / 100 %, 40 s | **53 % / 57 %, 189–239 s** | 64 % / 62 %, ~100 s |
| S8 ready Obsidian ^100 P0 (L240) | 0/3, 0/3; 8/22 spots | 96 % / 90 %, 60 s | **0/3, 0/3; 20/22** | 67 % / 64 %, 160 s |
| S8 ready ^100 P1 | 54 % / 0/3 | 100 % | **81 % / 66 %, 240–282 s** | 100 % |
| Fight length at the boss-ready build | 41–256 s | **20–60 s** | 56–282 s | 46–162 s |

**Verdict.**
- **×2.55 is rejected:** from Stage 4 every boss falls in 20–40 s at the mid-stage build.
- **×2.2 is too generous for Summer II–Autumn II:** mid builds beat both bosses with 60–90 % HP left, and evolved builds with 87–98 %.
- **×1.9 keeps every gate on Winter II–Spring I** (arrival 0/3, ready 3/3 with 23–71 % left) but **leaves Spring II needing a Prestige.**
- - **Hybrid H24 (×1.9 through Emerald, ×2.4 into Obsidian) is recommended.** It changes only Spring (S6 ready identical to A).
  - Spring I ready: Bee/Tabby go from 53/57 % to **63/67 % (161–193 s)**.
  - Spring II at Obsidian ^100: P0 Red Panda goes from 0/3 to **3/3 55 %**; Sunflower stays 0/3. P1: **86 % / 91 %**.
  - H28 (×2.8) adds little: Sunflower stays 0/3 at P0, and P1 Sunflower drops to 62 % (seed effect).
  - Spring II therefore keeps today's "one Prestige" requirement, matching the Change 36 final-boss verdict.

| Stage 7–8 build | A ×1.9 | **H24** | H28 | B ×2.2 |
|---|---|---|---|---|
| S7 mid (Obsidian ^10) | Bee 49 % 224 s, Tabby 57 % | **76 % 182 s, 74 %** | 61 %, 54 % | 98 %, 88 % |
| S7 ready (^20) | 53 % / 57 % | **63 % / 67 %** | 61 % / 85 % | 64 % / 62 % |
| S7 ready P1 | 80 % / 63 % | **96 % / 88 %** | 98 % / 90 % | 98 % / 96 % |
| S8 ^60 P0 | 0/3, 0/3 | **0/3, 0/3** | 0/3, 0/3 | 78 %, 50 % |
| S8 ^100 P0 | 0/3, 0/3 | **Panda 3/3 55 %, Sunflower 0/3** | 58 %, 0/3 | 67 %, 64 % |
| S8 ^100 P1 | 81 % / 66 % | **86 % / 91 %** | 96 % / 62 % | 100 % / 99 % |
| S8 3-actor spots won, ^100 P0 | 20/22 | 21/22 | 22/22 | 22/22 |

### 3.4 Merge caps, evolution and copy accounting (resolves conflict (a))

**Rule (recommended):** a weapon with a `next` tier merges to **^20** (= the evolution requirement). Obsidian (no `next`) merges to **^100**. Evolution costs **10 spare copies** above ^20. Outfits and skills are unchanged (^500, copy growth). The catalog's `base_multiplier` 0.85 retires, because the tier table is now explicit.

- Copies, exact: the first copy + 20 merges + 10 spares = **31 acquired**. Each repeat evolution of the same source costs +10. Obsidian ^100 = 101 copies. The source keeps ^20 and one copy (30 % stored value). The evolved copy starts at the target's `merge_memory` level.
- Why the cap: with cap ^100 and requirement ^20, Merge, Merge All and Auto-Merge (`merge_cycle` merges whenever `qty > 1`) always consume the spares. `evolve_block_reason` needs `qty ≥ 11` and is never satisfied, so **Auto Evolution (2,000 gems) could never fire**.
- The cap also removes a trap. Past ^20, 10 copies of merging give +0.2 base, while 10 copies of evolving give the next tier (×1.36 equipped) plus 30 % of the source.
- At the cap, extra copies keep their tiny stock bonus (+0.05 % each) and feed repeat evolutions.
- **Validator:** `valid_snapshot` rejects `merge > merge_cap(id)`. A save with Stone Axe ^100 would be **rejected and the profile lost**, so validation must keep allowing ^100 for any weapon (legacy over-cap levels keep their effect; only new merges stop at ^20). See §9.

**Candidates (PROJECTED; minutes of focus-farming one weapon-carrying spot at the measured A ×1.9 ready-build kill rates; P50 kills from Monte Carlo, 4,000 runs):**

| Candidate | Copies | Kills at 5 % (P10/P50/P90) | Winter II (21 k/m) | Summer I (17) | Summer II (13.4) | Autumn I (12) | Autumn II (10.6) | Spring I (8.6) | With Loot ^15, Summer I |
|---|---|---|---|---|---|---|---|---|---|
| Current ^100 + 100 | 201 | 3,656 / 3,999 / 4,360 | 191 min | 235 | 298 | 333 | 377 | 465 | 94 min |
| ^30 + 10 | 41 | 643 / 793 / 962 | 38 | 47 | 59 | 66 | 75 | 92 | 19 |
| **^20 + 10 (preferred)** | **31** | 470 / **594** / 738 | **28** | **35** | **44** | **50** | **56** | **69** | **14** |
| ^10 + 10 | 21 | 297 / 396 / 517 | 19 | 23 | 30 | 33 | 37 | 46 | 9 |

**First-run stage stay (PROJECTED: XP from arrival level to boss-ready level ÷ measured XP/min at the ready build):** Winter I ≈ 11 min, Winter II ≈ 43, Summer I ≈ 104, Summer II ≈ 258, Autumn I ≈ 302, Autumn II ≈ 253, Spring I ≈ 117 (Spring II is XP-rich: ≈ 15 min to its levels, but its Obsidian ^100 needs about 101 copies ≈ 1.5–3 h).

**Recommendation: keep ^20 + 10.**
- It is about **34–65 % of a stage stay** on Winter II, Summer I and Spring I and 17–22 % on Summer II–Autumn II, so every stage can produce one evolution, and players who farm get a measured +36 % weapon (S3: Gray Cat 23 % → 44 % HP left).
- ^10 + 10 makes evolution near-automatic. ^30 + 10 pushes it past the Winter II stay.
- Poor luck (P90) adds about 25 %.
- Risk: long stays (Summer II, Autumn I) yield 130–180 copies at base. That is the first evolution plus about 10–14 repeat evolutions, i.e. arriving at the next map with that map's tier already near ^10–^14. Measured, that build beats the next map's bosses only with a Prestige (S5 mid P1). That is a farming reward, not a skip. If it proves too fast in device play, the knob is **repeat evolutions at 20 spares** (first stays 10); see §12.
- Sword versus Axe (MEASURED, same build). S3: Iron Sword ^20 hits harder (+10 %) but has −61 HP, giving Gray Cat 15 % left versus the axe's 23 %, and the ×6 spot 0/3 versus 3/3. S7: Obsidian Sword loses both bosses where the axe wins. **Axes are the safer fighting choice and swords the faster farming choice**, which is today's intent; no change.

### 3.5 Old Snowman guarantee and boss gear

- Change 27's first-kill guarantee stays and now drops the **Wood Axe (boss-enhanced)**: data only, `onboarding_rules.tres` stays, catalog loot changes.
- The Summer I arrival with only guaranteed gear (previous C7/C8) is no longer a dead zone: Winter II drops Stone and the Snowman no longer hands out the Winter II tier.

---

## 4. Boss-enhanced weapons

### 4.1 What the extras are worth (MEASURED + PROJECTED)

- **The pool** (all weapons alike, not scaled by tier): crit 1–3 %, crit damage 5–15 %, attack speed 2–6 %, lifesteal 0.5–1.5 %.
- **One normal extra plus two boss extras:**
  - at mean rolls: +5.5 % dps (base build);
  - at max rolls: +7.5 % dps plus 1.5 % lifesteal;
  - in merge terms, about ^3–^4 on the same item.
- **Measured (A ×1.9):**
  - S3 ready: Gray Cat goes from 23 % (no extras) to 35 % (mean) or 42 % (max) HP left, 56 s → 48–50 s.
  - S7 ready, max: Bee 53 % → 60 %.
  - 3-actor spots move by 4–5 points.
- **So boss copies are a modest, felt bonus and never invalidate normal drops.** A next-tier normal drop is ×1.9 and ^20 is ×1.4.

### 4.2 Representation options

| Option | Model | Normal copies feed the same merge? | Save change | Exploit surface | Verdict |
|---|---|---|---|---|---|
| **B1 (recommended) ID-level enhancement** | `items[id]` gains `boss_extras: [{stat, value}, {stat, value}]` beside the existing `extras` (the base roll). The **first boss copy** of an ID while it has none fills both slots; later boss copies are ordinary copies (qty +1, merge fuel). | Yes: one stack, one merge level | Additive key (validator: optional array, ≤ 2, keys from the item's pool) | Low: no per-copy identities to duplicate | Simplest; matches the one-record-per-ID inventory |
| B2 Separate boss item IDs (`iron_axe_boss`) | Own catalog entry | **No**: violates "normal duplicates feed the same weapon" | Catalog +14 ids, merge memory split | Medium | Rejected |
| B3 Per-copy instances | Inventory becomes a list of copies | Partly | Inventory rewrite, every UI/reader | High | Rejected (out of scope) |

**Rules under B1:**
- **Reroll per attribute:** `reroll(id, slot)` with slot 0 = base, 1–2 = boss. Each reroll draws a stat **not held by the other slots** (4 stats, 3 slots), then a value in its range. Price per slot = today's item reroll price (3–192 gems, −50 % with Masterwork II).
- **Merge** never touches extras. Merging only raises core stats, as today; verified, `merge()` changes `qty` and `merge` only.
- **Equip** is by ID: the enhanced stack is the equipped item. Stored copies at 30 % apply extras at 30 % as well (today's rule).
- **Evolution** never carries extras. The target keeps its own (or rolls fresh on creation).
- **Prestige:** extras and boss extras are run-layer and reset with the inventory (DEC, §2). The merge level persists through `merge_memory`.
- **Source flag:** a boss pickup must carry `enhanced: true` (new optional key on `pickups[]`, allowed by `drops_valid`), so a boss copy picked up later, from offline or after a reload, still enhances. Offline grants are never enhanced (they are copies of owned gear).
- **Second boss copy while already enhanced:** offer nothing new (plain copy). Alternative for §12: "Better roll replaces the lower slot automatically" (no UI, but still no duplication).
- **Exploits checked:**
  - discard and re-pick of a stack keeps the record: fine;
  - reroll then Prestige: rolls reset;
  - Auto-Merge: unchanged;
  - an offline claim after Prestige would grant **un-enhanced** copies (and is removed by the auto-claim decision);
  - no path creates a boss slot without a boss kill.

### 4.3 UI impact (432×960 / 540×960)

The item card grows from one attribute line to three, each with a small "Reroll · N gems" button.
- At 432 px the card width (≈ 400 px usable) fits "Crit chance +2.4 %" plus a 96 px button per line.
- Three lines add about 132 px to the item panel, which already scrolls.
- Boss slots need a marker: a gold-edged line with the boss icon (no text, no localization).
- New English keys: `ITEM_BOSS_BONUS` ("Boss bonus"), `REROLL_ATTRIBUTE` ("Reroll · %s"), `ITEM_ENHANCED_TAG` ("Enhanced").

---

## 5. Eight-stage combat

### 5.1 The Stage 4 boundary (MEASURED, 1,102 trials per mode, baseline builds unchanged)

Summer I normals change from `group` (assist within 110 units on hit) to:

| Summer I build | Today (group) | **individual** (proximity aggro only, today's Winter II rule) | passive (only the enemy you hit, Winter I rule) |
|---|---|---|---|
| L22 arrival: worst 3-spot / Yellow ×6 weapon / ×6 skill | 31 % / 0/3 / 0/3 | **51 % / 3/3 28 % / 0/3** | 54 % / 3/3 60 % / 3/3 28 % |
| L28 farmed: Yellow ×6 skill | 0/3 | **3/3 9 %** (Snowman) / 0/3 (normal outfit) | 3/3 47–50 % |
| L35 boss-level: Yellow ×6 skill | 0/3 | **3/3 36 %** | 3/3 49 % |
| L35 + P1 / P3: ×6 skill | 17 % / 23 % | **54 % / 57 %** | 66 % / 68 % |
| Sustained 6-actor farm, L28 (Yellow skill / Yellow weapon / Sunglasses skill), deaths per 10 min | 24 / 18 / 24 | **18 / 14 / 12** | 4 / 2 / 2 |
| Same, L35 | 22 / 10 / 20 | **16 / 10 / 6** | 0 / 0 / 2 |
| Sustained 3-actor farm at L22 arrival (Yellow), deaths per 10 min | 7 | 6 | 3 |
| Gray Cat, every build | — | **identical** | identical |

- The A ×1.9 ladder with Summer I kept at `group` (`lad_A19_s3group`) loses the ready-build ×6 skill spot 0/3 again, so **the boundary change, not the tiers, makes Summer I spots farmable**.
- **Recommendation: `individual` on Summer I** (it preserves Winter II's rule, so Stages 2–3 match).
- **Technical note for approval:** `individual` is proximity aggro (58 units), and spot actors stand 24 units apart. Walking into a spot therefore still wakes 2–3 of its actors at once; it is simultaneous but not coordinated. If the developer reads "no group aggression" as "only the enemy you engage", choose `passive`: sustained 6-actor deaths fall to 0–4 per 10 min.

### 5.2 Stages 4–8 without an attacker cap: candidate tuning (WHAT-IF on the A ×1.9 ladder)

Candidates (none approved; all on the A ×1.9 ladder, Summer I `individual`, seeds 1–3; `tune_A19.csv`, `tuning_summary.txt`):
- `v3_115`: skill variant ×1.15 instead of ×1.35.
- `stgNN`: every normal joining a fight after the first starts its attacks and skills NN/100 s × join order later. This is recovery time, not a cap: every attacker still attacks.
- `ld75` / `ld60`: Spring I/II normal damage ×0.75 / ×0.60.

The cells show 6-actor spots won, then the worst 6-actor spot (wins, HP left).

| Build | Base | v ×1.15 | stagger 0.5 s | stagger 1.0 s | v ×1.15 + stg 0.5 | Spring ×0.75 | ×0.75 + stg | Spring ×0.60 | ×0.60 + v + stg |
|---|---|---|---|---|---|---|---|---|---|
| S3 ready | 2/2 · 24 % | 29 % | 20 % | 14 % | 25 % | — | — | — | — |
| S4 ready | 2/2 · 48 % | 48 % | 56 % | 53 % | 56 % | — | — | — | — |
| S4 ready P1 | 2/2 · 67 % | 67 % | 72 % | 83 % | 72 % | — | — | — | — |
| S5 ready | **1/2 · Pumpkin skill 0/3** | **2/3 13 %** | 0/3 | 0/3 | 2/3 13 % | — | — | — | — |
| S5 ready P1 | 2/2 · 47 % | **68 %** | 48 % | 64 % | 67 % | — | — | — | — |
| S6 ready | 2/2 · 45 % | 45 % | 50 % | 42 % | 50 % | — | — | — | — |
| S7 ready | **0/2** | 0/2 | 0/2 | 0/2 | 0/2 | 0/2 | 1/2 | 1/2 | 1/2 |
| S7 ready P1 | 1/2 · Elf skill 0/3 | 1/2 | 1/2 | 1/2 | 1/2 | 1/2 | 1/2 (2/3 45 %) | **2/2 · 3/3 69 %** | **2/2 · 75 %** |
| S7 Obsidian ^50 | 0/2 | 0/2 | 0/2 | 1/2 | 0/2 | 1/2 | 1/2 | **2/2 · 50 %** | 2/2 · 55 % |
| S8 Obsidian ^100 (3-actor spots won) | 0/2 (20/22) | 21/22 | 20/22 | 20/22 | 21/22 | 21/22 | 21/22 | **0/2 (22/22)** | 22/22 |
| S8 ^100 P1 | 0/2 | 0/2 | 0/2 | 0/2 | 0/2 | 0/2 | 0/2 | 1/2 | 1/2 |

- **Bosses are identical in every column**: normal-enemy what-ifs never touch bosses.
- **Recommended numbers:**
  - skill variant **×1.15** (only Autumn I needs it, harmless elsewhere);
  - **Spring I/II normals ×0.60** (with H24 tiers; re-measure in B4, because the late-damage factor was measured on table A);
  - **no stagger**: under 1 s it barely moves outcomes, and on Summer I it makes things worse (longer fights).
- **Spring II 6-actor Sprout spots stay lethal under every candidate.** That is acceptable as "large spots are a meaningful risk" (the brief keeps them risky) but should be named in the Help text. The alternative would be a Spring II-only factor below ×0.60, not measured.
- **Spawn Amount** still doubles the attackers. Measured above, 6-actor spots are winnable from the ready build on Summer I–Autumn II, so **Spawn Amount becomes a risk/reward farming choice again**, with no cap.

### 5.3 Boss rushing after the redesign

- **First arrival:** every map's arrival build loses its boss on all three tables except ×2.55 (§3.3). That holds for the hand-play P0 arrivals on Summer II, Autumn I, Autumn II and Spring I. A P1 arrival with the previous tier was not re-run on the ladder. The previous audit's level-38 P1 Summer II arrival beat both bosses with an Iron Axe **^20 boss weapon** that no longer exists; on the ladder the same P1 build needs this map's Gold at ^10 (`N4_mid`: 43 % / 44 %).
- Bosses become beatable after **current-stage farming**: the mid build (this tier ^10) or ready build (^20), or by evolving.
- **Prestige still helps bosses more than normals.** At S3 ready, P1 moves Gray Cat 23 % → 63 %, but the ×6 spot only 23 % → 50 %. The proposed new normal-farming cards (§7) are the counterweight, and the existing boss cards are left unchanged (nerfs not approved).
- **Repeat runs:** level, coin upgrades, merge memory and cards all persist. Early bosses therefore become trivially fast on run 2+, which is the intended shorter replay. First-time discovery (fog, gates, first kills, Prestige discoveries) is untouched.

### 5.4 Final boss (Change 36)

- MIN wears Diamond Sword ^75 (today 423 damage from the weapon); REC wears Diamond ^100 (507). On the proposed ladder the final boss is fought with Obsidian, and Diamond becomes the Autumn I tier (52 base).
- Equivalent weapon damage under the recommended table: H24 Obsidian Sword ^39 ≈ today's MIN weapon (423) and ^57 ≈ REC (507), so the final boss becomes reachable at a lower Obsidian merge than its Diamond equivalent today (Obsidian ^100 = 713, +41 % over REC).
- **The Change 36 ladder must be rebuilt with Obsidian builds** and rerun in the weapon batch. It should need only new builds (its harness reads catalog stats; not verified). That rerun was not done in this audit (the harness has no in-memory tier patch).

---

## 6. Economy and pacing

### 6.1 Coins across Prestige (CODE + PROJECTED)

- **Finite Coin sink** if every Coin upgrade is permanent (catalog formulas, every scope, to cap): **54.5 M coins**.
  - By upgrade: Coin Amount 25.0 M and Enemy XP 20.9 M make up 84 %; Skill Drop 4.0 M; Loot 2.0 M; Supply Drop 2.0 M. Global upgrades total 0.12 M (respawn, movement and six cooldowns, under 19 K together).
  - By map: Winter I 0.50 M, Winter II 1.41 M, Summer I 1.34 M, Summer II 3.95 M, Autumn I 3.95 M, Autumn II 7.26 M, Spring I 9.51 M, Spring II 26.4 M.
  - Camps re-bought every run: **11.6 K** for all eight maps.
- **First-run income (PROJECTED):** the stage stays of §3.4 × measured kill rates × base coins × an average Coin Amount multiplier of ~4 ≈ **0.3 M coins** over a full first run.
  - So a first run can max Winter I–Summer I (3.25 M) only after several runs, and Summer II onward lasts many runs.
  - **Coins do not become useless and buy no skip.** Coins buy income, XP, drop and research upgrades, camps and supplies, never access, gear or levels.
  - Retained Coins make the start of run 2 very fast: Winter I types get maxed in minutes. That is the approved, intended shorter replay.
- **Late repeat runs:** once Winter I–Summer II are maxed, run coins only flow into later-map types and supplies. At 20+ runs the Spring II per-type tree (26 M) is still a sink. **No coin overflow problem projected within about 20 Prestiges.**

### 6.2 Switching enemy types (re-assessed)

- **Within a run:** unchanged. A first switch to an un-invested type still costs **−78 % to −86 % coins** and −20 % to −36 % XP at once (previous `baseline_economy_projection.txt`; same formulas and kill rates).
- **Across runs:** every type invested in any earlier run keeps its levels. From run 2 the switching cost exists only for types never invested in, and on the maps reached by run 3 it is gone for most players.
- **First-run pain remains**, inside the slowest XP stretch (Summer I–Autumn II, 100–300 min per map).
- **Candidate remedies (none applied, PROJECTED):**

| Remedy | First-run switch cost (Summer I Straw → Yellow) | Interaction with permanent upgrades | Verdict |
|---|---|---|---|
| None | −85 % | Cost disappears in later runs anyway | Acceptable if a first-run cost is wanted |
| **"Cheap first five"**: the first 5 levels of each per-type Coin Amount / XP / Loot cost ×0.25 | ≈ −60 % for about 5 min, parity in ~25 min (was 72) | Small permanent effect on the 54.5 M sink (−0.3 %) | **Recommended (cheap, no migration, no save change)** |
| Map floor 50 % (old R6, not approved) | −46 %, parity 60 min | With permanence it also compounds into later runs | Not needed now |
| Shared map-level upgrades | 0 % | Needs a schema migration and refunds | Not recommended |

### 6.3 Missions, offline, gems, XP

- **Missions:**
  - Rewards scale with `reward_stage`, which is kept by Prestige. A repeat-run Winter I mission pays "40 kills of the highest map reached". With Spring II reached and Coin Amount ^20 bought there, that is about **7,500 coins** per kill mission while Winter I kills pay 1–11 coins. With Coins now kept, missions would become the dominant early repeat-run income.
  - **Recommend `reward_stage = unlocked_stage` of the current run** (DEC). It is one line, and current saves keep the field.
- **Offline:** 120 coins/h base (+60 per level, Coin-bought and already kept). No change. Offline gear stays copies of owned gear; see the hint in §8.
- **Gems:**
  - Demand rises slightly: per-attribute rerolls, up to 3 per weapon per tier.
  - Supply is unchanged: 5 % per kill × 1 gem, missions, offline 2/h.
  - Typical spend per run on rerolls: 3+6+12+24+48+96+192 = 381 gems for one reroll of each tier's slot, which fits in about one tier's gem income. Watch it, no change.
- **XP:** level is already kept. Kept Enemy-XP upgrades (+10 %/level, up to +200 % per type) shorten repeat runs further.
  - First-run mid-game is still the slowest stretch: about 4–5 h on Summer II–Autumn II (PROJECTED, §3.4).
  - The previous R7 (XP ×1.5 on maps 2–5) is still unmeasured. **Do not tune XP in the same batch as tiers**, because faster levels feed boss rushing.
- **Time between meaningful upgrades (PROJECTED, first run, base loot, one focused spot):**
  - first drop of the stage tier: 1–2 min after arrival (an upgrade over the old tier until ^45);
  - ^10: 14–34 min;
  - ^20: 28–60 min;
  - evolution: 28–69 min.
  - On Summer II–Autumn II the Coin Amount ladder gives a new level every 30–145 base kills (2–11 min). So a player gets a visible step at least every ~10 min. This is projected, not observed retention.

---

## 7. Prestige opportunities and cards

### 7.1 Verified inventory by the map where the requirement is performed (CODE)

Full table: `prestige_inventory.md`. Per map (multi-map objectives counted on each):

| Map | Boss objectives | Normal-farming objectives | Exploration | Total stage-specific |
|---|---|---|---|---|
| Winter I | Hunter I, Trophy I | Expedition I, Collection I | Regional I | 5 |
| Winter II | Challenge I, Trophy I | **none** | Regional I | 3 |
| Summer I | Hunter II, Trophy II | Expedition II, Collection II | Regional II | 5 |
| Summer II | Challenge II, Trophy II | **none** | Regional II | 3 |
| Autumn I | Trophy III | **none** | **none** | **1** |
| Autumn II | Hunter III, Challenge III, Trophy III | **none** | **none** | 3 |
| Spring I | **none** | Expedition III, Collection III | Regional III | 3 |
| Spring II | **none** | **none** | Regional III | **1** |
| General (any map) | Specialist II/III partly | Specialist I, Offering I–III | — | Masterwork I–III, Arsenal I–III, Offering I–III, Specialist I–III, Offline I–III (15) |

**Recurrence matrix (path × map, today):** Hunter 1·3·6; Challenge 2·4·6; Trophy 1–2·3–4·5–6; Expedition 1·3·7; Collection 1·3·7; Regional 1–2·3–4·7–8; Masterwork, Arsenal, Offering, Specialist and Offline are general.

**Cards:** 11 paths × 3 = 33 cards; a path offers only its own unowned cards, one per ready opportunity (`awardable_ids`). When a path's 3 cards are owned, its remaining opportunities award nothing (`NO_CARD_AVAILABLE`).

**Effect balance today:**
- Boss-only damage: Hunter I +25 %, Trophy II +20 %, Boss Specialist +10 %, Challenge set +10 % (max +65 %). Boss guard: Hunter II −20 % taken.
- Normal-only: Expedition I +20 % damage, and **no defensive normal card**.
- Generic: Arsenal +20 % HP, +15 % damage, −10 % taken.

### 7.2 Designs compared

| | **A: Map ladders (recommended)** | B: Card ranks | C: Season paths |
|---|---|---|---|
| Idea | Expedition and Collection recur on **every** map with that map's enemies and outfits; boss and exploration paths gain their missing seasons | Keep 33 cards; owning a card again raises its rank I→II→III (×1.6, ×2.0) | Four new season paths (Winter, Summer, Autumn, Spring), each 3 objectives (normals, outfits, bosses) and 3 season cards |
| Opportunities | 33 → **48** (+15) | 33 → 48 (+15, same as A) | 33 → 45 (+12) |
| Cards | 33 → **48** (+15 new effects) | 33 (ranks, +0 effects) | 33 → 45 (+12) |
| Map coverage, normal farming | **every map ≥ 2** | every map ≥ 2 | every season |
| Strategic novelty | High: new effects target group fights, recovery and gear | Low: blind stacking of existing +% | Medium |
| Boss-preference risk | Lowered (11 of 15 new cards serve normal farming or survival) | Raises it (boss cards rank up too) | Neutral |
| Localization | 15 opportunity names + 15 descriptions + 15 card names + 15 card texts ≈ 60 keys | ≈ 32 keys + rank strings | ≈ 60 keys |
| Save | Additive ids | Owned cards need ranks (`owned_cards` → counts) | Additive ids |

### 7.3 Design A in detail (counts and requirements are proposals; numbers sized to 20–45 min of that map's measured kill rate)

**New opportunities (+15):**

| Id (new) | Map | Requirement (real content) | Discovery |
|---|---|---|---|
| expedition_o4 | Winter II | Defeat 50 each of Wolf Hood, Calico Cat Hood, Golden Crown, Reindeer Antlers, Santa Hat, Space Helmet (300) | 10 Wolf Hoods |
| expedition_o5 | Summer II | 60 each of Cowboy Bandana, Duck Swim Ring, Rainbow Clown, Red Cap Swimmer, Snorkeler, Straw Hat Swimmer (360) | 10 Cowboy Bandanas |
| expedition_o6 | Autumn I | 120 each of Black Cap, Mushroom Cap, Pumpkin Head (360) | 10 Black Caps |
| expedition_o7 | Autumn II | 100 each of Horned Hood, Orange Screen Helmet, Television Head, Top Hat (400) | 10 Horned Hoods |
| expedition_o8 | Spring II | 60 each of the six Spring II types (360) | 10 Flower Crowns |
| collection_o4 | Winter II | Hand in 15 of each of three Winter II outfits (Santa, Reindeer, Space Helmet) | reach Winter II |
| collection_o5 | Summer II | Hand in 25 each of Snorkeler, Red Cap Swimmer, Straw Hat Swimmer outfits | reach Summer II |
| collection_o6 | Autumn I | Hand in 30 each of Autumn I's three outfits | reach Autumn I |
| collection_o7 | Autumn II | Hand in 30 each of TV Head, Top Hat, Orange Screen Helmet outfits | reach Autumn II |
| collection_o8 | Spring II | Hand in 40 each of Pink Cap, Plain, Sprout outfits | reach Spring II |
| hunter_o4 | Spring I | Defeat the Bee and the Orange Tabby Cat 10 times each | defeat the Bee |
| challenge_o4 | Spring II | Defeat the Red Panda without using a supply | defeat the Red Panda |
| trophy_o4 | Spring I–II | Bee, Orange Tabby Cat, Red Panda, Sunflower once each | defeat the Bee |
| regional_o4 | Autumn I–II | 90 % explored, all camps, all four bosses (run) | reach Autumn II |
| masterwork_o4 | Spring I–II | Merge an Obsidian weapon to ^100 | own Obsidian |

**Resulting per-map counts (existing + new):** Winter I 5, Winter II **6** (+3), Summer I 5, Summer II **6** (+3), Autumn I **5** (+4), Autumn II **6** (+3), Spring I **5** (+2), Spring II **6** (+5). Every map gets ≥ 2 normal-farming and ≥ 1 boss objective.

**Rules changed with it:**
- **Conflict (b):** Arsenal and Masterwork drop weapon thresholds above the new cap.
  - Arsenal I: one weapon at ^20 and one outfit at ^50.
  - Arsenal II: 3 weapons at ^20 and 3 outfits at ^50.
  - Arsenal III: 3 weapons of tier ≥ 2 at ^20, plus 3 outfits.
  - Masterwork I–III count outfits, skills or Obsidian.
- The UI stage grouping becomes catalog data (`stage` field per opportunity), which fixes D5.
- Id parsing (`int(id.right(1))`) works up to o9; keep ids within o1–o9 per path or switch to a catalog `index`.

**New cards (+15; no new currency; values are starting points for the Prestige batch's measurement):**

| Path | Card | Effect | Focus |
|---|---|---|---|
| Expedition | c4 Crowd Guard | −4 % damage taken per normal enemy attacking you beyond the first (max −20 %) | Normal, group |
| | c5 Second Wind | First drop below 30 % HP heals 25 % max HP; once per 90 s | Survival |
| | c6 Cleave | Basic attacks deal 30 % to other enemies within 32 units | Normal, throughput |
| | c7 Broken Rally | Enemies joining a group fight start attacking 0.5 s later | Normal, group (the "stagger" what-if, §5.2) |
| | c8 Field Rest | Out-of-combat recovery ×3 outside camps (1 % → 3 %/s) | Recovery between pulls |
| Collection | c4 Twin Find | Normal gear drops have a 10 % chance to be 2 copies | Gear |
| | c5 Thrifty Evolution | Evolution needs 8 spare copies instead of 10 | Gear |
| | c6 Steady Supplies | Supply cooldowns −15 % | Survival |
| | c7 Precise Reroll | Rerolling an attribute never returns the same stat; reroll −25 % | Gear |
| | c8 Treasure Sense | Boss-enhanced attributes roll in the upper half of their range | Gear (boss) |
| Hunter | c4 Boss Breaker | Boss telegraphs +0.3 s; boss heals −25 % | Boss, skill-based |
| Challenge | c4 Last Stand | Below 25 % HP: +20 % attack speed | Survival |
| Trophy | c4 Champion's Spoils | A boss's first defeat each run rolls its loot twice | Boss, gear |
| Regional | c4 Veteran Traveler | +25 % XP from normal enemies on maps below your highest unlocked map | Repeat-run pacing |
| Masterwork | c4 Obsidian Temper | Obsidian merge gain +15 % | Late gear |

New combos (optional, from new cards only): "Pack Breaker" (Crowd Guard + Broken Rally + Cleave): −5 % damage taken from normals. "Prospector" (Twin Find + Thrifty Evolution + Precise Reroll): +1 % gear chance.

**Fairness and saturation:**
- With 48 opportunities and 48 cards, every opportunity can award a card, so none is dead.
- Selection logic is unchanged: the same path, unowned cards, and choices shrink 3 → 2 → 1 within one batch.
- Cards owned today keep their ids and effects. New cards simply join their paths.
- A player holding all 3 Expedition cards gets new Expedition objectives offering only the 5 new cards. That is intended progression into the bigger pool.
- **Overflow rule (recommended for robustness):** if a path has no unowned card, offer up to 3 unowned cards from any path, so an opportunity never becomes dead again after future content.

### 7.4 Does the expansion amplify boss preference? (PROJECTED)

- **Today:** 6 of 9 discoverable-early opportunities are boss paths (Hunter, Challenge, Trophy), and the first boss alone makes three ready.
- **Design A:** the first map offers Expedition I and Collection I beside them, and every later map adds two normal objectives. Normal-farming objectives go from 6 to 16 (of 48); boss objectives from 9 to 12.
- 11 of the 15 new cards improve normal fights, recovery or gear, against 4 boss-leaning ones.
- Measured in the Prestige batch: not done here. Acceptance tests are in §11 (B5).

---

## 8. Contextual discoverability and copy

All hints follow the existing one-time notice pattern:
- a `tutorial.seen` latch, kept by Prestige and cleared by Hard Reset;
- Playbook 18.6–18.8: Basic/None mode, or after Guided ends; never over a modal, card choice or Prestige; never pausing; never naming an undiscovered enemy, spot or item;
- at most 3 shows, retired by the demonstrated action;
- one hint at a time (the existing guide arbitration).

| # | Trigger (state-driven) | Placement and English text (proposed key) | Route | Retire |
|---|---|---|---|---|
| M1 | World panel open on map *s*, `map_detail:s` = 0, ≥ 1 discovered spot on *s* | Replaces `MAP_LEGEND` under the map: **"Enemies and bosses you have found can be marked here. Buy Map Detail in Map upgrades below — it stays after Prestige."** (`MAP_MARKERS_HINT`) + button **"Map upgrades"** (`MAP_UPGRADES_JUMP`) | Scrolls to `SECTION_MAP_UPGRADES` | Rank ≥ 1 on that map; first purchase ever; or 3 shows |
| M2 | Map Detail card benefit | **"Next: markers for enemies and bosses you have found"** / **"Next: enemy names; tap a marker to inspect it"** / **"Next: loadout icons (weapon, outfit, skill)"** (`MAP_DETAIL_NEXT_1..3`) | — | Permanent copy |
| M3 | Main objective 6 | **"Upgrade Map Detail (World → Map upgrades)"** (edit `MAIN_6`) | Follow points at World | Permanent |
| O1 | Welcome-back panel open; `offline_weapon` or `offline_outfit` = 0; owns ≥ 1 weapon or outfit; Gems ≥ the cheaper missing unlock (18.7) | Above Claim: **"While you are away you can also receive copies of weapons and outfits you already own. Unlock it in Upgrades → Offline."** (`OFFLINE_GEAR_HINT`) + **"Offline upgrades"** (`OFFLINE_UPGRADES_JUMP`): claims, then opens the Offline tab | `player_tab = 4` | Both unlocked; or 3 shows |
| O2 | Offline unlock cards | **"Off → On · copies of gear you own, about 1 per hour each"** (`OFFLINE_GEAR_BENEFIT`) | — | Permanent |
| E1 | First time an item reaches ^20 with a next tier | Toast: **"%s is fully merged. Collect 10 more copies to evolve it into %s."** (`EVOLVE_READY_HINT`) | Opens the item | Once per profile |

**Prestige copy rewrite (approved rules):**
- `KEEP_LINE_UPGRADES` → **"Every upgrade you bought, with Coins or Gems (camp radius returns when you rebuy the camp)"**
- `KEEP_LINE_LEVEL` (unchanged text)
- New `KEEP_LINE_COINS` **"Your Coins: %s"**
- New `KEEP_LINE_MERGES` **"Merge levels of every weapon, outfit and skill — restored when you find that item again"**
- `RESET_LINE_ITEMS` → **"Every item you carry: weapons, outfits, skills and supplies (your merge levels stay)"**
- `RESET_LINE_MAPS` → **"Map access (back to Winter I) and owned camps. Explored areas stay visible."**
- `RESET_LINE_UPGRADES`: **delete**
- `RESET_LINE_CHALLENGES` → **"Unfinished opportunities and missions (finished missions are paid first)"**
- `RESET_LINE_COINS`: **delete**
- `RESET_LINE_SUPPLY_MASTERY` (unchanged unless the supply decision changes)
- `PRESTIGE_KEEP` / `PRESTIGE_RESET` (overview): rewrite to the same lists.
- Retire the dead `PRESTIGE_CONFIRM`, `PRESTIGE_CONFIRM_NEW`, `PRESTIGE_CONFIRM_SUMMARY` and `RESET_LINE_LEVEL`.

**Localization estimate:**
- Hints: 9 new keys + 1 edit.
- Prestige copy: 2 new keys, 6 edits, 2 deletions (4 dead keys retired).
- Boss items: 3 keys.
- Design A: about 60 keys.
- **≈ 75 new/edited English keys × 19 languages** through the established ChatGPT handoff. Until those arrive, every new line must fall back to English or stay hidden (Playbook 132.4–132.5). Edited keys change meaning in 19 catalogs and must be re-translated, not left stale.
- Width: the longest proposed line (M1) is about 120 characters. In German or Russian it needs 3 lines at 432 px; the World panel caption area scrolls, so that is acceptable. The Prestige confirmation body already scrolls (`prestige_confirm.gd _layout`).

---

## 9. Risks and save migration

**Schema 9 migration (one function, like `migrate_change8`, run in `normalize_snapshot` before `valid_snapshot`):**

1. **`merge_memory`** = for each item: `max(items[id].merge, mastery.merge[id])`.
   - `mastery.merge` already records the best merge per ID ever, across past Prestiges.
   - **DEC:** seeding from it **restores** merge levels lost in earlier Prestiges. That is generous and matches the new rule's spirit. Seeding from `items` only is conservative.
2. **Weapons above the new cap** (^21–^100 on non-Obsidian ids): keep the level and its effect. Validation allows up to 100 for every weapon (`weapon_cap` stays the validation bound). New merges stop at ^20. Evolution is allowed (merge ≥ 20).
3. **Old-stat weapons:** the re-based stats shrink Gold and up a lot. A current Spring I player's Gold Axe ^100 deals 159 today and would deal 66 under ×1.9.
   - **Recommended:** each owned weapon of tier ≥ 4 becomes a **legacy-stat copy** (`<id>_legacy`, catalog flag `legacy: true`, the old `normal`/`merge_gain`, not droppable, no evolution, mergeable only with itself).
   - It keeps exact power until the next Prestige, which removes it with the inventory, while `merge_memory` keeps the new id's level at 0.
   - Mapping today's ladder onto the new one (e.g. Diamond → Obsidian) is rejected: it hands out gear several stages ahead.
   - The catalog's existing `legacy_items` remap mechanism and `legacy` flag already exist (Change 7).
4. **Existing extras** keep slot 0. `boss_extras` = [] (old boss drops are not retroactively enhanced; their bonus was the +1 tier).
5. **Cards and opportunities:**
   - all 33 card ids, combos and consumed ids keep their meaning;
   - new ids are additive (`valid_snapshot` already accepts any catalog id);
   - Arsenal and Masterwork in progress may become ready on load, which is generous and acceptable;
   - a `prestige_batch` open during the update stays valid (same ids).
6. **Coin upgrades already bought** this run simply stop resetting. Coins on hand are kept from the next Prestige on.
7. **Map Mastery:**
   - the "forge" and "collect" contents per map change because each map drops different weapons;
   - completed categories stay latched (`mastery.done`);
   - in-progress ones change target, so note it in the change log.
8. **Stage-cleared saves on Stage 3:** Summer I enemies in `stage_worlds` keep `aggro` booleans. On load the mode comes from the catalog, so there is no migration.
9. **Downgrade** (an older build opening a schema-9 save):
   - `valid_snapshot` requires `schema == 8`, so an old build rejects the save and falls back to the backup or a new profile. **This is data loss on rollback.**
   - Mitigation: write the schema-9 save **beside** a preserved schema-8 backup on first migration, and keep the old build's backup slot untouched. Note it in the release notes.
10. **Untouched-player backups (Rule 1):** the migration must be tested on copies of real saves: fresh, mid Summer I, Spring with Prestiges, and Prestige batch open.

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Merge > cap rejected → profile reset | Certain without the fix | Severe | Validation bound stays 100 |
| Legacy weapons feel like a nerf at the next Prestige | Medium | Medium | Confirmation names them: "Legacy weapons (old stats) are retired" |
| Offline-pending duplication | Certain today with retained merges | Medium | Auto-claim inside the transaction |
| Missions overpay on repeat runs | High | Medium (economy) | `reward_stage` per run |
| Final-boss readiness shifts | Certain (new weapons) | High | Rebuild the Change 36 ladder in B2 |
| Prestige card text in 19 languages | Certain | Medium | English fallback, hidden until translated |
| Auto Evolution never fires | Certain with cap ^100 | Medium | Cap ^20 |

---

## 10. Validation record

| Item | Detail |
|---|---|
| Baseline | `python tools/player_feedback_audit_run.py --crosscheck`: PASS (§1.1), log `baseline_rerun.log` |
| What-if harness | `tests/tmp/c49/c49_audit.gd` (git-ignored; evidence copy `c49_audit.gd.txt`). It is the preserved harness plus three things: `--patch=` (in-memory catalog changes: `s3aggro_<mode>`, `s2aggro_<mode>`, `tiers_<CUR\|A19\|B22\|H24\|H28>`), a build `extras` field (rolled attributes) and the `staggerNN` what-if. The preserved `tests/player_feedback_audit.gd` is untouched. |
| Prestige probe | `c49_prestige_diff.gd` (real Prestige transaction, field classification), log `prestige_diff.log` |
| Builds | `builds_ladder.json` (40 builds), `builds_s3control.json` (53 baseline builds, unchanged), `builds_tuning.json` (89 what-if builds). Generators: `gen_builds.py`, `gen_whatif.py` |
| Batches (seeds 1–3; farms seed 1, 5 min) | s3ctl_ind / s3ctl_pas: 1,102 rows each (1 invalid each: the known "Focus a boss" row). lad_CUR / lad_A19 / lad_B22: 2,346 rows each, 0 invalid. lad_A19_s3group: 290. tune_A19: 5,523 rows (89 what-if builds), 0 invalid. lad_H24 / lad_H28: Stage 6–8 builds only, 0 invalid. No SCRIPT ERROR in any log. |
| Profiles | `probe-audit49`, `probe-audit49p`, `--no-autosave`, isolated |
| Projections | `copies_model.py` (Monte Carlo, seed 49), `coin_sink.py`, `prestige_inventory.py` |
| Not measured / limits | Natural or replayable policies (the pacing bot is stale, so only fixtures). Change 36 final-boss ladder on Obsidian. Prestige card effects (none exist in code). Gem income. Device feel at 432/540 px. Spot fights block respawns; farms use real respawns. The ladder builds swap weapons on the baseline builds, so levels, outfits and supplies are the old fixtures' values. 3/3 means reliable under the attentive policy, not a player win rate. |

---

## 11. Recommended implementation batches (not implemented)

| Batch | Scope | Depends on | Acceptance (measurable) | Rollback |
|---|---|---|---|---|
| **B0 Harness** | Promote the what-if harness (`--patch`, `extras`, stagger) into `tests/` as a non-gating tool. Commit the `.gd.uid`. Store this audit's CSVs as the new reference. | — | The preserved baseline still passes field for field; `lad_A19` reproduces `ladder_A19.csv` | Revert the tool files |
| **B1 Save and Prestige foundation** | Schema 9: `merge_memory` (+ migration from items/mastery), weapon validation bound, Prestige keeps Coins and every upgrade, auto-claim missions and offline pending, `main_ready` kept, `reward_stage` per run (if approved), Prestige copy keys (English) | B0 | Prestige diff probe: every field matches §2. Interrupted-reset test (kill before the write / write blocked) shows the old or new state only. Hard Reset wipes `merge_memory`. Real-save copies load (4 fixtures). Downgrade keeps the schema-8 backup. | Revert. Saves migrated to 9 restore from the kept schema-8 backup. |
| **B2 Weapon ladder** | Catalog: loot tiers per stage, tier stats (H24), weapon caps ^20 / Obsidian ^100, evolution 10 spares, Snowman guarantee → Wood Axe; legacy-stat copies of tier ≥ 4 weapons; Arsenal/Masterwork thresholds; Auto-Merge stops at the cap | B1 | `lad_<pick>` reproduces this report's cells. Change 36 ladder rebuilt with Obsidian: MIN/REC win 5/5. Copy probe: 31 copies → evolve; Auto Evolution fires; evolution keeps the target's memory; the source keeps ^20 + 1 copy. | Catalog revert. Legacy ids stay valid. |
| **B3 Boss-enhanced items** | `boss_extras`, pickup `enhanced`, per-slot reroll and UI | B2 | Boss drop → 3 attributes; reroll changes one slot and never duplicates a stat; merge leaves extras alone; Prestige clears them; 432/540 captures | Feature off: `boss_extras` ignored |
| **B4 Combat** | Summer I `individual` (or passive); Stage 4+ tuning (skill variant ×1.15; Spring normals ×0.60) | B2 | s3 control and tuning cells reproduce; bosses identical to B2; sustained 6-actor farm deaths ≤ the measured value | Catalog revert |
| **B5 Prestige expansion** | 15 opportunities, 15 cards, stage field, overflow rule, Trophy grouping fix | B1, B2 | Every map has ≥ 2 normal and ≥ 1 boss objective; no dead opportunity in a 48-card walk; owned-card saves unchanged; card effects measured on the ladder | Remove new ids (unowned) |
| **B6 UX** | M1–M3, O1–O2, E1; Prestige confirmation; GDD/C&B doc corrections D1–D7 | B1–B5 | Hint probe: shows, does not pause, routes, retires, never over a modal; 432/540 captures | Revert |
| **B7 Localization** | ≈ 75 keys × 19 languages via handoff | B6 | Validator 0 missing in 20 catalogs; sweep at 432 px | Hidden-until-translated |
| **B8 Re-validation** | Full matrix, Change 36, `change_9_balance`, suite, Android feel on Summer I/II spots | all | Report | — |

---

## 12. Developer approval checklist (genuinely open choices only)

- [ ] **Tier stats:** ×1.9 per tier Wood→Emerald (4.0 / 7.6 / 14.44 / 27.44 / 52.13 / 99.04 sword base), Obsidian ×2.4 = 237.7 ("H24", recommended), or ×2.8 = 277.3 ("H28")? Axe = 0.8× damage + 3.0× HP; merge gain 2 % of base. Accept that **Spring II bosses at Obsidian ^100 still need one Prestige** (Sunflower 0/3 at P0 under H24 and H28, 3/3 at P1; today it is also 0/3 at P0)?
- [ ] **Merge cap rule:** non-final weapons cap at ^20 (= evolution requirement), Obsidian ^100. *(Recommended; resolves Auto Evolution.)*
- [ ] **Evolution:** ^20 + 10 spares (31 copies). Repeat evolutions also 10, or 20?
- [ ] **Summer I aggro:** `individual` (recommended, Winter II rule) or `passive`?
- [ ] **Stage 4+ tuning:** skill variant ×1.35 → ×1.15 (helps Autumn I ×6 skill spots; no boss effect)? Spring I/II normal damage ×0.60 (needed for Spring 6-actor spots)? Staggered joining: not recommended.
- [ ] **Boss extras:** live ranges (≈ +5–8 % dps, recommended), or upper-half "boss band"? Second boss copy: plain copy (recommended) or auto-keep the better roll?
- [ ] **Extras through Prestige:** reset with inventory (recommended) or kept with merge memory?
- [ ] **Supply Mastery through Prestige:** reset (recommended, current) or kept?
- [ ] **Finished missions, earned main objectives and pending offline earnings at reset:** auto-claim inside the transaction (recommended)?
- [ ] **Mission pricing:** current-run `unlocked_stage` (recommended) or kept `reward_stage`?
- [ ] **Merge memory seed:** from current items only, or also from Map Mastery records (restores levels lost in past Prestiges)?
- [ ] **Old high-tier weapons:** legacy-stat copies until the next Prestige (recommended) or straight re-base?
- [ ] **Final boss loot:** boss-enhanced Obsidian Sword (recommended), or unchanged Emerald?
- [ ] **Switching cost:** add "cheap first five" levels (recommended) or leave as is?
- [ ] **Prestige expansion:** Design A (15 opportunities, 15 cards, recommended), B or C; and the overflow rule?
- [ ] **Hints and copy:** approve M1–M3, O1–O2, E1 and the Prestige lines; accept ≈ 75 keys for the 19-language handoff.
