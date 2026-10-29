# LootFarmer — Change 40: Progressive Localization Activation and Language Dropdown

Date: 2026-10-29. Brief: `LootFarmer_Localization_Progressive_Activation_and_Dropdown_Change_40.md` (developer-approved; "write code"). Previous: Change 39 `b643c67`. Batch 03 not started.

## 1. Outcome

- **11 languages selectable in normal builds:** English plus the ten catalogs validated in Changes 38 and 39. **9 draft languages hidden** from Settings, refused by the service, never packaged, and never chosen by Automatic. Their draft files are untouched (still untracked).
- **Settings › Language is one dropdown** (Godot `OptionButton` and its `PopupMenu`), replacing the 21-button grid.
- **Automatic now follows the device language** among the enabled locales, with English fallback.
- **All three release presets ship English + the ten enabled catalogs and nothing else from `localization/`.** Verified on real export packages.
- **Not done here:** no phone check and no native-speaker review. Public-release sign-off still needs a real Android smoke test (section 8).

## 2. Readiness: one source of truth

`scripts/autoload/localization_service.gd`

| Constant | Role |
|---|---|
| `RELEASE_LANGUAGES` | The 20 target locales in Settings order (a target, not a readiness claim) |
| `ENABLED_LANGUAGES` | **Per-locale readiness.** Settings, Automatic, catalog loading, `tools/export_manifest.py` and `tools/validate_localization.py` all read this one line |
| `ALL_LANGUAGES_CERTIFIED` | Final 20-language QA gate, `false`. The validator fails if it is `true` while any target locale is not enabled |
| `TEST_BATCHES` | Validated batches a probe/capture may load by name (`--test-languages=`). Player builds refuse it. `batch01`/`batch02` are now no-ops; an unvalidated name (`batch03`) is refused |
| `GODOT_LOCALES`, `NATIVE_NAMES` | Godot locale per id (es_419 → `es`); each language's own name |

Activating a future batch = add its locales to `ENABLED_LANGUAGES` (plus `GODOT_LOCALES`/`NATIVE_NAMES`), after its validation. No UI or routing rewrite.

### Enabled / hidden manifest

| Enabled (selectable, packaged) | Dropdown label |
|---|---|
| en_US | English |
| es_419 | Español (Latinoamérica) |
| es_ES | Español (España) |
| pt_BR | Português (Brasil) |
| fr_FR | Français |
| de_DE | Deutsch |
| it_IT | Italiano |
| nl_NL | Nederlands |
| pl_PL | Polski |
| ru_RU | Русский |
| uk_UA | Українська |

**Hidden drafts** (not listed, refused, not packaged): tr_TR, id_ID, vi_VN, th_TH, hi_IN, ja_JP, ko_KR, zh_CN, zh_TW.

### Catalog loading

`project.godot` still registers only `en.po`. The service loads an enabled catalog **on first use** (the selected or Automatic-resolved language), not all ten at startup. The developer's `project.godot` was not modified.

## 3. Automatic

`match_device_locale(device, available)` is a static, pure function. It works in this order:

1. Normalises the device string: `-` becomes `_`; `.UTF-8` and `@euro` are dropped; script tags are skipped; legacy `in` becomes `id`.
2. Tries an exact language + region match.
3. Applies the variant rules:
   - Spanish: Spain → `es_ES`; every other Spanish (including generic `es`, `es_MX`, `es_US`, `es_419`) → `es_419`.
   - Chinese (not enabled yet): `Hant`/TW/HK/MO → `zh_TW`, otherwise `zh_CN`.
4. Falls back to any enabled locale of the same language.
5. Otherwise returns English.

Tested mappings (probes):

| Device | Result |
|---|---|
| es_ES, es-ES | es_ES |
| es-419, es_419, es_MX, es_AR, es_US, es | es_419 |
| pt_BR, pt_PT, pt | pt_BR |
| fr_CA, fr_BE | fr_FR |
| de_AT, de_CH, de_LI, de_DE@euro | de_DE |
| ru, ru_RU, ru_UA, ru_KZ, ru_BY, ru_RU.UTF-8 | ru_RU |
| uk, uk_UA | uk_UA |
| it_CH / nl_BE / pl_PL | it_IT / nl_NL / pl_PL |
| en, en_GB, sv_SE, ar_EG, sr_Latn_RS, be_BY, kk_KZ, "" | en_US |
| tr_TR, id_ID, in_ID, vi_VN, th_TH, hi_IN, ja_JP, ko_KR, zh_CN, zh_TW, zh_Hant_HK, zh_Hans_CN, zh | **en_US** (no draft is ever reached) |

How the preference behaves:

- Automatic stays its own stored preference (`"automatic"`). It is never frozen to the language it resolved to.
- A manual choice is never rewritten because the device changed.
- A stored choice the build does not offer (for example `tr_TR` from a test build) shows English and **stays stored**, so it applies once that language is enabled. This replaces the old "reset to Automatic" rule.
- Malformed values still reset to Automatic.
- Progression saves are untouched.

## 4. The dropdown

`scripts/game/language_dropdown.gd` (preloaded by `game_ui.gd`). Theme additions in `resources/game/theme.tres` (PopupMenu hover = the gold Primary style, 24 px rows with 30 px gaps).

- **Closed control.** Shows the actual choice. Automatic shows its result ("Automatic (English)", "Automatisch (Deutsch)", "Автоматично (English)"). The engine arrow is drawn at 2×. Text trims instead of overflowing. Height 72.
- **Menu contents.** Automatic, then the 11 enabled languages in native names (never auto-translated). The current choice carries a radio mark.
- **Menu placement.** Width matches the button. It opens on the side with more room, inside the safe area (`LayoutService` insets). When the list is taller than the room, it is cut at half a row and scrolls with a wide blue thumb (the theme's slider fill). Rows are ≥ 56 units.
- **Scrim.** A dark scrim covers the screen behind the menu. It also swallows the outside tap that closes the menu, so the tap never reaches the map.
- **Reconciler-safe.** Settings rebuilds on every simulation revision. The dropdown keeps its own items, rebuilds them only when the list, the choice or the locale changes, and never while open. The scrim is an internal child.
- **Input.** Tap; keyboard/controller (opens on the current item, arrows, accept); Escape (closes only the menu); Android Back (closes the menu first, then the panel on the next press); outside tap; window resize (closes the menu); closing Settings (closes the menu).
- **Godot 4.7 findings** (now in Playbook 129.1):
  - `OptionButton.show_popup()` overrides any position/size set in `about_to_popup`, so the final rectangle is applied deferred.
  - A top-level catcher draws first among canvas roots, so it needs `z_index`.
  - The PopupMenu scroll bar is internal.
  - Escape reaches `_unhandled_key_input` only as a key event.

No Help/tutorial string referred to the old buttons. `LANG_*` names other than `LANG_AUTOMATIC` are now unreferenced, but they stay in the catalogs (no catalog edits in this change).

## 5. Visual evidence (actual windowed renders)

`docs/Change_40_Evidence/` contains 10 screens at each of 432x960 (20:9), 540x960 (16:9) and 768x1024 (4:3 tablet), plus `<shape>_layout.json` with the button/menu rectangles. Screens:

- `closed_automatic`
- `open_settings_top`
- `open_settings_bottom`
- `open_list_end` (scrolled to Русский/Українська)
- `closed_focus`
- `open_keyboard`
- `closed_ru`
- `open_ru` (Cyrillic UI)
- `closed_automatic_de`
- `open_automatic_de`

**Before:** `before_grid_uk_UA_432x960.png`, `before_grid_es_419_432x960.png` (the grid, from the Batch 01/02 evidence).

Layout results (canvas units; all 30 open-menu screens inside the visible screen, none covering the button):

| Shape | Settings at top | Settings at bottom |
|---|---|---|
| 432x960 (720x1600) | opens above, all 12 rows, no scroll | opens above, all 12 rows |
| 540x960 (720x1280) | opens above, all 12 rows | opens below, 635 tall, **scrolls** |
| 768x1024 (960x1280) | opens above, all 12 rows | opens below, 694 tall, **scrolls** |

Glyphs checked in the renders: Cyrillic (Русский, Українська, the Russian UI), Latin diacritics (Español, Português, Français). The Batch probes' font checks cover every catalog character.

Keyboard/Back checklist (`change_40_probe`, headless; rendered keyboard state in `open_keyboard`):

- [x] focus + ui_accept opens on the current choice
- [x] ui_down ×6 + ui_accept chooses Deutsch and closes the menu
- [x] Escape closes the menu only; a second Escape closes Settings
- [x] Android Back closes the menu only; the next Back closes Settings
- [x] outside tap closes the menu, no map gesture starts, Settings stays open
- [x] panel refreshes keep the open menu
- [x] window resize closes the menu
- [x] closing Settings closes the menu
- [x] Settings scroll position kept across a language switch

## 6. Export verification (real packages)

Derived files were regenerated in a clean `git worktree` (the working tree's uncommitted version edits make the generator refuse, as recorded in Change 39):

- `tools/export_manifest.json`: 250 files (was 239; +10 catalogs, +`language_dropdown.gd`).
- Family `language_catalogs` enumerates `ENABLED_LANGUAGES` minus `en_US`, replacing the empty `test_language_catalogs`.
- The generator gained `values: "const_strings"`.

Only the `export_files` lines of the three release presets were spliced into the developer's `export_presets.cfg`. Every other line is byte-identical to the developer's copy. The committed `export_presets.cfg` is HEAD plus those three lines only.

| Preset | Artifact (tests/tmp/export, ignored) | Result | localization/ contents | Store tag |
|---|---|---|---|---|
| Android Release | `LootFarmerIdleRPG.c40.aab` 59.60 MB (`--export-release`) | VERIFY_EXPORT PASS, sources 250/250, ABIs arm64-v8a + armeabi-v7a, package `com.shekinahwelefuldesigns.lootfarmeridlerpg`, versionCode 26 (the developer's working-tree value) | en + 10 | store_google_play |
| Android itch.io APK | `android_itch.pck` (`--export-pack`) | VERIFY_EXPORT PASS, 250/250 | en + 10 | store_itch_io |
| Windows itch.io | `windows_itch.pck` (`--export-pack`) | VERIFY_EXPORT PASS, 250/250 | en + 10 | store_itch_io |

- Compared with the Change 26 AAB, the additions are exactly the 10 catalogs and the dropdown script.
- No draft catalog, `untranslated_ids.*`, `check_draft.py`, `translation_status.json` or ASO file is packaged.
- `tools/verify_export.py` now also reads `.pck` files (ABIs and identity are skipped for them).
- The itch.io APK and Windows binaries themselves were not built (keystore and Windows metadata remain developer actions, Change 35). The packs are the exact resource content those presets ship.
- The DejaVu Sans theme font covers every enabled catalog. No text-server data is needed for Latin/Cyrillic.
- Nothing was published or pushed.

## 7. Tests

**Static checks:**
- `validate_localization`: 1,941 English keys (unchanged); 10 enabled catalogs checked; problems 0. New readiness checks: subset/order, Godot locale and native name per enabled locale, certification flag consistency.
- `export_manifest --check`: passes in the clean worktree.
- `validate_campaign_source`: passes.

**Probes:**
- `change_40_probe` (new, in the suite, 86 checks): readiness, the Automatic matcher, the dropdown content, placement at 3 shapes × top/bottom, and the input paths.
- `localization_batch01_probe` (87 checks) and `localization_batch02_probe` (107 checks): rewritten from "gate closed" to availability. They choose languages through the real dropdown (open, focus the item, accept), cover Automatic per device locale, keep a stored draft shown as English, and restore after a restart with no test switch. They reset the probe profile's stored language first: an earlier run's choice is now honoured, which exposed this.
- `ui_probe`, `bootstrap_probe`, `change_35_probe`: dropdown offers exactly Automatic + 11; drafts refused; manifest ships exactly en + 10 catalogs.
- `change_16_probe`: message only.
- `localization_sweep`: the pseudo-locale check ignores native language names (proper names).

**Full suite:** see section 9.

## 8. Known limitations and handoff

- **No Android device test in this change.** Before a public release that includes these ten languages, run the device smoke test from Playbook 132.6 on a real phone:
  - German (longest Latin) and Russian/Ukrainian (Cyrillic)
  - the dropdown by touch, including Android Back with the menu open
  - Automatic with the phone set to es-MX, es-ES, pt-PT and uk-UA
  - persistence across an app restart
- **No native-speaker review** of the ten catalogs (structural validation only, as in Changes 38/39).
- **Known English layout issue:** the Next Stage chip / View Camp overlap in English remains (pre-existing, unchanged).
- **Working tree:** `export_manifest`, `change_26_probe` and `change_27_probe` fail only because of the developer's uncommitted `project.godot`/`export_presets.cfg` edits (version 27 → 26, icon path → uid). See section 9.
- **Batch 03 handoff** (tr_TR, id_ID, vi_VN, th_TH, hi_IN):
  1. Validate with `TEST_BATCHES["batch03"]` (test-only).
  2. Add Thai/Devanagari font fallbacks and `include_text_server_data`.
  3. Then, on developer approval, append the five ids to `ENABLED_LANGUAGES` and add their `GODOT_LOCALES` and `NATIVE_NAMES`.
  4. Regenerate the manifest in a clean worktree.
  5. Re-export and verify all three presets.

  The `in` → `id` legacy mapping is already in place.

## 9. Regression results

`python tools/run_probes.py`, 44 entries (3 static checks + 41 Godot scenes).

**Clean worktree** (HEAD + this change only, imported once): **44/44 pass**, no script errors, no timeouts.

**Developer's working tree: 41/44.** The 3 failures are the pre-existing ones caused by the uncommitted `project.godot`/`export_presets.cfg` edits (the same three as Change 39); all pass on the clean worktree:

| Check | Failure | Cause |
|---|---|---|
| `export_manifest` | Android itch.io APK version/code 27 != project config/version 26 | the developer's uncommitted version 26 |
| `change_27_probe` | version 27, version code, launcher icon path | uncommitted `config/version` and `config/icon` (uid) |
| `change_26_probe` | core file `uid://drj4h6jnqymfy` | uncommitted icon uid |

**Regression of mine, found and fixed.** The first working-tree run (40/44) also failed `localization_batch02_probe` "no Batch 02 catalog loaded before use". The cause was the suite's persistent probe profile: it held a Polish choice saved by an earlier run, which is now honoured at startup (it used to fall back to English). Both batch probes now exempt only the language the profile restored. After the fix, all three localization probes passed twice in a row on the persistent profiles, and in both final runs.

Key totals:
- `change_40_probe` 86/86
- `localization_batch01_probe` 87/87
- `localization_batch02_probe` 107/107
- `localization_sweep` 2,112 screen checks, 0 findings
- `validate_localization` 0 problems

## 10. Developer files preserved

- `project.godot`: unchanged.
- `export_presets.cfg`: only the three `export_files` lines changed in the working copy. The commit contains HEAD's file plus those lines (staged from the clean worktree), so the developer's version/icon/Windows-preset edits stay uncommitted and intact.
- Untracked drafts, `README_TRANSLATION_STATUS.md`, `check_draft.py`, `translation_status.json`, `untranslated_ids.*`, the ASO package, the Playbook reconciliation draft and the earlier `tests/*.gd.uid` files: untouched and uncommitted.
- Export artifacts are under `tests/tmp/export/` (ignored); `builds/` is untouched.
