# Change 78 evidence

Desktop renders at 540x960 (9:16) and 432x960 (about 20:9) from tests/change_78_capture.tscn (not Android validation):

- 01 An equipped Iron Sword ^7: the next merge's gain sits in green beside the stat ("Damage 16.46 +0.29"); the separate "Next merge" line is gone.
- 02 A stored outfit on the comparison card: "Maximum health 32.64 +0.41" next to the red equip delta. At 432 px the green gain wraps under the value inside the card.
- 03 The same sword at its merge cap: no gain, the stock bonus line instead.
- 04 A Gray Cat outfit collected from its boss: two gold "★ Boss bonus" attributes, a Reroll for each slot and the boss-gear explanation.
- 05 The Health Potion panel.
- 06 The Health Potion name over the hero after use, in the game theme's MSDF font (it used the engine's raster fallback font at 10 px before, enlarged by the camera zoom).
- 07 Red Fox's automation upgrades: Auto-Collect 10 Gems and gear Auto-Merge 15 Gems (were 40 and 60).

Text rendering (offscreen renders, not phone photos):

- `1080x1920_supply_text_before_after.png`: the game rendered at 1080x1920 (a 1.5x phone), Coin Tonic panel, cropped and enlarged 2x. Top: labels on the UI root's inherited nearest filtering (before). Bottom: Change 78 linear filtering for text. The pixel coin icon is identical in both.
- `font_filter_msdf_3x.png`, `font_filter_msdf_2x.png`: the theme font at 3x and 2x stretch; rows: nearest MSDF (before), linear MSDF (after), and a raster (non-MSDF) copy for reference.
- `font_scaled_label_msdf_vs_raster.png`: a label scaled 1.8x: MSDF stays sharp, a raster font blurs, which is why the font stays MSDF and the filtering changed instead.
