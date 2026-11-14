"""Change 78 boss investigation, power ladder: per stage, rungs r=0..9 from stage arrival to well past the boss
level. Each rung raises level, weapon/outfit merges, stored-outfit merges, skill merges and supply mastery
together, with auto supplies and auto skills (the 'supported' policy) and P0 / P1 variants at chosen rungs."""
import json, sys, importlib.util
from pathlib import Path
ROOT = Path(__file__).resolve().parents[3]
spec = importlib.util.spec_from_file_location("b78", ROOT / "tests/tmp/c78/builds.py")
sys.argv = [sys.argv[0], str(ROOT / "tests/tmp/c78/_unused.json")] + sys.argv[1:]
b78 = importlib.util.module_from_spec(spec); spec.loader.exec_module(b78)
pfa = b78.pfa; build = pfa.build; G = pfa.G
TIER_W = {1: "wood", 2: "stone", 3: "iron", 4: "gold", 5: "diamond", 6: "emerald", 7: "obsidian", 8: "obsidian"}
PREV_BOSS_OUT = {1: "unit-chef-hat_outfit", 2: "boss-snowman_outfit", 3: "boss-cyan-robot_outfit", 4: "boss-gray-cat_outfit_t2",
                 5: "boss-teal-dinosaur_outfit_t2", 6: "boss-red-fox_outfit_t3", 7: "boss-grim-reaper_outfit_t3", 8: "boss-bee_outfit_t4"}
SKILLS = {1: [], 2: ["skill_heal"], 3: ["skill_heal"], 4: ["skill_heal", "skill_frost"], 5: ["skill_heal", "skill_fire"],
          6: ["skill_heal", "skill_fire", "skill_lightning"], 7: ["skill_heal", "skill_fire", "skill_strike"], 8: ["skill_heal", "skill_fire", "skill_strike"]}
RUNGS = 10
def lerp(a, b, t): return a + (b - a) * t
B = []
for st in range(1, 9):
    normals = b78.normals(st); bosses = [g for g in G if g["stage"] == st and g["boss"] and not g.get("final")]
    lo = min(g["level"] for g in normals); hi = max(g["level"] for g in bosses)
    enc = b78.encounters(st)
    for r in range(RUNGS):
        t = r / (RUNGS - 1)            # 0 = arrival ... 1 = well past the boss
        L = int(round(lerp(lo, hi * 1.25, t)))
        wcap = 100 if st >= 7 else 20
        wm = int(round(lerp(0, wcap, min(1, t * 1.6))))
        weapon = [TIER_W[st] + "_sword", wm]
        om = int(round(lerp(10, 300, t)))
        outfit = [PREV_BOSS_OUT[st], om]
        stored = [[x[0], int(round(lerp(5, 120, t)))] for x in b78.stored(st, 0)]
        if st > 1: stored.append([TIER_W[st - 1] + "_sword", 20] if TIER_W[st - 1] != TIER_W[st] else ["obsidian_axe", 60])
        sk = [[s, int(round(lerp(0, 60, t)))] for s in SKILLS[st]]
        m = int(round(lerp(2 + 2 * st, 20 + 8 * st, t)))
        sup = {"potion": [m, 40], "guard_tonic": [m, 15], "recovery_salve": [m, 15]} if st >= 3 else {"potion": [m, 20]}
        auto = ["potion", "guard_tonic", "recovery_salve"] if st >= 3 else ["potion"]
        for pre in ((0, 1) if r in (3, 6, 9) else (0,)):
            bid = f"L{st}_r{r}" + ("_P1" if pre else "")
            B.append(build(bid, st, L, weapon, outfit, f"Stage {st} ladder rung {r}: L{L}, {weapon[0]} ^{wm}, {outfit[0]} ^{om}, P{pre}",
                           stored=stored, skills=sk, supplies=sup, auto=auto, cast="auto", encounters=enc, prestiges=pre))
            B[-1]["ladder"] = f"S{st}"; B[-1]["rung"] = r
out = Path(sys.argv[2]) if len(sys.argv) > 2 else ROOT / "tests/tmp/c78/ladder_c78.json"
data = {"seeds": [1, 2], "card_sets": pfa.CARD_SETS, "builds": B}
out.write_bytes((json.dumps(data, indent=1) + "\n").encode("utf-8"))
print(len(B), "builds", sum(len(b["encounters"]) * 2 for b in B), "trials")
