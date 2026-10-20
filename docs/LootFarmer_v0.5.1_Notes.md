# LootFarmer 0.5.1 — Inventory and control layout

Apply this changed-files ZIP over version 0.5.0, at the folder containing project.godot. Replace the included files, then reopen Godot and let imports finish. This patch does not include export_presets.cfg or signing credentials. When uploading another AAB, increase the Android version code above the previous uploaded version.

## Changes
- Larger inventory viewport, approximately 21% of portrait height plus headings and navigation.
- Three square gear columns beside one square supply column, separated by a visible vertical rule.
- Slot sizes adapt to available width. Additional capacity wraps into rows with vertical scrolling; icons preserve aspect ratio and remain separate from counts.
- Tap an occupied supply to use it immediately. Hold for half a second to open its existing details, merge and automation actions. Dragging cancels activation. Empty slots still open their details.
- Potion cooldown appears on its slot. Existing potion health threshold, cooldown, quantity, and alive checks remain authoritative. Manual quick-use is blocked while paused.
- Simple Kenney frames with corrected nine-slice margins replace distorted control borders. Health and XP use flat cropped asset fills. The slider handle is reduced to 24px. Joystick borders preserve their corners through nine-slicing.
- Existing tier tinting remains.

## Verification
Godot 4.5.1 headless: UI probe 24 checks; progression probe 88 checks; new inventory probe 125 checks, all passed. Inventory probe covers short tap, hold, cooldown, drag cancellation and maximum capacity at 720x1280, 600x1100 and 720x1600.
No rendered or physical Android visual verification was available. Check the result on your internal-test build, especially scrolling supplies and holding without accidental use. Map art and combat balance are unchanged by this patch.
