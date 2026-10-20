# LootFarmer v0.6.2 — playbook audit fixes

## Install

Apply this changed-files ZIP over **v0.6.1**, not the original v0.1.0 bootstrap ZIP. Close the running game, extract directly into the project folder and overwrite. Open project.godot in Godot and let the scripts/localization reimport. No asset deletion, save reset or signing changes are required. This patch does not contain an APK or AAB.

## Changes

- Added a shared TouchScroll to the inspector, gear and supplies lists. Dynamically added controls pass input; sliders, editable controls and nested scroll containers retain their own input. Inventory no longer consumes the press that its scroll parent needs. Emulated mouse input cannot duplicate a slot tap.
- Inspector updates reconcile descriptions into existing live controls: unchanged rows/buttons retain identity, pressed state and scroll. Structural changes alone replace nodes; offset restoration waits two frames. Achievement status space is always reserved.
- Group and player upgrade cards show current → next benefit from simulation getters, currency buttons, progress bars and a permanent status row for affordability, maximum and pause reasons. Secondary blocked actions include their reason. Upgrade purchase validation uses the same block-reason function as presentation.
- Gameplay action methods reject player pause and app suspension, including purchases, merge, evolution, reroll, equipment, consumables, camp/focus selection and loot collection. Read-only inspection and settings work while paused. Hard Reset remains available and resumes; prestige remains a separate results transaction. Legacy saved pause no longer freezes a new session.
- The world alone controls target marker visibility. The selected living enemy keeps its gold arrow through actor updates; clearing selection/death hides it.
- HP, damage/healing feedback, gems, loot notifications/history and enemy values use the shared compact formatter. Display templates for XP, MAX, seconds and HP/s are localized. Percent values remain percentages, not altered gameplay values.
- Stats include base, level, equipped and stored-weapon contributions, permanent HP/damage multipliers, and an explanation of caps. The effective getter sums those same source buckets.
- Updated GDD/current handoff for v0.6.2, the 0.5-second acquisition wait, per-type upgrades/merge, potion +0.4, fractional coins and current UI. Old initial proposals remain explicitly historical.

## Verification

Godot 4.5.1 headless (user's target editor is 4.7):

| Probe | Checks | Failures |
|---|---:|---:|
| Audit | 143 | 0 |
| Gameplay | 52 | 0 |
| UI | 24 | 0 |
| Farming UI/economy | 29 | 0 |
| Group progression | 24 | 0 |
| Inventory | 125 | 0 |
| Attack timing | 49 | 0 |
| Camera gestures | 17 | 0 |
| Total | 463 | 0 |

The audit probe routes input through the viewport, including the companion mouse events Godot generates for physical touches (push_input itself bypasses OS emulation). It verifies dragging from buttons/card paper/slots, scroll without purchase/use, exactly-one tap purchase, retained button identity/scroll, late child input filters, shared getter values, contribution totals, target arrow lifetime, and unchanged snapshots after rejected paused actions. These are not direct calls to scroll/slot movement helpers.

Editor import reports no GDScript errors. Android build tools are unavailable in this environment; no Android export or signed artifact verification was performed. GPU screenshots and physical phone visual acceptance remain unverified here. On the phone, check inspector/expanded inventory scrolling, long-press details, pause action reasons, compact labels and target arrows before replacing the internal-test release.

Run the new probe from the project folder with an installed Godot executable:

    godot --headless --path . res://tests/audit_probe.tscn -- --profile=probe-audit062 --no-autosave

All probes use isolated test profiles. Do not point them at a production save.
