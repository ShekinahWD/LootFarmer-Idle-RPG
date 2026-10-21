# LootFarmer — Current Asset Registry — Change 2

Source: lootFarmer(6).zip, audited 2026-10-20. Supplied does not mean integrated. Historical mappings are archived under history/pre_change_2 and must not override this status.

## Existing visual baseline

The implemented interface uses Kenney Fantasy UI, not the retired Cartoon GUI interface. Current exact crops, nine-slices, fonts and actor mapping are recorded in Playbook section 22.4 and implemented resources. Cartoon GUI references in old notes are historical. Keep game-specific future mappings here.

PixelPlains selected characters: Basic character v2 (player), Character 1 v2 (Sprout), Character 18 v2 (Robot), Special 3 v2 (Dinosaur), Autumn 4 v2 (Death), Gato 4 v2 (cat). Current actor sheets use 24×24 cells within 216×120 sheets. Historical verified mappings: idle row 0 columns 0–7, movement row 1 columns 0–3, death row 2 columns 0–8. Weapon attack sheets are eight 64×32 cells; contact is simulation-owned. Preserve established mappings until actual playback review supports a change.

54 v2 character appearances are available, not 54 guaranteed enemy species. Environment tiles, props, items, weapon animation sets and UI resources are included. Final enemy/area assignments remain open. Existing scene-authored world terrain is the prototype; supplied art does not create final maps automatically.

## Magic Spells VFX Lite — supplied, not wired

Root: assets/magic-spells-vfx-lite/. Author: Willosuna. README, manifest and LICENSE included. All cells 64×64 RGBA; single-row sheets. Separate frames match the following counts.

| Effect | Sheet size | Frames | Frame time | Loop | Planned skill |
|---|---|---|---|---|---|
| cast | 512×64 | 8 | 70ms | No | Arcane Focus |
| impact | 512×64 | 8 | 60ms | No | Arcane Strike |
| fire_impact | 704×64 | 11 | 70ms | No | Fire Burst |
| ice_shatter | 768×64 | 12 | 70ms | No | Frost Burst |
| zap | 512×64 | 8 | 60ms | No | Lightning Strike |
| heal | 768×64 | 12 | 80ms | Yes | Heal |

Use manifest paths `<effect>/<effect>_sheet.png`. Stop Heal after the intended cast presentation. Visual loops and frame counts never control repeated rewards/damage. Check ground anchors, scaling, readability and simultaneous casts on device before acceptance.

## Magic Spells SFX Lite — supplied, not wired

Root: assets/magic-spells-sfx-lite/. Includes manifest, README, license and 30 WAV/OGG pairs. WAV headers verify mono 44.1kHz; durations 0.53–2.71s. Choose one playback encoding per sound for the shipped runtime; do not count both formats as separate variations.

Primary mappings: cast/cast_01, impact/impact_01, fire_impact/fire_impact_01, ice_shatter/ice_shatter_01, zap/zap_01, heal/heal_01. Remaining 24 families are optional resources, not approval to add 24 spells. Reuse AudioService semantic events; author effect priority/overlap/volume rules so enemy swarms do not drown out feedback. Listening and target-device mix acceptance remain pending.

Both spell licenses allow personal/commercial projects, editing and optional attribution. Do not redistribute standalone raw asset collections. Preserve licenses with source. This documentation-only patch contains no asset copies.

## Other audio and provenance

assets/sounds contains 16 WAVs: background music; six Castle_Damage clips; defeat; mission_ready; move_command_units; move_command_villager; reveal_unlock; stage_clear; ui_click; ui_confirm; ui_error. They have no accompanying folder license or confirmed byte-identical source elsewhere in ZIP 6. Keep pending source/license verification and listening review; do not silently replace current Audio/button and Audio/prestige mappings.

Kenney, spell packs, fonts and toolkit font licenses are included. PixelPlains and the new generic audio need explicit retained provenance/license evidence before release. Original purchase files may supply it; absence here is not a claim of prohibited use.
