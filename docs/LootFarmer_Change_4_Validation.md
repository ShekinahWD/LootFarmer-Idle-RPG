# LootFarmer — Change 4 validation

Date: 2026-10-21. Engine executed: Godot 4.6 stable official (89cea1439). The source declares Godot 4.7. No Android SDK/export templates or physical device were available. This report separates rule verification from release acceptance.

| Check | Evidence | Result |
|---|---|---|
| Campaign state + live scene integration | Change_4_Evidence/campaign_probe.log | 260 checks, 0 failures |
| All prestige content, gates, migration, evolution definitions | Change_4_Evidence/content_probe.log | 656 checks, 0 failures |
| Editor asset import / script scan | Change_4_Evidence/editor_import.log | No script parse/compile errors; older engine reports missing export-preset runnable fields and Android build-tools |
| Native English gettext catalog | msgfmt --check | No invalid strings/duplicate keys; standard translator-header metadata warnings only |
| Referenced resources, catalog shape, source package | Change_4_Evidence/static_checks.json | Machine-readable check results |

Campaign probe covers stage rosters/spawns and scene loading; all six skills by stage four; no selling API; every travel combat condition; camera/fog ownership; real camp-radius expansion; merge/evolve/full-tier stock behavior; skill stock and family cooldown; 10→1 automatic merges; final quest discovery/lock/13 keys/current-run clear; once-only main reward; three same-path prestige choices across save/restore and one reset; persistent keys and reset exploration; offline cap/owned-only selection/no online credit/double settlement/clock rollback; injected save failure rollback; mission claim/midnight protection; invalid-stage rejection; all main panel routes. A save_read_only warning is expected from deliberate failure injection, not an unhandled runtime error.

Content probe seeds explicit objective checkpoints to exercise all 33 opportunity predicates and 17 sets. It also checks restriction discovery vs next encounter, consumable invalidation, all three two-boss gates, full-inventory evolution rollback, schema-5 inventory migration and one-time removed-upgrade refunds, every catalog successor's 85% intrinsic ratio, and an overpowered late-game basic-attack ceiling. This is not a natural full-campaign completion or measured first-prestige pacing test.

Reproduce from the project root with isolated profiles:

```bash
godot --headless --path . tests/campaign_probe.tscn -- --probe --profile=probe-campaign --no-autosave
godot --headless --path . tests/campaign_content_probe.tscn -- --probe --profile=probe-content --no-autosave
python3 tools/validate_campaign_source.py
```

The explicit save calls in probes still exercise disk writes under the isolated probe namespace. They never load or overwrite the production profile. Older probes are retained as historical prototype tests: assertions about four types, selling and old first-boss prestige no longer describe the approved campaign. They were not removed or silently counted as passing regressions.

## Remaining acceptance gates

- Run import, runtime, saves and release export with the project's pinned Godot 4.7 and matching templates. The 4.6 run is compatibility evidence only.
- Physical Android: joystick/drag/pinch arbitration, modal controls and gesture release, safe areas at supported aspect ratios, app suspend/resume/process kill, storage failures and upgrade continuity.
- Actual rendered visual/animation/audio review: seasonal tile transitions, actor/weapon contacts, six skill cues, boss dodge windows, high-density weather/loot and phone readability. No screenshot or listening certification is claimed.
- Performance on representative Android hardware, lowest viable/borderline boss loadouts, natural first prestige, daily mission duration and long-run source/sink affordability. Correcting the draft exponent and passing a maximum-loadout bound do not establish balanced pacing.
- Asset provenance, localization release workflow, signed artifact testing and store/marketing work. No signing credentials or caches are in the patch.
