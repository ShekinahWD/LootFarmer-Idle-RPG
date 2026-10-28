# The Road Ahead — shared onboarding goal announcement

- One centered, dimmed, Prestige-style announcement now covers **Guided, Basic, and None**.
- Title: **THE ROAD AHEAD**. Existing body about the Stage 8 final boss, optional 100% Map Mastery milestones, and player pacing is unchanged.
- **Guided:** shown at the existing final step after entering Winter II. Its original five-second confirmation and saved Guided completion gate are unchanged.
- **Basic:** shown once after the last short feature card (`feature_prestige`) has been acknowledged or automatically retired. Basic cards still retire automatically; this final announcement **does not** auto-dismiss.
- **None:** shown once immediately after mode selection, without pointers or other instructional UI. The game-goal announcement is not a tutorial progression gate.
- For Basic/None, the same five-second visible confirmation gate is saved in `tutorial.road_ahead_seconds`. Confirming appends `road_ahead` to the existing `tutorial.seen` array. It survives save/reload/Prestige and resets with Hard Reset; previously played profiles receive it once unless it was already seen.
- Existing pauses, modals, open panels and banners suspend the announcement rather than completing it.
- Verify in Godot on Android portrait/narrow layouts: show timing and centering for all three modes, no auto-dismiss for Basic, interruption by panels, and persistence after save/relaunch.
