extends Node
## Shared manual/automatic eligibility, boundary movement, effect suppression and total Gem previews.
var sim: LootSimulation
var checks:=0
var failures:=0
var effects:=0
func check(ok: bool,label_: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(label_)
func close(a: float,b: float) -> bool:return absf(a-b)<.00001
func _ready() -> void:call_deferred("run")
func fixture(key: String) -> Dictionary:
    sim.new_profile();sim.set_physics_process(false);sim.state.tutorial.mode="none"
    sim.suspended=false;get_tree().paused=false
    sim.state.upgrades.skill_auto_slots=1
    var id:="skill_"+key
    sim.add_item(id);sim.campaign.equip_skill(id,0);sim.assign_automatic_skills([0])
    var enemy: Dictionary=sim.state.enemies[0]
    sim.state.player.x=enemy.x;sim.state.player.y=enemy.y
    for a in sim.state.enemies:a.hp=0
    enemy.hp=1000000;enemy.aggro=true
    sim.campaign.reveal();sim.locked_target=enemy.id
    effects=0
    return enemy
func move_enemy(enemy: Dictionary,distance: float) -> void:
    enemy.x=sim.state.player.x+distance;enemy.y=sim.state.player.y
func run() -> void:
    sim=LootSimulation.new();add_child(sim);sim.set_physics_process(false)
    sim.spell_cast.connect(func(_actor,_key,_position):effects+=1)
    for key in ["frost","fire","lightning","focus","strike"]:
        var enemy:=fixture(key)
        move_enemy(enemy,64.01)
        var hp: float=enemy.hp
        var rng_before: int=sim.rng.state
        var target_before: String=sim.locked_target
        for i in range(5):check(sim.campaign.skill_cast_block_reason(0)=="SKILL_TARGET_OUT_OF_RANGE",key+" outside boundary")
        check(sim.rng.state==rng_before and sim.locked_target==target_before,"Availability has no RNG/target effects")
        check(not sim.campaign.cast(0),key+" manual blocked")
        check(not sim.campaign.apply_skill(sim.state.player,key,1),key+" direct path blocked")
        sim.campaign.automate(.1)
        check(effects==0 and enemy.hp==hp and sim.state.skill_cooldowns.is_empty(),key+" auto blocked without effects/CD")
        move_enemy(enemy,64)
        check(sim.campaign.skill_cast_block_reason(0).is_empty(),key+" boundary enabled")
        check(sim.campaign.cast(0) and effects==1,key+" manual casts once")
        check(sim.campaign.skill_cast_block_reason(0)=="SKILL_COOLDOWN",key+" cooldown reason")
        sim.state.skill_cooldowns.clear();move_enemy(enemy,65)
        sim.campaign.automate(.1)
        check(effects==1 and sim.state.skill_cooldowns.is_empty(),key+" leaving range blocks next auto cast")
        move_enemy(enemy,63.9);sim.campaign.automate(.1)
        check(effects==2 and close(sim.state.skill_cooldowns[key],20),key+" entering range auto casts")
        sim.state.skill_cooldowns.clear();enemy.hp=0
        check(not sim.campaign.cast(0),key+" dead target cannot enable cast")
    var enemy:=fixture("heal")
    move_enemy(enemy,500);enemy.aggro=false;sim.state.player.quiet=10
    check(sim.campaign.skill_cast_block_reason(0)=="HEALTH_FULL","Heal full health disabled")
    sim.state.player.hp=sim.stats().hp*.99
    check(sim.campaign.skill_cast_block_reason(0).is_empty() and sim.campaign.cast(0),"Heal manual outside combat")
    sim.state.skill_cooldowns.clear();sim.state.player.hp=sim.stats().hp*.99
    sim.campaign.automate(.1)
    check(effects==2 and close(sim.state.player.hp,sim.stats().hp),"Heal automatic outside combat")
    sim.state.skill_cooldowns.clear();sim.state.player.hp=sim.stats().hp*.5
    get_tree().paused=true
    check(not sim.campaign.skill_cast_block_reason(0).is_empty() and not sim.campaign.cast(0),"Pause lock shared")
    get_tree().paused=false
    check(not sim.campaign.skill_cast_block_reason(-1).is_empty() and not sim.campaign.skill_cast_block_reason(3).is_empty(),"Invalid slots safe")
    enemy=fixture("fire");move_enemy(enemy,60)
    sim.catalog.progression.change17.skill_activation_distance=48.0
    check(not sim.campaign.cast(0),"Editable activation radius")
    sim.catalog.progression.change17.skill_activation_distance=64.0
    # Far locked actor must not suppress a valid nearby target or become the Fire centre.
    var far: Dictionary=sim.state.enemies[1]
    far.hp=1000000;far.x=sim.state.player.x+300;far.y=sim.state.player.y
    sim.locked_target=far.id
    check(sim.campaign.skill_activation_target().id==enemy.id and sim.campaign.cast(0),"Nearby fallback with far lock")
    check(close(far.hp,1000000),"Fire retains target-centred radius")
    sim.new_profile()
    check(close(sim.player_upgrade_value("boss_gem_chance"),.05) and close(sim.player_upgrade_value("boss_gem_chance",1),.10),"Boss preview 5 to 10 percent")
    sim.state.upgrades.boss_gem_chance=2;sim.state.upgrades.gem_chance=1
    check(close(sim.player_upgrade_value("boss_gem_chance"),.155) and close(sim.player_upgrade_value("boss_gem_chance",1),.205),"Boss subsequent totals include global upgrade")
    for g in range(sim.catalog.groups.size()):
        var expected:=.155 if sim.catalog.groups[g].boss else .055
        check(close(sim.gem_chance(g),expected),"Actual chance unchanged "+str(g))
    print("SKILL_PROXIMITY_CHECKS ",checks," FAILURES ",failures)
    get_tree().quit(1 if failures else 0)
