# LootFarmer — Change 27: Google Play Store Assets + First Snowman Reward

**Task type:** In **Claude's existing local LootFarmer Git repository**, implement one narrowly approved gameplay reward correction and produce the **actual final-candidate Google Play store imagery and preview trailer** from authentic in-game assets and gameplay. Validate, document and **commit autonomously**. This is a production task, not an investigation-only plan: deliver real PNGs, real MP4, reproducible capture/source files and tests. **Do not use an attached game ZIP as the baseline**; use the current repository.

**Expected starting baseline:** Change 26, commit `37ae83e5c4e7ff68170695dfe21d5849eafb37a1`, Godot 4.7.2, app/Android Release version 26, state schema 8, save file version 3. Change 26 reported 35/35 maintained suite, dependency-verified **229-source-file Android export allowlist** and a validated signed 58,948,378-byte AAB. **First verify actual HEAD, branch, worktree, versions, installed toolkit, export configuration and latest docs**. If the local repository differs, use its authoritative current state, preserve unrelated work and determine the next chronological Change number (expected **27**).

## 1. Scope and authority — read completely before editing

**Read all of this brief**, then inspect the current repository versions of:

- `docs/Reusable_Game_Development_Playbook.md`, especially §§**0.9**, **22.2**, **49** (Android/store release checks), **60–61** (regression/save-phase policy), **63.1** (developer-editable assets), **87.1–87.9** (authentic, per-device screenshot capture), **101** (authored visual branding), **133.1–133.4** (real gameplay, capture, video composition and verification), **134.4** (publication boundaries), **135.1–135.4** (version-pinned toolkit, source control/export separation).
- `docs/LootFarmer_GDD.md`, `docs/LootFarmer_State_Contracts.md`, `docs/LootFarmer_Content_and_Balance.md`, `docs/LootFarmer_Asset_Registry.md`, `docs/LootFarmer_Test_Suite.md`, `docs/LootFarmer_Design_README.md`, `docs/LootFarmer_Change_26_Report.md`, and the latest full-production-audit addendum.
- `data/game/catalog.json` (particularly the Snowman, late-game bosses and their carried loot); the **actual current** kill/drop/save/Prestige/Hard Reset paths in `scripts/game/*` and `autoload/*`.
- `Godot-Marketing-Toolkit/README.md`, `Godot-Marketing-Toolkit/INTEGRATION_FOR_CLAUDE.md`, `Godot-Marketing-Toolkit/RELEASE_NOTES.md`, its manifest/adapter examples, the installed `addons/marketing_capture/`, `addons/store_screenshot_capture/`, and `marketing_capture_toolkit.lock.json`.
- Google Play's current preview-asset requirements at `https://support.google.com/googleplay/android-developer/answer/9866151?hl=en`. Dimensions below reflect the requirements checked 2026-10-28; recheck before publishing.

**Approved developer decisions:**

1. **ONLY Google Play listing assets in this batch**, plus the single Snowman first-kill reward correction. Social videos, social posting descriptions and social-specific capture/composition belong in a **separate later Claude chat/Change 28**; do not create any social masters here.
2. LootFarmer is **portrait**. ALL four requested screenshot destinations — **Phone, 7-inch tablet, 10-inch tablet, Desktop/Chromebook** — must be separately captured as **genuine 9:16 portrait gameplay renderings**. **Desktop is a destination, not an instruction to switch to landscape.** No landscape screenshot sets and no stretching/cropping/upscaling one device screenshot into another.
3. Six ordered screenshots per destination (**24 PNG screenshots total**), with **combat first**, then equipment collection/merging, then late-game farming, then world/Prestige. Keep actual native HUD in ordinary shots; **no added promotional headlines, slogans, captions, frames or fake UI on screenshots**. Keep untouched raw PNG masters.
4. The preview trailer is **one 30-second 9:16 portrait gameplay-first MP4**, opening immediately on a **late-game summoning boss** using its genuine helper-spawn behavior and player skill effects. Feature real equipment collection and merge, late-game combat/farming, world progression, a brief Prestige view, then brand. No misleading scenes, invented mechanics, synthetic imagery or lengthy logo intro.
5. The icon, Android adaptive icon layers and feature graphic are **composed from existing licensed/supplied game artwork**. No AI-generated images or repainted/synthesized gameplay. The feature graphic may carry the **LootFarmer game name**, but **no unapproved tagline**.
6. **Snowman's first lifetime kill guarantees the weapon it ALREADY CARRIES**, currently `stone_axe` in the baseline catalog. The user called it a sword conversationally, but the instruction is explicitly **the existing equipped weapon** — **never replace it with `stone_sword` or introduce a new weapon**. This reward is completely undisclosed in player-facing UI, tutorial, notifications and store copy.
7. Do one coherent implementation batch, verify final media plus game behavior, run the maintained full regression suite **once at the end** (targeted reruns only if debugging). Update relevant docs, auto-commit the completed batch; **do not push, upload, post, or publish**.

## 2. G01 — First Snowman kill: guaranteed existing weapon drop

**Intent:** First defeat of the Winter I Snowman must feel rewarding, without calling attention to a hidden guarantee.

**Required gameplay contract:**

- On the **first eligible Snowman boss kill in the lifetime of a player profile**, ensure that boss drops **one copy of its existing carried weapon**, obtained from the authoritative enemy/group definition (`catalog.groups[...]` / `enemy_definition` / `loot`), **not a newly invented or hardcoded replacement item**. In the Change 26-era catalog the group is `boss-snowman` and the equipped weapon is `stone_axe`; confirm against live code before implementing.
- Use the **normal loot pickup creation and on-ground presentation**. It is a ground drop, **not** an item silently inserted into inventory; collection/capacity rules stay unchanged. Do not show a special announcement, tutorial clue, reward banner, explicit guarantee text or dedicated visual effect.
- Natural loot rolls still run normally. If the weapon **already dropped naturally on that first kill**, count that as satisfying the guarantee and **do not add a duplicate**. Otherwise add exactly one carried-weapon pickup. Other normal rolls (outfit, supply, skill if applicable), coin/gem/XP, kill credit, achievement, mission and Prestige processing are unchanged.
- Grant on first lifetime kill only, **not the first kill of every stage visit, game run, save reload, or Prestige**. Subsequent Snowman defeats use the existing ordinary drop probabilities, even if the player lost, sold (if applicable), merged or otherwise no longer holds the first item. **Hard Reset** creates a new profile and re-enables this once-only drop.
- Applies identically to **Guided, Basic and None**. Do not interfere with the existing Change 15 first-two-merge-compatible normal-enemy onboarding guarantee. A boss is not an eligible normal-enemy tutorial kill.
- Persist the consumed guarantee safely across save/load and Prestige. Prefer an existing **durable lifetime kill fact** if its semantics are demonstrably correct; otherwise add the smallest explicit per-profile persisted marker with current-schema serialization and default handling. Consider the kill/reward/save order: the flag must not allow a second bonus due to a reload/claim race. **No unnecessary development-save migration/reset, no public-release migration work, no arbitrary schema/version bump.** If a schema field requires normal schema bookkeeping, document the precise impact.
- Implement at the authoritative **reward generation** boundary, not in marketing fixtures, editor hooks, or only the UI. The gameplay change must work for a real player in a shipped Android build.

**Focused automated tests (new registered Change 27 probe or an appropriate maintained probe):** fresh profile first Snowman defeat always produces the carried weapon at gear chance 0 (using a deterministic fixture); no second guaranteed weapon; naturally rolled first weapon does not duplicate; ordinary other drops preserved; save→reload and Prestige do not regrant; Hard Reset does; all three onboarding modes; change of Snowman's catalog weapon (fixture) is respected; no new player-facing copy. Respect actual current test framework and State Contracts.

## 3. M01 — Screenshot creative brief: combat before menus

**Exactly six screenshot concepts in this order, for EACH of Phone, Tablet_7, Tablet_10, Desktop:**

| # | Scene / message | Capture acceptance |
|---|---|---|
| **01** | **Late-game summoning boss + player skills** | Boss and player clearly in frame; helpers visibly spawned by the boss's **real summoning ability**; at least one real player skill effect visible; readable combat/health and native HUD; dramatic but not cluttered. |
| **02** | **Equipment collection** | Valuable loot visibly earned/available from authentic gameplay, with real inventory/equipment context if helpful. Do not depict an item as obtained unless it actually exists in this staged state. |
| **03** | **Equipment merging** | The actual merge mechanic shown at a meaningful moment: compatible duplicates, clear merge action/result and visible improvement without fabricated before/after art. Use a real merged outcome; no fake upgrade levels. |
| **04** | **Late-game combat and loot farming** | A distinct high-power farming scene with multiple real enemies, authentic auto-attacks/skills, meaningful drops and a readable player. Avoid merely repeating screenshot 01. |
| **05** | **World exploration/progression** | True world/map/camp navigation or a distinct seasonal environment, accurately displaying available stages/camps, fog and UI states. No revealed undiscovered content. |
| **06** | **Prestige and upgrades** | Real Prestige cards/progression with the game's own UI, optionally showing the upgrade context. No falsely granted cards or unlocks. |

### Boss selection — correction to the preceding conversation

**Do not use the Green Alien to satisfy “late-game non-final summoning boss”: in the supplied catalog `boss-green-alien` is the **Spring II final boss**.** The prior suggestion mistakenly identified it as a regular boss. For this approved marketing direction, **prefer `boss-sunflower` (Spring II, non-final; summons Sprout helpers, baseline max 2)** to show a late-stage summoner without spoiling the final boss. **Fallback:** `boss-grim-reaper` (Autumn II, summons Horned Hood helpers) if the Sunflower shot proves visually weaker; still late-game and summoner. Inspect current catalog/abilities before capture. **Do not show the final boss unless the developer later explicitly approves it.** A genuine summoning *event* must be captured: not helpers manually spawned beside a boss to imitate its ability.

**Screenshot policies:**

- Generate **24 actual PNGs** organized `store_assets/screenshots/Phone/Phone_01.png`…`Phone_06.png`, similarly `Tablet_7`, `Tablet_10`, `Desktop`. Raw unedited frames (or byte-identical release copies) must be retained with scenario IDs and output hashes.
- Use **portrait 9:16** capture profiles and real per-device viewport/layout initialization. Do not use a 1920×1080 desktop landscape canvas. The device categories may use different pixel sizes, UI scale, safe-area/DPI simulation and layout profile, as directed by the approved toolkit; **never relabel a Phone screenshot as Desktop**.
- **Aim for true final dimensions of at least 1080×1920** (Google Play's promoted-game screenshot recommendation). E.g. Phone **1080×1920**, Tablet_7 **1440×2560**, Tablet_10 **1800×3200**, Desktop **1620×2880**, *if the toolkit supports authentic layout at these targets*. All are exact 9:16 and within Google's 3840-pixel general screenshot maximum. These are candidate presets, **not an instruction to upscale**; use the validated toolkit's actual classes and record chosen targets. For large-screen categories use real portrait renderings and confirm Play's live size/aspect requirements. If a window manager clamps requested pixel dimensions, use the Playbook §87.7 viewport/maximum-size solution or equivalent honest renderer; fail loudly instead of silently exporting a smaller/scaled capture.
- Google Play screenshot upload format: **24-bit PNG, RGB, no alpha**, with dimensions and aspect checked per file. The pixel-art style must remain pixel-sharp intentionally; no blur, invented glow, smoothing or resolution distortion.
- Preserve authentic normal game HUD by default. The relevant menus are allowed when demonstrating real collection/merge/Prestige features. Do not overlay promotional text. The same conceptual moment (fixture/seed) should correspond to each numbered capture across all four destinations, allowing real responsive differences.
- Generate a developer-friendly **contact sheet** and source/provenance manifest for review. Include a short **alt-text draft** (≤140 characters) for each unique concept, to be reviewed at listing time; these are metadata, not image overlays.
- **Desktop/Chromebook category:** capture the requested **portrait Desktop** output. Never claim the game has a dedicated landscape Windows mode. If the Play Console Chromebook slot requires a supported ChromeOS runtime and evidence is unavailable, keep the prepared Desktop captures but clearly mark Chromebook device-specific listing acceptance as pending; do not misrepresent Android support.

## 4. M02 — Google Play icon, Android adaptive icons and feature graphic

**Deliver finished files and the editable composition configuration/source** using **only supplied/authored LootFarmer art** and applicable licensed typefaces; do not commission/generate AI artwork or download a replacement illustration. Respect pixel-art nearest-neighbor scaling and source palette.

**Google Play store icon:**

- A distinct, recognizable **512×512** image, **32-bit RGBA PNG**, **≤1,024 KB**, following the current Google Play icon rules. Crisp silhouette, high contrast and clarity at small displayed sizes; use a strong existing game character/equipment visual as the focus, not tiny UI panels or a screenshot miniaturized to an icon.
- Avoid a text-heavy icon, price/rank claims, platform badges or unlicensed font/images. Output a preview/contact-sheet comparison at small viewing sizes for human choice. Do not claim brand approval before the developer has reviewed the actual pixels.

**Android launcher/adaptive icon layers:**

- Generate and integrate the actual Android/Godot export icon assets the project needs: background, foreground and optional/currently supported monochrome layer (where supported). Respect adaptive safe area/masking, transparent foreground, pixel-art quality and official platform constraints. Keep source layers editable, with reproducible export.
- Update **relevant** `project.godot`/Android Release preset icon paths so the exported app uses the new launcher design. Do not alter package id, signing, permissions, SDK, ABIs or unrelated export fields. Confirm these new required icon source dependencies are included in the **Change 26 positive allowlist** and the final signed export (no missing icons); rebuild the manifest rather than bypassing the fail-closed checks.

**Feature graphic:**

- **1024×500**, **24-bit RGB PNG with no alpha**. A separate composition from the icon, showing the game's actual fantasy/pixel-art combat/loot identity. Use real pixel-art characters/seasonal terrain/equipment from the game's assets, while allowing composed positioning, background and a clean **LootFarmer** game-name wordmark. **No unapproved slogan/tagline, invented gameplay or fake UI.** Keep focus central and important content away from crop zones; legible on a small phone.
- Generate source/layout config and one final graphic; provide a scaled review preview. Do not silently substitute the Google Play app icon as the feature graphic.

**Licensing gate:** Audit/record which existing sprites, font and music/SFX assets were actually used in the deliverables. **REL-02 licensing records for Pixel Plains and `assets/sounds` remain open in Change 26**; making a capture is allowed, but **do not claim publication clearance or upload media until proven commercial/promotional usage rights**. Do not delete originals or invent license grants.

## 5. M03 — Portrait Google Play preview trailer (30 seconds)

**One** final 30-second portrait **1080×1920, 9:16, 30 fps** gameplay-first **MP4 (H.264, yuv420p, AAC if audio present, faststart)**. No social-media videos or landscape alternate are authorized. The source shot footage, cut timings, audio mix configuration and editable manifest are required deliverables too.

**Approved story direction and time allocation (adjust individual cuts only if needed to preserve excellent pacing and exactly 30.0 s total):**

| Time | What must be visible |
|---|---|
| **0–7 s** | **Immediate late-game summoner boss combat**, preferably the Spring II **Sunflower**: genuine spawn action with new helpers arriving; player activates real skills. Open on action, not a logo. |
| **7–13 s** | **Gear drops/collection and a real equipment merge**; show meaningful progression in a few readable cuts, no synthetic merge result. |
| **13–21 s** | **Powerful late-game farming**, multiple authentic enemies, skills, combat and drops. Distinct from the boss scene. |
| **21–26 s** | A compact glimpse of **world/stages/camps**, then **Prestige/upgrade progression**, using actual UI and valid profile state. |
| **26–30 s** | Another strong gameplay beat, followed by a **brief LootFarmer name/logo end treatment** (prefer ~1–2 seconds). Total footage should remain overwhelmingly authentic gameplay (≥80%). |

**Capture and composition rules:**

- Use **Godot Marketing Capture Toolkit 1.0.2**, same game-specific scenario adapter as screenshots, and its validated **Godot Movie Maker → AVI/real footage → FFmpeg → MP4** route. Use the current toolkit configuration instead of reconstructing a new capture framework. Verify version/hash lock and tool availability before recording; if missing, report the concrete blocker rather than invent paths, source clips or success.
- The game actually performs all depicted actions. Use **isolated deterministic test state** to reach real late-game conditions quickly. Staging/fast-forwarding to just before a real summon is allowed; faking a skill animation, changing combat damage, hand-spawning helpers as though summoned, or compositing counterfeit equipment is not. Scenario preconditions and postconditions must assert actual mechanics (summon event occurred, expected helpers exist, player skill used, merge succeeds).
- The camera and UI must suit the genuine **portrait** game viewport; never rotate/crop a 16:9 gameplay recording into a claimed portrait game video. Keep important on-screen controls and character action inside safe framing; avoid fight/loot/UI ambiguity.
- **First seconds matter.** Use recognizable action without explanatory text; only the approved **LootFarmer brand name/logo** is permitted as an added end card. No invented marketing headlines, unsupported product claims, price/rank/download calls to action or long exposition. Native UI text is authentic and allowed. Keep optional captions/locale work out of scope; add them later only with approved copy.
- Preserve and mix genuine in-game SFX and background audio **only when source use is verified/licensable**; do not source new copyrighted music or silently use unverified external tracks. Audio may be game-audio-only if that is legally safe; mark any publication-rights uncertainty clearly. Maintain smooth mix and avoid clip-by-clip music restarts.
- Use toolkit's proven fade transitions and verify actual decoded frames: no one-frame black hard cuts masquerading as fades, no truncated gameplay actions, no off-by-one duration, no abrupt sound dropouts. Keep >80% authentic gameplay visible. Provide shot/transition **review sheet/contact sheet** and a normal-size preview. A playable MP4 must actually exist; a manifest alone is not completion.
- **Do not upload to YouTube or Google Play**. The store uses a YouTube URL for the uploaded preview later; this pass delivers the local **MP4** for human approval.

## 6. M04 — Toolkit integration, source safety and reproducible production

1. **Validate Toolkit 1.0.2 first.** Verify `Godot-Marketing-Toolkit/VERSION` and toolkit-managed files against `marketing_capture_toolkit.lock.json`; follow `INTEGRATION_FOR_CLAUDE.md`. Don't modify installed toolkit code directly. Implement only LootFarmer-specific adapters/shot/manifest/composition glue. If a proven general toolkit defect needs fixing, distinguish it from game adapter work and report its validated fix/version; do not silently fork or modify installed addon files.
2. Use **one game-specific `prepare_scenario(id, options)` interface** shared by screenshots and trailer, based on the game’s real game state. Scenarios must verify **test-save isolation** before game initialization/save read, and keep normal autosave off; do not expose permanent editor-only cheats or fake UI to regular gameplay. Do not let marketing runs mutate the developer's profile or cause a new player save/Prestige.
3. Keep the authored adapter, manifest, asset composition code/config, release-ready small source imagery and validation scripts in normal **version-controlled project-relative paths** (e.g. `marketing/`, `tools/`, `store_assets/`), and make them easy for the developer to adjust visually where reasonable. Keep raw AVI/MP4 capture and high-volume generated PNG output in clearly organized **non-runtime** folders. Store useful review contact sheets/evidence and a manifest of hashes/paths; do not commit massive raw recording archives by default unless an existing repository policy explicitly expects them. **Never discard the raw footage before developer review** — keep it on disk with a reproducible regeneration command.
4. Ensure the complete **Change 26 export allowlist and verifier** remain authoritative. Marketing generator source, screenshot PNGs, raw recordings, trailer MP4, test saves, review sheets, toolkit source and installed capture addons **must not enter the Android AAB/APK/PCK**. Put `.gdignore` at appropriate output/reference directories and update the fail-closed manifest exclusion rules only where justified. Do not accidentally exclude the genuine new launcher icon files or runtime content.
5. Save an easy-to-follow file map and **one-command/short-command reproducible workflow** for each deliverable category: screenshots, icon/feature graphic, trailer, validations. Store per-file provenance, stage, scenario ID, screen category/viewport, seed and an explicit distinction between raw capture and final deliverable.
6. Before claiming success **open/inspect** generated images, representative screenshots from each of the 4 categories, feature graphic, launcher icon previews and video keyframes/transition sheets. Automated correct dimensions alone cannot prove that player/boss, loot, text or visual scale are compelling and legible. Fix actual camera/framing/capture issues without changing game combat or UI design to make marketing easier. Record any review issues the developer should decide.

## 7. M05 — Version, regression gates, exported artifact and documentation

**Implementation order:** Game reward change → update game test → safely build capture scenarios → generate icon/feature/screenshots/trailer → verify final pixels/audio/packaging → documentation → **single final complete suite** → commit. Use targeted checks as needed while debugging, but no repeated full regression or multi-hour late-game balance simulation.

**Verification required:**

- Unit/integration tests for **G01 Snowman lifetime drop** including distinct natural-drop, reload, Prestige, Hard Reset, tutorial-mode and catalog-driven cases. Register any new probe in `tools/run_probes.py`. Do not bypass old tests or weaken unrelated assertions to get green.
- `python tools/run_probes.py` at the end; expected baseline 35/35; report **actual** result and additional Change 27 coverage. Count Godot `SCRIPT ERROR:` output as test failure even if exit status is zero.
- `python tools/export_manifest.py --check` after adding runtime launcher icons; verify new required icon files are covered and **marketing files are excluded**. Run source/asset import checks. Perform one new Release AAB verification export when the existing SDK/signing setup permits, then `python tools/verify_export.py <actual-v27-aab>`; record real version, signed status, ABIs, icon dependencies, missing/unexpected files and exact archive byte size. **Do not claim device validation** from the AAB inspection, and don't expose secrets. AAB and other generated binaries stay untracked/ignored.
- Actual image validation: all **24 screenshots**, correct ordering/names/categories, authentic renders and real target sizes; RGB/no alpha for screenshots/feature graphic; RGBA/≤1,024 KB for Play icon; feature exactly 1024×500; exact source/final hash tracking. Validate transparency where adaptive icon layers require it.
- Actual video validation via `ffprobe` + decoded-frame/transition inspection: **1080×1920**, portrait **30fps**, **~30.0 s** (prefer exactly 30), H.264 yuv420p, audio format/content when present, smooth fades, no accidental black bars and legible end branding. Save contact/review sheets with timestamps.
- Marketing capture must **not change gameplay or balance** except the approved first Snowman weapon guarantee. Preserve stage/skill/enemy tuning, late-game pacing, Prestige gates and keys, world fog, onboarding modes, save semantics, performance improvements, player UI and Android package identity.
- Since the Snowman rule changes real gameplay, update the **GDD, State Contracts, related Test Suite** with the internal hidden once-per-profile rule, and any relevant catalogue/balance notes. Update Asset Registry with icon/marketing source provenance and export inclusion/exclusion. Update Design README and `docs/LootFarmer_Change_27_Report.md` with real screenshots/trailer inventory, scenarios, errors/limits, licensing status and verification. Preserve historical docs. Amend the reusable Playbook only for a **truly new, tested reusable principle** not already covered by §§87/133/135; don't paste LootFarmer-specific screenshots, scripts or numeric results into it.
- Align the next app version and **Android Release** `version/code` to **27** (`version/name` policy preserved); do not needlessly change the Bootstrap preset. Avoid unrelated schema migrations or save resets. Review all modifications, binary files and `git status` before commit.

### Git and handoff

- **AUTOMATIC LOCAL COMMIT MANDATORY** once validation is green: suggested message **`Change 27: produce Google Play assets and guarantee first Snowman weapon`**. Do not ask the developer to run Git commands; **do not push**. If the actual repo is already beyond Change 26, determine correct next sequential number/message before touching version codes.
- Preserve any pre-existing unrelated local edits; don't discard them by force. Generated media must be accessible to the developer under predictable local paths even if bulky binaries are ignored by Git; report what is committed vs intentionally left locally untracked/ignored.
- Report actual paths, file sizes, test counts, AAB status, media validation results, unresolved licensing/review requirements, save behavior, version, commit hash and whether worktree is clean. **Do not claim that human approval or Play Console publication occurred**.

## 8. Explicit exclusions — do not accidentally widen this Change

- **No social media videos** (not 5 focused, not 5 landscape/full-frame, not 10 descriptions). **Separate Change 28 Claude chat.** You may retain reusable *store trailer footage* so Change 28 can derive approved social edits, but do not make the social package in Change 27.
- **No free demo implementation** and no demo-specific store screenshots/preview. Those must show the **actual future two-stage demo build**, generated later.
- **No runtime localization, 20-locale ASO/listing text, localized graphics or caption-writing campaign**. English store listing approval and translations are separate work. The approved screenshot default is language-neutral with in-game native UI; brand-only feature and trailer text need no extra tagline.
- **No general late-game rebalance** and no new features/content/UI overhaul/Steam port. The sole gameplay change is the hidden first Snowman carried-weapon drop.
- **No Android upload, YouTube upload, store listing edits, release submission or social posting**; these remain human-approved later actions.
- **No replacement or invented assets**, no unlicensed external source material and no novel toolkit rewrite. Never introduce Android runtime dependencies on FFmpeg/Pillow, capture source or fonts.
- No mandated Android profiling, low-end FPS traces or manual grinding; human reviews the actual outputs and runs ordinary device play later.

## 9. Definition of done — ALL must be true or specifically flagged as blocked

- [ ] Real, hidden **once-per-lifetime-profile** Snowman reward: existing catalog-carried weapon (baseline `stone_axe`), no duplicate if natural roll, standard world pickup, other drops unchanged; persists across load/Prestige and resets on Hard Reset. Registered automated tests green.
- [ ] **24 authentic screenshots** delivered: six **approved order** scenes × **Phone, Tablet_7, Tablet_10, Desktop**, all separately rendered portrait 9:16 with real target dimensions and no promotional text overlays. Contact sheet and original PNGs kept.
- [ ] Opening showcase is a **real late-game non-final summoning boss** (prefer Spring II Sunflower), genuine summoned helpers and actual player skill effects; **no final Green Alien boss spoiler**.
- [ ] Google Play **512×512** compliant icon, real integrated Android adaptive icon assets, and **1024×500** genuine-asset feature graphic, editable sources and visible review previews.
- [ ] Exactly **one 30-second portrait trailer**, real Godot gameplay, strong summoning-boss opening, loot/merge and late farming, proper audio/fades/brand ending, verified actual MP4 and keyframe/transition review sheets. Editable shot/manifest and raw clips retained on disk.
- [ ] Toolkit 1.0.2 installation/lock verified and used; real game-specific reproducible capture adapter/manifest, source-save isolation, no synthetic gameplay or accidental modification of user profile.
- [ ] Generated/marketing-only files excluded from exported game; new **runtime launcher icons included**; Change 26 positive manifest check and actual artifact verification pass (or explicit toolchain blocker); correct ARM-only release config preserved.
- [ ] Full maintained suite green at end with new Change 27 probes, no script errors; GDD, State Contracts, Tests, Asset Registry, Design README, Change 27 report updated; historical docs preserved.
- [ ] App and Release version advanced sequentially (expected 27), a **local Git commit** created autonomously, hash/worktree status reported; **no push/upload/publish**.
- [ ] No social deliverables, demo art, ASO copy or late-game rebalance in the diff; external licensing and human media approval are clearly open where relevant.

**Required final Claude response:** Summarize **G01, M01–M05** with actual created asset paths/counts and key visual checks; Snowman first-kill persistence/duplicate verification; source footage/repro commands; trailer metadata and frame checks; AAB/allowlist result if exported; full-suite command/count; exact docs changed; unresolved rights or device checks; and Git message, full hash and clean/dirty status. If a real image or video could not be produced, state the exact blocker rather than claiming a manifest or placeholder satisfies the deliverable.
