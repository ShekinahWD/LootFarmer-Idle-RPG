# Apply Change 6

Base: the LootFarmer project with the Change 5 corrections applied (the state of this workspace before Change 6). This is a changed-files set; paths are project-relative with no wrapper folder.

1. Back up the project.
2. Copy the files listed in LootFarmer_Change_6_Patch_Manifest.json over the project, keeping their relative paths (includes new scenes, scripts, tools, tests and docs; stage scenes 1–8 are modified in place).
3. Open with Godot 4.7 and let resources import (or run `godot --headless --path . --editor --import --quit`).
4. Existing current-schema saves load without Hard Reset: map exploration resets once because encounter sites moved (fog layout revision 2) and saved enemies move to their new homes.

Do not re-apply an earlier patch afterwards. No signing material, keystores, build products, engine caches or new art are included. Verification steps: LootFarmer_Change_6_Validation.md.
