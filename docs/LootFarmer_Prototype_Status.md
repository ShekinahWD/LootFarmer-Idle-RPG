# LootFarmer — Runtime status — Change 21

## Change 21 — current corrections (27 October 2026)

Built on the exact delivered Change 20 project; application/Android version is 21 and save schema remains 8. See [Change 21 report](LootFarmer_Change_21_Report.md) for the complete correction checklist and validation.

- Guided Missions unlock 60 active gameplay seconds after the first merge. Inventory expansion now explicitly points to Close before teaching potions. Already advanced saves do not repeat the new close step.
- Auto-merge item controls appear only with the applicable purchased upgrade, and remain available when excluded.
- Supplies support six total slots (one initial plus five purchases). Small shows 3 columns × 2 rows, Medium 2 × 2 visible, Large one visible; the viewport stays fixed. Gear and Supply headings and slot rows align.
- Missions, Mastery, Filters, Prestige and Upgrades show visible scrollbars on overflow. Claim has a compact, centered height.
- Mission/Prestige followers stack just above the joystick. The farming objective is larger and padded; boss countdowns show only seconds.
- Prestige opportunities are grouped by relevant unlocked maps with discovered/total counters, followed by General, Owned Cards and Card Sets. Objectives spanning multiple maps appear in each relevant section. General contains offline, merging, arsenal, offering and mission objectives.
- Expanded map camps are visible without Map Details and support release-to-travel with larger icons/hit areas. Camp-list buttons remain. Combat restrictions still apply.


## Change 20 — previous delivery (27 October 2026)

The full 22-section **Remaining Features, UI & Tutorial** brief is implemented, including interfaces. It supersedes the earlier gameplay-only scope and handoff to Claude. Application/Android version is 20; save schema remains 8. See [Change 20 implementation and acceptance report](LootFarmer_Change_20_Report.md) and [current test suite](LootFarmer_Test_Suite.md). Earlier numbered change descriptions are historical evidence, not conflicting current instructions.

Guided onboarding follows saved action outcomes and 60/60-second active-play delays, teaches physical camp purchase, boss preparation, inventory expansion and potion use, and ends in Winter II after a five-second visible-message delay and acknowledgement. Only Guided mode has the tutorial Prestige gate. Slots have saved Small/Medium/Large controls in Filters and Settings. Item details expose Auto-merge On/Off. Prestige keeps player level and XP, but resets Supply Mastery and partial use progress. World stage selection travels directly for one unlocked camp or shows a visual camp map for multiple camps. Map markers, trackers, mission layout and boss discovery/countdown presentation are integrated. All offensive skills (including Focus) require combat and an eligible target within the configurable 64-unit activation distance; Heal needs missing HP and works outside combat. Boss Gem previews include the existing base once.

Physical Android visual/performance acceptance remains open; desktop screenshots and headless checks are not device certification. No commits were made.

---

## Historical runtime status

# LootFarmer — Runtime status — Change 19

Current (2026-10-27): the original Change 17 gameplay systems plus shared manual/automatic skill proximity eligibility and corrected effective boss Gem upgrade previews. Maintained suite: 28/28 passing. UI integration remains with Claude; no Prestige retention changes. See `LootFarmer_Change_19_Report.md` and the updated Claude integration handoff. Physical Android and unresolved late-game balance acceptance remain open.

Historical Change 16 status:

Current (2026-10-23): the eight-stage campaign with Changes 7 to 16. Implementation status and open device checks: LootFarmer_Change_16_Notes.md; tests: LootFarmer_Test_Suite.md (the maintained suite is `python tools/run_probes.py`). No physical Android, release-template, signing or store-readiness claim is made.

---

Historical (Change 6):

# LootFarmer — Runtime status — Change 6

The eight-stage campaign is the runtime. Read LootFarmer_Design_README.md and LootFarmer_Change_6_Validation.md. Historical prototype probes (ui, gameplay, targeting, inventory, progression and others) still reference removed systems such as selling and old HUD nodes; they are kept for traceability and are not acceptance criteria. The maintained suite is change_6_probe, change_5_probe, campaign_probe, campaign_content_probe, the static validator and the pacing bot.

No physical Android, release-template, signing or store-readiness claim is made.
