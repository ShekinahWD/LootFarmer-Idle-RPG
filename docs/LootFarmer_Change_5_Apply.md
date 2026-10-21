# Apply Change 5

Base: the user-supplied updated ZIP 7. This is a changed-files patch, not a standalone project.

1. Back up the extracted ZIP 7 project.
2. Extract this patch into the directory containing project.godot, allowing listed files to overwrite. Paths in the ZIP are project-relative.
3. Open with Godot 4.7 and let changed resources import. Run the main scene.
4. Old development progress resets once under schema 7; available settings are retained. No manual hard reset should be needed to make saving writable.

Do not apply an earlier patch afterward. No signing credentials, private keystores, build products, engine caches or replacement art assets are included. Existing owned assets remain required. The source map generator requires an explicit destructive rebuild argument because rebuilding would discard authored scene landmarks.

Current validation: LootFarmer_Change_5_Validation.md. Remaining playbook gaps: LootFarmer_Change_5_Playbook_Audit.md. Changed path hashes: LootFarmer_Change_5_Patch_Manifest.json.
