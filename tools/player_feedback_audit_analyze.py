"""Player-feedback balance audit (2026-11-06): analysis and baseline comparison for
tests/player_feedback_audit.tscn. Reads CSVs written by the harness; never edits project data.

  python tools/player_feedback_audit_analyze.py compare  BASELINE.csv NEW.csv [--tol-time 0.05] [--tol-frac 0.001]
  python tools/player_feedback_audit_analyze.py builds-check [DIR]        # regenerated builds == committed builds
  python tools/player_feedback_audit_analyze.py summary  TRIALS.csv BUILDS.json [all|matrix|ladder|nb|farm]
  python tools/player_feedback_audit_analyze.py economy  TRIALS_MAIN.csv  # switching projections (PROJECTED)
  python tools/player_feedback_audit_analyze.py gear                      # equipment table from catalog formulas

compare exits 1 when any trial differs (result, kills, deaths, potions exactly; time and HP fractions
within tolerance) or a trial is missing; the simulation is deterministic per seed, so an unchanged tree
reproduces the baseline exactly.
"""
import csv, json, math, statistics as stx, subprocess, sys, tempfile
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EVIDENCE = ROOT / "docs/Player_Feedback_Audit_Evidence"
CAT = json.loads((ROOT / "data/game/catalog.json").read_text(encoding="utf-8"))
I = CAT["items"]; U = CAT["upgrades"]; GL = CAT["groups"]; G = {g["id"]: g for g in GL}

# ------------------------------------------------------------------ compare
KEY = ("build", "whatif", "enc", "target", "variant", "count", "seed")
EXACT = ("result", "kills", "deaths", "potions", "enemies_left", "why")
CLOSE = ("time", "player_left", "player_min", "target_hp_left", "coins", "xp", "taken")

def load(path):
    rows = {}
    for r in csv.DictReader(open(path, encoding="utf-8")):
        r.setdefault("whatif", "")
        rows[tuple(r.get(k, "") for k in KEY)] = r
    return rows

def compare(base_path, new_path, tol_time=0.05, tol_frac=0.001):
    base, new = load(base_path), load(new_path)
    missing = [k for k in base if k not in new]; extra = [k for k in new if k not in base]
    diffs = []
    for k, b in base.items():
        n = new.get(k)
        if n is None:
            continue
        for f in EXACT:
            if str(b.get(f, "")) != str(n.get(f, "")) and not (f in ("kills", "deaths", "potions", "enemies_left") and float(b.get(f) or 0) == float(n.get(f) or 0)):
                diffs.append((k, f, b.get(f), n.get(f)))
        for f in CLOSE:
            x, y = float(b.get(f) or 0), float(n.get(f) or 0)
            tol = tol_time if f == "time" else (tol_frac if f in ("player_left", "player_min", "target_hp_left") else max(0.01, abs(x) * 1e-4))
            if abs(x - y) > tol:
                diffs.append((k, f, x, y))
    print(f"compare {Path(base_path).name} vs {Path(new_path).name}: baseline {len(base)} rows, new {len(new)} rows, missing {len(missing)}, extra {len(extra)}, differing fields {len(diffs)}")
    for d in diffs[:20]:
        print("  DIFF", d)
    for k in missing[:10]:
        print("  MISSING", k)
    ok = not missing and not diffs
    print("COMPARE", "PASS" if ok else "FAIL")
    return ok

def builds_check(directory=None):
    tmp = Path(directory) if directory else Path(tempfile.mkdtemp(prefix="pfa_builds_"))
    subprocess.run([sys.executable, str(ROOT / "tools/player_feedback_audit_builds.py"), "--out", str(tmp)], check=True)
    ok = True
    for name in ("builds_main.json", "builds_supplementary.json", "builds_whatif.json", "builds_whatif_spring.json"):
        same = json.loads((tmp / name).read_text(encoding="utf-8")) == json.loads((EVIDENCE / name).read_text(encoding="utf-8"))
        print(f"  {name}: {'identical' if same else 'DIFFERS'}"); ok &= same
    print("BUILDS_CHECK", "PASS" if ok else "FAIL")
    return ok

# ------------------------------------------------------------------ summary
def summary(trials_path, builds_path, mode="all"):
    rows = list(csv.DictReader(open(trials_path, encoding="utf-8")))
    spec = json.loads(Path(builds_path).read_text(encoding="utf-8"))
    bmeta = {b["id"]: b for b in spec["builds"]}
    for r in rows:
        for k in ("time", "player_left", "player_min", "taken", "incoming_dps", "damage", "hp", "defense", "lifesteal", "coins", "xp", "minutes", "target_hp_left", "enemy_heal"):
            r[k] = float(r[k])
        for k in ("potions", "kills", "deaths", "variant", "count", "seed", "level", "stage", "prestiges", "casts", "enemies_left"):
            r[k] = int(float(r[k]))
    bad = [r for r in rows if r["result"] == "invalid" or r["why"]]
    print(f"rows {len(rows)} invalid {len(bad)}")
    for r in bad[:10]:
        print("  INVALID", r["build"], r["enc"], r["target"], r["why"])

    VN = {0: "outfit-only", 1: "weapon-only", 2: "both", 3: "skill"}
    def enc_key(r):
        if r["enc"] == "boss":
            return f"BOSS {r['target']}"
        return f"{r['enc']} {r['target'].replace('unit-','')} {VN[r['variant']]} x{r['count']}"

    groups = defaultdict(list)
    for r in rows:
        groups[(r["build"], enc_key(r))].append(r)

    def summary(rs):
        wins = sum(1 for r in rs if r["result"] == "win")
        win_rs = [r for r in rs if r["result"] == "win"] or rs
        return {"n": len(rs), "wins": wins, "time": stx.median(r["time"] for r in rs),
                "left": stx.median(r["player_left"] for r in rs), "min": stx.median(r["player_min"] for r in rs),
                "dps_in": stx.median(r["incoming_dps"] for r in rs), "pots": stx.median(r["potions"] for r in rs),
                "taken": stx.median(r["taken"] for r in rs), "hp": rs[0]["hp"], "dmg": rs[0]["damage"],
                "res": "/".join(sorted(set(r["result"] for r in rs))), "boss_left": stx.median(r["target_hp_left"] for r in rs)}

    def fmt(s):
        return f"{s['wins']}/{s['n']} {s['time']:5.1f}s left {s['left']*100:3.0f}% min {s['min']*100:3.0f}% in {s['dps_in']:6.1f}/s taken {s['taken']/s['hp']*100:4.0f}%HP pots {s['pots']:.0f}" + (f" foeHP {s['boss_left']*100:.0f}%" if s['wins'] < s['n'] else "")

    order = []
    for b in spec["builds"]:
        if b["id"] not in order:
            order.append(b["id"])

    if mode in ("all", "matrix"):
        print("\n=== STAGE MATRIX (non-ladder builds) ===")
        for bid in order:
            if bid.startswith(("LAD_", "NB_", "FARM")):
                continue
            keys = [k for (b, k) in groups if b == bid]
            if not keys:
                continue
            first = groups[(bid, keys[0])][0]
            print(f"\n[{bid}] {bmeta[bid]['label']} | dmg {first['damage']:.1f} hp {first['hp']:.0f} def {first['defense']:.0f} ls {first['lifesteal']:.3f} prestiges {first['prestiges']}")
            for k in keys:
                print(f"   {k:44s} {fmt(summary(groups[(bid, k)]))}")

    if mode in ("all", "ladder"):
        print("\n=== LADDERS: minimum level with 3/3 wins (and first level with any win) ===")
        lad = defaultdict(lambda: defaultdict(dict))
        for (bid, k), rs in groups.items():
            if not bid.startswith("LAD_"):
                continue
            prefix = bmeta[bid]["ladder"]; L = bmeta[bid]["level"]
            lad[prefix][k][L] = summary(rs)
        for prefix in lad:
            print(f"\n[{prefix}] {bmeta[[b for b in order if b.startswith(prefix + '_L')][0]]['label']}")
            for k, byL in lad[prefix].items():
                Ls = sorted(byL)
                full = next((L for L in Ls if byL[L]["wins"] == byL[L]["n"] and all(byL[x]["wins"] == byL[x]["n"] for x in Ls if x >= L)), None)
                anyw = next((L for L in Ls if byL[L]["wins"] > 0), None)
                line = " ".join(f"L{L}:{byL[L]['wins']}" for L in Ls)
                print(f"   {k:40s} reliable L{full} first-win L{anyw} | {line}")

    if mode in ("all", "nb"):
        print("\n=== GRAY CAT NEIGHBOURS (L30 base) ===")
        for bid in order:
            if not bid.startswith("NB_"):
                continue
            for (b, k), rs in groups.items():
                if b == bid:
                    print(f"   {bid:16s} {bmeta[bid]['label'][:44]:44s} {k:34s} {fmt(summary(rs))}")

    if mode in ("all", "farm"):
        print("\n=== FARM RATES (10 simulated minutes, Focus, real respawns) ===")
        for r in rows:
            if r["enc"] != "farm":
                continue
            m = r["minutes"] or 10
            print(f"   {r['build']:12s} L{r['level']:<3d} {r['target']:26s} kills/min {r['kills']/m:5.2f} coins/min {r['coins']/m:7.2f} xp/min {r['xp']/m:8.1f} deaths {r['deaths']} pots {r['potions']} minHP {r['player_min']*100:.0f}%")

# ------------------------------------------------------------------ economy (PROJECTED)
def price(id_, n, st, factor=1.0):
    d = U[id_]
    return math.ceil(d["base"] * d["growth"] ** n * 1.55 ** (st - 1) * factor)

def simulate(gid, kpm, minutes, start=(0, 0), start_coins=0.0, price_factor=1.0, policy="coin_first", step=0.25):
    """Greedy reinvestment on one type. Returns timeline of (minute, coins/min, xp/min, levels)."""
    g = G[gid]; st = g["stage"]
    a, x = start; coins = start_coins; t = 0.0; out = []; xp_total = 0.0
    while t <= minutes + 1e-9:
        cpk = g["coins"] * (1 + 0.5 * a); xpk = g["xp"] * (1 + 0.1 * x)
        out.append((t, cpk * kpm, xpk * kpm, a, x, coins, xp_total))
        coins += cpk * kpm * step; xp_total += xpk * kpm * step; t += step
        bought = True
        while bought:
            bought = False
            want = "coin_amount" if (policy == "coin_first" and a < 20 and (a < 10 or x >= 10 or a <= x)) else "group_xp"
            if want == "group_xp" and x >= 20:
                want = "coin_amount"
            lvl = a if want == "coin_amount" else x
            if lvl >= 20:
                continue
            p = price(want, lvl, st, price_factor)
            if coins >= p:
                coins -= p; bought = True
                if want == "coin_amount": a += 1
                else: x += 1
    return out

def at(timeline, minute):
    return min(timeline, key=lambda r: abs(r[0] - minute))

def economy(trials_path):
    global rates
    rates = load_rates(trials_path)
    print("Measured farm rates used (v2 spot, 10 simulated minutes, seed 1):")
    for (b, gid), v in sorted(rates.items()):
        print(f"  {b:12s} {gid:26s} kills/min {v['kpm']:5.2f} xp/min {v['xpm']:7.1f} coins/min(no upgrades) {v['cpm']:6.2f} deaths {v['deaths']}")

    print("\nA. Upgrade ladder on one type: kills needed for the NEXT Coin Amount level at that level's income (base-kill units are stage-independent)")
    for n in (0, 1, 2, 3, 5, 8, 10, 12, 15, 19):
        p = 30 * 1.4 ** n; inc = 1 + 0.5 * n
        print(f"  ^{n:2d}: price {p:8.0f} x stage factor; income {inc:4.1f}x base -> {p / inc:6.0f} kills (x1.033^(stage-1))")

    def scenario(title, old_gid, old_build, old_levels, new_gid, new_build, horizon=240):
        o = rates.get((old_build, old_gid)); n = rates.get((new_build, new_gid))
        if not o or not n:
            print(f"\n{title}: missing farm rate {old_build}/{old_gid} or {new_build}/{new_gid}"); return
        stay = simulate(old_gid, o["kpm"], horizon, start=old_levels)
        sw = simulate(new_gid, n["kpm"], horizon)
        s0 = stay[0]; w0 = sw[0]
        print(f"\n{title}")
        print(f"  stay  {old_gid} (^{old_levels[0]} coins, ^{old_levels[1]} XP): {s0[1]:7.1f} coins/min, {s0[2]:7.1f} XP/min at minute 0")
        print(f"  switch {new_gid} (no upgrades):          {w0[1]:7.1f} coins/min, {w0[2]:7.1f} XP/min at minute 0  ({(w0[1]/s0[1]-1)*100:+.0f}% coins, {(w0[2]/s0[2]-1)*100:+.0f}% XP)")
        parity_c = next((r[0] for r in sw if r[1] >= s0[1]), None)
        parity_x = next((r[0] for r in sw if r[2] >= s0[2]), None)
        # cumulative: staying player also keeps reinvesting
        cum_stay = 0.0; cum_sw = 0.0; be = None
        for rs, rw in zip(stay, sw):
            cum_stay += rs[1] * 0.25; cum_sw += rw[1] * 0.25
            if be is None and rw[0] > 0 and cum_sw >= cum_stay: be = rw[0]
        for m in (10, 30, 60, 120, 240):
            rs, rw = at(stay, m), at(sw, m)
            print(f"   t={m:3d} min: stay {rs[1]:7.1f} c/min ^{rs[3]}/^{rs[4]}   switch {rw[1]:7.1f} c/min ^{rw[3]}/^{rw[4]}")
        print(f"  PROJECTED: switched type reaches the old coin rate after {parity_c} min, old XP rate after {parity_x} min; cumulative coins catch up: {be or '>'+str(horizon)} min")

    print("\nB. Switching scenarios (PROJECTED from measured kill rates)")
    scenario("B1 Winter II: invested Santa Hat (^10/^5) vs new Space Helmet, same stage", "unit-santa-hat", "FARM_W2", (10, 5), "unit-space-helmet", "FARM_W2")
    scenario("B2 Winter II -> Summer I arrival: invested Space Helmet (^10/^5) vs first Summer type Straw Hat", "unit-space-helmet", "FARM_W2", (10, 5), "unit-straw-hat", "FARM_SW_S3")
    scenario("B3 Summer I: invested Straw Hat (^10/^5) vs Yellow Cap (better XP)", "unit-straw-hat", "FARM_S3", (10, 5), "unit-yellow-cap", "FARM_S3")
    scenario("B4 Summer I -> Summer II: invested Yellow Cap (^12/^8) vs Cowboy Bandana", "unit-yellow-cap", "FARM_S3", (12, 8), "unit-cowboy-bandana", "FARM_S4")

    print("\nC. Alternating among three types of one stage vs one type (same total kills, PROJECTED)")
    for build, ids in (("FARM_S3", ["unit-straw-hat", "unit-sunglasses", "unit-yellow-cap"]),):
        kpm = sum(rates[(build, i)]["kpm"] for i in ids) / len(ids)
        one = simulate(ids[-1], kpm, 180)
        three = [simulate(i, kpm / 3, 180) for i in ids]
        for m in (30, 60, 120, 180):
            o = at(one, m); tl = [at(t, m) for t in three]
            print(f"  t={m:3d}: one type {o[1]:6.1f} c/min (^{o[3]}/^{o[4]}) | three types {sum(x[1] for x in tl):6.1f} c/min (levels {[ (x[3],x[4]) for x in tl]})")

    print("\nD. Candidate remedies on scenario B2/B3 (PROJECTED)")
    o = rates.get(("FARM_S3", "unit-straw-hat")); n = rates.get(("FARM_S3", "unit-yellow-cap"))
    if o and n:
        base_old = simulate("unit-straw-hat", o["kpm"], 1, start=(10, 5))[0]
        opts = [("current (start ^0/^0)", (0, 0), 1.0),
                ("R2 carry 50% of the stage's best level (start ^5/^2)", (5, 2), 1.0),
                ("R2 carry 75% (start ^7/^3)", (7, 3), 1.0),
                ("R1 stage-wide upgrade (start ^10/^5, prices x2.5)", (10, 5), 2.5)]
        for name, lv, f in opts:
            tl = simulate("unit-yellow-cap", n["kpm"], 240, start=lv, price_factor=f)
            parity = next((r[0] for r in tl if r[1] >= base_old[1]), None)
            print(f"  {name:52s} minute-0 {tl[0][1]:6.1f} c/min vs old {base_old[1]:6.1f}; parity after {parity} min; ^ at 60 min {at(tl,60)[3]}/{at(tl,60)[4]}")
    print("\nE. Stage-wide pricing check: buying Coin Amount ^10 for ONE type vs ^10 stage-wide at x2.5 (stage 3 coins)")
    one = sum(price("coin_amount", i, 3) for i in range(10)); wide = sum(price("coin_amount", i, 3, 2.5) for i in range(10))
    print(f"  per type {one} coins (x3 types = {3*one}); stage-wide x2.5 = {wide} coins; Summer II (6 types) per-type total {6*sum(price('coin_amount', i, 4) for i in range(10))} vs stage-wide {sum(price('coin_amount', i, 4, 2.5) for i in range(10))}")


def load_rates(path):
    out = {}
    for r in csv.DictReader(open(path, encoding="utf-8")):
        if r["enc"] == "farm" and not r["why"]:
            m = float(r["minutes"]) or 10
            out[(r["build"], r["target"])] = {"kpm": int(float(r["kills"])) / m, "xpm": float(r["xp"]) / m, "cpm": float(r["coins"]) / m, "deaths": int(float(r["deaths"]))}
    return out

# ------------------------------------------------------------------ gear table (catalog formulas)
def gear():
    G = GL
    def levels(id_, m):
        if I[id_]["kind"] == "outfit" and m > 100:
            return 100 + 0.5 * (m - 100)
        return min(m, 100) if I[id_]["kind"] == "weapon" else m

    def stat(id_, m, key):
        if key not in I[id_]["normal"]:
            return 0.0
        b, _ = I[id_]["normal"][key]
        return b + I[id_]["merge_gain"][key] * levels(id_, m)

    droppers = {}
    for g in G:
        for l in g["loot"]:
            droppers.setdefault(l, []).append(g)

    def first_stage(id_):
        return min(g["stage"] for g in droppers[id_]) if id_ in droppers else None

    def normal_stage(id_):
        s = [g["stage"] for g in droppers.get(id_, []) if not g["boss"]]
        return min(s) if s else None

    print("WEAPONS: tier, first boss stage, first normal stage, damage/HP at ^0/^50/^100")
    for id_, v in I.items():
        if v["kind"] != "weapon" or v.get("legacy"):
            continue
        bs = [g["stage"] for g in droppers.get(id_, []) if g["boss"]]
        print(f"  {id_:14s} t{v['tier']} boss@{min(bs) if bs else '-'} normal@{normal_stage(id_) or '-'}  dmg {stat(id_,0,'damage'):6.1f}/{stat(id_,50,'damage'):6.1f}/{stat(id_,100,'damage'):6.1f}  hp {stat(id_,0,'hp'):6.1f}/{stat(id_,50,'hp'):6.1f}/{stat(id_,100,'hp'):6.1f}")

    print("\nOUTFITS (per stage normal vs boss): HP at ^0/^50/^100/^200/^500")
    seen = set()
    for g in G:
        for l in g["loot"]:
            if I[l]["kind"] != "outfit" or l in seen:
                continue
            seen.add(l)
            if g["boss"] or l.endswith("blue-cap_outfit") or g["id"] in ("unit-wolf-hood", "unit-straw-hat", "unit-cowboy-bandana", "unit-black-cap", "unit-horned-hood", "unit-bunny-ears", "unit-flower-crown"):
                print(f"  st{g['stage']} {l:34s} t{I[l]['tier']} {'BOSS' if g['boss'] else 'norm'} " + " ".join(f"{stat(l,m,'hp'):7.1f}" for m in (0, 50, 100, 200, 500)))

    print("\nMerge level of the stage's normal outfit needed to equal a boss outfit at ^m")
    pairs = [("boss-snowman_outfit", "unit-santa-hat_outfit"), ("boss-snowman_outfit", "unit-yellow-cap_outfit_t2"), ("boss-snowman_outfit", "unit-snorkeler_outfit_t2"),
             ("boss-gray-cat_outfit_t2", "unit-pumpkin-head_outfit_t3"), ("boss-gray-cat_outfit_t2", "unit-top-hat_outfit_t3"), ("boss-red-fox_outfit_t3", "unit-elf-ears_outfit_t4")]
    for boss, norm in pairs:
        for m in (0, 30, 60, 100):
            target = stat(boss, m, "hp")
            need = next((k for k in range(0, 501) if stat(norm, k, "hp") >= target), None)
            print(f"  {boss}^{m} ({target:.1f} HP) = {norm}^{need}")

    print("\nShare of total damage / HP from the equipped weapon and outfit at boss level")
    cases = [
        (2, 20, ("stone_axe", 0), ("wood_axe", 100), ("boss-snowman_outfit", 30), ("unit-santa-hat_outfit", 60)),
        (3, 35, ("stone_axe", 100), ("stone_sword", 100), ("boss-snowman_outfit", 80), ("unit-yellow-cap_outfit_t2", 80)),
        (4, 60, ("iron_axe", 60), ("stone_sword", 100), ("boss-gray-cat_outfit_t2", 60), ("unit-snorkeler_outfit_t2", 100)),
        (5, 95, ("iron_axe", 100), ("iron_sword", 100), ("boss-teal-dinosaur_outfit_t2", 80), ("unit-mushroom-cap_outfit_t3", 60)),
        (8, 240, ("diamond_sword", 100), ("diamond_axe", 100), ("boss-red-panda_outfit_t5", 0), ("unit-pink-cap_outfit_t5", 60)),
    ]
    for st, L, wa, wb, oa, ob in cases:
        base_d = 5 + 0.5 * (L - 1); base_h = 100 + 5 * (L - 1)
        for w, o in ((wa, oa), (wb, ob)):
            d = stat(w[0], w[1], "damage"); h = stat(w[0], w[1], "hp") + stat(o[0], o[1], "hp")
            print(f"  st{st} L{L} {w[0]}^{w[1]} + {o[0]}^{o[1]}: damage {base_d + d:.1f} (gear {d/(base_d+d)*100:.0f}%), HP {base_h + h:.0f} (gear {h/(base_h+h)*100:.0f}%)")

    print("\nCopies to reach a merge level / evolve (simulation.gd merge(), evolve_block_reason())")
    print("  ^m = m+1 copies of the same id; evolution needs ^100 and 101 copies on hand (100 spent) -> 201 copies per tier step")
    print("  Wood Axe ^100 + 100 spare -> Stone Axe ^0, which the first Snowman kill already guarantees (onboarding.boss_first_kill).")

if __name__ == "__main__":
    sys.stdout.reconfigure(newline=chr(10))
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    args = [a for a in sys.argv[2:] if not a.startswith("--")]
    if cmd == "compare":
        tt = float(sys.argv[sys.argv.index("--tol-time") + 1]) if "--tol-time" in sys.argv else 0.05
        tf = float(sys.argv[sys.argv.index("--tol-frac") + 1]) if "--tol-frac" in sys.argv else 0.001
        sys.exit(0 if compare(args[0], args[1], tt, tf) else 1)
    elif cmd == "builds-check":
        sys.exit(0 if builds_check(args[0] if args else None) else 1)
    elif cmd == "summary":
        summary(args[0], args[1], args[2] if len(args) > 2 else "all")
    elif cmd == "economy":
        economy(args[0])
    elif cmd == "gear":
        gear()
    else:
        print(__doc__); sys.exit(2)
