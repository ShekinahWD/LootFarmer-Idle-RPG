# LootFarmer 0.5.2 — Target locking and stronger merges

Extract over 0.5.1 in the folder containing project.godot. The prior bootstrap font hotfix is included. Export presets and signing configuration are not overwritten. Increase the Android version code for a new Play upload.

## Targeting
Automatic acquisition now keeps the same living enemy between strikes, even when a closer enemy arrives or spawns. The player pursues that enemy beyond the initial acquisition radius.

Drag from the player onto an enemy. A line follows the finger, turning gold when over a valid enemy. Release to select; a gold downward arrow marks the manually selected enemy. Release over empty ground or cancel to keep the existing target. A short tap on the player still opens upgrades. Drag elsewhere to pan; a second finger cancels aiming and starts pinch zoom. Manual targeting is disabled during pause.

Joystick movement overrides pursuit while held; pursuit resumes after the normal idle delay. Selecting a different enemy cancels the pending old strike. Enemy death, player death, reset and save reload clear target locks. Explicit enemy-group farming changes clear the old lock. Target locks are transient and do not alter the save schema.

## Merging
Each merge adds three times the previous authored fixed-stat increment. Base values, duplicate costs, merge cap and rolled extra stats are unchanged. Existing merge levels immediately benefit. Equipped weapons use 100% of their recalculated stats; unique stored weapons retain their 30% contribution.

Examples per merge: wood sword damage +0.12 (was +0.04); stone sword +0.24 (was +0.08); iron sword +0.45 (was +0.15); Sprout outfit health +0.30 (was +0.10). Consumables also receive triple fixed-stat increments. Item details display next-merge gains.

## Verification
Godot 4.5.1 headless: targeting 15 checks, camera gestures 17, gameplay 52 and progression 88, all passing. Existing numeric expectations were updated to the new merge balance. Target tests cover closer arrivals, manual retarget, pursuit, death cleanup, aiming, marker presentation state and pinch cancellation.

Physical Android and rendered visual verification remain outstanding. This balance change intentionally accelerates progression and needs playtesting.
