extends Control
## Change 81: the boss-key pickup. Presentation only: campaign.killed has already credited and saved the key
## (sim.key_earned is emitted after the commit), so nothing here can lose, duplicate or delay a reward.
## A large gold key (the repository's GUI Pack "Key - Gold" art, promoted to assets/ui) pops up over the fallen
## boss on a soft glow with its count ("Boss Key 5/13"), bobs and wobbles for a moment, then flies to the HUD's
## Boss Keys chip, which pulses on arrival. A tap on the key sends it at once; untouched it goes by itself.
## Never blocks play: the layer ignores input except the key itself, and the key ignores touches wherever it
## overlaps a control the player needs (the joystick, the dock). Pauses with the game tree. Travel to another map
## sends a floating key on its way; a panel over the chip, a hidden chip or a Prestige reset fades it in place
## (no flight across unrelated UI). Rapid keys are staggered so each one reads.
signal arrived(total: int)

const KEY_TEXTURE:=preload("res://assets/ui/Key - Gold.png")
const KEY_SIDE:=104.0
const POP_SECONDS:=.35
const FLOAT_SECONDS:=2.6
const FLY_SECONDS:=.8
const FADE_SECONDS:=.4
const STAGGER_SECONDS:=.45
const RISE:=78.0
const GLOW:=Color(1,.84,.32)

## world position -> this layer's coordinates (the map's, through the world viewport's scale). Callables are set
## by game_ui.
var project: Callable
## -> Rect2 (this layer's coordinates) of the Boss Keys chip, or an empty Rect2 when it cannot take the key now.
var destination: Callable
## -> Array of Rect2 (this layer's coordinates) where the key must not take touches.
var avoid: Callable
## -> Rect2 (this layer's coordinates) the floating key's centre stays in: the open play area between the HUD
## rails and the joystick, so it never sits on the chips, pills or minimap.
var bounds: Callable
var keys: Array=[]

func _ready() -> void:
    mouse_filter=Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    process_mode=Node.PROCESS_MODE_PAUSABLE

## A key credited at `at` (world position of the defeated boss); `total` is the new number of keys.
func play(at: Vector2,total: int,label: String) -> void:
    var node:=Control.new()
    node.size=Vector2(KEY_SIDE,KEY_SIDE)
    node.pivot_offset=node.size*.5
    node.mouse_filter=Control.MOUSE_FILTER_STOP
    var art:=TextureRect.new()
    art.texture=KEY_TEXTURE
    art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
    art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    art.mouse_filter=Control.MOUSE_FILTER_IGNORE
    node.add_child(art)
    var text:=Label.new()
    text.name="Count"
    text.text=label
    text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    text.add_theme_font_size_override("font_size",22)
    text.add_theme_color_override("font_color",Color(1,.92,.55))
    text.add_theme_color_override("font_outline_color",Color.BLACK)
    text.add_theme_constant_override("outline_size",6)
    text.mouse_filter=Control.MOUSE_FILTER_IGNORE
    text.position=Vector2(-60,KEY_SIDE-4)
    text.size=Vector2(KEY_SIDE+120,30)
    node.add_child(text)
    add_child(node)
    var entry:={"node":node,"at":at,"age":-STAGGER_SECONDS*_waiting(),"phase":"float","total":total,"from":Vector2.ZERO,"fly":0.0,"tapped":false}
    node.gui_input.connect(func(event: InputEvent)->void:
        if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed and entry.phase=="float":
            accept_event();entry.tapped=true;_launch(entry))
    node.visible=false
    keys.append(entry)

## Keys still on their way (the chip shows the credited count minus these until each one lands).
func in_flight() -> int:
    return keys.size()

## Prestige / Hard Reset / new profile: drop every key at once (they were credited already).
func clear() -> void:
    for entry in keys:entry.node.queue_free()
    keys.clear()
    queue_redraw()

## The hero moved to another map: floating keys leave for the chip from where they are.
func send_all() -> void:
    for entry in keys:
        if entry.phase=="float" and entry.age>=0:_launch(entry)

func _waiting() -> int:
    return keys.filter(func(e):return e.phase=="float" and e.age<0).size()+(1 if keys.any(func(e):return e.phase=="float" and e.age>=0 and e.age<POP_SECONDS) else 0)

func _screen(world_pos: Vector2) -> Vector2:
    return project.call(world_pos) if project.is_valid() else size*.5

func _launch(entry: Dictionary) -> void:
    if entry.phase!="float":return
    entry.from=entry.node.position+entry.node.pivot_offset
    var target: Rect2=destination.call() if destination.is_valid() else Rect2()
    entry.phase="fly" if target.has_area() else "fade"
    entry.fly=0.0
    entry.node.mouse_filter=Control.MOUSE_FILTER_IGNORE

func _process(dt: float) -> void:
    if keys.is_empty():return
    for entry in keys.duplicate():
        var node: Control=entry.node
        match str(entry.phase):
            "float":
                entry.age+=dt
                if entry.age<0:continue
                node.visible=true
                var t: float=entry.age
                var pop:=minf(1.0,t/POP_SECONDS)
                var scale_now:=lerpf(.2,1.0,pop)+.15*sin(pop*PI)
                var centre:=_screen(entry.at)+Vector2(0,-RISE*minf(1.0,t/.5)-6.0*sin(t*3.2))
                var area: Rect2=bounds.call() if bounds.is_valid() else Rect2()
                if not area.has_area():area=Rect2(Vector2(KEY_SIDE*.6,KEY_SIDE*.6),size-Vector2(KEY_SIDE*1.2,KEY_SIDE*1.7))
                centre=centre.clamp(area.position,area.end)
                node.position=centre-node.pivot_offset
                node.scale=Vector2.ONE*scale_now
                node.rotation=.16*sin(t*5.0)*(1.0-minf(1.0,t/FLOAT_SECONDS))
                var blocked:=false
                if avoid.is_valid():
                    for r in avoid.call():
                        if Rect2(node.position,node.size).intersects(r):blocked=true;break
                var filter:=Control.MOUSE_FILTER_IGNORE if blocked else Control.MOUSE_FILTER_STOP
                if node.mouse_filter!=filter:node.mouse_filter=filter
                if t>=FLOAT_SECONDS:_launch(entry)
            "fly":
                entry.fly+=dt
                var target: Rect2=destination.call() if destination.is_valid() else Rect2()
                if not target.has_area():
                    entry.phase="fade";entry.fly=0.0;continue
                var k:=minf(1.0,entry.fly/FLY_SECONDS)
                var e:=k*k*(3.0-2.0*k)
                var to: Vector2=target.get_center()
                var from: Vector2=entry.from
                var control: Vector2=(from+to)*.5+Vector2(0,-140)
                var p: Vector2=from.lerp(control,e).lerp(control.lerp(to,e),e)
                node.position=p-node.pivot_offset
                node.scale=Vector2.ONE*lerpf(1.0,.32,e)
                node.rotation=lerpf(node.rotation,-.6,e)
                node.get_node("Count").modulate.a=1.0-e
                if k>=1.0:_finish(entry)
            "fade":
                entry.fly+=dt
                node.modulate.a=1.0-minf(1.0,entry.fly/FADE_SECONDS)
                node.scale=Vector2.ONE*lerpf(1.0,1.25,minf(1.0,entry.fly/FADE_SECONDS))
                if entry.fly>=FADE_SECONDS:_finish(entry)
    queue_redraw()

func _finish(entry: Dictionary) -> void:
    keys.erase(entry)
    entry.node.queue_free()
    arrived.emit(int(entry.total))

## The soft glow behind each floating key keeps it readable on snow, sand, grass and rain.
func _draw() -> void:
    for entry in keys:
        if entry.phase!="float" or entry.age<0 or not entry.node.visible:continue
        var centre: Vector2=entry.node.position+entry.node.pivot_offset
        var pulse:=.85+.15*sin(float(entry.age)*6.0)
        var s: float=entry.node.scale.x
        for ring in [[1.05,.16],[.8,.24],[.58,.32]]:
            draw_circle(centre,KEY_SIDE*ring[0]*s*pulse,Color(GLOW.r,GLOW.g,GLOW.b,ring[1]))
