# Historical bootstrap report (v0.2)

**Superseded for current development:** the user confirmed this bootstrap in Godot and deferred signing. v0.3 gameplay is now implemented; read `LootFarmer_Prototype_Status.md`. The report below preserves the evidence available before that implementation and is not the current blocker list.

# LootFarmer — Bootstrap handoff v0.2

Updated: 2026-10-18, America/Santo_Domingo.

**Design: approved. Implementation: authorized. Checkpoint 0: source prepared, NOT PASSED. This package is not yet a playable prototype.**

The user requested a prototype following the Playbook. Sections 0 and 0.8 explicitly require a release-signed APK tested on a physical Android device before any gameplay checkpoint. This environment cannot complete that gate: no Godot editor, Android SDK/platform tools or connected device is available. Java 17 is available. No local upload keystore or signing password was supplied, requested or generated here.

## Completed in this package

- Approved title **LootFarmer - Idle RPG**, package `com.shekinahwelefuldesigns.lootfarmeridlerpg`, version 0.1.0 / version code 1.
- GDD/audit/checkpoint records updated with approval and final A01–A03 rules; latest-three/expanded-ten acquisition history added to gameplay scope.
- Canonical Playbook starter reconstructed and configured at 720×1280 portrait, canvas_items/expand. Orientation corrected to Godot integer enum 1, rather than the old starter's string value.
- Bootstrap utility scene is editor-authored: safe-area margins, title/version, touch/save count, explicit pause, confirmed reset and language buttons. This is a diagnostic screen, not final game UI.
- English source catalog and native TranslationServer support. All 20 locale options exist; 19 disabled, Automatic forced to English. English-name labels avoid implying shipped translations. Runtime CJK/Thai/Devanagari font validation remains a release localization gate, not certified here.
- Template layout/number/settings/audio services reused. Save service extended with namespaced probe isolation before load, staged file replacement, backup recovery, unknown-section preservation, read-only protection for malformed/newer saves and settings-preserving reset.
- English bootstrap labels use semantic keys. Theme/font, margins and scene layout are editable rather than constructed entirely in script.
- Original toolkit source retained. Installer installed the 11 managed addon files and pinned 1.0.2. Status verified installed files == lock == source; full package SHA256 checks pass. No toolkit code was rewritten.
- Signed APK and AAB export presets, arm64, no internet permission; test/docs/toolkit/capture sources excluded. No credential values stored. LF monogram is provisional bootstrap branding, not approved store art.
- Local Windows helper for key creation, prerequisites, isolated probe, signed APK export/signature verification and chosen-device installation.

## Validation actually performed

| Check | Result |
|---|---|
| Static project/resource paths, language catalog coverage, 19 disabled buttons, namespace order | PASS |
| Python source syntax | PASS |
| Toolkit package file SHA256 and installed lock status | PASS |
| Documentation obsolete approval/status scan | PASS |
| Changed-file archive byte comparison and integrity | PASS at packaging |
| Godot import/parser check | NOT RUN — executable absent |
| Bootstrap GDScript probe | NOT RUN — executable absent |
| PowerShell helper execution | NOT RUN — Windows/PowerShell unavailable here |
| UI render/touch/safe area | NOT RUN |
| Android export/signature and physical installation | NOT RUN |
| Gameplay or balance tests | NOT IMPLEMENTED / NOT RUN |

Static validation cannot certify GDScript API compatibility or runtime correctness. Exact Godot version and export-template pair must be recorded locally. Supplied starter specifies 4.7; Toolkit 1.0.2 documentation identifies 4.7.2 Windows validation. Do not silently downgrade to an older engine or claim a local engine is installed.

## Apply the patch

Extract the changed-files ZIP into the project folder containing project.godot and overwrite matching files. No extra wrapper folder is present. Keep existing assets and Godot-Marketing-Toolkit source. Do not delete user files or manually carry .godot caches from another machine; Godot regenerates imported state. This patch carries the exact updated Playbook, unchanged.

## Finish Checkpoint 0 locally

Run from the project root in PowerShell. Supply the actual installed Godot **console** executable path; no invented path is baked into the helper.

1. Create the dedicated upload key outside the project (only if it does not already exist). Password is prompted locally, never written into the project or command arguments:

```powershell
.\tools\android_checkpoint0.ps1 -Action CreateKey
```

Default JDK/SDK paths come from the Playbook. Override `-JavaHome`, `-AndroidSdk` or `-KeyStore` if yours differ. Existing keys are never overwritten. Securely back up the key and password. The key alias is `lootfarmer_upload`.

2. Set the actual Godot console path, then check installed prerequisites:

```powershell
$LootFarmerGodot = Read-Host 'Full path to Godot console executable'
.\tools\android_checkpoint0.ps1 -Action Check -Godot $LootFarmerGodot
```

In Godot Editor Settings configure the correct JDK/Android SDK paths. Install matching export templates and Project > Install Android Build Template. Use the supplied Android Bootstrap APK preset for the baseline; Android Release is the eventual AAB preset. Release credentials are passed transiently by the helper at export. GUI exports require entering the same local credentials in Godot's protected export credentials UI.

3. Run the actual import and isolated runtime probe:

```powershell
.\tools\android_checkpoint0.ps1 -Action Probe -Godot $LootFarmerGodot
```

The probe validates formatting, portrait, English gating, save/load, backup recovery and reset from pause. It uses `probe-bootstrap`, never production. Any SCRIPT ERROR, parse error or nonzero exit fails this step. Send the complete error text for correction if it fails. Do not proceed on static checks alone.

4. Open the main scene, inspect portrait layout and touch/save behavior, then export:

```powershell
.\tools\android_checkpoint0.ps1 -Action Export -Godot $LootFarmerGodot
```

This prompts for the local signing password, exports release APK, verifies its signature with apksigner and prints SHA256. Android SDK/template configuration is required first. If the export fails, correct it before installation; no debug-key substitute counts as the release-signed baseline.

5. List connected devices using ADB, choose the actual phone serial, and install:

```powershell
.\tools\android_checkpoint0.ps1 -Action Install -Godot $LootFarmerGodot -DeviceSerial '<your-device-serial>'
```

6. On the phone verify: portrait stays portrait; text/buttons fit safe areas; touch counter increments; closing/reopening preserves count; language Automatic stays English; other 19 buttons disabled; explicit pause toggles; Hard Reset from pause clears count and unpauses while preserving settings. Check app name/version/package/signing certificate. Rotate/background/resume without crash or reset. No gameplay is expected on this screen.

7. Record the exact Godot version, template version, device/Android version, APK SHA256/signature result and checklist outcome in a checkpoint evidence note. Only then mark Checkpoint 0 passed and proceed to Checkpoint 1. Current gameplay authorization remains valid; do not request “write code” again for the already authorized implementation.

## Engineering-reference limitation

The archive contains a blank project, assets, old reference GDDs and the toolkit, not a previously validated production project's source. The embedded Playbook starter is used as the explicit fallback. If a validated previous project is supplied, compare reusable platform fixes before certifying the baseline; no old mechanics/UI/economy are inherited. No claims are made that old reference GDDs were audited for reuse.

## Next authorized work

After the physical gate: implement CP1–CP6 from the approved GDD, including editor-authored actor/GUI templates, verified Pixel Plains layers/animation maps, the full compact progression loop, saved state, acquisition history, identity-list auto-sell and prestige. Additional offline rewards are still deferred to full game.

## Technical references used

- Supplied Playbook: sections 0/0.8, 13, 22, 63.1, 105–106, 132 and 135.
- Supplied Toolkit 1.0.2 README / INTEGRATION_FOR_CLAUDE.md / RELEASE_NOTES.md.
- Godot DisplayServer orientation enum: https://docs.godotengine.org/en/stable/classes/class_displayserver.html
- Godot Android export credentials/environment options: https://docs.godotengine.org/en/stable/classes/class_editorexportplatformandroid.html
