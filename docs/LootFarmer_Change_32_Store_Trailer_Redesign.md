# LootFarmer: Idle RPG — Change 32: Google Play Trailer Redesign

**Status:** Approved creative direction; implement the finished trailer in one focused Claude Code chat.  
**Starting point:** The developer's **current local repository**, after Change 31 (`8a243195271b60bf0e6aadcfb5b19ba5292012d7`), subject to verifying the actual Git history and worktree.  
**Scope:** The **30-second Google Play portrait trailer only**. Reuse the approved feature graphic and icon, but do not redesign them or regenerate store screenshots.  
**Creative authority:** Claude may choose exact timing, short title-card wording, shot staging and technical execution within the approved narrative and acceptance criteria. No separate creative-approval checkpoint is required.

## 1. Read first and protect the baseline

1. Read **this entire brief** before touching any files, then read the **current repository** `docs/Reusable_Game_Development_Playbook.md`. Consult its relevant sections, particularly §74 (no double-dash punctuation in authored prose), §87 (authentic captured gameplay), §101 (approved branding workflows), §133.1–133.4 (video composition, audio, fades, shot orchestration), §135 (versioned Godot Marketing Capture Toolkit 1.0.2), §63.1 (developer-editable sources) and §22.2 (fail-closed Android allowlist).
2. Inspect `git status`, recent numbered commits, the current GDD, actual `data/game/catalog.json`, enemy abilities, item/equipment state and presentation, weather rules, stage scenes, the existing approved brand compositions, marketing source files and current trailer source/footage. Do **not** use an older ZIP as the project baseline.
3. Preserve unrelated edits and the approved **Change 29 feature graphic** and **Change 30 icon** exactly. Prefer to compute and record file hashes for the approved branding and existing screenshot set before/after. Do not replace, regenerate, or change them.
4. Treat the prior `LootFarmer_Play_Trailer_en-US.mp4` as a **rejected creative reference**. Its technical transition verification did not establish creative quality. Preserve an accessible before/after review, but do not reuse weak or monotonous footage merely to save work.
5. Confirm **Godot Marketing Capture Toolkit 1.0.2** is installed and pinned, using the repository lock/status and integration instructions. Reuse its validated Godot Movie Maker / FFmpeg workflow. Do not silently edit the installed generic toolkit or replace it with an ad hoc framework.
6. The game name is **LootFarmer: Idle RPG**. The main selling point is that the player can obtain **the weapons and outfits enemies actually carry**, equip those items and **visibly change their character's appearance**. Marketing must communicate this clearly and accurately.

## 2. Strict separation of scope

**Produce only:** the finished replacement Google Play trailer, its necessary game-specific scenario/shot/composition source, original video masters, music-only audio composition, review evidence, validation, trailer-specific documentation and one chronological local Git commit.

**Do not produce or modify:** store screenshot captures, feature graphic, icon/adaptive icons, social media videos or social descriptions, Play listing copy, localization catalogs, gameplay balance, actual loot probabilities, enemy behavior, gameplay UI or save contracts. Do not change Android version/code merely because marketing was revised. Do not update the Reusable Game Development Playbook in this task; the developer will decide which validated lessons to promote **after reviewing the actual trailer**.

This is a production task, **not another storyboard-proposal task**. Create the MP4, not just a plan, preview, manifest or instructions to the developer.

## 3. Locked deliverable and format

- **One** finished **30.00-second**, **1080×1920**, **9:16 portrait**, **30-fps** MP4 for the Google Play preview, in H.264 `yuv420p`, with an AAC music-only stream and web-appropriate fast-start layout.
- Genuine Godot portrait gameplay captured at a real portrait viewport. No fake gameplay, AI-generated visuals, misleading UI, non-existent loot transfers, rotated/cropped landscape footage or invented effects.
- **Three short black explanatory title cards**, placed before the relevant chapters, each with clear, natural wording and enough fully readable on-screen time. No formulaic three-fragment slogans, unrelated promotion, price/rank claims, or text floating over a fading-out gameplay shot.
- No Prestige footage. No final boss reveal. No social edits in this task.
- Close with the already-approved **feature-graphic art direction**, **recomposed as a true portrait title/end card** using its editable composition or approved portrait preview, with the complete **LootFarmer: Idle RPG** branding. Not an icon-only or generic text-only closing card. No resizing or stretching the horizontal 1024×500 file to masquerade as portrait composition.

### Approved editorial outline (timings are targets, not rigid cuts)

| Approx. location | Content and proof required |
|---|---|
| **0.0–1.5 s** | Short **black title card** introducing a powerful boss battle. Music starts immediately and stays continuous. Choose readable, natural text. |
| **1.5–6.5 s** | **Spring II Sunflower** summoner boss in genuine **rain**; capture the summon action as it happens, with helpers visibly arriving **during** the clip, and actual player skills. Show readable boss/player/action and contrasting enemy art. Sunflower is not the final Green Alien boss. |
| **6.5–8.0 s** | Black title card introducing taking and wearing enemy gear. Explain the mechanic naturally rather than presenting a vague slogan. |
| **8.0–17.0 s** | **Priority sequence:** the player encounters a distinctly dressed/armed enemy, defeats it, the enemy genuinely drops appropriate gear, the player collects that gear, equips it, and the **player's sprite/outfit and/or held weapon visibly changes**. The viewer must understand that the new appearance comes from that enemy. This gets the **longest coherent screen sequence**. Hold the changed look clearly after equipping. |
| **17.0–20.0 s** | One **real duplicate-item merge** with a readable before/after improvement. Prefer one intentional panel interaction and a hold, not rapidly switching menus or mismatched item views. |
| **20.0–21.5 s** | Black title card introducing farming in different seasons. |
| **21.5–26.5 s** | Short **seasonal farming chapter** with genuinely different enemies, the game's **Autumn II falling leaves**, and a visibly different **winter/snow** setting. Show useful loot/combat/skills and **different player outfits and weapons**, not the same hero sprite and background repeated. A Grim Reaper encounter and actual helpers may be used where it helps, but this is not a required second boss shot. |
| **26.5–30.0 s** | Professionally composed portrait **feature-graphic-based end card** with **LootFarmer: Idle RPG** readable. Music continues and finishes with a natural fade. |

**Editorial authority:** Adjust tenths of seconds or shorten a redundant combat angle to ensure readable cards and a genuinely comprehensible gear transformation while retaining the ~30-second total and chapter order. Do **not** solve timing pressure by making the gear sequence too fast or replacing it with unrelated screenshots. A six-second equipment demonstration that is incomprehensible is not an acceptable substitute for the approved main feature.

**Storytelling requirement:** A new viewer should grasp (a) enemies have visibly desirable gear, (b) defeating them can grant that gear, and (c) equipping it visibly changes the playable character. This must be apparent from the **actual moving footage**, not solely asserted by text.

## 4. Absolutely music only: the supplied in-game track

The developer **explicitly selected the existing game background music**, not an alternative from Pixabay. **Do not source, purchase, generate or substitute other music**, and do not request further music selection.

- Use the track at `assets/sounds/background_music.wav` **if its bytes match the source provided by the developer**. For provenance, the attached `background_music.wav` in the original handoff has **SHA-256 `b3664d04791bb86f220b790823dab34ec6912ba93a1a60cf035e82b557b45778`**; this also matched the same path in the developer's earlier project ZIP. Verify the file in the **current** repository. If it differs, identify why before choosing a source; use the explicitly supplied audio attachment as authority if one accompanies this task.
- The source track is approximately **132.41 s**, stereo **44.1 kHz, 16-bit WAV**. Extract one **continuous musically appropriate 30-second portion** or edit its intro/end to fit the storyboard; do not restart the music at cuts or loop short segments awkwardly. Choose the musical entrance and beat/pulse alignment autonomously. Use modest gain/fade as needed; no additional audio.
- **Exclude gameplay audio tracks at source**, not by reducing their volume. Godot captured AVI may contain PCM game sounds: explicitly discard them before FFmpeg composition (e.g., video-only input mapping). The final mix must use **only this WAV-derived music stream**. No hits, pickups, skills, coins, menu clicks, footsteps, ambient weather, voices, sound effects, notification chimes or sound logos.
- No speech, AI-generated music, Pixabay replacement track or separate intro sting.
- Verify the actual rendered MP4 by examining the audio routing/filter graph, audio stream count, continuous waveform and sampled listening points around boss battle, gear/equip, merge, black cards and ending. Confirm the final is music-only, without clips' PCM inadvertently mixed in. Avoid clipping, silences at transitions, abrupt start/stop or sudden volume jumps.
- **Licensing:** the music's presence in the repository is not proof of commercial promotion/YouTube rights. Record the available license evidence or the precise unresolved release gate. Still produce the local review video using the developer-selected track; do **not** claim distribution/YouTube clearance or upload anywhere before rights are verified. Do not automatically replace the music if evidence is missing.

## 5. Exact authentic gameplay requirements

### Summoner boss, Spring II

- Verify the **actual Sunflower boss identifier, stage, and summoning behavior** in the current catalog and ability data. Stage a legal encounter and start recording before the real summon. Capture **summon → helpers visibly join → player uses skill** within the shot.
- Use the actual Spring II rainy weather system, not a composited rainfall overlay. Keep the boss and summoned enemies large enough to distinguish at phone playback size.
- **Never showcase the final Green Alien boss**; no final mission spoilers.

### Enemy gear → loot → equip → visible appearance

- Pick a verified enemy, actual weapon/outfit from its own carried loot table, and a **visually dramatic before/after player appearance**. Choose the strongest real example; do not prescribe a particular costume if another will film better.
- Use legitimate deterministic marketing fixtures or seeds to reach a scenario in which the real game drops and acquires the intended loot. Capture the real death, loot spawning, pickup, inventory/equip action and resulting animated player state. A shortened but **chronologically truthful edit** is allowed; a false before/after from different item/enemy identities is not.
- Show **the enemy wearing/carrying the item before defeat**, the item from **that enemy**, and the player's visible **equipped appearance afterward**. If the enemy only dropped one of outfit or weapon, don't imply it dropped both. Include item/enemy IDs in the scenario manifest and report.
- Keep the camera on the changing character long enough to register the outfit/weapon change. Avoid having the new character obscured by menus, particles, fog or camera jumps.
- Do not create a fake equip animation or paint a new costume over gameplay. If a necessary beat is not captured, **recapture that beat** rather than substituting a misleading edit.

### Merge, seasons and equipment variety

- One clearly visible **real merge**, with matching duplicates and a confirmed improved item level/stat. Allow viewers to actually read the UI before and after. Do not record multiple frantic tab/panel transitions.
- Across the film, show **at least three genuinely different seasonal visual treatments**: rainy Spring II, Autumn II falling leaves, and winter snow/blue falling leaves. Weather must be visible in actual recorded frames, not just present in stage metadata.
- Use **different enemy families/colors, visible outfits and weapons** between fights. Avoid the previous repetitive environment/weapon problem. Record those identities per shot; compare a contact sheet **at small scale** to catch accidental visual sameness.
- The final shots should show an actual idle/automatic farming rhythm and visible loot, not only boss combat or full-screen menus.

## 6. Black cards, fades, branding and video quality

- Reuse the Playbook §133 validated transition method: gameplay fades **out to genuine black**, readable text appears **on black**, fades out before the next scene, and the next gameplay scene fades in. Do not create abrupt one-frame swaps, hard-black glitches, or words prematurely superimposed on gameplay. A deliberate hard cut is allowed only where editorially appropriate between **gameplay clips**, not as a fake black-card fade.
- Use one natural short explanatory statement per card, not repeated formulaic three-clause catchphrases or a list of isolated imperatives. There should be **no double-dash punctuation** in the authored marketing copy.
- **Actual text-hold time** must be readable after accounting for fade-in/out, not just counted from the segment's overall duration. Tighten card copy, not reading duration. If needed, trade less-important combat footage for readability.
- Keep portrait UI/action unobstructed and safe for a small Google Play/YouTube thumbnail. Test at actual mobile preview dimensions.
- Use the **approved feature graphic composition**, including the full **IDLE RPG** subtitle, to build the portrait end card. The reference landscape graphic and icon are already approved and must remain unchanged. Avoid cheap stretching, crude cropping, tiny text, illegible art, or a title sitting behind a play overlay when used as a preview.
- Check the last 3.5 seconds independently: the end card should look as professionally composed as the approved feature graphic, not a quick black frame with a pasted logo.
- Capture natural game presentation and appropriate pixel-art scaling. No generated image or synthetic gameplay frames.

## 7. Reproducible generation, evidence and review

- Build from game-specific **reusable scenario and shot configs**, using the already pinned Marketing Capture Toolkit 1.0.2. Existing scenario adapters may be reused where valid; fix them at the game adapter layer when their outcome fails the approved requirements.
- Use real scene, item, weapon, outfit, enemy and ability state, not a hand-painted combat montage. Maintain **isolated marketing/test saves**. Protect the developer's ordinary profile from reset/Prestige/test captures; never write capture-only cheats or UI into the packaged game.
- Keep recording masters, exact frame/cut timestamps, title-card copy, source WAV selection and music in-point, FFmpeg composition parameters, layer/shot manifest, deterministic seed/fixture state and gameplay-proof checks so the video can be recut for the future social video task **without recapturing everything**.
- Generated large AVI/intermediate MP4s may remain local and ignored by Git under clearly identified project paths; **do not delete them at completion**. Commit only the appropriate manageable source, configs, scripts, README and evidence according to repo policy. Ensure the final MP4 itself remains in the project and is easy to locate.
- Include a **shot-by-shot contact sheet** (beginning/middle/end frames), **black-card full-hold frames**, a **small-size sequence strip**, a **transition frame sheet**, and **old-versus-new** representative comparison. Do not pass quality based solely on a JSON report with green flags.
- Provide a timeline/evidence matrix pointing to actual video timestamps and source footage for: boss summon, active rain, an ability, enemy item being carried, death, actual drop, pickup, equip, before/after look, successful merge, autumn leaves, winter scene, distinctly different weapon/outfit, and final approved branding.
- Check the feature-to-shot evidence at both full frame and realistic phone preview scale. Any missing core feature means recapture/recompose and check again **within this batch**, not defer the principal improvement to another task.

## 8. Validation and delivery

Perform implementation as **one coherent batch**, then run the complete maintained regression suite **once at the end**. If something fails, use focused diagnostics, correct it, then rerun the complete suite for the final acceptance check; do not repeatedly run the entire suite for every little edit.

1. Confirm **MP4 file exists** and `ffprobe` reports exactly **1080×1920**, **30 fps**, **30.00 s**, H.264 `yuv420p`, AAC, correct rotation and audio streams; no unintended black bars or stretched video.
2. Decode actual frames to validate real title-card black levels, hold lengths, fades, meaningful source/action start/end, cross-shot continuity, no abrupt image jumps disguised as transitions, no broken or missing content, legible title, and correct portrait end card.
3. Confirm **music-only final output** by FFmpeg graph/source selection and output listening analysis. Explicitly report how captured gameplay audio was excluded. The MP4 should have one intended music stream, no gameplay audio mixed in.
4. Confirm every visual feature contract using a timestamp + frame or deterministic-state proof. In particular **actual equipment transformation** and **real Sunflower summoning** are mandatory acceptance gates.
5. Check screenshots, approved icon, approved feature graphic, gameplay and source content hashes did not change. Keep the **Change 26 positive allowlist** closed; marketing-only adapters/footage/MP4/review artwork must not enter an AAB/APK. Run the export manifest/check and any relevant media package checks, without unnecessarily creating a new signed release AAB unless a concrete source/dependency change requires it.
6. Run `python tools/run_probes.py` or the current project-documented equivalent to completion. Report totals and exceptions truthfully.
7. Update **game-specific** marketing documentation, shot manifest, reuse instructions and a concise **Change 32 report** with source paths, actual music hash, scene/item identifiers, timecodes, validations, licensing caveat and remaining review tasks. Do not update the shared Playbook yet.
8. Determine the next chronological **Change N** from Git (expected Change **32** after the committed Change 31 baseline). Automatically commit source, configs, scripts and appropriate documentation/evidence, protecting approved assets and unrelated work. **Do not push, upload to YouTube/Play, publish, or ask the developer to run the generation.**

### Non-negotiable acceptance checklist

- [ ] Trailer finished and locally viewable: **30 s portrait 1080×1920**, full title at end.
- [ ] **Only `assets/sounds/background_music.wav`** in final audio mix; no game/UI/combat/weather/notification audio, no third-party replacement.
- [ ] Three **readable black explanatory cards** before the associated chapters, with verified fades and no generic three-part slogans.
- [ ] Real **Spring II Sunflower summon**, rainy boss combat and player skills; no final boss.
- [ ] Clear **same-enemy loot acquisition → equip → actual on-screen character appearance change**, the most prominent coherent sequence.
- [ ] One legible successful merge; no Prestige screens or rapid panel flicker.
- [ ] Rain, Autumn falling leaves and Winter scenery, multiple enemy palettes and **different equipped outfits/weapons**.
- [ ] End card derived from **approved feature graphic**, portrait-recomposed and showing **LootFarmer: Idle RPG**.
- [ ] Editable sources, original footage, review sheets, feature-to-timestamp evidence and reproducible commands retained.
- [ ] Existing icon, feature graphic, screenshots and gameplay remain unchanged; no marketing files leak into Android export.
- [ ] Final media validations and full maintained regression suite pass; documentation updated; auto-commit complete; no push or upload.

### Claude's final response

Provide the **relative path of the finished MP4**, an accessible playable preview if the environment supports it, review-sheet paths, actual WAV path/SHA, exact timeline and title-card copy, Sunflower summon proof, the enemy/gear IDs and visual transformation timestamps, merge proof, three-season/equipment-variation evidence, media validation metrics, suite totals, any music-rights limitation, preserved master/config paths, updated docs, Git commit message/hash and clean-worktree status. Report deficiencies candidly; don't declare success because an automated probe says the video file is valid.
