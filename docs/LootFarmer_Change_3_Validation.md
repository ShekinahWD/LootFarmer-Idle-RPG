# Documentation validation — Change 3

Performed 2026-10-20. This report covers documentation, not gameplay execution.

- Confirmed roster contains exactly 48 unique ids: 34 normals and 14 bosses across 8 stages, matching approved per-stage counts.
- Verified all 48 source-sheet paths exist in ZIP 6 and their SHA-256 hashes match the seasonal source index.
- Verified 33 unique cards and 33 opportunities, exactly 3 of each per path across 11 paths.
- Verified 17 combos, each referencing 3 distinct existing card ids (11 same-path, 6 mixed).
- Verified merged Playbook contains fog implementation 117.9, map presentation 124.12 and acceptance 127.6 exactly once while retaining 22.4 asset registry and 136 reconciliation guidance.
- Checked Markdown fence balance and active-document reading order.
- Reviewed latest decisions against current documents: +100% movement, 3–8 mission slots, permanent keys, no selling, retained stock bonus, 85% intrinsic evolution, all skills by stage 4, one boss skill roll, per-stage and per-camp reveal upgrades.
- Final archive validation checks CRC, documentation-only paths, SHA-256 manifest, no wrapper directory, no game files/assets/credentials/caches. No local source or signing files deleted.

No fresh Godot run, Android build/device test, animation playback or audio listening was performed. Prices, stat formulas, authored missions/cards and content placement are delegated initial tuning, not verified game balance. The pre-existing boss-loadout failure remains open. Gear/skill auto-merge frequency purchase is explicitly provisional.
