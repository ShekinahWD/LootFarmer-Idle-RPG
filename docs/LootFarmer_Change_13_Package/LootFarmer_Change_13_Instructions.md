# LootFarmer — Change 13: Automation, Rainy Maps, World-Gate Guidance, Boss Helpers & Compliance Audit

**Implementation brief for Claude — start in a NEW conversation.**

**Baseline:** Work from the **latest actual committed Git tree** in the LootFarmer Godot project (Godot 4.7). Change 12's last reported gameplay build was `2ffa8fb` with follow-up tests/docs at `2e7675c`, but **the live repository is authoritative**: later commits, including any already completed Auto-Evolution follow-up, take precedence. Inspect `git status` and recent commits first. **Do not overlay an older ZIP or revert newer work.**

Read the in-repository **Reusable Game Development Playbook**, current GDD, upgrade and balance catalogs, prestige/state contracts, Change 12 notes, test-suite notes, and relevant game code before editing. Some tasks below may already exist from a parallel follow-up: inspect and **verify, don't duplicate**. This is an implementation request, not a proposal-only investigation.

## Non-negotiable development rules

- **Android-first; compact, readable Spanish-capable UI.** Respect safe areas, joystick, minimap, and touch targets. Use existing approved pixel-art, sounds and UI assets only; do not generate/download substitutes. If a required asset is missing, report that rather than faking completion. Inspector-editable scene/resource parameters are preferred to hidden constants.
- **Pre-release save policy:** follow Playbook §61.1. Do **not** build elaborate migrations for old development saves. A schema change may reset old profiles. Current-schema save/load, Prestige and Hard Reset must still function.
- **Gem-funded upgrades remain purchased after Prestige** regardless of category; Hard Reset removes them. Do not change existing Gem balances or other economy rules unless specified here.
- Do not overwrite the developer's Android version code, signing configuration, export paths, local `export_presets.cfg` / `project.godot` changes, or unrelated untracked files. No broad `git clean`/checkout.
- Prefer focused code inspection and targeted checks over speculative redesigns and repeated long simulations. Human Android playtesting decides subjective balance. **Always commit completed implementation and subsequent corrections** with descriptive Git messages.

---

## 1. Auto-Merge must use the EXACT dropped item identity

An Auto-Merge unlock for an enemy dropping a **Wood Sword** must not also automatically merge **Stone Swords** merely because they were evolved from Wood Swords.

**Required behavior:**

- Determine Auto-Merge eligibility from the actual item identities in the drop tables of enemy types for which the player bought **Auto-Merge Gear**. Do not apply it to every item in a weapon family or to descendants of an evolved item.
- Wood Sword drops/duplicates can auto-merge if an eligible enemy's Auto-Merge was purchased. Two Stone Swords produced by evolving Wood Swords **remain unmerged** unless some enemy type that naturally drops Stone Sword has had its Auto-Merge unlocked.
- If another later enemy naturally drops Stone Sword and its Auto-Merge is unlocked, **all owned Stone Swords** may merge automatically, regardless of whether they came from evolution or enemy drops.
- Shared item identity across different enemies must work. Retain intentional manual merging, evolution rules and equipment caps. No auto-merging supplies through this gear unlock.
- Handle post-drop, post-merge and post-evolution inventory updates without unintended recursive chains; don't consume the wrong copies or transfer an unlock onto the evolved tier.

**Acceptance:** Wood-only unlock does not merge evolved Stone copies; adding an unlocked Stone-dropping enemy then enables merging those same copies. Test at least one sword and one axe progression, including shared drops.

## 2. Per-enemy Auto Evolution — 2,000 Gems

Add an **Auto Evolution** unlock **beside the existing Auto-Merge Gear** purchase in each applicable enemy's upgrade panel.

- One-time price: **2,000 Gems for each enemy type**; independent of Auto-Merge, purchased individually.
- Automatically evolve a **weapon item that enemy actually drops** when it meets the **current manual evolution requirements**. It must use the exact same material consumption, result tier/identity, caps and inventory validity as manual evolution.
- Do not evolve outfits, skills or supplies; those use duplicate-based progression without item evolution. Maximum-tier weapons do not evolve.
- Auto Evolution **does not grant Auto-Merge for the resulting higher-tier weapon**, and a Wood-dropping enemy's purchase must not implicitly manage Stone-tier evolutions. The resulting tier has its own eligibility based on its own actual droppers and unlocks.
- Unlock remains through Prestige and is removed by Hard Reset. Show clear purchased/available state and actual cost. If this feature was already implemented in an earlier follow-up, verify these contracts rather than add a second system.

**Acceptance:** Auto Evolution works both with manually prepared eligible weapons and with Auto-Merge, without recursively evolving all tiers or bypassing eligibility.

## 3. Health Potion cooldown and Heal skill usefulness

- Set **base Health Potion cooldown to 12 seconds** (previously approximately 4–5 seconds).
- Keep the current basic **20% max-HP heal amount**; do not independently rebalance other supplies.
- Inspect permanent supply mastery/milestones that reduce the cooldown. Select and document a **sensible minimum cooldown** so max mastery does not undo the intended slowdown or render the Heal skill irrelevant (prefer a brief formula comparison, not a full boss pacing campaign).
- Ensure potion auto-use, UI timer, tooltip, effective cooldown, save/load and Pause use the same authoritative value.

**Acceptance:** 12-second base is shown and respected; mastery reduction has a documented floor and Heal remains a distinct useful ability.

## 4. Stronger rainy-stage atmosphere using existing map art

On maps that **already use rain**, make the weather clearly perceptible and give the environment a subtly **darker, cloudy/overcast appearance** like the supplied rainy visual reference (from the earlier map reference set). The supplied package includes a darker example and brighter comparison.

- Increase rain density/visibility enough to read at normal Android zoom without becoming visual clutter; retain natural animation and **world-anchored particles** (rain must not move along with camera panning).
- Subtle ambient dimming/tint; retain legibility of enemies, HP, projectiles, camps, navigation markers and fog states. Do not darken maps without rain just to match a screenshot.
- Reuse existing assets; favor inspector-tunable rain density, color and ambience resources. Avoid extra full-screen expensive shaders/large sprite counts if current system can achieve the result.
- Keep the eight stage layouts, collision/nav and distinctive seasons intact.

**Acceptance:** rainy maps feel clearly rainier/overcast, camera movement doesn't drag rain, and player/target readability and device-performance expectations remain reasonable.

## 5. Skill unlock prices and cooldowns

### 5A. Skill Auto-Cast purchase prices (Gems)

The three successive **Auto-Cast skill unlocks** should cost **100 / 250 / 500 Gems** respectively. Do not confuse these with the separate equip-slot upgrades. Existing purchased levels, gating, Gem-funded Prestige permanence, and the underlying automatic casting behavior are unchanged.

### 5B. Additional equipped skill-slot prices (Gems)

The **second equipped skill slot** costs **300 Gems** and the **third slot** costs **600 Gems**. Preserve the initial free slot and existing maximum slot count.

### 5C. Skill cooldowns

Skills with current baseline cooldowns around **4 seconds** should move toward approximately **8 seconds**. Inspect the actual skill roster and rebalance **per skill** so differences remain meaningful; don't indiscriminately overwrite intentionally longer durations such as Heal or destroy boss-specific combat timings.

Keep **effective cooldown, tooltip, upgrade previews, auto-cast behavior, player and enemy casting, and save/configuration data** aligned. Document final base values. No exhaustive fight simulations.

## 6. Make next-stage/world boss requirements obvious

At the moment, required boss defeats are buried in small World-panel text. A player should be able to tell at a glance **which boss(es) must die to unlock the next world**, and how much progress remains.

- Add compact, visible current-stage progression guidance, such as **`Next World · Bosses 0/2`**, **`1/2`**, or **`0/1`**, based on the **actual specific required bosses**, not just arbitrary boss kill totals. Claude may choose the best placement/style for Android and existing HUD hierarchy; don't cover combat or spam repeated notifications.
- Distinguish a discovered boss that is a **current unlock requirement** with an unobtrusive marker/icon matching the existing World gate/unlock language. Consider the in-world boss marker and full World map/minimap as appropriate, but preserve readable discovered-enemy icons.
- **Never disclose undiscovered boss coordinates, identity or spot through the marker**. Required-boss indication appears on the boss **only after its discovery**; a progress fraction may still be shown without spoilers. Clear or update after the kill and on world transition, stage reset and load.
- Reuse authoritative progression state; do not introduce a separate competing set of stage unlock counters. Explain two-boss gates accurately, including the case when one of the two has already been killed.

**Acceptance:** player knows the next unlock objective and can identify discovered required bosses without hunting a tiny tooltip or receiving spoilers.

## 7. Audit ALL player-facing currency representation and use the shared formatter

**Observed bug:** Camp purchase cost currently prints large Coin amounts as raw numbers rather than abbreviated `K` notation.

This is **not** a camp-only patch: do a comprehensive source/UI audit for **Coins and Gems** displayed anywhere. Follow Playbook §40, the existing centralized `number_format.gd` (or the project's current canonical equivalent), and related HUD layout guidance.

- Route **all player-visible currencies and currency costs/rewards** through the same formatter: camp unlocks, HUD balances, player/enemy upgrades, inventory and supplies, World/map details, teleport fees (if any), missions/prestige rewards, shop/purchase buttons, offline claims, loot summaries, settings/stat text that includes currencies, warnings and confirmations.
- **Abbreviate amounts from 1,000 onward** with the canonical system (`1K`, `1.5K`, `1M`, etc.); preserve sufficient precision so a price is not misleading. Small values can remain un-abbreviated. Avoid duplicating local formatting functions or showing `1000` on one surface and `1K` elsewhere.
- Do not round wallet balances upward so the UI suggests more money than the player owns; purchase eligibility and arithmetic **always use exact underlying numbers**, never parsed display strings. Handle very high values and negative/signed reward messages through existing conventions.
- Include dynamic labels/tooltips and values set after initialization, not only static scenes. If any context deliberately requires exact quantities (e.g., a detailed breakdown), use the centralized formatter's exact-mode behavior or documented exception; keep presentation consistent.
- Give a concise list of the UI surfaces audited and the formatting issues actually fixed. Focused automated search/checks for missing formatting calls are appropriate.

**Acceptance:** large camp prices and other currencies consistently use the central presentation system, with correct purchasing behavior.

## 8. Full APPLICABLE Reusable Playbook compliance verification

The user explicitly asks Claude to verify that **the current game follows the Reusable Game Development Playbook**, not just to claim compliance because it was referenced in previous work.

- Read the **current in-repository Playbook**, not a stale copy, and perform a structured **applicability-based audit** across current gameplay and presentation. Mark irrelevant rules **N/A** rather than invent implementation merely to satisfy them.
- Check the highest-risk applicable areas: editor/inspector ownership of tuning and art; assets/animation mappings; safe-area/mobile HUD and scrolling; combat feedback/HP/VFX authority; player input/camera; fog/map discovery; scene/resource organization; data-driven catalogs; currency-number formatting; audio semantic categories; Prestige/save/reset; automation state and performance; tutorial/guidance; asset provenance; test hygiene; documentation consistency; Android build/export guardrails.
- Check previously flagged omissions and recent Change 10–12 work. **Identify concrete source evidence or reproducible examples**; fix material defects within current scope and cheap/high-risk compliance issues. For broader unrelated changes, document them honestly as remaining recommendations instead of silently undertaking an entire redesign.
- Produce **`docs/LootFarmer_Change_13_Playbook_Audit.md`** with a concise table: area/Playbook rule, status (Compliant / Fixed / Partial / N/A), evidence (file/resource/test), and remaining Android-only checks. Synchronize GDD/docs only when findings or implementation require it.
- Do not waste tokens running giant multi-seed simulations under the label of an audit. Use source/config inspection, focused probes, desktop smoke and a single maintained-suite pass after a stable implementation.

**Acceptance:** evidence-backed coverage of every *applicable major Playbook area*, with no unsupported blanket claim of full compliance.

## 9. Selected later enemies summon helpers

Add a **helper-summoning ability to approximately 2–3 DISTINCT enemy types total** in the campaign, including the **final boss**. This means **2–3 types of enemy with this mechanic**, not every group and not an uncontrolled total number of additional spawned actors.

- Choose suitable **later-stage** enemy types (not the introductory first two enemies). Keep earlier combat simple and communicate summons with distinct, readable existing VFX/animation/telegraph.
- Helpers use existing approved enemy assets and obey existing movement, targeting, attack, and group-farming boundaries; summoning should not pull adjacent farming spots or block camps and choke points.
- Use a cooldown, cap living helpers per summoner/encounter, and cleanup/despawn on the summoner's defeat, enemy reset, map change or de-aggro as appropriate. Avoid exponential/helper-on-helper summon chains.
- Prevent unbounded **loot, XP, Gems, kill-count, missions or achievement farming exploits** from spawned helpers. Be explicit about whether helpers award anything; safest default is no regular farming rewards for summons.
- Expose summon cooldown, count, eligible helper types and level/cap as inspector-editable catalog/resource settings wherever feasible.
- Add minimal visual feedback so the player understands the summoned actors aren't unrelated encounter spawns.

**Acceptance:** 2–3 selected enemy types summon a bounded number of helpers, maps remain navigable/farmable, and summoned helpers cannot generate infinite rewards.

## 10. Final boss: multiple skills, prioritised Heal, attack and summons

The **final Green Alien boss** must be visibly more advanced than normal enemies and **use more than one skill plus helper summoning**.

- Give it **Heal** and **a random attack skill drawn from an appropriate existing attack-skill pool** (use existing approved effects). It must actually cast those skills, respect per-skill cooldown/eligibility, and show truthful HP/VFX/audio feedback.
- When its HP is **below 50%**, **prioritise Heal if Heal is available and healing is useful**. If Heal is on cooldown or unusable, allow an eligible attack/summon action rather than freezing. Above 50%, follow ordinary attack/summon selection with appropriate cooldowns. The boss should not trigger false Heal VFX, duplicate casts, or constant repeated summoning.
- The final boss **also summons helpers**, following the rules/caps in §9. Ensure the encounter does not become impossible solely from new summon pressure; do a short, representative sanity check with feasible Stage 8 gear/skills/prestige, not a long balance bot campaign.
- **Optional Rage bar:** Briefly evaluate whether a compact Rage meter/phase would genuinely improve readability/telegraphing. If it adds a meaningful, understandable mechanic using current UI assets without significant clutter, implement it with a clear trigger, capped behavior and actual gameplay consequence. **Do not add a decorative meter with no associated rule**, and do not force a new progression system solely for this suggestion. State whether implemented and why.
- Keep final-boss key gating, stage completion, reset flow, existing baseline stats and other skills unless a verified conflict requires a focused correction.

**Acceptance:** boss casts an attack skill and Heal, prioritises Heal below 50% when available, summons bounded helpers, and the fight remains readable and feasible to test on Android.

---

## Mandatory sequence, commits and validation

### Phase A — Implement, commit, notify early

1. Confirm current Git HEAD, read Playbook/GDD, and audit which of §1–3 (earlier follow-up) are already implemented. Do not duplicate completed work.
2. Implement all mandatory gameplay, UI, tuning, weather, currency presentation and boss changes. The Rage bar is explicitly **optional**, with a reasoned decision. Make only **small essential** compile/smoke checks while coding; a known-unbuildable project is not ready to announce.
3. Complete the **currency-surface sweep** enough to avoid an obviously inconsistent build. Defer the larger Playbook compliance write-up and nonessential probes to the next phase.
4. **Git commit** all relevant gameplay changes; do not include unrelated developer-owned export or Godot-generated clutter.
5. **Immediately send this message in chat (with real hash):**

   **✅ YOU CAN BUILD AND TEST THE GAME NOW.**  
   **Commit: `<real hash>`**  
   **🧪 CHECKING PLAYBOOK COMPLIANCE AND RUNNING THE REMAINING FOCUSED TESTS NOW.**

   Do not stop working after this notice. Allow the user to begin the Android build/playtest while you complete the rest.

### Phase B — Compliance audit and targeted tests

6. Finish the **applicability-based Playbook audit** (§8), audit remaining currency labels (§7), and implement *small important issues* identified. Write the evidence-backed audit document.
7. Add/run focused checks for exact-item Auto-Merge vs evolved descendants, Auto Evolution + Prestige, potion cooldown/mastery, stage gates/discovered boss indicators, skill prices/cooldowns, currency formatting, world-anchored rain, bounded helper summoning, final-boss Heal priority and skill selection; current-schema save/load and Hard Reset where touched.
8. Run the maintained regression suite **once** after the code stabilises and a minimal smoke test. **No extensive pacing runs or repeated soak tests.** Desktop/headless checks cannot prove Android visuals, audio or performance.
9. If Phase B finds and fixes a gameplay/UI issue, **commit it and send a new build-ready commit hash immediately**, explaining that earlier APKs are outdated. Test/docs-only commits do not require rebuilding.

### Phase C — Docs and final report

10. Update GDD, enemy/skill/upgrade catalogs and related tables, state contracts, relevant notes, test documentation and **Playbook only if a genuinely reusable new lesson emerged**. Commit docs and tests.
11. Report concisely: all task statuses; selected summoning enemies and limits; final-boss Heal/attack/summon behavior and Rage decision; exact new skill prices/cooldowns; potion mastery floor; currency formatting coverage; Playbook audit findings; test counts; commits; Android-only verification checklist. Do not present untested performance or appearance as verified on a physical phone.

**Do not expand the brief:** no wholesale campaign rebalancing, new assets, store-release work, invented new skills, general map-layout overhaul, or migrations for pre-release profiles.
