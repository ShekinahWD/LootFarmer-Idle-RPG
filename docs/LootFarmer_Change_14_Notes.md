# LootFarmer — Change 14 Notes

Baseline: Change 13 (`5f64ba4`, tests/docs `f1c0f64`). Brief: docs/LootFarmer_Change_14_Instructions.md. None of the eight items was already resolved in the live tree, so all eight were implemented here.

Build commits: `508cefc` (implementation) and `3ea93cb` (the Focused Farming hint line moved above the Farm button after the rendered check). **Build from `3ea93cb` or later.** The tests/docs commit after it does not change the game.

## What changed

| # | Area | Change | Where |
|---|---|---|---|
| 1 | Next Stage chip | "Next Stage · Bosses n/m" (Spring II keeps "World clear · n/9") on a compact dark plate under the minimap. The plate is a new theme style, `HudChip`: the existing Kenney backing panel at (0.04, 0.06, 0.09, 0.86) with 10 / 3 px padding. Text is 19 px gold (1, 0.9, 0.56) with a 4 px black outline, at 10:1 contrast or more over snow, grass, sand and dirt. The count is unchanged: the run's kills of the specific required bosses (`campaign.gate_status`). It never takes touches, keeps its right edge on the minimap's and grows left for longer text (277 px for "Next Stage · Bosses 0/2" against the 230 px minimap). | `resources/game/theme.tres` (`hud_chip`, `HudChip`, `HudChipLabel`); `main.tscn Map/Gate` (PanelContainer → Row → Icon, Label); `game_ui._refresh_gate` |
| 2 | Map cluster | Top right, top to bottom: zoom slider (16–76), **Map Explored: n%** (84–118, `HudChipLabel`, 18 px white), minimap (124–354, was 90–320), Next Stage (360–398). The lower-right label is gone. The value is still `campaign.explored_percent`, from permanently explored cells only. Everything stays inside the `Safe` margin container, so insets move the cluster as one block. | `main.tscn Map/Explored`, `Map/MiniMap`; `en.po MAP_EXPLORED` |
| 3 | Missions badge | **Cause:** the panel listed the first three *unclaimed* main objectives whatever their state, while the badge lit for *any* entry in `main_ready`. A later objective could be ready (for example "Unlock Summer I") with no Claim button anywhere, so the `!` stayed on. **Fix:** one eligibility rule, `campaign.has_claimable()`, used by the badge. It is true for a complete, unclaimed daily mission that is not handled by purchased auto-claim, or for a ready objective that is listed (`main_shown()`). The panel lists exactly `main_shown()`: three cards, ready ones first. A lit badge therefore always has a Claim button behind it. The badge is recomputed from state every HUD tick, so claims, auto-claim, refresh, Prestige, load and Hard Reset update it immediately. Purchases never light it, which keeps Playbook §21's ready-versus-afford meanings apart. | `campaign.mission_claimable`, `main_claimable`, `main_shown`, `has_claimable`; `game_ui._refresh_badges`, `_missions_panel` |
| 4 | Rain splash | The rain sheet has falling frames 0–8 and splash frames 9–14. Before, the whole cell kept drifting at (8, 28) world px/s through the splash, so the splash slid about 17 px. Now `WeatherStyle.splash_frame` (9 for rain, −1 for leaves) freezes the particle at its position at the impact frame until the cycle ends, and the next cycle starts a new drop. Positions remain a pure function of the clock and the world grid, so camera pans and zoom never move an impact. Density, alpha, overcast and assets are unchanged. | `weather_style.gd`, `weather_rain.tres`, `season_weather.particles` |
| 5 | Skill effects | See the table below. **Cause of the low Lightning:** every target effect was centred on the target's feet, and the zap sheet's ground ring sits 21 px below its frame centre. Target effects were also drawn at z 0, under the actors (z 1), so the bolt struck below the target and partly behind it. **Fix:** an inspector resource, `resources/game/skill_effects.tres` (`SkillEffectSet` with one `SkillEffectStyle` per key), sets the anchor, the frame's contact row, the lift to the body, the scale (and whether it follows the actor's visual scale) and the layer for each skill. **Boss wind-up:** before, the wind-up played the full skill effect and sound at the aim, then played them again on the hit (two Lightning bolts per attack). Now the wind-up emits `sim.skill_warning`, which shows a small orange ground marker (the cast sheet, 0.6×, under the actors) with no sound. The skill effect and sound play once, on the hit. Single-target strikes (Lightning, Strike) play on the actor they actually hit; before, a boss's bolt played at its old aim while the damage landed on the player wherever they had moved. Damage, slow, heal, buff, ranges and cooldowns are unchanged. | `skill_effect_set.gd`, `skill_effect_style.gd`, `skill_effects.tres`; `world._spell`, `_warning`, `_effect`; `campaign.apply_skill` (`sim.cast_target`), `_begin_telegraph` |
| 6 | Enemy research | The Upgrades tab of a discovered enemy now ends with **Research: Reveal Stats, Reveal Drops**. These are the same `_group_upgrade_card` and `sim.buy_upgrade` as Overview, with the same price and state; once owned the card reads Max. Overview keeps its cards until a purchase, then shows the information. No new definition, currency or charge. The Farming Guide reads the same levels. | `game_ui._enemy_panel` |
| 7 | Joystick | Same anchors, offsets, 180 px touch box, radius 64 and input code. The pad gets a **Backplate** (the panel-014 texture, dark at alpha 0.34, inset 3 px). The ring goes from white 0.65 to (0.9, 0.94, 1, 0.8). The knob is (0.6, 0.67, 0.76, 0.92), with a dark 3 px **Rim** behind it. All are node modulates in `joystick.tscn`, editable in the inspector, and every layer ignores the mouse. | `scenes/game/joystick.tscn` |
| 8 | Focused Farming guidance | The profile's first Focused Farming purchase writes `"focus_unlocked"` to `tutorial.seen` and says **"Focused Farming unlocked"** on the panel's notice line, or as a toast if no panel is open. This happens in every onboarding mode. Except under "None", it also sets the session-only `campaign.focus_hint`. The guide then points at the next real tap: the **Farm** button in that enemy's panel (on either tab), with one line above it explaining Farm; else the HUD **Upgrades** button when it opens that enemy; else the minimap. The caption has Got it. Another panel suspends the hint, including another enemy's panel. It ends when Farm is turned on, on Got it, after 45 s on screen, or on another map. It never shows again: not after a reload, not on a second type's purchase, not after Prestige. On an undiscovered variant the guide says "Find this spot first" and does not point at the disabled button. Focus mechanics are unchanged. | `campaign.upgrade_bought`, `focus_hint`; `tutorial_guide._focus_hint`, `FOCUS_HINT_SECONDS`; `game_ui._enemy_panel` (`focus_toggle` tag), `_notice` |

### Skill effect placement (resources/game/skill_effects.tres)

| Skill | Anchor | Contact row (of 64) | Lift | Scale | Layer |
|---|---|---|---|---|---|
| Lightning (zap) | the actor hit, feet | 53 (the ground ring) | 0 | 0.75 × its visual scale | above actors (z 2) |
| Strike (impact) | the actor hit | 32 | 10 × visual scale (body centre) | 0.75 × visual scale | above actors |
| Fire (fire_impact) | the aim / area centre | 32 | 10 | 1.0 | above actors |
| Frost (ice_shatter) | caster's feet (fixed point) | 32 | 0 | 1.0 | beneath actors |
| Heal (heal) | child of the caster's view | 52 | 0 | 0.75 × visual scale | on the caster |
| Focus (cast) | child of the caster's view | 52 | 0 | 0.75 × visual scale | on the caster |
| Boss wind-up | the aim | 32 | 0 | 0.6, tinted (1, 0.5, 0.32, 0.8) | beneath actors |
| Summon (on summoner / where helpers appear) | caster / point | 52 / 32 | 0 | as in Change 13 | unchanged |

Heal, Focus and the summon effects keep their Change 7, 12 and 13 placement. The values moved from `world.gd` exports into the resource.

### What was verified, and how

| Claim | Static / headless (change_14_probe) | Rendered on desktop (change_14_capture) | Needs a phone |
|---|---|---|---|
| Lightning ring on the target's feet, bolt above its head, drawn over actors | Normal enemy and 2× boss, player and enemy casts | 05, 06, 07 | Look at zoom 1–3 |
| Strike and Fire on the body, above actors; Frost on the ground | Every skill on a normal enemy and the boss | 08, 09 | — |
| Heal and Focus on the caster, following it | Player and 2× robot | (Change 12/13 renders) | — |
| Real effect of each skill (damage, slow, heal, buff) | yes | — | Feel |
| Cooldowns = catalog values for player casts | yes | — | — |
| One effect per boss attack, a warning marker at wind-up | yes (warning count, cast count) | 10 | Whether the marker reads as "incoming" |

## Saves

No save-schema change (schema 7) and no migration. The only new saved value is the `"focus_unlocked"` string in `tutorial.seen`.

## Tests

- `tests/change_14_probe` (in the maintained suite): **202 checks, 0 failures**.
  - **Map cluster:** order, overlap, right-edge alignment, no-touch, style, font sizes, contrast on four grounds, 1/2 then hidden after the gate kills, Spring II wording, panning and zoom, new cells, a 60 / 40 px inset.
  - **Badge matrix:** fresh profile, a ready objective beyond the first three, claim, the unlisted final objective, daily missions, waiting slots, auto-claim on and off, Hard Reset.
  - **Rain:** 7,813 splash steps with 0 slides, 13,898 falling steps with 0 stalls, new drops after the splash, the impact point, pan and zoom, leaves unchanged.
  - **Skills:** player casts of four attacks on a normal enemy and a 2× boss; Heal and Focus; cooldowns; an enemy's Lightning; a boss wind-up and hit; boss Heal.
  - **Research:** both tabs, a single charge, Max, refusal, Farming Guide.
  - **Joystick:** placement, size, radius, no-touch layers, contrast arithmetic on four grounds, drag and release.
  - **Focused Farming:** all modes, every exit and suspension path, once per profile, an undiscovered spot, mechanics unchanged.
- `tests/change_14_capture` (desktop renders, `docs/Change_14_Evidence/ui/`):
  - 01–04: the cluster and joystick on Winter I, Summer II (rain), Autumn I and Spring I.
  - 05–10: Lightning on a Yellow Cap and on the 2× Gray Cat, the cat's Lightning on the player, Strike, Fire, and the wind-up marker.
  - 11: Research on the Upgrades tab.
  - 12–13: the Focused Farming hint in the panel and on the HUD.
  - 14: Missions with ready objectives listed first.
- **Maintained suite** (`python tools/run_probes.py`): one full run, **23 / 23**. Three stale contracts were updated first:
  - change_5: "spells render beneath actors" is now chosen per effect.
  - change_12: the lower-right explored label moved to the cluster, and the self-effect values come from the resource.
  - change_13: the gate label path, "Next Stage", and a wind-up counted from `skill_warning`.

  `validate_campaign_source`: 1,361 checks.
- No pacing bots, soak runs or balance campaigns: no combat values changed.

## Android-only checks (not tested on a phone)

- **Chips:** readability of "Map Explored" and "Next Stage" over snow, sand, fog and rain at arm's length. The Next Stage chip is 277 px wide on narrow phones, wider than the minimap, so check that it does not crowd the enemy name on the left.
- **Missions badge:** stays off after claiming everything; comes back for a new manual claim.
- **Rain:** splashes stay put at zooms 1, 2 and 3; no flicker at the cycle wrap.
- **Skills:** Lightning reads as hitting the target (normal and boss); the wind-up marker reads as a warning and not as a hit; effects above actors do not hide HP bars for too long.
- **Joystick:** findable on Winter snow and in Summer II / Spring II rain, without dominating the view.
- **Focused Farming:** the arrow and the line are understood after the first purchase; the arrow from below may cover part of the first Rewards card while it shows.
