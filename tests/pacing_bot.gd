extends Node
## Natural-pace bot: plays the real simulation in 0.1 s steps with ordinary player
## decisions (explore, farm what it can beat, tap nearby loot, equip, merge, buy,
## fight bosses when its own estimate says it can win). No state is injected.
## Usage: godot --headless --path . tests/pacing_bot.tscn -- --probe --no-autosave
##        --policy=ordinary|rush --minutes=120 --seed=1 [--cards=id,id] [--prestiges=N]
var sim
var policy:="ordinary"
var minutes:=120.0
var seed_value:=1
var waypoints: Array=[]
var milestones: Dictionary={}
var log_lines: Array=[]
var target_spot:=Vector2.INF
var deaths:=0
var boss_attempts:=0
var think:=0.0
var resting:=false
var committed:=-1
var goal_point:=Vector2.INF
var stage_entered: Dictionary={}

func _ready() -> void:call_deferred("run")

func arg(key: String,default):
    for a in OS.get_cmdline_user_args():
        if a.begins_with("--"+key+"="):return a.split("=")[1]
    return default

func mark(key: String) -> void:
    if not milestones.has(key):
        milestones[key]=sim.state.clock
        log_lines.append("%7.1f min  %s  (level %d, coins %d, dmg %.1f, hp %.0f)" % [sim.state.clock/60.0,key,sim.state.player_level,sim.state.coins,sim.stats().damage,sim.stats().hp])

func run() -> void:
    policy=str(arg("policy","ordinary"));minutes=float(arg("minutes",120));seed_value=int(arg("seed",1))
    sim=load("res://scripts/game/simulation.gd").new();add_child(sim);sim.set_physics_process(false)
    sim.new_profile();sim.rng.seed=seed_value;sim.state.tutorial.mode="none"
    var cards: String=str(arg("cards",""))
    if cards!="":
        for id in cards.split(","):sim.state.owned_cards.append(id)
        sim.state.prestiges=int(arg("prestiges",1));sim.touch()
    sim.event.connect(_event)
    _plan_waypoints()
    var steps:=int(minutes*600)
    for i in range(steps):
        think+=.1
        if think>=.5:think=0;_decide()
        elif goal_point!=Vector2.INF and sim.movement!=Vector2.ZERO:
            var offset: Vector2=goal_point-_player()
            sim.movement=Vector2.ZERO if offset.length()<26 else offset.normalized()
        sim.step(.1)
        if milestones.has("prestige_allowed") and policy!="full":break
        if arg("summary","")!="" and i%6000==0:_summary()
    var summary:="PACING policy=%s seed=%d cards=%s simulated_min=%.1f level=%d stage=%d unlocked=%d deaths=%d boss_attempts=%d" % [policy,seed_value,cards,sim.state.clock/60.0,sim.state.player_level,sim.state.stage,sim.state.unlocked_stage,deaths,boss_attempts]
    print("\n".join(log_lines));print(summary)
    var ready: Array=[]
    for id in sim.state.opportunities:
        if sim.state.opportunities[id].ready:ready.append(id)
    print("PACING ready=",ready," discovered=",sim.state.opportunities.keys())
    get_tree().quit()

func _summary() -> void:
    var gate:="";var margin:=0.0
    for g in sim.campaign.stage().groups:
        if sim.catalog.groups[g].boss:
            var def: Dictionary=sim.enemy_definition(g,2).duplicate();def["index"]=g
            gate=sim.catalog.groups[g].id;margin=_fight(def,1,mini(sim.quantity("potion"),6))
    var known:=0
    for g in sim.campaign.stage().groups:
        if sim.campaign.discovered(g):known+=1
    print("SUMMARY t=%.0fmin lvl=%d stage=%d known=%d/%d boss=%s margin=%.2f potions=%d hp=%.0f/%.0f dmg=%.1f deaths=%d pos=%s" % [sim.state.clock/60,sim.state.player_level,sim.state.stage,known,sim.campaign.stage().groups.size(),gate,margin,sim.quantity("potion"),sim.state.player.hp,sim.stats().hp,sim.stats().damage,deaths,_player()])

func _event(key: String) -> void:
    match key:
        "PLAYER_DIED":deaths+=1
        "STAGE_UNLOCKED":mark("unlock_stage_%d" % sim.state.unlocked_stage)
        "PRESTIGE_DISCOVERED":mark("first_prestige_discovered")
        "PRESTIGE_READY":mark("first_prestige_ready")
        "PLAYER_LEVEL_UP":
            if sim.state.player_level in [5,10,15,20,30,40]:mark("level_%d" % sim.state.player_level)

func _plan_waypoints() -> void:
    waypoints.clear()
    var size=sim.campaign.stage().size
    for y in range(4):
        for x in range(4):waypoints.append(Vector2((x+.5)*size[0]/4.0,(y+.5)*size[1]/4.0))

func _camp_price(i: int) -> int:
    return sim.campaign.camp_price(i) if sim.campaign.has_method("camp_price") else int(sim.catalog.world.spawn_prices[i])

func _player() -> Vector2:return sim.position_of(sim.state.player)

## Expected outcome of fighting `count` copies of an enemy definition one after another.
func _fight(def: Dictionary,count: int,potions:=0) -> float:
    var s: Dictionary=sim.stats()
    var dps: float=s.damage*(1+s.crit*(s.crit_damage-1))*(1+s.speed)*(1+sim.achievement_damage(int(def.get("index",0))))
    dps*=100.0/(100.0+float(def.defense))
    var taken: float=float(def.damage)/float(def.interval)*100.0/(100.0+s.defense)*(1-s.lifesteal*0)
    var time: float=float(def.hp)/maxf(.01,dps)*count
    var hp: float=float(sim.state.player.hp)+potions*sim.normal("potion").get("heal",25) if sim.quantity("potion")>0 else float(sim.state.player.hp)
    return hp/maxf(.01,taken*time)   # >1 means survives

func _decide() -> void:
    var p: Dictionary=sim.state.player
    if p.hp<=0:sim.movement=Vector2.ZERO;return
    _manage_items()
    _shop()
    _collect()
    _missions()
    # Stage advance when the next stage looks farmable.
    if sim.state.unlocked_stage>sim.state.stage and not sim.campaign.in_combat() and policy!="prestige":
        var next: Dictionary=sim.catalog.stages[sim.state.stage]
        var weakest: Dictionary=sim.enemy_definition(int(next.groups[0]),0).duplicate()
        if _fight(weakest,3)>1.3 or policy=="rush":
            if sim.campaign.camp_action(int(sim.state.stage)+1,0,true):
                mark("enter_stage_%d" % sim.state.stage);_plan_waypoints();target_spot=Vector2.INF;return
    if p.hp<sim.stats().hp*.45 and sim.quantity("potion")>0 and sim.state.use_cd<=0 and sim.campaign.in_combat():sim.use_item("potion")
    for i in range(1+sim.level("skill_slots")):sim.campaign.cast(i)
    # Fight anything already fighting us.
    # While committed to a boss, walk past chasers (the player outpaces them; leash resets them).
    if committed<0 or sim.state.player.hp<sim.stats().hp*.6:
        for e in sim.state.enemies:
            if e.hp>0 and e.aggro:sim.movement=Vector2.ZERO;return
    var goal:=_choose_goal()
    # Rest at the nearest owned camp when hurt; a player would too once they know camps heal.
    if sim.campaign.has_method("rest_rate") and sim.state.player.hp<sim.stats().hp*(.55 if not resting else .97):
        resting=true
        var best:=Vector2.INF
        for c in sim.state.spawns:
            var a: Array=sim.campaign.stage().spawns[int(c)]
            if best==Vector2.INF or Vector2(a[0],a[1]).distance_to(_player())<best.distance_to(_player()):best=Vector2(a[0],a[1])
        goal=best
    else:resting=false
    if arg("trace","")!="" and int(sim.state.clock*2)%120==0:
        var near:=INF;var aggro:=0
        for e in sim.state.enemies:
            if e.hp>0:near=minf(near,sim.position_of(e).distance_to(_player()))
            if e.aggro:aggro+=1
        print("TRACE t=%.0f pos=%s goal=%s target=%s near=%.0f aggro=%d hp=%.0f idle=%.1f focus=%d move=%s speed=%.1f windup=%.2f" % [sim.state.clock,_player(),goal,sim.locked_target,near,aggro,sim.state.player.hp,sim.state.player.idle,sim.state.focus,sim.movement,sim.campaign.move_speed(),sim.state.player.windup])
    if goal==Vector2.INF:sim.movement=Vector2.ZERO;return
    # A committed boss attempt starts from the owned camp closest to the arena (World -> Travel),
    # as a player would, instead of walking through every aggressive spot on the way.
    if committed>=0 and sim.campaign.travel_reason(int(sim.state.stage),0)=="":
        var best_camp:=-1;var best_d:=_player().distance_to(goal)-200
        for c in sim.state.spawns:
            var a: Array=sim.campaign.stage().spawns[int(c)]
            if Vector2(a[0],a[1]).distance_to(goal)<best_d:best_d=Vector2(a[0],a[1]).distance_to(goal);best_camp=int(c)
        if best_camp>=0 and sim.campaign.camp_action(int(sim.state.stage),best_camp,true):return
    var offset: Vector2=goal-_player()
    goal_point=goal
    sim.movement=Vector2.ZERO if offset.length()<26 else offset.normalized()

## Expert: farm the best experience per second it can sustain, knows where sites are.
func _expert_goal() -> Vector2:
    if committed>=0 and int(sim.state.run_kills.get(sim.catalog.groups[committed].id,0))==0 and sim.state.player.hp>=sim.stats().hp*.5 and sim.campaign.stage().groups.has(committed):
        return sim.campaign.spot(committed,2)
    committed=-1
    var best:=Vector2.INF;var rate:=-1.0
    var s: Dictionary=sim.stats()
    var dps: float=s.damage*(1+s.crit*(s.crit_damage-1))*(1+s.speed)
    for g in sim.campaign.stage().groups:
        var d: Dictionary=sim.catalog.groups[g]
        if d.boss:
            if int(sim.state.unlocked_stage)==int(sim.state.stage) and sim.campaign.discovered(g):
                var def: Dictionary=sim.enemy_definition(g,2).duplicate();def["index"]=g
                if _fight(def,1,mini(sim.quantity("potion"),6))>1.1 and sim.state.player.hp>=sim.stats().hp*.95:committed=g;return sim.campaign.spot(g,2)
            elif int(sim.state.unlocked_stage)==int(sim.state.stage) and not sim.campaign.discovered(g) and best!=Vector2.INF:
                pass
            continue
        for v in sim.campaign.variants(g):
            var def: Dictionary=sim.enemy_definition(g,v).duplicate();def["index"]=g
            if _fight(def,4)<1.0:continue
            var r: float=sim.group_xp(g,v)/(float(def.hp)/maxf(.01,dps)+1.2)
            if r>rate:rate=r;best=sim.campaign.spot(g,v)
    # Knows the layout: walk to the boss arena once strong enough to see it.
    for g in sim.campaign.stage().groups:
        if sim.catalog.groups[g].boss and not sim.campaign.discovered(g) and int(sim.state.unlocked_stage)==int(sim.state.stage):
            var def: Dictionary=sim.enemy_definition(g,2).duplicate();def["index"]=g
            if _fight(def,1,mini(sim.quantity("potion"),6))>1.1:return sim.campaign.spot(g,2)
    if best==Vector2.INF:
        for g in sim.campaign.stage().groups:
            if not sim.campaign.discovered(g) and not sim.catalog.groups[g].boss:return sim.campaign.spot(g,2)
    return best

func _choose_goal() -> Vector2:
    if policy=="expert":return _expert_goal()
    var best:=-1;var best_variant:=2;var best_level:=-1
    var boss:=-1
    for g in sim.campaign.stage().groups:
        if not sim.campaign.discovered(g):continue
        var d: Dictionary=sim.catalog.groups[g]
        if d.final and sim.state.keys.size()<13:continue
        if d.boss:
            if int(sim.state.run_kills.get(d.id,0))>0 and policy not in ["rush","prestige"]:continue
            var def: Dictionary=sim.enemy_definition(g,2).duplicate();def["index"]=g
            var margin:=_fight(def,1,mini(sim.quantity("potion"),6))
            if margin>(1.05 if policy in ["rush","prestige"] else 1.4) and sim.state.player.hp>=sim.stats().hp*.95:boss=g
            # Prestige hunter: retries a boss whose opportunity is discovered and not ready, at any HP.
            if policy=="prestige":
                for id in sim.state.opportunities:
                    if (id.begins_with("challenge") or id.begins_with("hunter")) and not sim.state.opportunities[id].ready and sim.campaign.boss_goal(id.split("_o")[0],int(id.right(1)))==d.id:boss=g
            continue
        for v in sim.campaign.variants(g):
            var def: Dictionary=sim.enemy_definition(g,v).duplicate();def["index"]=g
            var need:=float(sim.spawn_amount(g)) if d.aggro_mode=="group" else 1.0
            if _fight(def,int(need)*3)>1.0 and int(d.level)>=best_level:
                best=g;best_variant=v;best_level=int(d.level)
    var stage_gate: bool=int(sim.state.unlocked_stage)==int(sim.state.stage)
    # A committed boss attempt continues through fights on the way until HP falls below half.
    if committed>=0 and sim.campaign.stage().groups.has(committed) and int(sim.state.run_kills.get(sim.catalog.groups[committed].id,0))==0 and sim.state.player.hp>=sim.stats().hp*.5:
        return sim.campaign.spot(committed,2)
    committed=-1
    if boss>=0 and stage_gate:
        boss_attempts+=1 if target_spot!=sim.campaign.spot(boss,2) else 0
        committed=boss
        target_spot=sim.campaign.spot(boss,2);return target_spot
    # Explore until every site of the stage is known (a player reading the fog edge).
    var all_known:=true
    for g in sim.campaign.stage().groups:
        if not sim.campaign.discovered(g):all_known=false
    if not all_known and (best<0 or randf_explore()):
        waypoints=waypoints.filter(func(w):return not sim.campaign.cell_known(w))
        if not waypoints.is_empty():
            waypoints.sort_custom(func(a,b):return a.distance_to(_player())<b.distance_to(_player()))
            return waypoints[0]
    if best<0:return Vector2(sim.campaign.stage().spawns[sim.state.spawn][0],sim.campaign.stage().spawns[sim.state.spawn][1])
    var spot: Vector2=sim.campaign.spot(best,best_variant)
    # Within the spot, let auto-attack acquire; stand at its center.
    return spot

func randf_explore() -> bool:
    # Players look around between fights: roughly a fifth of decisions early on.
    return int(sim.state.clock)%300<60

func _manage_items() -> void:
    var best_weapon:="";var best_outfit:="";var bw:=-1.0;var bo:=-1.0
    for id in sim.state.items.keys():
        if sim.quantity(id)<1:continue
        var k: String=sim.catalog.items[id].kind
        if k in ["weapon","outfit","skill","consumable"]:
            if sim.quantity(id)>1 and sim.record(id).merge<100:sim.merge(id,true)
            if sim.record(id).merge>=100 and sim.quantity(id)>=101:sim.evolve(id)
        if k=="weapon" and sim.normal(id).damage>bw:bw=sim.normal(id).damage;best_weapon=id
        if k=="outfit" and sim.normal(id).hp>bo:bo=sim.normal(id).hp;best_outfit=id
        if k=="skill" and not sim.state.skills.has(id):sim.campaign.equip_skill(id)
    if best_weapon!="" and sim.state.weapon!=best_weapon:sim.equip(best_weapon);mark("first_equip")
    if best_outfit!="" and sim.state.outfit!=best_outfit:sim.equip(best_outfit)

func _shop() -> void:
    var st: int=int(sim.state.stage)
    for i in range(sim.campaign.stage().spawns.size()):
        var a: Array=sim.campaign.stage().spawns[i]
        if not sim.state.spawns.has(i) and sim.campaign.cell_known(Vector2(a[0],a[1])) and sim.state.coins>=_camp_price(i):
            if sim.select_spawn(i):mark("first_camp")
    var farm:=-1
    for e in sim.state.enemies:
        if e.hp>0 and e.id==sim.locked_target:farm=int(e.group)
    var wanted: Array=[["movement",-1,3],["respawn",-1,2],["map_detail",st,1]]
    if farm>=0:wanted.append_array([["loot",farm,6],["coin_amount",farm,4],["group_xp",farm,4],["supply_drop",farm,3]])
    if policy=="expert":
        wanted=[["movement",-1,2]]
        if farm>=0:wanted=[["group_xp",farm,8],["coin_amount",farm,2],["loot",farm,2]]+wanted
    if sim.state.unlocked_stage>=2:wanted.append(["cooldown_heal",-1,2])
    var cheapest:=[];var price:=INF
    for w in wanted:
        if sim.level(w[0],w[1])>=w[2] or not sim.upgrade_block_reason(w[0],w[1]).is_empty():continue
        if sim.upgrade_cost(w[0],w[1])<price:price=sim.upgrade_cost(w[0],w[1]);cheapest=w
    # Keep a small reserve for camps/potions.
    if not cheapest.is_empty() and sim.state.coins-price>=10:sim.buy_upgrade(cheapest[0],cheapest[1])
    if sim.state.gear.count("")==0 and sim.state.gems>=sim.upgrade_cost("gear_slots"):sim.buy_upgrade("gear_slots")
    if sim.quantity("potion")<(6 if policy=="expert" else 3) and sim.state.coins>60:sim.purchase_consumable("potion")

func _collect() -> void:
    for drop in sim.state.pickups.duplicate():
        if Vector2(drop.x,drop.y).distance_to(_player())<170 and sim.campaign.cell_known(Vector2(drop.x,drop.y)):
            sim.collect(int(drop.uid))

func _missions() -> void:
    for i in range(sim.state.missions.size()):sim.campaign.claim_mission(i)
    for i in range(16):sim.campaign.claim_main(i)
    for id in sim.state.run_kills:
        if id.begins_with("boss-"):mark("kill_"+id)
    if sim.campaign.counter("kill")>0:mark("first_kill")
    if not sim.campaign.ready_ids().is_empty():mark("first_opportunity_ready_any")
    # Change 5 baselines have no gate: any ready opportunity allowed a reset.
    var allowed: bool=sim.campaign.prestige_block_reason().is_empty() if sim.campaign.has_method("prestige_block_reason") else not sim.campaign.ready_ids().is_empty()
    if allowed:mark("prestige_allowed")
