# LootFarmer: Idle RPG | Dedicated Google Play & Android App Icon Redesign

**Execution:** One focused Claude Code implementation task in a fresh chat. **Icon work only.** The developer has delegated the investigation, artistic decisions, concept selection, production, and final execution to Claude. **Do not request a concept choice or further creative approval. Produce the finished assets in this batch.**

**Approved product name:** **LootFarmer: Idle RPG**. The game is a portrait Android idle RPG. Its differentiating gameplay is defeating enemies, obtaining the weapons and outfits they carry, and visually changing the player's appearance by equipping the loot. The English store identity and recently approved feature graphic already exist; preserve both.

## 1. Objective and creative authority

The current app icon was rejected as too ordinary. Produce a **distinctive, appealing, immediately recognizable icon** grounded in the real game's visual identity, following the **successful independent-research and concept-exploration workflow used for the approved feature graphic**.

**Claude owns the creative decisions.** Do not prescribe or request input on a specific character, enemy, weapon, loot item, color palette, setting, icon layout, visual motif, text/no-text choice, or composition. Research the current market, study the game's real artwork and gameplay, experiment with genuinely different treatments, and independently select and execute the strongest direction. The outcome must be better than the existing icon, not merely technically compliant. Distinguish visual-quality judgments from unverified claims about actual conversion rates.

The attached brief defines **workflow, truthfulness, artifact specifications, project safety, and acceptance checks**, not the picture Claude must draw.

## 2. Scope boundaries

### In scope

- Investigate the game's current icon/launcher implementations, art inventory, and approved feature graphic, including the final **LootFarmer / Idle RPG** branding correction.
- Research comparable currently listed games for **icon-specific** creative lessons, with traceable sources and observed imagery wherever obtainable.
- Explore **at least three meaningfully different internal icon concepts**, compare them at realistic launcher/store sizes, independently choose one, and refine it to production quality.
- Generate the finished **Google Play 512 x 512 app icon** and its **Android launcher/adaptive icon** variants as appropriate for the existing Godot Android export setup.
- Integrate the new icon outputs into the actual project's configuration and icon resource references so they are used by subsequent Android exports; keep the final Google Play marketing PNG available separately.
- Preserve **reproducible, editable source composition**, comparison sheets and concise research/validation/provenance evidence.
- Update *game-specific* icon documentation, run verification, and commit the scoped changes using the repository's next **chronological Change N**.

### Out of scope

- Do not redesign or modify the **approved feature graphic** or its portrait trailer end-card preview. The icon should fit the same game identity, but need not reproduce the feature graphic or copy its arrangement.
- Do not edit or regenerate store screenshots, the Play Store trailer, raw footage, social videos, advertising copy, descriptions, localizations, or their source configurations.
- Do not modify gameplay, enemy balance, player progression, UI, equipment, art packs, audio, save schemas, pricing, package identity, signing keys, permissions, Android SDK levels or unrelated export settings.
- Do not update `Reusable_Game_Development_Playbook.md` in this icon batch. The developer will decide later what icon-specific lessons to promote after reviewing the result.
- No uploads, Play Console changes, pushes, social publication, or screenshots/video production.

## 3. Source-of-truth review before implementation

1. Work **directly in the current local Git repository**, not an old uploaded ZIP. Inspect `git status`, recent `Change N` commits and the latest approved feature-graphic revision. Never reset, revert, discard or overwrite work belonging to another agent or the developer. Assign the next commit number from **actual Git history**, not an assumed Change 28/29.
2. Read this entire brief and the current repository's Playbook, especially **§101** (icon identity originates in the game's authentic art and remains legible at thumbnail size), **§22.2** (verified positive-list export integrity), **§63.1** (editability), **§74** (no double-dash punctuation), relevant Android/export and store-launcher requirements, and **§135** (toolkit/source control). Review the current GDD, asset registry, equipment/appearance presentation, current catalog and existing marketing icon resources. Do not rely on historic placeholder paths when the actual repository differs.
3. Review the **approved feature graphic** for a coherent overall brand relationship. Its composition is approved; do not modify it to make icon work easier. Treat it as an identity reference, **not** a template the icon must imitate.
4. Confirm ownership/licensing/provenance of art before reuse. **All illustrated source content must come from existing authorized game assets.** Composition, crops, native geometries, backgrounds, text treatment, scale and programmatic effects are permitted when they do not invent false gameplay artwork. **No generative-AI images, stock icons, traced competitor imagery, unauthorized third-party assets, or fabricated game features.** If a source license cannot be verified, use verified alternatives and report the open record; do not silently claim rights.
5. Verify current Google Play and Android icon requirements from official documentation at execution time:
   - Google Play preview assets: `https://support.google.com/googleplay/android-developer/answer/9866151?hl=en`.
   - Android adaptive icon design: `https://developer.android.com/develop/ui/compose/system/icon_design_adaptive`.
   - Inspect the exact Godot version/export pipeline and current project's icon settings before changing references.

## 4. Research-first creative workflow: Claude decides

1. Research **at least six genuinely relevant current game icons** spanning pixel-art RPGs, idle/action RPGs, loot collection/equipment or visually distinctive independent games. Record **store title, official URL, date checked and observed icon features**. Verify that references are actual icons, not feature graphics or imagined store images. If direct images are blocked, distinguish source-reported facts from inferred observations; find accessible replacements.
2. Analyze visual hierarchy, distinctiveness, silhouette, size legibility, focal simplicity, contrast, icon-mask behavior, stylistic consistency, and what distinguishes recognizably successful-looking artwork from generic source sprites. **Do not claim ranking or conversion performance unless verified.** Draw original lessons, never copy protected art, symbols, logos or layout.
3. Inspect the actual source assets and current in-game appearance rules. Identify available authentic motifs that could support an icon; **do not commit to any particular motif because the brief mentioned it**.
4. Produce **at least three visibly different icon concepts**, each with its own editable composition parameters and a small labeled concept-review image. They must differ in substantive visual idea, not simply in color/background/text.
5. Independently judge these at **512 px, about 96 px and about 48 px** (and real mask previews), choose the strongest, then iterate until it reads well on light and dark launcher/store surroundings. Record a concise rationale for the selection and why the previous icon was weaker. These are creative quality checks, not a formula that mandates a particular layout.
6. Do not stop at concepts or ask the developer to pick. Deliver the final polished icon and integrated variants now. Do not treat passing dimensions as proof of artistic success. The initial redesign should be genuinely stronger than the rejected icon.

## 5. Generate and integrate final outputs

### Play Store app icon

- Create a finished **512 x 512 PNG, 32-bit with alpha, maximum 1024 KB**, following the current official Play icon design requirements. Verify the final encoded PNG, not only the intermediate source.
- Use the project's existing established file path if one exists, or choose a clear path inside `store_assets/branding/` or equivalent and document the exact destination. Preserve old/new comparison evidence without leaving the obsolete image configured as the live icon.
- Do not accidentally apply an additional launcher-style mask or baked corner radius to the Play icon; verify how Google Play supplies masking/shadows per its current guidelines.

### Android launcher and adaptive icons

- Determine the current Godot Android icon configuration and export preset capabilities, then prepare the appropriate **foreground, background, and monochrome** sources, plus required conventional/legacy icon fallbacks for the project's supported Android versions.
- Use the *actual* Android adaptive icon safe-area/mask guidelines. Validate important shapes and foreground details under multiple masks (at minimum circle and squircle/rounded-square), light/dark surfaces and themed monochrome appearance. Do not allow the artwork to become clipped, illegible or off-center.
- Integrate the icon paths into **project configuration/export preset** only as necessary. Avoid changing unrelated export settings or application identity. Verify resource inclusion with the Change 26 fail-closed manifest/export setup; update its approved icon roots only if needed for the new resources and report those updates explicitly.
- If building a test APK/AAB is needed to verify the final launcher settings, use the existing safe local build process, inspect the exported artifact, and **do not publish or deliver a release upload as a side effect**. Do not expose credentials. Do not assume a new AAB exists unless one was actually produced and verified.

### Reproducible creative source

- Preserve the editable composition in an existing project-appropriate authoring format, such as a Godot scene/resource setup, structured layer-and-render configuration or equivalent inspectable design source. Keep positions, original sprite sources, treatments and output sizes adjustable without redrawing the image manually.
- Provide a reproducible render command or exact editor operation. Store the useful concept previews and **old versus new** contact sheet in an excluded marketing/review location. Do not commit large speculative research image downloads or redundant intermediate renders merely to fill out a report.
- Keep marketing-only design sources/review composites out of the Android runtime export; include only the icon resources the runtime/export pipeline truly needs. Do not delete purchased source assets.

## 6. Verification and Git discipline

1. **Visually review actual output** at full size, 96 px, 48 px, and with adaptive masks, on both light/dark backgrounds. Inspect for aliasing, blur, off-center placement, cramped edges, excessive visual noise, clipping or recognizable icon-size failures. Iterate if necessary.
2. Validate PNG file signature, exact dimensions, format/alpha/file size, referenced assets, configured icon paths, compatibility with adaptive variants, and finished file existence. Use official current guidance for any newer platform requirements.
3. Check the actual export manifest / positive allowlist integrity (`python tools/export_manifest.py --check`, if present). Run the maintained full project suite **once at the end** (`python tools/run_probes.py`), with targeted failure correction and final rerun only if needed. Do not claim unexecuted validation passed.
4. Confirm the approved feature graphic, screenshots and trailers are unchanged (compare Git diffs/hashes where relevant). No game feature, save or gameplay balance change is authorized.
5. Write a concise, **game-specific** report covering verified research sources, the three concepts, the selected reasoning, authentic asset provenance, editable source/render command, screenshot/comparison paths, Android mask tests, technical checks, unresolved licensing/technical caveats and commit details. Avoid changing the reusable Playbook.
6. Stage only intended icon/source/config/docs/test files. Commit automatically with the **next chronological Change N**, e.g. `Change N: redesign Google Play and Android app icon`. Do not amend other work, do not push. **Do not automatically increment gameplay/app version solely for marketing art** unless required by a current release/tool validation contract; document any such necessity. If concurrent work prevents a safe commit, never overwrite it: report and isolate the work honestly.

## 7. Completion acceptance

- [ ] Research into at least six real, relevant competing/reference game icons, with links and specific lessons.
- [ ] At least three substantively different internally rendered concepts, with a transparent independent selection.
- [ ] Final Play icon created and visually inspected at actual thumbnail sizes, with current Play PNG specifications verified.
- [ ] Android foreground/background/monochrome and legacy representations generated where supported/needed, inspected against masks, and integrated into the actual build configuration.
- [ ] Approved feature graphic, existing screenshots, and all video assets preserved byte-for-byte; no game code/balance/content changes.
- [ ] Source composition editable and render reproducible, with original-art provenance.
- [ ] Existing positive export allowlist and full maintained test suite checked; any actual export artifact validated if one is generated.
- [ ] Game-specific report and old/new + concept review sheets delivered.
- [ ] Correct scoped Git commit created, hash supplied, no push.

**Final response:** Present the selected final icon (and contact-sheet preview where possible), exact file paths, three concept paths, real researched sources, selection rationale, Android mask previews, reproduction command, actual verification results, unchanged-media confirmation, and full Git commit hash. **Do not ask the developer to choose a design or postpone the actual deliverable.**
