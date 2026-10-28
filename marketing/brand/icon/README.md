# LootFarmer app icon: editable source (Change 30)

One layered JSON composition renders the **Google Play icon** and every **Android launcher layer** from the
game's own art. Nothing is painted by hand and there is no image-editor step. The folder is outside Godot's
import (`marketing/brand/.gdignore`) and outside the Release export; only the four runtime PNGs in
`assets/branding/` ship.

## Reproduce

```powershell
python marketing/brand/icon/compose_icon.py            # 3 concepts + final + review sheets + docs/Change_30_Evidence copies
python marketing/brand/icon/compose_icon.py final      # only the final (+ review sheets)
python marketing/brand/icon/compose_icon.py --check    # format checks + a fresh render must equal the written bytes
```

Requirements: Python 3 with Pillow and NumPy. Output is deterministic (the check re-renders and compares bytes).
The game-art engine is imported from `marketing/brand/feature_graphic/compose_feature_graphic.py`, so actors,
rims, item icons, sparks and the `from_group` truth guard behave exactly as in the feature graphic.

`marketing/brand/compose_brand.py` (the rejected Change 27 icon) no longer renders unless given
`--legacy-change-27`; its `--check` still validates the same files for `finalize_store_assets.py`.

## Outputs

| Output | Path | Spec |
|---|---|---|
| Google Play icon | `store_assets/branding/play_icon_512.png` (ignored; tracked copy `docs/Change_30_Evidence/`) | 512 x 512, 32-bit RGBA PNG, fully opaque, full square (Play adds the 30% corner radius and shadow) |
| Legacy launcher + project icon | `assets/branding/launcher_192.png` | 192 x 192 RGBA, opaque full square; Release `launcher_icons/main_192x192` and `config/icon` |
| Adaptive background | `assets/branding/adaptive_background_432.png` | 432 x 432 (108 dp), opaque |
| Adaptive foreground | `assets/branding/adaptive_foreground_432.png` | 432 x 432, transparent; all art inside the 72 dp viewport, key art inside the 66 dp safe zone |
| Adaptive monochrome | `assets/branding/adaptive_monochrome_432.png` | 432 x 432, white on transparent (Android 13+ themed icon) |
| Every final layer alone | `store_assets/branding/source_layers/icon_final/NN_<layer>.png` | 512 x 512 transparent, for later editing |
| Review sheets | `store_assets/branding/review/icon/` | concept cards, `icon_concepts.png`, `icon_before_after.png`, `icon_small_sizes.png`, `icon_adaptive_masks.png` |
| Hashes | `store_assets/branding/icon_manifest.json` | bytes + SHA-256 per output, safe-zone measurements |

The runtime paths are the Change 27 ones, so `project.godot`, `export_presets.cfg` and `tools/export_rules.json`
did not change.

## The unit grid

Compositions are drawn on a **32 x 32 grid; one unit is one source pixel** of the game art. Each target renders
the same grid at a whole-number scale, so pixel art is never resampled by a fraction:

| Target | Size | px per unit | Grid shown |
|---|---|---|---|
| Play | 512 | 16 | the whole grid |
| Legacy launcher | 192 | 6 | the whole grid |
| Adaptive layers | 432 | 9 | the grid plus 8 units of bleed per side (108 dp); the grid is the 72 dp viewport |

The 66 dp safe zone is the circle of radius 14.67 units around (16, 16). Layers marked `"key": true` must stay
inside it (`--check` measures it); every front-plane layer must stay inside the viewport.

## Editing `compositions/final.json`

Each line is one layer, back to front. Back-plane types (`gradient`, `rays`, `glow`, `vignette`, `fill`) form the
adaptive background; front-plane types (`actor`, `item`, `sparkle`, `spark`) form the foreground and the themed
icon. All back layers must come before the front layers (the composer refuses otherwise), so the adaptive split
always equals the Play icon.

- **Move the hero:** `"at": [x, y]` is where its feet stand, in units. `"scale"` is a whole number.
- **Swap outfit or weapon:** change `actors.player_dino` in `../feature_graphic/components.json` or override it
  in the layer; keep `from_group`: the composer refuses an outfit or weapon that enemy does not carry or drop.
- **Pose:** `"override": {"frame": [row, col], "swing": n}`; frame `[0, 0]` + swing 0 is the game's attack
  wind-up with the face visible.
- **Light:** `sky.top/bottom`, `sun.radius/strength/color`, `rays.count/strength`, `vignette.strength`. Add
  `"pixel": true` to quantise a treatment per unit, and `"steps"` to band a glow (tried, rejected as noisy).
- **Twinkles:** `sparkles.items` = `[x, y, scale]`; `box` is the single cross cut from frame 0 of
  `Sparks 25x27.png`. At scale 2 it read as a medical plus, so the final uses scale 1.
- **Themed icon:** `monochrome.cut` (luminance below which a pixel counts as dark outline) and `monochrome.edge`
  (units of outer outline kept filled; interior dark pixels deeper than that are carved out as detail).

## Final layers (back to front)

| # | Layer | Source |
|---|---|---|
| 00 | sky | colour treatment: plum to rust gradient |
| 01 | rays | colour treatment: 12 faint sun rays |
| 02 | sun | colour treatment: amber glow behind the hero |
| 03 | vignette | colour treatment |
| 04 | hero | Teal Dinosaur outfit t2 (`Characters 24x24/Special 3 v1.png`, catalog `boss-teal-dinosaur_outfit_t2`, the boss's real drop) + Iron Sword swing frame 0 (`PixelPlainsAnimationPack/Iron set/Sword 2 64x32.png`, catalog `iron_sword`, the boss's weapon), laid out as `scenes/game/actor.tscn`, 1-pixel dark rim |
| 05 | sparkles | one cross from `PixelPlains/Sparks 25x27.png` frame 0, the game's loot sparkle |

Concepts: `concept_a_costume_hero.json` (selected and refined), `concept_b_loot_drop.json`,
`concept_c_close_up.json`; marks in `concept_scores.json`.
