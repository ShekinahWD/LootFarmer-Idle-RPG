# Godot Marketing Capture Toolkit

**Version:** `1.0.2` (stable capture/media baseline plus a Google Play locale-validator correction; installed Godot addons are unchanged). Production-validated in Everfort after earlier Growing Kingdom/Loopcremental integration. Per-game Android playback and final asset approval remain release QA, not toolkit-promotion blockers.

Reusable source code for store screenshots and promotional videos made from **real gameplay** of any Godot 4 game: per-game scenario staging through a small adapter, exact-size screenshots (language-neutral by default: authentic gameplay and native game UI, no added text), Movie Maker clips (landscape or genuine portrait), then composition with localized text where a campaign approves it (all 20 approved locales, complex scripts shaped by Godot's own text server), title cards, animated fades through black, game sound plus music, and H.264 MP4 export at a chosen quality preset, each output verified frame by frame. It is code, not a process document: the Reusable Game Development Playbook (§87, §133–135) owns the method.

## Contents

| Path | Purpose |
|---|---|
| `addons/store_screenshot_capture/` | Interactive editor-runtime screenshot overlay (Phone / 7" / 10" / Desktop, landscape or portrait). `viewport_capture.gd` holds the capture steps both tools share. |
| `addons/marketing_capture/` | `capture_runner.tscn` (the command-line capture scene), `scenario_adapter.gd` (the per-game contract, fail-closed), `marketing_fonts.gd` (font fallback chains from files outside `res://`) and `text_renderer.gd` (the headless Godot text renderer the composer runs). |
| `tools/marketing.py` | CLI: `check`, `install`, `status`, `record`, `screenshots`, `video`, `pipeline`, `verify`, `analyze`, `fonts`. |
| `tools/play_store_listing.py` | Validates the reusable 20-locale Google Play AI-import JSON package: explicit runtime-to-Play locale mapping, locale completeness, duplicate/missing entries and 30/80/4000 character limits. |
| `assets/fonts/` | Noto Sans (Latin, Cyrillic, Greek; the default face), Noto Sans Thai, Devanagari, JP, KR, SC and TC (variable, SIL OFL 1.1, licences in `licenses/`), `font_manifest.json` (source URL, size and SHA-256 of each download) and `script_samples.json` (test strings per locale, never marketing copy). `.gdignore`d. |
| `examples/` | A game adapter skeleton, a marketing manifest, and `play_locale_map.example.json` containing the default 20-entry runtime-to-Play mapping. |
| `tests/test_toolkit.py`, `tests/test_play_store_listing.py` | Offline tests (synthetic footage/listing data only): fades reach black, card text waits for black, reading time (planned and measured), `auto` cards and `fill` clips, in-points, game audio + music, hard-cut detection, social reframes (focused windows, full-landscape frames with text kept in the black bands), safe margins, install/status drift, re-takes that keep the master, the window override, quality presets, glyph coverage, default fonts for all 20 locales, font chains, wrapping before shrinking; with `MARKETING_GODOT` set, Thai/Devanagari shaping, Thai word breaking, fallback chains and a Thai video, screenshot and font proof. |
| `tests/test_package.py` | Package integrity: `PACKAGE_FILES.sha256` verifies against the working copy and against fresh clones made under every `core.autocrlf` / `core.eol` setting (needs git for the clone half). |
| `PACKAGE_FILES.sha256`, `.gitattributes` | SHA-256 of every package file's canonical bytes (`sha256sum -c` format); text is LF in the repository and in every checkout, so a fresh clone verifies. |
| `.gdignore` | Godot never imports this folder if it sits inside a project. |

No game-specific gameplay classes, saves, marketing copy or art assets are bundled. Historical validation notes may name the games used for testing.

## Requirements

- Godot **4.x** (validated: 4.7.2 on Windows; the overlay's dock needs 4.7's `EditorDock`). Captures need a desktop session: they render in a real window.
- Python **3.10+** with **Pillow** (`python -m pip install Pillow`). Raqm is not needed: shaped scripts and CJK are set by Godot (below); `check` reports both.
- **ffmpeg** and **ffprobe** on PATH (validated: 8.0.1). Development tools only, never in a game build.
- Fonts: none needed. The bundled Noto faces (SIL OFL 1.1) cover all 20 locales and are the default; map a game's own licensed brand face per locale (or `default`) to use it instead.
- For Thai, Devanagari, CJK or a font fallback chain: a Godot 4 console executable (`--godot`, or the `MARKETING_GODOT` environment variable). It runs headless in a throwaway project.

## Install in a new project

Files a project receives (copied by `install`, never by hand):

```text
addons/store_screenshot_capture/   README.md, editor_dock.gd, plugin.cfg, plugin.gd, runtime_capture.gd, viewport_capture.gd
addons/marketing_capture/          capture_runner.gd, capture_runner.tscn, scenario_adapter.gd, marketing_fonts.gd, text_renderer.gd
marketing_capture_toolkit.lock.json   the pinned version and every file's SHA-256
```

The fonts are **not** installed: they stay in the toolkit (`.gdignore`d), and the composer and `marketing_fonts.gd` load them from their files at run time, so a game's export never grows by them (a CJK face is 10 to 17 MB). A game whose own UI is localized needs its own font setup (see "Fonts and text").

```powershell
python <toolkit>\tools\marketing.py check --godot "<Godot console exe>"
python <toolkit>\tools\marketing.py install --project "D:\Godot\MyGame"     # refuses to replace existing addons
python <toolkit>\tools\marketing.py status  --project "D:\Godot\MyGame"     # installed == lock == toolkit
```

`install --overwrite` updates an installed copy: managed files are replaced, files the toolkit no longer ships are removed, Godot's `.uid` files are kept (and orphans removed). `status` fails on any drift: change toolkit code **in the toolkit**, then reinstall. Keep the toolkit in its own repository (or a `.gdignore`d folder) at a tagged version; the lock records which one a game uses.

**Package integrity:** from the toolkit root, `sha256sum -c PACKAGE_FILES.sha256` (Git Bash) or `python -m unittest tests.test_package -v` checks a copy against the release. After changing a package file, keep it LF and regenerate the manifest from the canonical files (every file except the manifest, `__pycache__` excluded, sorted by path); `tests/test_package.py` fails on a CRLF working copy or a manifest that a fresh clone would not reproduce.

Then the game provides, in its own files:

1. **An adapter** `res://marketing/game_scenarios.gd` extending `res://addons/marketing_capture/scenario_adapter.gd` (start from `examples/game_scenarios.example.gd`):
   - `is_capture_safe()`: true only when the game's own boot switches prove a test save and no autosave (read them in an autoload's `_init`, before any scene).
   - `prepare_scenario(id, options, game_root, job)`: synchronously build an authentic state through the game's own reset/debug/action paths; return false to abort. The adapter is a Node: per-frame staging (camera moves, scripted input, HUD presentation) can run from its `_process` or a child's while the clip plays. A game that already has a trailer/shot director should host it here rather than rewrite it.
2. **A manifest** `marketing/manifest.json` (start from `examples/marketing_manifest.example.json`; reference below).
3. **Export exclusion:** add `marketing/*, addons/marketing_capture/*, marketing_capture_toolkit.lock.json` (and whatever the adapter preloads, and any test scenes) to every release preset's `exclude_filter`; then list the exported PCK to confirm (verified in Loopcremental for 0.3.1: an Android PCK export with this filter contained none of them, the same export without it contained all 18 entries; the toolkit folder, its fonts and `output_root` never enter a pack thanks to their `.gdignore`). The screenshot overlay's autoload only acts in `editor_runtime`, but note that a command-line run with the *editor binary* is `editor_runtime` too; the runner hides that overlay itself.
4. **UI group:** add the game's screen-UI roots (CanvasLayers or Controls) to the group `store_screenshot_ui`, so `capture_ui: false` and the overlay's "Capture UI off" hide them and nothing else.
5. **Output:** set the manifest's `output_root` to an ignored folder (it gets a `.gdignore`); add it to `.gitignore`.

## Run

```powershell
python <toolkit>\tools\marketing.py pipeline --project . --manifest marketing\manifest.json --godot "<Godot console exe>" --locales en-US --overwrite
python <toolkit>\tools\marketing.py pipeline ... --reuse-raw          # recompose only (copy, cards, music, fades)
python <toolkit>\tools\marketing.py pipeline ... --jobs clip_a shot_b # re-record some jobs, then recompose
python <toolkit>\tools\marketing.py analyze --file some_video.mp4     # any video's cuts to/from black
python <toolkit>\tools\marketing.py pipeline ... --reuse-raw --quality preview   # quick look: *_preview.mp4, CRF 26
python <toolkit>\tools\marketing.py fonts --manifest marketing\manifest.json --locales all --godot "<Godot console exe>" --overwrite
```

Every command refuses to overwrite without `--overwrite`, and refuses a missing translation (`--locales all` needs all 20 approved locales).

### What `record` does

Per capture job: Godot writes `<output>.partial.avi` / `.partial.png`, which replaces the existing master only after every check below passes (a crash, a wrong size or a failed check deletes the partial file and leaves the master as it was, so `--overwrite` never costs an approved take). It writes a temporary `override.cfg` (window size; Godot 4.7.2's Movie Maker records at the project's window size and **ignores `--resolution`**), runs Godot on `capture_runner.tscn` with `--fixed-fps` (plus `--write-movie <avi> --quit-after <frames>` for a clip) and the manifest's `godot_user_args`, deletes the override, then checks the result: an AVI's size, fps and exact frame count, or a PNG's exact size. The full Godot output goes to `<output>.log`. A game's own `override.cfg` is never touched (the run refuses).

The runner: adds the adapter (refuses unless `is_capture_safe()`), sizes the real window to the job (raising the window's maximum first: Windows clamps windows to the screen, so 1080×1920 or 2560×1440 works on a 1920×1080 monitor), instantiates the game scene, calls `prepare_scenario`, optionally hides the `ui_group`, checks the **window** size (not the game's virtual canvas, which differs under `canvas_items` + `expand`). A screenshot then runs `capture_frame` frames of live play, freezes the tree (the game and adapter are made `PAUSABLE`; they would otherwise inherit the runner's `ALWAYS`), waits `settle_frames` and a finished render, and writes the PNG.

**Portrait is a real portrait render:** the game lays itself out in a tall window with its own reference layout. Frame it for portrait in the adapter. The composer refuses a clip of the wrong aspect unless its shot has an explicit, reviewed `reframe` (see "Short-form social videos"); it never crops implicitly, stretches or rotates.

### What `video` does

Each shot becomes a lossless segment: a clip (`source`, optional in-point `start`, `duration`) with an optional headline band, or a card (black, `headline_key` title, optional `subtitle_key`, optional `image` trimmed to its artwork, accent rule). Segments are joined with each shot's `transition_in`:

| Type | Rendering |
|---|---|
| `fade` (default 0.4 s next to a card) | Through black. Next to a card, a linear blend into the card's black: the card's text appears only once the picture is black, fades in/out over `style.text_fade`, and is gone before the next transition, so text never pops and no scene shows through it. Between clips, a linear dip to black and back (FFmpeg's `fadeblack` is not used: it drops to black in two frames). |
| `crossfade` | One picture blends into the next. |
| `cut` | Intentional hard cut. |

Transitions overlap their two shots: total = Σ shots − Σ transitions, which must equal `target_duration`. `fade_in` / `fade_out` fade the whole video from/to black (the last shot's text stays up through `fade_out`).

**Reading time.** Every card's text and every headline over gameplay stays **fully visible, fades excluded, for at least `style.text_min_hold` (default 3.0 s)**, longer when the copy is longer: its reading units ÷ `style.reading_cps` (default 15/s). A unit is a grapheme cluster (a base character with its marks; a run of spaces is one); a Han or Kana character counts 2 and a Hangul syllable 1.5, since they carry more per character. Title and subtitle are counted together. So `TOOLKIT TEST CARD` + `Art: Pixel Plains by SnowHex` (45 units) holds 3.0 s, a 90-character card 6.0 s. A shot may set its own `text_min_hold` / `reading_cps` (a deliberate exception; the style values apply to every locale).

A shot's `duration` is seconds, or:

| Value | Shot | Length |
|---|---|---|
| `"auto"` | card | Its transition in + text fade-in + the locale's reading time + text fade-out + the next transition (or the video's `fade_out`). With 0.4 s fades and short copy: 4.33 s. |
| `"fill"` | clip | What `target_duration` leaves after the other shots, shared between the fill clips as evenly as each allows: at least its `min_duration` (default 1 s) and its own headline's reading time, at most its footage after `start`. |

Each locale gets its own timing: a longer translation lengthens its card and shortens the fill clips, and every locale's video still lasts exactly `target_duration`. When the time cannot be found, the command stops before writing anything and says what is missing, e.g. `de-DE: video trailer: target_duration leaves 4.47s for the "fill" clips, they need 5.43s ... drop a title card, shorten its copy, or lengthen target_duration`. Text is never made unreadable to fit: fewer cards, shorter copy or more gameplay time are the remedies. A fixed `duration` that is too short is refused the same way (with the length that would work). After the encode, each card's hold is **measured** in the decoded frames (the run of frames at full text brightness on the card's plain colour) and must reach the required time; headlines over moving gameplay are checked by plan. Both are in `_review.json` (`text_holds`).

Quality: the final H.264 encode uses a preset, chosen by `--quality`, else the video's or the manifest's `"quality"`, else **`high`**:

| Preset | CRF | x264 preset | Output name | Use |
|---|---|---|---|---|
| `preview` | 26 | veryfast | `<name>_<locale>_preview.mp4` | Quick checks of an edit |
| `standard` | 21 | medium | `<name>_<locale>_standard.mp4` | Drafts to share |
| `high` (default) | 18 | slow | `<name>_<locale>.mp4` | Final exports, store delivery |

A preview or standard encode never replaces the final file. `"quality_presets": {"high": {"crf": 17}}` in the manifest changes a preset's `crf` / `x264_preset` or adds a named one. The choice is recorded in `_review.json` (`quality`) and in the file itself (x264's settings).

Audio: `game_audio: true` takes each clip's recorded sound (silence under cards, crossfaded like the pictures) at `game_volume`; `music` (looped/trimmed, `music_volume`, `music_start` in-point, `music_fade_in`, `music_fade_out`) plays under everything; a limiter keeps the mix under −1 dBFS. Output: H.264, yuv420p, **limited range** (Movie Maker's MJPEG is full range), `+faststart`, AAC 192 kb/s.

Verification after each encode: codec, size, fps, frame count, duration, audio duration; then every frame decoded (its luma plane averaged to 64×36 and expanded to full range, so black is 0): each `fade` must change gradually (no one-frame step above a third of its change, frames in between) and reach black; audio peak and quiet moments are measured. The results go to `<video>_review.json`, and `<video>_review.png` shows each shot's first/middle/last frame and every transition frame by frame, for the human check.

### Short-form social videos (TikTok / Reels / Shorts)

Derived from footage you already approved: each vertical cut is one more `videos[]` entry over the trailer's raw clips, not a new capture. Defaults to follow (Reusable Game Development Playbook §133.5):

- **9:16, 1080×1920, 30 fps**: `"profile": "tiktok"` (or `reels` / `shorts`, the same size).
- **Gameplay first, hook in the first 1–2 s**: open on the strongest real moment; the first shot's headline is the hook (it is fully visible after `style.text_fade`, 0.2–0.25 s). Short marketing text is allowed on social videos (unlike store screenshots), always from `strings`, never hard-coded.
- **Real gameplay only**: every clip is a recorded capture; cards hold only the brand (name, icon, subtitle).
- **10 master videos**, about 15 s each, H.264 + AAC, each with its own hook angle built on a real feature (intensity, progression, prestige, upgrades, ...), not near-duplicates. The masters serve TikTok, Reels and Shorts alike unless a platform needs its own cut. One set, not one per locale: localized variants only when requested (`--locales`).
- **A 5/5 composition split**: 5 **focused** reframes (a window on the action, blurred fill) and 5 **full-landscape** videos (the whole landscape frame centred in 9:16 with black bands above and below; the hook and feature text sit in those bands, never on the gameplay). See the reframe table below.
- **Safe margins**: on `tiktok`, `reels` and `shorts` headlines and card text stay inside `SOCIAL_SAFE_AREA` (top 8 %, bottom 22 %, left 6 %, right 12 % of the frame: the platforms' tabs, caption and buttons). Override with `style.safe_area` (`{top, bottom, left, right}`, shares of the frame; text is centred, so it keeps the larger side margin on both sides).
- A **hard end** on the brand card (`fade_out: 0`, a short `music_fade_out`) loops cleanly on the platform.

**Reframing landscape footage** (a clip's `reframe`, only on shots that set it):

| Key | Default | Meaning |
|---|---|---|
| `x`, `y` | 0.5 | Centre of the source window, as shares of the source (kept inside the frame). |
| `width` | widest window at the video's aspect (a full-height 9:16 crop, about 0.32 of a 16:9 source) | Share of the source width the window shows. Wider than the video's aspect keeps the full source height and scales the window to the video's width. |
| `fill` | `blur` | What fills above and below a wider window: `blur` (the same moment, blurred small and darkened) or `black`. |

Two compositions, both from the same `reframe`:

- **Focused** (`{"x": 0.6, "width": 0.46}`): a full-height 9:16 crop of a landscape game often cuts the action at both sides; a window of about 0.45–0.5 of the source width keeps the central action large (about 70 % of the height) and leaves blurred bands where the headline (top) and the platform's caption (bottom) sit anyway. Centre each shot on its action (the tapped button, the fight). The headline band may overlap the picture's edge.
- **Full landscape** (`{"width": 1.0, "fill": "black"}`): the whole 16:9 frame at the video's width (1080×608 in 1080×1920), centred, black above and below. A shot's headline is set **in the black band**: `"position": "top"` above the picture, `"bottom"` below it, centred in the band and inside the safe area, without a translucent strip; `"center"` is refused. Copy that cannot fit its band (the band below is the narrow one: about one line at 1080×1920) is refused before anything is written, never drawn over the gameplay. Use the top band for the hook and either band for feature lines.

Check the review sheet at phone size: game UI must stay readable. The window and every headline's fit are checked against every clip before anything is written.

### Screenshots

**Default: no added text.** Store screenshots are language-neutral: authentic gameplay plus the game's own UI, so one set per device class serves every store locale and nothing needs translating (Playbook §87). A `screenshots[]` entry without `headline_key` (or with `headline: false`) copies its master byte for byte. Capture each device class (Phone, 7-inch tablet, 10-inch tablet, Desktop) as its own capture job at that size: a real render of the game's own layout, never a resized, cropped or upscaled image of another class.

**Optional headlines (an exception the developer approves for a specific game or campaign):** an entry with `headline_key` (or `headline: true`) gets that string on a translucent band (`position` top/bottom/center), for every requested locale; every headline is set and its glyphs checked before any file is written. Masters are never modified. Output: `<output dir>/<id>_<locale>.png`, the master's size.

## Fonts and text

**Fonts per locale** (`fonts`): a locale (or `default`, for every locale not listed) maps to one face or a fallback chain:

```json
"fonts": {
  "default": "fonts/MyGame-SemiBold.ttf",
  "th-TH": ["fonts/MyGame-SemiBold.ttf", {"file": "toolkit:NotoSansThai[wdth,wght].ttf", "weight": 600}],
  "ja-JP": ["fonts/MyGame-SemiBold.ttf", {"file": "toolkit:NotoSansJP[wght].ttf", "weight": 700}]
}
```

A face is a path (relative to the manifest, absolute, or `toolkit:<file>` in `assets/fonts/`), or `{"file", "weight", "width"}` for a variable face's `wght` / `wdth` axes (a static face refuses them: pick the file of that weight). Variable Noto faces default to weight 400: choose the weight explicitly. In a chain each character comes from the first face that has it: the game's brand face sets the Latin letters and digits, Noto the rest. System fonts are never used.

| Locale | Bundled face (`toolkit:`) |
|---|---|
| th-TH | `NotoSansThai[wdth,wght].ttf` |
| hi-IN | `NotoSansDevanagari[wdth,wght].ttf` |
| ja-JP | `NotoSansJP[wght].ttf` |
| ko-KR | `NotoSansKR[wght].ttf` |
| zh-CN | `NotoSansSC[wght].ttf` (Simplified) |
| zh-TW | `NotoSansTC[wght].ttf` (Traditional, Taiwan punctuation) |
| the other 14 (Latin, Cyrillic) | `NotoSans[wdth,wght].ttf` |

**Defaults:** a locale the manifest's `fonts` maps neither itself nor through `default` (or a manifest with no `fonts`) gets the toolkit's chain at weight 700: Noto Sans for the 14 Latin/Cyrillic locales; Noto Sans Thai, then Noto Sans, for th-TH; Noto Sans Devanagari, then Noto Sans, for hi-IN (the script face sets its script and basic Latin, Noto Sans anything else); the CJK face alone (it carries Latin) for ja, ko and zh. Every character of every locale's test strings is covered (`test_default_fonts_cover_every_locale`). Map a locale or `default` to use a brand face instead (keep Noto as its fallback for scripts the brand face lacks).

**Text renderer** (`text_renderer`, per manifest):

| Value | Sets the text with |
|---|---|
| `auto` (default) | Godot for each locale that needs it (a fallback chain, a shaped script such as Thai or Devanagari, Han/Kana line breaking), decided once per locale from all its approved copy; Pillow for the others, so Latin/Cyrillic copy needs no Godot and looks as before. |
| `godot` | Godot for every locale (not `builtin:pillow`). |
| `pillow` | Pillow/FreeType, one face per locale. A shaped script needs Pillow with Raqm (else it refuses); words without spaces (Thai) are never broken, so the author breaks lines (`\n`, or U+200B where a break is allowed). |

The Godot renderer (`addons/marketing_capture/text_renderer.gd`) runs `godot --headless --script` once per composition in a throwaway project (never the game's, whose autoloads would start), with the chains built by `marketing_fonts.gd`. Godot's text server shapes with HarfBuzz (Thai marks, Devanagari conjuncts, reordered vowel signs) and breaks lines with ICU (Thai dictionary words, CJK with kinsoku); each glyph comes from the text server's own glyph cache, so no window or GPU is needed. The layout rule is the composer's, for both renderers: the author's lines (`\n`) are kept whole while they fit at `style.keep_lines_scale` (85%) of the start size or more; otherwise the text is **re-wrapped from the full start size** at word boundaries (Thai and CJK: dictionary and kinsoku breaks; anywhere as a last resort) and shrinks only if the wrapped text still does not fit. Wrapped lines are **balanced** (the narrowest width that keeps the line count, so no word is orphaned on a last line). Nothing is set below `style.min_text_scale` (50%) of its start size: such copy is refused (`shorten the copy`). Start sizes: headline 6.5% of the shorter side (70 px at 1080), card title 112 px and subtitle 58 px per 1080. A portrait headline therefore wraps onto two or three lines at 70 px, where 0.3.0 shrank it to one line at down to 42 px.

**Glyph coverage fails closed:** a character no face of the locale has stops the command before any output (`The font chain has no glyph for U+65E5 日`), with either renderer. Pillow's `builtin:pillow` (tests) is ASCII only.

**Proof** (`fonts`): verifies the bundled faces against `font_manifest.json`; with `--manifest`, renders every requested locale's test strings (`assets/fonts/script_samples.json`: public pangrams and "I can eat glass" sentences, never marketing copy) through the real headline band (landscape and portrait) and card, and sets every approved string of the manifest too. Output: `fonts_<locale>.png`, `fonts_proof.png` (all locales) and `fonts_proof.json` (renderer, faces, size, wrap mode, lines, glyph counts) in `<output_root>/fonts_proof/` (or `--out`). Look at every script before approving.

**In a game:** `marketing_fonts.gd` is usable from an adapter (`preload`) to draw localized captions inside a capture with the same chains, loaded from absolute paths. It configures nothing in the game's theme: a game that ships localized UI sets up its own fallbacks and should bundle only the faces (or subsets) it ships, sized against its Android budget.

## Manifest reference

| Key | Meaning |
|---|---|
| `game_scene`, `adapter_script` | `res://` paths. |
| `ui_group` | Default `store_screenshot_ui`. |
| `output_root` | Gets a `.gdignore`. Paths are relative to the manifest. |
| `godot_user_args` | The game's own test-save switches (each `--flag`). |
| `log_show` | Extra Godot log substrings echoed during `record`. |
| `capture_jobs[]` | `id`, `kind` (`video`/`screenshot`), `scenario`, `options` (adapter's), `width`, `height`, `fps`, `duration` (video), `capture_frame`, `settle_frames`, `capture_ui` (screenshot), `output` (`.avi`/`.png`). |
| `fonts` | Optional. Locale or `default` → a face, `{"file", "weight", "width"}` or a fallback list; `toolkit:<file>` for the bundled Noto faces; `builtin:pillow` for tests (ASCII). Unmapped locales get the toolkit's Noto chain. |
| `text_renderer` | `auto` (default), `godot` or `pillow` (see "Fonts and text"). |
| `quality`, `quality_presets` | Default MP4 preset (`high`) and preset overrides `{name: {crf, x264_preset}}`. |
| `strings` | Locale → key → approved text (`\n` breaks a line). |
| `style` | `text_color`, `subtitle_color`, `accent_color`, `band_color`, `band_opacity`, `card_color`, `card_safe_width`, `text_fade`; `safe_area` `{top, bottom, left, right}` (0 = whole frame; vertical social profiles default to `SOCIAL_SAFE_AREA`); layout `keep_lines_scale` (0.85), `min_text_scale` (0.5); reading time `text_min_hold` (3.0 s), `reading_cps` (15). |
| `screenshots[]` | `id`, `raw`, `output`; optional text (an approved exception): `headline_key`, `headline` (default: true only when `headline_key` is set), `position`. |
| `videos[]` (or one `video`) | `id`, `profile` (`play_store`, `youtube`, `tiktok`, `shorts`, `reels`, `square`, `custom` + `width`/`height`/`fps`), `target_duration`, `output` (`.mp4`, `_<locale>` appended), `fade_in`, `fade_out`, `music`, `music_volume`, `music_start`, `music_fade_in`, `music_fade_out`, `game_audio`, `game_volume`, `quality`, `style`, `shots[]`. |
| `shots[]` | `id`, `kind` (`clip`/`card`), `duration` (seconds, `"auto"` for a card, `"fill"` for a clip), `transition_in` `{type, duration}`, `text_min_hold`, `reading_cps`; clip: `source`, `start`, `min_duration` (a fill clip's minimum, 1 s), `audio` (`game`/`none`), `reframe` `{x, y, width, fill}` (another aspect's footage), `headline_key`, `headline`, `position` (`top`/`bottom`/`center`; on a `fill: "black"` letterbox, the band above/below the picture); card: `headline_key`, `subtitle_key`, `image`. |

## Google Play listing localization package

The Playbook owns ASO strategy and translation approval. When ChatGPT/Claude produces the structured 20-locale JSON used with Google Play Console's AI-assisted translation import, validate it before handoff:

```powershell
python <toolkit>\tools\play_store_listing.py validate Google_Play_Localizations_AI_Import.json
```

Expected schema: `source_locale: "en-US"`, `localizations` containing **exactly 20 Play-facing locale tags** (English plus 19 translations), and for each locale `locale`, `language`, `title`, `short_description`, `full_description`. The baseline mapping explicitly converts the runtime identifiers **`uk-UA → uk`, `id-ID → id`, `vi-VN → vi`, `th-TH → th`**; the other 16 tags are unchanged. Do not put the four region-qualified runtime tags into the listing JSON. The validator enforces completeness, uniqueness and the reusable field limits (30 / 80 / 4000 characters).

If Play Console's accepted tags change, copy `examples/play_locale_map.example.json`, then prepare a **reviewed complete 20-entry mapping JSON** of `runtime ID` → `Play tag` and validate using `python <toolkit>\tools\play_store_listing.py validate <file> --locale-map path\to\play-locale-map.json`. Missing/extra mapping keys and duplicate Play tags are rejected. **The override does not establish which locales Google Play accepts.** After importing, inspect the detected 19 translations plus the English source and resolve any mismatch in the actual Play surface before publication.

## Validated, and not yet

Validated in Everfort (2026-10-14, Windows 10, FFmpeg 8.0.1, Godot 4.7.2): 32 language-neutral store screenshots in four device classes, a 30.000 s 1920×1080 Play trailer, and ten 15.000 s 1080×1920 TikTok masters from the trailer's landscape footage and music (no new capture): five focused reframes and five full-landscape cuts with their copy in the black bands, every transition smooth, every text readable long enough, music + game sound; 42/42 tests with Godot.


Validated in Growing Kingdom (2026-10-13/14, Godot 4.7.2, Windows 10, 1920×1080 screen): 14 capture jobs (5 landscape clips, 2 portrait 1080×1920 clips, 7 screenshots including 2560×1440), a 30.000 s 1920×1080 trailer and a 12.8 s 1080×1920 social cut with every fade through black passing the frame check, music + game sound, the interactive overlay's capture at sizes beyond the screen, `install`/`status` on a real project, release-pack exclusion. The original hard-cut trailer, run through `analyze`, shows its 9 hard cuts to black; the composed one has none.

Validated for 0.3.1-draft (2026-10-14, Loopcremental clean project, same machine; report in that project's `tests/marketing_showcase/VALIDATION_REPORT.md`): all 20 locales' test strings proofed with the default Noto faces and no `fonts` mapping (0.3.0 failed closed on nl, pl, tr, uk there); re-recorded 3 clips and 2 stills through the partial-file path; a 12.000 s landscape and a 10.000 s portrait MP4 with `auto` cards and `fill` clips, card text measured fully visible for 3.03 s (0.3.0's 2 s cards: about 0.7 s), portrait headlines wrapped at full size; High/Standard/Preview encodes; 35/35 tests.

Validated for 0.3.0-draft (2026-10-14, same machine): all 20 locales' test strings set with Growing Kingdom's font configuration (Open Sans SemiBold, Noto at weight 600 as fallbacks) and proofed visually; Thai and Devanagari shaping and Thai word breaking checked by tests; the English media recomposed at `high` (CRF 18) with every check passing.

Not yet required for our Windows-only development workflow: macOS/Linux runs. Still pending: locales beyond English with real approved copy (only test strings so far); a native reader's review of each script; the reading-time constants (15 units/s, CJK and Hangul weights) checked with real viewers; per-platform safe zones beyond the one shared `SOCIAL_SAFE_AREA` (checked on the review sheet, not against each app's current UI); right-to-left scripts (none is among the 20); a final Everfort production review and phone playback; PNG-sequence recording; beat-synced editing. The toolkit is stable for the validated Windows workflow. Real-device playback, platform-specific safe-zone checks, native-language review and publication remain per-game release QA.
