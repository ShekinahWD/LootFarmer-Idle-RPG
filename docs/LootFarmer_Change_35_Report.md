# LootFarmer — Change 35 Report: cross-platform review invitation and enemy-targeting lesson

Date: 28 October 2026. Brief: [LootFarmer_Cross_Platform_Review_and_Targeting_Tutorial_Implementation.md](LootFarmer_Cross_Platform_Review_and_Targeting_Tutorial_Implementation.md). Save schema stays 8 (new records default on load). English only; the 19 translation drafts were not imported.

## 1. Review invitation

**Files:** `scripts/game/review_invitation.gd` (state and world rules), `scripts/game/review_rules.gd` + `resources/game/review_rules.tres` (3,600 s, 2 s, 50%, 280 px), `scripts/game/review_dialog.gd` + `scenes/game/review_invitation.tscn` (panel), `scripts/game/game_ui.gd` (arbitration, Back, Settings → Feedback), `scripts/game/simulation.gd` (`held`), `scripts/game/campaign.gd` (owner, defaults, Prestige keep, normalize, validation).

**Eligible time.** `state.playtime_total` is advanced only by `sim.step`, which returns while the tree is paused, the app is in the background (`suspended`), a Prestige choice is open or the invitation is open (`held`, new). Offline settlement never advances it. At ≥ 3,600 s `state.review.status` turns `none` → `pending` (`eligible_at` recorded).

**Safe moment.** Every frame, while pending on a build with a storefront, `game_ui._offer_review` asks `review.world_block_reason()` (opening unfinished, chooser, paused/background/held, Prestige choice, offline claim pending, dead or respawning, HP < 50%, a living boss within 280 px or engaging, in combat: any enemy aggro or wind-up, a pending player strike, or the 5 s post-combat cool-down; moving) and `_review_ui_block()` (panel, confirmation, Prestige confirmation, banner shown or queued, guide card or chooser, joystick or map touch). Both must be clear continuously for 2 s; any block resets the count. Nothing is shown or consumed while waiting.

**While open.** `sim.held` is set from the panel's visibility every frame: no step (no combat, damage, movement, timers, play-time), `select_target` refused, guide waits paused. `modal_open()` includes it (guide, banners, movement and the offline claim wait).

**Answers.** Maybe Later, Android Back and Escape → `dismissed`. Review → `OS.shell_open(url)`; `OK` → `opened` (the page opened; nothing claims a review). An error keeps `pending`, increments `open_failures`, shows "The store page couldn't be opened. Check your connection and try again." and keeps both buttons. Dismissed and opened are final: kept by reload, Prestige and a storefront/device change; Hard Reset creates a new profile (status `none`, play-time 0). Settings → Feedback offers a permanent button for the build's storefront (absent without one); a successful open there also settles the invitation.

**Presentation.** Backing plate, gold border, divider and static corner sparks (the Prestige confirmation's language), the teal heart art, the player's own weapon and outfit around a Coin and a Gem, the honest-review copy, a Primary 84 px store button and a 64 px Maybe Later. No tween or timer. First-frame size: wrapped labels get their width before measuring, containers are sorted synchronously, and the hidden panel is laid out and drawn once at startup (invisible, every control input-transparent, not counted as open).

## 2. Storefront configuration

| Export preset | Platform / format | `custom_features` | Review button | URL |
|---|---|---|---|---|
| Android Release | Android AAB (Google Play) | `store_google_play` | Review on Google Play | https://play.google.com/store/apps/details?id=com.shekinahwelefuldesigns.lootfarmeridlerpg |
| Android itch.io APK (new) | Android APK, same package | `store_itch_io` | Review on itch.io | https://shekinawd.itch.io/lootfarmer-idlerpg |
| Windows itch.io (new) | Windows Desktop, embedded pack | `store_itch_io` | Review on itch.io | https://shekinawd.itch.io/lootfarmer-idlerpg |
| Android Bootstrap APK | test build | none | no prompt, no button | none |

- `resources/game/distribution_channels.tres` maps channel → feature tag, CTA key, URL. `current()` returns the one channel whose tag `OS.has_feature` reports; none, unknown or two tags → "" (no prompt, no Settings button, state untouched). Editor and probe runs have no tag. `--store-channel=google_play|itch_io|none` overrides it only in test profiles.
- `tools/export_rules.json` `mirror_presets` / `store_tags`; `tools/export_manifest.py` writes the same allowlist into both itch.io presets and fails `--check` on a wrong, missing or extra store tag.
- **Artifact check:** `godot --headless --export-pack` for each preset, then the packed `project.binary`: Android Release → `store_google_play`; Android itch.io APK → `store_itch_io`; Windows itch.io → `store_itch_io`; Android Bootstrap APK → no custom features. `export_presets.cfg` was unchanged by the exports.
- **Developer action before an itch.io release:** the new Android itch.io preset needs its release keystore set in the editor (`.godot/export_credentials.cfg`, never committed); the Windows preset has no icon or version metadata yet. The itch.io APK uses the same package name as the Play build, so the two cannot be installed side by side and an itch.io APK must be signed with the same key to update a Play install.
- **Adding a storefront:** one entry in `distribution_channels.tres`, one CTA string in `localization/en.po`, one export preset with its tag and its line in `store_tags`.

## 3. Targeting lesson

- **Gesture taught:** touch and hold the hero, drag to an enemy, release on it (`map_gestures.gd` → `sim.select_target`).
- **Basic:** `TutorialGuide.BASIC_DECK` = overview, **basic_target**, basic_gear, basic_growth, basic_world, basic_prestige (card 2/6; Got it, Skip and 20 s retirement unchanged). Help shows the same card. None unchanged.
- **Guided:** `guided_progress.STEPS` gains `target` after `move`. Detection: the only successful-selection path, `sim.select_target`, calls `campaign.guided.action("target", id)` after its own checks; the action marks the step only in Guided. Automatic acquisition (`_combat_target`) never calls it. The guide draws the demonstration toward the nearest targetable enemy drawn on the map (else the nearest in sight) and hides it while the player aims. With none in sight: "Find an enemy to target"; `OnboardingRules.target_escape_seconds` (60) of such active time marks the step with `target_skipped`.
- **Old saves:** `target` counts as done when `kill` is done (only possible for profiles saved before the step existed) and `normalize` appends it; profiles beyond Winter I and finished tutorials never see it.

## 4. English keys (tools/change35_strings.json, 14 new)

`REVIEW_TITLE`, `REVIEW_LEAD`, `REVIEW_BODY`, `REVIEW_CTA_GOOGLE_PLAY`, `REVIEW_CTA_ITCH_IO`, `REVIEW_LATER`, `REVIEW_OPEN_FAILED`, `SECTION_FEEDBACK`, `GUIDE_BASIC_TARGET(_DETAIL)`, `GUIDE_TARGET(_DETAIL)`, `GUIDE_TARGET_FIND(_DETAIL)`. No placeholders. The validator now also checks scene keys of `review_invitation.tscn`; the probe checks the dynamic CTA keys.

## 5. Validation

- `change_35_probe` 144/144 (cases listed in [Test Suite](LootFarmer_Test_Suite.md)).
- Full maintained suite: **38/38**. The first full run found one real regression, `camera_probe` (map touch not reaching the map in the first frames): the startup layout pass left the plate and buttons input-catching. Fixed (every control input-transparent during it) and covered by a new probe check; the final run passed.
- Visual evidence, `docs/Change_35_Evidence/` (each at 540, 432 and 768 px wide): `01_review_google_play`, `01_review_itch_io`, `02_review_open_failed`, `03_basic_target_card`, `04_help_target_card`, `05_guided_target_demo_mid`, `06_guided_target_demo_release`, `07_guided_player_aiming`, `08_guided_target_done_next_lesson`. Inspected: the store button is the dominant control, Maybe Later is legible, the demo starts on the hero and ends on the enemy.

## 6. Not verified (needs hardware or the stores)

- `OS.shell_open` with each URL on a real Android device (Play app vs browser for the Play link, browser for itch.io) and on Windows; Android system Back on a device (the shared Back handler and desktop Escape were tested).
- Real notch/cut-out safe areas (`LayoutService` insets are Android-only; desktop captures have none).
- Feel of the targeting demo and the 60 s escape on a phone; store review-policy compliance of the copy.
