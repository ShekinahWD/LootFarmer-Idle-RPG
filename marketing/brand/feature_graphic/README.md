# LootFarmer feature graphic: editable source (Change 28)

The Google Play feature graphic is a **layered composition** described in JSON and rendered by one
Python script from the game's own art. Nothing is painted by hand, and there is no Photoshop step.
Everything here is outside Godot's import (`marketing/brand/.gdignore`) and outside the Release export
(`marketing/*` in the preset's exclude filter; `tools/export_manifest.py --check` still lists 232 files).

## Reproduce

```powershell
python marketing/brand/feature_graphic/compose_feature_graphic.py           # concepts, final, portrait preview
python marketing/brand/feature_graphic/compose_feature_graphic.py final     # only the store graphic
python marketing/brand/feature_graphic/make_review.py                       # review sheets + docs/Change_28_Evidence copies
python marketing/brand/feature_graphic/compose_feature_graphic.py --check   # 1024x500, RGB (no alpha), PNG, size limit
```

Requirements: Python 3 with Pillow (the same as `marketing/brand/compose_brand.py`). Output is
deterministic: the same JSON gives the same bytes (final SHA-256 `2510ca436aec94e3515520a365b3a61059e991afa342d45fd8d5ce19ae50775f`).

| File | What |
|---|---|
| `compositions/final.json` | **The store graphic.** 16 named layers, back to front, canvas-pixel coordinates. |
| `compositions/concept_a_loot_bridge.json`, `concept_b_wardrobe.json`, `concept_c_boss_drop.json` | The three explored concepts (A was selected). |
| `compositions/portrait_endcard_preview.json` | Static 1080x1920 framing study for a *future* trailer end card. |
| `components.json` | Shared pieces: actors (catalog outfit + weapon + frame), wordmark style, slot panel, spark sheet, tree boxes. |
| `concept_scores.json` | The internal selection rubric and marks. |
| `format_json.py` | Rewrites the JSON one layer per line after scripted edits. |
| `licenses/LilitaOne-OFL.txt` | Wordmark font licence (SIL OFL 1.1). |

Outputs (ignored `store_assets/branding/`): `feature_graphic_1024x500.png` (the upload file),
`review/concepts/*.png`, `review/feature_graphic_*.png`, `feature_graphic_manifest.json` (hash per output) and
`source_layers/final/NN_<layer>.png` + `source_layers/portrait_endcard_preview/` (**every layer alone, full canvas,
transparent**: drop them into a video or image editor as-is).

## Editing

Open `compositions/final.json`; each line is one layer. Common edits:

- **Move/resize a character:** `"at": [x, y]` is where its *feet* stand; `"scale"` is a whole number (pixel art is
  only ever scaled by integers with nearest-neighbour sampling).
- **Swap the featured enemy/loot:** change `actors.dino_boss` / `actors.player_dino` in `components.json` and the two
  `slot` items. Keep `from_group`: the script **refuses** a weapon or outfit that enemy does not carry or drop
  (catalog `groups[].weapon/body/loot`).
- **Pose:** `"frame": [row, col]` on the 24x24 sheet (row 0 idle, row 3 the effort face) and `"swing": n`, the
  64x32 attack frame drawn over the body exactly as `scenes/game/actor.tscn` places it. Frame 0 + normal face is the
  game's attack wind-up; frame 2 + row 3 is the contact frame (big crescent, hides the face at this size).
- **Wordmark:** `components.json > wordmark` (text, font, size, two-tone fill, outline, stepped depth) and
  `components.json > subtitle` ("IDLE RPG": same font, outline colour and stepped depth, smaller, letter-spaced,
  cream-to-gold). Together they spell the approved title **LootFarmer: Idle RPG**; the composer adds no other copy.
  A `wordmark` layer picks a style with `"style": "subtitle"`; `tracking` is letter spacing in pixels.
- **Colour treatments:** `tint` + `tint_amount` (multiply), `darken`, `opacity`, `rim` (1 source-pixel outline),
  `glow` (soft light), `band` (gradient shade), `vignette`.

Layer types: `sky`, `tiles`, `props`, `actor`, `item`, `slot`, `spark`, `glow`, `band`, `vignette`, `wordmark`.

## Play Console placement notes

Google: JPEG or 24-bit PNG (no alpha), 1024 x 500; focal point toward the centre; brand and key elements out of
"cutoff zones"; background at the edges; the graphic is the **cover of the preview video with a play button over
it**. Google gives no measurements, so `make_review.py` checks a conservative simulation (88 px centred button,
10% side and 8% top/bottom bands): the wordmark, both slots and both players' bodies stay inside. Keep that true
when moving layers.

## Final layers (back to front)

| # | Layer | Source art |
|---|---|---|
| 00 | ground | `Summer/Basic Tiles 1.png` sand tiles (336..416, 0), x4, warm tint |
| 01 | back_trees | `Summer/Basic Tiles 4 (Trees & Bushes).png` big trees, x3/x4, dusk tint |
| 02 | sunset_light | colour treatment |
| 03 | title_shade | colour treatment (keeps the title on a dark field) |
| 04 | boss | Teal Dinosaur outfit sheet `Special 3 v1.png` (catalog `boss-teal-dinosaur_outfit`), Iron Sword swing `Iron set/Sword 2 64x32.png` frame 0, `Shadow.png`, x12, facing the plain player; feet at y = 334 so a video play button (centre) falls on its torso, not its face |
| 05 | ground_shade, 06 vignette, 07 loot_glow | colour treatments |
| 08 | slot_weapon | Kenney `panel-014.png` (the game's Slot style) tinted by tier 3 colour; `iron_sword` icon from `16x16 All Items v1.png` |
| 09 | slot_outfit | same panel, tier 2 colour; `boss-teal-dinosaur_outfit_t2` portrait (its sheet's first cell, as the inventory shows it) |
| 10 | sparks | `Sparks 25x27.png` frames 6/9/11 (the game's loot sparkle) |
| 11 | player_before | `Basic character v2.png` (the plain player body) + Wood Sword swing frame 0, x8 |
| 12 | hero_glow | colour treatment |
| 13 | player_after | the same player wearing `boss-teal-dinosaur_outfit_t2` with `iron_sword` (wind-up frame), x11 |
| 14 | wordmark | "LootFarmer", Lilita One (OFL), gold two-tone fill, dark outline, 10 px stepped depth |
| 15 | subtitle | "IDLE RPG", Lilita One 46 px, 7 px tracking, cream-to-gold fill, the same dark outline and 5 px depth; drawn in front, tucked into the title's extrusion (ink y 135..187), clear of the boss's eyes and the simulated play button |

## Future portrait trailer end card (plan only; no video was made or changed)

The landscape graphic must **not** be stretched or cropped into 9:16. Recompose the same layers
(`source_layers/final/` or, better, re-render `portrait_endcard_preview.json`, which already restages them):

- **Canvas 1080x1920.** Safe margins: 90 px left/right, 220 px top, 300 px bottom (platform UI and captions).
- **Title:** wordmark at 168 px Lilita (about 840 px wide), centred at y = 640 (upper third), on the dark top shade;
  "IDLE RPG" subtitle at 62 px (9 px outline, 7 px depth, 10 px tracking) centred at y = 758, tucked under it.
- **Story, top to bottom:** boss (x17) centred at feet y = 1260; the two slots (156 px) just in front at y = 1336;
  plain player (x11) bottom-left and outfitted player (x14) bottom-right, feet at y = 1640.
- **Background:** the same Summer sand, tiled at x5 to fill the height (tile, never stretch); trees across the top
  behind the title shade; sunset glow centred lower (y = 1000) so the title stays on dark.
- **Suggested motion (future task):** 1) background + boss fade in from black over the trailer's last gameplay
  shot; 2) the two slots drop in with the spark frames played as the in-game 16-frame animation; 3) the plain player
  is shown, then the outfitted player appears (a hard swap reads as "equipped", like the game); 4) the wordmark
  fades/scales in last, the subtitle a beat after it, and both hold at least 1.5 s. Keep the music under it per Playbook 133.2/133.3.
- Static framing preview: `store_assets/branding/review/feature_graphic_portrait_endcard_preview.png`
  (copy in `docs/Change_28_Evidence/`). It is **not** the Play feature graphic and **not** a trailer frame.
