# Change 54 evidence: Prestige expansion (B5, Design A)

Card measurement (constructed fixtures, real Prestige transaction with explicit picks, seeds 1–3; 699 fights,
0 invalid): `python tools/change54_card_builds.py`, then
`godot --headless --path . res://tests/progression_audit.tscn -- --probe --profile=probe-audit54 --no-autosave
--first-run-complete --builds=res://docs/Change_54_Evidence/builds_cards.json --csv=<out>`;
`card_summary.txt` = `tools/progression_ladder_summary.py`.

- `pfarm` = Crowd Guard, Second Wind, Cleave, Broken Rally, Field Rest, Steady Supplies (one Prestige).
- `pboss` = Boss Breaker, Last Stand.

| Ready build | No cards | + pfarm | + pboss |
|---|---|---|---|
| Summer I (Gray Cat; 6-actor) | 23% HP left; 2/2 (worst 29%) | 48%; 2/2 (38%) | 23%; 2/2 (29%) |
| Autumn I (Fox / Squirrel; 6-actor) | 61% / 66%; 1/2 | 73% / 89%; **2/2** | 61% / 68%; 1/2 |
| Spring I (Bee / Tabby; 6-actor) | 64% / 67%; 2/2 (50%) | 67% / 64%; 2/2 (60%) | 51% / 65%; 2/2 |
| Spring II Obsidian ^100 (Panda / Sunflower; 6-actor) | 55% / 0/3; 0/2 | 64% / 0/3; **2/2** | 58% / 0/3; 0/2 |

Default 3-actor spots are won in every column. The farming cards make optional 6-actor spots winnable; they do not
make the Spring II Sunflower winnable (it still needs the boss cards of a Prestige, as approved). Second Wind also
adds survival in boss fights (Gray Cat +25 points HP left). Not measured in a fight: Twin Find, Thrifty Evolution,
Precise Reroll, Treasure Sense, Champion's Spoils, Veteran Traveler, Obsidian Temper (gear/pacing effects; their
rules are checked by tests/change_54_probe.gd).
