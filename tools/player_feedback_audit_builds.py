"""Player-feedback balance audit (2026-11-06): writes the four build-definition files read by
tests/player_feedback_audit.tscn, from the live catalog. Default output: docs/Player_Feedback_Audit_Evidence/.

  python tools/player_feedback_audit_builds.py [--out DIR]

Files: builds_main.json (eight-stage matrix, ladders, neighbours, farm rates), builds_supplementary.json
(hand-play arrivals, guaranteed-gear arrival, sustained 6-actor Summer I farms), builds_whatif.json
(cap3 / desync / v3_115 counterfactuals), builds_whatif_spring.json (Spring normal damage x0.75 / x0.60).
Regenerating against an unchanged catalog reproduces the committed baseline files exactly
(tools/player_feedback_audit_analyze.py builds-check). A catalog change changes the builds too: compare
like with like (Playbook 112.1: same harness, builds and seeds before and after).

Every build is a constructed fixture (evidence class 1, Playbook 112.2): level, merge levels, lifetime
kill counts (achievement bonuses), supply mastery and stock are seeded stand-ins for play time; Prestige
cards come from the game's real Prestige transaction over a named opportunity set.
"""
import json, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CAT = json.loads((ROOT / "data/game/catalog.json").read_text(encoding="utf-8"))
G = CAT["groups"]
SEEDS = [1, 2, 3]

CARD_SETS = {
    # First run that reached Summer I: the boss-leaning picks a boss-rushing player would make.
    "p1": {"ready": ["hunter_o1", "trophy_o1", "challenge_o1", "expedition_o1", "arsenal_o1", "regional_o1", "offering_o1"],
           "picks": ["hunter_c1", "trophy_c2", "challenge_c2", "expedition_c1", "arsenal_c1", "regional_c1", "offering_c1"]},
    # Second run (stages 1-3 again): Gray Cat x20, Summer I kill chain, first missions, a ^100 merge.
    "p2": {"ready": ["hunter_o2", "expedition_o2", "specialist_o1", "masterwork_o1"],
           "picks": ["hunter_c2", "expedition_c3", "specialist_c3", "masterwork_c3"]},
    # Third run: more missions and the Winter contract.
    "p3": {"ready": ["specialist_o2", "collection_o1"],
           "picks": ["specialist_c1", "collection_c2"]},
}
PRESTIGE = {0: [], 1: ["p1"], 3: ["p1", "p2", "p3"]}


def groups_of(stage):
    return [g for g in G if g["stage"] == stage and not g.get("final")]


def variants(g):
    return [2] if g["boss"] else ([0, 1, 2, 3] if g["skills"] else [0, 1, 2])


def stage_encounters(stage, six=True):
    """Every normal variant spot (3 actors), the strongest type's two most dangerous spots at 6 actors,
    one single actor of the strongest type, and every non-final boss."""
    enc = []
    normals = [g for g in groups_of(stage) if not g["boss"]]
    for g in normals:
        for v in variants(g):
            enc.append({"kind": "spot", "group": g["id"], "variant": v, "count": 3, "limit": 300})
    top = max(normals, key=lambda g: g["level"])
    if six:
        for v in ([1, 3] if top["skills"] else [1, 2]):
            enc.append({"kind": "spot", "group": top["id"], "variant": v, "count": 6, "limit": 300})
    enc.append({"kind": "single", "group": top["id"], "variant": 1, "limit": 300})
    for g in groups_of(stage):
        if g["boss"]:
            enc.append({"kind": "boss", "group": g["id"], "limit": 600})
    return enc


def kills_for(stage, prestiges, boss_first=True):
    """Lifetime kills (achievements +5% damage per milestone vs that type). Normal types of earlier
    stages 250 (3 milestones), current stage 100 (2). Earlier bosses: 3 kills each (2 milestones).
    This stage's bosses: 0 (first attempt). Prestige runs add the boss kills their opportunities needed."""
    k = {}
    for g in G:
        if g.get("final"):
            continue
        if g["stage"] < stage:
            k[g["id"]] = 3 if g["boss"] else 250
        elif g["stage"] == stage and not g["boss"]:
            k[g["id"]] = 100
    if prestiges >= 1:
        k["boss-snowman"] = max(k.get("boss-snowman", 0), 12)
        if stage > 2:
            k["boss-cyan-robot"] = max(k.get("boss-cyan-robot", 0), 3)
    if prestiges >= 3 and stage >= 3:
        k["boss-gray-cat"] = 21  # hunter_o2 needs 20 Gray Cat kills after discovery (earlier run)
    return k


def build(id_, stage, level, weapon, outfit, label, prestiges=0, stored=None, skills=None, supplies=None,
          potion_at=0.4, cast="manual", auto=None, encounters=None, kills=None, policy="attentive", extra=None):
    b = {"id": id_, "label": label, "stage": stage, "level": level, "prestige": PRESTIGE[prestiges],
         "weapon": weapon, "outfit": outfit, "stored": stored or [], "skills": skills or [],
         "supplies": supplies or {}, "potion_at": potion_at if policy == "attentive" else 0.0,
         "cast": cast if policy == "attentive" or cast == "auto" else "none", "auto": auto or [],
         "kills": kills if kills is not None else kills_for(stage, prestiges),
         "policy": policy, "prestiges": prestiges,
         "evidence": "constructed fixture (seeded level/merges/kills/supplies; Prestige via real transaction)",
         "encounters": encounters if encounters is not None else stage_encounters(stage)}
    if extra:
        b.update(extra)
    return b


def ladder(prefix, stage, levels, encounters, **kw):
    out = []
    for L in levels:
        out.append(build(f"{prefix}_L{L}", stage, L, encounters=encounters, **kw))
        out[-1]["ladder"] = prefix
    return out


B = []
P = lambda n, m: {"potion": [m, n]}

# ------------------------------------------------------------------ Winter I
B.append(build("W1_L1_bare", 1, 1, [], [], "Winter I arrival: level 1, nothing equipped", supplies={}, policy="attentive"))
B.append(build("W1_L5_wood5", 1, 5, ["wood_sword", 5], ["unit-red-scarf_outfit", 5], "Winter I mid: L5, Wood Sword ^5, Red Scarf ^5", supplies=P(3, 0)))
B.append(build("W1_L9_wood20", 1, 9, ["wood_axe", 20], ["unit-chef-hat_outfit", 20], "Winter I boss-ready: L9, Wood Axe ^20, Chef ^20", supplies=P(5, 3)))
B.append(build("W1_L9_wood20_casual", 1, 9, ["wood_axe", 20], ["unit-chef-hat_outfit", 20], "same, casual (no potions/skills)", supplies=P(5, 3), policy="casual"))

# ------------------------------------------------------------------ Winter II
w2_normal = dict(weapon=["stone_axe", 0], outfit=["unit-santa-hat_outfit", 60], stored=[["wood_axe", 100], ["wood_sword", 40]])
w2_snow = dict(weapon=["stone_axe", 30], outfit=["boss-snowman_outfit", 30], stored=[["wood_axe", 40]])
B.append(build("W2_L10_arrive", 2, 10, ["stone_axe", 0], ["unit-chef-hat_outfit", 20], "Winter II arrival: L10, Stone Axe ^0 (first Snowman kill), Chef ^20", stored=[["wood_axe", 20]], supplies=P(8, 5)))
B.append(build("W2_L16_normal", 2, 16, label="Winter II farmed normal path: L16, Stone Axe ^0 + stored Wood Axe ^100, Santa Hat ^60, Heal ^0", skills=[["skill_heal", 0]], supplies=P(10, 10), **w2_normal))
B.append(build("W2_L16_snow", 2, 16, label="Winter II Snowman carry: L16, Stone Axe ^30, Snowman ^30, Heal ^0", skills=[["skill_heal", 0]], supplies=P(10, 10), **w2_snow))
B.append(build("W2_L16_snow_casual", 2, 16, label="same Snowman carry, casual", skills=[["skill_heal", 0]], supplies=P(10, 10), policy="casual", **w2_snow))
B.append(build("W2_L20_snow", 2, 20, ["stone_axe", 40], ["boss-snowman_outfit", 40], "Winter II boss-level: L20, Stone Axe ^40, Snowman ^40, Heal ^5", stored=[["wood_axe", 40]], skills=[["skill_heal", 5]], supplies=P(10, 12)))
B.append(build("W2_L20_snow_P1", 2, 20, ["stone_axe", 40], ["boss-snowman_outfit", 40], "same + 1 Prestige (7 boss-leaning cards)", prestiges=1, stored=[["wood_axe", 40]], skills=[["skill_heal", 5]], supplies=P(10, 12)))

# ------------------------------------------------------------------ Summer I
s3_snow28 = dict(weapon=["stone_axe", 60], outfit=["boss-snowman_outfit", 60], stored=[["wood_axe", 60], ["stone_sword", 20]])
s3_norm28 = dict(weapon=["stone_axe", 60], outfit=["unit-yellow-cap_outfit_t2", 40], stored=[["wood_axe", 60], ["stone_sword", 20]])
B.append(build("S3_L22_arrive", 3, 22, ["stone_axe", 30], ["boss-snowman_outfit", 30], "Summer I arrival: L22, Stone Axe ^30, Snowman ^30, Heal ^5", stored=[["wood_axe", 40], ["stone_sword", 0]], skills=[["skill_heal", 5]], supplies=P(10, 10)))
B.append(build("S3_L28_normal", 3, 28, label="Summer I farmed normal outfit: L28, Stone Axe ^60, Yellow Cap t2 ^40, Heal ^10", skills=[["skill_heal", 10]], supplies=P(10, 15), **s3_norm28))
B.append(build("S3_L28_snow", 3, 28, label="Summer I Snowman carry: L28, Stone Axe ^60, Snowman ^60, Heal ^10", skills=[["skill_heal", 10]], supplies=P(10, 15), **s3_snow28))
B.append(build("S3_L28_snow_casual", 3, 28, label="same Snowman carry, casual", skills=[["skill_heal", 10]], supplies=P(10, 15), policy="casual", **s3_snow28))
B.append(build("S3_L28_snow_P3", 3, 28, label="Snowman carry + 3 Prestiges (13 cards; reported pattern)", prestiges=3, skills=[["skill_heal", 10]], supplies=P(10, 15), **s3_snow28))
B.append(build("S3_L35_normal", 3, 35, ["stone_axe", 100], ["unit-yellow-cap_outfit_t2", 80], "Summer I boss-level normal: L35, Stone Axe ^100, Yellow Cap t2 ^80, Heal ^15", stored=[["wood_axe", 60], ["stone_sword", 40]], skills=[["skill_heal", 15]], supplies=P(12, 20)))
B.append(build("S3_L35_snow", 3, 35, ["stone_axe", 100], ["boss-snowman_outfit", 80], "Summer I boss-level Snowman: L35, Stone Axe ^100, Snowman ^80, Heal ^15", stored=[["wood_axe", 60], ["stone_sword", 40]], skills=[["skill_heal", 15]], supplies=P(12, 20)))
B.append(build("S3_L35_snow_P1", 3, 35, ["stone_axe", 100], ["boss-snowman_outfit", 80], "same + 1 Prestige", prestiges=1, stored=[["wood_axe", 60], ["stone_sword", 40]], skills=[["skill_heal", 15]], supplies=P(12, 20)))
B.append(build("S3_L35_snow_P3", 3, 35, ["stone_axe", 100], ["boss-snowman_outfit", 80], "same + 3 Prestiges", prestiges=3, stored=[["wood_axe", 60], ["stone_sword", 40]], skills=[["skill_heal", 15]], supplies=P(12, 20)))

# ------------------------------------------------------------------ Stages 4-8 (lighter)
sup = lambda m, n: {"potion": [m, n], "guard_tonic": [m, max(3, n // 3)], "recovery_salve": [m, max(3, n // 3)]}
late = [
    # stage, arrival level, arrival weapon/outfit, ready level, ready weapon/outfit, skills
    (4, 38, ["iron_axe", 20], ["boss-gray-cat_outfit_t2", 20], 60, ["iron_axe", 60], ["boss-gray-cat_outfit_t2", 60], [["skill_heal", 20], ["skill_frost", 10]]),
    (5, 65, ["iron_sword", 30], ["boss-teal-dinosaur_outfit_t2", 40], 95, ["iron_axe", 100], ["unit-mushroom-cap_outfit_t3", 60], [["skill_heal", 30], ["skill_fire", 20]]),
    (6, 95, ["gold_sword", 20], ["boss-red-fox_outfit_t3", 30], 140, ["gold_sword", 80], ["boss-red-fox_outfit_t3", 80], [["skill_heal", 30], ["skill_fire", 30], ["skill_lightning", 20]]),
    (7, 140, ["gold_sword", 80], ["boss-grim-reaper_outfit_t3", 60], 195, ["gold_axe", 100], ["unit-elf-ears_outfit_t4", 60], [["skill_heal", 40], ["skill_fire", 40], ["skill_strike", 30]]),
    (8, 195, ["diamond_axe", 30], ["boss-bee_outfit_t4", 40], 240, ["diamond_sword", 100], ["unit-pink-cap_outfit_t5", 60], [["skill_heal", 50], ["skill_fire", 50], ["skill_strike", 50]]),
]
for st, aL, aw, ao, rL, rw, ro, sk in late:
    m_a, m_r = 10 + 4 * st, 15 + 5 * st
    B.append(build(f"S{st}_L{aL}_arrive", st, aL, aw, ao, f"Stage {st} arrival: L{aL}, previous boss gear", skills=sk[:2], supplies=sup(m_a, 20), auto=["potion", "guard_tonic", "recovery_salve"], cast="auto", prestiges=1))
    B.append(build(f"S{st}_L{rL}_ready_P0", st, rL, rw, ro, f"Stage {st} boss-level, no Prestige", skills=sk, supplies=sup(m_r, 30), auto=["potion", "guard_tonic", "recovery_salve"], cast="auto", prestiges=0))
    B.append(build(f"S{st}_L{rL}_ready_P1", st, rL, rw, ro, f"Stage {st} boss-level, 1 Prestige", skills=sk, supplies=sup(m_r, 30), auto=["potion", "guard_tonic", "recovery_salve"], cast="auto", prestiges=1))

# ------------------------------------------------------------------ ladders, first three bosses
def lad_enc(stage, boss, spots):
    e = [{"kind": "boss", "group": boss, "limit": 600}]
    for gid, v, n in spots:
        e.append({"kind": "spot", "group": gid, "variant": v, "count": n, "limit": 300})
    return e

e1 = lad_enc(1, "boss-snowman", [("unit-chef-hat", 1, 3), ("unit-chef-hat", 1, 6)])
B += ladder("LAD_W1_wood", 1, range(3, 15), e1, weapon=["wood_axe", 10], outfit=["unit-chef-hat_outfit", 10], label="Snowman ladder: Wood Axe ^10, Chef ^10, 5 potions", supplies=P(5, 0))
B += ladder("LAD_W1_wood_casual", 1, range(3, 15), e1, weapon=["wood_axe", 10], outfit=["unit-chef-hat_outfit", 10], label="Snowman ladder casual", supplies=P(5, 0), policy="casual")

e2 = lad_enc(2, "boss-cyan-robot", [("unit-space-helmet", 1, 3), ("unit-space-helmet", 3, 3), ("unit-santa-hat", 1, 3), ("unit-space-helmet", 1, 6)])
B += ladder("LAD_W2_normal", 2, range(8, 27, 2), e2, label="Robot ladder normal path (Stone Axe ^0, Santa ^60, Heal ^0, 10 potions)", skills=[["skill_heal", 0]], supplies=P(10, 10), **w2_normal)
B += ladder("LAD_W2_snow", 2, range(8, 27, 2), e2, label="Robot ladder Snowman (Stone Axe ^30, Snowman ^30)", skills=[["skill_heal", 0]], supplies=P(10, 10), **w2_snow)
B += ladder("LAD_W2_snow_casual", 2, range(8, 27, 2), e2, label="Robot ladder Snowman casual", skills=[["skill_heal", 0]], supplies=P(10, 10), policy="casual", **w2_snow)
B += ladder("LAD_W2_snow_P1", 2, range(8, 27, 2), e2, label="Robot ladder Snowman + 1 Prestige", prestiges=1, skills=[["skill_heal", 0]], supplies=P(10, 10), **w2_snow)

e3 = lad_enc(3, "boss-gray-cat", [("unit-yellow-cap", 1, 3), ("unit-yellow-cap", 3, 3), ("unit-straw-hat", 3, 3), ("unit-sunglasses", 3, 3), ("unit-yellow-cap", 1, 6)])
for pre in (0, 1, 3):
    tag = "" if pre == 0 else f"_P{pre}"
    B += ladder(f"LAD_S3_snow{tag}", 3, range(20, 47, 2), e3, label=f"Gray Cat ladder Snowman (Stone Axe ^60, Snowman ^60, Heal ^10) P{pre}", prestiges=pre, skills=[["skill_heal", 10]], supplies=P(10, 15), **s3_snow28)
B += ladder("LAD_S3_normal", 3, range(20, 47, 2), e3, label="Gray Cat ladder normal outfit (Stone Axe ^60, Yellow Cap ^40)", skills=[["skill_heal", 10]], supplies=P(10, 15), **s3_norm28)
B += ladder("LAD_S3_snow_casual", 3, range(20, 47, 2), e3, label="Gray Cat ladder Snowman casual", skills=[["skill_heal", 10]], supplies=P(10, 15), policy="casual", **s3_snow28)

# ------------------------------------------------------------------ one-variable neighbours of the Gray Cat ladder (L30)
nb = lad_enc(3, "boss-gray-cat", [("unit-yellow-cap", 1, 3), ("unit-yellow-cap", 3, 3)])
base = dict(weapon=["stone_axe", 60], outfit=["boss-snowman_outfit", 60], stored=[["wood_axe", 60], ["stone_sword", 20]], skills=[["skill_heal", 10]], supplies=P(10, 15))
def nbuild(id_, label, **over):
    d = dict(base); d.update(over)
    return build(id_, 3, int(d.pop("level", 30)), encounters=nb, label=label, **d)
B.append(nbuild("NB_S3_base", "Neighbour base: L30 Stone Axe ^60, Snowman ^60, Heal ^10, 15 potions ^10"))
B.append(nbuild("NB_S3_noheal", "minus Heal", skills=[]))
B.append(nbuild("NB_S3_nopotion", "minus potions", supplies={}))
B.append(nbuild("NB_S3_axe0", "Stone Axe ^0", weapon=["stone_axe", 0]))
B.append(nbuild("NB_S3_snow0", "Snowman ^0", outfit=["boss-snowman_outfit", 0]))
B.append(nbuild("NB_S3_chef", "Chef Hat t1 ^20 instead of Snowman", outfit=["unit-chef-hat_outfit", 20]))
B.append(nbuild("NB_S3_sword", "Stone Sword ^20 instead of Stone Axe", weapon=["stone_sword", 20], stored=[["wood_axe", 60], ["stone_axe", 60]]))
B.append(nbuild("NB_S3_L26", "level 26", level=26))
B.append(nbuild("NB_S3_L34", "level 34", level=34))
B.append(nbuild("NB_S3_P1", "plus 1 Prestige", prestiges=1))
B.append(nbuild("NB_S3_P3", "plus 3 Prestiges", prestiges=3))

# ------------------------------------------------------------------ farm rates (economy)
farm_builds = [
    ("FARM_W1", 1, 9, ["wood_axe", 20], ["unit-chef-hat_outfit", 20], [], P(5, 3)),
    ("FARM_W2", 2, 16, ["stone_axe", 30], ["boss-snowman_outfit", 30], [["skill_heal", 0]], P(10, 30)),
    ("FARM_S3", 3, 30, ["stone_axe", 60], ["boss-snowman_outfit", 60], [["skill_heal", 10]], P(10, 40)),
    ("FARM_S4", 4, 52, ["iron_axe", 50], ["boss-gray-cat_outfit_t2", 50], [["skill_heal", 20], ["skill_frost", 10]], P(20, 40)),
]
for id_, st, L, w, o, sk, su in farm_builds:
    enc = [{"kind": "farm", "group": g["id"], "variant": 2, "minutes": 10, "seeds": [1]} for g in groups_of(st) if not g["boss"]]
    enc += [{"kind": "farm", "group": g["id"], "variant": 2, "minutes": 10, "seeds": [1]} for g in groups_of(st) if g["boss"]]
    B.append(build(id_, st, L, w, o, f"Farm rates stage {st}", skills=sk, supplies=su, encounters=enc))
# switching: the same farmer arriving at the next stage's first types (no upgrades bought there)
for id_, st, L, w, o, sk, su in [("FARM_SW_W2", 2, 10, ["stone_axe", 0], ["unit-chef-hat_outfit", 20], [], P(8, 30)),
                                  ("FARM_SW_S3", 3, 22, ["stone_axe", 30], ["boss-snowman_outfit", 30], [["skill_heal", 5]], P(10, 40))]:
    enc = [{"kind": "farm", "group": g["id"], "variant": 2, "minutes": 10, "seeds": [1]} for g in groups_of(st) if not g["boss"]]
    B.append(build(id_, st, L, w, o, f"Switch farm, stage {st} arrival", skills=sk, supplies=su, encounters=enc))


def supplementary():
    """Later-stage arrivals with hand play (no automation), the guaranteed-gear Summer I arrival and
    sustained real-respawn farming of Summer I spots. Baseline note: both FARM_S3v_* and FARM_S3v6_* farm
    6-actor spots (the original generator shared one encounter list); a 3-actor sustained Summer I farm is
    in builds_main.json (FARM_S3, both-loadout spots)."""
    out = []
    lt = [(4, 38, ["iron_axe", 20], ["boss-gray-cat_outfit_t2", 20], [["skill_heal", 20]]),
          (5, 65, ["iron_sword", 30], ["boss-teal-dinosaur_outfit_t2", 40], [["skill_heal", 30]]),
          (6, 95, ["gold_sword", 20], ["boss-red-fox_outfit_t3", 30], [["skill_heal", 30]]),
          (7, 140, ["gold_sword", 80], ["boss-grim-reaper_outfit_t3", 60], [["skill_heal", 40]]),
          (8, 195, ["diamond_axe", 30], ["boss-bee_outfit_t4", 40], [["skill_heal", 50]])]
    for st, L, w, o, sk in lt:
        for pre in (0, 1):
            out.append(build(f"S{st}_L{L}_arrive_manual_P{pre}", st, L, w, o, f"Stage {st} arrival, previous boss gear, Heal + potions by hand, P{pre}", skills=sk, supplies={"potion": [10 + 4 * st, 20]}, prestiges=pre))
    out.append(build("S3_L22_guaranteed", 3, 22, ["stone_axe", 0], ["unit-chef-hat_outfit", 20], "Summer I arrival, guaranteed gear only: L22 Stone Axe ^0, Chef ^20, Heal ^5", stored=[["wood_axe", 20]], skills=[["skill_heal", 5]], supplies={"potion": [10, 10]}))
    for L, tag in ((28, "L28"), (35, "L35")):
        enc = [{"kind": "farm", "group": gid, "variant": v, "minutes": 5, "seeds": [1, 2], "count": 6}
               for gid, v in (("unit-yellow-cap", 3), ("unit-yellow-cap", 1), ("unit-sunglasses", 3))]
        w = ["stone_axe", 60 if L == 28 else 100]; o = ["boss-snowman_outfit", 60 if L == 28 else 80]
        out.append(build(f"FARM_S3v_{tag}", 3, L, w, o, f"Summer I sustained farm {tag}, 3 actors", skills=[["skill_heal", 10]], supplies={"potion": [10, 40]}, encounters=enc))
        out.append(build(f"FARM_S3v6_{tag}", 3, L, w, o, f"Summer I sustained farm {tag}, 6 actors (spawn upgrades)", skills=[["skill_heal", 10]], supplies={"potion": [10, 40]}, encounters=enc, extra={"spawn6": True}))
    return out

WHATIF_PICKS = {
  "W2_L16_snow": [("unit-space-helmet", 3, 3), ("unit-space-helmet", 3, 6), ("boss-cyan-robot", 2, 1)],
  "S3_L28_snow": [("unit-yellow-cap", 3, 3), ("unit-yellow-cap", 1, 6), ("unit-yellow-cap", 3, 6), ("unit-sunglasses", 3, 3), ("boss-gray-cat", 2, 1)],
  "S3_L35_snow": [("unit-yellow-cap", 3, 3), ("unit-yellow-cap", 3, 6), ("boss-gray-cat", 2, 1)],
  "S5_L95_ready_P0": [("unit-pumpkin-head", 3, 3), ("unit-pumpkin-head", 3, 6), ("boss-red-fox", 2, 1)],
  "S6_L140_ready_P0": [("unit-top-hat", 1, 6), ("unit-television-head", 3, 3), ("boss-black-cat", 2, 1)],
  "S7_L195_ready_P1": [("unit-elf-ears", 3, 3), ("unit-elf-ears", 3, 6), ("unit-elf-ears", 1, 6), ("boss-bee", 2, 1)],
  "S8_L240_ready_P1": [("unit-sprout", 3, 3), ("unit-sprout", 3, 6), ("boss-red-panda", 2, 1)],
}

def whatif_builds(variants, picks=WHATIF_PICKS):
    base = {b["id"]: b for b in B}
    out = []
    for bid, encs in picks.items():
        for wi in variants:
            b = json.loads(json.dumps(base[bid])); b["id"] = bid + ("__" + "+".join(wi) if wi else "__base"); b["whatif"] = wi
            b["encounters"] = [{"kind": "boss" if gid.startswith("boss-") else "spot", "group": gid, "variant": v, "count": n,
                                "limit": 600 if gid.startswith("boss-") else 300} for gid, v, n in encs]
            out.append(b)
    return out

def write(path, builds):
    data = json.dumps({"seeds": SEEDS, "card_sets": CARD_SETS, "builds": builds}, indent=1)
    path.write_bytes((data + chr(10)).encode("utf-8"))
    print(f"{path.name}: {len(builds)} builds, {sum(sum(len(e.get('seeds', b.get('seeds', SEEDS))) for e in b['encounters']) for b in builds)} trials")

if __name__ == "__main__":
    out = Path(sys.argv[sys.argv.index("--out") + 1]) if "--out" in sys.argv else ROOT / "docs/Player_Feedback_Audit_Evidence"
    out.mkdir(parents=True, exist_ok=True)
    write(out / "builds_main.json", B)
    write(out / "builds_supplementary.json", supplementary())
    write(out / "builds_whatif.json", whatif_builds([[], ["cap3"], ["desync"], ["v3_115"], ["cap3", "desync", "v3_115"]]))
    spring = {k: WHATIF_PICKS[k] for k in ("S7_L195_ready_P1", "S8_L240_ready_P1")}
    write(out / "builds_whatif_spring.json", whatif_builds([["late_dmg75"], ["late_dmg60"], ["late_dmg60", "cap3"]], spring))
