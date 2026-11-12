# LootFarmer — Change 61: Guided Tutorial Restructuring

**Status:** Developer-approved implementation brief  
**Scope:** Guided first-profile onboarding, its necessary gameplay hooks, one guaranteed mission, camp travel/respawn distinction, and contextual offline-reward discovery.  
**Sequence:** Change 60 (already committed as `8ce00ae`, plus VFX commit `7ba013e`) → **Change 61** → English-string freeze/localization delta → Android testing.  
**Authority:** Current repository's canonical GDD, current Reusable Game Development Playbook (especially 18, 44, 61, 132), and this approved brief. Read actual working-tree code before implementing; the supplied ZIP is older than Changes 59/60 and Localization Batch 01/02. Do not overwrite those changes.

## 1. Outcome

Make Guided onboarding genuinely *interactive*. Teach what the game asks the player to do, point to the live controls or world targets, and advance only when the corresponding real state/action succeeds. The central progression is:

**First additional camp → choose respawn camp → demonstrate camp travel → discover Snowman → buy Map Details Rank 1 → locate enemies using map pins → follow and claim a guaranteed 30-kill mission → follow the first Snowman Prestige opportunity → farm and defeat Snowman → travel to Winter II → inspect optional Prestige → existing final message.**

The full tutorial must also teach **stored equipment contributions** and **offline item reward upgrades**, and move the already-established inventory/potion lessons **before** Snowman discovery. Do not require a Prestige reset to finish onboarding.

### Nonnegotiable existing rules

- **Guided** gets step-by-step pointers and action-driven gates; **Basic** and **None** keep their existing teaching levels and must not get forced Guided steps. Actual game content (including the guaranteed mission) exists in all modes.
- Keep the established early lessons (movement, manual target drag, first kill, loot, equip, merge, first Missions claim, first global upgrade), tutorial-mode chooser, safety arbitration, and **unchanged** final `THE ROAD AHEAD` message.
- Keep all existing tutorial outcomes, achievements, claimed rewards, purchases, inventory/gear, Prestige cards and old-save progress. Never reset an existing player to step 1. Prestige must not replay the tutorial; Hard Reset may.
- All guidance must use the actual UI controls, navigation, scroll positioning, real target events, and currently unlocked features. Opening a panel is not proof that an upgrade, mission, travel or follow action succeeded.
- No new non-English translations in this batch. English key/wording changes must be recorded for the later 19-language delta. Never run a catalog-regeneration command that overwrites approved non-English translations.

## 2. Canonical Guided sequence and acceptance states

Implement the complete ordered flow below. Existing steps that are unchanged should retain their existing English keys/messages and completion rules. Newly supplied text is **proposed final English copy**; keep it natural and concise, make each message match the live UI, and only adjust where the current UI calls an action by a different exact label. Register new/changed strings in `en.po` and the project's existing localization-pending mechanism.

| # | Lesson / existing or new | Trigger / visibility | Guidance and completion — actual state, not acknowledgement |
|---:|---|---|---|
| 0 | Mode chooser | New profile / Hard Reset | Choose Guided. Basic and None unchanged. |
| 1 | Move | Guided selected | Existing joystick and path gesture; reach first path point or satisfy the existing safe escape condition. |
| 2 | Target | Movement done | Existing hero-to-enemy drag demonstration; successful manual target selection; preserve no-enemy escape. |
| 3 | Kill | Target done | Existing stationary auto-attack lesson; first eligible enemy defeated. |
| 4 | Collect loot | First kill | Existing dropped-item pointer and fallback; first item physically collected. |
| 5 | Equip | Item collected | Existing item comparison → Equip pointer; weapon/outfit equipped. |
| 6 | Close item | Equip succeeded | Point to real Close; panel closed. |
| **7** | **Equipment bonuses (new)** | First equip / early equipment phase, before merge if practical | Explain equipped vs stored contribution; point to actual Stats access path and stored-contribution display; complete when player has genuinely visited the relevant Stats view. Do **not** require the player to obtain an additional distinct item. |
| 8 | Merge | Equipment bonus lesson complete | Existing compatible-copy farming, item selection and Merge action; one actual merge. |
| 9 | Close item | Merge succeeded | Close item panel. |
| 10 | Missions introduction | Existing short gameplay delay | Existing Missions open/claim teaching; successfully claim a main objective or mission. |
| 11 | Close Missions | Claim succeeded | Close Missions. |
| 12 | First global upgrade | Existing short gameplay delay | Existing Player Upgrades purchase tutorial; a qualifying upgrade bought. |
| **13** | **Offline rewards (new)** | After first global upgrade, before ending Upgrades lesson | Guide to **Player Upgrades → Offline**, explain offline Coins/Gems and unlockable Weapons, Outfits and Supplies (Consumables), plus their upgradeable item rates. Complete when the player actually opens/inspects Offline. **No purchase or offline wait required.** |
| 14 | Close Upgrades | Offline viewed | Close Upgrades. |
| 15 | Expand equipment inventory (moved) | After global upgrade/Offline, **before** boss discovery | Preserve existing equipment-slot upgrade lesson and affordability safeguard; finish when a slot expansion is bought/already owned. |
| 16 | Close Upgrades | Slot lesson done | Close Upgrades. |
| 17 | Buy Health Potion (moved) | Inventory lesson done | Existing Supplies navigation and capacity guidance; complete on owned/already-used potion. |
| 18 | Use Health Potion (moved) | Potion available | Existing actual-use lesson: wait until HP is missing, then use a potion; preserve all full-HP and empty-stock recovery behavior. |
| 19 | Unlock additional camp | Potion lesson done | Existing arrow → discover camp → View Camp → Unlock. Must be the first **additional** camp in Winter I (arrival camp already owned). |
| **20** | **Choose respawn camp (new)** | Additional camp unlocked | Guide to the newly unlocked camp's **Select** action; complete only when it is explicitly selected as the respawn point. |
| **21** | **Travel between camps (new)** | Respawn camp chosen and at least two owned Winter I camps exist | Guide through camp's Teleport / destination picker or World camp travel, select a **different owned Winter I camp**, then actually teleport. Verify travel did **not** change the selected respawn camp. No Winter II content involved. |
| 22 | Discover Snowman | Camp travel completed | Existing boss-direction arrow; complete when Snowman is *discovered*, **not killed**. Reveal Prestige and the first Snowman defeat opportunity at this moment. |
| **23** | **Buy Map Details Rank 1 (new)** | Snowman discovered | Guide through **World → Map upgrades → Map Details** for Winter I; guide earning Coins if necessary; complete only after an actual purchase or if Rank 1+ was already bought. |
| **24** | **Inspect enemy pins (new)** | Map Details Rank 1 owned | Guide opening the World map and finding a **revealed/discovered enemy marker**; visually point out what the new Map Details rank actually revealed. Complete once the player has meaningfully viewed/selected a genuine eligible enemy pin. Avoid revealing undiscovered enemies or bypassing fog/discovery rules. |
| **25** | **Follow the 30-kill mission (new)** | Boss discovery unlocks guaranteed mission; reached after Map Details lesson | Guide opening Missions, finding the **one-time 30-enemy-kill mission**, and pressing its **Follow** control. Complete when `follow_mission` refers to that exact mission. |
| **26** | **Defeat 30 enemies (new)** | The mission is followed | Show its real `0/30 → 30/30` HUD progress; suggest using the new World enemy pins to find farming targets; count 30 real eligible defeats **since Snowman discovery**, of **any** enemy type. Complete at 30/30, not when panel opens. |
| **27** | **Claim mission reward (new)** | 30/30 | Guide Missions → actual **Claim**; complete only when that mission reward is successfully paid/claimed exactly once. |
| **28** | **Follow Snowman Prestige opportunity (new/rewritten)** | Mission claimed | Open Prestige, point to **the first Snowman-defeat opportunity** and **Follow** it. This opportunity must already be present since discovery, require the Snowman's **first defeat**, and become ready on **one kill**, not ten. Complete when that exact opportunity is followed, or when it is already ready due to an earlier defeat. |
| **29** | **Farm until ready; defeat Snowman (rewritten)** | Prestige opportunity followed/ready | Tell player to keep farming, leveling, merging and upgrading until strong enough; pointer to real Snowman/boss objective when useful. **Do not** impose a fixed extra 10-kill gate, an arbitrary wait, or a forced immediate boss attack. Complete on the **first real Snowman defeat**, which also completes/marks ready the first Snowman Prestige opportunity. |
| **30** | **Open World / unlock next stage (new/rewritten)** | Snowman defeated / Winter II unlocked | Celebrate, point to the actual **World** button; complete when World opens. Remove old three consecutive dismissible World/Travel/Milestones cards. |
| **31** | **Travel to Winter II (rewritten)** | World opened after boss defeat | Highlight Winter II and its **arrival camp**; use the actual travel controls; complete when `stage == Winter II` following successful travel. Don't teach cross-camp teleport here again. |
| **32** | **Prestige is optional (new)** | **First actual arrival in Winter II** | Guide to the actual Prestige button/panel and the ready Snowman opportunity. Explain that players may **Prestige now** or **accumulate multiple ready opportunities and redeem them together** later. **No reset required.** Complete after the Prestige panel has been opened **and then closed**, **or after a successful optional Prestige**. |
| 33 | **THE ROAD AHEAD** (existing final) | Optional Prestige lesson done, even if a voluntary Prestige moved player back to Winter I | Show the **existing final title and text unchanged** (including existing minimum read delay); complete on the existing acknowledgement. Fully reveal normal menus. |

If an action is **already validly completed** in an existing save, skip its teaching gate rather than requiring a repeat purchase, repeat boss fight, or another reset. A player who had already finished Guided before Change 61 must remain finished. For a partially Guided player, reconcile existing step IDs and newly inserted steps carefully; do not mark new steps by fragile array offsets alone.

## 3. New English lesson messages (use semantic localization keys)

For existing unchanged lessons, reuse current copy. For newly introduced or substantially rewritten steps, aim for these concise titles and details (text must fit small phone layouts). UI navigational substeps may use shorter contextual variants ("Open World", "Tap Map Details", "Tap Follow", "Tap Claim") while the underlying lesson waits for its own actual event.

| Lesson | Title | Detail / explanatory message |
|---|---|---|
| Equipment bonuses | **Your gear makes you stronger.** | **Equipped weapons and outfits give 100% of their stats. Stored weapons still give 30%, and stored outfits give 15%. Open Stats to see how your gear helps you.** |
| Offline rewards | **Earn rewards while you're away.** | **You earn Coins and Gems while offline. In Upgrades → Offline, you can also unlock Weapons, Outfits and Supplies from items you own, then improve their reward rates. Take a look; you don't need to buy anything now.** |
| Select respawn | **Choose where you'll respawn.** | **Select your newly unlocked camp. This is where you'll return after being defeated.** |
| Camp travel | **Travel between your camps.** | **You now have two unlocked camps in Winter I. Choose a different camp and tap Travel. Traveling does not change your selected respawn camp.** |
| Snowman discovery | **You've found the Snowman!** | **Finding a boss unlocks Prestige opportunities. First, let's make the World map more useful.** |
| Map Details | **Reveal enemy locations.** | **Open World → Map upgrades and buy the first Map Details rank. It reveals enemy and boss markers for places you've discovered.** |
| Inspect pins | **Find enemies on your map.** | **Open the map and look for the new enemy markers. Use them to find places to farm.** |
| Follow mission | **Follow your new mission.** | **A mission to defeat 30 enemies is now available. Open Missions and tap Follow to pin its progress to your screen. Any enemy counts.** |
| Farm 30 | **Defeat 30 enemies.** | **Farm any enemies you can beat. Check their locations using the markers on your World map. Follow your mission's progress until it reaches 30/30.** |
| Claim mission | **Claim your mission reward.** | **Your 30-enemy mission is complete! Open Missions and tap Claim.** |
| Follow boss Prestige | **Follow your first Prestige opportunity.** | **Open Prestige and follow the Snowman opportunity. Defeat the Snowman once to complete it.** |
| Beat Snowman | **Get stronger, then defeat the Snowman.** | **The Snowman may be too strong now. Keep farming, merging equipment and buying upgrades until you can win. Your followed Prestige opportunity will update when you defeat it.** |
| World after boss | **You defeated the Snowman!** | **Winter II is unlocked. Open World to choose your next stage.** |
| Winter II travel | **Travel to Winter II.** | **Select Winter II and travel to its arrival camp.** |
| Optional Prestige | **Prestige is your choice.** | **You've completed your first Prestige opportunity. You can Prestige now, or keep playing and complete more opportunities to redeem together in one reset. Open Prestige to see your choices; you don't have to reset.** |

**Final card:** Preserve exactly the existing `GUIDE_TUTORIAL_FINAL` and `GUIDE_TUTORIAL_FINAL_DETAIL` strings. No new generic Milestones introduction after Snowman; no text-only replacement for action-based steps.

## 4. Gameplay contracts and necessary corrections

### 4.1 Camp travel vs. selected respawn point

- **Select camp** changes the *respawn* destination; **Travel / Teleport** changes only the *current player location*. This is the developer-approved separation, not a cosmetic tutorial distinction.
- Inspect `campaign.gd`'s current `camp_action()` and UI: in the previous snapshot `camp_action(st, camp, true)` assigns `state.spawn = camp` while traveling. Remove that coupling safely.
- Where required, maintain the selected respawn **per stage** (with arrival camp as safe fallback on a stage not yet configured). Returning to a stage should restore its previously selected respawn camp, not the last teleport destination. Preserve death/revive and stage-switch camera behavior, and migrate old saves without losing owned camps or existing selection.
- Do not permit travel to locked/unowned camps or while prohibited by combat/action locks. The tutorial must never force travel into Winter II before it is unlocked.

### 4.2 Snowman discovery, first Prestige opportunity and reset gate

**Critical: the prior implementation may not support the approved first-boss flow.** In the uploaded snapshot, `hunter_o1` is discovered **after one Snowman defeat** and requires **10 further boss kills**. That is incompatible with the developer's explicit instruction: *discover the boss → the opportunity to kill it appears → defeat it once → the opportunity becomes ready*. Inspect current working-tree behavior rather than assuming this was already fixed.

- Adapt the **first existing Snowman/Hunter Prestige opportunity** (`hunter_o1`, if its ID remains appropriate) so **discovery is triggered by finding the Snowman**, its objective is **one Snowman defeat**, it is **followable before the first kill**, and it becomes **ready immediately after the first kill**. Do not invent a redundant additional card/path or silently alter the other Hunter objectives and their existing 3-card Set-bonus requirements.
- The Prestige panel becomes available on discovery. The **reset remains locked until the player has defeated the first boss and has a ready redeemable opportunity**, except that Guided onboarding also deliberately blocks resetting **until the new optional-Prestige lesson in Winter II**. At that lesson the player may actually Prestige; clicking Close must also complete the lesson without a reset.
- Save migration: existing players who have already killed the Snowman must not be asked to kill it again simply because the old opportunity baseline was recorded after their first kill. Preserve previously ready/consumed cards and all earned progress; prevent duplicate awards. Recheck current first-boss gate and the 48-card catalog/11-path integrity after any ID/condition change.

### 4.3 Guaranteed 30-kill mission

- Introduce a **one-time, stable-ID main/objective-style mission**, available in **all three onboarding modes** the instant the Snowman is discovered, with **30 kills of any enemy type**. Do not use a random daily slot, a daily rollover, or require a specific group. Exclude non-credited/summoned helper defeats, offline events, or anything that normally does not increment legitimate kill credit.
- Capture its **kill baseline at Snowman discovery**. Progress starts at `0/30` then, never counts pre-discovery kills, and persists through save/load. This is a *specific* tutorial mission, not the generic historic kill counter.
- The mission is always visible/reachable once unlocked, not buried by the ordinary **three-main-objective display limit**. It has its own Follow/Unfollow, normal tracker and Claim. Guided mode explicitly requires **following and manually claiming** it; automatic daily mission claim must not silently consume this one-off reward. Use an appropriate established main-mission reward scale instead of making up a new currency, and report the actual reward in the implementation summary.
- Keep claimed state/reward idempotent and profile-persistent; no re-award on reload, stage change, or Prestige. Existing profiles already beyond first-boss onboarding should be reconciled without retroactively blocking their completed tutorial.

### 4.4 Map Details Rank 1 and real map pins

- First Snowman sight unlocks this lesson; buy **Winter I Map Details Rank 1** with its **normal Coin cost** (do not grant an artificial rank). If not affordable, point to legitimate Coin farming and resume when affordable. A pre-owned Rank 1 satisfies the purchase gate.
- Show what this rank actually enables: visible markers for already discovered locations/enemies. Do **not** reveal hidden enemy groups or override fog/discovery. Only offer an interactive pointer to a real visible marker; recover if none currently available by guiding exploration rather than stalling.
- Do not relocate camp-travel teaching to Winter II. World may be taught twice for **different** purposes: map pins during Snowman prep and stage travel after the boss kill.

### 4.5 Stored gear bonuses and offline rewards

- Existing combat rule is **equipped 100%; stored weapons 30%; stored outfits 15%**; don't change stat formulas or invent bonuses for duplicate copies. The Change 60 effective-stat popups should continue showing only `+X Stat` / `−X Stat`, starting separate stat changes one second apart. Do **not** add “Stored Bonus” to popup text or change the buff VFX.
- Teach stored contributions through a brief Guided lesson and **real Stats surface** (existing `STATS_STORED_SHARE` is a starting point). The explanation should be permanently discoverable within Stats. If precise source totals are displayed, derive them from effective stat calculations, never guessed item values; avoid requiring the acquisition of a second distinct item during onboarding.
- Teach the Offline tab during first Player Upgrade lessons **without forcing a purchase or actual offline interval**. Explicitly mention optional offline **weapon, outfit, and supply/consumable unlocks**, plus rates, subject to the game's existing item-ownership mechanics.
- Fix the existing **offline-gear contextual hint** so its **Gem-affordability check cannot suppress learning**. Include supplies in the explanation. Preserve safe-moment/modal arbitration and reasonable anti-spam behavior; Basic/None must still be able to discover the feature. Do not imply that players receive offline item types they have not unlocked or are not eligible to receive.

### 4.6 Tutorial gates, migration and interruption handling

- Keep one ordered step authority (`guided_progress.gd` or its current equivalent) and one presentation owner (`tutorial_guide.gd`), without parallel competing flows.
- Each lesson should expose its step ID, unlock predicate, live pointer target, allowed panel(s), success predicate and saved completion state. Recompute as screens/rows change; do not point to invisible, disabled, offscreen or missing buttons. Follow existing Playbook teaching/arbitration rules.
- Suspend visual guidance during confirmations, unrelated panels, pause, boss combat where intrusive, modal choices and background. Keep gameplay and modal actions safe; do not hide or deny necessary menus during the very steps that use them.
- **Existing finished Guided saves stay finished.** For partial saves, translate the old 29-step progress into the new steps by stable IDs and true game state; do not replay purchases/claimed objectives, remove rewards, or skip the new flow incorrectly. Handle mid-step reload, quest followed/unfollowed, boss defeated early, lost target, stages already unlocked, travel interruption, and legitimate optional Prestige.
- If a player Prestiges at the optional lesson, persist that this lesson was reached/accepted **before the reset** so the final `THE ROAD AHEAD` card can appear in the post-Prestige starting map. A simple closing of the Prestige panel also advances to the final card. Don't force a second trip to Winter II.
- Do not change Basic/None menu visibility, early loot guarantees, gameplay drop rates, or the new Change 60 feedback/VFX.

## 5. Suggested code inspection anchors (not presumed authoritative)

- `scripts/game/guided_progress.gd`: ordered `STEPS`, action marks, `next_step()`, unlock gating, normalize/migration and `prestige_gate_reason()` interaction.
- `scripts/game/tutorial_guide.gd`: dynamic pointer targets, `GUIDE_` labels, `surfaces`, scrolling, card dismissal, travel, and final card.
- `scripts/game/onboarding.gd`: Guided vs Basic vs None reveal policies; discovery notices.
- `scripts/game/campaign.gd`: `camp_action`, `travel_reason`, `discoverable`/`evaluate`/Hunter goal, `prestige_unlocked`, `prestige_gate_reason`, mission progress/follow/claim and save normalization.
- `scripts/game/game_ui.gd`: World/Map Details, camp `Select`/`Travel`, Teleport, Missions Follow/Claim, Prestige Follow/confirm, Stats, Player Upgrades/Offline, offline hints.
- `data/game/catalog.json`, `localization/en.po`, pending-localization manifests, current save schema, existing test infrastructure.

If any code path differs in the **current working tree**, adapt the implementation to the genuine source of truth while preserving the behavioral contracts above. Do not roll back Change 60 or earlier localization integration commits.

## 6. Validation and local commit

This is larger than the Change 59 cosmetic update, but avoid an open-ended comprehensive balance audit. Use **focused runtime/smoke validation and the relevant existing regression checks**, rather than automatically launching every long-running test or generating large new test infrastructure.

Minimum acceptance checks:

1. Fresh Guided flow can traverse all steps, with real pointer targets and successful actions at both **432×960 and 540×960**. No mandatory step hangs in normal play.
2. Inventory and potion steps occur **before** Snowman sight; boss discovery starts the new Map Details / 30-kill / Prestige follow sequence without a generic 10-kill filler.
3. 30-kill mission appears **on discovery**, counts **any 30 legitimate kills after discovery**, can be followed, persists, and pays exactly once when claimed. Does not disappear on daily refresh; Basic/None can access without Guided gates.
4. **First Snowman Prestige opportunity** exists and can be followed after *discovery*, becomes ready after **one** boss kill, and the stage unlock behaves normally. Other Prestige cards unaffected.
5. Two owned Winter I camps: Select changes respawn; Travel changes position, **not respawn**; death/revive and stage switching retain sane camp selection.
6. Offline feature lesson works without spending Gems; the return hint is not blocked merely by insufficient Gems; description includes supplies. Stored-gear stats are accurately taught without modifying the Change 60 popup copy.
7. Finish Winter II → open Prestige → **close without reset** → unchanged final card; separately, optionally Prestige → unchanged final card after the reset. Respect tutorial reset gate until this optional stage.
8. Save/load and old Guided partial/complete profiles; no repeat rewards, forced re-purchases, reset of accepted progression or broken schema migration.
9. English key completeness/placeholder check; confirm **all 19 non-English catalogs remain byte-for-byte unchanged**, even if they temporarily fall back to English on newly introduced keys. Record the exact localization delta for later handoff.
10. Recheck the small affected UI at both viewport sizes (pointer to scrollable row, World map marker, Stats, Offline, Missions, Prestige) and keep actions tap-safe. Document Android-only verification as pending, not performed.

**Commit:** Use the next available Change number (`Change 61` reserved for this batch), create **one local implementation commit** after focused validation, e.g. `feat(change-61): complete interactive guided onboarding`. Preserve all unrelated uncommitted developer edits (particularly `project.godot`, export preset changes, Playbook, and marketing scripts). Do **not** push, publish, start localization batches, or modify the Playbook/GDD in this task. If the current repo requires a manifest adjustment for new script/resource dependencies, make it surgically without discarding developer edits. Report actual test evidence, changed files, commit hash, new/changed English key count, and any Android checks still needed.
