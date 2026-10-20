# LootFarmer 0.5.4 — Single-swing attacks and readable currency

Extract over 0.5.3 at the project root. Export/signing configuration is preserved. Increment the Android version code for the next Play upload.

## Attack correction
The supplied eight-frame weapon sheet contains a second swing at frame 5. Previously all eight frames played for one authoritative damage event. The shared actor renderer now plays frames 0–4 once (windup, contact, recovery). Frame 2 remains synchronized with damage contact. Simulation records attack duration when each attack starts, bounded by the cooldown; recovery cannot overlap the next scheduled attack. Both players and enemies use the correction, including player attack-speed bonuses. Unarmed attacks retain their single contact-centered hop.

This changes presentation, not damage values or attack frequency. Invalid/dead/out-of-range targets still cancel damage as before.

## Currency readability
Coin and gem atlases now crop their actual opaque artwork instead of including large transparent margins. HUD and gem pickup controls are 44x44 with preserved aspect ratio. Persistent gem-notification icons have a 38px width limit. Item icons retain their existing sizes.

## Verification
Godot 4.5.1 headless import succeeded. Attack timing probe: 49 checks, covering player and enemy attacks across cooldowns 1/3, 1/2, 1, 1.6, 1.8 and 2 seconds, single visual swing/single hit, contact frame alignment, recovery bounds and currency crops. UI probe: 24 checks. Progression/layout probe: 88 checks. All passed. Actual Android visual verification remains outstanding.
