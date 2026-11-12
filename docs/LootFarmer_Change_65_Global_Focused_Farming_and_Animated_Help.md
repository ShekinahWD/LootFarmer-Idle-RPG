# LootFarmer — Change 65: Global Focused Farming, Animated Basic/Help Tutorials, and Guided First Attack

**Status:** Approved for implementation. **Implement in the current Git working tree**, not from an older ZIP. This follows Change 64 and its separate discovery-banner correction (commits `9a078c4` and `587e563`).

**Approval/authorization:** The developer explicitly said **write code**. Make the implementation, update appropriate game-specific documentation, validate, and create a **local Git commit**; do not push, export, publish, or touch unrelated uncommitted/untracked work.

## Source of truth and Playbook rules

1. Inspect the latest repository first: `scripts/game/{simulation,campaign,game_ui,tutorial_guide,guided_progress,onboarding}.gd`, `data/game/catalog.json`, `scripts/autoload/save_service.gd`, current profile/save normalization, tests, `localization/en.po`, `tools/localization_pending.json`, `docs/LootFarmer_GDD.md`, and `docs/LootFarmer_Upgrade_Catalog.md`. Paths are leads, not permission to assume the older uploaded snapshot matches the latest commits.
2. Follow **Reusable Game Development Playbook** sections **18.1–18.8** (one concept per card, shared reference deck, mode separation, honest gesture completion, profile persistence, contextual help, input-transparent guidance/arbitration), **16.3**, **19–20** (stable modal geometry and Android sizing/safe areas), **61** (save migration), and relevant localization/test guidance. **Do not edit the Reusable Playbook.**
3. Preserve all approved Changes 59–64: 35-step Guided progression and subsequent corrections, movement/target gesture, onboarding economy, Prestige defeat gate, panel stability, banners/toast arbitration, visual camp teleport, offline rewards, and all balance changes. Adjust only the implementation surfaces needed for Change 65.
4. Make the **Basic opening and Settings Help use exactly one tutorial-card registry, identical text/animation renderer and identifiers**. Do not create a separate deck with divergent content. Never use live simulation actions to run demo animations.

---

## A. Focused Farming: one global unlock for 25 Gems

### Desired player behavior

- **Focused Farming** becomes a **single global, one-rank Player upgrade**, available in **Player → Upgrades** (or the latest equivalent Player-upgrades surface), costing **exactly 25 Gems**. It has no per-stage/per-enemy multiplier. A single purchase enables Focused Farming across **all eligible discovered enemy types, loadouts, and reached stages**. No subsequent charge to switch types, variants, stages, or farming spots.
- Remove the **per-enemy Focused Farming *purchase*** from all enemy upgrade tabs, descriptions, and price calculations. **Keep the enemy's Farm / Stop Farming action** and existing World/Farming Guide actions for selecting/ending a focus. If not yet globally owned, display a clear locked reason and a path to the Player upgrade, without exposing an accidental free unlock.
- Preserve the existing eligibility rules: no undiscovered enemy type/hidden spot, correct reached stage/variant constraints, same priority for focused enemies versus actual attackers, same auto-return/farming movement, manual movement cancelling focus, pause/combat/travel constraints, and **travel must not modify respawn**.
- **Enemy-specific automation remains per enemy type** with its current prices, prerequisites, persistence, and controls: Auto-Collect (and related collection upgrades), Auto-Merge, Auto-Evolution. These are **not** converted into global upgrades. Do not confuse the Focused Farming upgrade with the unrelated **Focus skill** or target drag.
- Already-owned global upgrade is clearly shown as **Owned / Max**, with no repeated purchase or stale enemy upgrade row. Global purchase and unlock state must be read from the same gameplay getter used by `sim.focus()` (not just a UI condition). The existing focused target/variant can remain selected across save/load as previously supported; do not clear it accidentally during migration.

### Existing saves and resets

- **Versioned and idempotent migration**: if an old profile owns Focused Farming for **at least one enemy**, grant global Focused Farming rank 1 on load, without charging another 25 Gems. If it owns none, global rank remains 0. If both old and new records exist, global remains rank 1. Remove/retire legacy per-enemy Focused Farming upgrade keys from operational lookups and UI so they cannot accidentally charge or unlock twice. Preserve all unrelated upgrades and current focus target. Repeated load/save/Prestige must not duplicate purchases.
- **No automatic Gem refunds or compensation**, because that economic change was not approved; if multiple old per-enemy purchases exist, note the count in the implementation report so the developer can decide separately whether to compensate. Do not quietly invent refunds.
- **Prestige retains** the global unlock, consistent with current purchased-upgrade retention rules. **Hard Reset clears** it. Keep the existing save schema and upgrade migration conventions; bump a schema version only if the present save architecture truly needs it, and migrate old fixtures.
- Update the existing first-purchase `focus_unlocked` notice / Guided Focus hint: it now originates from the **Player upgrade**, and the subsequent hint should guide the next actionable **Farm** choice (enemy or existing map workflow). Never point at an old enemy purchase, a locked control, or a UI element that cannot be tapped. No unsolicited pointer in Basic or None. Profiles that already owned Focus and migrate should not be made to repeat a first-purchase tutorial.

### Core verification

- Cost exactly 25, single purchase; eligible farms across at least two enemies and two maps, no extra charge; switch target or movement stops farming; locked/unseen spots still rejected; existing auto-collection/merge/evolution untouched.
- Save/load with zero, one, and multiple historic enemy Focus purchases; legacy + new hybrid; repeat migration; Prestige; Hard Reset. Verify that only Focus changes, not other upgrades/currency.

---

## B. One shared animated tutorial-card library (14 cards)

### Overall structure

**8 essential Basic onboarding cards** (only these appear in the one-time Basic opening) + **6 advanced Help cards** (not force-shown at startup). **All 14** are accessible through **Settings → Tutorial and help** (may rename the visible section to **Help & Tutorials** if that is already compatible with the UI; use localization keys). Guided and None may voluntarily open Help, with no restrictions on reading a guide for an as-yet locked feature: cards explain it, but don't grant access or reveal undiscovered enemy identities.

Do not reduce Basic to uninformative titles. Each card contains:

- **Title** (short), **one primary action/instruction** (prominent), **one short support explanation**, and **a distinct actual visual demonstration** built with existing game art/UI elements. Keep copy concise, localizable, and accurate to the current game's mechanics; adjust wording only when facts verified in current code require it, and report any such adjustment.
- **An animation that visibly teaches the real input or outcome**, not a generic icon pulse. Aim for a readable, seamlessly looping **~4–7 s** illustration (longer if needed for two closely related actions). Tutorial demo has **no effect** on actual stats, inventory, XP, combat, currencies, quests, saves, or unlocking. Use lightweight Godot-native scene/Control/sprite/tween/AnimationPlayer elements, reusing existing licensed assets; do not introduce generated AI images or new downloaded asset packs.
- Restart/rewind on switching cards; play only when visible; pause with game/modal pauses; avoid extra idle CPU work and live world side effects. Respect input accessibility (touch and optional reduced-motion/static keyframe fallback where feasible), and clear contrast at both 432×960 and 540×960 with safe areas/longer localized strings.
- A visual controller showing **Previous**, **Next**, position **N/14** (or **N/8** during Basic), **Back to Topics** (Help only), and **Close**. Keep stable panel geometry when cards advance; no text, animations, or buttons beyond screen bounds.

### Approved content and animation direction

These are the **implementation-ready proposed English messages**, finalized here to avoid building the animations before writing the copy. Verify every claim against live gameplay (especially where GDD notes were superseded by later changes). Preserve each card's concept and storyboard if a very small wording correction is required.

| ID | Title | Primary line | Support line | Required looping visual demonstration |
|---|---|---|---|---|
| `movement_combat` | Movement & Combat | **Drag the joystick to approach an enemy.** | **Your hero automatically attacks enemies within reach.** | Ghost thumb pushes *the actual joystick shape*; hero moves toward a nearby foe, stops, then performs an attack. No demo hit modifies world state. |
| `manual_target` | Choose Your Target | **Drag from your hero to an enemy, then release.** | **Use this gesture to change who your hero attacks.** | Highlight hero, trace drag line from hero to enemy, release marker, selected target ring, attack follows. Show origin as hero, never joystick. |
| `collect_equip` | Collect & Equip | **Collect dropped gear, then equip it.** | **Equipment strengthens you; stored gear also grants bonuses.** | Enemy falls, pickup appears, finger taps loot, item fills inventory, chosen weapon/outfit equips, stats rise. |
| `merge_gear` | Merge Equipment | **Merge two copies of the same item.** | **Merging increases the item's strength and merge rank.** | Two identical equipment icons/copies combine through actual Merge control into one rank-increased item. Never depict merging unrelated items. |
| `player_upgrades` | Player Upgrades | **Buy upgrades to strengthen your hero.** | **Focused Farming unlocks globally for 25 Gems here.** | Open Player Upgrades; highlight global Focused Farming 25-Gem button; purchase -> Owned; show one unlocked Farm action. |
| `enemy_automation` | Enemy Automation | **Upgrade each enemy type to automate its loot.** | **Auto-Collect, Auto-Merge and Auto-Evolution are type-specific.** | Open a particular enemy's upgrades; illuminate its Collect/Merge/Evolve options and show a loot/merge/evolution micro-loop, each visually distinct. |
| `missions` | Missions & Rewards | **Follow a mission and claim its completed reward.** | **Missions give you goals and additional resources.** | Open mission, tap Follow, demonstrate progress, ready state, Claim, reward icon. Avoid implying automatic claims by default. |
| `explore_camps` | Explore & Teleport | **Discover camps, then select your destination on the map.** | **Unlock camps to travel and choose where you respawn.** | Move through fog, discover/buy camp, open *visual teleport map*, tap another owned camp, Confirm; separately highlight Respawn Here (travel does not change it). |
| `skills_supplies` | Skills & Supplies | **Equip skills and supplies before tougher fights.** | **Skills assist combat; supplies can heal or grant boosts.** | Skill slot equips and skill triggers; Health Potion in supply slot heals; show the distinct slots/controls, not a new nonexistent feature. |
| `offline_rewards` | Offline Rewards | **Claim rewards when you return to the game.** | **Offline upgrades unlock more reward categories.** | Return receipt shows Coins/Gems and zero-locked Gear/Supplies; open Offline upgrades; unlock one category; future receipt demonstrates the newly available category (never retroactively update prior receipt). |
| `weapon_evolution` | Weapon Evolution | **Meet the merge and copy requirements to evolve a weapon.** | **Evolution advances a weapon to a stronger tier.** | Show compatible same-tier weapon plus merge rank and extra-copy requirement; evolve into next-tier icon, using *current game thresholds* (do not hardcode obsolete ^100). |
| `prestige` | Prestige | **Defeat the Snowman and complete Prestige opportunities.** | **Prestige grants permanent cards when you reset your run.** | Snowman defeat unlock state -> opportunity ready -> Prestige confirmation -> permanent card joins owned collection -> new run. Showing menu on discovery is different from being able to reset. |
| `map_details_mastery` | Map Details & Mastery | **Explore maps and purchase Map Details to learn more.** | **Map Mastery tracks lasting exploration and achievements.** | Explore fog/percentage, Map Details increases to show map markers/info, Mastery categories fill and give completion reward; keep these distinct. |
| `advanced_farming` | Advanced Farming | **Choose a discovered spot and tap Farm.** | **Move manually to stop farming or choose another spot.** | On visual World/Farming Guide or enemy panel, select visible eligible location -> Farm -> hero routes/fights/collects -> joystick input stops; global unlock stays owned. |

**Accuracy notes:** Coin/Gem category unlocks, full gear stats, skill automation rules, auto-use, crafting thresholds and Map Detail levels must match *current* code. For offline item categories, use real current receipt categories (Change 64: Coins, Gems, Weapons, Outfits, Supplies); the animation can group Weapons/Outfits as Gear but must not imply that all items unlock together if they don't. Do not turn an animation into a gameplay grant.

### Information architecture and navigation

1. **Help landing screen:** `Choose a Topic` (category browser) and `Read All Tutorials` (complete 14-card sequential reader). Show categories: **Combat**, **Equipment**, **Farming**, **Progression**, **Permanent Progression**. Map cards to exactly one clear category; preserve a logical order and avoid duplicate cards/data. Example: Combat (Movement, Manual Target, Skills/Supplies), Equipment (Collect/Equip, Merge, Weapon Evolution), Farming (Player Upgrades, Enemy Automation, Advanced Farming), Progression (Missions, Explore/Camps, Offline Rewards), Permanent Progression (Prestige, Map Details/Mastery). Consider putting Map Details/Mastery under Progression if that better matches the final UI; its placement must be unambiguous.
2. **Choose a Topic:** category list -> list of titled cards -> selected card opens with animation, text, Previous/Next (within the full collection or clearly indicate category-local order), Back to Topics/Close. Never require reopening the category for the next card.
3. **Read All Tutorials:** start at first card (or offer **Continue where you left off**), Previous/Next across all 14; **optional Auto-Advance** (default OFF) so players who want to see them one after another *without tapping Next* can do so. Auto-Advance waits for **at least one animation loop and a comfortable reading interval**, pauses on game background, menus, text interaction and manual navigation; easy Pause/Resume and off. Last card stops (never wraps automatically). Manual controls always work. This reconciles both user requests: choose just one topic, or let the entire collection play sequentially.
4. **Viewed / Not Viewed:** mark an individual card seen after a deliberate advance/close or a completed readable auto-advance, not merely because it was briefly visible. Persist viewed cards and `last_help_card` across ordinary saves and Prestige; Hard Reset clears them. Store IDs, not numeric indices; adding cards later must not invalidate saved progress. Reading Help in Guided/None must not mark **Guided lesson steps** or grant actual progression.
5. **Basic opening:** uses the first **8 cards** from the same registry and viewer in `N/8` order, automatically or manually advanced, with Previous, Next, Skip Overview, and Close/finish as appropriate; avoid inadvertently replaying after save/load or Prestige. Existing Basic can skip, and normal gameplay remains unaffected. Maintain the existing *THE ROAD AHEAD* sequence and avoid duplicate final cards.
6. **Cross-mode discoverability:** the three modes must explain where reference help lives, but respect None's opt-out:
   - **Basic:** a concise note at the end of the 8 cards / existing ending card: **“Want more help? Open Settings → Help & Tutorials. Pick a topic or read all 14 guides.”** No extra forced 14-card experience.
   - **Guided:** append a concise Help discovery line to its existing **THE ROAD AHEAD** finale; **preserve that card's title, content, and action** otherwise.
   - **None:** on the *mode-selection chooser only*, a persistent unobtrusive one-line reference **“You can explore Help & Tutorials anytime in Settings.”** After choosing None, no instructional notification, pointing hand, autoplay Help or forced card; help remains available if opened voluntarily.
   - Make Settings → Help easy to find in all modes, respecting actual menu state. Do not force reopen a chooser to access Help. A user who switches mode or opens Help manually never loses completed tutorial state.
7. **Long language safety:** new English keys + pending-translation manifest; **do not edit the 19 non-English catalogs** in this Change 65 implementation batch. Existing translated keys remain intact even if unused. Since onboarding is a critical surface, gracefully handle untranslated keys and screenshot English and one long-copy locale at both target sizes.

---

## C. Guided tutorial: the first attack must be manual

**Approved intended experience:** During the initial Guided “drag from the hero to the enemy” targeting lesson, the hero must **not automatically attack nearby enemies** before the player actually performs that manual drag. Once the player has performed the gesture and the hero has made the **first valid attack on that manually selected enemy**, Guided teaches: **“Auto-Attack Enabled! Your hero now attacks nearby enemies automatically. Drag from your hero to an enemy whenever you want to change targets.”** Then ordinary auto-attack behavior resumes and stays enabled.

### Required implementation (surgical, state-driven)

1. **Narrow-scope combat gate:** disable **automatic target acquisition / unattended player attack** only while a *new Guided profile* is at the required first-target lesson and has not made its first manual attack. Do not disable enemy attacks or unrelated simulation systems, change drops/damage/HP, introduce training enemies or give invulnerability. Basic/None combat remains identical to normal gameplay. Do not globally disable autoattack outside the tutorial.
2. **Real gesture:** the user must drag **from the hero (not joystick)** to a currently valid enemy and release. Preserve the existing input-transparent gesture illustration (start ring, actual enemy end ring, moving pointer, line). An ordinary tap or auto-target finding an enemy does not complete the requirement.
3. **First-attack completion:** after a valid gesture, allow the hero to approach and perform an actual basic attack on the selected enemy even though unattended auto-target acquisition remains gated. Complete the gated lesson on **the actual valid attack resolution**, not merely finger release or selecting a target. If the game's hit resolution counts blocked/missed attacks differently, use the event closest to "hero performed a real targeted attack" and explain what the check means; do not complete on animation-only visuals. After the attack, restore normal auto-targeting immediately and show the short, dismissible autoattack explanation without blocking subsequent combat.
4. **No soft locks:** if a selected target dies/disappears, moves outside eligibility, or player dies before the first strike, return to the gesture instruction on a new eligible target. The existing **no-eligible-enemy** escape must still work: count only truly unavailable *active* seconds, allow the player to continue and restore normal autoattack on an escape. Ordinary waiting while a valid target exists must not skip. Save/load mid-gesture, between selection/attack, on death/respawn and after completion must produce a consistent state; avoid granting the first attack retroactively through save/load or passive damage.
5. **Lesson order and legacy saves:** keep the current **35 ordered Guided steps** unless an extra step is truly required; prefer a substate of the `target` lesson and a one-time post-attack explanation. Updating completion from `select_target` to first hit requires carefully updating `guided_progress.gd` and its migration/normalization. Any profile past the first kill, completed first targeting lesson, or past the onboarding window must never be re-gated or lose autoattack; old profiles must not replay the new mandatory lesson. Prestige never reenables the gate, Hard Reset restores the fresh chooser.
6. **Other systems:** an already-progressed/old Guided save, Basic/None, manual attack outside tutorial, Focused Farming, skill autocast, enemy retaliation, and boss aggression remain unchanged. The tutorial may use only the **real combat/gesture pipeline**, not a fabricated combat outcome.
7. **UI priority:** after enabling autoattack, its explanation must not cover the target, block movement or compete with top banners/Modals; route through the existing Change 63/64 guidance arbitration and avoid panel jumps.

### Targeted checks

- Fresh Guided at target step: standing beside an enemy and waiting produces **no automatic player attack/damage**; a valid manual drag causes approach/attack; only the real first attack unblocks auto-attack and displays the explanation once. Verify failed drag, bad target, premature target death, movement, player death/respawn, empty map escape, pause/resume, save/load before selection, after selection, after attack, after Prestige, and Hard Reset.
- Fresh Basic and None: automatic player attacks remain active immediately with **no tutorial gate**. Old Guided save already past target: no new gate. Verify gesture illustration stays aligned with hero and enemy at 432×960 / 540×960 and doesn't take touches.

---

## D. Validation, docs and handoff

### Focused validation, not marathon QA

- Add/update a **Change 65 focused probe** for global purchase/migration/Prestige/Hard Reset, enemy automation unchanged, shared 14-card registry and individual navigation/sequential mode/Auto-Advance persistence, and first manual attack gate with failure/escape/legacy states. Validate each mode (`Guided`, `Basic`, `None`).
- Inspect **real rendered screenshots** at **432×960 and 540×960** of: Player global Focus owned/locked; enemy panel Farm/Stop/automation; Basic cards 1/2/5/6/8; Help category browser and an advanced card; Auto-Advance controls; first Guided targeting gesture + post-attack message; longest translated/expanded copy. Check touch-target geometry, safe areas, card animation containment, panel height stability and orientation.
- Run relevant existing focused onboarding, farming, save-migration, upgrade, guided, help and localization validators, adjusting obsolete expectations only where the approved feature changed. **No full test suite, long balance simulation, export or physical Android claim**. Report actual tests with pass/fail counts and any pre-existing failures separately (earlier Change 64 reports of obsolete Snowman/Prestige test fixtures may still exist).
- **Avoid screenshots in the repo unless needed as concise evidence**; use small purposeful evidence rather than tens of megabytes of duplicate frames.

### Documents and localization

- Update the **game-specific** `docs/LootFarmer_GDD.md` and `docs/LootFarmer_Upgrade_Catalog.md` to reflect the new global upgrade and teaching/navigation flows, reconciling outdated contradictory historical statements only in the sections these changes actually own. Leave historical notes intact, or mark them superseded; don't rewrite history.
- All new/mutated English copy belongs in `localization/en.po` with proper keys, placeholders and documented pending entries (`tools/localization_pending.json` and the current manifest convention). Do **not** touch the 19 non-English `.po` files; they belong to a later translation pass, including the still-outstanding Changes 60–64/65 strings. Use localizable category names, buttons, captions, statuses and help discovery text (no hardcoded English UI).
- Do not create a new independent tutorial renderer, player-save subsystem, farm-selection system, notification stack, or test harness if the existing one can be extended.

### Git and report

- Preserve user edits to `project.godot`, `export_presets.cfg`, the Reusable Playbook, `add_speed_blur.py`, and all untracked assets; **stage only Change 65 files**. Commit after focused validation:

  `feat(change-65): global focused farming and animated tutorial help`

- Report: file list; exact global-upgrade migration behavior (and how many legacy records can be found, if tested); all 14 animations working; Guided first-attack outcome/escape; 432×960 & 540×960 screenshots; localization keys; check counts and failures; commit hash. **Do not push, build/export, publish or overwrite the developer's work.**

### Acceptance checklist

- [ ] Focused Farming appears exactly once in **Player Upgrades**, costs exactly **25 Gems**, persists through Prestige and works on all eligible stages/enemies.
- [ ] Enemy panels retain **Farm/Stop** and per-enemy **Auto-Collect, Auto-Merge and Auto-Evolution** with unchanged pricing/rules.
- [ ] Old saves with per-enemy Focus purchases receive global unlock exactly once, without losing unrelated upgrades/targets/currencies.
- [ ] Basic presents **8 concise, distinct animated cards**; the full Help library has **14**; both share the same data and animation system.
- [ ] Help offers **Choose Topic**, **Read All** with Previous/Next, optional Auto-Advance, Viewed/Not Viewed, and resume progress.
- [ ] **All three onboarding modes** make Settings Help discoverable, while None never receives an unsolicited instructional overlay.
- [ ] Fresh Guided's first attack **requires the manual hero→enemy drag**, then a real attack; ordinary autoattack begins afterward, including across save/load, without harming older profiles.
- [ ] No regressions in tutorials, overlay arbitration, UI layout, Prestige, farming, or translations; capture-based checks at both phone sizes.
