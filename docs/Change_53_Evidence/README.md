# Change 53 evidence: approved combat on the H24 ladder (B4)

`python tools/progression_audit_run.py live_ladder --no-compare`: the audit's 40 ladder builds (constructed fixtures,
seeds 1–3, farms seed 1 for 5 simulated minutes) on the shipped game: H24 weapons, Summer I normals `individual`,
skill variant damage ×1.15, Spring I/II normal damage ×0.60, no attacker cap, no join stagger.
2,346 rows, 0 invalid, no script error. `ladder_summary_vs_A19.txt` (tools/progression_ladder_summary.py) lists each
build next to the audit's `lad_A19` what-if (A19 tiers = H24 tiers through Emerald; Summer I individual; no
other tuning).

- Bosses on Stages 1–6 are identical to the reference (normal-only tuning never touches bosses); Stage 7–8 bosses
  differ only by the H24 Obsidian step.
- Every arrival build loses its map's boss(es); every ready build wins every default 3-actor spot
  (Spring II at Obsidian ^100: 22/22, was 20/22).
- 6-actor spots: won at the ready build on Winter II–Autumn II (Autumn I Pumpkin skill spot 2/3, was 0/3) and now
  on Spring I (Elf Ears 3/3, was 0/3); Spring II Sprout 6-actor stays lethal without a Prestige (optional risk).
- Spring II: Red Panda 3/3 at Obsidian ^100 without Prestige, Sunflower 0/3 (3/3 with one Prestige), as approved.
