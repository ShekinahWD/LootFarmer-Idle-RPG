# LootFarmer — Change 11 Notes

Baseline: Change 10 (`4dcc7d4`, tests/docs `ca0819f`). Brief: docs/LootFarmer_Change_11_Instructions.md, plus the developer's added requirement that every gem-funded upgrade persists through Prestige.

Build commits: `766a213` (implementation), `72666e7` (map markers never overlap; supply text), `a047048` (ground loot expiry restored, found by a legacy probe), `7081d18` (cheaper enemy spawn upgrades, requested during the change). **Build from `7081d18` or later.** Tests and docs commits after it do not change the game.

## What changed

| # | Area | Change | Where |
|---|---|---|---|
| 1 | Prestige follower | A followed collection contract reads "Step n/3 · Collect items · x/y" (outfits done + 1; the closest unfinished count), then "All found · hand them in from Prestige". There are no item names, icons or descriptions. The Prestige panel names each outfit with its count. Other followers are unchanged. | `campaign.follow_summary`, `collection_counts`, `opportunity_progress` |
| 2 | Minimap | 230 × 230 (was 130). It now follows the Map Details ranks (it used to draw generic dots): rank 2 type portrait, rank 3 weapon badge, skill badge and a dimmed portrait on weapon-only spots. Markers are 16–24 px, sized per map so the closest two spots keep a gap; a type's spots spread around its centre when needed. The World map uses the same fit, which also fixed its overlaps on Winter II, Summer II and Spring II. Undiscovered spots never get a marker. The player dot moves without redrawing the markers. | `map_view.gd`, `main.tscn MiniMap` |
| 3 | Camp Teleport | A camp's Teleport opens a destination picker of every owned camp on every reached map. The camp you stand in is marked and not selectable; one destination is chosen; Back cancels. Combat, death, pause and Prestige block it when opening and again when moving; a blocked move changes nothing. Arrival sets the respawn camp, recentres the camera and does not pop the camp menu. In World, Travel to the camp you stand in is disabled. | `game_ui._teleport_panel`, `_travel_to`, `campaign.camp_action` (shared rules) |
| 4 | Loot speech | The "Hey! My outfit!" line was the first-hit line, so it fired without any drop. Loot lines now come from `_reward` after every roll, for an item that actually dropped: outfit, else weapon, else skill, else supply, one bubble at most. The first-hit line is now "Hey! Watch it!". Drop chances, RNG use and loot notifications are unchanged. | `simulation._reward`, `_loot_speech` |
| 5 | Supplies | Five supplies (below), one identity each. Supply tiers, supply evolution and supply auto-merge are removed. Stock is separate from permanent mastery. Supply slots: 1 + 4 purchases = 5. | catalog (`tools/change11_catalog.py`), `simulation` supply section, `game_ui._supply_panel` |
| 6 | Filters | A Filters button next to the gear count opens the existing filter panel. While open it reads "Filters · Outfits"; every close path clears the filter (`_clear_filters`). Upgrades → Inventory keeps only the slot purchases. | `main.tscn …/Head/Filters`, `game_ui._clear_filters`, `_sync_filter_button` |
| + | Gem upgrades | Prestige keeps every upgrade bought with Gems, from the currency (`simulation.upgrade_kept`). Six gem upgrades used to reset: Gem Chance, Gem Amount, Boss Gem Chance, Boss Gem Amount, Spawn Amount and Spawn Cooldown. Kept spawn levels respawn their actors at once. Coin upgrades are unchanged, Hard Reset clears everything, and unspent Gems still reset. No upgrade has two currencies, so no purchase history needed splitting. | `campaign.choose_card`, catalog `keep` mirror |
| price | Spawn upgrades | Winter I per enemy type: Spawn Amount 75 / 125 / 200 gems (400 total, was 800), Spawn Cooldown 50 / 100 / 150 / 225 / 300 (825, was 1,500). Later stages keep × (1 + 0.25 × (stage − 1)). Effects and caps unchanged. | catalog via `tools/change11_catalog.py` |
| fix | Ground loot | Pickups expire after 300 s of active time again (fade in the last 30 s; frozen while paused, in the background or on another map). Nothing had decremented `ttl`, so loot the inventory could not take piled up without bound in the save and the world view. | `simulation.step` |

## Supply catalog

| Supply | Effect at ^0 → ^100 | Duration / cooldown (^100) | Tap / auto-use | Drops from |
|---|---|---|---|---|
| Health Potion | heals 20% → 40% of max HP | cooldown 5 s (4 s) | at 80% HP or below | Winter I |
| Coin Tonic | +25% → +50% coins per kill | 30 s (48 s) | when not running | Winter I |
| Guard Tonic | +20 → +40 Defense | 20 s (32 s) | tap when not running; auto in combat | Winter II |
| Recovery Salve | 1.5% → 3% max HP per second | 10 s (16 s) | below 90% HP; auto at 60% | Summer I |
| Wisdom Tonic | +25% → +50% XP per kill | 60 s (96 s) | when not running | Summer II |

- **Supply slot cap: 5**, exactly the number of supply identities (1 initial + 4 purchases at 4/8/12/16 gems).
- **Permanent mastery:** every copy found (a collected drop or claimed offline earnings) after the first adds ^1, up to ^100. Using a charge never lowers it, and Prestige keeps it (`supply_found`). Shop purchases (Potion 10 coins, Coin Tonic 30) add stock only. Effect = base + 1% of base per level. Milestones: ^25 Steady (duration ×1.2, potion cooldown ×0.9), ^50 Potent (×1.4, ×0.85), ^100 Mastered (×1.6, ×0.8). A timed supply cannot be reused while it is running.
- **Availability:** the per-kill supply roll is unchanged; a successful roll picks among the supplies the map allows by weight (8 / 2 / 2.5 / 2 / 1.5), so Winter I keeps its 80/20 split. Enemy drop research and the Farming Guide list every supply's chance.
- **UI:** the supply panel shows effect and amount now, use condition, running status or cooldown, the auto-use rule, stock, mastery ^n / ^100, the next copy's gain and milestones, plus Use and Auto toggles. Active Guard and Recovery appear in the stat breakdown ("Active supplies"); all running supplies show in Stats → Boosts and as timers on their slots.
- **Art:** owned PixelPlains orbs: Item-67 (Guard), Item-71 (Recovery), Item-70 (Wisdom); Potion and Coin Tonic keep Item-212 and Item-68.
- **Saves:** a Change 10 save loads. Tier copies fold into the base supply (`legacy_items`), the supply row shrinks to its purchased size and mastery starts at 0. No migration beyond that, per the pre-release save policy.

## Legacy test disposition (brief section 7)

See also docs/LootFarmer_Test_Suite.md.

| Test | Disposition | Reason (and replacement coverage) |
|---|---|---|
| change_1_probe | **Deleted** | Asserted Change 1 contracts that were later replaced on purpose: gem prices 50…500, a schema-4 → 5 refund migration, 4 enemy types / 55 actors, the old `victory`/`offer` Prestige and "Player only has respawn". 87 of 131 checks failed for those reasons. Its still-current contracts moved: per-type collection and spawn upgrades to gameplay_probe; gem chance/amount and boss payouts are in change_10_probe; dialog bounds in change_10_probe. |
| progression_probe | **Deleted (consolidated)** | Called the removed `sim.sell()`; the script error aborted the run, so it hung until killed. It also assumed 28 enemies, the removed `sprout`/`robot` items, level cap 1000 and the old Prestige. Variant loadouts, worn-loot rolls, the exact XP threshold and the level gain moved to gameplay_probe; stored shares are in change_9_probe; level growth in change_10_probe; panel width in change_7–10 probes. |
| gameplay_probe | **Fixed and consolidated** | Core combat and timing rules exist only here (stop-to-attack delay, single contact, no reload resurrection, respawn, pause/suspension, leash, regeneration, focus after respawn). Repairs: `sim.step` clamps to 0.1 s, so a stepping helper replaces `step(9)`; fog fixture (explored ground); current Prestige batch; the invalid-save rule is now "fresh writable profile"; supply rules; selling removed. **Revealed a genuine bug (ground loot never expired), fixed in `a047048`.** 72 / 0. |
| ui_probe | **Fixed** | HUD presentation contracts (tap-collect, joystick, walk/death/attack frames, zoom bounds, camera follow, ground-item size, enemy HP colour) are still current. Repairs: onboarding chooser answered (a pending chooser suspends the simulation, blocking use and collect); type discovered before its enemy panel; Use is a pinned action; navigation includes Upgrades again (Change 8); the HP bar check reads the Change 8 textured fill. The old run hung on `hp_fill`. 24 / 0. |
| inventory_probe | **Kept (fixture updated)** | Dock tap/hold/scroll and slot layout. Onboarding fixture added; the supply row is filled to the new 5 slots. 119 / 0. |
| change_10_probe | Updated 1 check | "Supplies cap 13" became "5 slots since Change 11". |

## Tests (focused)

- `tests/change_11_probe`: **153 checks, 0 failures**. It covers:
  - the follower at each collection stage (no names, path icon kept, Prestige panel still names the outfits; other followers unchanged; unfollow);
  - minimap and World-map markers on all 8 stages (sizes, no overlaps, privacy, loadout definitions, the player dot does not redraw);
  - Teleport (one camp, two camps, choose, combat block when opening and moving with nothing charged, arrival without the camp menu, another map, locked camps and maps, pause);
  - loot speech over 1,500 rewards (no drop means no line; each line matches a real drop; Outfit-only spots never say "weapon");
  - supplies (catalog, availability per stage, the real drop and collect path, stock versus mastery, purchases, the cap, milestones, every effect and expiry, auto-use rules, UI, offline mastery);
  - supply save/load, the Change 10 fold, Hard Reset;
  - Filters through all six close paths;
  - gem upgrades kept and coin upgrades reset across the whole catalog, kept spawn levels applied at once;
  - spawn prices on Winter I and Winter II.
- `tests/change_11_smoke` (build readiness) and `tests/change_11_capture` (screenshots in docs/Change_11_Evidence/ui/).
- **Maintained suite** `python tools/run_probes.py`: **19 / 19 passed**. It is validate_campaign_source (1,326 / 0), change_11 probe and smoke, change_10 … change_5, campaign, campaign_content, gameplay, ui, inventory, targeting, camera, attack_timing, bootstrap and change_8_walk. See docs/LootFarmer_Test_Suite.md.
- No balance simulations or pacing bots were run (per the brief).

## Android-only checks (not tested on a phone)

- Minimap size (230 canvas px, top right) against the map view and the zoom slider on a real aspect ratio; portrait and badge readability at 16–24 px; whether 230 px feels too large in play.
- Filters button size next to "Gear n / 70" and the equipped icons on narrow phones; the orange open state.
- Teleport picker row height and the Choose / ✓ buttons with real insets; the camp menu flow on arrival.
- Supply panel length on small screens; the readability of the three new orb icons next to the Coin Tonic orb.
- The loot speech bubble during the death fade (it lasts about 1 s).
- Collection follower wrapping to two lines in the lower-left tracker.
- Balance (not simulated): potion strength as a share of max HP, Guard Tonic in boss fights, supply drop shares and mastery pace, and what keeping Gem Chance, Gem Amount and Spawn upgrades through Prestige does to later runs.

## Text

English only (other languages are gated until release), so "Filtros" was not added; there is no Spanish locale to add it to. New and changed strings are in tools/change11_strings.json (applied with tools/po_set.py). Obsolete keys were removed: POTION_ROLE, COIN_TONIC_ROLE, COIN_TONIC_ACTIVE, BUY_POTION, BUY_BOOST, UP_MERGE_SUPPLIES, UP_MERGE_SPEED, POTION_CONDITION, STATS_TONIC_VALUE and CHAT_LOOT.
