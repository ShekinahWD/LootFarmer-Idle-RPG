# Reusable Marketing Toolkit — integration handoff (1.0.2)

**Stable reusable baseline.** Read `README.md` and `RELEASE_NOTES.md`, then follow the project's approved Reusable Game Development Playbook. The toolkit is self-contained and must not depend on another game's repository.

## Install into the current Godot game

1. Inspect `project.godot`, existing addons, release export presets and `.gitignore`. Keep the toolkit source in a `.gdignore`d folder or external pinned package. Never overwrite an existing addon without reviewing the difference.
2. From the project root on Windows:

```powershell
python .\Godot-Marketing-Toolkit\tools\marketing.py check --godot "<godot console exe>"
python .\Godot-Marketing-Toolkit\tools\marketing.py install --project .
python .\Godot-Marketing-Toolkit\tools\marketing.py status --project .
```

`install` writes `marketing_capture_toolkit.lock.json`; `status` must confirm installed files == lock == toolkit source. Use `--overwrite` only for a deliberate toolkit update.

3. Create a **game-owned** `marketing/game_scenarios.gd` and `marketing/manifest.json` from `examples/`. Never copy another game's scenario logic, saves, wording or staged state. Capture must use a disposable/test save namespace and disable normal autosave before the game reads any production save.
4. Capture authentic gameplay only. Store screenshots are language-neutral by default: real gameplay + native UI + no added promotional copy. Capture every applicable device class as a real render at its target size.
5. Build the approved store trailer from the same scenario system. After that trailer is approved, produce the standard social set from the approved footage/music: **10 masters**, 1080×1920, 30 fps, about 15 s; **5 focused reframes** with blurred fill and **5 full-landscape cuts** with black bands. Copy is manifest-driven, feature-true, inside social safe areas, and never covers gameplay in the black-band composition. Re-record only when existing footage genuinely cannot support a useful variation.
6. Keep one reference-language social master set by default. Localized social variants are generated only when explicitly requested.
7. Validate typography when marketing copy is localized:

```powershell
python .\Godot-Marketing-Toolkit\tools\marketing.py fonts --manifest marketing\manifest.json --locales all --godot "<godot console exe>" --overwrite
```

8. For the approved 20-locale Google Play listing package, validate the structured JSON before giving it to Play Console's AI-assisted importer:

```powershell
python .\Godot-Marketing-Toolkit\tools\play_store_listing.py validate path\to\Google_Play_Localizations_AI_Import.json
```

The validator checks the **Play-facing** 20 tags, not runtime identifiers: `uk-UA → uk`, `id-ID → id`, `vi-VN → vi`, and `th-TH → th` (the other 16 are unchanged), plus required fields, duplicates and the 30/80/4000 character limits. If Play Console changes its accepted tags, validate using a reviewed complete mapping file via `--locale-map <map.json>`. After importing, verify that Play Console actually detected all **19 translations plus the English source**, and identify any missing locale rather than assuming the AI importer accepted everything.

9. Release presets must exclude development-only material, at minimum the game-owned marketing sources, generated outputs/recordings, the installed capture addons, toolkit lock/source, docs/test scenes and other development-only files. List the exported pack/bundle and verify those files are absent. Do not exclude the game's runtime localization catalogs/fonts.
10. Run:

```powershell
python -m unittest discover -s Godot-Marketing-Toolkit\tests -v
```

The suite includes `tests/test_package.py`, which verifies `PACKAGE_FILES.sha256` against the toolkit copy and fresh clones.

Then run the game's relevant safe probes, inspect every screenshot/review/contact sheet at phone size, and perform game-level Android media smoke testing before publication.

## Ownership

- **ChatGPT:** marketing/ASO strategy, approved copy, screenshot subjects/order, video brief/storyboard, reusable-method decisions.
- **Claude/repository agent:** game-specific scenarios, integration, capture, composition, export checks and tests.
- **Human developer:** approves claims/copy/assets, checks representative device behavior and decides when to commit/upload/publish.

Do not upload, publish or push merely because toolkit validation passed.
