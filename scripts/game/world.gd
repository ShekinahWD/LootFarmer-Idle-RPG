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
    if countdown_clock>=.2:
        countdown_clock=0
        _boss_countdowns()
    if active_stage!=int(sim.state.stage):
        active_stage=int(sim.state.stage)
        for effect in get_children():
            if effect is AnimatedSprite2D:effect.queue_free()
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
            var icon: Sprite2D=node.get_node("Icon")
            icon.texture=textures[drop.item]
            icon.scale=Vector2.ONE*14.0/maxf(icon.texture.get_width(),icon.texture.get_height())
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
            pickups[id].queue_free()
            pickups.erase(id)
    update_camera()

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

## The skill icons of one enemy loadout (cached per type and variant: definitions never change).
var _icon_rows: Dictionary={}
func _skill_icons(group: int,variant: int,def: Dictionary) -> Array:
    var key:=group*8+variant
    if not _icon_rows.has(key):
        var row: Array=[]
        for skill in def.skills:row.append(textures.get("skill_"+str(skill)))
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
    $Camera.zoom=Vector2.ONE*zoom_factor
    if following_player:
        camera_position=sim.position_of(sim.state.player)
    $Camera.position=camera_position
    $Camera.force_update_scroll()

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
        views[id].show_hit(amount,healing,bool(sim._find_actor(id).get("critical_hit",false)) and not healing,id=="player")

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
