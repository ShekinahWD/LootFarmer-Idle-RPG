# LootFarmer — Current Asset Registry — Change 30

## Store listing and launcher branding (Change 27, 2026-10-28)

**Runtime (tracked, ships):** `assets/branding/launcher_192.png` (project `config/icon` and Android `launcher_icons/main_192x192`), `adaptive_foreground_432.png` (transparent, content inside the 288 px safe zone), `adaptive_background_432.png` (opaque), `adaptive_monochrome_432.png` (white on transparent, Android 13 themed icon). They replace the REL-01 placeholder: `icon.svg` stays in source but no longer ships. Registered as roots in `tools/export_rules.json` (the generator then lists 232 files); verified in the signed `LootFarmerIdleRPG.27.aab` as `base/res/mipmap-*/icon*.webp`.

**App icon (Change 30, tracked source, never ships):** `marketing/brand/icon/` (`compose_icon.py`, `compositions/final.json`, three concepts, `concept_scores.json`, `README.md`) writes the same five files as Change 27 (the four runtime PNGs above and the Play icon), so no project, preset or allowlist path changed. Elements: Teal Dinosaur outfit t2 (`Characters 24x24/Special 3 v1.png`, frame [0, 0]), Iron Sword swing frame 0 (`PixelPlainsAnimationPack/Iron set/Sword 2 64x32.png`), one twinkle from `Sparks 25x27.png` frame 0; colour treatments only (gradient, rays, glow, vignette, 1-pixel rim); no font. 32-unit grid rendered at 16/6/9 px per source pixel (Play/legacy/adaptive). Report: `docs/LootFarmer_Change_30_Report.md`; evidence `docs/Change_30_Evidence/`.

**Change 27 composition source (record only, renders nothing without `--legacy-change-27`):** `marketing/brand/compose_brand.py` + `brand_config.json`. Elements, all existing game art scaled by whole numbers with nearest-neighbour sampling: player in the Sprout outfit (`Characters 24x24/Character 1 v1.png`, idle frame), Sunflower (`Spring 2 v1.png`), helper Sprouts with the game's `helper_tint`, `Shadow.png`, item icons from `Items/16x16 All Items v1.png` (Emerald Sword, Diamond Axe/Sword, coin, gem at the catalog/resource regions), Spring grass/path tiles (`Basic Tiles 1.png`) and trees (`Basic Tiles 4 (Trees & Bushes).png`). Wordmark "LootFarmer" in Noto Sans weight 800 (toolkit copy, SIL OFL 1.1). No AI-generated or external imagery.

**Feature graphic (Change 28, tracked source, never ships):** `marketing/brand/feature_graphic/` replaces the Change 27 composition (kept in `compose_brand.py`/`brand_config.json` as the record; the rejected file is `docs/Change_27_Evidence/feature_graphic_1024x500.png`). Elements: Teal Dinosaur outfit sheet `Characters 24x24/Special 3 v1.png` (boss and outfitted player), `Basic character v2.png` (plain player), Iron and Wood sword swings from `PixelPlainsAnimationPack` (frame 0), `iron_sword` icon from `Items/16x16 All Items v1.png`, Kenney `panel-014.png` slot (CC0) in catalog tier colours, `Sparks 25x27.png`, Summer sand tiles and trees, `Shadow.png`. Title "LootFarmer" with the subtitle "IDLE RPG" (approved name *LootFarmer: Idle RPG*) in Lilita One (`assets/GUIPackCartoon/Demo/Fonts/`, SIL OFL 1.1, notice in `marketing/brand/feature_graphic/licenses/`). The composer refuses loot an enemy does not carry or drop. Report: `docs/LootFarmer_Change_28_Report.md`; evidence `docs/Change_28_Evidence/`.

**Store outputs (ignored `store_assets/`, `.gdignore`, never ship):** Play icon 512×512 RGBA, feature graphic 1024×500 RGB, 24 screenshots (Change 34 set from `marketing/screenshots/`: raw masters + byte-identical upload copies, provenance in `store_assets/screenshots/screenshots_manifest.json`, copy in `docs/Change_34_Evidence/`; the replaced Change 27 set kept in `store_assets/screenshots_change_27/`), 7 raw AVI clips (Change 27) and the Change 32 30 s trailer MP4 with its own masters in `store_assets/raw/video/trailer_c32/` (rejected Change 27 cut kept in `store_assets/video/rejected_change_27/`); provenance and SHA-256 in `store_assets/store_assets_manifest.json` (copy in `docs/Change_27_Evidence/`) and, for the trailer, `docs/Change_32_Evidence/validation.json`.

**Rights used by the deliverables:** Pixel Plains characters/items/tiles (icon, feature graphic, every capture), Pixel Plains Animation Pack swings, Kenney Fantasy UI and DejaVu Sans (native HUD in captures), Willosuna magic VFX/SFX lite (skill effects and sounds in captures), `assets/sounds/background_music.wav` (the Change 32 trailer's only audio) and cue WAVs (UI sounds in the game, not in the trailer), `assets/Audio` (clicks), Lilita One (feature graphic wordmark, Change 28; trailer title cards and end card, Change 32). **REL-02 remains open:** Pixel Plains and `assets/sounds` still have no retained licence/purchase record, so the store media are capture-ready but **not cleared for publication**.


## Source vs export policy (Change 26, 2026-10-28)

**Source keeps everything; the paid export ships only the dependency-verified allowlist.** Purchased and supplied packs, their licences, ReadMes and unused variants stay in Git. What ships is `tools/export_manifest.json` (229 files, a reason for each), generated by `python tools/export_manifest.py` from the reviewed rules `tools/export_rules.json` and written into the Android Release preset (`export_filter="resources"`). The suite runs `--check`. `--why res://...` explains one file. After an export, `python tools/verify_export.py builds/<artifact>.aab` checks the real package. Details: [Change 26 report](LootFarmer_Change_26_Report.md).

| Group | Shipped (verified in `LootFarmerIdleRPG.26.aab`) | Kept in source only |
|---|---|---|
| Pixel Plains characters | 52 sheets: 48 enemy/outfit appearances (catalog), player body, Autumn 4 v2 (Death), Gato 4 v2 (Cat), Shadow | other v1/v2 sheets |
| Pixel Plains items | `All v3 (Separated Files, Black Outline)`: catalog icons plus UI indices 1, 12, 42, 44, 57, 60, 94, 97, 147, 171, 208, 209, 211, 212, 216, 249, 264, 266, 269 (prewarm list, `MASTERY_ART`, `HELP_ART`, Prestige path icons, defaults); `16x16 All Items v1.png` (coin, gem, Death weapon) | seven other outline variants, unused Black Outline indices, `New Items`, `Items.png` |
| Pixel Plains seasons / weather | Winter, Summer, Fall and root Spring tiles/props used by the 8 baked stages; Winter/Fall falling leaves; rain sheet; Sparks | waterfalls, fountain, `All tiles Spring.png`, `Basic Tiles 1.0.png`, no-shadow trees, `Tileset 8x8`, mushrooms, rock pillars, demo sheets |
| Pixel Plains Animation Pack | Sword/Axe 1-6 swings and Onix Scythe 7 (13 sheets) | Tools, Items, hands-only, base anims, preview |
| Kenney Fantasy UI | 13 PNGs referenced by `theme.tres`, scenes and the guide frame | 267 other PNGs, Sample/Preview, Vector |
| Willosuna VFX lite | the six `<effect>_sheet.png` named by `catalog.skills[].effect` | per-frame files, manifest |
| Willosuna SFX lite | 7 OGG cues in `audio_cues.tres` | 30 WAV duplicates, 23 other OGGs |
| `assets/sounds` | background_music, ui_confirm, mission_ready, stage_clear | 12 other WAVs (including reveal_unlock, no longer referenced) |
| `assets/Audio`, `assets/Fonts` | button, prestige; DejaVu Sans | README, licence text |
| Retired / reference-only | none | `Zombies Free ver`, `PP Pumpkins Set Free`, `LootFarmer-seasonal-animation-sheets` (now `.gdignore`), `GUIPackCartoon` (`.gdignore`) |
| Bootstrap leftovers | none | `scenes/main.tscn`, `scripts/main.gd`, `ui/bootstrap_theme.tres` (Bootstrap preset only) |

Dynamic families the allowlist enumerates from data and code: stage scenes `stage_%d.tscn` (`catalog.stages[].id`), item art `Item-%d.png`, skill sheets, catalog `icon_path`/`texture`/`attack`, three player body sheets. A new art path built in code must be registered in `tools/export_rules.json` or the generator fails. `docs/` has `.gdignore` (evidence screenshots and `LootFarmer_Enemy_Roster.csv` are no longer imported). REL-01 (icon) and REL-02 (licence records) remain open.


## Production audit status (2026-10-28)

Facts checked against the repository and the newest exported artifact (`builds/LootFarmerIdleRPG.22.aab`). Finding ids refer to `LootFarmer_Full_Production_Audit_Report.md`.

- **Referenced by game code and data:** Pixel Plains (characters, items "All v3 Black Outline", weather sheets), Pixel Plains Animation Pack (weapon swings), Kenney Fantasy UI (theme, panels, frames), Willosuna magic VFX lite (six effects plus warning and summon) and SFX lite (OGG only), `assets/sounds` (background music plus four cues), `assets/Audio` (click, Prestige; original tones), DejaVu Sans.
- **Exported but unreferenced** (historical; fixed in Change 26, see the policy above; `export_filter="all_resources"`, REL-06): `Zombies Free ver`, `PP Pumpkins Set Free`, `LootFarmer-seasonal-animation-sheets`, the seven unused Pixel Plains item outline variants, most of the Kenney and animation-pack files, and the SFX WAV duplicates. `GUIPackCartoon` has `.gdignore` and is not exported. Some item art paths are constructed at runtime (`Item-%d.png`), so an export allowlist must include catalog icons and the UI art indices, not only literal paths. This allowlist is also the base of the Stage 16 demo build.
- **Release gates (REL-01, REL-02):** the project icon is a placeholder "LF" monogram and the Android adaptive/launcher icon fields are empty. Licence or purchase records are still missing for Pixel Plains (only `ReadMe.txt`) and for `assets/sounds` (five files in use, including `background_music.wav`, a 23 MB WAV source).
- **Not validated on device:** effect alignment on 2× and 2.5× bosses, rain and HUD readability, the audio mix (AST-02, AST-03). All recent visual evidence is desktop 540×960 captures.

Source: supplied ZIP 7, corrected 2026-10-21. Supplied does not mean integrated. Historical mappings are archived under history/pre_change_2 and must not override this status.

## Existing visual baseline

The implemented interface uses Kenney Fantasy UI, not the retired Cartoon GUI interface. Current exact crops, nine-slices, fonts and actor mapping are recorded in Playbook section 22.4 and implemented resources. Cartoon GUI references in old notes are historical. Keep game-specific future mappings here.

PixelPlains selected characters: Basic character v2 (player), Character 1 v2 (Sprout), Character 18 v2 (Robot), Special 3 v2 (Dinosaur), Autumn 4 v2 (Death), Gato 4 v2 (cat). Current actor sheets use 24×24 cells within 216×120 sheets. Historical verified mappings: idle row 0 columns 0–7, movement row 1 columns 0–3, death row 2 columns 0–8. Weapon attack sheets are eight 64×32 cells; contact is simulation-owned. Preserve established mappings until actual playback review supports a change.

54 v2 character appearances are available, not 54 guaranteed enemy species. Environment tiles, props, items, weapon animation sets and UI resources are included. Final enemy/area assignments in LootFarmer_Enemy_Roster.csv are implemented. Eight baked editable stage scenes replace the old active world. Headless loads pass; visual playback/device acceptance remains pending.

## Magic Spells VFX Lite — integrated in Change 4

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

## Magic Spells SFX Lite — integrated in Change 4

Root: assets/magic-spells-sfx-lite/. Includes manifest, README, license and 30 WAV/OGG pairs. WAV headers verify mono 44.1kHz; durations 0.53–2.71s. Choose one playback encoding per sound for the shipped runtime; do not count both formats as separate variations.

Primary mappings: cast/cast_01, impact/impact_01, fire_impact/fire_impact_01, ice_shatter/ice_shatter_01, zap/zap_01, heal/heal_01. Remaining 24 families are optional resources, not approval to add 24 spells. Reuse AudioService semantic events; author effect priority/overlap/volume rules so enemy swarms do not drown out feedback. Listening and target-device mix acceptance remain pending.

Both spell licenses allow personal/commercial projects, editing and optional attribution. Do not redistribute standalone raw asset collections. Preserve licenses with source. This source patch references existing supplied assets; no standalone asset collection is redistributed.

## Other audio and provenance

assets/sounds contains 16 WAVs: background music; six Castle_Damage clips; defeat; mission_ready; move_command_units; move_command_villager; reveal_unlock; stage_clear; ui_click; ui_confirm; ui_error. They have no accompanying folder license or confirmed byte-identical source elsewhere in ZIP 6. Keep pending source/license verification and listening review; do not silently replace current Audio/button and Audio/prestige mappings.

**Change 12 activation (developer brief: use existing approved audio):** the game now uses five files from this set through `resources/game/audio_cues.tres`: `background_music.wav` (looping music, mixed at −8 dB under the Music slider), `ui_confirm.wav` (successful manual purchase, claim, merge, evolution, card), `mission_ready.wav` (a manually claimed mission reaches its goal), `reveal_unlock.wav` (a step of the followed Prestige opportunity completed) and `stage_clear.wav` (a new map unlocked). These are the developer's authored cue set already used by Growing Kingdom and Everfort (see docs/GDDs). `Audio/button.wav` (click) and `Audio/prestige.wav` (Prestige discovered, ready and performed) keep their mappings. Not used: Castle_Damage ×6, defeat, move_command_units, move_command_villager, ui_error. **Still pending before release:** a retained licence/provenance record for `assets/sounds` (nothing in the repository records one) and a listening/mix review on a phone.

Kenney, spell packs, fonts and toolkit font licenses are included. PixelPlains and the new generic audio need explicit retained provenance/license evidence before release. Original purchase files may supply it; absence here is not a claim of prohibited use.


## Seasonal and weather additions

The 48 selected preview sheets use dark-outline v1 art, 216×120 with 24×24 cells. The prototype uses v2 for some actors; the 48 v1 enemy appearances are now the active mapping. Roster CSV records source file and SHA-256 for every selected character. Sheets remain unchanged in the supplied project. Existing seasonal ZIP misspells its boss folders `bosss/`; do not depend on that spelling as a runtime path. Use original project asset paths from the CSV. Future exports should use `bosses/` consistently.

Winter I/II use `assets/PixelPlains/Winter/`; Summer uses `Summer/`; Autumn uses `Fall/`; Spring uses root Spring tiles. Winter II effect: `Winter/Falling leaves.png` (blue leaves, visually reviewed in conversation). Autumn II: seasonal falling leaves. Summer II and Spring II: `Rain full anim sheet 52x216.png` / `Rain Sheet.png` (15 horizontal 52×216 frames, drawn at half-size with low opacity). First seasonal stages clear.

Spark sources under PixelPlains: `Spark (White Ver.) 7x5.png` (40×7), `Spark 7x5.png` (40×7), `Sparks 25x27.png` (400×27). Visually inspected as white/yellow single spark and yellow clustered sparkle sequences; useful optional feedback/ambience. Filenames alone do not establish frame stride/timing. Sparks 25x27 uses 16 horizontal 25×27 frames as sparse ground-loot sparkle; it inherits fog hiding from the pickup node. Weather is cosmetic and must not leak hidden actors.

Use six approved Willosuna effects only; no new spell roster from unused audio names. Final enemy types still require actual composite weapon/body/skill playback checks, contact alignment and readable silhouettes. Full-body appearance labels identify bosses but do not prove animation coverage without source verification.

## Exact Change 4 runtime integration

- Stage scenes use seasonal Basic Tiles 1/2/3 atlases, paths and court topology, perimeter Trees & Bushes, and Props camp fountains/benches. `tools/build_campaign_maps.gd` is an authoring tool; gameplay loads the baked scenes. World bounds are square, not a stretched prototype strip.
- All 48 roster appearance sheets are referenced by their original paths. New weapon families reuse the existing wood sword icon and 64×32 attack animation; legacy mappings remain for migrated inventory. No new unverified weapon artwork is claimed.
- Six VFX sheets use the table above; Heal plays once per cast. Icons crop the nonempty representative frame. Boss attacks announce an aim point before contact, and area damage resolves against that point. The VFX never apply damage.
- Audio paths are `assets/magic-spells-sfx-lite/ogg/<effect>_01.ogg`, routed through AudioService. A 250ms per-family throttle limits swarm repetition; the existing six-player pool and volume controls are retained.
- Winter II and Autumn II falling leaves use 16×16 frame cells. Rain is decorative on Summer II/Spring II only. All effects are filtered against the same explored-cell query as actors/pickups.

Remaining release evidence: PixelPlains purchase/provenance record, original generic audio provenance if those unused files are later activated, actual animation alignment, on-device audio mix and simultaneous-cast readability.

## Change 5 asset-backed presentation

No new drawn/generated art. Shared panel/button frames use Kenney panel-000 with 12-pixel slices; Card variation uses panel-015 and contrasting tint. Main divider uses divider-003. Actor HP bars use the shared theme. Item and map icons come from existing separated PixelPlains item files; portraits retain existing atlas crops. `scenes/game/info_card.tscn` exposes card composition in the editor. Dynamic panel lists still have code-owned construction; see audit limitations.

Each stage has editor-visible BossLandmarks under its existing scene: seasonal Props atlas stone-post region (0,176,32,32), approach signs (128,144,16,32), surrounding the existing distinct boss floor patch. Boss scale is catalog data, carried through actor art, weapon, shadow, bar offsets and picking bounds. Bee and squirrel are deliberate normal-size exceptions. Actors use Y-sort on z=1; supplied spell animations use z=0; scenery stays below them.

Rendered evidence: Change_5_Evidence contains onboarding, first lesson, missions, upgrades, achievements, boss arena, map and potion screenshots. These are desktop render checks at 450×800, not phone certification.

## Change 6 asset use (no new or generated art)

- **Guidance pointer and item arrows:** PixelPlains `Items/All v3 (Separated Files, Black Outline)/Item-273.png` (arrow), cropped to its used pixels and rotated in code (`UiArt.cropped`, base direction up-left). Kenney Fantasy UI and Cartoon GUI contain no LootFarmer-approved pointer; Cartoon GUI arrows/hand exist but that pack is retired for this game's interface.
- **Prestige cards:** Kenney `Panel/panel-011.png` (theme variation `PrestigeCard`, tinted per path), selected frame `Border/panel-border-011.png` tinted gold. Path art (cropped PixelPlains items): Boss Hunter 269, Expedition 97, Collection 216, Masterwork 12, Arsenal 44, Regional 266, Challenge 264, Offering 208, Specialist 57, Trophy 94, Offline 171. Recorded in `catalog.campaign.paths`.
- **Milestone banner:** `scenes/game/milestone_banner.tscn`: Kenney panel-000 `Backing`, gold `panel-border-011`, PixelPlains Item-211 star, `Sparks 25x27.png` (16 frames, 25×27, cycled at 20 fps). Since Change 12 its sound plays at the milestone through the audio service (`Audio/prestige.wav` for Prestige), not when the banner shows; `assets/sounds` is partly in use (see Other audio and provenance).
- **Dock icons:** World 249, Missions 60, Prestige 211, Stats 42, Settings 209 (cropped). **Notification backing:** theme variation `Backing` (panel-000, near-black 90% alpha) behind toasts, recent finds, tutorial cards and the banner. **Primary action:** theme variation `Primary` (panel-000 tinted amber) for the main action of a panel and affordable purchases.
- **Contrast:** floating combat numbers and speech labels have a 4/3-px dark outline; world camp labels get a 5-px outline at runtime. Meaning is carried by sign and glyph (−, +, !, ▲/▼, ✓), with colour as reinforcement.

## Change 12 asset use (no new art or audio)

- **Stone-tier swing:** `PixelPlainsAnimationPack/Iron set/Axe 2 64x32.png` and `Sword 2 64x32.png` with a warm-gray multiply tint (catalog `attack_tint` [0.9, 0.84, 0.84], applied to the swing sprite only) for Stone Axe and Stone Sword. The pack has seven swing sets (Wood, Onix, Iron, Gold, Diamond, Emerald, Ruby) and no Stone set; the stone tier used the navy Onix set, which looked black against the gray stone icon. Onix stays on the Death boss scythe.
- **Audio:** see Other audio and provenance (Change 12 activation). Cue ids, categories, priorities and cooldowns: `resources/game/audio_cues.tres`.

## Change 13 asset use (no new art or audio)

- **Rain:** `PixelPlains/Rain full anim sheet 52x216.png`, now described by `resources/game/weather_rain.tres` (`WeatherStyle`: 15 frames of 52×216 drawn at 26×108 world units, 64 streaks per 440×500 cell, colour (0.86, 0.93, 1, 0.62), world-anchored). The falling leaves use `weather_leaves.tres` / `weather_blue_leaves.tres` with their Change 7 values. The rainy maps' overcast is a multiply tint on the stage scene (0.77, 0.78, 0.92), measured from the supplied reference pair (docs/LootFarmer_Change_13_Package/visual_refs); camps are restored to their own colours.
- **Required-boss banner:** `PixelPlains/Items/.../Item-249.png` (the World button's icon) in gold (1, 0.84, 0.34): the HUD Next-stage line (`main.tscn Map/Gate`, 24 px), above a boss's HP bar (`actor.tscn Gate`, 0.75 scale) and on the map/minimap marker corner (`map_view._gate_badge`). Camps on the map use the same icon in white/gray at full marker size, so the small gold corner badge reads as a boss attribute.
- **Summoning:** `magic-spells-vfx-lite/cast` (the Focus effect) tinted (0.78, 0.66, 1) on the summoner (telegraph) and on each helper; `magic-spells-sfx-lite/ogg/summon_01.ogg` as the `spell_summon` cue (gameplay, priority 10, 0.5 s cooldown, −4 dB). Helpers reuse their copied type's outfit sheet and swing, with the same violet tint on the body.
- **Provenance still open:** `assets/sounds` licence record (see above); PixelPlains purchase record (only `ReadMe.txt` in the pack folders).


## Change 14 asset use (no new art or audio)

- **HUD chips** (Map Explored, Next Stage): `KenneyFantasyUI/PNG/Default/Panel/panel-000.png` as the `hud_chip` StyleBoxTexture in `resources/game/theme.tres` (dark modulate, the same art as the `Backing` style).
- **Joystick**: the Backplate and the knob Rim reuse `Panel/panel-014.png` (the knob texture) with dark node modulates in `scenes/game/joystick.tscn`; the ring stays `Transparent center/panel-transparent-center-014.png`.
- **Skill effects**: the same magic-spells-vfx-lite sheets, now placed per skill by `resources/game/skill_effects.tres` (contact rows: zap ring 53, heal/cast self rings 52, bursts 32). The boss wind-up marker is the `cast` sheet at 0.6×, tinted (1, 0.5, 0.32, 0.8).
- **Rain**: `PixelPlains/Rain full anim sheet 52x216.png`; frames 0–8 are the fall and 9–14 the ground splash (`weather_rain.tres splash_frame = 9`).
- **Focused Farming hint**: the guide's existing PixelPlains arrow (Item-273), Kenney frame and caption card, with Item-147 as the card picture.

## Dinosaur identity correction (Change 20)

The character at `Special 1 v1.png`, saved as `boss-elephant`, is a dinosaur. Keep that identifier, sprite association and combat definition. English boss/outfit descriptions now say Dinosaur. No artwork was replaced.

## Change 24 asset review (no asset changed)

- **Background music** (`assets/sounds/background_music.wav`, 23 MB source): imported as QOA (`compress/mode=2`, loop mode forward), 4.7 MB in the build and in memory while playing. Evaluated for PERF-07 and left unchanged: an OGG would save a few megabytes but needs a lossy re-encode and a listening check, which is not a clear benefit. Repository size alone is not a reason to convert.
- **Fog veil** (`resources/game/fog_veil.gdshader`, new code resource, not art): draws the existing `fog_rules.tres` cover and vision colours from the explored mask; no texture asset.

## Script fallback fonts (Change 42, Localization Batch 03)

DejaVu Sans (the theme font) has no Thai or Devanagari. Two OFL fonts were added as runtime fallbacks; both are byte-identical copies of the files already vendored (and hash-recorded) in `Godot-Marketing-Toolkit/assets/fonts/font_manifest.json`, so nothing was downloaded.

| Runtime file (ships) | Family / version | Upstream file and source | SHA-256 | Licence (kept beside the font; the OFL notice is also embedded in the font's name table, IDs 13/14) |
|---|---|---|---|---|
| `assets/Fonts/NotoSansThai.ttf` (218,652 B, variable wght/wdth, default 400/100) | Noto Sans Thai 2.002 | `NotoSansThai[wdth,wght].ttf`, google/fonts `ofl/notosansthai` | `5a1c559b…3096cc9ef8` | SIL OFL 1.1, `assets/Fonts/NotoSansThai-OFL.txt` (sha `2e98fd23…c374a0`), © 2022 The Noto Project Authors |
| `assets/Fonts/NotoSansDevanagari.ttf` (641,944 B, variable wght/wdth, default 400/100) | Noto Sans Devanagari 2.007 | `NotoSansDevanagari[wdth,wght].ttf`, google/fonts `ofl/notosansdevanagari` | `14ec4af4…03229853e` | SIL OFL 1.1, `assets/Fonts/NotoSansDevanagari-OFL.txt` (sha `a216f6f8…31d0f331`), © 2022 The Noto Project Authors |

- **Not subset:** both are small and subsetting can drop GSUB/GPOS lookups that Thai mark positioning and Devanagari conjuncts need. CJK fonts (Batch 04) will need subsetting.
- **Import settings** copy DejaVu Sans's (MSDF, pixel range 8, size 48).
- **Use:** `resources/game/ui_font_thai.tres` and `ui_font_devanagari.tres` (FontVariation: DejaVu Sans + one fallback) become the theme default font only while th_TH or hi_IN is active (`LocalizationService.SCRIPT_FONTS`); `ui_font_all_scripts.tres` (both fallbacks) is the language dropdown's own font, so ไทย and हिन्दी render in every locale. Other locales keep plain DejaVu Sans, because Godot sizes lines by the tallest font in a chain (Noto Thai 1.511 em vs DejaVu 1.164 em) and the chain would otherwise change every existing Latin/Cyrillic layout.
- **Text-server data:** `internationalization/locale/include_text_server_data=true` packs Godot's ICU data (`icudt_godot.dat`, 4.8 MB) so Thai, which has no spaces, wraps at word boundaries in exported builds.
- **Exports:** all three release presets and the signed AAB ship both fonts, the three chains and the ICU data (Change 42 report §8). The licence text files are not packed (the embedded OFL notice travels with the font data, as for DejaVu Sans).

## CJK fonts (Change 43, Localization Batch 04)

DejaVu Sans has no kana, Hangul or Han. Four regional Noto Sans faces were subset from the copies already vendored and hash-recorded in `Godot-Marketing-Toolkit/assets/fonts/font_manifest.json` (google/fonts `main`, SIL OFL 1.1); nothing was downloaded. `tools/build_cjk_fonts.py` refuses a source whose SHA-256 differs from that manifest, instances the variable font at **wght 400** (the regular weight of DejaVu Sans Book) and subsets it with fontTools (all layout features and name records kept, empty `.notdef`), following EverFort's verified `tools/localization/build_font_subsets.py`. Re-run it after editing a CJK catalog; `--check` and `localization_batch04_probe` fail when a catalog character is missing.

| Runtime file (ships) | Content | Upstream source (SHA-256 in the toolkit manifest) | SHA-256 |
|---|---|---|---|
| `assets/Fonts/NotoSansJP-LootFarmer.ttf` (293,232 B) | 668 characters of `ja_JP.po` that DejaVu lacks | `NotoSansJP[wght].ttf` (`c2f3b4d4…0fc68f`), Noto Sans JP 2.004 | `281ce4d9…c4bd67dd` |
| `assets/Fonts/NotoSansKR-LootFarmer.ttf` (81,912 B) | 519 characters of `ko_KR.po` | `NotoSansKR[wght].ttf` (`194018e6…1e252`), Noto Sans KR 2.004 | `bd0b986e…ce90a553` |
| `assets/Fonts/NotoSansSC-LootFarmer.ttf` (222,900 B) | 822 characters of `zh_CN.po` plus full-width “”‘’ | `NotoSansSC[wght].ttf` (`a3041811…99af0da`), Noto Sans SC 2.004 | `f1eaa7a3…2f7718f` |
| `assets/Fonts/NotoSansTC-LootFarmer.ttf` (257,928 B) | 821 characters of `zh_TW.po` | `NotoSansTC[wght].ttf` (`864727d2…46bd44f`), Noto Sans TC 2.004 | `91a3ee81…9937e5e` |
| `assets/Fonts/NotoSans{JP,KR,SC,TC}-Endonym.ttf` (3.5–4.4 KB each) | 日本語 / 한국어 / 简体中文 / 繁體中文 only | same four sources | `0bade34a…`, `009d8f0a…`, `45303c32…`, `d2604667…` |

- **Licence:** SIL OFL 1.1, texts beside the fonts (`assets/Fonts/NotoSans{JP,KR,SC,TC}-OFL.txt`, byte-identical to the toolkit's, SHA-256 `1c05c68c…ccc374a0`); the OFL notice and copyright (© 2014-2021 Adobe, with Reserved Font Name "Source") stay in each subset's name table. The subsets are modified versions under OFL §3 and keep the family names "Noto Sans JP/KR/SC/TC", which do not use the reserved name "Source". As for DejaVu and the Change 42 fonts, the licence text files are not packed; the embedded notice travels with the font data.
- **Regional forms:** each locale draws with its own regional face, so a Han character shared by the locales takes Japanese, Simplified or Traditional (Taiwan) forms by locale. Hong Kong and Macao devices route to zh_TW and therefore get Taiwan forms (no separate HK face).
- **Import settings:** like the Thai/Devanagari fonts but **without MSDF** (plain antialiased rasterisation per size), so dense Han glyphs stay sharp at small sizes. The endonym imports declare their script (`script_support` Hani or Hang): Godot 4.7 prefers a fallback that declares the run's script over an earlier one that does not, and a 3–4 glyph subset loses its OpenType script records.
- **Use:** `resources/game/ui_font_{japanese,korean,chinese_simplified,chinese_traditional}.tres` (regional face first, DejaVu Sans second) become the theme font only while that locale is active (`LocalizationService.SCRIPT_FONTS`); `ui_font_all_scripts.tres` gained the four endonym fonts (its line height is unchanged: the Thai face is still the tallest); in a CJK locale `LocalizationService.selector_font` appends that locale's face for the translated "Automatic".
- **Size:** 0.85 MB of TTF in total (the full variable sources are 49.7 MB).

## Change 67 merge and evolution effects

Source: Cartoon Coffee "2D Deluxe VFX" (Unity Asset Store pack under the untracked `assets/Cartoon Coffee/`, 381 MB; it ships Unity prefabs, materials and HDR shaders and **no licence file**; licence/release clearance is not verified here, same status as the Change 60 buff textures). The prefabs were inspected (layer textures resolved through material GUIDs, start colours, gradients, lifetimes, counts, timing) and rebuilt with Godot CPUParticles2D, Sprite2D and a one-line flash shader, additive `CanvasItemMaterial`, no Unity code. Runtime copies are white masks resampled with premultiplied alpha (no dark fringes), tinted in code, in `assets/vfx/celebration/` (≈228 KB):

| Runtime file | Size | Source texture | Used for (prefab it adapts) |
|---|---|---|---|
| Circle_Outline_002.png | 256 | Textures/Circle_Outline_002 | merge ring, glint ring, evolution contracting rings (Star_Flash_V1, Charge_Light Burst_Ring) |
| Star_003.png | 256 | Textures/Star_003 | merge star flash, slot glints, evolution star shower (Star_Flash_V1, Impact_Shine_V3, Impact_Light_Lv3 Star_Burst) |
| Star_004.png | 96 | Textures/Star_004 | merge sparks (Star_Bursts_Center_V3) |
| Light_Ray_001.png | 256 | Textures/Light_Ray_001 | release light lines (Impact_Light_Lv3 Impact_Lines) |
| Radial_Glow_006.png | 512 | Textures/Radial_Glow_006 | rotating rays behind the evolved weapon (Radial_Loop_V2) |
| Shockwave_001.png | 256 | Textures/Shockwave_001 | release shockwave (Charge_Light / Impact_Light_Lv3 Impact_Burst) |
| Rainbow_Ring_001.png | 256 | Textures/Rainbow_Ring_001 (colour kept) | release rainbow ring (Impact_Light_Lv3 Rainbow_Burst) |
| Impact_006.png | 256 | Textures/Impact_006 | release centre flash (Impact_Light_Lv3 Impact_Center) |
| Smoke_Cloud_002.png | 128 | Textures/Smoke_Cloud_002 | rising charge smoke (Aura_V14/V15, white half-alpha smoke, tinted here) |

Glow is the existing `assets/vfx/buff/Glow_001.png`. Fireworks_V1 (Empty_001 trails + embers + purple glow) is approximated by velocity-aligned stretched glows; Unity trails and the distortion shaders are not reproduced. Sounds (licensed Magic Spells SFX Lite OGGs, gameplay category, `resources/game/audio_cues.tres`): `item_merge` enchant_01 (−3 dB), `evolve_charge` charge_01 (its swell peaks near the 1.35 s release), `evolve_burst` arcane_blast_01, `evolve_reveal` holy_01 (−2 dB), `evolve_auto` spell_ready_01 (−8 dB, 1.5 s cooldown). The unlicensed-provenance `assets/sounds/reveal_unlock.wav` was deliberately not used.
