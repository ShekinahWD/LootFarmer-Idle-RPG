# LootFarmer — Change 66: Enemy Achievement Gem Removal, Guided Map Mastery, Gem Chance Cost & Focused Farming Copy

**Status:** Approved implementation handoff, 11 November 2026.  
**Working baseline:** Local repository **after Change 65 (`ddbf570`)**, including Change 64 / 63 corrections. Claude must inspect the *current working tree*, not infer implementations from an older ZIP or an older GDD snapshot.  
**Source guidance:** Current game-specific GDD and Upgrade Catalog; Reusable Game Development Playbook, especially §18 (state-driven, contextual, actual-control tutorials), localization policy §132, and local-commit workflow. **Do not edit the reusable Playbook.**

## 1. Final approved decisions (supersedes earlier ambiguous wording)

1. **Remove ONLY the Gem Chance/Gem bonus earned through enemy-kill achievements.** Keep enemy-specific damage achievements **exactly as they work today**, including kill thresholds, percentages, scopes and persistence. Do not convert former Gem Chance rewards into extra damage or redesign milestones.
2. **Replace the Change 63 optional “100% explored” Map Mastery hint with a proper action-driven Guided lesson**, taught when Map Mastery becomes available. The lesson must guide the player to the real Map Mastery control, open the panel, understand where objectives/progress are, and close/continue. **No 100% exploration requirement or deferred hint.** Do not require actually completing any Mastery objective.
3. **Gem Chance Player Upgrade: first rank costs 10 Gems instead of 25 Gems**, still grants **+0.5 percentage points**. Preserve existing prices for **ranks 2–20** (currently rank 2 = 40 Gems, with later prices from the live catalog), the 5% base drop chance, all other gem-price schedules and the rate of future ranks. The user is adjusting **upgrade price, not gem drop chance**.
4. **Clarify Global Focused Farming unlock description.** Suggested English player-facing copy: **“Select an enemy to farm automatically. If your hero dies, they'll return to that enemy and continue farming after respawning.”** Preserve the global, one-time **25-Gem** unlock from Change 65, target selection and persistence. This is a copy correction, not an automation rebalance.

## 2. Enemy kill achievements — remove Gem Chance contribution

### Gameplay
- Trace the source of enemy-type kill milestones, their displayed rewards, the actual enemy-targeted damage calculation, gem-drop-chance aggregation, stat previews and save/load re-derivation. Remove **only** the kill-achievement-derived Gem Chance modifier wherever it influences normal/boss drop rolls or previews.
- Preserve **all existing enemy-specific damage achievement behavior**: milestone thresholds, accumulated kill counts, damage values, variants/types affected, visual progress and Prestige retention. Do not substitute a generic/global damage reward and do not alter the damage formula.
- Preserve base Gem Chance (**5%**), purchased Gem Chance ranks, Gem Wisdom, Prestige cards, boss-specific Gem Chance, and the drop/amount rules from other sources. The only removed source is enemy kill achievements. Do not alter Gem Amount, boss amounts, raw drop RNG, unrelated missions or rewards.
- Existing saves: preserve earned kill counts and damage awards, without granting or refunding currency and without corrupting saves. Previously earned kill-achievement Gem Chance should no longer apply after load/Prestige; avoid retaining obsolete cached contributions.

### Presentation
- Enemy achievement rows, preview panels, tooltips, notifications, Stats/Farming Guide and Help text (where applicable) must no longer promise a Gem Chance bonus from enemy kills. Display the unchanged damage reward in a way that clearly targets **that enemy type**.
- Check how milestones with *both* bonuses and/or any *Gem-only* stage are represented. Keep the existing milestone progress intact; do not invent a replacement reward. If an achievement becomes rewardless after removal, report the exact milestone and choose the smallest presentation treatment consistent with this approved scope, without silently redesigning damage achievements.

## 3. Guided tutorial — teach Map Mastery properly

### Trigger and sequence
- Inspect current Guided sequence (Change 61 + 63 + 65), including feature availability / menu reveal. Insert teaching at the **earliest appropriate point once Map Mastery is truly visible and actionable**, not on reaching exploration 100%. Its precise position must respect actual progression and preserve the existing Snowman / Prestige / Winter II lessons and *THE ROAD AHEAD* ending.
- Use the **existing** tutorial guide, pointer, caption, event/state completion and panel arbitration; do not build a separate tutorial framework.
- Teach one action at a time using live controls:
  1. **Open Map Mastery:** point to its *real, enabled* entry (HUD Mastery chip or the actual World → Map Mastery control, whichever is available in that Guided state). Tell the player to tap it. Complete when the real panel opens.
  2. **Read the objectives/progress:** while the panel is open, briefly identify the five existing categories — **Explore, Hunt, Research, Collect, Forge** — and that each map's permanent Mastery rewards come from completing its goals. Use the real panel's progress and requirements; do not require 100% exploration, kills, purchases or a completed objective. If necessary, guide to a real scrollable area or category control; **do not point at static text as if clickable**. Make the step complete based on an appropriate real/visible state or a clearly marked acknowledgement, not on a fake purchase or unachievable gameplay requirement.
  3. **Close and continue:** frame the real **Close** control; close completes the lesson and normal progression resumes. If the user leaves/reopens the panel or navigates elsewhere, resume at the appropriate actionable control without losing saved progress or trapping the player.
- Preserve existing guide behavior: arrows only to actionable controls, no touch interception, captions remain readable over panels, panel sizes stable while open, queued banners/toasts do not hide guide instructions. Respect safe areas, shorter panels, and the 432×960 / 540×960 layouts established in Changes 63–64.
- Add localized English copy for the new teaching, concise enough for mobile; use the same terms and values as the real Mastery panel. Ensure **Basic/None remain ungated** and show no new unsolicited popups; the existing shared 14-card Help system contains a Map Details/Mastery entry — update it if any explanation or animation requires accuracy corrections, without duplicating a deck.

### Retire the 100%-exploration hint completely
- Remove the optional Change 63 Map Mastery hint trigger, delayed scheduling, 30-second countdown, Got It prompt, pointer/card presentation and related event paths; delete dead code where safe.
- **Do not remove** the actual 100%-exploration Map Mastery objective, completion tracking, achievement/milestone rewards or ordinary completion notifications. Only remove the **separate tutorial hint**.
- Old profiles that already saw the optional hint must not have their game progress erased or wrongly skip the new required Guided step. Apply the Playbook's **ordered tutorial step migration**: a profile already beyond the insertion point (or with onboarding finished) treats the new lesson as completed; a new Guided profile encounters it at the designed point. Do not equate “hint viewed” with completing the new lesson. Preserve save compatibility, completed 35-step progress, and Step/ID-based fixture references (no fragile numeric indices). Prestige does not replay it; Hard Reset behaves like other Guided lessons.

## 4. Gem Chance first-rank price — 10 Gems

- Locate **the authoritative price definition** for the global Player Gem Chance upgrade (`gem_chance` or its actual live identifier), and update **only the first price entry** from **25** to **10 Gems**. The first purchase still grants **+0.5 percentage points**.
- Preserve rank 2 price **40 Gems**, other subsequent prices, all 20-rank progression, VIP/card discounts or pricing modifiers if any, and cost display/purchase confirmation consistency. Validate that unaffordable purchases fail without spending; already purchased rank 1 remains purchased (no retroactive refund).
- Do not change gem drop chance itself, any gem earnings, boss Gem Chance upgrade, Gem Amount upgrade, or the global 25-Gem Focused Farming purchase.
- Update current Upgrade Catalog / game-specific GDD documentation that would otherwise still state the old first price or kill-achievement Gem Chance rule, with clear supersession of historical sections as appropriate.

## 5. Focused Farming — accurate unlock copy

- Update the **current Global Focused Farming row** in Player → Upgrades, its description/tooltip/locked explanation and relevant **Help tutorial card** to clearly explain: the player selects an enemy for automatic farming, and **after death/respawn the hero returns and continues farming that selected target**.
- Suggested unlock description (can wrap into two mobile lines):

  > Select an enemy to farm automatically. If your hero dies, they'll return to that enemy and continue farming after respawning.

- Use one authoritative English translation key per meaningful text surface. Reuse keys when sensible; don't scatter hardcoded English copy.
- Verify the description matches **actual current** post-death Focused Farming behavior. If the implemented behavior differs, explicitly report it rather than silently presenting an incorrect promise or redesigning combat/navigation.
- Preserve price **25 Gems**, owned/MAX status, one global unlock, auto-return/farming choice and all **per-enemy** Auto-Collect, Auto-Merge and Auto-Evolution purchases.

## 6. Localization and documentation

- Edit **English source catalog** and record **all new/changed/retired copy** in the existing `tools/localization_pending.json` workflow (Change 66; align with the actual manifest schema in the live tree). Include price/help text and removed Gem Chance achievement promises. Preserve approved translations already present; **do not edit the 19 non-English catalogs** during this English-first implementation batch.
- If a translation key is still used by multiple unrelated mechanics, split/change it carefully so this removal does not eliminate legitimate Gem Chance descriptions elsewhere.
- Reconcile **current game-specific GDD**, Upgrade Catalog and maintained test docs where affected. Do not rewrite unrelated historical design notes; mark superseded current assertions where needed. **Do not edit the Reusable Playbook**.

## 7. Focused validation (no long balance sessions)

Use targeted probes and a brief real-scene UI capture; update existing probes rather than creating redundant infrastructure. Suggested minimum checks:

1. Enemy with 0, intermediate and full kill-achievement progress: unchanged damage bonuses; **zero achievement-derived gem chance** in actual rolls/previews; other Gem Chance sources intact. Cover boss and normal types/variants.
2. Existing profile with earned Gem Chance milestones: load and Prestige retain kills/damage but no obsolete gem modifier. No unexpected refunds, reset or stat drift.
3. Gem Chance first purchase costs **10 Gems** and grants **0.5 points**; second costs **40 Gems**, later prices and cap unchanged. Low balance refuses safely.
4. Guided first-time Map Mastery entry: open, inspect progress/requirements, close and advance; pointer always points to real enabled control; alternate panel open/close, save/load, old finished profile and Prestige safe; Basic/None unaffected. Reaching 100% exploration must **not** show the removed optional hint but must still fulfill the actual Mastery goal.
5. Focused Farming copy appears in Player Upgrades and the shared Help card; owned/locked states readable; 25-Gem cost unchanged. Verify post-death behavior if possible in a short scenario.
6. Render relevant screens at **432×960 and 540×960**; inspect actual images, no clipped long copy, scrolling/action visibility, touch targeting, banner/tutorial priority.
7. Run localization validator and the relevant Change 61/63/65/tutorial, achievement and upgrade probes. Do not run full suite or long playthroughs solely for this change. Report pre-existing unrelated probe failures separately.

## 8. Git and completion report

- Preserve unrelated local developer changes, assets, and commits. Stage only Change 66 files.
- Once focused validation passes, create **one local Git commit**:

  `feat(change-66): refine enemy achievements and teach map mastery`

- Report: implementation summary, precise Guided insertion point and final step count, exact affected achievement milestone UI, Gem Chance level-1/level-2 prices, Focused Farming copy and behavior verification, changed files, focused tests, screenshot locations, all pending English keys, any remaining risks and commit hash.
- **Do not push, export or publish.** Stop after Change 66; Android acceptance and remaining localization are separate.
