# LootFarmer — Change 15 Playbook Compliance Audit

Date: 2026-10-22. Scope: the Change 15 systems (early equipment guarantee, first-profile menu reveal for Guided / Basic / None, notification sounds, Map Mastery, reachable exploration), checked against `docs/Reusable_Game_Development_Playbook.md`. It covers only the rules these systems touch. Desktop and headless checks cannot prove phone layout, colour or feel; those items are in the last column.

Evidence keys:

- **P15:** `tests/change_15_probe` (177 checks, runs without `--first-run-complete`).
- **CAP:** `tests/change_15_capture` (desktop renders in `docs/Change_15_Evidence/ui/`, 540 × 960).
- **SUITE:** `python tools/run_probes.py` (24 / 24).
- **FOG:** `tools/fog_reachability.gd` (stored unreachable cells match a fresh flood fill).

| # | Playbook rule | Status | Evidence | Android-only |
|---|---|---|---|---|
| 1 | §18.2 depth is presentation, pacing is the game | Compliant | Guided, Basic and None share one reveal table and one guarantee; the mode changes only the guide (pointer lessons, retiring cards, nothing). P15 runs the guarantee in all three modes and the reveal chain per mode. | — |
| 2 | §18.10 first-profile progression: demonstrated actions, latched, one reveal table, a handover in every mode, probes opt out | Compliant | `onboarding.gd` FEATURES and triggers with level backstops; `state.onboarding.reveal` saved, kept by Prestige, cleared by Hard Reset; one "Prestige unlocked" banner in every mode; `--first-run-complete` for suite probes of ordinary play (runner), the Change 15 probe without it. P15: chain, level backstops, full row, Snowman first, save/load, Prestige, Hard Reset. | — |
| 3 | §18.5 / §18.8 pointer on live controls, state-completed lessons, one arbitration, no input | Compliant | New Guided lessons find tagged controls (`claim`, `buy_gear_slots`, `buy_supply_potion`, `tab_tab_inventory`, `follow`), complete on state (claimed, bought, followed) and skip lessons already done out of order; a lesson whose system is hidden waits. P15 walks the whole Guided sequence. CAP 04. | Arrow and card legibility |
| 4 | §18.1 / §18.3 concise cards, finite duration for informational text | Compliant | Basic cards are one title line and one support line and retire after 20 s on screen (OnboardingRules) or Got it. P15 checks the retirement and the reveal-ordered cards. CAP 03. | Whether 20 s feels right |
| 5 | §21 badges | Compliant | The existing gold ✦ marks a revealed, unopened menu; the Missions `!` keeps the Change 14 claim rule and only shows once Missions is revealed. P15: ✦ shows and clears on open. CAP 02, 06. | ✦ legibility |
| 6 | §85 sparse semantic audio; §142.2 announce once | Compliant (extended) | One notification sound for the progression family, distinct sounds kept for a new map / 100% and the Prestige reset; per-frame priority unchanged; a shared cooldown per sound file prevents a double play; hidden systems are silent; main objectives announce on the transition only. P15 covers each trigger, mutes and the same-frame rule. | Sound frequency in play |
| 7 | §3 progression layers | Compliant | Mastery rewards are permanent numbers in the existing bonus pool (`campaign.bonus`), shown in Stats as their own source line; no new currency or reset. P15 checks HP, damage, coins, XP, Loot and Gem Chance apply exactly once. | Balance |
| 8 | §90 completion display | Compliant | Percentages round down and read 100 only when complete; P15 checks 0%, partial, one map and all eight. | — |
| 9 | §117.9 / §127.6 fog: discovery is state | Compliant (extended) | Explored percent excludes the 4 unreachable Summer II cells from count and area; P15 walks every reachable point of all eight maps to exactly 100%; FOG compares stored and recomputed cells. | — |
| 10 | §63 / §67 inspector-editable configuration | Compliant | `onboarding_rules.tres`, `mastery_rules.tres`, `fog_rules.tres unreachable_cells`, `audio_cues.tres` (stream reassignments and five new cues). | — |
| 11 | §16 panels: one opener, content-sized, no orphan state | Compliant (fixed) | `_open` refuses hidden panels from every path (P15). The suite exposed a reconciler that pruned the World map's player dot on an in-place refresh; controls that build their own children now opt out (`e52054a`, P15 regression check that fails without the fix). | Mastery panel length on a phone |
| 12 | §61.1 pre-release saves | Compliant | Schema 8; schema 7 development saves reset by instruction (no migration). Validation covers the new records (P15 rejects a duplicated reveal and an unknown item). | — |
| 13 | §60.1 layered testing | Compliant | Smoke probes before the build commit, one focused probe, full suite runs, one capture run, all sequential. No pacing, soak or balance campaigns. | — |
| 14 | §74 no double dashes in written text | Compliant | New strings and docs contain none. | — |
| 15 | §22 / §63 asset reuse | Compliant | No new art or audio: existing Kenney panels, PixelPlains icons, `mission_ready.wav`, `stage_clear.wav`, `prestige.wav`. `reveal_unlock.wav` is no longer referenced. | Licence record for `assets/sounds` still missing (Change 12 item) |

## Android checklist

1. A fresh profile shows only Settings in the bottom bar; each button appears in its own slot as its system opens, with a ✦ until opened.
2. The first weapon or outfit drops within five Winter I defeats and a matching copy within five more, whichever enemy is farmed.
3. Guided: the arrow leads through Missions, Loot Chance, camp, equipment slot, then the Snowman card pointing at Next Stage; after the Snowman, Prestige.
4. Basic: one short card per new system, gone after about 20 s; None: no cards at all.
5. The mission-ready sound is pleasant at the rate it now plays; no doubled sounds.
6. World → Map Mastery is readable and scrolls well; map pages show what remains without naming unmet enemies.
