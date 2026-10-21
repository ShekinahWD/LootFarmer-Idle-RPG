extends Node
## Change 8 behaviour probe. Real main scene and simulation; one named case per changed contract.
## State set directly is labelled. Phase A runs only the build-safety cases (prestige gate, merge
## cap validation, save migration, fog/targeting); Phase C adds the remaining acceptance cases.
var checks:=0
var failures:=0
var sim
var game
func check(ok: bool,label_: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(label_)
func _ready() -> void:call_deferred("run")
func fresh() -> void:
    get_tree().paused=false
    sim.new_profile();sim.state.tutorial.mode="none";sim.suspended=false;SaveService.write_blocked=false;sim.rng.seed=88123;game._close()
func frames(n:=6) -> void:
    for i in range(n):await get_tree().process_frame
func run() -> void:
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim;sim.set_physics_process(false);fresh()
    prestige_gate_checks()
    merge_cap_checks()
    await save_migration_checks()
    fog_checks()
    print("CHANGE_8_CHECKS ",checks," FAILURES ",failures)
    game.queue_free();await get_tree().process_frame
    AudioService.stop_all_sfx()
    await get_tree().create_timer(.1).timeout
    get_tree().quit(1 if failures else 0)

## 4.1 Prestige opens with the first kill; a reset needs a ready opportunity with a card left; the
## card is chosen inside the reset.
func prestige_gate_checks() -> void:
    fresh()
    check(sim.campaign.prestige_block_reason()=="PRESTIGE_LOCKED_FIRST_KILL","New profile: prestige locked until the first kill")
    sim.state.group_kills[0]=1 # labelled: one recorded kill
    check(sim.campaign.prestige_unlocked(),"First kill unlocks Prestige")
    check(sim.campaign.prestige_block_reason()=="NO_READY_PRESTIGE","Unlocked without a ready opportunity: needs one")
    check(sim.state.owned_cards.is_empty(),"No card owned beforehand")
    sim.state.opportunities["hunter_o1"]={"ready":true,"baseline":{},"step":0,"count":0} # labelled: ready opportunity
    check(sim.campaign.prestige_block_reason()=="","Ready opportunity with cards: reset allowed in Winter I")
    check(sim.campaign.begin_prestige(),"Batch begins")
    var offered: Array=sim.campaign.offered_cards()
    check(not offered.is_empty(),"Cards offered during the reset")
    check(sim.prestige(offered[0]),"Card chosen during the reset commits")
    check(sim.state.prestiges==1 and sim.state.owned_cards.has(offered[0]),"One reset, one card")
    check(sim.campaign.prestige_unlocked(),"Lifetime kills keep Prestige open after the reset")

## 3.1-3.3 Outfits and skills merge their own copies up to the cap; weapons keep ^100.
func merge_cap_checks() -> void:
    fresh()
    sim.add_item("unit-blue-cap_outfit",600)
    check(sim.merge_cap("unit-blue-cap_outfit")==500 and sim.merge_cap("wood_sword")==100,"Copy cap 500, weapon cap 100")
    check(sim.merge("unit-blue-cap_outfit",true) and int(sim.record("unit-blue-cap_outfit").merge)==500,"Merge all reaches ^500")
    check(not sim.merge("unit-blue-cap_outfit"),"No merge past the cap")
    var hp: float=sim.normal("unit-blue-cap_outfit").hp
    check(hp>45 and hp<60,"^500 outfit is bounded (%.1f HP, about 6.2x base)" % hp)
    check(str(sim.catalog.items["unit-blue-cap_outfit"].next)=="" and not sim.evolve("unit-blue-cap_outfit"),"Outfits do not evolve")
    check(sim.campaign.valid_snapshot(JSON.parse_string(JSON.stringify(sim.snapshot()))),"A ^500 save validates")

## Older saves load without a reset; Change 8 fields are derived, never copied from live state.
func save_migration_checks() -> void:
    fresh()
    sim.add_item("skill_frost",1);sim.state.group_kills[0]=3
    var snap: Dictionary=JSON.parse_string(JSON.stringify(sim.snapshot()))
    for key in ["skills_seen","discovered_spots","camps_known"]:snap.erase(key) # labelled: Change 7 save
    sim.state.skills_seen=["heal"] # live state that must not leak into the load
    sim.restore(snap)
    await frames(2)
    check(SaveService.last_load_result not in ["development_reset","invalid_profile_reset"],"Change 7 save loads without a reset")
    check(sim.state.skills_seen==["frost"],"Owned skill backfills skills_seen (live state not copied)")
    check(sim.quantity("skill_frost")==1,"Items kept")

## 5.1 Permanent reveal vs momentary vision.
func fog_checks() -> void:
    fresh()
    var rules=sim.campaign.fog_rules
    check(is_equal_approx(rules.player_radius,48.0) and is_equal_approx(sim.campaign.vision_radius(),96.0),"Reveal 48 (a third of 144), vision 96")
    var p: Vector2=sim.position_of(sim.state.player)
    var near:=p+Vector2(84,0)
    check(sim.campaign.can_see(near) or sim.campaign.cell_visible(near),"84 units away is in sight")
    check(not sim.campaign.cell_visible(p+Vector2(200,0)),"200 units away is not in sight")
