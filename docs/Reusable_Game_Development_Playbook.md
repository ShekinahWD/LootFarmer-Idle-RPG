# Reusable Game Development Playbook

> Purpose: a working manual for building small premium Godot games, especially Android-first 2D incremental, roguelite, idle, tower-defense, city-management and automation-heavy games.
>
> It is distilled from three projects: **Everfort** (an incremental tower defense, shipped on Google Play), **Feed the Dragon** (a city builder with a final battle) and **Growing Kingdom** (a kingdom-management and wave-defense game, in development). It is not any game's design document. It keeps the patterns, architecture, UI rules, asset practices, AI workflow and production lessons that held up across them.
>
> **How to read it.** Each rule is written as a **reusable principle**. Examples name the game that validated them ("Growing Kingdom: ..."); their numbers, names and tables belong to that game and are evidence, not defaults. A game's own design decisions live in that game's GDD and decision log, never here (section 107).
>
> **Approved cross-game production baseline (2026-10-15):** 19-stage lifecycle (section 0.9), paid-once/no-tracking policy (0.10), English-first localization infrastructure from the first feature, with all 20 languages validated before release (132), authentic language-neutral screenshot capture (87), universal trailer + 10-master social-video production and posting-copy workflow (133), ChatGPT-owned ASO with policy-reviewed English source copy, Play-locale mapping, localized listing/release-note handoff (134), and the separately versioned **Godot Marketing Capture Toolkit 1.0.2 stable** (135). These decisions supersede older optional-service/marketing assumptions. The toolkit is an implementation artifact, **not** a second process document; pin/install it rather than recreating solved infrastructure.
>
> **Last consolidated:** 2026-10-15 (Everfort publishing + reusable workflow finalization). Everfort established the 20-locale runtime reference architecture; the shared workflow now separates English-first implementation from the later 19-language translation handoff, probe-save isolation, old-save compatibility checks, release-export localization verification, language-neutral store screenshots, the 30-second store trailer workflow, the standard ten-video social package (5 focused + 5 full-landscape), per-video social posting copy, policy-first English store-copy approval, and explicit separation between runtime locale IDs and Google Play locale tags. Godot Marketing Capture Toolkit 1.0.2 is the approved stable Windows/Godot baseline. Earlier consolidation history follows. Sections 128 to 133, which had grown as one section per Growing Kingdom pass, were reorganized by topic and merged into the sections that own each subject; contradictions between sections were resolved (what a workforce counter counts, where a block reason goes, how a reassignment treats a carried load, when old saves must be migrated); and new canonical sections cover the iteration loop (44), save compatibility by development phase (61), progression-layer roles (3), management surfaces (16), teaching (18), text hierarchy (128), controls (129), army management (130) and soft counters (131). Earlier synchronization notes are in git history. Strengthened 2026-10-02 from Growing Kingdom's Android corrections, merged into the owning sections: centralized tutorial arbitration (18.8), automation modes above manual configuration (8.2), bulk mode changes (129.6), support anti-stacking (130.7), the Defend coverage pass (130.4), HUD ownership surfaces (16.4), adding to an established HUD (19.1), authored price tables (92), current-schema correctness before release (61.1) and targeted correction batches during device testing (44.2). Strengthened again 2026-10-02 from Growing Kingdom's Villager corrections: a blocked carried load falls through instead of blocking the list (115.4, 120.4), and automatic workers share one coordinated allocation instead of each taking the same best task (8.2, 115.1).

> **Asset-workflow update — 2026-10-18:** Added lessons from Loopcremental's supplied-asset prototype review: verified animation inventories and base-unit composition (22.1–22.3), action/contact/death presentation contracts (13.1–13.4), asset-only UI boundaries (22.2, 125.10), practical editor-editability checks (63.1), and evidence-based visual audits (56.1). These additions document reusable requirements and approved examples; they do not certify the prototype or its previous test reports. The 2026-10-15 production baseline and unrelated guidance remain unchanged.

> **Change 3 documentation merge — 2026-10-20:** Incorporated supplied fog sections 117.9, 124.12 and 127.6 without replacing the existing LootFarmer asset registry or section 136. Added reusable contracts for camp reveal, copy-count bonuses, evolution baselines and batched rewards. These are specifications, not implementation evidence.

## Topic map

| Topic | Sections |
|---|---|
| Starting a new game (GDD, bootstrap, signing) | 0, 105 to 107 |
| Universal production lifecycle and business model | 0.9, 0.10, 2, 44, 95 |
| Scope, checkpoints and the iteration loop | 1, 2, 44, 45, 60.1, 95, 108 |
| Progression layers (run, Permanent, Prestige, Ascension) | 3, 32 to 37, 53, 92, 110 |
| Automation | 8, 9, 55 |
| Workers, resources, buildings, the living world | 10 to 13, 80, 109, 115 to 127 |
| Army management and combat | 5 to 7, 38, 39, 72, 79, 130, 131 |
| Mobile UI: surfaces, text, controls | 14 to 17, 19 to 21, 70, 78, 123 to 125, 128, 129, 143 |
| Teaching, onboarding and first-profile progression | 18 |
| Pause, save, reset and offline | 26 to 31, 57, 58, 61, 110, 111, 145 |
| Validation, probes, bots and audits | 41 to 43, 59, 60, 100, 112, 113, 127, 145 |
| Assets, terrain and visuals | 22 to 25, 54, 63 to 67, 71, 73, 101, 103, 104 |
| Android, release and store | 47 to 49, 64, 68, 84, 87 to 89, 95, 96, 134 |
| Localization across 20 languages | 0.11, 132 |
| Screenshots and universal video | 87, 133 |
| Reusable source toolkit and AI responsibilities | 0.2, 44, 135 |

## Historical section moves (2026-10-01): former sections 128 to 133

| Former section | Now |
|---|---|
| 128.1 value first; 131.3 reason on the cost's row; 131.4 one icon per state; 131.5 relabel a changed word | 128 (text hierarchy and card anatomy) |
| 128.2 content-fit panels; 129.4 settled size; 129.5 stable lists | 16 (management surfaces) |
| 128.3 coach hints; 128.4 first-threat warning; 130.3 pointing hand; 132.2 teach on the introduction card | 18 (teaching) |
| 128.5 guard hysteresis; 129.7 protect the base first; 133.2 hard leash | 130.4 (stances) |
| 128.6 meta layer from a milestone; 131.1 tier gate; 131.2 and 133.1 moving rewards between layers | 3 (progression layers), 61 (saves) |
| 128.7 herds | 118.12 |
| 128.8, 129.8, 130.5 probe hygiene and races | 127.5 |
| 129.1 what a workforce number counts | 124.2 |
| 129.2 pause as a gameplay lock | 26.1 |
| 129.3 reassignment drops the load as a pickup | 115.4, 120.11 |
| 129.6 direct selection; 130.1 one edit rule; 130.2 a way back | 129 (controls and actions) |
| 130.4 random start plots | 119.2 |
| 131.6 and 132.4 composition audits | 112.1 |
| 132.1, 132.3 defence traits as matchups | 131 (soft counters) |
| 133.3 per-building jobs | 109, 130.8 |
| 133.4 real and game time; 133.5 Current Boosts | 17 |

---

# 0. Canonical new-project startup flow: GDD first, then Android bootstrap

A future game should not begin with gameplay code. The project starts by defining the game, then proving that the clean technical baseline can become a correctly identified, signed, installable Android application.

The canonical startup order is:

```text
1. Create and finalize the game-specific GDD
2. Bootstrap/configure the Godot project from the validated production baseline
3. Create the game's Android upload keystore
4. Configure the project's release-signing identity
5. Install/verify Android dependencies, export templates and the Android build template
6. Open and validate the clean starter project
7. Export a release-signed Bootstrap APK
8. Install/test that APK on the physical Android target
9. Commit/archive Bootstrap / Checkpoint 0
10. Begin implementing the GDD with Checkpoint 1
```

The signing identity is established before project-specific Android build dependencies are installed. The **actual signed APK export** happens after those dependencies/templates are available.

Do not start the first gameplay mechanic until both the GDD and Bootstrap / Checkpoint 0 are complete.

## 0.1 Phase A: create and finalize the game-specific GDD

The GDD is the design authority for the new game. Finish the major behavioral contracts before implementation expands across many systems.

At minimum, define:

- game identity and player fantasy;
- core loop;
- run/session structure;
- economy and resource ownership;
- progression layers;
- major systems/content;
- UI/UX and onboarding;
- persistence, offline and reset rules;
- balance/pacing targets;
- production scope and first-playable acceptance criteria.

Use the staged GDD interview and contradiction audit described later in this Playbook. The important startup rule is:

> **Design first. Prove the Android production baseline second. Implement the GDD third.**

## 0.2 Phase B: bootstrap/configure Godot from the validated production baseline

After the GDD is approved, use the last **validated full production project** as an engineering reference and extract a clean starter baseline. Do not manually recreate Android, display, persistence and tooling configuration from memory when a shipping project already proved those choices.

This is a **configuration transfer**, not a game clone.

This Playbook is intentionally **self-contained** for this workflow. Do not require a separate bootstrap audit, starter-template document, or second reusable guide. The canonical starter specification and source template are embedded in this file so a repository-aware agent can recreate Bootstrap / Checkpoint 0 from this document plus the previous validated project.

### 0.2.1 Required inputs

Give the repository-aware agent:

- the completed/approved game-specific GDD;
- the latest full validated project from the previous game;
- this standalone reusable Playbook;
- the new game's name (the Android package ID is derived automatically as `com.shekinahwelefuldesigns.<normalized_game_name>`);
- the intended Godot version;
- orientation and reference resolution;
- whether the game needs network services;
- any approved service IDs that the developer intentionally supplies.

The agent should inspect the repository rather than relying on an old continuity summary for technical configuration. If the previous project contains an embedded copy of the reusable Playbook while a newer standalone Playbook is supplied separately, the standalone file is the documentation authority; do not overwrite newer cross-game lessons with the older embedded copy.

### 0.2.2 Classify every previous-project setting

Use four buckets:

```text
Carry unchanged
= proven engine/mobile defaults that are truly cross-game

Generalize
= useful architecture whose gameplay-specific dependencies must be removed

Recreate per game
= identity, branding, permissions, derived package/store/service configuration

Do not carry
= old gameplay, balance, content, assets, experiments or obsolete workarounds
```

For Everfort, the reusable baseline included the 1920×1080 reference layout, `canvas_items` + `expand`, Android-first mobile renderer choices, touch emulation, Android AAB/arm64 defaults, immersive-mode policy, version-name inheritance, safe-area conversion, centralized number formatting, settings ownership, semantic audio ownership and versioned/throttled save architecture.

### 0.2.3 Never copy game identity or secrets blindly

The new project must deliberately replace or regenerate:

- application/store name;
- Android package ID, generated from the fixed `com.shekinahwelefuldesigns.<normalized_game_name>` convention;
- integer change version and store version code;
- launcher/adaptive/store icons;
- Android upload keystore/alias;
- no AdMob, Firebase Analytics, Crashlytics, Google Play Billing, tracking or telemetry configuration (these integrations are excluded by section 0.10);
- privacy/support/community URLs;
- permissions;
- game-specific save paths/schemas and cloud identifiers;
- store listing identity and pricing (one-time paid purchase; no in-app products).

Do not place signing keys or passwords into the reusable template merely to make setup feel automatic. Automation should remove repetitive configuration, not weaken key separation.

### 0.2.4 Carry proven platform configuration automatically

A repository-aware agent can normally preconfigure:

- `project.godot` application/display/stretch/orientation defaults;
- input emulation and mobile renderer settings;
- Android export preset and architecture;
- blank Android version name so the project integer change version remains the single source of truth;
- source-control ignores;
- generic layout/safe-area helpers;
- centralized numeric formatting;
- Settings state and persistence hooks;
- semantic Audio service shell;
- Save service shell with schema/version/reset/lifecycle behavior;
- debug/probe folder conventions;
- reusable editor tooling whose source is actually present and versioned.

Prefer a small bootstrap script or agent-driven configuration pass that accepts the new game name/orientation, derives the Android package ID from the fixed company prefix, and avoids editing the same fields by hand every project.

**Shared toolkit contract:** In addition to this self-contained bootstrap specification, every new project consumes a **versioned source-code toolkit** (section 135) whenever the validated artifact exists. Bootstrap installs or references that pinned toolkit automatically; it must not regenerate previously validated capture/video/FFmpeg code from prompts. Source is reused, while the game's screenshots, gameplay scenarios, trailer timeline and storefront copy remain game-specific. Do not pretend an unbuilt toolkit has already been installed.

## 0.3 Phase C: create the Android upload keystore

Create a dedicated upload keystore for each new game immediately after the new project's identity/package configuration is established.

### 0.3.1 Standard keystore location and naming

Keep upload keystores outside the game repository under:

```text
D:\OneDrive\GameDevolpment\AndroidKeyStores\
```

Everfort reference:

```text
D:\OneDrive\GameDevolpment\AndroidKeyStores\Everfort-upload.keystore
```

Future-game convention:

```text
GAME_NAME-upload.keystore
alias: game_name-upload
```

Change both the filename and alias for the new game. Do not reuse `Everfort-upload.keystore` or `everfort-upload` for a different title.

### 0.3.2 Run the key-generation command in Windows CMD

Open **Command Prompt (CMD)** and run the command. Everfort's reference command is:

```bat
"D:\Programs\Eclipse Adoptium\jdk-17\bin\keytool.exe" -v -genkey -keystore "D:\OneDrive\GameDevolpment\AndroidKeyStores\Everfort-upload.keystore" -alias everfort-upload -keyalg RSA -keysize 2048 -validity 10000
```

For a new project, change:

```text
Everfort-upload.keystore -> the new game's keystore filename
everfort-upload          -> the new game's alias
```

`keytool` comes from the JDK. On the current Windows development machine, Godot's configured Java SDK path is `D:\Programs\Eclipse Adoptium\jdk-17`, so signing commands should call `D:\Programs\Eclipse Adoptium\jdk-17\bin\keytool.exe` explicitly instead of assuming `keytool` is on the Windows `PATH`. If the Java SDK location changes later, use the value shown in **Godot -> Editor -> Editor Settings -> Export -> Android -> Java SDK Path** and append `\bin\keytool.exe`.

### 0.3.3 Password rule

When asked for the keystore password:

- create a strong password and store it in the developer's secure credential storage;
- use the **same password for the key and keystore**;
- if `keytool` asks for a separate key password and offers `RETURN if same as keystore password`, press **Enter**;
- never put the password in Git, this Playbook, a project ZIP, a prompt, or a shared continuity file.

### 0.3.4 Default certificate information

Use the following publisher identity by default unless the developer's legal/company information changes:

```text
What is your first and last name?
Yorki Oscar Bonilla Sanchez

What is the name of your organizational unit?
Game Development

What is the name of your organization?
Shekinah Weleful Designs

What is the name of your City or Locality?
Santo Domingo Este

What is the name of your State or Province?
Santo Domingo

What is the two-letter country code for this unit?
DO
```

Equivalent certificate identity:

```text
CN=Yorki Oscar Bonilla Sanchez
OU=Game Development
O=Shekinah Weleful Designs
L=Santo Domingo Este
ST=Santo Domingo
C=DO
```

When `keytool` prints the completed identity and asks whether it is correct, review it and answer `yes` only when those values are correct.

The street address is not part of the normal certificate prompts and should not be added to this reusable signing procedure.

### 0.3.5 Verify and protect the keystore

After creation, verify that the expected file exists in the AndroidKeyStores directory. The keystore is a credential and must remain outside the repository.

Keep at least one protected backup. The reusable project may record the **path and alias**, but must never embed the keystore file or password.

## 0.4 Phase D: configure the project's release-signing identity

In Godot's Android export preset, configure:

```text
Release          = path to the game's upload keystore
Release User     = the game's key alias
Release Password = the upload-key password
```

For Everfort the path/alias reference is:

```text
Release      = D:\OneDrive\GameDevolpment\AndroidKeyStores\Everfort-upload.keystore
Release User = everfort-upload
```

The password remains private and is entered locally.

Godot stores confidential export values separately from the normal version-controlled export preset. Do not deliberately copy `.godot/export_credentials.cfg` into source control or project handoff ZIPs.

For release-signed validation/export, ensure **Export With Debug** is disabled.

## 0.5 Phase E: install and verify Android dependencies/templates

After project identity and signing identity are established, make the development environment capable of building the Android project.

For the Windows Godot workflow, verify/install as needed:

- JDK 17 / Java SDK path;
- Android SDK;
- Android platform tools / ADB;
- the SDK/build-platform components required by the intended Godot version;
- matching Godot export templates;
- the Android Gradle Build Template when the project uses Gradle/AAB or Android plugins.

In Godot, configure the Java SDK and Android SDK paths in **Editor Settings**.

Confirmed paths on the current Windows development machine:

```text
Java SDK Path    = D:\Programs\Eclipse Adoptium\jdk-17
keytool.exe      = D:\Programs\Eclipse Adoptium\jdk-17\bin\keytool.exe
Android SDK Path = D:\Android\Sdk
```

Use these explicit paths in Windows commands unless the Godot Editor Settings are later changed.

When Gradle/AAB support is required, use:

```text
Project -> Install Android Build Template
```

and keep **Use Gradle Build** enabled in the Android export preset.

A project that depends on an Android addon/plugin must install/version that dependency reproducibly. A `project.godot` reference is not proof that the referenced dependency exists in the transferred repository.

Everfort exposed an important example: the project configuration referenced the Store Screenshot Capture addon, while the inspected full archive did not contain the addon source and the old `.gitignore` ignored `/addons/` globally. A future project should not inherit that contradiction.

Reusable rule:

> If the project depends on an addon, either version the addon source with the project or install it reproducibly from an explicit dependency source. Do not globally ignore project dependencies.

## 0.6 Phase F: clean-room scan before Android validation

Before calling the starter ready, search the entire new baseline for residue from the previous game:

```text
previous game name
previous Android package ID
previous save filenames
previous URLs
previous store/service IDs
previous asset paths
previous balance/content identifiers
```

Every remaining match must be intentionally reusable or removed.

The clean starter must boot without any previous-game content.

## 0.7 Phase G: validate signed Bootstrap / Checkpoint 0 on Android

Before the first gameplay mechanic begins:

1. open the starter in the intended Godot version;
2. resolve every parser/import/missing-resource error;
3. run the bootstrap probe for core autoloads/helpers;
4. verify orientation, reference resolution, stretch and safe-area behavior;
5. export a **release-signed Bootstrap APK** using the new game's upload key;
6. install that exact APK on the physical target device;
7. launch it and verify app name, package ID, orientation, touch/input, safe area and displayed integer change version;
8. if replacing an earlier build of the same package, verify the same signing identity allows a normal update/install-over flow;
9. preserve the ADB install path/command as the fallback deployment method;
10. commit or archive a **fresh full-project Bootstrap / Checkpoint 0 baseline**;
11. only then begin Checkpoint 1 and implement the GDD's first playable loop.

The Play Store artifact can later be exported as a release-signed AAB from the same signing identity. The APK is the practical physical-device bootstrap validation artifact.

This makes future game setup deterministic:

```text
approved GDD
+ validated previous production project
+ reusable Playbook
+ new game identity/config inputs
-> automated clean starter
-> dedicated upload keystore/signing identity
-> Android dependencies/templates
-> signed APK on physical device
-> Bootstrap / Checkpoint 0
-> GDD implementation / first playable loop
```

Reusable rule:

> Reuse proven infrastructure, establish signing early, validate the Android artifact before gameplay implementation, and never carry previous-game identity by accident.


<!-- EMBEDDED_STARTER_TEMPLATE_START -->
## 0.8 Embedded canonical Godot Android starter template
The reusable starter lives **inside this Playbook**. A future ChatGPT/Claude/repository-aware agent should reconstruct these files directly into a new repository, then apply the new game's identity/configuration inputs. No second bootstrap document is required.
The embedded template is a clean infrastructure baseline, not an Everfort clone. It intentionally excludes gameplay, art, balance, previous package identity, store identity, service IDs, and signing credentials.
### Canonical starter tree

```text
Godot_Android_Starter/
  .editorconfig
  .gitattributes
  .gitignore
  bootstrap_manifest.json
  project.godot
  export_presets.cfg
  icon.svg
  scenes/main.tscn
  scripts/main.gd
  scripts/autoload/layout_service.gd
  scripts/autoload/number_format.gd
  scripts/autoload/settings_state.gd
  scripts/autoload/audio_service.gd
  scripts/autoload/save_service.gd
  tests/bootstrap_probe.gd
  tests/bootstrap_probe.tscn
  tools/bootstrap_new_game.py
```
### Bootstrap contract

A new project should be created from these embedded files, then configured with the new game's:

- application name;
- Android package ID, generated from the fixed `com.shekinahwelefuldesigns.<normalized_game_name>` convention;
- integer change version;
- Android version code;
- orientation/reference resolution;
- network permission only when actually required;
- new icons/branding;
- release signing;
- service/store IDs and URLs only when supplied for the new game.

The repository-aware agent must still compare the previous validated production project against this embedded baseline and carry forward newer **proven cross-game infrastructure** when appropriate. The embedded starter is the minimum canonical baseline, not a reason to ignore a newer validated improvement.
### Embedded files

#### `.editorconfig`

````ini
root = true

[*]
charset = utf-8
````

#### `.gitattributes`

````text
# Normalize EOL for text files.
* text=auto eol=lf
````

#### `.gitignore`

````text
# Godot-generated caches (keep authored .gdignore files and *.gd.uid files tracked)
/.godot/

# Generated Android Gradle workspace and export artifacts
# If you customize Android template/plugin code, preserve it in a reproducible
# source/patch/install process instead of relying on this ignored workspace.
/android/
/builds/
*.apk
*.aab
*.pck

# Generated marketing assets and raw recordings
# KEEP /marketing/ (scenario adapters, manifests and approved source copy).
/store_assets/
/recordings/

# Temporary marketing capture override, never a committed project setting
/override.cfg

# Test scratch files and Python tooling caches
/tests/tmp/
__pycache__/
*.py[cod]
.pytest_cache/
.mypy_cache/
.ruff_cache/
.coverage
htmlcov/
.venv/
venv/

# Signing materials and local environment secrets: NEVER commit these
*.keystore
*.jks
*.p12
*.pfx
.env
.env.*
!.env.example

# Local archives and temporary files
/*.zip
/*.7z
/*.rar
*.tmp
*.swp
*.swo
*~

# OS/editor metadata
.DS_Store
Thumbs.db
Desktop.ini
.idea/

# DO NOT ignore /addons/, /Godot-Marketing-Toolkit/, /marketing/,
# docs, source assets, .gdignore, *.gd.uid, marketing_capture_toolkit.lock.json,
# or approved toolkit fonts/licenses. They are required for reproducible builds.
````

#### `bootstrap_manifest.json`

````json
{
  "derived_from": "validated production baseline",
  "godot_reference": "4.7 Mobile",
  "defaults": {
    "reference_resolution": [
      1920,
      1080
    ],
    "stretch_mode": "canvas_items",
    "stretch_aspect": "expand",
    "orientation": "landscape",
    "renderer": "mobile / gl_compatibility",
    "android_export": "AAB",
    "android_architecture": [
      "arm64-v8a"
    ],
    "android_immersive_mode": true,
    "android_edge_to_edge": false,
    "android_user_data_backup": false,
    "version_name_source": "application/config/version via blank Android version/name",
    "android_package_prefix": "com.shekinahwelefuldesigns",
    "android_package_rule": "prefix + normalized lowercase game name"
  },
  "included_reusable_services": [
    "LayoutService",
    "NumberFormat",
    "SettingsState",
    "AudioService",
    "SaveService"
  ],
  "must_replace_per_game": [
    "application name",
    "integer change version",
    "Android version code",
    "orientation/reference resolution if different",
    "icons/branding",
    "release signing",
    "store/service IDs",
    "permissions",
    "privacy/community URLs",
    "game-specific save state"
  ],
  "intentionally_excluded": [
    "previous-game gameplay assets",
    "previous-game UI theme",
    "Balance/Profile/Run/Mission/Prestige/Encyclopedia state",
    "previous-game package ID",
    "previous-game launcher icons",
    "previous-game build path/version code",
    "game-specific scenes/content"
  ]
}
````

#### `project.godot`

````ini
; Reusable Android-first Godot starter derived from a validated production project.
; Run tools/bootstrap_new_game.py once before beginning game-specific implementation.

config_version=5

[application]

config/name="New Game"
config/version="0.1.0"
run/main_scene="res://scenes/main.tscn"
config/features=PackedStringArray("4.7", "Mobile")
config/icon="res://icon.svg"

[autoload]

LayoutService="*res://scripts/autoload/layout_service.gd"
NumberFormat="*res://scripts/autoload/number_format.gd"
SettingsState="*res://scripts/autoload/settings_state.gd"
AudioService="*res://scripts/autoload/audio_service.gd"
SaveService="*res://scripts/autoload/save_service.gd"

[display]

window/size/viewport_width=1920
window/size/viewport_height=1080
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"
window/handheld/orientation="landscape"

[input_devices]

pointing/emulate_touch_from_mouse=true

[rendering]

renderer/rendering_method="mobile"
renderer/rendering_method.mobile="gl_compatibility"
textures/vram_compression/import_etc2_astc=true
````

#### `export_presets.cfg`

````ini
[runnable_presets]

Android="Android"

[preset.0]

name="Android"
platform="Android"
dedicated_server=false
custom_features=""
export_filter="all_resources"
include_filter=""
exclude_filter=""
export_path="builds/NewGame.0.1.0.aab"
patches=PackedStringArray()
encrypt_pck=false
encrypt_directory=false
script_export_mode=2

[preset.0.options]

gradle_build/use_gradle_build=true
gradle_build/export_format=1
architectures/armeabi-v7a=false
architectures/arm64-v8a=true
architectures/x86=false
architectures/x86_64=false
version/code=1
version/name=""
package/unique_name="com.shekinahwelefuldesigns.newgame"
package/name="New Game"
package/signed=false
package/app_category=2
screen/immersive_mode=true
screen/edge_to_edge=false
screen/support_small=true
screen/support_normal=true
screen/support_large=true
screen/support_xlarge=true
user_data_backup/allow=false
permissions/internet=false
````

#### `icon.svg`

````xml
<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128"><rect width="124" height="124" x="2" y="2" fill="#363d52" stroke="#212532" stroke-width="4" rx="14"/><g fill="#fff" transform="translate(12.322 12.322)scale(.101)"><path d="M105 673v33q407 354 814 0v-33z"/><path fill="#478cbf" d="m105 673 152 14q12 1 15 14l4 67 132 10 8-61q2-11 15-15h162q13 4 15 15l8 61 132-10 4-67q3-13 15-14l152-14V427q30-39 56-81-35-59-83-108-43 20-82 47-40-37-88-64 7-51 8-102-59-28-123-42-26 43-46 89-49-7-98 0-20-46-46-89-64 14-123 42 1 51 8 102-48 27-88 64-39-27-82-47-48 49-83 108 26 42 56 81zm0 33v39c0 276 813 276 814 0v-39l-134 12-5 69q-2 10-14 13l-162 11q-12 0-16-11l-10-65H446l-10 65q-4 11-16 11l-162-11q-12-3-14-13l-5-69z"/><path d="M483 600c0 34 58 34 58 0v-86c0-34-58-34-58 0z"/><circle cx="725" cy="526" r="90"/><circle cx="299" cy="526" r="90"/></g><g fill="#414042" transform="translate(12.322 12.322)scale(.101)"><circle cx="307" cy="532" r="60"/><circle cx="717" cy="532" r="60"/></g></svg>
````

#### `scenes/main.tscn`

````ini
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/main.gd" id="1_main"]

[node name="Main" type="Node"]
script = ExtResource("1_main")

[node name="UI" type="CanvasLayer" parent="."]

[node name="Background" type="ColorRect" parent="UI"]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
color = Color(0.09, 0.11, 0.15, 1)
mouse_filter = 2

[node name="Center" type="CenterContainer" parent="UI"]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0

[node name="Panel" type="PanelContainer" parent="UI/Center"]
custom_minimum_size = Vector2(760, 260)

[node name="Margin" type="MarginContainer" parent="UI/Center/Panel"]
theme_override_constants/margin_left = 48
theme_override_constants/margin_top = 36
theme_override_constants/margin_right = 48
theme_override_constants/margin_bottom = 36

[node name="VBox" type="VBoxContainer" parent="UI/Center/Panel/Margin"]
theme_override_constants/separation = 20

[node name="Title" type="Label" parent="UI/Center/Panel/Margin/VBox"]
theme_override_font_sizes/font_size = 42
text = "New Game"
horizontal_alignment = 1

[node name="Detail" type="Label" parent="UI/Center/Panel/Margin/VBox"]
theme_override_font_sizes/font_size = 24
text = "Starter project ready"
horizontal_alignment = 1
````

#### `scripts/main.gd`

````gdscript
extends Node

@onready var title_label: Label = $UI/Center/Panel/Margin/VBox/Title
@onready var detail_label: Label = $UI/Center/Panel/Margin/VBox/Detail


func _ready() -> void:
    var game_name := String(ProjectSettings.get_setting("application/config/name", "New Game"))
    var version := String(ProjectSettings.get_setting("application/config/version", "0.0.0"))
    title_label.text = game_name
    detail_label.text = "Starter project ready • Version %s\nReplace this scene with the first playable loop." % version
````

#### `scripts/autoload/layout_service.gd`

````gdscript
extends Node
## Shared reference-layout and safe-area helper for Android-first 2D projects.
## Keep gameplay/UI authored in one reference coordinate system, then let
## canvas_items + expand expose extra space on wider/taller devices.

const REFERENCE_SIZE := Vector2(1920.0, 1080.0)


func get_viewport_size() -> Vector2:
    var viewport := get_viewport()
    if viewport == null:
        return REFERENCE_SIZE
    return viewport.get_visible_rect().size


func get_center() -> Vector2:
    return get_viewport_size() * 0.5


func get_reference_center_offset() -> Vector2:
    return get_center() - (REFERENCE_SIZE * 0.5)


## Returns canvas-space safe insets as Vector4(left, top, right, bottom).
## Godot reports DisplayServer safe area in physical screen pixels, while
## Control offsets live in the stretched viewport coordinate system.
func get_safe_area_insets_canvas(extra_android_padding: float = 0.0) -> Vector4:
    var result := Vector4.ZERO
    if OS.get_name() != "Android":
        return result

    var safe_area: Rect2i = DisplayServer.get_display_safe_area()
    var screen_size: Vector2i = DisplayServer.screen_get_size(DisplayServer.SCREEN_OF_MAIN_WINDOW)
    var viewport_size: Vector2 = get_viewport_size()
    if screen_size.x <= 0 or screen_size.y <= 0 or viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
        return result
    if safe_area.size.x <= 0 or safe_area.size.y <= 0:
        return Vector4(extra_android_padding, extra_android_padding, extra_android_padding, extra_android_padding)

    var safe_right_px := maxi(0, screen_size.x - (safe_area.position.x + safe_area.size.x))
    var safe_bottom_px := maxi(0, screen_size.y - (safe_area.position.y + safe_area.size.y))
    var x_scale := viewport_size.x / float(screen_size.x)
    var y_scale := viewport_size.y / float(screen_size.y)

    result.x = float(maxi(0, safe_area.position.x)) * x_scale + extra_android_padding
    result.y = float(maxi(0, safe_area.position.y)) * y_scale + extra_android_padding
    result.z = float(safe_right_px) * x_scale + extra_android_padding
    result.w = float(safe_bottom_px) * y_scale + extra_android_padding
    return result
````

#### `scripts/autoload/number_format.gd`

````gdscript
extends Node
## Centralized player-facing numeric formatting. Keep formatting out of gameplay math.

const SUFFIXES: Array[Array] = [
    [1e63, "V"], [1e60, "Nd"], [1e57, "Od"], [1e54, "Sd"], [1e51, "sd"],
    [1e48, "Qd"], [1e45, "Qu"], [1e42, "Tr"], [1e39, "Du"], [1e36, "Un"],
    [1e33, "De"], [1e30, "No"], [1e27, "Oc"], [1e24, "Sp"], [1e21, "Sx"],
    [1e18, "Qi"], [1e15, "Qa"], [1e12, "T"], [1e9, "B"], [1e6, "M"], [1e3, "K"],
]


func _fmt_float(value: float, decimals: int) -> String:
    var fmt := "%." + str(decimals) + "f"
    return fmt % value


func number(value: float, decimals: int = 2) -> String:
    if is_nan(value) or is_inf(value):
        return "—"
    var sign_text := "-" if value < 0.0 else ""
    var magnitude := absf(value)
    if magnitude >= 1e66:
        var efmt := "%." + str(decimals) + "e"
        return sign_text + (efmt % magnitude)
    for entry in SUFFIXES:
        if magnitude >= entry[0]:
            return sign_text + _fmt_float(magnitude / float(entry[0]), decimals) + String(entry[1])
    return sign_text + _fmt_float(magnitude, decimals)


func count(value: float) -> String:
    return number(value, 0)


func percent(value_0_to_1: float, decimals: int = 2) -> String:
    if is_nan(value_0_to_1) or is_inf(value_0_to_1):
        return "—%"
    return _fmt_float(value_0_to_1 * 100.0, decimals) + "%"


func pair(current: float, max_value: float, decimals: int = 2) -> String:
    return "%s / %s" % [number(current, decimals), number(max_value, decimals)]


func signed_number(value: float, decimals: int = 2) -> String:
    var body := number(absf(value), decimals)
    return ("+" + body) if value >= 0.0 else ("-" + body)
````

#### `scripts/autoload/settings_state.gd`

````gdscript
extends Node
## Minimal cross-game player settings. Add game-specific preferences only when needed.

signal settings_changed()
signal game_speed_changed(new_speed: float)

var sfx_volume: float = 1.0
var music_volume: float = 1.0
var sfx_enabled: bool = true
var music_enabled: bool = true

## Optional but useful for incremental/idle projects. If the game has no speed
## control, simply leave this at 1.0 and do not expose a UI for it.
const MIN_GAME_SPEED: float = 1.0
const MAX_GAME_SPEED: float = 3.0
var selected_game_speed: float = 1.0


func reset_to_defaults() -> void:
    sfx_volume = 1.0
    music_volume = 1.0
    sfx_enabled = true
    music_enabled = true
    selected_game_speed = 1.0
    Engine.time_scale = 1.0
    settings_changed.emit()
    game_speed_changed.emit(selected_game_speed)


func set_sfx_volume(value: float) -> void:
    sfx_volume = clampf(value, 0.0, 1.0)
    settings_changed.emit()


func set_music_volume(value: float) -> void:
    music_volume = clampf(value, 0.0, 1.0)
    settings_changed.emit()


func set_sfx_enabled(value: bool) -> void:
    sfx_enabled = value
    settings_changed.emit()


func set_music_enabled(value: bool) -> void:
    music_enabled = value
    settings_changed.emit()


func set_game_speed(value: float) -> void:
    var clamped := clampf(value, MIN_GAME_SPEED, MAX_GAME_SPEED)
    var changed := not is_equal_approx(clamped, selected_game_speed)
    selected_game_speed = clamped
    Engine.time_scale = clamped
    if changed:
        settings_changed.emit()
        game_speed_changed.emit(clamped)


func to_save_dict() -> Dictionary:
    return {
        "sfx_volume": sfx_volume,
        "music_volume": music_volume,
        "sfx_enabled": sfx_enabled,
        "music_enabled": music_enabled,
        "selected_game_speed": selected_game_speed,
    }


func from_save_dict(data: Dictionary) -> void:
    sfx_volume = clampf(float(data.get("sfx_volume", 1.0)), 0.0, 1.0)
    music_volume = clampf(float(data.get("music_volume", 1.0)), 0.0, 1.0)
    sfx_enabled = bool(data.get("sfx_enabled", true))
    music_enabled = bool(data.get("music_enabled", true))
    set_game_speed(float(data.get("selected_game_speed", 1.0)))
    settings_changed.emit()
````

#### `scripts/autoload/audio_service.gd`

````gdscript
extends Node
## Sparse semantic-audio service. Register game-specific streams at startup;
## gameplay code then requests semantic event IDs instead of owning players.

const SFX_POOL_SIZE: int = 6
const SILENT_DB: float = -80.0

var _sfx_streams: Dictionary = {}
var _music_streams: Dictionary = {}
var _sfx_players: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer
var _current_music_track: String = ""


func _ready() -> void:
    for i in range(SFX_POOL_SIZE):
        var player := AudioStreamPlayer.new()
        add_child(player)
        _sfx_players.append(player)
    _music_player = AudioStreamPlayer.new()
    add_child(_music_player)
    _music_player.finished.connect(_on_music_finished)
    SettingsState.settings_changed.connect(_on_settings_changed)


func register_sfx(event_id: String, stream: AudioStream) -> void:
    _sfx_streams[event_id] = stream


func register_music(track_id: String, stream: AudioStream) -> void:
    _music_streams[track_id] = stream


func play_sfx(event_id: String) -> void:
    if not SettingsState.sfx_enabled:
        return
    var stream: AudioStream = _sfx_streams.get(event_id)
    if stream == null:
        return
    var player := _next_free_sfx_player()
    player.stream = stream
    player.volume_db = _volume_to_db(SettingsState.sfx_volume)
    player.play()


func play_music(track_id: String) -> void:
    _current_music_track = track_id
    var stream: AudioStream = _music_streams.get(track_id)
    if stream == null:
        _music_player.stop()
        return
    if _music_player.stream != stream:
        _music_player.stream = stream
    _apply_music_volume()
    if SettingsState.music_enabled and not _music_player.playing:
        _music_player.play()


func stop_music() -> void:
    _current_music_track = ""
    _music_player.stop()


func _next_free_sfx_player() -> AudioStreamPlayer:
    for player in _sfx_players:
        if not player.playing:
            return player
    return _sfx_players[0]


func _on_music_finished() -> void:
    if _current_music_track == "" or not SettingsState.music_enabled:
        return
    var stream: AudioStream = _music_streams.get(_current_music_track)
    if stream == null:
        return
    _music_player.stream = stream
    _apply_music_volume()
    _music_player.play()


func _on_settings_changed() -> void:
    _apply_music_volume()
    if not SettingsState.music_enabled:
        _music_player.stop()
    elif _current_music_track != "" and _music_streams.get(_current_music_track) != null and not _music_player.playing:
        _music_player.play()
    for player in _sfx_players:
        if not SettingsState.sfx_enabled:
            player.stop()
        else:
            player.volume_db = _volume_to_db(SettingsState.sfx_volume)


func _apply_music_volume() -> void:
    var enabled := SettingsState.music_enabled and SettingsState.music_volume > 0.0
    _music_player.volume_db = _volume_to_db(SettingsState.music_volume) if enabled else SILENT_DB


func _volume_to_db(value: float) -> float:
    return linear_to_db(value) if value > 0.0 else SILENT_DB
````

#### `scripts/autoload/save_service.gd`

````gdscript
extends Node
## Generic versioned JSON persistence with throttled dirty saves and provider
## registration. Settings are built in; game-specific state registers sections.

signal saved()

const SAVE_VERSION: int = 1
const SAVE_PATH: String = "user://save.json"
const PERIODIC_SAVE_INTERVAL: float = 120.0
const DIRTY_SAVE_INTERVAL: float = 5.0

var _providers: Dictionary = {}
var _loaded_sections: Dictionary = {}
var _dirty: bool = false
var _periodic_timer: Timer
var _dirty_timer: Timer


func _ready() -> void:
    load_and_apply()
    SettingsState.settings_changed.connect(mark_dirty)

    _periodic_timer = Timer.new()
    _periodic_timer.wait_time = PERIODIC_SAVE_INTERVAL
    _periodic_timer.autostart = true
    _periodic_timer.timeout.connect(save_now)
    add_child(_periodic_timer)

    _dirty_timer = Timer.new()
    _dirty_timer.wait_time = DIRTY_SAVE_INTERVAL
    _dirty_timer.autostart = true
    _dirty_timer.timeout.connect(_flush_dirty)
    add_child(_dirty_timer)


## Register a game-specific persistent section. Register early in the owning
## autoload's _ready(); if save data was loaded before registration, it is
## applied immediately through load_callable.
func register_section(
        section_key: String,
        save_callable: Callable,
        load_callable: Callable,
        reset_callable: Callable = Callable()
    ) -> void:
    _providers[section_key] = {
        "save": save_callable,
        "load": load_callable,
        "reset": reset_callable,
    }
    if _loaded_sections.has(section_key) and load_callable.is_valid():
        load_callable.call(_loaded_sections[section_key])


func mark_dirty() -> void:
    _dirty = true


func _flush_dirty() -> void:
    if _dirty:
        save_now()


func _notification(what: int) -> void:
    match what:
        NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT:
            save_now()


func save_now() -> void:
    var sections: Dictionary = {}
    for key in _providers.keys():
        var save_callable: Callable = _providers[key]["save"]
        if save_callable.is_valid():
            sections[key] = save_callable.call()

    var data := {
        "version": SAVE_VERSION,
        "last_seen_unix": int(Time.get_unix_time_from_system()),
        "settings": SettingsState.to_save_dict(),
        "sections": sections,
    }

    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        push_warning("SaveService: could not open save file for writing (%s)" % error_string(FileAccess.get_open_error()))
        return
    file.store_string(JSON.stringify(data))
    file.close()
    _dirty = false
    saved.emit()


func load_and_apply() -> void:
    _loaded_sections = {}
    if not FileAccess.file_exists(SAVE_PATH):
        SettingsState.reset_to_defaults()
        return

    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        SettingsState.reset_to_defaults()
        return
    var parsed = JSON.parse_string(file.get_as_text())
    file.close()

    if not (parsed is Dictionary) or int(parsed.get("version", -1)) != SAVE_VERSION:
        SettingsState.reset_to_defaults()
        return

    SettingsState.from_save_dict(parsed.get("settings", {}))
    _loaded_sections = parsed.get("sections", {}).duplicate(true)
    for key in _providers.keys():
        if not _loaded_sections.has(key):
            continue
        var load_callable: Callable = _providers[key]["load"]
        if load_callable.is_valid():
            load_callable.call(_loaded_sections[key])


func hard_reset() -> void:
    if FileAccess.file_exists(SAVE_PATH):
        DirAccess.remove_absolute(SAVE_PATH)
    SettingsState.reset_to_defaults()
    _loaded_sections = {}
    for key in _providers.keys():
        var reset_callable: Callable = _providers[key]["reset"]
        if reset_callable.is_valid():
            reset_callable.call()
    _dirty = false
````

#### `tests/bootstrap_probe.gd`

````gdscript
extends Node


func _ready() -> void:
    var failures: Array[String] = []
    if String(ProjectSettings.get_setting("application/config/version", "")) == "":
        failures.append("application/config/version is empty")
    if NumberFormat.number(1250.0, 2) != "1.25K":
        failures.append("NumberFormat basic abbreviation failed")
    if LayoutService.get_viewport_size().x <= 0.0:
        failures.append("LayoutService viewport size invalid")
    if SettingsState.selected_game_speed < 1.0:
        failures.append("SettingsState default game speed invalid")

    if failures.is_empty():
        print("BOOTSTRAP_PROBE PASS")
        get_tree().quit(0)
    else:
        for failure in failures:
            push_error("BOOTSTRAP_PROBE: " + failure)
        get_tree().quit(1)
````

#### `tests/bootstrap_probe.tscn`

````ini
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://tests/bootstrap_probe.gd" id="1_probe"]

[node name="BootstrapProbe" type="Node"]
script = ExtResource("1_probe")
````

#### `tools/bootstrap_new_game.py`

````python
#!/usr/bin/env python3
from pathlib import Path
import argparse
import re


def slugify(name: str) -> str:
    value = re.sub(r"[^A-Za-z0-9]+", "", name)
    return value or "NewGame"


def replace_setting(text: str, key: str, value: str) -> str:
    pattern = rf'(?m)^{re.escape(key)}=.*$'
    replacement = f'{key}={value}'
    new_text, count = re.subn(pattern, replacement, text)
    if count != 1:
        raise RuntimeError(f"Expected exactly one setting for {key}, found {count}")
    return new_text


def main() -> None:
    parser = argparse.ArgumentParser(description="Configure the reusable Godot starter for a new game.")
    parser.add_argument("--name", required=True, help="Player-facing game name")
    parser.add_argument("--version", default="0.1.0")
    parser.add_argument("--version-code", type=int, default=1)
    parser.add_argument("--orientation", choices=["landscape", "portrait"], default="landscape")
    parser.add_argument("--width", type=int)
    parser.add_argument("--height", type=int)
    parser.add_argument("--internet", action="store_true", help="Enable Android INTERNET permission")
    args = parser.parse_args()

    project_root = Path(__file__).resolve().parents[1]
    project_path = project_root / "project.godot"
    export_path = project_root / "export_presets.cfg"

    width = args.width or (1920 if args.orientation == "landscape" else 1080)
    height = args.height or (1080 if args.orientation == "landscape" else 1920)
    slug = slugify(args.name)
    package_id = f"com.shekinahwelefuldesigns.{slug.lower()}"

    project = project_path.read_text(encoding="utf-8")
    project = replace_setting(project, 'config/name', f'"{args.name}"')
    project = replace_setting(project, 'config/version', f'"{args.version}"')
    project = replace_setting(project, 'window/size/viewport_width', str(width))
    project = replace_setting(project, 'window/size/viewport_height', str(height))
    project = replace_setting(project, 'window/handheld/orientation', f'"{args.orientation}"')
    project_path.write_text(project, encoding="utf-8")

    preset = export_path.read_text(encoding="utf-8")
    preset = replace_setting(preset, 'export_path', f'"builds/{slug}.{args.version}.aab"')
    preset = replace_setting(preset, 'version/code', str(args.version_code))
    preset = replace_setting(preset, 'version/name', '""')
    preset = replace_setting(preset, 'package/unique_name', f'"{package_id}"')
    preset = replace_setting(preset, 'package/name', f'"{args.name}"')
    preset = replace_setting(preset, 'permissions/internet', 'true' if args.internet else 'false')
    export_path.write_text(preset, encoding="utf-8")

    print("Configured starter project:")
    print(f"  Name:         {args.name}")
    print(f"  Package:      {package_id}")
    print(f"  Version:      {args.version}")
    print(f"  Version code: {args.version_code}")
    print(f"  Orientation:  {args.orientation} ({width}x{height})")
    print(f"  Internet:     {'enabled' if args.internet else 'disabled'}")
    print("\nStill intentionally per-game: icons, release signing/keystore, store listing/pricing, privacy disclosures, and game-specific permissions. No AdMob, IAP, Analytics or Crashlytics.")


if __name__ == "__main__":
    main()
````

### Reconstruction and validation procedure

1. Finish and approve the game-specific GDD before gameplay implementation.
2. Create the directory tree exactly as listed above.
3. Write the embedded file contents verbatim as the initial baseline.
4. Run `tools/bootstrap_new_game.py` with the new identity/configuration values, or let the repository-aware agent apply the same transformations directly.
5. Replace placeholder identity/branding fields that must be unique to the new game.
6. Create the game's dedicated Android upload keystore using the Phase C procedure above.
7. Configure the Android export preset to use that upload keystore/alias without committing credentials.
8. Install/verify the JDK, Android SDK, matching Godot export templates and Android Build Template required by the project's export mode.
9. Add only the permissions/services/dependencies the new game actually uses.
10. Open the project in the intended Godot version and resolve parser/import errors.
11. Run `res://tests/bootstrap_probe.tscn`.
12. Export a release-signed Bootstrap APK, install that exact APK on the physical Android target, and verify orientation, safe area, touch/input, package identity, version display, signing and startup.
13. Commit/archive the resulting clean repository as **Bootstrap / Checkpoint 0**.
14. Begin Checkpoint 1 gameplay implementation from the approved GDD.

The main purpose of this section is that **this one reusable file is enough to instruct an agent to build the starter project**. Do not maintain a second reusable bootstrap guide that can drift from this Playbook.
<!-- EMBEDDED_STARTER_TEMPLATE_END -->

## 0.9 Universal production lifecycle — 19 approved stages

**This is the canonical game-independent production roadmap.** Keep the existing engineering checkpoints (section 2) as intermediate delivery gates. The GDD determines which optional mechanics exist; neither campaign/Prestige nor offline income, automation, armies, workers or any other genre mechanic is a universal requirement. The stages are production milestones, **not** an instruction to delay UI, localization, testing or asset work until their named stage.

| # | Production stage | Relation to existing checkpoints |
|---:|---|---|
| 1 | Game Concept & GDD Definition | Approve game-specific design before code. |
| 2 | Godot Project Bootstrap & Android Validation | Bootstrap / Checkpoint 0. |
| 3 | Core Gameplay — First Playable | Checkpoint 1. |
| 4 | Gameplay Variety & Mechanics | Checkpoint 2. |
| 5 | Restart, Debug & Development Tools | Checkpoint 3; reset and debug appropriate to the game. |
| 6 | Progression & Unlock Systems (If Applicable) | Checkpoint 4; only GDD-defined systems. |
| 7 | Save, Load, Resume & Offline Systems (If Applicable) | Checkpoint 5; persistence as required, offline **simulation/rewards only** if designed. |
| 8 | Game Objectives, Completion & Replayability | Checkpoint 6; a GDD-defined ending, outcome or ongoing play contract, **not mandatory Prestige**. |
| 9 | Secondary Systems & Content Expansion | Checkpoint 7+ where applicable. |
| 10 | UI/UX Implementation & Player Onboarding | Consolidate UI and teaching after incremental implementation. |
| 11 | Visual Assets, Animations, Effects & Audio | Finish production presentation; start necessary assets earlier. |
| 12 | Full Feature & Content Completion | GDD scope freeze. |
| 13 | UI/UX Refinement & Android Device Validation | Physical device readability and interaction acceptance before long balance QA. |
| 14 | Gameplay Balancing & Full Playthrough Testing | No remaining progression/softlock blockers. |
| 15 | Performance Optimization & Stability Testing | Profile and verify target devices. |
| 16 | Google Play Store Preparation & Marketing Assets | ASO, policy-reviewed English store copy, gameplay screenshots (every device class), video, feature graphic, localizations, a set of 10 short-form social videos (5 focused + 5 full-landscape) from approved footage, per-video posting copy, and localized Play release notes when applicable; see 87, 133 and 134. |
| 17 | Release Candidate & Final Android Validation | Test exact release artifact; section 88. |
| 18 | Google Play Publishing | Configure one-time price, store compliance and submit. |
| 19 | Post-Launch Support, Updates & Improvements | Fix issues using the developer's chosen support process; no player/crash telemetry. |

**Continuous during all stages:** native localization infrastructure and an up-to-date English reference catalog (other 19 translations deliberately deferred until localization freeze; section 132), focused tests/Android checks, save/reset correctness, GDD/decision-log maintenance, version control and validated reusable lessons (44, 108). Claude may commit approved, validated implementation batches. Final creative, storefront and release decisions require human approval. A phase may overlap another when practical; never use the roadmap to postpone cross-cutting quality requirements.

## 0.10 Standard business model and prohibited integrations

All games developed under this playbook are **paid once through Google Play**, with **no ads, no in-app purchases and no subscriptions**. Google Play handles the initial storefront purchase; do not add Google Play Billing for IAPs. **Do not integrate AdMob, Firebase Analytics, Firebase Crashlytics, other player-tracking/telemetry SDKs or remote crash-monitoring services.** Do not introduce a separate platform-services/monetization stage. Ordinary local debugging, on-device tests, engine logs and developer-directed troubleshooting remain allowed; there is no ongoing analytics/crash-monitoring obligation.

At publishing time, set the paid price and required Play Console declarations (including Data safety and any applicable privacy policy or permissions) accurately; do not interpret "no tracking SDK" as automatic exemption from store compliance. Networking for a genuine gameplay feature would require an explicit game-specific decision; it must not be introduced for monetization or tracking.

## 0.11 Cross-phase localization policy

**Build localization infrastructure from the first player-facing UI, but translate only English during feature development.** Claude owns Godot `TranslationServer`, semantic keys, the continuously updated English source catalog, the Settings language selector, layout/font readiness and localization integration tests. All 20 languages are visible in Settings, but the 19 not-yet-installed translations are **disabled, not hidden**. Until the complete translation release is validated and enabled, **Automatic explicitly resolves to English**, regardless of the device locale; manual English works normally, while choosing an unavailable locale is blocked.

At the **localization freeze** (after the intended UI and English strings are stable), ChatGPT generates and structurally checks the 19 non-English catalogs from the final English catalog; the human developer copies them into the Godot project. Claude then imports, tests, fixes and enables them **in strict batches of four or five languages** (normally 5 + 5 + 5 + 4); Claude may fix **any** issue it finds, including translation wording, without sending changes back to ChatGPT. A batch must be checked and reported before the next batch. After all 19 pass, enable their Settings entries and device-language detection for Automatic. Launch still requires **all 20 complete and verified**. Section 132 is the authoritative detailed process.

Use a lightweight English-key completeness/integrity check during development; do not require a costly bespoke validator when a small existing test suffices. Allow targeted pseudolocalization for text-expansion testing. Never assume a translation is reviewed merely because a catalog parses.

---

# 1. Start with a deliberately small game

A successful small premium game should have a simple core loop that can be understood in seconds.

Everfort worked because its first loop was:

```text
Enemies approach
-> Castle attacks
-> enemies drop Gold
-> player collects Gold
-> player buys temporary upgrades
-> Castle eventually dies
-> run restarts
-> player earns permanent progression
```

That loop was playable before:

- Prestige;
- Missions;
- Bestiary;
- Towers;
- Sheep;
- Mining;
- Workers;
- Offline rewards;
- automation.

For future games:

> Build one satisfying 30–90 second loop before creating meta systems.

If the base interaction is not fun or clear, progression systems will only hide the problem.

---

# 2. Build in checkpoints

Use explicit checkpoints with a playable result after each one. These are the **engineering gates inside the 19-stage production lifecycle** (section 0.9), not a second competing roadmap. A checkpoint is omitted or adapted when its example mechanic is absent from the game's GDD.

A good generic order:

## Checkpoint 1 — Core interaction

Examples:

- basic player/base;
- one enemy;
- damage;
- win/lose state;
- resource pickup;
- one upgrade.

## Checkpoint 2 — Variety

Add:

- additional enemy archetypes;
- ranged/support/tank roles;
- difficulty scaling.

## Checkpoint 3 — Restart and debug

Before more content:

- robust new-run reset;
- debug currency;
- jump-to-stage;
- save now;
- clean timers/spawns.

## Checkpoint 4 — Progression / meta systems (when the GDD requires them)

Examples:

- missions;
- encyclopedia/bestiary;
- unlocks;
- progression UI.

## Checkpoint 5 — Save/resume/offline

Implement the game's required persistence and lifecycle behavior before the game becomes too complex. Offline **progression/rewards** are optional, not a universal requirement.

## Checkpoint 6 — Objectives, completion or replayability

Establish the GDD-defined player goal and what happens after success/failure; campaigns and Prestige are examples, not mandatory mechanics. Endless games can define an ongoing-play contract instead of a formal ending.

## Checkpoint 7+ — Secondary loops and content

Only after the core game is stable. Automation, campaigns, complex systems and meta layers are included **only** when designed for this game.

This ordering prevents permanent systems from being built on unstable run-state behavior.

---

# 3. Give each progression layer one job

Most of these games stack several progression layers. Each layer needs a distinct role the player can name, or the layers blur into one long list of percentages and the rarest choices fill up with chores.

## 3.1 The layers and their roles

| Layer | Resets | Its job | Typical content |
|---|---|---|---|
| **Run** | every run | make the current run feel increasingly powerful | run upgrades, building tiers bought with run resources, research |
| **Permanent** | only at Prestige (or never, if the game has no deeper reset) | steady account capability: scaling, convenience, infrastructure; the things most players are expected eventually to want | stat percentages, economy rates, capacities (slots, saved setups, queue sizes), starting resources, Salvage, offline rate |
| **Prestige** | only at a deeper layer (if any) | rarer strategic choices: meaningful unlocks, specialization and build identity | new buildings, units and systems, automation tiers, access to higher building tiers, large multipliers chosen over alternatives |
| **Ascension** (meta-meta, endgame) | rarely or never | rules or starting-state advantages strong enough to sit above Prestige | a stronger starting kingdom, rule changes, a stacking endgame currency |

Players should be able to say in one line what each currency is for. Everfort: "Gold = this run; Skill Points = permanent; Prestige = rare build-defining choices." Growing Kingdom: "Wood, Gold and Food = this kingdom; Glory = permanent upgrades; a Prestige card = a new capability; an Ascension Decree = a new starting kingdom."

**Name the layers, not just the currencies.** Once two or more layers are all "upgrades", give each one player-facing name that says its scope, keep it in one constant, and use it wherever two layers could be confused; keep the reset event's name apart from what it grants. Growing Kingdom v0.20: **Kingdom Upgrades** (resources, this kingdom), **Glory Upgrades** (Glory, until the next Prestige), **Prestige Upgrades** (the cards owned, kept), with "Prestige" left for the conquest and reset. Teach the names once side by side (the help deck's last card), not on every screen, and let a reward that boosts a currency say what that currency buys ("+50% Glory from enemies. Glory buys Glory Upgrades that last until your next Prestige."). Ordinary verbs ("Upgrade Castle") stay: the rule names layers, it does not ban the word.

## 3.2 Which layer does a reward belong to?

Ask, in order:

```text
Will nearly every player want it eventually, and is it a number or a capacity?   -> Permanent
Does it change what the player can do, or define a build the player chooses?    -> Prestige
Does it change the starting state or a rule at a scale that would trivialize
the Prestige layer if it sat there?                                            -> Ascension
```

A random draft (Prestige offers) is the wrong home for universally wanted utility: when a card every player needs competes with build-defining cards, the player is taxed for the draft instead of choosing. Keep the draft for choices that are interesting to decline.

Growing Kingdom's moves (each approved by the developer in a brief and implemented):

- **Down, Prestige to Permanent:** active Deployment Slots (Expanded Command) and extra Salvage (Recovery Doctrine). Both are capacities nearly every player eventually wants (more cards in play, more value back after a defeat), the kind of universally wanted utility the draft should not hold.
- **Into Prestige:** building Tier II and III. A run-level multiplier let a skilled first run go far beyond the intended pacing; gating the whole axis made the multiplier something earned (section 3.4).
- **Up, Permanent to Ascension:** a higher starting Castle tier. As a permanent upgrade it bypassed the new Prestige tier gate; in Ascension it improves the starting state of a player who has already unlocked that tier.

When a reward moves between layers, change its tables and copy in the same pass and audit what depended on it (section 99). What happens to profiles that owned it depends on the development phase (section 61): before release, change the tables and let development profiles reset if that is simpler; after release, migrate with the rules in section 61.3.

## 3.3 A higher layer builds on the lower one

- **A higher layer's reward requires the lower-layer unlocks it builds on.** Give rewards an eligibility list checked when an offer is rolled, plus a clamp where the effect applies (for hand-made or older profiles). Growing Kingdom: the Ascension Decree that starts the Castle at Tier 2 is offered only after the Prestige card that opens Tier 2, and the Decree that trains units one tier higher never trains above the unlocked tier. Ascension improves the starting state; it never opens what Prestige has not.
- **A reward's eligibility reads only layers at least as durable as the reward.** A Prestige card kept forever must not be gated by something Prestige resets (a permanent upgrade, a run value): after every Prestige the condition fails again and the card can never be offered. Gate it by its Prestige prerequisites; when its use needs the reset layer, let it be owned but dormant with one clear reason ("Requires 2 Deployment Slots") and work again by itself once the condition holds. Growing Kingdom's Synchronized Deployment needed two slots to be offered; when slots became a permanent upgrade, an owned card sat idle and an unowned one could not appear (fixed in v0.11).
- **Review overlaps by effect, not by name.** Two rewards that both "speed the rebuild" may stack into double counting; probe them owned together.
- **Check the reset layer of what a reward depends on.** A reward kept by a deep reset should not depend on a capacity from a layer that resets more often, or it sits idle after every reset. Growing Kingdom's audit found this after slots moved down: Synchronized Deployment (a Prestige card, kept) needs two Deployment Slots, which now come from a permanent upgrade that every Prestige resets (an open design question there, not a validated rule yet).
- **Gate context-specific choices by content** (section 36), and exclude a card whose layer no longer has anything to give (Growing Kingdom offers its "+30% Renown" Decree only while a further Prestige exists).

## 3.4 Gate a whole upgrade axis with one cap

When a run-level multiplier lets runs go much further than intended, gating the axis behind the meta layer is often better than nerfing the unit: the unit stays good and the multiplier becomes something earned.

- **One cap function on the profile** (Growing Kingdom: `building_tier_cap()`, the highest tier whose unlock and every lower one are owned) and **one check in the action layer's block reason**, after the pause lock and the object's own state, before the cost. Every path that upgrades goes through it.
- **Apply it to every object on the axis** unless the design names an exception, and follow what hangs off it: things that require a tier (research levels, unit specials), missions that ask for the gated action (they must not be offered before it is possible), and effects that raise a tier on their own (a reward that promotes units must stop at the cap).
- **Say where the unlock comes from** in a line of the card's structure (it changes only with the meta layer, so it is not a warning) and name the unlock in the block reason.
- Re-run the pacing bot: Growing Kingdom's first-run bot lasted slightly longer without tiers, because its upgrades had not paid back within one run.

## 3.5 Progress toward the next Prestige

- **Start the meta layer at a milestone the player understands.** Growing Kingdom's Prestige began at the first real defeat (until its v0.18, when each Prestige became the conquest of a rival kingdom, below): a one-way profile flag set in one place (the run-end path every loss passes through), never by victories, debug jumps or reloads, cleared by Hard Reset. Before it, the meta currency does not accumulate and every screen says what unlocks it ("Prestige unlocks at your first defeat"); the defeat's receipt announces the unlock. Debug shortcuts go through the real rule (a "force defeat" runs the real defeat path).
- **When the number of Prestige picks is bounded, author the requirement table.** If the offers hold a known number of ranks in all, the requirement for each pick is a design decision, not a formula: author one entry per pick, end the meter at the last one ("Every Prestige has been taken"), make every screen read the same table, and let a probe check that the table length equals the ranks the offers hold. A bounded total is also worth showing: ranks owned out of the total ("7 / 33") beside the progress bar, with the bar as the way into a read-only list of what is owned (section 16.4). Short permanent-upgrade tracks benefit from authored price tables in the same way (section 92). Growing Kingdom replaced `150 × 1.6^k` with a 33-entry table when its offers held 33 ranks; the exact values are that game's.
- **Route every gain of the meta currency through one function** that applies its multipliers once (Growing Kingdom's Renown went through `grant_renown()`), so a later source cannot bypass a "+30% Renown" reward or apply it twice.
- **A meter can become an event.** When the meta layer is earned by an achievement rather than a currency (Growing Kingdom v0.18: one conquered rival kingdom = one Prestige, one authored rival per rank), the achievement is the requirement table: one authored challenge per pick, fixed, never scaled from the player's power. Resolve it in state and save before anything is shown (the conquest, the stopped waves and the rolled offer survive a crash during the celebration), and let every surface read one progress function ("Rival 8", "Ready", "Complete") instead of a bar that no longer fills. If the pick count is also the challenge count, derive one from the other on load (Prestige count = ranks owned), so a migration that removes a rank simply hands back a challenge to redo.
- **Randomized offers must not block critical progression indefinitely.** If a pick is essential (the first new building), guarantee it in every offer until it is actually chosen: Growing Kingdom put a random eligible building unlock in the Unlock slot of every offer until the player picked one. Derive the guarantee from owned state (no extra flag), and keep it inside the offer that is rolled and saved (section 53).
- **Narrow a guarantee once the pool is fair.** A guarantee repeated in every offer starts to crowd out the rest of the pool. Growing Kingdom v0.18 kept it for the first offer only and made the draw itself fair: each slot draws among its eligible cards the one offered least often so far (a saved per-card count, ties at random), so every card comes up before any comes up twice and nothing ineligible is ever offered. Then design the challenges so no card is required (below, and section 112.1).
- **Valuable random offers persist** from the moment they are rolled, so relaunching never rerolls them (section 53).
- **The reset boundary is a table** of what a Prestige keeps and resets, enforced by a probe (section 110), and the confirmation names every loss.

**Gate the first reset on run progression when side objectives can finish early** (LootFarmer Change 6). Opportunities that complete in minutes (a mission chain, an easy challenge, a long offline absence) made a reset available at 15 minutes. Keep discovery and readiness early, but require a run milestone (clear the first season) before any redemption, state it in the prestige panel, and measure the fastest route with a bot rather than inspecting the catalog.

Reusable rule:

> Give every layer one job the player can name, put universally wanted utility in the steady layer and choices in the draft, let a higher layer build on the lower one without bypassing it, and author bounded progressions as tables.

---

# 4. Make the campaign structure deterministic

Everfort benefited from using absolute stage rather than prestige count to define enemy composition.

Recommended pattern:

```text
absolute progression index -> content pool
meta unlock -> how far player may travel
```

This avoids the problem where replaying Stage 20 after several Prestiges unexpectedly creates a completely different Stage 20.

Benefits:

- easier balancing;
- easier debugging;
- easier player learning;
- older stages naturally become easier.

For any level/stage game:

> progression gates should unlock content; they should not silently redefine old content unless that is a deliberate mechanic.

A wave flow of "all enemies defeated -> next wave" has an exploit built in: leave one harmless enemy alive and the next wave never comes, so the economy grows for free. Growing Kingdom gives each wave a resolution clock that starts only after its **last scheduled spawn** (so long authored sequences are never cut short), in simulated time (game speed scales it, the pause stops it, a save keeps it). When it runs out with enemies alive, the next countdown starts and the survivors fight on into the next wave. Keep three moments apart instead of overloading one flag: spawning completed, pressure advanced, actually cleared. Only the clear pays (its sound, its message, its counter, its milestones), and anything that waits for "no enemies" (an attack launch, repairs) keeps waiting for the survivors. Deliberate gates (a tutorial hold) stay above the clock.

> One harmless survivor must not become an unlimited economy stall.

**Appending authored content must not move what exists.** When a generated content table gains an entry past its end (Growing Kingdom's final rival after 33 authored ones), every curve the generator spreads over "the number of entries" (a cadence interpolated from first to last) silently changes the earlier entries. Keep such curves on a fixed authored span, extend only the new entry past it, and prove it: diff the old and new data for the existing range (byte-identical), and scope any fingerprint probe (sums of caps, timings) to that fixed range, with the new entry checked on its own.

---

# 5. Introduce archetypes one at a time

A strong enemy roster does not require dozens of enemies.

Everfort uses a small functional set:

- melee/basic;
- ranged;
- tank;
- support/healer;
- Elite variants.

This is enough because each unit changes battlefield behavior.

For future games, prioritize **functional archetypes** over cosmetic variety.

A good enemy introduction cadence:

1. teach the basic unit;
2. introduce one new behavior;
3. give time to learn it;
4. introduce the next;
5. later combine them;
6. then add Elite variants.

Archetypes create pressure; they do not by themselves create army diversity. When one cheap player unit can answer every archetype by numbers, give some enemies traits that specialists answer better (soft counters, section 131).

---

# 6. Use stage scaling and base stats separately

Keep base archetype values and stage scaling independent.

Conceptually:

```text
effective_stat = base_stat × progression_multiplier
```

This lets you rebalance:

- “this archetype is too tanky” by changing base HP;
- “late game is too easy” by changing growth;
- “early game is too hard” without breaking endgame.

Avoid hardcoding per-stage enemy values.

---

# 7. Support units need percentage-aware scaling

When repeatable healing and consumable healing coexist, assign distinct roles: sustainable modest recovery versus larger immediate rescue. Compare effective healing across tiers, merges and maximum-health growth; test cooldown independence and missing-health clamping. Do not tune only the starting item pair or allow free healing to erase the consumable’s purpose.

A flat heal that works at Stage 30 may become meaningless at Stage 90.

A reusable approach:

```text
support_effect(stage) =
base_support_effect
× relative_progression_growth^support_factor
```

Where:

```text
0 < support_factor < 1
```

Everfort used roughly 75% of enemy-HP growth.

This keeps healing relevant without making enemy sustain scale as aggressively as enemy durability.

Use the same principle for:

- shields;
- buffs;
- slows;
- regen;
- summon health;
- damage-over-time.

Scaling decides how much one support action is worth. How often one target may receive it is a separate control: with several supporters, cadence alone lets them stack on one target (section 130.7).

---

# 8. Automation should be progression, not a settings toggle

Automation became one of the strongest parts of Everfort.

Examples:

- auto-collect;
- auto-restart;
- auto-targeting;
- auto-run-upgrades;
- auto-claim missions;
- miners;
- game speed.

The useful pattern:

```text
manual interaction
-> partial automation
-> faster automation
-> more automation capacity
```

Do not give everything automatically.

Let the player feel the improvement.

Example:

```text
Buy one upgrade every 30s
-> reduce timer
-> buy 2 different upgrades per cycle
-> buy 3 different upgrades per cycle
```

This makes automation itself a progression system.

## 8.1 Rules for layered automation

Growing Kingdom automates two halves of the game (Villager task priorities, and deployment of saved army cards through Auto Deployment, Deployment Sequences and Synchronized Deployment) and validated these rules:

- **Manual first, then automation as unlocks.** The player trains by tapping cards and assigns workers by hand before any automation exists. Each automation tier is a separate unlock with prerequisites (a sequence needs basic auto-deploy; synchronized groups need sequences, and two active slots to be used, section 3.3), so the player meets each layer when the previous one is understood.
- **Automate the player's own configuration, not hardcoded content.** Automation addresses player-defined objects (deployment slots, priority places), so any future card or task joins without new automation code.
- **The program is saved data, run deterministically.** A program is a list of steps (which slots, the delay after the step, repeat or not), saved with the profile; the runtime cursor and timers belong to the run. The same state always produces the same next action, which keeps save/resume exact and bots reproducible.
- **One path for manual and automated actions.** An automated step queues training exactly like a tap on the card, with the same costs, block reasons and population reservation. A second path would drift.
- **Wait safely when blocked** (section 9): a step waits until the combined cost and population of all its slots can be paid; it never skips, spends partially or silently burns a cycle.
- **Show what it is doing.** A status read from the runtime ("Waiting for Gold", "Next: Slot 3", "Training Slot 1", "Delay: 3s") sits where the automated objects are (section 9.1), and every automated action has world feedback (section 13).
- **Never hide core state.** Automation runs on top of the same cards, queues and counters the player sees; each card still shows its own blocking reason and units in training, so the player can always tell automation waiting from the economy failing.
- **Reduce friction, keep the strategy.** Automation repeats the player's decisions; it does not make them. What to train, in which proportions and which stance remains the player's design; worker automation adds fallthrough (the next task in the player's own list runs when the first cannot) rather than choosing the economy. A game may deliberately go further and unlock an explicit **Smart mode** per worker when that automation is itself a strategic reward: then it is a named, visible mode the player switches on, above the manual configuration, never a silent fallback (section 8.2).
- **Run only while the thing it serves is live** (Growing Kingdom: deployment automation only during a live battle), and make game speed its own progression (section 86).

## 8.2 An automation mode sits above the manual configuration

When an entity can either follow the player's manual configuration or decide for itself (a worker's Smart mode, a squad's automatic targeting policy, a factory that produces whatever is short, an AI personality for a unit), model **automation as a mode of the entity, above its manual configuration**, never as one more value inside that configuration.

```text
entity
  mode           MANUAL | AUTO                       one switch, two named states
  manual_config  [slot 1 .. slot N]                  the authored slots; kept untouched while AUTO
  auto_state     {choice, commitment_end, target}    the policy's own runtime; saved; cleared on a mode change

decide(entity)
  AUTO   -> policy(entity)                           reads shared need; never reads or writes manual_config
  MANUAL -> the first executable entry of manual_config
```

Why not "Smart" as a priority value: inside the list it allows "Priority 1: Smart, Priority 2: Smart", leaves the other places meaningless (what does place 2 do under Smart?), and lets the one edit rule (section 129.5) swap the mode around like a task. As a mode, the list and the policy each keep one meaning.

**State ownership**

- **One state owner and one function change the mode** (Growing Kingdom: `RunState.set_villager_mode(ids, smart)`); nothing writes the flag or the policy's fields directly. Like every action it checks the gameplay lock (section 26.1) and the unlock, and returns a player-facing reason.
- **Auto preserves the manual data.** The policy reads and writes only its own fields. Every manual edit of an Auto entity (its dropdowns, a direct command, a group order) is refused with a reason ("This Villager is Smart: switch it to Manual first"), never applied to the hidden configuration.
- **An individual switch back to Manual restores that individual's configuration,** cleaned to the slots unlocked now (the default only if nothing valid remains), and applies it at once by the ordinary manual rule (section 115.4 for what happens to a carried load).
- **A bulk change is a different operation** (section 129.6): an explicit Apply gives everyone what the creation card shows, Auto (each keeping its hidden configuration) or Manual with the shown configuration.

**Presentation**

- **Manual exposes exactly the authored slots the player has unlocked** (one to three priority places in Growing Kingdom). Auto hides those controls entirely and shows a clear state tag (a badge and a tinted row), while the entity's status line keeps saying what it is doing.
- **Two side-by-side choices, never a cycling button** (section 129.1), and the same switch everywhere the mode is set: the entity's row, its context card and the creation card (which is also the bulk template, section 129.6).
- **Hide the machinery.** The policy's commitment timer and scores stay internal; expose only deterministic, actionable timing (section 9.1).

**Creation and queues**

- **New entities can be born in a mode.** Once the automation is unlocked, the creation flow offers the same switch before creating ("New Villager [Manual][Smart]"): Manual shows the configuration the recruit will get (the saved default for new entities), Auto shows the tag instead. Store the choice as a profile preference through its own function, saved on the pick (section 129.5), and read it through one getter that also checks the unlock, so every creation path (manual, automated, debug) agrees and a profile without the unlock always creates Manual.
- **A queued creation snapshots the whole configuration.** When creation takes time (a recruit in a House queue, a unit in training), copy what the creation card shows into the queue entry when it is queued (the mode and the manual configuration, cut to the slots unlocked then), save it with the queue, and create the entity from the entry, so a later change of the card never alters an entity already paid for. Growing Kingdom first snapshotted only the mode and let a Manual recruit read the default list at spawn, so retuning the card while a recruit was in line changed that recruit; the Android follow-up corrections made the queue snapshot both.

**A policy commits, then reassesses**

- An automatic chooser that re-picks after every action thrashes (a worker switching resource after each delivery), and reads as broken. Commit to a choice for a fixed interval of **simulation time** (Growing Kingdom: `Balance.SMART_COMMIT`, 2 minutes), stored as an end time in the entity's saved state, so pause and game speed apply and a reload continues the same commitment.
- Break the commitment early only for events that make it wrong or impossible: the task becomes impossible, a more important kind of need appears (Growing Kingdom: construction whose unmet need is at least the held resource's), the player switches the mode on. A commitment is anti-thrashing, never permission to idle.
- Every automatic entity reads need from **one shared helper** (Growing Kingdom: `EconomySystem.kingdom_needs()`), so they agree on what is scarce, and the decision is a pure function of state (no movement, no claim, no random draw) so probes and the UI can ask it without changing the simulation.
- **Several automatic entities are one workforce, not copies of one decision.** If each reads the same need and takes the globally best answer, they all pile onto it (every Smart Villager on the one project, then every one on the scarcest resource). Each must take the **greatest unmet need**: the need shared among those already handling it, `need / (1 + others on that task)`, where "others" counts manual entities by what they are doing and automatic ones by their commitment (a reservation), all derived from the records like claims, never saved. Count work already in flight as supply (loads already carried toward storage), give a task that cannot run now nobody, and let one possible task take everyone. The split then follows demand without a fixed ratio, and the decisions stay sequential and deterministic, because each entity sees the commitments of those that decided before it. Growing Kingdom first had each Smart Villager decide alone ("Build first, then the scarcest resource"); the correction pass replaced it with this allocation.
- **Give a shared need a scale its tasks agree on.** Growing Kingdom reads a resource's need as how empty its storage is (0 to 1) and Build's as a constant on that scale (an empty resource): a lone automatic worker still builds first, and each builder already on a project halves what the next adds, so construction never takes the whole workforce merely because it exists.
- **Commitments and coordination together:** inside a commitment, only a more important *kind* of need breaks it (construction whose unmet need is at least the held task's); at a reassessment, the held task stays unless another's unmet need is greater by a margin (Growing Kingdom: `Balance.SMART_SWITCH_MARGIN`, 1.2), so equal tasks never alternate.

Probe: several automatic entities with several needs never all take the same task while uncovered needs remain (construction plus two scarce resources; a nearly full resource; a resource many manual entities already serve; a load already inbound; a well-covered project), one possible task may take everyone, an impossible one nobody, the same state gives the same split, and nobody alternates across two commitments with the need held steady; Auto never appears inside the manual controls; individual Auto hides the controls and leaves the hidden configuration identical through many decisions; individual Manual restores it; manual edits of an Auto entity are refused; creation in each mode with each number of unlocked slots; a queued creation keeps its mode and configuration after the card changes, across a save; changing the card alone changes nobody; Apply with Auto shown keeps every hidden configuration; Apply with Manual shown gives everyone the shown configuration; save and reload keep modes, hidden configurations and commitments; the commitment holds for its interval and breaks on each early event.

Reuse (Growing Kingdom): `RunState.set_villager_mode()`, `set_recruit_mode()`, `apply_new_villager_config()`, `set_all_smart()`, `set_all_manual()`, `SMART_EDIT_REASON`; `ProfileState.recruits_smart()`; `EconomySystem.smart_plan()`, `kingdom_needs()`, `task_coverage()`, `smart_scores()`; the New Villager card in `villagers_panel.gd`; `core_probe` `_test_smart_workforce`, `_test_smart_recruit_modes`, `_test_smart_allocation`; `android_ui_probe` `_check_villager_modes`. Worker specifics (coordinated allocation, finishing a taken project) are in section 115.1.

Reusable rule:

> Automation is a mode above the manual configuration: one function changes it, the manual data waits untouched underneath, an individual switch back restores it, creation can choose the mode up front and a queue snapshots what the creation card showed, and the policy commits in simulation time before it reassesses.

---

# 9. Automation should wait, not fail

A subtle but important rule:

If an auto-purchase timer completes but the player cannot afford the purchase:

> wait until the resource is available.

Do not silently discard the automation cycle.

This feels much better because the player purchased reliability.

Likewise, for batch automation:

- remember the unfinished batch;
- complete it when resources become available;
- only then restart the main cooldown.

## 9.1 Expose deterministic automation timing

Once automation becomes important, players need to understand **when** it will act. A compact optional HUD readout is better than forcing the player to infer hidden timers.

Useful examples:

```text
Buy upgrade in 5s
Claim mission in 10s
Next mine in 8s
Upgrade: Waiting for Gold
```

Only expose timers that are deterministic and actionable. Do not fill the screen with every worker cooldown, pathing delay, projectile cooldown, or per-unit state. If a system has many asynchronous agents, a single countdown is usually misleading rather than helpful.

Architectural rule:

> the UI reads the authoritative runtime timer; it does not duplicate the timer formula.

Expose a small read-only status contract from the owning controller/system. This prevents the HUD from drifting out of sync after balance changes, speed multipliers, retries, or wait-for-resource behavior.

Make the readout optional and persist the preference. For automation-heavy games, defaulting it to **On** is reasonable because visibility helps the player understand the value of newly purchased automation; advanced players can disable it for a cleaner battlefield.

---

# 10. Physical resources create stronger feedback

Everfort used physical Gold pickups instead of immediately adding currency.

Advantages:

- stronger reward feedback;
- makes collection meaningful;
- enables Sheep/collector automation;
- enables manual vs automated economy decisions;
- battlefield remains visually active.

If using physical pickups:

- decide whether they expire;
- decide whether they persist across stages;
- decide whether they save/resume;
- decide what clears them.

Everfort final rule:

```text
pickup remains indefinitely during the current run
-> collected manually or automatically
-> cleared on new run / death / hard reset
```

This is a good default for idle/incremental games where missed resources should not feel punitive.

---

# 11. Secondary economy systems should use shared resources

The Mine design worked because manual and automated extraction consumed the same reserve.

Generic model:

```text
resource node has finite reserve
manual extraction = low efficiency, instant
worker extraction = high efficiency, slower
```

This creates a meaningful decision:

> take less now, or leave it for automation and earn more later.

This is more interesting than having manual and worker mining generate unrelated rewards.

---

# 12. Worker systems need a visible loop

A worker should not simply “increase income per second” invisibly if the game has room to show physical activity.

Recommended worker loop:

```text
home
-> travel
-> perform work animation
-> load resource
-> return
-> deposit
```

This creates:

- visual life;
- clear explanation of upgrades;
- natural capacity/speed/yield stats;
- clear reasons for additional workers.

Worker upgrade categories that generalize well:

- amount;
- movement speed;
- work speed;
- carry capacity;
- yield;
- rare-drop chance.

For a city of workers with several tasks, shared storage and construction (priority lists that fall through, drop-offs, carry safety, a construction order), see section 115. For the implementation of that loop (what a worker saves, its state machine, re-evaluation points, animation and contact frames), see section 120 and the stack it belongs to (sections 116 to 127).

---

# 13. Use visual feedback for every automated action

Automation without animation feels fake.

Everfort improved when it added:

- Mine spring on hit;
- Pawn mining animation;
- floating rewards;
- warning badges;
- charge bars;
- projectile feedback.

Rule:

> If the player did not press the button themselves, the game needs even stronger feedback showing what happened.

---

## 13.1 Animate the actor, not just a tool beside it

An automated action needs a readable actor pose, a target reaction and a clear result. Moving a detached axe while the body stays idle is insufficient when suitable body/expression frames exist in the supplied pack.

Define presentation states explicitly, mapped through the verified animation inventory in section 22.1:

| State | Presentation contract |
|---|---|
| Idle | Rest pose; no accidental tool swing or movement cycle |
| Moving | Verified walk/run frames and supported facing; stop the cycle when movement stops |
| Attacking | Anticipation, contact and recovery; weapon visibility follows the active equipment snapshot |
| Gathering | Resource-appropriate body/tool/expression combination; contact matches the target reaction |
| Fishing or another sustained action | Enter/cast, visibly hold/work, resolve/catch, recover |
| Dying | One non-looping sequence, with cleanup after the agreed completion boundary |

This is a semantic contract, not a demand for six separate source animations. Inventory the actual pack first. Missing frames require an explicit fallback decision, not a fabricated claim that a dedicated animation exists.

**Unarmed fallback:** when an approved base unit has no weapon and no dedicated unarmed attack, an approved brief hop/lunge using existing movement or jump poses and an effort expression can communicate a strike. Do not silently give it a sword to reuse an armed animation. Keep the animation offset on a visual child so the actor's navigation position, collision and ground origin do not jump. Preserve the game's authored attack reach; the visual hop must not grant extra movement or hits.

Loopcremental discussion example: Basic companions should attack unarmed; a short hop with an existing effort expression was accepted as the fallback. That choice is game-specific, not a universal animation requirement or proof of implementation correctness.

## 13.2 Give every action one authoritative contact and result

Use a small action contract: action id, actor/target ids, start, contact or completion, recovery, and cancellation. The simulation owns eligibility, damage, resource credit and item rolls; the view presents those events. Do not let both a simulation timer and an animation callback apply the same hit.

- In a simulation-driven game, schedule one authoritative contact and synchronize the visible frame to it. In an animation-driven game, a frame event may request that contact, but the state owner still validates and deduplicates it.
- Damage, target flash/recoil and the hit indication belong to the same contact. Gathering awards and resource popups belong to the authored award moment. A pickup game may intentionally award later on collection; preserve that distinction rather than forcing every economy to credit at contact.
- A canceled action, dead target, interrupted cast or invalidated node must not produce a late hit, catch or duplicate award. Use action ids or generation tokens to invalidate pending callbacks.
- Pause and speed changes must keep pose timing and simulation timing coherent. A headless simulation, hidden view or disposed sprite must not lose an authoritative reward because an animation signal never arrived.

Choose one timing owner and document it. This refines the contact-frame guidance in sections 120.9 and 125.4; it does not introduce a second reward path.

## 13.3 Sustained actions need a visible working phase

Some actions should communicate waiting or effort, not repeated fast tool flicks. For fishing, show a cast toward a valid water point, keep the pose/line readable during the wait, then resolve the catch and show the fish icon plus amount at the correct award moment.

Loopcremental's discussed target was a visible wait of roughly one to two seconds. Treat this as an example: cycle duration, minimum readable hold, catch rules and speed-upgrade behavior belong in the game's data/GDD. Never hardcode that duration as a cross-game default. If rod/line/water effects are absent from an asset-only project, flag the gap before drawing replacements.

Upgrades may shorten the cycle, but the fastest supported state must remain readable. Test direction changes, canceled work, depletion, pause and boosted speed. Do not add reward rolls or economy changes merely to make the animation look busy.

## 13.4 Logical death and visible death have different lifetimes

Death must immediately stop attacks, gathering, healing, navigation and targetability, while the presentation may still need time to finish the supplied death frames. Apply this to both friendly units and enemies.

Use a boundary such as `alive -> dying -> presentation complete -> removed/resting`, with the state owner authoritative for the gameplay consequences. A dying visual is not a living combatant and must not hold a target reservation or block victory calculations as though it were alive.

- Continue updating the death presentation after HP reaches zero. An early return for dead actors must not prevent their death frames from advancing.
- Do not free the actor view or replace the whole map in the same frame that starts its death sequence. Keep a detached death view or wait at the transition owner, with explicit cancellation on reset/travel.
- Ensure respawn or party redeployment cannot erase an unfinished sequence. Define whether the respawn delay starts at logical death or after presentation, and how it relates to the animation duration; keep that decision in the GDD.
- Define whether death sequences follow game speed or real time and what pause does. Use a guaranteed completion boundary; do not wait forever for a callback from a view that may be hidden, freed or skipped.
- Commit kills, loot, rewards and respawn timing once. Reload may restore a dying state or use a documented settled fallback, but must not resurrect a rewarded enemy or replay its loot.
- On reset, pooled reuse or respawn, clear death flags, pose offsets, tool/expression overrides and pending callbacks. Never let an old fade or completion callback remove the replacement actor.

Verify friendly death, enemy death, final-enemy death, simultaneous party defeat, interruption by travel/reset, and save/reload during the transition. A screenshot of a corpse does not prove the full sequence or respawn boundary.

---

# 14. Design mobile UI from the beginning

The biggest repeated UI lesson was that desktop intuition underestimates mobile readability.

## 14.1 Use a reference resolution

A practical reference:

```text
1920 × 1080
```

Then use anchors/containers so the same layout scales.

## 14.2 Test text on an actual phone

Do not judge text size only from a desktop screenshot.

World-space numbers often need to be much larger.

Everfort eventually used roughly:

- combat/resource floating text: +100%;
- special/charge text: +25%;
- HUD values: +15–20%.

## 14.3 Keep tap targets generous

A button should be easy to hit with a thumb.

Do not make interaction regions tightly match tiny pixel sprites.

For world objects, give every selectable entity one generous pick rectangle and use it everywhere: the tap test, the selection marker, the tutorial pointer and the generator's clearance check (section 122.1). The touch minimum for UI buttons and how it is enforced are in section 125.9.

## 14.4 Prevent interactive overlap

Mines accidentally opening Tower menus was a direct example.

Before choosing spawn areas:

- map all interactive zones;
- reserve clear space;
- ensure click shapes do not overlap.

On a map with generated decoration, the generator itself must keep every decoration's tap rectangle off every authored plot, and a probe must tap the centre of every plot and check that the plot is selected (sections 115.9, 122.2). HUD controls must also shield the world from taps and pans that start on them (section 121.2).

**Derive encounter spacing from the targeting rules.** When idle auto-attack acquires the nearest enemy within a range, every farming spot must be farther from every other spot than acquisition + reach (measured between the closest actors, after spawn spread), and respawn points must sit outside every spot's range; otherwise farming one spot silently chains into its neighbour. Put the weakest encounter nearest the arrival and bosses farthest. Encode the rules in a layout tool with a check mode and a probe over every map (LootFarmer `tools/layout_campaign_groups.py`).

## 14.5 Avoid bottom-edge UI

Phones have:

- gesture bars;
- navigation bars;
- different aspect ratios.

Do not anchor important controls directly on the bottom edge.

---

# 15. Three cards per row is a strong mobile default

For a large permanent-upgrade screen on a landscape/mobile reference layout:

```text
3 cards per row
```

was a good balance.

Benefits:

- readable title;
- readable effect;
- visible cost;
- large icon;
- large purchase button.

More columns looked efficient on desktop but produced undersized mobile cards.

Use this as an initial design constraint rather than shrinking cards later.

In a side panel (not a full screen), two columns fit better: Growing Kingdom's Build cards lead with a large benefit value, and three columns left too little width for it. Put the button in the card's last row so buttons align across a row (section 128.1).

---

# 16. Management surfaces: one job per surface, grouped by the player's mental model

A management game shows a lot of state. It stays readable when each surface answers one kind of question and the player learns where each question is answered.

## 16.1 Which surface answers which question

| Surface | Question it answers | Examples |
|---|---|---|
| **HUD** | "What is my immediate status? Is anything wrong?" | resources and storage, population, wave and base HP, warnings, badges on the buttons that open systems |
| **Context panel** (a tapped object) | "What can I do to this object?" | a building's tier, queue and upgrade; a worker's task; a soldier's stance; a node's stock |
| **Management screen** (side panel or screen) | "How is the whole system configured?" | all workers and their priorities, construction order, army cards and slots, research per building |
| **Stats** | "What are my effective numbers, and what is boosting them?" | effective unit and economy values, Current Boosts by source (section 17) |
| **Reference** (Bestiary, help, codex) | "What does this mechanic mean?" | enemy entries with their traits, rule explanations that outlive a one-time lesson (section 18) |
| **Ownership** (read-only) | "What do I already own, and what does it do now?" | owned Prestige ranks with their current effects, opened from the HUD's progress element (section 16.4); never the place to buy or choose |

Do not make one panel do all of these. A context panel that also explains the mechanic in paragraphs, or a management screen that doubles as a stats sheet, grows until no question is answered at a glance. Link between surfaces instead: a resource chip opens the worker screen, a building card opens its research list, an enemy introduction leads to its Bestiary entry.

**In a context panel, show the few actions relevant to the selected object** (one primary action in a stable place, section 129.2), its live state and why an action is unavailable. Everything else is one tap away on the surface that owns it.

## 16.2 Group by the player's mental model

The skill screen improved when automation cards were moved into an **Automation** section.

Good categories might be:

- Combat
- Defense
- Economy
- Automation
- Towers
- Mining / Workers
- Offline
- Utility

Avoid grouping solely by code architecture. The player does not care which script owns the feature. Growing Kingdom's Current Boosts groups by the effect the player feels (Combat, Economy, Command and utility), not by which layer or script owns it; the source is a detail under each row.

## 16.3 Stable panels

A panel is one stable screen whose data changes, not a new layout every time the state changes.

- **Size a side panel to its content**, clamped between a minimum and the free area, and let longer content scroll inside it. A `ScrollContainer` reports no content height of its own, so measure the header plus the body's combined minimum size plus the stylebox margins. Set the **width first**: wrapped labels compute their height at the final width. Refit when the content changes size, not only on open.
- **Show a panel only at its settled size.** A container with autowrap labels measures too tall on its first layout pass (one word per line). Build the panel transparent (alpha 0: it lays out and measures like a visible one; `visible = false` may skip layout), measure its wanted height every frame, and show it once that height has held for two frames, with a cap (twelve frames) so it can never stay hidden. Resize a visible panel the same way, only to a height that has held. Remove any timer-based refit that applied the unsettled measurement.
- **Pin the action header** (counts, the main button, a default setting) above a list that scrolls on its own; build it once.
- **Diff lists in place:** a new entity appends a row, a removed one removes its row, values update in the existing rows; rebuild only when the structure really changes (a settings change such as the number of priority places). Keep the scroll position when an action changes a row (section 121.8).
- **Poll continuous values at modest intervals** (Growing Kingdom 0.12 s; Feed the Dragon 0.1 s for the HUD and 0.2 s for the context panel), write a label only when its text changed, and rebuild only when a structure key changes (section 123.2).
- **Reserve fixed lines** for transient states ("Recruiting Villager · 8s", an idle "Nothing in training" queue line) instead of adding and removing lines; a status line never wraps.
- **No collapsed text:** one-line labels that end in an ellipsis, a minimum width for name columns, and a flow container (not a box) for rows of buttons, so a narrow screen wraps buttons instead of squeezing text into a column of broken words. Size a button for the widest label it can ever show.
- **A control line the design wants on one row gets a width budget, not a wrap.** When a mock puts several equal dropdowns and an action on one line ("[Build v] [Wood v] [Gold v] [Apply to all]"), add up the widths at the narrowest supported layout before building it: the widest label any dropdown can show plus its chrome (margins, icon, caret, gaps), times the slot count, plus the action button and the gaps, against the card's inside width there. If it does not fit, trim chrome, never text: a smaller icon and caret, narrower padding, dropping a redundant prefix the layout already conveys (left-to-right order instead of "1."), in a compact variant used only where it is needed. Give every dropdown the same width (the widest any of them needs) and never let them stretch. Growing Kingdom's New Villager line: standard chrome needed about 870 px against 746 inside the card at 16:9 with a notch; compact chrome made it 722 at full text size.
- **Measure fit against what bounds the element.** A card whose content outgrows it grows past its panel, so "every control inside the card" still passes; assert the card against the panel (as wide as its siblings, enclosed by the panel rect) at every screen shape, and print the measured widths so the margin is visible in the log. Growing Kingdom's first New Villager probe passed while the card was 1,010 px wide in an 860 px panel.
- **Scroll from anywhere:** a drag that starts on a button or card scrolls the list and never presses (section 121.8).
- Probe it: the pinned rectangles identical before, during and after an action; old rows are the same node instances; per frame from the open, hidden first, shown at the content's size, no size change after; no visible label narrower than about 120 px or taller than three lines at every screen shape.

Reuse (Growing Kingdom): `PanelHost` (settle-then-reveal, `SETTLE_FRAMES`), `GamePanel.content_height()` and its pinned area, `villagers_panel.gd` (rows diffed in place; the New Villager line), `TaskButton.fit_width()` and `compact()`; `android_ui_probe` `_check_new_villager_layout`; probes `world_probe` "panels appear at their final size", "Villagers panel keeps its structure".

**Small panels expose their actions directly.** Do not add a More/Less Options gate when the complete set fits comfortably in the existing scroll panel. Group related controls by what they affect: player actions on the player, enemy-type automation on the enemy type, shared upgrades in a clearly named Upgrades section. Record scope, price scaling, pickup provenance and reset behavior in the game's GDD; moving an upgrade must migrate purchased levels deliberately.

**Confirmation bounds are part of the layout contract.** A desktop/native dialog with a fixed minimum width can escape a scaled mobile viewport even when the underlying settings panel fits. Use the existing UI theme, constrain the confirmation to the safe canvas rectangle, wrap/scroll its message and pin explicit Confirm/Cancel controls. Block input to underlying UI while it is open, clear stale callbacks on cancellation, and test long text, narrow/tall/wide layouts and destructive reset from pause. Check the dialog against the viewport and its buttons against the dialog, not just children against their own containers.

Two measurement traps found in Godot 4.7 (LootFarmer Change 6): buttons inside a flow container must not autowrap, or each collapses to one word per line and the flow reports hundreds of pixels of height; and descriptions built off-tree cannot resolve theme defaults, so when reconciling them into live controls compare only explicit overrides, or every refresh replaces the controls it meant to keep.

## 16.4 A HUD progress element as the entry to a read-only ownership surface

A bounded meta progression (a Prestige track with a known number of ranks, a codex, a set of relics) raises two separate questions: "how close am I to the next one?" (status) and "what do I already own?" (reference). One HUD element can answer the first and be the door to the second.

```text
HUD element (status + entry)          tap -> read-only ownership panel     (what I own, what it does now)
the offer or shop (choice)            reached only by its own flow         (what I could take, at what cost)
```

- **Status on the HUD, ownership one tap away.** Growing Kingdom's Prestige block shows a fixed title, the meta currency's progress centred inside a bar (LOCKED, "850 / 1,000", READY, COMPLETE) and, beside the bar, the ranks owned out of the authored total ("7 / 33"). The whole block is one button that opens a read-only Owned Prestiges panel.
- **Keep choosing and owning apart.** The offer (buy, choose, reroll) is a decision surface reached through its own flow; the ownership panel lists only what is owned, grouped by the player's categories, each with its name, its rank when it has several, and its effect at the rank owned, and it has no action at all. A status element that opened the purchase screen would mix "what could I take" with "what do I have" and invite accidental decisions.
- **Show "X / N" when N is authored and bounded.** N comes from the same authored data the offers hold (section 3.5), counted in the same unit as X (ranks, not cards); both come from the ownership record through getters, never a cached count, and every surface that shows them reads the same getters. An unbounded track shows X alone.
- **Nothing to list: feedback, not an empty panel.** With nothing owned, a tap shows a brief note anchored under the element ("No Prestiges so far."), which ignores input and disappears after a moment; the tap closes any open panel first, so the note is never covered.
- **Teach that it is interactive, once, subtly.** A small info glyph on the element pulses gently until the first tap, then stays still for good. The discovered state is a seen-hint id in the profile (section 18.1), set by the tap whatever it shows (the empty note counts), so the invitation never returns after a reload. Animate a child glyph, never the block, with one looping tween that is killed on discovery (section 76).
- **The whole element is the target.** The glyph is part of the button and ignores input itself; a tap anywhere on the block does the same thing.
- **It is navigation, not gameplay.** Opening it stays allowed while the player's Pause holds (section 26.1); the panel joins the same panel host, settle-then-reveal (section 16.3) and tutorial arbitration (section 18.8) as every other panel.
- **Fixed geometry in every state** (section 19.1): size the bar for the widest text its states can show and the counter for its widest value ("33 / 33"), so a state change never reflows the HUD.

Reuse (Growing Kingdom): `Hud._build_prestige_section()`, `_on_prestige_pressed()`, `_update_prestige_info()` (`HINT_PRESTIGE_INFO`); `owned_prestige_panel.gd`; `ProfileState.owned_prestige_ranks()`, `prestige_rank_total()`, `prestige_progress()`; `android_ui_probe` `_check_prestige_hud`, `_check_prestige_info`; `core_probe` `_test_owned_prestige`.

Reusable rule:

> Give every surface one question to answer, group by what the player feels, keep each panel one stable screen that appears at its final size and changes only its data, and keep "what I own" apart from "what I could choose".

---

# 17. Show current effective stats and what is boosting them

When a game has temporary upgrades, permanent upgrades, Prestige modifiers, Ascension rewards and buffs, the player must be able to answer

```text
What is affecting me right now?
```

without mentally combining several menus. A consolidated Stats page answers it.

## 17.1 Effective values

Show the numbers the simulation actually uses: effective HP, damage, attack interval, range, crit, lifesteal and regen where they exist; per-unit values as the unit would be trained now; base defences; economy rates (gathering time, carry, worker speed, construction rate, storage, regrowth); reward multipliers (meta currency, Salvage, offline rate). Every value comes from the **same getter the gameplay uses** (section 116.5); the page never recomputes a formula.

## 17.2 Current Boosts: totals by effect, with optional sources

A game with several meta layers needs a summary of what those layers give right now. Growing Kingdom's Stats page opens on **Current Boosts**:

- **Rows grouped by the effect the player feels** (Combat, Economy, Command and utility), not by which layer or script owns them (section 16.2).
- **Each row shows the effective total**, then, small under it, **where it comes from**: "Permanent +40% · Ascension ×1.1". Additive parts show as +%, multiplying ones as ×, so the parts never pretend to add when the game multiplies.
- **Only owned effects show**; a fresh profile says there are none yet. Capacities and unlocks are rows too ("Deployment Slots 5", "Building Tier II", "Game Speed 2x").
- **Tie every total to the gameplay getter.** Take the total from the getter itself where it holds only the meta layers, otherwise from the same values that getter adds in. Move constants that lived as literals inside getters (a Decree's ×2) into named balance constants both read. A probe builds a rich profile and compares every total with the gameplay value on a run without run-scoped bonuses.
- Keep run-scoped bonuses (run upgrades, research) out of this summary or clearly apart: they change within the run and belong to the run's own panels.

## 17.3 Real time and game time

When game speed multiplies the simulation, "time played" has two honest meanings. Show both, from one clock:

- **Real time:** each frame's wall-clock delta (the same clamped delta that feeds the simulation), counted only while the simulation runs.
- **Game time:** the fixed simulation step, after the speed multiplier.

They agree at 1x and part at 2x and 3x; neither counts paused screens, modal decisions, time between runs or time away. Probe it in the real scene at a fixed frame rate (Growing Kingdom: 180 frames at 3x give 3 s and 9 s; nothing while paused). Pricing a speed upgrade is section 86.

Reuse (Growing Kingdom): `MetaBoosts` (`scripts/core/meta_boosts.gd`), `stats_panel.gd`, `Balance.DECREE_*`, `RunState.note_real_time()`; probes `core_probe` "Current Boosts show the gameplay values", "Real and Game Time Played".

Reusable rule:

> One page answers "what is affecting me right now": effective values from the gameplay getters, meta boosts as totals by effect with their sources, and real and game time kept apart.

---

# 18. Teaching: state-driven, contextual, concise and safe

A good tutorial teaches only the immediate loop, owns its state so the game cannot outrun the lesson, and leaves every later rule findable without it. A management-heavy game has far more to teach than any tutorial can hold, so most teaching must happen in context, briefly, and stay available in a reference surface afterwards.

## 18.1 Principles

- **Teach the immediate action, not the whole system.** "Tap a Villager, pick Gold" teaches more than a paragraph on the priority system. One concept and one thing to do per card.
- **Teach when the relevant state first occurs.** An enemy kind is introduced on the wave that brings it; a mechanic is explained the first time it matters (the first armoured enemy, the first Monastery waiting for its specialty, the first wave about to arrive), never in a front-loaded list.
- **Reuse the existing teaching architecture.** One pointer and caption, one introduction card, one toast queue. A new mechanic rides an existing carrier (Growing Kingdom taught armour on the enemy introduction card that already existed) rather than adding a notification system.
- **Non-blocking unless a real action must be gated.** Informational messages never pause and never take input; only a mandatory action gates progress, at a safe boundary (sections 18.2 and 18.4).
- **Decide "first time" in state and persist it.** A seen-hint id in the profile (saved, kept by Prestige, cleared by Hard Reset), set by a function the probes can call headless, so a lesson can never show twice and its trigger is testable.
- **First meaningful encounter → concise explanation; permanent reference → the reference surface.** The player should never need to remember a one-time lesson: the same rule stays in the Bestiary, the help page or the Stats page, read from the same data (section 131.5).
- **Let the screen carry most of the information.** Icons, states, warnings beside the cost and layout teach continuously; copy stays short (section 128). Remove messages that repeat what the world already shows.

## 18.2 Onboarding depth and gameplay modes

When the audience can include both experienced incremental players and first-time players, it can be better to offer **onboarding depth** instead of one universal tutorial:

```text
Basic overview -> the reference card deck once up front, then a short note as a later part opens
Hand Holding -> state-driven guided first run
None -> no instructional help at all
```

**Depth is presentation; pacing is the game.** The chooser decides how much *help* the player gets, never what the simulation does: every mode starts the same state with the same costs and the same gates. What is relevant on the first kingdom (progressive disclosure, no enemies while the economy is learned) is a separate first-profile progression owned by the game (section 18.10). "None" therefore means no pointer, caption, card or instructional toast, and it does **not** mean "show the entire game immediately". Growing Kingdom first let None and Basic start the full game while Guided got a reshaped run; playtesters who skipped the text met every menu and the first enemies before understanding the economy, and the three modes were three different simulations to balance and test.

If a mode shows reference cards up front, it opens the very deck the settings screen offers (one data source, one renderer), never an onboarding copy: two decks drift apart in text and art. Drop any opening note that repeats what the deck and the objective card just said (Growing Kingdom v0.17).

Persist the chosen mode and define reset behavior explicitly: Hard Reset returns to the chooser, and a Prestige never replays first-run onboarding.

Use two gameplay modes only:

```text
Normal
Hard Gate
```

**Normal:** the game behaves exactly like ordinary play.

**Hard Gate:** finish the current combat/wave cleanly, then prevent the next wave/progression step until the required action is completed.

Avoid "protected tutorial gameplay" that changes damage, grants invulnerability, or introduces an HP floor. Those rules create a different balance model and can let players advance farther than intended. Growing Kingdom's first kingdom is the real game; its gates (no wave before the settlement and the first defender) sit before any fighting and belong to the first-profile progression, not to a tutorial mode (section 18.10).

## 18.3 First-run guided tutorial

Teach one concept at a time:

1. core combat/base;
2. physical resource collection;
3. one temporary/run upgrade;
4. mission/reward interaction if central to the loop;
5. one secondary resource interaction;
6. first defeat;
7. permanent progression;
8. first long-term/meta goal.

Use event completion, not arbitrary timers, for mandatory actions.

For optional/informational messages, use a readable finite duration (Everfort settled around 15 seconds for important non-blocking messages; Growing Kingdom's enemy introductions stay 7 to 14 seconds and dismiss on a tap).

**Prefer a tutorial that never reshapes the simulation.** Open the chooser before the first tick (it pauses), but let the choice change only the guidance; the first-profile progression (section 18.10) gives every mode the same state. If a design truly needs a reshaped opening, apply it only to a pristine state behind the paused chooser and gate it on a strict "fresh start" predicate: Feed the Dragon's Guided reshapes a city nothing has touched yet, and the reshaping accepts only a state that passes `is_fresh_start()` (first run, nothing built, bought, queued or survived), so an old save, a test save or a mid-game mode change can never receive the tutorial's protection. Growing Kingdom had such a Guided opening (no free Barracks, wave 1 held) until v0.12, and retired it for the shared progression.

**Cards: one action line, one support line, a picture.** Cap the words in a probe (Growing Kingdom: action at most 12 words, support at most 18, action font larger than support).

Reuse: `RunState.is_fresh_start()` and `start_guided_opening()` in Feed the Dragon; `TutorialGuide` and the onboarding chooser in Growing Kingdom (its Guided steps read the first-run goals, `FirstRun`).

## 18.4 Grace period before a hard gate

A hard gate does not need to trigger immediately. A useful pattern is:

```text
mandatory action appears
-> allow 1-2 normal wave clears
-> if ignored, stop at the next safe boundary
-> keep the action available
-> release immediately when completed
```

This lets discovery feel natural without allowing the game to progress so far that onboarding breaks.

Persist the grace boundary and required-action state. Closing/reopening the app must not reset the allowance or bypass the tutorial.

## 18.5 The pointer: named controls, recomputed every frame

**Point help at named controls and recompute the step every frame.** Feed the Dragon's mission Help is a pointing hand and a pulsing frame, never a scripted sequence. Each frame it reads state and picks the one thing to tap next: "Build a Lumberjack" points at an empty plot, then at that plot's `Build_lumberjack` button once the overlay is open, then at the site while it rises. Controls are found by node name, so the pointer follows whatever the player actually did, and probes press the same named buttons a player sees. The pointer only shows: it never blocks input or changes state, and it hides under modals.

**Scale a pointing hand about its fingertip.** Making the hand larger by scaling its rectangle from the corner moves the fingertip off the target. Measure where the fingertip is in the texture (as a fraction of its size), keep the point it touches beside the target, and place the hand from that point. Keep it on screen: turn it to the other side of targets at the right edge and point from above at targets at the bottom, clamping only as a last resort. A frame meant to be seen over every background needs a dark edge under its bright line. Probe it at every screen shape and inset: hand size, hand inside the safe area, fingertip at the target's corner, no input taken, hidden under modals.

**Check the resulting state, never the click.** A mandatory step completes when the state it asks for exists, however it came about: a Villager already Building is not told to pick Build, a Villager already on a resource completes the gathering lesson. A step that waits for a specific tap tells the player to undo a correct state, and a step that waits for a delivery ("gathered > 0") keeps pointing at an action already done. Growing Kingdom's Android testers met both.

**But the state a lesson waits for is the learned outcome, not the work starting.** The opposite mistake came from the next playtest: lessons that completed the moment a worker was sent to a resource, recruits were queued, a site was placed or a builder assigned. The tutorial then raced ahead, introducing the next concept while the player was still watching the first one happen, and the economy lesson pointed at the next building while the current one was still a construction site. Make each mandatory lesson complete on the meaningful result (an amount actually delivered, the units actually ready, the building actually complete), read from the same progression state every mode uses, so the guided mode never gets easier rules. While the asynchronous work is under way, keep the lesson and show its progress ("7 / 14 delivered", "1 / 3 ready", "Building: 40%"), with a soft "watch this" highlight and no tap pointer: never tell the player to repeat an action already happening, and never introduce the next concept early. If the work stops (the node ran out, the worker left), point at the way to restart it. Teach a sequence of similar tasks one at a time, each to completion, and skip one the player already finished out of order. Pick targets that show the loop a few times without dragging, and no timers: the work is the pacing. A placement lesson may suggest a sensible spot from the game's own placement rule (start the preview there once, mark the footprint softly, say why), but never snap it back or restrict placement: the suggestion teaches the spatial relationship, the player still decides.

**Follow the live rectangle, and drop it the moment it goes.** Keep a reference to the target control (or the world target) and read its global rectangle every frame, not once per logic tick: panels settle at their size a few frames after opening, lists scroll, a rotation or a safe-area change moves everything. When that control is freed or hidden (its panel closed or rebuilt), clear the frame at once instead of drawing it at the last known coordinates. Search for the control only in the HUD and the panel actually open, never in a panel queued for deletion, and point into a panel only once it shows at its final size.

Reuse: `scripts/ui/help_guide.gd` in Feed the Dragon; `TutorialGuide.hand_layout()`, `HAND_TIP` and `TutorialGuide._process` (live rect) in Growing Kingdom, and its `_wait()` (progress caption and soft frame), `current_economy()` (one at a time) and `suggested_tile()` over `RunState.recommended_build_tile()` (the suggestion).

## 18.6 Contextual teaching after the tutorial

Teach later systems when they unlock or first matter: towers and targeting, workers, automation, Prestige, reference menus, a new enemy trait. Reference systems need not block anything; a hint can simply point out that a feature exists.

**Introduce enemies and mechanics on their first appearance.** The first appearance of each enemy kind shows a compact introduction card (portrait, name, a one-line description, the special first, then the numbers as tiles), non-pausing, dismissed by a tap, once per profile. A new rule that comes with an enemy rides that card: Growing Kingdom's first armoured enemy brings a variant ribbon ("Armored enemy!") and two short lines in the description's place, then the rule lives in the Bestiary's trait strip.

- Decide the lesson in state: a function returns the enemy to teach it on and marks the hint seen.
- Profiles older than the rule already saw the enemy's card: teach them on their next wave that brings the trait, and let the lesson wait for any other introduction of that wave (one waiting slot) instead of replacing it.
- Match the lesson's words to the data table with a probe, so a later retune cannot leave the lesson saying the opposite.

**Warn before the first threat, derived from state.** A first wave that arrives unannounced teaches nothing. Warn once per run, a few seconds before it:

- Derive the visible window from the wave clock (the last seconds before wave 1 and the first seconds of it) instead of a "warning shown" flag. A reload inside the window shows the rest of it; nothing can show it twice; nothing new is saved.
- Emit one event when the countdown crosses the threshold, for one-shot effects (sound, vibration).
- Say where: mark the spawn area in the world and, when it is off screen, give the banner a button that pans the camera to it.
- Suspend it while a guided lesson holds the wave, so the warning always means "now".

**Point at a choice that is waiting.** When the game needs a decision only the player can make (Growing Kingdom: a new Monastery's permanent specialty), mark the object in the world ("Choose: Mage or Healer"), toast once, and keep the choice on the object's card; nothing else proceeds silently.

## 18.7 Coach hints: the fallback for players who skipped the text

Players dismiss explanation cards and then miss a basic action: a Growing Kingdom tester stopped reading at card 2, did not find how to recruit Villagers and lost several runs before learning it. A fallback that does not nag:

```text
for each hint:
  retired?       -> skip (for good)
  demonstrated?  -> retire: a lifetime counter, or the action in progress now
  situation true for DELAY seconds, affordable now, cooldown over, shows < MAX?
      -> point at the next control, with one line of text
  showing ends when the situation ends, or after SHOW seconds, then COOLDOWN
```

- **Only real mistakes in progress:** enemies near and no soldier in play or training; a project waiting with nobody on Build; population full with a House affordable; still one worker after a while with a recruit affordable. Never a hint about something the player cannot afford.
- **Retire on evidence, not on display.** A hint shown three times retires anyway; one whose action the player has already done (this run or any earlier run) never shows.
- **Never pause, never move the camera, never block input.** Point at a world object only when it is already comfortably on screen; otherwise point at the dock button.
- **Follow what is open:** dock button, then the button inside the opened panel, then the confirm button, so the hint always shows the next tap.
- Only the first few runs of a profile; the showing counts are profile data kept across Prestige and cleared by Hard Reset.
- Reuse the guided tutorial's pointer and caption rather than building a second overlay. The guided mode never shows them.
- Probe each hint in its situation: shows, does not pause, points through the panel, retires on the action.

Reuse: `TutorialGuide` coach section in Growing Kingdom (`coach_learned`, `coach_relevant`, `_evaluate_coach`, `_point_coach`); `tests/onboarding_probe.gd`.

## 18.8 Arbitration: one place decides what guidance may show

A guided tutorial shares the screen with modals, side panels, dropdowns, build modes and the world. Fixing each conflict per step ("hide the Villager hint while Stats is open") never ends: every new panel is a new special case, and the first one nobody thought of leaves a caption and a pointing hand over an unrelated screen (Growing Kingdom on Android: "Tap your Villager, then Build" over the Stats panel). Build guidance as **one centralized system** with three layers of state, each with one owner:

| Layer | What it holds | Owner and lifetime |
|---|---|---|
| **Logical progress** | which lessons are complete (and any hard-gate state, section 18.4) | the profile: saved, kept by Prestige, cleared by Hard Reset |
| **Pending step** | the one step the current state asks for, and the surface it belongs to | derived from game state at every evaluation; never saved |
| **Presentation** | caption, hand, frame, the live target, a camera focus, a list scroll | the guide node; rebuilt from the pending step at every evaluation; never authoritative |

One evaluation drives all of it:

```text
evaluate():                                   on a slow tick AND on every surface change
  no live run, or a blocking modal is open  -> hide everything; stop
  complete every lesson whose desired state already holds        (state, never a click)
  step = the first incomplete lesson; it names its surface: "" (HUD and world, no panel) or one panel id
  claim(step, surface):
    the open surface is not the step's surface    -> suspended: hide caption, hand and frame; step stays pending
    the step's panel is open but not yet settled  -> suspended until it settles (section 16.3)
    a dropdown covers the step's panel            -> suspended
    otherwise                                     -> shown: find the live target, then (only now) scroll or focus
```

Priority, highest first:

```text
Pause / Defeat / Prestige / any blocking or full-screen modal
-> an open panel or dropdown the step does not belong to
-> tutorial guidance
-> ordinary HUD
```

Rules that held up:

- **Steps declare their surface; panels know nothing about the tutorial.** Every pointer call passes the panel id its step belongs to, and one claim function that every pointer goes through applies the rule. A new panel, an informational one included (Growing Kingdom's read-only Owned Prestiges, section 16.4), then obeys it with no code of its own; no panel ever shows or hides tutorial UI itself.
- **Suspend the presentation, never the progress.** Suspension hides everything visible and keeps the step pending; it never completes, skips or resets a lesson. Expose the pending step and what suspends it (probe accessors), so a test can assert "still pending, suspended by Stats".
- **Re-evaluate on every surface change, coalesced to the end of the frame.** The panel host emits one change signal when a panel opens, switches, closes or finishes settling, and when a dropdown opens or closes; the guide queues one deferred evaluation. A switch is a close then an open, and judging the instant in between can move the camera for a step that is about to be suspended. The slow tick remains for changes in the world.
- **On close, re-read the state before showing anything.** A step satisfied meanwhile (the player did it inside the other panel, or the world did it) completes at once; otherwise the guidance returns on the live control. Closing the step's own panel early simply points back at the way in (the dock button), so nothing soft-locks.
- **Complete on the desired state, not on the click** (section 18.5). The evaluation that decides what to show also decides what is already done, so a correct state reached in any order is never undone to please the tutorial.
- **Side effects only after a successful claim.** Scrolling a list to the target and focusing the camera on a world object happen only when the step is actually shown, once per step and target, so a suspended step never moves the camera and the guide never fights the player's own scrolling.
- **Point at the live control, found only where it can be.** Look the target up by name in the HUD and the panel actually open (never one queued for deletion), read its rectangle every frame, and drop the frame the moment the control is freed or hidden (section 18.5). A panel still measuring itself does not lend a rectangle: the claim waits for its settled reveal.
- **Guidance never takes input.** Every guide node ignores the mouse, shown or hidden; the tutorial gates progress only through game state (a wave hold at a safe boundary, section 18.2), never by catching taps. An overlay that blocks input is a soft-lock waiting for the first panel nobody anticipated.
- **Save and resume restore the logical state, then evaluate.** Only completed lessons (and hard-gate state) are saved. After a load the guide starts hidden, evaluates against the restored state and whatever is open, and shows only what that evaluation claims, so a reload never replays a finished lesson or shows a stale pointer.
- **Debug and capture hooks go through the same claim.** A probe or capture that shows a pointer on demand belongs to whatever panel is open, or the arbitration hides what it was asked to show.
- **One arbitration for every guidance mode.** Growing Kingdom's Guided steps, its pointers for later systems and the coach hints for players who skipped the text (section 18.7) all point through the same claim; optional pointers add one condition of their own (they show only while no panel or build mode is open).

Probe it on the real main scene, not on the guide alone: a step suspended by an unrelated panel with its lesson still pending; restored on close; no orphan pointer after a panel-to-panel switch; a dropdown hides it; modals outrank it; guide nodes ignore input; the frame on the live rectangle after a relayout, at every screen shape and inset; a state-satisfied step (a Villager already gathering, already building) that completes, also when it was satisfied behind a panel, and never asks again; the step recomputed after a reload.

Reuse (Growing Kingdom): `TutorialGuide._claim()`, `refresh()` (deferred, coalesced), `pending` and `suspended_by`, `_find_control()`; `PanelHost.changed` and `revealed()`; `tests/android_ui_probe.gd` (`_check_tutorial`).

## 18.9 Tutorial economy constraints

When onboarding needs a bounded economy, prefer limiting **resource generation** over limiting player choice.

Example pattern:

```text
first-run total-resource budget
-> player may spend however they want
-> resource sources stop/clip at the budget
-> budget disappears after the intended first-run transition
```

Track total resources **earned**, not current wallet balance; otherwise spending reopens the cap.

Reserve mandatory tutorial payouts before ordinary generation consumes the budget, so the tutorial can never make itself unsolvable (Growing Kingdom tops the starting stock up to one Barracks for its Guided lesson).

**A tutorial protection must hold every clock that pays, not only the one that punishes.** Feed the Dragon's Guided opening holds the Dragon until the first Villager has a task. Holding only Hunger would have left survival time running, and survival time pays Meta, completes time-based missions and reaches milestones: idling in the tutorial would have been the best farm in the game. The hold stops the whole run clock, lives in the tick that live and offline play share, and an absence that began held earns no Offline Reward.

Reuse: `RunState.guided_opening` and `_update_guided_opening()` in Feed the Dragon.

## 18.10 First-profile progression: gate the first kingdom, once

A management game can reveal itself in stages on the very first kingdom (Growing Kingdom v0.12: Settlement, then Defense Preparation, then combat) without any tutorial. Rules that made it work:

- **Stages are gated by demonstrated actions, never timers.** Each goal is a thing the player did (a resource delivered into storage, a building *completed*, a population reached, the first defender trained), latched once in the profile the first time the state shows it, so spending or demolishing later never un-ticks it and an experienced player clears the stage in a minute. A placed site is not a completed building: Growing Kingdom's first version counted unfinished sites (`count_of` includes them) and a probe caught the Lumber Camp goal latching the moment it was placed.
- **Audit the economy for deadlock before shipping the gate.** Every goal must be reachable from the start state with no other unlock: a general drop-off for every resource from the start, the starting stock covering the recruits, the goal buildings needing only what can be gathered, storage large enough to hold it. Put the audit in a probe so a balance change cannot silently make the first kingdom unwinnable.
- **The gate holds the threat, not the clocks the player learns on.** Waves do not advance and nothing spawns; the economy, construction and recruiting run normally. No damage, HP or balance value changes.
- **Hand the first threat over generously.** When the last stage completes, start the normal countdown at a balance constant (Growing Kingdom: 60 s) with the usual first-wave warning; never spawn an enemy as a side effect of completing the goal.
- **Mark completion when normal play begins, at profile scope, permanently.** Not at the first death and not per run: once the countdown starts, the progression is complete for that profile. Later runs, death and Prestige start the normal, fully revealed game with normal timing; only Hard Reset (a fresh profile) restores it. Put the field in the Prestige keep table, the save, the reset and a probe that dies and Prestiges after completion.
- **One reveal table decides what shows.** A single module maps each feature to the first stage it shows in; the HUD, the panel host (so no other path opens a hidden panel), list contents (Build hides the military buildings) and the action layer (training and military buildings refused with a reason) all ask it. Scattered `visible = false` lines drift apart.
- **Say the next loop when it completes, in every mode.** The handover is the game's goal, not guidance, so None gets it too: one non-blocking message, long enough to read, triggered by the progression's own completion (never a lesson list, a closed deck or a timer), remembered with the profile's one-time notices so reload, death and Prestige never replay it. A toast queue that shortens or drops messages under load must let this one through whole.
- **One compact objective card**, read-only, naming the stage and listing each goal's progress, never the button to press; it disappears for good at completion. Tutorial modes add help on top of it, never instead of it.
- **Probes of normal play opt out explicitly.** Fresh profiles start in the first stage; every probe of ordinary play passes a debug-only flag (Growing Kingdom: `--first-run-complete`, read by `ProfileState` defaults in debug builds) and the onboarding probe runs without it to cover the progression itself. Debug presets other than "fresh" are profiles that played past it.

Reuse (Growing Kingdom): `FirstRun` (`scripts/core/first_run.gd`: `REVEAL`, goals, `lock_reason()`), `RunState._tick_first_run()`, `ProfileState.first_run_stage` / `first_run_marks` with `mark_first_run()` / `advance_first_run()`, `Hud._update_reveals()` / `_update_objective()`, `tests/onboarding_probe.gd`.

Reusable rule:

> Teach the next action when it first matters, on the carrier the game already has, once, decided in state; let one arbitration decide when guidance may share the screen; keep the rule in a reference surface afterwards; and let the screen, not paragraphs, carry the rest.

---

# 19. Do not shrink UI to solve positioning bugs

An important lesson from the tutorial:

When a panel is clipped or too low, first ask:

> Is the size wrong, or is the position wrong?

The correct fix was often:

- center it vertically;
- move it opposite the highlighted object;
- constrain to viewport;

not:

- make everything smaller.

This is especially important on mobile where readability is already constrained.

The same holds for text density: too much copy is fixed by cutting and restructuring it, never by shrinking it below comfortable phone size (section 128.2).

## 19.1 Adding a system to an established HUD

A new system that needs a HUD place puts pressure on what is already there. The quick fixes (merge it into a neighbour, restyle the neighbour, scale the new element until it fits) each spend something the player had already accepted or the new feature needs.

- **Treat an accepted HUD element as a visual contract.** Growing Kingdom's first Prestige HUD was merged into the Wave and Castle HP chip and changed that chip's look; the developer had validated the old chip on device and asked for it back exactly. Changing an established element is a design decision with its own approval, never a side effect of fitting something else in.
- **Prefer a sibling region.** Give the new system its own block in a gap the layout already has (Growing Kingdom's top band: Resources, Population, Glory, then Prestige, then Wave and Castle HP, then the controls), with an identity of its own so it does not read as one more resource card (no resource icon, its own plate tint).
- **Do not halve an important new control without deciding that trade-off.** A block that scales "as one piece" to fit protects the layout, but can quietly leave the new control at half size on some screens: Growing Kingdom's Prestige block drew at 83% on a 16:9 canvas beside a notch, and at about 49% once Glory reached six figures. Report such a result as an open design question with the screen shapes it affects; do not ship it as the solution.
- **Relieve the pressure where it comes from, first:** compact number formatting for large neighbouring values (a six-figure currency as "123.4K", through the one number formatter, section 40), tighter spacing between chips on narrow canvases, a less dense neighbour (a shorter label, a smaller icon), and only then a deliberate, approved size reduction with a floor.
- **If anything must scale, keep the touch target whole.** Scale the drawing, never the button: Growing Kingdom's Prestige button always fills the gap's full height, so the target stays finger-sized whatever the drawing does.
- **Fixed sizes for every state.** Size each part for the widest content its states can show (LOCKED, READY, COMPLETE, the largest number the table allows), so a state change never reflows the band and never moves a neighbour's tap target.
- **Validate the whole band with late-game numbers** at every supported screen shape and inset, not with a fresh profile: the six-figure case is the one that breaks. Assert that the neighbours' rectangles are unchanged from before the addition.
- **A small affordance on a crowded element: reuse its decorative part before widening it.** Growing Kingdom's Glory "?" first reserved 30 px on the chip's right; at six-figure Glory on a 16:9 notch it shrank the neighbouring Prestige block from 49% to 35%. Turning the chip's icon column (decoration, nothing to tap) into the "?" target, with the glyph on the icon's corner, cost 10 px (45% in that extreme case), left the amount as the chip's own action, and put the "?" exactly where players look for it.
- **Size a wrapping note yourself, and check it in a window.** A popover built from a container and an autowrapped label, sized in the frame it is created, kept the label's first (one word per line) minimum: a 4,264 px empty plate in the windowed capture while headless probes measured it correctly. Measure the wrapped height from the font at the intended width, set it, and re-apply the container's size on the next frame (a container never shrinks by itself); probe the note's rectangle, not only its text. Two overlapping buttons need the new one on top and a probe that taps each region and asserts only its action happened.

Reusable rule:

> A new HUD system gets its own region without redesigning accepted neighbours; relieve space pressure through formatting, spacing and density before shrinking anything important, and make any size reduction an explicit decision.

---

# 20. Modal sizing must be intentionally mobile-sized

Several panels were too small initially:

- Tower targeting tutorial;
- offline reward;
- first-run tutorial.

If a modal is important and shown rarely:

> it can occupy a large portion of the screen.

Do not design rare informational modals as tiny desktop popups.

A good landscape-phone modal can use 40–60% of the visible area.

---

# 21. Use notification badges

When a system requires attention, put the warning on the button that opens it.

Examples:

- Mission ready to claim -> `!` on Missions.
- Skill affordable -> `!` on Skills.

This prevents players from repeatedly opening menus “just to check.”

Generic triggers:

- reward ready;
- upgrade affordable;
- inventory full;
- worker idle;
- research complete;
- event available.

Use one look per meaning, so a badge is read before its button:

| Kind | Look | Meaning |
|---|---|---|
| alert | red "!" | a problem only the player can fix (a worker with nothing it can do) |
| ready | green "!" | something is waiting to be collected (a reward) |
| afford | gold "+" | something can be bought now (an upgrade, a research) |

A worker-idle alert belongs on the button that opens worker management, and should mirror an in-world marker over the idle worker (sections 120.10, 124.3).

---

# 22. Asset workflow for pixel-art packs

A large asset pack should be treated like a library, not a folder to grab the first matching PNG from.

Before implementing a visual:

1. search all related filenames;
2. inspect dimensions;
3. inspect animated/highlight variants;
4. inspect transparent padding;
5. identify native intended size;
6. choose the largest correct source;
7. crop before scaling.

Tiny Swords-specific examples:

- use Gold Stone 5/6 instead of enlarging tiny Gold resources;
- use `_Highlight` variants for animated resources;
- use one extracted unit frame for portraits;
- use `House2.png` for Miner House;
- use Pawn mining/Gold variants for workers.

---

## 22.1 Build a verified animation inventory before wiring states

Inspect the actual sheets, preview their frame sequence, and check any author documentation. Filenames alone do not establish which row is walking, which face means effort, or whether death/jump is available for every enemy.

Record per asset family:

| Field | Required evidence |
|---|---|
| Source and role | Exact source path, body/tool/outfit/expression role, permitted use |
| Frame geometry | Cell size, atlas regions, valid frame count and transparent padding |
| Animation mapping | Semantic state, source row/regions, FPS/durations, loop or one-shot |
| Facing | Authored directions, permitted mirroring, exceptions for asymmetric equipment |
| Attachment | Ground pivot, body/face/tool offsets, layer order and supported combinations |
| Action timing | Contact frame/normalized marker, recovery and completion boundary |
| Coverage | Which unit/enemy variants have this animation; explicit missing-state fallback |

Do not carry guessed row indices between different sheets. Preview at least one complete loop/one-shot for every mapping, then verify it in gameplay. The idle-row-as-walk failure makes moving characters appear to float even when a frame counter is advancing.

## 22.2 Separate interface assets from displayed game content

When changing an atlas or panel texture, verify its actual corner dimensions and update nine-slice margins together. Render at the target UI scale: a valid texture path with stale slice margins can stretch ornaments across the whole panel.

Declare the asset policy before composing screens. A project may require one pack for all interface surfaces while using another for characters, equipment, resources and world content shown inside those surfaces.

When the user requires an **asset-only UI**, that includes panel/card backgrounds, buttons, tabs, HP/progress bars, slider tracks/handles, toggles, scrollbars, tooltips and their interaction states. Code-drawn replacement borders, rectangles, bars or icons are new visual design even when no image generator was used. An asset-only audit must inspect runtime drawing and style overrides, not just the image directory.

Code may arrange, slice, crop, tile, animate and apply approved tints to supplied assets. Use authored transparent variants where available; keep touch hit areas usable even when the visible control has little or no background. Do not invent extra item categories, currencies or systems from a pack's demonstration screen.

Keep a mapping of each UI component and state to its source asset. If a necessary element is missing, report the gap and obtain a design decision before substituting new artwork. Placeholder permissions in section 125.10 do not override an asset-only instruction.

Loopcremental example: Cartoon GUI Pack was designated for interface visuals; Pixel Plains for displayed characters, equipment and resources. These names describe that project's boundary, not mandatory packs for future games.

## 22.3 Compose a reusable base unit and reuse its renderer

For modular packs, use a reusable actor scene/presentation component with a stable root and clearly separated visual layers. Typical responsibilities are ground/shadow anchor, base body, outfit, expression, held tool/weapon, effects and selection/HP attachment points. The actual layer order and required children come from inspected assets; do not assume every pack supports independently composited clothing or faces.

- Share animation/appearance definitions across supported unit variants instead of duplicating frame arithmetic in each screen.
- Resolve the displayed class, outfit and weapon from the correct state snapshot. If equipment is planned for the next run, the current world actor must not adopt it prematurely. Unarmed actors hide weapon/tool layers during combat.
- Reset action-specific expressions/tools after recovery; use only supported body/outfit/expression combinations. Keep synchronized layers on the same pose phase rather than advancing them independently.
- Use the same presentation component for the world actor, inventory preview, portrait capture and animated drag preview, configured for each context. Preview mode must not tick combat, credit resources, alter the live unit or play unwanted gameplay sounds.
- Put artistic offsets, atlas definitions and animation parameters in editor-visible scenes/resources where practical (63.1, 67). Keep the ground origin stable and apply squash/hops to the visual branch.
- For finger dragging, offset the visible character beside/below the contact as approved, clamp it to the usable screen area, and keep the original pointer as the drop-test coordinate. A walking/effort preview is presentation only; do not drag the whole card when the operation moves one member.

Acceptance: change a preview layer or animation resource in the editor and inspect it without starting a live battle. Then verify idle, movement, unarmed/armed actions, gathering and death on representative valid combinations. Do not label unsupported combinations as implemented.

---

## 22.4 Pixel Plains and Kenney Fantasy UI: concrete implementation registry

Added from LootFarmer v0.6.3 (2026-10-19). These are **project-relative paths and implemented mappings for the supplied asset versions**, not universal row definitions for similarly named packs. Keep the original asset licenses and recheck the sheet when replacing a source. LootFarmer uses Kenney Fantasy UI for interface surfaces and Pixel Plains for displayed game content. This supersedes Cartoon GUI Pack only for LootFarmer; it does not change other projects' asset policies.

### Body/outfit mapping and shared renderer

`scenes/game/actor.tscn` and `scripts/game/actor_view.gd` implement the shared renderer. Its root is the stable ground point; `Visual` owns temporary recoil/hop offsets. The shadow, HP, marker and feedback do not move with the hop.

| Role | Source/mapping used in LootFarmer |
|---|---|
| Base body | `assets/PixelPlains/Characters 24x24/Basic character v2.png` |
| Outfit families | Within `Characters 24x24/`: Sprout = `Character 1 v2.png`; Robot = `Character 18 v2.png`; Dinosaur = `Special 3 v2.png`; Reaper = `Autumn 4 v2.png`. These sheets contain body pixels: replace the body texture rather than stacking a naked body underneath. |
| Boss/cat | `Autumn 4 v2.png` / `Gato 4 v2.png` in the same character directory |
| Shadow | `Characters 24x24/Shadow.png`, separate ground layer |
| Cell | 24 × 24 pixels; `Body.region_rect` selects one cell |
| Idle | Row 0, 8 frames, 5 FPS, looping |
| Walk | Row 1, 4 frames, 10 FPS, looping |
| Death | Row 2, 9 frames, 12 FPS, non-looping; 0.2 s final fade allowance |
| Effort | Row 3, column 0, used during the contact phase; not a claimed standalone unarmed animation |
| Facing | Mirror `Visual.scale.x`; preserve ground/world position |
| Attachment | Body at (0, −10), held weapon at (8, −8), attack sprite at (0, −14), shadow at (0, 0). These are this project's tuned offsets, not cross-pack defaults. |

The unarmed fallback is an approved visual hop/lunge with the effort pose, on `Visual`, without adding a sword or changing reach. Logical death immediately removes targeting/attack eligibility; the actor remains for its non-looping death presentation. Do not use a screenshot of a corpse as proof of death lifecycle correctness (13.4).

### Attack-sheet segments: one swing is not necessarily the whole sheet

Source directory: `assets/PixelPlainsAnimationPack/`. The implemented mapping is:

| Item art identity | Attack source |
|---|---|
| Wooden Sword | `Wood set/Sword 1 64x32.png` |
| Stone Sword | `Onix set/Sword 7 64x32.png` (intentional current mapping; retain or explicitly replace after visual review) |
| Iron Sword | `Iron set/Sword 2 64x32.png` |
| Death Scythe / boss scythe | `Onix set/Scythe 7 64x32.png` |

Frames are 64 × 32. The LootFarmer renderer uses **zero-based frames 0–4 for one swing, contact at frame 2**. Frame 5 begins another swing in the sequence used here. Playing the entire row once per authoritative attack previously showed two swings for one hit. This segment must be checked per additional weapon sheet; never infer it just from `64x32` in a filename.

Simulation timing: `contact = min(0.22, interval × 0.4)`; visible frame is `min(4, floor(attack_age / contact × 2))`; visible duration is `min(interval, contact × 2.5)`. Damage resolves once when authoritative windup reaches contact. The attack view hides the held weapon while the swing is visible, then restores it. Both player and enemies use the same contract. Cancellation, movement, target death, pause and upgraded attack speed must be tested; no animation callback also applies damage.

Reuse the **art identity**, not the gameplay item ID, for an evolved item that keeps its appearance. `catalog.art_id()` routes generated tiers back to the verified weapon/body mapping. Otherwise a newly named sword can lose its attack sheet and accidentally fall back to an unarmed hop.

### Icon crops, visible size and world/UI separation

`assets/PixelPlains/Items/16x16 All Items v1.png` has padding; its filename alone does not define every usable icon rectangle. Current currency resources are:

| Resource | Atlas crop `(x, y, width, height)` |
|---|---|
| `resources/game/coin.tres` | (104, 264, 16, 16) |
| `resources/game/gem.tres` | (137, 362, 14, 12) |

For other catalog icons, extract the declared frame first, then use that frame's opaque bounding rectangle (`Image.get_used_rect`) to remove padding. Do not crop the whole sheet and accidentally include adjacent icons. Keep a fallback for empty/invalid frames when accepting new assets.

Use keep-aspect-centered TextureRects for UI; `EXPAND_IGNORE_SIZE` lets the layout set the slot size. Use nearest filtering for these pixel icons. The HUD uses 44-pixel currency controls; notifications use 38-pixel currency icons. These sizes are layout targets, not universal required scale factors. A large control containing a heavily padded source still looks like a tiny icon.

World pickups normalize their longest visible side to about 14 world units; held weapon icons to about 12. Never reuse a UI potion scale directly in the world: that produced a giant potion covering combat. Slot shape remains square and independent of sprite aspect ratio. Cropping/scaling is presentation only; it never changes collision, hit reach or pickup eligibility.

### Kenney Fantasy UI border assembly

Normalized local folder: `assets/KenneyFantasyUI/`, from the supplied `kenney_fantasy-ui-borders` ZIP. Both sources below are 48 × 48 pixels. The reusable theme is `resources/game/theme.tres`.

| Surface | Source | Assembly in this implementation |
|---|---|---|
| Panel and button states | `PNG/Default/Panel/panel-015.png` | StyleBoxTexture with 6-pixel texture margins; content margins 12 left/right and 8 top/bottom |
| Inventory slots | `PNG/Default/Panel/panel-014.png` | StyleBoxTexture with 12-pixel texture margins; content margins 12 left/right and 8 top/bottom |
| Flat bar fill/background | Crop (20, 20, 8, 8) of panel-015 | Only the plain center is stretched; do not stretch the decorative border across a thin HP/XP bar |
| Slider handle source | Crop (12, 12, 24, 24) of panel-014 | Preserve square proportions |

Keep texture margins separate from content padding: one preserves the art, the other keeps labels away from the frame. Normal/hover/pressed/disabled states reuse the frame with approved tints. Do not stretch the entire 48 × 48 border into every aspect ratio. Do not treat these slice settings as automatically correct for every other Kenney panel number.

Tier backgrounds tint the slot's StyleBoxTexture, **not the icon or whole control**. This preserves the authored weapon/outfit colors and text contrast. Store the palette in data, keep an explicit tier number in item details, and never rely on color alone to explain progression. Same-art tiers retain source texture/crop, actor animation and consumable behavior through a stable art/family ID; gameplay identity, quantity, merge level and stats remain separate. Tier colors and balance formulas belong to the game's catalog/GDD, not this general asset rule.

### Fonts, retiring packs and verification boundaries

LootFarmer separates `assets/Fonts/DejaVuSans.ttf` (MSDF enabled) from UI pack folders. UI/world text uses a scalable font with suitable filtering; pixel sprites retain nearest filtering. A pixel-art game does not require rasterized, unreadable text. World text size must still be reviewed at every supported camera zoom.

Before deleting a retired pack, scan `.tscn`, `.tres`, `.gd`, `project.godot`, themes, bootstrap scenes and import/config references for its old directory. In LootFarmer, `ui/bootstrap_theme.tres` still referenced `GUIPackCartoon/Demo/Fonts/...` after the gameplay theme had migrated, preventing the main scene from loading. Move or replace fonts with their license before deleting their source pack. Test a clean import and both bootstrap and gameplay entry scenes; an already imported editor cache can hide missing source dependencies.

Evidence should distinguish source geometry, code/rule probes, rendered composition and phone acceptance (56.1, 68). LootFarmer's attack timing, inventory layout, touch routing and evolution/art-ID probes are automated evidence; these do not certify final phone visual quality. Add a sheet/frame preview and device check for each new asset variant before declaring that variant visually approved.

Cross-reference 121.8 for dynamic scroll children and 123 for stable panels. A card's correct asset slicing does not prove touch scrolling works: a PanelContainer still blocks input by default. Likewise, only one presentation owner should write selection-marker visibility; the shared actor renderer must not overwrite the world's selected-enemy marker each frame.

---

# 23. Never put an entire spritesheet in a portrait

This mistake produced milestone popups showing many tiny enemies at once.

Reusable rule:

```text
spritesheet -> frame extraction -> crop transparency -> scale frame
```

This applies to:

- Bestiary;
- shop icons;
- milestone cards;
- character selection;
- tutorials.

If portraits are generated dynamically, centralize the extraction helper.

---

# 24. Avoid pixelation by respecting source resolution

Pixel art tolerates integer scaling better than arbitrary enlargement, but very small sprites still look bad when blown up too far.

Recommendations:

- find a larger source variant;
- crop transparent margins;
- use integer-ish scale factors when possible;
- keep texture filtering consistent with pixel-art style;
- avoid stretching one axis independently.

---

# 25. Use Y-sort for battlefield actors

For a top-down 2D battlefield, coherent Y-sorting is preferable to manually tuning every `z_index`.

Recommended Y-sort groups:

- combat entities;
- Towers;
- Sheep;
- workers;
- props that should overlap actors naturally.

Static UI/world markers can use explicit draw order where needed.

Gold/resource pickups may need a deliberate priority so they stay visible near large buildings.

Y-sort only works when every sorted node's origin is its **ground contact point**. Compute each sprite's offset from the measured bottom row of its opaque pixels (a table per art variant) instead of nudging instances by hand, sort each group (plots, nodes, workers, units) in its own Y-sorted container under one Y-sorted root, and keep effects, floating text and selection markers in a separate layer above it (section 125.1).

---

# 26. Treat pause and modal state as game systems

A “freeze” may actually be:

- game tree paused;
- modal hidden behind another CanvasLayer;
- debug overlay intercepting input;
- popup opened while pause state persists.

Before debugging combat, inspect:

- `process_mode`;
- pause state;
- CanvasLayer order;
- visibility;
- mouse filtering.

If players can configure whether individual panels pause gameplay, define **pause ownership** explicitly:

```text
panel opens
-> panel decides whether it owns pause
-> child/unlock modal must remain interactive even if tree is paused
-> child modal closes
-> parent panel still owns pause
-> parent closes
-> gameplay resumes only if no other owner remains
```

Everfort exposed the failure mode directly: buying the first Tower/Miner while Skills was configured to pause opened an unlock popup that could not process its Continue button. Blocking/interactive modal layers were changed to process while paused.

Do not solve this by globally making the entire HUD interactive during pause. Only the UI that must function under that pause state should opt in.

## 26.1 A player's Pause is an authoritative gameplay lock

A player-owned pause that only stops the clock is an exploit: the player freezes the waves and keeps recruiting, training, buying and claiming. Make the pause a lock in the **action layer**:

```text
action_lock_reason() -> "Unavailable while paused" if the player's pause holds and a run is in progress, else ""
every block-reason function and every mutating action checks it first
```

- **One writer.** The pause owner mirrors the player's owner into the state layer; nothing else sets the flag. It is session state: not saved, not cleared by a run reset.
- **Enforce in the block reasons,** so every screen that already shows a reason shows this one, and in the mutating functions, so a path that skips the reason is refused anyway. Actions that returned nothing must start returning a reason. A new player action must check it too; never rely on a disabled button.
- **Keep reading open:** stats, codex, missions and their progress, entity information, settings, game speed. List what stays allowed in the design document as explicitly as what is refused.
- **Modal pauses are not the lock.** A results screen, a reward claim or a big confirmation owns its own pause for its own decision; locking it would soft-lock the player behind a hidden Pause button. Scope the lock to a run in progress, release the player's pause when the run ends, and defer offers that could not be taken while locked.
- **Say it once:** a banner (placed beside open panels, not under them) and a small tag in each panel header, plus the reason where buttons already show reasons (beside the cost, section 128.3); do not add a new line to every card.
- **Probe it without buttons:** pause in state, call every mutating function, assert each returns the reason and that the run and profile save data are byte-identical afterwards; assert reading works and nothing is locked between runs; then drive the real UI once.

Reuse (Growing Kingdom): `RunState.action_lock_reason()`, `Main.acquire_pause/release_pause`, `GamePanel` (Paused tag); `core_probe` "Pause locks every gameplay action".

---

# 27. Build Hard Reset alongside every persistent system

Every time you add a permanent system, update:

- default profile;
- save serialization;
- load;
- Hard Reset;
- the Prestige keep/reset table, when the game has one (section 110);
- live UI refresh;
- migration, only once the game is released (section 61).

Checklist:

```text
new persistent field?
-> default
-> save
-> load
-> reset (Hard Reset, and keep or reset at Prestige)
-> signal/update UI
-> probe check
-> migration: released games only (section 61)
```

Skipping one causes “ghost” progression after reset.

---

# 28. Reset run-transient worker state

A particularly subtle bug:

Workers still carried Gold into a restarted run.

For every worker system, define which state is:

## persistent

Examples:

- worker unlock;
- number of workers;
- speed level.

## run-transient

Examples:

- carried Gold;
- target;
- progress through current extraction;
- current path;
- temporary buff.

Run restart must clear transient state explicitly.

---

# 29. Save active-run state intentionally

If the game allows closing/reopening mid-run, decide which battlefield objects persist.

Good candidates:

- player/base HP;
- stage;
- current currency;
- upgrade levels;
- spawner progress;
- unclaimed pickups;
- resource nodes;
- worker carry;
- special run charges.

Do not stop at aggregate counters when reconstruction can materially change the run. Everfort initially stored only enemy spawned/alive counts; relaunch could reroll surviving archetypes and restore them at full HP. The corrected pattern snapshots the exact survivors that matter (identity, current HP, meaningful position) while still letting the unspawned remainder continue normally.

For moving workers, persisting carry alone is also insufficient if relaunch can skip travel or work. Save the minimum meaningful runtime phase/position/target/progress required to continue fairly.

Without intentional active-run state, players can exploit reloads or lose progress unpredictably.

---

# 30. Prevent reload exploits

For systems such as:

- shields;
- cooldowns;
- Mine reserves;
- Second Wind charges;
- worker carry;

ask:

> Can the player close/reopen to restore or duplicate value?

If yes, persist enough state to prevent it.

For timers where exact persistence is not worth complexity, resetting conservatively is often better than granting free value.

Also persist **processed transitions** when replaying the transition would duplicate progression. Saving only the stage and entity counts is not enough if relaunch can emit the same stage-clear event again and increment missions twice.

For claimable rewards, persist the unresolved reward itself until Claim consumes it. Otherwise a background save can advance `last_seen` and silently erase a Welcome Back reward before the player receives it.

Two more rules validated in Feed the Dragon's endgame:

- **Save irreversible *progression boundaries* at once; decide whether to coalesce frequent irreversible events.** Complete an assault, claim, defeat, Prestige and Ascension with one immediate atomic save. Frequent casualties in large fights can make per-event synchronous serialization and file flushing the dominant frame-time cost: Growing Kingdom v0.25 explicitly accepts up to **5 real seconds** of rollback in an interrupted fight, marking each death dirty while the established 5-second timer coalesces them into one write. Document that trade-off and test it; never silently weaken durability, and do not conflate it with a committed progression boundary. The stricter save-on-each-death policy remains appropriate for games that require zero rollback and can afford it.
- **Lock a currency between committing to a reset and completing it** when the reset erases that currency. Otherwise the player can convert about-to-be-erased currency into things that survive the reset. The lock should come with a reason string, and the confirmation should name the amount that will be lost and offer Cancel to spend it first.

---

# 31. Offline rewards should reuse normal multipliers carefully

A common implementation bug is:

```text
popup calculates base reward
claim path applies normal wallet multiplier
```

so the displayed amount differs from credited amount.

Better:

1. calculate final reward in one function;
2. display that exact value;
3. credit that exact value;
4. avoid applying the multiplier twice.

Centralize reward calculation.

For player trust and balance debugging, expose the actual formula as a receipt when the reward is important. A compact pattern is:

```text
Base rate × rewarded time = base amount
Bonuses: multiplier A · multiplier B · multiplier C
Total: credited amount
```

Do not show a simplified explanatory formula if it differs from the code that produced the credited value.

**Live and offline must share one timer function.** In Feed the Dragon every timer (construction, research, training, respawns, Hunger) advances through one `tick_timers(delta)` that both the live frame and the offline simulator call. A new system is offline-correct the moment it is live-correct, and there is no second rule to drift. Systems that must not advance offline (a real-time battle) are frozen explicitly inside that function, not skipped by the offline path.

**A rolled-back dry run must roll back every store it writes.** Feed the Dragon measures the offline window with a dry run of the same tick, then restores the state and runs the real pass. When missions added lifetime counters to a second owner (the profile), the dry run restored the run but not the counters, so every offline recruit and Meat fed counted twice. Snapshot and restore every owner the tick can touch, and keep a probe that checks one offline event counts once.

**Storage-capped offline resources: fit them when the receipt is made.** Growing Kingdom's frozen kingdom grants a share of storage per hour away, never past the free space. Compute the raw amounts in the one reward function, then fit each to the free storage when the receipt is created and save the fitted amounts in it: the receipt shows exactly what Claim will credit, and the state cannot change while the receipt waits (a true modal over a frozen run). A second absence before Claim adds raw amounts and is fitted again to the same space, so two receipts never add up past the cap; Claim credits the fitted amounts once and is not a delivery (no gathering counter or tutorial goal moves). Keep older receipts loadable: a receipt saved before the resource fields existed claims its currency only.

Reuse: `scripts/core/offline_simulator.gd` (`process_absence`) in Feed the Dragon; `ProfileState.compute_offline_reward()` / `set_pending_offline()` / `claim_offline()` in Growing Kingdom.

---

# 32. Separate repeatable run rewards, first-clear rewards, and mission rewards

Do not collapse every SP source into one opaque “stage reward.” Separate concepts explicitly:

- **repeatable run progress** — what every successful run earns;
- **first-clear progression bonus** — one-time reward for new territory;
- **mission reward** — authored/snapshotted objective payout;
- **earned multipliers** — permanent/prestige bonuses the player actually unlocked.

Everfort's final run-end model is a useful example:

```text
0.5 SP per stage actually cleared this run
+
one-time first-clear SP per newly cleared stage
+
Permanent Skill / Prestige percentage contributions
```

First-clear value increases by progression bracket rather than every single stage, making new chapters more valuable without explosive growth.

Avoid unexplained global multipliers that every player receives automatically. If a multiplier is not earned or tied to a mechanic, fold it into the base formula or remove it.

**Name the owner of a reward that fires at a reset boundary.** Feed the Dragon's GDD said "there is no Dragon-kill Meta Currency payout", while its one-time "Dragonslayer" mission paid 50 Meta at the kill, and the kill starts a Grand Prestige that resets Meta to 0. A reset-layer audit read that as a contradiction. Both were intended: the kill itself pays nothing, and the Mission system pays its one-time reward, claimable only after the Grand Prestige, so it lands in the new cycle. The fix was one GDD sentence naming the owner and the side of the reset the reward lands on, not a change to the reward. Reuse: the GDD §12 amendment of 29 September 2026 in Feed the Dragon, and `MissionState.claim_block_reason()` in `scripts/autoload/mission_state.gd`, which holds any claim while a Prestige is pending.

---

# 33. Reward screens should be receipts

Rare/meta currencies deserve transparent payout UI.

Show both the percentage and its actual numerical contribution:

```text
Run Progress                 +X SP
First-time Stage Clears      +Y SP
Permanent Skill +10%         +Z SP
Prestige Legacy +20%         +W SP
---------------------------------
TOTAL                        N SP
```

This teaches the economy and makes permanent bonuses feel valuable.

For grouped first-clear rewards, summarize chapter ranges instead of listing dozens of individual stages unless the player asks for details.

---

# 34. Snapshot mission rewards at assignment

When mission reward values depend on progression:

> snapshot the reward when the mission is created.

Otherwise the player can accept an easy mission, advance many chapters, and receive a much larger payout than the task was designed for.

Progression-anchor missions can use fixed authored payouts, while ordinary missions use a ceiling derived from the next progression milestone.

---

# 35. Mission difficulty and reward-currency rolls should be independent

A robust dynamic mission generator can choose:

1. difficulty;
2. reward currency;
3. compatible objective family.

This prevents the board from becoming rigidly divided into “Gold missions” and “SP missions.”

Everfort's useful final reference values were:

```text
Difficulty roll:
Easy 45% / Standard 35% / Hard 20%

Gold payout fraction:
50% / 75% / 100%

SP payout fraction:
20% / 40% / 60%
```

The reward-currency probability can itself be progression/skill-driven (for example, a permanent skill that raises SP-mission probability).

Keep stronger progression sources above ordinary mission farming in the economy hierarchy. A rare/Special tier can cleanly pay **100% of the same progression ceiling** while ordinary difficulties pay fractions of it, avoiding a second arbitrary reward curve.

---

# 36. Gate context-specific meta choices by content unlock

A meta/prestige choice should not appear if it affects only a subsystem the player does not have.

Examples:

```text
Tower-only boon -> require Towers
Sheep-only boon -> require Sheep
Miner-only boon -> require Miners
```

Exclude the card from the random choice pool entirely rather than showing a disabled/useless option.

Do **not** gate a mixed boon merely because one part is locked. If it already benefits the core game (for example Castle + Tower damage), it can remain eligible.

When counting “remaining meta content,” distinguish:

- unmastered boon definitions;
- remaining stack/pick count;
- currently eligible choices.

That lets the UI explain “more paths remain, but their systems are not unlocked yet” without spoiling the specific hidden options.

**List what is coming, but never sell it.** While Feed the Dragon's Military research had no units to affect (Phase 4), the Research panel still listed that family, marked "Arrives in a later phase" and not purchasable; it opened in the phase that built the units. The player learns the system's shape without spending on an effect that does nothing. Sell an entry only once its effect exists.

---

# 37. Design the post-campaign loop explicitly

A finite campaign should have an authored ending rather than silently looping.

Recommended first-completion flow:

```text
final stage clear
-> bank rewards
-> thank-you / campaign complete
-> optional community link
-> explain what progression remains
-> resolve any meta reward earned by the final clear
-> begin the post-campaign loop
```

If the final milestone itself earns a Prestige/meta choice, present the authored ending first and then grant that earned choice before the next run. Do not make the final campaign milestone the only major progression gate that silently withholds its normal meta reward unless that exception is deliberate and clearly communicated.

Subsequent final-stage clears can then become optional Prestige/reset opportunities if the game supports an ongoing post-campaign meta loop.

When all authored meta content is exhausted:

- explicitly say the player reached the end of current content;
- thank them;
- offer community/feedback link;
- let them continue sandbox/permanent progression if technically safe;
- show the full end-of-content message once, not every loop.

This is more honest and satisfying than pretending an endless loop is additional authored content.

**A layer above Prestige that restarts the climb.** Growing Kingdom's Ascension is earned by the final rival after every Prestige rank is owned; it grants a permanent token and a chosen modifier, then resets the Prestige layer for a new ascent. Rules that held up:

- the trigger is the end of the ladder, never an unrelated milestone, and its record holds no drawn options (the choice is made from the full list when it is taken), so a reload or a second conquest can neither reroll nor duplicate it;
- deferrable through the same surfaces as an ordinary Prestige, never blocking a new run, and committed as one saved transition (section 110);
- every cycle must be completable: if the ladder's length equals the pool's size, nothing a higher layer grants may remove a card from the pool (a modifier that unlocks the same building as a card would otherwise stall the ladder one step short);
- a hard cap with an honest end state ("fully Ascended"): the final rival then gives nothing more and forces no reset.

---

# 38. Avoid recursive proc systems

For effects such as:

- extra projectile chance;
- extra Tower shot;
- reflected damage;

explicitly mark secondary effects as unable to proc themselves.

Otherwise:

```text
extra shot -> extra shot proc -> extra shot proc...
```

can create runaway recursion.

---

# 39. Define damage order

For defensive systems, document exact order:

Example:

```text
raw damage
-> damage reduction
-> shield
-> HP
-> reflection based on actual HP damage
-> lethal check / Second Wind
```

Without a defined order, later systems will conflict.

When a defence trait depends on the attack's type (armour that blocks blows fully but arrows by half and magic not at all), it is one more step, between the target's damage reduction and its shield, and every hit must name its type (section 131.2).

---

# 40. Number formatting belongs in one utility

Incremental games quickly reach large values.

Centralize:

- decimal places;
- abbreviations;
- signed values;
- percentages.

For currencies and other large player-facing whole quantities, abbreviate starting at **1,000** (`1K`, `1.5K`, `125K`, `1M`, `1B`, `1T`). Keep significant precision for costs, and don't round wallets upward. Keep exact stage/wave numbers, timers and other identifying counts in their intended format. A space-constrained HUD should use this formatter before shrinking controls (section 19.1).

Do not manually format in each UI script.

---

# 41. Debug tools are not optional

For progression-heavy games, create debug tools early.

Useful controls:

- add currency;
- add premium/meta currency;
- jump stage;
- unlock system;
- reset run;
- save now;
- hard reset;
- force milestone;
- set Prestige.

This can save hours during balancing.

**Debug actions must call the real entry points.** A "Force Dragon kill" button that calls the same function combat will later call let Feed the Dragon build and probe the whole Grand Prestige flow before any combat code existed (section 110). A debug action that sets fields directly tests a state the game can never produce.

---

# 42. Build visual probes before final polish

For reusable UI/components, create debug scenes or controlled states that show:

- every enemy;
- every card;
- every modal;
- long text;
- max values;
- locked/unlocked states;
- phone reference size.

This is better than waiting for a rare game state to occur naturally.

For progression-heavy games, also keep **prepared save/debug presets** for states that are expensive to reproduce manually. Everfort used presets for mature panels, post-campaign state, tutorial choice, Hand Holding, and Offline Reward validation. A good preset should load a legitimate deterministic state through the game's real save/profile contract, identify exactly what it is meant to validate, and be safe to recreate after schema changes.

Reusable rule:

> Rare UI and progression states should be reproducible in seconds, not hours.

**Screenshot timing is not simulation timing.** A windowed capture's first frames hitch, and clamped frame steps advance less simulated time than the wall clock. A capture that must show a steady state should set that state up (resync, skip ahead) instead of waiting a fixed time for it.

**Capture the largest content case, not only a typical one.** Feed the Dragon's Grand Prestige preservation screen looked fine with five stacks in the capture and overflowed a real 1080 px screen when the tester owned every stack. Keep one scenario per list-like modal that fills it with every item the catalog can produce (`tests/showcase.gd`, scenario `grand_preserve_full`).

---

# 43. Static validation checklist for AI coding

When AI cannot run the engine, it should still do disciplined checks.

Minimum:

```text
res:// paths exist
scene resources resolve
callbacks exist
node paths exist
save keys handled
reset paths handled
changed ZIP verified
```

Never write:

> “tested in Godot”

unless Godot actually ran.

---

# 44. AI collaboration and the iteration loop

## 44.1 Roles

**Design conversation (ChatGPT or a chat agent).** Design decisions, system architecture, balance reasoning, small focused code changes, briefs for the repository agent, continuity documentation. **ChatGPT owns the post-freeze 19 non-English in-game catalogs (132.4), external competitor/keyword research, ASO strategy, game-name/genre localization proposals, store copy in 20 locales, screenshot order and subjects (screenshots carry no added text by default, section 87.9), trailer/video briefs and storyboards** (section 134). Research is not a claim of verified search volume without supporting data.

**Repository-aware coding agent (Claude Code).** Implementing a batch across many files, broad refactors, finding existing architecture, editor-scene work, running probes and audits, keeping the decision log and report current. **Claude owns Godot tooling/integration, game-specific scenarios, screenshot capture, video recording/FFmpeg production, and localization of every newly implemented player-facing string**. It uses the existing versioned shared toolkit rather than recreating it.

Do not prescribe exact files to a repository-aware agent unless necessary. Define:

- objective;
- constraints;
- acceptance criteria;
- known evidence.

Let the agent inspect the repository. The repository stays the authority rather than an enormous chat transcript: when an agent conversation has accumulated very large context or its prompt cache has expired, prefer a fresh session with a self-contained brief plus the current working tree. This reduces token waste and lowers the chance that stale conversational assumptions override current code.

**Human developer.** Plays the build on the physical device, judges feel, readability and balance, validates visual composition and the exported artifact, and approves design changes, marketing outputs and publishing. **Claude may commit after completing and validating a batch when authorized**; the human does not need to perform every routine commit.

## 44.2 The iteration loop that worked

Growing Kingdom's passes settled on this loop:

```text
define a focused batch (one brief)
-> implement the whole batch, with compile checks and the targeted probes of each change
-> expose a playable build early: tell the developer it is ready to play
-> the developer tests on a physical Android device while the agent verifies
-> fix concrete findings from both
-> one full regression suite once the batch is stable
-> commit the validated batch
```

Rules that make it fast without losing trust:

- **Automation exists to catch regressions, not to consume most of every feature cycle.** The smallest probe that can disprove a change runs while it is written; the related group runs when the feature is locally correct; the full suite runs once per stable batch (section 60.1).
- **Long simulations are separate tools for actual balance questions.** Pacing bots, multi-seed composition audits and long soaks run when the batch can materially change what they measure (an AI, economy, wave or map change), one at a time, with recorded profiles and seeds (sections 112, 112.1). A UI, copy or documentation change never triggers a multi-hour simulation.
- **Prepared deterministic scenarios replace long natural playthroughs.** A test save, a debug preset or a capture option that lands on the state in seconds is worth more than a run that reaches it in an hour (sections 42, 100).
- **Human device testing and automated testing complement each other.** Probes prove rules, layouts and persistence; the developer's hands find feel, touch comfort, readability at arm's length and balance impressions that no bot can. Neither waits for the other.
- **Make the batch playable early.** Implement every feature of the batch before the heavy verification, so the developer can build and play while probes and audits run. Waiting for every audit before the first playable build wastes the developer's parallel time.
- **While a device-testing round is still open, correction batches stay targeted.** Each correction gets its compile check and the targeted probe cases that can disprove it, one named case per acceptance item of the brief (Growing Kingdom's Android corrections: Healer cadence, lockout, multi-Healer spread, Attack Speed independence, Sanctuary counting; tutorial suspension and restore per panel; Prestige HUD at each screen shape; each Smart recruit and bulk mode). The full suite waits until the round settles, because the next device finding will change the batch again; the brief says so explicitly ("do not run the full suite yet"), and the report states that it was deferred and lists the device checks still open. Before a commit, the full suite runs once (section 60.1).
- **Report progress during long work.** A short "what is left, roughly how long" every twenty minutes or so; separate active work from unattended simulation time and say which heavy steps could be cut.
- **Record decisions as they are made.** Every choice the brief leaves open goes into the game's decision log with its reason and how it was validated; the report states what was actually run (section 43: never claim a test that did not run).

The older chat-only pipeline (AI design, AI implementation, static checks, human validation in Godot, targeted fixes, commit) still applies when the agent cannot run the engine: then the human runs every check, and the agent's report lists exactly what was only checked statically.

Reusable rule:

> Ship a focused batch to the developer's hands early, verify in layers while they play, run the full suite once, and keep long simulations for real balance questions.

## 44.3 Integer change numbering

Use one simple integer for each delivered project change batch: **1, 2, 3, ...**. Start at 1 when adopting this rule; increment by exactly one per subsequent delivered batch, including documentation-only batches. A batch can contain multiple fixes; do not increment once per edited file or test rerun. Use the same number in the project version, current GDD/status, release notes and patch name. Do not introduce dotted game-change versions such as 0.1.2. Preserve old releases as historical records instead of renaming them.

Android's internal `version/code` is a separate monotonic store counter and must never be lowered when starting change 1. Save schemas and pinned third-party/toolkit versions are also independent compatibility identifiers; do not renumber them to match a game change. Leave Android `version/name` blank when it inherits the project's integer version.


---

# 45. Avoid giant one-shot feature batches

Everfort grew quickly, and later batches sometimes introduced multiple interacting regressions.

For future games, prefer batches such as:

```text
one new system + its UI + persistence + reset + debug
```

instead of:

```text
five systems + visual redesign + save migration + balance pass
```

A batch can hold several related changes when one brief defines them and their acceptance criteria (Growing Kingdom's passes held five to nine items each); keep unrelated rebalancing and long audits out of it unless the batch's own changes need them. The exception is when a full ZIP/commit checkpoint is intentionally being consolidated.

---

# 46. Always design the reset path at implementation time

For a new system, answer these immediately:

- What happens on death?
- What happens on new run?
- What happens on Prestige?
- What happens on Hard Reset?
- What happens on app close?
- What happens on resume?
- What happens offline?

Write these into the design before code.

---

# 47. Mobile vs desktop recommendations

## Mobile

Prioritize:

- larger text;
- large tap zones;
- fewer columns;
- visible feedback;
- centered modals;
- touch scrolling;
- safe bottom margins;
- no tiny icons;
- short tutorials;
- landscape-safe spacing.

## Desktop

Can tolerate:

- denser UI;
- hover;
- smaller interaction targets;
- more simultaneous information.

But if mobile is primary:

> design for mobile first, then let desktop inherit the larger, clearer UI.

Do not design desktop first and shrink it later.

---

# 48. Performance considerations for Android

Before publishing:

- limit uncontrolled floating-text spam;
- pool projectiles/pickups if necessary;
- avoid excessive scene instantiation;
- cap particle/VFX counts;
- avoid large transparent textures when smaller cropped ones work;
- watch draw calls from many CanvasItems;
- verify y-sort cost with many entities;
- pause unnecessary processing when modals are open;
- test 1x and 3x game speed;
- test low-end Android hardware.

A simple-looking 2D game can still become CPU-heavy at high entity counts and accelerated time.

**Measure a mode against play on the same state before changing anything.** Growing Kingdom's late-kingdom report ("slow as soon as I enter Build mode") was reproduced with a deterministic dense fixture measured in three states of one game: normal play, the mode idle, the mode with its preview moving, each with frame time and a count of the suspect work (full scans, rule calls). The counts named the hot path at once: the build overlay listened to the general "state changed" signal, which fires on every death in a fight, and every notification rescanned all 630 placement anchors, each check walking every building and resource (about 90 ms a scan, several a second). Nothing about y-sort, drawing or UI rebuilds was involved; guessing would have optimized the wrong thing.

The fix pattern for any expensive validity preview (placement, targeting, area overlays):

- invalidate on the **changes the rule actually reads** (a version counter bumped where blockers are added or removed), never on a broad "something changed" signal;
- keep the answer for the **same candidate cell** while neither the cell nor the version changed; a pointer moving inside one cell checks nothing and redraws nothing;
- make one check **spatially local**: blockers gathered once per version into coarse buckets, so a check reads only what is near its footprint;
- keep **one rule path** and prove the optimization exact: a probe compares the cached, bucketed rule with the old full scan on every cell, before and after placing and removing something.

> Expensive build-preview validation should be event and cell driven and spatially local, not a repeated full-world scan.

---

# 49. Store-ready polish checklist

Before Play Store submission:

## Gameplay

- complete the GDD-defined primary playthrough or representative long-running/endless scenario;
- verify objectives, progression, completion/replay paths and optional systems **only when present** (e.g. campaign, Prestige, missions, automation, workers and offline rewards);
- no soft-lock, unreachable objective or exploitable state transition;
- save, resume, failure/restart and Hard Reset behave according to the game's own persistence contract.

## UI

- readable on actual phone;
- no clipping;
- no hidden buttons;
- panel/background dimensions contain their real content at min/max values;
- no text/button/progress-bar overlap or escape outside its intended surface;
- consistent margins, title placement, close/back placement and comparable control states;
- selected/focused/toggled styles preserve background readability;
- all scroll areas touch-friendly;
- all warning badges correct;
- every player-configurable paused panel can open/dismiss its child modals without soft-locking;
- tutorial cannot soft-lock; required onboarding completes correctly;
- offline modal readable.

## Assets

- no pixelated over-scaling;
- no whole spritesheets in portraits;
- correct highlight animations;
- consistent filtering;
- icons readable.

## Persistence

- fresh install;
- upgrade from previous save;
- background/foreground;
- force close;
- resume mid-run;
- reset.

## Android

- package ID;
- version code;
- version name;
- signed AAB;
- icon/adaptive icon;
- orientation;
- target SDK;
- permissions;
- Play App Signing;
- release build;
- install/play the **exact exported release artifact** that is intended for upload;
- confirm the player-facing version and Android version name come from one intended source of truth;
- increment Android version code for every replacement upload.

## Store

- authentic, correctly sized, language-neutral gameplay screenshots for every applicable device class, each a real render at its size, with no added promotional text unless the developer approved an exception (raw masters retained; section 87);
- genuine gameplay video exports, when selected for the store, validated as MP4 with proper transitions/audio handling (section 133);
- feature graphic prepared consistently with actual in-game presentation;
- short-form social videos (TikTok/Reels/Shorts): 10 masters, 9:16 1080×1920, about 15 s, derived from the approved trailer footage and music: 5 focused reframes and 5 full-landscape cuts with their text in the black bands; distinct feature-based hooks, real gameplay only, configurable copy inside platform-safe margins (section 133.5); never uploaded by Claude;
- one approved social posting-copy entry per master video: video-specific caption/description plus a concise set of relevant hashtags, with claims matching the footage and no automatic posting (133.6);
- researched and human-approved English title, short description and full description after a current Google Play metadata-policy check; localize only after that English source is locked (section 134);
- one validated UTF-8 Play AI-import localization package containing 20 logical locales (English source + 19 translations) using the locale tags accepted by the current Play Console surface; after import, compare the detected languages against the intended set rather than trusting the raw count (134.2 to 134.3);
- concise release notes, when needed, approved in English first and then translated using the locale identifiers accepted by the release-notes surface (134.5);
- accurate content rating, Data safety, privacy disclosures and permissions;
- country/region availability and **one-time paid** price; no ads, IAP, subscriptions, analytics, Crashlytics or tracking integrations;
- screenshots/video/store descriptions promise only features truly available in the shipping build;
- after submission/review starts, freeze feature scope and treat new changes as release-candidate stabilization unless a real blocker justifies reopening scope.

---

# 50. Reusable architecture template for the next game

A future project can begin with this conceptual structure:

```text
autoload/
  balance
  profile_state
  run_state
  save_service
  settings_state
  mission_state
  encyclopedia_state

systems/
  combat
  stage_generation
  rewards
  automation
  offline
  prestige

entities/
  player_or_base
  enemies
  pickups
  workers
  resource_nodes

ui/
  hud
  run_upgrades
  permanent_skills
  missions
  bestiary
  tutorial
  settings
  offline_reward
  debug

data/
  enemy_definitions
  milestone_definitions
  skill_definitions
  prestige_definitions
```

The important architectural rule is less about exact folders and more about state ownership:

```text
ProfileState = permanent/meta
RunState = current run
MissionState = mission lifecycle
SaveService = persistence
Balance = formulas/constants
scene scripts = presentation + local behavior
```

For a game with a living world (workers, nodes, buildings on a map), extend it:

```text
World scene   = presentation + agent behaviour, rebuilt from state by sync_from_state()
entity nodes  = runtime plans (paths, phases) + presentation; never saved
reservations  = in the state owner, never saved, cleared at every resync
UI            = reads getters, calls intents with block reasons; the world owns the selection
```

Section 116 describes that architecture in full; section 116.11 describes the variant validated in Growing Kingdom, where agent behaviour lives in state too and the whole run simulates headless.

---

# 51. Recommended first-week plan for the next small game

## Day 0
Finish/approve the GDD, bootstrap the clean project from the validated production baseline, configure new identity/package/orientation, create/configure the dedicated Android upload key, install/verify Android build dependencies/templates, export a release-signed Bootstrap APK, validate that exact APK on the physical Android target, and commit **Bootstrap / Checkpoint 0**.

## Day 1
Core loop only.

## Day 2
Enemy/content variety + fail/restart.

## Day 3
Permanent progression + debug.

## Day 4
Save/resume + UI mobile pass.

## Day 5
Campaign/meta system.

## Day 6
Automation/secondary loop.

## Day 7
Full device QA + store prep.

The exact timing may vary, but the key principle is:

> Do not build the fifth progression system before the first run can restart/save correctly.

---

# 52. Centralize external/community links

If Discord, support, privacy, store, or feedback URLs appear in several screens, define each URL once and route UI buttons through a shared helper.

Benefits:

- one place to update expired invites;
- fewer mismatched URLs;
- easier platform/browser handling;
- easier QA before release.

Community links fit naturally in Settings and major completion/end-of-content screens, but should remain optional and never block progression.

---

# 53. Persist valuable random offers before display

Any random offer the player may care enough to reroll should become persistent state as soon as the opportunity is created.

Examples:

- Prestige/boon drafts;
- rare shop inventories;
- chest choices;
- daily reward alternatives;
- randomized upgrade cards.

Reusable pattern:

```text
opportunity begins
-> roll choices once
-> persist exact IDs/order
-> display
-> relaunch restores same offer
-> selection/explicit abandonment consumes offer
-> only next legitimate opportunity rerolls
```

This prevents force-close/relaunch from becoming the optimal strategy.

**Roll at commitment, not at eligibility.** Feed the Dragon rolls Prestige offers only when the player confirms the irreversible Prestige, and shows them after that point with no cancel. Rolling when the player first becomes eligible would let them look at the offers and decline, which is a reroll by another name.

---

# 54. Rare content needs visual identity, not only higher numbers

A rare mission/event can reuse an existing mechanical difficulty tier and still feel special if presentation communicates rarity immediately.

Everfort Special Missions keep the normal mission layout and Hard objective target, but use a warm dark-gold surface, thicker gold border/glow, brighter header/reward text and gold progress fill.

Useful rule:

> Make the rare state recognizable at a glance without making it look like it belongs to a different game.

---

# 55. Give manual play a progression path when automation exists

Automation should be attractive, but a manual interaction does not need to become permanently obsolete.

Everfort's Mine tapping begins at low efficiency, then a cheap Permanent Skill can raise manual extraction to parity and slightly beyond the worker baseline.

This supports different player preferences while preserving the early-game incentive to discover automation.

---

# 56. Run a dedicated UI consistency audit before final gameplay QA

Do not let visual consistency remain an informal part of a long playthrough.

Audit the entire UI as its own phase:

- panel size vs content;
- padding/margins/alignment;
- typography hierarchy;
- button/toggle selected/hover/focus/disabled states;
- close/back placement;
- icon sizing;
- scrolling and touch hit areas;
- long-number/max-value states;
- layer/modal/pause interactions;
- multiple target aspect ratios;
- rare/special/locked/complete visual states.

Produce one consolidated issue list first, then fix it as a controlled batch. This prevents Stage 1–100 QA from being dominated by random layout corrections.

---

## 56.1 Audit source assets, editability and behavior separately

For every surface, inspect both the rendered result and how the developer can modify it. A pack-textured runtime control may satisfy asset provenance while still failing the editor-composition preference; an editor-visible placeholder may satisfy neither the required look nor the asset policy.

Use separate checks for asset/state provenance (22.2), editor tuning (63.1), geometry/readability, live interaction, and lifecycle behavior. Include HP bars, drag previews, tooltips, context buttons and transient feedback, not only the main modal panels.

Classify each applicable requirement/subsection as **verified, partial, missing, justified exception, or unverified**, with concrete evidence and any required modification. Reading every numbered heading or passing unrelated probes does not establish compliance. A preference still requires a reasoned choice: existing code or acceptance of appearance is not evidence that an editor-authored alternative would be fragile.

Distinguish a decision accepted in discussion, source inspected, automated behavior checked, rendered behavior reviewed, and physical-device validation. Do not turn earlier delivery claims or test counts into fresh evidence. Report deferred architectural work in the delivery summary, not only inside a long audit table.

---

# 57. Pull volatile runtime state at the save boundary

Do not continuously mirror every moving actor into profile state just to make saves accurate. That creates noisy ownership and unnecessary writes.

Better pattern:

```text
runtime actor moves normally
-> save begins
-> save coordinator asks live systems for a fresh snapshot
-> serialize that snapshot immediately
```

Everfort's Miner runtime exposed why this matters: a cached Dictionary updated only on carry/Mine events could be several seconds stale while the worker moved every frame. A save-boundary `force_sync_runtime()` preserved exact position/phase without turning profile state into a per-frame mirror.

---

# 58. Persist unresolved rewards until consumption

A reward is not safely delivered merely because its amount was calculated. If the player must press Claim, preserve the unresolved reward across background/kill/relaunch until the Claim action consumes it.

Reusable lifecycle:

```text
calculate final reward
-> persist pending reward
-> display modal
-> Claim credits exact persisted value
-> clear pending reward
```

This is especially important for offline/welcome-back rewards because updating `last_seen` before Claim can otherwise erase the interval that produced the reward.

---

# 59. Automated probes must create legitimate deterministic state

A regression probe can manufacture a false production bug if it directly mutates progression into a state real gameplay cannot reach.

Everfort exposed two common hazards:

- a fresh profile's tutorial chooser paused the tree before a physics-driven probe could advance;
- a probe unlocked Miner progression while tutorial mode was still unselected, so the tutorial Mine gate legitimately removed a restored Mine and made the test look like a persistence defect.

Rules for future probes:

- establish deterministic profile/tutorial/progression state **before** the main child scene initializes when necessary;
- prefer public/current state APIs over impossible direct field combinations;
- explicitly assert the tree is not unintentionally paused before physics/timer tests;
- give every test-state-machine phase a handler;
- add a default/unknown-phase failure path so stale tests fail loudly instead of hanging forever.

---

# 60. Diagnose stale tests before changing production code

When an old probe fails after intentional design changes, first classify the failure:

1. genuine production regression;
2. stale expected number/contract;
3. invalid test setup;
4. timing/pause harness problem.

Do not weaken production rules or rebalance the game merely to make an old assertion green. Everfort's Post-Checkpoint-6 probe still expected older Lifesteal/Health-Regen maxima, an obsolete Permanent-Skill presentation contract, and a Stage 12 resume on a profile whose legitimate cap was Stage 10. Modernizing the probe was the correct fix.

A useful rule:

> Tests are executable documentation, so when the documented game contract changes intentionally, the tests must be updated deliberately too.

### Regression fixtures must respect unlock gates and quiet-battle assumptions

When a feature becomes available only after a lifetime event (for example, Missions after the first Castle defeat), a fixture using that feature must set up the event through a suitable state transition or an explicit saved-profile fact **before** opening its panel, reading its board or testing its sound. Keep a separate test of the earlier locked state. Guard array indexing and panel method calls so a missing prerequisite reports a failed assertion rather than a misleading script error.

Similarly, a test that needs *no combat progress* cannot rely merely on distance after AI pursuit rules change. Freeze damage or cooldowns **inside that test's isolated fixture**, leaving movement, targeting, spawn caps and escalation logic real; protect a tiny attack force if the test is measuring timer suspension rather than battle difficulty. Never weaken production AI to satisfy an obsolete spatial fixture.

Treat engine `SCRIPT ERROR:` output as a failed run even when Godot returns a zero exit status. For a one-time reward issued during an interrupted save/load transition, validate the credited amount, persisted claim flag and **second relaunch** to catch duplication.

## 60.1 Test in layers and do not saturate the machine

Automated validation becomes counterproductive when every small edit launches the entire suite, several long Godot simulations compete for the same CPU and memory, or a balance audit is rerun even though the change cannot affect balance. More simultaneous processes do not automatically mean a faster result. Many gameplay and headless Godot workloads spend substantial time on one main simulation thread, while multiple instances still contend for CPU time, memory bandwidth, disk/cache access and scheduler time. Timing-sensitive probes can also become noisier under artificial machine load.

Use a layered validation policy:

1. **While implementing, run the smallest probe that can disprove the current change.** A stance change should start with the combat/world probe that owns stances, a card-layout change with the relevant layout case, and a save change with the lifecycle/save probe.
2. **After the feature is locally correct, run the related test group.** Do not run unrelated pacing, soak or balance work merely because code changed somewhere in the project.
3. **Run the complete regression suite once after the implementation batch is stable.** Rerun the full suite only when a subsequent fix can plausibly invalidate something it already covered.
4. **Run heavy simulations sequentially by default.** Whole-game pacing bots, balance audits, multi-seed combat sweeps, long soak tests, screenshot sweeps that open full scenes, and release exports should not compete with each other. Give one heavy Godot process the machine, collect its result, then start the next.
5. **Parallelize only cheap, independent probes when measurement proves it helps.** Cap ordinary probe concurrency at two processes unless the project has benchmarked a higher value on the actual development machine. Never choose concurrency from core count alone.
6. **Do not run validation that the change cannot affect.** Documentation-only edits do not need a combat audit; a UI-copy correction does not need a multi-hour pacing run unless the text is part of a measured layout contract.
7. **Prefer deterministic headless/state simulation over speeding up rendered gameplay.** If the simulation can advance authoritative state directly without rendering, use that path. Large visual game-speed multipliers can create frame-step artifacts and waste rendering work; they are not a substitute for a proper headless harness.
8. **Keep long audits outside the pass/fail regression suite.** Their results support design decisions and should be run deliberately with recorded profiles, seeds and assumptions, not every time the ordinary suite runs.

A practical AI/developer loop is:

```text
edit
-> smallest relevant probe
-> related probe group
-> relevant long audit only if the mechanic can affect it
-> complete regression suite once
-> physical/release validation at the appropriate milestone
```

If the team is unsure whether sequential or parallel execution is faster, benchmark one representative batch both ways and keep the measured policy. The goal is **shortest trustworthy feedback**, not maximum CPU occupancy.

This policy is the verification half of the iteration loop in section 44.2: while it runs, the developer is already playing the batch on a device. When a heavy run is needed, prefer a deterministic prepared scenario (a fixed budget, a preset save, a single recorded cell) over a full natural playthrough, and stop a run that has stopped answering its question (Growing Kingdom replaced an hour-long binary search with a few fixed-budget trials per recorded cell).

Reusable rule:

> Target the current risk first, run heavy Godot simulations one at a time, bound cheap-probe concurrency, and save the full regression suite for a stable batch.

---

# 61. Save compatibility depends on the development phase

Whether old saves must keep working is not a technical constant; it depends on whether players hold them. Decide it by phase, and make the phase change explicit, so an agent neither spends days on migrations for internal test saves nor destroys real players' progress after launch.

## 61.1 Pre-release / development (the default until the developer says otherwise)

Test a real serialize-to-disk/load cycle for the current schema. JSON numbers can return as floating point: normalize integral IDs and membership arrays before validation, and use canonical integer stage/map keys. An in-memory snapshot restore alone cannot prove save correctness. A permitted development reset must leave a fresh profile writable.

Old development saves carry **no compatibility obligation**.

- One current schema, an explicit `SAVE_VERSION`, defensive defaults inside the current schema, and a version mismatch that loads a fresh profile.
- When a schema or system changes substantially, old saves may be invalidated: bump `SAVE_VERSION`, or let the changed fields fall back to defaults, and reset to a fresh profile if that is simpler.
- Do not spend significant effort on migrations purely for internal development saves unless the developer explicitly asks for one. Say in the report which old saves will reset.
- Prepared test saves are builders, not stored files (section 100), so they survive schema changes for free.
- Changing a reward's layer, a table or a rule is then a table change plus its UI and probes (section 99), not a migration project.
- **Current-schema correctness is not a migration, and it is required.** Loading must still bring every value inside the current schema's bounds: a level above its upgrade's new maximum is capped, an unknown id is dropped, a missing field takes its default (Growing Kingdom caps every permanent-upgrade level at its maximum when a profile loads). That protects every later getter and costs a line per field. Converting or refunding what an old schema meant (a refund, a rank turned into levels) is a migration, and optional before release.
- **A new persistent field still needs its full lifecycle** (default, save, load, reset, a probe check; section 27), even when old saves may reset: the lifecycle is for the current schema, not for compatibility.

Everfort's pre-release cleanup removed its legacy migration ladder this way. Growing Kingdom built several field-level migrations for development profiles before this rule was stated (refunds and conversions when rewards moved between layers); they work, but under this policy such work is optional and needs a request.

## 61.2 Released / production

This policy changes **only when the developer explicitly declares the game released** (a public build that players keep progress in: open testing or a store release). From that point:

- player saves are a compatibility obligation;
- every schema change needs a deliberate migration, designed with the change and probed with real old save files (load once, load twice, load the migrated save, relaunch);
- destructive changes need backup and recovery consideration (keep the previous file, write atomically);
- old public saves are treated carefully: never silently reset progress a player paid for in time or money.

Record the declaration in the game's decision log and in the agent instructions (CLAUDE.md or equivalent), with the date and the first released `SAVE_VERSION`, so every later session knows which phase it is in.

## 61.3 Moving rewards between layers after release

When a released game moves a purchase or reward to another progression layer (section 3.2), migrate what players own:

- **Moving up a layer (a permanent upgrade becomes a higher-layer reward):** retire the old purchase with a refund computed from the loaded file: add back what was paid, drop the level, save at once and say so once. Loading the same old file twice gives the same result, and the next save no longer holds the level, so it is paid exactly once. It is not new lifetime currency and does not fill progress meters.
- **Moving down a layer (a Prestige card becomes a permanent upgrade):** the player chose it instead of other cards, so **convert what was earned, do not refund it**: a rank becomes the same number of levels (`max(level owned, rank)`, capped), computed from the loaded file. State the consequence once: the levels now belong to the lower layer and reset with it. Do not keep a hidden legacy floor that survives resets.
- **Saved offers may hold a retired card.** An offer is never rerolled (section 53), but a card that no longer exists cannot be granted: re-draw only that card, from its old category's eligible cards, with the profile's saved RNG, keep the others, and save at once.
- **Gates added to a run in progress:** keep what a run already built or paid for (never downgrade a run in progress) and apply the gate to new actions; drop saved offers that became impossible (an unfinished mission) and refill them; never reroll a saved offer that is still valid.
- Probe: an old profile beyond the new maximum, an offer holding the retired card, loading the file twice, loading the migrated save, and a real relaunch.

Growing Kingdom validated each of these on development profiles (`ProfileState._refund_retired_upgrades()`, `_move_prestige_to_meta()`, `_redraw_retired_offer_cards()`; `lifecycle_probe` migrate phases), which makes them ready-made for a released game.

Reusable rule:

> Before release, old development saves may reset; after the developer declares the game released, every player save is a compatibility obligation with probed migrations.

---

# 62. Final recommendations

For the next game:

1. Start Android-first from the first UI scene.
2. Establish a 1920×1080 reference layout immediately.
3. Use 3-card rows for full-screen progression screens and 2 in side panels, unless testing proves otherwise.
4. Add a Current Stats panel early, with a Current Boosts summary once there are several meta layers.
5. Create Hard Reset before adding many permanent systems.
6. Save active-run state before implementing offline systems.
7. Add warning badges as soon as claimable/affordable menus exist.
8. Inspect the full asset pack before scaling any image.
9. Use representative sprite frames for UI portraits.
10. Add contextual teaching hooks while systems are built: teach on first encounter, keep the rule in a reference surface.
11. Give automation visible world feedback.
12. Let a repository-aware agent work in the repository; when an agent cannot, have it deliver changed-files patches against a named baseline (section 98).
13. Commit after every validated feature batch.
14. Keep a living `.md` continuity file from the beginning.
15. Persist valuable random offers before displaying them so relaunch cannot reroll them.
16. Define pause ownership for every modal/panel combination.
17. Offer tutorial depth when the audience spans beginners and experienced players.
18. Run a dedicated UI consistency audit before full campaign QA.
19. Pull volatile actor state at the save boundary instead of maintaining stale cached snapshots.
20. Make automated probes establish legitimate deterministic tutorial/progression state before runtime assertions.
21. Classify failing probes before changing production behavior; stale tests are not regressions.
22. Keep pre-release save compatibility simple: old development saves may reset until the developer declares the game released (section 61).
23. Reserve the final phase for cleanup, balance, Android performance, and Play Store compliance.
24. Cap subjective AI UI/environment iteration and hand final alignment to the editor when practical.
25. Classify asset sheets before deciding to stretch, tile, slice, crop, or animate them.
26. Preserve successful asset implementations in a project registry so later AI sessions reuse them.
27. Validate major responsive UI changes on a physical Android device before calling them finished.
28. Prefer authored palette variants over generic tinting for major progression visuals.
29. Use one coherent panel family and reserve visual exceptions for semantic meaning.
30. When following an asset-author reference, preserve its composition grammar without copying irrelevant decoration.
31. Convert validated human corrections into reusable contracts, registries, helpers, or documentation instead of solving the same problem from scratch in the next game.
32. Never stack an older changed-files patch over a newer tree without reconciling overlapping files against the latest full project.
33. Treat a major design reversal as a migration across runtime logic, UI, debug tools, tests/probes, persistence, and docs.
34. Maintain deterministic prepared saves/debug presets for rare UI states and expensive progression states.
35. Derive branding from the actual game's asset language before reaching for generic genre conventions.
36. Test the exact exported release artifact on the real target device before declaring the game finished.
37. Use one source of truth for the human-readable application version and a separate monotonic store build code.
38. Align float display precision, UI refresh precision, and completion tolerance.
39. Rebalance currency sources and sinks together rather than buffing rewards or cutting prices in isolation.
40. Make offline and high-value reward screens show auditable calculation receipts.
41. Switch from feature development to release stabilization once a real store candidate exists.
42. Reconcile continuity docs with the latest full project at major release milestones.
43. Start every new game with an approved GDD, then a repository audit and automated **Bootstrap / Checkpoint 0** that establishes the new Android identity, dedicated upload key, dependencies/templates and signed physical-device validation before gameplay implementation.
44. Put a focused batch in the developer's hands early, verify in layers while they play, run the full suite once per stable batch, and keep long simulations for real balance questions (sections 44, 60.1).
45. Give every progression layer one job: steady capability in Permanent, choices in Prestige, starting-state and rule changes in Ascension (section 3).
46. Give every UI surface one question: HUD status, context actions, management configuration, Stats effects, reference meanings (section 16).
47. Lead every card with its value, keep one short line, put the block reason beside the cost, and never let a warning change a card's height (section 128).
48. Choose named states from a dropdown, never by cycling; keep one rule for every surface that edits the same list (section 129).
49. Enforce every rule (the pause lock, tier gates, block reasons) in the action layer, never only in a disabled button (sections 26.1, 123.3).
50. Give stances mechanically distinct behaviour, not different radii (section 130.4).
51. Create army diversity with soft counters that specialists answer, not with raw stat escalation (section 131).
52. Decide what a UI number answers before choosing what it counts: allocation counts assignments, throughput counts the agents executing the task (section 124.2).

The biggest process improvement for future games is not a single code technique.

It is this:

> **Design every feature together with its mobile UI, save behavior, reset behavior, feedback, and validation path.**

That is what prevented the later versions of Everfort from becoming an unmanageable pile of independent systems.

# 63. Keep an asset implementation registry

A reusable asset workflow should record not only **which file** was used, but **how it was successfully used**.

Before an AI or developer implements a visual from an existing asset pack:

1. inspect the source asset/sheet;
2. search the current project and continuity docs for prior implementations of that asset family;
3. inspect the owner/reference presentation when available;
4. classify the source: finished sprite, animation, 3-slice, 9-slice, or compositional/tiled sheet;
5. identify fixed regions and repeatable/stretchable regions;
6. preserve any validated/manual tuning already present in the latest project;
7. only then decide whether to crop, tile, 9-slice, duplicate, or scale.

Record successful implementations with:

```text
asset/source path
semantic role
scene/node using it
assembly method (crop / frame / 9-slice / tile / repeated pieces)
important sizing/filtering constraints
known visual failure modes
manual tuning that should be preserved
```

This avoids repeating asset mistakes in later games or later AI sessions.

### Everfort example — Tiny Swords Wood Table

The Wood Table exposed the difference between a compositional sheet and a stretchable rectangle.

A wide Run Upgrade dock looked wrong when the wood center was simply stretched: wood grain distorted and the authored turquoise corners lost visual weight. A better treatment repeats the authored middle/center pieces and preserves corners/edge pieces.

Conceptually:

```text
corner | repeated top pieces | corner
edge   | repeated center     | edge
edge   | repeated center     | edge
corner | repeated bottom     | corner
```

When artistic adjustment is expected, represent these parts as **editor-visible UI nodes** so they can be moved/resized in Godot instead of burying every adjustment in procedural constants.

Reusable rule:

> If stretching visibly changes the authored character of a pixel-art UI asset, investigate tiling/repetition or proper slice composition before accepting the stretch.

---


## 63.1 Prefer editor-modifiable visual composition when practical

For visual placement and composition work, prefer **editor-modifiable nodes/resources** over code-only positioning when the editor-based approach is reliable, maintainable, and responsive enough for the project.

Why:

- visual corrections can be made directly in Godot;
- the result can be inspected immediately without a code/edit/export cycle;
- small artistic alignment changes are easier to tune by eye;
- future iteration is less dependent on hard-coded offsets and procedural constants.

Examples include terrain decoration, shoreline VFX markers, UI composition pieces, and other elements whose final placement is primarily visual rather than behavioral.

This is a **preference, not an absolute rule**. Use code/procedural layout when it is clearly better for correctness, responsiveness, scalability, data-driven behavior, runtime generation, or long-term maintainability. The project's technical needs take priority over editor convenience.

Reusable decision rule:

> If both approaches are robust, favor the one that leaves visual tuning editable in the Godot editor. If editor-driven placement would make the system fragile or difficult to maintain across resolutions/states, use code instead.

### Practical acceptance for editor-modifiable composition

Use `.tscn` templates for reusable HUD/panel/card/actor composition and Theme/resources for shared skins, atlas/animation definitions and tunable visual values when reliable. Scripts bind state, populate instances and handle responsive rules. Runtime-generated lists can instantiate editor-authored cards; dynamic content does not require code-only artistic composition.

Verify editability with a real task: can the developer open a representative scene, see a safe sample/preview, adjust a panel margin, bar texture, sprite attachment or font style, and retain that change at runtime without editing source code? Runtime overrides must not silently replace the authored value. A root-only scene that constructs all visual children in code, or a shared Theme containing only a font, is not equivalent to editable screen composition.

Where code is necessary, document the specific reason and expose meaningful tuning through exported properties/resources. Do not add a collection of cosmetic exports while still burying the actual layout in hardcoded factories. Preserve the conditional preference above; do not force fragile manual placement for genuinely procedural geometry.


# 64. Have a confirmed ADB path for Android iteration

Godot one-click deploy is convenient, but the production workflow should not depend on the editor successfully exposing the device.

Everfort confirmed this failure mode directly: `adb devices` detected an authorized phone while Godot still showed no one-click deployment target. Direct ADB installation worked on the physical phone and became the accepted fallback.

Generic flow:

```text
export debug APK from Godot
-> adb devices
-> adb install -r <apk>
-> launch/test on phone
```

Typical commands:

```bat
"<Android SDK>\platform-tools\adb.exe" devices
"<Android SDK>\platform-tools\adb.exe" install -r "<build folder>\<app>.apk"
```

Optional launcher command when the package ID is known:

```bat
"<Android SDK>\platform-tools\adb.exe" shell monkey -p <package.id> -c android.intent.category.LAUNCHER 1
```

`-r` replaces/updates the installed package and normally preserves app data when package/signature compatibility is unchanged.

Once validated for a project, record:

```text
Android SDK path
JDK path
build output directory
package ID
exact install command
optional launch command
```

A small `.bat` wrapper can later reduce the loop to:

```text
Export -> deploy script -> test
```

Reusable rule:

> If ADB sees the phone and direct install works, do not spend excessive iteration time debugging an optional editor deploy button.

# 65. Cap subjective AI visual iteration

Repeated UI/environment micro-adjustments can become slower and less reliable when every 1-3 pixel change goes through another AI implementation pass.

Everfort adopted this rule:

```text
maximum 4 implementation iterations per UI/environment section
```

After that:

1. stop the AI redesign loop;
2. describe the exact remaining adjustment;
3. hand visual tuning to the editor when possible;
4. only continue AI implementation if the user explicitly approves going beyond the cap twice.

Parser/runtime fixes caused by the implementation itself do not count as subjective redesign iterations.

Why this helps:

- prevents over-polishing one small area while the rest of the game waits;
- reduces regression risk from repeated scene rewrites;
- encourages editor-visible composition;
- preserves user control over final artistic placement.

Reusable principle:

> Use AI to establish the system and composition; use the editor for the last subjective alignment when the project supports it.

---

# 66. Classify authored UI assets before choosing stretch, tile, slice, or crop

Do not assume every rectangular image is meant to be stretched.

Before using an asset sheet, classify it:

```text
finished sprite
animation strip/sheet
3-slice
9-slice
compositional/tiled sheet
fixed decorative element
```

Then identify:

- fixed corners/caps;
- repeatable center pieces;
- safe stretch axes;
- transparent padding;
- owner/reference assembly;
- existing project implementation.

## Everfort Wood Table lesson

The Tiny Swords Wood Table looked wrong when stretched across the Run Upgrade dock. The wood grain distorted and authored corner hardware lost weight.

The successful approach was:

```text
corner | repeat top | repeat top | corner
edge   | repeat center           | edge
edge   | repeat center           | edge
corner | repeat bottom           | corner
```

The final project kept only the tiled/editor-visible version after desktop + Android validation.

Reusable rule:

> When stretching changes the authored character of pixel art, preserve the fixed pieces and repeat/tile the intended middle regions instead.

Do not keep a failed comparison implementation after the direction is chosen; remove obsolete variants so future developers do not mistake them for supported options.

---

# 67. Prefer editor-visible artistic composition, but keep responsive rules in code

The best hybrid approach is often:

```text
code owns responsive/system behavior
editor-visible nodes own artistic placement
```

Everfort's shoreline foam exposed why. Code-generated side foam was technically repeatable but repeatedly landed as obvious isolated rectangles in open water. Refactoring the sensitive pieces into editor-visible marker nodes let the user drag them into the authored terrain contour immediately.

Good candidates for editor-visible composition:

- terrain decorations;
- shoreline/corner VFX;
- UI frame pieces;
- decorative title elements;
- manually tuned authored asset assemblies.

Good candidates for code-driven behavior:

- resolution/safe-area adaptation;
- procedural data-driven content;
- runtime-generated lists;
- world-to-screen conversion;
- state-dependent visibility;
- repeated geometry whose placement is algorithmically stable.

The two can coexist. For example, an editor-authored foam group can still inherit a responsive parent transform so it remains aligned on wider phones.

Reusable principle:

> Editor control should improve artistic tuning without sacrificing responsive correctness.

---

# 68. Real-device validation must happen before declaring responsive UI complete

Desktop reference layouts can hide failures that only appear on a real phone.

Everfort caught all of these only during Android testing:

- a Run Upgrade frame edge positioned through a desktop-width compensation disappeared on the wider phone viewport;
- top-HUD content sat too close to the physical display edge;
- right-side controls needed safe-area-aware placement.

For every major HUD/panel batch:

```text
reference desktop test
-> physical Android test
-> only then call responsive layout complete
```

Use the platform safe area for interactive content. It is acceptable for noninteractive background bands to extend to the screen edge while actual controls receive inset padding.

Avoid solving responsiveness with giant hard-coded offsets. Anchor structural UI to the correct parent edge and apply safe-area logic at the container level.

**Make the layout pass a probe before the device pass.** Feed the Dragon's layout probe opens the real main scene at four screen shapes (20:9 and 19.5:9 phones, 16:9, a 4:3 tablet) × three inset cases (none, a left notch, a right notch, each with a gesture bar). For each it opens every side panel with the context overlay and a toast, a Wrath state, a tutorial card, the Help captions and every modal, and checks that every visible control is inside the safe area, every button meets the touch minimum both ways, and no HUD group overlaps another, the open panel or the toast. It found four real defects in a HUD that looked right at 1920 × 1080 (a toast over the open panel, a warning banner under a panel, the dock rising into the top row above a gesture bar, a meter covering the economy chips under a notch), and keeps them fixed. A debug-only safe-area override (`--debug-safe-area=left,top,right,bottom`) lets a desktop, the probe and the Debug panel reproduce a notch. The physical device still decides touch comfort; the probe removes everything a machine can check first.

Reuse: `tests/layout_probe.gd` and `LayoutService.debug_insets` in Feed the Dragon.

---

# 69. Show combat progress truthfully

A progress meter should communicate the mechanic that actually triggers the event.

Everfort's enemy special attacks are action-count driven, so the improved UI shows values such as:

```text
0/4
1/4
2/4
3/4
4/4 -> special
```

rather than implying a continuous timer.

The same principle applies to:

- hits until proc;
- charges until ability;
- workers until capacity;
- combo steps;
- stacks until effect.

Use a familiar bar visual if helpful, but keep the displayed unit truthful.

Also keep stacked combat information spatially distinct. Everfort moved enemy HP text inside the HP bar and placed the special meter above it so two systems no longer occupied the same vertical space.

Reusable principle:

> A polished meter that lies about the trigger is worse UX than a simpler meter that tells the truth.

---

# 70. Reuse one panel family and reserve exceptions for semantic meaning

A full UI pass should not invent a different frame language for every screen.

Everfort's main-panel direction became:

```text
normal information/progression -> Standard Paper family
rare/prestige                -> premium dark/gold or SpecialPaper family
section heading              -> small ribbon
screen identity              -> large ribbon / authored title treatment
```

A shared family should standardize:

- title placement;
- close/back placement;
- padding;
- card spacing;
- button states;
- scroll behavior;
- touch targets.

Exceptions should communicate meaning, not novelty.

Examples:

- Special Missions may keep a distinct warm/gold identity because rarity matters;
- Prestige can use premium visual treatment because it is rare/meta-defining;
- ordinary Skills/Missions/Statistics should still feel related.

Reusable rule:

> Build a visual grammar, not a collection of unrelated pretty screens.

---

# 71. When mimicking an asset-author reference, preserve its composition grammar rather than copying irrelevant decoration

Reference images are often more useful than the raw sprite sheet because they reveal intended assembly.

For Everfort's Bestiary, the Tiny Swords “Enemy Pack” reference established the important grammar:

- parchment board;
- large gold ribbon title;
- decorative double swords behind the title;
- compact enemy-cell grid;
- unknown slots represented simply;
- authored enemy art displayed directly in cells.

Everfort intentionally ignored irrelevant lower decoration from the reference and retained its own useful information architecture: selected-enemy details above, selector grid below.

This is the right kind of adaptation:

```text
preserve visual grammar
+ preserve game-specific information needs
- copy decorative parts that do not serve the game
```

For discovered enemies, using real authored Idle/Walk/Attack animations in the selector can create strong identity without inventing new portraits. For undiscovered entries, a simple `?` is clearer than a fake silhouette when the reference already establishes that language.

When using relative stat bars, keep exact numbers and meaningful text visible. Bars are a comparison aid, not a replacement for data.

---

# 72. Preserve learned enemy rhythms across Elite variants

If a special attack is triggered after a learned number of actions, Elite versions should normally preserve the same cadence unless changing it is itself a deliberate mechanic.

Everfort settled on:

```text
Warrior  special every 3 attacks
Archer   special every 4 attacks
Lancer   special every 4 attacks
Monk     support special every 3 actions
```

Elite variants keep that rhythm and become more dangerous through stats/effects rather than secretly changing the timing.

This improves readability and player learning:

> Elite should feel stronger, not arbitrarily less predictable.

---

# 73. Use authored palette variants before tinting important progression visuals

For major progression rewards, a simple runtime tint can look cheaper than an asset pack's authored color variants.

Everfort originally tinted the Blue Castle for Prestige progression. A better result came from using actual authored Castle palettes:

```text
base        Blue
lower tier  Yellow/Gold
mid tier    Purple
high tier   Black
```

Red remained enemy-only because color already carries faction meaning.

Reusable rule:

> Before adding a shader/modulate tint to an important progression visual, search the asset pack for authored palette variants. Use the artist's version when it communicates the same state cleanly.

# 74. Never use double dashes in written text

Do not use double dashes (`--`) in player-facing text, documentation, prompts, release notes, or other authored prose.

Use punctuation that fits the sentence instead, such as a comma, colon, semicolon, parentheses, or an em dash.

Reusable rule:

> **Never use `--` as punctuation in written text.**

---

# 75. Fractional currencies should be real values, not hidden remainder systems

If a visible percentage bonus can produce fractions, prefer storing the resource as a fractional value instead of accumulating hidden remainders.

Example:

```text
base pickup = 1 Gold
bonus       = +40%
credit      = 1.40 Gold immediately
```

Benefits:

- the wallet always matches the reward the player actually earned;
- save/resume is easier to reason about;
- UI receipts can expose the bonus honestly;
- no delayed threshold payout creates confusing third-pickup jumps.

Whole-number prices can still subtract from a fractional wallet. Audit every serialization, mission, statistic and formatter path so no accidental integer cast reintroduces truncation.

Reusable rule:

> If the economy promises a fractional bonus, preserve the fraction end to end.

---

# 76. Repeated UI tweens must be idempotent under rapid updates

A subtle UI bug appeared twice in Everfort:

- rapid Run Upgrade purchases permanently tinted cards;
- repeated Mission progress updates made the progress bar and text grow larger and larger.

The shared failure pattern was:

```text
new animation starts
-> reads current animated scale/modulate as the new base
-> previous animation has not restored yet
-> effect compounds
```

Safer approaches:

- keep a stable original/base value;
- cancel/replace the previous tween before starting a new one;
- animate a disposable child/feedback element instead of the structural container;
- avoid scale punches on controls that can update many times per second or while hidden.

Reusable rule:

> Animation feedback must tolerate re-entry. Rapid legitimate updates must not permanently mutate layout or color.

---

# 77. Do not replace a shared utility with a partial rewrite

When hardening a shared UI helper, preserve its full public contract. Everfort temporarily replaced `UiFx` with a file containing only the newly edited animation helpers and accidentally removed established methods such as `style_button()`. That caused parse failures across many unrelated screens.

Before replacing a shared helper:

1. enumerate its public functions/resources;
2. merge the targeted change into the current full implementation;
3. search all call sites;
4. statically verify the expected public API still exists.

Reusable rule:

> Patch shared infrastructure by merging, not by reconstructing from the one function currently under discussion.

---

# 78. Reuse visual language, not interaction type

Everfort reused the Zoom slider's polished visual language for Settings. That was correct for continuous SFX/Music volume, but using draggable sliders for binary Mute or Pause Panel controls felt annoying on a phone.

Better rule:

```text
continuous value -> slider
binary value     -> checkbox/toggle/button
```

The two controls can share colors, track/thumb motifs and touch sizing without forcing the same interaction model.

Reusable rule:

> Consistency should make controls feel related, not make different decisions behave identically.

The full table of which control fits which decision, including dropdowns for named states, is section 129.1.

---

# 79. Support AI should evaluate while moving, not only after arrival

A healer that only checks for wounded allies after reaching its final stand-off position can walk past valid support opportunities. Everfort's Monk improved when it continuously scanned while advancing, stopped when a wounded ally entered range, healed, then reevaluated movement.

General support-unit loop:

```text
move toward preferred formation position
-> continuously scan for valid support target
-> if valid target enters range, stop and act
-> reevaluate
-> resume movement when no support action is available
```

Keep formation intent separate from support range. A rear-line healer can stand behind ranged attackers while still interrupting travel for urgent support.

---

# 80. Worker assignment should spread naturally before stacking

When several workers can service several resource nodes, always choosing the first valid node makes the whole system look artificial and wastes the visual value of multiple nodes.

A useful assignment rule is:

```text
valid nodes
-> prefer nodes with no worker already assigned
-> randomize among free nodes
-> if none are free, randomize among all valid nodes
```

Once chosen, keep the assignment stable through the work cycle. Whether to keep it across save/resume depends on the design: with many interchangeable workers, not saving it and letting every worker re-plan on load (claims rebuilt from scratch) proved simpler and invisible to players (sections 116.2, 120.2).

This provides natural distribution without forbidding multiple workers from sharing a node when workers outnumber nodes.

On a large map, randomizing among **all** free nodes sends workers across the map. Feed the Dragon picks randomly among the **nearest three** free nodes, and a claim reserves a trip's worth of stock, so a node is shared only while its unclaimed stock still covers another trip. See section 115.2.

---

# 81. Name upgrades by the resource they actually modify

Generic labels such as **Mining Yield** become ambiguous when one activity can produce several resource types. Everfort's Miners can produce Gold or discover Skill Points, but the yield upgrade affects Gold only. Renaming it **Miner Gold Yield** communicates the contract immediately.

Reusable naming pattern:

```text
[system/source] + [resource/stat] + [effect]
```

Examples:

- Miner Gold Yield
- Sheep Gold Bonus
- Offline Gold Rate
- Tower Attack Speed

If an upgrade excludes another plausible resource, say so explicitly in its description.

---

# 82. Mobile readability often requires reallocating world space, not only enlarging UI

Simply making bottom controls larger can overlap gameplay. Everfort improved the phone layout by shifting the battlefield upward, reducing unused sea space above, and deliberately reserving more vertical area below for Run Upgrade controls.

Think of the screen as a fixed budget:

```text
noninteractive decorative space
+ gameplay space
+ persistent HUD space
= device viewport
```

When a mobile control needs to grow, identify low-value decorative space that can be reclaimed instead of blindly overlaying more UI on combat.

---

# 83. Constrain decorative trajectories to believable environment boundaries

A physical pickup can be mechanically correct but visually wrong if its arc ignores terrain. Everfort's Mine Gold could fly over the settlement mountains until the toss was constrained below the cliff boundary.

For decorative tosses:

- constrain landing positions;
- constrain arc apex;
- preserve reward mechanics independently from the visual path;
- use environment boundaries as visual rules even when they are not collision bodies.

Reusable rule:

> Physical-looking feedback should respect the visual world's implied geometry.

---

# 84. Final mobile acceptance should precede long-form balance QA

A Stage 1-100 playthrough is too expensive to repeatedly interrupt with basic layout defects. Everfort's final workflow became:

```text
UI consistency audit
-> desktop check
-> physical Android acceptance
-> concrete responsive fixes
-> freeze major UI scope
-> full gameplay/balance QA
```

This keeps long-form QA focused on progression, balance, persistence, exploits and softlocks instead of rediscovering obvious touch/readability problems.

---

# 85. Use sparse semantic audio in automation-heavy games

An idle/incremental game can generate dozens of actions every second once combat and automation mature. Giving each hit, death, resource pickup, worker strike or automated collection its own sound quickly becomes exhausting.

A better small-game audio model is:

```text
continuous mood          -> one restrained background loop
normal UI navigation     -> one shared click
successful manual action -> one shared confirm
invalid manual action    -> one shared error cue
meaningful state change  -> a small set of distinct event cues
repetitive simulation    -> usually silent
```

Everfort's compact reference set became:

- UI click;
- UI confirm;
- optional UI error;
- Mission ready;
- Stage clear;
- reveal/unlock;
- defeat;
- background music.

Rare events such as Prestige or campaign completion may earn unique sounds later, but they do not require separate assets merely to increase the sound count.

Automation should usually be quieter than manual interaction. Auto-buy, auto-claim, workers and collectors should not repeatedly fire the same confirmation cue that a player receives for a deliberate tap.

Once real assets replace placeholder tones, stacked cues become audible. A shared button click plus the action's own confirm or error, or a victory plus the unlock it grants, used to blur together as short beeps; as recorded sounds they are noise. Resolve this in the audio service, not at each caller: collect everything requested during one frame and play only the highest-priority cue (click lowest, outcomes highest). A per-caller "skip the click on this button" rule touches every consequential button and drifts.

A cue that can legitimately repeat fast (a structure under attack) gets a small pool of variants dealt from a shuffle bag (no immediate repeat) and a short real-time cooldown owned by the service, so callers still request one semantic event per authoritative state change and never pick files or throttle themselves. Keep the service's decision logic running in headless tests and record what it would play: routing, one-shot behaviour and cooldowns become probeable without hearing anything.

A player-issued RTS command is acknowledged **once at the order level**, never once per unit: one cue for the soldiers (a mixed selection included), another for workers alone, and the same cue from every surface that gives an order (a world tap, the selection bar, a unit's card, the army panel), routed through each surface's one feedback helper rather than sprinkled per branch. It replaces the generic confirm; a refusal is the error alone; configuration (editing a list, saving a squad) still confirms; automatic movement never acknowledges.

A **persistent danger indicator represents the danger state; impact sounds represent the individual hits.** "Castle under attack" is a chip that holds while blows keep landing (a grace longer than the slowest attacker's interval, in simulated time, so it never flickers between blows) and clears when they stop; its warning cue plays once on entering the state, while each blow stays on the pooled, throttled impact cue.

The gameplay pause holds the music where it is (pause the stream, never stop and restart it); settings changed while paused apply their volume at once but never start it audibly before play resumes, and UI sounds keep working in the pause menu.

Reusable rule:

> Sound important decisions and state changes, not every simulation tick.

---

# 86. Price global game-speed upgrades as compound accelerators

A global speed multiplier is stronger than a normal percentage stat when it accelerates many systems at once. If game speed affects combat, spawning, resource generation, workers, regeneration and automation cooldowns, buying 2x speed can approach buying improvements across several progression tracks simultaneously.

Before pricing a speed upgrade, inventory everything that uses gameplay-scaled time. Keep wall-clock systems separate, including real play-time statistics, offline elapsed time and human-facing UI delays.

Useful distinction:

```text
simulation timer -> game speed applies
real-world/UI timer -> game speed does not apply
```

Reusable rule:

> Price time acceleration according to the number of systems it compounds, not as a cosmetic convenience upgrade.

---

# 87. Automate Play Store screenshot generation as reusable editor tooling

Store screenshots are repetitive production work and are easy to mislabel when several device classes must be uploaded separately. Treat screenshot generation as a reusable development tool rather than a manual sequence of window resizing, OS screenshots and file renaming.

**Default policy: Play Store screenshots are language-neutral and contain no added promotional text.** The normal store screenshot is:

```text
authentic gameplay + native game UI + no added promotional copy
```

Do not add marketing headlines, captions, slogans, feature descriptions or other localized overlays unless the human developer explicitly requests an exception for a specific game/campaign. One screenshot set per device class then serves every store language, instead of a separate image set per locale. Native in-game UI text stays: it is part of the authentic screen (do not hide or fake the game UI to make a shot text-free). Produce every applicable device class (Phone, 7-inch tablet, 10-inch tablet, Desktop) as **its own real render at its target size**; never resize, crop or upscale another class's image.

A useful Godot workflow is:

```text
prepare exact live game state
-> choose Landscape 16:9 or Portrait 9:16
-> select Phone / 7-inch / 10-inch / Desktop targets
-> choose UI or clean gameplay capture
-> freeze simulation
-> resize the real viewport per target
-> wait for responsive layout/render to settle
-> save PNG into the matching destination folder
-> restore window/pause/UI state
-> advance screenshot number
```

## 87.1 Keep device class, orientation and resolution separate

Do not hard-wire the tool around one landscape game. A reusable capture addon should expose:

- target category: Phone / 7-inch tablet / 10-inch tablet / Desktop;
- orientation/aspect: Landscape 16:9 / Portrait 9:16;
- editable resolution preset per target.

Changing a project from landscape to portrait should be a simple preset/orientation switch, not a code modification. Portrait capture must resize the **game viewport** to portrait; do not rotate a landscape screenshot after capture.

## 87.2 Capture UI by default, but support intentional clean shots

Normal store screenshots generally need the actual player-facing HUD, so `Capture UI` should default to **ON**.

For clean promotional/gameplay shots, hide only explicitly registered UI roots. Do not hide every `Control`/`CanvasLayer`, because world-space HP bars, labels, markers and other presentation may also use those classes. A project group such as:

```text
store_screenshot_ui
```

provides a game-independent contract.

## 87.3 Preserve one gameplay moment across all selected outputs

Pause/freeze the simulation while generating a multi-target set. Otherwise the phone shot may capture one enemy arrangement while the tablet/desktop shot captures a later moment.

The capture tool should remember and restore:

- previous pause state;
- window size and mode;
- visibility of temporarily hidden UI roots;
- capture-overlay visibility.

## 87.4 Name files by their destination for Play Store organization

Default filenames should use the **same destination/category name as the folder plus a sequence number**. This is intentionally boring and operationally useful:

```text
Phone/Phone_01.png
Phone/Phone_02.png
Tablet_7/Tablet_7_01.png
Tablet_10/Tablet_10_01.png
Desktop/Desktop_01.png
```

The exact on-disk folder key can be normalized when necessary, but the basename must unambiguously mirror that destination category. This makes Play Console upload much easier: when selecting files, the device class is obvious from both the folder and the filename, and mixed screenshot sets are much harder to upload accidentally.

If the user manually supplies a semantic name, that is the one exception to automatic `Destination_#` naming. For example:

```text
PrestigeChoice.png
```

may be stored in every selected target folder. If generating a UI-free variant, append a deterministic suffix such as:

```text
PrestigeChoice_no_ui.png
```

so clean and normal screenshots never collide.

## 87.5 Keep generated marketing images out of game assets

Use an output root such as:

```text
res://store_assets/screenshots/
```

and put `.gdignore` at the store-screenshot root. Generated screenshots should not be imported as runtime textures or inflate editor import work.

## 87.6 Do not use `debug` as the editor-tool safety boundary

A critical Godot lesson from Everfort: exported Android debug builds are still debug builds. Therefore this is insufficient:

```gdscript
OS.is_debug_build()
```

for deciding whether a development-only capture overlay may exist on screen.

For a tool intended only when the project is launched from the editor, use the editor-runtime distinction, e.g.:

```gdscript
OS.has_feature("editor_runtime") and not OS.has_feature("template")
```

This keeps the capture overlay out of Android/Desktop export-template runs, including debug exports.

Also distinguish **runtime suppression** from **package exclusion**. If production requirements say the screenshot tool must not exist in the exported package at all, use an editor-only architecture, explicit export exclusion, or disable/remove its autoload before the production export.

## 87.7 Validate the image that was actually rendered

After changing the window/viewport size, wait several frames plus a completed render before reading the viewport texture. Verify that the image dimensions exactly match the requested target.

Three traps validated in Growing Kingdom (Godot 4.7.2, Windows, 1920×1080 screen):

- **The OS clamps the window to the screen.** A 2560×1440 tablet or a 1080×1920 portrait target came out 1084 px tall. Raising the window's maximum size first (`DisplayServer.window_set_max_size()`, then `window_set_size()`) lets the window exceed the screen; restore the previous maximum afterwards.
- **Compare the rendered size, never the canvas size.** Under `canvas_items` + `expand` a 1080×1920 window lays out a 1920×3413 virtual canvas: check the window or the read-back image, not `get_visible_rect()`.
- **A freeze must reach the game.** A capture scene with `PROCESS_MODE_ALWAYS` (so its own coroutine survives the pause) passes ALWAYS to every child it adds: set the game and the scenario adapter to `PAUSABLE` explicitly, or pausing the tree freezes nothing.

A command-line run with the **editor binary** reports `editor_runtime` too: an editor-only overlay gated on it appears in automated captures unless the capture tool hides it.

Godot's fixed embedded-game viewport can otherwise produce a screenshot with the wrong dimensions even when the surrounding editor window changed. Fail loudly instead of writing a mislabeled file.

A desktop monitor can clamp the capture window: 720×1280 on a 1080-pixel screen became 720×1084, and `canvas_items` + `expand` widened the canvas, so the "phone" capture was a different aspect. Choose capture sizes that fit the monitor at the exact target aspect (540×960 for 9:16, 432×960 for about 20:9) and check the saved image's size.

## 87.8 Trigger and ownership: the UI-readiness gate

Screenshots belong to **stage 16, Google Play Store Preparation & Marketing Assets** (0.9). Prepare the reusable capture infrastructure earlier during bootstrap/implementation if useful, but generate final store screenshots once **the UI is mostly ready**, core gameplay is representative and sufficient visual content exists. Final balance, full completion and perfect progression pacing are **not** required for screenshot staging. Regenerate affected marketing captures after significant UI/visual or feature changes.

- **ChatGPT** plans each game's marketing sequence, screenshot order and scenario purposes (what each screenshot shows, not text drawn onto it); the **human** approves what is being advertised and any exception to the no-added-text screenshot default (87.9).
- **Claude** implements game-specific deterministic scenarios, uses the reusable capture tooling and checks the images actually produced. Each scenario can be overridden by the user (subject, action, camera, UI visibility, device classes).
- The scenario system is **shared with video** (section 133): one `prepare_scenario(id, options)` concept can produce a held screenshot frame or a running video shot. The generic orchestrator should not know game-specific save fields, armies, resources or scenes.
- Scenario state must be true game state. **AI directs staging and composition but must never fabricate, repaint or synthesize gameplay visuals that cannot be captured from the shipped game.**

## 87.9 Raw gameplay, language-neutral output and the text exception

The default store screenshot is the **authentic gameplay capture itself**: real game state and native game UI, **no added promotional copy**. It sells the game through what is visibly happening on screen, and because it carries no added language it is reused unchanged across every store locale (one set per device class, not one per language). Screenshot strategy still matters: ordering, choosing authentic features, staging, device-class coverage, framing and conversion-focused composition of the gameplay itself.

Always retain the **untouched raw PNG** with its scenario settings and provenance. The final store file is normally a byte-identical copy of that master. Verify final image dimensions per target/orientation, that no added text is present, and that each numbered screenshot shows the same approved concept across device classes (responsive layout differences are expected).

**Exception (explicit developer request for a specific game/campaign only):** the reusable toolkit keeps an optional post-capture text composition (headline band, framing) for such campaigns. It is never the default production workflow. When approved, it is a derived image beside the raw master (never altering the gameplay depicted), its copy is localized for every requested locale from the approved 20-language set (132), it must not cover important gameplay or invent visual mechanics, and its legibility and clipping are checked per target.

**Other raster assets are not screenshots:** a feature graphic, logo or wordmark may carry the **game's brand name**; a descriptive tagline/subtitle on a feature graphic needs explicit approval for that game, because it creates localization work. **Video** title cards and on-screen text remain allowed when they are part of the approved storyboard, and are localized when required (133).

Reusable rule:

> **Play Store screenshots are language-neutral by default and contain no added promotional text.** Use authentic gameplay and native in-game UI only. Do not add marketing headlines, captions, slogans, feature descriptions, or other localized overlays unless the human developer explicitly requests an exception for a specific game/campaign. This avoids maintaining separate screenshot image sets for every store language. Preserve untouched raw captures. The reusable toolkit may retain optional text-composition capability for exceptional campaigns, but it must not be the default production workflow. Store screenshot tooling should validate responsive behavior, preserve one deterministic authentic gameplay moment, capture every device class as a real render at its own size, organize every output by destination, and remain development-only.



---

# 88. Test the exact release artifact before declaring the game finished

Editor play, static analysis, deterministic probes and debug-device testing are all valuable, but none is a substitute for playing the exact artifact/configuration that will ship.

Everfort found a Mission completion defect during Android release-build play after earlier validation had passed. The practical release gate became:

```text
implementation/static checks
-> editor/runtime checks
-> exported Android release build
-> real-device progression play
-> only then call the candidate stable
```

When a release-build defect is fixed, rebuild the artifact and test the corrected artifact again; do not assume an editor confirmation proves the uploaded binary is fixed.

Reusable rule:

> The shipping artifact is the final runtime authority.

---

# 89. Use one source of truth for application version names

Maintaining a version in project settings, another in export settings and another in UI invites drift. Everfort reached a state where the Android export had advanced while Settings still displayed an older project version.

Prefer:

```text
one integer change version source
-> player-facing Settings/About UI
-> platform version name where the engine allows inheritance
```

Keep platform build/version **codes** separate when the store requires a monotonically increasing integer.

For Godot Android specifically, leaving export `version/name` blank can intentionally fall back to `application/config/version`; the integer Android version code still increments independently.

Reusable rule:

> Human-readable version name: one source. Store build code: separate monotonic counter.

---

# 90. Float progress needs aligned display precision and completion tolerance

Continuous systems frequently accumulate fractional values: healing, Gold, damage, resource extraction, timers and progress bars. A dangerous failure mode is:

```text
internal progress = 168.9996
UI rounds to      = 169 / 169
completion test   = false
```

The player sees a completed objective that the state machine refuses to complete.

Use one explicit policy:

1. define the display precision;
2. define a completion epsilon compatible with that precision;
3. snap near-target residuals to the exact target when appropriate;
4. refresh UI when the **displayed** precision changes, not necessarily every simulation tick;
5. keep discrete objectives integer-based when fractions are impossible.

Avoid generic relative-equality helpers for large accumulated progress if legitimate frame-sized increments can fall inside their tolerance.

Reusable rule:

> If the UI says the target is reached, the completion state must agree.

---

# 91. Mission difficulty includes player agency, not only target size

A mission can be numerically small and still be difficult if the player cannot intentionally make it progress. RNG-gated objectives are the clearest example.

Everfort's Miner Skill Point mission depended on a rare Skill Find roll. As an ordinary mission it could occupy a normal board slot for too long even when its target looked reasonable. Moving it to the rare/Special pool made the contract honest: unusual difficulty, unusual rarity, premium reward.

When classifying a mission, consider:

- target magnitude;
- expected time;
- system unlock requirements;
- player agency/control;
- RNG dependence;
- whether progress competes with other resources/actions.

Reusable rule:

> Difficulty is the effort and control required to complete an objective, not just the number printed on it.

---

# 92. Rebalance reward sources and sinks as one economy

Increasing currency income without revisiting permanent-skill costs can make an entire progression tree trivial. Increasing costs while leaving acquisition untouched can create a grind wall. Treat both sides together.

Everfort's late SP rebalance changed several interacting pieces in one controlled pass:

- first-clear SP increased;
- ordinary Mission SP rewards increased;
- Special Mission rewards became progression-based;
- Special Mission chance increased;
- automation/mission utility costs were reduced;
- Mission Expertise costs were re-evaluated;
- Gold Gain became substantially stronger and therefore received a steeper cost curve;
- offline SP became more useful, with its own unlock/efficiency costs.

A practical rebalance worksheet should list:

```text
all repeatable sources
all one-time sources
all multipliers
all major sinks
unlock timing
max-level total investment
expected early/mid/late purchasing pace
```

**Short tracks: author the prices.** A formula (`base × growth^level`) suits a long track. A short one (three levels of a capacity, three ranks of a big multiplier) is a handful of design decisions the formula only approximates, and tuning base and growth to land one level moves the others. Let an upgrade carry an authored price table:

```text
price(id, level):
  table present -> table[level]                  (levels never exceed the table: the max level is its length)
  otherwise     -> ceil(base × growth^level)
```

- **One price function** is the only source: cards, bots, the receipt and the Stats page ask it; nothing computes a price itself.
- **Probe both branches:** every authored level equals its table entry, and every formula upgrade still matches its formula at every level, so adding a table to one upgrade cannot shift another.
- **Retune by table, record by decision:** a price change is a table edit with its reason in the decision log and, when it touches the economy's pace, a pacing run (section 112).
- Bounded requirements follow the same table-first rule (section 3.5).

Growing Kingdom: Expanded Command 200 / 350 / 600 and Recovery Doctrine 600 / 850 / 1,200 through `Balance.meta_cost()`; every other permanent upgrade keeps base and growth (`core_probe` checks both branches).

Reusable rule:

> Never evaluate a reward buff or price cut in isolation when the same currency feeds multiple permanent systems, and author the prices of short tracks instead of bending a formula to fit them.

---

# 93. Progression-based rare rewards are easier to reason about than arbitrary random ranges

A rare mission that pays a fixed random `20–50` currency can be overpowered early and irrelevant late. If normal missions already have a progression ceiling, reuse that ceiling for the rare tier.

A clean hierarchy is:

```text
Easy     -> fraction of current ceiling
Standard -> larger fraction
Hard     -> larger fraction
Special  -> full current ceiling
```

Snapshot the resulting reward at mission assignment so later progression cannot inflate an already-created contract.

This produces a reward hierarchy that automatically stays relevant as progression grows without inventing a separate table for every rarity.

---

# 94. Offline rewards should be predictable enough to explain

Offline systems often become hard to balance because they combine stage scaling, time scaling, efficiency upgrades and global multipliers. If a player cannot predict why they received a number, balance feedback becomes noisy.

A useful split is:

- one simple base rate for the offline currency;
- one dedicated efficiency track that changes that rate;
- a clear time cap track if needed;
- only intentional global earned multipliers afterward.

Everfort's offline SP was simplified to a fixed base rate with an explicit efficiency multiplier, removing highest-stage scaling from that currency. Gold kept its own stage-based formula because that was a separate economy decision.

The UI should show the exact calculation inputs below the total so players and developers can validate the result immediately.

---

# 95. Release stabilization is a different mode from feature development

Once the store candidate is uploaded and the real release build is under review/testing, the cost of every change rises. New features create new regression surface, version-code churn and possible review delays.

Switch the team/chat contract to:

```text
release candidate exists
-> test exact artifact
-> fix demonstrated blockers/regressions
-> regression-check adjacent systems
-> rebuild/re-upload if needed
-> freeze again
```

Good release-stabilization changes include crashes, softlocks, persistence defects, incorrect progression, misleading UI, severe readability problems and balance issues proven by real play.

Avoid opportunistic architecture cleanup or feature expansion unless the release genuinely depends on it.

Reusable rule:

> Near release, reduce scope faster than you reduce quality.

---

# 96. Synchronize continuity documentation after the release candidate changes materially

A long AI-assisted project can have correct code and dangerously stale handoff documents at the same time. That is especially risky when old documents still describe earlier version numbers, balance curves or unfinished phases.

At major milestones, compare the continuity document against the latest full project snapshot and explicitly update:

- current version/build identity;
- completed vs pending phases;
- final balance values that changed;
- save/versioning contracts;
- release/store state;
- bugs whose fixes created reusable engineering lessons.

Keep historical audits/reports historical rather than rewriting them to look current. The current handoff should summarize where the project is **now**, while dated audit files remain evidence of what was true at that date.

Reusable rule:

> Code is implementation authority; the continuity handoff is navigation authority. Keep both synchronized at release milestones.

---

# 97. Turn validated human corrections into reusable specifications

The strongest compounding benefit of an AI-assisted small-game workflow is not that the AI writes the first version quickly. It is that each successful human correction can become a permanent input to the next implementation.

Examples from Everfort include:

- exact enemy/unit visual mappings;
- panel families and typography hierarchy;
- Tiny Swords asset assembly rules;
- sparse audio policy;
- Android ADB fallback procedure;
- screenshot-capture workflow;
- mission/reward receipts;
- mobile touch/readability rules;
- versioning/release rules.

After a human validates a correction, capture it as one of:

```text
project continuity rule
reusable playbook rule
asset implementation registry entry
shared helper/tool
balance/data definition
QA preset/checklist
```

Do not leave a validated decision only in a chat message or in one person's memory.

Reusable rule:

> Every correction should make the next game cheaper to build and harder to get wrong.

---

# 98. Changed-files patches are not commutative

Small changed-files ZIPs are efficient, but two patches that touch the same file cannot safely be applied in arbitrary order.

Everfort experienced this directly when overlapping patch sequencing reintroduced older Stage-100 behavior after a newer contract had already been implemented.

Safe patch workflow:

```text
latest full project snapshot
-> apply/implement new requested change against that snapshot
-> merge every overlapping file deliberately
-> static/runtime validation
-> consolidate patch chain before commit/release
```

Never assume:

```text
Patch A + Patch B = same result as Patch B + Patch A
```

Shared state files, `main` coordinators, save services, balance definitions, UI helpers and endgame flow are especially high risk.

After a short patch chain has been accepted, produce or request a **fresh full-project snapshot** before starting unrelated work. A new authoritative baseline reduces accidental regressions, makes documentation/version checks trustworthy again, and prevents future sessions from having to reconstruct which deltas were already applied.

Reusable rule:

> A changed-files ZIP is a delta against a specific baseline, not an independent feature package.

---

# 99. A design reversal is a cross-system migration

During development, a major rule can legitimately change. The dangerous part is updating only the screen where the change was noticed.

Everfort's first Stage-100 completion behavior changed during development. That decision affected more than the ending modal; it also touched Prestige eligibility, pending offers, continue behavior, debug triggers, probes and continuity documentation.

When a core contract changes, inventory every dependent layer:

```text
gameplay/state machine
save/pending state
UI copy and buttons
debug/test entry points
probes/automated expectations
local gameplay statistics if applicable (never remote telemetry)
continuity/design documentation
```

Reusable rule:

> A design reversal should be handled like a migration, not a local patch.

**When a feature is dropped, cut it completely.** Feed the Dragon built phone notifications (a planner run from the offline simulation, Settings toggles, an Android plugin interface), then the design lead dropped outside-game notifications at review. The removal went through the same inventory: the autoload and its plugin interface, the settings and their save fields, the balance limits, the simulator hooks and the state snapshot used only by the planner, the Debug controls, the probes and showcase, the Settings copy, the GDD, the report and the plan. Nothing was kept "for a future plugin": a leftover settings contract or abstraction is a promise the game no longer keeps and code nobody runs. Fixes found while building the dropped feature (here, a save-copy defect) stay, with their regression tests.

---

# 100. Prepared saves and debug presets are part of production QA tooling

Progression-heavy games contain states that are expensive to reach naturally but still need repeated visual and functional validation.

Everfort's UI acceptance work became much faster when deterministic presets could reproduce states such as:

- mature progression panels;
- post-campaign/endgame;
- tutorial chooser;
- Hand Holding progression;
- pending Offline Reward;
- milestone/reveal states.

A useful preset system should:

- create a **legitimate** state through the current save/profile schema;
- name the validation purpose clearly;
- avoid impossible field combinations;
- survive ordinary restart/reload rules;
- be updated or intentionally retired when the schema/contract changes.

This complements, rather than replaces, full gameplay QA.

Reusable rule:

> If a state must be inspected repeatedly, make it reproducible deterministically.

**Build presets, do not store them.** Feed the Dragon's Debug panel "Test saves" are functions, not JSON files: each builds its state through the same public and debug APIs the game uses. A stored save is discarded by the first schema change (section 61); a builder keeps up with the game and can only produce reachable states (section 59).

The structure that worked:

- **Few saves, each covering a group of features** (eight for the whole game: early village, Dragon crisis, growing town, research and towers, Prestige ready, army ready, new cycle veteran, sandbox maxed). A new feature extends the save that covers its part of the game instead of adding a save.
- **Each save has a one-line summary** in the panel naming what it is for, and a camera focus that lands on the thing to test.
- **Loading keeps one backup of the player's real game**, and a "Restore my save" button puts it back, so testers can use presets on their own device without losing progress.
- **A probe builds every save, reloads it unchanged and checks what each one promises** ("24 troops ready", "the army wins in a real fight", "the first kill asks which stacks to keep"). A save that stops keeping its promise fails the build instead of misleading a tester.
- **The visual capture tool can load any save**, so screenshots and manual tests share the same states.
- **Human validation checklists start from a save** instead of a list of manual setup steps.
- **Keep two kinds of fixture apart: whole-profile saves and current-progress setups.** A deterministic test save that starts from a hard reset is right for probes and screenshots, and wrong for testing a campaign in sequence: each use wipes the progression being tested (Growing Kingdom's developer wanted to test rival 1, conquer it, take the Prestige, then test rival 2 with the same army). A current-progress setup rebuilds only the run (a ready settlement, a fixed army ready to launch) and leaves the profile exactly as it was: no hard reset, no ranks, unlocks or currency granted, statistics a rebuild advanced put back; anything stronger than the profile owns (a locked building, a higher tier) exists only in that run's state. Label the two groups differently in the Debug panel ("keeps progress; replaces the current run" against "erases the profile"), and give the probe the strict check: the profile's whole saved dictionary is identical before and after, but for the one field the setup exists to move. Growing Kingdom: `scripts/debug/settlement_setups.gd`.

Reuse: `scripts/debug/debug_presets.gd`, `tests/presets_probe.gd` and the `preset:<id>` scenario of `tests/showcase.gd` in Feed the Dragon.

---

# 101. Brand from the game's authored visual language

Store branding is stronger when it looks unmistakably connected to the game rather than merely connected to the genre.

Everfort's icon and wordmark direction improved when it started from the same sword shapes, chunky pixel-art weight, palette and medieval visual grammar already present in the game instead of inventing a generic fantasy/RPG identity.

For future games:

1. inventory the strongest recognizable shapes/colors in the actual game;
2. identify what remains readable at launcher/store-thumbnail size;
3. derive icon/wordmark motifs from those assets;
4. preserve exact product-name spelling/capitalization;
5. test readability at the real store/runtime sizes;
6. only then add genre cues that reinforce rather than replace the game's identity.

Reusable rule:

> The store art should look like the game first and the genre second.


---

# 102. Make defeat screens diagnostic, not merely terminal

A defeat screen can do more than report that a run ended. In a combat/progression game, it can explain **what pressure actually broke the player's build** and therefore help the player make the next decision.

A useful damage-attribution model should define a clear analysis window. Everfort uses **since the Castle was last at full HP**:

```text
Castle reaches full HP
-> clear prior damage history
-> track actual HP damage by source and stage
-> track partial healing in the same window
-> if healing reaches full HP, clear again
-> on defeat, summarize only the surviving window
```

Important implementation details:

- attribute **actual HP lost**, after mitigation and shielding, rather than raw attack damage;
- preserve source identity on in-flight projectiles so a ranged attacker can still be credited if it dies before impact;
- aggregate by useful player-facing source (enemy archetype/variant), not transient object instance;
- show both cumulative damage and healing, because healing can make cumulative damage legitimately exceed 100% of max HP;
- show the biggest threat per stage as well as the biggest threat across the full window;
- persist the diagnostic window with the active run so save/resume cannot erase the evidence;
- reset it on a genuinely fresh run and on any state transition that semantically establishes a fresh combat baseline.

The presentation should prioritize information rather than compress everything equally. Keep the primary run reward/summary and the top diagnostic conclusion visible, then place long receipts and per-stage evidence in their own scroll areas. This permits larger, more readable text without sacrificing detailed analysis. In Everfort, the Skill Point reward summary is shown before the damage report; reward details and per-stage damage details scroll independently while their key totals remain fixed.

The presentation should expose enough information to answer a player question such as:

> Which enemy type is actually causing my run to collapse?

Reusable rule:

> When a loss can teach the player something actionable, make the end screen explain the loss rather than only announce it.

# 103. Build terrain from connected topology, not isolated decorative sprites

One of the most reusable environment lessons from Everfort was that convincing 2D terrain came from treating the terrain atlas as a **construction grammar**, not as a bag of mountain, grass, stair, and cliff sprites.

The successful battlefield pass used connected surface masks and then derived the visible edge treatment from neighboring cells. That gave the terrain a continuous authored shape instead of a collection of individually placed cliff pieces.

A reusable approach is:

```text
1. Define the playable/elevated region as occupied cells or row spans.
2. Paint the grass/surface from that occupancy mask.
3. For every surface cell, inspect left/right/up/down neighbors.
4. Select authored edge/corner variants from the source tileset.
5. Derive cliff faces from the exposed lower boundary of the elevated mask.
6. Add access features only where the terrain has a readable connection.
```

For an authored atlas, identify the tile families before composing anything:

```text
surface left / middle / right
surface top / middle / bottom
cliff left / middle / right
diagonal access left / right
corner and grass-lip variants
```

Do not paint a generic rectangular grass platform and then place unrelated rock sprites around its border. The shape, grass cap, stone face, and corners should all come from the same authored terrain family whenever possible.

## Mountains and cliff ridges should read as one landform

A common failure during Everfort's environment work was for mountain/cliff pieces around an entrance to read as several disconnected islands.

The fix was not "add more mountain sprites." It was to make the underlying topology continuous:

- keep the actual access passage open;
- flank it with the correct authored diagonal cliff pieces;
- continue a single cliff/ridge behind that passage;
- reuse the same grass lip/corner treatment as the surrounding cliffs.

This made the stairs/access read as climbing into **one mountain ridge / raised district**, rather than passing between unrelated terrain chunks.

Reusable rule:

> When a terrain feature is supposed to represent one geological structure, first make its silhouette/topology continuous. Decoration cannot repair a disconnected silhouette.

## Stairs and ramps must be interpreted according to the source atlas

Do not assume a sprite that visually resembles a stair is itself the walkable stair surface.

In Everfort's Tiny Swords terrain atlas, the successful central access used a two-cell-wide **flat grass path**, while the diagonal authored pieces were the **side walls of the access**. The left and right source pieces also had to be placed according to the atlas's authored orientation rather than automatically flipped or rotated.

This is broadly reusable:

- inspect how the source artist assembled stairs/ramps in reference material;
- determine whether a tile is the walking surface, retaining wall, edge, corner, or shadow;
- preserve that semantic role in the game;
- avoid arbitrary flip/rotation when the atlas already provides directional pieces;
- keep the route itself visually continuous from the lower elevation to the upper elevation.

A higher terrace should not exist merely because there is room for one. Everfort deliberately removed an additional upper shelf until it had a believable authored ramp/stair connection.

> Every visible elevation should have a readable connection, unless inaccessibility is an intentional part of the scene.

## Preserve terrain consistency with deterministic variation

Large flat areas can look repetitive, but random decoration is not the only solution.

Everfort varied fully surrounded ground tiles with deterministic horizontal/vertical atlas transforms while keeping boundary cells fixed. This reduced visible repetition without destabilizing edges or producing a different battlefield every load.

Useful rules:

- vary only interior tiles whose edge semantics are identical;
- never randomize a cliff/shore/corner tile into a variant with different topology;
- prefer deterministic variation derived from cell coordinates when the world layout itself is deterministic;
- use the same terrain palette/family for a given elevation band;
- use color/elevation changes intentionally to establish depth rather than recoloring individual props independently.

Everfort's environment hierarchy was approximately:

```text
lower combat ground -> richer/stronger green
raised settlement   -> warmer/yellow-green terrain family
far/upper terrain   -> paler/softer terrain family
```

The exact colors are asset-pack dependent. The reusable lesson is to communicate elevation/depth through **consistent terrain families**, not arbitrary per-sprite tinting.

## Separate decorative terrain from gameplay semantics

Everfort's mountains, cliffs, water, trees, settlement props, and stairs were primarily visual composition. They did not silently become new collision or navigation rules.

This matters for games with an already-working combat lane:

- visual cliffs do not automatically imply new physics walls;
- decoration should not block taps/clicks;
- keep negative space around active combat paths;
- do not place high-detail terrain behind information-heavy combat if it reduces silhouette readability;
- constrain visual effects and trajectories to terrain boundaries even when those boundaries are not physics bodies.

The Mine Gold toss lesson is a good example: the reward arc was constrained so it did not visually fly over the settlement mountains, without changing the reward or adding a collision wall.

**Keep generated decoration off authored gameplay spots.** Feed the Dragon generates its forests around authored building plots. On the device, two tree canopies were drawn over plots and won every tap. The world generator now keeps every canopy off every plot, and the world probe taps the centre of every plot and checks that the plot is what gets selected (section 115.9).

---

# 104. Animate water as one coherent system, not scattered effects

Everfort's moving water became convincing only after treating the river as a single visual system with **base water + contact animation**, rather than placing splash animations wherever motion was desired.

The core model was:

```text
continuous water body
+ animated shoreline where land contacts water
+ authored water treatment around rocks/objects
+ carefully placed corner/intersection pieces
= coherent moving river
```

## Use one water language everywhere

If the art pack already includes a looping shoreline/foam animation, reuse it consistently around the same type of boundary.

Everfort reused Tiny Swords `Water Foam.png` as the shoreline animation instead of inventing a second foam/splash style.

The automatic terrain system detected exposed grass cells by checking whether neighboring cells were absent. Shoreline animation was then added along the corresponding land/water boundary.

This means animation follows **terrain topology** rather than arbitrary screen coordinates.

Reusable rule:

> A water effect should answer "what is the water touching here?" If there is no shoreline, rock, obstacle, fall, impact, or other cause, a standalone splash is probably the wrong effect.

## Moving water does not require animating every pixel of the water body

A static or subtly moving water background can feel alive when its contact points animate consistently.

For a lightweight mobile scene, it can be enough to combine:

- a continuous water background;
- looping foam/wave frames at exposed shorelines;
- animated water around authored water rocks/objects;
- occasional justified splash effects;
- subtle atmospheric motion elsewhere.

This is cheaper and often visually cleaner than covering the entire river with independent animated sprites.

## Use a hybrid procedural + editor-authored shoreline

Straight/repeatable boundaries are good candidates for procedural generation. Artistically sensitive corners are not always.

Everfort ended with this split:

```text
automatic:
- predictable top/bottom shoreline segments
- repeatable exposed ground/water boundaries

editor-authored:
- mountain-side shoreline corners
- settlement side foam
- awkward contour transitions that required visual judgment
```

The manual pieces remained real editor-visible nodes, while a small layout script applied the same responsive horizontal center offset used by the procedural terrain. That preserved both artistic control and wide-screen correctness.

This is a useful general pattern:

> Proceduralize stable rules. Expose subjective boundary composition to the editor. Keep both driven by the same layout coordinate system.

## Desynchronize looping environmental animation

When many shoreline pieces share the same loop, starting every sprite on frame zero at the same instant can make the river look synthetic.

Everfort seeded the initial frame from the terrain cell coordinates so neighboring shoreline sprites did not all pulse in lockstep.

For repeated environmental animation:

- use the same animation/fps for consistency;
- vary the starting frame deterministically;
- avoid random state that changes every load unless that variation is desirable;
- keep texture filtering appropriate for the source art, especially pixel art.

## Validate the environment as a composition, not only as code

Terrain that is technically connected can still look wrong. Environment validation should include:

- the reference viewport;
- the widest target Android aspect;
- all supported camera zoom levels;
- shoreline corners and side tapers;
- whether mountains read as one ridge;
- whether stairs actually communicate a path between elevations;
- whether decorative density competes with combat readability;
- whether moving water looks continuous rather than like repeated rectangles.

Everfort also established an iteration rule that applies strongly here: after a limited number of AI positioning passes, move subjective terrain markers directly in the editor instead of continuing blind pixel-by-pixel code edits.

The reusable result is not a specific Everfort map. It is the construction method:

> **Topology first, authored tile grammar second, coherent boundary animation third, decoration last.**

---

# 105. Treat the game-specific GDD as the design authority before implementation

This section expands the GDD phase summarized in the canonical startup flow at the beginning of this Playbook. The GDD is completed first; Bootstrap / Checkpoint 0 then proves the clean Godot/Android/signing baseline; only after that does gameplay implementation begin.

For a new game, finish the major design contracts before implementation expands across many systems. The goal is not to freeze every balance number, but to remove ambiguity about how the game is supposed to behave.

The GDD should define at least:

- game identity and player fantasy;
- core loop;
- run/session structure;
- economy and resource ownership;
- progression layers;
- major systems and content;
- UI/UX and onboarding;
- persistence, offline behavior and reset contracts;
- balance/pacing targets;
- production scope and acceptance criteria for the first playable phase.

Exact tuning values can remain targets or placeholders when they do not change the system contract.

Before declaring the GDD complete, run a contradiction/missing-state audit. Check edge cases such as:

```text
normal failure
successful run / endgame
Prestige or deeper reset
Hard Reset
app close / resume
offline progression
unfinished timers / queues
locked systems with saved configuration
first-time rewards vs repeatable rewards
```

Reusable rule:

> Resolve behavioral contracts before code, then use implementation and balance testing to tune the numbers rather than rediscover the design.

---

# 106. Build the GDD through a staged interview, not one giant questionnaire

A structured back-and-forth produces better decisions than dumping every design question at once.

A useful reusable sequence is:

```text
1. Game Identity
2. Core Loop
3. Run Structure
4. Economy
5. Progression
6. Systems & Content
7. UI / UX / Onboarding
8. Persistence & Reset Rules
9. Balance & Pacing
10. Production Definition
```

Ask one or a few related questions at a time. Lock approved decisions as they are made, and surface contradictions when a later decision changes an earlier contract.

This keeps the designer focused on the current decision while still allowing the complete design to emerge coherently.

Do not mistake "GDD-first" for "write a huge document before talking." The effective workflow is:

```text
discuss small decision
-> challenge weak assumptions
-> lock the contract
-> continue
-> final audit
-> consolidate into one GDD
```

Reusable rule:

> Design conversations should reduce uncertainty progressively; the final document is the consolidation of validated decisions, not the place where those decisions are invented for the first time.

---

# 107. Keep reusable methodology separate from each game's design authority

Use two documentation layers with different jobs:

```text
Reusable Playbook
= cross-game process, engineering, UI, asset and production lessons

Game GDD
= the authoritative design contract for one specific game
```

Do not copy a game's full mechanics into the reusable Playbook. Only extract lessons that are likely to help another project.

Likewise, do not rely on the Playbook to define game-specific behavior. If a rule determines how the current game works, it belongs in that game's GDD even when the implementation technique came from the Playbook.

**Previous game GDDs may be attached to a new project as reference material**, but they are not templates and never become design authority for the new game. The startup prompt must say explicitly: use prior GDDs to identify reusable patterns, game-specific decisions and lessons/anti-patterns; do **not** inherit mechanics, progression, economy, UI structure, theme or content unless the new game independently justifies them. This prevents a new design from becoming an accidental reskin of an older one.

When an asset or workflow lesson becomes reusable, record the method rather than the map/layout/content that happened to reveal it.

Reusable rule:

> One game, one GDD. One reusable Playbook. Avoid parallel design documents that can drift into competing sources of truth.

---

# 108. End major development phases with a reusable-lesson checkpoint

Do not wait until release to remember what was learned, but also do not add every speculative idea to the Playbook while a feature is still moving.

At the end of a substantial phase, ask:

```text
What was validated?
What correction came from real testing or deliberate design review?
Would another small Godot game benefit from this lesson?
Is the lesson already covered by an existing Playbook rule?
```

If the answer is yes, update the Playbook before closing the phase or when enough proven material has accumulated to justify a coherent update.

Good candidates include:

- workflow improvements;
- state/persistence contracts;
- UI patterns;
- asset composition techniques;
- debugging/validation practices;
- production handoff rules.

Avoid adding:

- game-specific balance numbers;
- untested implementation guesses;
- temporary experiments;
- duplicated rules already covered elsewhere.

Reusable rule:

> Capture proven lessons close to the phase that produced them, but keep the reusable document curated rather than chronological.

**Process that makes this happen.** Each phase report keeps a short "Reusable lessons (candidates)" section while the phase is in progress. The close-out commit of an approved phase moves the validated candidates into this Playbook (into an existing section when one fits, a new section otherwise) and marks the report section as moved. Feed the Dragon learned this the hard way: three validated phases of candidates sat in reports until Phase 5 closed. Growing Kingdom learned the opposite failure: it appended one Playbook section per pass, so the same subject (guard stances, panels, saves) ended up in three places that disagreed, until a consolidation pass merged them by topic. Merge each lesson into the section that owns its subject; when it contradicts an earlier rule, reconcile the two instead of adding a note.

---

# 109. Store state where its lifetime already lives

Before adding a field to a global state object, ask which existing entity has the same lifetime.

Feed the Dragon examples:

- **Research lives inside the Research Building's record.** "Research survives or burns with its building" needed no new rule for survival, save, load or reset: it came with the building.
- **Jobs on the building, results on the run, when several buildings share one result.** Growing Kingdom lets two Monasteries research at once while completed levels belong to the whole kingdom: each building stores its own job (topic, progress, what was paid), the run stores the levels. "Who runs topic X" is derived from the building records, so one topic cannot run twice; on load a topic's job is kept at one building only. A demolished building ends its job like a cancelled project (refunded by progress) and never grants the result. Choose by lifetime: if losing the building should lose the result (Feed the Dragon), keep both on the building.
- **Training queues live inside the Barracks record,** so a surviving building keeps its queue and a destroyed one loses it.
- **Progress counters are derived from what was bought.** Legacy Progress (the Prestige requirement) is computed from the saved upgrade levels. A separately stored "invested" counter can drift through save, load, refund or reset; a derived one cannot.
- **Mission progress is read, never saved.** Each goal reads the run (buildings, tiers, Villagers), the profile (Legacy, blueprints) or a lifetime counter; only "completed" and "claimed" are saved. Nothing to migrate, nothing to drift, offline progress counts the moment the player is back, and a test save only has to say which missions are done. Reuse: `scripts/autoload/mission_state.gd` in Feed the Dragon.

Reusable rule:

> Put state in the entity whose lifetime it shares, and derive counters from owned state instead of storing them.

---

# 110. Make irreversible transitions one saved step, and build the exit first

A Prestige, a campaign end or any reset that grants a reward has three parts: apply the reward, reset the layers, start the next state. If they are saved separately, a force-close can land between them: reward granted but reset not applied, or reset applied and reward lost.

Feed the Dragon's pattern:

```text
commit (irreversible confirmation)
-> roll and save the offers (section 53)
-> lock currencies the reset will erase (section 30)
-> choice: grant reward + reset layers + start fresh run, one save
-> relaunch lands before the choice (same offers) or after all of it
```

**Make the reset boundary an enforced table.** Growing Kingdom keeps two lists beside the profile fields, the fields a Prestige keeps and the fields it resets, and a probe enumerates every persisted field and fails when one is in neither list. A new field then cannot silently cross (or miss) the boundary, and informational collections kept on purpose (a bestiary, the onboarding choice) appear as named exceptions instead of accidents. The same table, in player language, is the "you will lose / you keep" list of the confirmation.

**Build the exit before the content that reaches it.** The Final Assault ends by calling `trigger_dragon_defeat()`. That function, its Grand Prestige flow, persistence and probes were finished and validated with a debug "Force Dragon kill" before any combat code existed. The combat batch then only had to call one proven entry point.

**A lock owned by a pending decision must not disable that decision's own controls.** LootFarmer's prestige batch locks gameplay actions, and a generic pinned-action helper applied the same lock to the batch's Keep button, so the choice could never be confirmed. Probe the confirm control of every modal decision while its own lock is held.

Reusable rule:

> An irreversible transition is one save. Build and validate the endgame's exit before the gameplay that reaches it.

---

# 111. Simulate in state, present with events

Feed the Dragon's Final Assault is a real-time battle, but the fight lives entirely in the run state: a saved record per unit, the Dragon's HP, and a timer-driven step. The world scene only replays what the state reports (a strike, a bite, a fall) and can be rebuilt from state at any moment.

What that gave for free:

- save and resume mid-battle, with the same HP and survivors;
- game speed and headless probes without special cases;
- a calibration table produced by running the real combat thousands of times without a window;
- no difference between what the player sees and what the save holds.

The same split holds for ordinary workers. A feeder's Meat restores Hunger at the toss, in the step it leaves the worker's hands, and the flying Meat is only a visual; carried amounts are saved, while paths, positions and claims are rebuilt from state (section 115.8). Section 116 describes the whole architecture that keeps such a world disposable. **Clamp each frame's simulation step** (Feed the Dragon: 0.1 s × game speed, `World.MAX_FRAME_STEP`), so a hitch or an Android resume never lands one huge unobserved step; real absences go through the offline window instead.

Reusable rule:

> If a system must survive a force-close, the simulation belongs in state and the scene is only its presentation.

---

# 112. Pacing bots find what rule probes cannot

Rule probes check that each rule does what it says. They do not find economies that deadlock when the rules interact. Feed the Dragon's bot-played pacing probe found both economy defects of its Phase 3: a start that filled storage before the player could act, and a building that cost more than the storage able to hold its price.

Lessons:

- **A bot needs a savings policy.** A bot that always buys the cheapest affordable item never reaches one expensive unlock, so it measures the wrong game. One "buy first, save for these" list fixed it.
- **A shared-capacity economy must never silently block the survival resource.** When one storage pool holds both growth resources and the resource that keeps the player alive, test every state for a path to store the survival resource, and warn when it is blocked.
- Record milestone times (first unlock, first building, first Prestige) so balance changes are compared on the same axis.

Feed the Dragon's whole-game balance (Phase 7) added four more:

- **Measure the whole journey before tuning a part.** Every system had passed its own bot. Only a journey bot, playing from a fresh profile through destructions, Meta purchases, Prestige, military and the final fight to the first kill, showed that the military chain arrived 3 to 5 hours late and that the first real attempt was usually also the kill. Let that bot check the reset layers at every run transition it crosses: it is the cheapest audit of what each reset keeps and clears.
- **The bot's spending policy must match the goal it measures.** Cheapest-first never fielded the army a player going for the kill would build, and "invest in the fight" without population starved that army. Fix the instrument and re-measure before changing any game value, and record the fixes so the before and after numbers compare.
- **Check the arrival before changing a sharp threshold.** A win-or-lose fight that looks too harsh (repeated near misses) may just be reached too late with too little. Moving the prices that set the arrival time first left only a small stat change (Dragon regeneration -25%) instead of a large one.
- **Run several player profiles, and stop at the first state every profile passes.** Direct, no-Prestige, hoarding and slow players (acting every 15 s) reach the goal differently. Tune until all of them get there, then stop. A question the bot raises but cannot answer (is a Prestige detour worth it, would a person commit to the fight earlier) becomes a named human-playtest question with what to record, not another tuning iteration.

Growing Kingdom added these:

- **Look for stalls, not only for the end time.** After units gained stances, a bot run lasted far too long because one wave never ended: a ranged enemy stood just outside the "defend" zone and picked off the guards one by one, and the guards never answered. Later an enemy healer kept an Elite group alive just outside the guard area, with the same result. A trace that prints wave number and enemies alive every 30 s shows it at once (the same wave with one enemy for minutes). Guard behaviour needs a retaliation rule and must count the enemies that sustain a threat (section 130.4).
- **Anything that moves the bot's economy or army needs a pacing re-run, not only wave changes.** Resource positions (moving the herds dropped the first-run median from 17.8 to 10.4 minutes until the bot's farm placement followed them), guard targeting (a too-stubborn target lock cost about three minutes) and start positions all moved the median. Guard AI is balance.
- **Know which lever moves the measure.** Raising the late threat budget barely changed the fresh-run length (the bot sizes its army to each wave and dies where its economy runs out); spawn density after the opening waves did. Find the effective lever with a few candidate tables before tuning.
- **Compare curves side by side without saturating the machine.** Let a debug build load an alternate content table from the command line (Growing Kingdom: `--waves-file=<path>`) and give the table generator command-line knobs, so every candidate is generated before measurement and can run through the exact same harness. Queue long candidate runs sequentially by default. If the runs are genuinely cheap and a benchmark shows parallel execution is faster, cap concurrency according to section 60.1 rather than launching one process per core. The shipped table stays the only one a release build can read.
- **Bots must agree with play, not replace it.** Growing Kingdom's bot accepted a wave table with a one-enemy wall at wave 20 that the developer's first playtest rejected at once ("the Brute is too strong"). Treat the bot as a check that must agree with the human verdict.

Reuse: `tests/pacing_probe.gd` in Feed the Dragon (profiles and flags in its header; `--journey` plays to the first kill with the reset-layer checks, `--think-seconds` models a slower player); `docs/BALANCE_QA_REPORT.md` sections 3 and 10 show the before and after tables and the deferred playtest questions. Growing Kingdom: `tests/pacing_probe.gd` (`--think`, `--trace`, `--journey`), `tools/gen_waves.py`.

**Remove bot artifacts before trusting a pacing result.** Two LootFarmer bot bugs looked like balance walls: a 0.5 s steering interval overshot a 26-unit arrival radius at 117 units/s and the bot oscillated forever, and boss attempts that were re-decided every tick turned back whenever enemies on the route lowered HP. Steer at the simulation step, treat a boss attempt as a commitment held until a retreat threshold, print periodic summaries (level, margin, position), and run several seeds and policies (ordinary, rush, expert).

## 112.1 Controlled composition audits

"Is the cheap generalist army as efficient as specialised armies?" is hard to answer with economy bots alone: a bot's army is shaped by its spending policy, not only by its units. Growing Kingdom's audit bot, allowed to save for upgrades, starved its army while saving and died earlier than without them; its full runs measured the bot.

- **Add a controlled hold test:** for a wave and an army, the smallest budget (on a geometric grid, every seed must hold) whose army, standing at its posts when the wave starts, clears the wave with the base above a threshold; then what that army loses doing it. Compare armies at the same wave and profile. This audits **by representative encounter composition** (the Boss waves, the waves dominated by one enemy trait) instead of only by full-run completion time.
- **Separate capital from consumables:** long-lived defences (towers) hold every later wave, soldiers are partly spent on each; report tower cost apart, and compare per-wave losses (the running cost) as well as the standing army. Report population too: late in a run the population cap, not resources, may bind.
- **Measure at several progression profiles:** near the permanent upgrades' caps everything is strong and differences shrink; mid-progression shows the pressure the player actually meets.
- **Before and after a change:** the same harness, profiles, seeds and scenarios as the audit that proposed it; first reproduce one recorded cell on a clean copy of the committed code (the tests are deterministic); run "after" from a snapshot of the working tree so edits made meanwhile cannot leak in; never compare across tool versions. Add only the scenario the change needs to be visible, with its own "before".
- **Read each checkpoint against what the change touches** (for a trait, its share of that wave's enemy HP); expect movement only there.
- **Noise:** two seeds on a 1.2x budget grid move a cell by a step either way for reasons unrelated to the change. Rerun a contradicting cell with more seeds before calling it a gain or a regression.
- **A failed trial may be a stall, not a loss:** a stall breaks a binary search (which assumes more army never holds worse). Diagnose with per-seed replays at fixed budgets and a trace, and for a before/after check prefer a few fixed budgets per recorded cell (the recorded budget and one step below) over a fresh search.
- **Compute value per resource for each option** (damage per second per 100 resources). When one option is an order of magnitude behind, a percentage rule cannot make it matter; say so rather than expect it.
- **Know the test's limits:** a time limit fails slow armies on time, not on losses; mark those cells.
- **Authored opponents need two army models.** When difficulty is a fixed authored table (Growing Kingdom's 33 rival kingdoms), tune it against a **typical** army (what a player plausibly has when they first meet entry k: tiers, mix and upgrades growing with k) and check it against a **floor** army: the weakest the game can force, built from the worst case of every random pick (Growing Kingdom: the k - 1 Prestige cards least useful to an assault, Tier 1 Warriors until the draw runs out of other cards) with the steady layer maxed. The floor is the no-soft-lock promise ("no specific card is ever required"); make it a pass/fail check in the suite, at the population cap, and keep the typical search out of it.
- **Calibrate by scaling in memory, then write the curve once.** A calibration mode that scales a template in memory (every count and cap times m, the boss HP at N seconds of the typical army's damage) and bisects m for a survival target answers "how strong may entry k be" for the typical and the floor army; fit those numbers into the generator's curve and regenerate the data, never hand-edit the outputs. Calibrate a sample of entries in parallel processes, then verify every entry with the real data.
- **Trace a lost battle before retuning it.** A battle that drags for minutes and ends with the objective untouched is usually a behaviour bug, not a strength problem. Growing Kingdom's rival audit showed its weakest army "collapsing" from the 13th rival; a per-20-second trace (units left on both sides, reserves, objective HP, the last enemies' positions) showed reinforcements fighting from their building doors, and later a healer standing inside the Castle's footprint, both where the attackers' movement clamp could not reach. One shared ground for both sides fixed it, and the same army then won every rival. Rule: both sides of a fight move on one ground; no unit may stand where its attackers cannot reach it.
- **Remember that `threat` is not comparable across compositions.** Budget-by-threat sizing piled the archetypes that are deadliest per threat point into a few entries; size a fixed composition by count instead, and let composition change only on a schedule.
- **Keep audits out of the pass/fail suite** and out of ordinary feature work (section 60.1); their numbers go into the decision log with their assumptions.

Reuse (Growing Kingdom): `tests/balance_audit.tscn` (`--hold`, `--budget`, `--seeds`, `--trace`, profiles fresh / mid / late; see its header), IMPLEMENTATION_DECISIONS.md B8 to B10.

Reusable rule:

> Every economy, AI, wave or map change runs through a bot that plays the whole game, not only through rule checks; army questions get a controlled hold test with the economy held constant. Bots measure; people judge whether it feels right.

---

# 113. Godot editor and tool boundaries

Three Godot 4 traps that cost Feed the Dragon time, each with a guard that now prevents it:

- **`--script` tools cannot see autoloads.** A tool that instantiates entity scenes referencing an autoload fails to compile them and may silently drop exported data. Run such tools as scenes (`tools/build_world.tscn`), not with `--script`.
- **`@tool` scripts run inside the editor, where autoloads are inert placeholders.** Guard every editor path and `_process` with `Engine.is_editor_hint()` before touching run state. The probe runner opens the main scenes in the editor headlessly and fails on any error line, so a missing guard is caught before a human opens the editor.
- **Tests must never touch the real save.** Every probe and capture tool requires `--save-path=user://<name>.json` and refuses to run without it.
- **When a first-run screen is added, make every end-to-end probe choose explicitly.** A chooser that pauses a fresh profile would stall every scene probe. Each probe sets the onboarding mode (Skip) before it instantiates the main scene, so all of them start exactly as before, and the onboarding checks do a Hard Reset and choose their own mode.
- **`Array()` of a typed array is not a copy.** In Godot 4 it returns the same array. Feed the Dragon's `to_save_dict()` stored `Array(construction_order)`, and the offline pass used that dictionary as its in-memory snapshot: the dry run changed the live array, the restore brought back a changed order, and the offline pass built projects in the wrong order. Any `to_save_dict()` that is also used as a snapshot must `duplicate()` its typed arrays, with a regression test that changes the live array after saving (`test_save_dict_is_a_copy` in `tests/core_probe.gd`).

Reuse: `tools/run_probes.ps1` in Feed the Dragon (editor-open check, then every probe with its own save path).

Reusable rule:

> Make each engine trap a probe failure, not a note.

---

# 114. Choices with a slot budget: one control per item type, not per unit

When the player keeps N units out of a pool that holds several of the same item (Prestige stacks, inventory copies, party members of one class), show one row per item type with a stepper ("kept / owned", minus and plus) and a shared "slots used" counter.

Feed the Dragon's first version showed one toggle per stack. The rule was correct (each stack filled one slot), but testers read three toggles of one reward as one choice, could not express "keep 2 of 3" directly, and the grid overflowed the screen with every stack owned. One row per reward fixed all three.

Also:

- disable plus when the budget is full or every copy is kept, and guard the same limits in the handler, since probes and fast taps can bypass a disabled state;
- keep the output format the logic already validates (one entry per kept unit), so the UI change needs no state change;
- capture the screen with every item owned (section 42).

Reusable rule:

> Let the player choose a count per item type; never make them pick identical copies one by one.

---

# 115. City-builder worker economy: tasks, drop-offs, storage and construction

Sections 10 to 13 and 80 describe one kind of worker on one resource. This section covers a whole city of them: workers who gather several resources (a building material, a currency, a survival food) from finite nodes, deliver to drop-off buildings, build, and carry food to a consumer that must be kept fed, all from player-set priorities, with one shared storage pool. These rules kept that economy readable, exploit-free and safe through save, offline and destruction. Sections 116 to 127 describe how the stack is implemented and tested.

## 115.1 Workers run a priority list that falls through

Each worker holds a short ordered list of tasks (one slot at first, more as account unlocks). It runs **the first task it can actually do right now**, otherwise it idles:

```text
for task in priorities:
    if executable(task): run it; stop
idle and re-check shortly
```

"Executable" is a real check, not a label:

- gathering: storage has room, a drop-off for that resource exists, and a reachable node with unclaimed stock exists;
- building: any construction project exists;
- feeding: the target can take one more unit, **counting what is already on its way** (reserved by other feeders), and there is something to carry.

That makes "Feed first, Gather Food second" work on its own: when the consumer is full, the feeder falls through to gathering, and returns to feeding when its need rises again. No special "smart" mode is needed for that.

**An explicit Smart mode is a valid progression reward, not a fallback.** When a game makes worker intelligence something to earn (Growing Kingdom's Smart Workforce, a Prestige unlock), keep the manual list as the default doctrine and add Smart as an **assignment mode per worker, above the priority list** (section 8.2 is the generic pattern: state ownership, creation in a mode, queue snapshots, bulk changes). For workers:

- **Preserve the hidden manual list.** Smart ignores it but never edits it; switching one worker back restores its own list. Every manual edit of a Smart worker (its dropdowns, a direct command, a group order) is refused with a reason ("switch it to Manual first"), never applied to the hidden list. The "Apply to all" of the default for new workers touches manual workers only; making everyone Manual with one shared list is the separate bulk action of section 129.6.
- **Show the state, hide the machinery.** A Smart worker's task controls give way to a clear tag (and a tinted row), while its status line keeps saying what it is doing; the internal timer stays hidden.
- **Allocate as a workforce, then commit.** A Smart worker takes the greatest unmet need after counting the workers already on each task (section 8.2: need from **one shared helper**, shared by coverage, impossible tasks excluded); it finishes the project it took on, even if another is moved ahead, and keeps a resource for a fixed interval of simulation time (Growing Kingdom: 2 minutes) so it does not jump after every delivery. It reassesses at once when its task becomes impossible and when the player switches it on; new construction calls it only while the project's unmet need is at least its resource's, so an unattended project always gets someone and never everyone. The commitment is anti-thrashing, never permission to idle. A Smart worker never walks its hidden manual list: Smart and Manual are separate decisions.
- **Save the commitment** (the chosen task, when it ends in run time, the project it is finishing) so a reload neither resets it nor changes what happens next; probe the replay.

Also:

- **Re-evaluate at natural cycle boundaries** (after each delivery, every few seconds while building, after a feeding trip), not every frame. Workers stay stable, and an automatic change of plan never throws away what they carry, with one exception: a load its storage cannot take is put down when, and only when, that lets another task run (section 115.4).
- **A player's order takes effect at once.** A direct command or a priority edit re-plans the worker immediately; a carried load the new task does not deliver is put down as a pickup, never deleted (section 115.4). Waiting for the current delivery is stable but feels unresponsive: the player ordered a change and nothing happened.
- **A direct command edits the priority list through the one edit rule** (section 129.5). There is no separate "manual mode" to save and clear.
- **An unreachable target gets a short cooldown** for that worker, so it does not retry the same blocked node every frame.
- **Decide which question a workforce number answers before choosing what it counts** (section 124.2): an allocation number counts assigned workers, including those walking or waiting; a throughput number counts the workers actually executing the task.

## 115.2 Resource nodes: finite stock, claims that reserve stock, respawn

Each node holds a small stock (a few trips) and becomes unavailable at zero, then respawns on a timer that lives in state (so it advances offline and is saved). Section 80's spread rule, refined for a large map:

```text
valid nodes = right type, available, reachable, unclaimed stock > 0
prefer nodes nobody has claimed
pick randomly among the NEAREST few (three) of those
share a node only while its unclaimed stock still covers another trip
```

A claim reserves a trip's worth of stock (`stock - claims × carry`), so two workers never walk to the last load. Claims are runtime-only: they are rebuilt when workers re-plan after a load.

## 115.3 Drop-offs make building placement a decision

- The general building (House, Storage) accepts every resource; specialised ones (Lumberjack: Wood, Gold Building: Gold) accept one.
- Workers deliver to the **nearest valid drop-off**. Travel distance is the cost a well-placed drop-off removes.
- A specialised drop-off's tier bonus belongs to **that building instance** (+25% / +50% on deliveries there), so upgrading the Lumberjack beside the forest you use is a different choice from upgrading a distant one.
- Show every delivery as a floating "+amount" at the drop-off (section 13), with the bonus included.

## 115.4 Carried resources are never deleted

With one shared storage pool, "storage full" is a normal state, not an error:

- deposit what fits and **keep the rest in the worker's hands**; the carried type and amount are saved with the worker;
- a worker with full hands may still do the task its load serves (Feed, if it carries Meat); a game may also let it do tasks that do not need hands (Build) while holding the load, but Growing Kingdom puts a blocked load down for Build too (below), so one rule covers every task;
- **a blocked load falls through, it does not block the list.** If the load cannot be delivered (its storage is full) and a later task in the worker's list can run, the worker puts the load down as an ordinary pickup (the same function and pile as a reassignment drop below: exact type and amount) and starts that task at once, Build included (Growing Kingdom first kept the load while building; one rule for every task proved simpler to read and to probe). With nothing else executable it keeps the load and waits: a fallthrough, never littering. Growing Kingdom first held the load whenever storage was full, so a "Wood → Gold" Villager stood holding Wood while Gold could have been gathered; the correction made the blocked load a pickup only in that case;
- decide this with the same pure plan the reassignment uses (the task an empty-handed worker would start now), and check it where the worker already decides: after a gather, on arriving at a full drop-off, when the storage fills while it walks there (the trip's target became invalid), and while it waits;
- an idle worker unloads by itself once there is room.

Pair this with section 112: the survival resource must always have a path into storage, and a blocked state must be loud in the UI.

**A player's reassignment puts the load down as a pickup.** To make a reassignment immediate without breaking "never delete what they carry":

```text
priorities changed by the player?
  keep the load only if the new plan delivers it (the task an empty-handed worker would start now is that resource)
  otherwise put it on the ground as a pickup: exact type and amount, where the worker stands
  decide now (targets and claims are derived from the record, so they are released)
an unchanged list only re-plans; nothing is dropped
```

- Compute "the plan" with a **pure** version of the decision (no movement, no claim, no random draw), or the check itself changes the simulation.
- A pickup is run state like a node: id, type, amount, position; saved, restored by id (so a worker walking to it still finds it), cleared by a new run. Merge a drop into a nearby pile of the same type so repeated drops stay one readable pile.
- Workers on that resource collect pickups before nodes (they are free work), take what fits, leave the rest (take a sub-epsilon remainder whole), and deliver as usual; bonuses apply at delivery exactly as they would have. With storage full, piles wait.
- Route **every** reassignment path (single worker, dropdown, apply to all, group command, multi-select) through one function, so each load drops at most once per change.
- **Conservation probe:** resource in storage + on the ground + in hands is unchanged across any reassignment and any blocked-load fallthrough; a batch drop moves exactly what the hands held. Probe the fallthrough for every resource pair, with both tasks blocked (load kept, no pickup), with Build next (pickup created, Build starts) and with one task only (load kept).
- Show the drop: the pile pops (idempotent tween, section 76) and a short text says what was put down.

Reuse (Growing Kingdom): `RunState.assign_task()`, `_reassign()`, `EconomySystem.reassign()` / `planned_task()` / `_decide_blocked_load()`, `SimPickup`, `PickupVisual`; `core_probe` "reassignment drops the carried load", "a blocked load falls through to the next priority".

## 115.5 Construction is a player-ordered project list

```text
every project progresses passively (1 work/s)
each builder on site adds 1 work/s
all builders work the TOP project
the player can move projects up and down
```

- The passive rate means nothing ever stalls completely; builders are an accelerator the player chooses to spend workers on. Passive progress is a design choice: Growing Kingdom deliberately has none, so the Build task always matters; a game without it must make "a project waits and nobody builds" loud (a badge, a coach hint, section 18.7).
- One top project gives the player one clear lever ("what do I want first?") instead of per-builder assignment.
- **Tier upgrades are construction projects too:** paid up front, they join the same list, progress the same way and run offline. While being rebuilt, the building **keeps working at its current tier** (storage, population, drop-off, training), so upgrading the only House never removes capacity. The tier rises when the work completes.
- Unfinished construction and upgrades are lost when the city is destroyed; a surviving building keeps the tier it had.
- Show the next tier as the construction silhouette, and use authored palette variants per tier (section 73).

## 115.6 Population: one pool, reserved at queue time

Workers and trained troops share one population pool from Houses. **A queued unit reserves its population when it is queued,** not when it finishes, so the player can never queue past capacity and a finished unit always has room. Training queues live in the building that trains (section 109), and a queue that outlives a destruction pauses while population is full.

## 115.7 Offline: simulate timers, never free labour

The offline window advances every timer through the same `tick_timers()` as live play (section 31): construction, training, research, respawns, Hunger. Workers are resolved **abstractly from their saved priorities with the same fall-through rule**: a worker whose first executable task is Build adds builder work to the top project; a feeder consumes one unit per feeding cycle.

**Gathering is not simulated offline.** It has no timer the player started, and simulating it would make closing the app the best income source. Offline, gather tasks count as unavailable and workers fall through to Build or Feed. The small, capped Offline Reward (section 94) replaces it, limited by free storage.

The simplest exploit-free alternative, validated in Growing Kingdom: **freeze the whole run while the app is closed** (no combat, construction, research or training advances) and grant only a small, capped meta-currency reward for the absence, computed once and kept until claimed (section 58).

## 115.8 Credit at the moment of commitment, animate afterwards

The feeder's Meat restores Hunger **at the toss**, in the same step it leaves the worker's hands; the flying Meat is presentation only. A force-close can never lose a unit in flight, and the save never holds "half a delivery". The same split applies to every worker: carried amounts are saved; paths, positions, claims and in-flight visuals are runtime-only and rebuilt from state (section 111).

## 115.9 Authored plots, generated nature

Building plots are authored (their positions are design); forests and deposits can be generated deterministically around them. (A game with free placement keeps the same rule for everything that is not a building: section 119.2.) The generator must keep every tree canopy off every plot: a device test found canopies drawn over two plots that won every tap. The world probe now taps the centre of every plot and checks that the plot is selected.

Reference implementation (Feed the Dragon): `scripts/world/villager.gd` (`decide()`, `_can_do()`, feeding at the toss), `World.find_resource_target()` and `nearest_dropoff()` in `scripts/world/world.gd`, `RunState.deposit()`, the construction and population functions in `scripts/autoload/run_state.gd`, `OfflineSimulator` (abstract builders and feeders) in `scripts/core/offline_simulator.gd`, and `tools/build_world.tscn` (canopy clearance). Implementation details: sections 118 (nodes and claims), 119 (buildings and construction), 120 (the worker entity).

Reusable rule:

> Let workers run the first task they can really do, make the player's orders take effect at once without ever deleting what workers carry, give construction one ordered list, reserve population at queue time, and never simulate free labour offline.

---

# World-interaction stack (sections 116 to 127)

Sections 116 to 127 describe a reusable stack for 2D top-down games in which autonomous workers walk a map, gather from resource nodes, deliver to buildings and construct on authored plots, while the player pans, zooms, taps things to inspect them and gives orders through contextual panels. Section 115 holds the economy **design rules** (priority fall-through, drop-offs, carry safety, construction order, offline). These sections hold the **implementation**: who owns which data, how the world presents it, how input reaches it, and how it is tested.

| Section | System |
|---|---|
| 116 | State architecture: one authoritative state, a disposable world |
| 117 | Navigation grid and movement |
| 118 | Resource nodes |
| 119 | Building plots and buildings |
| 120 | Worker lifecycle |
| 121 | Touch input arbitration and the map camera |
| 122 | World picking, selection and the selection marker |
| 123 | Contextual information panels |
| 124 | HUD and assignment presentation |
| 125 | World readability and feedback techniques |
| 126 | Recreating the stack: dependency order and stage gates |
| 127 | Validation matrix |

Each section ends with a **reuse classification**:

- **Generic:** carry it into any game with this kind of world.
- **Configure per game:** the mechanism is reusable, the values, catalogs, art and labels change.
- **Mechanic-specific:** reuse only when the new game's design has the same mechanic.

Numbers quoted as "reference values" are the ones validated on a 1920 × 1080 landscape phone layout with 64 px terrain cells and 192 px character frames. Treat them as starting points, not rules.

Reference implementation paths are **Feed the Dragon's**, where this stack was investigated, given once per section for readers who have that code; the text is written to be implementable without it. Growing Kingdom rebuilt the same stack with a fully headless simulation (section 116.11) and free building placement (section 119.2); where its validated choice differs, the section says so and names its files.

---

# 116. State architecture: one authoritative state, a disposable world

## 116.1 Problem

A living world tempts every entity to keep its own truth: the tree node knows how much wood it has left, the building sprite knows its tier, the worker knows what it carries. Then save, load, offline progress, destruction, Prestige and debug test saves each need their own code to reach into the scene, and sooner or later the screen and the save disagree.

The pattern that avoided this: **every gameplay quantity lives in state objects; the world is presentation plus agent behaviour, and can be thrown away and rebuilt from state at any moment.**

## 116.2 State layers and owners

| Layer | Owner | Lifetime | Saved | Examples |
|---|---|---|---|---|
| Configuration | a static `Balance` class | build | no | resource types and names, node catalog (resource, stock, respawn seconds), building catalog (cost, build time, tiers, drop-off types, what it trains), task ids and names, worker speed, carry, gather times, construction rates |
| Map registry | authored world scene, registered into run state at boot | session | no, rebuilt every boot | plot ids with allowed building types and a start flag; node ids with node type |
| Account state | `ProfileState` | across runs | yes | per-worker-slot task priorities, unlocks (task slot count), blueprints, permanent upgrades |
| Run state (authoritative) | `RunState` | one run | yes | resources; building records `{type, tier, state, upgrading, work_done, work_total, built_order, queue}`; construction order; worker records `{slot, carry_type, carry_amount}`; node records `{type, stock, respawn}`; run upgrades |
| Runtime reservations | `RunState`, in fields that are never saved | until the next resync | no | node claims `{node_id: [worker slots]}`, delivery already in flight, last recruiting plot (a spawn hint) |
| Entity runtime | world entity nodes | until the next resync | no | worker phase, path and path index, current purpose, target references, timers, unreachable cooldowns, status text, facing |
| Presentation | world entity nodes | until the next resync | no | sprites and animations, displayed progress, tweens, effects, floating text, the selection marker |
| UI state | `World` and `Hud` | session | no | the selected object (World), the open side panel, the context panel's structure key, the toast queue, the tutorial pointer's target |
| Settings | `SettingsState` | device | yes | game speed, vibration, the collapsed state of the side dock |

Two rules decide where a new value goes:

> If losing the value at a force-close would change gameplay, it belongs in run or account state and is saved. Otherwise it is runtime, and it must be rebuildable from saved state.

> Reservations shared by several agents (who is walking to which node, what is already in flight) live in the state object, so every query answers the same way, but they are never saved and are cleared at every resync, because the agents that own them are being replaced.

## 116.3 The complete data and control flow

```text
Player input (tap, button)
  -> intent method on a state owner: start_construction(), upgrade_building(),
     queue_recruit(), direct_command(), move_construction_priority() ...
     each validates with its *_block_reason() twin, mutates, marks the save dirty
     and emits a signal

Simulation tick (World._process, one clamped step per frame)
  -> RunState.tick(dt): timers shared with offline (construction passive work,
     training queues, node respawns, other timers)
  -> worker.tick(dt) for every worker: movement, work, delivery; every gameplay
     effect goes through a RunState method (take_from_node, deposit, set_carry,
     add_construction_work, feed ...)

RunState signals (discrete changes)
  -> World handlers -> entity.refresh() and one-shot feedback (dust, punch,
     floating text)

Continuous values (progress, amounts, countdowns, statuses)
  -> polled from RunState getters: entities while something animates,
     UI on throttled intervals (HUD 0.1 s, context panel 0.2 s, lists 0.25 s)

SaveService
  -> mark_dirty(): written within a few seconds (reference 5 s)
  -> save_now(): at irreversible moments (run end, run start, offline report)
  -> lifecycle saves: close, back, app pause, focus loss; plus a periodic save

Wholesale replacement (load, offline return, reset, Prestige, debug test save)
  -> RunState emits state_replaced
  -> World.sync_from_state() (deferred and coalesced) rebuilds every entity
```

## 116.4 Three synchronization mechanisms, each for its own job

**1. Events for discrete changes that deserve feedback.** Construction started, completed and upgraded; building changed; node changed; worker spawned; worker list changed; destruction. The world handler refreshes the one entity concerned and plays its feedback. An event carries an id, never a copy of the data; the handler reads the record.

**2. Polling for continuous values.** Progress bars, resource amounts, countdowns and worker statuses are read from state, never pushed. To keep this cheap:

- an entity enables `_process` only while it has something animated (a plot turns processing on only while it is under construction, upgrading, or training), and redraws only when the value moved past a threshold (reference: 0.001 of a progress bar);
- UI refreshes on intervals (0.1 s for the HUD, 0.2 s for the context panel) and writes a label only when its text changed.

**3. Full resync for wholesale replacement.** `World.sync_from_state()`:

```text
clear runtime reservations (node claims, in-flight delivery)
refresh every plot and every node (without feedback effects)
refresh every depot display
free every worker node; spawn one per saved worker record at a default spawn point
rebuild secondary units (troops) from their counts
restore special world states (destroyed, defeated) from the run phase
keep the selection only if it points at an authored entity that still exists
  (plots, nodes); workers were replaced, so their selection clears
```

Run it deferred and coalesced: a flag is set on `state_replaced`, and one deferred call does the work, however many replacements happened in that frame. Also call it explicitly after the boot-time offline pass, after a return from the background, after Rebuild or Prestige, after Hard Reset and after loading a debug test save.

**Mute state signals during offline simulation.** The offline pass runs a dry run and a live run through the same rule functions. A mute counter in the state owner suppresses every signal while it runs, and the world resyncs once afterwards. No feedback storm, and no entity sees a half-applied state.

## 116.5 Effective values are getters, and timers store base units

Every derived number has one getter on the state owner that combines the base constant with run upgrades, account upgrades and research: move speed, carry capacity, gather time per resource, passive construction rate, builder work rate, node regrowth multiplier, delivery bonus of a given drop-off for a given resource, recruit time. Worker movement, offline simulation, the context panel and the stats screen all call the same getter. Gameplay and UI never read the base constants.

Timers store **base units** and apply the multiplier to the step:

```gdscript
# Respawn countdown stays in base seconds; a regrowth bonus bought
# mid-countdown speeds up the rest, and the saved value stays exact.
func _tick_respawns(dt: float) -> void:
	var step := dt * node_regrowth_multiplier()
	for node_id in nodes.keys():
		var n: Dictionary = nodes[node_id]
		if float(n["respawn"]) <= 0.0:
			continue
		n["respawn"] = float(n["respawn"]) - step
		if n["respawn"] <= 0.0:
			n["respawn"] = 0.0
			n["stock"] = node_max_stock(String(n["type"]))
			_emit_arg(node_changed, node_id)
```

The UI converts to an effective ETA by dividing by the multiplier (`respawn / node_regrowth_multiplier()`). The same holds for training queues (`remaining` is base work) and construction (`work_done / work_total` in base work units).

## 116.6 Authored map registry and stable ids

- The world scene contains every authored plot (`slot_id`, `allowed_types`, `start_house`) and every resource node (`node_id`, `node_type`, `variant`) as editor-visible instances.
- At boot the world collects them through node groups (only its own descendants, so probes that load several scenes stay clean), then `register_map()` hands `{id: data}` to the run state **before** the run is created.
- The run state keeps the registry as static data and reconciles saved state against it, at registration and at every load: buildings on unknown plots are dropped, missing nodes are added fresh, stale node records are dropped, and the construction order is rebuilt to contain exactly the buildings under construction.
- **Ids are save keys.** Never rename a shipped plot or node id. Positions, art and allowed types may change freely.
- **A second, opposing base is the first one transformed, never a second authored map.** When the player attacks a base built like their own, derive it from the one authored map through one explicit transform (Growing Kingdom: a 180° turn, `WorldLayout.to_rival()` and its inverse) and run the same layout rules over the same sites with the opponent's own seed, then transform the result. Every opposing coordinate (its field and its clamp, the castle footprint and front, its attack positions, tower slots, landing band, defender lines) is then a function of a home one, and combat rules can be worked out in the home frame and shared (one castle-attack rule for both castles). A hand-built copy drifts at once: Growing Kingdom's first rival island was an approximation with its own constants, a different town height and a castle rule measured to its footprint, and read as an arena with buildings. Keep art upright when the asset set has no back-facing variants: turn the band the sprite covers and mirror it left to right, never flip it vertically. The same holds for terrain: a tileset that draws cliff faces and stairs only facing one way cannot turn a ramp around, so open the edge flat where the opposing base needs an entrance (Growing Kingdom: no plateau rim across the rival Castle's front, the battlefield ground running up to it) instead of showing a wrong or upside-down face, and make the open ground exactly the ground units may walk (a probe checks the path from the gate to every attack position crosses no raised tile). Readability and traversability beat a literal mirror. If the opposing base presents its buildings as working, production comes out of them: each unit appears at the door of the building whose queue made it and walks to the fight (through its castle, as the player's own do), several buildings each from their own; a unit appearing in front of the castle reads as a scripted arena again. The simulation may read the transformed layout for that if it stays a pure, unsaved function of the opponent.

Boot order, which must not change:

```text
1. autoloads load the save
2. the world registers the authored map with the run state
3. ensure_run() creates the fresh run if none exists
4. the bounded offline simulation for the time away
5. world.sync_from_state() builds every presentation object
6. pending flows (run results, a choice in progress), else the Welcome Back summary
7. first-run choices (onboarding mode) once no other modal is open
```

## 116.7 One simulation clock

- Game speed is `Engine.time_scale` in Feed the Dragon. Growing Kingdom instead runs a fixed simulation step (1/30 s) from an accumulator that game speed scales, which leaves every UI tween and timer on wall-clock time without opting out one by one; count real and game time from that one clock (section 17.3).
- In the `Engine.time_scale` variant the world advances the simulation once per frame with `dt = min(delta, MAX_FRAME_STEP × time_scale)` (reference `MAX_FRAME_STEP` 0.1 s), so a hitch or an Android resume never lands one huge unobserved step. Real absences go through the offline pass instead (section 111).
- Sprite animations and gameplay-synced micro feedback (a tree swaying under an axe) run on game time and speed up with it. Presentation that must keep a readable length regardless of speed runs on real time: toasts, banners, alerts, tutorial pulses, the destruction sequence (`tween.set_ignore_time_scale(true)`, or `delta / Engine.time_scale`), and the save timers.
- The world node is `PROCESS_MODE_PAUSABLE`; HUD, modals and camera are `PROCESS_MODE_ALWAYS`. Pause is owned (section 26): the tree stays paused while any owner remains.
- While a scripted sequence plays (destruction), the world stops ticking the simulation and agents; the state already holds the outcome.

## 116.8 Rules that stop the world from becoming a second source of truth

1. **Entities read, never cache, gameplay quantities.** A worker's `carry_amount()` reads its record in the run state every time. A plot's tier comes from the building record on every refresh.
2. **Every mutation is an intent on the state owner, with a block-reason twin.** `start_construction()` and `construction_block_reason()` share one validation. The button is disabled by the reason; the intent re-checks it anyway, because probes and fast double taps bypass a disabled state.
3. **Credit at the moment of commitment, animate afterwards** (section 115.8). Projectiles, flying resources and floating numbers never carry value.
4. **Outcomes are resolved and saved before presentation.** A destruction result names the destroyed and surviving buildings; the burn sequence reads that list. It never decides anything.
5. **A presentation tween that could outlive a state change is owned and killed by `refresh()`.** The validated regression: a destruction fade paused under the results modal resumed after Rebuild and faded out the new building while workers still used it.
6. **Runtime reservations have one release path per owner:** released at the end of each use, released by `decide()` before re-planning, released in the entity's `_exit_tree()`, and cleared wholesale at resync.
7. **`to_save_dict()` returns copies** (`duplicate()` every container, typed arrays included), because the offline pass also uses it as an in-memory snapshot (section 113).
8. **Load sanitizes every record:** clamp stock and timers to their catalog ranges, drop unknown types and ids, keep only valid carry types, de-duplicate worker slots.
9. **A group transition that hides its members is one step on the group, with a bounded wait.** When a group leaves sight together (boarding ships, entering a portal, garrisoning), let each member walk to a visible staging place and wait there; when all stand ready, one function moves every living member and the group to the new stage in the same tick. Never let a member hide itself and the group wait for the rest: Growing Kingdom's soldiers each went into the water on reaching the beach while the group sailed only once all were aboard, so one soldier stuck on its way left the rest of the army invisible forever and the assault could never end. Give the wait a generous timeout (the longest legitimate walk plus slack) after which a straggler is brought to its staging place, never killed, failed or copied, and the group goes; logistics is not a challenge. Load (and the tick) repairs the mixed state an older build could save, back to the visible staging state.

## 116.9 Reuse classification

- **Generic:** the layer table, intents with block-reason twins, the three sync mechanisms, deferred coalesced resync, muted signals during offline, getters for effective values, base-unit timers, the map registry with reconciliation, stable ids, the clamped frame step, the nine rules above.
- **Configure per game:** the catalogs, which records exist, refresh intervals, `MAX_FRAME_STEP`, save timings.
- **Mechanic-specific:** survival rolls on destruction, Prestige layers, run phases beyond active and ended.

## 116.10 Mistakes to avoid

- Saving positions and paths "to be safe". They make every load a migration problem and buy nothing: agents re-plan in one frame.
- Emitting signals with data payloads that UI then caches.
- A resync that forgets runtime reservations: the old agents' claims survive and block nodes for the new agents.
- Letting a tutorial, a debug tool or a probe edit entity nodes directly instead of calling state intents.

Reference implementation: `scripts/autoload/run_state.gd`, `scripts/world/world.gd` (`sync_from_state`, `register_map`, `_process`), `scripts/main.gd` (boot order), `scripts/core/offline_simulator.gd` (muted dry run).

## 116.11 Variant: the whole simulation headless

Growing Kingdom took the split one step further: **agent behaviour lives in state too.** Workers, soldiers, enemies, construction, waves and automation are plain records advanced by system objects (`EconomySystem`, `CombatSystem`, `WaveSystem`, `DeploySystem`) on a fixed step owned by the run state; the world scene only draws them (interpolated between steps) and turns simulation events into effects. Nothing in a scene decides anything.

What it bought:

- save and resume of everything, including in-flight combat, with no world involvement;
- a whole first run (about 20 minutes of play) simulated by the pacing bot in under a second, and balance audits that run thousands of fights headless;
- probes that test rules without a scene, and world probes that only check presentation;
- one place for every rule, so the action layer (block reasons, the pause lock) covers every path.

The cost is that presentation must be event-driven and interpolated (a visual never owns timing: contact frames are fired from the simulation's gather timer, section 120.9), and that pick rectangles and movement live in the simulation's geometry (`Geo`). For a new game with combat, many agents or bot-driven balance, start here.

Reference (Growing Kingdom): `scripts/autoload/run_state.gd`, `scripts/core/sim/*.gd`, `scripts/world/world_view.gd`, `scripts/core/geo.gd`.

---

# 117. Navigation grid and movement

## 117.1 Problem

Workers must walk believable routes around cliffs and water, reach buildings and nodes of very different sizes, never get stuck, and do it cheaply for dozens of agents at 3x speed, headless in probes and identically every run.

## 117.2 Representation: an explicit walkability layer, separate from the art

- A grid with the terrain's cell size (reference 64 px; a 64 × 36 map with a one-cell water border).
- Walkability is **authored**, not inferred from decorative sprites. A hidden marker `TileMapLayer` (called NavBlock here) sits in the terrain scene with two marker tiles: *blocked* and *walkable override*. A cell is walkable when it carries the override marker, not walkable when it carries the blocked marker, and otherwise walkable exactly when the ground layer has a tile.
- The terrain builder paints the blocked markers for cliffs, plateau rims and the walls that frame stairs; stairs themselves are walkable. After the first bake, the layer is edited by hand in the editor; an exported `show_navigation` toggle on the terrain node makes it visible there.
- **Buildings, trees and resource nodes do not block movement.** Y-sorting draws a worker in front of or behind them correctly. This keeps plots and nodes free to sit wherever the design wants, needs no re-baking when a building rises or a tree is cut, and makes it impossible for a worker to be sealed inside a dense forest.

```gdscript
func is_walkable_cell(cell: Vector2i) -> bool:
	var marker := nav_block.get_cell_atlas_coords(cell)
	if marker == NAV_WALKABLE:
		return true
	if marker == NAV_BLOCKED:
		return false
	return ground.get_cell_source_id(cell) != -1
```

## 117.3 Pathfinding

`AStarGrid2D`, built once when the world is ready:

- `region` = map size in cells, `cell_size` = tile size, `offset` = half a cell (points are cell centres);
- `diagonal_mode = DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES` (no corner cutting through cliffs);
- octile heuristics for both compute and estimate;
- `set_point_solid()` for every non-walkable cell.

Conversions: `to_cell(pos) = floor(pos / tile)`, `cell_center(cell) = cell × tile + tile / 2`.

```gdscript
func find_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	var start := nearest_walkable_cell(from)
	var goal := nearest_walkable_cell(to)
	if not _astar.is_in_boundsv(start) or not _astar.is_in_boundsv(goal):
		return PackedVector2Array()
	# End exactly at the target when it is walkable, else at the snapped cell.
	var end_point := to if is_walkable(to) else cell_center(goal)
	if start == goal or _line_clear(from, end_point):
		return PackedVector2Array([end_point])
	var cells := _astar.get_id_path(start, goal)
	if cells.is_empty():
		return PackedVector2Array()   # unreachable
	var raw := PackedVector2Array()
	for i in range(1, cells.size() - 1):
		raw.append(cell_center(cells[i]))
	raw.append(end_point)
	return _smooth(from, raw)
```

- **Nearest walkable cell:** if the cell is blocked, search square rings of radius 1 to 7 and take the walkable cell whose centre is nearest the position. A target on a cliff edge, or a worker spawned on a blocked cell, still gets a path.
- **Smoothing (string pulling):** from the current anchor, jump to the furthest later point with a clear line, append it, repeat. Workers walk natural diagonals instead of cell-to-cell zigzags.
- **Line clear:** sample the segment every quarter tile and require every sample to be walkable.
- A path is computed **once per trip**. The map is static during play, so there is no re-pathing.

## 117.4 Interaction positions on large objects

The destination is never the object's origin. Each entity exposes the points workers use:

| Point | Rule (reference values) |
|---|---|
| Node work point | Beside the node on the side the worker approaches from: `origin + (±gap, 6)`, gap 44 px for a tree, 62 for a large gold deposit, 34 for an animal |
| Drop-off point | In front of the building base, 22 px below the origin (the doorway) |
| Builder work points | Five spread points around the footprint (left, right, two lower corners, front centre), chosen by `worker_slot % 5`, so builders do not stack |
| Depot pickup point | A fixed offset beside the depot sprite |
| Delivery point to a fixed consumer | A fixed map point (the toss point), authored in the map layout |

Because buildings do not block navigation, these points are what makes a worker visibly *stand at* the building instead of walking into its sprite.

## 117.5 Movement

```gdscript
func _move(dt: float) -> void:
	var budget := RunState.worker_move_speed() * dt
	while budget > 0.0 and _path_index < _path.size():
		var target := _path[_path_index]
		var to_target := target - global_position
		var dist := to_target.length()
		if dist > 0.5:
			_sprite.flip_h = to_target.x < 0.0
		if dist <= budget:
			global_position = target
			budget -= dist
			_path_index += 1
		else:
			global_position += to_target / dist * budget
			budget = 0.0
	if _path_index >= _path.size():
		_arrive()
```

- A movement budget per tick consumes as many path points as it covers, so high game speeds never overshoot or stall on a corner.
- Speed comes from the effective getter (with task multipliers, such as faster delivery trips from research).
- There is no steering or avoidance between workers; they may overlap, and Y-sort keeps it readable. At city-builder densities this was never a readability problem.
- Secondary presentation-only units (troops drilling around their building, an army marching to its posts) reuse the same grid and the same budgeted follower, so every walker obeys one walkability authority.

## 117.6 Unreachable targets and retries

- An empty path means unreachable. The worker marks a resource node unreachable **for itself** for 10 s (a per-worker dictionary that counts down every tick), releases its reservations, idles with the status "Can't reach target" and retries after 1 s.
- Resource target selection skips nodes in that dictionary, so the retry picks another node.
- Other destinations (drop-offs, construction sites) are simply retried on the next re-plan.
- The soak probe asserts every second that every worker stands on walkable ground (or within 8 px of it), which catches any spawn or snap bug.

## 117.7 Reuse classification

- **Generic:** explicit walkability layer separate from art, nearest-walkable snapping at both ends, octile A* without corner cutting, line-of-sight smoothing, per-entity approach points, budgeted path following, per-worker unreachable cooldown.
- **Configure per game:** cell size, map size, ring search radius, approach gaps and builder point layout, cooldown and retry times, which terrain features block.
- **Mechanic-specific:** dynamic obstacles (walls the player builds), unit avoidance, formations. Add them only when the design needs them; then buildings must also update the solid map when they appear and disappear.

## 117.8 Mistakes to avoid

- Deriving walkability from sprite shapes or collision polygons of decoration.
- Making every building an obstacle without approach points outside its footprint: workers stop at the far side or fail to path.
- Pathing to the target's exact origin when it sits on a blocked cell: every trip fails.
- Re-pathing every frame "for safety" on a static map.
- Running movement with real time instead of the simulation step, which breaks game speed and headless probes.

Reference implementation: `scripts/world/nav_grid.gd`, `scripts/world/terrain.gd`, `tools/build_terrain.gd` (painting the markers), the `get_work_point()` and `get_dropoff_point()` functions in `scripts/world/resource_node.gd` and `scripts/world/building_slot.gd`.

---

## 117.9 Fog of war: discovery is state, fog is presentation

Use this pattern when the game includes exploration or finding enemies/resources through a map. Do not silently add fog, vision obstruction, marker upgrades or exploration rewards to a game whose GDD does not require them. The world camera, minimap and expanded map must read one discovery authority; moving the camera must never explore the world.

**Percent-explored goals must count the same cell unit as the discovery store.** LootFarmer's "explore 90%" counted 24-unit fog cells against an area measured in 48-unit blocks, so it passed at about 22.5% real exploration. When an authored layout moves sites, bump the discovery layout revision and re-home saved actors to their authored homes on load instead of requiring a Hard Reset.

### A. Separate three spatial states and entity knowledge

| Spatial state | State definition | Presentation policy |
|---|---|---|
| Unexplored | Cell has never been revealed in this discovery lifetime | Cover terrain and suppress undiscovered points of interest, unless the GDD explicitly exposes known landmarks |
| Explored, outside current vision | Cell was revealed earlier but no active vision source sees it now | Show remembered terrain dimmed; entity markers follow the memory/intelligence policy |
| Currently visible | Cell is within an eligible source's current vision | Show terrain and entities allowed by the game's identification rules |

Maintain a durable `explored` set/bitset and a transient `visible_now` set/bitset, with `visible_now` a subset of `explored`. For discovery-only games, retain the explored mask without imposing a dimmed current-vision layer. Store the selected fog mode explicitly in the design/configuration.

Cell discovery is not automatically enemy identification. Keep an explicit discovery record per stable point-of-interest/enemy-type id when identification, a bestiary, camps or stairs must remain known after the original entity moves or despawns. Define the identification trigger: first sight, approach, interaction or defeat. A renderer must not mark something discovered merely because it instantiated a node.

### B. One coordinate contract and data owner

Use map-local coordinates with an explicit origin, cell size and integer width/height. A simple dense index is `index = y * width + x`; reject out-of-bounds positions before indexing. Convert world positions through the map transform first; do not assume the terrain is rooted at world zero or has unit scale.

Fog may share navigation cell dimensions, but walkability and visibility are different data. Water can be visible without being walkable. If walls/cliffs block sight, author an independent opaque-cell layer or another explicit visibility representation; do not infer occlusion from decorative sprite silhouettes or treat every unwalkable cell as opaque.

Suggested ownership, adapted to the project's existing architecture:

- A map definition/resource owns stable `map_id`, layout revision, bounds, cell size, discoverable-area mask, vision rules and public landmark policy.
- The authoritative run/profile state owns explored cells and entity-discovery records under that map id and the chosen progression lifetime (116, 109).
- A visibility service computes current vision from eligible simulation actors and exposes queries such as cell explored/visible and marker disclosure. It can be part of the state owner; do not create a second competing state store.
- Views receive dirty regions or a visibility revision and render masks/markers. They never own the durable exploration result.

Use inspector-editable resources/layers for radius, opacity, update cadence, occluders and map bounds where practical (63.1, 67). Code owns the spatial algorithm. A shader, debug overlay or sample preview must not write exploration to a production save.

### C. Reveal from active actors, not from the viewport

1. At boot/load/travel, register the map definition, load validated discovery, then build current vision before showing the first world/map frame. Avoid briefly drawing all markers while the mask initializes.
2. Gather eligible vision sources from simulation state. Typically these are living, deployed companions or the player; dead/resting/queued units and drag/inventory previews do not reveal terrain. Any exceptions belong in the GDD.
3. For each source, inspect only the bounded cell region around its map-local position. For circular vision, test cell-center distance against the configured radius. Union the results so overlapping allies share sight correctly.
4. If the game requires blocked sight, apply the chosen deterministic line-of-sight/shadowcasting rule to candidate cells. Define whether the blocking cell itself is revealed and how corners behave. Otherwise document unobstructed radial reveal; fog does not imply wall occlusion.
5. Replace `visible_now` with the union. Add newly visible cells to `explored`, record any genuinely discovered entities, and emit one revision/dirty-region notification. Losing a source removes only its contribution to current vision, not previous exploration.
6. Update on movement/radius/source changes at a bounded simulation cadence. On teleport, spawn, death, map replacement, load or a vision upgrade, invalidate immediately so hidden markers cannot remain for a frame. Define pause behavior: no movement-based exploration while simulation is paused, while initial/load synchronization still completes.

For continuous movement, account for the distance moved between samples. Reveal along the traversed movement segment or use a cadence/spatial threshold that cannot leave holes behind a fast actor. Teleport is different: reveal the destination, not the straight line across intermediate territory, unless explicitly designed otherwise.

Illustrative state flow, not engine API or a second simulation loop:

```text
next_visible = union(compute_vision(source, map_definition) for eligible sources)
newly_explored = next_visible minus explored
explored = explored union next_visible
visible_now = next_visible
update_discovery_records_from_authoritative_sight()
publish_visibility_revision_if_state_changed()
```

### D. Marker disclosure is separate from revealing terrain

Centralize disclosure in a query returning `hidden`, `unknown`, `identified`, or an explicitly supported remembered state. Both map views, tooltips, picking and world-adjacent labels must use the same policy. Apply it before choosing an icon, building a label or creating a hit target.

An optional configurable progression, discussed for Loopcremental, is:

| Intelligence rank | Eligible, already discovered points of interest |
|---|---|
| 0 | No point-of-interest markers |
| 1 | Generic `?` markers |
| 2 | Specific resource/enemy/chest icons |

This example does not reveal undiscovered locations. Companions and discovered stairs can be explicit exceptions; which markers qualify, whether they persist outside current vision, and when ranks reset are game-specific decisions. Do not impose repurchasing map upgrades each level as a reusable rule.

Distinguish known locations from live remote tracking. Remembering a resource deposit, camp or enemy spawn site does not authorize displaying the exact current position/HP of an unseen moving enemy. For a memory-based game, store last-seen location/status and label it as such, or hide the marker; do not silently read live hidden state. Define how opened chests, depleted resources, dead enemies and respawns invalidate memory. If global up-to-date marker knowledge is intentionally granted by an upgrade, document that exception.

Fog is also an information rule: hidden icons must not remain selectable, open tooltips, expose names/HP bars, appear in search/auto-locate, or leak exact live totals through counters. The GDD may intentionally disclose authored totals or boss requirements; identify those as public information. Decorative particles, loot popups and selection effects must not bypass the same disclosure boundary.

Keep simulation permission separate from map presentation. Fog does not automatically stop off-screen combat, resource simulation or AI pathing. If auto-targeting may only use discovered enemies or unseen cells may be explored by a move order, enforce that gameplay rule in the action/state layer rather than relying on invisible controls.

### E. Persistence, revisits and reset boundaries

Save discovery under stable map id plus the appropriate run/cycle/profile scope, alongside any required layout revision and entity knowledge. Recompute `visible_now` from restored actors; do not trust stale serialized current vision. Serialize a copied, deterministic representation such as validated cell indices or a bounded bitset; reject invalid lengths, indices and unknown map ids.

State the lifetime of each field explicitly:

| Event | Required design decision |
|---|---|
| Ordinary death/respawn | Does discovery remain? Where does current sight resume? |
| Leave and revisit a level | Restore its discovery, or deliberately begin a new instance? |
| New run / Prestige | Which discovery records and intelligence ranks reset? |
| Hard Reset | Clear all progression-owned discovery and ranks; preserve only the independent settings defined by the reset contract |
| Offline interval | No exploration from merely opening a camera or calculating generic offline income; reveal only if an approved offline exploration simulation actually advances eligible actors |
| Changed map layout | Apply an explicit revision policy; never interpret an old index with a different width/origin silently |

Integrate discovery into the normal save/checkpoint policy. Define the acceptable force-close rollback rather than saving on every revealed pixel or claiming stronger durability than the implementation provides. For layout changes, preserve/migrate known cells only when their meaning is stable; otherwise reset the affected map's discovery intentionally according to section 61, without clearing unrelated progression.

Exploration percentage uses the authored discoverable-area mask as its denominator, not viewport pixels or the entire bounding rectangle. Decide whether water, unreachable decoration or secret regions count. Handle zero-area maps safely and keep progress consistent across world/minimap/expanded map.

### F. Render efficiently without creating another truth

A practical Godot presentation can upload the state masks as a cached low-resolution texture aligned to map bounds and sample them in a fog material, or draw cached cell regions through a dedicated fog layer. This is an implementation option, not a mandated shader or a claim of measured Android performance. Use supplied fog artwork/materials where available and respect the approved asset policy; functional masks do not authorize replacement UI frames or unapproved decorative artwork.

Keep the cover above concealed content and below allowed UI/owned-unit indicators. A world-only dark overlay is insufficient if enemy labels or minimap icons draw above it. Alternatively, filter unknown entity presentation before drawing; in either case the logical disclosure queries remain authoritative.

Update dirty regions/chunks or batch a mask upload when visibility changes; avoid rebuilding every cell node, full UI panel or all map textures every rendered frame. For multiple sources, use a fresh union or correct per-cell source counts so one source leaving does not erase another's sight. Keep discovery and masks bounded to map dimensions. Profile worst-case roster, reveal radius, high game speed, repeated map opening and large maps on a target Android device.

Soft edges are presentation only: blur/fades must not reveal hidden labels or permit picking cells that the state still considers unknown. Full-screen fog should ignore pointer input; interactive map controls follow section 121's input arbitration.

This section is the reusable implementation specification. Keep actual source paths, measured costs, selected algorithm, exact radii and visual acceptance captures in the project's implementation registry and validation report once verified.

---

---

# 118. Resource nodes

## 118.1 Problem

Nodes must make gathering visible and spatial (distance matters, forests thin out), must never let two workers walk to the last load, must regrow on a timer that survives save and offline, and must read at a glance as full, being worked or depleted.

## 118.2 Catalog and placement

Configuration, one entry per node type:

```gdscript
const NODES := {
	"tree":  {"resource": "wood", "stock": 12.0, "respawn": 60.0, "name": "Tree"},
	"gold":  {"resource": "gold", "stock": 12.0, "respawn": 90.0, "name": "Gold Deposit"},
	"sheep": {"resource": "meat", "stock": 4.0,  "respawn": 45.0, "name": "Sheep"},
}
```

Reference choice: stock is a few trips at the base carry capacity (12 = three trips of 4; an animal is one trip and then leaves).

Placement is **authored or generated at edit time, never at runtime.** Each node is an editor-visible scene instance with exported `node_id`, `node_type` (an enum) and `variant` (art variant). Dense forests are generated once by an editor tool, then the scene becomes the authority:

- staggered rows with jitter inside a quarter-ellipse from each map corner, with a ragged edge;
- **draw every random number before any rejection test**, so changing an exclusion rule does not reshuffle the whole forest;
- keep-out rectangles (mountain, shoreline);
- keep every node's tap rectangle (its canopy) off every plot's tap rectangle, and keep a building-sized area around each plot clear (section 115.9);
- one art variety per forest so each area reads as one place;
- stable ids from a sort of the generated positions.

Hand-placed deposits can be mirrored across the map axis for symmetry. Once the scene is hand-tuned, never re-run the generator: it overwrites the scene.

## 118.3 State and rules

Record: `{type, stock, respawn}`; available when `respawn <= 0 and stock > ε`.

```gdscript
func take_from_node(node_id: String, amount: float) -> float:
	if not node_available(node_id):
		return 0.0
	var n: Dictionary = nodes[node_id]
	var taken := minf(amount, float(n["stock"]))
	n["stock"] = float(n["stock"]) - taken
	if float(n["stock"]) <= EPSILON:
		n["stock"] = 0.0
		n["respawn"] = float(Balance.node_def(String(n["type"])).get("respawn", 30.0))
	SaveService.mark_dirty()
	_emit_arg(node_changed, node_id)
	return taken
```

- Depletion starts the respawn countdown in base seconds; `tick_timers()` (shared with offline) counts it down with the regrowth multiplier and refills to the **current** maximum stock (account bonuses to maximum stock apply at refill).
- A partially harvested node stays available.

## 118.4 Reservations (claims)

```gdscript
func node_unreserved_stock(node_id: String) -> float:
	if not node_available(node_id):
		return 0.0
	return float(nodes[node_id]["stock"]) - node_claim_count(node_id) * worker_carry_capacity()
```

- A worker **claims** a node when it picks it, and releases the claim right after taking its load, when it abandons the plan (`decide()` releases everything first), and when its node leaves the tree.
- Claims are runtime-only (`node_claims: {node_id: [worker slots]}`), cleared at every resync.
- Target selection:

```gdscript
func find_resource_target(resource: String, from: Vector2, unreachable: Dictionary) -> ResourceNode:
	var free: Array = []
	var shared: Array = []
	for node in resource_nodes.values():
		if node.resource_type() != resource or unreachable.has(node.node_id):
			continue
		if not RunState.node_available(node.node_id) or RunState.node_unreserved_stock(node.node_id) <= 0.01:
			continue
		if RunState.node_claim_count(node.node_id) == 0:
			free.append(node)
		else:
			shared.append(node)
	var pool := free if not free.is_empty() else shared
	if pool.is_empty():
		return null
	pool.sort_custom(func(a, b): return from.distance_squared_to(a.global_position) < from.distance_squared_to(b.global_position))
	return pool[randi() % mini(3, pool.size())]
```

Unclaimed nodes first; random among the **nearest three** so workers spread without crossing the map; a claimed node is shared only when no unclaimed node exists and its unreserved stock still covers another trip.

## 118.5 Gathering from the node's side

The worker walks to the node's work point, checks the node is still available (another worker may have emptied it), plays the resource's work animation for `gather_time(resource)` (effective), then takes `carry_capacity - already_carried` of that resource, releases its claim, refreshes the node, and heads to the nearest drop-off. The node reacts to every tool strike (section 118.6).

## 118.6 Presentation

- **Origin = ground contact point.** Sprite offsets come from the measured opaque bottom of each art variant, so every node sorts correctly with workers and buildings in the Y-sorted entity layer.
- **Available states** stay alive: trees loop their sway animation from a random start frame (desynchronized), large gold deposits play an always-on shimmer at a larger scale (reference 1.15), animals alternate idle and graze animations and flip direction every 3 to 9 s.
- **Depleted states** are distinct silhouettes, not tints of the full one: a tree becomes its stump, a deposit becomes a dim grey rock (`modulate` about (0.75, 0.72, 0.68, 0.9)), an animal disappears. The idle-life timer stops while depleted.
- **Availability changes play a dust puff** (small when it depletes, large when it returns, large for an animal leaving): `refresh(play_fx)` compares the new availability with the shown one. A resync refreshes without effects.
- **Strike feedback on the tool's contact frame** (section 120.9): a tree sways (rotation 0.06, then -0.04, then 0), a deposit springs up 9 px with a squash (0.92 × 1.10), then settles (1.09 × 0.94) with `TRANS_BACK`, anything else hops 6 px. Each strike kills the previous tween and **restarts from the authored base** position, rotation and scale (section 76).
- **Editor preview:** the node is a `@tool` script whose `node_type` and `variant` setters re-apply the visual, so forests are tuned by eye. Editor paths never touch the autoloads (section 113).

## 118.7 Interaction bounds and contextual information

Pick rectangle per type (world space, from the ground origin): a tree covers its whole canopy (112 × 206), a deposit 104 × 96, an animal 88 × 76. A depleted node stays selectable, so tapping a stump or an empty pasture spot shows its countdown.

Context panel (section 123), refreshed every 0.2 s:

- title: the node type's name;
- `Depleted. Returns in 42s.` using `respawn / regrowth_multiplier`, or `Wood available: 8 / 12` (current stock / current maximum);
- `Workers here: 2`, the number of claims (workers walking to it or working it);
- one line saying which task harvests it and where the resource goes.

## 118.8 Persistence and offline

- Saved: `stock` and `respawn` per node id, clamped on load to `[0, max stock]` and `[0, catalog respawn]`. Unknown node types and ids are dropped; map nodes missing from the save are added full.
- Offline, respawn timers advance through the same `tick_timers()`; gathering is not simulated (section 115.7). The Welcome Back report can count nodes that returned.

## 118.9 Edge cases

- Carry capacity rises mid-trip: the unreserved-stock arithmetic uses the current capacity; the worker simply takes what is there.
- The node is emptied or its timer restarted while a worker walks there: arrival re-checks availability and re-plans.
- A worker already carrying some of the same resource gathers only the remainder of its capacity.

## 118.10 Reuse classification

- **Generic:** the catalog shape, finite stock with timed respawn in state, claims that reserve a trip's worth of stock, nearest-few random selection, ground-contact origins, distinct depleted art, contact-frame strike feedback, edit-time generation with stable random draws and plot clearance.
- **Configure per game:** node types, resources, stock and respawn numbers, the "nearest N", work animations, art variants, strike tween shapes.
- **Mechanic-specific:** animals that vanish while regrowing, regrowth research, maximum-stock bonuses.

## 118.11 Mistakes to avoid

- Keeping stock on the node scene: it cannot be saved, simulated offline or reset without the scene.
- Reserving the node but not the stock, so two workers walk to the last load.
- Always choosing the nearest node (everybody stacks) or any random node (everybody crosses the map).
- A tree canopy drawn over a plot: it wins every tap on that plot.
- Tinting the full sprite for "depleted": at map zoom it reads as the same object.

Reference implementation: `scripts/world/resource_node.gd`, the resource node section of `scripts/autoload/run_state.gd`, `World.find_resource_target()` in `scripts/world/world.gd`, `tools/build_world.gd` (forest generation and plot clearance).

## 118.12 Variant: grouped wandering actors (herds)

Free-roaming animals across the whole map look random and block construction everywhere. Authored herd zones with membership read as intentional and keep the map free:

- Each actor belongs to the herd of its authored home (derived from the authored site on load, so it needs no save field). Grazing picks a point near the herd centre inside the zone, else inside the zone grown by a leash, else stays put.
- Construction displaces actors through a fallback chain: free ground in its own herd area, then a wider ring around the herd centre, then the nearest free ground anywhere. An actor is never trapped and never blocks placement; a visible hop shows the move and the workers using it re-target.
- A loader moves actors from older saves back into their herd.
- Map validation: at least N herds of at least M members, inside the build area, clear of blocking zones.
- **Moving a resource moves the bots.** Growing Kingdom's first herd placement (top edge) dropped the pacing median from 17.8 to 10.4 minutes because the bot's farm and walking distances were built for the old positions; fix the bot's placement heuristic and the positions together, then re-measure.

Reuse (Growing Kingdom): `MapZone` (role "herd"), `SimNode.herd`, `EconomySystem` grazing, `MapRegistry.validate()`; `core_probe` "sheep".

---

# 119. Building plots and buildings

## 119.1 Problem

Buildings are the player's main lever: where they stand sets travel distances, what they are sets capacity, and their construction is a visible project that workers speed up. They must show at a glance whether a plot is free, what is being built, how far along it is, what tier it is, what it accepts, and what it is training, and all of it must survive save, offline and destruction.

## 119.2 Placement: authored plots or free placement

**Authored plots.** Each plot is an editor-visible instance with:

- `slot_id`: a stable save key;
- `allowed_types`: the building types this plot can hold (settlement plots accept a general building or storage; resource plots accept one specialised drop-off);
- `start_house`: the plot that receives the safeguard building on a fresh run.

The node's origin is the **building's ground base**, so the Y-sorted entity layer orders it naturally against workers and nodes. In the editor the plot previews its first allowed building at 45% alpha and draws its id, so the layout is tuned visually (section 63.1).

**Free placement** (Growing Kingdom) lets the player put buildings anywhere valid. The authored-map idea still applies to everything that is not a building: resource zones, reserved zones (defence strip, access lanes), start plots and markers are editor nodes with stable ids. Rules validated there:

- **Placement validity is authoritative and has one function** on the state owner (Growing Kingdom: `RunState.placement_problem()`, returning "" or the reason). Place, the preview, automation and probes all call it.
- **The invalid-area overlay is computed by that same function**, run for every anchor when build mode opens and whenever the world's structure changes, never by a separate approximation, so what is shown red is exactly what Place refuses.
- **Build mode stays open** after each placement until the player taps Done, picks another building or leaves, so a row of Houses is one flow, not one menu trip each. When another copy cannot follow (cost, limit, capacity, no free ground), the mode stays open and says why; after a placement the preview jumps to the nearest spot that is still valid.
- **Direction arrows step to the next valid anchor in that direction: straight line first, then the nearest valid anchor inside that direction's 90° cone**, otherwise a "no space that way" reason. Nearest-in-cone alone jumps sideways and feels random.
- **Roaming entities never block placement.** An animal under the new footprint is displaced to free ground with a small visible hop; the workers using it re-target (section 118.12).
- **Buildings and world entities have stable saved identities** (an id per building record, an id per authored site), so a reload, a world rebuild or a map edit restores the same objects and never re-rolls them.
- **Relocation is its own feature, not part of placement.** Growing Kingdom considered moving finished buildings and intentionally dropped it; its layouts change by Demolish (with its refund rule) and placing again. Do not add relocation as a side effect of a placement pass.

**Random start positions from authored plots.** When a run's first buildings should not always stand in the same place, draw them from authored start plots (editor markers validated by the map validator for clearance against every resource profile and each other), not from any valid tile: every draw then looks deliberate, and bounded distances keep the pacing stable. Draw the order from a generator seeded from the run seed alone, not the run's own random stream, so one seed always gives one arrangement and the rest of the run is not shifted; check each plot with the ordinary placement rule; keep a fallback so the buildings always exist. The choice lives in the saved buildings: loading and world rebuilds never draw again.

Reuse (Growing Kingdom): `RunState.placement_problem()`, `WorldView.begin_placement()` / `step_preview()` / `_BuildOverlay`, `LayoutGenerator.start_plot_order()`, `MapRegistry.start_plots()` and `validate()`; `world_probe` "build mode", `core_probe` "start plots: random, legal, saved".

## 119.3 Building record and lifecycle

```text
no record, a type buildable now  -> "empty" plot
no record, no type buildable yet -> "reserved" plot (a later-phase building)
state constructing               -> construction site
state built                      -> working building at its tier
state built + upgrading          -> working at its current tier while the next tier is built
record removed                   -> destroyed (the run end resolved it)
```

Record: `{type, tier, state, upgrading, work_done, work_total, built_order, queue}` plus type-specific data that shares the building's lifetime (a training queue, research owned by that building; section 109). `built_order` is a counter used to rank instances of one type (first House, second House) for rules that care.

## 119.4 Construction and upgrades in state

```text
start_construction(slot, type)
  construction_block_reason(): run active, known plot, plot empty, type allowed
    here, type buildable in this build, blueprint owned (say how to get it),
    affordable (say the price)
  spend, create the record (state constructing, work_total = build time),
  append to construction_order, emit construction_started + building_changed

tick_timers(dt): every project in construction_order gets passive_rate × dt
worker in BUILD phase: adds builder_rate × dt to the TOP project each tick
add_construction_work() completes at work_total:
  new building -> state built, built_order = ++counter, leave the order,
                  emit construction_completed + building_changed
  upgrade      -> tier + 1, upgrading false, leave the order,
                  emit building_upgraded + building_changed

upgrade_building(slot)
  upgrade_block_reason(): built, not already upgrading, below max tier, affordable
  pay up front, upgrading = true, work_done = 0, work_total = next tier's time,
  append to construction_order, emit construction_started + building_changed

move_construction_priority(slot, ±1): reorder, emit building_changed for every project
```

Everything that uses a building's capacity asks for `state == built` and reads `tier`, so an upgrading building keeps its storage, population, drop-off role and training at the current tier (section 115.5).

## 119.5 Building usage by workers

- `dropoff_types(slot)` returns the catalog's accepted resources for a **built** building (upgrading included), else nothing. The general building accepts every resource; specialised buildings accept one.
- Workers look for the **nearest** valid drop-off point (straight-line distance from where they stand) when they finish gathering. The result carries the delivery bonus of that instance (its tier bonus plus global bonuses) so the deposit and the floating number agree.
- A drop-off does not have to be a building. A depot that visualizes a stored survival resource (section 125.3) is also an always-available drop-off for that resource, placed near its sources, and the pickup point for workers who carry it onward. It earns every global delivery bonus but has no tier of its own.
- Training buildings own a queue of `{remaining}` base work; queued units reserve population (section 115.6). A finished worker walks out of the building that trained it: the world spawns it at that building's drop-off point with a dust puff (the run state remembers the last training plot as a runtime hint).

## 119.6 Presentation of a plot

| State | Visual |
|---|---|
| empty | Dashed outline (12 px dashes, 3 px lines), a faint warm fill and a centred plus sign, drawn in `_draw()` at the plot's footprint width |
| reserved | The same dashed outline, faint and without fill or plus |
| constructing | The finished building's art, modulated to a dark blue-grey **silhouette** (reference `Color(0.13, 0.13, 0.2, 0.82)`), plus a progress bar |
| upgrading | The **next tier's** art as a silhouette, plus a progress bar, plus the building's props (it still works) |
| built | The tier's art in full colour, plus resource props for specialised drop-offs |

- **Tier art** comes from authored palette variants (one colour folder per tier, reference Blue, Yellow, Purple, with Black kept in reserve and Red kept for the enemy), resolved by one path function `building_sprite_path(type, tier)` (section 73).
- **Sprite anchoring:** each building sprite family has a measured bottom row of opaque pixels; `offset.y = texture_height / 2 - opaque_bottom + 4` puts the drawn base exactly on the node's origin.
- **Resource props** tell apart buildings that share a generic silhouette: a log pile beside the wood drop-off, a gold stone beside the gold drop-off, meat and wood beside the storage building. This is how a gathering building says which resource it belongs to without text. The props are small sprites at authored offsets, shown when built or upgrading.
- **Progress overlay:** a child `Node2D` with `z_index` 20 draws the bars with `_draw()` above the sprite (top = `-sprite_height - 26`): a 120 px amber construction bar; above it, while training, a 96 px blue bar with an outlined `x3` queue count. The plot turns `_process` on only while constructing, upgrading or built (to watch its queue), reads the progress from state and redraws only when it moved.

## 119.7 Geometry contract

Every plot answers four questions from one place, by sprite family:

| Function | Reference values |
|---|---|
| `footprint_width()` | 116 px small house, 176 px large building, 300 px castle |
| `sprite_height()` | 150 px house, 184 to 262 px for taller families |
| `get_pick_rect()` | the whole building (width × height, plus 24 px of ground below); an empty plot uses a 90 px tall rect |
| `get_dropoff_point()`, `get_work_point(i)` | section 117.4 |

The same rectangle is used by the tap test, the selection marker, the tutorial pointer and the world generator's clearance check (section 122).

## 119.8 Feedback

| Event | Feedback |
|---|---|
| construction started | one large dust burst at the base |
| construction completed | three dust bursts across the base, a scale **punch** (1.08 back to 1 in 0.25 s, `TRANS_BACK`, ease out), a floating "House complete!" above the roof |
| upgrade completed | a dust burst, the punch, "Lumberjack Tier II!" |
| training finished | the unit appears at the door with a dust puff |
| destruction | per building, staggered: an explosion, two looping fires with a lifetime, the sprite darkens, then fades; defensive buildings shoot presentation-only arrows until they burn; the camera shakes; the phone vibrates |

The punch always kills the previous punch tween and restarts from scale 1 (section 76). The destruction tween is owned by the plot and killed by `refresh()` (section 116.8, rule 5).

## 119.9 Editor safety

The plot is a `@tool` script so the editor can preview it. Its `_ready()` calls `set_process(false)`, every runtime path starts with `if Engine.is_editor_hint(): return`, and the probe runner opens the world scene in a headless editor and fails on any error line (section 113).

## 119.10 Persistence and destruction

- Saved: the building records and the construction order. On load each record is sanitized (known type, tier within range, `upgrading` only if built and below the maximum tier, `work_done` clamped to `work_total`, queue items clamped to the unit's training time), and the construction order is rebuilt to contain exactly the records under construction.
- Offline: passive construction and abstract builders advance projects (section 115.7).
- Destruction (mechanic-specific): the run end decides survivors and saves them before any presentation; unfinished construction and upgrades never survive; a survivor keeps the tier it had. A safeguard rule places a fresh basic building if none survives.

## 119.11 Reuse classification

- **Generic:** authored plots with stable ids and allowed types, the record and lifecycle, construction as an ordered project list with passive progress, upgrades as projects that keep the building working, silhouette plus bar for projects, next-tier silhouette for upgrades, ground-base origins and measured sprite offsets, one geometry contract per plot, owned and restartable tweens, `@tool` preview with editor guards.
- **Configure per game:** the building catalog (costs, times, tiers and their effects, drop-off types), footprint and height tables, prop art and offsets, palettes, bar sizes and colours.
- **Mechanic-specific:** training queues, research owned by a building, survival rolls, defensive fire during destruction, a command building that launches a battle.

## 119.12 Mistakes to avoid

- Showing an upgrade as "the old building, now disabled": the player loses capacity to press a button meant to add it.
- Drawing progress with a Control in a CanvasLayer that has to follow the camera; a world-space overlay node is simpler and sorts with its building.
- Plot tap rectangles that only cover the ground: players tap the roof.
- Letting a generator or an artist put tall decoration in front of a plot without re-running the tap-every-plot probe.

Reference implementation: `scripts/world/building_slot.gd`, the construction, tier and drop-off sections of `scripts/autoload/run_state.gd`, the building event handlers in `scripts/world/world.gd`.

---

# 120. Worker lifecycle

## 120.1 Problem

Section 115.1 says what workers decide: the first task they can really do. This section is how a worker entity carries that out frame by frame, what it saves, what it rebuilds, how it animates, and where it re-plans, so that dozens of workers stay stable, readable and exploit-free at any game speed and across force-closes.

## 120.2 What is saved and what is not

| Data | Where | Saved |
|---|---|---|
| Existence and slot index | run state `workers[] = {slot, carry_type, carry_amount}` | yes |
| What it carries | same record | yes |
| Task priorities | account state, per worker **slot** (`task_configs[slot] = [task, task, ...]`) | yes, and they outlive the worker (a new worker in slot 3 inherits slot 3's priorities) |
| Current task, phase, purpose, path, target node, target plot, chosen drop-off, timers, unreachable cooldowns, status text | the entity | no |
| Node claims, delivery reservations | run state runtime fields | no |
| Position | the entity | no: after a load every worker appears at the default spawn point (the first built house's door) and re-plans; a worker holding cargo delivers it first |

A new worker takes the **lowest free slot index**, so priorities stay attached to "worker 1, worker 2..." across runs.

**A direct world order is saved as intent only** (section 120.11): its kind, the stable id of its target (a node by its authored site, a building by its id) and the ground of a Move. Its path, claim and animation are derived again after a load; an order whose target is gone is dropped on load and the worker re-plans from its own behaviour on its next tick.

## 120.3 Phases and purposes

```text
Phase: IDLE | MOVE | GATHER | BUILD | DELIVER(TOSS)
MOVE carries a purpose that says what arrival means:
  "node"    -> begin gathering
  "dropoff" -> deposit
  "site"    -> begin building
  "pickup"  -> take goods from a depot (delivery task)
  "deliver" -> begin handing goods to the consumer
```

```text
            decide()
               |
     first executable task in priorities
   +-----------+-----------+------------+-----------------+
   | gather    | build     | deliver    | none            |
   v           v           v            v
 claim node  top project  go to depot   IDLE (re-check 0.5 s;
 MOVE node   MOVE site    MOVE pickup    unload if carrying
   |           |           |             and storage has room)
 GATHER      BUILD        take goods
 (timer)     (every tick   MOVE deliver
   |          adds work)   |
 take load,    |          DELIVER: one unit per timer,
 release claim re-plan     credit at hand-off
 MOVE dropoff  every 2.5 s, |
   |           on done or  re-plan when done
 deposit       new top
 re-plan
```

## 120.4 `decide()` and executability

```gdscript
func decide() -> void:
	_release_all()                     # claims, delivery reservation, site
	_path = PackedVector2Array()
	var chosen := ""
	for candidate in ProfileState.get_priorities(worker_slot):
		if candidate != "" and _can_do(candidate):
			chosen = candidate
			break
	task = chosen
	_start(chosen)
```

`_can_do(task)`, the real check (section 115.1):

| Task | Executable when |
|---|---|
| gather X | the run is active; storage is not full; a drop-off for X exists; a reachable node of X with unreserved stock exists (hands holding another resource deposit it first, or put it down when its storage is full, below) |
| build | at least one construction project exists |
| deliver to consumer | delivery is open; the consumer can take at least one more unit counting what is already in flight; either the worker already carries that good, or storage holds at least one unit (and the worker's hands are not full of something storage cannot take) |

`_start(task)`, the hands-full rules (section 115.4):

- carrying the consumer's good and the task is delivery: go straight to the delivery point;
- carrying anything else and the task is not build: deposit first, if storage has room and a drop-off exists;
- carrying a load storage cannot take: the first executable task in the list (the blocked resource is not one) runs, after the load is put down as a pickup (section 115.4), whatever the task;
- build is allowed with full hands;
- no executable task: idle with the status "Idle", or "Storage full: holding Wood" when it carries something it cannot unload. An idle worker re-runs `decide()` every 0.5 s, which is also how it unloads by itself once there is room.

## 120.5 Re-evaluation points and target stability

| Moment | Why here |
|---|---|
| after every deposit | a natural cycle boundary; nothing is lost by re-planning |
| arrival at a node that is no longer available | the target changed under it |
| after a gather that yielded nothing | same |
| while building: every 2.5 s, when the project completes, and when the top project changes | builders follow the player's order without walking away mid-swing every frame |
| after a delivery trip | the consumer may be full |
| every 0.5 s while idle | cheap polling for "something became possible" |
| immediately when this worker's priorities change (direct command or edit) | the player expects an order to take effect now |
| on spawn and at resync | a fresh entity has no plan |

Between these points the worker keeps its node (and claim), its drop-off and its path. It does **not** re-plan every frame, so it never oscillates between two equally good targets, and it drops what it carries only by the blocked-load rule (section 115.4). A storage that fills while the worker walks to a drop-off invalidates that trip: re-plan then, as for a node emptied on the way.

## 120.6 Gathering, carrying and depositing

```gdscript
func _tick_gather(dt: float) -> void:
	if _target_node == null or not RunState.node_available(_target_node.node_id):
		decide(); return
	_timer -= dt
	if _timer > 0.0:
		return
	var resource := _target_node.resource_type()
	var already := carry_amount() if carry_type() == resource else 0.0
	var taken := RunState.take_from_node(_target_node.node_id, maxf(0.0, RunState.worker_carry_capacity() - already))
	RunState.release_node(_target_node.node_id, worker_slot)
	_target_node.refresh(true)
	_target_node = null
	if taken <= 0.0:
		decide(); return
	RunState.set_carry(worker_slot, resource, already + taken)
	if not _go_deposit():
		_set_idle("No drop-off for %s" % resource_name(resource))

func _deposit() -> void:
	var ctype := carry_type()
	var amount := carry_amount()
	var bonus := float(_dropoff.get("bonus", 0.0))
	var consumed := RunState.deposit(ctype, amount, bonus)
	if consumed > 0.0:
		RunState.set_carry(worker_slot, ctype, amount - consumed)
		world.show_delivery(_dropoff["pos"], ctype, consumed * (1.0 + bonus))
	_dropoff = {}
	decide()
```

`RunState.deposit(type, carried, bonus)` credits `min(carried × (1 + bonus), free storage)`, counts it for statistics, and returns how much of the **carried** amount it consumed; the rest stays in hand and is saved.

## 120.7 Construction work

The builder walks to its spread work point at the top project (skipping the walk when already within 6 px), faces the building, plays the build animation, and every tick calls `add_construction_work(top, builder_rate × dt)`. There is no reservation: every builder works the top project (section 115.5). The context panel counts builders **on site** (phase BUILD at that plot) for its ETA.

## 120.8 Delivery to a consumer (mechanic-specific)

For a design where workers carry a stored good to a fixed consumer (a creature to feed, a furnace, a market):

1. Walk to the depot, take `min(floor(carry capacity), units the consumer still wants)` from storage.
2. Walk to the delivery point.
3. At arrival, reserve what will be handed over (`pending += units × value`), so other workers' executability checks see it.
4. Hand over one unit per timer (reference 0.7 s, shortened by research): release one unit of reservation, remove it from the carry, **credit the consumer immediately**, then launch a purely visual projectile.
5. Re-plan when the reservation or the carry runs out. If delivery closes mid-trip (a battle started), the goods stay in hand and are deposited later.

## 120.9 Animation

- One `AnimatedSprite2D` with a `SpriteFrames` resource baked by a tool from the pack's strips (never a whole sheet; section 23). Animations: `idle`, `run`, a carry variant of each for every resource (`idle_wood`, `run_gold`...), one work animation per resource (`chop`, `mine`, `harvest`) and `build`. Reference rates: idle 6 fps, run 8, work 8.
- `_carry_anim(base)` returns `base + "_" + carry_type` while carrying, so a loaded worker always looks loaded, walking or waiting.
- `_play(anim)` only calls `play()` when the animation changed or stopped, so re-plans never restart a cycle visibly.
- Each worker starts its idle animation at a random frame, so a crowd does not breathe in sync.
- Facing: `flip_h` from the movement direction, and toward the node, site or consumer when work starts.
- **Contact frames:** a table maps each work animation to the frame where the tool connects (reference axe 3, pickaxe 3, knife 2, hammer 1). On `frame_changed` at that frame: a gathering worker calls `node.hit()`; a builder spawns a small dust puff on its tool side. Feedback lands on the impact, not on a timer, so every strike reads as physical.

## 120.10 Status and the idle indicator

- The worker sets a status string at each transition, for example "Going to Tree", "Gathering Wood", "Delivering Wood", "Walking to construction", "Building House", "Upgrading House to Tier II", "Fetching food for the consumer", "Carrying food to the consumer", "Feeding", "Idle", "Storage full: holding Wood", "Can't reach target", "No drop-off for Gold". UI polls it (section 123); nothing needs a push signal.
- A worker with **no executable task** (phase IDLE and task empty) draws a floating "?" in a yellow disc above its head (in `_draw()`, redrawn only when the flag flips). The same condition drives the red "!" badge on the workers button in the dock (section 124). A worker idling after "Can't reach target" still has a task, so it shows no "?".

## 120.11 Direct commands and priority edits

- A state owner owns priorities (Feed the Dragon: the account, per worker slot; Growing Kingdom: the run, per Villager, with a saved default for new ones). **Every edit goes through one rule** (section 129.5): the chosen task lands in the place the player edited and, if it sat elsewhere, the two swap; a direct command ("send to work") is that rule applied to place 1. Feed the Dragon first had two rules (a direct command shifted the list down, a dropdown swapped), which gave two different lists for the same intent. The owner emits a change signal for that worker.
- **One rule per intent, never two rules for one intent.** Two different intents may deserve two rules, each named and owned once. Growing Kingdom keeps the swap rule for every surface that *edits a place* (dropdowns, the one-tap task grid, group task commands, the default editor) and adds a **move-to-front** rule only for a *world work order on a specific target* ("work this tree"): the task leaves its place, goes first, the rest keep their order one place back, the list is cut to the unlocked places (Food, Gold, Build + Wood gives Wood, Food, Gold; the swap rule would give Wood, Gold, Build). Two named functions on the state owner (`priorities_after()`, `priorities_after_direct_command()`), each called from exactly one kind of action, documented side by side in the design so nobody later "fixes" one into the other, and a probe asserting both on the same input.
- The worker with that slot listens and calls `decide()` at once. There is no "manual mode" to save or clear (section 115.1).
- Direct command buttons are always enabled: a command to a task that cannot run now is still a valid preference, and the worker's status shows what it does instead.
- A player's command takes effect at once: a carried load the new task does not deliver is dropped as a world pickup and the new task starts immediately (section 115.4). Waiting for the delivery to finish was Feed the Dragon's first choice and felt unresponsive in Growing Kingdom's playtest.
- There are no per-task worker caps. Distribution comes from node claims (section 118.4), builder spread points and the player's priorities. If a design needs "at most N workers here", model it as a reservation like claims, never as a counter on the entity.
- **A world order is an override layer first.** RTS-style control (select a worker, tap ground, a node or a construction) sits above the autonomous behaviour: `decide()` serves an active order first (Move and Hold, one exact node, one construction, one delivery), else the Smart allocation, else the Manual list. Whether an order also changes the standing list is a design decision to state explicitly: Growing Kingdom's v0.12 orders touched nothing (a Move should not cost the player's doctrine), and v0.13 made a **work** order on a specific target also put its task first (move to front, above), because a player who sends a worker to a tree means "keep doing Wood"; Moves and deliveries still touch nothing, and an automatic (Smart) worker's hidden list is never edited. Either way the exact target stays the immediate target: the list only says what comes after it. A repeated identical order must be a no-op (no re-plan, no second drop). The order ends when it completes or its target is gone for good (an emptied node ends it: never retarget silently to another node), on Resume Work, or on any task command or mode switch, and the worker returns at once to its own behaviour.
- **An order reuses every rule of the normal loop.** It only chooses the target: gathering, carrying, delivery, claims, depletion, pickups and the blocked-load rule are the ones every worker uses, so resource conservation needs no new proof. Loads follow the reassignment rule (a gather order of the carried resource delivers first; any other carried load becomes a pickup); a Move keeps what is carried and never delivers it.
- **An ordered worker counts as what it works.** Workforce numbers (HUD chips) and an automatic allocator's coverage read the order's task, not the hidden Smart commitment or Manual first priority; the allocator never reassigns an ordered worker until the order ends.

## 120.12 Spawn, removal and resync

- Spawn: the world instantiates the entity, sets its slot and a position (the training building's door, or the default spawn point), and calls `decide()`.
- Removal: `villagers_changed` reconciles entities with records; freed entities release their claims in `_exit_tree()`.
- Resync: every worker entity is freed and rebuilt (section 116.4); claims and delivery reservations are cleared first.

## 120.13 Edge cases

- Hands hold a resource with no drop-off anywhere: gathering another resource is not executable until it is deposited; the worker idles with a status that says why.
- Storage full: gathering that resource is not executable (the HUD warns, section 124); build and other resources still are, and a worker holding the blocked resource puts it down for them (section 115.4) or keeps it when nothing else can run.
- The top project changes while building: the builder re-plans within one tick.
- The node empties while walking: arrival re-plans.
- Unreachable node: 10 s per-worker cooldown for that node, 1 s retry (section 117.6).
- Game speed 3x: everything is driven by the simulation step, so a soak at 3x produces the same outcome as 1x for the same simulated time.

## 120.14 Reuse classification

- **Generic:** saved carry plus runtime everything else, priorities owned by a state owner, phase plus purpose state machine, `decide()` releasing before re-planning, the re-evaluation table, deposit that returns the consumed amount, carry-variant animations, contact frames, polled status text, the "?" condition shared with the dock badge, one edit rule for every priority surface, immediate reassignment with the load put down.
- **Configure per game:** task catalog and names, executability rules per task, carry capacity, gather times, speeds, re-evaluation intervals, spawn point, animation names and contact frames.
- **Mechanic-specific:** delivery to a consumer with in-flight reservations, task slot unlocks, the hands-full exceptions tied to one good.

## 120.15 Mistakes to avoid

- Storing the current task as the saved state: after a load the world differs (storage, nodes) and the saved task may be impossible.
- Re-running priorities every frame: workers jitter between targets and abandon work.
- Clearing carry when a plan changes: section 115.4.
- A HUD workforce number that answers a different question than the player asks (section 124.2).
- Letting the projectile credit the consumer on landing.

Reference implementation (Feed the Dragon): `scripts/world/villager.gd`, `ProfileState.direct_command()` and `set_priority()` in `scripts/autoload/profile_state.gd`, `RunState.deposit()`, `set_carry()` and the delivery reservation functions in `scripts/autoload/run_state.gd`.

---

# 121. Touch input arbitration and the map camera

## 121.1 Problem

On a phone one finger does three things: tap to select, drag to pan, and (with a second finger) pinch to zoom. The same screen is covered in HUD buttons, panels and scroll lists. A tap meant for a button must never select the tree behind it, a pan must never end as a selection, a pinch must never end as a tap, and a scroll list must scroll even when the drag starts on one of its buttons.

## 121.2 Layers and who sees input first

```text
CanvasLayer 20  modals: full-screen dim (MOUSE_FILTER_STOP) + centred panel
CanvasLayer 15  tutorial pointer: everything MOUSE_FILTER_IGNORE (never blocks)
CanvasLayer 10  HUD: root and safe-area margin IGNORE;
                interactive groups (panels, dock, buttons, tappable meter,
                mission tracker, context panel, tutorial card) STOP or PASS;
                read-only chips and labels IGNORE (taps fall through to the world)
World           the camera receives what the GUI did not consume (_unhandled_input)
```

Godot delivers input to the GUI before `_unhandled_input`, so controls that stop input already shield the world. The camera adds a **second, explicit gate**: at touch-down it asks a HUD callback whether the point is on interactive UI.

```gdscript
# main, after both exist:
world.camera.input_blocker = hud.blocks_point

# hud:
func blocks_point(screen_pos: Vector2) -> bool:
	for control in [_context, _dock, _top_right, _meter, _tracker]:
		if control.is_visible_in_tree() and control.get_global_rect().has_point(screen_pos):
			return true
	if _open_panel_id != "" and _panels[_open_panel_id].get_global_rect().has_point(screen_pos):
		return true
	return onboarding != null and onboarding.card_rect().has_point(screen_pos)
```

The gate makes shielding independent of engine details (emulated touch, containers left at `PASS`, a control that forgets to stop input). Keep the list next to the HUD's layout list and extend both when a HUD group is added. Read-only chips are deliberately **not** in it: tapping through the resource readout to the map is expected.

Tappable HUD pieces that are not buttons (the survival meter, the mission tracker) handle the left mouse button in `_gui_input` and call `accept_event()`. On a phone this works because Godot emulates mouse events from touch by default; keep that setting on.

## 121.3 The gesture state machine

```gdscript
const TAP_MAX_MOVE := 14.0   # px on screen
const TAP_MAX_TIME := 0.45   # s

func _on_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		# A gesture that starts on UI is never registered: it can neither pan nor tap.
		if _touches.is_empty() and input_blocker.is_valid() and input_blocker.call(event.position):
			return
		_touches[event.index] = event.position
		if _touches.size() == 1:
			_press_pos = event.position
			_press_time = Time.get_ticks_msec() / 1000.0
			_dragging = false
		elif _touches.size() == 2:
			_dragging = true                       # a pinch can never end as a tap
			var p: Array = _touches.values()
			_pinch_start_distance = (p[0] as Vector2).distance_to(p[1])
			_pinch_start_zoom = zoom.x
	else:
		if not _touches.has(event.index):
			return                                 # released a touch we ignored
		var was_single := _touches.size() == 1
		_touches.erase(event.index)
		if was_single and not _dragging:
			var held := Time.get_ticks_msec() / 1000.0 - _press_time
			if held <= TAP_MAX_TIME and event.position.distance_to(_press_pos) <= TAP_MAX_MOVE:
				tapped.emit(_screen_to_world(event.position), event.position)
		if _touches.is_empty():
			_dragging = false
	get_viewport().set_input_as_handled()

func _on_drag(event: InputEventScreenDrag) -> void:
	if not _touches.has(event.index):
		return
	_touches[event.index] = event.position
	if _touches.size() >= 2:
		var p: Array = _touches.values()
		var distance := (p[0] as Vector2).distance_to(p[1])
		if _pinch_start_distance > 1.0:
			var center := ((p[0] as Vector2) + (p[1] as Vector2)) * 0.5
			set_zoom_level(_pinch_start_zoom * distance / _pinch_start_distance, center)
		return
	if not _dragging and event.position.distance_to(_press_pos) > TAP_MAX_MOVE:
		_dragging = true
	if _dragging:
		position -= event.relative / zoom
		clamp_to_bounds()
	get_viewport().set_input_as_handled()
```

What this guarantees:

| Situation | Result |
|---|---|
| press, release within 14 px and 0.45 s | tap, emitted in world and screen coordinates |
| press, move past 14 px | pan for the rest of the gesture; no tap on release |
| press, hold longer than 0.45 s, release in place | nothing |
| press, hold longer than 0.45 s, then drag (a game with spatial selection) | a selection box, never a pan (below) |
| second finger lands | pinch; the gesture can no longer become a tap; lifting one finger continues as a one-finger pan |
| pinch | zoom proportional to finger distance, anchored at the midpoint; the midpoint moving does not pan |
| touch starts on UI and slides onto the map | ignored entirely |
| touch starts on the map and slides under UI | still the camera's gesture |

The first 14 px of a drag are absorbed by the dead zone (not applied as pan); at map zoom this is invisible and it is what makes taps reliable.

**Adding a selection box without breaking the pan (Growing Kingdom v0.14).** An RTS needs a drag that selects; a touch map needs a drag that pans. Give the box the one gesture that had no meaning, a long press, and make the arbitration an explicit state machine instead of booleans:

```text
PRESS ── released within 14 px and 0.45 s ───────────────────────► tap
  │  ── leaves the 14 px dead zone ── on the placement preview ──► OBJECT (moves it)
  │                                 ── held ≥ 0.45 s, or mouse ──► BOX (selection rectangle)
  │                                 ── otherwise ────────────────► PAN (for the whole gesture)
  └─ second finger ──────────────────────────────────────────────► PINCH (a BOX is cancelled)
PINCH, one finger lifted ─► PAN        a modal opens during BOX ─► DEAD (rest of gesture ignored)
```

- **Decide once,** when the press leaves the dead zone: a finger that moved before the long press is a pan for good, so a slow pan that pauses can never turn into a box. A long press released in place still does nothing.
- **Show the hold.** Once a still press reaches the long-press time, draw a ring under the finger and say what the next drag does ("Drag to select multiple units") beside the finger, clear of it (above it on the map, else below or beside, inside the safe area, never over the top band or the dock): a finger hides the ring and the box's corner. It is gesture feedback, not a lesson, so every tutorial mode shows it. Drive both from the camera's own hold state (a signal), never a second timer in the HUD, and re-evaluate that state at the end of every touch and drag event, not only per frame, so the hint goes in the same event a box begins, a second finger lands or the finger lifts (Growing Kingdom v0.15).
- **The box never commands.** Releasing it only selects (and an empty box clears); it never places, orders or taps.
- **Same threshold as the tap.** Using the tap's own time limit (0.45 s) as the long-press time means every press is exactly one of the two.
- **Gate it per mode.** Build mode keeps every drag for its preview and the pan; the camera asks a callable (`box_allower`) instead of knowing the modes.

## 121.4 Zoom

```gdscript
func min_zoom() -> float:
	var view := get_viewport_rect().size
	return maxf(view.x / bounds.size.x, view.y / bounds.size.y)   # never show outside the bounds

func set_zoom_level(value: float, anchor_screen := Vector2(-1, -1)) -> void:
	var z := clampf(value, min_zoom(), MAX_ZOOM)
	if anchor_screen.x < 0.0:
		zoom = Vector2(z, z)
	else:
		var before := _screen_to_world(anchor_screen)
		zoom = Vector2(z, z)
		position += before - _screen_to_world(anchor_screen)   # keep the anchored world point fixed
	clamp_to_bounds()
```

- Minimum zoom is computed from the viewport and the bounds (a "cover" fit), so it adapts to every aspect ratio; maximum is a constant (reference 1.6).
- Anchored zoom (pinch midpoint, mouse cursor) keeps the world point under the fingers still.

## 121.5 Bounds and clamping

- Bounds = the playable map rectangle grown by a margin (reference 96 px of shoreline), plus **headroom** where the HUD covers the map: the reference adds 420 px above the map, because the most important landmark sits at the top centre, exactly under the top HUD band, and must be scrollable clear of it.
- `clamp_to_bounds()` keeps the visible rectangle inside the bounds on each axis, and centres the camera on an axis where the view is larger than the bounds. It runs after every pan and zoom and on every viewport size change (rotation, window resize, a new safe area).

```gdscript
func clamp_to_bounds() -> void:
	var half := get_viewport_rect().size / zoom * 0.5
	var lo := bounds.position + half
	var hi := bounds.end - half
	position.x = bounds.get_center().x if lo.x > hi.x else clampf(position.x, lo.x, hi.x)
	position.y = bounds.get_center().y if lo.y > hi.y else clampf(position.y, lo.y, hi.y)
```

## 121.6 Coordinates, focus and shake

- Screen to world: `get_canvas_transform().affine_inverse() * screen`. World to screen (for UI that points at world objects): `get_viewport().get_canvas_transform() * world_point`, applied to both corners of the object's pick rectangle.
- `focus(world_pos, zoom)` sets the position, optionally the zoom, then clamps. Uses:
  - at run start, on the first home building, offset upward (reference 300 px) at zoom 0.75;
  - "look at the landmark" frames it at 58% of the screen height so it clears the top HUD band (the survival meter itself is tappable for this);
  - a "Show" button in a list focuses a plot and selects it;
  - the tutorial pointer focuses a world target **once per target**, and only if the target is not already comfortably on screen (screen shrunk by 120 px), so it never fights the player's own panning.
- Shake tweens the camera's `offset` (not its position) with decaying random steps every 0.05 s, ignoring time scale, so clamping and picking are unaffected.
- The camera is `PROCESS_MODE_ALWAYS`: the player can look around while the game is paused. The modal dim stops input while a modal is open.

## 121.7 Desktop and development input

`input_devices/pointing/emulate_touch_from_mouse=true` routes a left-button drag through the same touch path, so desktop play exercises the phone logic. Extra desktop conveniences: mouse wheel zoom anchored at the cursor (factor 1.12 per notch), middle or right drag to pan, trackpad magnify and pan gestures.

**When the left drag must select (an RTS on desktop):** tell the mouse from a finger inside the same touch path, not with a second handler: Godot marks emulated touch and drag events with `device == InputEvent.DEVICE_ID_EMULATION`. A mouse press then becomes a box as soon as it leaves the dead zone (no long press), a click counts however long it is held, and panning stays on the right and middle buttons and the wheel. Do not also handle the left `InputEventMouseButton`: the emulated touch already carries it, and handling both draws two gestures. Read modifiers (Shift to add) from `Input.is_key_pressed`, since touch events carry none.

## 121.8 Scroll lists inside panels

A `ScrollContainer` whose buttons stop input cannot be scrolled by a drag that starts on a button, which on a phone is almost every drag. The reusable fix is a `TouchScroll` subclass that sets `MOUSE_FILTER_PASS` on every `BaseButton` inside it, including buttons added later (it listens to `node_added`, because panels rebuild their contents). A tap still presses the button; a drag past the container's dead zone scrolls and cancels the press.

Buttons are not the only blockers: a `PanelContainer` card stops input by default, so a drag that starts on a card's paper (not its button) still does not scroll. Set `MOUSE_FILTER_PASS` on every control that stops input inside the list, except the ones that need their own drags (sliders, scroll bars, spin boxes, text fields, nested scroll containers), and let a probe assert that nothing inside each list still stops. To keep the scroll position when an action changes a row (buying an upgrade), update that row in place; rebuild the list only when its structure changes, and then restore the offset after layout has settled (over a couple of frames, since wrapped text changes heights on the first pass).

**A tray whose items can also be dragged out into the world (Growing Kingdom v0.15, the Build Shelf).** A horizontal strip of building cards must scroll sideways, choose on a tap and lift a building into the world on an upward drag. Make the strip the only control that takes input (its scroll container, row and cards ignore the mouse) and run one state machine there, decided once when the press leaves its dead zone: steeper than 45° upward from a card is a lift, anything else scrolls; released inside the dead zone it is a tap. A scroll never becomes a lift, nor a lift a scroll; a second finger, a modal or closing the tray makes it dead until the finger lifts. A lift enters the game's existing placement mode (without moving the camera); the preview follows the pointer wherever no UI is under it; the release over the map runs the same authoritative action as the Place button (so an invalid spot refuses with its reason and spends nothing, and placement mode stays), over UI it places nothing. While a lift is in progress the camera's blocker answers true everywhere, so a second finger cannot start a camera gesture. Let the drag only ever lift a new item: nothing already placed is draggable. Start the angle at 45°: a 40° limit took a natural diagonal drag from a card at the strip's left end to the middle of the map for a scroll.

## 121.9 Safe areas

The world may draw under a notch or gesture bar; controls may not. The HUD applies the safe-area insets as margins on a full-rect `MarginContainer` (with extra padding, more at the bottom for the gesture bar). Because the camera's blocker reads the controls' real rectangles, shielding follows the safe area automatically. Modals are centred inside the safe area while their dim covers the full screen (section 68).

## 121.10 Reuse classification

- **Generic:** everything in this section: the layer order, the explicit blocker gate registered at touch-down, the gesture state machine, cover-fit minimum zoom, anchored zoom, clamp with centring, HUD headroom in the bounds, focus rules, offset shake, `TouchScroll`, emulated touch on desktop.
- **Configure per game:** tap thresholds (14 px, 0.45 s were comfortable on a 20:9 phone at a 1080 px canvas), maximum zoom, wheel step, bounds margins and headroom, start focus.
- **Mechanic-specific:** long-press actions (Growing Kingdom: long press then drag draws a selection box, section 121.3), two-finger pan, edge scrolling, rotation.

## 121.11 Mistakes to avoid

- Deciding "tap or drag" on press. Decide on release (tap) or on crossing the threshold (drag).
- Clearing the dragging flag when one of two fingers lifts: the remaining finger's release becomes a tap.
- Relying only on `mouse_filter` to protect the world from UI taps.
- A second implementation of placement for a drag-to-place shortcut: converge on the existing placement mode and its confirm action.
- Layering booleans (`_dragging`, `_boxing`, `_object_drag`) for gesture kinds that must be exclusive: a pan that later becomes a box, or a pinch that ends as a selection, comes from two flags both true. One state, decided once.
- Leaving a world bar's height out of the camera's headroom: a selection bar along the bottom then hides the far end of the map, which can no longer be pulled out from under it to be tapped.
- Clamping before applying the new zoom, or forgetting to clamp on viewport size changes.
- Zooming about the screen centre when the player pinched elsewhere.

Reference implementation: `scripts/world/map_camera.gd`, `Hud.blocks_point()` in `scripts/ui/hud.gd`, `scripts/ui/touch_scroll.gd`, `scripts/autoload/layout_service.gd`.

---

# 122. World picking, selection and the selection marker

## 122.1 One geometry contract

Every selectable entity implements `get_pick_rect() -> Rect2` in world space. The rectangle is **generous**: it covers the whole drawn object (a canopy, a roof) plus some ground below the base, not the opaque pixels (section 14.3). The same rectangle is used by:

- the tap hit test;
- the selection marker's frame;
- the tutorial pointer's target frame (converted to screen space);
- the world generator's clearance check (no decoration's rectangle may cover a plot's), for decorations and authored plots;
- the probe that taps the centre of every plot.

Reference sizes: worker 68 × 100 around a roughly 40 px wide figure; tree 112 × 206; deposit 104 × 96; animal 88 × 76; building = footprint × sprite height + 24; empty plot = footprint × 90 + 24; depot 120 × 130; the large landmark 330 × 190.

**Player placement clearance is a separate, functional footprint.** Where the player places buildings freely, do not reuse the generous pick rectangle as the clearance between a building and a resource: a tree's canopy rectangle reaches far beyond its trunk, so buildings are refused along tree lines with nothing visible in the way (Growing Kingdom's players hit "Too close to a resource" a tile away from the trunks). Give each resource type its own clearance in the geometry contract, sized by what must stay clear: a tree's trunk, the stands workers use and enough lower canopy that a tree in front never hides a building's body; a deposit its whole rock; an animal nothing. Then resolve the overlap the looser rule allows in picking: where a node's and a building's rectangles both hold the tap, the one drawn in front (the lower ground point) takes it. One function serves the placement rule, its preview overlay, recommended spots, authored start plots and the probes.

## 122.2 Priority

```gdscript
func pick_at(world_pos: Vector2) -> Object:
	var best: Object = null
	var best_d := INF
	# Workers first: small, and they walk in front of everything.
	for w in workers.values():
		if w.get_pick_rect().has_point(world_pos):
			var d := world_pos.distance_squared_to(w.global_position)
			if d < best_d:
				best_d = d
				best = w
	if best != null:
		return best
	if depot.get_pick_rect().has_point(world_pos):
		return depot
	if landmark.get_pick_rect().has_point(world_pos):
		return landmark
	for node in resource_nodes.values():      # then nodes, nearest origin wins
		...
	if best != null:
		return best
	for slot in slots.values():               # then plots, nearest origin wins
		...
	return best
```

- Categories are ordered from small and moving to large and static. Inside a category the nearest origin wins, so overlapping trees resolve predictably.
- A later category is only reached when no earlier one contains the point. That is why a tree in front of a plot steals the plot's taps, and why generation keeps canopies off plots and a probe taps every plot.
- Secondary decorative units (drilling troops) and effects are not selectable.

## 122.3 Selection state

- The world owns `selected` (UI state, not saved). `select(target)` sets it, shows or hides the marker, and emits `selection_changed(target)`. The HUD forwards that to the context panel.
- A tap on nothing selects `null`: tapping empty ground deselects and closes the panel. The panel's close button also calls `world.select(null)`. **Exception (Growing Kingdom v0.12): with a worker selected, a tap on walkable ground is a Move order**, a tap on a node or a construction an order on it, and only taps on other selectable things (another worker, a soldier, a building it has nothing to do with) change the selection. Once empty ground stops deselecting, keep obvious ways out: the card's close button, Android Back / Escape, and a tap on ground no worker can reach.
- **Back and Escape close what is open, innermost first** (build mode, multi-select, the selection, a panel), and quit the app only when nothing is open. Keep `quit_on_go_back` in step with that each UI tick (a dropdown that sets it while open restores the previous value when it closes, so recompute it rather than toggle it).
- Every frame the world checks `is_instance_valid(selected)` and deselects a freed target; the context panel does the same check and closes itself.
- After a resync the world re-selects the same object only if it is an authored entity that still exists (plot, node). Workers are rebuilt as new instances, so a worker selection clears. Re-selecting also rebuilds the panel, so it never shows the replaced state.
- Scripted moments (a destruction sequence, a battle launch, loading a test save) clear the selection first.

- **One selection contract when several things can be selected.** Keep two fields, the single selection (what the context card shows: any selectable thing) and the multi-selection (several units), and make each setter empty the other: the card and the bar can then never disagree, and a recalled squad can never leave a stale single selection driving the card. Every command reads one accessor ("the selected units, whichever way"). Growing Kingdom: `WorldView.select()`, `set_multi()`, `friendly_selection()`.
- **A box selects by one anchor per unit,** the centre of its pick rectangle (the geometry contract above): only friendly units are tested, so buildings, resources and enemies can never enter, and the result does not depend on zoom. A "same type" double tap takes the units of that type whose pick rectangle meets the camera's visible rectangle, never units the player cannot see.
- **Enemies as command targets, not selections.** Hit-test them with the same body rectangles in a separate function that returns a target kind ("enemy"); later target kinds (an enemy building) join it without touching friendly selection.

## 122.4 The selection marker

- Four corner sprites cut from a cursor atlas at their native proportions (reference 21 × 25 px each), placed at the corners of the target's pick rectangle (minimum frame 48 px). The corners stay authored; only the distance between them changes, so one marker frames a worker and a castle equally well.
- It lives in the effects layer with a `z_index` above entities, so it is never hidden behind a roof.
- **Zoom compensation:** corner scale = `clamp(1.15 / zoom, 1.15, 2.6)`. Zoomed out, the corners grow in world units so they keep a readable size on screen; zoomed in, they never shrink below the authored scale.
- **Moving targets:** the world repositions and resizes the marker from `selected.get_pick_rect()` every frame, so it follows a walking worker exactly.
- **Many targets:** draw every multi-selection marker from one canvas item (`draw_texture_rect_region` of the same corner atlas, the same zoom compensation) instead of four sprites per member; it redraws each frame while anything is selected. The same node marks an order's target (a ground square for a move, the corners in red on an attack target, never the friendly colour on an enemy).
- **Marks stay subordinate to what they mark.** A corner sized for one building, repeated on thirty clustered soldiers, merges into one bright block that hides the army. Draw unit marks lighter than building marks: the same corner art at about 0.6 of its size (so about half the stroke once a little transparency is counted), filtered smoothly so the scaled pixel art keeps an even line, around the same rectangle; the tap target and every hit test stay as they were. Check on a large zoomed-in selection that the sprites read first and the marks second, and that one selected unit is still easy to find.

## 122.5 Selection and the rest of the UI

- The context panel shows the selected object's information and actions (section 123).
- The tutorial pointer (section 18) can wait for a selection, then point at a **named** control inside the context panel (`Build_<type>`, `RecruitButton`, `UpgradeButton`, `Task_<task>`). For a world target it frames the same pick rectangle, converted to screen space. Naming controls for pointers and probes is part of the pattern.
- Manual redirection of a worker is done through the context panel's direct commands (section 120.11), not by dragging the worker. A "tap a node to send the selected worker there" feature is not part of this stack; if a design needs it, make it an intent on the state owner (a one-shot target preference), not an entity-side override.

## 122.6 Reuse classification

- **Generic:** the pick-rectangle contract and its five consumers, category priority with nearest-in-category, world-owned selection with a signal, deselect on empty tap and on freed targets, resync-aware re-selection, the corner marker with zoom compensation, named controls for pointers and probes.
- **Configure per game:** rectangle sizes, category order, marker art and scale range.
- **Mechanic-specific:** which categories exist (a depot, a landmark).

## 122.7 Mistakes to avoid

- Physics-based picking (`Area2D` shapes) for a few hundred static objects: it adds collision setup, and the shapes drift from the art. Rectangles computed from the same geometry functions stay consistent.
- A custom selection ring drawn at the sprite's feet: it hides under neighbours and fights Y-sort. Frame the pick rectangle instead.
- Keeping a reference to a worker across a resync.

Reference implementation: `World.pick_at()`, `select()`, `_place_marker()` in `scripts/world/world.gd`; `scripts/ui/target_selection_marker.gd` and its scene; `get_pick_rect()` in every entity script.

---

# 123. Contextual information panels

## 123.1 Problem

A tapped object must explain itself: what it is, its state, the numbers that matter now, what can be done, and why an action is unavailable. Values change every frame (progress, countdowns, statuses); the structure changes occasionally (a plot becomes a site, then a building). The panel must never show stale values or buttons for a state that no longer exists.

## 123.2 Pattern: structure key, updaters, reason-bound buttons

```gdscript
const REFRESH_INTERVAL := 0.2

func show_target(new_target: Object) -> void:
	target = new_target
	visible = target != null
	_structure_key = ""
	if visible:
		_rebuild()

func _process(delta: float) -> void:
	if not visible:
		return
	if target == null or not is_instance_valid(target):
		close_requested.emit()
		return
	if _structure() != _structure_key:
		_rebuild()                 # the object's shape changed: new layout
		return
	_accum += delta
	if _accum >= REFRESH_INTERVAL:
		_accum = 0.0
		for updater in _updaters:
			updater.call()         # values only, read from state

func _structure() -> String:
	if target is BuildingSlot:
		var b: Dictionary = RunState.buildings.get(target.slot_id, {})
		return "slot:%s:%s:%s:%s:%s:%s" % [target.slot_id, b.get("type", ""), b.get("state", ""),
			b.get("tier", 0), b.get("upgrading", false), RunState.phase]
	if target is Worker:
		return "worker:%d:%s:%d" % [target.worker_slot, ",".join(ProfileState.get_priorities(target.worker_slot)),
			ProfileState.task_slot_count()]
	if target is ResourceNode:
		return "node:%s" % target.node_id
	return "other:%s" % str(target.get_instance_id())

func _dynamic_line(fn: Callable, variation := "") -> Label:
	var l := _add_line("", variation)
	_updaters.append(func(): l.text = fn.call())
	return l

## Enabled state and a visible reason both come from the state owner's block-reason function.
## The reason sits on the cost's row, a row of fixed height that is always present,
## so the card never changes height when the reason appears (section 128.3).
func _action_row(cost_text: String, text: String, action: Callable, reason_fn: Callable, icon := "") -> Button:
	var row := UiKit.cost_status_row(cost_text)   # cost left, reason right, fixed height
	_body.add_child(row)
	var b := UiKit.button(text, action, "", icon)
	_body.add_child(b)
	_updaters.append(func():
		var reason: String = reason_fn.call()
		b.disabled = reason != ""
		UiKit.show_status(row, reason))          # short form, never hides the row
	return b

func _do(success: bool, message: String) -> void:
	if success:
		hud.toast(message)
	_structure_key = ""            # force a rebuild next frame
```

Why this works:

- **Authoritative values:** every dynamic line is a closure over a state getter; nothing is copied into the panel.
- **No stale structure:** the key encodes exactly what changes the layout; when it differs, the panel rebuilds once.
- **No per-object signal wiring:** a 0.2 s poll of a handful of closures is cheaper and simpler than subscribing to every state signal for every object type.
- **Disabled actions explain themselves:** the reason beside the cost is the same text (or its short form) the intent would refuse with, and the full reason is the toast when the player taps anyway. Feed the Dragon's first version put the reason on its own line under the button; Growing Kingdom's playtest found cards that changed height and moved the button the player was aiming at, which is why it now shares the cost's row.
- **Rapid values stay current:** progress bars and countdowns are updaters too; 0.2 s is smooth enough for text and bars at city-builder pace.
- **Buttons that change the structure** (Build, Upgrade) reset the key, so the new state appears on the next frame.

## 123.3 Block-reason functions

One per action, on the state owner, returning `""` when allowed, otherwise a short sentence that says how to fix it:

```text
"Need 50 Wood."            "Need 60 Wood, 40 Gold."
"Upgrade in progress."     "Maximum tier reached."     "Finish construction first."
"Recruit queue is full."   "Population full. Build or upgrade a House."
"Blueprint required (free at 30 min of total survival)."
"Cannot be built here."    "The city has fallen."
```

The same functions drive the context panel, the side panels, the tutorial pointer's caption ("Tap Build Lumberjack." or the reason) and the intent's own validation. Every block reason checks the gameplay lock first (section 26.1) and any progression gate before the cost (section 3.4). A narrow card shows a short, decisive form mapped from the full reason ("Needs Wood" becomes "Need more Wood"; section 128.3).

## 123.4 Content recipes

**Resource node**

- title: node type name;
- dynamic: `Depleted. Returns in 42s.` (base countdown / regrowth multiplier) or `Wood available: 8 / 12` (stock / current maximum);
- dynamic, small: `Workers here: N` (claims: walking to it or working it);
- small: which task harvests it and that workers carry it to the nearest drop-off.

**Empty plot**

- title "Empty Plot", one line on the cost rule;
- one option card per allowed type that is buildable in this build: tier-1 art (64 × 80), name, description, `Cost 30 Wood · Build time 20s`, and a reason-bound Build button named `Build_<type>`.

**Reserved plot**: which buildings it is reserved for and that they arrive later.

**Construction site or upgrade** (shared project controls)

- progress bar (updater);
- ETA: `About 1m 12s left · 2 builders on site`, where ETA = remaining work / (passive rate + builders on site × builder rate), and builders on site are workers in the build phase at this plot (walking builders are not counted yet);
- `Construction priority: 2 of 3`;
- Raise and Lower buttons, disabled at the ends of the order;
- one sentence explaining passive progress and builders.

**Built building**

- title with tier (`House · Tier II`), no tier for one-tier buildings;
- description, then what the current tier gives (`Population +3 · Storage +120`, `Wood drop-off · Delivery bonus +25%`);
- while upgrading: "Upgrading to Tier III. It keeps working at Tier II until the work is done." plus the project controls;
- otherwise the next tier's gain and build time, and a reason-bound `Upgrade: 60 Wood, 40 Gold` button named `UpgradeButton`; or "Maximum tier reached.";
- type-specific sections, each with its own updaters and reason-bound buttons: recruitment (`Population 5 / 6 (1 training)`, a queue line and bar that stay present with an idle text when nothing trains, `Recruit Villager: 21 Gold · 12s`), unit training, research summary with a button to its screen, a command building's launch button, a permanent choice the building is waiting for (section 129.7);
- a destructive action (Demolish) apart from the others, with its refund on a line of its own rather than inside the button (a button that names three resources grew wider than the screen in Growing Kingdom).

**Worker**

- avatar and title (`Villager 3`);
- dynamic status (section 120.10) and `Carrying 3.5 Wood` or `Hands empty`;
- `Priorities: 1. Gather Wood 2. Build` (static, the structure key rebuilds it when priorities change);
- "Send to work" and a grid of task buttons with icons, named `Task_<task>`, always enabled, which set place 1 through the one edit rule (section 129.5);
- "Manage Priorities", which opens the workers panel with this worker selected.

**Depot** (a visible stand-in for a stored resource): the stored amount and an explanation of who fills and empties it.

**Landmark or consumer**: its state lines (for example a need meter, its drain rate, per-unit value, a danger countdown in the warning colour when active).

## 123.5 Placement

The panel sits in the left column under the economy readout (reference minimum width 580 px, a 76 × 76 close button in its header), inside the HUD's safe area. It is listed in the camera's blocker (section 121.2). A low-priority element sharing that column (the mission tracker) hides while the panel is open and returns when it closes.

**Command versus inspection (Growing Kingdom v0.15).** In a game where the player commands units on the map, a card that opens on every unit tap covers the world the next tap is aimed at. Treat selecting a commandable unit as command mode: no card opens; a compact status in a lower corner (picture, name, one live line, a Details body and a clear button, a full touch target each, reserving no camera room) shows what is selected, and the same card opens only from Details. Closing that card keeps the unit selected; Back closes the details first and clears the selection second, never both in one press. Buildings and resources stay inspected (their card opens on selection). A selection of several gets the same compact status, its command bar the expanded state.

## 123.6 Reuse classification

- **Generic:** structure key plus updater closures, reason-bound action buttons, rebuild after a structure-changing action, close on an invalid target, state-owned block reasons, ETA from rates, named controls.
- **Configure per game:** recipes per entity type, texts, refresh interval, width and position.
- **Mechanic-specific:** recruitment, training, research and command sections.

## 123.7 Mistakes to avoid

- Rebuilding the whole panel every refresh: buttons lose presses, scroll positions jump, and it costs far more.
- Only rebuilding on selection change: a plot that finishes construction keeps showing the site controls.
- Disabling a button without saying why.
- A reason or status line that appears and disappears, so the card changes height and the button moves under the player's thumb (section 128.3).
- Computing an ETA from the configured builders instead of those actually working.
- A panel as tall as the screen for a three-line card: size it to its content (section 16.3).

Reference implementation (Feed the Dragon): `scripts/ui/context_panel.gd`; the `*_block_reason()` functions in `scripts/autoload/run_state.gd`. Growing Kingdom: `scripts/ui/panels/context_panel.gd`, `UiKit.cost_status_row()` / `show_status()`.

---

# 124. HUD and assignment presentation

## 124.1 Problem

With dozens of workers, the player cannot tap each one to learn what the economy is doing. The HUD must answer "what do I have, how many workers are on each resource, is anything blocked, is anyone idle, is anything waiting for me" in one glance, without covering the map on a phone.

## 124.2 Economy readout (top left)

| Element | Content and rule |
|---|---|
| Resource chip, one per resource | icon (44 px), floored amount, and a **worker badge** on the icon |
| Worker badge | the number of workers on this resource, counted for the question the badge answers (below). Feed the Dragon counts the **running** task (a worker that fell through because storage is full is not counted); Growing Kingdom counts **assignments**. Pinned to the icon's lower-right corner and growing up and left, so two digits cover the icon, never the amount (a probe asserts no overlap). Worker blue with a gold border while above zero, muted grey at zero. The style is swapped only when it crosses zero; the text only when it changed |
| Storage chip | `used / capacity`; the whole chip switches to the alert style while storage is full |
| Population chip | worker avatar and `used / capacity`, where used includes queued units (they reserve population) |
| Blocking warning | a dedicated alert chip, visible only while full storage blocks gathering of the survival resource: "Storage full: villagers cannot gather Meat!" (section 112: a shared-capacity economy must be loud when the survival resource is blocked) |

All chips are dark translucent panels with a gold border (alert: dark red with an orange border) and `MOUSE_FILTER_IGNORE`: read-only, never blocking a tap on the map.

**Decide which question a workforce number answers, then count for that question.** "How many workers on Gold" has two honest answers:

| Question | Count | When it is the right one |
|---|---|---|
| **Allocation:** how did I assign my workforce? | workers **assigned** to Gold (their first priority), including those walking, waiting on full storage or waiting for a node | the number sits next to the control that assigns workers; it must change the instant the player reassigns and not flicker while workers walk or wait |
| **Activity / throughput:** who is producing Gold now? | workers **currently executing** the gather task (walking to a node, working, carrying home) | the number explains a production rate; a worker blocked by full storage should visibly drop out |

Neither is "the" correct counter; a counter is wrong when it answers a different question than the player is asking. Growing Kingdom first counted activity (the generic choice of the earlier stack); its playtest read the chip as allocation ("I put three on Gold, why does it say two?"), so the chip now counts assignments, and the game makes blocked production loud elsewhere (the storage-full chip and warning). Rules that hold either way:

- Read one authoritative field (the assignment, or the running task), never an animation or a phase you have to interpret.
- With several priority places, count the first (the assignment); counting every place counts one person on several chips.
- Exclude the dead and the removed; include new recruits at once.
- Say which question it answers in the design document, and probe the cases where the two answers differ (walking, full storage, fall-through).
- If a game needs both, show both, labelled, not one number that changes meaning.

Reuse (Growing Kingdom): `RunState.assigned_counts()`, `assigned_task()`; `core_probe` "resource chips count assignments", `world_probe` "HUD workforce counts".

## 124.3 Idle and opportunity badges

On the dock button that opens each system, one look per meaning (section 21):

| Kind | Look | Trigger here |
|---|---|---|
| alert | red "!" | any worker is idle with no executable task (the same condition as the in-world "?") |
| ready | green "!" | a reward waits to be claimed |
| afford | gold "+" | an upgrade or research can be bought now |

## 124.4 Top band and controls

- Centre: the main survival meter (mechanic-specific), tappable to focus the landmark, with a stage label and an info line; a warning banner below it during danger. It is laid out every frame between the economy readout and the top-right row, so a notch never pushes it over the chips.
- A later system that needs a place in this band (a meta-progress element) takes a sibling region of its own rather than reshaping the meter or the chips (sections 16.4, 19.1).
- Top right: pause (a "user" pause owner) and a speed button that cycles the speeds the account has unlocked (hidden while only 1x exists). In debug builds a debug button sits in this row, so the dock is laid out exactly as in release.
- Right: a dock of square buttons (reference 96 px) hanging under the top row, with a collapse arrow whose state is saved in settings. One side panel at a time, created lazily on first open and kept; toggling the same button closes it. An open panel starts below the meter wherever they share columns, so a danger banner is never hidden under management UI.

## 124.5 The worker management panel

- **Slot row (bottom):** an "All" toggle, then one button per worker slot up to the population capacity (at least 10 shown). An owned slot shows the worker's avatar and a **column of small task icons**, one place per unlocked priority, top to bottom, with blank places kept so rows compare across workers. A slot inside capacity but empty shows "+"; a slot beyond capacity shows "?". The row is a `TouchScroll`.
- **Detail (top):** avatar, title, status and carry (polled every 0.25 s), an effective-stats line (`Move 115 px/s · Carry 4 · Build +1.0/s`), then one control per priority place (every task plus "None"). Locked priority places say what unlocks them. Growing Kingdom replaced Feed the Dragon's row of toggle buttons per place with one dropdown per place (section 129.1) and a stable panel with a pinned header and rows diffed in place (section 16.3).
- **"All" mode:** a pick is written to every worker through `set_priority()`; a task shows as selected only when every worker has it ("mixed" selects nothing).
- It rebuilds when marked dirty by worker spawn, the worker list changing, a state replacement, unlocks and priority changes, and only while visible.

This is what lets the player read the whole assignment at a glance: the slot row is a compact table of everyone's priorities, and the HUD badges answer their stated question.

## 124.6 Construction panel

Every project in priority order with a progress bar (updater, 0.2 s), and Raise, Lower and Show (focus the camera on it and select it). It rebuilds on construction started, completed and building changed signals.

## 124.7 Toasts

- One at a time, **queued** (maximum 4, the oldest dropped first), with a shorter hold while more wait (reference 1.6 s, 1.0 s when busy, then a 0.6 s fade), so two events in the same moment are both read.
- The same text twice in a row is dropped.
- Placed every frame in the free band of the world view: right of the context panel, left of the open side panel (or the dock), under the top meter, wrapped to that width, and one font step smaller below 520 px.
- Real time (`set_ignore_time_scale(true)`), and a short history kept for probes.
- Reserved for events the world cannot show by itself (a mission, an unlock, a blocked launch); a building completing is already shown in the world (section 119.8).

## 124.8 Refresh strategy

- Values: every 0.1 s (amounts, badges, chips, labels, dock badges, tracker).
- Layout: every frame (cheap), because groups depend on each other's size (meter placement, panel top, toast band).
- Danger alerts are presentation-only pacing: a banner held briefly after the danger pauses (no flicker), and a vibration at most once per cooldown, both in real seconds and never touching the timer they describe.

## 124.9 What the player can read without inspecting a unit

| Question | Where |
|---|---|
| How many workers are on each resource (allocation or activity, as the game decided) | the badge on each resource icon |
| Is anyone doing nothing | the red "!" on the workers button and the "?" above the worker |
| Why did gathering stop | the storage chip turns red and the survival-resource warning appears |
| Who is assigned to what | the task icon columns in the workers panel slot row |
| What is being built next and how fast | construction panel; progress bars over the sites |
| What can I buy | gold "+" badges |
| Is a worker blocked | its status line ("Can't reach target", "Storage full: holding Wood") |

## 124.10 Reuse classification

- **Generic:** read-only chips that let taps through, worker badges that answer one stated question, storage alert styling, badge vocabulary, one side panel at a time, lazy panels, slot row with priority icon columns and "All", toast queue and placement, throttled value refresh with per-frame layout, real-time alert pacing.
- **Configure per game:** resources and icons, chip contents, dock entries, sizes, intervals.
- **Mechanic-specific:** the survival meter and danger banner, the blocking warning for a survival resource.

## 124.11 Mistakes to avoid

- A workforce number that answers the other question: counted from assignments, it hides blocked production; counted from the running task, it flickers and disagrees with what the player just assigned. Pick the question first (section 124.2).
- Toasts that replace each other, or sit on the open panel.
- Badges that only appear inside the panel they concern.
- Letting read-only HUD pieces block world taps.

Variant (Growing Kingdom): the resource chips show a Villager icon and the assigned count as text and are buttons that open the Villagers panel, so the number and the place to change it are one tap apart; a chip that is a button must then be in the camera's blocker.

Reference implementation (Feed the Dragon): `scripts/ui/hud.gd`, `scripts/ui/villagers_panel.gd`, `scripts/ui/construction_panel.gd`, `World.gatherer_count()` in `scripts/world/world.gd`, `UiKit.badge()` in `scripts/ui/ui_kit.gd`.

---

## 124.12 Minimap and expanded map share the fog contract

Use the discovery/visibility queries in 117.9 for every map surface. Fit the map into a content rectangle using one uniform scale with letterboxing where necessary; never stretch X and Y independently. Exclude headers, legends and controls from the drawable map rectangle.

Map-local bounds, including a nonzero origin, determine normalization. Apply the same content rectangle, zoom, pan and clipping transform to terrain, fog, markers and pointer-to-map conversion. A tap in a letterbox margin is not a map location. Reopening, resizing or switching between minimap and expanded view must not alter exploration or briefly show hidden markers.

Use representative approved icons for identified enemies/resources/chests, a supplied unknown marker for unknown entries, and the game's explicit owned-unit/known-landmark exceptions. Do not create fake marker art when the required pack lacks an icon; follow the asset-gap process (22.2). Tooltips should be compact, placed beside/below their anchor, clamped to safe bounds and nonblocking. Any timed expiry, such as three seconds, is configurable.

If a map supports tap-to-locate, selection or navigation, filter the hit candidates with the same disclosure decision used for drawing. If opening uses double tap/click, keep it distinct from camera panning, pinching and single-tap selection. Panel-open pause and UI animation must not change discovery ownership.

---

---

# 125. World readability and feedback techniques

"Readable" came from a set of concrete techniques, each cheap. Sections 13, 24, 25 and 76 give the principles; this is the validated toolkit.

## 125.1 Layering and draw order

- **Every world entity's origin is its ground contact point,** and each sprite's offset is computed from the measured bottom row of its opaque pixels (a table per art variant). Nothing is hand-nudged per instance.
- **Y-sorted containers:** the entity root and each group under it (plots, nodes, workers, secondary units) have `y_sort_enabled`. Workers walk behind and in front of houses and trees correctly with no `z_index` tuning.
- **A separate effects layer** (a `Node2D` above the entities, `z_index` 10) holds bursts, projectiles, floating text and the selection marker. Relative order inside it: marker 15, building progress overlays 20 (drawn by each plot's own overlay child), thrown goods 25, arrows 26, floating text 40.
- The terrain's hidden navigation layer sits at a high `z_index` so it draws over everything when toggled on in the editor.

## 125.2 Pixel art

- Project default canvas texture filter: Nearest. Imports stay lossless.
- Use the pack's larger variants instead of scaling small ones (large gold deposits at scale 1.15, not small stones at 2x). Scale world text, not sprites, when something must read at map zoom.
- Tier and faction colour come from authored palette variants, not tints (section 73). One colour is reserved for the enemy.

## 125.3 State legibility per entity

| Entity | Technique |
|---|---|
| Empty plot | dashed outline, faint fill, a plus sign: "you can build here" |
| Reserved plot | faint dashed outline, no fill: "later" |
| Construction | the target building's art as a dark blue-grey silhouette plus a progress bar |
| Upgrade | the **next tier's** art as a silhouette, props kept, bar |
| Finished tier | full colour tier palette, a punch on completion |
| Specialised building | small resource props (a log pile, a gold stone, food and wood) beside a shared house silhouette |
| Node, full | animated, desynchronized, with idle life (sway, shimmer, grazing) |
| Node, depleted | a different silhouette (stump, grey rock) or absent |
| Worker, loaded | carry-variant walk and idle animations show the resource in hand |
| Worker, working | a per-resource tool animation facing the target |
| Worker, idle with nothing to do | a floating "?" in a yellow disc |
| Stored survival resource | a depot sprite that grows with the stock (`scale = 1 + min(stock / 40, 1) × 1.4`) with an outlined amount label, dimmed at zero |

## 125.4 Activity and delivery feedback

- **Contact frames:** feedback fires on the frame where the tool connects (section 120.9), not on a timer. The node sways, springs or hops; the builder raises a dust puff on its tool side.
- **Delivery numbers:** "+4 Wood" rises from the drop-off in the resource's colour, **including the bonus**, so a better drop-off visibly pays more.
- **Thrown goods:** a sprite on a quadratic Bézier arc (apex 140 px above the midpoint), spinning 1.5 turns in 0.65 s; the receiver reacts on landing (a heal burst and "+10"). The credit already happened at the throw.
- **Availability changes:** dust when a node empties or returns; a large dust burst when a worker or unit appears.

## 125.5 Impact

- **Punch:** scale to 1.08 and back in 0.25 s with `TRANS_BACK`, ease out, on completion and upgrade.
- **Spring recoil:** position and squash keys with `TRANS_BACK` for struck deposits.
- **Camera shake:** the camera's `offset`, random steps every 0.05 s decaying from 10 px, real time.
- **Vibration:** only for major events (destruction, a battle launch, a danger start with a cooldown), and only on mobile when enabled in settings.

### Contact and resource feedback with supplied assets

Combine the verified actor pose/expression with a restrained target response: brief squash/stretch, shake/recoil, or an approved colour flash. Restore authored base transforms/colour after each response; rapid hits must not accumulate scale or displacement. Do not tint or shake the logical collision/navigation root.

Use representative supplied resource icons beside awarded amounts where available. Emit the popup once at the authoritative award/collection moment (13.2), anchored to the relevant world target; keep camera zoom, overlap and pooling cleanup in mind. Inventory/HUD pulses can reinforce receipt without rebuilding the panel. Depletion needs a clear authored empty/stump/removed state, with the final impact still visible.

Apply section 22.2 to all world-adjacent interface controls too: HP bars and selected-unit action buttons are UI, even when they follow a character. Use the required pack's bar/button assets and keep their attachment offsets editable. Target reactions and existing sprite transforms do not authorize drawing replacement UI or generating particles/art when the project's asset policy forbids it.

Validation: idle versus walking visibly differs; armed and unarmed actions differ; impact frame matches the target reaction; resource credit and icon popup agree; fishing retains a readable hold at supported speeds; repeated hits restore base transforms; death completes before cleanup. Test pause, speed changes, fast repeated actions and state replacement. Validate finger visibility and readability on a physical phone separately from desktop checks.


## 125.6 Tween hygiene

- Every repeating feedback tween is stored, killed before a new one starts, and restarts from the authored base values (section 76).
- A tween that must not outlive a state change is owned by the entity and killed in `refresh()`.
- Sequences whose length matters (destruction, toasts, banners) ignore time scale; micro feedback tied to gameplay (strikes) runs on game time.

## 125.7 A small effects helper

All effects free themselves:

```gdscript
static func burst(parent: Node, anim: String, pos: Vector2, scale := 1.0, z := 5) -> AnimatedSprite2D:
	var s := AnimatedSprite2D.new()
	s.sprite_frames = frames()          # one shared SpriteFrames for all effects
	s.position = pos
	s.scale = Vector2(scale, scale)
	s.z_index = z
	parent.add_child(s)
	s.play(anim)                        # non-looping animation
	s.animation_finished.connect(s.queue_free)
	return s

static func float_text(parent: Node, pos: Vector2, text: String, color := Color.WHITE) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 30)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.1, 0.07, 0.05))
	l.add_theme_constant_override("outline_size", 8)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(220, 40)
	l.position = pos - Vector2(110, 60)
	l.z_index = 40
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	var t := l.create_tween().set_parallel(true)
	t.tween_property(l, "position:y", l.position.y - 70.0, 1.2)
	t.tween_property(l, "modulate:a", 0.0, 1.2).set_delay(0.5)
	t.chain().tween_callback(l.queue_free)
```

Plus a looping fire with a lifetime and fade, and a projectile that rotates along its arc's tangent. Effect animations are baked once into one `SpriteFrames` resource by a tool (dust, large dust, fires, explosions, splash, heal).

## 125.8 World text and bars

- World floating text: 30 px with an 8 px dark outline (about double what a desktop screenshot suggests; section 14.2).
- World bars: drawn in `_draw()` with a dark outer frame, a mid-tone track and a saturated fill; a queue count drawn with `draw_string_outline` then `draw_string`.

## 125.9 UI panels and controls

- **One panel family** (section 70) built by factory functions: paper 9-slice panels, button 9-slices with per-state `modulate_color` (hover 1.12, disabled 0.55 grey with lighter text, toggle off 0.72 and on warm 1.25/1.2/0.8), a danger variant, ribbons for screen titles.
- **Type scale** for a 1080 px tall canvas: body 26, small 22, title 36, HUD readouts 28 to 30 with an 8 px outline over the map. Growing Kingdom's phone review found 26/22/36 with 76 px buttons too small for dense management panels and moved to body 33, small 28, title 46 and 92 px buttons (dock 96); treat the smaller scale as the floor, not the target, for panel-heavy games.
- **Do not rely on a full-rect anchor preset for a host under a `CanvasLayer`.** In Growing Kingdom such hosts (HUD, panels, modals, results) measured 0 × 0 in headless probes and during the first frames, so every child positioned from the host's size landed at the origin. Give each top-level host an explicit size (the viewport's) in its `relayout()`, and relayout on viewport size and safe-area changes.
- **A container holding autowrap labels reports an inflated height on the first layout pass after a rebuild** (the label measures itself one word per line before it knows its width). Fit and position a rebuilt panel or modal again on the next frame (`call_deferred`), not only immediately. Better: never show that first measurement at all; keep a new panel invisible until its size holds, and resize a visible one only to a size that has held (section 16.3).
- **Touch minimum 76 px both ways** for every visible button, enforced by the layout probe; ordinary buttons taller where the layout allows (Growing Kingdom 92 px), dock buttons 96 px.
- **Every disabled action shows its reason in a fixed place:** beside the cost on cards that sell something (section 128.3), otherwise in a status line that is always present.
- **Icons** for resources, tasks and states, reused everywhere that concept appears (chips, task buttons, slot icon columns, stance tags), so the player learns one symbol per concept (section 128.4).
- Wrapped labels must expand horizontally inside rows, or they collapse to one character per line.

## 125.10 Placeholder art behind a small interface

When final art for a major entity does not exist yet and the project's asset policy permits procedural placeholders, draw a procedural placeholder in the game's palette behind a handful of presentation calls (for the consumer in the reference: `on_fed()`, `mouth_position()`, `get_pick_rect()`, `play_destruction(targets) -> duration`, `play_defeat() -> duration`, and a few combat reactions). The simulation never calls anything else, so swapping in the real animated sprite touches one script. Sequence functions return their length in real seconds, so the orchestrator waits on a real-time timer that also runs while paused (`get_tree().create_timer(duration, true, false, true)`) and shows the results after it.

## 125.11 Reuse classification

- **Generic:** ground-contact origins with measured offsets, Y-sorted groups plus one effects layer, silhouettes for projects, distinct depleted art, carry variants, contact-frame feedback, delivery numbers including bonuses, credit-first projectiles, punch and spring presets, offset shake, tween hygiene, self-freeing effect helpers, the panel family and touch minimum.
- **Configure per game:** every art choice, sizes, colours, timings, the depot scale formula.
- **Mechanic-specific:** thrown goods to a consumer, destruction sequences, defensive fire.

Reference implementation: `scripts/world/fx.gd`, `scripts/world/building_slot.gd`, `scripts/world/resource_node.gd`, `scripts/world/villager.gd`, `scripts/world/offering_pile.gd`, `scripts/ui/ui_kit.gd`, `tools/build_generated_resources.gd`.

---

# 126. Recreating the stack: dependency order and stage gates

Build in this order. Each stage lists what must exist first and what must pass before moving on. Keep each stage a probe-covered checkpoint (section 2).

| Stage | Build | Needs | Gate (must pass) |
|---|---|---|---|
| 0. State skeleton | `Balance` catalogs (resources, nodes, buildings, tasks); run and account state owners with `reset()`, `to_save_dict()` (copies), `from_save_dict()` (sanitizing), registered save sections; intents with block reasons; effective-value getters; `tick()` and `tick_timers()` | the bootstrap baseline (section 0) | save round trip is lossless; Hard Reset returns defaults; a saved dictionary does not follow later live changes |
| 1. Terrain and navigation | terrain scene with ground and a hidden walkability layer; nav grid with snapping, A* and smoothing | 0 | paths exist between known points; blocked targets snap; an unreachable target returns an empty path; the editor toggle shows the layer |
| 2. Camera and input | map camera with the gesture state machine, bounds, clamping, anchored zoom, focus; emulated touch on desktop | 1 | synthetic tap, pan and pinch sequences behave as in section 121.3; zoom and position stay within limits at every tested aspect ratio |
| 3. Authored map registry | `@tool` plot and node scenes with stable ids; world collects them and registers them before the run is created; reconciliation on load | 0, 1 | editor-open check is clean; a save with an unknown id loads without it; a new map node appears full in an old save |
| 4. Resource nodes | node state, depletion and respawn in `tick_timers()`, claims and unreserved stock, target selection; node presentation with depleted art | 3 | deplete and respawn by timer; partial harvest keeps a node; claims never exceed stock; depleted art shows |
| 5. Storage and drop-offs | shared storage, `deposit()` returning consumed carry, drop-off types, delivery bonus, nearest drop-off | 3 | deposit clips to free storage; bonus credit clips and consumes only what was credited; nothing deposits into full storage |
| 6. Worker loop | worker entity: spawn, movement along paths, gather, carry animation, deposit with floating number, driven by a direct command | 1, 4, 5 | in the real main scene a walking worker delivers a resource; the node reacts on contact frames |
| 7. Decisions | priorities per slot in account state, `decide()` and `_can_do()`, re-evaluation points, fall-through, carry safety, unreachable cooldown, "?" indicator | 6 | fall-through works both ways; full storage blocks gathering without losing carry; an unreachable node is skipped |
| 8. Buildings | construction order with passive and builder work, upgrades as projects, plot presentation (empty, reserved, silhouette, tiers, props, bars), completion feedback, builders at spread points | 5, 7 | a walking builder finishes a building and an upgrade; the upgrading building keeps working; the construction order always matches the records |
| 9. Picking and selection | pick rectangles, `pick_at()` priority, selection signal, corner marker with zoom compensation | 2, 8 | tapping the centre of every plot selects it; a worker in front of a building wins; the marker follows a walking worker |
| 10. Context panel | structure key, updaters, reason-bound buttons, recipes per entity | 9 | the Build, Upgrade and task buttons work through the real panel; a finished construction rebuilds the panel |
| 11. HUD and management | chips, worker badges that answer one stated question (section 124.2), storage alert, warnings, dock with badges, workers panel with slot icons and "All", construction panel, toasts; the camera's blocker registered | 10 | badges follow direct commands; badges never cover amounts; the layout probe passes at every screen shape and inset case |
| 12. Resync, persistence and offline | `sync_from_state()` with reservation clearing, deferred coalesced trigger, muted offline pass, boot order | 0 to 11 | reload rebuilds the same workers and buildings; carried goods survive a force-close; offline completes timers and never gathers |
| 13. Feedback and readability pass | effects helper, punches, springs, shake, depots, tween hygiene | 8, 11 | showcase captures reviewed at phone resolution; no tween drift after rapid events |
| 14. Endurance and pacing | a soak with many workers at top speed checking invariants; a pacing bot that plays through direct commands | all | zero invariant failures over tens of simulated minutes; the same simulated time yields the same output at every speed |

Order rationale:

- State before world: every later stage writes through intents, so they must exist first.
- Navigation and camera before entities: every entity needs approach points and every manual test needs to look around.
- The registry before nodes and plots: ids are save keys from the first save.
- Workers before buildings: construction without walking builders hides the hardest integration (builder spread, top-project switches).
- Selection after buildings and workers: the priority order only makes sense with all categories on the map.
- Resync last among the systems, but its rules (no saved runtime) from stage 0.

---

# 127. Validation matrix

## 127.1 Probe techniques that proved themselves

- **Test the real main scene, with real walking.** Instantiate the game's main scene, set an explicit onboarding mode so first-run screens stay closed, raise game speed, and let workers actually path, gather and build. Wait on **simulated** time (`wait_until(predicate, timeout_in_sim_seconds)`), not on frame counts.
- **Drive intents, then observe.** Probes call the same intents the UI calls (`direct_command`, `start_construction`), press real buttons by name (`find_child("Build_lumberjack")`, `pressed.emit()`), and assert on state and on what the HUD shows.
- **Synthetic pointer input** through `get_viewport().push_input(event, true)`: mouse button and motion events with `button_mask` for UI drags (with emulated touch they arrive as touches), and `InputEventScreenTouch` and `InputEventScreenDrag` with finger indices for camera gestures.
- **Separate processes for close and reopen:** a write phase builds a state, saves and exits abruptly; a verify phase boots the real game from that save. Assert conservation, not exact positions ("carried plus stored equals what was carried at close").
- **Soak invariants every simulated second** at top speed with a bot that keeps building and upgrading.
- **Layout matrix:** four screen shapes × three inset cases × every panel, card and modal (section 68).
- **Editor-open check** of the world and main scenes (section 113).
- **Regression checks that fail on the old code,** added with each fix.
- **Named controls and read-only probe accessors** (`worker_badge_text()`, `toast_history()`, `layout_parts()`, `is_sprite_shown()`), so probes never parse pixels.

## 127.2 Scenarios

"Covered" means an automated probe in the reference implementation asserts it; "add" marks a gap worth closing in the next game; "device" needs a physical phone.

| Scenario | Assert | Status |
|---|---|---|
| Tap selects | tapping the centre of every plot selects that plot (skip points under a worker) | covered |
| Tap versus pan | a press moved less than the threshold and released in time emits one tap; moving past it pans and emits none | add: synthetic touch sequence against the camera |
| Long press | a press held past the time limit emits no tap | covered (Growing Kingdom world_probe) |
| Long press, then drag | draws a selection box, selects the friendlies in it, never pans or taps; moving before the threshold pans for good; a second finger cancels it; a modal ends it | covered (Growing Kingdom world_probe, v0.14) |
| Pinch zoom | two-finger spread zooms about the midpoint; zoom stays within `[min_zoom, MAX_ZOOM]`; lifting one finger never taps | add |
| Camera limits | after pans and zooms toward every edge, the visible rectangle stays inside the bounds; on a viewport resize it re-clamps | add |
| UI blocks the world | a touch starting on each blocker group never pans or taps | partly covered (the tutorial card); add: every group in the blocker list |
| Selection near UI | a tap just outside a panel's rectangle reaches the world; just inside does not | add |
| Selecting a moving worker | select a walking worker; the marker's centre equals its pick rectangle's centre on later frames | add |
| Resync with a selection | after a reload a selected plot stays selected; a selected worker clears and the panel closes | add |
| Gathering | a walking worker delivers; the delivery reaches storage | covered |
| Depletion and respawn | a node empties, becomes unavailable, starts its timer, returns full | covered |
| Worker distribution | several gatherers spread over distinct nearby nodes; claims never exceed stock | covered by soak invariants (claims held only by live workers, stock never negative); add: distinct targets |
| Reassignment | a direct command changes the running task and the HUD badges within seconds | covered |
| Fall-through | a full consumer makes a delivery-first worker gather instead | covered; add: it returns to delivery when the need comes back |
| Direct command order | the task becomes priority 1 and the others shift; a task appears once | covered |
| Unreachable target | a node on an island is skipped and not retried for the cooldown; the worker picks another | add |
| Storage limits | storage never exceeds capacity; carry stays bounded; nothing is gathered into full storage; the warning shows and clears | covered |
| Construction | a walking builder finishes a building and an upgrade; the building keeps working while upgrading; the order matches the records | covered |
| Animation and state sync | an upgrading plot shows the silhouette, a finished one the full sprite; a rebuilt building stays visible after a destruction fade | covered |
| Saving during active work | carry and construction survive a force-close; carry plus stored is conserved | covered |
| Loading and resuming | a reload rebuilds the same number of workers and the same buildings | covered |
| Offline | timers complete within the bounded window; gathering is not simulated; builders and feeders are resolved from priorities; the reward is claimed exactly once | covered |
| Speed | the same simulated time gives the same output at 1x, 2x and 3x | covered |
| Aspect ratios and safe areas | every control inside the safe area, 76 px touch targets, no overlaps, toasts clear of panels | covered |
| Scroll lists | a drag starting on a button scrolls the list and does not press it | covered |
| Android touch | pan, pinch, tap comfort, notch and gesture bar in both landscape directions, readability of world text | device |

## 127.3 Additional cases found during this investigation

- **A decoration in front of a plot:** re-run the tap-every-plot probe whenever generated or hand-placed decoration changes.
- **Destruction presentation interrupted by a modal:** after Rebuild, wait a few seconds and assert the new building is still drawn.
- **Upgrade silhouette shows the next tier:** assert the plot's state and that the full sprite is hidden while upgrading.
- **Workforce badge honesty:** fill storage and assert the badge follows its stated question (an activity badge drops to zero for a gatherer that fell through; an allocation badge keeps it).
- **Save dictionary is a copy:** change the live construction order after saving and assert the saved copy did not follow (section 113).
- **Offline order:** the offline pass builds the player's top project first.
- **Editor safety:** opening the world scene in the editor prints no errors (a `@tool` plot that polls run state in the editor fails here).

## 127.4 Minimal gesture probe (to add in the next game)

```gdscript
func _touch(index: int, pos: Vector2, pressed: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = index
	e.position = pos
	e.pressed = pressed
	get_viewport().push_input(e, true)

func _drag(index: int, pos: Vector2, relative: Vector2) -> void:
	var e := InputEventScreenDrag.new()
	e.index = index
	e.position = pos
	e.relative = relative
	get_viewport().push_input(e, true)

# tap: press and release in place -> one `tapped` emission, camera position unchanged
# pan: press, 12 drags of 25 px, release -> no `tapped`, position moved by about the drag / zoom
# pinch: two presses 200 px apart, spread to 400 px -> zoom doubled (clamped), no `tapped`
# blocker: press on a HUD group, drag, release -> no `tapped`, position unchanged
```

Connect to the camera's `tapped` signal, count emissions, and compare the camera's position and zoom before and after each sequence. Run it at every screen shape of the layout probe, with a notch inset, so the blocker rectangles move.

Reference implementation (Feed the Dragon): `tests/world_probe.gd` (real scene loop, badges, panels, scroll drag via `push_input`), `tests/core_probe.gd` (rules), `tests/soak_probe.gd` (invariants), `tests/lifecycle_probe.gd` (close and reopen), `tests/layout_probe.gd` (screen shapes), `tests/showcase.gd` (visual captures), `tools/run_probes.ps1` (runner, editor-open check). Growing Kingdom keeps the same probe set (with `tests/capture.tscn` for visual captures and `tests/balance_audit.tscn` outside the suite).

## 127.5 Probe hygiene and races

Defects that were in the probes, not the game, and the habits that prevent them:

- **Give every awaited probe a watchdog.** A script error inside an awaited coroutine stops it silently; the probe then waits forever instead of failing. A real-time watchdog prints FAIL ("timed out: a check stopped with an error") and quits.
- **Walk the real path to a gated state.** When a feature gains a precondition (Prestige after the first defeat), every probe and debug preset that reached the feature directly breaks; reach it through the real precondition (a real defeat), not by setting the flag, so the probes keep testing what players do.
- **Wait for UI to settle before tapping or measuring.** A tap in the frame a button becomes enabled, or while a layout animation runs, is flaky; wait for the panel's reveal (section 16.3) and for the UI's refresh interval before reading UI state that a periodic tick updates (four frames at 60 fps is less than a 0.12 s refresh).
- **Check exact restoration before the game resumes.** A reload probe that counted units after the main scene had simulated a few frames failed only under CPU load (a unit finished training or died meanwhile).
- **Do not let a check depend on where an earlier section left the camera or a panel;** derive the case from state (find a blocked gap in the placement overlay instead of hoping the preview starts next to one).
- **Hide editor-only overlays.** An editor plugin that adds a runtime autoload (a screenshot tool's panel, a debug console) is built whenever the project runs from the editor binary, and headless probes are such runs; its panel caught the world probe's synthetic taps. At the start of every probe that drives the real scene, and of capture tools, hide the canvas layers of known developer autoloads with a small shared helper, rather than removing the tool or weakening the probe.
- **PowerShell and Godot user arguments:** a script that forwards arguments can lose a bare `--` (PowerShell's own end-of-parameters token) and turns an unquoted `--look=1,2` into an array. Build the argument list as an array literal (as `run_probes.ps1` does) or call Godot from a POSIX shell.
- **Gate first-launch rewards on real play,** and test a first launch reopened hours later: an offline reward computed on a brand-new profile appeared next to the onboarding chooser.
- **Probes refuse to touch the real save:** every probe and capture requires `--save-path=user://<name>.json` (section 113). A probe that "resets the save, back it up first" will eventually destroy a real profile: Everfort lost a desktop save this way. Enforce it in the save service, not in probe discipline. The service picks a disposable sandbox path in `_init()` whenever the process was launched on a `res://tests/` entry point. Every file operation resolves through one guard that quits with a distinct exit code (2) if the path is outside the sandbox. Each probe asserts the sandbox as the first line of `_ready()`. One isolation probe proves the guard works: a child process tries the production path and must exit with code 2, a source scan checks that every probe has the guard line, and the production file's existence and modified time must not change. The probe only checks those two things and never opens the file (Everfort: `SaveService.assert_probe_save_isolated()`, `tests/probes/save_isolation_probe.tscn`).
- **Clean up transient UI a section caused.** A timed card one section raised (an enemy introduction shown for a few real seconds) covered a later section's button only when the run reached it quickly; the later tap failed with the button visible and valid. A section that triggers such a card dismisses it. Find it through its host's reference, not by name: a node added while a same-named one is still queued for deletion gets an engine-made name (and `find_child` sees only owned nodes unless `owned` is false). Bisect an order-dependent failure by running a subset of sections (`--only=a|b`).
- **A tap aimed at an object can be taken by a unit standing in front of it** (a worker gathering the nearest tree). Choose a target the pick test confirms is clear rather than the nearest one.
- **Scroll a target into view before tapping it when its content is random.** A rolled offer (three cards drawn per run) changes the text and so the layout: one long card text pushed every card's button below the list's scroll edge and the probe's tap missed only in the runs that drew it, a "flaky" failure for weeks. Force the worst-case content once to reproduce it, then bring the control into view (as a player scrolls) before the tap.
- **A runtime error inside a synchronous test ends it early and can still read as a pass.** Godot stops the function at a script error (Growing Kingdom: assigning an untyped array literal to a typed `Array[String]` field); the harness printed "ok" for the section because none of the checks that ran had failed, and the checks after the error never ran. Treat any `SCRIPT ERROR` in a probe's output as a failure (scan the log, or count errors in the harness), and assign typed arrays with `assign()`.
- **A JSON round trip turns integers into floats.** A saved record compared after reload (`{"rival": 34}` against `{"rival": 34.0}`) is unequal, and a typed comparison downstream may misbehave. Normalise each saved record's fields to their types in the loader, and let probes compare the loaded record with the original.
- **A rule change can remove a probe's scaffolding.** Probes that parked soldiers with a Move to build a stall broke when Moves became temporary (they now end after idle time). When an order, timer or state becomes self-ending, search the probes for every place that used it as a fixture, and keep the fixture alive explicitly (re-issue it on its end event) rather than weakening the new rule.

Reuse (Growing Kingdom): `tests/probe_env.gd` (`hide_dev_overlays()`), the watchdog in each probe, `tools/run_probes.ps1`.

---

## 127.6 Fog and map-discovery acceptance matrix

Use isolated saves and deterministic map fixtures. These are required checks for a game implementing section 117.9, not results claimed for the current project.

| Case | Assert |
|---|---|
| Fresh map | Only intended starting vision/public landmarks are exposed; no one-frame full-map reveal |
| Movement and fast movement | The expected cells become explored; sampled movement leaves no unexplained gaps; camera-only motion reveals nothing |
| Overlapping sources | Union is correct; death/removal of one source does not remove another's current sight; explored cells remain |
| Ineligible actors | Dead/resting/queued actors, inventory previews and dragged portraits do not reveal cells |
| Optional occlusion | Chosen wall/corner behavior is deterministic; walkability alone does not decide visibility |
| Teleport / map switch | Destination vision is recomputed immediately; no reveal along teleport path or discovery copied from another map id |
| Knowledge ranks | Rank 0/1/2 follows configured hidden/unknown/specific policy; upgrading never exposes an undiscovered location |
| Information leaks | Hidden entities have no pickable marker, tooltip, name, HP, auto-locate result or unintended counter/effect disclosure |
| Remembered moving entities | Marker is hidden or explicitly last-seen, unless a documented live-tracking upgrade permits otherwise |
| Depletion / death / respawn | Marker and knowledge updates follow the declared memory policy without granting hidden live information |
| Save / reload / revisit | Exact explored state and required knowledge persist; current vision recomputes from actors before presentation |
| Reset / Prestige / offline | Each follows the documented lifetime table; settings remain independent; offline income does not explore terrain |
| Invalid/older saves | Out-of-range cells, malformed masks, unknown map ids and layout-revision changes have bounded, explicit handling |
| Minimap / expanded map | Same discovery and markers; square and non-square maps retain proportions under zoom, pan, safe areas and resize |
| Input / pause | Fog does not swallow world input; hidden markers cannot be clicked; opening/panning maps while paused does not explore |
| Exploration percentage | Correct discoverable-area denominator, safe zero-area case, same value on every surface |
| Performance / lifecycle | Worst-case map/roster/radius and repeated openings stay within measured target-device budgets; subscriptions/masks do not accumulate |

Combine state assertions, actual pointer/touch input and rendered checks. A source scan or screenshot alone cannot establish hidden-information safety. Device performance, finger interaction and soft-edge readability remain unverified until measured on physical hardware. Record the selected mode, exceptions, reset decisions, fixtures and evidence with the implementation.

---

---

# 128. Text hierarchy and card anatomy on phones

Growing Kingdom's UI improved every time text was reduced **without reducing information**: the decision value got bigger, the paragraph got shorter, and states, icons and warnings took over what prose had been explaining. Players on a phone read the big number and the button, not the paragraph.

## 128.1 The card's hierarchy

```text
Title                              <- name (and tier)
+5 Population                      <- the decision value: large, colored, computed
Raises your population cap.        <- one supporting line
Wood 120              Need more Wood   <- cost and state on one fixed row
[Place]                            <- the action, in the card's last row
```

- **The primary value is computed, never written.** A small text module reads the effective getters the simulation uses (Growing Kingdom: `BuildingText.benefit(type, tier)` over `RunState.building_effect()`), so a permanent upgrade or a tier changes the number on the card. A probe compares the card with the getter, including after an upgrade.
- **One concise description.** Shorten prose, never decisions: costs, requirements, block reasons, anything irreversible (Prestige, Hard Reset, a permanent choice) and unusual mechanics stay explicit. If a short line becomes ambiguous, it was cut too far. A card explains a mechanic its name does not (Growing Kingdom's Salvage cards say in one line what Salvage recovers).
- **Cost and state share one row; the action keeps one place** (sections 128.3, 129.2). Put the button in the card's last row so buttons align across a row of cards.
- **Detailed explanation belongs in an info or reference surface** (section 16.1), not on an operational card. Remove messages that repeat what the screen already shows.
- Long reasons keep their full form where there is room (toasts, confirmations) and a short form on small cards.

## 128.2 Less text, not smaller text

- **Never solve excessive copy by shrinking text** below comfortable phone readability (section 19). Cut it, restructure it, or move it to a reference surface.
- **Spend the recovered space on size, selectively.** Raise the values and actions (Growing Kingdom: HUD amounts 36 px, card values and tutorial actions 40 px at a 1080 px canvas), not the body text; a global font increase makes every panel larger without making anything clearer.
- **Fit, don't clip.** A primary value steps down to a floor size (Growing Kingdom `UiKit.fit_line()`) before it would clip; the layout probe fails on clipping at every screen shape.
- **Prefer hierarchy, icons and state indicators to tiny text.** A state the player meets repeatedly gets an icon (section 128.4); a value gets size and color; a warning gets a fixed place.
- Treat a starting type scale as the floor for panel-heavy games (section 125.9).

## 128.3 Fixed rows: a warning never changes a card's height

A card whose warning line appears and disappears changes height, moves the button the player is aiming at, and makes a list jump. Warnings such as

```text
Need more Wood
Unavailable while paused
Requires Barracks T2
```

must appear in a place that already exists. Put the reason on the cost's row:

```text
Title
Description
Cost                         Warning
```

- One helper builds a **row of fixed height**: the cost on the left, the reason right-aligned in a slightly smaller type, one line. Mark the row (metadata) so probes find every one, whatever it is named.
- **Short, decisive words** from a mapping of the state owner's reasons ("Needs Wood" becomes "Need more Wood"), a **compact form** for narrow rows ("Paused", "Need Wood", "Max 1"), and the font stepped down to the readable floor before switching form; the full reason remains the tooltip and the text of every toast. Fit by measuring the text against the label's width, and re-fit when the label is resized (a card laid out after its last refresh kept a form chosen for the old width). Never let an ellipsis cut a reason at a supported screen shape.
- Narrow cards (two per row on a phone) may need a compact cost row too (smaller icons and numbers) so the reason keeps its room.
- **Audit every line of a card that can change**, not only the one reported: Growing Kingdom's House card still moved after its upgrade row was fixed, because the Recruit row above it had its own appearing reason, and a training queue line appeared and vanished as units queued and finished. Keep such lines always present (an idle text) instead.
- A neutral note may use the same place when nothing blocks ("Built 2 / 4").
- **Probe it by geometry:** record every card's and button's rectangle, change affordability, pause, resume, and require identical rectangles; at every screen shape, require each reason to fit untrimmed on one line inside its row.

Reuse (Growing Kingdom): `UiKit.cost_status_row()`, `show_status()`, `short_reason()`, `compact_reason()`; `world_probe` "warnings beside the cost: cards keep their height", `layout_probe` status rows at every shape.

## 128.4 Icons for repeated concepts; one icon per state

When the player should recognise a concept or a state without reading (a resource, a task, a stance), give it one icon and use it on every screen that shows or sets it.

- Build the icons from the asset pack's own art (a script that composes them, checked in with its output), and prefer a grammar the player can learn from parts: Growing Kingdom's shield guards, sword attacks, green arrow leaves the Castle (Defend = shield, Intercept = shield + arrow, Pursue = sword + arrow).
- Do not reuse a picture that already means something else in the UI (the plain shield was already the Castle's dock icon).
- One lookup function is the only source; tag each control with the state it shows, and let a probe walk the whole tree to assert that no control shows another state's picture.
- Prefer words to icons when the icons would be ambiguous (two units sharing one portrait).
- Draw marks and carets instead of relying on symbol glyphs: a font without them shows boxes on some devices.

Reuse (Growing Kingdom): `UiKit.stance_texture()`, `tools/pack_ui_textures.py` (`stance_icons()`); `world_probe` "one icon per stance, everywhere".

## 128.5 When a word changes meaning, relabel everything that used it

Making a card's stance its "Command" left older text ("a command adds a buff") contradicting it, and a button still labelled "Command" that cycled buffs. When a player-facing word takes a new meaning, search every label and help line for it in the same pass, and make every enumerated setting of the card a direct choice (section 129.1), so none still cycles.

Reusable rule:

> Lead with the computed value, keep one short line, put the state beside the cost in a row that never moves, let icons carry repeated concepts, and move explanations to a reference surface instead of shrinking them.

---

# 129. Controls and action organization

## 129.1 Choose the control by the decision

| The player is choosing... | Control |
|---|---|
| one of several **named states** (a task, a stance, a unit type, a buff, which slot) | a dropdown that shows every option at once |
| a frequent direct order on a selected object (send this worker to Wood) | a one-tap grid of icon buttons |
| a **continuous** value | a slider (section 78) |
| a **binary** setting | a toggle or checkbox |
| a count per item type under a budget | a stepper per type (section 114) |

**Never cycle through invisible choices.** A button that cycles makes the player tap past everything they do not want, and hides what the options are. Tap, see all options, tap one:

- A compact menu anchored to the button (below it, else above it, always clamped to the safe area even when the button is partly scrolled away), each option with its icon and short name and a mark on the current one.
- A full-screen invisible catcher closes it on a tap outside **without passing that tap on** (it must not also select something in the world), and the camera's blocker must report it. Escape and the platform Back close it; on Android turn `quit_on_go_back` off while it is open and restore it after. When it closes, stop catching input at once: it lives until the end of the frame.
- Options come from the game's own list of what is allowed now, never a hardcoded list. Something temporarily impossible follows the game's convention: an assignment is a standing preference, so Growing Kingdom keeps a task that cannot run now selectable, with a few words saying why ("Storage full"); a unit or buff not unlocked yet is listed but off, naming what unlocks it.
- One menu component serves every short choice (tasks, units with portraits, stances, buffs, "which slot?"), and every enumerated setting of one card gets the same treatment; a single cycling button left beside dropdowns reads as a bug.

Reuse (Growing Kingdom): `TaskPicker`, `TaskButton`; `world_probe` "task dropdowns", "Castle Command: a stance dropdown", "Train cards: the unit dropdown".

## 129.2 One stable place for the primary action

- Each card or panel has one primary action in a fixed position (the card's last row, a pinned header), so the player's thumb learns where it is.
- Buttons are sized for the widest label they can ever show, so a changed value never reflows the row (section 16.3).
- Destructive actions stand apart (a red danger style, a confirmation that names what is lost); their consequences sit on a line of their own (a refund line beside a short Demolish button).
- On a selected object, show the few actions relevant to it; everything else is one tap away on the surface that owns it (section 16.1).
- Touch targets meet the touch minimum both ways (sections 14.3, 125.9).

## 129.3 Identity and state are visually separate

A unit card shows **who** (the portrait, the unit's identity) and **what it is doing** (its command or state). Mixing them makes both harder to read: Growing Kingdom's stance badge on the portrait's corner read as part of the unit.

- Show the state as a small tag in a fixed corner of the card (Growing Kingdom: the top-left corner, on a dark tag with a gold edge), apart from the portrait, once per card.
- Controls that **set** a state (a stance dropdown, stance buttons, group orders) carry the icon on the control itself; they are the choice, not the card's state, so no card shows the icon twice.
- **An icon on a control counts in its minimum size.** Godot's `expand_icon` takes only the button's spare width: in a grid of stretched buttons it shows, in a row that wraps (`HFlowContainer`) it gets no width and vanishes. Use a fixed icon (`expand_icon = false`, `icon_max_width`). Growing Kingdom's Multi-Select stance commands showed text only for several versions before a capture caught it.
- **A new state's icon must read apart at badge size.** Compose it from the same grammar, but check it at the smallest size it is shown beside its neighbours: Growing Kingdom's first Standby icon (Intercept's arrow turned around) could not be told from Intercept at 44 px.
- Probe the corner and the gap to the portrait at every screen shape.

## 129.4 A disabled action always explains why

- The reason comes from the state owner's block-reason function (section 123.3) and appears in a fixed place: beside the cost (section 128.3) or in an always-present status line. Never add or hide a line for a warning.
- The rule is enforced where the state changes, not where the buttons are: the intent re-checks its block reason, so a probe, a fast double tap or another surface cannot bypass it (section 26.1 for the pause lock).
- A tap on a blocked control may toast the full reason; a button that silently does nothing is a defect (Growing Kingdom found an End run button that closed its message and did nothing while paused).

## 129.5 One edit rule for every surface that edits the same list

An ordered list without duplicates (worker priorities, a loadout, a build queue by type) is often edited from several surfaces: a dropdown per place, a one-tap "make this first" grid, a group command, a default editor. Growing Kingdom had three rules for that one edit: Gold / Food / Build with Build picked for place 1 became Build / Food / Gold in the dropdown and Build / Gold / Food on the card.

- **Put one function on the state owner** (`list_after(list, place, value)`; Growing Kingdom `RunState.priorities_after()`) and route every surface through it, group commands applying it to each member's own list.
- **Never refuse a value because it is used elsewhere; swap.** The value lands in the place the player edited; the value that was there moves to the chosen value's old place.
- **Picking the value a place already holds is a no-op:** return before any re-plan, so nothing moves, no claim changes and no random number is drawn.
- **Decide what an empty place means once.** A list without gaps closes up: a value moved into an empty place settles at the end, and the first place can never be emptied. Say so in the design.
- **A control that names a standing setting saves on the pick.** Growing Kingdom's "Default for new Villagers" edited a draft that only "Apply to all" saved; players changed it, closed the panel, and saw it (and every recruit) back on the old value. Save the setting when it is chosen, read it back from the state owner, and keep "apply to everyone now" as a separate action.

## 129.6 Multi-select, group commands and bulk changes

- **Selection is a core control; persistent groups are the progression.** Growing Kingdom first gated multi-select itself behind a permanent upgrade (Squad Command) and learned (v0.14) that selecting several units is basic control the player needs from the first army: gating it made the army clumsy without making the upgrade feel better. Keep selecting (box, same type, add and remove) and world commands free; let the upgrade give *saved* groups and their number. Rename the upgrade's description, keep its price and levels.
- Touch first: a box by long press and drag (section 121.3), a double tap for "every visible unit of this type", and an add mode (tap to add or remove) as the touch stand-in for Shift; plus "select all", "all of this type" and "all workers" shortcuts; then one command applies to the whole selection.
- **A temporary selection may mix kinds** (workers and soldiers); only saving it as a group applies the compatibility rule, with its reason, the selection kept as it was. A world tap gives each member the command it can perform (workers work, soldiers move or attack), leaves the others out of it, and keeps the selection; when nobody can do anything with the tap, it falls back to ordinary selection rather than being swallowed.
- A command applies the same single-object rule to each member (the one edit rule, the immediate reassignment of section 115.4), through the same function, so each member changes exactly once (dedupe the ids: a selection may name a member twice).
- A world tap with a selection carries each member's own order (Growing Kingdom: a node or construction sends the selected Villagers, an enemy the soldiers that can attack, ground moves everyone, each to a slot of one formation). Pass each order only the members it concerns, through the same state functions a single unit uses.
- Refuse an incompatible mix with a reason (Growing Kingdom: "Villagers and soldiers cannot share a group"), never trim it silently.
- Saved groups (squads) keep membership valid: the dead and removed leave automatically; an empty group disappears.

**One configuration surface: the creation card is the bulk template.** When entities have a mode with its own configuration (section 8.2), the card that configures new entities also configures everyone, through one explicit button:

```text
New worker                     [Manual] [Auto]
[Build v] [Wood v] [Gold v]          [Apply to all]

choosing on the card   saves the setting for new entities; changes nobody already working
Apply, Auto shown      every entity becomes Auto; each keeps its own hidden manual configuration
Apply, Manual shown    every entity becomes Manual with the shown configuration
```

- **Do not build a second bulk card.** Growing Kingdom first had a "New Villager [Manual][Smart]" card and an "All Villagers [Manual][Smart]" card with its own draft priorities, its own Apply and a mixed-mode line: two near-identical Manual / Smart surfaces holding two different lists. The Android follow-up corrections removed the bulk card and made "Apply to all" apply exactly what the New Villager card shows. One surface, one meaning: what you see is what a recruit gets and what Apply gives.
- **Selecting on the card is not a mutation of anyone.** Picking a mode or a slot value saves the standing setting for new entities (section 129.5) and changes no existing entity; only the explicit Apply does, through one state-owner function that reads the setting, checks the gameplay lock and returns a reason (Growing Kingdom: `RunState.apply_new_villager_config()`). A destructive bulk change triggered by merely choosing a mode would erase every individual configuration the player built, with no confirmation and no way back.
- **Individual Manual restores; bulk Manual replaces.** Switching one entity back restores its own configuration; Apply with Manual shown is an explicit reassignment with the shared configuration. State both in the design, so neither is later "fixed" into the other.
- **Keep the card still across modes.** With Auto shown the slot controls hide, but the line keeps its height and Apply stays in place, so the pinned header does not move (section 16.3).
- **Bulk applies the single-entity rule to each member,** through the same functions (the immediate reassignment of section 115.4 included), so each member changes exactly once.

## 129.7 A permanent choice: options, consequence, confirmation

When a building or unit must make a choice that can never change (Growing Kingdom: each Monastery's Mage or Healer specialty):

- Make the unchosen state explicit and visible: the object does nothing that depends on the choice yet, the world marks it ("Choose: Mage or Healer") and a toast says a choice is waiting (section 18.6).
- Present the options on the object's own card, each saying what it gives (what it trains and researches), and confirm with a dialog that says it is permanent. There is no respec path anywhere.
- Afterwards show the choice where the object is identified: a ribbon in the world, the card title ("Mage Monastery").
- Store the choice on the object's record (saved with the run) and derive everything from it (what it trains, which research it offers), so every surface agrees.

## 129.8 A deferred decision keeps a visible way back

A modal that offers "Stay", "Keep playing" or "Later" for a decision that must still be made (an end-of-content Ascension, a pending Prestige) closes the modal, not the decision. A badge on a menu the player has no reason to open is not a way back: Growing Kingdom's players stayed at the final wave and felt stranded, although Castle > End run existed.

- While the decision is open, show a persistent, one-tap entry on the main screen that reopens **the same** decision screen, as often as needed.
- Derive its visibility from state (the victory run is in progress and the decision screen is closed), so it survives a reload and disappears the moment the decision is made.
- Opening it is navigation and stays available while the game is paused; the decision's own action obeys the gameplay lock (section 26.1) and shows the reason instead of failing silently.

## 129.9 Management panels: validated recipes

| Panel | Recipe |
|---|---|
| Worker list | pinned header (population, Recruit with one status line, the default task saved on pick and "Apply to all"); one row per worker diffed in place; one dropdown per priority place (sections 16.3, 129.1, 129.5). With an automation mode unlocked, the default card becomes the "New worker [Manual][Auto]" card, the one configuration surface whose Apply to all gives what it shows to everyone, and each row gets the same switch (sections 8.2, 129.6). Its slots sit on one line at one width with Apply to all on the right (section 16.3) |
| Worker card | status, carry, a one-tap task grid that sets place 1 by the one edit rule |
| Army / training cards | the unit from a dropdown with portraits, quantity, command (stance) and buff from dropdowns, cost and state on one row, Assign to a slot from the card (section 130.1) |
| Base command (Castle) | the same cards, the deployment program, base upgrades; the Prestige entry while an offer waits |
| Building context | title with tier, the computed benefit, the next tier's gain with its gate and cost row, queue and training lines always present, specialty choice when waiting, Demolish apart |
| Research | each research building's current job, then the topics for the chosen building, each with the reason beside its cost ("Healer Monastery only", "Researching at the other Monastery") |
| Permanent upgrades | grouped by the player's mental model, cards that update in place so buying keeps the scroll position |

Reusable rule:

> Choose named states from a dropdown and never by cycling, keep the primary action in one place, show state apart from identity, explain every disabled action in a fixed place, give one edit one rule on every surface, and never let choosing a bulk mode overwrite everyone's setup without an explicit Apply.

---

# 130. Army management: production, slots, stances and squads

Lessons from Growing Kingdom's army layer: the player designs, produces and commands an army that fights on its own, with automation layered on top (section 8.1). Values quoted are that game's.

## 130.1 Saved cards versus active slots

Separate **what the player has configured** from **what is in play**:

- A **saved card** is a configuration: one unit type, a quantity, a command (the stance its units take), an optional buff, and the resulting cost and population. One unit type per card keeps cost, production and automation readable.
- An **active slot** is a place on the deployment rail that holds one saved card. Tapping it trains the card; automation addresses slots by number.
- They are **two capacities**, upgraded separately and worded apart ("Saved Train Cards" vs "Deployment Slots"). Saving setups is cheap convenience; a slot in play is power, priced accordingly.
- Slot position has **no implicit order**: it is an address for manual and automated commands, nothing more.
- Assign from the card list: each card has an Assign action that asks which slot when there are several (showing what each slot holds) and shows the slot it occupies once assigned; an empty slot on the rail opens that list. One list, no separate slot editor with a cycling "Change" button.
- Cards are profile data (the player's doctrine) and survive runs; their capacity resets with its layer.

## 130.2 Production: buildings, queues and population

- Units are trained at buildings, one at a time per building, in parallel across buildings of a kind; a card sends its units to the trainer with the shortest queue.
- Pay when queued; a queued unit **reserves its population** (section 115.6); cancelling refunds exactly what the job stored.
- The building's tier when training **finishes** sets the unit's quality; units already in the field keep the profile they spawned with (snapshot at spawn).
- Trained units walk out of their building to the field, so production is visible.
- A card shows how many of its units are still in training and, when it cannot train, the exact reason (resources, population, no building that trains the unit, the building's specialty).

## 130.3 Unit cards

A unit card answers: who is it (portrait and name, tier palette), what does it cost, how many, what is it doing (state tag, section 129.3), what is it doing it with (attack type: "Magic damage 10 every 2s"), and what protects it (HP, and a shield on its own line, never added to HP).

## 130.4 Stances need mechanically distinct behaviour

Stance names must map to different targeting and movement rules, not to different radii of one rule; otherwise the player cannot tell them apart and one dominates. Growing Kingdom's four:

| Stance | Behaviour | What it is for |
|---|---|---|
| **Defend** | a hard defensive leash: rests at its post near the base, takes on what attacks the base, what attacks it or a guard near its post, and what enters the base's threat area; never passes the leash | protect the home area |
| **Pursue** | waits near the base; once committed to a target (the nearest anywhere) follows it with **no leash** and never switches until it dies; then the next; then home | finish what reaches the field |
| **Intercept** | advances to a forward line and meets waves where they appear, spreading so each enemy draws few interceptors | proactive forward engagement |
| **Standby** | stands in reserve behind the base, off the battlefield, out of every fight; defends the base as Defend once it falls to 30% during a wave | keep an army for later without ordinary waves eating it |

Rules that made the guard stance (the hardest one) work:

- **Hysteresis, not one radius.** A single radius oscillates against ranged enemies standing just outside it (acquire, step out, drop, return, reacquire: 60 of each in one probe). Use increasing distances for acquiring, keeping and abandoning, re-evaluate on a retarget interval, never every frame, and switch only to a clearly nearer enemy (Growing Kingdom: a 40 px margin). Keep the engagement as saved unit state; a stance change clears it.

```text
take on       inside the threat area (every spot an enemy can strike the base from), or an attacker of a guard within the answer reach
keep          while the target stays inside the hard leash
let go        the target passes the leash, or the guard itself does (it walks home, taking nothing new)
switch        only to a clearly nearer threat, or to an uncovered threat to the base
afterwards    walk back to the post
```

- **Measure from what the guard protects**, not from a point: Growing Kingdom measures distance to the Castle's wall line widened to the guard's posts. A radius around one point covers the whole field depth below it; its first guard could be drawn across most of the battlefield.
- **Bound the distances by the field:** the threat area covers every spot an enemy can strike the base from (checked against the roster's longest reach in a probe), the answer reach a little more, and the hard leash stops short of the enemies' spawn band. The leash binds the guard itself.
- **Count the sustainers.** An enemy healer or warder that keeps a threat alive from just outside the area stalls a wave forever if the guard ignores it. Stamp the sustainer when its heal or ward lands on a current threat; for a few seconds after, it counts as part of that threat, within the answer reach and never past the leash.
- **Protect the base first: priority and coverage, never a dogpile.** Protecting the base needs both: base threats come before local fights, and each base threat gets only the guards it needs. Without coverage, one archer shooting the walls pulls the whole army off the enemies beside it; without priority, guards keep their local fights while the base burns. One **coverage pass** at the start of every tick, before any guard acts, decides who answers:

```text
coverage pass (start of every tick)
  duty = {}                                        derived each tick from saved unit state, never saved itself
  threats = enemies that are base threats now
  need[threat] = requirement by tier               Growing Kingdom: 1 normal, 2 elite, 3 boss
  each guard already engaged on a threat           stays a responder (an engagement ends when its
                                                   threat dies or passes the leash)
  more responders than need?                       release the farthest, ties by id
  for each uncovered threat, those striking the base first, ties by id:
      while duty[threat] < need[threat] and a free guard exists:
          take the nearest free guard              a guard in a local fight counts a little further away
          save its engagement as base duty on that threat; duty[threat] += 1
target choice (every other guard)
  skip a covered threat unless it is attacking this guard
```

  - *Define the threat once:* a base threat is an enemy going for the base inside the threat area or striking it, plus its sustainers; an enemy fighting a guard is a local threat, even inside the area. Put the definition in one function every rule reads.
  - *Duty is a saved engagement:* kept while the threat lives inside the leash, even after it turns on its responder, and **never switched** to another threat (that would uncover the first). A reload resumes the same assignment; the duty counts are rebuilt from it.
  - *Coverage is a goal, not a squad:* a lost responder is replaced by exactly one guard on the next tick; a threat whose requirement is met draws nobody else.
  - *Deterministic:* fixed order and ties by id, so the same state always assigns the same responders, which keeps save/resume, bots and probes reproducible.
  - *One writer:* only the coverage pass hands out base duty; there is no second path where every guard answers the walls.

  History: Growing Kingdom first sent every guard to the walls (a pacing cost of 2.4 minutes), then shared them out with a per-guard distance cost, which still let one archer shooting the base pull a whole army off nearby enemies; the coverage pass replaced both (v0.11).
- **Guard AI is balance.** Each change re-runs the pacing bot and, for army questions, the composition audit (sections 112, 112.1). Growing Kingdom's hard leash fixed a wave-stalling stalemate and made Defend-only armies need more (it now fights near the base instead of camping the spawn); that trade-off is a design decision, so it was reported, not retuned.
- **Test the exact failing case on the real roster** (a ranged enemy outside the area, a healer sustaining an Elite), plus a save and reload mid-engagement.

**A reserve stance with an emergency override** (Growing Kingdom's Standby, v0.13):

- **Saved choice versus acting behaviour.** The player's stance is saved and never written by the simulation; behaviour reads one function (`acting_stance(u)`) that returns Defend for a reserve unit while the emergency holds. Mutating the saved stance to Defend would lose the player's choice and needs a second write to undo, which is where flip-flops and lost reserves come from.
- **Latch the override on a lifecycle, not on a sampled value.** One saved run flag turns on when the condition first holds during a wave (base HP at or below 30%, exactly 30% included) and turns off only when that wave ends; a repaired base mid-wave keeps it on. Per-frame sampling of HP would oscillate. A later wave that starts with the condition still true starts it again.
- **Make protection structural.** A reserve off the battlefield is excluded by the same `is_active()` filter every target choice already uses, rather than by a new exception in each enemy rule. A unit still walking back across the field is not safe and can be struck.
- **Walk, never place.** Changing stance turns the march around from wherever the unit is (field to gate, in through the base, to its spot; and back out the same way), so a probe can measure the longest step against the unit's speed. Reserve spots are derived each tick from an authored zone, never saved.
- **Arrive with a tolerance above the stop distance.** Moving "until within d" then testing `distance <= d` can leave a unit 4.0000001 px short forever; walk to within a smaller distance and accept arrival at the larger one.

Reuse (Growing Kingdom): `CombatSystem._defend_target()`, `_cover_castle_threats()`, `castle_threat_now()`, `covered()`, `is_castle_threat()`, `sustains_threat()`, `_pursue_target()`, `_intercept_target()`; `WorldLayout.castle_front_distance()`; `Balance.DEFEND_*`; `core_probe` "defend engagement", "Defend: the Castle comes first" (with the coverage scenes: one archer and thirty guards, three guards and two archers, elite and boss requirements), "Pursue commits"; for Standby `CombatSystem.acting_stance()`, `_route_standby()`, `_withdraw()`, `_assign_reserve_posts()`, `RunState._tick_standby_alert()`, `MapRegistry.reserve_rect()`, `core_probe` "Standby: the reserve and the Castle emergency".

**Direct orders are an override, not a stance.** RTS control of soldiers (move and hold, attack this enemy) sits above the stances exactly as a worker's direct order sits above its priorities (section 120.11): an order field on the unit (kind, spot, target id, saved), one state owner for giving and ending it (`command_soldiers`, `resume_stance`), and one behaviour function that serves it instead of the stance. Lessons from Growing Kingdom v0.14:

- **Never write the saved stance for it.** The card keeps showing the stance the player chose; "Manual · Holding" is the current command. Resume Stance ends the order; choosing a stance also ends it and takes over at once.
- **A move must stay where it was sent.** Arrival becomes hold: act only on what is already in reach, walk back if pushed, never chase and never walk home; otherwise the order looks broken (the unit reaches the point and returns to its post).
- **An attack order is a commitment:** no leash, no retargeting while the target lives; when it dies, hold where you stand. On load, a target that no longer exists becomes a hold, never a silent retarget.
- **Every autonomous path skips a unit under orders:** coverage assignment, spreading counts, reserve routing. One `has_order()` check in each, or the AI quietly takes the unit back.
- **Safety rules outrank the player only where the design says so** (Growing Kingdom: the 30% Castle emergency cancels orders on reserve soldiers and refuses new ones until the wave ends), stated in the design and enforced in the owner, never by hiding a button.
- **Where units may be sent is one function** (`command_area()`, `clamp_command_point()`), so a later map extension changes one rule.

## 130.5 Multi-select, squads and formations

- Per-unit stances and multi-select from the start; saved squads as the progression unlock (section 129.6 for the interaction and why).
- **One formation algorithm** for squads, a moved selection and any later army (Growing Kingdom: `Formation.offsets()`): role order (melee in front, ranged behind, support last, ties by id), the shape shifted whole into the commandable area before each slot is clamped, so a tap at an edge keeps the shape. A temporary selection moves in one compact default; formation upgrades choose among the squad formations, they are not needed to keep units apart.
- A squad stores members and its command (stance for soldiers, task for workers) and, for combat squads, a formation (line, block, spread as offsets around an anchor).
- Workers and soldiers never share a squad; membership stays valid as units die.
- **Friendly formations are never hard walls.** Pairwise separation that pushes every friendly pair apart turns a packed, standing line (Defend posts by the gate) into a wall: the standing units, pushed aside, walk back to their posts, and the pushes on a soldier trying to pass match its step forever. Make friendly occupancy soft: a unit moving by its own intent this tick and a standing one never push each other (it walks through, the line keeps its place); two standing or two moving keep their spacing, so units still settle apart on arrival. Add a progress failsafe (little net progress over a short window while moving -> pass through friendlies briefly), never a teleport, and leave enemy blocking alone. Reproduce it first with a probe: packed rows, then a Move, a squad Move, a focus attack and a stance's own advance across them.

## 130.6 Shields: a second durability pool

Growing Kingdom changed shields from timed buffs into durability, which read and played better:

- A shield has **no timer**: it stays until damage depletes it.
- Damage hits the shield first; what is left of a hit continues into HP (section 39).
- No regeneration by itself; a source that grants a shield again **tops it up to its own amount** (`max(shield, amount)`), never above, never stacked.
- Its remaining value is saved with the run.
- Show it apart from HP: a thin bar of another color over the HP bar (measured against max HP), and its own line on the unit card ("Shield 40 · lasts until broken").
- Apply one rule to every shield in the game, the enemies' included: two lifetimes would look the same and behave differently.

## 130.7 Support units: cadence, recipient eligibility and anti-stacking

Support units evaluate while moving (section 79) and scale with a share of enemy growth (section 7). A guard-stance healer keeps the guard's leash. An enemy healer is a target the guards must be able to reach (section 130.4).

**Support power has two controls, and balancing only the first fails once the player owns several supporters:**

```text
caster cadence          how often one supporter acts         its own interval
recipient eligibility   how often one target may receive     a lockout timer on the target
```

With only a caster interval, five healers on one tank heal it five times as often: the tank becomes effectively immortal, and the number of healers, not the composition, decides fights. Growing Kingdom's Healer (16 every 2 s) did exactly that in Android testing; it became 10 every 6 s plus a 10-second **Recently Healed** lockout on the recipient, later shortened to 5 s after more device play (the numbers are that game's; the structure is the lesson).

- **Put the lockout on the recipient,** as a timer in the unit's saved state, counted down in **simulation time** by the same tick that runs combat, so pause stops it, game speed scales it and a reload keeps it. One writer: the direct support action sets it the moment it lands. A new heal sets it back to the full duration; nothing stacks.
- **Eligibility is a targeting filter, so supporters redistribute.** Target selection skips ineligible recipients; a supporter whose current target becomes ineligible (another supporter reached it first) or is healed up drops it and picks the next valid one at once, without waiting for its retarget interval. With no valid recipient it waits (at its post, inside its leash); waiting is not an action.
- **Scope the lockout to the mechanic it balances.** It blocks only direct support heals. Self-heals and regeneration (Growing Kingdom's Lancer Rally), the mass part of a supporter's own special (Sanctuary heals everyone) and any other recovery neither check nor set it. A lockout that blocked every heal would silently weaken unrelated units.
- **Count only successful actions.** An "every Nth action" special (Growing Kingdom: every 4th successful heal is Sanctuary) advances only when an action actually lands; a search that found nobody, a wait or a walk does not, and the cadence cooldown starts at the same moment as the effect, not when the supporter merely looks.
- **Offensive speed does not drive support cadence unless the design says so.** A global "+Attack Speed" that also shortened the heal interval made support scale with an offensive investment and multiplied the stacking problem. Growing Kingdom's support interval ignores Troop Attack Speed, while support-specific research (Field Medicine) raises the amount; a game that wants faster support gives it its own named effect, priced as such.
- **Know which control binds.** The two timers interact: a lockout longer than the cadence also paces a lone supporter on a lone target (Growing Kingdom at 10 s: a lone ally healed every 10 s, not every 6 s); a lockout shorter than the cadence leaves one supporter paced by its own cadence, and the lockout only limits how often several supporters together may treat one target (at 5 s: at most once per 5 s). Say which regime the numbers put the game in, and write probes for that regime rather than the previous one.
- **Make the lockout visible on the recipient.** Players watching supporters skip a wounded ally read it as a targeting bug. Show a small mark over the recipient while the lockout runs (Growing Kingdom: the heal's green cross struck through in red, on a dark disc, above the health bar), drawn from the same predicate targeting uses (`can_take_heal()`), refreshed in the frame the simulation steps so it appears and goes with the state, removed with the unit, never shown on enemies. Keep it small for large armies, and make it name only the direct-support lockout (a crossed heal symbol, not a generic "immune" sign), since other healing still reaches the unit.
- **Restate nothing.** The unit card, Stats and the special's description read the same definitions the simulation uses (section 17.1), so a retune cannot leave the old amount or cadence on screen.

Probe: one supporter's cadence; the lockout's duration in simulation time under pause and game speed (eligible again on the exact step it ends); the mark shown exactly while the lockout runs, frame by frame; several supporters on one wounded group spreading to different targets; supporters waiting when every wounded ally is locked out; Attack Speed leaving the support interval unchanged; the Nth special counting only landed actions; unrelated healing unaffected and never setting the lockout; the lockout surviving a save.

Reuse (Growing Kingdom): `CombatSystem._ally_heal()`, `_wounded_ally()`, `SimUnit.healed_timer` and `can_take_heal()`, `Balance.HEALER_LOCKOUT`, `RunState.ally_stats()` (the support interval), `UnitVisual._draw_no_heal()`; `core_probe` `_test_healer_lockout`; `android_ui_probe` `_check_heal_timer`.

## 130.8 Specialization buildings and per-building jobs

- A building that can specialize chooses once, on its card, with a confirmation (section 129.7); it then trains only its specialty's unit and offers only its specialty's research.
- Several buildings of a kind may each run their own job (research) while the results are shared by the run (section 109); one topic runs in one place; demolition refunds a job by progress.

Reusable rule:

> Keep configuration apart from what is in play, produce visibly with population reserved at queue time, give each stance its own rule rather than its own radius, bound a guard by what it guards and cover base threats by requirement, treat shields as durability, and limit support by recipient eligibility as well as caster cadence.

---

# 131. Soft counters and combat specialization

## 131.1 Raw stat escalation does not create army diversity

When one cheap generalist unit answers every enemy, tougher late enemies only raise the count of that unit. Growing Kingdom's audit (section 112.1) found Warrior-only armies viable to the end: area cleave made the Warrior good against late swarms, enemy traits were type-neutral (armour cut every attack alike), and late population let one unit win by numbers. Specialists were cheaper only at a few Boss waves.

The fix is soft counters: enemy traits that some player options answer better, so specialization pays without making any option useless.

## 131.2 Make a defence trait a matchup, not a flat cut

A trait that cuts every attack alike ("takes 35% less damage") asks for more of the same army. A matchup by attack type turns it into a question the specialists answer:

- **One table** in the balance data: the share of the trait each attack type meets. Combat, the reference screen and the lesson all read it; nothing restates the numbers.
- **Every hit names its type, with no default.** Make the type a required argument of the one damage function, so a new damage source that forgets it fails to compile instead of silently meeting the full cut (or none). Specials keep their unit's type.
- **Derive the type from what the unit already is** (its role), so nothing new is saved and a saved run resumes under the rule.
- **Favour the specialists instead of nerfing the generalist:** the generalist's numbers stay identical, and a probe says so.
- **Put it in the damage order** (section 39): raw → attacker bonus → the target's reduction → the trait, by the hit's type → shield → HP. Decide what a shield does against the type that ignores the trait (it still absorbs).

Growing Kingdom's table, as an example of the architecture (the values are that game's):

```text
melee                      -> meets all of an enemy's armour
arrows, towers, the castle -> meet half
magic                      -> ignores armour
```

## 131.3 Preserve the specialists' trade-offs

A counter must not make one type universally superior. In Growing Kingdom magic ignores armour but Mages kill slowly (their armies cleared fewer waves in the same time than Warriors with Archers), and Archers are fragile. Check after each change that the cheapest army still differs by encounter, and that no type wins every cell. Compute value per resource: when an option is an order of magnitude behind (Growing Kingdom's Towers, about 22 times less damage per resource than a Warrior), a percentage matchup cannot make it matter; that needs its own change.

## 131.4 Teach the counter when it first matters

Teach the rule on the first encounter with an enemy that has the trait, on the existing introduction card, once, decided in state (section 18.6); the player then sees it every time in the reference surface.

## 131.5 One compact trait strip in the reference surface

- Show a trait as one strip in the reference screen's existing tile grammar, built from the same table: the value, a one-line caption that says what it means ("how much of it each attack meets"), then one tile per attack type (Full, Half, Ignores).
- Remove the old single number that implied the old rule; update the descriptions that stated it.
- Name the attack type on the player's unit cards, so the lesson's words map to the units the player owns.
- Probe the geometry at every screen shape, on every card variant that can carry it.

## 131.6 Audit by representative encounter composition

A matchup changes only the fights where the trait is present. Judge it with a controlled audit by wave and army (section 112.1), reading each checkpoint against the trait's share of that wave's enemy HP, not by full-run completion time alone.

Reuse (Growing Kingdom): `Balance.ARMOR_EFFECT`, `ATTACK_TYPES`, `ROLE_ATTACK`, `armor_against()`; `CombatSystem.deal(target, amount, kind)`; `ProfileState.take_armor_lesson()`; `EnemyCard.armor_pairs()`; IMPLEMENTATION_DECISIONS.md B8 and B9.

Reusable rule:

> Create army diversity with soft counters: a trait every hit must name its type against, specialists favoured rather than the generalist nerfed, trade-offs kept, the counter taught at first encounter and kept in the reference, and the change judged by encounter composition.


---

# 132. Native localization from first implementation — English-first, 20 languages at release

**Implementation is English-first; publication remains 20-language.** Do not require Claude to translate 19 catalogs every time a feature changes. Instead, build the localization system early, keep the English source complete, and deliver all approved languages after a deliberate localization freeze. This applies to menus, gameplay text, tutorials, settings, confirmation dialogs, accessibility copy where present, and other player-visible strings. Store listing localization is a separate ChatGPT-owned workstream (134).

## 132.1 Approved language set (fixed release baseline)

| Locale (store-facing reference) | Language |
|---|---|
| `en-US` | English (reference/fallback) |
| `es-419` | Spanish (Latin America) |
| `es-ES` | Spanish (Spain) |
| `pt-BR` | Portuguese (Brazil) |
| `fr-FR` | French |
| `de-DE` | German |
| `it-IT` | Italian |
| `nl-NL` | Dutch |
| `pl-PL` | Polish |
| `ru-RU` | Russian |
| `uk-UA` | Ukrainian |
| `tr-TR` | Turkish |
| `id-ID` | Indonesian |
| `vi-VN` | Vietnamese |
| `th-TH` | Thai |
| `hi-IN` | Hindi |
| `ja-JP` | Japanese |
| `ko-KR` | Korean |
| `zh-CN` | Chinese (Simplified) |
| `zh-TW` | Chinese (Traditional) |

Arabic and RTL UI are **outside this approved baseline**. These are audience/store-facing references: **map explicitly to the identifiers accepted by the pinned Godot version and each Google Play surface** rather than assuming shared tags. Keep distinct Spanish/Chinese variants where needed.

## 132.2 Phase 1 — Claude builds localization infrastructure at the start

Claude must implement the following before or alongside the first player-facing UI:

- Godot-native `TranslationServer`; English source catalog (prefer `.po`), stable semantic IDs (e.g. `UI.SETTINGS.TITLE`, `UI.ACTIONS.UPGRADE`) and a shared convention for translating UI, data definitions and messages. No ordinary player-facing hardcoded English outside the source catalog. Text values in saves/game data use IDs, not translated display strings; translate complete sentences with stable placeholders/plurals.
- **Settings › Language immediately shows Automatic, English and all 19 other approved language options.** The 19 other options stay **visible but disabled** while their catalogs are absent/unapproved. Do not hide them or let tapping them switch the locale. Do not create deceptive empty/stub catalogs that Godot treats as shipped translations; references/disabled choices are sufficient.
- **Automatic is English-only during development and final localization integration.** Until the complete language rollout has passed all validation and a controlled readiness flag/gate is enabled, Automatic resolves to **English irrespective of device language**. Manual English is usable. Never expose raw keys or fallback surprises by accidentally selecting a not-yet-ready locale.
- Store manual choice or Automatic in settings independently of run/progression saves. Implement live UI refresh for locale changes; do not require a restart where feasible. The eventual Automatic resolver should select the best available device locale after **all 19 other languages** are approved and enabled; unsupported device locales continue to fall back to English.
- Build flexible text containers, layout margins, wrapping, font/script fallback architecture, correct formatting placeholders and a defensible UI font-size floor up front. Full CJK/Thai/Indic font subset finalization may wait for completed catalogs, but missing scripts must not require architectural rewrites.
- Maintain a **lightweight English-key consistency check** (IDs referenced by released content exist in English, no duplicate IDs or invalid placeholders) using existing appropriate tooling. Optional pseudolocalization can stress-test overflow while actual translations are deferred. Do not consume feature-development cycles on 19-language translation testing.

## 132.3 Phase 2 — Claude maintains English only during development

For every new feature or UI change, Claude adds/updates the corresponding semantic English keys, removes obsolete keys deliberately, tests affected English UI, and keeps localization-ready layouts. **Do not generate or maintain any other language catalogs in these iterations.** Changes in text semantics and placeholders must be reflected in the source catalog. Document intentionally untranslated proper names/brands in game-specific localization notes.

Compact feature report:

```text
Localization phase: English-only development
English catalog: <key count> keys; <new/changed/retired> this batch
English key/placeholder check: PASS or failures
Other 19 locales: deferred; Settings choices visible but disabled
Automatic locale: English (device detection gated)
```

## 132.4 Phase 3 — Localization freeze and ChatGPT translation handoff

**Freeze gate:** Before requesting non-English catalogs, Claude confirms intended UI/screens and English wording are stable, there is no unexpected player-visible hardcoded text, all referenced English keys exist, placeholders/plural intent are finalized, and the English layout works on the targeted screen sizes. Record this checkpoint (catalog version/hash and any intentional exceptions) in the project's GDD/release notes.

The developer supplies ChatGPT the **actual final English catalog**, plus any necessary terminology/character-limit context. **ChatGPT**, not Claude, generates the **remaining 19 complete translation files**, preserving keys, placeholders and format, using a consistent glossary where applicable. ChatGPT performs structural checks (completeness, unique IDs, valid catalog syntax, placeholder parity) and returns a **single ZIP** ready for the developer to copy into the designated localization folder. A machine check cannot certify native wording, glyph rendering or UI fit; those remain separate QA obligations. Translation files are not to be regenerated automatically during normal English feature changes after the freeze; apply targeted changed-key updates instead.

## 132.5 Phase 4 — Developer copies files; Claude integrates in mandatory small batches

**Developer:** manually copies ChatGPT's 19 non-English catalogs into the project. **Claude:** owns all subsequent implementation, validation and corrections, **including any translation edits** needed for terminology, correctness or fitting; no round-trip to ChatGPT is required for fixes.

**Strict execution rule: handle four or five languages per batch; do not implement/review all 19 in one Claude batch or one giant chat context.** Default sequence is **5 + 5 + 5 + 4** (use an ordered manifest/checklist that names each locale). For each batch:

1. Import/register that batch in Godot and validate correct locale mapping, file paths, catalog syntax, English-key parity, placeholders/plurals and non-empty translations. Maintain the languages' Settings entries **disabled until the complete 19-language rollout is accepted**, even if a batch has passed; local test switches may override the gate in test builds only.
2. Test live switching, persistence, all relevant screen/layout categories, glyph rendering/font fallback, text wrapping/overflow, longer strings, UI redraw, and representative Android screens where practical. Use the correct headless/window sizing rules and do not mistake an untested screen for a pass.
3. Claude fixes **anything necessary**, including incorrect/awkward translations, text length, UI layout, import registration, resource paths, script fallback and placeholders. For material rewrites, preserve meaning and update the terminology glossary. Recheck every corrected catalog before passing the batch.
4. Save a **short handoff report**: 4–5 locale IDs, imported key totals, missing/placeholder/glyph/layout test results, exact fixes, tests actually run, unresolved issues and artifact paths. Stop on blocking issues; complete each batch before proceeding. A new Claude chat can start the next batch using the report and files rather than replaying earlier translation output.
5. After all 19 catalogs pass, run a **global 20-language release gate**: confirm catalog/locale completeness, translation fallbacks, live Settings switches, available device-locale detection, export contents and the representative Android script/layout matrix. **Only then** enable all 19 Settings buttons and activate device-based Automatic. Recheck that the production build cannot revert to its English-only gate or expose disabled languages by mistake.

Suggested batch assignment (adjust order for the specific project's risks without changing the 4–5-language limit):

| Batch | Locales |
|---|---|
| 1 (5) | `es-419`, `es-ES`, `pt-BR`, `fr-FR`, `de-DE` |
| 2 (5) | `it-IT`, `nl-NL`, `pl-PL`, `ru-RU`, `uk-UA` |
| 3 (5) | `tr-TR`, `id-ID`, `vi-VN`, `th-TH`, `hi-IN` |
| 4 (4) | `ja-JP`, `ko-KR`, `zh-CN`, `zh-TW` |

Final completion report:

```text
Localization phase: all languages validated and enabled
English reference key count: <count>
Catalogs present and complete: 20/20
Batch verification: 5 + 5 + 5 + 4; 4 handoff reports
Missing keys / placeholder failures: 0 / 0
Glyph/layout/Android/export checks: <actual results and exceptions>
Settings: English and 19 other locales enabled
Automatic: device-language detection active; English fallback
```

## 132.6 Godot 4.7 implementation lessons (first applied in Everfort)

- **Locale mapping:** Godot folds `es_419` into `es`, so generic `es` serves Latin America and `es_ES` serves Spain. Resolve device locales in code: `zh` with `Hant`/TW/HK/MO to `zh_TW`, `pt_*` to `pt_BR`, and other known languages to their accepted Godot IDs; apply this **only after** enabling the final Automatic detection gate. Store tags are a separate mapping (134.2).
- **Fonts:** keep the primary theme font. Add script fallbacks (Devanagari, Thai, JP/KR/SC/TC) with a `FontVariation` chain at the primary weight; reorder Han fallbacks per locale to preserve regional glyphs. Subset CJK fonts to used catalog characters once the translations are available. A glyph probe fails and prompts re-subsetting if characters are missing. Enable `internationalization/locale/include_text_server_data` for Thai/CJK line breaking in exports.
- **Data and live refresh:** saves/resources store semantic keys, not translated text. Source scene text can use auto-translation; code-built strings redraw on `NOTIFICATION_TRANSLATION_CHANGED`. A probe switches language with panels open and checks the redraw (during final integration in test mode).
- **Layout probes:** check each screen in each available locale against English geometry and absolute on-screen limits. Headless Godot defaults to a 64×64 window; force the project's real reference canvas (e.g. 1920×1080 KEEP). Windowed screenshots must be taken after animations settle. Inspect clipped decorative frames, banners, ribbons and multiline descriptions, not just label rectangles.
- **Isolation:** private CSVs that Godot might import as translations (e.g. promo codes) must remain outside the project and outside release exports, with checks that they were not registered.
- **Backward compatibility:** localization must not reset progression. Prior saves without a language preference default to Automatic; during English-only phase that means English. Verify prior save fixture loads, switching and restart without lost progress.
- **Release-export gate:** inspect an actual release export, not just editor resources. All 20 approved catalogs, fonts/fallbacks and text-server data must ship; private CSVs, docs, development-only scenes and capture artifacts must not.
- **Representative Android smoke test:** do not require a full 20-locale manual device tour. On a real device, test at minimum German (long Latin), Russian (Cyrillic), Hindi (Devanagari), Thai, Japanese and Simplified Chinese; include live selection, persistence, HUD, Settings, major panels, popups/tutorials, shaping, wrapping, clipping and missing glyphs. Add other languages when the game presents specific risks. This device matrix complements, rather than replaces, automated checks of all 20.

---

# 133. Universal video generator — trailers, social and custom formats

A **single reusable video workflow** must produce a Play Store trailer **or any gameplay-based promotional video**, including TikTok, YouTube Shorts, regular YouTube and custom campaigns. It is not a Growing-Kingdom-only "trailer test." Do not force the user to assemble clips manually in an editor. Video production normally occurs in **stage 16** (0.9), with toolkit preparation and scenario development earlier if valuable.

## 133.1 Authored composition, flexible output

- User-specified storyboard, music, durations, text, camera and transitions **override** defaults; otherwise Claude follows a ChatGPT-approved creative brief or proposes composition for human approval.
- Support landscape **16:9**, portrait **9:16**, square **1:1**, and configurable profiles for resolution, frame rate, orientation and length. Example targets: Play Store 16:9, TikTok/Shorts 9:16. Render/capture gameplay with an appropriate game camera and responsive UI for the target; **do not just rotate or crop landscape footage** and call it portrait support. The one exception is a short-form social cut derived from already-approved footage (133.5): an explicit, reviewed reframe of real landscape gameplay (a focused window, or the whole frame letterboxed in black), never a claim that the game itself has a portrait layout.
- Shot types: staged real-gameplay clip, marketing text on black or branded background, title/end card, and reusable already-recorded footage. Marketing text may overlay gameplay **or** appear on cards, independently enabled per shot.
- Animate cameras where feasible (zoom, pan, follow, fixed), control gameplay staging and framing, and support explicit transitions, sequence order, overlays and optional sound effects.
- Output can be silent/game-audio-only by default; when the developer supplies an MP3/WAV (or another supported source), arrange scenes against the track and include it in the final render. **Do not require Claude to source or create music.**
- Maintain all written video headlines/title-card copy in the approved 20-language marketing localization set. Allow export of selected locales using the same source composition and footage.

## 133.2 Transitions must be rendered, never simulated by instantaneous swaps

The earlier failure mode was **gameplay → instant black → instant gameplay**, which looked unfinished. The default for black title screens is **fade out to black → readable black/title interval → fade in**. Example: 0.4 s out, 2.0 s card, 0.4 s in; all three intervals count toward the requested total duration. A change of scene during a fully black interval should not produce a visible pop.

What made the fades correct in practice:

- **Text waits for black.** A card's text is held back while the picture fades to black, fades in on black, and has faded out before the fade to the next scene starts. A crossfade from gameplay straight into a card with its text already on (the toolkit draft's behaviour) shows words over the scene and is not a fade to black.
- **Use a linear dip, and check the curve.** FFmpeg's `xfade=fadeblack` falls from full brightness to black within two frames and then fades in slowly: a near hard cut. A dip written as a linear expression (picture A down to black over the first half, black up to B over the second, with the correct YUV black) is even.
- **Keep the action out of the fade.** Record a clip with a few tenths of a second of live play before its first action (a "head"), so the fade covers lead-in, not the click or the selection.
- **Prove it frame by frame.** Decode the final MP4 small (e.g. its luma plane averaged to 64×36, expanded to full range so black is 0; swscale's YUV-to-grey conversion at that downscale is biased at dark levels and can fake a one-frame jump on a dark card) and check each transition: no single-frame step larger than about a third of the transition's whole change, frames in between, and the black point actually black. The same decode finds hard cuts in any video: Growing Kingdom's original one-take trailer showed its nine hard cuts to black; the composed replacement showed none.
- **Produce a review sheet** (each shot's first, middle and last frame, then every transition frame by frame) for the human check, next to the video.

Also support explicit hard cuts (only when intentional), crossfades between compatible clips, and text fades. Validate frame boundaries, overlaps, audio continuity and title legibility. Transition durations and shot lengths must sum to the specified finished runtime rather than inadvertently extending it.

## 133.3 Godot capture and MP4 post-production

**Godot Movie Maker → AVI intermediate → FFmpeg composition/mux/encode → `.mp4` H.264 (YUV 4:2:0) final.** Use Godot's actual configured available recording formats; the approved baseline is **AVI**, with an image-sequence alternative available for higher-quality or particularly long jobs. FFmpeg is a **required development-tool dependency for video generation**, never a runtime dependency included in the Android game. Verify that it is callable as part of the toolkit setup/health check.

Validated details (Godot 4.7.2):

- **Movie Maker ignores `--resolution`**: it records at the project's window size. Set the size for one run with a temporary `override.cfg` (`display/window/size/window_width_override`, `window_height_override`), never a project-settings edit, and delete it afterwards; refuse to touch a project's own `override.cfg`. The game keeps its reference layout, so a portrait window is a genuine portrait layout, not a crop.
- **Movie Maker's MJPEG is full range** (`yuvj420p`): convert to limited (TV) range for the H.264 delivery, or players and stores may show crushed or washed-out levels.
- Encode segments losslessly, join them in one filter graph, and encode the delivery once. Give every joined input the same frame rate and timebase (`xfade` refuses mismatched links).
- Record each clip's game sound with the picture (Movie Maker writes PCM); compose music afterwards, under the whole video, so cuts and fades never restart it. Silence under cards, crossfade the clips' sound with the same overlaps as the pictures, limit the mix (about −1 dBFS), and measure peaks and quiet moments; a rest in the supplied music is the composer's, not a dropout.

FFmpeg handles joins, text and fades, optional sourced audio, scaling/framing if genuinely required, H.264 encoding, `yuv420p`, and web-friendly MP4 metadata (`+faststart` when appropriate). A run should check codec, dimensions, frame rate, duration, audio presence when required, black frames/transition timing and readable final composition. Do not claim an MP4 was verified without actually inspecting its output/metadata.

**Preserve raw source recordings, scenario IDs, shot/timeline metadata, fonts/text assets and composition settings** separately from final MP4s. Changing subtitles, headlines, transitions or music should recompose from saved footage rather than force a new gameplay recording. Regenerate recorded shots only when the underlying gameplay/visual content changes or a shot is genuinely unsuitable.

## 133.4 One scenario interface for screenshots and video

The generic toolkit orchestrator controls duration, capture targets, transitions, export and post-processing. The **game-specific adapter** prepares the GDD-defined state, camera and action, then starts/stops or freezes that state. It may use legitimate debug/test fixtures to reach otherwise expensive situations quickly. Screenshot capture consumes a frozen/scouted frame; video capture runs that prepared state for a controlled interval. Neither orchestrator imports Growing Kingdom gameplay classes. All gameplay depiction must remain authentic to the game.

When the game already has a trailer or shot director (timeline, deterministic setups, scripted input, camera, HUD presentation, per-shot checks), the adapter **hosts it** for one shot at a time instead of reimplementing it: the same shot data then drives the one-take preview, the clips and the screenshots, and the director's checks fail a capture whose action drifted. A screenshot is a chosen frame of that live clip (run N frames, then freeze), so it shows exactly what the video shows at that moment.

## 133.5 Short-form social videos (TikTok / Reels / Shorts) from approved footage

Produced after the store trailer is approved. Treat them as **derived edits of footage that already passed review**, not a new capture project.

Defaults (Everfort, 2026-10-14: ten 15 s TikTok masters from the Play trailer's raw clips and music, no new recording):

- **10 master videos**, 9:16, 1080×1920, 30 fps, about 15 s; H.264 + AAC like the trailer. The masters serve TikTok, Reels and Shorts alike; make a platform-specific version only when a platform genuinely needs one.
- **One set, not one per locale.** The default deliverable is 10 masters in the reference language. Localized social variants are produced only when explicitly requested; their copy comes from the same manifest keys.
- **Ten different angles, not near-duplicates.** Each video sells a different real feature or promise (e.g. survival intensity, the progression loop, prestige and visual evolution, damage/crit escalation, horde pressure, the campaign length, upgrades, permanent skills, idle defense, early-vs-late comparison). Reuse the same raw clips with different in-points, framing and order rather than repeating the same edit with new text.
- **Mandatory 5/5 composition split:**
  - **5 focused reframes.** Centre a window on each shot's action. For a landscape game, a full-height 9:16 crop usually cuts off the enemies at both sides; a window about 0.45–0.5 of the source width keeps the action large (about 70% of the height). The bands above and below get a blurred, darkened copy of the same moment, where the hook (top) and the platform's caption (bottom) sit. Panels and buttons must stay readable at phone size: crop onto the button being tapped, not the whole panel.
  - **5 full-landscape videos.** The complete landscape frame, centred in the 9:16 output, with black space above and below (the toolkit's `reframe` with full source width and `fill: "black"`, not a separate render path). The hook goes in the top black band, feature lines in either band, so marketing text never covers the gameplay; the toolkit refuses copy that does not fit its band.
- **Gameplay first; a strong hook in the first 1–2 seconds.** Open on an authentic moment that fits the angle, with the hook headline visible within a quarter second. Keep shots short (1.5–3.5 s) and cut on the music's accents.
- **Short marketing text is allowed** on social videos (unlike store screenshots, 87.9): a hook, optional short feature lines, a brand card. Every string lives in the manifest's `strings`, so each game (and each variant) sets its own copy; nothing is hard-coded in the tool. Every claim must match what the clip shows (a stage number, a feature that exists in the build).
- **Real gameplay only.** No fake or misleading footage, mechanics or results; cards hold only the brand (name, icon, approved subtitle).
- **Reuse before recapture.** Derive all 10 from the approved raws and music. Recapture only when the existing footage genuinely cannot support a required variation.
- **Platform-safe text margins**: keep text out of the top ~8% (tabs), bottom ~22% (caption, sound) and right ~12% (buttons). The toolkit applies these by default to vertical social profiles, in both compositions.
- **End on the brand** (logo/icon + name). A hard end (no picture fade) loops cleanly; give the music a short fade.
- **Reuse the approved music**, varying the in-point per video so a phrase or bar accent lands on the first cut.
- **Package from the manifest**, not a hard-coded list: every social-profile video in the manifest is a master; its composition is read from its reframes, and the packager checks the count and the 5/5 split.
- Validate like the trailer, for all 10: resolution/fps/duration/audio probe, transition and text-hold checks, review sheet and a keyframe contact sheet checked at phone size (plus one overview sheet of the whole set), and the Play Store deliverables' hashes unchanged.

Reusable rule:

> **Short-form social videos are a set of 10 vertical (9:16, 1080×1920, ~15 s) gameplay-first masters derived from already-approved footage and music: 5 focused reframes (blurred fill) and 5 full-landscape cuts (the whole frame, text in the black bands, never over the gameplay).** Each has its own feature-based hook in the first 1–2 seconds, real gameplay only, short configurable copy inside platform-safe margins, ending on the brand. One master set, reused across TikTok/Reels/Shorts; localized variants only on request; recapture only when the footage genuinely cannot support a variant.


## 133.6 Social posting copy after the 10 masters are approved

The video files are not the complete social deliverable. Once the ten masters in 133.5 are approved, prepare **one posting-copy entry for each video** so publishing does not require a second creative pass later.

Default rules:

- **Match the actual video.** Each caption/description should describe or amplify the mechanic, transformation, challenge or payoff visible in that specific master. Do not reuse one generic paragraph for all ten and do not claim a feature the footage does not show.
- **Caption and hashtags travel together.** The copyable content should contain the caption/description followed by its relevant hashtags in one block, ready to paste into TikTok. Use the game brand, genre and actual mechanic/topic where useful; avoid unrelated, spammy or trend-chasing tags.
- **Human review is one video at a time by default.** In an interactive review, show `Video N` outside the copyable block, then provide only that video's caption + hashtags inside the block and wait for the developer to request the next one. This minimizes copy/paste mistakes and makes it obvious which text belongs to which master. After approval, a consolidated posting-copy file may contain all ten entries.
- **Do not bake posting copy into the media automatically.** The rendered hook/feature text remains controlled by the video manifest. Social captions and hashtags are publishing metadata and stay separate unless the developer explicitly asks to render additional text.
- **Reference language first.** Produce the ten reference-language posting entries by default. Localized social captions/hashtags are optional campaign work, generated only for markets the developer explicitly chooses to target.
- **No automatic posting.** The toolkit/agent prepares media and copy; the human developer decides when and where to publish.

Reusable rule:

> **Every approved ten-video social set receives ten matching posting-copy entries. Present them one video at a time for human review: video number outside the copyable area, then caption + relevant hashtags together inside it. Claims must match the footage; localized social copy is optional and publishing remains a human action.**

---

# 134. Google Play ASO and localized store publishing

**ChatGPT owns non-code marketing strategy and copy.** It researches each game's live genre/competitor landscape, relevant search phrases, actual differentiation and approved features, then proposes the final store presentation. **Claude owns the technical production** of screenshots and video from the real Godot build (sections 87 and 133). **The human developer approves** titles, descriptions, assets, final paid price and publication. Do not transfer non-code research to Claude by default or make Claude duplicate research already approved.

## 134.1 Research and drafting sequence

1. Read the approved game GDD plus the actual shipping feature list; do not advertise planned but missing mechanics.
2. Search current Google Play competitors and audience language, noting evidence and differentiators. **Never present assumed keyword rankings, search volume or competitor conversion data as verified facts** without a real source/tool.
3. Produce **2–3 differentiated title/short-description positioning options** and an evidence-based recommendation for human review. The short description should sell the player's fantasy/core loop and why the game feels fun, not merely list a content count or technical fact unless that fact is genuinely the hook.
4. Before translating anything, finalize the **English source listing in this order: title → short description → full description → current Google Play metadata-policy review → human approval**. Check current field limits and policy guidance at publishing time. Avoid price/promotional language in descriptive metadata, ranking/superiority claims, calls to action, keyword stuffing, decorative emoji/special-character spam, and other wording that can create a policy or promotion-eligibility issue. Factual paid price and commercial configuration belong in the Play Console fields that own them.
5. After English approval, author the screenshot order and subjects (language-neutral gameplay, no added text by default; 87.9), any feature-graphic copy proposed for explicit approval, and the video brief around consistent feature claims (not stuffed/repetitive keywords).
6. Only then localize and adapt the store listing **text** for all 20 approved languages, researching genre terminology when useful instead of blindly translating individual English words. Standard language-neutral screenshots need no per-locale image variants.
7. Check each locale's current Play requirements, text lengths, readability, metadata policy, locale identifier and the truthfulness of every claim (listing text, the features screenshots depict, video copy) before export/submission.

## 134.2 Listing identity and locales

**Preserve the recognizable core game name across markets.** When useful for local ASO, adapt a **genre descriptor** or subtitle by locale while retaining the same clear brand identity. Do not force literal translation of the brand. Validate title length (commonly **30 characters**), short description (**80 characters**) and full description (**4,000 characters**), and recheck current Google Play rules at publishing time. Localized store listing locales must be mapped explicitly to the supported application locale plan (132); they need not share identical locale-code spelling.

The normal localized store workload is: title; short description; full description; any explicitly approved feature-graphic copy; and trailer title-card/caption copy where the approved video actually contains such copy. It does **not** include localized screenshot overlays: screenshots follow the language-neutral default (87.9) and one set per device class is reused for every locale. Localized screenshot text exists only when the developer approved that exception for a specific game/campaign. Keep English as the approved reference for claims, but tailor search vocabulary per locale. Supply final copy and source research to the developer for approval **before** technical asset production or publication.

**Runtime locale IDs and Google Play locale tags are separate contracts.** Never assume the Godot/runtime identifier can be pasted unchanged into every Play Console surface. Maintain an explicit mapping and verify it against the current Play surface. In Everfort's validated 20-language Play import/release-note flow, these runtime locales required base-language Play tags: `uk-UA → uk`, `id-ID → id`, `vi-VN → vi`, `th-TH → th`. A rejection of a region-qualified tag does **not** prove the language itself is unsupported. Store listing import, release notes and other Play surfaces may normalize or validate identifiers differently, so verify the accepted tag set at publication time rather than guessing.

## 134.3 Google Play AI-assisted translation handoff

After the English title, short description and full description pass the current metadata-policy review and are human-approved, translate/adapt the listing into the other 19 approved languages. Generate **one UTF-8 structured JSON handoff** for Google Play Console's AI-assisted translation import. This is a transport artifact, not a second source of truth. It contains 20 logical locales (English source + 19 translations), each with: the **Play-facing locale tag**, human-readable language, `title`, `short_description`, and `full_description`, plus the expected field limits. Language-neutral screenshots are not duplicated into this package.

Reusable validation before handoff:

- exactly **20 logical locale entries**: one English source + 19 translations;
- map runtime locales to the locale tags accepted by the current Play Console surface before validation/import; for the current baseline, known normalizations include `uk-UA → uk`, `id-ID → id`, `vi-VN → vi`, and `th-TH → th`;
- no duplicate or missing intended language after mapping;
- title <= 30 characters, short description <= 80, full description <= 4,000 (recheck current Play rules at publication time);
- the short description sells the real game loop/fantasy rather than filler facts and contains no unapproved promotional/ranking/call-to-action language;
- natural localized store wording and approved feature claims, not literal word-for-word translation merely to fill the file;
- run the stable toolkit's `tools/play_store_listing.py validate <file>` (or an equivalent reviewed validator) **with its explicit runtime-to-Play map matching the Play-facing tags currently being used**. Toolkit 1.0.2 defaults to the verified 20-language baseline (`uk-UA → uk`, `id-ID → id`, `vi-VN → vi`, `th-TH → th`). If the Console changes accepted tags, use a deliberately reviewed complete 20-entry mapping via `--locale-map <map.json>` rather than accepting runtime codes or claiming import success.

**The Console import itself is a separate verification step.** A syntactically valid file is not proof that Play recognized every language. Import the handoff, inspect the detected language list, compare it language-by-language with the intended set, and correct any rejected/normalized locale tag. For the 20-language baseline, the intended outcome is the English source plus all 19 translations, but verify the **actual languages**, not just the number displayed. Do not conclude that a language is unsupported until you have ruled out an incorrect locale identifier.

Keep the approved English listing, the structured 20-locale handoff, the runtime-to-Play locale map and the validation report as source/release evidence. Do not require 20 copies of language-neutral screenshots.

## 134.4 Publishing gate

At **production stage 16**, plan and produce store screenshots and video, feature graphic and ASO, the set of 10 short-form social videos derived from the approved trailer footage (5 focused and 5 full-landscape, 133.5), and their posting copy (133.6), after the UI-readiness trigger for screenshots (87.8). Generate/validate the 20-locale Play listing handoff (134.3) only after the English source copy is policy-checked and approved. Stage 17 validates the exact Android release candidate and assets against the shipped features. Stage 18 completes Play Console configuration: listing, locales, policy declarations, ratings, countries, signed build, release notes where applicable, and **one-time paid** price. No advertising, IAP, subscriptions, analytics or crash-tracking integration is part of this sequence. Treat each final store/social deliverable as an approved artifact, not automatically published material.

## 134.5 Localized Google Play release notes

Release notes are their own Play Console input and use the locale tags accepted by that surface. Do not assume the project's runtime tags are valid release-note identifiers.

Workflow:

1. Write one **short, consolidated English release note** describing only meaningful user-visible changes in the release.
2. Obtain human approval of the English note before translating it.
3. Translate it into every applicable store language, preserving the same factual scope rather than adding marketing claims per locale.
4. Wrap each translation in the exact locale tag syntax required by the current Play Console release-notes importer. Apply the runtime-to-Play mapping from 134.2; Everfort validated base tags such as `uk`, `id`, `vi` and `th` where region-qualified runtime tags were rejected.
5. Paste/import and resolve any rejected identifier by checking the current Play-supported tag, not by deleting the language immediately.
6. Keep release notes concise. They are update notes, not a second long description or keyword surface.

Reusable rule:

> **Approve one concise English release note first, then translate it using the identifiers accepted by the current Google Play release-notes surface. Runtime locale IDs and Play release-note tags may differ; a rejected tag is not evidence that the language is unsupported.**

---

# 135. Reusable Godot toolkit — versioned code, not recreated per game

The Playbook is the **one reusable methodology document** (section 107). It is accompanied by a **versioned Godot source toolkit** holding reusable implementation code so Claude does not waste tokens rebuilding solved infrastructure. The toolkit is a code package, **not** another Playbook and **not** any one game's whole project. **Godot Marketing Capture Toolkit 1.0.2 is the approved stable reusable baseline** for the validated Windows/Godot 4 workflow: its capture/composition path was exercised across multiple projects and production-validated in Everfort with four screenshot device classes, a store trailer and the standard ten-video social package. A game's own Android/media review remains a release gate for that game; it is not a reason to rebuild or fork the toolkit.

## 135.1 Package boundary and lifecycle

The approved target structure is one **Marketing Capture Toolkit** with reusable:

- capture/scenario-orchestration interfaces (but **not** each game's scenario logic);
- Godot screenshot capture code and optional localized promotional composition;
- Godot video/shot orchestrator and transition/timeline configuration;
- FFmpeg command templates, installation/health checks, composition and MP4 export;
- aspect/resolution profiles, output manifests and validation helpers;
- concise integration instructions and a small non-game-specific smoke test.

**Reuse first:** audit and extract compatible proven code from Growing Kingdom's screenshot addon and trailer director/timeline/recording scripts; remove game-specific dependencies; extend and test the generic parts rather than rewriting existing functionality. The game's own scenario adapters, screenshots and trailer composition remain in its repository. Do not copy Growing Kingdom-specific game state or marketing wording into the reusable baseline.

## 135.2 New-game bootstrap and changes

A new project starts with (a) this Playbook, (b) the approved game GDD, and (c) an identifiable **validated toolkit version/repository or package**. Bootstrap pins and installs the toolkit automatically from that version; no hand-copying files and no invented downloads/paths if the toolkit is absent. A new feature first checks whether a reusable implementation already exists; write game-specific adapter code only where needed. Toolkit improvements are tested in the actual Godot project, reviewed, then promoted to a new **validated** toolkit version for the next game; keep version/changelog so updates are deliberate, not silent.

Validated integration pattern (Toolkit **1.0.2**): the toolkit carries its own `addons/`; `install` copies them into the project and writes a lock file (version and every managed file's SHA-256); `status` fails when the project's copies, the lock or the toolkit source disagree, so local edits cannot drift silently (change code in the toolkit, reinstall). Reinstalling keeps Godot's authored/generated `.uid` references. If the toolkit sits inside a game's repository during development, give its source folder a `.gdignore` so Godot never imports it alongside the installed addon. Version the game adapter, manifest, toolkit lock and required installed addon files. Keep **marketing-only** Noto fonts/OFL licenses inside the toolkit's `.gdignore`-protected asset directory, not in the Android export. Godot's text engine handles complex-script marketing text; do not require Pillow/Raqm for Thai/Devanagari rendering. The MP4 composer supports Preview/Standard/High H.264 CRF presets (26/21/18); High is the default final output. The toolkit is validated on the approved Windows toolchain; macOS/Linux support is not implied until separately tested.

## 135.3 Creation, integration and sign-off

- **ChatGPT:** owns reusable-method decisions, marketing/ASO strategy, approved copy, screenshot subjects/order and video brief/storyboard; proposes generic toolkit changes when a cross-game need is proven.
- **Claude/repository-aware coding agent:** pins/installs the stable toolkit, implements only the current game's scenario adapter/manifest/packaging glue, runs Godot/capture/FFmpeg verification and export audits, and proposes reusable bug fixes upstream rather than silently editing installed addon copies.
- **Human developer:** reviews authentic screenshots, MP4/video transitions, localized marketing copy and representative real-device behavior; approves new toolkit versions, store outputs and publication.

Toolkit **1.0.2 is production-ready as reusable source** for the validated Windows workflow. A future generic change increments the toolkit version/changelog and is validated before games deliberately upgrade their lock. Game-level device checks remain mandatory before that game's publication. The embedded Android starter in this Playbook remains canonical for base app setup; the separately distributed toolkit supplies **additional reusable code**, not a competing process guide.


## 135.4 Source control and `.gitignore` baseline — every Godot game

**The embedded `.gitignore` at section 0.8 is the canonical starter template.** Keep the actual game's root `.gitignore` synchronized with it, extending only for tools the game genuinely uses. This is part of bootstrap and every new integration, not a one-time cleanup before release.

**Version with Git:** Godot source (`project.godot`, scenes, scripts, assets, `*.gd.uid`), Android/export configurations that contain no secrets, game tests, `docs/` including GDD and this Playbook, installed `addons/` required at runtime/editor-time, `marketing/` scenario adapters/manifests/approved source copy, `marketing_capture_toolkit.lock.json`, and the reusable toolkit source/package **while it is vendored in the project**. Keep toolkit-required Noto font files, `font_manifest.json`, sample texts and OFL licenses together; do not ignore fonts merely because the Git footprint is large. Once toolkit source is maintained in a separate repository, pin a reproducible package/version and only remove the vendored source after the new installation path is actually verified.

**Ignore, but keep locally as needed:** `.godot/` import/editor cache; generated Android Gradle workspace in `/android/` when it is reproducible; `/builds/` and exported APK/AAB/PCK; raw recordings and generated marketing previews/final images/videos under `/recordings/` and `/store_assets/`; temporary capture `/override.cfg`; `/tests/tmp/`; Python virtual environments, caches/bytecode and test caches; and local archives. Keep raw recordings outside Git for recomposition but back up selected final deliverables somewhere durable if they matter for publishing. Do **not** globally ignore `*.png`, `*.mp4`, `*.wav`, `*.ttf` or `addons/`: real assets, audio, reference videos, fonts and necessary plugin code might be source files in a different project.

**Never commit private keys or credentials:** signing `*.keystore`, `*.jks`, PKCS#12 files and `.env` secrets belong outside Git and preferably outside the project tree. If export settings contain only paths to private keys and no passwords, those settings may be versioned. Handle any custom changes made inside `/android/` as explicit reproducible source patches/plugins or a documented exception; do not silently discard unique Android code because the generated folder is ignored.

**Keep private operational publishing data outside the Godot project tree.** Promotion-code inventories, recipient/profile lists, campaign-tracking CSVs and similar operational records are not game source and should live in a separate private location. Merely git-ignoring such a CSV is insufficient: Godot may still import it (for example, as bogus translation resources), local archives may still capture it, and editor import errors can create noise. If legacy operational data must temporarily remain under the project, exclude it from export and place it under a `.gdignore` boundary until it is moved out.

**Before an implementation commit or project handoff:** run `git status --short` and `git ls-files` and audit for generated captures, secrets and accidentally omitted required sources. Use `git check-ignore -v <path>` to explain ignored paths. `.gitignore` affects new Git tracking only: a file already committed remains tracked until deliberately removed from the index (`git rm --cached`), and copying/zipping a directory can still include `.git/`, `.godot/`, outputs, and private files. For a clean source handoff, build the archive from tracked, reviewed files (for example, `git archive` at the desired commit) rather than zipping the entire working directory. Never automatically clean or delete untracked work without the developer's approval.

**Reuse gate:** The toolkit's README/installer must say what gets copied to a new project; the project's ignore rules must preserve that install contract. Claude reports new `.gitignore` exceptions when adding new generators, tools or Android plugins, and keeps this Playbook template aligned after a reviewed change.


# 136. Whole-project review and design reconciliation

Added in documentation Change 2, 2026-10-20. These are reusable review rules; a game's content, prices and reset matrix belong in its GDD.

## 136.1 Distinguish available, approved, implemented and verified

For each major system, record four separate states: resources supplied, behavior approved, code implemented and evidence verified. An asset copied into a project is not an integrated feature. A headless test is not a physical-device review. When auditing a new archive, compare it with the prior source and identify whether code, content or only assets changed. State the audit method and limitations; preserve historical failures without relabeling old results as fresh runs.

## 136.2 Reconcile documents instead of stacking contradictory authority

After substantial design discussion, consolidate latest explicit decisions into one current GDD. Separate superseded examples/proposals, delegated numerical authoring and unresolved choices. Update the entry point, audit, checkpoints, asset registry and status documents together. Archive previous versions as clearly historical; keep original release notes and test evidence immutable. Do not leave old APPROVED headers looking like final-game sign-off. Keep reusable methodology in this Playbook and game-specific rules in the game's documents.

Continue integer change numbering once per delivered batch. Documentation-only changes record their own batch but do not silently change executable version, store code or save schema. Never imply a new playable build was tested when only documentation changed.

## 136.3 Resource and license checks

Read actual manifests and files: frame dimensions/counts/timing/loop flags, file paths, audio headers and license terms. Distinguish a sprite's appearances/variants from enemy species and audio encodings from distinct sound variations. Record supplied but unintegrated resources and their intended event mappings. Presence/header checks do not replace animation playback or listening. Trace generic renamed audio to its source/license; missing proof is a release follow-up, not an assumption of permission or prohibition. Do not include standalone restricted asset packs in documentation patches.

## 136.4 Bounded confirmations and persistent-state contracts

Every destructive confirmation must fit supported viewports and safe areas, wrap or scroll its explanation, and keep both action and cancel reachable without reducing readable text. Verify paused/dead/long-text states through the real UI. Do not infer that fixing desktop geometry proves phone acceptance.

For refreshable rewards, offline accumulation and batched permanent choices, document ownership, refresh/reset scope, commit point, interruption/resume behavior and duplicate-credit prevention before implementation. Separate lifetime progress from run progress and animation/audio from authoritative rewards. Use targeted interruption tests when these systems are built.

## 136.5 Clean handoff and honest sign-off

Apply section 135.4 to ZIPs as well as Git: packaging a whole directory can include caches and credentials despite .gitignore. Check archive contents without displaying secret values. Produce handoffs from reviewed source; do not delete local untracked work. Verify installed toolkit hashes against both lock and source before claiming reuse integrity. Keep intended-engine, Android signing/device, localization, performance and balance gates explicit until actually verified.


## 136.6 Stationary discovery sources and staged intelligence

When explicitly approved, unlocked camps can reveal a configured radius without the player present. Treat them as stationary sources owned by discovery state, not cameras. Camp radius, player radius and map-information rank are independent purchases with explicit map/camp scope. Apply reveal at unlock/radius change; do not repeatedly scan inactive maps each frame. A remembered spawn location is not live enemy tracking. Teleports reveal the destination only. Keep upgrade lifetime separate from map exploration lifetime and test both.

## 136.7 Stock bonuses and evolution comparisons

If holding spare copies grants power, derive that bonus from current quantity; do not silently consume copies or store it as an irreversible permanent stat. Every quantity-changing operation must use the same effective-stat getter, including consumable use, merging, evolution and offline grants. Define which copies count, activation threshold, caps and reset scope. Do not infer a copy reservation system from an evolution cost.

Specify evolution's reference precisely: source merge level, intrinsic stats, quantity bonuses, random rolls and external buffs. Use a stable catalog baseline when intended, so temporary buffs or repeated evolution cannot compound into stronger newly minted items. Compare successor start and successor growth with the source on the actual equipment screen, not only in a spreadsheet. Preserve source/target identity rules and validate output capacity before spending. Keep game-specific percentages and formulas in the game's balance document.

## 136.8 Persistent keys and batched unique rewards

Distinguish permanent quest discovery, permanent collected keys, run gate kills and once-only quest rewards. Reset each according to an explicit matrix; a world reset must not inadvertently erase permanent keys or grant the quest reward again. Separate fight eligibility from an already-completed objective record.

For multiple earned opportunities resolved in one reset, snapshot eligible opportunity ids and remaining card ids before choice. Save each choice and resume interruption without rerolling, duplicate grants or partial resets. Derive combo ownership idempotently from unique cards. Offline grants carry provenance so they cannot accidentally increment online challenges through shared inventory/currency event handlers.


---

# 137. Campaign migration and verification lessons

## 137.1 Shared travel authority

Every UI surface that can teleport must query the same authoritative combat/travel rule. Include pending player contact, enemy aggression/windups, recent damage, death, pause/suspension and an unresolved permanent-choice transaction. A disabled button and its reason derive from that query; direct commands validate it again. Respawn is a distinct action, not a route around travel restrictions.

## 137.2 Changing inventory policy is a migration

Compatibility work here is conditional on section 61: preserve production saves, or development saves explicitly promised compatibility. For an authorized pre-release reset, document the reset boundary instead of keeping obsolete migration/refund machinery.

Removing an economy service means removing its controls, callbacks, definitions and active strings, and explicitly handling existing purchases. Preserve owned item identities and their progress. If refunding removed upgrades, derive the refund from the old schedule and guard it with the schema transition; repeated loads must not repeat it. Historical test/source evidence can retain the old contract but must be labelled historical.

## 137.3 Test the reachable ceiling before polishing exponential growth

Compute the authored final enemy against the actual catalog's upper loadout bound before claiming a full campaign is viable. A fixed-level exponent can outgrow every item by orders of magnitude. Correct that defect without replacing fixed authored levels with player scaling. A maximum-loadout check establishes a bound only: separately test borderline loadouts, skill encounters and natural time-to-first-prestige.

## 137.4 Provenance must survive consumption

If a quest accepts online-earned items/currency only, a cumulative earned counter is insufficient. Track unspent eligible credit, decrement it on spending, and bound submissions by both eligible credit and present stock. A later offline replacement must not inherit the spent online copy's provenance. Record per-opportunity credits after discovery; a relevant triggering acquisition may count once.

## 137.5 Separate authoring from runtime

Bake editable stage TileMapLayers from a deterministic authoring utility; gameplay loads the baked scenes. Keep scenario data, stable ids, scene resources and validation probes together in root-relative patches. Importing successfully with another engine version is not proof of the declared target engine or Android release artifact.

---

# 138. Device playtest correction lessons (LootFarmer Change 7)

## 138.1 One identity per item, and beware breadth-stacked passives

When many sources carry "the same" item (every enemy type had its own visually identical sword), give the item one identity and let sources differ by tier, not by copy. Before collapsing duplicates, measure what the duplicates were secretly worth: a passive "each owned item adds 30%" bonus turns N duplicate families into N stacked bonuses. Compare damage at the first hard gate before and after (one deterministic bot run) and compensate in the shared item's base, not by raising the passive share. Map removed ids to their successors in the catalog and apply the map wherever an id can live in a save (items, slots, equipped, ground loot, history, counters, quest progress).

## 138.2 Offline earnings are claimed, not silently applied

Background or startup settlement records a pending claim (saved, merged across absences, each interval capped as before). Payment, offline counters and anything they discover happen on an explicit in-game claim, which clears the pending record in the same durable write so a reload cannot repeat it.

## 138.3 Ambient particles belong to the world

Lay weather out on a fixed world grid with the same local pattern in every cell and drift it with time; the camera rectangle only culls. A camera-relative layout follows pans and zooms. Keep the placement a pure function so a probe can compare two camera rectangles.

## 138.4 Anchor self effects to the rendered actor

Place an effect from the art's own anchor (a heal ring 20 px below the frame centre) on the actor's feet, scaled with the actor's rendered scale, not at the actor coordinate. Large bosses expose the error first.

## 138.5 A reveal-radius cut can hide authored landmarks

Lowering a fog radius changes which landmarks the natural route uncovers. After a cut, check that each authored camp or shrine is still found on the ordinary path (a short bot slice is enough). Prefer lowering the burst radius at arrival over the walking radius.

Reusable rule:

> Share identities and compensate the passive breadth you remove; pay offline rewards on an explicit claim; keep ambient effects world-anchored and self effects anchored to the art; re-check landmark discovery after any fog change.

---

# 139. Close reveal, separate sight, and solid scenery (LootFarmer Change 8)

## 139.1 Split permanent exploration from momentary vision

When the player asks for exploration to stay close to the character, do not just shrink one radius. Keep two states with different jobs:

- **Explored cells (saved):** reveal a small radius around the walking player. They drive map memory and encounter discovery.
- **Vision (never saved):** a live radius around the living player, about 2× the reveal. Terrain, enemies and loot inside it are drawn through a lighter veil and can be fought or picked up, but vision never discovers an encounter.

Upgrades and cards that scale the reveal should scale both. Persist only the explored set, so load, relaunch and teleport never produce a fresh full reveal.

## 139.2 Discover per spot, and give landmarks their own sighting rule

Track discovery per encounter spot (type + loadout), not per type. The map then draws one small marker per found spot and none for an unfound one at any map-intelligence rank, and auto-farm can never walk to hidden coordinates. A spot is found when its home cell is explored, a living actor of it stands on explored ground, or the player defeats one of its enemies.

A close reveal can hide authored landmarks (138.5). Instead of restoring the big reveal, let landmarks such as camps be sighted from farther away. Remember them, show a short notice, and reveal only their footprint. Compute the sighting radius from the layout: every landmark must lie within it of an ordinary farming spot or of a gate encounter.

## 139.3 Solid scenery for a point-movement simulation

When the simulation moves points directly (no physics):

- **Store solids as editor content:** a physics-free StaticBody2D with a circle or rectangle shape at the trunk or base, never the canopy. The simulation reads the shapes once per stage and buckets them in a coarse grid.
- **Slide, don't stop:** a blocked step slides along the solid toward the goal. Take the contact normal at the actor's current, touching position, because the tentative step can slip past a corner. Give rectangles round corners (normal from the nearest point). A head-on approach to a long solid heads for its nearer end.
- **Prevent traps at authoring time:** keep every pair of solids at least a walkable gap apart, so no concave pocket can trap an actor. Keep solids out of camp, spot and boss keep-clear disks, and prove reachability of every actor home with a grid BFS before saving the scene.
- **Test with the real mover:** walk the simulation's own movement between every camp and every actor home on every stage. A topology BFS alone missed the corner and head-on stalls.

## 139.4 Data from JSON is float until proven otherwise

`Array.has()` is type-strict in Godot 4. Id lists loaded from JSON (`[0, 1, 2]` arrives as floats) must be converted to ints once, in the catalog loader. In LootFarmer this silently refused every Focus (auto-farm) request for several releases, because no probe called the real entry point with an int.

## 139.5 Evolution versus growth from copies

When identities should stay fixed (outfits, skills), replace successor evolution with a copy-growth cap:

- linear up to the old cap, then logarithmic, so the extra power stays bounded;
- coefficients kept in data;
- check that the capped lower tier stays below the next tier's normal ^100 item, so later drops still matter;
- keep unreachable successor ids as legacy items, so saves keep what they own.

Reusable rule:

> Save exploration, not sight; discover encounters per spot; sight landmarks from afar; make blockers editor content with walkable gaps and test them with the game's own mover; convert JSON ids to ints at load.

---

# 140. Late-game balance lessons (LootFarmer Change 9)

## 140.1 A ceiling fixture must own, equip and verify

A "maximum loadout" check is only as good as its fixture. LootFarmer's ceiling equipped an item it never added; the equip call failed silently, so the reported survival described a player with no outfit at all. It also used weapons no enemy drops. Make a ceiling fixture:

- assert that every item exists, is obtainable (dropped by some enemy, not a legacy id, within the best drop tier) and was added;
- assert that every equip call succeeded and the slot holds the expected id before computing anything;
- reject impossible loadouts explicitly in a test, so a later edit cannot quietly reintroduce them.

## 140.2 Measure fights with the real simulation

Hand estimates of time-to-kill against survival count basic hits only. Boss skills, boss healing and the player's auto-cast skills changed the outcome by about 2×. A few short deterministic duels in the real simulation (one seed, at most a few hundred simulated seconds each, a watchdog timer so a script error cannot hang a headless run) are cheap and much more trustworthy than a long multi-seed campaign.

## 140.3 Worn bonuses versus collection passives

When many identities each contribute a passive share, the collection outweighs the worn item. Lower the passive share for broad collections (48 outfits), keep it for narrow ones (14 weapons), and put new power on the worn item as milestones that never stack across the collection. Prefer percentage effects (Defense through an existing reduction formula, regeneration as a share of max HP) and scale them by the item's tier, so they stay relevant late and cannot trivialise early content.

# 141. Device playtest correction lessons (LootFarmer Change 11)

## 141.1 Consumables: charges and mastery are separate state

When a consumable can improve, keep **stock** (charges spent by use) and **mastery** (permanent growth) in different fields. If mastery is derived from stock, or growth consumes copies the way gear merges do, using an item destroys progress and players hoard instead of using it. Choose the authoritative mastery event explicitly: acquisition or successful use, never both by accident. For usage-based mastery, increment a per-type counter only after a successful consumption, retain its remainder, and derive capped levels from uses-per-level. Purchases, drops, offline receipts and re-pickups grant stock only. When replacing acquisition-based mastery in compatible saves, preserve earned levels as one-time legacy credit and add future use-based levels; never rederive that credit on subsequent loads. Decide explicitly whether bought copies count: if acquisition grants mastery, coins buy permanent power. Keep one inventory identity per consumable, so improvement never creates tier ids. Supply capacity can then equal the number of identities exactly.

## 141.2 Flavour that describes an outcome must read the final outcome

Speech, toasts or effects that refer to a result ("my outfit!") must be emitted after every roll that decides the result, from the actual outcome, with one deterministic pick when several qualify. A line attached to an earlier event (the first hit) reads as a promise and turns into a lie whenever the roll fails. Do not re-roll or grant extra rewards to justify a line.

## 141.3 Transient view state needs one reset funnel

A filter, highlight or selection that should last only while a panel is open must be cleared by one function that every close path calls: the close button, the toggle, Back, opening another panel and programmatic closes. Test every path, because each missing one leaves the main view looking empty or broken. Keep durable preferences (such as sort order) in a separate field so the reset cannot erase them.

## 141.4 Derive retention from the property that defines it

If the rule is "everything bought with premium currency survives a reset", enforce it from the currency in code, not from a per-row flag copied into each upgrade. Flags drift: six premium upgrades were silently reset while the reset screen promised the opposite. Keep the flag only as a mirror, validate the mirror statically, and after the reset re-apply anything a kept level changes in the fresh world (for example, spawn extra actors immediately).

## 141.5 Headless probes: a script error is a hang, so run them through a watchdog

In Godot, a runtime script error inside a probe's async `run()` aborts the coroutine, so `quit()` is never reached and a headless run waits forever. Old suites then look "slow" or "timed out" instead of failing. Run probes through a runner that applies a hard timeout per probe, counts any `SCRIPT ERROR` line as a failure (playbook 60) and requires the probe's own summary line. When repairing old probes, also check how the harness advances time: a simulation that clamps each step (here to 0.1 s) turns `step(9)` into a tenth of a second, so long spans need a stepping helper. Finally, an assertion that keeps failing can be the only remaining record of a lost rule (here, ground-loot expiry), so read the current contract before deleting it.

# 142. Device playtest correction lessons (LootFarmer Change 12)

## 142.1 A telegraph announces only what can happen

When an enemy warns before a skill (a 0.5–1 s wind-up with its effect), check the skill's own eligibility **before** the warning, not only when it resolves. A self-heal at full health, a buff with no target or a cast whose condition already fails otherwise plays its effect and sound for nothing, again on every retry, and players conclude the skill is broken. Pass an ineligible skill's turn to the next skill in the rotation, or a single blocked skill can silence all the others. Play the success effect, sound and number from the authoritative change (HP actually restored), once, and attach effects that belong to an actor to that actor's view so they follow it. Attack warnings are different: they show where a hit will land, so they still play and the target may dodge, but as a distinct marker, never as a copy of the hit effect (section 143.3).

## 142.2 Progress notifications: announce a rising count against a session baseline

To play one cue when a tracked objective's step completes, compare a derived "steps done" count with a baseline held in memory (not saved). The first reading after a load or after the player picks a new objective only sets the baseline, so nothing re-announces on reopen; a rise announces once and the baseline keeps its maximum, so a step lost and regained is not announced twice. Route the cue through the audio service's per-frame priority, so a final step that also completes the objective plays one sound, not two. When purchased automation consumes the same event repeatedly (auto-claim), stay silent: that is the automation rule of section 85.

# 143. Device playtest correction lessons (LootFarmer Change 14)

## 143.1 A badge and the action it advertises read one predicate, and the list shows what the badge counts

A "ready" badge that reads its own condition drifts from the Claim buttons it promises. LootFarmer's Missions `!` lit for any ready main objective, while the panel listed only the first three unclaimed objectives whatever their state, so a ready objective further down kept the badge on with no Claim button anywhere. Write one eligibility function per claimable kind and let the badge, the button and the list all call it. When a list is capped, choose its entries by that function, ready ones first, so every lit badge has a visible action behind it. Things that automation will take on the next tick (auto-claim) are not manual actions. Recompute the badge from state rather than storing a flag, so a claim, refresh, reset or load cannot leave it stale.

## 143.2 Place each effect by the sheet's contact point, the body and the layer, per effect

An actor's world origin is its feet, not its body, and an effect sheet's frame centre is not where it hits. A bolt sheet whose ground ring sits 21 px below the frame centre, centred on the feet and drawn under the actors, appeared to strike below and behind its target. Keep for every effect: an anchor (the actor hit, the area centre, the caster's view, the caster's ground point), the frame row that meets the anchor, a lift to the body that scales with the actor's rendered size, a scale rule and a layer. Strikes and blasts go above the actors; ground novas and markers go beneath them. Put these values in one inspector resource and probe the arithmetic (contact row on the feet, top of the effect above the head) for a normal-sized actor and a 2× boss. A single-target hit plays on the actor it actually hit, not on where the attacker aimed.

## 143.3 A wind-up warning is its own small marker

If a telegraph plays the skill's own effect and sound at the aim and the hit plays them again, every attack shows twice. Players read the first as the hit and the second as a bug. Emit a separate warning event and draw a small, tinted ground marker for it, with no skill sound. The real effect and sound then play once, on resolution, from the authoritative outcome.

## 143.4 Sheet particles with an impact phase freeze at the impact

A world-anchored particle that drifts while its sheet plays a fall and then a splash makes the splash slide along the ground. Mark the first impact frame in the particle's style, and from that frame to the end of the cycle compute the position at the impact frame's time rather than the current time. That keeps the placement a pure function of the clock and the world grid (section 138.3): camera moves still cannot shift it, and the next cycle starts a new drop.

## 143.5 After an unlock, teach the next real tap once

A purchased feature whose control lives elsewhere (a toggle inside a panel) needs one contextual lesson at the moment of purchase. That lesson is a short confirmation in every onboarding mode, then the guide's pointer on the next real tap on that path: the control itself when its panel is open, otherwise the button that opens that panel, otherwise the map. Write a seen flag to the profile at purchase time, so a reload or a second purchase never repeats it. Keep the active hint itself in memory only. End it on the demonstrated action, on Got it, after a finite time on screen, or when it no longer applies. Point only at enabled, visible controls. Keep the explanatory line out of the pointer's path: render it, look at the result, and place the line on the far side of the control from the arrow.

## 143.6 Related HUD information lives with its control, on a dark plate

Map completion in a far corner and a stage-gate line in pale text under the minimap were both missed on device. Group map facts with the map they describe (zoom, explored percentage, minimap, gate progress, in that order) and give each one a compact dark plate from the existing panel art. A plate reads over snow, sand, fog and rain, where an outline alone fails. Check contrast against representative light and dark grounds in a probe (7:1 or better for small text). Let a plate grow away from the screen edge for longer text rather than shrinking the font.

Reusable rule:

> One predicate per claimable thing for badge, button and list; effects placed by contact row, body lift and layer, from data; warnings distinct from hits; impact phases frozen in world space; unlock lessons once, at the next real tap; map facts grouped by the map on dark plates.

# 144. First-profile reveals, onboarding guarantees and completion tracking (LootFarmer Change 15)

## 144.1 A pity guarantee reads the inventory and the ground, never a "dropped" flag

To promise the first item (and a mergeable copy) within N kills without touching drop chances, add a drop after the natural rolls only when nothing suitable came, and derive the step from state: nothing owned or on the ground, one item without a match, a matching pair still on the ground, a pair owned. A natural drop advances the step and restarts the count; supplies and non-matching items never count. Because the ground is part of the state, a drop that expires before pickup lowers the step again and the next eligible kill replaces it. The guarantee must not depend on which enemy the player farms: when the farmed enemy carries nothing that matches, give two copies of its own item, and with a full row a copy of an owned item (a stack needs no slot). Never create item records while checking (here `record()` rolled extras and moved the RNG). Latch it done as soon as a pair is owned, keep it through Prestige and clear it with Hard Reset.

## 144.2 One reveal table for every onboarding mode; hidden buttons keep their place

Progressive menus are first-profile progression (section 18.10), not tutorial depth: Guided, Basic and None share one reveal table, and the mode decides only how much is explained (pointer lessons, short cards that retire after a readable time, nothing). Each step needs the previous one and opens on a demonstrated action, with a player-level backstop so a player who ignores a new menu still gets the next one; a hard blocker (a full inventory) reveals what unblocks it at once, and the gate boss reveals everything left. Latch reveals in the profile. Refuse hidden panels in the one panel opener, so the minimap, the character, an enemy, a camp, a tracker and a banner cannot reach them either. Keep a hidden navigation button's slot (transparent, disabled, ignoring input) so nothing shifts as buttons appear. Mark a new menu with the existing "new" badge until it is opened. Notices for a hidden system stay silent and a single milestone announces its reveal. Offer "Show all menus now" behind a confirmation as the way out.

## 144.3 Completion that survives resets copies the best values as they happen

When run state resets (exploration, camps, items, merge levels), a permanent completion system cannot read it later. Copy the best values into permanent records as they happen (ever obtained, best merge, ever owned, best percent), latch each completed category, and announce only on the latch, so a reload never repeats a banner and a reset never removes progress. Count shared items wherever they apply rather than assigning them to one place. Rewards go into the same bonus pool as the other permanent sources, so every getter applies them once; probe the exact multiplier on HP, damage, coins, XP and chances. A percentage reads 100 only when everything is complete (round down and cap at 99 otherwise).

## 144.4 "100%" must be reachable: measure it

A coverage percentage over a grid can be impossible to complete when cells sit inside solid scenery. Flood-fill the walkable space with the movement rules, find the cells no walking reveal can reach, store them as inspector data, and exclude them from both the count and the area. Keep a tool that recomputes and compares, and a probe that walks every reachable point with the real reveal rule and expects exactly 100% on every map.

## 144.5 Reconcilers must not prune children a control builds itself

A panel that rebuilds off-tree descriptions and reconciles them into live controls will delete any child a live control created in `_ready` (its off-tree description never ran `_ready`). Let such controls opt out of child reconciliation and keep their own children, and probe two in-place refreshes of the open panel.

## 144.6 One sound for a family of notifications, one cooldown for that sound

When several semantic cues share one sound file, give the file a shared cooldown in the audio service as well as each cue's own, or two notifications a frame apart play the same sound twice. Keep the semantic cue ids separate so the inspector can still reassign them.

Reusable rule:

> Guarantees read inventory and ground, add to natural drops and latch once; one reveal table for every mode with stable slots and one opener that refuses hidden panels; permanent completion copies best values and latches; 100% is measured on reachable cells; reconcilers leave self-built children alone; shared sounds share a cooldown.

# 145. Correction lessons (LootFarmer Change 16)

## 145.1 A paused audio player is not "playing": decide music state in one place

In Godot 4 an `AudioStreamPlayer` with `stream_paused` set reports `playing == false`. Code that pauses the music at volume 0 and later resumes it only "if playing" never resumes it: the slider leaves the music off for good, the bug players report. Keep the music in one function that derives the state from three facts (the game wants music, the track has started, it should hold now because the volume is 0 or the game is paused): start the track only when it is neither playing nor paused, otherwise set `stream_paused` from "should hold". Call it from every settings change, from the pause button and when the game scene re-enters, so a reload never restarts the song. The engine also resumes a pausable player by itself when the tree unpauses, so re-apply the state after your own pause toggle. Headless runs often skip decoding; test real playback in a short windowed check, and reproduce the reported bug against the old code once before trusting the new one.

## 145.2 Discarding items needs provenance, or it becomes a farming loop

A "drop to free a slot" action must not turn into a way to earn progress. Drop the whole stack as one ground pile that remembers what it is: its quantity, the run credit it took with it (online-earned copies, per-opportunity collection credit) and that it was dropped. Exclude dropped piles from every automatic pickup (no enemy type owns them), and on pickup add the copies back without any of the "found" side effects (missions, opportunity steps, recent finds, permanent mastery from found copies) and restore exactly the stored credit, never more. Leave the item's record (merge level, rolls) in place, as when stock runs out, so the pile restores the item exactly. Prove it with a loop: drop and pick up ten times and compare every counter, mission, credit and permanent record with the start. Refuse to drop what is equipped.

## 145.3 Probes that read content chosen by the calendar

Daily content selected from the date (a hash of the day picks the missions) can make a probe pass one day and fail the next: a section that performs 200 kills of one enemy also completes whichever daily mission happens to target it and adds a notice the section was not about. Count exactly the signal the section measures (here followed-step notices only), or fix the daily content in the fixture. When a probe starts failing with no code change, check what it reads from the clock before suspecting the game.

## 145.4 Scene text that is a translation key reads raw in code

A Label or Button whose scene `text` is a translation key displays the translation, but code and probes that read `.text` get the key. Set such texts with `tr()` in code when anything reads them back, and let the source validator check that every key used as scene text exists in the catalogue.

## 145.5 Per-map economy growth as two explicit constants

When income and prices both grow per map, keep the two growth factors as named data (income per map, map-tied price per map), apply the price factor through one function used by every map-, enemy- and camp-scoped purchase, and test the ratio "price ÷ income" map by map. A price factor slightly above the income factor makes each map a little more expensive relative to what it pays; a large gap (2 against 1.25) silently makes late upgrades hundreds of kills apart. Document the before/after ratio, because players feel it even when each number looks reasonable.

Reusable rule:

> Derive music state from intent, started and hold, never from "playing"; dropped items carry their provenance and earn nothing back; probes count only what they measure, not the day's content; scene key texts are set with tr() where code reads them; per-map growth is two named constants with a tested ratio.

# 146. Gameplay-only integration and bounded-effect changes

## 146.1 Separate purchased capacity from selected positions

An automation purchase buys capacity; a separate validated assignment owns the positions it operates. Route manual and automatic use through the same action. Validate replacements atomically (unique indices, unlocked/equipped slots, purchased count, action lock). Migrate position-specific purchases into capacity once and define whether empty positions retain a dormant binding. Publish state, methods, return values and refresh events when another implementer owns UI; never add temporary controls or claim the unfinished UI is tested.

## 146.2 Caps belong after all applicable multipliers

An advertised hard ceiling must be enforced in the actual resolver after every relevant skill, target and temporary-buff multiplier. Audit legacy tiers and spare-copy growth too. Test endpoints, intermediate levels, legacy identities, large stock, actual HP loss and the minimum-damage floor. Expose the effective getter so presentation cannot promise uncapped results.

## 146.3 A countdown needs an explicit clock and one owner

For per-encounter countdowns, specify active time, pause, inactive maps, background time and Prestige separately. Persist stable identity, remaining time and spawn location, and advance offline elapsed only once. An actor's visual remaining timer is a mirror, not a second timer owner. Test multiple bosses expiring independently, map travel, saved inactive worlds, legacy actor-only saves, resume and real JSON/disk round trips.

## 146.4 Measure ambient work without asserting an Android bottleneck

Compare the original and optimized implementation using the same camera rectangles and timestamps. Reuse repeated-grid particle calculations and frame buffers before reducing density or changing appearance. Capture invariant visibility inputs once per draw. Include weather-to-dry transitions so redraw throttling cannot leave stale commands visible. Measure simulation costs separately: later wet maps often also contain more actors. Headless CPU results cannot establish mobile GPU overdraw or device FPS; report that boundary and leave device profiling explicit.
