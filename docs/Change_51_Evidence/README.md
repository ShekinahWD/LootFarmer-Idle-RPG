# Change 51 evidence: H24 weapon ladder (B2 of the approved progression brief)

All runs are constructed fixtures in the real simulation (Playbook 112.2 evidence class 1), seeds 1–5 (final boss)
or 1–3 (ladder). Nothing here is a natural playthrough.

| File | What it is |
|---|---|
| `ladder_live_H24_trials.csv` | `python tools/progression_audit_run.py live_H24`: the audit's Stage 6–8 ladder builds on the shipped H24 catalog, no tier patch. 734 rows, **field-identical** to the audit's what-if `docs/Consolidated_Audit_Evidence/lad_H24.csv` (only the patch label differs). |
| `final_boss_builds_obsidian.json` | The Change 36 final-boss ladder rebuilt by `tools/change51_final_boss_builds.py`: every Diamond/Emerald sword → Obsidian Sword at the merge level with the same damage (capped at ^100); stored weapons on legal Spring-era tiers. |
| `final_boss_obsidian_trials.csv` | `res://tests/change_36_final_boss_audit.tscn --builds=res://docs/Change_51_Evidence/final_boss_builds_obsidian.json`: 140 duels, `AUDIT36_CHECKS 280 FAILURES 0`. |

Final boss (Green Alien), Obsidian builds:

| Build | Weapon | Result | Time (s) | Change 36 (Diamond) |
|---|---|---|---|---|
| MIN (early Prestige, L250, supplies ^25) | Obsidian Sword ^39 | 5/5 | 245–258 | 5/5, 256–263 |
| REC (L260, 3 skills ^10) | Obsidian Sword ^57 | 5/5 | 151–158 | 5/5, 156–160 |
| NOP (no Prestige, supplies ^100, Red Panda ^100) | Obsidian Sword ^100 | 5/5 | 524–541 | Emerald ^50: 5/5 |
| MIN with any one supply removed, supplies ^20, or stock 15/10/6 | — | 0/5 | — | 0/5 (same cliff) |
