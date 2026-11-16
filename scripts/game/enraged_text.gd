extends Node2D
## Change 86: the large "ENRAGED!" floating text over the Green Alien when Rage Mode starts (one per activation,
## world.gd creates it on sim.final_rage). Presentation only and non-blocking: nothing waits for it.
##
## - Fire on both sides is the game's own Fire skill art (no emoji font ships with the game, so a literal emoji
##   would draw as a missing-glyph box).
## - It follows the boss and sits above everything drawn over it (HP bar, name, skill icons, banner, target marker:
##   actor_view.overhead_top), so it never covers the HP bar or the icons. It also keeps clear of the HUD over the
##   map (both rails, trackers, banner, toast, joystick: world.hud_avoid): slid sideways as little as needed, or,
##   when no spot above is clear (the boss near the top of the map), just below the boss's feet.
## - Constant on-screen size whatever the camera zoom (TEXT_PX tall), never wider than MAX_WIDTH of the screen and
##   always EDGE_PX inside it, so it fits every portrait phone.
## - Timeline in real seconds (game speed and pause aside): a pop-in entrance (ENTER), a hold, then a gradual fade
##   (FADE) ending at LIFE, while it drifts up a little; the colour pulses between red and orange.
const LIFE:=5.0
const ENTER:=.4
const FADE:=1.6
## Cap height of the word on screen, pixels; the fire icons are FIRE_RATIO of it.
const TEXT_PX:=34.0
const FIRE_RATIO:=1.25
## Widest it may be, as a share of the screen width.
const MAX_WIDTH:=.72
## Closest it comes to the left or right screen edge, pixels.
const EDGE_PX:=8.0
## Space between the boss's overhead stack and the text, pixels; the upward drift over its life, pixels.
const GAP_PX:=10.0
const DRIFT_PX:=14.0
const FONT_SIZE:=64
const RED:=Color(1.0,.22,.12)
const ORANGE:=Color(1.0,.62,.16)

## The boss's actor view, looked up by id every frame (world.views are pooled and may be reassigned).
var view: Node2D
var world: Node
var actor_id:=""
var fire: Texture2D
var age:=0.0
var label: Label
## True while it sits below the boss (the space above was off the top of the map view).
var below:=false
var flames: Array[Sprite2D]=[]
var _settings:=LabelSettings.new()

func setup(world_node: Node,id: String,fire_texture: Texture2D,text: String) -> void:
    world=world_node;actor_id=id;view=world.views.get(id);fire=fire_texture
    _settings.font_size=FONT_SIZE
    _settings.font_color=RED
    _settings.outline_size=16
    _settings.outline_color=Color(.22,0,0)
    _settings.shadow_size=6
    _settings.shadow_color=Color(0,0,0,.55)
    _settings.shadow_offset=Vector2(0,5)
    label=Label.new()
    label.label_settings=_settings
    label.text=text
    label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
    label.mouse_filter=Control.MOUSE_FILTER_IGNORE
    label.auto_translate_mode=Node.AUTO_TRANSLATE_MODE_DISABLED
    add_child(label)
    for i in range(2):
        var s:=Sprite2D.new();s.texture=fire;add_child(s);flames.append(s)
    modulate.a=0.0
    _layout()

## Seconds left before it is gone.
func remaining() -> float:
    return maxf(0.0,LIFE-age)

## Opacity over its life: in during ENTER, full, then out over the last FADE seconds.
static func alpha_at(t: float) -> float:
    if t<ENTER:return clampf(t/ENTER,0.0,1.0)
    if t>LIFE-FADE:return clampf((LIFE-t)/FADE,0.0,1.0)
    return 1.0

## Size factor over its life: a pop (small, past full size, settle), then full size.
static func pop_at(t: float) -> float:
    if t>=ENTER:return 1.0
    var k:=t/ENTER
    return lerpf(.35,1.0,1.0-pow(1.0-k,3.0))+sin(k*PI)*.22

func _process(delta: float) -> void:
    age+=delta/maxf(Engine.time_scale,.01)
    view=world.views.get(actor_id) if world!=null and is_instance_valid(world) else null
    if age>=LIFE or view==null or not is_instance_valid(view):
        queue_free()
        return
    _layout()

## Screen pixels per world unit (the camera zoom).
func _zoom() -> float:
    return maxf(.01,get_viewport().get_canvas_transform().get_scale().x) if is_inside_tree() else 1.0

func _layout() -> void:
    if label==null or view==null or not is_instance_valid(view):return
    var zoom:=_zoom()
    var text_size:=label.get_combined_minimum_size()
    label.size=text_size
    label.position=Vector2(-text_size.x*.5,-text_size.y)
    # Flames beside the word, their bottoms on the text's baseline area.
    var fire_h:=text_size.y*.62*FIRE_RATIO
    var fire_scale:=fire_h/maxf(1.0,float(fire.get_height())) if fire!=null else 1.0
    var fire_w:=(float(fire.get_width()) if fire!=null else 0.0)*fire_scale
    for i in range(flames.size()):
        var s:=flames[i]
        s.scale=Vector2.ONE*fire_scale*(1.0+.08*sin(age*9.0+i*1.7))
        s.position=Vector2((text_size.x*.5+fire_w*.62)*(-1 if i==0 else 1),-text_size.y*.5)
    var full_w:=text_size.x+fire_w*2.5
    # World scale for a TEXT_PX cap height (about 0.7 of the font size), held to MAX_WIDTH of the screen.
    var s_px:=TEXT_PX/(FONT_SIZE*.7)
    var screen_w:=get_viewport_rect().size.x if is_inside_tree() else 540.0
    s_px=minf(s_px,screen_w*MAX_WIDTH/maxf(1.0,full_w))
    scale=Vector2.ONE*s_px/zoom*pop_at(age)
    var t:=clampf(age/LIFE,0.0,1.0)
    _settings.font_color=RED.lerp(ORANGE,.5+.5*sin(age*6.0))
    modulate.a=alpha_at(age)
    visible=view.visible
    global_position=view.global_position+Vector2(0,float(view.get("overhead_top"))-(GAP_PX+DRIFT_PX*t)/zoom)
    # Placement: above the boss's stack, else below its feet; slid sideways only as far as needed to stay inside the
    # map and clear of every HUD control (world.hud_avoid). Without any clear spot it stays above, on screen.
    if is_inside_tree():
        var above_y:=global_position.y
        var below_y:=view.global_position.y+(GAP_PX+DRIFT_PX*t)/zoom+text_size.y*scale.y
        var avoid: Array=world.hud_avoid.call() if world!=null and world.hud_avoid.is_valid() else []
        var best:=Vector2.INF
        for y in [above_y,below_y]:
            global_position=Vector2(view.global_position.x,y)
            var shift:=_clear_shift(screen_rect(),avoid)
            if shift!=INF:
                best=Vector2(view.global_position.x+shift/zoom,y)
                break
        below=best!=Vector2.INF and is_equal_approx(best.y,below_y) and not is_equal_approx(below_y,above_y)
        if best==Vector2.INF:
            global_position=Vector2(view.global_position.x,above_y)
            best=global_position+Vector2(_edge_shift(screen_rect())/zoom,0)
        global_position=best

## Sideways shift (pixels) putting r inside the map and clear of every avoid rect, nearest first; INF when none.
func _clear_shift(r: Rect2,avoid: Array) -> float:
    var w:=get_viewport_rect().size
    if r.position.y<EDGE_PX or r.end.y>w.y-EDGE_PX:return INF
    var options: Array=[_edge_shift(r)]
    for a in avoid:
        options.append((a.position.x-EDGE_PX)-r.end.x)
        options.append((a.end.x+EDGE_PX)-r.position.x)
    options.sort_custom(func(x,y):return absf(x)<absf(y))
    for shift in options:
        var moved:=Rect2(r.position+Vector2(shift,0),r.size)
        if moved.position.x<EDGE_PX-.5 or moved.end.x>w.x-EDGE_PX+.5:continue
        var clear:=true
        for a in avoid:
            if moved.intersects(a.grow(EDGE_PX*.5)):clear=false;break
        if clear:return shift
    return INF

## Sideways shift (pixels) keeping r inside the map's width.
func _edge_shift(r: Rect2) -> float:
    var w:=get_viewport_rect().size.x
    if r.position.x<EDGE_PX:return EDGE_PX-r.position.x
    if r.end.x>w-EDGE_PX:return (w-EDGE_PX)-r.end.x
    return 0.0

## Its on-screen rectangle (pixels), for probes: the word and the flames.
func screen_rect() -> Rect2:
    var xf:=get_viewport().get_canvas_transform()*get_global_transform()
    var r:=Rect2(label.position,label.size)
    for s in flames:
        var half:=Vector2(s.texture.get_width(),s.texture.get_height())*s.scale*.5 if s.texture!=null else Vector2.ZERO
        r=r.merge(Rect2(s.position-half,half*2))
    return xf*r
