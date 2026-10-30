# LootFarmer: Idle RPG — Four-Season Action Match-Cut Experiment

**Status:** Approved creative brief; produce the video now, not another proposal.  
**Project baseline:** The developer's **current local Godot repository**.  
**Output:** One self-contained **~15-second (acceptable 14–17 s), 1080×1920, 30 fps, H.264/yuv420p + AAC** portrait MP4 for developer review.  
**Location suggestion:** `store_assets/video/experiments/LootFarmer_MatchCut_15s_v1.mp4`.  
**Priority:** Convincing match-cut action > clear visual power progression > extra effects.

## 1. Approved idea (locked)

Show one escalating combat montage, with the hero getting **visibly stronger at every transition** and the opponent becoming more threatening. The player should remain in approximately the same on-screen position, scale, facing, and phase of their attack as the season changes. The video should feel like one fluid progression, not four arbitrary clips.

| Order | Stage | Genuine encounter | Hero progression and visual purpose |
|---|---|---|---|
| 1 | **Winter II** | A group of **normal enemies** (not a boss) | Modest, recognizable early equipment; simple melee attack; winter environment immediately readable. |
| 2 | **Summer II** | **Teal Dinosaur boss** | Clear outfit/weapon upgrade; a harder boss; summer/rain contrast. |
| 3 | **Autumn II** | **Grim Reaper boss summoning enemies** | Advanced-looking gear; **the genuine summon must be visible**; leaves/Autumn visible. The Grim Reaper **does** summon enemies. |
| 4 | **Spring II** | **Red Panda boss**, unless another **non-final** Spring II encounter is demonstrably better on camera | Strongest, most impressive *legitimate* build; readable skills/combat; hold this shot longer. **Do not reveal the final Green Alien boss.** |

Equip progressively better **real, obtainable** outfits and weapons from the actual item catalog, roughly beginner → iron-tier → gold-tier → high-end/emerald-tier where appropriate. Prioritize **visibly distinct character silhouettes**, not numbers or UI stats. The four seasonal backgrounds must be discernible. The montage is editorial time compression, **not** a claim that hitting enemies instantly upgrades the player.

**Pacing guide (flexible):** Winter ~2.2 s → Summer ~2.7 s → Autumn ~3.4 s → Spring ~3.4 s → approved portrait branding ~3.3 s. Keep the last combat shot longer if needed. No explanatory title cards or transition text; the action should speak for itself.

## 2. Transitions (the experiment's main feature)

**Primary: hard action match cuts**, *not* slides, wipes or standard fades. Choose the same phase of a real attack (for example, sword impact or peak swing) in the outgoing and incoming take. Match:

- Hero screen position, sprite size, facing, attack pose / swing phase and direction of motion.
- Camera framing and approximate relative target position (enemy directly above/in front of hero works well in portrait).
- Timing around natural accents of the existing 8-bit music, **without switching to beat-heavy music**.

Use **one subtle impact-masked cut** only if a **real in-game attack or skill effect** already crosses the transition and conceals it naturally. Do not synthesize fake combat, fake equipment transformation, artificial gameplay effects or a pixelation gimmick. No world-to-world crossfades unless a specific match-cut is visibly worse and an extremely short fallback is necessary; report that fallback. Fade only into/out of the existing approved brand end card where appropriate.

The scene changes should be instantaneous but the hero's movement should look continuous. If an exact frame match is impossible, prioritize matching **motion and silhouette** over an elaborate transition effect. Judge the cut at both full resolution and phone-screen size.

## 3. Audio (locked)

Use **only** the game's established 8-bit track, `assets/sounds/background_music.wav`, as used in the approved trailer. One **continuous** musical passage across the entire edit, with only unobtrusive head/tail fades. Transitions may land on chiptune accents but **must not** introduce a new heavy-beat track, additional drums, game sounds, impact SFX, speech or generated audio. The existing composition used `music_start: 60.0`; that is a useful starting point, not a requirement. Strip **all** AVI game-audio tracks at composition and verify the MP4 has the single intended AAC stream.

## 4. Reuse the local system; protect approved assets

The raw recordings **already exist locally**. **Do not spend tokens checking whether the raw folder exists or ask for it to be supplied.** Start from the current local repo, use existing masters where they actually fit the scenes, and record **only missing or poorly aligned boss/attack shots**. Existing `c33_winter`, `c33_summer`, `c33_autumn`, `c33_spring` recordings are *farming shots*, **not substitutes for required boss encounters**. The existing `c32_boss` is a Sunflower encounter; don't relabel it as Red Panda or Grim Reaper.

Read only the directly applicable portions of `docs/Reusable_Game_Development_Playbook.md` (§87.2, §133.1–133.3, §133.7, §135) plus `marketing/trailer/README.md`. Reuse pinned **Godot Marketing Capture Toolkit 1.0.2**, `marketing/game_scenarios.gd`, `marketing/trailer/make_trailer_manifest.py`, and the *existing portrait end card master* (`store_assets/raw/video/trailer_c32/end_card.mkv`) as references. Do not rewrite the toolkit or duplicate its video pipeline. Use a **separate experimental manifest/script directory** such as `marketing/match_cut/`; keep changes to the shared adapter minimal and capture-only. The experimental video must **not overwrite** `store_assets/video/LootFarmer_Play_Trailer_en-US.mp4` or alter the approved trailer's generator/manifest.

Use normal game logic for attacks, boss summons, player abilities, outfits and weapons. Capture-only fixture profiles / fixed seeds / staging / camera options are allowed as in the existing pipeline; **no changes to live enemy behavior, drop rates, gameplay balance, save behavior, or Android builds**. All scenario code must be non-shipping, respect `capture-store` and `--no-autosave`, and preserve the release allowlist. Keep prior approved store screenshots, app icons, feature graphics, Play listing assets and the Reusable Playbook unchanged.

## 5. Efficient execution — one focused production pass

1. Read the relevant files once, inspect only scenario and boss/summon APIs needed to stage these four genuine encounters.
2. Reuse existing suitable Winter footage. Create the smallest necessary **game-specific** reproducible staging for the Summer Teal Dinosaur, Autumn Grim Reaper summon, and Spring II Red Panda. Compose one clean 9:16 sequence; don't build a general-purpose transition editor.
3. Render a **single candidate** MP4. Adjust cut frames/clip in-points as needed for a credible match. Avoid alternative versions and unnecessary research unless the result clearly fails.
4. Deliver a compact review: MP4, a **three-transition contact sheet** (last 2–3 frames before each cut and first 2–3 after), a phone-size preview/contact sheet, and a short report stating the source clips, transition frame numbers, real summon evidence, chosen outfits/weapons, music source and any compromises.
5. Validate with `ffprobe`: actual duration, 1080×1920, 30 fps, H.264/yuv420p, AAC music-only, no extra audio streams. Check that old approved assets were not modified. Run only relevant capture/video checks; no unrelated full game test suite unless required by actual changes. If editing tracked source, make **one autonomous sequential `Change N` commit** under the project's existing convention; keep review video masters local/ignored.

**Done means an actual playable MP4 exists**, not merely a storyboard, manifest, screenshot set or code. If resources prevent all four authentic scenes, deliver the best real-footage partial video plus a precise blocker rather than faking the missing scene. Ask no creative follow-up questions; choices within these boundaries are delegated to Claude.

**Publication gate:** This is a **local experimental review master**, not an approved trailer replacement or authorized upload. Preserve the existing outstanding audio/art licensing checks before publication.
