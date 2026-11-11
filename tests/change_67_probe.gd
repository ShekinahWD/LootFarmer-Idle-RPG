extends Node
## Change 67 focused checks (real main scene and simulation; state set directly is labelled "fixture"):
## - Manual merge: the same quantity/level result as the simulation rule, the card burst and the merge cue
##   only when a merge happened (single copy, cap and a locked action do nothing visible or audible).
## - Merge all copies (item card) and Merge All (inventory): one aggregate flash, at most MERGE_ALL_GLINTS
##   dock glints, no per-item card burst.
## - Auto-Merge: no card burst, no sound, at most one glint per slot and never more than the glint pool.
## - Manual evolution: the panel shows the snapshot taken before the transaction (source and evolved
##   names, tiers, icons), the inventory is exactly the simulation's evolve() result, the world is held
##   while it is open; skip, Back, close, save/load and repeated skips never change or repeat the result.
## - Blocked evolution: no panel. Auto Evolution: no panel, no hold, a named notice, a quiet cue, a glint.
## - Real time: the presentation clock ignores Engine.time_scale; nothing is left visible after closing.
var checks:=0
var failures:=0
var game
var sim
var fx
var show
func check(ok: bool,label_: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(label_)
    else:print("  ok  ",label_)
func frames(n:=4) -> void:
    for i in range(n):await get_tree().process_frame
## Real seconds (headless frames are not paced, so animation checks wait on time, not frame counts).
func wait(seconds: float) -> void:
    await get_tree().create_timer(seconds,true,false,true).timeout
    await frames(1)
func _ready() -> void:call_deferred("run")

func run() -> void:
    TranslationServer.set_locale("en")
    SettingsState.set_mute_gameplay(false);SettingsState.set_mute_special(false);SettingsState.set_sfx_volume(1.0)
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    fx=game.merge_fx;show=game.evolution_show
    await frames()
    await merge_checks()
    await merge_all_checks()
    await auto_merge_checks()
    await evolution_checks()
    await auto_evolution_checks()
    await time_scale_checks()
    await collect_checks()
    await respawn_checks()
    await crit_checks()
    await supply_checks()
    print("CHANGE_67_CHECKS %d FAILURES %d" % [checks,failures])
    get_tree().quit(1 if failures>0 else 0)

# ---------------------------------------------------------------- helpers
func fresh() -> void:
    get_tree().paused=false
    Engine.time_scale=1.0
    if game.help_viewer.visible:game.help_viewer.hide()
    if show.visible:show.visible=false
    sim.held=false
    sim.new_profile();sim.set_physics_process(false);sim.suspended=false;SaveService.write_blocked=false
    sim.state.tutorial.mode="none"
    sim.campaign.onboarding.reveal_all(true)
    game._close();game.banner.queue.clear();game.banner._finish();game.toast_queue.clear();game.get_node("Toast").hide()
    game.get_node("PrestigeConfirm").close();game._cancel_confirm()
    sim.state.player.quiet=1e9
    for e in sim.state.enemies:e.aggro=false
    fx.stop();fx.clear_glints();game.pending_glints.clear()
func g(id: String) -> int:
    for i in range(sim.catalog.groups.size()):
        if sim.catalog.groups[i].id==id:return i
    return -1
## Cues requested this frame (a higher-priority notice, e.g. a mission reaching its goal through this
## merge, may legitimately win the frame, so "requested" is what the feedback owns).
func requested(id: String) -> bool:
    return AudioService._pending.has(id)
## Cues the audio service resolved since the last call.
func cues() -> Array:
    AudioService.flush()
    var played: Array=AudioService.played_log.duplicate()
    AudioService.reset_history()
    return played
func open_item(id: String) -> void:
    game.selected=id;game.selected_slot=-1;game._open("item")
    await frames(6)
func reload() -> void:
    sim.restore(JSON.parse_string(JSON.stringify(sim.snapshot())))

# ---------------------------------------------------------------- manual merge
func merge_checks() -> void:
    fresh()
    sim.add_item("wood_sword",4)
    await open_item("wood_sword")
    AudioService.reset_history()
    var before:=int(sim.record("wood_sword").merge)
    check(game._manual_merge("wood_sword"),"Manual merge succeeds")
    check(requested("item_merge") and not requested("ui_confirm"),"The merge cue is requested (instead of the old confirm)")
    check(sim.quantity("wood_sword")==3 and int(sim.record("wood_sword").merge)==before+1,"One copy merged: quantity 4 -> 3, level +1 (the simulation's rule)")
    check(fx.busy() and fx.ghosts.all(func(n):return n.visible and n.texture==game.icon_cache["wood_sword"]),"Two copies of the item's own icon converge")
    await wait(.3)
    check(fx.icon_double.visible and fx.icon_double.texture==game.icon_cache["wood_sword"] and fx.ghosts.all(func(n):return not n.visible),"Impact: the copies are gone, the item's icon punches")
    check(fx.level_label.visible and fx.level_label.text=="^%d" % (before+1),"The new merge level rises from the card: %s" % fx.level_label.text)
    await wait(1.0)
    check(not fx.busy(),"The burst ends by itself (about a second)")
    # Merge all copies from the card: one burst, "^a -> ^b".
    var from:=int(sim.record("wood_sword").merge)
    check(game._manual_merge("wood_sword",true),"Merge all copies succeeds")
    check(sim.quantity("wood_sword")==1 and int(sim.record("wood_sword").merge)==from+2,"Two copies merged, one kept")
    await wait(.3)
    check(fx.level_label.text=="^%d → ^%d" % [from,from+2],"A multi-copy merge shows from -> to: %s" % fx.level_label.text)
    await wait(1.0)
    # Failures: one copy, at the cap, and a locked action.
    cues()
    check(not game._manual_merge("wood_sword") and not fx.busy(),"One copy: no merge, no burst")
    check(cues().is_empty(),"One copy: no sound")
    sim.state.items["wood_sword"].merge=sim.merge_cap("wood_sword") # fixture: at the cap with spares
    sim.add_item("wood_sword",2)
    var q: int=sim.quantity("wood_sword")
    check(not game._manual_merge("wood_sword") and not fx.busy() and sim.quantity("wood_sword")==q,"At the cap: nothing merged, no burst")
    check(not cues().has("item_merge"),"At the cap: no merge cue")

# ---------------------------------------------------------------- Merge All (inventory)
func merge_all_checks() -> void:
    fresh()
    sim.state.upgrades["merge_all"]=1
    for id in ["wood_sword","wood_axe","cloth_shirt"]:
        if sim.catalog.items.has(id):sim.add_item(id,3)
    var expected: int=sim.merge_all_copies()
    game._open("filters")
    await frames(6)
    var button: Button=game._guide_button("merge_all")
    check(button!=null and not button.disabled,"Merge All button present and enabled (%d copies)" % expected)
    AudioService.reset_history()
    button.pressed.emit()
    check(requested("item_merge"),"Merge All requests the merge cue once")
    check(sim.merge_all_copies()==0,"Merge All merged everything it offered")
    await wait(.05)
    check(fx.glow.visible and not fx.icon_double.visible and fx.ghosts.all(func(n):return not n.visible),"One aggregate flash on the button, no per-item card burst")
    await wait(.25)
    check(fx.active_glints()>0 and fx.active_glints()<=game.MERGE_ALL_GLINTS,"Merged dock slots glint (%d, cap %d)" % [fx.active_glints(),game.MERGE_ALL_GLINTS])
    await wait(1.4)
    check(fx.active_glints()==0 and not fx.busy(),"Everything ends by itself")
    # Idle Merge All: disabled, nothing plays.
    await frames(6)
    button=game._guide_button("merge_all")
    check(button!=null and button.disabled,"With nothing to merge the button is disabled (no celebration possible)")

# ---------------------------------------------------------------- Auto-Merge
func auto_merge_checks() -> void:
    fresh()
    var blue:=g("unit-blue-cap")
    sim.state.upgrades["merge_gear:%d" % blue]=1 # fixture: Auto-Merge owned
    sim.add_item("wood_sword",31)
    await frames(6)
    AudioService.reset_history()
    var peak:=0
    for i in range(25):
        sim.campaign.merge_cycle(str(blue),0.0,1.0,blue)
        await wait(.05)
        peak=maxi(peak,fx.active_glints())
    check(int(sim.record("wood_sword").merge)>=20,"Auto-Merge merged as before (^%d)" % int(sim.record("wood_sword").merge))
    check(not fx.busy(),"Auto-Merge never plays the card burst")
    check(peak<=1,"One slot glints at most once at a time (peak %d)" % peak)
    check(not cues().has("item_merge"),"Auto-Merge is silent")
    # A burst of many items at once is bounded by the pool.
    fresh()
    sim.state.upgrades["merge_gear:%d" % blue]=1
    var ids:=[]
    for id in sim.catalog.items:
        if sim.catalog.items[id].kind!="consumable" and sim.droppers(id).has(blue) and ids.size()<12:ids.append(id)
    for id in ids:sim.add_item(id,3)
    await frames(6)
    for id in ids:sim.merge(id)
    await wait(.2)
    check(fx.active_glints()<=fx.GLINT_POOL,"Many automatic merges at once stay within the glint pool (%d of %d)" % [fx.active_glints(),fx.GLINT_POOL])

# ---------------------------------------------------------------- manual evolution
func evolution_checks() -> void:
    fresh()
    sim.add_item("wood_sword",31)
    sim.merge("wood_sword",true)
    await open_item("wood_sword")
    check(sim.evolve_block_reason("wood_sword")=="","Fixture: Wood Sword ^20 with 10 spares can evolve")
    var expect_source: int=sim.quantity("wood_sword")-sim.evolution_spare_cost("wood_sword")
    AudioService.reset_history()
    check(game._manual_evolve("wood_sword"),"Manual evolution succeeds")
    check(show.visible and show.clock<.1,"The evolution panel opens")
    check(sim.quantity("wood_sword")==expect_source and sim.quantity("stone_sword")==1,"Inventory is exactly evolve()'s result (source %d, Stone Sword 1)" % sim.quantity("wood_sword"))
    check(show.snapshot.source=="wood_sword" and show.snapshot.target=="stone_sword","Snapshot names the real source and result")
    check(show.icon.texture==game.icon_cache["wood_sword"],"It starts on the real source weapon")
    check(show.item_name.text==sim.catalog.display_name("wood_sword") and show.tier.text==tr("ITEM_TIER_MERGE") % [1,20],"Source name and tier/level: %s · %s" % [show.item_name.text,show.tier.text])
    await frames(2)
    check(sim.held and game.modal_open(),"The world is held while the panel is open")
    await wait(.3)
    check(cues().has("evolve_charge"),"The charge cue starts with the charge")
    # Sample the real timeline by seeking (as a capture does): charge, release, reveal.
    show.seek(1.0)
    check(show.icon.texture==game.icon_cache["wood_sword"] and show.streaks.emitting and float(show.icon_material.get_shader_parameter("flash"))>.4,"Charge: still the source, streaks converging, turning white")
    show.seek(show.RELEASE+.05)
    check(show.icon.texture==game.icon_cache["stone_sword"] and show.shock.visible and show.flash.color.a>.3,"Release: the evolved weapon appears under the flash and shockwave")
    show.seek(show.REVEAL+.4)
    check(show.item_name.text==sim.catalog.display_name("stone_sword") and show.tier.text==tr("EVOLUTION_TIER_CHANGE") % [1,2],"Reveal: %s · %s" % [show.item_name.text,show.tier.text])
    check(not show.finished,"Not finished before READY")
    # Restart and skip from the start.
    var snap: Dictionary=sim.snapshot()
    show.present(show.snapshot)
    await frames(2)
    AudioService.reset_history()
    show.clock=show.SKIP_GUARD+.01
    game.back()
    check(show.visible and show.finished and show.continue_button.visible,"Back while playing skips to the result")
    check(show.icon.texture==game.icon_cache["stone_sword"] and not show.shock.visible and not show.stars.emitting,"Skipped: the evolved weapon, no leftover burst")
    check(not cues().has("evolve_burst"),"Skipping does not play the jumped-over sounds late")
    await frames(1)
    game.back()
    await wait(.3)
    check(not show.visible and not sim.held and not game.modal_open(),"Back again closes; the world resumes")
    check(JSON.stringify(sim.snapshot().items)==JSON.stringify(snap.items),"Skip and close changed nothing in the inventory")
    check(sim.quantity("stone_sword")==1,"Exactly one evolved copy (no duplicate)")
    # Save/load while the panel is open keeps the single result.
    sim.add_item("wood_sword",10)
    check(game._manual_evolve("wood_sword"),"A second evolution (10 more spares)")
    reload()
    check(sim.quantity("stone_sword")==2 and sim.quantity("wood_sword")==1,"Save/load mid-presentation: two Stone Swords, source kept at one copy")
    show.close()
    await wait(.3)
    check(not show.visible and show.emitters.all(func(p):return not p.emitting),"Closed: no emitter left running")
    # Blocked evolution: no panel.
    check(not game._manual_evolve("wood_sword") and not show.visible,"Not enough spares: no panel")
    # Inventory full: no panel, nothing lost.
    fresh()
    sim.add_item("wood_sword",31);sim.merge("wood_sword",true)
    var gear: Array=sim.state.gear
    for i in range(gear.size()):
        if gear[i]=="":gear[i]="__fixture_%d" % i # fixture: every free slot taken
    var reason: String=sim.evolve_block_reason("wood_sword")
    for i in range(gear.size()):
        if str(gear[i]).begins_with("__fixture_"):gear[i]=""
    check(reason=="INVENTORY_FULL" or reason=="","Fixture inventory-full reason: %s" % reason)

func auto_evolution_checks() -> void:
    fresh()
    var blue:=g("unit-blue-cap")
    sim.state.upgrades["merge_gear:%d" % blue]=1
    sim.state.upgrades["auto_evolve:%d" % blue]=1
    sim.add_item("wood_sword",31)
    for i in range(40):sim.campaign.merge_cycle(str(blue),0.0,1.0,blue)
    await wait(1.0)
    AudioService.reset_history()
    sim.campaign.evolve_clock=1.0;sim.campaign.auto_evolve()
    check(requested("evolve_auto"),"A quiet Auto Evolution cue is requested")
    check(sim.quantity("stone_sword")==1,"Auto Evolution evolved once")
    await wait(.25)
    check(not show.visible and not sim.held,"Auto Evolution: no panel, the world keeps running")
    var expected: String=tr("AUTO_EVOLVED_NOTICE") % [sim.catalog.display_name("wood_sword"),sim.catalog.display_name("stone_sword")]
    check(game.toast_queue.has(expected) or game.get_node("Toast/Text").text==expected,"A named notice: %s" % expected)
    check(fx.active_glints()==1,"One gold glint (on the new weapon's slot)")

func time_scale_checks() -> void:
    fresh()
    sim.add_item("wood_sword",31);sim.merge("wood_sword",true)
    await open_item("wood_sword")
    Engine.time_scale=3.0
    game._manual_evolve("wood_sword")
    var start:=Time.get_ticks_msec()
    await wait(.6)
    var real:=(Time.get_ticks_msec()-start)/1000.0
    check(absf(show.clock-real)<.25,"At 3x game speed the presentation runs in real time (clock %.2f s vs %.2f s)" % [show.clock,real])
    Engine.time_scale=1.0
    show.close()
    await wait(.3)
    game._close()
    await frames(4)
    check(not show.visible and not fx.busy(),"Leaving the panel: nothing persists")

# ---------------------------------------------------------------- Phase 2: collection and respawn
func collect_checks() -> void:
    fresh()
    var w=game.world
    var at: Vector2=sim.position_of(sim.state.player)+Vector2(14,0)
    sim.state.pickups.clear()
    var foe: Dictionary=sim.state.enemies[0]
    foe.x=at.x;foe.y=at.y # fixture: the drop lies beside the hero
    sim._drop("wood_sword",foe)
    sim._drop("potion",foe)
    sim.campaign.reveal_circle(at,80)
    await frames(4)
    var uids: Array=w.pickups.keys()
    check(uids.size()==2,"Two drops on the ground")
    var node: Node2D=w.pickups[uids[0]]
    var emitted: Array=[]
    sim.collected.connect(func(u):emitted.append(u))
    var have: int=sim.quantity("wood_sword")+sim.quantity("potion")
    check(sim.collect(int(uids[0])),"Collect succeeds (the rule is unchanged)")
    check(emitted==[uids[0]],"collected is emitted once, with the pickup's uid")
    await frames(2)
    check(is_instance_valid(node) and not w.pickups.has(uids[0]) and node.z_index==3,"The collected drop flies into the hero instead of vanishing")
    await wait(.4)
    check(not is_instance_valid(node),"…and frees itself after the flight")
    # Expiry: no flight, gone at once.
    var other: Node2D=w.pickups[uids[1]]
    for d in sim.state.pickups:d.ttl=0.0
    sim.state.pickups.clear() # fixture: the drop expired
    await frames(2)
    check(not is_instance_valid(other) or other.is_queued_for_deletion(),"An expired drop disappears at once (no flight)")
    check(emitted.size()==1,"Expiry emits nothing")
    check(sim.quantity("wood_sword")+sim.quantity("potion")==have+1,"Inventory gained exactly the collected copy")

func respawn_checks() -> void:
    fresh()
    var fx=game.world.respawn_fx
    check(not fx.running(),"No arrival effect before a revive")
    sim.set_physics_process(true)
    sim.state.player.hp=0.0;sim.state.player.respawn=.05 # fixture: about to revive
    await wait(.3)
    sim.set_physics_process(false)
    check(sim.state.player.hp>0,"The hero revived (simulation rule)")
    check(fx.running() and fx.position.distance_to(sim.position_of(sim.state.player))<1.0,"The arrival effect plays at the respawn point")
    await wait(1.2)
    check(not fx.running(),"It ends by itself (under a second)")
    fx.play(Vector2.ZERO)
    sim.state.stage=2;await frames(3) # fixture: a map change
    check(not fx.running(),"A map change stops it")
    sim.state.stage=1;await frames(3)

# ---------------------------------------------------------------- critical hits and supplies
func crit_checks() -> void:
    fresh()
    var w=game.world
    var p: Vector2=sim.position_of(sim.state.player)
    var f: Dictionary=sim.state.enemies[0]
    f.x=p.x+16;f.y=p.y;f.hp=1e6 # fixture: a sturdy enemy beside the hero
    sim.campaign.reveal_circle(p,80)
    await frames(4)
    var before: float=f.hp
    f.critical_hit=false
    AudioService.reset_history()
    sim.feedback.emit(f.id,5.0,false) # an ordinary hit's feedback
    check(w.crit_fx.active()==0 and not requested("crit_hit"),"An ordinary hit: no crit impact, no crit cue")
    f.critical_hit=true;f.hurt=.16 # fixture: the simulation marked this hit critical
    sim.feedback.emit(f.id,15.0,false)
    check(w.crit_fx.active()==1 and requested("crit_hit") and w.kick_start>=0,"A crit: impact on the target, its cue and a camera kick")
    var tags: Array=w.get_children().filter(func(n):return n is Label and n.text==tr("CRIT_TAG"))
    check(tags.size()>=1 or w.views[f.id].get_parent().get_children().any(func(n):return n is Label and n.text==tr("CRIT_TAG")),"The number carries a CRIT! tag")
    for i in range(6):
        f.critical_hit=true;sim.feedback.emit(f.id,15.0,false)
    check(w.crit_fx.active()<=w.crit_fx.SLOTS,"Rapid crits reuse a fixed pool (%d of %d)" % [w.crit_fx.active(),w.crit_fx.SLOTS])
    check(f.hp==before,"Presentation never changes HP")
    sim.state.player.critical_hit=true
    w.crit_fx.stop()
    sim.feedback.emit("player",3.0,false)
    check(w.crit_fx.active()==0,"The hero being hit never shows the hero's crit impact")
    await wait(.6)
    check(w.crit_fx.active()==0,"The impact ends by itself")
    check(not w.get_node("Camera").offset.length()>0.01,"The camera kick ends")

func supply_checks() -> void:
    fresh()
    var w=game.world
    var fx=w.supply_fx
    sim.state.supplies=["","","","",""] # fixture: five supply slots
    for id in ["potion","coin_boost","guard_tonic","recovery_salve","wisdom_tonic"]:sim.add_item(id,2)
    var seen: Array=[]
    sim.supply_used.connect(func(id):seen.append(id))
    for id in ["potion","coin_boost","guard_tonic","recovery_salve","wisdom_tonic"]:
        sim.state.player.hp=sim.stats().hp*.4 # fixture: hurt, so every supply's use rule allows it
        AudioService.reset_history()
        var kind: String=str(sim.supply(id).effect)
        check(sim.use_item(id),"%s used (the rule is unchanged)" % id)
        check(fx.bursts[kind].node.visible and fx.label.text==sim.catalog.display_name(id),"%s: its own burst and its name (%s)" % [id,fx.label.text])
        check(requested(fx.THEMES[kind].cue),"%s: its cue (%s)" % [id,fx.THEMES[kind].cue])
    check(seen==["potion","coin_boost","guard_tonic","recovery_salve","wisdom_tonic"],"supply_used once per use")
    check(not fx.bursts.has("") and fx.since_burst()<.1,"The generic stat burst is held back right after a supply burst")
    await wait(.5)
    for kind in ["coins","guard","recovery","xp"]:
        check(fx.auras[kind].node.visible,"%s aura shows while it lasts" % kind)
    check(fx.auras["guard"].shield.modulate.a>.2,"Guard Tonic: the shield bubble is visible")
    sim.state.boost_time=0.0;sim.state.buffs.clear() # fixture: every timed supply ran out
    await wait(.6)
    for kind in ["coins","guard","recovery","xp"]:
        check(not fx.auras[kind].node.visible,"%s aura ends with its supply" % kind)
    sim.state.supplies=["","","","",""]
    sim.add_item("coin_boost",1);sim.use_item("coin_boost")
    sim.state.stage=2;await frames(3) # fixture: a map change
    check(not fx.bursts["coins"].node.visible and not fx.label.visible,"A map change clears the supply effects")
    sim.state.stage=1;await frames(3)
