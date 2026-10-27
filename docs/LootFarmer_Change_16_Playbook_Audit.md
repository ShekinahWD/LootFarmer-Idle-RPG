# LootFarmer — Change 16 Playbook Compliance Audit

Date: 2026-10-23. Scope: the Change 16 systems (map economy, Gem collection upgrades, music, boss discovery and the Prestige unlock, overhead names and skill icons, the Winter I objective, mission and Prestige tracking, opportunity followers, Prestige retention, Map Mastery chip and rewards, the Cyan Robot's Heal, the Health Potion, Drop All, the Guided opening and View Camp, skill descriptions, the Prestige confirmation, Help and the removed development UI), checked against `docs/Reusable_Game_Development_Playbook.md`. Desktop and headless checks cannot prove phone layout, colour or feel; those items are in the last column.

Evidence keys:

- **P16:** `tests/change_16_probe` (197 checks, runs with `--first-run-complete`; reveal-dependent checks set reveals as labelled fixtures).
- **AUD:** `tests/change_16_audio` (windowed, real music playback, 11 checks). The previous audio service was also run once and reproduced the bug (the track stays paused after the volume returns from 0).
- **CAP:** `tests/change_16_capture` (desktop renders in `docs/Change_16_Evidence/ui/`, 540 × 960).
- **SUITE:** `python tools/run_probes.py` (25 / 25 with change_16_probe; see the Test Suite document).
- **SRC:** `tools/validate_campaign_source.py` (Change 16 static checks and `tools/change16_catalog.py --check`).

| # | Playbook rule | Status | Evidence | Android-only |
|---|---|---|---|---|
| 1 | §63 / §67 inspector-editable configuration | Compliant | Coin growth in the catalog (`map_cost_growth`, owned by a tool with `--check`), boss sight radius in `fog_rules.tres`, the Robot's Heal in `enemy_abilities.tres` (`skill_cooldowns`), the Guided path point in `onboarding_rules.tres`, Mastery rewards in `mastery_rules.tres`, the boss cue in `audio_cues.tres`, the Prestige confirmation as its own scene, name/icon sizes and colours as `LootActorView` exports, `HudChipButton` and `Danger` theme types. SRC. | — |
| 2 | §92 rebalance sources and sinks as one economy | Compliant, flagged | Income (1.5) and every map-tied Coin price (1.55) changed together; the probe checks every category on all eight maps and that cost per income rises map by map. The size of the late-map change is documented (Spring II upgrade ÷ income 537 → 25). P16. | Whether late maps now feel too fast |
| 3 | §141.4 retention derived from the currency | Compliant | Auto-Collect and Collect Batch became Gem upgrades and are kept by Prestige through `upgrade_kept` (currency), not a flag; older Coin levels keep their level. P16, SRC. | — |
| 4 | §61.1 / §137.2 save compatibility | Compliant | Schema stays 8; `bosses_found` and `follow_mission` are derived or defaulted on load; a save without them loads, keeps upgrades and the Prestige unlock, and survives a disk round trip; validation covers the new records. P16. | — |
| 5 | §85 sparse semantic audio; §144.6 shared sound cooldown | Compliant | The boss warning is its own semantic cue on the mission-ready sound (shared cooldown), once per boss per profile. P16. | Mix |
| 6 | §26.1 pause as a gameplay lock (music holds its place) | Compliant (fixed) | One `_sync_music` decides playback; volume 0 and the game pause hold the track; resume continues in place; a scene re-entry keeps playback. AUD. | Speaker / headset behaviour |
| 7 | §136.8 / §110 discovery that must not repeat | Compliant | `bosses_found` latches per boss, kept by Prestige, cleared by Hard Reset; approaching again never repeats the warning; a dead boss is not found. P16. | — |
| 8 | §128 text hierarchy; §14.2 / §143.6 readable text on any ground | Compliant | Boss names red with a 9-px dark outline (≥ 4.5:1 against it); skill icons on a dark disc; the Winter I objective on the dark chip (9.5:1); trackers 16–17 px on the backing plate. P16, CAP 02–04. | Red names on each season's ground |
| 9 | §14.4 prevent interactive overlap | Compliant | Overhead stack (HP bar, name, icons, banner, speech) never overlaps (rect checks); both trackers bottom-right, clear of the joystick and the map cluster; the Mastery chip sits between zoom and Map Explored. P16, CAP 03, 04. | 20:9 phone with toast and guide card |
| 10 | §14.3 generous tap targets | Compliant | Mastery chip 44 px tall, View Camp 56 px, Follow buttons 52 px, Prestige confirmation buttons 72 px, Drop All 64 px. P16. | Thumb reach |
| 11 | §136.4 bounded confirmations | Compliant | The Prestige confirmation fits the safe area, its body scrolls, both buttons stay reachable; Drop All uses the bounded confirm with a red action. P16, CAP 07, 08. | Small phone |
| 12 | §143.1 one predicate per claimable thing | Compliant | The mission tracker's "Ready" reads `main_claimable` / mission progress; a claim ends the follow through the same claim functions. P16. | — |
| 13 | §137.4 provenance survives consumption | Compliant | A dropped stack carries the online credit it took and returns exactly that on pickup; ten drop-and-pickup loops change no mission, counter, supply mastery, Map Mastery or credit. P16. | — |
| 14 | §115.4 / §8.1 automation never undoes a deliberate action | Compliant | Dropped piles belong to no enemy type, so no Auto-Collect takes them back (40 s of Auto-Collect beside a pile). P16. | — |
| 15 | §18.5 pointer on live controls; §18.10 first-profile progression | Compliant | The opening arrow points from the player toward the path and recomputes each frame; a defeat anywhere continues the tutorial; the camp lesson points at the live View Camp button when it shows, else World. P16, CAP 01, 05. | Arrow legibility over the camp |
| 16 | §18.8 one arbitration | Compliant | The guide treats the Prestige confirmation like the ordinary confirmation (`modal_open`). P16. | — |
| 17 | §16.1 / §16.4 surfaces; Help without side effects | Compliant | Help is a read-only page of the Basic cards for revealed systems; reading it changes no tutorial, reveal, exploration or counter. P16, CAP 10, 11. | — |
| 18 | §0.11 / §132 localization: English-first, no development notices | Compliant | Every new player-facing string is in `en.po` (validator checks code, scene keys and the dynamic `MAIN_HINT_*`, `MISSION_DO_*`, `FOLLOW_GOAL_*`, `SKILL_DESC_*` keys); the language list offers only selectable languages. SRC, P16. | — |
| 19 | §74 no double dashes | Compliant | Validator check over every English string. SRC. | — |
| 20 | §60.1 layered testing; §141.5 runner | Compliant | One focused probe in the runner, a windowed audio check outside it (headless cannot decode music), one capture run, full suite runs, all sequential. Stale contracts updated with the same intent, each listed in the Test Suite document. | — |
| 21 | §22 / §63 asset reuse | Compliant | No new art or audio: Kenney panels and border, PixelPlains star, sparks and arrow, the mission-ready sound, existing skill icons. | Licence record for `assets/sounds` still open (Change 12 item) |

## Android checklist

1. Guided starts with "Follow the path to your left." and the arrow beside the character; walking the path continues the tutorial.
2. Approaching each boss for the first time shows the red warning and plays the notification sound once; finding the Snowman opens Prestige.
3. Boss names read in red on snow, sand, autumn and rainy grass; skill icons read on their discs.
4. Following a mission and an opportunity together keeps both trackers readable bottom-right with the joystick, toast and guide card.
5. View Camp appears under the camp's name and stays with it while the camera moves; walking in never opens the camp panel.
6. Drop All on a stack, then pick the pile up again; Auto-Collect leaves it alone.
7. Music volume to 0 and back: the track continues from where it stopped; Pause and resume keep it.
8. The Prestige confirmation reads well and scrolls on a small phone.
