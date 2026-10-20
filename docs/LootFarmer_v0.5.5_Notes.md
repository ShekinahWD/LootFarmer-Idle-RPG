# LootFarmer 0.5.5 — Movement cancels targeting

Apply over version 0.5.4 at the project root. Export presets/signing settings are preserved. Increase the Android version code for the next Play upload.

Manual joystick/keyboard movement now clears both the combat target lock and manually selected target. Movement still cancels the pending strike. Stopping allows nearby-target acquisition after 0.5 seconds instead of 1 second. Existing weapon cooldowns remain authoritative. Enemy death continues to clear targeting.

Validation: Godot 4.5.1 headless targeting probe, 23 checks passed. Added regression coverage for manual and automatic lock cancellation, pending strike cancellation, cooldown preservation, the half-second acquisition threshold and acquiring a nearby enemy instead of returning to the old target. Android visual verification remains outstanding.
