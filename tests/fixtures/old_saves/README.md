# Released-build save fixtures (schema 8)

Real save files written by the released pre-update game (commit `3dd2eab`, save file version 3, state schema 8),
read by `tests/change_57_probe.gd` to prove that this update migrates them without loss. Each file is exactly what
that build's `SaveService` format holds, plus one extra top-level key, `_old_build_stats` (that build's
`sim.stats()` for the profile), which both builds ignore when loading.

| File | Profile |
|---|---|
| `schema8_fresh.json` | A new profile |
| `schema8_mid.json` | Summer I reached; Wood Sword ^40, Stone Axe ^60 (equipped), outfit ^120; Map Mastery best merges from an earlier run (Iron Sword ^70, a tier-2 outfit ^150); Coin and Gem upgrades; an extra camp; a finished unclaimed mission; an earned main objective; a pending offline claim with a Wood Sword copy |
| `schema8_late.json` | Spring II reached, 3 Prestiges; Diamond Sword ^100 equipped, Gold Axe ^35 and Emerald Sword ^12 stored, Red Panda outfit, 20 cards and their consumed opportunities, 13 equipment slots |
| `schema8_batch.json` | An open Prestige batch (one ready Hunter opportunity, no card chosen yet) |

Regenerate (only if the fixtures must change): `git worktree add ../lootFarmer_c48 3dd2eab`, copy this folder's
`generate_on_3dd2eab.gd.txt` to `../lootFarmer_c48/tests/tmp/oldsave/gen.gd` with a scene that runs it, copy the
`.godot` import cache, run it headless with `-- --probe --profile=probe-oldsave-gen --no-autosave
--first-run-complete`, and copy `user://oldsave_<name>.json` here as `schema8_<name>.json`.
