# LootFarmer — Change 88: Living Endgame Celebration and Green Alien HP Reset

## Objective and authority

Implement **only** the two focused corrections below, based on the current repository (after Change 87, `3d5d36f`). Read and follow the current repository's Reusable Game Development Playbook and inspect the existing Change 82–87 encounter, music, victory, save, and UI logic before editing. This is an implementation request, not an evaluation-only request. Make necessary technical decisions without asking for another approval.

**No balance changes:** Do not alter the Green Alien's maximum HP, attack, Rage thresholds/bonuses, healing values, attack intervals, boss rewards, Prestige rules, other enemies, or progression. Do not rerun lengthy combat ladders or player-profile simulations.

## 1. Living first-victory celebration and ending message

The current ending message freezes the hero in a combat frame, blurs/obscures the outfits, and interrupts the celebration. Replace this presentation while preserving the existing 10-second first-victory sequence, one-time ending-message rules, and subsequent nonblocking dance floor.

- **At Green Alien's defeat:** Open the arena and immediately transition from boss/Rage music to the **normal main game music**. Do not stop or pause main music when the ending message appears. Keep any explicitly accepted temporary recommended-volume mix through the full initial **10-second forced celebration**, then restore the player's previous audio settings at the agreed boundary. Honor manual user audio changes and mute settings.
- **Dance animation:** All owned outfit characters continue animating; the **player character joins the dance**, using a suitable idle/celebration animation rather than remaining frozen mid-slash. Fireworks, confetti, lights, and other celebration FX continue while the ending panel is visible. Do not globally pause the scene tree or any visual/audio processes needed for the celebration.
- **Ending panel:** After the initial 10 seconds, show the existing one-time congratulations message with **Continue Playing**, **Leave an Honest Review**, and **Join Our Discord**. Position it primarily over the **inventory/lower HUD**; it may occupy extra lower gameplay space as needed, but **do not blur or darken the background or cover the dance floor**. Keep it readable and tappable on Android portrait devices. External links should not inadvertently dismiss/acknowledge the ending.
- **Camera:** Smoothly frame the player and the dance floor with an appropriate centered composition and zoom, accounting for up to 48 outfits and the lower panel. Preserve and restore the user's prior camera/zoom state on Continue Playing. Do not fight manual camera controls after the ending has closed.
- **Gameplay versus spectacle:** Suspend ordinary player controls/combat, enemy AI, and encounter progression while the one-time ending panel requires acknowledgment, **without freezing character dancing, ongoing effects, music, or panel interactions**.
- **Boss countdown:** Stop and **hide** the Green Alien respawn countdown during the initial forced celebration **and while the ending panel remains open**. On Continue Playing, resume from the **remaining time** (no hidden countdown elapsed and no premature respawn), return control to the player, and let the existing outfit dance floor remain until the boss eventually respawns.
- **Persistence/interruptions:** Do not permanently lock the camera, freeze the game, or lose the ending if the app pauses, backgrounds, saves, or reloads. The once-only message counts as acknowledged only when the player actually completes the acknowledgment path; if not acknowledged, show it on the next Green Alien victory. After acknowledgment, subsequent victories continue to use the existing nonblocking dance floor, without replaying the forced cinematic or ending panel.

## 2. Green Alien starts every fresh encounter at full HP

Investigate the observed behavior: Green Alien sometimes appears to begin a fight near **80% HP**. Earlier inspection suggested that after killing the player it may retain its remaining HP and regenerate gradually, and that older saved absolute HP values can mismatch a newer maximum HP. Verify the **current** code before choosing the fix; also check premature damage and HP-bar initialization.

- On initial spawn, boss respawn after defeat, and any **fresh** engagement after the player's death, ensure Green Alien is at **100% of its current maximum HP** *before* the fight begins, and that the displayed HP corresponds to its true HP.
- After player death, reset encounter-specific state consistently with the existing approved Rage reset; the next fight must not retain damage from the previous attempt. Do not rely on waiting for out-of-combat regeneration.
- After the key ceremony and arena closure, HP must still be full until a valid combat hit occurs; don't permit damage during a frozen/locked pre-fight sequence.
- For existing saves, safely handle an idle Green Alien whose stored **absolute** HP came from an older maximum-HP configuration. Distinguish this from a **legitimate active-fight save**: preserving real mid-fight damage on a reload is correct. Do not apply a blanket heal every time a save is loaded or an enemy is inspected.
- Inspect the HP-bar's show/hide and maximum-HP update logic so a stale bar cannot falsely display 80%.
- Preserve all other encounter rules, the boss's current balance, and save compatibility.

## Focused validation only

- Demonstrate the current-vs-fixed Green Alien HP percentage at: fresh spawn, immediately after the player dies and boss resets, next approach, after ceremony/arena startup, and save/load (idle old save versus active combat save). Confirm no unintended early hit or stale HP bar.
- Inspect **normal-speed playback** and screenshots at 432×960 and 540×960: player dancing, outfits animated, VFX still running, main music uninterrupted, no blur, lower ending panel, camera framing, and countdown hidden/paused.
- Check Continue Playing restoration (camera, controls, countdown, player animation), unacknowledged ending retry, later nonblocking victories, and pause/reload safety.
- Run small relevant focused probes and existing nearby tests; no gameplay rebalance, long simulations, or full player-profile batch required.

## Completion requirements

Preserve the user's **uncommitted `project.godot` and `export_presets.cfg` version edits**; inspect actual working state rather than assuming a version number. Commit only the intentional source/config/test changes locally **without pushing, exporting, or publishing**. Report the root cause(s) of the HP issue, implementation details, visual validation evidence, focused test results, any remaining phone checks, and commit hash.
