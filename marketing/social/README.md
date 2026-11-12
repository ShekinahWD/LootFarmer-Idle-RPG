# LootFarmer social videos (Change 70)

> **Revision 2 (12 Nov 2026, developer review).** The 15 s cap is gone (videos run 15 to 37 s). Panels are shown at
> full width, never cropped (the merge burst sits on the item icon at the panel's left edge). Every caption sits on
> a dark plate in one place per video, one at a time, and `review_social.py` now fails a caption shown for less
> than 1.4 s or asking for more than 14 characters per second. Video 2 is a new crit match cut (takes `c_winter`,
> `c_summer`, `n_crit`, `c_spring`) instead of a re-record of the Change 47 camera. Video 3 uses `n_gear2`: the
> boss's skills are on cooldown, the kill drops exactly its outfit and sword (seed 3316, found by search), and both
> lie in view for two seconds after the defeat effect before they are picked up. Video 5 uses HUD-free halves
> (`n_day1c`, `n_endc`) with a gold divider. Where this file says "15.000 s" below, read the durations in
> `store_assets/video/social/review/validation.json`.

Ten vertical masters (1080x1920, 30 fps, 15.000 s, H.264 High + AAC) for TikTok, Instagram Reels and YouTube
Shorts, built from **fresh takes of the current build** (HEAD `cece9c8`, 11 Nov 2026) with the pinned
**Godot Marketing Capture Toolkit 1.0.2**. Nothing here ships (`marketing/*` is in the Release preset's
`exclude_filter`; `store_assets/` is ignored by Git and Godot). Nothing has been uploaded.

Finished files: `store_assets/video/social/LootFarmer_Social_NN_<slug>.mp4`, their timelines in `timelines/`,
review sheets and `validation.json` in `review/`. Posting copy: `posting_copy.md`.

## Files

| Path | What |
|---|---|
| `social_scenarios.gd` | Adapter. Extends `../game_scenarios.gd` and adds one data-driven scenario, `soc`: a staged profile, a placement and timed steps that call what a tap calls (item panel Merge / Evolve buttons, `sim.equip`, `sim.collect`, `sim.use_item`, the Teleport picker's own controls, `campaign.settle_offline` and the Claim button, the map's Auto Farm button). `seed_search` + `want_drops` plays seeds in turn and keeps the first whose real kill drops the wanted items (found, never forced). |
| `make_social_manifest.py` -> `manifest.json` | The 30 capture jobs (`--draft` writes 540x960 staging jobs). `SOC_PROBE=1` adds balance probes (a fight run to its end) used to choose loadouts that win honestly. |
| `record_takes.py` | Records jobs one after another, prints each take's event summary, writes a contact sheet. `--manifest/--project` record from another checkout (the "before" worktree). |
| `social_engine.py` | Frame compositor: FFmpeg decode, crop window / slow push, split screen, cut / flash / crossfade, Pillow text (Lilita One) with a safe-area guard, one H.264 encode, music section or the takes' own game sound. |
| `build_social.py` | The ten storyboards (shots, in-points, strings, message type, music in-point). |
| `review_social.py` | Validation (`validation.json`, non-zero exit on a failed contract) and review sheets. |
| `posting_copy.md` | One caption + hashtags entry per video. |

## Commands (project root, Windows)

```powershell
python marketing/social/make_social_manifest.py            # manifest.json
python marketing/social/record_takes.py                    # all 30 takes (about 12 min); or take ids
python marketing/social/build_social.py                    # all ten; or numbers, e.g. 3 7
python marketing/social/review_social.py                   # validation + sheets
```

Recomposing (copy, timing, order, music in-point) never needs a new recording: edit `build_social.py`, build,
review. Re-record a take only when its gameplay or framing must change.

## Sources

- **Current build:** `store_assets/raw/video/social/*.avi` (+ `.log` with every event and its take time).
  Profile `capture-store`, `--no-autosave`; the adapter starts from `sim.new_profile()`.
- **"Before" footage (video 1 only):** `store_assets/raw/video/social/before/o_pack.avi` and `o_teleport.avi`,
  recorded from a detached worktree of `3dd2eab` (6 Nov 2026, the build the review described) outside the
  repository, with that commit's own adapter (`match_boss`, `explore`); and `trailer_c32/c33_gear.avi`
  (28 Oct 2026 build). The working tree was not touched.
- **End card:** `store_assets/raw/video/trailer_c32/end_card.mkv`, the approved brand card restaged from the
  feature graphic (it shows the feature graphic's Iron Sword; brand art, not a gameplay claim).
- **Sound:** nine videos carry only `assets/sounds/background_music.wav` (one continuous section each, in-points
  on the track's downbeats, 145 BPM); video 6 carries the takes' recorded game sound effects with the same track low underneath (level 0.3;
  music volume is 0 in every take, so cuts never restart it).

## Staging rules kept

Real play only. Fixtures stand in for play time (a profile at a map, owned gear and merge levels, upgrades
within their caps, earlier boss defeats so no unrelated banner rises, a fight fast-forwarded in the real
simulation, a skill or summon cooldown moved to just before its real event, the offline clock moved back
8 hours before the game's own settlement). Loadouts follow the current rules: evolvable weapons at most ^20,
outfits at most ^500. Hero levels above a map's boss level (200 at Summer II, 400 to 500 at Autumn II) are those
of a player who has used Prestige, which keeps the level. Never the final Green Alien boss.

Probed outcomes the videos rely on (`SOC_PROBE=1`, same seeds): at level 400 with a Gold Sword ^20 and an
unmerged Red Fox outfit the hero loses to the Grim Reaper; with the outfit at ^500 and a Diamond Sword ^20 the
same hero wins with 25 HP left (video 10).

## Rights

REL-02 is still open: no licence or purchase record exists in the repository for `assets/sounds` or the Pixel
Plains art. These are local review masters, not cleared for upload.
