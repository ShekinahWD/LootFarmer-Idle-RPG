# Apply documentation Change 3

1. Back up the project's current docs folder or commit it.
2. Extract LootFarmer-3-documentation.zip directly into the project root and allow listed docs files to overwrite. There is no wrapper project directory.
3. Start with docs/LootFarmer_Design_README.md. No commands, Godot import, Firebase rules or build/export step is required for this documentation-only patch.

This is cumulative for current active documentation: it can be applied directly to ZIP 6 without applying Change 2 first. It includes preserved pre-Change-2 and pre-Change-3 document history. Existing historical manifests/release notes may remain; they are not active design authority. No file deletion is required.

No gameplay, scenes, assets, signing configuration, save-schema version, runtime version or Android versionCode changes. Do not expect new mechanics to appear after extracting. Rollback by restoring the backed-up active docs; history copies are included for reference. The manifest lists each packaged file's SHA-256 except the manifest itself.
