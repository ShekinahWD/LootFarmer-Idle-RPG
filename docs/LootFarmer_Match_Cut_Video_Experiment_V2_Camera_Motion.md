# LootFarmer — Match-Cut Experiment V2: Moving Camera + Swords Only

**Task:** Produce a **second, distinct experimental video** (not a proposal) that improves the earlier four-season match-cut concept with **coordinated camera movement through the cuts**. Treat the first experiment as the comparison baseline, **not** something to overwrite. Work in the developer's **current local Godot repository**.

**Deliverable:** `store_assets/video/experiments/LootFarmer_MatchCut_Camera_V2.mp4` — ~15 seconds (14–17 acceptable), **1080×1920, 30 fps, H.264/yuv420p, AAC**, 9:16 portrait. Keep the existing approved Play trailer and V1 masters unchanged.

**Priority order:** Real combat and clean continuity > camera-motion match cuts > recognizable escalating enemies/gear > optional effects. This is a **focused, low-token production pass**: make **one good candidate**, review/fix obvious mistakes, deliver it.

## 1. The locked four-shot story

| Shot | Environment / real encounter | Player's visible progression | Sword |
|---|---|---|---|
| 1 | **Winter II:** pack of regular enemies | Early/simple outfit and attack | **Wood Sword** (`wood_sword`) |
| 2 | **Summer II:** **Teal Dinosaur boss** | Improved outfit, boss combat | **Iron Sword** (`iron_sword`) |
| 3 | **Autumn II:** **Grim Reaper boss genuinely summoning enemies**; summons must be visible | Advanced outfit, stronger combat | **Gold Sword** (`gold_sword`) |
| 4 | **Spring II:** **Red Panda boss**, or clearly superior-looking **non-final** Spring II boss if justified | Best-looking legitimate late-game outfit, dramatic sword-led combat; hold longer | **Emerald Sword** (`emerald_sword`) |

**Hard rule: swords only.** The hero must equip and visibly wield **a sword in every scene**—no axes, bows or mixed weapon types, even if earlier recordings used axes. Different sword tiers are intentional and should visibly progress. Choose real obtainable outfits that also make the hero look increasingly powerful; avoid a player outfit that makes the hero indistinguishable from the boss. Never show the final **Green Alien** boss. Use actual game actors, sword attacks, summoned enemies, skills and weather; no fabricated combat or artificial enemy/equipment transformation.

The video is an editorial progression montage, not literal in-game instant upgrading. Avoid text labels between shots; let the seasons, swords, outfits and enemies communicate escalation.

## 2. Key change vs. V1: **camera motion continues across the match cut**

The inspiration is the dynamic camera movement commonly paired with action match cuts (reference supplied by developer: `https://www.youtube.com/shorts/z6ZjX3gYFRY`). Use it as **motion inspiration only**, not a requirement to copy specific frames or use someone else's video/audio.

**Do not** simply add a pan/zoom separately to each clip: the cut should occur **while the camera is moving**, with the *outgoing and incoming* motion matching in **direction and approximate speed**. Match sword swing phase, hero position/scale, attack direction and framing at the same time. The result should briefly feel like **one flowing camera move** transporting the viewer to the next world.

Suggested choreography (adjust to actual footage if needed):

| Boundary | Camera choreography | Cut anchor |
|---|---|---|
| **Winter → Summer** | Short **horizontal tracking move** in the sword-swing direction. Carry the same-direction movement across the hard cut; settle in Summer on the boss. | Same **sword swing / impact phase**, near-identical player screen location. |
| **Summer → Autumn** | **Fast, controlled push-in** toward the hero/boss clash, continuing through the cut, then gentle settle/reframe to show Grim Reaper and its **real summons**. | Peak sword contact or a naturally obscured real combat impact. |
| **Autumn → Spring** | **Diagonal tracking or slight pullback** following the sword attack; match the outgoing motion to the incoming Spring shot, revealing the more impressive final encounter. | Same sword-attack arc; keep the boss and upgraded sword legible after the cut. |

**Editing principles:**

- These are **action + camera match cuts**, not slide wipes, scene crossfades, spinning transitions, or a slideshow. Prefer **hard cuts during continuous camera motion**; at most one brief impact-masked cut if an *existing real in-game effect* helps conceal it.
- Camera moves should be **noticeable but controlled** on a phone. As an initial guide, start ~0.25–0.6 s before each cut and continue ~0.2–0.5 s afterward; adjust to the game's attack cadence and the 8-bit track. No need to use all three different moves if they hurt continuity.
- Keep the sword/player as a strong visual anchor, but preserve enough of each season and each enemy to identify it. No excessive shake, constant zooming, letterboxing, black frames, digital smearing or heavy motion blur that destroys pixel-art clarity.
- **Prefer capture-only camera movement within Godot** when it produces cleaner framing/parallax. The existing marketing adapter already supports clean shots and zoom push-ins; extend it minimally for a **scripted camera offset/tracking motion** if needed. **FFmpeg animated crop/reframe** is a reasonable simpler alternative *only* with adequate source padding/overscan and no empty edges or blurry upscaling. You may mix approaches. Do **not** alter the live gameplay camera or save-game settings.
- If the most ambitious motion looks worse, simplify to a restrained moving-camera match cut rather than forcing an obvious gimmick. Matching **camera velocity + sword pose** matters more than effect complexity.

## 3. Pacing and music

Approximate visual timeline: Winter 0–2.3 s; Summer 2.3–5.2 s; Autumn 5.2–9.0 s; Spring 9.0–12.2 s; familiar approved portrait end card ~12.2–15.0 s. Adjust to actual events; **the Grim Reaper summon must occur on screen**, and Spring must have time to register as the strongest encounter.

Keep **the exact established 8-bit track** from the approved trailer: `assets/sounds/background_music.wav`. One **continuous musical passage** across all scenes; sync the moving-camera cuts to natural chiptune accents when possible. **No heavy-beat soundtrack, extra drums, voice-over, generated music, sound effects or game audio.** Strip gameplay AVI audio at composition. A subtle fade on the *end card* is fine; no fades *between* the four action shots.

## 4. Efficient technical path and project protection

1. Read only relevant guidance: `docs/Reusable_Game_Development_Playbook.md` §§ **87.2, 133.1–133.3, 133.7, 135** and `marketing/trailer/README.md`; also use the supplied V1 experiment brief if attached. **Do not run broad audits.**
2. Use the existing **Godot Marketing Capture Toolkit 1.0.2**, `marketing/game_scenarios.gd`, the current trailer manifest/generator and approved end-card master. The developer confirms **raw recordings already exist locally**: do not spend tokens verifying their existence. **Reuse compatible sword footage; recapture where wrong weapon, camera motion or encounter prevents a real match cut.** Older `c33_winter` / `c33_spring` takes used **axes**, so **do not reuse those unchanged**. Farming takes are not substitutes for boss fights or the Grim Reaper summon.
3. Keep V2 in a **new experimental** manifest/script space (e.g., `marketing/match_cut_v2/`), not the approved trailer pipeline. Use isolated `capture-store` / `--no-autosave` capture-only fixtures and the game's real simulation: real enemies, real boss AI/summon, authentic sword attacks and skills. If necessary, minimally add a capture-only scripted-camera option to the adapter. No shipped mechanics, balances, saves, export rules, marketing assets or Playbook changes.
4. Stage, record/reuse, and compose **one** V2 MP4. Refine camera curves, frame in-points and cut timing until the **three joins are readable and convincing**. Preserve the V1 and existing published/trailer output paths. Do not replace `store_assets/video/LootFarmer_Play_Trailer_en-US.mp4`.
5. Deliver: **MP4**; a compact **three-boundary contact sheet** showing frames just before/on/after each transition; a **phone-size whole-video strip**; and a short report including source take IDs, sword/outfit per shot, Grim Reaper summon evidence/time, transition frame numbers, camera-motion type and speed/direction at each cut, audio source, and any compromises. Compare with V1 where its local video exists—no need to reconstruct V1.
6. Verify via `ffprobe`: length, exact dimensions, 30 fps, H.264/yuv420p, AAC **music-only** (one audio stream), and no unexpected black frames. Review all three joins frame by frame and at actual phone size. Check existing trailer/source files remain unmodified. Run **only relevant capture/video validations**. If tracked source changes, make **one autonomous sequential `Change N` commit** per repository convention; leave raw/generated review video files local/ignored.

**Completion rule:** Return an actual playable V2 MP4, not a design-only response. If a real encounter or camera join proves infeasible, deliver the best honest partial cut plus a concise blocker—do **not** fake gameplay. No publication/upload authorization; the project's existing media-rights checks still apply.
