# Change 5 validation

Target engine actually used: Godot 4.7.stable.official.5b4e0cb0f, Linux. Source imported and executed with this engine. No Android release package was built.

| Check | Result | Evidence |
|---|---:|---|
| Correction probe | 137 checks, 0 failures | Change_5_Evidence/change_5_probe.log |
| Campaign regression | 260 checks, 0 failures | Change_5_Evidence/campaign_probe.log |
| Content regression | 655 checks, 0 failures | Change_5_Evidence/campaign_content_probe.log |
| Static catalog/source | 1,778 checks, 0 failures | Change_5_Evidence/static_checks.json |
| Actual rendered frames | 8 captured and reviewed | Change_5_Evidence/*.png |

The campaign log includes an expected `save_read_only` warning from an intentional write-failure injection. It verifies rollback; it is not a normal fresh-profile save failure. Other final probe logs contain no script errors. Current-schema disk serialization and reload are exercised, including currency, items, tutorial, discovery and integer membership arrays. Old development schema and malformed discovery records reset to writable profiles.

Healing checks sample all seven tiers at merge 0, 50 and 100. Potion burst remains more than twice effective Heal recovery at each sample; casts preserve skill stock and obey cooldown/HP cap. Potions consume exactly one copy, work during skill cooldown and do not waste stock at full HP. These checks establish role separation, not a guarantee of satisfying natural progression balance.

Opening tests check first-two-type passive individual retaliation, stage-1 skill absence, authored boss scales, skill layers, fog camera invariance, movement segments, invalid bounds and dead sources. UI checks instantiate nine routes and exercise tutorial choice, panel arbitration and reset. Existing campaign/content tests retain transaction, prestige, mission, offline, item and upper-loadout checks.

Rendered captures use Godot's Compatibility renderer with software OpenGL at 450×800. They show onboarding, first lesson, mission cards, enemy upgrades, achievements, boss arena, map and potion details. Capture fixtures deliberately seed representative inventory/progress; they do not represent a natural play session. Only existing game assets appear. Frame slice defects found during review were corrected before final captures.

To reproduce from the project root:

```sh
godot --headless --path . tests/change_5_probe.tscn -- --probe --profile=probe-change5 --no-autosave
godot --headless --path . tests/campaign_probe.tscn -- --probe --profile=probe-campaign5 --no-autosave
godot --headless --path . tests/campaign_content_probe.tscn -- --probe --profile=probe-content5 --no-autosave
python tools/validate_campaign_source.py
```

Use a rendered display for `tests/change_5_capture.tscn`, with `--probe --profile=capture-change5 --no-autosave`.

Outstanding: physical Android touch, safe areas, lifecycle/OS-interrupted writes, device performance/audio, all visual states and aspect ratios, full localization, low-loadout combat, natural first-prestige pacing and release signing/template QA. The full playbook audit also identifies unfinished source architecture/first-profile gate work. Neither the seeded ceiling test nor this patch certifies those gates.
