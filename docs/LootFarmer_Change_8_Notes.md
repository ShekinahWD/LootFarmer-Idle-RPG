# Change 8: gameplay, UI, economy, fog, and the eight-map environment pass

Baseline: the committed Change 7 tree (f397381). Brief: `docs/LootFarmer_Change_8_Package/LootFarmer_Change_8_Instructions.md`. The save schema stays at 7, and the fog layout revision stays at 2, so explored maps are kept. New state fields are derived when an older save loads (see "Saves" below).

## Phase A: what changed

| § | Item | Implementation |
|---|---|---|
| 2.1 | Camps open on approach | Opens when the player walks in by hand within `camp_open_radius` (64, an exported value on the game UI) of a sighted camp. It opens once per entry; leaving and coming back re-arms it. Respawn, teleport, load and auto-farm never trigger it. It waits until no panel, confirmation, pause, guide chooser, prestige choice or combat is in front. Travel rules are unchanged (`travel_reason`). |
| 2.2 | Navigation | The nav button `Stats` is replaced by `Upgrades`, which opens the same Player Upgrades panel as before. Stats is the first button in Settings. The toggle-close rule still applies. |
| 2.3 | Stats | Sectioned cards with aligned name/value rows: Character, Offense (attacks per second plus bonus %), Defense and recovery (damage reduction %), Boosts, Where your stats come from, Time played. |
| 2.4 | Prestige banner | Centred horizontally at the top of the safe area (`banner_max_width`, `banner_top_gap` exports). The queue is unchanged. |
| 2.5 | HP numbers | Player, enemy and boss bars show `hp/max` inside the bar. Numbers above 1,000 are abbreviated (1.2K) and HP is rounded up. The text is laid out at 4× and scaled to 0.25 so it stays sharp under camera zoom. `hp_bar_width`, `hp_bar_height` and `hp_text_scale` are exported on the actor. |
| 2.6 | Pinned equipment | The dock gear heading shows "Equipped [weapon] [outfit]". The Inventory panel has a non-scrolling Equipped row (new `Sheet/…/Pinned` container) above its filter tabs. Both only display the equipped ids. |
| 2.7 | Comparison | The EQUIPPED card is on top (an empty slot shows a placeholder). The SELECTED card sits below it, next to the pinned Equip button. Each stat row shows a ▲/▼ delta; a "—" row shows a stat that only the equipped item provides. A verdict (Upgrade / Downgrade / Trade-off) is followed by the full effect. The ◀ ▶ arrows are kept. There is no Sell. |
| 3.1–3.3 | Outfits and skills: growth from copies | `next` is cleared for outfits and skills, so neither evolves. Weapons and supplies keep ^100 and evolution. The 324 outfit/skill tiers that no enemy drops are marked `legacy`, so saves that own them keep them. |
| 3.4 | Boss weapons | Each boss carries and drops the weapon one tier above its stage's normal enemies, in its own family. Winter I Snowman: Stone Axe. Winter II Cyan Robot: Stone Sword. Summer I Gray Cat: Iron Axe. Summer II bosses: Iron Sword. Autumn I/II bosses: Gold Sword. Spring I bosses: Diamond Axe. Spring II bosses: Diamond Sword. Enemy damage still comes from `tools/tune_campaign.py`, so nothing is counted twice. |
| 3.5 | Normal gear drops | 5% per carried item for every normal enemy on every stage, rolled independently. Before: 10% in Winter I, falling to 3% in Spring II. Bosses stay at 30%. |
| 3.6 | Loot Chance | +0.5 points per level, 15 levels: 5% → 12.5% per item (bosses 30% → 37.5%). Price 20 × 1.35^level × 2^(stage−1) coins, so later enemy types cost more. Labels, math and the probe use `catalog.upgrades.loot.effect`. |
| 3.7 | Skill upgrades | `skills_seen` records skill families ever obtained; prestige keeps it and Hard Reset clears it. A skill's cooldown upgrade, and the slot and auto-cast upgrades (which need at least one skill), stay hidden and unbuyable until then. The first copy shows "New upgrades unlocked: Frost (Player Upgrades)"; duplicates show nothing. |
| 4.1 | Prestige entry | Opens after the first boss, the Winter I Snowman, is defeated (its lifetime `group_kills`, which survive prestige; `progression.prestige_unlock_boss`). Regular kills do not open it. A reset needs a ready opportunity that can still award a card (`awardable_ids`), and the card is chosen during the reset. Removed: `progression.prestige_gate_stage`. Before the Snowman falls the button reads "Prestige · Defeat the Snowman". *Corrected after Phase C: the first build of Change 8 opened Prestige on the first regular kill, which was wrong.* |
| 4.2 | Follow tracker | A lower-left HUD backing shows the path icon, the opportunity name and one line: "Step 2/3 — Hunt Red Scarf: 12/100" (or "Defeat Snowman: 3/10", or "Ready! Open Prestige…"). Tapping it opens Prestige. It hides when unfollowed or consumed. Following a ready opportunity is still refused (Change 7 rule). |
| 5.1 | Reveal vs vision | Permanent reveal is 48 (Change 7: 144). Vision is `vision_factor` 2.0 × reveal = 96, is never saved, is drawn as a lighter veil (`vision_color`), and allows seeing, targeting and loot pickup. Reveal-radius upgrades and cards scale both. |
| 5.2 | Discoverability | Camps are sighted from `camp_sight_radius` 400. They are stored per stage in `camps_known`, show a "Camp spotted!" notice, and reveal a 40-unit footprint so the camp shows through fog. That radius was chosen from the authored layout: every camp is within 400 of a farm spot or of its gate boss court (the largest gap is 533 to a farm spot, 243 to a boss: Spring II camp 3). Camp unlock/select requires a sighted camp. |
| 5.3/5.4 | Map markers | One marker per discovered spot (`discovered_spots`, keyed type:variant). A spot is found when its home cell is explored, when a living actor of that spot stands on an explored cell, or when the player kills one of its enemies. Sight alone never finds a spot. Rank 1 shows generic markers, rank 2 the enemy portrait per spot, rank 3 loadout badges (weapon bottom-right, skill top-right, outfit = portrait; weapon-only spots show the plain body). Map taps only consider drawn markers. Boss markers appear only while the boss is alive. Focus needs the spot found. The World map is now 420 tall (was 300). |
| 6 | Prices | See the table below. Special-case code for slot prices was replaced by data (`step`, `sequence`, `floor`). |

## Merge cap and curve (§3.3)

Effective merge levels = m for m ≤ 100, then 100 + 100·ln(1 + (m−100)/100). Stat = base + per-merge gain × effective levels. At the cap, the existing 0.05% per spare copy stock bonus applies. All coefficients are in `catalog.progression.merge` (`copy_cap` 500, `linear_levels` 100, `tail_scale` 100, `stock_bonus_per_copy`).

| Copies merged | Effective levels | T1 outfit HP (base 8) | T2 outfit HP (base 20.4) | Heal power (base 10) |
|---:|---:|---:|---:|---:|
| 10 | 10 | 9.6 | 24.5 | 12.0 |
| 50 | 50 | 16.0 | 40.8 | 20.0 |
| 100 | 100 | 24.0 | 61.2 | 30.0 |
| 200 | 169 | 35.1 | 89.5 | 43.9 |
| 500 (cap) | 261 | 49.8 | 126.9 | 62.2 |

**Why 500:** focused farming of one type yields about 14–84 copies of its outfit per hour (6–15 kills/min, 5–12.5% per item, 3 of 4 spots carry it). Offline adds up to 6 per hour across owned outfits, capped at 48 h. A typical run therefore merges 30–250 copies; ^500 rewards long or idle-heavy runs. ^1000 would add only 26% more power (7.6× base vs 6.2×) for twice the copies. **Power check:** a ^500 Tier 1 outfit (49.8 HP) stays below a ^100 Tier 2 outfit (61.2 HP), so later stages' drops still matter.

**Balance note:** a Stone Axe from the Snowman (8.16 damage + 30.6 HP) is roughly a +45% damage step over a Wood Sword at level 10, available from a 30% boss drop in Winter I. The brief asks for this; judge it on device.

## Price formulas (§6)

The Gem first prices of Player Upgrades are roughly halved. Coin factor is 2^(stage−1) for type/stage/camp scopes. Representative levels:

| Upgrade | Currency | Formula | Prices (level: cost) | Before |
|---|---|---|---|---|
| Inventory slots | gems | 5 + level (+1 every purchase) | 1:5, 2:6, 3:7, 5:9, 10:14 | 10 for 10 purchases, then +5 |
| Supply slots | gems | 4 + 4·level | 1:4, 2:8, 3:12, 5:20, 10:40 | 8 + 4·level |
| Supply auto-merge | gems | 10 | 10 | 20 |
| Supply merge speed | gems | 12·1.7^level | 1:12, 2:21, 3:35, 5:101, 9:838 | 25·1.7^level |
| Auto-use | gems | 6·2.6^level | 6, 16, 41 | 10·2.4^level |
| Gem chance / gem amount | gems | list | 25, 40, 58, 80, 105 … 470 / 320 | 50, 75, 105 … |
| Boss gem chance | gems | list | 50, 80, 120, 170 … 530 | 100 … 1000 |
| Boss gem amount | gems | list | 25, 40, 58 … 320 | 50 … 500 |
| Skill slots | gems | list | 50, 160 | 100, 300 |
| Skill auto-cast 1/2/3 | gems | flat | 38 / 75 / 150 | 75 / 150 / 300 |
| Mission slots | gems | list | 25, 50, 90, 140, 200 | 50 … 400 |
| Mission auto-claim | gems | flat | 75 | 150 |
| Offline cap | gems | list | 25, 50, 90, 140, 215, 330 | 50 … 650 |
| Offline gems | gems | 20·1.25^level | 1:20, 2:25, 3:32, 5:49, 10:150 | 40·1.45^level (rank 20 cost 23k gems for +0.5 gem/h) |
| Offline weapon/outfit/supply unlock | gems | flat | 50 / 50 / 38 | 100 / 100 / 75 |
| Offline coins (exception: coins) | coins | 100·1.3^level | 1:100, 2:130, 3:170, 5:286, 10:1061 | 100·1.5^level (rank 20 cost 221k for +60 coins/h) |
| **Auto-Collect Batch** (premium, exception) | coins | 120·3^level × stage | Winter I: 120, 360, 1080, 3240, 9720; Summer I: 480 … 38,880 | 30·1.5^level |
| **Map Details** | coins | max(60·1.3^k, 40·2^(stage−1)), k = Map Details bought this run on any stage | in stage order: 60, 78, 102 · 132, 172, 223 · 290, 377, 490 … 25,053 (24th) | 40, 100, 200 × 2^(stage−1) per stage |
| Loot Chance | coins | 20·1.35^level × 2^(stage−1) | Winter I 1:20, 5:67, 10:298, 15:1336; Autumn I 1:320 … 15:21,371 | same price for +1 point |

Unchanged (reviewed): respawn, movement, use speed, cooldowns, offline rate tracks, enemy-type gem upgrades (auto-merge, focus, spawn).

- **Exceptions:**
  - Auto-Collect Batch: coins, the premium price takes precedence, and its effect is unchanged.
  - Map Details: each purchase costs more than the one before it, in natural stage order. Its total over all 24 ranks is about 1.25× the old total, and the stage floor keeps a late stage from being cheap.
  - Offline coins: growth cut only.
- **Saved levels** are untouched. Prices are a pure function of the saved level (Map Details: of the levels saved this run), so preview prices equal what you pay, and there is no refund or exploit path.

## Saves (§7)

No schema bump. On load, an older (Change 7) save gets:

- `skills_seen` from owned skill items and bought cooldown ranks, with no notice;
- `discovered_spots` from known types whose spot home cell is already explored;
- `camps_known` from explored camp cells.

These fields are never copied from the live state. Explored cells are kept as they are: no new reveal and no reset. Evolved outfit and skill copies stay owned and can still merge their own copies. Outfits and skills above ^100 validate against their own cap (500), weapons against 100.

## Validation in Phase A (desktop, headless; not device evidence)

- `tests/change_7_smoke`: clean, no script errors.
- `tests/change_8_probe` (Phase A build-safety cases): 22 checks, 0 failures. Covers the prestige gate and transaction, merge cap and validation, migration of a Change 7 save, and reveal vs vision radii.
- `tests/change_8_capture`: one rendered check of the HUD, comparison, Stats, Inventory and Upgrades (`docs/Change_8_Evidence/ui`).

## Phase B: eight-map environment pass (§8)

`tools/compose_stage_art.gd` is a deterministic, re-runnable authoring tool (`godot --headless --path . --script res://tools/compose_stage_art.gd -- [--stage=N]`). It works on each existing stage scene: everything it adds is ordinary editor content, and the authored Ground layer, border Scenery, Camps and BossLandmarks keep their node ids.

| Layer | What it holds |
|---|---|
| Regions | Darker ground patches (the sheet's dark-region autotile, with inner corners) that carry the groves, as in references 03/04 |
| Paths | One connected route network: a minimum spanning tree over camps, encounter-type centres and boss courts, drawn as 3-tile dirt routes (it replaces the Change 1 grid roads that no longer matched the Change 6 layout) |
| Clearings | Camp courts are dirt plazas on the route network; boss courts are dark ground. The old court autotile was mis-indexed and drew white stripes. |
| Water | Ponds: blue water, frozen pools in Winter. Reeds and pebbles line their shores. |
| Details | Non-blocking decals: tufts, flower bunches on a low-frequency wave (rhythm, not noise), pebbles, mushrooms (Autumn and Spring) |
| Decor | Y-sorted with actors: groves and lone trees in the stage's season colours, a tree line along the map edge, boulders, rock pillars (Winter and Autumn), lamp pairs at each camp, lamps at route bends, and a fenced crop field (Summer and Spring flowers, Autumn I pumpkins, Autumn II sunflowers) |

- **Season identity:**
  - Winter: teal, mint and white snow trees, ice ponds, pillars.
  - Summer: green with orange accents, ponds, flower field.
  - Autumn: red, orange and pink groves, crimson ground, pumpkins and sunflowers.
  - Spring: green with purple blossom, flower fields, mushrooms.
- **Winter camps:** they now use the Winter sheet's fountain, bench and planter; the builder had used Spring sheet coordinates, which drew gravestones and swords.
- **Depth:** World, the stage root and Decor are y-sorted with Actors (z 1). Every ground layer has an absolute z below that, so trees and actors sort by their feet.

**Blocking:** trees (trunk circle r 6–9, never the canopy), boulders (7–10), pillars (8), lamps (4), ponds and fenced fields (rectangles) carry an editor-visible `Block` StaticBody2D. It has no physics layers; the simulation reads its shape. The tool enforces these rules:

- no solid within 96 of a camp, 64 of a spot, or 110 of a boss;
- every two solids leave a walkable gap (14 after the 6-unit actor clearance), so solids never form a concave trap;
- a grid BFS proves every camp, every actor home and every boss home is reachable from the arrival camp (no solid had to be removed on any stage).

`campaign.blocked_step()` slides any moving actor (player, enemies, auto-farm, leash return) along a solid toward its goal. Rectangles have round corners, and a head-on approach to a long solid heads for its nearer end. The shapes are read once per stage per process and bucketed in a 64-unit grid.

| Stage | Decor nodes | Solids |
|---|---:|---:|
| Winter I | 93 | 93 |
| Winter II | 329 | 329 |
| Summer I | 156 | 138 |
| Summer II | 377 | 351 |
| Autumn I | 189 | 175 |
| Autumn II | 307 | 281 |
| Spring I | 252 | 226 |
| Spring II | 675 | 657 |

**Unchanged:** camps, spot and boss positions, teleport destinations, map bounds and the fog layout revision. Old saves and their explored cells stay valid.

**Checks (desktop, headless or rendered; not device evidence):**

- `tests/change_8_walk_probe`: on every stage, the simulation's own movement walks from each camp to every camp, actor home and boss home. 2,178 walks, 0 stalls, worst detour 1.11× the straight line, no home inside a solid.
- `change_8_probe` 22/0; `change_7_smoke` clean.
- Before/after overviews: `docs/Change_8_Evidence/maps/before|after`. The camp at gameplay zoom: `docs/Change_8_Evidence/ui/01_hud.png`.

## Phase C: focused tests and fixes

**Fix found by the new tests (gameplay, so the Phase B APK is outdated):** `catalog.gd` now converts stage group ids to ints. They came from JSON as floats, and `Array.has()` is type-strict, so `sim.focus()` refused every request. The Focus (auto-farm) button has never worked on any build so far. No other behaviour depends on it.

| Suite | Result |
|---|---|
| `tests/change_8_probe` (new, one case per §9 item: camp entry/re-entry, nav and Settings → Stats, pinned equipment, comparison, HP text, skill/outfit merge and cap, migration, boss tier and per-item loot, Loot Chance 15 levels and prices, first-boss gate and card transaction, follow tracker and Ready, reveal vs vision, hidden-spot disclosure, per-spot loadout markers, banner centring) | 72 / 0 |
| `tests/change_8_walk_probe` (eight-stage movement around solids) | 2,178 walks / 0 stalls |
| `tests/change_7_smoke` | clean |
| `tests/change_7_probe` | 78 / 0 |
| `tests/change_6_probe` | 200 / 0 |
| `tests/change_5_probe` | 137 / 0 |
| `tests/campaign_probe` | 262 / 0 |
| `tests/campaign_content_probe` | 102 / 0 (the 324 fewer checks are the evolved outfit/skill transitions that no longer exist) |
| `tools/validate_campaign_source.py` | 1223 / 0 (now writes docs/Change_8_Evidence/static_checks.json) |

**Assertions updated** (each one encoded a rule Change 8 replaced; production logic unchanged):

- the Winter II reset gate is now the first boss defeated (Change 6/7 probes, campaign_probe fixture, validator; corrected from "first kill" after Phase C);
- the Stats nav button is now Upgrades, with Stats in Settings;
- boss weapon tiers are +1;
- the first enemy type is found by walking to a spot (48 reveal);
- the Stats playtime rows;
- the boss-marker test also erases the spot record;
- the Change 6 camp lesson fixture uses a sighted camp;
- the item-sheet height bound is 85% of the map (the two-card comparison is taller but still content-sized);
- the Change 5 heal-role walk iterates the authored legacy tiers directly.

**One pacing scenario** (`pacing_bot --policy=ordinary --seed=1`, desktop):

- first kill 0.8 min, second camp 3.4 min (Change 7: 1.0), level 10 at 17.3 min, Snowman 18.6 min, Winter II entered 18.7 min;
- the first prestige was allowed at 29.1 min (Specialist ready). Under the Change 6/7 Winter II gate this was 76–113 min; this run used the since-corrected first-kill rule, but the Snowman fell at 18.6 min, before any opportunity was ready, so the first-boss rule would allow the same 29.1 min (not re-measured);
- no stall from the close fog or the solid scenery.

**Needs a developer decision:** the content probe's theoretical ceiling still kills the final boss in 463 s, unchanged. Its survival fell from 256 s to 14 s, because outfits no longer evolve to tiers 5–7. The best reachable outfit is now a tier-4 boss outfit: about 400 HP base, about 2.5K at ^500. If late-game survivability feels short on device, the options are:

1. raise the late stages' outfit tiers;
2. raise `copy_cap`;
3. retune the late bosses in tools/tune_campaign.py (already open from Change 7).
