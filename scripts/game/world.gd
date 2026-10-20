extends Node2D
signal actor_selected(group: int,variant: int)
signal camp_selected(index: int)
var camp_revision: int=-1
const ACTOR=preload("res://scenes/game/actor.tscn")
const ATTACKS={
    "death_scythe": preload("res://assets/PixelPlainsAnimationPack/Onix set/Scythe 7 64x32.png"),
    "wood_sword": preload("res://assets/PixelPlainsAnimationPack/Wood set/Sword 1 64x32.png"),
    "stone_sword": preload("res://assets/PixelPlainsAnimationPack/Onix set/Sword 7 64x32.png"),
    "iron_sword": preload("res://assets/PixelPlainsAnimationPack/Iron set/Sword 2 64x32.png")
}
const PICKUP=preload("res://scenes/game/pickup.tscn")
var following_player:=true
var camera_position:=Vector2.ZERO
var sim: LootSimulation
var views: Dictionary={}
var pickups: Dictionary={}
var textures: Dictionary={}

func setup(value: LootSimulation) -> void:
    sim=value
    sim.feedback.connect(_feedback)
    sim.chatter.connect(func(id: String,key: String)->void:
        if views.has(id):views[id].say(key))
    for id in sim.catalog.items:
        textures[id]=sim.catalog.icon(id)

func _process(_delta: float) -> void:
    if sim==null:
        return
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
        v.get_node("Marker").text="▼" if id==sim.manual_target else "•"
        v.get_node("Marker").modulate=Color(1,.75,.2) if id==sim.manual_target else Color(.45,.8,1)
        v.position=sim.position_of(actor)
        var body: String=""
        var weapon: String=""
        if id=="player":
            body=sim.state.outfit
            weapon=sim.state.weapon
            v.max_hp=sim.stats().hp
        else:
            var group:=int(actor.group)
            if group==4:
                body="cat"
                v.max_hp=25.0
            else:
                var g: Dictionary=sim.enemy_definition(group,int(actor.get("variant",2)))
                body=g.body
                weapon=g.weapon
                v.max_hp=g.hp
        body=sim.catalog.art_id(body)
        weapon=sim.catalog.art_id(weapon)
        var path: String="res://assets/PixelPlains/Characters 24x24/Basic character v2.png"
        if body in ["sprout","robot","dinosaur","reaper"]:
            path=sim.catalog.items[body].texture
        elif body=="death":
            path="res://assets/PixelPlains/Characters 24x24/Autumn 4 v2.png"
        elif body=="cat":
            path="res://assets/PixelPlains/Characters 24x24/Gato 4 v2.png"
        if not textures.has(path):
            textures[path]=load(path)
        if v.body_texture!=textures[path]:
            v.body_texture=textures[path]
        v.attack_texture=ATTACKS.get(weapon)
        v.weapon_texture=textures.get(weapon)
        if body=="death":
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
        pickups[id].modulate.a=.55 if drop.ttl<30 else 1.0
    for id in pickups.keys():
        if not seen.has(id):
            pickups[id].queue_free()
            pickups.erase(id)
    update_camera()

func _update_camps() -> void:
    if camp_revision!=sim.revision:
        camp_revision=sim.revision
        for i in range(3):
            var camp=get_node("Camps/Camp%d" % i)
            var owned: bool=sim.state.spawns.has(i)
            var active: bool=int(sim.state.spawn)==i
            camp.get_node("Fountain").modulate=Color.WHITE if owned else Color(.5,.55,.6)
            camp.get_node("Selected").visible=active
            camp.get_node("Label").modulate=Color(1,.9,.45) if active else Color.WHITE
            camp.get_node("Label").text=tr("CAMP_NAME") % (i+1)+"\n"+tr("SELECTED" if active else ("CAMP_AVAILABLE" if owned else "CAMP_LOCKED"))

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
    camera_position=camera_position.clamp(Vector2.ZERO,Vector2(1080,1500))
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
            if d<distance:
                closest=drop
                distance=d
    if not closest.is_empty():
        sim.collect(int(closest.uid))
        return
    var selected_actor: Dictionary={}
    distance=18.0
    for actor in [sim.state.player]+sim.state.enemies:
        if actor.hp<=0:
            continue
        var d: float=(sim.position_of(actor)+Vector2(0,-10)).distance_to(point)
        if d<distance:
            selected_actor=actor
            distance=d
    if not selected_actor.is_empty():
        actor_selected.emit(int(selected_actor.group),int(selected_actor.get("variant",2)))
        return
    for i in range(3):
        var camp_position: Vector2=get_node("Camps/Camp%d" % i).position
        if Rect2(camp_position+Vector2(-36,-58),Vector2(72,86)).has_point(point):
            camp_selected.emit(i)
            return

func _feedback(id: String,amount: float,healing: bool) -> void:
    if views.has(id):
        views[id].show_hit(amount,healing,bool(sim._find_actor(id).get("critical_hit",false)) and not healing)

func actor_at_screen(screen_point: Vector2,player_only:=false) -> Dictionary:
    var point:=get_canvas_transform().affine_inverse()*screen_point
    var best: Dictionary={}
    var distance:=22.0
    var candidates: Array=[sim.state.player] if player_only else sim.state.enemies
    for actor in candidates:
        if actor.hp<=0:
            continue
        var d: float=(sim.position_of(actor)+Vector2(0,-10)).distance_to(point)
        if d<distance:
            best=actor
            distance=d
    return best

func player_screen_position() -> Vector2:
    return get_canvas_transform()*(sim.position_of(sim.state.player)+Vector2(0,-10))
