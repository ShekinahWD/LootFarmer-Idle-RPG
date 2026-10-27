# Change 17 — validation, performance and balance limits

Date: 27 October 2026. Final engine: **Godot 4.7.2 stable, ed1daf0bf, Linux headless**, matching the project's 4.7 generation. Initial implementation checks also ran under 4.6.1; final evidence below uses 4.7.2. No Android export or physical-device test is claimed.

## Maintained gates

**27/27 entries currently passing:** source validation plus 26 headless probes. New coverage: **679 gameplay checks** and **60 weather-equivalence checks**. Static validation: **1,557 checks, zero failures**. Final editor import/compile on 4.7.2 had no script errors.

The full 4.7.2 run returned 26/27: the newly added legacy-timer assertion allowed only 1.9 milliseconds of wall-clock movement during restore, but the actual load legitimately took about 3.7 ms. Its tolerance is now 0.5 seconds (the separate simulated-time assertions remain exact). The targeted rerun of this probe plus the source validator passed 2/2. No production code was changed to satisfy that test. Raw full-run and rerun logs are both included; the current individual gameplay log is the passing rerun.

Earlier 4.6.1 full-run failures were superseded contracts: Potion below 100% instead of 80%, use_speed and auto_use prices, six 20-second cooldowns, new Heal/Focus values, and a fixture binding an automatic supply slot without owning it. Only those affected tests were updated. UI skill-description checks no longer certify the deliberately deferred Heal threshold prose; that integration is listed explicitly for Claude.

Coverage includes:

- Every level/cost/cap of both critical upgrades and capped effective stats.
- First automatic capacity assigned to the third equipped slot; atomic reassignment, duplicates/out-of-range/fractional/empty slots, pause lock, saved legacy capacity and Prestige.
- All five supplies purchased/collected without mastery; five successful uses per level; blocked uses; cooldown and mastery caps; automatic healing outside combat; full health; legacy credit and five-use remainder.
- All 42 current/legacy skill identities at ^0/^100/^250/^500, effective cast values, large surplus stock, actual Heal/Fire casts, Fire after a large Focus bonus, cooldown upgrades, Lightning target/attack cooldown/windup/partial expiry, unchanged movement and actual Frost/Lightning boss resistance.
- Boss Gem base for all 48 types; additive upgrade chance; boss countdown home position, pause, inactive maps, elapsed restart time, expiry/spawn, two independent bosses and old actor-only timer migration.
- All eight mission stage multipliers, 40/80-kill Coin equivalents, reward bonuses once, repeated refresh, early-map visit, actual claim and rejection of a second claim.
- Real disk save/load, repeated migration, malformed new state, actual Prestige transaction, Hard Reset and disk reload.
- Original versus optimized particle arrays at ten times and two camera rectangles for each of all three weather styles (60 exact comparisons).

Run the gates with `GODOT=<Godot console executable> python tools/run_probes.py`. Optional `PROBE_LOG_DIR` records individual logs. The separate balance and performance probes are deliberately not gates.

## Rain investigation

The original weather uses a single Node2D drawing a repeated world-space field, not CPUParticles2D/GPUParticles2D. Rain has 64 particles per 440×500 cell (leaves are sparser); its 15-frame 52×216 sheet runs at 10 fps, drawn as 26×108 quads. Splash starts at frame 9 and freezes drift. There are no separate splash nodes or splash allocations; splash is the later sheet frames.

Original work per draw: build nested arrays for every visible particle, repeat modulo/frame/drift calculations for every grid cell, and call full campaign visibility (including vision bonus derivation) for each particle. New drawing reuses packed pattern buffers, computes one pattern per frame, avoids per-particle result arrays in production, and snapshots visibility inputs once. The compatibility `particles()` diagnostic still returns arrays.

**Same-process weather CPU benchmark, 300 frames, 3000×2200 world rectangle:** original 312,431 μs; optimized 161,104 μs (**48.4% less time**, ratio 0.516). This measures particle generation, not total frame time. The diagnostic path still allocates result arrays, so it does not measure the extra allocation savings of production drawing.

Separate simulation-only samples (600 steps/map, no renderer) show other work matters: Winter I has 28 enemies, Summer II 62, Spring II 69. The baseline measured roughly 0.79 / 1.26 / 1.53 ms per step for those maps; the new run measured 0.66 / 1.51 / 2.30 ms. These short samples include campaign/fog/reward work and host scheduling noise; they do **not** establish an overall simulation speedup. Rain itself does not run inside these simulation steps. New status/reward logic also adds work. Logs for all eight maps and both versions are included.

Overdraw remains the same translucent quad count/size; no unverified density, opacity, animation or splash cuts were made. CPU and GPU timing on the reported Android device remains unresolved. Reproduce identical map/camera/loadout with weather on/off on device, capture CPU/GPU frame time and draw calls, and compare normal combat versus a quiet camp. This distinguishes weather fill-rate from the much larger late-stage actor workload. No mobile FPS improvement or full-game performance fix is claimed.

## Late-game balance: unresolved, developer review required

Ran the existing non-gating `change_9_balance` against the untouched latest attachment and this patch with the same Godot 4.7.2 engine and deterministic fixture seed. Original: **34/35**. Change 17: **33/35**. The original already failed the ^300 final-boss target; Change 17 additionally fails the Red Panda ^500 target.

| Existing fixture | Original attachment | Change 17 |
|---|---|---|
| Red Panda, ^300 outfit, six cards | Win, 82 s | Win, 160 s |
| Red Panda, ^500 outfit, four cards | Win, 82 s | Loss, boss 39.1% HP remaining |
| Final boss, ^300 outfit, four cards | Loss, boss 3.0% HP remaining | Loss, boss 57.8% HP remaining |
| Final boss, ^500 outfit, four cards | Win, 74 s | Loss, boss 17.4% HP remaining |

These are deterministic combat fixtures, **not a campaign playthrough**. Their player skills are ^50, and they omit the new critical upgrades, supply automation and broader alternate loadouts. The result nevertheless demonstrates a substantial difficulty increase with the prescribed cooldown/power changes. No enemy nerf, hidden skill boost or weakened benchmark assertion was introduced. Developer approval is needed before a separate boss/pacing rebalance; the requested skill values remain intact.

## Pending acceptance

- Claude's UI, tutorial and localization work listed in the integration contract.
- Physical Android rain/performance and visual comparison; GPU bottleneck attribution.
- Late-game progression/boss tuning decision, informed by the benchmark above and actual play.
- Save interruption at OS write and exported-release device checks remain release gates, as before.
