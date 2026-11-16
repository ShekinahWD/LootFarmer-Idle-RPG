# LootFarmer — Change 79: Auto Farm, Unified Reroll, Objective HUD, Offline Skills & Boss Balance

**Status:** Approved for implementation. **Scope:** The pending gameplay, balance, and QoL changes below. **Excluded:** Automated testing-player profiles / Playtest Framework Phase 2.  
**Starting point:** Claude's **current live repository**. Change 78's five fixes are already committed as `1cde5b5`; Change 77's Camp Supplies is committed as `8f110ef`. Do **not** reimplement either batch or replace live files with an older ZIP.  
**Version context:** Google Play **Release 40** was uploaded to **Internal Testing**, not production. Game version and Android version code currently **41**. Do not reuse code 40 or upload/push anything.

## 0. Working rules

1. Read the repository's **Reusable Game Development Playbook**, current GDD, implementation, test harness, and relevant current docs before editing. The latest code and data are the authority, not assumptions from earlier reports.
2. Inspect the working tree first. Preserve existing uncommitted edits and untracked work; **especially preserve** the uncommitted `docs/LootFarmer_Change_78_Boss_Balance_Report.md` and `docs/Change_78_Boss_Balance_Evidence/`. Read those actual files, not merely a chat summary.
3. These changes **are approved**, including authority for Claude to **choose, implement, test, and document the boss balance solution**. Do not stop after making balance recommendations, and do not request another approval for the boss solution. Use judgment and evidence, avoiding unrelated redesigns.
4. Changes that affect game mechanics, UI text, or progression must have corresponding GDD/localization/test updates. Keep the Playbook itself untouched unless a genuinely reusable process lesson requires a separate, justified change.
5. Keep the automated player-profile work entirely out of this batch; existing test utilities may be used to verify balance but do not implement new player profiles or Phase 2 features.

## 1. Auto Farm: return directly to the selected spot after death

**Observed problem (notably Summer II):** After dying and respawning, Auto Farm travels toward the previously selected farming location but interrupts travel to target/attack enemies encountered along the route. It can repeatedly die before ever reaching its intended spot.

**Required behavior:**

- Preserve the chosen farming position across death and respawn. During **post-respawn return**, prioritize movement to that spot over automatic target selection, auto attacks, skills, and enemy pursuit.
- Do not stop to fight enemies encountered on the way, even if they are attacking the player. Continue navigating until arrival, unless genuinely blocked/dead or the user cancels/changes the mode.
- At the farming spot, resume the existing Auto Farm combat behavior and attack enemies that approach. Do not wander away from the selected farming location to pursue targets.
- This special priority applies only to Auto Farm's return-to-spot state, not manual movement or ordinary combat outside that state. Respect valid manual user overrides, pause/panels, map changes and mode cancellation.
- Fix state priority/root cause rather than repeatedly restarting movement every frame. Use an appropriate arrival tolerance and make sure movement does not oscillate near the point.

**Tests:** Interrupted travel with enemies attacking; multiple consecutive deaths; saved/selected spot retained; reaching spot resumes attacks; user cancels or changes destination; realistic Summer II encounter.

## 2. Equipment: one reroll button, individual stat locks

**Replace per-stat reroll buttons** with **one `Reroll Stats` button per equipment item**, including boss-dropped **weapons and outfits** with the two bonus attributes added/fixed in Change 78.

- Each attribute row gets a lock/unlock control. The controls distinguish regular attributes from boss bonus attributes where needed for pricing.
- Pressing `Reroll Stats` makes **one atomic reroll operation** for **all currently unlocked** attributes. Each locked attribute keeps **both its stat identity and its numerical value**; preserving only the stat type is insufficient.
- Use existing per-type reroll generation constraints, currency, base price, stat rules and any existing discounts. Preserve boss bonus-attribute classification; do not accidentally convert a boss bonus into a regular stat or duplicate stat slots. Ensure resulting stats are correctly reflected when equipped, merged, persisted, and reloaded.
- The reroll is unavailable if **all attributes are locked**; it must not charge currency or silently unlock anything. With zero locks it rerolls all eligible attributes at the normal base price. Insufficient funds must not partially mutate attributes.
- Lock state must belong to the **specific equipment item**, not to stat names shared by other items, and must survive relevant UI rebuilds and saves/reloads. Handle item replacement, merges, removal and older saves safely; no lock may migrate to unrelated gear.
- Show the exact new total cost as locks toggle, immediately before purchase. Use integer rounding consistent with the current price/currency system; the charge and shown amount must agree. Make the layout touch-friendly and readable in portrait.

### Approved additive pricing (not compounding)

`final_cost = base_reroll_cost × (1 + 0.20 × locked_regular_attributes + 0.40 × locked_boss_bonus_attributes)`

For example, if the base cost is 100: no locks = 100; 1 regular = 120; 2 regular = 140; 1 boss bonus = 140; 1 regular + 1 boss bonus = 160; 2 regular + 2 boss bonuses = 220.

- The **+20% / +40%** additions are calculated relative to the same base cost, not successively multiplied.
- Apply the pricing only to **locked** attributes; boss bonus attributes that are *unlocked* add no premium.
- Test 0/1/multiple/all locks, combinations of regular and boss bonus locks, weapons/outfits, saves, merges, and transaction rollback on insufficient currency.

## 3. Followed Prestige / Mastery objective text: never hide the required action

**Observed problem:** A followed objective with a long enemy name is cut off, leaving only part of the name and obscuring **what the player needs to do**. Example: a Summer Mastery objective should clearly read **`Defeat Teal Dinosaur`** and show its progress/target when applicable.

- Keep the full **action + target** understandable. Do not prioritize a decorative card/category title over the necessary instruction.
- Make the relevant follow-tracker content wrap to multiple lines or otherwise adapt its layout without clipping essential action text or meaningful progress. Expand vertically only as needed; avoid HUD overlap with controls, enemy name, minimap, notifications or other follow chips.
- Preserve the existing followed-objective interaction, objective counts, stage associations, and tracking logic. This is primarily a presentation correction, not a change to Prestige requirements.
- Apply to followed **Prestige, Mastery and mission** text using their real localized strings, including longer translated labels and enemy names.
- Validate at least **432×960** and **540×960**, plus long-text localization and normal combat HUD visibility. Capture before/after screenshots.

## 4. Enable skill items in the Offline Rewards system

**User request:** "Unlock offline skills."

**Implementation interpretation for this batch:** Allow **skill-item copies to be earned in the existing Offline Rewards system**, parallel to the existing offline weapon, outfit and consumable unlocks—not automatic skill casting or offline combat. The existing GDD explicitly says "no offline skills"; this new request supersedes **that restriction only**. Do not invent unrelated offline skill usage or passive skill effects.

- Inspect the actual offline reward catalog, purchase/unlock UI, earning/claim paths and item eligibility rules. Add a clearly named **Offline Skills unlock** to that progression using the established upgrade architecture; if the surrounding system uses a separate rate upgrade per eligible item class, support a corresponding skill rate upgrade consistently.
- **No new discoveries while offline:** only skill identities already owned/in positive stock at departure are eligible, matching current offline item rules. Do not generate unowned skills or change their rarity, skill functionality, activation, cooldowns or combat effects.
- Respect the existing offline duration cap, offline item rewards, currencies, pending claim persistence, safe stacking/capacity rules, Prestige persistence and Hard Reset behavior. Do not duplicate rewards through multiple claims or save/load.
- Set unlock/rate costs and earning rates using the existing offline item economy as a **design reference**, checking skill drop rarity and progression so offline skill income does not become disproportionately strong. Document exact chosen values and rationale in the completion report; avoid changing unrelated offline economics.
- Make the unlock discoverable in the appropriate upgrades and offline earnings UI with correct cost, disabled state, effects and localization/fallback. Update the GDD's old "no offline skills" statement to reflect the newly approved behavior.
- Validate locked versus unlocked cases, empty eligible skill stock, owned skill stock, varied offline durations, repeat claims, save/load, capacity handling and Prestige/Hard Reset.

**Boundary:** If repository terminology reveals that "offline skills" means something materially different from skill-item rewards, **do not silently implement an unrelated interpretation**. State the discrepancy in the final report; otherwise proceed with the interpretation above rather than blocking the rest of the batch.

## 5. Boss balance: investigate, decide, IMPLEMENT, and report

### Authority and objective

Claude is explicitly authorized to make the final balanced choice **and implement it in this batch**, including changes to boss HP, damage, skill selection/cooldowns and, if justified, the **boss-specific Prestige card effects**. The earlier Change 78 boss investigation was report-only; **this task lifts that restriction**.

**Player feedback:** Bosses from approximately **Summer II onward** feel underpowered. Winter I, Winter II and Summer I have felt good, but **do not use early bosses as numeric or difficulty references for later stages**. Each stage is balanced against its **own** player progression, expected gear/evolution, upgrades, Prestige state, normal enemy groups and encounter mechanics. Later bosses can and should become appropriately more threatening as player power expands.

### Existing evidence to inspect (do not treat as definitive)

Read `docs/LootFarmer_Change_78_Boss_Balance_Report.md` and `docs/Change_78_Boss_Balance_Evidence/` from the live tree, then independently verify important assertions against current code and repeat representative tests. Claude previously reported:

- Normal enemies become group attackers around Summer II; a six-enemy encounter can sustain greater damage than its stage's boss.
- Several late bosses are nearly harmless to realistic players with approximately three Prestiges because of boss-specific Prestige bonuses.
- **Elephant, Squirrel, Sunflower** lack a damaging skill in the tested implementation; some later boss skills may be non-threatening even after Change 78's skill-priority fix.
- Some Spring II boss fights last roughly six minutes and consume 20–30 potions, becoming HP sponges without meaningful danger.
- The earlier tests had proposed selective HP decreases/damage or skill changes, but did **not** validate the final boss **Green Alien**. Do not apply those earlier suggestions blindly; test Green Alien too.

### Required approach

1. Enumerate **every boss on all eight stages**, including multiple bosses per stage and the **Green Alien**. Record current HP, normal attack damage/interval, skill damage/conditions/cooldowns, and normal enemy-group comparisons.
2. Audit the actual order of combat, post-respawn enemy skill state (fixed in Change 78), attack frequency, concurrent attackers, player mitigation, equipment and boss bonus attributes, potion economy, and effects/stacks of all relevant Prestige boss cards. Identify root causes, not just raw DPS differences.
3. Test realistic **stage-specific builds**, covering both little/no Prestige and multiple-Prestige players (roughly the 2–4 range seen in prior playthroughs), without making either group impossible or trivial by design. Use existing deterministic combat/simulation facilities; **do not build new testing profiles**.
4. Compare stage-relevant boss encounters with the dangerous normal groups at the **same stage**: measured actual damage taken/time-to-defeat/time-to-player-death, boss skill frequency, survival HP and potion demand. Distinguish idealized DPS from actual measured outcomes.
5. Explore competing solutions (including Prestige boss-card scaling/stacking, targeted damage/skill adjustments, boss HP reduction and encounter pacing); select the **simplest robust combination** that maintains meaningful challenge in both no-Prestige and multiple-Prestige progression. Avoid blanket damage multipliers or simply making bosses one-shot players. Keep boss cards meaningful, not useless; preserve card ownership, IDs, set bonuses and older saves if modifying effects.
6. Prevent excessively long, low-threat boss fights (especially Spring II) without making fights trivial, and fix clear **Summer II** boss under-threat. Avoid changing bosses that are already satisfactory for their stage unless test evidence supports it.
7. **Implement the chosen balance changes**, run/broaden reproducible tests to check them, iterate until the evidence supports the result, and document exact modifications. The final report must plainly state any tradeoffs or limitations rather than declaring balance proven from synthetic tests alone.

### Required boss report (include in this batch, not just advice)

Update/reconcile the existing Change 78 boss report or produce one concise Change 79 report with:

- All-boss table: **stage / boss / before→after HP / damage / attack interval / skills / rationale** (explicitly mark unchanged bosses).
- Comparison for each affected stage of dangerous normal-group measured damage versus boss measured damage.
- For tested stage-specific, no-Prestige and multiple-Prestige builds: before/after fight duration, damage taken, survival outcomes and potion usage; expose the assumptions and seeds/reproduction commands.
- Effects and exact values of any modified boss-related Prestige cards, including persistence/migration decisions.
- Alternatives considered, why the selected solution was chosen, unresolved risks and what to watch during Android playtesting.

## 6. Regression, UX and release safeguards

- Verify the latest Change 78 fixes remain intact: enemy skill priority, next-merge stat gains, font clarity, **two boss attributes on every boss-dropped gear type**, and reduced boss automation prices. Do **not** reimplement these unless a new regression is found.
- Verify Change 77 Camp Supplies still grants once per camp per Prestige run, with a deferred reward if full.
- Add focused repeatable tests for each change in this brief; run the maintained full suite. There were **16 known baseline failures** after Change 78 (`52/68`); compare error lines to baseline and explicitly call out **new** failures rather than dismissing them as old.
- Confirm UI at 432×960 and 540×960 and relevant localization; validate actual use on phone later (automated render does not equal device certification).
- Maintain backward compatibility for equipment reroll locks, Offline Skills upgrades and any changed Prestige card mechanics. No silent save corruption, duplicate rewards, or free purchases.
- Preserve current game/version code **41** (Release 40 already used for Internal Testing). Do not alter Android package ID, signing, export presets, marketing assets or store media unless directly required and justified. **Never push, export/upload to Play, or publish automatically.**
- Keep the working tree's unrelated uncommitted/untracked files intact; inspect staging before commit. Commit the validated implementation locally, with an appropriate `Change 79` message and report the hash. The report/evidence must not be left in an ambiguous uncommitted state: state exactly what was committed and what remains uncommitted, without staging unrelated user files.

## 7. Final response required from Claude

1. Summary of **Auto Farm**, **Unified Reroll + additive locks**, **Followed objective HUD**, **Offline Skills**, and **Boss balance implemented**.
2. Exact gameplay/economic changes: reroll behavior and pricing examples, offline skill unlock costs/rates, boss stats and any Prestige bonus revisions.
3. Root causes of the Auto Farm detours and HUD truncation; actual fixes made.
4. Boss balance report path and compact before/after results, including **Green Alien** and realistic low-/multiple-Prestige player scenarios.
5. Focused and full test results with baseline comparison; Android-only remaining checks.
6. Version and Android version-code confirmation, changed-file summary, local commit hash, and confirmation that nothing was pushed or published.

**Do not implement automated player-testing profiles in this batch.**
