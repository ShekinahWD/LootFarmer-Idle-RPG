extends Node2D
## Prestige celebration (Change 70 ZIP, rebuilt in Change 71 after a review at the real camera zoom).
## Presentation only: campaign.choose_card has already committed and saved the Prestige before the
## "prestiged" milestone starts it, so pausing, travelling, a Hard Reset (stop()) or playing it twice can
## never lose or repeat a reward. Centred on the hero in world space, above the actors.
##
##   0.00  REVEAL   one icon per owned Prestige path fades in on a tilted orbit around the hero (at most
##                  MAX_ICONS); every further owned card is a small star on an inner orbit, so the size of the
##                  collection still reads. A soft glow and a ground ring come up.
##   0.60  CHARGE   Cartoon Coffee "Charge_Light" / "ChargeUp_Energy": the orbit accelerates into a spiral
##                  that pulls the icons into the hero (short light trails), streaks converge from a ring,
##                  two Circle_Outline rings contract, a ring gathers on the ground and the glow swells.
##   1.90  IMPACT   "Impact_Light_Lv3": a short white-gold flash (never full screen), Shockwave_001, a
##                  Star_002 four-point flash, an expanding gold ring and a one-shot star burst.
##   1.90  ASCEND   a light beam (Light_Ray_007) rises from the hero with slow god rays (Radial_Glow_006)
##                  behind it while stars drift upward.
##   2.70  RESOLVE  a soft aura and the ground ring at the feet and the last sparkles fade; nothing
##                  remains at END.
## Glow_001 is a full soft disc (64 px): every glow stays under about 2x the hero's width, and the impact flash
## under a third of the screen at the default zoom.
##
## Sizes are world pixels at the default 2x camera; the node is scaled by sqrt(2 / zoom) so the effect stays
## readable when zoomed out and does not fill the screen when zoomed in. At most MAX_ICONS sprites, MAX_STARS
## stars and three small particle emitters; nothing runs while it is idle.

const REVEAL_END:=.6
const IMPACT:=1.9
const ASCEND_END:=2.7
const END:=3.6
const MAX_ICONS:=10
const MAX_STARS:=16
## The orbit (world px at the default zoom) and its tilt: a flattened ellipse reads as a ring around the hero.
const ORBIT:=Vector2(64,36)
const BODY_OFFSET:=Vector2(0,-13)
const GOLD:=Color(1,.84,.42)
const LIGHT:=Color(.72,.9,1)
## Moments the Change 71 capture samples (one per phase and the transitions between them).
const CAPTURE_MOMENTS:=[.25,.55,1.0,1.5,1.8,1.95,2.1,2.4,2.9,3.4]

const ITEM_ART:="res://assets/PixelPlains/Items/All v3 (Separated Files, Black Outline)/Item-%d.png"
const GLOW:=preload("res://assets/vfx/buff/Glow_001.png")
const RING:=preload("res://assets/vfx/celebration/Circle_Outline_002.png")
const SHOCKWAVE:=preload("res://assets/vfx/celebration/Shockwave_001.png")
const PILLAR:=preload("res://assets/vfx/buff/Light_Ray_007.png")
const AURA:=preload("res://assets/vfx/celebration/Radial_Glow_006.png")
const SPARK:=preload("res://assets/vfx/celebration/Star_003.png")
const STAR_FLASH:=preload("res://assets/vfx/prestige/Star_002.png")

var sim
var clock:=END
var active:=false
var add_material:=CanvasItemMaterial.new()
var icon_cache: Dictionary={}
var icons: Array[Sprite2D]=[]
var halos: Array[Sprite2D]=[]
var stars: Array[Sprite2D]=[]
var trails: Array=[]
var glow: Sprite2D
var flash: Sprite2D
var ground: Sprite2D
var rays: Sprite2D
var contract: Array[Sprite2D]=[]
var shock: Sprite2D
var burst_ring: Sprite2D
var star_flash: Sprite2D
var pillar: Sprite2D
var aura: Sprite2D
var streaks: CPUParticles2D
var burst: CPUParticles2D
var rise: CPUParticles2D
var fired: Dictionary={}

func setup(owner) -> void:
    sim=owner
    z_index=18
    add_material.blend_mode=CanvasItemMaterial.BLEND_MODE_ADD
    rays=_sprite(AURA)
    aura=_sprite(GLOW)
    ground=_sprite(RING)
    for i in range(2):contract.append(_sprite(RING))
    glow=_sprite(GLOW)
    streaks=_emitter(GLOW,16,.5,false)
    streaks.emission_shape=CPUParticles2D.EMISSION_SHAPE_RING
    streaks.emission_ring_radius=84.0;streaks.emission_ring_inner_radius=70.0
    streaks.radial_accel_min=-520;streaks.radial_accel_max=-420
    streaks.particle_flag_align_y=true
    streaks.split_scale=true
    streaks.scale_curve_x=_curve([[0,.07],[1,.05]])
    streaks.scale_curve_y=_curve([[0,.2],[.7,.36],[1,.16]])
    streaks.color_ramp=_ramp([[0,0],[.3,1],[.85,.9],[1,0]])
    streaks.color=GOLD
    pillar=_sprite(PILLAR)
    shock=_sprite(SHOCKWAVE);burst_ring=_sprite(RING);star_flash=_sprite(STAR_FLASH)
    flash=_sprite(GLOW)
    burst=_emitter(SPARK,16,.7,true)
    burst.spread=180
    burst.initial_velocity_min=70;burst.initial_velocity_max=130
    burst.damping_min=120;burst.damping_max=170
    burst.scale_amount_min=.03;burst.scale_amount_max=.05
    burst.angular_velocity_min=-180;burst.angular_velocity_max=180
    burst.color_ramp=_ramp([[0,1],[.6,.9],[1,0]])
    burst.color=Color(1,.93,.7)
    rise=_emitter(SPARK,14,1.1,false)
    rise.emission_shape=CPUParticles2D.EMISSION_SHAPE_RECTANGLE
    rise.emission_rect_extents=Vector2(18,6)
    rise.direction=Vector2(0,-1);rise.spread=12
    rise.initial_velocity_min=34;rise.initial_velocity_max=60
    rise.scale_amount_min=.025;rise.scale_amount_max=.045
    rise.color_ramp=_ramp([[0,0],[.2,1],[1,0]])
    rise.color=Color(.95,.98,1)
    set_process(false)
    hide()

## Starts (or restarts) the celebration for the cards the profile owns now.
func play() -> void:
    _clear_icons()
    var owned: Array=[]
    for card_id in sim.state.owned_cards:
        if sim.catalog.campaign.cards.has(card_id):owned.append(str(card_id))
    if owned.is_empty():return
    # One icon per path (the collection's variety), in first-owned order; every other card is a star.
    var paths: Array=[]
    for card_id in owned:
        var path: String=str(sim.catalog.campaign.cards[card_id].path)
        if not paths.has(path) and paths.size()<MAX_ICONS:paths.append(path)
    for path in paths:
        var icon:=Sprite2D.new()
        icon.texture=_path_icon(path)
        icon.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
        var halo:=_sprite(GLOW)
        halo.self_modulate=Color(sim.catalog.campaign.paths.get(path,{}).get("color","ffd36b")).lightened(.25)
        add_child(icon)
        icons.append(icon);halos.append(halo);trails.append([])
    for i in range(mini(owned.size()-paths.size(),MAX_STARS)):
        var star:=_sprite(SPARK)
        stars.append(star)
    fired.clear()
    clock=0.0
    active=true
    burst.restart();burst.emitting=false
    rise.emitting=false;streaks.emitting=false
    show()
    set_process(true)
    _update(0.0)

## Ends at once (Hard Reset, or a new profile): nothing stays on screen.
func stop() -> void:
    active=false
    clock=END
    _clear_icons()
    for p in [streaks,burst,rise]:p.emitting=false
    set_process(false)
    hide()

## Probes and captures: the frame at time t (particles keep their own simulation).
func seek(t: float) -> void:
    clock=clampf(t,0.0,END)
    _update(0.0)

func _process(delta: float) -> void:
    clock+=delta
    if clock>=END:
        stop()
        return
    _update(delta)

func _update(_dt: float) -> void:
    var t:=clock
    if sim!=null:position=sim.position_of(sim.state.player)+BODY_OFFSET
    var zoom: float=maxf(.5,get_viewport().get_canvas_transform().get_scale().x) if is_inside_tree() else 2.0
    scale=Vector2.ONE*clampf(sqrt(2.0/zoom),.8,1.4)
    var reveal:=_smooth(t/REVEAL_END)
    var charge:=clampf((t-REVEAL_END)/(IMPACT-REVEAL_END),0,1)
    var after:=clampf((t-IMPACT)/(END-IMPACT),0,1)
    var fade_out:=1.0-_smooth((t-ASCEND_END)/(END-ASCEND_END))
    # Behind the hero: god rays of the ascension (drawn first, so everything else is above them).
    var after_u:=_smooth((t-IMPACT)/.3)
    _show(rays,t>=IMPACT,Vector2.ONE*(.15+.05*after),Vector2(0,-6),Color(1,.9,.6,.3*after_u*fade_out),t*.35)
    # A ring on the ground around the feet (Charge_Light's outline in perspective): it gathers with the
    # charge and widens and settles in the resolve.
    _show(ground,true,Vector2(1,.36)*(.34+.05*charge)*(1.0+.2*after),Vector2(0,13),Color(GOLD.lerp(LIGHT,after),(.3+.35*charge)*reveal*fade_out),0.0)
    _show(aura,t>=IMPACT,Vector2(1.5,.5)*(1.0+.2*after),Vector2(0,12),Color(LIGHT,.32*after_u*fade_out),0.0)
    # Charge_Light: two outline rings contracting in turn while it charges (seen in perspective).
    for i in range(contract.size()):
        var phase:=fposmod((t-REVEAL_END)/.62+i*.5,1.0)
        var on:=t>REVEAL_END and t<IMPACT-.05
        _show(contract[i],on,Vector2(1,.7)*lerpf(.5,.08,phase),Vector2(0,2),Color(GOLD,.55*sin(PI*phase)*clampf(charge*3,0,1)),0.0)
    streaks.emitting=t>REVEAL_END+.1 and t<IMPACT-.15
    # The hero's glow swells with the charge, then the impact flash (bright, but about a third of the screen).
    var flash_u:=clampf((t-IMPACT)/.3,0,1)
    _show(glow,t<IMPACT+.05,Vector2.ONE*(.42+.45*charge*charge),Vector2.ZERO,Color(1,.95,.8,(.18+.32*charge)*reveal),0.0)
    _show(flash,t>=IMPACT and flash_u<1,Vector2.ONE*(1.0+.8*_ease_out(flash_u)),Vector2.ZERO,Color(1,.98,.9,.9*(1.0-flash_u)),0.0)
    var ring_u:=clampf((t-IMPACT)/.55,0,1)
    _show(shock,t>=IMPACT and ring_u<1,Vector2.ONE*(.1+.42*_ease_out(ring_u)),Vector2.ZERO,Color(1,.92,.7,.8*(1.0-ring_u)),0.0)
    _show(burst_ring,t>=IMPACT and ring_u<1,Vector2(1,.6)*(.12+.5*_ease_out(ring_u)),Vector2(0,8),Color(GOLD,.65*(1.0-ring_u)),0.0)
    var star_u:=clampf((t-IMPACT+.04)/.42,0,1)
    _show(star_flash,t>=IMPACT-.04 and star_u<1,Vector2.ONE*.11*sin(PI*star_u),Vector2.ZERO,Color(1,1,.92,1.0-star_u*.5),star_u*.6)
    if t>=IMPACT and not fired.has("impact"):
        fired["impact"]=true
        burst.restart();burst.emitting=true
    # Ascension: Light_Ray_007 is a beam bright at its base; its base sits on the hero and it rises and fades.
    var pillar_u:=clampf((t-IMPACT)/(ASCEND_END-IMPACT+.4),0,1)
    var beam:=Vector2(.55*(1.0-.35*pillar_u),.9+.35*pillar_u)
    _show(pillar,t>=IMPACT and pillar_u<1,beam,Vector2(0,10-64.0*beam.y),Color(1,.95,.8,.8*sin(PI*minf(1.0,pillar_u*1.4+.12))),0.0)
    rise.emitting=t>=IMPACT and t<END-.9
    _icons(t,reveal,charge)

## The orbiting icons, their halos, light trails and the collection's stars.
func _icons(t: float,reveal: float,charge: float) -> void:
    var n:=icons.size()
    var pull:=charge*charge
    for i in range(n):
        var appear:=_smooth((t-.05*i)/.32)
        var angle:=TAU*float(i)/float(n)+t*.7+9.0*pull*charge
        var radius:=ORBIT*(1.0-pull)*(.85+.15*appear)
        var at:=Vector2(cos(angle)*radius.x,sin(angle)*radius.y)+Vector2(0,-4*sin(t*3.0+i))
        var gone:=t>=IMPACT-.02
        var alpha:=appear*(1.0-_smooth((charge-.9)/.1))
        var icon: Sprite2D=icons[i]
        icon.visible=not gone and alpha>0.01
        icon.position=at
        icon.scale=Vector2.ONE*lerpf(.62,.4,pull)*(.6+.4*_ease_back(appear))
        icon.modulate=Color(1,1,1,alpha)
        # Icons in front of the hero (lower half of the orbit) draw above the halo of the hero's glow.
        icon.z_index=1 if sin(angle)>0 else 0
        var halo: Sprite2D=halos[i]
        _show(halo,icon.visible,Vector2.ONE*lerpf(.4,.28,pull),at,Color(halo.self_modulate,.38*alpha),0.0)
        var trail: Array=trails[i]
        trail.push_front(at)
        if trail.size()>5:trail.pop_back()
    for i in range(stars.size()):
        var angle:=-TAU*float(i)/float(maxi(1,stars.size()))-t*1.1-7.0*pull*charge
        var radius:=ORBIT*.62*(1.0-pull)
        var star: Sprite2D=stars[i]
        var twinkle:=.55+.45*sin(t*9.0+i*1.7)
        _show(star,t<IMPACT-.02,Vector2.ONE*.035*(.7+.3*twinkle),Vector2(cos(angle)*radius.x,sin(angle)*radius.y),Color(1,.95,.75,reveal*twinkle*(1.0-_smooth((charge-.9)/.1))),t*2.0)
    queue_redraw()

func _draw() -> void:
    if not active or clock>=IMPACT:return
    # Light trails of the charge: the last few orbit positions as fading additive dots.
    var charge:=clampf((clock-REVEAL_END)/(IMPACT-REVEAL_END),0,1)
    if charge<=0:return
    for i in range(icons.size()):
        var trail: Array=trails[i]
        var tint: Color=halos[i].self_modulate
        for k in range(1,trail.size()):
            var a:=.4*charge*(1.0-float(k)/trail.size())*icons[i].modulate.a
            draw_texture_rect(GLOW,Rect2(trail[k]-Vector2(5,5),Vector2(10,10)),false,Color(tint,a))

# ---------------------------------------------------------------- helpers

func _path_icon(path: String) -> Texture2D:
    var index:=int(sim.catalog.campaign.paths.get(path,{}).get("icon",211))
    if not icon_cache.has(index):icon_cache[index]=UiArt.cropped(load(ITEM_ART % index))
    return icon_cache[index]

func _clear_icons() -> void:
    for node in icons+halos+stars:node.queue_free()
    icons.clear();halos.clear();stars.clear();trails.clear()

func _sprite(texture: Texture2D) -> Sprite2D:
    var s:=Sprite2D.new()
    s.texture=texture
    s.material=add_material
    s.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    s.visible=false
    add_child(s)
    return s

func _show(s: Sprite2D,on: bool,scale_: Vector2,at: Vector2,color: Color,rot: float) -> void:
    s.visible=on and color.a>.004
    if not s.visible:return
    s.scale=scale_
    s.position=at
    s.modulate=color
    s.rotation=rot

func _emitter(texture: Texture2D,amount: int,life: float,one_shot: bool) -> CPUParticles2D:
    var p:=CPUParticles2D.new()
    p.texture=texture
    p.material=add_material
    p.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    p.amount=amount
    p.lifetime=life
    p.lifetime_randomness=.3
    p.one_shot=one_shot
    p.explosiveness=1.0 if one_shot else 0.0
    p.emitting=false
    p.local_coords=true
    p.gravity=Vector2.ZERO
    add_child(p)
    return p

func _curve(points: Array) -> Curve:
    var c:=Curve.new()
    for p in points:c.add_point(Vector2(p[0],p[1]))
    return c

func _ramp(stops: Array) -> Gradient:
    var g:=Gradient.new()
    g.offsets=PackedFloat32Array(stops.map(func(s):return float(s[0])))
    g.colors=PackedColorArray(stops.map(func(s):return Color(1,1,1,float(s[1]))))
    return g

func _smooth(u: float) -> float:
    return smoothstep(0.0,1.0,clampf(u,0,1))

func _ease_out(u: float) -> float:
    return 1.0-pow(1.0-clampf(u,0,1),3.0)

func _ease_back(u: float) -> float:
    var x:=clampf(u,0,1)-1.0
    return 1.0+2.2*x*x*x+1.2*x*x
