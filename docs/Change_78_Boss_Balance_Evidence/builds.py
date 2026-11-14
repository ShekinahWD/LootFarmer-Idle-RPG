"""Change 78 boss investigation builds for tests/player_feedback_audit.tscn (current catalog, H24 weapon ladder).
Stage N gear: tier-N weapon (H24: stage N drops tier N; evolvable weapons merge to ^20, Obsidian to ^100),
the previous boss's outfit or the stage's own outfits (copy growth to ^500), stored items at 30%/15%."""
import json, sys, importlib.util
from pathlib import Path
ROOT = Path(__file__).resolve().parents[3]
spec = importlib.util.spec_from_file_location("pfa", ROOT / "tools/player_feedback_audit_builds.py")
pfa = importlib.util.module_from_spec(spec); spec.loader.exec_module(pfa)
G = pfa.G; build = pfa.build
def gid(i): return [g for g in G if g["id"] == i][0]
def normals(st): return [g for g in G if g["stage"] == st and not g["boss"]]
def bosses(st): return [g for g in G if g["stage"] == st and g["boss"]]
def outfit(g): return [x for x in g["loot"] if x.endswith("_outfit") or "_outfit_t" in x][0]
VAR = lambda g: [0, 1, 2, 3] if g["skills"] else [0, 1, 2]

def per_actor(g, v):
    c = pfa.CAT["progression"]["combat"]
    d = g["damage"] * {0: .75, 1: 1.25, 2: 1.0, 3: c["skill_variant_damage"]}[v] * float(c["normal_damage_scale"].get(str(g["stage"]), 1.0))
    return d / g["interval"]

def encounters(st):
    enc = [{"kind": "boss", "group": b["id"], "limit": 600} for b in bosses(st) if not b.get("final")]
    ranked = sorted(((per_actor(g, v), g["id"], v) for g in normals(st) for v in VAR(g)), reverse=True)
    picks = []
    for _, i, v in ranked:
        if (i, v) not in picks: picks.append((i, v))
        if len(picks) == 2: break
    for i, v in picks:
        enc.append({"kind": "spot", "group": i, "variant": v, "count": 3, "limit": 300})
        enc.append({"kind": "spot", "group": i, "variant": v, "count": 6, "limit": 300})
    return enc

S = {  # stage: (arrive L, arrive weapon, arrive outfit, ready L, ready weapon, ready outfit, skills)
 1: (1, [], [], 8, ["wood_axe", 10], ["unit-chef-hat_outfit", 10], []),
 2: (9, ["wood_axe", 20], ["boss-snowman_outfit", 10], 20, ["stone_sword", 20], ["boss-snowman_outfit", 30], [["skill_heal", 0]]),
 3: (21, ["stone_sword", 20], ["boss-cyan-robot_outfit", 20], 35, ["iron_axe", 20], ["boss-cyan-robot_outfit", 40], [["skill_heal", 5]]),
 4: (36, ["iron_axe", 20], ["boss-gray-cat_outfit_t2", 20], 60, ["gold_sword", 20], ["boss-gray-cat_outfit_t2", 60], [["skill_heal", 10], ["skill_frost", 5]]),
 5: (62, ["gold_sword", 20], ["boss-teal-dinosaur_outfit_t2", 40], 90, ["diamond_sword", 20], ["boss-teal-dinosaur_outfit_t2", 80], [["skill_heal", 20], ["skill_fire", 10]]),
 6: (92, ["diamond_sword", 20], ["boss-red-fox_outfit_t3", 40], 135, ["emerald_sword", 20], ["boss-red-fox_outfit_t3", 80], [["skill_heal", 30], ["skill_fire", 20], ["skill_lightning", 10]]),
 7: (137, ["emerald_sword", 20], ["boss-grim-reaper_outfit_t3", 60], 190, ["obsidian_axe", 40], ["boss-grim-reaper_outfit_t3", 100], [["skill_heal", 40], ["skill_fire", 30], ["skill_strike", 20]]),
 8: (192, ["obsidian_axe", 40], ["boss-bee_outfit_t4", 60], 235, ["obsidian_sword", 60], ["boss-bee_outfit_t4", 100], [["skill_heal", 50], ["skill_fire", 40], ["skill_strike", 30]]),
}
def stored(st, merge):
    # the stage's own normal outfits (farmed) and the previous stage's, a few copies merged
    out = [[outfit(g), merge] for g in normals(st)]
    if st > 1: out += [[outfit(g), merge] for g in normals(st - 1)]
    return out[:10]
B = []
for st, (aL, aw, ao, rL, rw, ro, sk) in S.items():
    enc = encounters(st)
    sup = {"potion": [10 + 5 * st, 30], "guard_tonic": [5 + 3 * st, 10], "recovery_salve": [5 + 3 * st, 10]} if st >= 3 else {"potion": [5 * st, 10]}
    auto = ["potion", "guard_tonic", "recovery_salve"] if st >= 3 else ["potion"]
    # raw: no supplies, no skills (the encounter's own threat); supported: auto supplies + auto skills
    B.append(build(f"S{st}_arrive_raw", st, aL, aw, ao, f"Stage {st} arrival L{aL}, raw (no supplies/skills)", stored=stored(st - 1, 10) if st > 1 else [], supplies={}, policy="casual", encounters=enc, prestiges=0))
    B.append(build(f"S{st}_ready_raw", st, rL, rw, ro, f"Stage {st} boss-ready L{rL}, raw", stored=stored(st, 20), supplies={}, policy="casual", encounters=enc, prestiges=0))
    B.append(build(f"S{st}_ready_sup", st, rL, rw, ro, f"Stage {st} boss-ready L{rL}, auto supplies + auto skills", stored=stored(st, 20), skills=sk, supplies=sup, auto=auto, cast="auto", encounters=enc, prestiges=0))
    B.append(build(f"S{st}_ready_P1_raw", st, rL, rw, ro, f"Stage {st} boss-ready L{rL} + 1 Prestige (7 boss-leaning cards), raw", stored=stored(st, 20), supplies={}, policy="casual", encounters=enc, prestiges=1))
out = Path(sys.argv[1])
data = {"seeds": [1, 2, 3], "card_sets": pfa.CARD_SETS, "builds": B}
out.write_bytes((json.dumps(data, indent=1) + "\n").encode("utf-8"))
print(len(B), "builds", sum(len(b["encounters"]) * 3 for b in B), "trials")
