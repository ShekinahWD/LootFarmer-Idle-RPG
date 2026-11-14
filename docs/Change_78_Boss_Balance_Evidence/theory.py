"""Change 78 boss investigation: theoretical (catalog + code formulas) enemy output per stage. Pre-Defense."""
import json
c=json.load(open('data/game/catalog.json',encoding='utf-8'))
G=c['groups'];SK=c['skills'];comb=c['progression']['combat']
NAMES={1:'Winter I',2:'Winter II',3:'Summer I',4:'Summer II',5:'Autumn I',6:'Autumn II',7:'Spring I',8:'Spring II'}
BOSS_CD=10.0;TELE=0.6;NORMAL_CD=20.0;FOCUS_S=5.0;FOCUS_P=.15
def vdef(g,v):
    hp,d=g['hp'],g['damage']
    if not g['boss']:
        hp*={0:1.25,1:.75,2:1.0,3:comb['skill_variant_hp']}[v]
        d*={0:.75,1:1.25,2:1.0,3:comb['skill_variant_damage']}[v]
        d*=comb['normal_damage_scale'].get(str(g['stage']),1.0)
    return hp,d
def boss_row(g):
    hp,d=vdef(g,2); iv=g['interval']; nd=d/iv
    sk=g['skills']; final=g['final']
    period=BOSS_CD+TELE
    if final:
        # final: action gap 11 s, random from fire/strike/frost/lightning pool + focus; heal below 50%
        pool=['fire','strike','frost','lightning']
        avg=sum(SK[k]['power'] for k in pool)/len(pool)
        # 5 options (4 attacks + focus) equally likely
        atk=(avg*4/5)*d/11.6; foc=(1/5)*FOCUS_S/11.6
    else:
        atks=[SK[k]['power'] for k in sk if k not in ('heal','focus')]
        atk=sum(atks)*d/(len(sk)*period) if sk else 0.0
        foc=(FOCUS_S/(len(sk)*period)) if 'focus' in sk else 0.0
    eff=(nd+atk)*(1+FOCUS_P*foc)
    heal='heal' in sk
    return dict(id=g['id'],stage=g['stage'],hp=hp,dmg=d,iv=iv,nd=nd,skills=sk,atk=atk,foc=foc,eff=eff,heal=heal,aggro=g['aggro_mode'])
def spot_rows(st):
    out=[]
    for g in G:
        if g['stage']!=st or g['boss']: continue
        for v in ([0,1,2,3] if g['skills'] else [0,1,2]):
            hp,d=vdef(g,v); nd=d/g['interval']
            sk=0.0
            if v==3:
                k=g['skills'][0]
                if k not in ('heal','focus'): sk=SK[k]['power']*d/NORMAL_CD
                elif k=='focus': nd*=1+FOCUS_P*FOCUS_S/NORMAL_CD
            out.append(dict(id=g['id'],v=v,hp=hp,dmg=d,per=nd+sk,aggro=g['aggro_mode'],skill=g['skills'][0] if v==3 else ''))
    return out
print('stage|boss|HP|dmg/hit|interval|normal DPS|skills (dmg/cast)|skill DPS|eff DPS|strongest spot (type v)|per-actor DPS|3-actor DPS|6-actor DPS|attackers at once|boss/3-spot|boss/6-spot')
for st in range(1,9):
    spots=spot_rows(st); top=max(spots,key=lambda r:r['per'])
    for g in G:
        if g['stage']!=st or not g['boss']: continue
        b=boss_row(g)
        skd=', '.join(f"{k} {SK[k]['power']*b['dmg']:.0f}" if k not in ('heal','focus') else (f"heal {('4' if g['final'] else '8')}%HP" if k=='heal' else 'focus +15% 5s') for k in b['skills']) or '-'
        conc=1 if top['aggro']=='passive' else 3
        s3=top['per']*3; s6=top['per']*6
        att='1 (passive)' if top['aggro']=='passive' else 'all (group)'
        r3=b['eff']/(top['per']*conc); r6=b['eff']/(top['per']*(1 if conc==1 else 6))
        print(f"{st} {NAMES[st]}|{b['id']}|{b['hp']:.0f}|{b['dmg']:.1f}|{b['iv']}|{b['nd']:.1f}|{skd}|{b['atk']:.1f}|{b['eff']:.1f}|{top['id']} v{top['v']}|{top['per']:.2f}|{s3:.1f}|{s6:.1f}|{att}|{r3:.2f}|{r6:.2f}")
