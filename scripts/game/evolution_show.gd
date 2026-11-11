extends Control
## Change 67: the manual weapon evolution presentation. Presentation only: the simulation has already
## evolved the weapon (and saved through its normal path) before present() is called with a snapshot
## taken just before the transaction, so closing, skipping, backgrounding or a scene change can never
## lose or repeat the result. Auto Evolution never opens this panel.
##
## One real-time clock drives everything (Engine.time_scale is countered), so Skip simply moves the
## clock to the end, and a probe or capture can sample any moment with seek().
##
##   0.00  dim in; the source weapon, its name and tier
##   0.20  charge (Cartoon Coffee "Charge_Light" / "ChargeUp_Energy"): glow growing, streaks converging
##         from a ring, contracting rings, the tier-coloured "Aura_V15" smoke rising, the weapon
##         shaking harder and turning white; charge_01 swells to its peak at the release
##  RELEASE white flash, controlled shake, the weapon becomes the evolved one ("Impact_Light_Lv3":
##         Shockwave_001, Rainbow_Ring_001, Impact_006, Light_Ray_001 lines, rainbow Star_003 shower,
##         embers); arcane_blast_01, then holy_01
##  REVEAL the new name and "Tier n → Tier n+1"; slow counter-rotating rays ("Radial_Loop_V2") stay
##         behind the weapon; two small bursts adapted from "Fireworks_V1"
##  READY  Continue. A tap before READY skips to the result; a tap after it (or Continue / Back) closes.
##
## While visible it holds the world (game_ui sets sim.held), like the other full-screen panels.

signal closed

const GLOW:=preload("res://assets/vfx/buff/Glow_001.png")
const RING:=preload("res://assets/vfx/celebration/Circle_Outline_002.png")
const FLASH_STAR:=preload("res://assets/vfx/celebration/Star_003.png")
const LINE:=preload("res://assets/vfx/celebration/Light_Ray_001.png")
const RAYS:=preload("res://assets/vfx/celebration/Radial_Glow_006.png")
const SHOCKWAVE:=preload("res://assets/vfx/celebration/Shockwave_001.png")
const RAINBOW:=preload("res://assets/vfx/celebration/Rainbow_Ring_001.png")
const IMPACT:=preload("res://assets/vfx/celebration/Impact_006.png")
const SMOKE:=preload("res://assets/vfx/celebration/Smoke_Cloud_002.png")

const CHARGE_START:=.2
const RELEASE:=1.35
const REVEAL:=1.55
const READY:=2.45
const END:=2.9
## A tap in the first moment is the end of the tap that pressed Evolve, never a skip.
const SKIP_GUARD:=.3
## Weapon art size on the base canvas (720 wide), and its centre as a fraction of the safe height.
const ICON_PX:=216.0
const ICON_Y:=.40
const SHAKE_PX:=9.0
const SHAKE_TIME:=.42
## The Impact_Light_Lv3 star shower gradient, lightened so it sits with the pixel palette.
## Charge energy (Charge_Light's warm start colour); the weapon's tier colour tints it a little.
const CHARGE_COLOR:=Color(1,.7,.32)
const RAINBOW_STOPS:=["ff6a5a","ff6ad0","9a7dff","5ad2ff","5aff8f","d4f06a","ffe266"]

var snapshot: Dictionary={}
var clock:=0.0
var finished:=false
var closing:=0.0
var add_material:=CanvasItemMaterial.new()
var icon_material:=ShaderMaterial.new()
var shake_offset:=Vector2.ZERO
var shake_step:=0.0
var fired: Dictionary={}
var rng:=RandomNumberGenerator.new()

var dim: ColorRect
var flash: ColorRect
var stage: Node2D
var rays_a: Sprite2D
var rays_b: Sprite2D
var aura: CPUParticles2D
var glow: Sprite2D
var pulses: Array[Sprite2D]=[]
var streaks: CPUParticles2D
var icon: Sprite2D
var shock: Sprite2D
var rainbow: Sprite2D
var impact: Sprite2D
var lines: CPUParticles2D
var stars: CPUParticles2D
var embers: CPUParticles2D
var fireworks: Array[CPUParticles2D]=[]
var firework_glows: Array[Sprite2D]=[]
var title: Label
var item_name: Label
var tier: Label
var note: Label
var hint: Label
var continue_button: Button
var emitters: Array[CPUParticles2D]=[]

func _init() -> void:
    name="EvolutionShow"
    visible=false
    mouse_filter=Control.MOUSE_FILTER_STOP
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_material.blend_mode=CanvasItemMaterial.BLEND_MODE_ADD
    var shader:=Shader.new()
    shader.code="shader_type canvas_item;\nuniform float flash : hint_range(0.0, 1.0) = 0.0;\nvoid fragment() {\n\tvec4 c = texture(TEXTURE, UV) * COLOR;\n\tCOLOR = vec4(mix(c.rgb, vec3(1.0), flash), c.a);\n}\n"
    icon_material.shader=shader

func _ready() -> void:
    dim=ColorRect.new()
    dim.color=Color(.02,.03,.07,.88)
    dim.mouse_filter=Control.MOUSE_FILTER_IGNORE
    dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(dim)
    stage=Node2D.new()
    add_child(stage)
    rays_a=_sprite(RAYS);rays_b=_sprite(RAYS)
    aura=_emitter(SMOKE,9,1.1,false)
    aura.emission_shape=CPUParticles2D.EMISSION_SHAPE_RECTANGLE
    aura.emission_rect_extents=Vector2(52,30)
    aura.position=Vector2(0,40)
    aura.gravity=Vector2(0,-150)
    aura.initial_velocity_min=10;aura.initial_velocity_max=30
    aura.direction=Vector2(0,-1);aura.spread=20
    aura.angular_velocity_min=-40;aura.angular_velocity_max=40
    aura.scale_amount_min=1.7;aura.scale_amount_max=2.5
    aura.scale_amount_curve=_curve([[0,.4],[.4,1],[1,1.2]])
    aura.color_ramp=_ramp([[0,0],[.25,1],[1,0]])
    glow=_sprite(GLOW)
    for i in range(2):pulses.append(_sprite(RING))
    streaks=_emitter(GLOW,34,.5,false)
    streaks.emission_shape=CPUParticles2D.EMISSION_SHAPE_RING
    streaks.emission_ring_radius=250.0;streaks.emission_ring_inner_radius=210.0
    streaks.initial_velocity_min=0;streaks.initial_velocity_max=0
    streaks.radial_accel_min=-1700;streaks.radial_accel_max=-1400
    streaks.particle_flag_align_y=true
    streaks.split_scale=true
    streaks.scale_curve_x=_curve([[0,.09],[1,.07]])
    streaks.scale_curve_y=_curve([[0,.35],[.7,.75],[1,.35]])
    streaks.color_ramp=_ramp([[0,0],[.3,1],[.85,1],[1,0]])
    icon=Sprite2D.new()
    icon.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
    icon.material=icon_material
    stage.add_child(icon)
    shock=_sprite(SHOCKWAVE);rainbow=_sprite(RAINBOW);impact=_sprite(IMPACT)
    lines=_emitter(LINE,14,.38,true)
    lines.initial_velocity_min=520;lines.initial_velocity_max=880
    lines.damping_min=1300;lines.damping_max=1500
    lines.spread=180
    lines.particle_flag_align_y=true
    lines.scale_amount_min=.55;lines.scale_amount_max=.95
    lines.color_ramp=_ramp([[0,1],[.6,.8],[1,0]])
    stars=_emitter(FLASH_STAR,22,.95,true)
    stars.initial_velocity_min=240;stars.initial_velocity_max=620
    stars.damping_min=480;stars.damping_max=620
    stars.spread=180
    stars.angular_velocity_min=-200;stars.angular_velocity_max=200
    stars.scale_amount_min=.11;stars.scale_amount_max=.26
    stars.scale_amount_curve=_curve([[0,1],[.7,.7],[1,0]])
    var shower:=Gradient.new()
    shower.offsets=PackedFloat32Array(range(RAINBOW_STOPS.size()).map(func(i):return float(i)/(RAINBOW_STOPS.size()-1)))
    shower.colors=PackedColorArray(RAINBOW_STOPS.map(func(h):return Color.html(h)))
    stars.color_initial_ramp=shower
    stars.color_ramp=_ramp([[0,1],[.75,1],[1,0]])
    embers=_emitter(GLOW,30,1.1,true)
    embers.initial_velocity_min=80;embers.initial_velocity_max=440
    embers.damping_min=200;embers.damping_max=300
    embers.gravity=Vector2(0,140)
    embers.spread=180
    embers.scale_amount_min=.04;embers.scale_amount_max=.09
    embers.color_ramp=_ramp([[0,1],[.6,.9],[1,0]])
    for i in range(2):
        var f:=_emitter(GLOW,24,1.0,true)
        f.initial_velocity_min=150;f.initial_velocity_max=250
        f.damping_min=60;f.damping_max=90
        f.gravity=Vector2(0,170)
        f.spread=180
        f.particle_flag_align_y=true
        f.split_scale=true
        f.scale_curve_x=_curve([[0,.07],[1,.04]])
        f.scale_curve_y=_curve([[0,.32],[.4,.24],[1,.08]])
        f.color_ramp=_ramp([[0,1],[.7,.8],[1,0]])
        fireworks.append(f)
        firework_glows.append(_sprite(GLOW))
    flash=ColorRect.new()
    flash.color=Color(1,1,1,0)
    flash.mouse_filter=Control.MOUSE_FILTER_IGNORE
    flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(flash)
    title=_label(30,Color(1,.86,.5))
    item_name=_label(36,Color.WHITE)
    tier=_label(24,Color(.8,.84,.9))
    note=_label(19,Color(.75,.8,.87))
    hint=_label(19,Color(.7,.75,.82))
    continue_button=Button.new()
    continue_button.theme_type_variation=&"Primary"
    continue_button.custom_minimum_size=Vector2(300,76)
    continue_button.add_theme_font_size_override("font_size",24)
    continue_button.pressed.connect(close)
    add_child(continue_button)

func _sprite(texture: Texture2D) -> Sprite2D:
    var s:=Sprite2D.new()
    s.texture=texture
    s.material=add_material
    s.visible=false
    stage.add_child(s)
    return s

func _emitter(texture: Texture2D,amount: int,life: float,one_shot: bool) -> CPUParticles2D:
    var p:=CPUParticles2D.new()
    p.texture=texture
    p.material=add_material
    p.amount=amount
    p.lifetime=life
    p.lifetime_randomness=.3
    p.one_shot=one_shot
    p.explosiveness=1.0 if one_shot else 0.0
    p.emitting=false
    p.local_coords=true
    p.gravity=Vector2.ZERO
    stage.add_child(p)
    emitters.append(p)
    return p

func _label(font_size: int,color: Color) -> Label:
    var l:=Label.new()
    l.mouse_filter=Control.MOUSE_FILTER_IGNORE
    l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    l.add_theme_font_size_override("font_size",font_size)
    l.add_theme_color_override("font_color",color)
    l.add_theme_color_override("font_outline_color",Color(.02,.03,.07))
    l.add_theme_constant_override("outline_size",8)
    add_child(l)
    return l

func _curve(points: Array) -> Curve:
    var c:=Curve.new()
    for p in points:c.add_point(Vector2(p[0],p[1]))
    return c

## A white ramp with these [offset, alpha] stops (the emitter's colour tints it).
func _ramp(stops: Array) -> Gradient:
    var g:=Gradient.new()
    g.offsets=PackedFloat32Array(stops.map(func(s):return float(s[0])))
    g.colors=PackedColorArray(stops.map(func(s):return Color(1,1,1,float(s[1]))))
    return g

## Shows the presentation for a snapshot {source, target, source_name, target_name, source_tier,
## target_tier, source_merge, source_color, target_color, source_icon, target_icon}, all taken before
## the transaction. Calling it again while open restarts it with the new snapshot.
func present(data: Dictionary) -> void:
    snapshot=data
    clock=0.0
    finished=false
    closing=0.0
    fired.clear()
    rng.seed=hash(str(data.get("source",""))+str(data.get("target","")))
    modulate=Color.WHITE
    for p in emitters:
        p.emitting=false
        p.restart()
        p.emitting=false
    var source_color: Color=data.source_color
    var target_color: Color=data.target_color
    icon.texture=data.source_icon
    title.text=tr("HELP_CARD_WEAPON_EVOLUTION_TITLE")
    item_name.text=str(data.source_name)
    item_name.add_theme_color_override("font_color",source_color.lightened(.55))
    tier.text=tr("ITEM_TIER_MERGE") % [int(data.source_tier),int(data.source_merge)]
    note.text=""
    hint.text=tr("EVOLUTION_SKIP_HINT")
    continue_button.text=tr("EVOLUTION_CONTINUE")
    rays_a.modulate=Color(target_color.lightened(.35),0)
    rays_b.modulate=Color(target_color.lightened(.6),0)
    # The smoke mask peaks at about a quarter alpha, so the additive tint is pushed above 1 to read.
    var energy:=CHARGE_COLOR.lerp(target_color,.3)
    aura.color=Color(energy.r*2.4,energy.g*2.4,energy.b*2.4,1)
    streaks.color=Color(energy.lightened(.35)*1.4,1)
    lines.color=target_color.lightened(.7)
    embers.color=Color(1,.93,.7)
    for f in fireworks:f.color=target_color.lightened(.55)
    visible=true
    _layout()
    _update(0.0)

func is_open() -> bool:
    return visible

## Back: skip while it plays, close once the result shows.
func back() -> void:
    if not finished:skip()
    else:close()

## Jumps to the final result (the evolved weapon, its name and tier, the rays, Continue).
func skip() -> void:
    if not visible or finished:return
    seek(END)

## Moves the clock to t (probes and captures sample frames this way; skip uses it too).
func seek(t: float) -> void:
    if t>=RELEASE and not fired.has("release"):
        # Sounds of moments jumped over are not played late.
        fired["charge"]=true;fired["release"]=true;fired["reveal_sound"]=true
        fired["firework0"]=true;fired["firework1"]=true
        for p in emitters:
            p.emitting=false
            p.restart()
            p.emitting=false
    clock=t
    _update(0.0)

func close() -> void:
    if not visible or closing>0:return
    if not finished:seek(END)
    closing=.18

func _gui_input(event: InputEvent) -> void:
    var tap: bool=(event is InputEventScreenTouch or event is InputEventMouseButton) and event.pressed
    if not tap:return
    accept_event()
    if clock<SKIP_GUARD:return
    if not finished:skip()
    elif not continue_button.get_global_rect().has_point(event.position):close()

func _process(delta: float) -> void:
    if not visible:return
    var dt:=delta/maxf(Engine.time_scale,.01)
    for p in emitters:p.speed_scale=1.0/maxf(Engine.time_scale,.01)
    if closing>0:
        closing-=dt
        modulate.a=clampf(closing/.18,0,1)
        if closing<=0:
            closing=0
            visible=false
            for p in emitters:
                p.emitting=false
                p.restart()
                p.emitting=false
            closed.emit()
        return
    _layout()
    clock+=dt
    _update(dt)

func _layout() -> void:
    var view:=size
    var insets:=LayoutService.get_safe_area_insets_canvas()
    var top:=insets.y;var bottom:=view.y-insets.w
    var center:=Vector2(view.x*.5,top+(bottom-top)*ICON_Y)
    stage.position=center+shake_offset
    var width:=minf(view.x-insets.x-insets.z-48,640)
    var left:=(view.x-width)*.5
    for l in [title,item_name,tier,note,hint]:
        l.size=Vector2(width,0)
        l.position.x=left
    title.reset_size();title.size.x=width
    title.position.y=maxf(top+28,center.y-ICON_PX*.5-200)
    item_name.reset_size();item_name.size.x=width
    item_name.position.y=center.y+ICON_PX*.5+70
    tier.reset_size();tier.size.x=width
    tier.position.y=item_name.position.y+item_name.size.y+6
    note.reset_size();note.size.x=width
    note.position.y=tier.position.y+tier.size.y+14
    continue_button.reset_size()
    continue_button.position=Vector2((view.x-continue_button.size.x)*.5,bottom-continue_button.size.y-36)
    hint.reset_size();hint.size.x=width
    hint.position.y=bottom-hint.size.y-60

func _fire(key: String) -> bool:
    if fired.has(key):return false
    fired[key]=true
    return true

func _ease_out(u: float) -> float:
    return 1.0-pow(1.0-clampf(u,0,1),3.0)

## Sets every node for the current clock. dt > 0 advances the shake and the rays' spin.
func _update(dt: float) -> void:
    var t:=clock
    var source_color: Color=snapshot.get("source_color",Color.WHITE)
    var target_color: Color=snapshot.get("target_color",Color.WHITE)
    dim.modulate.a=clampf(t/.25,0,1)
    stage.modulate.a=clampf(t/.2,0,1)
    title.modulate.a=clampf((t-.05)/.25,0,1)
    var charge:=clampf((t-CHARGE_START)/(RELEASE-CHARGE_START),0,1)
    var released:=t>=RELEASE
    var after:=t-RELEASE
    # --- weapon
    var art_scale:=1.0
    var art: Texture2D=icon.texture
    if art!=null:art_scale=ICON_PX/maxf(art.get_width(),art.get_height())
    if not released:
        if t>=CHARGE_START and _fire("charge"):
            AudioService.play("evolve_charge")
            streaks.emitting=true
            aura.emitting=true
        var amp:=1.0+7.0*charge*charge
        var jitter:=Vector2.ZERO
        if t>=CHARGE_START:jitter=Vector2(rng.randf_range(-1,1),rng.randf_range(-1,1))*amp
        icon.position=jitter
        icon.rotation=sin(t*38.0)*.06*charge
        icon.scale=Vector2.ONE*art_scale*(1.0+.12*charge)
        icon_material.set_shader_parameter("flash",.85*charge*charge)
    else:
        if _fire("release"):_release()
        icon.texture=snapshot.get("target_icon")
        art=icon.texture
        if art!=null:art_scale=ICON_PX/maxf(art.get_width(),art.get_height())
        icon.position=Vector2.ZERO
        icon.rotation=0.0
        var settle:=clampf(after/.5,0,1)
        # TRANS_BACK-like settle from 1.45 to 1.
        var back:=1.0+.45*(1.0-settle)-.08*sin(settle*PI)*(1.0-settle*.5)
        icon.scale=Vector2.ONE*art_scale*back
        icon_material.set_shader_parameter("flash",1.0-_ease_out(after/.55))
        if after>=.05 and _fire("reveal_sound"):AudioService.play("evolve_reveal")
    # --- glow behind the weapon: grows with the charge, settles in the evolved tier's colour
    glow.visible=true
    var glow_px:=130.0+150.0*charge
    var glow_a:=.35+.6*charge
    var glow_color:=CHARGE_COLOR.lerp(source_color,.25).lerp(target_color.lightened(.2),charge*.5)
    if released:
        var u:=clampf(after/.6,0,1)
        glow_px=lerpf(460.0,250.0,_ease_out(u))
        glow_a=lerpf(1.0,.55,u)
        glow_color=target_color.lightened(.35)
    glow.scale=Vector2.ONE*glow_px/GLOW.get_width()
    glow.modulate=Color(glow_color,glow_a*dim.modulate.a)
    # --- contracting rings while charging (two, half a period apart)
    for i in range(pulses.size()):
        var p:=pulses[i]
        var period:=.36
        var phase:=fposmod((t-CHARGE_START)/period+i*.5,1.0)
        p.visible=t>=CHARGE_START and not released
        if p.visible:
            p.scale=Vector2.ONE*lerpf(320.0,96.0,phase)/RING.get_width()
            p.modulate=Color(CHARGE_COLOR.lerp(target_color,.3*charge).lightened(.4),sin(phase*PI)*(.3+.6*charge))
    # --- release burst (one-shot sprites)
    _pop(shock,after,.48,.3*256,2.6*256,.95,target_color.lightened(.5))
    _pop(rainbow,after,.42,.4*256,2.3*256,.8,Color.WHITE)
    _pop(impact,after,.32,.25*256,1.7*256,1.0,Color(1,.96,.85),.6)
    flash.color.a=.85*(1.0-_ease_out(after/.45)) if released else 0.0
    # --- shake: decaying random steps every 0.05 s (Playbook 121.6), real time, release only
    if released and after<SHAKE_TIME and dt>0:
        shake_step-=dt
        if shake_step<=0:
            shake_step=.05
            var k:=1.0-after/SHAKE_TIME
            shake_offset=Vector2(rng.randf_range(-1,1),rng.randf_range(-1,1))*SHAKE_PX*k
    elif not released or after>=SHAKE_TIME or dt==0:
        shake_offset=Vector2.ZERO
    # --- rays: fade in behind the evolved weapon and keep turning slowly
    var rays_a_alpha:=.42*clampf((after-.05)/.6,0,1) if released else 0.0
    rays_a.visible=rays_a_alpha>0
    rays_b.visible=rays_a.visible
    rays_a.scale=Vector2.ONE*560.0/RAYS.get_width()
    rays_b.scale=Vector2.ONE*420.0/RAYS.get_width()
    rays_a.modulate.a=rays_a_alpha
    rays_b.modulate.a=rays_a_alpha*.8
    rays_a.rotation+=dt*.16
    rays_b.rotation-=dt*.1
    # --- fireworks (Fireworks_V1: a small purple-white glow, then falling streaks)
    for i in range(2):
        var at:=REVEAL+.2+i*.3
        var spot:=Vector2(-150 if i==0 else 155,-150 if i==0 else -110)
        if t>=at and _fire("firework%d" % i):
            fireworks[i].position=spot
            fireworks[i].restart()
            fireworks[i].emitting=true
        var g:=firework_glows[i]
        g.position=spot
        _pop(g,t-at,.22,30,120,.9,Color(1,.92,.8))
    # --- labels
    if t>=REVEAL:
        item_name.text=str(snapshot.get("target_name",""))
        item_name.add_theme_color_override("font_color",target_color.lightened(.55))
        tier.text=tr("EVOLUTION_TIER_CHANGE") % [int(snapshot.get("source_tier",0)),int(snapshot.get("target_tier",0))]
        tier.add_theme_color_override("font_color",Color(1,.86,.5))
        note.text=tr("EVOLVED")
        var u:=clampf((t-REVEAL)/.3,0,1)
        item_name.pivot_offset=item_name.size*.5
        item_name.scale=Vector2.ONE*(1.0+.35*(1.0-_ease_out(u))-.06*sin(u*PI))
        note.modulate.a=clampf((t-REVEAL-.25)/.3,0,1)
    else:
        item_name.scale=Vector2.ONE
        note.modulate.a=0
    item_name.modulate.a=clampf((t-.1)/.25,0,1)
    tier.modulate.a=item_name.modulate.a
    finished=t>=READY
    hint.visible=not finished and t>=SKIP_GUARD
    continue_button.visible=finished
    continue_button.modulate.a=clampf((t-READY)/.25,0,1)
    if finished:
        streaks.emitting=false
        aura.emitting=false

## A one-shot additive sprite: age u seconds into a d-second life, growing from a to b px, fading.
func _pop(s: Sprite2D,age: float,d: float,a: float,b: float,alpha: float,color: Color,spin:=0.0) -> void:
    s.visible=age>=0 and age<d
    if not s.visible:return
    var u:=age/d
    s.scale=Vector2.ONE*lerpf(a,b,_ease_out(u))/s.texture.get_width()
    s.rotation=spin*u
    s.modulate=Color(color,alpha*(1.0-u*u))

func _release() -> void:
    streaks.emitting=false
    aura.emitting=false
    for p in [lines,stars,embers]:
        p.restart()
        p.emitting=true
    shake_step=0.0
    AudioService.play("evolve_burst")
