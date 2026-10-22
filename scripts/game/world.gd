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

func _process(_delta: float) -> void:
    if sim==null:
        return
    if active_stage!=int(sim.state.stage):
        active_stage=int(sim.state.stage)
        for effect in get_children():
            if effect is AnimatedSprite2D:effect.queue_free()
        if scenery:remove_child(scenery);scenery.queue_free()
        scenery=load("res://scenes/game/stages/stage_%d.tscn" % active_stage).instantiate()
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
    var actors: Array=[sim.state.player]+sim.state.enemies
    var seen: Dictionary={}
    for actor in actors:
        var id: String=actor.id
        seen[id]=true
        if not views.has(id):
            var view=ACTOR.instantiate()
            $Actors.add_child(view)
            views[id]=view
        var v: LootActorView=views[id]
        v.actor=actor
        v.get_node("Marker").visible=(id=="player" or id==sim.manual_target) and actor.hp>0
        v.get_node("Marker").texture=preload("res://assets/PixelPlains/Items/All v3 (Separated Files, Black Outline)/Item-211.png")
        v.get_node("Marker").modulate=Color(1,.75,.2) if id==sim.manual_target else Color(.45,.8,1)
        v.position=sim.position_of(actor)
        var body: String=""
        var weapon: String=""
        if id=="player":
            body=sim.state.outfit
            weapon=sim.state.weapon
            v.max_hp=sim.stats().hp
            v.visual_scale=1.0
        else:
            var group:=int(actor.group)
            var g: Dictionary=sim.enemy_definition(group,int(actor.get("variant",2)))
            body=g.body
            weapon=g.weapon
            v.max_hp=g.hp
            v.visual_scale=float(g.visual_scale)
            # Change 13: summoned helpers wear a tint; a discovered boss the next map still needs
            # carries the World banner (never before its type is discovered).
            v.body_tint=sim.abilities.helper_tint if sim.is_helper(actor) else Color.WHITE
            v.gate=bool(g.boss) and sim.campaign.gate_required(group)
        v.disclosed=id=="player" or sim.campaign.can_see(sim.position_of(actor))
        body=sim.catalog.art_id(body)
        weapon=sim.catalog.art_id(weapon)
        var path: String="res://assets/PixelPlains/Characters 24x24/Basic character v2.png"
        if sim.catalog.items.has(body) and sim.catalog.items[body].kind=="outfit":
            path=sim.catalog.items[body].texture
        elif body=="death":
            path="res://assets/PixelPlains/Characters 24x24/Autumn 4 v2.png"
        elif body=="cat":
            path="res://assets/PixelPlains/Characters 24x24/Gato 4 v2.png"
        if not textures.has(path):
            textures[path]=load(path)
        if v.body_texture!=textures[path]:
            v.body_texture=textures[path]
        v.attack_texture=load(sim.catalog.items[weapon].attack) if sim.catalog.items.has(weapon) and sim.catalog.items[weapon].has("attack") else ATTACKS.get(weapon)
        v.attack_tint=attack_tint(weapon)
        v.weapon_texture=textures.get(weapon)
        if body=="death":
            v.attack_tint=Color.WHITE
            v.weapon_texture=preload("res://resources/game/death_weapon.tres")
            v.attack_texture=preload("res://assets/PixelPlainsAnimationPack/Onix set/Scythe 7 64x32.png")
    for id in views.keys():
        if not seen.has(id):
            views[id].queue_free()
            views.erase(id)
    seen.clear()
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
        pickups[id].visible=sim.campaign.can_see(Vector2(drop.x,drop.y))
        pickups[id].modulate.a=.55 if drop.ttl<30 else 1.0
    for id in pickups.keys():
        if not seen.has(id):
            pickups[id].queue_free()
            pickups.erase(id)
    update_camera()

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
