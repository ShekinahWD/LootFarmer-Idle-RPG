extends "res://tests/change_20_probe.gd"
## Change 53 (approved progression brief, B4): combat structure and tuning.
## Winter I passive, Winter II and Summer I individual (proximity) aggression, Summer II-Spring II group;
## skill variant damage x1.15 (HP x1.35 unchanged); Spring I/II normal damage x0.60 for every loadout,
## multiplying with the variant (0.69 for a Spring skill variant); bosses and summoned helpers exempt; no
## attacker cap: a six-actor spot (Spawn Amount) spawns and fights six. A Summer I hit no longer pulls the
## rest of the spot (group assist) while a Summer II hit still does. Runs with --first-run-complete.
func run() -> void:
    get_window().size=Vector2i(720,1280)
    SettingsState.mute_all_sfx()
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    await frames(6)
    aggro_checks()
    damage_checks()
    behaviour_checks()
    print("CHANGE_53_CHECKS %d FAILURES %d" % [checks,failures])
    game.queue_free();await frames();AudioService.stop_all_sfx();get_tree().quit(1 if failures else 0)

func near(a: float,b: float) -> bool:return absf(a-b)<=1e-6*maxf(1.0,absf(b))

func aggro_checks() -> void:
    # Change 62: normals passive through stage 3, bosses passive through stage 2; proximity from there on.
    var want:={1:"passive",2:"passive",3:"passive",4:"group",5:"group",6:"group",7:"group",8:"group"}
    for d in sim.catalog.groups:
        var mode: String=("passive" if int(d.stage)<=2 else "group") if d.boss else want[int(d.stage)]
        check(str(d.aggro_mode)==mode,"%s (stage %d) aggression %s" % [d.id,int(d.stage),d.aggro_mode])
    check(str(sim.catalog.groups[sim.campaign.group_id("boss-gray-cat")].aggro_mode)=="group","The Summer I boss keeps its own rule")

func damage_checks() -> void:
    for g in range(sim.catalog.groups.size()):
        var d: Dictionary=sim.catalog.groups[g]
        var base: float=float(d.damage)
        if d.boss:
            check(near(float(sim.enemy_definition(g,2).damage),base),"%s boss damage unchanged" % d.id)
            continue
        # Change 81: Spring I/II normal damage x0.90 (was x0.60, change_81_probe).
        var scale:=0.9 if int(d.stage)>=7 else 1.0
        check(near(float(sim.enemy_definition(g,0).damage),base*.75*scale) and near(float(sim.enemy_definition(g,1).damage),base*1.25*scale) and near(float(sim.enemy_definition(g,2).damage),base*scale),"%s loadouts x%.2f" % [d.id,scale])
        if not d.skills.is_empty():
            check(near(float(sim.enemy_definition(g,3).damage),base*1.15*scale) and near(float(sim.enemy_definition(g,3).hp),float(d.hp)*1.35),"%s skill variant damage x%.3f, HP x1.35" % [d.id,1.15*scale])
    var bee=sim.campaign.group_id("unit-elf-ears")
    check(near(float(sim.enemy_definition(bee,3).damage),float(sim.catalog.groups[bee].damage)*1.035),"Spring skill variant: 0.90 x 1.15 = 1.035 (Change 81)")
    # Helpers copy their type's catalog damage scaled by their summon rule only.
    for g in range(sim.catalog.groups.size()):
        var rule: SummonRule=sim.abilities.helper_rule(str(sim.catalog.groups[g].id))
        if rule:check(near(float(sim.enemy_definition(g,sim.HELPER_VARIANT).damage),float(sim.catalog.groups[g].damage)*rule.damage_scale),"Helper %s unaffected" % sim.catalog.groups[g].id)

## A hit on one actor of a spot: Summer I (individual) leaves its distant neighbours alone; Summer II
## (group) pulls them in. Six actors spawn at Spawn Amount 3 and every one may attack (no cap).
func behaviour_checks() -> void:
    for pair in [["unit-straw-hat",false],["unit-cowboy-bandana",true]]:
        fresh()
        var g=sim.campaign.group_id(str(pair[0]))
        var st:=int(sim.catalog.groups[g].stage)
        sim.state.unlocked_stage=st;sim.state.camps[str(st)]=[0]
        check(sim.campaign.camp_action(st,0,true),"Travel to stage %d" % st)
        var spot: Array=sim.state.enemies.filter(func(e):return int(e.group)==g and int(e.variant)==2)
        var target: Dictionary=spot[0]
        # Stand far from the spot so proximity aggro cannot fire; resolve one player hit directly.
        sim.state.player.x=float(target.x)+10;sim.state.player.y=float(target.y)
        for e in spot:e.aggro=false
        sim.state.player.target=target.id;sim.state.player.windup=.001
        sim._resolve_attack(sim.state.player,.1)
        var pulled:=spot.filter(func(e):return e.id!=target.id and e.aggro).size()
        check((pulled>0)==bool(pair[1]),"%s: a hit %s the rest of the spot (%d)" % [pair[0],"pulls" if pair[1] else "does not pull",pulled])
    fresh()
    sim.state.upgrades["spawn_amount:0"]=3;sim._sync_spawn_counts()
    var six: Array=sim.state.enemies.filter(func(e):return int(e.group)==0 and int(e.variant)==2)
    check(six.size()==6 and sim.spawn_amount(0)==6,"Spawn Amount 3 gives six actors per spot (no attacker cap)")
