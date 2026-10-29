# LootFarmer — Supplies Mastery 3 Uses + Final Boss Balance Audit

## Purpose and boundaries

Implement **one gameplay balance change**: supply mastery increases once per **3 successful supply uses**, instead of once per 5. In the same change, perform an **evidence-based, focused audit of the final boss only**: the **Green Alien final boss in Spring II (Stage 8)**. Determine whether a legitimate player can defeat it and what it realistically takes. **Do not silently rebalance the final boss or any other enemies, weapons, skills, Prestige cards, or the economy.** Report recommendations separately if necessary.

Work in the developer's **current local Git repository**, not in an older ZIP snapshot. The ZIP is supporting context only. First read the canonical `docs/Reusable_Game_Development_Playbook.md` in that repository and the applicable gameplay, test, save, and balance documents. Follow their current contracts when they differ from historical notes.

## A. Approved supply change: 5 uses → 3 uses

- The progression being changed is **usage-based supply mastery**, sometimes described to the player as supplies becoming stronger or evolving. **Do not** replace it with item-tier evolution or gear merging; consumables retain separate **stock** and **mastery** as established in Playbook §141.1.
- In the supplied snapshot the shared authoritative parameter is `data/game/catalog.json` → `progression.change17.supply_uses_per_level: 5`. Locate the authoritative value in the **current** repository, and change it to **3**. Avoid hardcoding duplicate divisors.
- Award mastery **only after successful consumption**, never for collecting, purchasing, or an unsuccessful/blocked activation. Preserve automatic supply use, cooldowns, cap, milestone thresholds, persistence, and Prestige reset rules as currently approved.
- Keep compatibility with existing saves. Existing `supply_uses` counts are actual successful uses and should retain their meaning; derive mastery using the new divisor, subject to the existing cap and preserved one-time legacy credit. Inspect the real save normalization/migration before changing it. Do not double-credit or erase existing progress.
- Verify the visible mastery progress display, any descriptions or tooltips mentioning **5 uses**, and English `en.po` entries that would become incorrect. Add/update translations **in English source only**; the 19 other runtime languages are not yet imported and must not be enabled here.
- Review tests with hardcoded `5`, `50`, `125`, `250`, or `500` successful-use fixtures that assume `5 uses = 1 level`. Update only assertions/fixtures that this rule invalidates, without weakening meaningful coverage.
- Minimum targeted checks: uses 0/1/2/3/4/5/6, repeated uses, different supply types, capped mastery (^100), mastery milestones, auto-use, blocked use, older save migration, save/load, and Prestige. Include a test proving mastery no longer waits for the fifth use.

## B. Final boss only: realistic beatability and requirements

The relevant boss is **`boss-green-alien`** in **Spring II (Stage 8)**, behind the campaign's **13-key** route. Do not confuse it with the Sunflower boss, which is a **different Spring II encounter**. Consult the **current** catalog and implementation for up-to-date stats, AI, summons, healing, skills, telegraphs, loot, and gate prerequisites. Historical balance results are benchmarks, **not proof of current balance**.

### Questions the audit must answer

1. Can the final boss actually be defeated under the real rules? If yes, demonstrate a reproducible win, not just a theoretical DPS calculation.
2. What is the **lowest realistically obtainable winning build**? Identify player level; equipped obtainable weapon and outfit (real drop IDs and tier); merge/mastery levels; meaningful stored equipment bonuses; skill choices and levels; coin/gem upgrades; Prestige rewards/cards; supply types, mastery, and charges; and relevant survival stats. A minimum is a **tested lower bound**, not a proven universal optimum unless a sufficient search is performed.
3. What is a **recommended practical build** with reasonable safety margin? Identify which investments are essential versus optional.
4. What are the boss mechanics that matter (skills, sub-50%-HP healing, summons/helpers, cooldowns, damage intake, regeneration, player control/auto-cast, positioning, telegraphs)? Can a player win while surviving the actual full encounter?
5. How many legitimate attempts, deaths, supplies, and seconds/minutes per fight are expected? Provide a small reproducible set of seeds or trials for the minimum and recommended builds, win/loss outcomes and fight durations; do **not** extrapolate a statistical win rate from one deterministic fight.
6. How long, approximately, would an actual player need to earn the recommended build, including **keys**, required gear acquisition/drop and merge farming, upgrades, Prestige unlocks/rewards, and supply acquisition? Distinguish **measured** progression from **estimated** time, show assumptions and uncertainty. Do not claim an exact hour count unsupported by simulation.
7. What happens under **no Prestige**, modest Prestige, and higher investment where feasible? Separate optional optimization from true requirements. The final boss should be challenging but not demand impossible/legacy gear or unreasonable mandatory grinding (especially not arbitrary ^500+ outfits without evidence).

### Audit method and realism safeguards

- Start with the current test infrastructure (e.g. `tests/change_9_balance.gd`, `tests/balance_probe.gd`, applicable campaign/progression probes), but inspect and correct outdated fixtures/assumptions before treating them as evidence.
- Follow Playbook §140: fixtures must **own** every item, use **obtainable** IDs and tiers, prove equips succeeded, obey access/unlock/currency/skill/Prestige constraints, and refuse impossible loadouts. An unconstrained max-stat fixture can be labelled *theoretical ceiling* only, never the minimum or recommended build.
- Use **real combat simulation** where practical (including final-boss healing, summons, abilities and player auto-cast), with bounded timeouts, captured summary lines, and failures on `SCRIPT ERROR`. Do not infer outcome from basic-attack DPS alone.
- Deterministic fixtures can seed legitimate state to accelerate testing **only after proving each seeded resource/equipment level is obtainable through current gameplay**. Clearly distinguish reproducible combat fixtures from actual end-to-end progression measurements. Never assert an actual player farmed the resources if the fixture injected them.
- Test a bounded progression/build ladder to locate the practical threshold (losing build then winning build). Compare minimum plausible vs recommended; use multiple seeds/trials in a small, targeted sample where random behavior matters. Record actual boss HP and damage and any player loadout-derived combat statistics.
- Investigate whether the new **3-use mastery** meaningfully changes boss outcomes; account for the new divisor in the audit, rather than rerunning with the old catalog.
- **Scope** is the final boss only. Check early stages only as needed to establish whether key/gear/progression prerequisites are legitimately obtainable; do not audit or rebalance the earlier bosses. Beating the final boss does not logically establish the balance of every earlier encounter.
- If no legitimate build wins, state that clearly, identify the bottleneck and propose **separate, quantified** balancing options, but do not implement those options without the developer's approval.

## C. Implementation, test, documentation, and delivery

1. Read the canonical Playbook and current game documents, inspect actual `supply_uses_per_level` consumers, the final boss, and current test suite. Prefer the authoritative data/configuration parameter over new constants.
2. Implement the **only approved balance change**, including necessary UI/localization English strings and updated tests. Do not change gameplay mechanics to make the audit pass.
3. Run small targeted supply tests, then the **final-boss audit sequentially** (Playbook §§60.1, 140). Keep heavy simulations out of ordinary fast regression and enforce watchdogs.
4. Run the **complete maintained regression suite once** after the implementation is stable. Require no Godot script errors; report actual results rather than assuming success.
5. Write a compact auditable report under `docs/` that identifies: source commit/version, old→new supply rule and save impact; precise final boss stats/mechanics; build tables; real vs seeded/test resources; fight trials and seeds; time-to-prepare evidence; verdict and recommendations. Include reproducible test invocation(s) and relevant logs/CSV as appropriate.
6. Update game-specific GDD/content, test, and English localization documents as needed. **Do not rewrite generic reusable balance guidance** unless implementation proves a genuinely new reusable lesson; preserve all existing Playbook rules.
7. Determine the **next chronological Change number from local Git history**, commit this change and documentation automatically, and **do not push**. Do not modify the 19 pending translation files, marketing assets, export packaging, or unrelated gameplay.
8. In the final Claude response, supply the commit hash, changed files, test summary, supply rule/save compatibility, the final-boss verdict, **minimum verified winning build**, recommended build, encounter stats and results, estimated preparation effort (with assumptions), and any unimplemented balance recommendations.

## Acceptance checklist

- [ ] Successful supply consumption #3 grants the first mastery level; #1–2 do not; caps and milestone effects remain valid.
- [ ] Existing inventory stock/mastery save semantics, automatic use and Prestige behavior remain consistent.
- [ ] English UI/catalog and relevant tests reflect 3 rather than 5.
- [ ] The final boss analysis includes **Green Alien, Spring II, 13 keys**, not Sunflower.
- [ ] Demonstrated reachable/obtainable winning and losing combat fixtures, or a clearly evidenced no-win result.
- [ ] Minimum and recommended build, consumables, skills, Prestige, combat trials and realistic grind estimates are reported with limitations.
- [ ] No undocumented boss balancing or changes to other stages.
- [ ] Relevant tests and full maintained suite pass, with no script errors; evidence and report committed locally, not pushed.
