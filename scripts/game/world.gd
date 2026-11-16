extends Node2D
signal actor_selected(group: int,variant: int)
signal camp_selected(index: int)
var camp_revision: int=-1
var active_stage: int=-1
var scenery: Node2D
var fog: Node2D
const ACTOR=preload("res://scenes/game/actor.tscn")
const ATTACKS={
    "death_scythe": preload("res://assets/PixelPlainsAnimationPack/Onix set/Scythe 7 64x32.png"),
    "wood_sword": preload("res://assets/PixelPlainsAnimationPack/Wood set/Sword 1 64x32.png"),
    "stone_sword": preload("res://assets/PixelPlainsAnimationPack/Iron set/Sword 2 64x32.png"),
    "iron_sword": preload("res://assets/PixelPlainsAnimationPack/Iron set/Sword 2 64x32.png")
}
const PICKUP=preload("res://scenes/game/pickup.tscn")
const GAME_THEME=preload("res://resources/game/theme.tres")
const PICKUP_STYLE=preload("res://resources/game/pickup_style.tres")
## Change 14: placement, scale and layer of every skill effect, per skill (inspector resource).
@export var effects: SkillEffectSet=preload("res://resources/game/skill_effects.tres")
var following_player:=true
var camera_position:=Vector2.ZERO
var sim: LootSimulation
var views: Dictionary={}
var pickups: Dictionary={}
var textures: Dictionary={}
var boss_labels: Dictionary={}
var countdown_clock:=0.0
var weather: Node2D
## Change 60 follow-up: the positive (green) and negative (red) buff bursts on the player (buff_burst.gd).
var buff_bursts: Dictionary={}
## Change 67 (Phase 2): the hero's arrival effect after a revive (respawn_fx.gd), and the pickups the
## player collected since the last frame (uid -> true), which fly into the hero instead of vanishing.
var respawn_fx: Node2D
var collected_uids: Dictionary={}
## Change 67 follow-up: the critical-hit impact (crit_fx.gd), the supply bursts and auras (supply_fx.gd)
## and the small camera kick of a crit (world units, decaying over KICK_TIME real seconds).
var crit_fx: Node2D
var supply_fx: Node2D
var prestige_fx: Node2D
var kick_start:=-1
var kick_time:=.16
var kick_amount:=2.5
const KICK_TIME:=.16
const KICK:=2.5
## Change 67 follow-up: teleport, map travel, respawn selection and boss defeat (world_moments.gd).
var moments: Node2D
var ceremony_fx: Node2D
var arena_fx: Node2D
## Change 83: the enraged Green Alien's aura and its celebration floor (dance_floor.gd, one at a time).
var rage_fx: Node2D
var dance_floor: Node2D
var floor_clock:=0.0
const DANCE_FLOOR=preload("res://scripts/game/dance_floor.gd")
## A boss defeat shakes the camera harder and longer than a crit.
const BOSS_SHAKE:=6.0
const BOSS_SHAKE_TIME:=.45
## Seconds a collected pickup takes to fly into the hero.
const COLLECT_FLIGHT:=.22

## Change 60 follow-up: a stat popup's burst on the player, green for an increase, red for a decrease.
func buff_burst(is_positive: bool) -> void:
    if sim==null:return
    # Change 67 follow-up: a supply that just started shows its own burst (the shield, the coins); the
    # generic green burst of its stat change would only repeat it. Its stat popup still shows.
    if is_positive and supply_fx!=null and supply_fx.since_burst()<1.2:return
    _place_bursts()
    buff_bursts[is_positive].play()

func stop_buff_bursts() -> void:
    for burst in buff_bursts.values():burst.stop()

func _place_bursts() -> void:
    var at: Vector2=views["player"].position if views.has("player") else sim.position_of(sim.state.player)
    for burst in buff_bursts.values():
        if burst.running() or burst.position!=at:burst.position=at

## Change 13 summoning: the existing cast effect, tinted like the helpers, on the summoner (warning)
## and where each helper appears ("summon" and "summon_appear" styles; the sheet is the cast one).

func setup(value: LootSimulation) -> void:
    sim=value
    sim.spell_cast.connect(_spell)
    fog=preload("res://scripts/game/fog_layer.gd").new()
    fog.sim=sim
    fog.z_index=50
    add_child(fog)
    weather=preload("res://scripts/game/season_weather.gd").new()
    weather.sim=sim
    weather.z_index=51
    add_child(weather)
    sim.feedback.connect(_feedback)
    sim.summon_warning.connect(func(id: String)->void:
        if views.has(id) and views[id].disclosed:_effect("summon",views[id].position,id,sim.abilities.helper_tint))
    sim.skill_warning.connect(_warning)
    sim.summoned.connect(_summoned)
    sim.chatter.connect(func(id: String,key: String)->void:
        if views.has(id) and views[id].disclosed:views[id].say(key))
    for id in sim.catalog.items:
        textures[id]=sim.catalog.icon(id)
    reminder=Sprite2D.new()
    reminder.centered=false
    reminder.visible=false
    add_child(reminder)
    for is_positive in [true,false]:
        var burst: Node2D=preload("res://scripts/game/buff_burst.gd").new()
        add_child(burst)
        burst.setup(is_positive)
        buff_bursts[is_positive]=burst
    respawn_fx=preload("res://scripts/game/respawn_fx.gd").new()
    add_child(respawn_fx)
    sim.revived.connect(func()->void:respawn_fx.play(sim.position_of(sim.state.player)))
    sim.collected.connect(func(uid: int)->void:collected_uids[uid]=true)
    crit_fx=preload("res://scripts/game/crit_fx.gd").new()
    add_child(crit_fx)
    supply_fx=preload("res://scripts/game/supply_fx.gd").new()
    supply_fx.setup(sim)
    add_child(supply_fx)
    sim.supply_used.connect(func(id: String)->void:supply_fx.play(id,_player_feet()))
    prestige_fx=preload("res://scripts/game/prestige_fx.gd").new()
    add_child(prestige_fx)
    prestige_fx.setup(sim)
    sim.milestone.connect(func(kind: String,_id: String)->void:
        if kind=="prestiged":prestige_fx.play()
        elif kind=="reset" and prestige_fx!=null:prestige_fx.stop())
    moments=preload("res://scripts/game/world_moments.gd").new()
    add_child(moments)
    sim.traveled.connect(_traveled)
    sim.respawn_selected.connect(_respawn_selected)
    sim.boss_defeated.connect(_boss_defeated)
    # Change 82: the Green Alien unsealing ceremony (13 keys) and its arena barrier.
    ceremony_fx=preload("res://scripts/game/final_ceremony_fx.gd").new()
    ceremony_fx.sim=sim
    ceremony_fx.feet=func(id: String)->Vector2:
        if views.has(id):return views[id].position
        var a: Dictionary=sim._find_actor(id)
        return sim.position_of(a) if not a.is_empty() else Vector2.ZERO
    add_child(ceremony_fx)
    arena_fx=preload("res://scripts/game/arena_fx.gd").new()
    arena_fx.sim=sim
    add_child(arena_fx)
    sim.final_ceremony.connect(_final_ceremony)
    sim.arena_changed.connect(_arena_changed)
    # Change 83: Rage Mode (aura and entry burst) and the victory celebration floor.
    rage_fx=preload("res://scripts/game/rage_fx.gd").new()
    rage_fx.sim=sim
    rage_fx.feet=ceremony_fx.feet
    # Ground level, under the actors (the y-sorted world): the glow shows around the boss, never over the hero.
    rage_fx.z_index=-1
    add_child(rage_fx)
    sim.final_rage.connect(_final_rage)

## Change 24 (Playbook 44): presentation work scales with what is on screen, not with the map.
## - Views whose actor is outside the camera (plus CULL_MARGIN world units) are hidden and skip their
##   per-frame animation; the world still keeps their data current (actor, position, look, fog
##   disclosure), so a view is right the moment it returns. The simulation never reads views.
## - Each enemy loadout's look (textures, tint, scale, name, skill icons) and each player outfit and
##   weapon pair is resolved once and applied only when it changes.
## - Views of actors that leave (a map change, a dissolved helper) are reset and pooled for the next
##   new actor instead of freed and instantiated again.
## - The previous stage scenery is hidden at once and freed over the next frames; stage scenes come
##   from the shared StageScenes cache, likely destinations parsed in the background beforehand.
const STAGE_SCENES=preload("res://scripts/game/stage_scenes.gd")
const MARKER_ART=preload("res://assets/PixelPlains/Items/All v3 (Separated Files, Black Outline)/Item-211.png")
const CULL_MARGIN:=96.0
const VIEW_POOL_LIMIT:=192
const RETIRE_BUDGET:=400
var _view_pool: Array=[]
var _enemy_looks: Dictionary={}
var _player_looks: Dictionary={}
var _look_serial:=0
var _gates: Dictionary={}
var _retired: Array=[]

func _process(_delta: float) -> void:
    if sim==null:
        return
    STAGE_SCENES.poll()
    _dispose_retired()
    _prepare_cached_obstacles()
    countdown_clock+=_delta
    if buff_bursts.values().any(func(b):return b.running()):_place_bursts()
    _update_floor(_delta)
    _update_rage_fx()
    supply_fx.follow(_player_feet(),_delta)
    if countdown_clock>=.2:
        countdown_clock=0
        _boss_countdowns()
    if active_stage!=int(sim.state.stage):
        active_stage=int(sim.state.stage)
        for effect in get_children():
            if effect is AnimatedSprite2D:effect.queue_free()
        respawn_fx.stop()
        if arena_fx!=null and not sim.campaign.arena_active():arena_fx.clear()
        crit_fx.stop()
        supply_fx.stop()
        collected_uids.clear()
        if scenery:_retire(scenery)
        scenery=STAGE_SCENES.scene(active_stage).instantiate()
        scenery.z_index=-2
        add_child(scenery)
        for camp in scenery.get_node("Camps").get_children():
            var label: Label=camp.get_node("Label")
            label.add_theme_constant_override("outline_size",5)
            label.add_theme_color_override("font_outline_color",Color(.04,.04,.06))
        move_child(scenery,0)
        _apply_ambient()
        camp_revision=-1
        follow_player()
        _preload_destinations()
    var seen: Dictionary={"player":true}
    for actor in sim.state.enemies:seen[actor.id]=true
    for id in views.keys():
        if not seen.has(id):
            _release_view(views[id])
            views.erase(id)
    seen.clear()
    _gates.clear()
    var view_rect:=_cull_rect()
    var sight=sim.campaign.sight()
    _update_view(sim.state.player,view_rect,sight)
    for actor in sim.state.enemies:_update_view(actor,view_rect,sight)
    for drop in sim.state.pickups:
        var id:=int(drop.uid)
        seen[id]=true
        if not pickups.has(id):
            var node=PICKUP.instantiate()
            # Change 41: equipment hops in with a tier-coloured ring (resources/game/pickup_style.tres).
            # Only a drop made moments ago arrives that way (ground loot lasts 300 s; a load or a map
            # change shows older drops in place).
            var item: Dictionary=sim.catalog.items[drop.item]
            node.setup(textures[drop.item],str(item.kind),_tier_color(item),id,float(drop.ttl)>=FRESH_DROP_TTL)
            $Pickups.add_child(node)
            pickups[id]=node
        pickups[id].position=Vector2(drop.x,drop.y)
        pickups[id].visible=sight.sees(Vector2(drop.x,drop.y))
        pickups[id].modulate.a=.55 if drop.ttl<30 else 1.0
        # Change 16: a dropped stack is one pile on the ground and says how many copies it holds.
        var count: Label=pickups[id].get_node("Count")
        var amount:=int(drop.get("qty",1))
        count.visible=amount>1
        if amount>1 and count.text!="×"+NumberFormat.count(amount):count.text="×"+NumberFormat.count(amount)
    for id in pickups.keys():
        if not seen.has(id):
            # Change 67 (Phase 2): a collected pickup flies into the hero; an expired one (or one left
            # behind by a map change) still disappears at once.
            if collected_uids.has(id) and pickups[id].visible:_fly_to_player(pickups[id])
            else:pickups[id].queue_free()
            pickups.erase(id)
    collected_uids.clear()
    update_camera()

## Change 59: one pointing hand (the existing GUI pack Hand, copied to assets/ui) reminds the player
## of uncollected loot. Its target is the oldest drop with at least reminder_delay seconds of ground
## time that is sighted and on screen (ties by uid); it shows for reminder_seconds every
## reminder_interval seconds. Ground time is 300 - ttl: pausable play time, never offline time.
## Presentation only: a Sprite2D in the world never takes input, and nothing here touches the sim.
## game_ui calls this every frame (it keeps running while paused) with blocked set while a panel,
## confirmation, Prestige choice or guide surface is in front of the game.
const GROUND_TTL:=300.0
var reminder: Sprite2D
var reminder_uid:=-1
func update_reminder(blocked: bool) -> void:
    if reminder==null:return
    var target: Dictionary={}
    var since:=0.0
    if not (blocked or get_tree().paused or sim.suspended or sim.held):
        var style=PICKUP_STYLE
        var view:=_cull_rect().grow(-CULL_MARGIN-4.0)
        var best_age:=-1.0
        for drop in sim.state.pickups:
            var age: float=GROUND_TTL-float(drop.ttl)
            if age<style.reminder_delay or float(drop.ttl)<=0:continue
            var node=pickups.get(int(drop.uid))
            if node==null or not node.visible or not view.has_point(Vector2(drop.x,drop.y)):continue
            if age>best_age or (age==best_age and int(drop.uid)<int(target.uid)):
                target=drop;best_age=age
        if not target.is_empty():
            since=fmod(best_age-style.reminder_delay,maxf(style.reminder_interval,.1))
            if since>=style.reminder_seconds:target={}
    if target.is_empty():
        if reminder.visible:reminder.visible=false
        reminder_uid=-1
        return
    _place_reminder(target,since,_cull_rect().grow(-CULL_MARGIN-2.0))

## The hand sits off one corner of the icon with its fingertip just outside that corner, so it points
## at the loot without covering it. Its visible art is at most the icon's size. The default side is
## below-right (the art points up-left); near a screen edge it mirrors to a side that fits.
func _place_reminder(drop: Dictionary,since: float,view: Rect2) -> void:
    var style=PICKUP_STYLE
    var node=pickups[int(drop.uid)]
    if reminder.texture!=style.reminder_texture:reminder.texture=style.reminder_texture
    var art: Rect2=style.reminder_art_rect
    var size: float=node.icon_size()
    var k: float=size*style.reminder_size_ratio/maxf(art.size.x,art.size.y)
    var center: Vector2=Vector2(drop.x,drop.y)+node.icon_offset()
    var tex_size: Vector2=reminder.texture.get_size()
    var poke: float=style.reminder_poke*(.5+.5*sin(since*style.reminder_poke_speed))
    var chosen:=Vector2.ONE
    for side in [Vector2(1,1),Vector2(-1,1),Vector2(1,-1),Vector2(-1,-1)]:
        chosen=side
        var tip: Vector2=center+side*(size*.5+style.reminder_gap)
        var near: Vector2=tip+side*(art.position-style.reminder_tip)*k
        var far: Vector2=tip+side*(art.end-style.reminder_tip)*k
        if view.has_point(near) and view.has_point(far):break
    var tip_tex: Vector2=style.reminder_tip
    if chosen.x<0:tip_tex.x=tex_size.x-tip_tex.x
    if chosen.y<0:tip_tex.y=tex_size.y-tip_tex.y
    reminder.flip_h=chosen.x<0
    reminder.flip_v=chosen.y<0
    reminder.scale=Vector2.ONE*k
    reminder.offset=-tip_tex
    reminder.position=center+chosen*(size*.5+style.reminder_gap+poke*.7071)
    reminder.z_index=style.reminder_z
    var fade: float=maxf(style.reminder_fade,.01)
    reminder.modulate.a=clampf(minf(since,style.reminder_seconds-since)/fade,0.0,1.0)*node.modulate.a
    reminder.visible=true
    reminder_uid=int(drop.uid)

## A drop whose remaining ground time is at least this was made within the last half second.
const FRESH_DROP_TTL:=299.5
## The pickup's own node (already drawn, nothing new allocated) moves to the hero's chest, shrinking
## and fading, then frees itself. Game time: it pauses with the world and speeds up with it.
func _fly_to_player(node: Node2D) -> void:
    var target: Vector2=(views["player"].position if views.has("player") else sim.position_of(sim.state.player))+Vector2(0,-9)
    node.set_process(false)
    node.z_index=3
    var t:=node.create_tween().set_parallel(true)
    t.tween_property(node,"position",target,COLLECT_FLIGHT).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
    t.tween_property(node,"scale",Vector2.ONE*.35,COLLECT_FLIGHT).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
    t.tween_property(node,"modulate:a",0.0,COLLECT_FLIGHT*.5).set_delay(COLLECT_FLIGHT*.5)
    t.chain().tween_callback(node.queue_free)

func _tier_color(item: Dictionary) -> Color:
    var colors: Array=sim.catalog.progression.tier_colors
    return Color(colors[clampi(int(item.get("tier",1))-1,0,colors.size()-1)])

## The camera's visible world rectangle this frame, grown by CULL_MARGIN (bosses, overhead stacks).
func _cull_rect() -> Rect2:
    var zoom_factor: float=get_viewport_rect().size.x/360.0*SettingsState.camera_zoom
    var center: Vector2=sim.position_of(sim.state.player) if following_player else camera_position
    var half: Vector2=get_viewport_rect().size/maxf(zoom_factor,.01)*.5
    return Rect2(center-half,half*2).grow(CULL_MARGIN)

func _update_view(actor: Dictionary,view_rect: Rect2,sight) -> void:
    var id: String=actor.id
    var v: LootActorView=views.get(id)
    if v==null:
        v=_take_view()
        views[id]=v
    v.actor=actor
    var pos: Vector2=sim.position_of(actor)
    v.position=pos
    var marker: Control=v._marker
    marker.visible=(id=="player" or id==sim.manual_target) and actor.hp>0
    marker.modulate=Color(1,.75,.2) if id==sim.manual_target else Color(.45,.8,1)
    if id=="player":
        var key: String=str(sim.state.outfit)+"|"+str(sim.state.weapon)
        if not _player_looks.has(key):_player_looks[key]=_visual_look(sim.state.outfit,sim.state.weapon)
        var look: Dictionary=_player_looks[key]
        if v.look_id!=look.id:
            v.look_id=look.id
            _apply_look(v,look)
            v.visual_scale=1.0
        v.max_hp=sim.stats().hp
        v.disclosed=true
    else:
        var group:=int(actor.group)
        var variant:=int(actor.get("variant",2))
        var key:=group*8+variant
        if not _enemy_looks.has(key):_enemy_looks[key]=_enemy_look(group,variant)
        var look: Dictionary=_enemy_looks[key]
        if v.look_id!=look.id:
            v.look_id=look.id
            _apply_look(v,look)
            v.max_hp=look.max_hp
            v.visual_scale=look.visual_scale
            # Change 13: summoned helpers wear a tint. Change 16: bosses show their name in red above
            # the HP bar; any enemy with skills shows one small icon per skill (helpers carry none).
            v.body_tint=look.tint
            v.display_name=look.name
            v.skill_icons=look.icons
        # Change 13: a discovered boss the next map still needs carries the World banner (never before
        # its type is discovered).
        if look.boss:
            if not _gates.has(group):_gates[group]=sim.campaign.gate_required(group)
            v.gate=_gates[group]
        else:v.gate=false
        v.disclosed=sight.sees(pos)
    var onscreen: bool=view_rect.has_point(pos)
    if v.is_processing()!=onscreen:v.set_process(onscreen)
    if not onscreen and v.visible:v.visible=false

func _take_view() -> LootActorView:
    var v: LootActorView
    if not _view_pool.is_empty():
        v=_view_pool.pop_back()
        # Same draw order as a newly added view (y-sort ties fall back to child order).
        $Actors.move_child(v,-1)
    else:
        v=ACTOR.instantiate()
        $Actors.add_child(v)
        v.get_node("Marker").texture=MARKER_ART
    v.look_id=-1
    v.set_process(true)
    return v

func _release_view(v: LootActorView) -> void:
    if _view_pool.size()>=VIEW_POOL_LIMIT:
        v.queue_free()
        return
    v.recycle()
    v.set_process(false)
    _view_pool.append(v)

## Textures of one body and weapon pair (catalog ids before art_id), resolved once.
func _visual_look(body_id: String,weapon_id: String) -> Dictionary:
    var body: String=sim.catalog.art_id(body_id)
    var weapon: String=sim.catalog.art_id(weapon_id)
    var path: String="res://assets/PixelPlains/Characters 24x24/Basic character v2.png"
    if sim.catalog.items.has(body) and sim.catalog.items[body].kind=="outfit":
        path=sim.catalog.items[body].texture
    elif body=="death":
        path="res://assets/PixelPlains/Characters 24x24/Autumn 4 v2.png"
    elif body=="cat":
        path="res://assets/PixelPlains/Characters 24x24/Gato 4 v2.png"
    if not textures.has(path):
        textures[path]=load(path)
    var look: Dictionary={"body":textures[path],
        "attack":load(sim.catalog.items[weapon].attack) if sim.catalog.items.has(weapon) and sim.catalog.items[weapon].has("attack") else ATTACKS.get(weapon),
        "attack_tint":attack_tint(weapon),"weapon":textures.get(weapon)}
    if body=="death":
        look.attack_tint=Color.WHITE
        look.weapon=preload("res://resources/game/death_weapon.tres")
        look.attack=preload("res://assets/PixelPlainsAnimationPack/Onix set/Scythe 7 64x32.png")
    _look_serial+=1
    look["id"]=_look_serial
    return look

func _enemy_look(group: int,variant: int) -> Dictionary:
    var g: Dictionary=sim.enemy_definition(group,variant)
    var look:=_visual_look(g.body,g.weapon)
    look.merge({"max_hp":g.hp,"visual_scale":float(g.visual_scale),"boss":bool(g.boss),
        "tint":sim.abilities.helper_tint if variant==sim.HELPER_VARIANT else Color.WHITE,
        "name":str(g.name) if bool(g.boss) else "","icons":_skill_icons(group,variant,g)})
    return look

func _apply_look(v: LootActorView,look: Dictionary) -> void:
    if v.body_texture!=look.body:v.body_texture=look.body
    v.attack_texture=look.attack
    v.attack_tint=look.attack_tint
    v.weapon_texture=look.weapon

## Likely next destinations, parsed in the background: the next map once it is open, and Winter I
## (where every Prestige starts). The World panel's camp picker requests the map it shows.
func _preload_destinations() -> void:
    if active_stage+1<=int(sim.state.unlocked_stage):STAGE_SCENES.request(active_stage+1)
    if active_stage!=1:STAGE_SCENES.request(1)

## A stage scene that finished loading in the background gets its solid-scenery grid now, one stage
## per frame, so arriving there does not build it in the travel frame.
func _prepare_cached_obstacles() -> void:
    for id in range(1,9):
        if STAGE_SCENES.cached(id) and sim.campaign.prepare_obstacles(id):return

## The previous stage scenery: hidden and frozen now, freed RETIRE_BUDGET nodes per frame from the
## end of its tree (removing last children keeps each free cheap).
func _retire(node: Node) -> void:
    node.visible=false
    node.process_mode=Node.PROCESS_MODE_DISABLED
    _retired.append(node)

func _dispose_retired() -> void:
    var budget:=RETIRE_BUDGET
    while budget>0 and not _retired.is_empty():
        var root: Node=_retired[0]
        if root.get_child_count()==0:
            root.free()
            _retired.pop_front()
            budget-=1
            continue
        var group: Node=root.get_child(root.get_child_count()-1)
        if group.get_child_count()==0:
            group.free()
            budget-=1
            continue
        var item: Node=group.get_child(group.get_child_count()-1)
        budget-=1+item.get_child_count()
        item.free()

## The skill icons of one enemy loadout (cached per type and variant: definitions never change). Changes 84-85:
## campaign.shown_skills, every skill the type can use, including the final boss's Change 13 kit.
var _icon_rows: Dictionary={}
func _skill_icons(group: int,variant: int,def: Dictionary) -> Array:
    var key:=group*8+variant
    if not _icon_rows.has(key):
        var row: Array=[]
        for skill in sim.campaign.shown_skills(def):row.append(textures.get("skill_"+str(skill)))
        _icon_rows[key]=row
    return _icon_rows[key]

## Change 13 overcast: the current weather's ambient tint multiplies the stage art (terrain, scenery,
## props) only; the camps are restored to their own colours so navigation stays as readable. Actors,
## loot, effects, fog and rain are siblings of the stage and are never tinted. No shader, no extra draw.
func _apply_ambient() -> void:
    if scenery==null:return
    var tint: Color=weather.styles[sim.campaign.stage().weather].ambient_tint if weather.styles.has(sim.campaign.stage().weather) else Color.WHITE
    scenery.modulate=tint
    var camps: Node=scenery.get_node_or_null("Camps")
    if camps:camps.modulate=Color(1.0/maxf(tint.r,.01),1.0/maxf(tint.g,.01),1.0/maxf(tint.b,.01))

func _summoned(summoner_id: String,ids: Array) -> void:
    for id in ids:
        var helper:=sim._find_actor(str(id))
        if not helper.is_empty() and sim.campaign.can_see(sim.position_of(helper)):_effect("summon_appear",sim.position_of(helper),"",sim.abilities.helper_tint)
    if views.has(summoner_id) and views[summoner_id].disclosed:AudioService.play("spell_summon")

## Swing-sheet tint from the catalog (attack_tint, Change 12): the stone tier shares the Iron set's
## swing in warm gray so it matches its gray stone icon. White for every other weapon.
func attack_tint(weapon: String) -> Color:
    var tint: Array=sim.catalog.items.get(weapon,{}).get("attack_tint",[])
    return Color(float(tint[0]),float(tint[1]),float(tint[2])) if tint.size()>=3 else Color.WHITE

func _update_camps() -> void:
    if scenery==null or active_stage!=int(sim.state.stage):return
    for i in range(sim.campaign.stage().spawns.size()):
        var camp=scenery.get_node("Camps/Camp%d" % i)
        var owned: bool=sim.state.spawns.has(i)
        var active: bool=int(sim.state.spawn)==i
        camp.visible=sim.campaign.camp_known(i)
        camp.get_node("Fountain").modulate=Color.WHITE if owned else Color(.5,.55,.6)
        camp.get_node("Selected").visible=active
        camp.get_node("Label").text=tr("CAMP_NAME") % (i+1)+(" ✓" if active else ("" if owned else " · "+tr("CAMP_LOCKED_SHORT")))

func update_camera() -> void:
    if sim==null:
        return
    _update_camps()
    var zoom_factor: float=get_viewport_rect().size.x/360.0*SettingsState.camera_zoom
    if following_player:
        camera_position=sim.position_of(sim.state.player)
    var shot:=_cinematic(zoom_factor)
    $Camera.zoom=Vector2.ONE*lerpf(zoom_factor,float(shot.zoom),float(shot.w))
    $Camera.position=camera_position.lerp(shot.pos,float(shot.w))
    # Change 67 follow-up: a critical hit kicks the camera a little (real time, decaying, offset only).
    var kick:=Vector2.ZERO
    if kick_start>=0:
        var u:=(Time.get_ticks_msec()-kick_start)/1000.0/kick_time
        if u<1 and not get_tree().paused:kick=Vector2(randf_range(-1,1),randf_range(-1,1))*kick_amount*(1.0-u)
        elif u>=1:kick_start=-1
    $Camera.offset=kick
    $Camera.force_update_scroll()

## Change 82: two short framings, blended in and out over CINE_BLEND seconds of unpaused time and never saved or
## written to the zoom setting. During the Green Alien ceremony the camera frames the hero and the boss together
## (the keys fly between them); when the arena closes it pulls back to show the whole barrier for ARENA_SHOT
## seconds, then returns to the player's own zoom and follow.
const CINE_BLEND:=.45
## Fractions of the world view's height: where the hero's feet may sit below the centre, and the room above it.
const HERO_BAND:=.12
const TOP_BAND:=.34
const ARENA_SHOT:=1.6
## Change 83: world extent the celebration shot keeps in view (floor rings, fireworks above, caption below).
const FLOOR_SHOT:=Vector2(250,250)
var cine_weight:=0.0
var cine_last: Dictionary={"pos":Vector2.ZERO,"zoom":1.0}
var arena_shot:=0.0
var cine_frame:=-1
func _cinematic(zoom_factor: float) -> Dictionary:
    # update_camera can run several times in one frame (follow, pan, the world's own frame): time advances once.
    var dt: float=0.0 if get_tree().paused or Engine.get_process_frames()==cine_frame else get_process_delta_time()
    cine_frame=Engine.get_process_frames()
    var goal: Dictionary={}
    var view: Vector2=get_viewport_rect().size
    if sim.campaign.celebration_active() and dance_floor!=null:
        # Change 83: the first victory's celebration frames the floor, its dancers, fireworks and caption in the
        # open upper part of the map (above the joystick), then eases back to the player's own zoom and follow.
        var zoom: float=minf(zoom_factor,minf(view.x/FLOOR_SHOT.x,view.y*.62/FLOOR_SHOT.y))
        goal={"pos":dance_floor.position+Vector2(0,-30+view.y*.07/zoom),"zoom":zoom}
    elif sim.campaign.ceremony_active():
        var boss: Dictionary=sim._find_actor(sim.campaign.ceremony_boss)
        if not boss.is_empty():
            var hero:=sim.position_of(sim.state.player)+Vector2(0,-10)
            var top:=sim.position_of(boss)+Vector2(0,-14.0*float(sim.catalog.groups[int(boss.group)].visual_scale))
            # Both in the open upper part of the map (the joystick sits low in the middle): the hero's feet no
            # lower than HERO_BAND below the centre, the boss's head below the top rail.
            var zoom: float=minf(zoom_factor,minf(view.x/(absf(top.x-hero.x)+110.0),view.y*(HERO_BAND+TOP_BAND)/(absf(top.y-hero.y)+60.0)))
            goal={"pos":Vector2((hero.x+top.x)*.5,hero.y+10-view.y*HERO_BAND/zoom),"zoom":zoom}
    elif arena_shot>0 and sim.campaign.arena_active():
        arena_shot-=dt
        var extent: float=sim.campaign.arena_radius()+30.0
        goal={"pos":sim.campaign.arena_center()+Vector2(0,-6),"zoom":minf(zoom_factor,minf(view.x,view.y)/(2*extent))}
    cine_weight=move_toward(cine_weight,1.0 if not goal.is_empty() else 0.0,dt/CINE_BLEND)
    if not goal.is_empty():cine_last=goal
    var w:=cine_weight*cine_weight*(3.0-2.0*cine_weight)
    return {"pos":cine_last.pos,"zoom":cine_last.zoom,"w":w}

func follow_player() -> void:
    following_player=true
    update_camera()

func pan_camera(delta: Vector2) -> void:
    following_player=false
    camera_position-=delta/$Camera.zoom
    camera_position=camera_position.clamp(Vector2.ZERO,Vector2(sim.catalog.world.size[0],sim.catalog.world.size[1]))
    update_camera()

func collect_at(screen_point: Vector2) -> void:
    if sim==null or sim.suspended:
        return
    var point:=get_canvas_transform().affine_inverse()*screen_point
    # Loot gets a small precise target so nearby actors remain selectable.
    var closest: Dictionary={}
    var distance:=14.0
    if not get_tree().paused:
        for drop in sim.state.pickups:
            var d:=Vector2(drop.x,drop.y).distance_to(point)
            if d<distance and sim.campaign.can_see(Vector2(drop.x,drop.y)):
                closest=drop
                distance=d
    if not closest.is_empty():
        sim.collect(int(closest.uid))
        return
    var selected_actor: Dictionary={}
    distance=18.0
    for actor in [sim.state.player]+sim.state.enemies:
        if actor.hp<=0 or sim.is_helper(actor) or (actor.id!="player" and not sim.campaign.can_see(sim.position_of(actor))):
            continue
        var d: float=actor_pick_rect(actor).get_center().distance_to(point)
        if actor_pick_rect(actor).has_point(point) and (selected_actor.is_empty() or d<distance):
            selected_actor=actor
            distance=d
    if not selected_actor.is_empty():
        actor_selected.emit(int(selected_actor.group),int(selected_actor.get("variant",2)))
        return
    for i in range(sim.campaign.stage().spawns.size()):
        var camp_position: Vector2=scenery.get_node("Camps/Camp%d" % i).position
        if not sim.campaign.camp_known(i):continue
        if Rect2(camp_position+Vector2(-36,-58),Vector2(72,86)).has_point(point):
            camp_selected.emit(i)
            return

func _feedback(id: String,amount: float,healing: bool) -> void:
    if views.has(id) and views[id].disclosed:
        var critical: bool=bool(sim._find_actor(id).get("critical_hit",false)) and not healing
        views[id].show_hit(amount,healing,critical,id=="player")
        # Change 67 follow-up: a crit lands visibly harder (impact, camera kick, its own cue).
        if critical and id!="player" and views[id].visible:
            var v: LootActorView=views[id]
            var facing:=signf(v.position.x-_player_feet().x)
            crit_fx.play(v.position+Vector2(0,-10*v.visual_scale),v.visual_scale,facing if facing!=0 else 1.0)
            shake(KICK,KICK_TIME)
            AudioService.play("crit_hit")

## A camera shake of up to amount world units for seconds (real time, decaying, offset only). A
## stronger shake already running is never cut short by a weaker one.
func shake(amount: float,seconds: float) -> void:
    if kick_start>=0 and (Time.get_ticks_msec()-kick_start)/1000.0<kick_time and amount<kick_amount:return
    kick_start=Time.get_ticks_msec()
    kick_amount=amount
    kick_time=seconds

## Change 67 follow-up: a Teleport. Within the map: the cyan blink (where the hero left, then where they
## arrived). To another map: the violet portal at the arrival (game_ui opens the iris over the map).
func _traveled(map_changed: bool,from: Vector2,to: Vector2) -> void:
    if map_changed:
        moments.play("portal",to)
        AudioService.play("travel_map")
    else:
        moments.play("teleport",to,from)
        AudioService.play("travel_camp")

## The respawn camp of this map was chosen: a gold beacon at that camp.
func _respawn_selected(camp: int) -> void:
    var node: Node2D=scenery.get_node_or_null("Camps/Camp%d" % camp) if scenery!=null else null
    var at: Vector2=node.position if node!=null else Vector2(sim.campaign.stage().spawns[camp][0],sim.campaign.stage().spawns[camp][1])
    moments.play("beacon",at)
    AudioService.play("respawn_select")

## A boss fell: the triumph at its body, a strong shake and its cue (only when the player can see it).
func _boss_defeated(id: String,_group: int,at: Vector2) -> void:
    if not (views.has(id) and views[id].disclosed and views[id].visible):return
    var v: LootActorView=views[id]
    moments.play("boss",at+Vector2(0,-10*v.visual_scale),Vector2.INF,clampf(v.visual_scale,1.0,1.6))
    shake(BOSS_SHAKE,BOSS_SHAKE_TIME)
    AudioService.play("boss_defeated")

## Change 82: the ceremony's sound and seal-breaking moment (the keys themselves are ceremony_fx).
func _final_ceremony(phase: String) -> void:
    match phase:
        "start":AudioService.play("final_keys")
        "unseal":
            var boss: Dictionary=sim._find_actor(sim.campaign.ceremony_boss)
            if boss.is_empty():return
            var vs: float=float(sim.catalog.groups[int(boss.group)].visual_scale)
            var at: Vector2=(views[boss.id].position if views.has(boss.id) else sim.position_of(boss))+Vector2(0,-10*vs)
            moments.play("unseal",at,Vector2.INF,clampf(vs/2.0,1.0,1.4))
            shake(BOSS_SHAKE,BOSS_SHAKE_TIME)
            AudioService.play("final_unseal")

## Change 82: the arena barrier closes and opens with the encounter (arena_fx also follows the simulation).
func _arena_changed(active: bool,_reason: String) -> void:
    if active:
        arena_fx.close(sim.campaign.arena_center(),sim.campaign.arena_radius())
        arena_shot=ARENA_SHOT
        AudioService.play("arena_close")
    else:
        arena_fx.open()
        AudioService.play("arena_open")

## The hero's feet: the drawn view when there is one, else the simulation position.
func _player_feet() -> Vector2:
    return views["player"].position if views.has("player") else sim.position_of(sim.state.player)

func actor_pick_rect(actor: Dictionary) -> Rect2:
    var factor: float=1.0 if actor.id=="player" else float(sim.catalog.groups[int(actor.group)].visual_scale)
    return Rect2(sim.position_of(actor)+Vector2(-15,-27)*factor,Vector2(30,32)*factor)

func actor_at_screen(screen_point: Vector2,player_only:=false) -> Dictionary:
    var point:=get_canvas_transform().affine_inverse()*screen_point
    var best: Dictionary={}
    var distance:=22.0
    var candidates: Array=[sim.state.player] if player_only else sim.state.enemies
    for actor in candidates:
        if actor.hp<=0 or (actor.id!="player" and not sim.campaign.can_see(sim.position_of(actor))):
            continue
        var d: float=actor_pick_rect(actor).get_center().distance_to(point)
        if actor_pick_rect(actor).has_point(point) and (best.is_empty() or d<distance):
            best=actor
            distance=d
    return best

func player_screen_position() -> Vector2:
    return get_canvas_transform()*(sim.position_of(sim.state.player)+Vector2(0,-10))

func _spell(actor_id: String,key: String,pos: Vector2) -> void:
    if not sim.campaign.can_see(pos):return
    var style: SkillEffectStyle=effects.style(key)
    # The actor the effect sits on or scales with: the caster for self and caster-centred effects,
    # the hit actor for single-target strikes (campaign.apply_skill records it before emitting).
    var on: String=actor_id if style.anchor in ["caster","caster_ground"] else (sim.cast_target if style.anchor=="target" else "")
    _effect(key,pos,on,Color.WHITE)
    # One semantic cue per cast; the audio service owns the asset, category and repeat throttle.
    AudioService.play("spell_"+key)

## Change 14: a boss's attack wind-up shows a small tinted ground marker where the attack is aimed
## (the "warning" style on the cast sheet), never the skill's own effect or sound: the skill effect
## then plays once, when the attack resolves.
func _warning(_actor_id: String,_key: String,pos: Vector2) -> void:
    if sim.campaign.can_see(pos):_effect("warning",pos,"",Color.WHITE)

## One effect sheet (the catalog skill's effect, or the cast sheet for warnings and summons) placed by
## its SkillEffectStyle: the sheet's contact row on the anchor, lifted to the body when the style says
## so, scaled with the anchored actor when it says so, above or beneath the actors. A "caster" effect
## is a child of the caster's view, so it stays on the feet while the caster moves.
func _effect(key: String,pos: Vector2,on_actor: String,tint: Color) -> AnimatedSprite2D:
    var d: Dictionary=sim.catalog.skills.get(key,sim.catalog.skills.focus)
    var style: SkillEffectStyle=effects.style(key)
    var frames:=SpriteFrames.new()
    frames.set_animation_speed("default",1.0/float(d.frame_time))
    frames.set_animation_loop("default",false)
    var texture: Texture2D=load("res://assets/magic-spells-vfx-lite/%s/%s_sheet.png" % [d.effect,d.effect])
    for i in range(int(d.frames)):
        var atlas:=AtlasTexture.new()
        atlas.atlas=texture;atlas.region=Rect2(i*64,0,64,64)
        frames.add_frame("default",atlas)
    var sprite:=AnimatedSprite2D.new()
    sprite.sprite_frames=frames
    sprite.modulate=tint*style.tint
    var view: LootActorView=views.get(on_actor) if on_actor!="" else null
    var factor: float=style.scale
    var lift: float=style.lift
    if style.scale_with_actor and view!=null:
        factor*=float(view.visual_scale);lift*=float(view.visual_scale)
    sprite.scale=Vector2.ONE*factor
    var offset:=Vector2(0,-lift-(style.contact_y-32.0)*factor)
    if style.anchor=="caster" and view!=null:
        sprite.position=offset
        view.add_child(sprite)
    else:
        sprite.position=pos+offset
        sprite.z_index=effects.above_z if style.above_actors else 0
        add_child(sprite)
    sprite.animation_finished.connect(sprite.queue_free)
    sprite.play()
    return sprite

## Countdown views are keyed by the authoritative saved boss actor, and hidden outside discovered areas.
func _boss_countdowns() -> void:
    var live: Array=[]
    for entry in sim.boss_respawn_countdowns(int(sim.state.stage)):
        if float(entry.remaining)<=0 or not sim.campaign.boss_found(str(sim.catalog.groups[int(entry.group)].id)):continue
        if not sim.campaign.can_see(entry.position):continue
        var key: String=entry.actor_id
        live.append(key)
        if not boss_labels.has(key):
            var label:=Label.new()
            # Change 78: the game theme's MSDF font (a label under a Node2D inherits no theme).
            label.theme=GAME_THEME
            label.mouse_filter=Control.MOUSE_FILTER_IGNORE
            label.add_theme_font_size_override("font_size",32)
            label.scale=Vector2.ONE*.5
            label.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
            label.add_theme_constant_override("outline_size",4)
            label.add_theme_color_override("font_outline_color",Color.BLACK)
            label.z_index=52
            add_child(label);boss_labels[key]=label
        var label: Label=boss_labels[key]
        label.text=tr("BOSS_RESPAWN_TIME") % ceili(entry.remaining)
        label.position=entry.position-Vector2(label.get_combined_minimum_size().x*.25,30)
    for key in boss_labels.keys():
        if not live.has(key):boss_labels[key].queue_free();boss_labels.erase(key)

## Change 83: the Green Alien enraged: the red burst at the boss, a hard shake (the enrage cue is final_audio's).
func _final_rage(id: String) -> void:
    var boss: Dictionary=sim._find_actor(id)
    if boss.is_empty():return
    var vs: float=float(sim.catalog.groups[int(boss.group)].visual_scale)
    var at: Vector2=(views[id].position if views.has(id) else sim.position_of(boss))+Vector2(0,-10*vs)
    moments.play("rage",at,Vector2.INF,clampf(vs/2.0,1.0,1.4))
    shake(BOSS_SHAKE,BOSS_SHAKE_TIME)
    _update_rage_fx()

## The aura follows whichever Green Alien on this map is enraged (state-derived: a reload shows it again).
func _update_rage_fx() -> void:
    if rage_fx==null:return
    for e in sim.state.enemies:
        if sim.campaign.enraged(e) and views.has(e.id) and views[e.id].disclosed:
            rage_fx.follow(str(e.id),float(sim.catalog.groups[int(e.group)].visual_scale))
            return
    rage_fx.follow("",1.0)

## The celebration floor exists exactly while campaign.floor_visible() on this map: created at the victory (or on
## arriving / reloading while the boss is still down), freed when it respawns or the map changes. Owned outfits are
## re-read once a second, so a new outfit joins the dance.
func _update_floor(delta: float) -> void:
    var want: bool=sim.campaign.floor_visible() and sim.campaign.final_home()!=Vector2.INF
    if not want:
        if dance_floor!=null:dance_floor.queue_free();dance_floor=null
        return
    if dance_floor==null:
        dance_floor=DANCE_FLOOR.new()
        dance_floor.sim=sim
        add_child(dance_floor)
        dance_floor.open(sim.campaign.final_home(),sim.campaign.celebration_active())
        floor_clock=0.0
    dance_floor.set_intro(sim.campaign.celebration_active())
    floor_clock+=delta
    if floor_clock>=1.0:
        floor_clock=0.0
        dance_floor.refresh_outfits()
