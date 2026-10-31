# LootFarmer — Match-Cut Experiment V3: Zoom Rush Transitions

**Implementation brief for Claude — execute in the CURRENT LOCAL LootFarmer repository.**

**Goal:** Produce a third, independently reviewable ~15-second portrait gameplay video. Build on **Change 45 / V2**, replacing its horizontal/diagonal camera traveling with **fast, centered zoom-in / zoom-out match cuts**. The edits must feel like the viewer is rushing into and pulling away from real combat, with a restrained speed effect during the rapid zooms.

**Required output:** `store_assets/video/experiments/LootFarmer_MatchCut_Zoom_V3.mp4` — target **15 seconds** (14–17 acceptable), genuine **1080×1920 portrait**, **30 fps**, **H.264 / yuv420p**, **AAC music-only**. Also deliver compact transition and phone-size review images, and a short validation report.

**Protect:** Do **not** overwrite the approved store trailer, V1, V2, source footage, or their reports. Do **not** alter shipped gameplay behavior, the regular player HUD, saves, balances, release/export configuration, or the Reusable Playbook. This is a **marketing-capture-only** experiment. No uploads or publication.

## 1. Locked story and equipment progression

Keep the established four encounters and **swords only**:

| Shot | Real environment and encounter | Player progression | Sword |
|---|---|---|---|
| **1 — Winter II** | Reindeer Antlers **group of ordinary enemies** | Basic outfit/attack | **Wood Sword** |
| **2 — Summer II** | **Teal Dinosaur boss** (rain visible if possible) | Better-looking legitimate outfit | **Iron Sword** |
| **3 — Autumn II** | **Grim Reaper boss** and its **actual in-game summoned Horned Hoods**, shown on screen | More advanced outfit, sword-led combat | **Gold Sword** |
| **4 — Spring II** | **Red Panda boss** (non-final boss) | Strongest legitimate outfit, sword and visually impressive **real skills** | **Emerald Sword** |

Player outfit and sword must be visibly more impressive at each change. Keep the same recognizable player/attack action through each cut. **Never show the final Green Alien boss.** Use authentic gameplay: do not fabricate an enemy, summon, damage event, item, skill or equipment change in post-production. The actual summoning event must be captured and supported by a capture log.

## 2. Main creative change: zoom movement, NOT side movement

**No horizontal pans, diagonal tracking, slide transitions, traveling across the map, or sideways cinematic camera offsets.** Keep the **player and their opponent together as the visual center** of every shot. Framing may make the small adjustment needed to keep the combat pair centered, but should not visibly drift to either side.

Follow this **IN → OUT → IN** rhythm, with zoom motion continuous across the three hard cuts:

| Section / cut | Zoom choreography | What must remain readable |
|---|---|---|
| **Winter → Summer** | **Winter starts wider** so the normal enemy pack is recognizable. Begin a **fast zoom IN** into the sword clash shortly before the cut; continue **zooming IN** across the hard cut and settle in Summer on a close but fully readable hero + Dinosaur fight. | Winter pack before rush; hero, sword and Dinosaur after rush. |
| **Summer → Autumn** | Hold the close-up briefly in Summer. Build a **fast zoom OUT** approaching the swing/cut; continue **zooming OUT** into Autumn, revealing the Grim Reaper and the actual spawned helpers. Settle on a medium/wider combat view. | Both combatants and the summons; Autumn must not look like an empty scene. |
| **Autumn → Spring** | After the summons have been clearly shown, **zoom IN rapidly** toward an authentic sword impact. Cut while still moving **IN**, continue and decelerate in Spring toward the Red Panda + strongest hero. | Red Panda and hero remain fully in frame; sword and effects are legible. |
| **Spring → end card** | Hold the best-looking fight with **stable or very gentle final close-up**. Transition cleanly to the **existing approved end card** (normal fade acceptable here only). | A few uninterrupted frames of dramatic Spring combat before branding. |

**Do not** alternate separate zoom animations that stop at each cut. At every match cut, match **zoom level**, **zoom direction**, and **zoom velocity** in the outgoing and incoming frames; also match the hero's **screen position, orientation and sword-swing phase**. The Winter sideways-attack vs. upward-attack mismatch identified in V2 should be corrected with a new suitable take if needed. Use the same attack direction at the boundary whenever practical.

**Framing constraint:** Anchor zooms to the **visual midpoint of the player and boss/enemy group**, not the player's feet alone. At every sampled moment, the player, relevant enemies and swords must remain within safe, visible bounds. A zoom that loses the boss or crops the weapon **fails**, even if it looks fast. Do not make an over-tight close-up or upscale low-resolution footage noticeably.

**Camera timing guide, not a rigid requirement:** Ramp up over approximately **0.25–0.50 seconds** before each cut; travel through the cut for approximately **0.15–0.35 seconds**; ease into the new shot. Use actual zoom curves appropriate for the footage and 30 fps. The zoom should be clearly visible at phone size, but avoid nauseating jolts or a single-frame scale discontinuity. Favor controlled speed over large zoom distance.

## 3. Speed effect — short and restrained

Add a **brief sense of speed** to rapid zooms, if it actually improves the result:

- Try a short **radial / zoom motion blur** or subtle outward/inward speed streaks **centered on the combat pair**. Drive intensity from zoom speed rather than applying a constant overlay. Aim for roughly **0.10–0.20 seconds** around the fastest part of each rush.
- Preserve **pixel-art readability**: swords, character silhouettes, enemies and damage moments should remain identifiable. If a fully blurred frame hurts readability, lower the strength or limit the effect mostly to the environment.
- No screen-whip, lateral smear, heavy shake, white flash, spinning, crossfade, or black-frame concealment between seasons. Use **hard action cuts** with real zoom continuity. Optional *very subtle* impact emphasis is acceptable only if it remains readable.
- Prefer a clean zoom without blur over a flashy but unconvincing effect. Do not spend excessive time building a new post-processing framework for an optional effect.

## 4. Capture HUD changes — preserve gameplay clarity

V2 is visually too flat when nearly all UI is removed; reduce combat clutter selectively instead of hiding everything.

**Capture-only visibility rules:**

1. **Hide the PLAYER's health bar**, including any floating player HP display that distracts from the outfit/sword. Do not change real HP/damage/combat values.
2. **Keep the existing compact inventory/equipment HUD section visible** (the unobtrusive inventory/quick-access UI that normally appears during gameplay), provided it does not cover the actors. Do **not** open a full inventory panel, manufacture inventory overlays or introduce new UI art. Position the fight above the relevant HUD so it stays legible.
3. **Keep the boss health bar** as a recognizable cue for boss fights, unless a specific capture framing makes it cover essential action. Do not fake health bar values.
4. **Reduce damage-number congestion**, especially in Winter, via capture-only display filtering/visibility or better staging. Retain enough feedback to convey real hits; do not alter actual damage or game balance.
5. Leave real skills, attacks, weather and the Grim Reaper's summons visible. Prefer minimal HUD-specific capture flags over enabling a broad clean-HUD mode that hides the inventory section too.

If the inventory HUD would visibly obstruct the fight at a specific zoom, adjust authentic capture framing **first**; do not move the fight entirely off-center just to accommodate the HUD.

## 5. Music, pacing and authenticity

- Use **only** `assets/sounds/background_music.wav`, with **one continuous passage** as in the approved trailer and V1/V2. No new soundtrack, heavy beat, game sounds, attack SFX or voice-over. Exclude the recorded gameplay audio in the composition.
- Keep the video approximately **15 seconds**. Use about **2 s Winter**, **3 s Summer**, **3–4 s Autumn**, **3–4 s Spring**, followed by the **approved existing end card** for the remaining ~3 s. Shift cut frames to match genuine attack phases and to **show the full summon event**, not to meet an arbitrary timestamp.
- Make the fourth Spring fight slightly longer/more impressive than the earlier sections. No inter-shot text cards. No reveal of the final boss.
- Time zoom peaks to natural accents in the original 8-bit music where practical; the music must remain uninterrupted through all match cuts.

## 6. Lean implementation path (Claude token budget)

1. Read the relevant sections only: `docs/Reusable_Game_Development_Playbook.md` §§ **87.2, 133.1–133.3, 133.7, 135** and the existing `marketing/trailer/README.md`. Use **Change 45's V2** scripts/manifests/report as your implementation base, not older ZIP state or a new architecture. The developer has **confirmed raw recordings are present locally**: **do not spend tokens auditing whether they exist**.
2. Start from V2's deterministic four encounters and sword choreography. Reuse compatible recordings, but **recapture shots as needed** for correct zoom geometry, unobstructed composition, selective HUD visibility and Winter's attack direction. Existing V2 camera-offset shots may not be suitable for the new center-anchored zooms.
3. Implement zoom in the **marketing capture adapter** using real Godot camera framing when this yields sufficient source quality; alternatively use a well-bounded FFmpeg crop/zoom if recordings have genuine overscan and no empty edges or blurry upscaling. Avoid modifying installed toolkit files or the production camera. For the optional speed effect, use a small, reproducible FFmpeg filter/compositor step rather than a major new system.
4. Keep V3 in its own experimental manifest/scripts directory (e.g. `marketing/match_cut_v3/`) and final output path. Reuse the existing end card. Run **one candidate** and correct only obvious alignment/visibility issues; do not spin off many alternatives.
5. Deliver the **actual playable V3 MP4**, a **three-cut review sheet** (frames before / at / after each cut, plus a handful from each zoom ramp), a **phone-size contact sheet/strip**, and a **concise report** (scenario/take IDs, weapon/outfit, real summon timestamp, cut frame numbers, zoom scale/direction at each boundary, UI controls, speed-effect choice, remaining compromises).
6. Validate with `ffprobe` and visual checks: correct **1080×1920 / 30 fps / H.264 yuv420p / AAC**, expected runtime and **exactly one music-only audio stream**; no accidental black frames; no noticeable frame jump, sideways camera travel, weapons/bosses cropped, UI-over-combat, or broken music. Verify older trailer, V1 and V2 files unchanged. Run relevant marketing tests only.
7. Follow repository convention: commit **only necessary tracked V3 source changes** with the next sequential **`Change N`** commit. Leave generated raw captures, video and review media in their established local/ignored directories. Preserve pre-existing uncommitted user edits.

**Success criterion:** On a phone, the player visibly upgrades from **Wood → Iron → Gold → Emerald sword**, opponents escalate through **normal pack → Dinosaur → summoning Grim Reaper → Red Panda**, and all three zoom-assisted hard cuts feel like one camera rushing **IN → OUT → IN** through continuously matched sword combat. The **player health bar is absent**, the **real compact inventory UI is present**, the **boss bar remains useful**, and the old 8-bit music plays without interruption.

**Fail-safe:** If the radial blur or ambitious zoom makes the edit worse, simplify the effect and keep a clean centered zoom match cut. Deliver the best honest result plus a brief limitation; never fake gameplay, modify the approved trailer, or publish footage before the existing **REL-02 media-rights** gate is satisfied.
