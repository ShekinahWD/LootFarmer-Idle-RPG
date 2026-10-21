"""Deterministic encounter layout for every stage (authoring tool, Change 6).

Places each stage's groups so that:
- the weakest normal type is nearest the arrival camp and difficulty rises with distance;
- every boss is farther than every normal type of its stage (the final boss keeps its authored arena);
- no two farming spots (type + variant) can be auto-acquired from each other: the closest actors of
  different spots stay farther apart than acquisition + reach + margin, so a player farming one spot,
  including after its enemies die, never walks into a neighbouring spot by itself;
- camps (respawn points) stay out of every spot's acquisition range.

Writes `center` for each group in data/game/catalog.json and prints a report. Run with --check to only
validate the current catalog. The constants mirror campaign.gd (`SPOT_OFFSET`) and catalog.world.
"""
from pathlib import Path
import json, math, sys

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / 'data/game/catalog.json'
SPOT = 100.0            # campaign.gd SPOT_OFFSET: variant spots sit at center +-SPOT on both axes
ACTORS = [((i % 3 - 1) * 24.0, (i // 3) * 26.0) for i in range(6)]   # simulation._sync_spawn_counts
MARGIN = 12.0
GRID = 16.0


def variants(g):
    if g['boss']:
        return [2]
    return [0, 1, 2, 3] if g['skills'] else [0, 1, 2]


def spot(center, g, v):
    if g['boss']:
        return center
    return (center[0] + (-SPOT if v % 2 == 0 else SPOT), center[1] + (-SPOT if v < 2 else SPOT))


def actors(center, g):
    out = []
    for v in variants(g):
        sx, sy = spot(center, g, v)
        for dx, dy in (ACTORS[:1] if g['boss'] else ACTORS):
            out.append(((sx + dx, sy + dy), v))
    return out


def min_gap(a_center, a, b_center, b):
    return min(math.dist(p, q) for p, _ in actors(a_center, a) for q, _ in actors(b_center, b))


def internal_gap(center, g):
    pts = actors(center, g)
    return min((math.dist(p, q) for p, v in pts for q, w in pts if v != w), default=math.inf)


def layout(stage, groups, world):
    need = world['acquisition'] + world['reach'] + MARGIN
    camp_need = world['acquisition'] + MARGIN + 40
    w, h = stage['size']
    arrival = stage['spawns'][0]
    order = sorted([g for g in stage['groups'] if not groups[g]['boss']], key=lambda g: groups[g]['level'])
    order += sorted([g for g in stage['groups'] if groups[g]['boss'] and not groups[g]['final']], key=lambda g: groups[g]['level'])
    fixed = {g: tuple(groups[g]['center']) for g in stage['groups'] if groups[g]['final']}
    placed = dict(fixed)
    candidates = []
    y = 0.0
    while y <= h:
        x = 0.0
        while x <= w:
            candidates.append((x, y))
            x += GRID
        y += GRID
    def feasible(c, g):
        edge = 150.0 if groups[g]['boss'] else SPOT + 60.0
        if c[0] < edge or c[1] < edge or c[0] > w - edge or c[1] > h - edge:
            return False
        if internal_gap(c, groups[g]) < need:
            return False
        for camp in stage['spawns']:
            if min(math.dist(camp, p) for p, _ in actors(c, groups[g])) < (camp_need if not groups[g]['boss'] else camp_need + 60):
                return False
        for other, oc in placed.items():
            gap = need + (40 if groups[g]['boss'] or groups[other]['boss'] else 0)
            if math.dist(c, oc) > 2 * SPOT * 1.5 + gap + 60:
                continue
            if math.dist(c, oc) < gap or min_gap(c, groups[g], oc, groups[other]) < gap:
                return False
        return True
    far = max(math.dist(arrival, c) for c in candidates)
    near = 300.0
    for rank, g in enumerate(order):
        frac = rank / max(1, len(order) - 1)
        target = near + (far * 0.82 - near) * frac
        best, score = None, math.inf
        prev = max((math.dist(arrival, placed[o]) for o in order[:rank]), default=0.0)
        for c in candidates:
            d = math.dist(arrival, c)
            if d < prev + 20 or not feasible(c, g):
                continue
            spread = min((math.dist(c, oc) for oc in placed.values()), default=999.0)
            s = abs(d - target) - 0.25 * min(spread, 500.0)
            if s < score:
                best, score = c, s
        if best is None:
            raise SystemExit('stage %d: no feasible center for %s' % (stage['id'], groups[g]['id']))
        placed[g] = best
    return placed


def report(stage, groups, world):
    need = world['acquisition'] + world['reach'] + MARGIN
    arrival = stage['spawns'][0]
    ok = True
    lines = []
    ids = stage['groups']
    for g in ids:
        c = tuple(groups[g]['center'])
        lines.append('  %-28s L%-3d boss=%-5s center=(%4.0f,%4.0f) arrival_dist=%5.0f' % (groups[g]['id'], groups[g]['level'], groups[g]['boss'], c[0], c[1], math.dist(arrival, c)))
        if internal_gap(c, groups[g]) < need:
            ok = False; lines.append('    FAIL internal variant gap %.0f < %.0f' % (internal_gap(c, groups[g]), need))
        for h in ids:
            if h > g and min_gap(c, groups[g], tuple(groups[h]['center']), groups[h]) < need:
                ok = False; lines.append('    FAIL gap to %s %.0f' % (groups[h]['id'], min_gap(c, groups[g], tuple(groups[h]['center']), groups[h])))
        for camp in stage['spawns']:
            if min(math.dist(camp, p) for p, _ in actors(c, groups[g])) < world['acquisition'] + MARGIN:
                ok = False; lines.append('    FAIL camp %s inside acquisition' % (camp,))
    normals = [g for g in ids if not groups[g]['boss']]
    bosses = [g for g in ids if groups[g]['boss']]
    if max(math.dist(arrival, groups[g]['center']) for g in normals) >= min(math.dist(arrival, groups[g]['center']) for g in bosses):
        ok = False; lines.append('    FAIL a boss is nearer the arrival than a normal type')
    return ok, lines


def main():
    data = json.loads(CATALOG.read_text())
    groups, world = data['groups'], data['world']
    if '--check' not in sys.argv:
        for stage in data['stages']:
            for g, c in layout(stage, groups, world).items():
                groups[g]['center'] = [round(c[0], 2), round(c[1], 2)]
        CATALOG.write_bytes((json.dumps(data, indent=2) + '\n').encode())
    failures = 0
    for stage in data['stages']:
        ok, lines = report(stage, groups, world)
        failures += 0 if ok else 1
        print('Stage %d %s %s' % (stage['id'], stage['size'], 'OK' if ok else 'FAIL'))
        print('\n'.join(lines))
    print(json.dumps({'stages': len(data['stages']), 'failures': failures}))
    sys.exit(1 if failures else 0)


if __name__ == '__main__':
    main()
