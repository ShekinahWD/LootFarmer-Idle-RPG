extends RefCounted
## Saved, ordered tutorial outcomes. Gameplay time pauses with the simulation and survives reloads.
## Presentation asks next_step(); only successful actions and explicit acknowledgements finish steps.
var sim
const STEPS:=["move","kill","collect","equip","close_equip","merge","close_merge","mission_wait","missions","close_missions","upgrade_wait","player_upgrade","close_upgrade","camp","boss_find","boss_preparation","boss_farm","expand_inventory","close_inventory","potion_buy","potion_use","prestige_intro","boss_win","world_intro","travel_intro","milestones_intro","winter_two","tutorial_final"]

func _init(owner) -> void:sim=owner

func data() -> Dictionary:
    var t: Dictionary=sim.state.tutorial
    if not t.get("flow") is Dictionary:
        t.flow={"done":[],"times":{},"gem_grant":false,"supply_grant":false,"boss_kills":-1,"final_seconds":0.0}
        # Existing players beyond the introductory map receive just its final explanation.
        if int(sim.state.stage)>=2:t.flow.done=STEPS.slice(0,STEPS.size()-1)
    return t.flow

func active() -> bool:return sim.state.tutorial.mode=="guided" and not complete()
func complete() -> bool:return data().done.has("tutorial_final")
func rules() -> Dictionary:return sim.catalog.progression.change20
func now() -> float:return float(sim.state.playtime_total)
func mark(id: String) -> void:
    var f:=data()
    if f.done.has(id):return
    f.done.append(id);f.times[id]=now();sim.touch();SaveService.mark_dirty()

func action(kind: String,id: String) -> void:
    if sim.state.tutorial.mode!="guided":return
    match kind:
        "equip":
            if sim.state.weapon!="" or sim.state.outfit!="":mark("equip")
        "merge":
            if sim.catalog.items[id].kind in ["weapon","outfit"]:mark("merge")
        "mission":mark("missions")
        "upgrade":
            if sim.catalog.upgrades.has(id) and sim.catalog.upgrades[id].scope=="global":mark("player_upgrade")
        "supply_buy":
            if id=="potion":mark("potion_buy")

func panel_closed(panel: String) -> void:
    if not active():return
    var f:=data()
    for pair in [["item","equip","close_equip"],["item","merge","close_merge"],["missions","missions","close_missions"],["upgrades","player_upgrade","close_upgrade"],["upgrades","expand_inventory","close_inventory"]]:
        if panel==pair[0] and f.done.has(pair[1]):mark(pair[2])

func acknowledge(id: String) -> void:
    if next_step()!=id:return
    if id=="tutorial_final" and float(data().final_seconds)<float(rules().final_delay):return
    if id not in ["boss_preparation","prestige_intro","world_intro","travel_intro","milestones_intro","tutorial_final"]:return
    mark(id)
    if id=="boss_preparation" and not sim.state.tutorial.seen.has(id):sim.state.tutorial.seen.append(id)
    if id=="tutorial_final":sim.campaign.onboarding.reveal_all(true)

func shown(seconds: float) -> void:
    if active() and next_step()=="tutorial_final":
        data().final_seconds=minf(float(rules().final_delay),float(data().final_seconds)+seconds)
        SaveService.mark_dirty()

func next_step() -> String:
    if not active_mode():return ""
    var f:=data()
    for id in STEPS:
        if f.done.has(id):continue
        var satisfied:=false
        match id:
            "move":satisfied=sim.campaign.counter("kill")>0 or sim.position_of(sim.state.player).distance_to(sim.campaign.onboarding.rules.path_target)<=sim.campaign.onboarding.rules.path_reach
            "kill":satisfied=sim.campaign.counter("kill")>0
            "collect":satisfied=not sim.state.items.is_empty()
            "equip":satisfied=sim.state.weapon!="" or sim.state.outfit!=""
            "merge":satisfied=sim.state.items.values().any(func(r):return int(r.merge)>0)
            "mission_wait":satisfied=now()-float(f.times.get("merge",now()))>=float(rules().mission_delay)
            "missions":satisfied=sim.campaign.counter("mission")>0 or not sim.state.main_claimed.is_empty()
            "upgrade_wait":satisfied=now()-float(f.times.get("close_missions",now()))>=float(rules().upgrade_delay)
            "player_upgrade":satisfied=sim.campaign.onboarding.player_purchase()
            "camp":satisfied=sim.campaign.counter("camp")>0
            "boss_find":satisfied=sim.campaign.prestige_unlocked()
            "boss_farm":
                if int(f.boss_kills)<0:f.boss_kills=int(sim.campaign.counter("kill"));SaveService.mark_dirty()
                satisfied=int(sim.campaign.counter("kill"))-int(f.boss_kills)>=int(rules().post_boss_kills)
            "expand_inventory":
                satisfied=sim.level("gear_slots")>0
                if not satisfied and not f.gem_grant:
                    var grant:=maxf(0,sim.upgrade_cost("gear_slots")-float(sim.state.gems))
                    sim.state.gems+=grant;f.gem_grant=true;sim.touch();SaveService.mark_dirty()
            "potion_buy":
                satisfied=sim.quantity("potion")>0 or int(sim.state.supply_uses.get("potion",0))>0
                if not satisfied and not sim.can_add("potion") and not f.get("supply_grant",false):
                    sim.state.gems+=maxf(0,sim.upgrade_cost("supply_slots")-float(sim.state.gems))
                    f.supply_grant=true;sim.touch();SaveService.mark_dirty()
            "potion_use":satisfied=int(sim.state.supply_uses.get("potion",0))>0
            "boss_win":satisfied=sim.campaign.first_boss_defeated()
            "winter_two":satisfied=int(sim.state.stage)>=2
        if satisfied:mark(id);continue
        return id
    return ""

func active_mode() -> bool:return sim.state.tutorial.mode=="guided"

func feature_allowed(feature: String) -> bool:
    if not active():return true
    var f:=data()
    match feature:
        "missions":return f.done.has("mission_wait")
        "upgrades":return f.done.has("upgrade_wait")
        "world","enemy":return f.done.has("close_upgrade")
        "objective":return f.done.has("boss_preparation")
        "prestige":return f.done.has("potion_use")
    return true

func normalize(out: Dictionary) -> void:
    if out.get("items") is Dictionary:
        for id in out.items:
            if out.items[id] is Dictionary and out.items[id].has("auto_merge_excluded"):
                out.items[id].auto_merge_excluded=out.items[id].auto_merge_excluded==true
    if not out.get("tutorial") is Dictionary:return
    var t: Dictionary=out.tutorial
    if not t.get("flow") is Dictionary:
        t.erase("flow");return
    var f: Dictionary=t.flow
    var done: Array=[]
    if f.get("done") is Array:
        for id in f.done:
            if id is String and STEPS.has(id) and not done.has(id):done.append(id)
    if done.has("potion_buy") and not done.has("close_inventory"):done.append("close_inventory")
    f.done=done
    if not f.get("times") is Dictionary:f.times={}
    for id in f.times.keys():
        if not STEPS.has(id) or not sim.campaign.number(f.times[id]):f.times.erase(id)
        else:f.times[id]=clampf(float(f.times[id]),0,float(out.get("playtime_total",0)))
    for id in done:
        if not f.times.has(id):f.times[id]=float(out.get("playtime_total",0))
    f.supply_grant=f.get("supply_grant",false)==true
    f.gem_grant=f.get("gem_grant",false)==true
    f.boss_kills=maxi(-1,int(f.get("boss_kills",-1))) if sim.campaign.number(f.get("boss_kills",-1)) else -1
    f.final_seconds=clampf(float(f.get("final_seconds",0)),0,float(rules().final_delay)) if sim.campaign.number(f.get("final_seconds",0)) else 0.0
