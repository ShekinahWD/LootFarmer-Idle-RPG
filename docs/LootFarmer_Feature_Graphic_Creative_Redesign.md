# LootFarmer — Google Play Feature Graphic: Dedicated Creative Redesign

**Task type:** One focused Claude Code implementation batch, **FEATURE GRAPHIC ONLY**. The developer explicitly delegated competitive research, art direction, selection, and final execution to Claude. **Do not pause to request creative approval.** Deliver the improved file and evidence in this batch; do not merely propose designs.

**Product:** **LootFarmer: Idle RPG** (approved Google Play title). The game's differentiating mechanic is that enemies visibly carry lootable weapons and outfits. The player can obtain that equipment, equip it, and visually change their character's look. The graphic should convey that identity much more powerfully than a generic pixel-RPG collage.

**Potential later reuse:** The developer might make this artwork the **final branding shot of the 30-second portrait store trailer**, instead of the old plain icon/name-on-black ending. Design the feature graphic and its editable components so a future video task can recompose the branding into **9:16 portrait**. **Do not edit, render, replace, or re-export the video in this task.**

## 1. Scope and creative problem

### Only in scope

- Research live comparable game-store art and develop/choose an improved LootFarmer feature-graphic direction.
- Create and export the **finished Google Play feature graphic, 1024 × 500**, with a professional, recognizable composition.
- Preserve an **editable, reproducible source composition** using the real game's supplied art.
- Create a small, meaningful old/new comparison, selected concept/contact sheet, and readable-small-size checks.
- Document chosen visual direction, provenance, validation, and a future **portrait video end-card composition plan** without implementing the video.
- Commit only this task's appropriate source, finished graphic, reports, and supporting tooling, using the repository's **next chronological `Change N`**.

### Explicitly out of scope

- **Do not** modify the app icon, launcher/adaptive icons, screenshots, trailer, game UI, combat, progression, localization, save system, or Google Play listing text.
- **Do not** generate social videos or their copy. The screenshot/video revision and the icon redesign each have their **own future Claude chats and Markdown briefs**.
- Do not change or regenerate the existing AAB, Android signing/architectures, or release package as part of this graphic-only task.
- Do not update the reusable Game Development Playbook. We will assess the results before promoting validated methods to reusable rules.
- Do not use AI image generation, stock art, competitor art, new unlicensed artwork, or screenshots falsely presented as authentic game features.

## 2. Mandatory project review and starting state

1. Work **directly in the developer's CURRENT local Git repository**, not from the historical ZIP. Inspect `git status`, recent `Change N` commits, and any currently modified files first. **Do not overwrite other agents' or editor's pending changes.** If the last Change is 27, use Change 28; otherwise derive the actual next number from Git. Do not amend previous commits or push.
2. **Read this entire brief** and the current repository's `docs/Reusable_Game_Development_Playbook.md`, especially:
   - **§101:** Brand from the game's authored visual language: recognizable game-specific forms, legible wordmark, thumbnail-size verification.
   - **§87.9:** Feature graphics (unlike raw gameplay screenshots) may carry the game's brand name. Do not add a tagline/subtitle outside the already approved game title without approval.
   - **§74:** No double-dash punctuation in authored prose.
   - **§63.1:** Prefer developer-editable source composition and inspectable parameters.
   - **§133.1–133.4:** Composition/brand reuse, editable shot sources and validation; **no video creation in this batch**.
   - **§134–135:** Approved store brand identity, accurate claims, pinned toolkit/reuse and repository boundaries.
   - **§22.2:** Fail-closed Android export allowlist; marketing sources must not inflate builds.
3. Inspect the GDD, asset registry, the shipped asset catalog, outfit/weapon visual presentation, existing `store_assets/branding/` outputs/source files, the current rejected `branding/feature_graphic_1024x500.png`, and the available marketing toolkit. **Use actual repository filenames; don't invent asset or toolkit paths.** The approved Toolkit 1.0.2 is reusable infrastructure, but don't force a screenshot-oriented flow to do graphic design if an editor-editable Godot scene/layered composition is better.
4. Preserve the previous feature graphic and its original composition as comparison evidence, without unnecessarily tracking huge duplicates. Record the exact source paths/hashes in your report.

## 3. Competitive research: substantive, not a checkbox

Before choosing a direction, study **at least six actual relevant game listings**, preferably current Google Play listings in pixel-art RPG, loot RPG, idle RPG, equipment-collection, or character-customization categories. Use real accessible sources and **capture their feature-graphic presentation when available**, not merely their icons. If a comparable game has no feature graphic, explicitly record that rather than mislabeling screenshots or fabricated art.

Record each game's **title, store link, visual observations, and applicable lesson**. Compare:

- Composition hierarchy and focal point: hero, equipment, enemy, action, setting, brand title.
- Readability at realistic mobile/YouTube-preview scale, value contrast, shape distinction, and typography.
- Whether visuals communicate a recognizable mechanic and feel polished without busy UI or tiny sprites.
- How pixel-art competitors use layering, environment, contrast, scale, and silhouettes.

Do not copy their composition, typography, logo, art, effects, or slogans. Do not claim unverified rankings, ad performance, conversion rates, or keyword volume. Research informs quality, not imitation. **Claude has full creative decision authority after this research.**

## 4. Asset direction: express LootFarmer's actual identity

### The rejected design and what to avoid

The previous feature graphic uses a flat, mostly green grass field with a small white player, large Sunflower, two similar purple enemies and small scattered items. The existing yellow 'LootFarmer' wordmark dominates while the *stealing/equipping enemy loot* mechanic remains visually unclear. It reads like ordinary game-scene furniture, not differentiated store branding.

**Do not simply enlarge the same scene, rearrange its four characters, add a generic gradient, or cover it with text.** The design must be materially more expressive and polished.

### Mandatory visual goals

1. **Instantly legible product identity:** Make the player, a visually distinctive enemy/loot relationship, and the name **LootFarmer** identifiable at thumbnail size. Name spelling/capitalization must match the approved title. The registered descriptor **Idle RPG** may appear as part of that title if it improves the layout; don't invent a separate slogan.
2. **Equipment transformation is the hook:** Find a clever, clear **promotional composition using existing art** that suggests an enemy's recognizable weapon/outfit can become the player's look. Possibilities include an authentic *before/after equipped-appearance comparison*, foregrounded loot between enemy and player, or a strong hero equipped with a striking enemy-derived outfit and weapon alongside the source enemy. These are directions to evaluate, **not a mandated layout**. Be truthful about which item each enemy actually carries/drops, and use the game's actual equipped appearances, not an invented costume/weapon or mocked-up game mechanic.
3. **Stronger silhouette and composition:** Use intentional scale, depth/layers, separated foreground/background, focal contrast, and sufficient negative space. The important characters and item should not be tiny dots. Avoid UI clutter, multiple equally weighted enemies, generic badge piles, or tiny scattered loot icons that disappear at small size.
4. **Meaningful environmental identity:** Inventory the game's winter snow, autumn leaves, summer palette, spring rain and relevant enemy shapes. You may use a visually complementary blend of *authentic* seasonal art to suggest variety if it makes sense, but don't force four equal quadrants or produce incoherent scene geography. Aim for a strong coherent art direction rather than a uniform green backdrop.
5. **Professional pixel-art execution:** Respect source sprite proportions, nearest-neighbor/intended pixel scaling, crisp edges, clean outlined typography, controlled palette and contrast. Never smooth or distort pixel-art sprites. It is permissible to design a **marketing composition** from the game's authentic layers; it need not be a literal HUD screenshot. Don't represent composited promotional imagery as an actual gameplay screenshot.
6. **No unwanted marketing prose:** Avoid extra taglines, ASO keywords, generic three-fragment slogans, and any claims not supported by gameplay. Brand/title text only by default.
7. **Feature graphic and trailer-endcard compatibility:** Keep artwork, title, background, and effects on separately editable layers. Establish safe central/focal content so the artwork can later be **recomposed** into a portrait 1080×1920 end frame. Do **not** merely stretch/crop a 1024×500 landscape image into 9:16, which would lose the focal elements or make the name illegible. A layered, portrait-ready design is a desired property, not permission to regenerate the current trailer.

## 5. Design process: three genuine alternatives, Claude selects one

1. Create a **verified art inventory** (source paths and intended equipment/appearance relationships). Identify the strongest real player variants, outfit silhouettes, weapons, loot images, enemies, backgrounds and environment/seasonal elements. If a licensed item is not authorized for redistribution, don't use it; report the blocker and choose verified material.
2. Produce **three genuinely different feature-graphic concepts**, each with a one-paragraph thesis and quick 1024×500 composition preview. They must vary **how the equipment-transfer idea and brand are communicated**, not just their color hue.
3. Evaluate the previews against a small rubric: 30% distinct game/mechanic communication, 25% readability/focal hierarchy, 20% aesthetic polish and original compositional quality, 15% fidelity to real game art, 10% suitability for a later portrait trailer end card. These are **internal creative selection criteria**, not claims about Play Store conversion.
4. **Pick the strongest concept without consulting the developer**, refine it to a finished 1024×500 deliverable, then visually inspect it. If one concept scores well on theory but looks generic or unreadable, switch directions and improve it before declaring done. Don't deliver three rough ideas in place of one completed final asset.
5. Preserve the three preview concepts and final chosen editable composition for transparency and subsequent iteration. Keep images reasonably sized and use the repository's normal `store_assets` organization.

## 6. Concrete deliverables and technical quality gates

**Primary final output:** keep/replace the established repo path if it exists:

`store_assets/branding/feature_graphic_1024x500.png`

- Output a **real finished 1024 × 500 PNG**, suitable for the current Google Play feature-graphic slot (verify Google's current official requirements). Use sRGB and an **opaque** final background. Verify width/height, file size, alpha/transparency absence, display readability and the exact on-disk artifact.
- Save an **editable source file** in a suitable project-local branding source folder (Godot scene(s) and editor-visible resources, or a structured layer/manifest composition with source assets and positions). Preserve explicit paths/parameters for title placement, font/outline, sprite crops, sizes, color treatments, terrain/weather layers and export resolution. Provide a **single documented reproducible render command** or clear Godot editor procedure. Regeneration should not require manual Photoshop work.
- Provide `store_assets/branding/review/feature_graphic_concepts.png` (contact sheet), `store_assets/branding/review/feature_graphic_before_after.png` (rejected vs final), and small-size readability examples appropriate for a mobile store card and desktop/YouTube preview. Prefer contact sheets using the real generated files, not reconstructed mockups.
- Include a **portrait end-card adaptation note** with exact layers to keep/reposition, suggested title placement, portrait background treatment, safe margins and which elements should be animated/faded in a *future* trailer task. If practical, save a **static portrait framing preview** under `store_assets/branding/review/`; this preview is NOT the finished Play feature graphic and NOT a replacement trailer. Do not change any current MP4 or its storyboard/manifests.
- Keep the current **icon, 24 screenshots and trailer byte-for-byte unchanged**. Verify by comparing hashes when present. Do not repurpose their file paths or edit shared scripts in a way that changes existing captures.
- Keep graphic-only sources and review outputs out of Godot's imported runtime resources and out of the Change 26 positive export allowlist. Use existing `.gdignore` and repository ignore policy; don't include research downloads or captured competitor images in Android exports. Check with `python tools/export_manifest.py --check` when the existing tool is present.
- Run the complete maintained regression suite **once after the implementation** (`python tools/run_probes.py`) when the available development environment supports it, with targeted retries if needed. If visual/marketing-only changes require no gameplay tests, still preserve the established test gate rather than claiming a pass without running it.
- Write a **small scoped report** (chosen concept, researched links/observations, art provenance, before/after paths, editable source/command, technical checks, future end-card plan and limitations) to a suitable `docs/` Change report or branding notes file. **Do not modify the reusable Playbook.**
- Check Git scope and commit **only the feature-graphic work** using the next sequential `Change N: redesign Google Play feature graphic` (or analogous accurate wording). Stage deliberate files rather than `git add -A` if other agents are editing nearby resources. **Do not push**. If another concurrent change makes the worktree unsafe, isolate the owned files and explicitly report the limitation; never silently revert someone else's work. Do not force an Android/app version increment or AAB export for a graphic-only commit unless existing project checks truly require it (explain if so).

## 7. Acceptance criteria and required final report

All are required before claiming the feature graphic is done:

- [ ] Six or more real comparable store pages researched; only applicable visual lessons adopted, without borrowed art.
- [ ] Three meaningful distinct creative directions rendered for internal review, strongest refined and selected **without developer sign-off request**.
- [ ] Genuine improvement over previous green-collage graphic: clear focal point, player/loot/equipment mechanic, visual differentiation, and readable brand.
- [ ] One final **opaque 1024×500 PNG** generated, file inspected at full and reduced scale, dimensions/size validated and Play requirement reviewed.
- [ ] Editable layered, reproducible source and rendering instructions included; provenance of real gameplay assets noted.
- [ ] A future **portrait trailer end-card** can reuse the components without cropping or distorting the landscape graphic; adaptation note (and optional static framing preview) retained. **No video edited.**
- [ ] Old/new comparison and concept sheets available.
- [ ] Existing icons, screenshots, trailer, gameplay and release exports preserved; graphic-only files excluded from shipped runtime content.
- [ ] Existing full regression suite and relevant export manifest checks reported honestly.
- [ ] Scoped docs updated; correct `Change N` commit created automatically; commit hash and clean/remaining worktree changes reported; nothing pushed.

**Final Claude response must contain:** researched links and a concise analysis, all three concept-preview paths, the exact finished PNG path, the source composition path and reproduction command, old-vs-new comparison sheet, the chosen creative rationale, actual image-file validation, intended 9:16 end-card adaptation notes, confirmation that other media remained untouched, regression/export results, relevant license caveats, and the full Git commit hash and status. Show a visual preview of the final PNG and comparison sheet if your environment supports it; don't leave the developer with only a list of paths.
