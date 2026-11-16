# LootFarmer — Change 81: Final Boss Clarity, Boss Keys, Spring Combat & Endgame Progression

**Status:** Approved for implementation in one batch.  
**Base:** Latest LootFarmer repository after Change 80 (`356f07f`) and subsequent developer changes. Inspect **the actual working tree** before editing; the attached/project ZIP is not guaranteed current.  
**Scope:** Seven approved changes below. No player-profile framework work, localization freeze, release upload, or unrelated gameplay changes.

## Operating rules

1. Read the project's current Reusable Game Development Playbook and canonical GDD, then inspect the actual implementations and tests. Follow existing ownership of combat, upgrades, save/load, HUD, animations and localization; avoid duplicate systems.
2. Implement, validate, and **commit locally** as one coherent batch. Do not push, export, upload, publish, or silently bump versions.
3. **Preserve the developer's uncommitted version-42 edits** in `project.godot` and `export_presets.cfg`. Do not stage them. Inspect `git status` before and after; preserve all unrelated work.
4. Maintain save compatibility, including Prestige and Hard Reset behavior. Use legitimate upgrade/action APIs, not UI-only restrictions. Preserve existing item IDs, owned gear, and boss-key progress.
5. English-first localization: add/update semantic English keys, support safe fallbacks for the other 19 languages until the planned localization pass, and visually test long-text layouts. Do not attempt a wholesale retranslation now.
6. Store generated test screenshots/evidence under the Playbook's designated `generated/` locations. Update only the canonical GDD and applicable maintained tests where the approved rules have changed. Do not create a duplicate GDD or routinely rewrite the shared Playbook.

---

## 1. Global Camp Reveal Radius upgrade

### Requested design

The existing **Camp Reveal Radius** is purchased separately for each camp. Replace it with **one global, permanent upgrade** affecting the reveal radius of **every owned camp**, including camps acquired later and camps on other maps.

| Purchased level | Gem cost for this level | Total radius bonus over base |
|---|---:|---:|
| 0 | — | +0% |
| 1 | 10 | +25% |
| 2 | 20 | +50% |
| 3 (MAX) | 40 | +75% |

- Three purchased levels, total cost **70 Gems**. Costs are fixed steps, not a geometric price progression.
- The bonus is global, additive against the base camp reveal radius. Keep other existing reveal-radius/Prestige modifiers functioning according to their intended stacking rules; prevent double application.
- Show **one** upgrade entry in the appropriate general Upgrades area, with current/next effect and cost. Remove per-camp purchase UI; camp screens should reflect the actual effective radius without suggesting a separate purchase.
- Treat it as a permanent Gem upgrade (survives Prestige; Hard Reset clears it), consistent with the current upgrade-persistence policy.
- **Migration:** inspect historical per-camp purchases and preserve reasonable earned value. Migrate once, deterministically, to a valid global level (e.g., max previously owned camp level, clamped to 3, if compatible with existing records); never silently grant unlimited levels, charge again for already credited levels, or corrupt save state. Record the actual chosen policy in the completion report.
- Leave the separate map-exploration radius upgrade and unrelated camp mechanics untouched.

### Acceptance

All camps receive the same purchased global bonus, no per-camp upgrade remains purchasable, prices are exactly 10/20/40 Gems, and save/load/Prestige/migration/Hard Reset behave correctly.

---

## 2. Auto Skill: require the corresponding skill slot first

Auto Skill must **not be purchasable for a slot the player has not unlocked**.

- First automatic skill slot may be bought when the default first manual skill slot exists and current discovery/unlock conditions are met.
- Second automatic skill slot requires the second manual skill slot to have been purchased.
- Third automatic skill slot requires the third manual skill slot to have been purchased.
- Inspect **both** existing upgrade paths (`skill_auto_*`, `skill_auto_slots` or their current replacements), their pricing and saved state. Enforce the prerequisite at the authoritative purchase/action layer **and** visibly in UI; prevent any path from bypassing it.
- Show a concise translated locked reason such as “Unlock Skill Slot 2 first,” with the required slot number. Do not debit Gems for a blocked purchase.
- Existing saves with Auto Skill purchases made before this new restriction must not lose the purchases. If a formerly purchased slot lacks its required manual slot, keep its purchase but do not activate an unavailable slot; restore functionality once the prerequisite is met.
- Do not otherwise change Auto Skill behavior, prices or manual skill-slot prices.

### Acceptance

All three slot combinations, direct API purchases, UI, existing saves, and Prestige are covered by tests.

---

## 3. Increase enemy attack damage in Spring I and Spring II; review skills

Player feedback: enemy attacks in **the last two stages** are too weak. Increase **normal/direct attack damage by at least 50%** from the effective values in the current repository for **Spring I and Spring II**. This includes the intended hostile combatants in those stages; do not silently omit bosses.

**Important:** Inspect how catalog attack values, stage multipliers, normal/boss rules, damage reduction, attack cadence, and skills combine before editing. In particular, determine whether an offensive skill scales from base attack damage or has its own damage formula.

- Target **≥1.50× the previous effective pre-mitigation damage per direct hit** for affected enemies; keep attack intervals unchanged unless a documented defect forces a correction.
- Ensure damaging skills (Strike, Fire, Frost, Lightning, final-boss specials, etc., where applicable) remain consistent with their intended relationship to enemy attacks. If they already scale with base damage, **do not apply the +50% a second time**. If they bypass base damage, explicitly review and adjust as justified.
- Check non-damaging skills (Heal, Focus, statuses, summoning, etc.) for inappropriate interactions; do not blindly multiply healing, durations or status magnitudes.
- Evaluate normal enemy groups, bosses and summoner/helper damage. Balance against realistic **current** Spring I/II player levels and equipment **after Change 80 XP reductions**, with 0, 1 and 3 Prestiges where practical. Preserve a reasonable first-clear path; explain and correct any resulting unavoidable walls without reverting the approved attack increase.
- No changes to Winter, Summer or Autumn combat values unless required to fix an actual regression directly caused by this batch.
- Provide before/after tables for affected normal enemy groups and bosses: direct hit, attack interval, theoretical DPS, offensive skill behavior, and measured damage received in representative combat scenarios. Distinguish measurements from estimates.

### Acceptance

Every applicable Spring I/II enemy has the approved attack increase; offensive skills are audited for correct scaling; representative non-Prestige and Prestiged combat remains playable; no unrelated stage damage changes.

---

## 4. Green Alien: clear final-boss introduction and persistent 13-key objective

### Existing rule to preserve

The Green Alien is sealed until the player collects **13 distinct boss keys** by defeating the other bosses **after discovering the Green Alien**. Previously defeated bosses do not retroactively grant keys. Key progress persists according to existing save/Prestige rules. **Do not change the unlock requirement.**

### First discovery / explanation

The first time the Green Alien is discovered (or the first time the player meets the existing discovery trigger), show a prominent, readable, non-spammy story/tutorial message. Suggested English wording (adapt for readability/localization):

**“YOU ARE NOT WORTHY!”**  
“The Green Alien refuses to fight you. Prove your strength: defeat the other 13 bosses and collect their keys. Return when you have all 13.”

- Present this **once per profile** on first discovery; persist the acknowledgement appropriately. Reopening the objective/help later must remain possible without an intrusive repeating popup.
- If a player tries to attack or select the sealed boss, explain that it is locked and show current `X/13` progress instead of appearing broken. Do not start a fight or consume an action.
- Do not reveal/spoil this final-boss quest before first discovery.

### Persistent objective HUD

After first discovery, show an always-available, compact final-boss key tracker **on every stage**, not just Spring II:

- Incomplete: `Final Boss · Boss Keys X/13` (with a suitable icon).
- Complete but not defeated: `Green Alien · Ready to Challenge`.
- After defeating Green Alien: mark complete and remove the permanent tracked objective (retain completion in normal progress/history).
- Update immediately on a newly earned key, after load, after travel, and after Prestige. Preserve existing mission/Mastery/Prestige follow chips; no collision, clipping, or important text loss.
- Use the HUD's existing rail and notification layout rather than inserting a blocking full-screen panel. On 432×960 and 540×960, ensure labels and numbers remain legible and controls unobstructed.
- Keep `World Clear X/9` as an **independent** metric: it counts enemy types defeated in the world, **not** boss keys. If the current label is confusing, clarify it as `Enemy Types Defeated: X/9` (or equivalent concise wording) without changing its counter semantics.

### Acceptance

Quest stays hidden before discovery; explanation appears only once; locked-target feedback works; tracker persists globally from discovery until victory; keys remain 13 distinct qualifying kills; existing saves are not reset.

---

## 5. Player level cap: 1,000 → **500**

- Reduce the maximum player level to **500** (this supersedes the earlier suggestion of 250).
- Preserve `ceil(12 × L^1.35)` and all approved enemy XP rewards and XP multipliers. No XP rebalance in this batch.
- At 500, show a sensible **MAX** state, no misleading “next level” bar/requirement, and no XP beyond the cap. Audit UI, milestones, objectives, achievements, tutorials and progression scripts for hard-coded 1,000 references or invalid level expectations.
- Keep player level/XP persistence across Prestige as before. On legacy saves above 500, clamp safely to 500 with correct stats/UI; avoid overflow, infinite accumulation, or a save corruption. Define and test what happens to remaining XP at the cap.

### Acceptance

Correct leveling up to 500, cap behavior, safe old-save handling, and no changed XP curve or stage XP payouts.

---

## 6. BOTH Obsidian Sword and Obsidian Axe: extend merge progression to **^500**

The current final-tier Obsidian Sword and Obsidian Axe stop at **^100**. Both should support merge level **^500**, with meaningful milestones at **^100, ^200, ^300, ^400 and ^500**, analogous in **structure and presentation** to the existing high-end outfit progression.

- **Merge level ^500 is not equipment tier 500**: preserve their actual final weapon tier and item IDs. Only the merge cap/progression changes.
- Inspect the current outfit milestone implementation and actual Obsidian weapon formulas/Obsidian Temper bonus. Reuse the existing milestone pattern and UI where possible rather than creating separate ad-hoc logic.
- Design and implement **offense-appropriate** milestone effects for the five thresholds, tailored to Sword/Axe stat identities; do not copy outfit defense/HP/regen rewards blindly. Preserve differentiation between sword and axe.
- Extend the stat/merge progression smoothly from ^100 to ^500; use a controlled post-100 growth curve informed by the current outfit tail behavior. Avoid allowing weapon scaling to undo the approved Critical Damage or boss balance adjustments. Specify the exact milestone effects and scaling in the final report.
- Ensure copy requirements, spare-copy bonuses, manual/automatic merge, maximum-level behavior, stats, previews, card interactions, and saved merge progress agree with the actual system. **Do not spend evolution reserves** that current rules protect. No evolution beyond the existing final tier.
- Existing ^100 owned weapons should become eligible to advance to ^101 rather than reset or lose stats. Respect previous legitimate merge investment and save compatibility.
- Update any Masterwork/Prestige/opportunity checks that incorrectly assume ^100 is now the absolute Obsidian maximum, without silently changing the meaning of already-earned achievements.
- Validate the endgame damage impact with realistic builds, including at/near ^100 and at representative higher milestones. Report outlier risks.

### Acceptance

Both Obsidian weapons can reach ^500 through legitimate merge actions; milestones trigger exactly once at the correct threshold; ^100 saves remain valid; UI/previews and automation match the actual progression; no unintended power spikes.

---

## 7. Important boss key drop/collection animation (using existing art)

After Green Alien discovery, each qualifying **new** boss key should feel like a major progression reward. Use the existing key imagery; inspect both available assets and choose the one that is clearest in-game:

- `res://assets/GUIPackCartoon/Demo/Sprites/Icons/Icons Colored/Lock - Key/Key - Gold.png`
- `res://assets/GUIPackCartoon/Demo/Sprites/Icons/Icons Colored/Lock - Key/Key - Sliver.png` *(filename is spelled “Sliver” in the supplied asset)*

Claude may choose the best visual treatment/animation after inspecting the assets, with this gameplay contract:

1. **Award and save the key immediately** when the qualifying unique boss kill is committed. The animation is presentation, not the source of truth.
2. Show an easily noticed, **large floating key** near the defeated boss; make it readable against the game background.
3. Allow a player to **tap to trigger early collection animation** if feasible on touch. If untouched, the key **automatically** finishes the animation—no reward can be missed or lost.
4. Animate it toward the persistent Boss Keys counter (or an appropriate HUD destination), then acknowledge the new total `X/13` with a restrained pulse/celebration. If a panel obscures the destination, degrade gracefully rather than teleport across unrelated UI.
5. **Do not block movement/combat**, steal joystick touches, cover essential controls, or require staying nearby. The visual may continue during ordinary play; adapt safely to travel, death, pause, panel opening, scene changes, and save/reload.
6. Only show on a newly earned key. No repeat for already collected keys, no key before discovery, no duplicate keys from a repeated reward event or reload. The 13th key should get a distinct `Ready to Challenge` feedback state.
7. Use existing animation/VFX/UI infrastructure and **source assets already in the repository**. No AI-generated images or replacements.

**Presentation guidance, not a mandatory timing contract:** a brief floating/wobbling or turning phase, then a fly-to-HUD pickup. Ensure the key is discoverable without being visually disruptive.

### Acceptance

The actual key is credited exactly once even if the animation is interrupted, skipped, never tapped, or the app closes; visual/feedback matches awarded keys; works on small portrait screens and with overlapping HUD trackers.

---

## Required validation and completion report

### Tests / acceptance matrix

- **Upgrade:** global radius levels 0–3; exact Gem deductions; all camps, future camps, map travel, Prestige, Hard Reset, old-save migration, and no per-camp purchase route.
- **Auto Skill:** slots 1–3 and both purchase APIs; locked UI reason; no currency spent on invalid purchase; previously purchased automation preserved.
- **Combat:** actual Spring I/II direct hit numbers before/after; boss and normal group scenarios; offensive skill effects and cooldowns; 0/1/3 Prestige where feasible; earlier stages unchanged.
- **Green Alien:** undiscovered, first discovery, sealed boss attempts, key progress, save/load, Prestige, travel across eight maps, 13th key, battle unlocked, final defeat; `World Clear` remains distinct.
- **Key FX:** new boss key vs duplicate, tap vs auto completion, scene interruption, pause, rapid rewards, save/reload and UI conflict; state is not animation-dependent.
- **Level 500:** normal level-ups, max XP, old saves above cap, Prestige, any achievement/goal references.
- **Obsidian:** sword and axe ^100/^101/^200/^300/^400/^500, merge gain/stat previews, automation, milestone ownership/idempotency, save/load, boss bonus attributes and realistic endgame balance.
- **UI:** Godot portrait captures at 432×960 and 540×960, with long translations where available; dynamic objective widths, message stacking, upgrade labels, merge details and the key animation.
- Run focused probes, parser/headless tests and the maintained full suite. Current historical baseline has **16 known failures**; verify no *new* failures, distinguish fixed vs existing, and do not falsely claim the suite is fully green.
- Protect real player saves: run probes against dedicated isolated save paths, not the developer's profile.

### Report back in chat

Give a concise implementation summary by item, the choices made for migration and Obsidian milestones, exact before/after enemy and skill damage tables, simulations and limitations, how the key animation behaves, screenshots/evidence locations, the regression comparison, any strings pending translation, and the **local commit hash**. Confirm `project.godot`/`export_presets.cfg` version-42 edits remain untouched and **nothing was pushed, built/exported, or uploaded**.
