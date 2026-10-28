# LootFarmer — Change 26: Android Export & Asset Cleanup

**Task type:** Implement a single complete, controlled packaging/asset-import cleanup in **Claude's current local Git repository**; verify the real resulting export where tooling permits; update project docs; **commit autonomously**. This is **not** the demo build, localization, store-art generation, performance rewrite, or publishing pass.

**Expected baseline:** Change 25 (`0a005302d77d723c43f2a1603bd561bdda6501a7`), project version and Android Release code 25, Godot 4.7.x, save file version 3; the maintained suite passed **33/33**. **First inspect the actual HEAD, worktree, export presets, asset tree, current reports, and Git history.** If anything differs, respect the live repo and choose the next sequential Change number accordingly. Expected delivery is **Change 26**, versions **26**; do not alter the Bootstrap/utility preset just to align numbering.

## 1. Authoritative reading and decisions

Read current repository versions of:

- `docs/Reusable_Game_Development_Playbook.md`: especially **§0.9.1** (Stage 16 demo allowlist, *future* work), **§22.2** (ship only used assets), **§60.1** (batch regression), **§61.1** (development saves), **§135.4** (source/ignored generated files and secrets), and the relevant Android export/asset/import rules.
- `docs/LootFarmer_Full_Production_Audit_Report.md`: **REL-05, REL-06, AST-04, AST-05**, the assets section, and packaging plan Batch G.
- `docs/LootFarmer_Asset_Registry.md`, `docs/LootFarmer_GDD.md`, `docs/LootFarmer_State_Contracts.md`, `docs/LootFarmer_Test_Suite.md`, `docs/LootFarmer_Design_README.md`, `docs/LootFarmer_Change_24_Performance_Report.md`, and `docs/LootFarmer_Change_25_Report.md`.
- Current `project.godot`, `export_presets.cfg`, `.gitignore`, stage/scene/resource references, `data/game/catalog.json`, dynamically generated art paths, localization/theme/font paths, audio paths, runtime `load`/`preload` use, and the actual Android build/export configuration.

**Developer decisions:** Perform **all related export/import cleanup in one change**, minimize costly repeated test runs, **run the full maintained regression suite at the end**, do **not** require Android profilers or extensive phone work, do **not** preserve obsolete development-save compatibility (Playbook §61.1), **commit locally without asking** and **do not push**. Prevent functional or appearance changes. Build as little custom tooling as needed for reliable, reproducible verification.

## 2. Implementation scope (all required)

### E01 — Dependency-verified full-game export allowlist (audit REL-06)

**Problem:** The audit found `export_filter="all_resources"` and inclusion of many unneeded Pixel Plains variants, Kenney sources, animation-pack extras, and unreferenced folders. The actual shipped bytes must shrink **without breaking dynamic resource loading**.

1. Inventory the current full game's **actual runtime dependencies**, starting from the project's active entry scenes, required autoloads and all eight stages, plus catalog/data-driven resources, shared UI/styles/fonts, skill VFX, music/audio, icon(s), legal metadata as appropriate, and any files loaded through paths assembled at runtime. Inspect `load`/`preload`, `ResourceLoader`, scene `ext_resource` and UIDs, resource scripts, JSON and `.tres` references. A textual `res://` grep **alone is not sufficient**.
2. Specifically account for `game_ui.gd`'s dynamically constructed `Item-%d.png` style lookups, `catalog.icon`, mastery art indices, actor/equipment variants, skill/action animation sheets, stage map/weather/fog resources and all enemy/boss references. Consider resources that are only used after late-game progression, prestige, special effects, alternate outfits, settings or tutorial modes.
3. Establish a **maintainable, reproducible, positive manifest/allowlist or appropriate Godot export filter with a reviewed explicit inclusion set**. It must be regenerated or validated from authoritative dependencies when code/data changes, not a manually guessed one-off blocklist. The full paid game must continue to include **all eight stages and all current content**, even where a player has not unlocked it. Source packs and their provenance must remain available in the repository; **do not delete purchased original assets** simply because they are not packed.
4. Exclude only provably unused or retired packs/variants. The audit named unused candidates `Zombies Free ver`, `PP Pumpkins Set Free`, `LootFarmer-seasonal-animation-sheets`, unused Pixel Plains item-outline variants, unused animation-pack and Kenney sources. **Reconfirm with the live Change 25 code** before excluding; historic counts are not proof of present use. Apply `.gdignore` only to truly reference-only/import-unneeded directories, not to a parent of needed assets. When `.gdignore` conflicts with needed sources, use export exclusions instead.
5. Prefer existing Godot export facilities over a brittle new packaging framework, but provide a reproducible check that can answer **what is included and why**. Store allowlist/manifests, validation script and short instructions in `tools/`/`docs/`, never as runtime content or developer-only UI.
6. Treat missing dependencies, unaccounted dynamically constructed paths, and unexpected exported content as **validation failures**, not warnings that can be ignored. Fail closed; do not hide missing content behind fallbacks or change visual assets to make the export pass.

**Acceptance:** all required scenes, enemy/item visuals and dynamic resource paths resolve; package inventory shows unneeded content absent and all needed content present; a release-like export is measurably smaller or an evidence-based explanation is provided if an asset group cannot safely be excluded.

### E02 — Android ABI/export preset cleanup (audit REL-05)

1. Inspect the **actual Godot 4.7 export preset schema**, current custom Android build behavior, and actual package ABI contents first. The audit observed `arm64-v8a`, `armeabi-v7a`, `x86`, `x86_64` even though the `architectures/*` fields were false. Do **not** blindly toggle flags and assume the exporter honored them.
2. Configure only the intended phone architectures: **`arm64-v8a` required; `armeabi-v7a` optional if the project actively supports 32-bit Android**. Default to keeping both ARM ABIs if no reason to drop 32-bit support; exclude x86 and x86_64 for the phone release where the toolchain genuinely supports it.
3. If an engine/custom build/export-template limitation causes x86 artifacts despite correct settings, investigate and report the underlying reason. Avoid replacing signed tools, changing keystores, manually rewriting generated Gradle sources, or stripping libraries with an unsafe post-build hack. Distinguish settings intention from **verified actual exported ABIs**.
4. Preserve application id, Android permissions, min/target SDK policy, render configuration, orientation, signing paths and other unrelated release metadata. Keep secret materials out of Git. Change only relevant Release preset fields; do not alter the Bootstrap/utility export preset unnecessarily.

**Acceptance:** archive contents prove only intended ABI directories are shipped, or clearly record an unresolved toolchain constraint without claiming success. Correctness of all exported ARM native libraries matters more than small bundle-size gains.

### E03 — Godot documentation/import hygiene (audit AST-04 / AST-05)

1. Prevent historical evidence screenshots under older `docs/Change_10..16_Evidence/ui/` (and any equivalent reference-only folders) from being imported as game assets. Use appropriate `.gdignore` boundaries; **retain source screenshots and historical documentation**.
2. Stop `docs/LootFarmer_Enemy_Roster.csv` being treated as a Godot translation catalog. Prefer `.gdignore` for documentation scope if it is safe; rename to `.tsv` **only if necessary**, and update all references if renamed. Do not accidentally exclude actual runtime translations (`localization/en.po`) or test/capture scenes relied upon by maintained tools.
3. Remove only clearly generated/now-obsolete `.import` or `.translation` files with proper Git tracking hygiene. Do not delete authored evidence or any user-authored references. If files are tracked, explicitly check them before removing; `.gitignore` alone does not untrack files.
4. Inspect `.gitignore` for cache, export, temporary build and key protection; add only justified exclusions. Preserve source assets, project files, installed marketing toolkit/addons, and required license records. Do not use global wildcards that hide legitimate assets.

**Acceptance:** the Godot import pass is clean, docs are not turned into translation files/import artifacts, and docs/source evidence remain intact.

### E04 — Real exported artifact verification (mandatory for claiming packaging success)

1. Establish the **before** package baseline from a real existing prior export **only when comparable** (same type/configuration and the old file genuinely exists). Record archive byte size, major packaged asset categories and ABI entries. Do not invent precise size savings if no valid baseline is available.
2. After implementation, perform a clean headless Godot import/load and **export a non-published Android verification artifact** using the installed SDK/templates and safe local signing configuration. Prefer the current legitimate release-like export settings; use an isolated non-production debug/unsigned route when production signing is unavailable. **Do not invent or expose keystore credentials.** Do not publish/upload or install a package without explicit instruction.
3. Inspect the **actual built APK/AAB/PCK**, not only `res://` source folders or a pretend export manifest. Check archive contents and, if Godot content is embedded within an asset pack or imported-resource mapping, inspect it using a compatible documented method. Distinguish source paths, imported resources and engine/Android files; don't assume a ZIP listing alone reveals internal Godot paths.
4. Validate that: expected runtime files and **all eight stages** are included; actual shipped dependencies resolve; excluded source variants/retired packs are absent; no unexpected tests, docs, marketing captures, reference-only packs, private keys, credentials, dev saves or project Git data are included; expected ARM ABIs are present and undesired ABIs absent if supported.
5. Add a lightweight **reusable packaging validation script/check** (non-gating if Android toolchain isn't present). It should compare artifact contents to the reviewed allowlist and report missing/unexpected paths, including dynamically reachable resources, rather than merely asserting a folder size. Keep only **small, useful textual evidence** (lists, hashes, deltas, tool versions) in the final report. Do not commit generated APK/AAB/PCK files, caches or huge file dumps unless the repo explicitly tracks such artifacts by design.
6. If Android export is blocked by a missing SDK, template, credentials or tool limitation, **do not claim that the exported artifact was verified**. Still finish safe source changes and headless dependency checks, give the exact blocker and reproduction command; clearly identify which packaging criteria remain unverified.

**Acceptance:** an actual archive inventory and source dependency audit, with verified inclusion and exclusion results; exact build command/configuration and limitations documented.

### E05 — Future demo generation foundation, not the demo itself

- Preserve a **positive, dependency-checked manifest model** that a later Stage 16 generator can reuse with filtered data rows and roots for Winter I + II, while the paid game's manifest continues to include everything needed for **all eight stages**.
- Record dynamic resource families and any general-purpose runtime dependencies that the future demo builder must handle. Make scope filtering possible **without modifying paid-game combat/economy rules**.
- **Do not** create the separate demo project, its APK/AAB, demo save, purchase invitation, stripped catalog, package id, store listing or store assets in Change 26. These belong to later, separately approved work.

### E06 — Version, docs and autonomous Git commit

- Determine the next Change number from **current Git history** (expected **26**). Update `project.godot` application `config/version` and Android **Release** `version/code` to the same integer. Retain inherited/blank `version/name` and independent Bootstrap preset policy unless the current repo says otherwise. **No save-schema/version bump** merely for an export/import-only correction.
- Update the Asset Registry with source-vs-export inclusion policies and verified asset groups; the GDD/State Contracts only where the actual product contract changed; Test Suite with new packaging check commands/results; Design README and a new `docs/LootFarmer_Change_26_Report.md` with actual package evidence, pending constraints and a before/after comparison if defensible. Annotate the original audit findings as fixed/partial/blocked in an addendum; keep the historical audit body and past evidence immutable.
- Add a short **reusable, validated principle** to the correct existing Playbook section(s) **only if Change 26 establishes a new generalizable technique**; don't duplicate existing §22.2 or §0.9.1, and don't add game-specific counts into the Playbook.
- Check `git status`, review staged diff and that secrets/generated outputs aren't being committed, then **commit autonomously**. Suggested message: **`Change 26: optimize Android exports and clean unused assets`**. Report full hash and whether the worktree is clean. **Never push** unless explicitly instructed.

## 3. Guardrails / explicit non-goals

- **No gameplay/content changes**: preserve all eight maps, current enemy roster, existing equipment/skill/item content, stage completion/key rules, Prestige, balance, drops, UI states, onboarding, saved current profiles, audio/visual appearance, fog shader, off-screen culling and Change 24/25 optimizations. Fix genuine missing references, not gameplay behavior to suit the export list.
- **Do not delete source art packs or their provenance**. Keep unused originals in Git if currently tracked and licensed, and prevent their inclusion in shipped artifacts instead.
- **No Android profiling, ADB tracing or manual low-end performance benchmarks**. The developer prefers ordinary device play later; packaging verification is automated on the desktop.
- **No additional save compatibility engineering**. Playbook §61.1 allows resets when needed, but this packaging-only batch should not change persistence or require a reset.
- **No demo implementation, localization, brand/store icon, marketing captures, Play Console, SDK upgrades or permissions changes**, except a minimal strictly necessary packaging configuration adjustment that is explained.
- **No UI overhaul, wholesale refactor or new external dependency** without a demonstrated need. Keep tooling simple, inspector-editable authored assets untouched, and shipping packages free of debug/testing code.
- **Do not silently rewrite `android/` generated files**, signing presets, private keys, licenses or external SDK configurations. Inspect toolchain behavior; report blockers truthfully.

## 4. Efficient implementation and final validation strategy

Use **one Claude chat and one coherent correction batch**. No full-suite rerun after every edit.

1. **Inspect** current repo + docs + actual export format and catalog/dynamic paths. Establish proof for what can be removed from **exports**. Build the reviewed dependency manifest and make the export configuration/import hygiene changes.
2. **Implement packaging checks** and focused fixtures demonstrating real dynamic asset resolution and coverage for all eight stages. Do targeted syntax/build checks as needed when debugging; avoid repeated expensive whole-project tests.
3. **At the end**, run Godot's import/resource load checks; then the maintained `python tools/run_probes.py` suite **once as the primary full gate** (expected ≥33/33 based on Change 25, report actual count). If it fails, fix and run targeted probes; finish with one final complete green suite, rather than declaring a partial pass.
4. Run one **Android verification export** (or the minimum necessary retries for a genuine build failure), then the **actual artifact** inventory/dependency/ABI checker. Separately inspect source-to-export coverage for late-game scenes and dynamic assets. Record package size/ABIs, missing/unexpected entries, and include/exclude counts **only as measured**. If the Android toolchain cannot export here, report the limitation and do not invent results.
5. Review startup/cold-cache outlier from Change 25 **only if the usual smoke check naturally reproduces it**; don't initiate another performance optimization batch or add user profiling.
6. Update documentation once the results are known, inspect Git status/diff and **commit automatically**. No push and no manual commit requested from developer.

**Testing boundary:** A successful headless source load is **not** proof that a packaged artifact contains every dynamically used resource. An export filter that makes APK/AAB smaller is **not** a success if player-visible content disappears. Be accurate about which claims are verified and which remain untested on Android.

## 5. Definition of done / final handoff

- [ ] Reviewed full-game allowlist from all eight stages, dynamic runtime art and core UI/audio/FX dependencies; no unverifiable exclusions.
- [ ] Unneeded asset variants/packs are excluded from the shipped artifact **without deleting original source packs**.
- [ ] Godot import hygiene corrected for old evidence screenshots and Enemy Roster documentation; actual runtime translations unaffected.
- [ ] Android Release ABI configuration audited; actual ABI contents verified or exact limitation reported.
- [ ] A real APK/AAB/PCK exported and inspected if environment supports it; actual asset inclusion/omission validated with appropriate package-aware tooling. No debug, docs, private files or credentials packed.
- [ ] Reproducible manifest + separate packaging verification tool retained for later use by Stage 16 demo generator.
- [ ] Maintained regression suite passes fully at end; no new script errors; current save version intact; no gameplay/design/visual change.
- [ ] App/Android Release version aligned to Change 26; GDD/Registry/Tests/README/Change 26 report updated as appropriate; historical reports preserved.
- [ ] **Claude committed locally**, reports commit message/hash/worktree state, and did **not** push.

### Required final response

Briefly report changes **by E01–E06**, actual proof of exported contents (artifact type, archive size, ABI directories, asset categories excluded and retained, resource/scene load checks), exact test commands and results, limits/blocks, documentation touched, version numbers, any development-save effect (expected none), and the **Git commit message and full hash**. Never claim phone-specific performance or Play Console readiness from this packaging pass.
