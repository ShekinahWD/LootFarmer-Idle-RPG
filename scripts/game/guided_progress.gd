extends RefCounted
## Saved, ordered tutorial outcomes. Gameplay time pauses with the simulation and survives reloads.
## Presentation asks next_step(); only successful actions and explicit acknowledgements finish steps.
var sim
## Change 35: "target" (drag from the hero to an enemy and release) follows the path walk and comes
## before the first kill. Only a successful manual selection completes it (action "target", from
## sim.select_target); see target_unavailable() for the one escape.
## Change 61 (approved interactive Guided flow): every lesson is finished by its real action or state.
## - gear_bonus: open Stats (where stored gear's share is listed) and close it again.
## - offline_rewards: open Player Upgrades -> Offline (no purchase, no offline wait).
## - expand_inventory / potion lessons now come before the Snowman.
## - respawn_select: Select the new camp as the respawn camp; camp_travel: travel to another owned
##   Winter I camp (travel never changes the respawn camp, campaign.camp_action).
## - boss_find (found, not defeated) -> map_details (buy Map Details rank 1) -> enemy_pins (tap a real
##   enemy marker on the World map) -> hunt_follow / hunt_farm / hunt_claim (the one-time 30-defeat
##   mission, campaign.hunt_*) -> prestige_follow (follow hunter_o1, ready on the first Snowman defeat)
##   -> boss_win -> world_open (open World) -> winter_two (travel) -> prestige_optional (open Prestige
##   and close it, or Prestige) -> tutorial_final (unchanged).
## The old acknowledgement cards (boss_preparation, prestige_intro, world_intro, travel_intro,
## milestones_intro) and the fixed boss_farm kill count are gone; normalize() migrates saves.
const STEPS:=["move","target","kill","collect","equip","close_equip","gear_bonus","merge","close_merge","mission_wait","missions","close_missions","upgrade_wait","player_upgrade","offline_rewards","close_upgrade","expand_inventory","close_inventory","potion_buy","potion_use","camp","respawn_select","camp_travel","boss_find","map_details","enemy_pins","hunt_follow","hunt_farm","hunt_claim","prestige_follow","boss_win","world_open","winter_two","prestige_optional","tutorial_final"]
## Steps a Change 61 save records as passed when a pre-Change 61 Guided save had already defeated the
## Snowman: its first-boss lessons are behind it, so it never goes back to them (the mission and the
## Prestige card stay ordinary content in Missions and Prestige).
const PRE_BOSS_NEW:=["gear_bonus","offline_rewards","respawn_select","camp_travel","map_details","enemy_pins","hunt_follow","hunt_farm","hunt_claim","prestige_follow"]
const FLOW_VERSION:=61
const FIRST_BOSS_OPPORTUNITY:="hunter_o1"

func _init(owner) -> void:sim=owner

func data() -> Dictionary:
    var t: Dictionary=sim.state.tutorial
    if not t.get("flow") is Dictionary:
        t.flow={"done":[],"times":{},"wait_seconds":{},"gem_grant":false,"supply_grant":false,"final_seconds":0.0,"version":FLOW_VERSION}
        # Existing players beyond the introductory map receive just its final explanation.
        if int(sim.state.stage)>=2:t.flow.done=STEPS.slice(0,STEPS.size()-1)
    return t.flow

func active() -> bool:return sim.state.tutorial.mode=="guided" and not complete()
func complete() -> bool:return data().done.has("tutorial_final")
func rules() -> Dictionary:return sim.catalog.progression.change20
func now() -> float:return float(sim.state.playtime_total)

## Use real, unscaled frame seconds while the game is active. Physics _step() caps dt to 0.1,
## so under Android frame drops its playtime clock can advance much slower than wall time.
## The accumulated seconds are saved; pauses/background time never count.
func advance_waits(seconds: float) -> void:
    if not active() or seconds<=0.0:return
    var f:=data()
    if not f.get("wait_seconds") is Dictionary:f.wait_seconds={}
    for pair in [["merge","mission_wait","mission_delay"],["close_missions","upgrade_wait","upgrade_delay"]]:
        if not f.done.has(pair[0]) or f.done.has(pair[1]):continue
        var limit: float=float(rules()[pair[2]])
        var previous: float=float(f.wait_seconds.get(pair[1],0.0))
        if previous>=limit:continue
        f.wait_seconds[pair[1]]=minf(limit,previous+seconds)
        SaveService.mark_dirty()
func mark(id: String) -> void:
    var f:=data()
    if f.done.has(id):return
    f.done.append(id);f.times[id]=now();sim.touch();SaveService.mark_dirty()

func action(kind: String,id: String) -> void:
    if sim.state.tutorial.mode!="guided":return
    var f:=data()
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
        "target":mark("target")
        # Change 61: travel to another owned camp of the same map, once the respawn camp is chosen.
        "camp_travel":
            if f.done.has("respawn_select") and int(sim.state.stage)==1:mark("camp_travel")
        # A real enemy marker tapped on the World map (map_view.marker_tapped).
        "pin":
            if f.done.has("map_details"):mark("enemy_pins")

## Change 61: panels the lessons ask the player to look at. Called by game_ui each time a panel (or an
## Upgrades tab) is shown, so only the real screen counts, never a guide acknowledgement.
func panel_opened(panel: String,tab:=-1) -> void:
    if not active():return
    var f:=data()
    match panel:
        "stats":
            if f.done.has("close_equip") and not f.get("stats_viewed",false):f.stats_viewed=true;SaveService.mark_dirty()
        "upgrades":
            if tab==4 and f.done.has("player_upgrade"):mark("offline_rewards")
        "world":
            if f.done.has("boss_win") and sim.campaign.first_boss_defeated():mark("world_open")
        "prestige":
            if f.done.has("winter_two") and not f.get("prestige_viewed",false):f.prestige_viewed=true;SaveService.mark_dirty()

func panel_closed(panel: String) -> void:
    if not active():return
    var f:=data()
    for pair in [["item","equip","close_equip"],["item","merge","close_merge"],["missions","missions","close_missions"],["upgrades","offline_rewards","close_upgrade"],["upgrades","expand_inventory","close_inventory"]]:
        if panel==pair[0] and f.done.has(pair[1]):mark(pair[2])
    if panel=="stats" and f.get("stats_viewed",false):mark("gear_bonus")
    if panel=="prestige" and f.get("prestige_viewed",false) and f.done.has("winter_two"):mark("prestige_optional")

## The Prestige reset is held back in Guided until its optional-Prestige lesson in Winter II.
func prestige_allowed() -> bool:
    return not active() or data().done.has("winter_two")

## A Prestige begun at the optional lesson completes it before the reset (the tutorial is kept).
func prestige_started() -> void:
    if active() and data().done.has("winter_two"):mark("prestige_optional")

func acknowledge(id: String) -> void:
    if next_step()!=id:return
    if id=="tutorial_final" and float(data().final_seconds)<float(rules().final_delay):return
    if id!="tutorial_final":return
    mark(id)
    sim.campaign.onboarding.reveal_all(true)

## Change 35 escape: the targeting lesson needs a living enemy in sight. The guide reports active
## seconds in which none is (target_find); after OnboardingRules.target_escape_seconds of them the step
## is recorded as passed (target_skipped) so the tutorial never waits on an empty map. Time with a
## targetable enemy in sight never counts, so ordinary play still has to make the real gesture.
func target_unavailable(seconds: float) -> void:
    if not active() or seconds<=0.0 or next_step()!="target":return
    var f:=data()
    var limit: float=sim.campaign.onboarding.rules.target_escape_seconds
    f.target_unavailable=minf(limit,float(f.get("target_unavailable",0.0))+seconds)
    SaveService.mark_dirty()
    if f.target_unavailable>=limit:
        f.target_skipped=true;mark("target")

func shown(seconds: float) -> void:
    if active() and next_step()=="tutorial_final":
        data().final_seconds=minf(float(rules().final_delay),float(data().final_seconds)+seconds)
        SaveService.mark_dirty()

func first_boss_opportunity() -> Dictionary:
    return sim.state.opportunities.get(FIRST_BOSS_OPPORTUNITY,{})

func next_step() -> String:
    # A finished tutorial has no next step (a pre-Change 61 finished save lacks the new step ids).
    if not active_mode() or complete():return ""
    var f:=data()
    for id in STEPS:
        if f.done.has(id):continue
        var satisfied:=false
        match id:
            "move":satisfied=sim.campaign.counter("kill")>0 or sim.position_of(sim.state.player).distance_to(sim.campaign.onboarding.rules.path_target)<=sim.campaign.onboarding.rules.path_reach
            # Change 35: never by a kill or automatic attack. Only a profile from before this step existed
            # can have "kill" done without it (kill is ordered after target), and it keeps its place.
            "target":satisfied=f.done.has("kill")
            "kill":satisfied=sim.campaign.counter("kill")>0
            "collect":satisfied=not sim.state.items.is_empty()
            "equip":satisfied=sim.state.weapon!="" or sim.state.outfit!=""
            "merge":satisfied=sim.state.items.values().any(func(r):return int(r.merge)>0)
            "mission_wait":satisfied=float(f.wait_seconds.get("mission_wait",0.0))>=float(rules().mission_delay)
            "missions":satisfied=sim.campaign.counter("mission")>0 or not sim.state.main_claimed.is_empty()
            "upgrade_wait":satisfied=float(f.wait_seconds.get("upgrade_wait",0.0))>=float(rules().upgrade_delay)
            "player_upgrade":satisfied=sim.campaign.onboarding.player_purchase()
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
            "camp":satisfied=sim.campaign.counter("camp")>0
            # The selected respawn camp is an additional camp (the arrival camp is the default). Only
            # Select changes it since Change 61, so a non-arrival choice is an explicit selection.
            "respawn_select":satisfied=int(sim.state.stage)!=1 or int(sim.state.spawn)!=0
            "camp_travel":satisfied=int(sim.state.stage)!=1
            "boss_find":satisfied=sim.campaign.prestige_unlocked()
            "map_details":satisfied=sim.level("map_detail",1)>0 or sim.level("map_detail",int(sim.state.stage))>0
            "hunt_follow":
                var followed: Dictionary=sim.campaign.followed_mission()
                satisfied=str(followed.get("kind",""))=="hunt" or sim.campaign.hunt_ready() or bool(sim.campaign.hunt_state().claimed)
            "hunt_farm":satisfied=sim.campaign.hunt_ready() or bool(sim.campaign.hunt_state().claimed)
            "hunt_claim":satisfied=bool(sim.campaign.hunt_state().claimed)
            "prestige_follow":
                var o:=first_boss_opportunity()
                satisfied=str(sim.state.follow)==FIRST_BOSS_OPPORTUNITY or (not o.is_empty() and bool(o.ready)) or sim.state.consumed.has(FIRST_BOSS_OPPORTUNITY) or sim.campaign.first_boss_defeated()
            "boss_win":satisfied=sim.campaign.first_boss_defeated()
            "world_open":satisfied=int(sim.state.stage)>=2
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
        # Change 61: finding the Snowman reveals its objective and Prestige at once.
        "objective","prestige":return f.done.has("boss_find")
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
    var old: Array=f.done if f.get("done") is Array else []
    var done: Array=[]
    for id in old:
        if id is String and STEPS.has(id) and not done.has(id):done.append(id)
    if done.has("potion_buy") and not done.has("close_inventory"):done.append("close_inventory")
    # Change 35: profiles saved before the targeting step existed and already past the first kill keep
    # their place (the step is ordered before "kill", so a newer profile cannot have kill without it).
    if done.has("kill") and not done.has("target"):done.append("target")
    # Change 61: a Guided save from before the restructured flow keeps every outcome it reached (by step
    # id and real state, never by list position). A finished tutorial stays finished; one that had
    # already defeated the Snowman skips the new first-boss lessons; any other continues into the new
    # lessons in order (each skips itself when its real state already holds, e.g. a bought Map Details).
    if int(f.get("version",0))<FLOW_VERSION:
        var boss_defeated: bool=old.has("boss_win")
        if out.get("group_kills") is Array:
            var g: int=sim.campaign.prestige_unlock_group()
            if g>=0 and g<out.group_kills.size() and sim.campaign.number(out.group_kills[g]) and float(out.group_kills[g])>0:boss_defeated=true
        if boss_defeated and not done.has("tutorial_final"):
            for id in PRE_BOSS_NEW:
                if not done.has(id):done.append(id)
            if (old.has("world_intro") or old.has("winter_two")) and not done.has("world_open"):done.append("world_open")
        f.version=FLOW_VERSION
    f.done=done
    if not f.get("times") is Dictionary:f.times={}
    for id in f.times.keys():
        if not STEPS.has(id) or not sim.campaign.number(f.times[id]):f.times.erase(id)
        else:f.times[id]=clampf(float(f.times[id]),0,float(out.get("playtime_total",0)))
    for id in done:
        if not f.times.has(id):f.times[id]=float(out.get("playtime_total",0))
    if not f.get("wait_seconds") is Dictionary:
        # Preserve a partially elapsed wait on existing profiles when switching clock sources.
        f.wait_seconds={}
        for pair in [["merge","mission_wait","mission_delay"],["close_missions","upgrade_wait","upgrade_delay"]]:
            if done.has(pair[0]):
                var elapsed: float=float(out.get("playtime_total",0.0))-float(f.times.get(pair[0],out.get("playtime_total",0.0)))
                f.wait_seconds[pair[1]]=clampf(elapsed,0.0,float(rules()[pair[2]]))
    for id in f.wait_seconds.keys():
        if id not in ["mission_wait","upgrade_wait"] or not sim.campaign.number(f.wait_seconds[id]):
            f.wait_seconds.erase(id)
        else:
            f.wait_seconds[id]=clampf(float(f.wait_seconds[id]),0.0,float(rules().mission_delay if id=="mission_wait" else rules().upgrade_delay))
    f.target_unavailable=clampf(float(f.get("target_unavailable",0)),0,float(sim.campaign.onboarding.rules.target_escape_seconds)) if sim.campaign.number(f.get("target_unavailable",0)) else 0.0
    f.target_skipped=f.get("target_skipped",false)==true
    f.supply_grant=f.get("supply_grant",false)==true
    f.gem_grant=f.get("gem_grant",false)==true
    f.stats_viewed=f.get("stats_viewed",false)==true
    f.prestige_viewed=f.get("prestige_viewed",false)==true
    f.erase("boss_kills")
    f.final_seconds=clampf(float(f.get("final_seconds",0)),0,float(rules().final_delay)) if sim.campaign.number(f.get("final_seconds",0)) else 0.0
