"""Change 56: PROJECTED (catalog arithmetic, not a simulation) effect of "cheap first five" on per-type Coin prices
and on the finite Coin sink once every Coin upgrade is permanent (Change 50). Writes nothing; prints a table."""
import json
c = json.load(open('data/game/catalog.json', encoding='utf-8'))
U, G = c['upgrades'], c['groups']
eco = c['progression']['economy']
growth = float(c['progression'].get('map_cost_growth', 1.55))
f = lambda s: growth ** (s - 1)
def price(id_, n, st, cheap):
    d = U[id_]
    p = d['base'] * d['growth'] ** n * f(st)
    if cheap and id_ in eco['cheap_first_upgrades'] and n < eco['cheap_first_levels']:
        p *= eco['cheap_first_factor']
    return p
print('First five levels of one type (Coin Amount + Enemy XP + Loot Chance), coins:')
print('map | before | after | first normal coins/kill (^0)')
for st in range(1, 9):
    before = sum(price(i, n, st, False) for i in eco['cheap_first_upgrades'] for n in range(5))
    after = sum(price(i, n, st, True) for i in eco['cheap_first_upgrades'] for n in range(5))
    coins = [g['coins'] for g in G if g['stage'] == st and not g['boss']][0]
    print(f'{st} | {before:,.0f} | {after:,.0f} | {coins}')
tot_b = tot_a = 0.0
for id_ in eco['cheap_first_upgrades']:
    for g in G:
        tot_b += sum(price(id_, n, g['stage'], False) for n in range(U[id_]['cap']))
        tot_a += sum(price(id_, n, g['stage'], True) for n in range(U[id_]['cap']))
print(f'Sink of these three upgrades, every type to cap: {tot_b:,.0f} -> {tot_a:,.0f} coins ({(tot_b - tot_a) / tot_b * 100:.2f}% less)')
