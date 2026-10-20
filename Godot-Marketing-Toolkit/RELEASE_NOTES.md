# Godot Marketing Capture Toolkit — 1.0.2

**Status:** stable reusable baseline for the validated Windows/Godot workflow.

## 1.0.2 maintenance release (Play locale tag validation)

- Corrects the structured Google Play listing validator to expect Play-facing locale codes rather than all runtime codes. The four verified baseline mappings are `uk-UA → uk`, `id-ID → id`, `vi-VN → vi`, `th-TH → th`; the 16 other tags remain unchanged. It detects incorrect legacy tags, missing/duplicate entries and text lengths.
- Supports an optional, deliberately reviewed **complete** map of 20 runtime IDs to Play tags via `--locale-map` (start from `examples/play_locale_map.example.json`). Always inspect the Play Console import results for all intended languages: this validator performs local structural checks only.
- Package integrity SHA-256 manifest and offline regression tests updated. **No change** to Godot addons, installed capture behavior, video composition or fonts. Capture/media production validation from 1.0.0 and package-integrity validation from 1.0.1 remain applicable. This release's locale validator has been tested offline; it does not independently certify new Play Console UI behavior.

## 1.0.1 maintenance release (packaging/integrity fix)

1.0.0's `PACKAGE_FILES.sha256` did not verify on a fresh Git clone (reported during Everfort consolidation): it had been generated from a Windows working tree in which `assets/fonts/font_manifest.json`, `examples/marketing_manifest.example.json` and `tests/test_toolkit.py` had CRLF line endings, while the repository, and so every clone, holds them with LF. 1.0.1 hashes the canonical bytes, adds a toolkit `.gitattributes` (LF text in every checkout, fonts and media binary) and a regression test that clones the package under each line-ending configuration and verifies it.

**No functional change:** the installed addons, the CLI, screenshot capture, trailer and 10-video social composition, fonts, localization/store-listing tooling and `install` / `status` behave exactly as in 1.0.0. No existing code, addon, example or data file changed in the repository; the release adds `.gitattributes` and `tests/test_package.py` and updates `VERSION`, `PACKAGE_FILES.sha256` and the documentation. A game pinned to 1.0.0 upgrades deliberately with `install --overwrite` (the installed addon files are byte-identical; only the lock's version changes), then `status`.

The validation basis below is that of 1.0.0 and applies unchanged.

## Validation basis

Version 1.0.0 consolidated the reusable capture/composition code validated across Growing Kingdom, Loopcremental and Everfort. Everfort production validation exercised 32 language-neutral Play Store screenshots across four device classes, a 30-second 1920×1080 Play trailer, and ten 15-second 1080×1920 social masters derived from the approved trailer footage: five focused reframes and five full-landscape cuts with copy kept in the black bands. The Windows suite reported 42/42 passing with Godot 4.7.2 and FFmpeg 8.0.1.

Stable means the reusable source contract is approved for new projects. It does **not** waive game-level release QA: each game still reviews its real screenshots/videos, verifies release-export exclusions, and plays representative media on a target Android device before publication.

## Included

- Generic Godot screenshot and video capture addons.
- Scenario-adapter contract; game-specific scenarios remain in each game.
- Python marketing CLI, FFmpeg composition/verification, font proofing and media analysis.
- Language-neutral screenshot workflow by default.
- Trailer composition with cards, fades, music/game audio and configurable quality.
- Ten-master social workflow: 5 focused + 5 full-landscape portrait cuts.
- Seven Noto font families and OFL licenses for marketing text proofing across the approved 20 locales.
- Google Play store-listing localization package validator (`tools/play_store_listing.py`).
- Generic examples and offline tests.

## Deliberately outside the package

- Game-specific gameplay code, saves, scenarios, marketing copy, recordings or final media.
- Runtime localization architecture for a shipped game; that is governed by the Reusable Game Development Playbook and implemented in the game itself.
- Uploading/publishing to Google Play or social platforms.

## New-project rule

Install and pin this exact version, create a game-owned adapter/manifest from the examples, keep capture saves isolated from production saves, and verify `status` before production capture. Do not copy another game's scenario logic or wording.
