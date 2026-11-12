# LootFarmer — Change 67: Merge & Evolution Celebrations + Independent VFX Review

**Status:** Approved implementation instructions — 11 November 2026  
**Baseline:** Current live local project following **Change 66, commit `d0b5e2b`**. Do not implement against the old ZIP or assume an older GDD snapshot describes the latest behavior.  
**Authoritative references:** `docs/Reusable_Game_Development_Playbook.md` (especially visual-feedback/action ownership, verified asset inspection, mobile responsiveness, Android performance and commit-after-batch workflow), current game-specific GDD, asset registry, existing audio/VFX configuration, and the actual game code. Do **not** modify the shared Playbook.

## Objective and creative authority

Make **manual equipment merging** feel satisfyingly rewarding and **manual weapon evolution** feel like an exceptional progression achievement. After implementing, validating and **committing** these two mandatory features, independently audit the game's visual feedback and apply **only** additional VFX improvements that genuinely improve quality.

You have broad artistic discretion. Inspect and select from the **entire available Cartoon Coffee VFX pack**, not just the specifically mentioned effects, alongside the project's existing art/VFX and sound resources. Choose combinations, timing, layering, particles, lighting, presentation and technical implementation based on actual previews. You do **not** need approval for individual artistic decisions within this brief. **Do not create an evolution replay feature.**

The developer's asset examples (`Fireworks_V1/V2`, `Aura_V14/V15`, `Aura_V41`) are **leads to inspect, not a required list**, nor a restriction. Do not use assets purely because their names sound appropriate.

**Two mandatory sequential phases, with a local Git commit at the end of Phase 1 before Phase 2 begins.**

---

## Phase 1 — Mandatory: equipment Merge and weapon Evolution

### A. Inventory Merge — frequent, satisfying, quick

- When the player **manually merges eligible copies** of a real item, visually communicate **copies converging into a stronger result**. Present a distinct successful merge moment and clearly show the actual resulting item and improved merge level.
- Keep the visual treatment **short, readable and satisfying**. Do not add an unnecessary full-screen interruption to an action the player may perform repeatedly. You choose the choreography and VFX after reviewing real assets.
- Distinguish actual manual success from failed/no-op attempts. Never play an earned-result celebration when no merge occurred.
- Respect the game's *actual* merge semantics: copies of the same item identity, inventory state, level/cap and the existing `Merge All` mechanic. Do not imply that arbitrary items can be merged, add new gameplay requirements, alter merge levels, or modify which equipment can merge.
- Existing **Auto-Merge** and **Merge All** can run rapidly or across many items. Their feedback must stay nonintrusive and bounded; avoid one blocking cinematic or a high-cost effect instance per individual result. Choose an appropriate concise/aggregated presentation consistent with their real outcomes.

### B. Weapon Evolution — high-impact, memorable presentation

- Introduce a **dedicated evolution presentation panel** for a **successful manual weapon evolution**. It should be visibly more impressive than ordinary merging while matching LootFarmer's UI and pixel-art style.
- The presentation must visibly tell the *before → after* story: **the actual source weapon**, its original state/tier, a rising sense of energy and transformation (including meaningful movement/vibration), a clear transition, and an unmistakable reveal of the **actual evolved weapon** and its new identity/tier. Include the correct item visuals and an accurate result rather than placeholder equipment.
- Use layered **VFX, light/particles, impactful motion, restrained screen shake and appropriate existing audio** as your artistic judgment supports. The evolution moment should feel exceptional, not simply like a bigger merge popup. Do not obscure the final weapon or its readable result with persistent particles.
- You choose exact duration, pacing, effects, scale, transitions, panel composition, text and audio mix. Keep it perceptible and exciting on a **portrait Android screen**. Keep important controls inside the safe area; do not shrink text until illegible.
- Let the player **skip/finish the presentation safely** without losing or duplicating the evolution result. Skipping should leave a clear final result state; don't make players wait through every flourish to continue. A separate replay/archive/watch-again feature is explicitly **out of scope**.
- For **Auto-Evolution**, give appropriate confirmation **without a recurring blocking panel** or gameplay-stopping cinematic. Keep automated farming fluent even at increased game speed.
- Only **weapons** evolve under the current approved game rules. Do not accidentally add outfit/skill evolution or change tier mapping, evolution costs, copy requirements, caps, inventory capacity checks or underlying probabilities.

### C. Correct state ownership, persistence and interruption behavior

- **The simulation/inventory transaction is authoritative.** An animation must present a successful result; it must not perform the merge/evolution a second time from a frame callback, nor become the only place where an award is committed.
- A successful result must remain safe across dismissal, skip, game pause, app backgrounding, save/load, leaving a panel, and any interrupted/cleaned-up animation. Prevent duplicate transactions, stale callbacks, stuck modal states and accidental item loss. If the game applies the transaction first, the displayed before/after snapshot must be captured reliably before source inventory changes are no longer queryable.
- Use existing event/state/action ownership and audio-cue routing rather than introducing a parallel inventory, save, sound or reward system. Respect gameplay/special mute settings, priority and volume, and avoid double-playing existing confirmation cues.
- Maintain responsive touch input, scrollability and normal game speed. Decide intentionally whether/how the **manual evolution panel** pauses gameplay to protect the player while viewing it, with clean resume behavior. Don't make auto actions pause gameplay.

### D. Real asset review and Godot adaptation

- **Before choosing effects**, inspect actual Cartoon Coffee source assets available in the *live* project: images, sprite sheets, prefab configurations, materials, shaders, metadata and relevant supporting definitions. Preview animation frames, alpha, sizes, scaling, colors and layering; don't judge solely from names or screenshots of the pack.
- Recreate/adapt chosen visuals using suitable **Godot-native** particles, sprites, tweens or shaders. Do not assume Unity prefabs/materials/shaders can run in Godot without adaptation. Retain visual cohesion with existing equipment and interface sources.
- Use **existing supplied assets** rather than generating substitute art. Preserve all Unity source/reference files that could be useful for current or future VFX recreation. Do **not** perform additional Cartoon Coffee cleanup or delete supporting reference files.
- The Cartoon Coffee pack may currently be **untracked and large**. Do not indiscriminately stage or ship the whole source collection: determine the minimal runtime dependencies, retain necessary source/reference material and license/provenance information, and avoid breaking Godot's explicit export allowlist / dynamic resource loading. If a required source cannot be included or its licensing cannot be verified, report the precise issue; do not silently swap in unrelated artwork or claim release clearance.
- Keep emission counts, overdraw, large transparent effects, active effect lifetime and concurrent instances appropriate for Android. Pool/reuse where appropriate; test ordinary speed and accelerated/automatic farming. VFX must not leak hidden map information or block unrelated touch targets.

### Phase 1 validation and **FIRST COMMIT**

Perform **focused**, practical validation only; do not run lengthy balance simulations or the full regression suite just for this visual change.

1. Verify real **manual merge** before/after level and inventory count are unchanged from gameplay rules; success has visible feedback; failed/no-op operations do not celebrate.
2. Verify a legitimate **manual weapon evolution** shows the *actual* source and evolved items, tier/identity/result; both normal completion and skip leave correct inventory and state.
3. Verify **Auto-Merge, Merge All, Auto-Evolution**, no duplicate rewards, save/load and interrupted-animation safety, without excessive repeated effects or modal interruption.
4. Verify pauses, sound/mute behavior, UI touch and no persistent effects after closing/leaving the scene.
5. Capture **actual rendered frames/short motion evidence** covering beginning → transformation → result (a static screenshot alone cannot prove animation quality). Review at **432×960 and 540×960**, including relevant safe-area constraints. Note that desktop/windowed captures do **not** certify physical Android performance.
6. Run relevant existing inventory/evolution, audio, localization/UI and regression probes impacted by the change; create a small focused probe only if necessary. Report pre-existing unrelated failures separately.

**Once Phase 1 is implemented and the focused checks pass, immediately create a local commit**, staging only Phase 1's intentional files:

`feat(change-67): celebrate equipment merges and weapon evolution`

Report the commit hash **before** starting Phase 2; do not defer or combine these changes into one commit.

---

## Phase 2 — Independent audit, autonomous selective VFX polish

**Begin only after the Phase 1 commit exists.**

1. Inspect the **entire game's existing visual feedback and animation systems in the current live build**, including the interaction of effects with gameplay, navigation, UI, performance and audio.
2. Revisit the full available **Cartoon Coffee** and existing in-project VFX/resource inventory. Judge compatibility, visual fit, feasibility in Godot and cost on portrait Android.
3. **Decide independently** what additional improvements are worthwhile. **The developer is deliberately not giving a list of targets or suggested VFX applications.** Do not treat earlier conversational examples as a required backlog or mandate to add an effect everywhere.
4. Implement **only** the changes you conclude provide a demonstrable improvement, with suitable creative restraint. If existing feedback is already appropriate, **leave it unchanged**. Avoid generic particles plastered over every event, gameplay or balance changes, excessive screen shake, clutter, or features not needed for visual polish.
5. Respect exactly the same state ownership, source-asset, save safety, localization, performance and compatibility boundaries as Phase 1.
6. Validate actual visual results with a small representative capture set and focused probes. Compare what existed before versus after where possible. **Do not infer phone FPS from desktop/headless tests.**

**If Phase 2 implements improvements**, create a **second, separate local commit** (use a meaningful scope-based message such as `polish(change-67): refine selected game visual effects`). If you judge no additional changes justified, **do not create an empty commit**—explain why.

Do not ask for further approval before making reasonable within-scope Phase 2 creative decisions. Do not push, publish, or export a release.

---

## Scope guardrails and completion report

- Preserve gameplay math, combat damage/timing, upgrades, inventories, drop rates, missions, Prestige, Map Mastery, tutorial progression, Focused Farming, save compatibility and all previous Changes 1–66.
- Preserve developer-owned uncommitted changes (`project.godot`, `export_presets.cfg`, shared Playbook, `add_speed_blur.py` if still present) and unrelated untracked assets. Inspect current `git status` first; **stage deliberately**. Do not alter Android version codes or export settings merely to make an unrelated check green.
- Keep English-only string additions minimal and place them in the existing localization system; record changed/new keys in `tools/localization_pending.json`, without modifying the **19 non-English catalogs**. Reuse existing strings when accurate.
- Update the **game-specific** GDD, asset registry or maintained test documentation only where current implementation facts need to be recorded. **Never change the shared Reusable Playbook.**
- Document the **exact effect source assets and Godot treatment** selected; note licensing/source packaging risk without assuming commercial clearance. Only stage required runtime effects and their legitimate source records, not an indiscriminate 381 MB pack.
- Provide a report **for each phase**: what was changed, which source assets were chosen and why, focused tests, visual evidence paths, Android checks still open, modified files, translation keys if any, and local commit hash.
- For Phase 2, also report **what you evaluated but deliberately chose not to change**, with reasoning. You may group this by general findings; the user did not request a pre-supplied candidate list.
- **No evolution replay feature. No push. No release export. No publication.**
