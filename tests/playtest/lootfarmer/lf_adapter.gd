extends "res://addons/player_profiles/core/adapter_base.gd"
## LootFarmer player-profile integration: the ADAPTER / STRATEGY for player-profiles.contract/1.
## Maps LootFarmer's legitimate player actions onto the generic intents and supplies player-observable
## signals (benefit, confidence, risk, urgency, novelty, cost). The universal engine chooses; this file
## only says what is possible and how to do it. The runtime layer (lootfarmer_adapter.gd, the Phase 1/2
## adapter, unchanged) performs every action through the game's own functions and records the evidence.
##
## Intent mapping (LootFarmer -> generic):
##   claim_rewards     finished daily missions, main objectives, the 30-defeat hunt, the offline receipt
##   recover           rest at a camp (urgency from HP), walk away from a boss it did not choose to fight
##   progress_main     travel to the next unlocked map; Prestige (both milestones that leave content behind)
##   attempt_challenge the map's gate boss (confidence from the survival estimate, potions included)
##   strengthen        farm for experience; wear the best pair; merge; evolve; equip skills; XP / crit / slot
##                     upgrades; Health Potions for a boss attempt
##   improve_economy   Loot / Coin Amount / Gem Chance / Movement / Respawn / spawn upgrades; nearer camps
##   invest_automation Focused Farming, Auto-Collect, Auto-Merge, Auto Use/Buy, automatic skills, mission
##                     Auto-Claim, Merge All, Offline upgrades; switching owned automation on
##   explore           an exploration burst on the current map; Map Details and reveal upgrades
##   complete_optional farm the target of an open daily "defeat" mission; farm toward the next kill
##                     achievement of a type
##   collect           farm a type that drops gear the player does not own yet
##   wait              stand still
## ORACLE LIMITATIONS (documented, not hidden): combat estimates read enemy HP/damage/defense and the
## loot lists from the catalog even before the in-game Reveal Stats / Reveal Drops upgrades are bought; a
## real player learns them by fighting. Positions, fog, discovered spots, found bosses, prices and refusal
## reasons are what the screen shows.

const Runtime:=preload("res://tests/playtest/lootfarmer_adapter.gd")
const Tactics:=preload("res://tests/playtest/lootfarmer/lf_tactics.gd")
const ADAPTER_VERSION:="lootfarmer-adapter-2"
const STRATEGY_VERSION:="lootfarmer-strategy-1"

## Upgrade id -> [intent, benefit prior]. Benefit falls with each level bought (prior / (1 + 0.15*level)).
const UPGRADES:={
    "focus":["invest_automation",.8],"collect":["invest_automation",.7],"merge_gear":["invest_automation",.5],"auto_use":["invest_automation",.4],
    "auto_buy_slots":["invest_automation",.35],"skill_auto_slots":["invest_automation",.4],"mission_claim":["invest_automation",.45],
    "merge_all":["invest_automation",.4],"auto_evolve":["invest_automation",.3],"offline_cap":["invest_automation",.6],
    "offline_coins":["invest_automation",.55],"offline_gems":["invest_automation",.45],"offline_weapon":["invest_automation",.4],
    "offline_outfit":["invest_automation",.4],"offline_consumable":["invest_automation",.3],"offline_skill":["invest_automation",.3],
    "offline_weapon_rate":["invest_automation",.3],"offline_outfit_rate":["invest_automation",.3],"offline_consumable_rate":["invest_automation",.25],
    "offline_skill_rate":["invest_automation",.25],"collect_range":["invest_automation",.3],"collect_batch":["invest_automation",.25],
    "collect_speed":["invest_automation",.25],"gear_merge_speed":["invest_automation",.2],"use_speed":["invest_automation",.2],
    "coin_amount":["improve_economy",.5],"loot":["improve_economy",.5],"gem_chance":["improve_economy",.6],"gem_amount":["improve_economy",.4],
    "supply_drop":["improve_economy",.2],"skill_drop":["improve_economy",.2],"boss_gem_chance":["improve_economy",.2],"boss_gem_amount":["improve_economy",.2],
    "spawn_amount":["improve_economy",.35],"spawn_cooldown":["improve_economy",.3],"respawn":["improve_economy",.25],"movement":["improve_economy",.35],
    "group_xp":["strengthen",.6],"critical_chance":["strengthen",.55],"critical_damage":["strengthen",.45],"skill_slots":["strengthen",.35],
    "cooldown_heal":["strengthen",.2],"cooldown_frost":["strengthen",.2],"cooldown_fire":["strengthen",.2],"cooldown_lightning":["strengthen",.2],
    "cooldown_focus":["strengthen",.2],"cooldown_strike":["strengthen",.2],
    "map_detail":["explore",.5],"reveal_radius":["explore",.35],"reveal_drops":["explore",.3],"reveal_stats":["explore",.2],
    "mission_slots":["complete_optional",.4],
}
const SKILL_UPGRADES:=["skill_slots","skill_auto_slots","offline_skill","offline_skill_rate","cooldown_heal","cooldown_frost","cooldown_fire","cooldown_lightning","cooldown_focus","cooldown_strike"]
## Prestige card effect -> the intent it serves (cards are chosen by the profile's intent weights).
const CARD_INTENTS:={"damage":"strengthen","hp":"strengthen","crit":"strengthen","crit_damage":"strengthen","guard":"strengthen","lifesteal":"strengthen",
    "last_stand":"strengthen","second_wind":"strengthen","cleave":"strengthen","crowd_guard":"strengthen","normal_damage":"strengthen","equipped":"strengthen",
    "merge":"strengthen","obsidian_temper":"strengthen","skill":"strengthen","field_rest":"strengthen","thrifty_evolution":"strengthen",
    "boss_damage":"attempt_challenge","boss_guard":"attempt_challenge","boss_breaker":"attempt_challenge","broken_rally":"attempt_challenge",
    "coins":"improve_economy","normal_coins":"improve_economy","coin_discount":"improve_economy","gem_chance":"improve_economy","mission_coins":"improve_economy",
    "mission_gems":"improve_economy","boss_coins":"improve_economy","boss_gems":"improve_economy","champions_spoils":"improve_economy","movement":"improve_economy",
    "veteran_traveler":"improve_economy","steady_supplies":"improve_economy","supply_chance":"improve_economy","camp_supplies":"improve_economy",
    "offline_coins":"invest_automation","offline_gems":"invest_automation","offline_items":"invest_automation","collection_radius":"invest_automation",
    "gear_chance":"collect","treasure_sense":"collect","twin_find":"collect","reveal":"collect","precise_reroll":"collect","reroll_discount":"collect",
    "normal_xp":"progress_main","boss_xp":"progress_main"}

var rt                      # runtime (lootfarmer_adapter.gd)
var tac                     # tactics (lf_tactics.gd)
var profile: Dictionary={}
var _sig_cache:=""
var _progress:=0.0
var _boss_gap:=false        # the found gate boss is not beatable yet: getting stronger is the visible bottleneck
const GAP_UPGRADES:=["group_xp","critical_chance","critical_damage"]

func setup(runtime) -> void:
    rt=runtime
    tac=Tactics.new()
    tac.setup(rt)

# ---------------------------------------------------------------- identity
func integration_info() -> Dictionary:
    return {"game":"lootfarmer","adapter_version":ADAPTER_VERSION,"strategy_version":STRATEGY_VERSION,"contract":Framework.CONTRACT_VERSION}

func capabilities() -> Dictionary:
    var intents: Dictionary={}
    for i in Framework.INTENTS:intents[i]={"supported":true,"note":""}
    return {"intents":intents,"features":{"sessions":true,"offline":true,"automation":true,"persistence":true}}

func configure(p: Dictionary) -> void:
    profile=p
    tac.configure(p)
    rt.note("strategy",{"tactics":tac.describe()})

func step_seconds() -> float:return 0.1
func tick_seconds() -> float:return 0.5

# ---------------------------------------------------------------- observation
func observe() -> Dictionary:
    var sig: String=rt.progress_signature()
    if sig!=_sig_cache:_sig_cache=sig;_progress+=1.0
    var urgent: Array=[]
    for o in _recover_options():
        if float(o.urgency)>0.0:urgent.append(o)
    return {"progress":_progress,"health":rt.hp_frac(),"area_completion":_area_completion(),"collection_completion":_collection_completion(),
        "resources":{"coins":floorf(rt.coins()),"gems":floorf(rt.gems())},"urgent":urgent}

## Map loot identities (weapons/outfits of the map's types, boss loot included) owned this run.
func _map_loot() -> Array:
    var ids: Array=[]
    for g in rt.stage_groups():
        for v in rt.variants(g):
            for id in rt.enemy(g,v).loot:
                if not ids.has(id) and str(rt.sim.catalog.items[id].kind) in ["weapon","outfit"]:ids.append(id)
    return ids

func _owned(id: String) -> bool:return rt.sim.state.items.has(id)

func _collection_completion() -> float:
    var ids:=_map_loot()
    if ids.is_empty():return -1.0
    var n:=0
    for id in ids:
        if _owned(id):n+=1
    return float(n)/float(ids.size())

## Explored share, first kill achievement on each normal type, and loot identities, averaged.
func _area_completion() -> float:
    var normals:=0
    var achieved:=0
    for g in rt.stage_groups():
        if bool(rt.group(g).boss):continue
        normals+=1
        if rt.lifetime_kills(g)>=25:achieved+=1
    var parts: Array=[float(rt.explored_percent())/100.0]
    if normals>0:parts.append(float(achieved)/float(normals))
    var cc:=_collection_completion()
    if cc>=0.0:parts.append(cc)
    var total:=0.0
    for p in parts:total+=float(p)
    return clampf(total/float(parts.size()),0.0,1.0)

# ---------------------------------------------------------------- options
func options() -> Array:
    var out: Array=[]
    if rt.prestige_batch_open():return out
    var gate: int=tac.gate_boss()
    _boss_gap=gate>=0 and rt.boss_found(str(rt.group(gate).id)) and tac.boss_confidence(gate,rt.quantity("potion"))<float(profile.get("derived",{}).get("required_confidence",0.6))
    out.append_array(_claim_options())
    out.append_array(_recover_options())
    out.append_array(_progress_options())
    out.append_array(_gear_options())
    out.append_array(_upgrade_options())
    out.append_array(_automation_toggle_options())
    out.append_array(_camp_options())
    out.append_array(_boss_options())
    out.append_array(_farm_options())
    out.append_array(_explore_options())
    out.append({"id":"wait","intent":"wait","kind":"activity","feature":"","benefit":0.05,"commitment_s":30.0})
    return out

func _claim_options() -> Array:
    var out: Array=[]
    for i in rt.missions_claimable():out.append({"id":"claim_mission:%d" % i,"intent":"claim_rewards","kind":"instant","feature":"missions","benefit":0.8})
    for i in rt.main_ready():out.append({"id":"claim_main:%d" % i,"intent":"claim_rewards","kind":"instant","feature":"objectives","benefit":0.9})
    if rt.hunt_claimable():out.append({"id":"claim_hunt","intent":"claim_rewards","kind":"instant","feature":"objectives","benefit":0.8})
    if not rt.offline_pending().is_empty():out.append({"id":"claim_offline","intent":"claim_rewards","kind":"instant","feature":"offline","benefit":1.0})
    return out

func _recover_options() -> Array:
    var out: Array=[]
    if not rt.alive():return out
    if rt.boss_aggro() and tac.mode!="boss":
        out.append({"id":"leave_boss","intent":"recover","kind":"activity","feature":"","benefit":1.0,"urgency":1.0,"commitment_s":20.0})
    # A committed boss attempt is not interrupted by resting: potions and the doomed-fight retreat inside the
    # attempt handle HP (the Phase 1 commitment rule). Resting before the attempt is part of the attempt.
    if tac.mode=="boss":return out
    var hp: float=rt.hp_frac()
    if hp<0.6 or tac.mode=="rest":
        out.append({"id":"rest","intent":"recover","kind":"activity","feature":"camp","benefit":0.5,"urgency":clampf((0.6-hp)/0.45,0.0,1.0),"commitment_s":30.0})
    return out

func _progress_options() -> Array:
    var out: Array=[]
    if rt.unlocked_stage()>rt.stage():
        var next: int=rt.stage()+1
        var weakest: int=int(rt.stage_groups(next)[0])
        var block: String=rt.travel_block(next,0)
        if rt.in_combat():block="IN_COMBAT"
        var o:={"id":"travel:%d" % next,"intent":"progress_main","kind":"instant","feature":"travel","family":"travel","benefit":0.9,"milestone":true,"advances":true,
            "confidence":clampf((tac.farm_margin(weakest,2,3)-1.0)/0.6,0.0,1.0),"risk":0.3}
        if block!="":o.eligible=false;o.block=block
        out.append(o)
    var pblock: String=rt.prestige_block()
    if pblock!="NO_READY_PRESTIGE":
        var ready:=0
        var ops: Dictionary=rt.opportunities()
        for k in ops:
            if bool(ops[k]):ready+=1
        var o2:={"id":"prestige","intent":"progress_main","kind":"instant","feature":"prestige","benefit":clampf(0.4+0.2*ready,0.0,1.0),"milestone":true,"advances":true}
        if pblock!="":o2.eligible=false;o2.block=pblock
        elif rt.in_combat() or tac.mode=="boss":o2.eligible=false;o2.block="IN_COMBAT"
        out.append(o2)
    return out

func _power(s: Dictionary) -> float:
    return float(s.damage)*(1.0+float(s.crit)*(float(s.crit_damage)-1.0))*(1.0+float(s.speed))*float(s.hp)*(1.0+float(s.defense)/100.0)

func _gear_options() -> Array:
    var out: Array=[]
    var items: Array=rt.items()
    var mergeable:=false
    for item in items:
        if bool(item.can_merge):mergeable=true
        if bool(item.can_evolve):out.append({"id":"evolve:"+str(item.id),"intent":"strengthen","kind":"instant","feature":"evolve","benefit":0.6})
    if mergeable:out.append({"id":"merge_spares","intent":"strengthen","kind":"instant","feature":"merge","benefit":0.5})
    if tac.mode!="boss":
        var weapons: Array=[""];var outfits: Array=[""]
        for item in items:
            if str(item.kind)=="weapon":weapons.append(str(item.id))
            elif str(item.kind)=="outfit":outfits.append(str(item.id))
        var now_power:=_power(rt.stats_with(rt.weapon(),rt.outfit()))
        var best:=now_power
        for w in weapons:
            for o in outfits:best=maxf(best,_power(rt.stats_with(w,o)))
        if best>now_power*1.0001:
            out.append({"id":"equip_best","intent":"strengthen","kind":"instant","feature":"equip","benefit":clampf((best/maxf(0.001,now_power)-1.0)*2.0,0.2,1.0)})
    var equipped: Array=rt.skills()
    if equipped.has(""):
        for item in items:
            if str(item.kind)=="skill" and not equipped.has(str(item.id)):
                out.append({"id":"equip_skill:"+str(item.id),"intent":"strengthen","kind":"instant","feature":"skills","benefit":0.5});break
    return out

func _upgrade_option(id: String,g: int,intent: String,prior: float,extra: Dictionary={}) -> Dictionary:
    var u: Dictionary=rt.upgrade(id,g)
    if int(u.cap)<=0 or int(u.level)>=int(u.cap):return {}
    var o:={"id":"up:%s:%d" % [id,g],"intent":intent,"kind":"instant","feature":"upgrades","family":"up:"+id,"benefit":prior/(1.0+0.15*int(u.level)),
        "cost":{str(u.currency):float(u.cost)}}
    var block:=str(u.block)
    if block in ["NOT_ENOUGH_COINS","NOT_ENOUGH_GEMS"]:
        o.affordable=false
        var have: float=rt.coins() if str(u.currency)=="coins" else rt.gems()
        o.shortfall=clampf(1.0-have/maxf(1.0,float(u.cost)),0.0,1.0)
    elif block!="":
        o.eligible=false;o.block=block
    for k in extra:o[k]=extra[k]
    return o

func _upgrade_options() -> Array:
    var out: Array=[]
    var skills_seen: bool=rt.skills_seen()
    var farm: int=tac.farm_group
    for id in UPGRADES:
        if SKILL_UPGRADES.has(id) and not skills_seen:continue
        var scope:=str(rt.sim.catalog.upgrades[id].get("scope","global"))
        var g:=-1
        match scope:
            "global":g=-1
            "type","normal_type":
                if farm<0:continue
                g=farm
            "stage":g=rt.stage()
            _:continue
        var o:=_upgrade_option(id,g,str(UPGRADES[id][0]),float(UPGRADES[id][1]),{"bottleneck":_boss_gap and GAP_UPGRADES.has(id)})
        if not o.is_empty():out.append(o)
    # Slots only when a pickup was refused for room, or potions for a boss need one: a visible blocker.
    if tac.need_gear_slot:
        var o:=_upgrade_option("gear_slots",-1,"strengthen",0.7,{"bottleneck":true})
        if not o.is_empty():out.append(o)
    var potion_slot_needed: bool=tac.boss_potions>0 and rt.quantity("potion")==0 and rt.supply_free()==0
    if tac.need_supply_slot or potion_slot_needed:
        var o2:=_upgrade_option("supply_slots",-1,"strengthen",0.6,{"bottleneck":potion_slot_needed})
        if not o2.is_empty():out.append(o2)
    return out

func _automation_toggle_options() -> Array:
    var out: Array=[]
    if rt.upgrade("mission_claim").level>0 and not rt.mission_auto():
        out.append({"id":"auto:mission_claim","intent":"invest_automation","kind":"instant","feature":"automation","benefit":0.8})
    if rt.auto_use_levels()>0:
        var slot: int=rt.supply_slot_of("potion")
        if slot>=0 and not rt.auto_slots().has(slot) and rt.auto_slots().size()<rt.auto_use_levels():
            out.append({"id":"auto:use_potion","intent":"invest_automation","kind":"instant","feature":"automation","benefit":0.7})
    if rt.auto_buy_capacity()>0 and not rt.auto_buy_selection().has("potion") and rt.auto_buy_selection().find("")>=0:
        out.append({"id":"auto:buy_potion","intent":"invest_automation","kind":"instant","feature":"automation","benefit":0.6})
    var capacity: int=rt.automatic_skill_capacity()
    if capacity>0 and _wanted_auto_skills(capacity)!=rt.automatic_skill_slots() and not _wanted_auto_skills(capacity).is_empty():
        out.append({"id":"auto:skills","intent":"invest_automation","kind":"instant","feature":"automation","benefit":0.7})
    return out

func _wanted_auto_skills(capacity: int) -> Array:
    var wanted: Array=[]
    var equipped: Array=rt.skills()
    for i in range(rt.skill_slots()):
        if str(equipped[i])!="" and wanted.size()<capacity:wanted.append(i)
    return wanted

func _work_spot() -> Vector2:
    var gate: int=tac.gate_boss()
    if gate>=0 and rt.group_discovered(gate) and tac.boss_confidence(gate,rt.quantity("potion"))>=0.3:return rt.spot(gate,2)
    if tac.farm_group>=0:return rt.spot(tac.farm_group,tac.farm_variant)
    return Vector2.INF

func _camp_options() -> Array:
    var out: Array=[]
    var work:=_work_spot()
    if work==Vector2.INF:return out
    for camp in rt.camps():
        if bool(camp.owned) or not bool(camp.known) or not tac.camp_useful(camp,work):continue
        var price:=float(camp.price)
        out.append({"id":"camp:%d" % int(camp.index),"intent":"improve_economy","kind":"instant","feature":"camps","family":"camp","benefit":0.45,
            "cost":{"coins":price},"affordable":rt.coins()>=price,"shortfall":clampf(1.0-rt.coins()/maxf(1.0,price),0.0,1.0)})
    return out

func _boss_options() -> Array:
    var out: Array=[]
    tac.boss_potions=0
    var gate: int=tac.gate_boss()
    if gate<0 or not rt.group_discovered(gate) or not rt.boss_found(str(rt.group(gate).id)):return out
    var stock: int=rt.quantity("potion")
    var conf: float=tac.boss_confidence(gate,stock)
    var o:={"id":"boss:"+str(rt.group(gate).id),"intent":"attempt_challenge","kind":"activity","feature":"boss","family":"boss:"+str(rt.group(gate).id),
        "confidence":conf,"risk":0.6,"benefit":0.9,"milestone":true,"bottleneck":true,"commitment_s":150.0}
    if tac.mode=="boss":o.confidence=maxf(conf,1.0)   # a committed attempt is not re-judged mid-fight
    out.append(o)
    # Health Potions that would lift the estimate over what this player needs: a visible, buyable blocker.
    var need: float=float(profile.get("derived",{}).get("required_confidence",0.6))
    var price: int=rt.supply_price("potion")
    if conf<need and price>0 and tac.mode!="boss" and tac.boss_confidence(gate,0)>=0.1:
        for n in range(stock+1,stock+9):
            if tac.boss_confidence(gate,n)>=need:
                tac.boss_potions=n
                var slot_ok: bool=stock>0 or rt.supply_free()>0
                var p:={"id":"buy_potion","intent":"strengthen","kind":"instant","feature":"supplies","benefit":0.8,"bottleneck":true,
                    "cost":{"coins":float(price)},"affordable":rt.coins()>=float(price),"shortfall":clampf(1.0-rt.coins()/maxf(1.0,float(price)),0.0,1.0)}
                if not slot_ok:p.eligible=false;p.block="NO_SUPPLY_SLOT"
                elif rt.in_combat():p.eligible=false;p.block="IN_COMBAT"
                out.append(p)
                break
    return out

## The variant a player farms on a type: the skill loadout while a skill it carries is missing, else the
## two-piece loadout, else the one-piece ones (the Phase 1 rule), among discovered, survivable spots.
func _variant_for(g: int) -> int:
    for v in [3,2,1,0]:
        if not rt.variants(g).has(v) or not rt.spot_discovered(g,v) or tac.farm_margin(g,v,4)<Tactics.FARM_MARGIN:continue
        if v==3 and not rt.missing_skill(g):continue
        return v
    return -1

func _farm_options() -> Array:
    var out: Array=[]
    var rows: Array=[]
    var best_rate:=0.0
    for g in rt.stage_groups():
        if bool(rt.group(g).boss) or not rt.group_discovered(g):continue
        var v:=_variant_for(g)
        if v<0:continue
        var rate: float=tac.xp_rate(g,v)
        best_rate=maxf(best_rate,rate)
        rows.append([g,v,rate,tac.farm_margin(g,v,4)])
    var missions: Array=rt.missions()
    for r in rows:
        var g:=int(r[0]);var v:=int(r[1])
        var gid:=str(rt.group(g).id)
        var risk:=clampf((1.8-float(r[3]))/1.0,0.0,1.0)*0.5
        var base:={"kind":"activity","feature":"farm","family":"farm:"+gid,"risk":risk,"commitment_s":180.0,"payload":[g,v]}
        var xp:=base.duplicate();xp.merge({"id":"farm:%s:%d" % [gid,v],"intent":"strengthen","benefit":float(r[2])/maxf(0.0001,best_rate),
            "bottleneck":_boss_gap and float(r[2])>=0.7*best_rate})
        out.append(xp)
        var unowned:=0
        var loot: Array=rt.enemy(g,v).loot
        for id in loot:
            if not _owned(str(id)):unowned+=1
        if unowned>0:
            var c:=base.duplicate();c.merge({"id":"farm_gear:%s:%d" % [gid,v],"intent":"collect","benefit":0.5,"novelty":float(unowned)/float(loot.size())})
            out.append(c)
        for m in missions:
            if str(m.kind)=="kill" and str(m.target)==gid and not bool(m.claimed) and float(m.progress)<float(m.goal):
                var mo:=base.duplicate();mo.merge({"id":"farm_mission:%s:%d" % [gid,v],"intent":"complete_optional","benefit":0.6,"optional":true})
                out.append(mo);break
        var kills: int=rt.lifetime_kills(g)
        for threshold in [25,100,250,500,1000]:
            if kills<threshold:
                if threshold-kills<=150:
                    var ao:=base.duplicate();ao.merge({"id":"farm_achievement:%s:%d" % [gid,v],"intent":"complete_optional","optional":true,
                        "benefit":clampf(0.3+0.5*float(kills)/float(threshold),0.0,0.8)})
                    out.append(ao)
                break
    return out

func _explore_options() -> Array:
    if rt.boss_aggro() or not tac.unexplored_left():return []
    var hidden:=false
    for g in rt.stage_groups():
        if bool(rt.group(g).boss) and not rt.boss_found(str(rt.group(g).id)):hidden=true
    var farmable:=false
    for g in rt.stage_groups():
        if not bool(rt.group(g).boss) and rt.group_discovered(g) and _variant_for(g)>=0:farmable=true
    var gate: int=tac.gate_boss()
    var gate_hidden: bool=gate>=0 and not rt.boss_found(str(rt.group(gate).id))
    return [{"id":"explore","intent":"explore","kind":"activity","feature":"explore","benefit":clampf(1.0-float(rt.explored_percent())/100.0,0.05,1.0),
        "novelty":0.5 if hidden else 0.1,"bottleneck":not farmable or gate_hidden,"commitment_s":float(tac.P.explore_burst)}]

# ---------------------------------------------------------------- execution
func begin(o: Dictionary) -> Dictionary:
    var id:=str(o.id)
    var parts:=id.split(":")
    var r: Dictionary={"ok":false,"reason":"UNKNOWN_OPTION"}
    match parts[0]:
        "claim_mission":r=rt.claim_mission(int(parts[1]))
        "claim_main":r=rt.claim_main(int(parts[1]))
        "claim_hunt":r=rt.claim_hunt()
        "claim_offline":r=rt.claim_offline()
        "evolve":r=rt.evolve(id.trim_prefix("evolve:"))
        "merge_spares":r=_merge_spares()
        "equip_best":r=_equip_best()
        "equip_skill":r=rt.equip_skill(id.trim_prefix("equip_skill:"))
        "up":r=rt.buy_upgrade(parts[1],int(parts[2]))
        "camp":r=rt.buy_camp(int(parts[1]))
        "buy_potion":r=rt.buy_supply("potion")
        "auto":r=_toggle(parts[1])
        "travel":
            tac.cancel()
            r=rt.travel(int(parts[1]),0)
            if r.ok:tac.reset()
        "prestige":r=_prestige()
        "farm","farm_gear","farm_mission","farm_achievement":
            var g:=int(o.payload[0]);var v:=int(o.payload[1])
            if tac.mode=="farm" and tac.farm_group==g and tac.farm_variant==v:return {"status":"started","reason":"already farming there"}
            tac.cancel()
            r={"ok":tac.start("farm",g,v),"reason":"CANNOT_FARM"}
        "explore":
            if tac.mode=="explore":return {"status":"started","reason":"already exploring"}
            tac.cancel()
            r={"ok":tac.start("explore"),"reason":"NOTHING_TO_EXPLORE"}
        "boss":
            if tac.mode=="boss":return {"status":"started","reason":"attempt in progress"}
            tac.cancel()
            var gate: int=tac.gate_boss()
            r={"ok":gate>=0 and tac.start("boss",gate),"reason":"NO_GATE_BOSS"}
        "rest","leave_boss":
            if tac.mode=="rest":return {"status":"started","reason":"already resting"}
            tac.cancel()
            r={"ok":tac.start("rest"),"reason":"CANNOT_REST"}
        "wait":
            if tac.mode=="wait":return {"status":"started","reason":""}
            tac.cancel()
            r={"ok":tac.start("wait"),"reason":""}
    if not bool(r.ok):return {"status":"rejected","reason":str(r.reason)}
    return {"status":"started" if str(o.kind)=="activity" else "done","reason":""}

func _merge_spares() -> Dictionary:
    if rt.upgrade("merge_all").level>0:
        var all: Dictionary=rt.merge_all()
        if all.ok:return all
    var any:=false
    for item in rt.items():
        if bool(item.can_merge) and rt.merge_copies(str(item.id)).ok:any=true
    return {"ok":any,"reason":"" if any else "NOTHING_TO_MERGE"}

func _equip_best() -> Dictionary:
    var weapons: Array=[""];var outfits: Array=[""]
    for item in rt.items():
        if str(item.kind)=="weapon":weapons.append(str(item.id))
        elif str(item.kind)=="outfit":outfits.append(str(item.id))
    var best_w: String=rt.weapon();var best_o: String=rt.outfit()
    var best:=_power(rt.stats_with(best_w,best_o))
    for w in weapons:
        for o in outfits:
            var score:=_power(rt.stats_with(w,o))
            if score>best*1.0001:best=score;best_w=w;best_o=o
    var ok:=false
    if best_w!=rt.weapon() and best_w!="":ok=rt.equip(best_w).ok or ok
    if best_o!=rt.outfit() and best_o!="":ok=rt.equip(best_o).ok or ok
    return {"ok":ok,"reason":"" if ok else "NO_BETTER_PAIR"}

func _toggle(what: String) -> Dictionary:
    match what:
        "mission_claim":return rt.set_mission_auto(true)
        "use_potion":return rt.bind_auto(rt.supply_slot_of("potion"))
        "buy_potion":return rt.set_auto_buy(rt.auto_buy_selection().find(""),"potion")
        "skills":return rt.assign_automatic_skills(_wanted_auto_skills(rt.automatic_skill_capacity()))
    return {"ok":false,"reason":"UNKNOWN_TOGGLE"}

## Prestige is one transaction: begin, then one card per opportunity, chosen by the profile's intent
## weights (the card effect's intent), ties by the order offered.
func _prestige() -> Dictionary:
    tac.cancel()
    rt.note("prestige_decision",{"awardable":rt.awardable(),"level":rt.level(),"prestiges":rt.prestiges()})
    var r: Dictionary=rt.begin_prestige()
    if not r.ok:return r
    _finish_prestige()
    tac.reset()
    return {"ok":not rt.prestige_batch_open(),"reason":"PRESTIGE_UNFINISHED"}

func _finish_prestige() -> void:
    var weights: Dictionary=profile.get("intent_weights",{})
    var guard:=0
    while rt.prestige_batch_open() and guard<60:
        guard+=1
        var offered: Array=rt.offered_cards()
        if offered.is_empty():break
        var pick: String=str(offered[0].id)
        var best:=-1.0
        for card in offered:
            var w:=float(weights.get(CARD_INTENTS.get(str(card.effect),"strengthen"),0.0))
            if w>best+1e-9:best=w;pick=str(card.id)
        if not rt.choose_card(pick).ok:break

func advance(now: float) -> Dictionary:
    if rt.prestige_batch_open():
        _finish_prestige();tac.reset()
    return tac.tick(now)

func cancel() -> void:tac.cancel()
func steer() -> void:tac.steer()

# ---------------------------------------------------------------- simulation and sessions
func set_clock(unix: float) -> void:rt.set_clock(unix)
func step(dt: float) -> bool:return rt.step(dt)
func blocked_reason() -> String:return rt.blocked_reason()
func failed() -> String:return rt.failed()
func goal_reached(goal: String) -> bool:return rt.goal_reached(goal)
func session_can_end() -> bool:return rt.session_can_end() and tac.mode!="boss"
func leave_session(n: int) -> void:
    tac.cancel()
    rt.leave_session(n)
func return_session(n: int,away_s: float,mode: String) -> String:
    var problem: String=rt.return_session(n,away_s,mode)
    tac.reset()
    return problem
func teardown() -> void:rt.teardown()

# ---------------------------------------------------------------- telemetry (reports only)
func progress_signature() -> String:return rt.progress_signature()
func trace_sample() -> Dictionary:
    var s: Dictionary=rt.trace_sample()
    s.merge({"mode":tac.mode,"why":tac.reason,"farm":tac._name(tac.farm_group),"farm_variant":tac.farm_variant})
    return s
func state_digest() -> String:return rt.state_digest()

func game_summary() -> Dictionary:
    var g: Dictionary=rt.summary()
    g["strategy"]={"version":STRATEGY_VERSION,"tactics":tac.describe(),"tactic_stats":tac.stats.duplicate()}
    return g

func generic_metrics() -> Dictionary:
    var list: Array=[]
    for k in rt.milestones:list.append({"key":str(k),"t":float(rt.milestones[k].t),"c":float(rt.milestones[k].c)})
    list.sort_custom(func(x,y):return float(x.t)<float(y.t) or (float(x.t)==float(y.t) and str(x.key)<str(y.key)))
    var g: Dictionary=rt.summary()
    var automation:=0
    for k in g.automation_upgrades:automation+=int(g.automation_upgrades[k])
    return {"milestones":list,
        "economy":{"coins":{"earned":g.currency.coins.earned_total,"spent":g.currency.coins.spent_total},"gems":{"earned":g.currency.gems.earned_total,"spent":g.currency.gems.spent_total}},
        "automation_owned":automation,"main_milestone_level":int(g.highest_stage_unlocked),"resets":int(g.prestiges),"deaths":int(g.deaths)}
