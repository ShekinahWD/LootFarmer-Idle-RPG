# LootFarmer — Change 83: Green Alien Finale, Rage, Audio, Arena Warning, Outfit Celebration & Full Completion

**Status:** Approved for implementation in one batch.  
**Base:** Current working repository after Change 82 (`45e5efa`) and any later local work; inspect the actual code before modifying it.  
**Purpose:** Complete the Green Alien finale: its approved difficulty increase and Rage Mode, mandatory first-time no-escape warning and replayed key ceremony for existing players, opt-in recommended sound settings, distinct normal/enraged music and SFX, a red enraged **arena barrier**, persistent 13-key guidance, a memorable victory celebration with a repeatable outfit floor, and accurate long-term completion.

## Working rules and limits

1. Read the repository's **Reusable Game Development Playbook**, canonical `docs/LootFarmer_GDD.md`, and the actual Change 81–82 implementation (final-boss key quest, one-time unlock ceremony, sealed arena, key-pickup animation, HUD tracker, boss respawn, save rules). Reuse existing VFX, audio, panels, sprites, achievement/mission machinery and save conventions.
2. **Implement** all approved work below; make sensible internal choices without returning a proposal for approval. Keep the latest player work untouched. The developer's `project.godot` and `export_presets.cfg` **version-43 edits are uncommitted**; do not overwrite or stage those edits. Do not push, build, export, upload, publish, or change version numbers.
3. The developer personally evaluates balance. **No boss rebalance or combat ladders.** Apart from the **explicitly approved Green Alien changes** (HP ×2, attack ×2, Heal, and threshold-triggered Rage Mode: attack speed +50%, defense +30%, healing effectiveness +20% and one immediate Heal), do not change any other combat balance, other bosses, player stats, Prestige effects, loot or XP. No player-profile runs or long simulations. Focus on behavior, functionality and presentation.
4. Add only necessary English localization keys with working fallback for all other languages. Record pending localization for the planned audit; preserve existing official terminology, save compatibility, Prestige and Hard Reset rules. Never alter the user’s audio preferences without an explicit tap.
5. Update the canonical GDD where gameplay rules change, targeted tests, and evidence under the Playbook's `generated/` location. Keep required dynamic scripts/assets in the export allowlist. Commit only intended files locally after focused validation. Inspect the actual supplied audio filenames, license/provenance, and reusable audio/VFX systems before adding files.

## 1. Green Alien — exact requested difficulty changes

- **Double its current maximum HP and base attack damage**, inspecting the **current** source of truth. From the reported Change 81 values this is approximately **91,354 → 182,708 HP** and **622.8 → 1,245.6 damage per hit**. If the checked-in source differs, double actual current values and report before/after. Preserve attack interval, AI attack ordering, arena, key requirement, previously implemented ceremony state (except the new replay exception in §1B) and all other values.
- Add an appropriate **Heal** skill using the game's existing enemy/boss skill system and matching healing VFX. It should trigger only under sensible injured-HP conditions and obey the established cooldown behavior. Choose parameters consistent with an existing Heal skill; **do not use this change to tune overall difficulty**. Report the selected heal amount/condition/cooldown.
- Damage-based skills already scale from base attack: ensure doubling the base value affects them **once**, without layering an accidental extra ×2 skill multiplier.
- No further buff, nerf, helper rebalance or progression-gate change beyond §1A Rage Mode. The final boss is intended to reward substantial Prestige progression; do not try to make it beatable without Prestige.

## 1A. Green Alien Rage Mode — 20% HP threshold (approved addition)

**Trigger:** the first time the current Green Alien reaches **20% or lower HP while alive**, after receiving damage. A lethal blow must not interrupt the victory flow with a rage cutscene. Do not trigger repeatedly on every hit/tick.

| Property | Normal | While enraged |
|---|---|---|
| Attack speed | Existing base rate | **+50% attack speed** (1.50× attacks per second; calculate intervals correctly) |
| Defense / damage mitigation | Existing boss behavior | **+30% effectiveness** using the game's actual defense mechanic; don't invent an unrelated defense system |
| Healing | Existing Heal from §1 | **+20% healing effectiveness** on that Heal's existing amount, exactly once per heal |
| Threshold action | — | **Immediately perform one Heal**, with the game's existing healing visuals and safe cooldown semantics |
| Duration | — | **Latched until Green Alien is defeated**, including when healed back above 20%; do not make the rage threshold oscillate |

- The immediate Heal is a **one-time rage activation action**, not an extra periodic heal or an unlimited cooldown reset. Subsequent Heals use the existing normal cooldown/conditions with the +20% effectiveness.
- Rage should stay visibly and mechanically active until **this boss is defeated**, not revert because the player dies, the arena temporarily opens, or the boss heals. Reconcile persistence with the current boss-reset/respawn design, and explain what survives save/load. After the boss is defeated and the *next* Green Alien spawns, that new boss begins in the normal state.
- Reuse suitable existing combat VFX for an unmistakable red/orange aura, burst/shockwave, and sustained particles, avoiding heavy mobile rendering or hiding HP bars.
- Trigger the provided **`Enraged - Long 01.wav`** once on rage entry; coordinate it with the VFX and musical switch (§1C).
- Show a **prominent but non-blocking** warning for roughly 5 seconds, such as: **“GREEN ALIEN IS ENRAGED! Attack speed +50% · Defense +30% · Healing +20%”**. Do not pause gameplay or cover critical controls. Continue showing the visual rage state after the toast disappears.
- **The circular energy barrier that seals the final-boss arena must turn RED during Rage Mode.** This refers specifically to the **physical, hexagon-cell arena wall/ring**, **not** merely the boss's targeting circle, selection marker or floor decal. Change the *whole barrier treatment* (ring, hex cells, shafts and wall-contact flare) from its normal blue/green presentation to clearly readable red/crimson, without altering its radius, collision, arena restrictions or hit feedback. Keep it red for as long as the boss is enraged; cleanly reset it for the next boss. Validate at portrait size and on bright backgrounds.

## 1B. First-time final-boss danger confirmation and ceremony replay (approved addition)

**Before any eligible final-boss fight,** show a high-visibility, **blocking confirmation** once per player profile, including on existing saves that already unlocked or defeated Green Alien **before this update**. Trigger on the first valid attempt to enter the encounter (approach with all 13 keys, tap/eligible Auto Farm), *before* initiating key visuals, arena closure, combat or encounter music.

Suggested English panel text (polish for Android layout):

> **FINAL BOSS — DANGER**  
> Are you sure you want to fight the Green Alien?  
> **There is no escape once the arena seals: you must win or fall.**  
> For the full final-boss experience, we suggest recommended audio settings.
>
> **[Set Recommended Volume]**  
> **[Yes, Fight!]**    **[No, Not Yet]**

- **Set Recommended Volume** explicitly applies **Music 40%, Sound Effects 100%** using the existing settings/audio service; it should not implicitly accept or dismiss the warning. Apply only when the user taps, respecting the game's own persistable audio setting conventions. No silent unmuting/change on approach or loading.
- **No** closes the prompt safely, cancels this encounter, and leaves the arena open and the boss disengaged. The warning is shown again on a *later attempt*, not immediately every physics tick while the player stays in the trigger radius; allow the player to leave safely or reattempt explicitly.
- **Yes** acknowledges the warning durably; it must not appear again on later attempts, after a defeat, after a victory, after Prestige or on reload. Hard Reset clears acknowledgment. An interrupted/unanswered warning must not count as accepted.
- **Critical retrofit:** when the player **first accepts this new warning**, play the full **13-key orbit/unlock ceremony again even if Change 82 marked the original ceremony as already played** or the player has defeated Green Alien in the past. **Every qualifying existing player should experience the new warning → key ceremony → boss battle sequence once.** Do not remove/re-spend keys, reopen the sealed quest, revoke boss unlock or grant rewards again. Replay here is a **presentation** event, not new progress.
- For a newcomer who has never seen the original ceremony, use the normal full ceremony. After **this updated full experience is completed**, later fights **skip both the warning and the ceremony** and go directly to combat. If the player accepts but the ceremony is interrupted before completion, resume/replay it on their next eligible attempt. Use an explicit, durable new presentation-completion flag as needed; do **not** mistake the old `ceremony_completed` or `boss_defeated` state for having seen this new experience.
- Run the ~5.6-second ceremony with its existing camera, visual effects and safety rules, then engage the boss and close the arena as Change 82 already does. Do not trigger a fake unlock or second sound burst for every normal subsequent engagement.
- A previously defeated boss can respawn and be challenged normally; do not suppress the one-time **new** confirmation/ceremony merely because a legacy completion bit exists.
- Respect pause, modal ownership, save/load and interruption recovery. No lost input, repeat confirmation loop, stuck barrier, or camera takeover after a canceled encounter.

## 1C. Recommended audio prompt, Green Alien soundtrack and voice/SFX (approved addition)

- Whenever the player reaches/approaches Green Alien, keep a **small, non-blocking, readable “Recommended Audio — Tap to Apply”** control available near the existing encounter/HUD UI. It must not cover the boss, map, missions, joystick, health or attack controls. Tapping it sets **Music 40%** and **Sound Effects 100%**; the player retains control over settings at all times. The same action is available in the first-time danger panel.
- Use the **actual audio files** already supplied in the game's asset directories (discover/verify exact paths; do not assume the screenshot shows full paths):

  | Event | Approved file / behavior |
  |---|---|
  | Normal Green Alien battle | **`EndGame - Music 1 (1).ogg`** |
  | Rage Mode battle (§1A) | **`EndGame - Music 1 (2).ogg`**, smoothly transitioned from the normal battle track |
  | Rage entry | **`Enraged - Long 01.wav`**, once per rage activation |
  | Occasional boss laughter | Choose randomly from **`Laugh 01.wav`**, **`Laugh 03.wav`**, **`Laugh 05.wav`**, with sensible cooldowns and no overlapping spam |

- Start special battle music when **combat actually begins** following the warning/ceremony (not during a canceled warning); switch to the second track on rage entry. Retain the expected state if the game is paused/resumed; on boss defeat, player death, map change or valid encounter teardown, release the boss audio and **restore the previous game/celebration audio state** rather than leaving the rage song stuck.
- Random laughter should be occasional during an active encounter, based on real game RNG/audio conventions; do not play it while sealed, on the warning panel, during canceled approaches, or during victory.
- Reuse the audio manager: honor music/SFX mute settings and user volume changes, avoid duplicate AudioStreamPlayers/leaks, support mobile pause/resume. Reuse/import assets with proper export inclusion and verify license/provenance under the Playbook.
- The old Change 83 **“suggest music at least 50%”** language is superseded: the sole approved recommended mix is **Music 40% / Sound Effects 100%**, always **opt-in**.

## 2. Boss-key quest — an understandable mission on every map

After the Green Alien is discovered and the 13-key requirement is revealed, players must know **which keys are missing and where to obtain them**, even while visiting another stage.

- Preserve the existing globally visible Boss Keys tracker, discovery gate, 13 **distinct** keys, and how kills award keys; do not change key acquisition.
- Integrate the hunt into the existing **Missions / Main Objectives** experience as a persistent quest, available on **every map**, showing **X/13** and the remaining keys. Use actual boss names and their stage locations from the game catalog, grouped or ordered by stage. Mark already collected keys clearly (e.g. check/key icon), distinguish missing keys, and provide the practical action **“Defeat [Boss] — [Stage]”**.
- Let players inspect this list using the existing Boss Keys HUD chip and/or Missions navigation. Where a compatible followed-objective/pin mechanism already exists, offer it without interfering with the user's separately followed missions, Mastery, Prestige objectives or current-map indicators. Do not fabricate map pins for bosses in maps the player has not reached this run.
- Never show or spoil the key quest before Green Alien discovery. At **13/13**, clearly change it to **Return to Green Alien — Spring II** / ready-to-challenge, then complete or archive the quest when Green Alien is defeated. Support discovery/key ownership through Prestige and save/load.
- Ensure long names and translated strings wrap instead of truncating actions or stage names on 432×960 and 540×960 portraits.

## 3. Green Alien map marker — unmistakably the final boss

- The **star/marker representing Green Alien's position** should be approximately **40% larger** than ordinary boss markers, with a distinct final-boss silhouette/treatment (e.g. prominent border, crown or glow) that remains legible without visual noise.
- Apply the same **final-boss identity** wherever the boss is represented on the World map, minimap/map details, map legend, unlock/encounter representations or relevant boss-navigation UI. Inspect actual surfaces; avoid introducing a duplicate unrelated marker.
- The marker must stay tappable with a suitable hit target and should remain clear whether Green Alien is sealed, unlock-ready or already unsealed. Do not disclose the quest before its existing discovery gate merely through a new label.
- Keep icons for other bosses at their current sizes. Verify positioning/clipping and icon density on portrait screens.

## 4. First Green Alien victory — a grand 10-second celebration

**Trigger:** Green Alien is defeated for the first time on that profile. Keep the Change 82 arena-opening and normal reward resolution correct. This is a **main adventure victory**, **not** 100% completion or an automatic Prestige/Hard Reset.

### Visual sequence

1. After victory and arena release, establish a **celebration/dance floor in Green Alien's area**, positioned on safe terrain within the last-boss clearing. It must read as a festival scene **beneath/around the defeated final boss's location** without covering the player or blocking controls.
2. Spawn visible, animated representations of **every unique outfit the player currently owns**, one by one, over **no more than 5 seconds total**, then let all of them idle/dance continuously. Use existing outfit sprites/idle animations and reuse rendering systems/atlases where possible; copies of the same outfit do **not** inflate the count. Inspect the actual inventory/ownership rules so the display genuinely represents **owned** outfits (and only legitimate obtainable outfits count toward the total).
3. Add striking but mobile-friendly **confetti, colorful light effects and repeated fireworks** throughout the celebration. Fit within existing game art direction; reuse available sound/VFX and avoid excessive particles/draw calls on Android. Effects must not make the hero, outfit silhouettes or HUD unreadable.
4. Show a small persistent in-world/in-area line, e.g. **“Collect every outfit to complete this celebration floor!”** and an accurate **“Outfits dancing: X / Y”** counter. Put this **below the floor**, not above combat controls, and update it when owned outfit types change.
5. Let the introductory celebration play for **10 seconds total**, counting the first 5-second spawn sequence within that period. Only **after** those 10 seconds present the one-time endgame message defined below. Keep the celebration coherent with the game's existing boss respawn (normally ~10 seconds): **do not allow the boss to respawn and remove the first celebration before its 10 seconds/message have been delivered**. Coordinate respawn timing safely, and resume the normal loop after the cinematic/panel is resolved.
6. Respect pause, save/reload, deaths, app interruption and screen transitions: no soft-lock, duplicate rewards or permanently stuck camera/effect. Follow existing modal/pause ownership rules, and restore the user's camera/zoom afterwards.

### Music consent

- The suggested settings for the final-boss experience are **Music 40% / Sound Effects 100%**, available from the first-time confirmation and small opt-in near-boss prompt (§1B–1C). **Do not silently alter either volume, unmute audio or nag users repeatedly.** The endgame celebration should honor the resulting user choices; do not add a conflicting 50% music suggestion.

## 5. One-time ending message — with review and Discord

After the first full 10-second celebration, show a clear, polished end-of-main-adventure panel using the game's normal panel system. Suggested copy (refine for natural localization and fit):

**“CONGRATULATIONS! You defeated the Green Alien and completed LootFarmer's main adventure. Your journey continues: collect every outfit, master every map, earn every Prestige card and finish your upgrades!”**

Provide accessible, working controls:

- **Continue Playing** — close the panel and return control to normal gameplay, **without any automatic reset**.
- **Leave an Honest Review** — open the official LootFarmer Google Play listing using the game's configured URL/OS link flow; do not imply that a positive rating is expected or required.
- **Join Our Discord** — open the official studio Discord invite using the existing external-link method.

Previously supplied official links, to verify against current project configuration before use:
- Google Play: `https://play.google.com/store/apps/details?id=com.shekinahwelefuldesigns.lootfarmeridlerpg`
- Discord: `https://discord.gg/JKjeP6PDAU`

### Durable one-time state

- Distinguish **boss defeated**, **first victory celebration occurred**, **ending message actually shown/acknowledged**, and **full 100% completion**; they are not interchangeable.
- Show the ending panel **once per profile**, and persist its acknowledgment across save/load, subsequent victories and Prestige; clear it on Hard Reset.
- If a defeat occurs but the message is **not actually shown/acknowledged** (e.g. interruption, app closed, transition), do **not** mark it as delivered. On the **next Green Alien victory**, present the missing message after a suitable celebration window. Do not require replaying the full cinematic each time or present the message spuriously on unrelated maps.
- Once acknowledged, **never repeat the endgame panel**, even if Green Alien is defeated again. Closing/declining review/Discord must not block the player. Ensure external app/browser returns and panel lifecycle work without double acknowledgments.
- Existing saves that already defeated Green Alien but have never seen the new panel should be eligible for the endgame panel on their next victory. Do not assume previous boss defeat implies the new message was seen.

## 6. All later Green Alien victories — dance floor without stopping gameplay

- Every subsequent victory should create/show the **same outfit dance floor** and **X/Y counter**, using current owned outfits. It stays visible in the Green Alien area **until the boss respawns**; then despawns/cleans up cleanly. It should appear again with refreshed ownership when the boss is defeated again.
- Once the one-time ending message is acknowledged, subsequent dance-floor celebrations must be **entirely non-blocking**: **no forced 10-second cutscene, camera takeover, gameplay freeze, modal or repeat endgame message**. The character can move, fight, collect loot and use controls normally.
- If the ending message was never acknowledged, a subsequent victory must still deliver it as in §5; that exceptional deferred message may be modal. Ordinary later victories remain non-blocking.
- Prevent effects accumulating across boss respawns, deaths, Prestige, map changes or relaunches. If the scene is left, stop the local spectacle appropriately; no orphan nodes, sounds or performance leaks.
- The dance floor should encourage collecting the remaining outfits, but completing the outfit collection **does not automatically change the separately defined 100% game-completion requirements**, unless existing canonical rules already specify otherwise.

## 7. Expand the existing Game Completion percentage

Currently the completion calculation appears to count only **Map Mastery**. Rework the existing source of truth and all its displays so **100% Game Completion** requires *all four categories*:

1. **All Map Mastery objectives completed** (all actual stages/maps).
2. **Every available Prestige card owned** (respect the existing card catalog and ownership; do not confuse card set completion with every card).
3. **All Player upgrades maxed**, based on the actual upgrade families and rank/cap definitions (including legitimate Coin/Gem upgrades as applicable).
4. **All Enemy upgrades maxed**, across every applicable enemy/type and available upgrade track.

Implement a clear **breakdown** in the appropriate existing completion UI: per-category achieved/total and progress, plus an overall percentage. Prefer **equal category weight (25% each)** so a large number of enemy upgrade ranks cannot obscure all other progression; within each category derive progress from actual earned ranks/completed entries rather than treating a partially upgraded track as finished. If an existing completion architecture has an intentional different weighting, reconcile it thoughtfully and **report the exact formula and coverage**; in all cases 100% must be impossible unless all four categories are fully complete.

- Inspect the actual catalog and avoid counting disabled, nonexistent, unpurchasable, dynamically unbounded or debug-only upgrades in the denominator. Include valid upgrades across maps; do not mistakenly count only the currently unlocked stage.
- Clamp/normalize progress safely; no divide-by-zero, percent >100 or floating-point 99.999% when genuinely complete. Make it efficient for UI refreshes, and derive counts from canonical progression state.
- Preserve existing Mastery calculations; completion is a new combined **gamewide** indicator, not a redesign of stage Mastery. Maintain **main adventure completed** (Green Alien defeated) as separate from the longer **100% Game Completion** goal. Do not gate the victory message on 100%.
- Update all existing completion displays, objectives and help texts that currently imply Mastery alone determines full completion. Save compatibility must not erroneously award completion for older profiles without all four requirements.
- **Outfit collection is tracked independently** by its dance-floor X/Y counter; do not silently add it as a fifth requirement.

## 8. Focused validation only; no balance studies

Run only targeted functional and visual checks appropriate for this feature/presentation batch; avoid re-running gameplay profiles, fight ladders or time-consuming combat balance tests. Validate at minimum:

- Green Alien's HP/attack exactly doubled, Heal correctly wired and damage skills inherit base attack once; **Rage Mode** triggers only once at <=20% HP, boosts **attack speed 50%, defense 30%, heal 20%**, applies one immediate heal, latches even when healing above 20%, and does not alter other combat data.
- Normal arena wall changes visibly from blue/green to **RED** during Rage Mode and returns to normal for the next boss. Confirm both the graphics and **the physical barrier** remain in sync, with unchanged arena blocking/collision.
- **New warning** is shown once before the first eligible updated encounter for *both new and previously victorious saves*, with Yes/No, cancel/retry, opt-in recommended audio, interruption persistence, and no automatic re-prompt each frame. The **full 13-key ceremony replays once after accepting** even if the old ceremony was completed, without changing key ownership or unlocking progression; it is skipped on later fights.
- Music starts with `EndGame - Music 1 (1).ogg`, transitions to `(2)` on Rage; the enraged SFX and randomized occasional laughs fire at correct times; the mix respects opt-in, mute, pause and restore behavior. Test the persistent near-boss recommended-volume tap action at 432×960 and 540×960.
- Boss-key quest appears only after discovery, is accessible on every map, and names *missing keys and source bosses/stages*; updates correctly after obtaining keys, Prestige and reload.
- Final-boss marker is visually distinct and about 40% larger wherever shown, with correct touch targets and no leaked/spoiler UI.
- First victory: arena opens, rewards resolve, owned outfit types spawn within 5 seconds, VFX/floor persists through the 10-second intro, endgame panel appears afterward, and user retains access to normal gameplay.
- One-time message survives save/load and Prestige only after real acknowledgment; interrupted/missed panel is delivered on the next boss win; old winner saves work. Hard Reset restores eligibility.
- Review and Discord open correct official links and Continue Playing always works; music/SFX settings are never changed without an explicit tap. Restore the previous soundtrack after the fight and cleanup.
- Subsequent victories: floor/count update, remains until respawn, does **not** pause or interrupt controls, and cleans up safely when leaving/reloading.
- Completion percentages and breakdown correctly handle zero/full/partial progress, every category, upgrades across maps/enemies, and old saves.
- Visual playback at **432×960 and 540×960**, with readable danger dialog, non-blocking audio prompt, normal and **red enraged arena**, rage warning, dynamic outfits and effects; inspect at real playback speed, not just static bounds. Be careful of Android performance and rendering density; list phone-only checks honestly.

Update or add one focused Change 83 probe as appropriate. Headless/load, localized English fallback and export-allowlist sanity checks are appropriate. **Do not** rerun the whole old suite or large simulations unless an actual integration error makes it necessary; report exactly what was and wasn't tested.

## Delivery

- One local scoped commit, e.g. `feat(change-83): celebrate final victory and expand completion`; do not push/export/publish.
- Preserve the developer's uncommitted version **43** changes, including the preset. When source files need export allowance updates, stage only those specific lines without staging the existing user changes.
- Provide the before/after Green Alien HP, attack, Heal and **Rage Mode** settings; confirm **+50% attack speed** and the **red sealing arena ring**, the first-time danger prompt/ceremony replay on old saves, opted-in 40%/100% audio and asset mappings; victory/respawn/dance floor timing and lifecycle; exact full-completion formula and category counts; links and one-time message persistence; screenshots/video locations; focused test results and remaining Android checks; Git commit hash.
- **No unrelated changes, no further balancing beyond the explicitly approved Green Alien changes, no long gameplay simulations, and no release/publication work in this batch.**
