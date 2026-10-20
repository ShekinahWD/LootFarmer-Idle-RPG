# Store Screenshot Capture

Reusable Godot 4.x editor-runtime addon for generating Play Store screenshot sets from the same live game state.

## Features

- Phone, 7-inch tablet, 10-inch tablet, and desktop target checkboxes.
- Landscape 16:9 or Portrait 9:16 capture with one selection.
- Editable per-target landscape resolution presets; Portrait swaps width/height automatically.
- `Capture UI` is ON by default.
- UI-off captures hide only nodes explicitly assigned to the configurable `store_screenshot_ui` group.
- Optional filename override. When blank, filenames are generated from the destination category and shot number.
- Automatic shot numbering across existing output folders.
- Overwrite protection.
- PNG output.
- Game is paused while the selected target set is captured so the same gameplay moment is preserved.
- Original window size, pause state, registered UI visibility, and capture overlay visibility are restored after capture.
- Runtime overlay is **editor-runtime only**. It appears when the project is run from Godot Editor and does not appear in exported Android/desktop builds, including debug exports.
- F10 toggles the runtime capture panel.

## Install

1. Copy `addons/store_screenshot_capture/` into any Godot project.
2. Enable **Store Screenshot Capture** in `Project > Project Settings > Plugins`.
3. Configure defaults in the **Store Capture** editor dock.
4. For UI-free screenshots, assign the root UI nodes you want hidden to the node group configured in the dock. Default: `store_screenshot_ui`.
5. Run the game from the Godot editor. The capture overlay appears in the upper-left. Exported builds (including Android debug builds) do not show the overlay.

## Capture workflow

1. Prepare the gameplay/menu state you want.
2. Choose Landscape or Portrait.
3. Choose Phone / 7-inch tablet / 10-inch tablet / Desktop.
4. Leave **Capture UI** enabled for normal store screenshots, or disable it for gameplay-only shots.
5. Optionally enter a filename override. Leave it blank to use the automatic destination-based name.
6. Press **CAPTURE SELECTED**.
7. Change the game state and repeat.

Default output structure:

```text
res://store_assets/screenshots/
  landscape/
    phone/
    tablet_7/
    tablet_10/
    desktop/
  portrait/
    phone/
    tablet_7/
    tablet_10/
    desktop/
```

Default filename examples:

```text
landscape/phone/Phone_01.png
landscape/tablet_7/Tablet_7_01.png
landscape/tablet_10/Tablet_10_01.png
landscape/desktop/Desktop_01.png
landscape/desktop/Desktop_02_no_ui.png
```

If the filename field is filled manually, it replaces the automatic `Destination_#` basename for every selected target. For example, entering `PrestigeChoice` produces:

```text
landscape/phone/PrestigeChoice.png
landscape/tablet_10/PrestigeChoice.png
landscape/desktop/PrestigeChoice.png
```

When `Capture UI` is off, `_no_ui` is still appended to avoid collisions, e.g. `PrestigeChoice_no_ui.png`.

The addon creates `.gdignore` under the screenshot root so generated images are not imported into the game as assets.

## Default resolution presets

| Target | Landscape | Portrait |
|---|---:|---:|
| Phone | 1920x1080 | 1080x1920 |
| 7-inch tablet | 1920x1080 | 1080x1920 |
| 10-inch tablet | 2560x1440 | 1440x2560 |
| Desktop | 2560x1440 | 1440x2560 |

These are editable project defaults, not hardcoded requirements.

## UI group rule

The addon intentionally does **not** hide every `Control` or `CanvasLayer`, because games often use those node types for world-space HP bars, labels, markers, or effects.

Only roots in the configured group are hidden when `Capture UI` is unchecked. This makes the addon game-independent and prevents accidental loss of world-space presentation.

## Runtime validation

The addon changes the actual game window size before each screenshot, waits several frames for responsive layout to settle, then captures the viewport. This validates the game's real responsive behavior rather than resizing a screenshot after the fact.


## Godot embedded-game note

Godot 4.7 can run the game embedded in the editor with a fixed viewport size. A fixed embedded viewport prevents a true multi-resolution screenshot even if the window area changes. For reliable captures, use a floating/unembedded game window or an embedded sizing mode that allows the viewport to resize.

The addon verifies the rendered image dimensions after every resize. If Godot renders a different size than requested, that target fails with an explicit message instead of silently saving a mislabeled screenshot.


## Export safety fix (v1.0.1)

The runtime gate uses Godot's `editor_runtime` feature rather than `OS.is_debug_build()`.
This distinction is important: exported Android debug builds are still `debug` builds, but they are export-template (`template`) builds, not `editor_runtime`. Therefore the capture overlay is never created there.


## Filename behavior (v1.0.2)

When the filename override is empty, each destination uses its own category prefix plus the shared shot number:

- `Phone_#`
- `Tablet_7_#`
- `Tablet_10_#`
- `Desktop_#`

The next-shot scanner recognizes this format and still recognizes the older v1.0.x numeric-prefix files for backward compatibility. Manually named files intentionally do not participate in automatic number discovery because they do not encode a shot number.


## Shared capture helper and larger-than-screen targets (v1.1.0)

The capture steps live in `viewport_capture.gd` (window sizing, settle and readback with the exact-size check, UI-group hiding and restore, PNG writes that never overwrite, `.gdignore`). The command-line Marketing Capture runner (`addons/marketing_capture/`) uses the same file, so the two tools never diverge.

Windows clamps a game window to the screen. `fit_window()` raises the window's maximum size first, so a 2560x1440 tablet or a 1080x1920 portrait target captures at its real size on a 1920x1080 monitor; the previous maximum is restored afterwards. Validated in Growing Kingdom on Godot 4.7.2 (Windows 10, 1920x1080 at 125% scaling).
