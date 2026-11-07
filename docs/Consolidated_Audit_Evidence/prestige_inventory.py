# Verified from campaign.gd (discoverable/evaluate/chain_for/boss_goal/trophy_bosses/collection_names)
# and game_ui.gd prestige_stages(). Stage = map where the requirement is performed.
ops=[
('hunter_o1','Snowman x10 after discovery','discover: defeat Snowman',[1],[1],'boss'),
('hunter_o2','Gray Cat x20','discover: defeat Gray Cat',[3],[3],'boss'),
('hunter_o3','Grim Reaper x30','discover: defeat Grim Reaper',[6],[6],'boss'),
('challenge_o1','Cyan Robot, no supply in fight','discover: defeat Cyan Robot (catalog note says Snowman)',[2],[2],'boss'),
('challenge_o2','Teal Dinosaur, no supply','discover: defeat Teal Dinosaur',[4],[4],'boss'),
('challenge_o3','Grim Reaper, no supply','discover: defeat Grim Reaper',[6],[6],'boss'),
('trophy_o1','Snowman + Cyan Robot once each','discover: Snowman kill',[1,2],[1,2],'boss'),
('trophy_o2','Gray Cat + Elephant + Teal Dinosaur','discover: Gray Cat kill',[3,4],[3,4,5],'boss'),
('trophy_o3','Squirrel + Red Fox + Black Cat + Grim Reaper','discover: Squirrel kill',[5,6],[6,7,8],'boss'),
('expedition_o1','100 each Blue Cap/Red Scarf/Chef Hat','discover: 10 Blue Caps',[1],[1],'normal'),
('expedition_o2','150 each Straw Hat/Sunglasses/Yellow Cap','discover: 10 Straw Hats',[3],[3],'normal'),
('expedition_o3','200 each Bunny/Cat/Elf Ears','discover: 10 Bunny Ears',[7],[7],'normal'),
('collection_o1','hand in 20 of each Winter I outfit','discover: 3 online gear families',[1],[1],'normal'),
('collection_o2','hand in 30 of each Summer I outfit','discover: reach Summer I',[3],[3],'normal'),
('collection_o3','hand in 40 of each Spring I outfit','discover: reach Spring I',[7],[7],'normal'),
('regional_o1','W1+W2: 90% explored, all camps, both bosses (run)','discover: reach W2',[1,2],[1,2],'explore'),
('regional_o2','S1+S2: same, three bosses','discover: reach S2',[3,4],[3,4],'explore'),
('regional_o3','Sp1+Sp2: same, five bosses','discover: reach Sp2',[7,8],[7,8],'explore'),
('masterwork_o1','any item ^100','discover: any ^10',['any'],['general'],'general'),
('masterwork_o2','tier>=2 item ^100','discover: evolve once',['any'],['general'],'general'),
('masterwork_o3','tier>=3 item ^100','discover: own tier 3',['any'],['general'],'general'),
('arsenal_o1','1 weapon + 1 outfit ^50','discover: equip both',['any'],['general'],'general'),
('arsenal_o2','3 weapons + 3 outfit families ^50','discover: 4 online families',['any'],['general'],'general'),
('arsenal_o3','3 tier2+ weapons + 3 tier2+ outfits ^50','discover: evolve 2 families',['any'],['general'],'general'),
('offering_o1','submit 2K coins + 30 gems earned this run','discover: 1,000 online coins',['any'],['general'],'general'),
('offering_o2','submit 20K + 100','discover: reach Autumn I',['any (5+)'],['general'],'general'),
('offering_o3','submit 100K + 300','discover: reach Spring II',['any (8)'],['general'],'general'),
('specialist_o1','100 kills, 10 gear, 10 merges','discover: 1 mission',['any'],['general'],'general'),
('specialist_o2','250 kills, 3 bosses, 25 merges, 30 casts','discover: 5 missions',['any'],['general'],'general'),
('specialist_o3','500 kills, 10 bosses, 50 merges, 3 missions','discover: reach Autumn II',['any (6+)'],['general'],'general'),
('offline_o1','72 h away total (lifetime)','discover: first offline',['offline'],['general'],'offline'),
('offline_o2','24 h away in one go (lifetime)','discover: first offline',['offline'],['general'],'offline'),
('offline_o3','10K offline coins (lifetime)','discover: first offline claim',['offline'],['general'],'offline'),
]
print('| Opportunity | Requirement (code) | Discovery (code) | Performed on map | Shown under (UI) | Focus | Mismatch |')
print('|---|---|---|---|---|---|---|')
for o in ops:
    mis='**yes**' if o[3]!=o[4] and o[4]!=['general'] else ''
    print(f'| `{o[0]}` | {o[1]} | {o[2]} | {",".join(map(str,o[3]))} | {",".join(map(str,o[4]))} | {o[5]} | {mis} |')
counts={s:{'boss':0,'normal':0,'explore':0} for s in range(1,9)}
for o in ops:
    for s in o[3]:
        if isinstance(s,int):counts[s][o[5]]+=1
print('\nPer map (stage-specific objectives performed there; multi-map objectives count on each map):')
for s,c in counts.items():print(s,c,sum(c.values()))
