# LootFarmer — current prototype — Change 1

Current handoff: `LootFarmer_Change_1_Notes.md` and the Current implementation authority section of the GDD. Older handoffs below are historical and do not override these.

## Historical v0.4.0 status

Date: 2026-10-18, America/Santo_Domingo.

## Current result

The compact gameplay loop is implemented in source. Open `project.godot` and run the main scene (`scenes/game/main.tscn`). Extract this changed-files ZIP directly into the existing project root; it uses the supplied asset folders. No extra parent directory is present.

The user confirmed the v0.2 bootstrap's save, Hard Reset and English-only languages work in their Godot editor. The user explicitly deferred signing and authorized prototype implementation. This exception supersedes the earlier project-document signing gate for development only. No signed APK, Android device acceptance or release readiness is claimed.

The declared Godot feature version remains 4.7. Local checks used Godot **4.5.1 stable**, Linux, compatibility renderer; this is a compatibility check, not certification of the user's exact editor/export-template pair.

## Play

- Drag the circular joystick; desktop arrows/WASD also work. Release for one second to acquire and approach a nearby enemy automatically.
- Move north through the scrolling meadow. Each band has two small clusters sharing its group upgrades. The central route permits travel around most encounters; the world is open from the start.
- Tap dropped gear or consumables. Coins/gems credit on the kill. Your character has a blue arrow above it.
- Tap an inventory slot to equip, inspect, merge, evolve, reroll or sell. The gear and supply rows scroll horizontally as capacity grows. Equipped gear still occupies its slot.
- Upgrades contains the group selector, group drop upgrades, automation/capacity purchases, the identity-based auto-sell list and consumable shop.
- World contains purchasable/selectable respawn camps and group focus. Buying a camp does not select it. Manual movement cancels focus.
- Health potions need HP strictly below 80%. Auto-use is assigned to a supply slot after unlocking a channel. Empty slots keep their assignment.
- Management panels leave combat active. Only Pause freezes simulation; background suspension also stops simulated time. Settings contains Save and confirmed Hard Reset.
- Defeat Death, who summons black cats, to choose one of three persistent prestige cards. You may close the offer and keep farming. World reopens the offer. Confirmation explains the reset.

## Implemented slice

Three ordinary enemy groups, Death and capped summons; unarmed movement/combat, three sword tiers, three outfits, potion and coin tonic; manual pickup, expiry, two inventories, shared rolls and merges, evolution, sale, rerolls; all scoped upgrade tracks; collection, merge, use, auto-sell and focused-return automation; three camps; death/respawn; acquisition history 3/10; contextual guidance; explicit pause; save/recovery/reset; prestige and permanent cards; English-first language gate. Actor, terrain, dock, slot, action-row and joystick scenes are editable.

First enemies retaliate individually. Robots aggro on proximity. Dinosaurs assist their group. Leashed enemies return before re-engaging. Corpse presentation ends separately from logical death and rewards. Short localized surprise/loot lines supply the clothing-theft tone.

## Validation evidence

| Check | Result |
|---|---|
| Godot import and gameplay startup | PASS on 4.5.1; no GDScript errors |
| Existing bootstrap regression | PASS, including damaged-primary recovery and paused reset |
| Gameplay probe | **52 checks, 0 failures** |
| UI/actor probe | **14 checks, 0 failures** |
| Rendered inspection | Gameplay and all panels at 720×1280; tall layout at 720×1600 |
| Boss build fixtures | Dinosaur and Sprout builds won; Robot fixture lost, confirming equipment choice matters |
| Resource-pack export and startup | PASS; gameplay JSON explicitly included; probes/docs excluded |
| Signed Android export/device play | Deferred / NOT RUN |
| Natural first-run length and sustained Android performance | NOT measured; initial 30–60 minute target remains provisional |
| Audio listening on device | NOT verified; sparse supplied UI sounds are wired |

Gameplay checks cover retained progression at zero quantity, last-equipped protection, full-inventory stacking/auto-sale, evolution and output space, strict potion threshold/cooldown, stronger boost reuse, attack cancellation/contact, dead-enemy reload, respawn, pause/background clocks, loot expiry, prestige durability/retention, malformed gameplay data, leash/regen, automated collection/merge/use and focused return.

UI checks cover layout boundaries, unpaused management, actual upgrade/use callbacks, touch pickup through the SubViewport, joystick release, disabled locales and verified walk/death presentation. Rendered QA caught and corrected GUI slicing, shadow placement and the idle/walk row mapping. Desktop capture emitted only an unsupported-VSync environment warning in the final pass.

Prepared boss fixtures use Iron Sword ^100, outfit ^100, +6% attack speed/+1.5% lifesteal sword extras, +15 HP/+4 defense outfit extras, and automated Potion ^100 at a two-second interval. Dinosaur won in 38.3 simulated seconds with ~113.5 HP; Sprout won in 38.3 seconds with ~11.9 HP. Robot lost at 31.2 seconds. These fixtures prove two viable loadouts; they do not prove normal acquisition pacing.

## Run isolated checks locally

Use your installed Godot console executable in place of `godot`:

```text
godot --headless --path . tests/bootstrap_probe.tscn -- --profile=probe-bootstrap --no-autosave
godot --headless --path . tests/gameplay_probe.tscn -- --profile=probe-gameplay --no-autosave
godot --headless --path . tests/ui_probe.tscn -- --profile=probe-ui --no-autosave
godot --headless --path . tests/balance_probe.tscn -- --profile=probe-balance --no-autosave
```

Every probe resolves an isolated profile before load. Never change the probe profile to production. The Android helper's signing procedure is unchanged and remains available when signing resumes. The old bootstrap scene remains available as `scenes/main.tscn`.

## First human playtest

Verify movement/stop-to-attack, readable loot tapping, equipment appearance, inventory/full-slot behavior, closing/reopening during combat, pause/reset, and a complete natural progression run. Report the first point that feels slow, unclear or impossible, plus your exact Godot version and phone viewport if layout differs. No more core-design interview is needed.

Offline rewards, translations beyond English, extra weapon families/content, final marketing and release signing remain their already agreed later stages. Toolkit 1.0.2 was kept unchanged; QA viewport captures are not store-media certification.

## Visual correction pass — v0.3.1

Implemented the requested player-locked camera, closer default and saved zoom controls; source-independent item bounds; complete supplied sword/scythe animations; compact icon-based wallet without the title; normal rectangular player HP and red enemy HP. Existing save data defaults to 2× zoom. Combat balance and inventory ownership are unchanged.

Validation: Godot 4.5.1 compatibility runtime, 52 gameplay assertions and 24 UI/presentation assertions; rendered portrait views at 1×, 2× and 3× zoom, attack poses, panels and tall viewport. Bootstrap probe rechecked after the settings schema addition. The project retains its declared Godot 4.7 feature baseline. Device feel still needs your Godot/Android review; signing remains intentionally deferred.

Apply the changed-files ZIP over the already installed v0.3 prototype. Paths are directly at the ZIP root. Open `scenes/game/main.tscn` or run the project; use the map −/+ buttons. Recheck zoom persistence, movement/attack, potion pickup, and enemy bars. Attack weapon/hands use the supplied sequences; outfit bodies retain their matching idle art because the selected outfit family has no dedicated attack row.

## Camera gestures — v0.3.2

Apply this changed-files ZIP over v0.3.1. Drag with one finger or the left mouse button to pan; the camera remains at that position while the player auto-moves. Joystick movement (or keyboard movement) restores player-follow immediately. Camera center is bounded to the authored world rectangle, 360×1500.

Pinch with two fingers that both start on the map to zoom. The horizontal slider replaces the zoom buttons; it updates immediately with pinch and preserves the existing saved 1×–3× preference. Pinch leaves the camera center/follow mode unchanged. Joystick and other HUD touches never participate in the pinch. After a pinch, lift both fingers before starting another drag/tap.

Loot collection occurs on release of a short tap (under 10 canvas pixels); drags, pinches, canceled touches and releases outside the map never collect. Focus loss, opening a panel and joystick use clear active gestures. Map camera controls remain available while paused, but loot cannot be collected while paused.

Validation: 17 camera/input assertions using viewport-routed touches, 24 UI assertions, portrait visual review. Actual device multitouch feel still needs Android review.

## Current v0.4.0 handoff

World redesign, actor inspectors, permanent information unlocks, camp selection, HUD placement, MSDF text and new gear-drop bases are implemented. See `LootFarmer_v0.4.0_Notes.md` for the current behavior and test evidence. Earlier version sections above are historical. Full GPU/device visual acceptance remains pending.


## Approved implementation revision — 0.5.0

The current interface, XP progression, stored-weapon bonuses, three-column enemy variants, worn-gear drops and schema-2 migration are specified in `LootFarmer_v0.5.0_Notes.md`. Those rules supersede earlier single-group map/UI and equipped-only stat descriptions. Test evidence is in `Progression_UI_Evidence/`. Physical-phone visual review and a complete natural run remain pending.
