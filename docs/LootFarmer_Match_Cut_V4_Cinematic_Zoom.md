# LootFarmer — Match-Cut Experiment V4: Cinematic Zoom Refinement

**Implementation brief for Claude. Execute in the CURRENT LOCAL LootFarmer repository.**

**Base:** Change 46 (`bdb1718`), the completed V3 zoom experiment. This is a targeted **visual refinement**, not a new trailer or a redesigned capture system. Reuse V3's working four-scenario setup, sword choreography, selective HUD, music, and compositor. Do not begin by auditing for raw recordings; **they already exist locally**.

**Goal:** Make the three **IN → OUT → IN** zoom match cuts visibly energetic on a phone, like a camera rushing between fights, while preserving **smooth motion across each cut**, consistent hero size/position, and readable combat. V3 passed technical checks but its zooms feel too much like ordinary hard cuts; the Winter shot is too wide and Winter → Summer has a perceptible hero-size jump.

**Deliverable:** `store_assets/video/experiments/LootFarmer_MatchCut_Zoom_V4.mp4`; approximately 15 seconds (14–17 acceptable); **1080×1920, 30 fps, H.264 yuv420p, one AAC music-only track**. Provide `review_v4/` contact/transition sheets and a concise Change N report. Preserve the original approved trailer and V1/V2/V3 **byte-for-byte**; do not upload anything.

## 1. Locked content — no storyboard changes

| Shot | Encounter (genuine gameplay) | Sword | Progression |
|---|---|---|---|
| **Winter II** | Reindeer Antlers ordinary enemy group | **Wood** | Basic outfit/combat; introduce the pack |
| **Summer II** | Teal Dinosaur boss | **Iron** | Stronger appearance and attacks |
| **Autumn II** | Grim Reaper boss **actually summoning two Horned Hoods** | **Gold** | Advanced appearance; reveal the summon clearly |
| **Spring II** | Red Panda boss | **Emerald** | Strongest-looking character and real combat skills; longest fight |

Keep the authentic sword-swing matching and **same facing/attack direction** across all cuts. Never reveal the Green Alien final boss. Keep the **existing end card** and **one continuous passage of `assets/sounds/background_music.wav`**; no new beat track, sound effects, narration, inter-shot cards, fake gameplay, or other music. Existing approximate V3 shot lengths and end-card fade are acceptable; adjust a few frames only to improve genuine attack matching and show Autumn's real summon.

## 2. Primary correction: visibly stronger zoom choreography

**No sideways or diagonal camera travel, pans, slides, whip movements, or scene crossfades.** The hero and relevant enemies stay the center of attention throughout. Use actual camera zoom in capture when practical, or a reproducible world-only post transform if it preserves quality; do **not** scale or blur the inventory HUD together with the world.

| Cut | Required choreography | Desired experience |
|---|---|---|
| **Winter → Summer: fast IN** | Start Winter **closer than V3**, but wide enough to recognize the full pack. Accelerate quickly toward the sword clash, **continue zooming IN through the hard cut**, then ease into the Summer boss fight. | A visible approach into combat, **not** a sudden change in actor size. |
| **Summer → Autumn: fast OUT** | From the closer Summer fight, accelerate zoom **OUT** into the cut; keep zooming OUT after entering Autumn; settle wide enough to show the **Grim Reaper plus its real summoned enemies**. | The world opens up to reveal the more complex encounter. |
| **Autumn → Spring: fast IN** | After the helpers are visibly shown, accelerate zoom **IN** toward a real sword impact; carry the inward motion into the Red Panda fight and settle on the clearest dynamic framing. | The biggest payoff, showing the strong Emerald Sword build and boss together. |

**Camera kinetics:** Prefer clear acceleration → short, fast traversal across the cut → deceleration. Use a reproducible easing/speed-ramp curve (not constant-speed linear scaling). As a starting point, use ~0.25–0.45 s to build speed before the cut and ~0.20–0.40 s to settle afterward, with **nonzero speed at the cut**. Tune the total zoom travel to be **noticeably larger/faster than V3** without clipping subjects; a range such as **~20–40% apparent scale travel over a transition window** is an exploratory target, **not** permission to exceed visibility or resolution limits. If the available zoom range is tight because the dock is visible, prioritize **quicker acceleration and stronger perceived travel**, not a cropped ultra-close-up.

**World-only motion:** The dock and other retained screen-space UI must stay in place and at constant size while the world zooms. Do not emulate speed by sliding the whole frame or enlarging the dock. Use the midpoint of the **visible hero and opponent(s)** as a stable framing reference; minimal follow corrections to keep the pair in the safe playfield are fine, but no intentional side motion.

## 3. Fix cut alignment and hero scale (especially Winter → Summer)

A match cut is not validated by having the same raw camera zoom number: differing costumes, source framing and animation poses can still produce an obvious jump.

At each of the **three** cut boundaries:

1. Select **real wind-up / slash frames** matching sword direction, hero orientation, and action phase, as closely as the existing game allows.
2. Match the hero's **screen-space anchor** (e.g., torso/feet center) before and after the cut. Keep the action pair visually centered in the world area **above the inventory dock**, not the midpoint of the entire 1080×1920 video.
3. Match **perceived hero size** using comparable sprite features or a reference pose, not just numeric zoom. Avoid a sudden actor-scale change; inspect one frame before and after each hard cut at full resolution and phone size.
4. Match the **direction and velocity** of zoom through the boundary: no freeze, reversal, discontinuity or one-frame jump in scale. Different environmental backgrounds are expected; the **hero movement** must read as continuous.
5. For **Winter**, replace/reframe the take if necessary so the pack is close enough to see yet the hero stays legible and aligned with the first Summer frame. Do not fake a size match by excessively enlarging low-resolution footage.

**Practical review targets, not arbitrary pass/fail magic numbers:** seek a hero reference-size change **under ~10%** across each boundary (costume/swing pose may justify deviation), an anchor movement **under ~5% of usable world-view width/height**, and **no obvious single-frame zoom jump**. Report the actual measurements or explain visually justified exceptions. Preserve the genuine position/scale of enemies relative to the camera within each scene; do not manufacture combat using sprite overlays.

## 4. Speed sensation — better, but still pixel-art appropriate

Retain or refine V3's restrained radial/zoom-blur idea, synchronized to the **peak zoom velocity**, with a short duration near each cut (roughly **0.10–0.20 s** as a starting point). The effect should suggest quick physical movement, not look like a conventional transition effect.

- Restrict noticeable blur/streaking mainly to **environment and outer world-frame edges**. Keep the **hero, swords, bosses, summons, boss bar and inventory dock readable**; sharp pixel sprites during stable combat are essential.
- Small velocity-driven speed lines or zoom smear may help, but avoid excessive blur, ghosting, flashes, heavy shake, spinning or visual artifacts.
- The effect must **enhance the zoom**, not conceal an alignment failure; if it reduces readability or looks fake, weaken/remove it. Do not build a large new filter/framework for this.
- **Hard action cuts only** between seasons; normal fade is acceptable only to the existing branded end card.

## 5. Keep V3's improved HUD and content rules

- **Hide all player health meters**, both top and floating, **only in marketing captures**. Preserve actual combat/HP values.
- **Keep the authentic compact equipment/inventory dock visible** and stationary so the sword/outfit progression is readable. Never open an inventory panel or fabricate UI.
- **Keep real boss HP bars**, with truthful values. Minimize overhead name/skill-icon overlap if a simple capture-only display adjustment helps; do not over-scope this.
- Keep reduced floating damage-number density (about V3 level); enough authentic hit feedback, not a blizzard covering the hero.
- Keep genuine rain, enemy attack patterns, skills and **the logged real Grim Reaper summon**. No debug indicators or changes to live game UI, balances, saving or export configuration.

## 6. Efficient execution and evidence

1. Read only the relevant playbook sections: **87.2**, **133.1–133.3**, **133.7**, **135**, and V3's `marketing/match_cut*` source/manifest plus `docs/LootFarmer_Change_46_Report.md`. Follow the **pinned Marketing Capture Toolkit** contract; do not fork/rebuild it. The playbook predates these experiments, so its old sentence saying match cuts were unvalidated is **historical**, not an instruction to undo V1–V3. No Playbook editing in this batch.
2. Reuse V3 captures where their composition permits the improved move; recapture **only** if Winter framing, action alignment or usable zoom range requires it. Use isolated capture profiles and real game simulation calls. Never modify approved media, existing raw masters or unrelated gameplay.
3. Produce **one focused V4 candidate**, review its three boundaries **frame by frame**, and fix evident misses before completing; avoid variants, broad audits and token-heavy narration.
4. Provide a V3-vs-V4 **same-boundary comparison** for each cut: frames **before / at / after**, plus a short interval demonstrating acceleration/deceleration. Also make a **whole-video phone-size strip** and a compact first/middle/last-frame shot sheet. Static review frames cannot verify speed: inspect the **actual rendered MP4 at playback speed**, as well as frame by frame.
5. Include in the short report: source take IDs (new captures if any), time/frame of each cut, hero anchor and apparent-size comparisons, zoom values/**velocities** immediately before and after cuts, zoom curve/effect choices, actual summon timestamp/log, fixed vs remaining compromises, and the output validation result. Avoid claiming the match cuts feel cinematic solely because ffprobe passes.
6. Validate **1080×1920, ~15 s, 30 fps, H.264 yuv420p, one AAC music stream, no unintended black frames**, soundtrack continuity, the actual summon, weapons/outfits, dock presence, no player HP, no actor/weapon cropping or unacceptable pixellation, and no side-drift. Run the relevant existing marketing probes only. Verify the approved trailer and V1/V2/V3 remain unchanged.
7. Commit necessary **V4 source changes** using the next sequential **`Change N`** convention (after Change 46, **Change 47 if not already taken**); preserve existing user edits to `project.godot` / `export_presets.cfg` and any other unrelated uncommitted work. Keep generated video/raw/review assets under the established local `store_assets/` structure and reference their paths in the report.

## Acceptance decision

**Success:** At phone size, the audience clearly sees a **fast, continuous IN → OUT → IN camera rush** across three sword-swing match cuts; the Winter pack is easy to read; the hero does **not visibly jump in size or position** at Winter → Summer or the other cuts; the player and boss/enemy group remain together on screen; inventory stays stable; combat and authentic summon are visible; music is the same 8-bit track; the final Spring encounter lands as the strongest beat.

**Do not force success:** If the stronger movement breaks alignment, clips the fight or introduces blurry scaling, choose the best **cleaner/smaller** zoom that still improves V3 and **state the limitation**. The MP4 remains a **local review master** until developer approval and **REL-02** art/music rights documentation permit publication.
