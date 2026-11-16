# LootFarmer — Change 82: Green Alien Unlock Ceremony and Final Boss Arena

**Task:** Implement the two final-boss presentation/encounter features below in the **current repository** (after Change 81, commit `fe557ae`). This is an approved implementation task, not a request for proposals or balance analysis.

## Scope boundary — read first

**ONLY:** (1) a one-time 13-key unsealing ceremony; (2) a sealed arena during Green Alien combat; and the minimum save, UI, audio/VFX, localization, documentation, and focused tests required for them.

**DO NOT** change boss/enemy HP, damage, attack rate, skills, summons, AI difficulty, player damage, equipment, XP, Prestige cards, Prestige pacing, boss-key requirements, or any combat/balance values. **DO NOT** run new combat ladders, player-profile runs, long gameplay simulations, balancing studies, exports, or extensive test suites for this task. The difficulty of the final boss and the importance of repeated Prestige are deliberate. The developer will assess balance personally.

Follow the repository's Reusable Game Development Playbook. Inspect the **latest** Change 81 implementation (Green Alien sealing, persistent 13-key tracker, key pickup animation, save/Prestige rules) and reuse existing VFX and UI systems rather than creating parallel ones.

## 1. Green Alien — one-time 13-key unsealing ceremony

### Trigger

- Green Alien remains sealed until **all 13 distinct boss keys** are collected, per the existing rules.
- The ceremony triggers **once** when a player with all 13 keys **approaches/attempts to engage Green Alien** in Spring II. Reaching 13/13 on another map must **not** play it immediately.
- With fewer than 13 keys, retain the existing sealed-boss behavior, explanation, and key tracker. Do not allow the cinematic or combat to begin.
- A player who already has all 13 keys from an existing save should see the ceremony on their first valid approach unless a durable completed-unlock state already exists.

### Visual sequence

Aim for a clear, polished **~4–6 second** in-game cinematic, using the existing gold-key artwork and compatible VFX:

1. Show **13 visible keys** materializing around the player.
2. Keys **orbit** the player, increasing speed and brightness; use legible glow/sparkles without obscuring the sprite or HUD.
3. Keys converge and **fly toward Green Alien**, triggering an obvious seal-breaking/shining effect at the boss.
4. Transition to the boss's unsealed/attackable state. Display a short readable message, for example: **“YOU HAVE PROVEN YOUR WORTH! The Green Alien accepts your challenge. Defeat it!”** (copy can be refined for clarity/localization).
5. Once the message has been conveyed, start the actual boss encounter and close the arena as described below.

The ceremony is **presentation**, not thirteen new collectible objects. Never consume or re-award keys; the existing 13-key count remains authoritative. No taps or pickups are required. During the unsealing sequence, prevent premature combat and any damage/AI side effects caused by cinematic timing; restore normal play reliably afterwards. Reuse existing theme, assets and effects, and make the effect performant on Android portrait screens. Any audio must use the current sound/settings controls.

### Once-only state and interruptions

- Persist a **completed/unsealed** state separately from transient animation playback. Completed ceremonies **never repeat** on subsequent attacks, deaths, reloads, or Prestige runs; Hard Reset clears the state.
- An interrupted **incomplete** ceremony must recover safely: resume or replay on a subsequent valid approach, without softlocks or counting a completed ceremony twice. Do not permanently unlock the boss *before* the presentation finishes unless equivalent safe completion logic is guaranteed.
- After the first completed ceremony, future valid encounters begin normally with **no circling keys and no repeated worthiness message**.
- Keep the existing Boss Keys tracker and existing key-pickup animation unchanged.

## 2. Green Alien — final boss arena (fight to win or defeat)

When the actual Green Alien encounter starts, spawn/activate a **visually obvious energy barrier around the combat arena**. It must be more than decoration:

- The boss and player must be **inside** the boundary when it closes. Choose the arena center/size from the actual Spring II battlefield and boss mechanics; make room for melee, ranged skills, knockback, and intended summoned helpers. Do not place the boundary through impassable terrain or the player.
- Allow normal movement, skills, fighting and consumables **inside** the arena, but **physically prevent escape** by joystick movement, automated navigation/Auto Farm, knockback, targeting/movement quirks or other paths.
- Disable/prevent **camp travel, map teleportation, change-map navigation, and any other teleport-out mechanic** while the encounter is active. Give concise non-spamming feedback if the player tries to leave. Keep pause/settings available.
- Ensure projectiles, hitboxes, telegraphs, and camera/zoom function without unfair clipping at the boundary. Reuse existing effects; do not introduce competing full-screen UI or obscure joystick, boss, health or HUD.
- Avoid unrelated ordinary enemy interference **where feasible without changing wider combat balance**; retain Green Alien's intentionally summoned helpers and all existing attack/skill behavior.
- **Player death:** open/remove the barrier immediately and follow normal death/respawn. **Green Alien defeat:** open/remove the barrier and follow the existing win/quest flow. Clean up visual/collision nodes in both cases.
- **Next attempt after a death:** the arena closes again on combat engagement; the 13-key ceremony does not replay.
- Handle pause, save/reload, map transitions, boss despawn/reset, app interruption, and hard reset safely: no phantom collision, permanent entrapment, or easy teleport-out bypass. Prefer restoring a valid encounter state on reload, or an explicitly safe and consistent reset aligned with existing save rules. Do not allow reload to mark Green Alien defeated or keys consumed.
- The barrier is **only** for the final Green Alien encounter. No other bosses or stages are affected.

## 3. Implementation guidance

- First inspect current Green Alien targeting, key/unseal state, fight lifecycle, map boundaries, navigation/teleport controls and save schema. Centralize encounter state so the arena cannot disagree with whether the fight is active.
- Build on Change 81's key asset, existing event/animation/FX patterns, and current portrait HUD; do not produce AI-generated art.
- Keep the ceremony one-time and the barrier per-attempt as **distinct** states; the permanent unlock must not persist an active barrier after a death or finished fight.
- Use existing localization keys and fallback strategy for any new text; flag new English strings for the later 19-language localization pass. Do not run a whole localization rewrite now.
- Update the relevant GDD section and the smallest necessary tests; avoid unrelated documentation and version changes.
- Preserve all existing saves, unlocked keys, boss discovery and Prestige progress. Avoid migrating or rewriting records unnecessarily.
- Preserve the developer's **uncommitted version 43 / Android code 43 edits** in `project.godot` and `export_presets.cfg`. Only touch export allowlisting if genuinely necessary for newly added scripts/assets, and stage those exact changes without staging the developer's version edits.

## 4. Focused acceptance checks — no balance retesting

Only validate the features being introduced:

1. Fewer than 13 keys: Green Alien stays sealed; ceremony and arena do not start.
2. Exactly 13 keys and first valid approach: orbit/shining/unsealing sequence happens once; encounter starts only after safe cinematic completion.
3. After unsealing, repeat attempt/death/Prestige/save-load does **not** replay the ceremony; incomplete interrupted sequence recovers.
4. Arena locks when fighting, cannot be crossed via walking/Auto Farm/knockback or exited via travel/teleport; combat inside works.
5. On death or victory, barrier opens and cleans up; re-engagement after death recloses it without redoing the cinematic.
6. Reload, pause and reset do not strand the player or leave stale barriers.
7. Short visual inspection/captures at **432×960 and 540×960**: key-orbit clarity, boss unlock, boundary visibility, and HUD/joystick readability. Inspect one normal-speed playback of the ceremony and barrier open/close, not only static bounds.

Run relevant **small focused functional/visual probes**, plus lightweight parser/import checks as needed. **Do not** run combat balance simulations, 7-day player profiles, giant screenshot sweeps or a full gameplay regression battery. Disclose any checks not run; do not imply they passed.

## 5. Completion and commit

Implement the batch end-to-end, validate it, and make **one local Git commit** after checking precisely what is staged. **Do not push, build/export or upload**.

Report briefly:
- How the unlock animation looks, duration and assets/VFX reused.
- Arena geometry and the exact escape restrictions.
- What persists through save/reload, death and Prestige, and what Hard Reset clears.
- Focused checks actually executed and relevant 432×960 / 540×960 screenshots or evidence.
- Limitations and anything needing a real Android phone check.
- Commit hash and confirmation the developer's uncommitted version 43 changes remain untouched.

**No boss rebalance or balance recommendations.** The developer handles final-boss difficulty personally.
