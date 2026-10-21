# Apply LootFarmer Change 4

This is a cumulative changed-files patch against the supplied `lootFarmer(6).zip` source. It includes the current design documents and reusable playbook, so a separate Change 3 documentation patch is unnecessary. Apply this patch last; applying an older patch afterward can revert approved rules.

1. Back up the project and existing player saves. Close the editor.
2. Extract this ZIP into the directory containing `project.godot`, replacing files at their existing relative paths. Do not create an extra nested project folder. No source-file deletions are required.
3. Reopen with the project's Godot 4.7 installation and allow resource imports. The baked stage scenes are included; regeneration is optional with `tools/build_campaign_maps.gd`.
4. Run the two isolated campaign probes described in Change_4_Validation before updating the production build. Existing schema-5 saves migrate to schema 6 on load; retain a backup because older game versions cannot interpret new saves.

The package contains source, eight stage scenes, documentation, tests and evidence. It excludes `.git`, `.godot`, generated builds, credential files, saves and raw third-party asset copies. Required art/audio already exists in the supplied source ZIP. `LootFarmer_Change_4_Patch_Manifest.json` lists file hashes. Application version is 4; Android version codes and signing settings are intentionally untouched because this is not a release export.
