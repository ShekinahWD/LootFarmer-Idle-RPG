# LootFarmer v0.3.1 asset and presentation registry

## Shared actor

`scenes/game/actor.tscn` and `scripts/game/actor_view.gd` own presentation only. The simulation owns all contact, health, loot and timing. The scene separates ground shadow, visual body, weapon, player marker, health, hit text and speech. Selected outfit sheets already contain body and clothing pixels; there is no fabricated independent clothing/expression layer. Item icons use the same authored identities and first body frame.

All chosen character sources are under `assets/PixelPlains/Characters 24x24/`:

| Role | Source |
|---|---|
| Unclothed player | `Basic character v2.png` |
| Sprout outfit/enemy | `Character 1 v2.png` |
| Robot outfit/enemy | `Character 18 v2.png` |
| Dinosaur outfit/enemy | `Special 3 v2.png` |
| Death | `Autumn 4 v2.png` |
| Black cat | `Gato 4 v2.png` |
| Ground shadow | `Shadow.png` (17×6; use the full texture, not a 24×24 region) |

The chosen sheets are 216×120 with 24×24 cells. Source-frame inspection distinguished the mostly stationary first row from the four lifted-leg poses on the second row. This mapping was corrected during QA; filenames alone were not treated as evidence.

| State | Mapping, zero-based | Behavior |
|---|---|---|
| Idle | row 0, columns 0–7, 5 FPS | Loop |
| Move | row 1, columns 0–3, 10 FPS | Loop only during actual movement |
| Armed attack | PixelPlainsAnimationPack tool/hands sheets, 64×32, all 8 frames | One-shot; first slash (frame 2) starts at simulation contact |
| Death | row 2, columns 0–8, 12 FPS | Clamp to last frame; hide at 1 second; no looping |

Horizontal mirroring supplies facing. Ground origin remains fixed; the body offset is (0,−10), and the animated tool layer sits at (0,−14) with its native pixel scale. Hit flash and damage text follow the authoritative contact. Unarmed actors hide the weapon. The normal contact is at 0.22 seconds; the eight-frame sequence finishes at 0.88 seconds. Upgraded attack speed shortens both contact and presentation together. These outfit sheets have no dedicated matching attack row, so their idle body remains under the full animated weapon/hands layer. Unarmed actors retain a small presentation-only lunge; no weapon is fabricated. Manual movement/death cancels pending contact. The runtime probe traverses all four walk poses and verifies the visible-death boundary.

Body/outfit-specific expressions are baked into these sheets. Dedicated modular attacks with every outfit are not claimed. The authored movement-pose lunge is the deliberate first-playable fallback, keeping outfits aligned instead of overlaying unrelated 64×32 bodies.

## Items and world

- Sword icons: `assets/PixelPlains/Items/16x16 All Items v1.png`, **32×32 item cells**, despite the filename. Wooden/Stone/Iron regions are (0,0,32,32), (32,0,32,32), (64,0,32,32).
- Death's dark scythe: Onix set `Scythe 7 64x32.png`; atlas region (144,16,32,16) includes the inspected broad tool pose. This is the resting weapon only; attacks use the entire eight-frame Scythe 7 sheet.
- Health Potion/Coin Tonic: supplied Cartoon GUI colored red/yellow potion icons. These are the prototype's explicit consumable-art selection; no new item categories were inferred from icon sheets.
- Grass/path/flowers/camp sign: inspected regions in `Basic Tiles 1.png`. Trees: `Basic Tiles 4 (Trees & Bushes).png`.
- Terrain/decoration is scene-authored in `world.tscn`, not regenerated during gameplay. Edit its Sprite2D placement to tune composition. Enemy/group balance and positions are data-authored in `data/game/catalog.json`; that file is authoritative for spawning.

## Interface

The Cartoon GUI Pack supplies surfaces, controls, joystick, font, player marker and sparse sounds. `resources/game/theme.tres` contains shared styles. The actor's small health fill is an explicitly authored StyleBoxFlat; this project has not imposed an asset-only restriction. Floating text and health values are presentation, not new rewards.

Derived files under `resources/game/art/` resize these supplied textures solely for correct nine-slice border dimensions:

| Derived file | Source under `assets/GUIPackCartoon/Demo/Sprites/` | Size |
|---|---|---|
| panel.png | Shapes/Shapes/Rectangle/Rounded Rectangle - 256px.png | 64×64 |
| slot.png | Buttons/Square/Dark.png | 64×64 |
| button.png | Buttons/Rectangles/Teal.png | 130×50 |
| pressed.png | Buttons/Rectangles/Blue.png | 130×50 |
| disabled.png | Buttons/Rectangles/Gray.png | 130×50 |

Original assets are unchanged. Reuse remains scoped to this game project under the supplied asset licenses.

## Editor verification

- Open `main.tscn`: the top bar, map viewport, dock rows, navigation, sheet and dialog are visible authored nodes.
- Open `slot.tscn`/`action_row.tscn`: dimensions, icon/count placement and button styles are editor-editable; runtime instantiates and binds these templates.
- Open `actor.tscn`: body/weapon offsets, shadow, animation fields, hit text and marker are inspectable without starting combat.
- Runtime respects scene-authored terrain and attachment offsets. The management sheet's position/size is intentionally responsive to the map rectangle; its inset is exported on the root UI script.
- Dynamic list length, item definitions and actor populations are data driven rather than manually duplicating scenes.

## v0.3.1 visual correction mapping

- Wooden Sword: `PixelPlainsAnimationPack/Wood set/Sword 1 64x32.png`.
- Stone Sword: `PixelPlainsAnimationPack/Onix set/Sword 7 64x32.png` (dark tool variant; no Stone set exists).
- Iron Sword: `PixelPlainsAnimationPack/Iron set/Sword 2 64x32.png`.
- Death: `PixelPlainsAnimationPack/Onix set/Scythe 7 64x32.png`.
- Each attack sheet is 512×32, eight 64×32 cells. Native orientation faces right; mirror the complete Visual branch for left. First slash at frame 2; later poses are recovery and never apply extra damage. Simulation owns windup/contact. Tools remain native size during attacks; resting weapon visible bounds fit 12 world units.
- Catalog icons crop transparent padding once and cache their atlas region. Inventory fits cropped icons to existing slots. Ground loot fits a 14-world-unit box, independent of source resolution; potion/tonic no longer inherit a fixed half-scale.
- Currency header uses Cartoon GUI `Icons/Icons Colored/Coins/Coin.png` and `Gems/Gem - Blue.png`, in 32×32 controls.
- Main HP uses a 12px-high flat style with 3px corners. Actor fills are per-instance: player green, enemies red.
- Camera follows the exact player position on both axes. Existing grass source supplies a surrounding backdrop at map edges. Zoom is a saved setting: default 2×, minimum original 1×, maximum 3×, step 0.25×. Zoom also works while explicitly paused. Hard reset restores 2×.

## v0.3.2 camera input

`map_gestures.gd` owns only map-origin pointers, with a 10px drag threshold and at most two touch pointers. The editor-authored GestureSurface sits behind the joystick/history/zoom controls. The zoom slider uses a 60px-high touch control and a 28px teal SVG handle (`resources/game/art/zoom_handle.svg`), an authored interface primitive. Pinch and slider share SettingsState.camera_zoom without recursive value-change signals.


## v0.4.0 map and text

- Ground/details/path borders: Basic Tiles 1.png (16px cells; path border square at 320,96; dark woodland border at 400,144).
- Stone court border: Basic Tiles 2.png at 400,192,48,48; matching 16px paving detail cells at y=256.
- Pond border: Basic Tiles 3 (Water).png at 640,192,48,48; matching water detail cells at y=144.
- Camp shrine: Props.png fountain region 176,272,48,64 plus bench 64,0,48,48. Selected camp adds the supplied planter marker and a gold Selected label; unowned shrine is dimmed.
- Native 16px tiles are baked into editable TileMapLayers by tools/build_map.gd. No giant stretched grass sprite remains. Large trees are scenery beyond the existing walkable bounds.
- BPreplayExtendedBold.otf enables MSDF through its import settings; world/actor labels explicitly override nearest-neighbor filtering with linear filtering. This changes font rendering, not pixel-art sprite filtering.


## Approved implementation revision — 0.5.0

The current interface, XP progression, stored-weapon bonuses, three-column enemy variants, worn-gear drops and schema-2 migration are specified in `LootFarmer_v0.5.0_Notes.md`. Those rules supersede earlier single-group map/UI and equipped-only stat descriptions. Test evidence is in `Progression_UI_Evidence/`. Physical-phone visual review and a complete natural run remain pending.


## v0.6.3 asset implementation reference

The detailed current mapping is in Reusable_Game_Development_Playbook.md section 22.4: actor rows/frames, attack segments/contact, exact currency crops, Kenney panel-014/015 slices, fonts and removal of GUIPackCartoon dependencies. Generated higher-tier items keep a catalog `art_id` and `family`; use `art_id` for sprites, icons and attack mapping, while gameplay uses the unique item ID. Tier backgrounds come from `progression.tier_colors`, with explicit tier in item details. This section supersedes historical references to Cartoon GUI Pack for LootFarmer. Phone visual acceptance remains separate from headless verification.
