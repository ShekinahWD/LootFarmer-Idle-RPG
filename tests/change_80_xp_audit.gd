extends "res://tests/player_feedback_audit.gd"
## Change 80 XP farming measurement (non-gating; never in tools/run_probes.py). The player-feedback audit
## harness unchanged, except that Focused Farming (a single global Player upgrade since Change 65, which that
## harness still tried to buy per enemy type) is set directly as a labelled fixture. Run on HEAD and on Change 80
## with docs/Change_80_Evidence/xp_farm_builds.json; see docs/Change_80_Evidence/README.md.
func buy(id: String,times: int,group:=-1) -> bool:
    if id=="focus":
        sim.state.upgrades["focus"]=1 # fixture: Focused Farming owned (global upgrade)
        return true
    return super.buy(id,times,group)
