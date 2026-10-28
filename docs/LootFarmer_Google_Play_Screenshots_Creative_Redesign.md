# LootFarmer — Google Play Screenshots: Focused Creative Redesign and Production

**Task:** Produce the final *Google Play screenshot images only* in one dedicated Claude Code conversation. This is not a combined icon / feature-graphic / trailer batch.

**Baseline:** Use the developer's current local LootFarmer Git checkout. Do not assume a specific latest Change number; the previous Change 32 trailer received a subsequent correction whose commit number must be checked in Git. Do not use a historical ZIP as a base.

**Read first:**
- The current `docs/Reusable_Game_Development_Playbook.md`, especially §§87.1–87.9 (original authentic per-device screenshot workflow), §101 (separate marketing asset batches), §133.4 (shared scene adapter where relevant), §134 (approved claims/language-neutral screenshot rules), §135 (pinned toolkit and reproducibility), §49 (store/export checks), §63.1 (editable authoring), and applicable test/export rules.
- Current `docs/LootFarmer_GDD.md`, approved content and asset registry, current project asset/scenario documentation, `docs/LootFarmer_Change_32_Report.md` where available, and the active screenshot implementation under `marketing/`, `store_assets/` and installed `addons/`.
- Current **Godot Marketing Capture Toolkit 1.0.2**, its integration instructions, and pinned/locked source. Check the installed version and status instead of guessing paths or silently replacing toolkit files.
- Official Play screenshot guidance (verify the live requirements before final delivery): https://support.google.com/googleplay/android-developer/answer/9866151?hl=en . Current guidance emphasizes accurate gameplay, up to 8 images per class, at least 3 portrait 1080×1920 game screenshots for certain promotional placements, minimum 4 large-screen screenshots, 9:16 portrait, JPEG or 24-bit PNG without alpha, and consistent visual quality.

## 1. Creative objective and boundaries

The previous screenshot package failed creatively: it repeatedly showed nearly the **same green background** and similar enemy/equipment combinations. Correct file dimensions and passing automated tests were not sufficient.

Create a coherent **six-image narrative across each of four device categories**, prioritizing the real game's strongest differentiator: **defeated enemies can drop the weapons and outfits they are carrying, and equipping them visibly changes the player's appearance**. Let gameplay, enemy variety, seasonal art and native UI communicate this. Avoid six images of similar map color and nearly identical framing.

The approved creative order is **boss combat first, equipment collection, equipment merging, late-game farming, world exploration, Prestige**. Preserve this sequence exactly. The user has already approved that marketing emphasis, so do not stop for new creative approvals. Claude owns the concrete choice of gameplay camera moment, encounter, visible equipment, seasonal location, and framing within these boundaries.

**This batch produces only screenshots, their capture code/configuration, previews, validation and game-specific documentation.** Do not edit or regenerate the approved store icon, adaptive icons, feature graphic, trailer, audio, English/translated listings, social videos, game combat, drop rates, UI, game economy, save system, tutorial or the reusable Playbook. Do not publish or push.

## 2. Final deliverable: 24 separately rendered portrait screenshots

Exactly **six numbered gameplay screenshots for each of four device destinations**:

| Folder | Filenames | Quantity |
|---|---|---:|
| `store_assets/screenshots/Phone/` | `Phone_01.png` to `Phone_06.png` | 6 |
| `store_assets/screenshots/Tablet_7/` | `Tablet_7_01.png` to `Tablet_7_06.png` | 6 |
| `store_assets/screenshots/Tablet_10/` | `Tablet_10_01.png` to `Tablet_10_06.png` | 6 |
| `store_assets/screenshots/Desktop/` | `Desktop_01.png` to `Desktop_06.png` | 6 |

**All are 9:16 portrait**, including Desktop/Chromebook. Desktop names a screenshot destination, not a landscape game orientation. Use authentic renders at each target's actual device-class resolution/layout, not an image stretched/cropped/rotated/copied from another class. Each numbered screenshot should represent the same scenario moment across classes, with natural responsive differences. Investigate the toolkit's existing profiles and select target pixel dimensions consistent with live Play guidance: aim for **at least 1080×1920** true captures (e.g. Phone 1080×1920; other target sizes may vary), and never claim a smaller, letterboxed or resampled image is a genuine full-resolution device render. Large-screen shots must be tested with the actual portrait viewport. If the OS clamps the capture size or large-screen UI clips, fix the capture path/viewport and retry; don't silently resize output.

**Google Play format:** 24-bit RGB PNG, no alpha, exact aspect and pixels checked. Retain untouched authentic originals and provenance, ideally delivered screenshot PNGs byte-identical to the raw capture. Keep pixel art intentionally crisp (nearest-neighbor when supported); do not blur/stretch. Do not add borders, fake device frames, promotional copy, callouts, arrows, logos, marketing title bands or composite before/after images. Native real-game HUD and panel text are allowed and usually desirable. One language-neutral screenshot set is reused across all store locales.

The requested Desktop category must be portrait. Do not assert the game has a separate Windows/landscape build or certified Chromebook compatibility; report Chromebook listing/device availability as unverified until separately established.

## 3. Six scenes in approved store order

Use the game's actual stage/enemy/equipment catalogs. Specific candidates below are **direction and quality targets**, not permission to invent game content. Validate current stage membership/abilities before choosing a scenario. The selected set must visibly represent **Winter, Summer, Autumn and Spring** across the six screenshots, with four recognizably different equipped outfits/weapons and strikingly different terrain/weather. No entire sequence may be dominated by the same green-background view.

| # | Concept (do not change order) | Creative/functional acceptance |
|---|---|---|
| **01** | **Late-game summoning boss and skills** | Prefer **Spring II Sunflower** in real rain. Capture an exciting *actual* summoning event with Sprout helpers, recognizable boss/player, a real skill effect, combat feedback and native HUD. No final-boss Green Alien spoiler. Frame so the boss remains visible, not obscured by giant VFX, menus or damage numbers. |
| **02** | **Steal enemies' equipment / visibly wear it** | Prefer a visually distinct **Summer II Teal Dinosaur** outfit and Iron Sword (consistent with the approved icon/feature graphic) if the scenario renders best. Show genuine acquired/carryable gear and the character **actually wearing enemy-sourced equipment**, with a recognizable enemy and meaningful collected/dropped loot visible. A static screenshot cannot literally depict the entire before→after action; choose a truthful moment that communicates the identity link best. Use the normal engine equipment/loot state; no fake pickups, no invented outfit. |
| **03** | **Merge equipment and improve it** | Show a real merged item at a clear, readable native UI state with recognizable duplicate/merge context and a meaningful **actual** stat/level improvement. Avoid tiny unreadable panels or a cluttered full-screen inventory. Choose **Winter** as this screenshot's visible environment if composition permits, with winter enemies and/or a winter equipped look behind the authentic panel. A merge may be prepared by isolated deterministic scenario state, but must use the actual game merge action/result. |
| **04** | **Late-game auto-farming/loot combat** | Choose **Autumn II** with **falling leaves**, visually distinct enemy types, another equipped outfit and weapon, high-powered real skills/combat and visible loot. Different camera framing from #01; show an appealing playfield, not a second identical green boss scene. Avoid showing the same equipment as #02. |
| **05** | **World exploration/progression** | Show the authentic World map and stages/camps/travel/fog as the current player could legitimately see them, or an actual exploration screen that convincingly communicates seasonal/world progression. Don't expose undiscovered enemies/camps or fabricate stage access. Ensure the screenshot is meaningful at phone size and visually distinct from the first four. |
| **06** | **Prestige and permanent upgrades** | Show genuine unlocked Prestige cards/progression in the native panel (and real HUD/context where possible). Use readable meaningful rewards, not locked placeholders or illegible card walls. Set this in a visually different backdrop where feasible so it isn't another duplicate of #02/04. The screenshot's purpose is progression; it can use a panel, but the key card/bonus must be clear. |

Across the set, audit actual environment weather: **Spring II rain**, **Autumn II falling leaves**, **Winter snowy**, **Summer distinct seasonal terrain**, and differing enemies/gear. Two scenes can be on visually related maps only if they are substantially distinguished by composition, action, outfits, enemies and background elements. A weather effect that's too subtle in a still may be supported by choosing a stronger authentic moment/area, not painted into the screenshot.

**Core selling point check:** If a viewer only sees #01–#03, the images should clearly imply this is an action/idle RPG about defeating enemies, taking recognizable loot, equipping their appearance and merging gear. If #02 cannot honestly communicate visual equipment transformation through a single native screen, choose the best authentic frame and document the limitation rather than manufacturing a collage or adding explanatory text.

## 4. Independent creative investigation, without reopening prior decisions

Before recording, examine the old 24 screenshots and create a compact critique (background duplicates, unreadable UI, character scale, enemy repetition, missed weather, empty negative space). If useful, inspect a small relevant sample of successful idle-RPG / pixel-art Google Play screenshot presentations for **framing and ordering principles**, never copy their graphic elements or invent visual claims. This is a focused screenshot task, **not** a repeat of the full icon/feature-graphic market research.

Use actual game assets and the existing validated capture tooling. Choose the best scenes independently. Create at least one alternate candidate for any weak concept (bad particle timing, tiny character, unreadable panel, inactive boss, poor seasonal contrast), inspect both at realistic store sizes, and select the better authentic shot. Do not force a technically valid but unattractive frame through the final gate.

Do not alter the already-approved creative direction, product name, loot behavior, marketing wording or game balance to manufacture a better screenshot.

## 5. Technical capture methodology

1. **Preserve approved assets:** hash the current final icon/adaptive icons, feature graphic, trailer (including any recently corrected trailer), audio sources and all other approved media **before** work. Verify those hashes after work; no incidental regeneration.
2. **Reuse toolkit:** verify `Godot Marketing Capture Toolkit 1.0.2` and installed lock/status. Reuse existing screenshot adapters and real-game scenario mechanics. Do not modify locked toolkit source or installed addon copies ad hoc. Changes to genuinely reusable toolkit code require a separate validated version, not a silent fork.
3. **Prepare deterministic real state:** stage/enemy spawn/skills/loot inventory/equipped items/mission/map access must be consistent with the GDD and actual game APIs. Author development-only screenshot scenarios/fixtures if necessary; they may start from known valid progressed states and use real game actions to set up the final frame. Do not mutate user saves, inject fake UI labels, bypass runtime equipment styling, or make gameplay-specific changes for marketing. Respect test-profile/save isolation and auto-save safety.
4. **One scenario, four real render profiles:** freeze at the correct gameplay moment, adjust the real viewport for each target, wait for responsive layout/render to settle, capture native screen, then restore prior viewport, visibility and pause state. Use Playbook §87.7 OS-window-max/clamping guards. Confirm same scene moment across the four targets (seed/event IDs/character state), not a later action as another device finishes rendering.
5. **HUD policy:** default real HUD on. Use a real panel only where it helps demonstrate the approved concept. Hide only explicitly known development-only overlays; no screenshot automation buttons/tooltips. Do not remove regular UI arbitrarily to pretend to offer a different player experience.
6. **Scope and export:** put final images under `store_assets/screenshots/`, use `.gdignore` for non-game media, and keep raw captures, fixtures, contact sheets and generator code excluded from the game via the existing positive resource allowlist. Never delete purchased art or alter the production content manifest just to make a screenshot. Confirm the release export manifest remains unchanged unless a legitimate unrelated source-file dependency actually changed (none should).
7. **Reproduce:** keep a game-specific source manifest of scenario ID, map, encounter, equipped weapon/outfit, UI state, render target, requested/actual dimensions, raw file/hash, final file/hash, and notes. Provide a reliable one-command or clearly documented short-command regeneration path. Don't overwrite approved icon/feature/trailer evidence as a side effect.

## 6. Visual review and acceptance checks

A successful run MUST produce and visually review the **actual 24 delivered images**, not just report that the engine screenshot commands returned successfully.

- One **24-image overview grid** grouped by scenario and device, plus **six larger scene comparisons** or a useful per-device contact sheet. Include at least one store-card-size preview (e.g. 360px wide) to assess HUD readability and composition.
- Compare the old vs new screenshot set on **season variety**, enemy/character silhouettes, outfit/weapon changes, action readability, boss summoning, loot clarity, panel legibility, pixel-art crispness, and repetition. Show qualitative evidence, not invented conversion claims.
- Programmatic validations: exactly 6 per folder, expected filename sequence, exact 9:16 dimensions, minimum suitable resolution, true PNG RGB/no alpha, no borders/overlays, unique content, correct scenario metadata, and stable deterministic regeneration. Use actual raster inspection to detect poor poses/blank frames. Do not assume difference in file hash proves meaningful visual diversity.
- Gameplay evidence: boss actually summoned helpers; equipment genuinely from enemy drop and equipped via real mechanics; a genuine merge result; autumn leaves/rain are authored effects; stages/camps and Prestige accurately represent accessible states.
- **Across the entire six-shot story:** Winter, Summer, Autumn, Spring all represented and clearly distinguishable. Do not merely tint a screenshot into another season. Four distinct player gear presentations where practical, with distinct weapons and outfits; if one slot cannot reasonably show gear, satisfy this coverage in the others and document the visual evidence.
- Compare every new screenshot with what it replaces: major improvement should be visible without needing technical explanation.
- Verify originals and edited delivery files have matching hashes if no user-approved overlays are introduced.
- Audit marketing output against the already-approved brand style, but don't add icon/feature imagery onto raw gameplay screenshots.
- Audit Play Console requirements and provide **six short English alt-text drafts** (<= 140 characters each) as **separate metadata**, not as overlays.

**Failure behavior:** If a scene is visually disappointing, use alternate legitimate gameplay moments or another matching enemy/season; do not accept a weak image simply because test assertions pass. If an actual engine/UI defect blocks capture, report it accurately and confine fixes to genuinely required capture tooling; do not unilaterally redesign gameplay/UI.

## 7. Documentation, testing, commit

- Update the game-specific marketing screenshot README/manifest, evidence index, screenshot capture instructions, affected asset registry and test-suite notes only as warranted by actual changes. Preserve historical reports. Do **not** modify the reusable Playbook yet. After the user reviews and approves these screenshots, successful validated lessons can be documented in a separate Playbook update.
- Maintain or add useful screenshot-scenario/verification probes to the existing test runner; no unnecessary migration or version/schema change. Run cheap targeted tests while developing, then **one complete maintained regression suite at the end**. If failures occur, correct them, use focused reruns, then run the complete suite once again.
- Recheck `python tools/export_manifest.py --check` or the current equivalent, and the positive resource allowlist/exclusion checks. No full AAB export is needed for screenshot-only changes unless the existing pipeline requires one to prove export exclusion.
- Determine the next chronological **Change N** from the real local Git history. The earlier Change 32 trailer revision may already have produced a later commit; don't blindly reuse a number. Commit generated deliverables and the required source/docs according to existing repository media policies. If full-resolution final PNGs are intentionally ignored by Git, preserve them on disk and commit reproducible source plus appropriate evidence/manifest; report precisely which outputs are Git-tracked vs local-only.
- **Automatically commit** the completed validated change, leaving a clean worktree unless pre-existing developer modifications must be preserved. Do not push, publish, upload media or modify the release build/version merely because marketing screenshots changed.
- At completion report the Change number/hash, paths to all 24 PNGs, contact-sheet location, chosen scenarios/map/gear for each scene, before/after highlights, sizes/provenance, exact test/manifest results, any blockers or unverified claims, and unchanged-branding proof.

## 8. Explicit exclusions

- No app icon / adaptive icon regeneration.
- No feature graphic modification.
- No store trailer changes (including the recently requested four-seasons correction).
- No social media video production or caption writing.
- No editing the approved `LootFarmer: Idle RPG` title, English store descriptions or 20-locale listing package.
- No free demo implementation or demo screenshots. A future demo must capture its **own** two-stage build and only advertise what that demo contains.
- No gameplay balance changes, new mechanics, drop adjustments, art asset purchases, AI-generated image content or new marketing slogans.
- No Playbook editing in this task; revisit it **after** user approval of final screenshots.

## 9. Definition of done

- [ ] Twenty-four real separately rendered **portrait** screenshots delivered, six per Phone / Tablet_7 / Tablet_10 / Desktop.
- [ ] Approved six-concept order retained with authentic gameplay and readable native HUD.
- [ ] Four seasons distinctly visible, diverse enemies, four meaningful gear looks and a non-final summoning boss.
- [ ] #02 communicates gear obtained from enemies and visibly equipped by the player, without fabricated claims.
- [ ] #03 represents a real merge; #05 accurate world progression; #06 real Prestige state.
- [ ] No added promotional text or AI images; final PNGs true RGB and 9:16 in verified Play-compatible resolutions.
- [ ] Raw captures, reproducible scenarios, sizes/provenance manifest, alt-text metadata and good-quality contact sheets retained.
- [ ] Approved icon, adaptive icons, feature graphic, trailer, audio and store copy unchanged by hashes.
- [ ] Toolkit lock and export allowlist validations pass; marketing assets excluded from Android content.
- [ ] Full maintained regression suite passes; docs reflect actual work; next chronological Change commit created; no push.
