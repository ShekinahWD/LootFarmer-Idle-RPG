# LootFarmer — Change 20: complete remaining features, UI and tutorial

## Installation and scope

Apply this changed-files patch over **`lootFarmer(20261027-171448).zip` with the Change 19 patch applied**, the last project state confirmed by the developer. Extract at the directory containing `project.godot`, replacing matching files. There is no enclosing project folder inside this patch. Open/import in Godot 4.7.2, then run or export the game again. This is source code, not an APK; replacing source files does not update an already installed APK without rebuilding/installing it.

Application version and the current Android export version code are **20**. Save schema stays **8**; no Hard Reset is required. No commits were made. The original source ZIP and Change 19 ZIP were used unchanged to create the comparison baseline. Engine caches and build artifacts are excluded.

This implements the entire 22-section **Remaining Features, UI & Tutorial** brief. The earlier gameplay-only scope and pending Claude UI handoff are superseded. Existing Change 17 systems are reused through their action/getter APIs.

## Where the most visible changes are

- **Slot size:** Inventory → **Filters** → Inventory slot size → **Small / Medium / Large**. The same setting is in Settings. Both gear and supplies scale; the enclosing inventory panel stays the same height. Large is about three gear columns, Medium four, Small six on the tested portrait layout. The choice saves.
- **Individual auto-merge:** tap a gear item, then **Auto-merge: On/Off** in its details. Off protects that inventory identity from automatic merge/evolution. Manual merge still works. The flag survives saves, dropped/reacquired stacks and manual evolution.
- **Prestige:** the next reset retains the current **player level and earned XP**, with their derived stats, while resetting **Supply Mastery and its partial use progress**. It cannot reconstruct levels already lost by an older reset without an earlier save.
- **Automation and critical upgrades:** Upgrades → Player contains the critical tracks, pooled automatic-skill capacity and assignment controls. Upgrades → Supplies exposes automatic supply slots, interval and all five shop supplies.
- **Travel:** World → a stage with one unlocked camp travels directly; multiple unlocked camps open the camp map. Tap/release a green camp. Gray camps are locked. Dragging the map inside its sheet does not activate a camp. Combat blocks both paths.

## Requirement-by-requirement implementation

| Brief section | Implemented behavior | Primary evidence |
|---|---|---|
| 1. Guided progression | Saved action outcomes and acknowledgements; recognition of completed actions; no premature boss objective; mode-specific gates | `guided_progress.gd`; Change 20 and 15 probes |
| 2. Close panels | Arrow targets the real Close control after equip, equipment merge, mission claim and player upgrade; next step waits for the relevant close | Change 20/15/6 probes; `tutorial_guide.gd` |
| 3. Timing | 120 active-play seconds after first merge, then missions/claim/close; 60 seconds after mission close before Player Upgrades | Delay boundaries and JSON reload in Change 20 probe |
| 4. Camp lesson | Direction toward first camp, physical approach, discovery, View Camp, manual unlock; insufficient Coins returns to farming | Change 15/16/6 probes |
| 5. Boss preparation | Direction to Snowman; acknowledgement explains levels, global stats, merging and farming; only then permanent objective below minimap | Change 15/16/20; rendered boss-preparation/objective captures |
| 6. Inventory/potion | Additional farming, capacity/Gem purchase, one-time shortfall grant, potion stock/currency/capacity checks and use while hurt | Change 20 progression and existing supply action tests |
| 7. Prestige lesson | Follows potion use; recognizes ready opportunities; execution blocked until Guided completion; Basic/None keep normal eligibility | Change 20 real Prestige and mode checks |
| 8. World/final lesson | Post-boss World, camp travel and milestone explanations; next-map direction; Winter II final message, optional Prestige, five visible seconds before confirmation | Change 20 progression, button visibility and reload tests; final-message captures |
| 9. Missions | Description spans card width; progress/rewards share a separate compact row; values refresh before display | Mission screenshot and existing claim/reward probes |
| 10. Trackers | Mission and Prestige followers stacked below contextual Upgrades, wider with a gap | Change 8/11/16 placement tests; simultaneous tracker capture |
| 11. Slot zoom | Shared saved 3-preset controls; content scales with slots, fixed enclosing height, existing scrolling/actions | Change 20 geometry/disk/Hard Reset tests; three zoom captures |
| 12. Boss discovery | Warning holds eight seconds; discovered surroundings receive camp-sized permanent reveal, with existing-found backfill | Change 20 reveal/reload/warning checks; existing discovery tests |
| 13. Travel map | One camp direct; multiple camps visual map at authored coordinates, locked/unlocked distinction; shared combat gate; release-only selection | Change 20 direct/picker/touch/drag/combat checks; travel screenshot |
| 14. Player marker | Cropped contrasting star with outline, at least double prior dimensions on both maps; explicit layer above map markers and below panels | Change 20 layer/size test; minimap and expanded-map renders |
| 15. Merge exclusion | Details toggle; auto merge and auto evolution skip excluded records; manual merge/evolve permitted; successor inherits protection | Change 20 automation, JSON/disk, discard and evolution checks |
| 16. Dinosaur | Correct English boss/outfit labels and descriptions; saved `boss-elephant` identity and `Special 1 v1.png` association preserved | Asset inspection, label assertion, updated Asset Registry |
| 17. Supply Mastery reset | Both use-derived mastery and legacy mastery credit reset, including partial progress | Actual Prestige and disk reload in Change 20; updated Change 17/11 assertions |
| 18. Player level | Level and XP retained; derived benefits computed once; no replay of level rewards | Actual Prestige/disk/stat assertions in Change 20 |
| 19. Skill eligibility | Shared manual/automatic 64-unit configurable activation gate, offensive combat requirement, Heal missing-HP exception, disabled UI and no failed-cast cooldown/effect | 133-check proximity probe; Change 17/20 and updated combat fixtures |
| 20. Boss Gem preview | Effective total includes existing 5% base once; initial 5% → 10%, subsequent levels/bonuses retained | Proximity/probability probe, Change 20 UI assertion and screenshot |
| 21. Prior gameplay integration | Critical upgrades, skill assignments, supply automation/shop, world boss countdown, current mission rewards, effective skill power and Lightning/Frost resistance descriptions | Change 17 (679), weather (60), Change 20 integration tests and rendered controls |
| 22. Regression | Maintained suite plus new interaction/state tests, updated obsolete expectations, source validator and rendered review | `Change_20_Evidence/`, Test Suite document |

## State and tuning choices

`data/game/catalog.json` → `progression.change20` owns the tutorial delays, ten additional farming kills and five-second final delay. Gameplay time means active unpaused simulation time (`playtime_total`): closing/backgrounding the app preserves the elapsed part but does not finish these tutorial waits offline. The final delay counts only visible, unpaused message time. No lesson timeout consumes coins or grants repeated Gems.

The existing supply purchase API buys exactly one positive unit per action; there is no free-form quantity that could become negative. Existing potion stock or prior valid use is recognized. If a full supply inventory blocks the potion lesson, a separate one-time Gem shortfall grant enables its capacity prerequisite. Insufficient Coins still requires farming. Optional introductory actions done early are recognized rather than charged twice.

Map Mastery is a separate permanent system and still survives Prestige. Only **Supply Mastery** resets here. Other existing permanent Gem upgrades, cards, exploration and recorded completion retain their earlier rules. Exclusions are run inventory metadata and clear with the run's item records on Prestige/Hard Reset.

The camp picker and slot grid use runtime layout because their geometry depends on destination stage coordinates, available width, owned capacity and density. Existing panel/theme components, scroll containers and action controls are reused. No new art pack or sprite was introduced.

## Verification and limits

See `LootFarmer_Test_Suite.md` and `Change_20_Evidence/suite_summary.txt` for the full maintained run, final targeted rerun and exact counts. Raw per-probe logs are included. Desktop OpenGL Compatibility renders at a 540×960 portrait window cover inventory density, toggle, automation, supplies, mission layout, travel, minimap/expanded map, trackers and tutorial cards.

Physical Android touch, safe areas, GPU performance, background/resume and exported-build acceptance have **not** been verified in this environment. No APK/export/signing claim is made. The software-rendered capture reports a V-Sync limitation and shutdown resource warnings; it completes its screenshots without a script error. The earlier standalone late-game balance benchmark remains unresolved (Change 17 reported 33/35 versus 34/35 in its supplied baseline); this patch does not retune those encounters or represent them as passing. Those are separate from the maintained regression suite.

## Android verification checklist

- Build version 20 and install over the existing app without clearing its data. Confirm a previous save loads normally.
- At normal phone scale, test all three slot sizes, scrolling, dragging/equipping, long-press supply details and the Filters/Settings controls. Check notch/gesture-bar clearance.
- Toggle a specific item's automatic merge off/on, leave other items eligible, background/restart, drop/reacquire and manually evolve it. Confirm protection and manual merges behave as described.
- Run Guided from a test fresh profile: each close arrow, both delays (including background/restart), camp shortage/farming/return, boss discovery/acknowledgement, capacity grant/potion lesson, Prestige restriction and Winter II five-second final confirmation. Also check Basic and None.
- From a backed-up test save, Prestige at a known level/XP with nonzero Supply Mastery and partial uses. Check retained level/XP/permanent upgrades and reset supply progress after restart.
- Test single- and multi-camp travel, locked camps, drag-versus-tap, and attempts while fighting. Check player marker ordering on minimap/expanded map and that open panels cover it.
- Let an enemy enter/leave the 64-unit skill activation radius; test manual and selected automatic skills. Heal while hurt outside combat. Failed actions must not consume cooldown or create spell effects.
- Check all five supply prices/purchases, critical upgrades, automatic-slot assignment, mission reward text, Lightning/Frost descriptions, boss respawn countdown and longer discovery banner.
- Review simultaneous followers, objective/Next Stage separation and tutorial overlays at narrow/tall aspect ratios. Measure rain and normal play on the target device; desktop renders do not establish Android performance.
