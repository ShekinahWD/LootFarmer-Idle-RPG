extends Node
## Change 14 probe: the top-right map cluster (zoom, Map Explored, minimap, Next Stage) and its chips,
## the Missions badge against the Claim rules, rain splashes that stay where they land, the six skill
## effects for player and enemy casts (placement, layer, scale, real effect, one effect per action),
## Reveal Stats / Reveal Drops on both enemy tabs, joystick contrast layers and the one-time Focused
## Farming guidance. Real main scene and simulation; state set directly is labelled "fixture".
var checks:=0
var failures:=0
var sim
var game
var casts: Array=[]
var warnings: Array=[]
func check(ok: bool,label_: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(label_)
    else:print("  ok  ",label_)
func near(a: float,b: float,tolerance:=.0001) -> bool:return absf(a-b)<=tolerance*maxf(1.0,absf(b))
func _ready() -> void:call_deferred("run")
func fresh(mode:="none") -> void:
    get_tree().paused=false
    sim.new_profile();sim.state.tutorial.mode=mode;sim.suspended=false;SaveService.write_blocked=false;sim.rng.seed=14014;game._close()
    if mode!="none":sim.state.tutorial.seen.append_array(["overview","aggression","skills","groups","prestige","rest","camp_done"]) # fixture: earlier intros seen
    if mode=="guided":sim.state.tutorial.done.append_array(game.guide.LESSONS) # fixture: lessons done
    sim.campaign.focus_hint=-1
    casts.clear();warnings.clear()
func frames(n:=4) -> void:
    for i in range(n):await get_tree().process_frame
func run() -> void:
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim;sim.set_physics_process(false)
    SettingsState.mute_all_sfx()
    sim.spell_cast.connect(func(id: String,key: String,p: Vector2)->void:casts.append([id,key,p]))
    sim.skill_warning.connect(func(id: String,key: String,p: Vector2)->void:warnings.append([id,key,p]))
    fresh()
    await frames(4)
    await cluster_checks()
    await badge_checks()
    await rain_checks()
    await skill_checks()
    await research_checks()
    await joystick_checks()
    await focus_checks()
    print("CHANGE_14_CHECKS ",checks," FAILURES ",failures)
    game.queue_free();await get_tree().process_frame
    AudioService.stop_all_sfx()
    await get_tree().create_timer(.1).timeout
    get_tree().quit(1 if failures else 0)

func group(id: String) -> int:return sim.campaign.group_id(id)
func actor_of(id: String) -> Dictionary:
    for e in sim.state.enemies:
        if sim.catalog.groups[int(e.group)].id==id and not sim.is_helper(e):return e
    return {}
func stage(n: int) -> void:
    sim.state.stage=n;sim.state.unlocked_stage=maxi(int(sim.state.unlocked_stage),n);sim._reset_world() # fixture
func labels_text(root: Node) -> String:
    return " | ".join(root.find_children("*","Label",true,false).map(func(l):return l.text))
func map_node(path: String) -> Control:return game.get_node("Safe/Layout/Map/"+path)
## Relative luminance (WCAG) and the contrast ratio of two opaque colours.
func lum(c: Color) -> float:
    var f:=func(v: float)->float:return v/12.92 if v<=.03928 else pow((v+.055)/1.055,2.4)
    return .2126*f.call(c.r)+.7152*f.call(c.g)+.0722*f.call(c.b)
func contrast(a: Color,b: Color) -> float:
    var la:=lum(a);var lb:=lum(b)
    return (maxf(la,lb)+.05)/(minf(la,lb)+.05)
func over(top: Color,under: Color) -> Color:
    return Color(lerpf(under.r,top.r,top.a),lerpf(under.g,top.g,top.a),lerpf(under.b,top.b,top.a))
## Light snow and dark rainy ground (the Summer II grass under the 0.77/0.78/0.92 overcast).
const SNOW:=Color(.93,.95,.98)
const RAIN_GRASS:=Color(.22,.36,.2)

# ---------------------------------------------------------------- §1 §2 map cluster
func cluster_checks() -> void:
    fresh()
    stage(4)
    game._refresh_explored();game._refresh_gate()
    await frames(3)
    var zoom:=map_node("Zoom");var explored: Label=map_node("Explored");var mini:=map_node("MiniMap");var gate:=map_node("Gate")
    var gate_label: Label=gate.get_node("Row/Label")
    check(gate.visible and gate_label.text=="Next Stage · Bosses 0/2","Summer II reads \"%s\"" % gate_label.text)
    check(explored.text==tr("MAP_EXPLORED") % sim.campaign.explored_percent(4) and explored.text.begins_with("Map Explored: "),"Map Explored reads \"%s\" from the saved explored cells" % explored.text)
    var rz:=zoom.get_global_rect();var re:=explored.get_global_rect();var rm:=mini.get_global_rect();var rg:=gate.get_global_rect()
    check(rz.end.y<=re.position.y and re.end.y<=rm.position.y and rm.end.y<=rg.position.y,"Top-down order: zoom %s, Map Explored %s, minimap %s, Next Stage %s" % [rz,re,rm,rg])
    var map_rect: Rect2=game.get_node("Safe/Layout/Map").get_global_rect()
    check(re.get_center().x>map_rect.get_center().x and rg.get_center().x>map_rect.get_center().x and absf(re.end.x-rm.end.x)<=1 and absf(rg.end.x-rm.end.x)<=1,"Both chips share the minimap's right edge, top right of the map")
    check(re.end.y<map_rect.get_center().y,"The percentage is no longer in the lower right (it ends at y %.0f of %.0f)" % [re.end.y,map_rect.end.y])
    var cluster: Array=[zoom,explored,mini,gate]
    for i in range(cluster.size()):
        for j in range(i+1,cluster.size()):check(not cluster[i].get_global_rect().intersects(cluster[j].get_global_rect()),"%s and %s do not overlap" % [cluster[i].name,cluster[j].name])
    for path in ["Joystick","EnemyUpgrades","Achievement","EnemySection","History","FollowTracker","GemPickup"]:
        for node in [explored,gate]:check(not node.get_global_rect().intersects(map_node(path).get_global_rect()),"%s clear of %s" % [node.name,path])
    check(explored.mouse_filter==Control.MOUSE_FILTER_IGNORE and gate.mouse_filter==Control.MOUSE_FILTER_IGNORE and gate_label.mouse_filter==Control.MOUSE_FILTER_IGNORE and gate.get_node("Row").mouse_filter==Control.MOUSE_FILTER_IGNORE,"Neither chip takes touches")
    # Readability: a dark plate under both, readable font sizes and high contrast on any ground.
    var chip: StyleBoxTexture=gate.get_theme_stylebox("panel")
    var plate: StyleBoxTexture=explored.get_theme_stylebox("normal")
    check(gate.theme_type_variation==&"HudChip" and explored.theme_type_variation==&"HudChipLabel" and chip==plate and chip.texture!=null,"Both use the HudChip style (the Kenney backing panel)")
    check(chip.modulate_color.a>=.8 and lum(chip.modulate_color)<.01,"The plate is dark and nearly opaque (%s)" % chip.modulate_color)
    check(gate_label.get_theme_font_size("font_size")>=19 and explored.get_theme_font_size("font_size")>=18,"Font sizes %d / %d (were 18 / 17)" % [gate_label.get_theme_font_size("font_size"),explored.get_theme_font_size("font_size")])
    for ground in [SNOW,RAIN_GRASS,Color(.85,.75,.45),Color(.45,.3,.2)]:
        var back:=over(chip.modulate_color,ground)
        check(contrast(gate_label.get_theme_color("font_color"),back)>=7.0 and contrast(explored.get_theme_color("font_color"),back)>=7.0,"Contrast over %s ground: %.1f / %.1f (≥ 7)" % [ground,contrast(gate_label.get_theme_color("font_color"),back),contrast(explored.get_theme_color("font_color"),back)])
    check(gate_label.get_minimum_size().x+gate.get_node("Row/Icon").custom_minimum_size.x<=rm.size.x+40,"The Next Stage text fits beside the minimap (%.0f px)" % gate.get_combined_minimum_size().x)
    # Updates as required bosses fall; the World wording on Spring II.
    var e:=actor_of("boss-elephant");e.hp=0.0;sim._kill(e) # fixture kill
    game._refresh_gate()
    check(gate_label.text=="Next Stage · Bosses 1/2","After one gate boss: %s" % gate_label.text)
    var d:=actor_of("boss-teal-dinosaur");d.hp=0.0;sim._kill(d) # fixture kill
    game._refresh_gate()
    check(not gate.visible,"Both defeated: the next map is open and the chip hides")
    stage(8);game._refresh_gate()
    check(gate.visible and gate_label.text==tr("GATE_HUD_WORLD") % [0,int(sim.campaign.gate_status().total)],"Spring II keeps the world wording: %s" % gate_label.text)
    # The percent reads permanent exploration only; panning and zoom never change it.
    stage(1);game._refresh_explored()
    var before:=explored.text
    game.world.pan_camera(Vector2(-300,-300));SettingsState.set_camera_zoom(1.0);game._refresh_explored()
    check(explored.text==before,"Panning and zoom leave it at \"%s\"" % before)
    SettingsState.set_camera_zoom(2.0);game.world.follow_player()
    sim.campaign.reveal_circle(Vector2(800,150),200.0);game._refresh_explored()
    check(explored.text==tr("MAP_EXPLORED") % sim.campaign.explored_percent(1) and explored.text!=before,"Newly explored cells raise it (%s → %s)" % [before,explored.text])
    # Safe area: the cluster lives in the Safe margin container, so insets move it as a whole.
    check(game.get_node("Safe").is_ancestor_of(explored) and game.get_node("Safe").is_ancestor_of(gate),"Both chips sit inside the safe-area container")
    game.get_node("Safe").add_theme_constant_override("margin_top",60);game.get_node("Safe").add_theme_constant_override("margin_right",40) # fixture: a notch inset
    await frames(3)
    check(explored.get_global_rect().position.y>=60 and explored.get_global_rect().end.x<=game.size.x-40 and not explored.get_global_rect().intersects(mini.get_global_rect()) and not gate.get_global_rect().intersects(mini.get_global_rect()),"With 60 px top / 40 px right insets the cluster moves inside and stays ordered")
    game._safe_area()
    await frames(2)

# ---------------------------------------------------------------- §3 Missions badge
func badge_visible() -> bool:
    game._refresh_badges()
    return game.dock.get_node("Navigation/Missions/Badge").visible
func claim_buttons() -> int:
    var n:=0
    for b in game.rows.find_children("*","Button",true,false):
        if b.text==tr("CLAIM") and not b.disabled and b.is_visible_in_tree():n+=1
    return n
func badge_checks() -> void:
    fresh()
    check(tr("CLAIM")!="CLAIM","fixture: the Claim label is translated")
    sim.campaign.refresh_missions()
    check(not badge_visible(),"Fresh profile, nothing complete: no badge")
    # Main objectives: a ready one beyond the first three unfinished was the stale case.
    sim.state.main_ready["8"]=true # fixture: "Reach Summer I" ready while objectives 0 to 2 are not
    check(sim.campaign.main_shown().has(8) and sim.campaign.main_shown()[0]==8 and sim.campaign.main_shown().size()==3,"A ready objective is listed first: %s" % [sim.campaign.main_shown()])
    check(badge_visible(),"…and the badge shows")
    game._open("missions");await frames(3)
    check(claim_buttons()==1,"The panel shows its Claim button (%d)" % claim_buttons())
    var coins: float=sim.state.coins
    check(sim.campaign.claim_main(8) and sim.state.coins>coins,"Claiming it pays")
    game._refresh_panel();await frames(2)
    check(not badge_visible() and claim_buttons()==0,"After the claim: no badge, no Claim button")
    game._close()
    # The final objective while the final boss is undiscovered is not listed, so no badge.
    sim.state.main_ready["15"]=true;sim.state.final_discovered=false # fixture
    check(not badge_visible() and not sim.campaign.main_shown().has(15),"An unlisted final objective never lights the badge")
    sim.state.final_discovered=true
    check(badge_visible() and sim.campaign.main_shown().has(15),"…it does once the objective is listed")
    sim.state.main_ready.erase("15");sim.state.final_discovered=false
    # Daily missions.
    var m: Dictionary=sim.state.missions[0]
    m.progress=m.goal # fixture: complete
    check(badge_visible() and sim.campaign.mission_claimable(0),"A complete daily mission shows the badge")
    game._open("missions");await frames(3)
    check(claim_buttons()==1,"…with one Claim button in the panel")
    check(sim.campaign.claim_mission(0),"Claim")
    game._refresh_panel();await frames(2)
    check(not badge_visible() and claim_buttons()==0,"After claiming every reward the badge clears")
    game._close()
    # Claimed missions waiting for tomorrow and "waiting" slots never count.
    sim.state.missions.append({"kind":"waiting","target":"","goal":1.0,"progress":1.0,"coins":0.0,"gems":0.0,"day":"","claimed":false}) # fixture
    check(not badge_visible(),"A waiting slot never counts")
    sim.state.missions.pop_back()
    # Purchased auto-claim handles complete missions itself: no manual claim, no badge.
    sim.state.upgrades["mission_claim"]=1;sim.state.mission_auto=true # fixture: auto-claim owned and on
    sim.state.missions[1].progress=sim.state.missions[1].goal
    check(not badge_visible(),"With auto-claim on, a complete mission does not light the badge")
    sim.campaign.automate(.1)
    check(sim.state.missions[1].claimed or sim.state.missions[1].progress<sim.state.missions[1].goal,"…and auto-claim takes it on the next tick")
    sim.state.mission_auto=false
    sim.state.missions[2].progress=sim.state.missions[2].goal
    check(badge_visible(),"Auto-claim switched off: the complete mission needs a manual claim, badge on")
    # Recalculated from state after a reset: Hard Reset clears it.
    check(SaveService.hard_reset() and not badge_visible(),"Hard Reset clears it")
    sim.state.tutorial.mode="none";sim.suspended=false

# ---------------------------------------------------------------- §4 rain splash in place
func rain_checks() -> void:
    fresh()
    stage(4)
    var weather=game.world.weather
    weather._process(0)
    check(weather.style!=null and weather.style.splash_frame==9 and weather.style.frames==15,"Rain: splash frames 9 to 14 of 15")
    var rect:=Rect2(0,0,1400,1400)
    var falling:=0;var splashing:=0;var fresh_drops:=0;var slid:=0;var stalled:=0
    for t in range(40):
        weather.clock=20.0+t*.1+.05
        var a: Array=weather.particles(rect)
        weather.clock+=.1
        var b: Array=weather.particles(rect)
        var index: Dictionary={}
        for p in b:index[str(p[1])+":"+str(floori(p[0].x/weather.style.period.x))+":"+str(floori(p[0].y/weather.style.period.y))]=p
        for p in a:
            var key:=str(p[1])+":"+str(floori(p[0].x/weather.style.period.x))+":"+str(floori(p[0].y/weather.style.period.y))
            if not index.has(key):continue
            var q: Array=index[key]
            if int(p[2])>=9 and int(q[2])==int(p[2])+1:
                splashing+=1
                if not p[0].is_equal_approx(q[0]):slid+=1
            elif int(p[2])<9 and int(q[2])==int(p[2])+1:
                falling+=1
                var moved: Vector2=q[0]-p[0]
                if moved.length()<.5:stalled+=1
            elif int(p[2])==14 and int(q[2])==0:fresh_drops+=1
    check(splashing>100 and slid==0,"%d splash steps stay exactly where the drop landed (%d slides)" % [splashing,slid])
    check(falling>100 and stalled==0,"%d falling steps keep the drift (%d stalled)" % [falling,stalled])
    check(fresh_drops>10,"After the last splash frame the particle starts a new drop (%d)" % fresh_drops)
    # The impact point: the first splash frame sits where the falling drop's drift reached.
    weather.clock=30.05
    var tick:=int(weather.clock*weather.style.fps)
    for p in weather.particles(rect):
        if int(p[2])==9:
            var i: int=p[1]
            var cell: Vector2=Vector2(floori(p[0].x/weather.style.period.x),floori(p[0].y/weather.style.period.y))*weather.style.period
            var expected: Vector2=cell+Vector2(fposmod(i*83.0+float(tick)/weather.style.fps*weather.style.drift.x,weather.style.period.x),fposmod(i*47.0+i*i*13.0+float(tick)/weather.style.fps*weather.style.drift.y,weather.style.period.y))
            check(p[0].is_equal_approx(expected),"The splash starts at the drop's position at the impact frame")
            break
    # Camera pans and zoom never move an impact relative to the terrain.
    weather.clock=31.95
    var before: Array=weather.particles(rect)
    game.world.pan_camera(Vector2(-250,-180));SettingsState.set_camera_zoom(3.0)
    check(weather.particles(rect)==before,"Panning and zooming leave every drop and splash in place")
    SettingsState.set_camera_zoom(2.0);game.world.follow_player()
    stage(6);weather._process(0)
    check(weather.style.splash_frame==-1,"Falling leaves have no splash phase (unchanged)")

# ---------------------------------------------------------------- §5 skills
func effects_on(node: Node) -> Array:
    return node.get_children().filter(func(n):return n is AnimatedSprite2D and not n.is_queued_for_deletion())
func clear_effects() -> void:
    for n in effects_on(game.world):n.queue_free()
    for id in game.world.views:
        for n in effects_on(game.world.views[id]):n.queue_free()
## The world point the sheet's contact row lands on.
func contact(sprite: AnimatedSprite2D,style: SkillEffectStyle) -> Vector2:
    var base: Vector2=sprite.position if sprite.get_parent()==game.world else sprite.get_parent().position+sprite.position
    return base+Vector2(0,(style.contact_y-32.0)*sprite.scale.y)
func skill_checks() -> void:
    fresh()
    stage(3)
    var set: SkillEffectSet=game.world.effects
    for key in ["heal","focus","frost","fire","lightning","strike"]:check(set.styles.has(key),"%s has an inspector placement style" % key)
    var actors_z: int=game.world.get_node("Actors").z_index
    sim.campaign.reveal_circle(sim.position_of(sim.state.player),400.0)
    var cat:=actor_of("boss-gray-cat")
    var yellow:=actor_of("unit-yellow-cap")
    check(not cat.is_empty() and not yellow.is_empty(),"fixture: Summer I has the Gray Cat (2× boss, Lightning) and Yellow Caps (Lightning)")
    var px: float=sim.state.player.x;var py: float=sim.state.player.y
    # ---- Player casts on a normal enemy and on a 2× boss.
    for target in [yellow,cat]:
        for key in ["lightning","strike","fire","frost"]:
            fresh();stage(3);sim.campaign.reveal_circle(Vector2(px,py),400.0)
            var t:=actor_of(sim.catalog.groups[int(target.group)].id)
            t.x=px+40;t.y=py;t.hp=1e7;t.aggro=true;sim.state.player.quiet=0;sim.locked_target=t.id;sim.state.discovered[str(t.group)]=true # fixture: a target in reach
            game.world._process(0);clear_effects();await frames(1)
            var view: LootActorView=game.world.views[t.id]
            var hp: float=t.hp
            casts.clear()
            check(sim.campaign.apply_skill(sim.state.player,key,float(sim.catalog.skills[key].power)),"Player %s on %s resolves" % [key,t.group])
            check(t.hp<hp,"…and deals real damage (%.0f)" % (hp-t.hp))
            if key=="frost":check(float(t.slow)>0,"…Frost slows (%.1f s)" % float(t.slow))
            check(casts.size()==1,"…one effect event")
            var fx: Array=effects_on(game.world)
            var style: SkillEffectStyle=set.style(key)
            check(fx.size()==1,"…one effect sprite (%d)" % fx.size())
            if fx.is_empty():continue
            var sprite: AnimatedSprite2D=fx[0]
            var scale_wanted: float=style.scale*(view.visual_scale if style.scale_with_actor else 1.0)
            check(near(sprite.scale.x,scale_wanted),"…scale %.2f" % sprite.scale.x)
            match key:
                "lightning":
                    check(sprite.z_index>actors_z,"Lightning draws above the actors (z %d > %d), not hidden under the target" % [sprite.z_index,actors_z])
                    check(contact(sprite,style).distance_to(sim.position_of(t))<.5,"Lightning's ground ring lands on the target's feet")
                    var body_top: float=sim.position_of(t).y-22.0*view.visual_scale
                    check(sprite.position.y-32.0*sprite.scale.y<=body_top and sprite.position.y+32.0*sprite.scale.y>=sim.position_of(t).y,"The bolt spans the whole body: from above its head (%.0f ≤ %.0f) to its feet" % [sprite.position.y-32.0*sprite.scale.y,body_top])
                "strike":
                    check(sprite.z_index>actors_z and contact(sprite,style).distance_to(sim.position_of(t)+Vector2(0,-10*view.visual_scale))<.5,"Strike bursts on the body centre, above the actors")
                "fire":
                    check(sprite.z_index>actors_z and contact(sprite,style).distance_to(sim.position_of(t)+Vector2(0,-10))<.5,"Fire explodes at its aim, body height, above the actors")
                "frost":
                    check(sprite.z_index<actors_z and contact(sprite,style).distance_to(sim.position_of(sim.state.player))<.5,"Frost is a ground effect under the actors, centred on the caster")
    # ---- Self skills: real effect, on the caster, following it.
    fresh();stage(3)
    game.world._process(0);clear_effects();await frames(1)
    var pview: LootActorView=game.world.views["player"]
    var hp_max: float=sim.stats().hp
    sim.state.player.hp=hp_max*.5
    check(sim.campaign.apply_skill(sim.state.player,"heal",1000.0) and sim.state.player.hp>hp_max*.5,"Player Heal restores HP")
    var hfx: Array=effects_on(pview)
    check(hfx.size()==1 and near(hfx[0].position.y,-(52-32)*.75) and near(hfx[0].scale.x,.75),"Heal: on the player's view, ring on the feet")
    sim.state.player.x+=30;game.world._process(0)
    check(hfx[0].global_position.is_equal_approx(pview.to_global(hfx[0].position)) and pview.position.x==sim.state.player.x,"…and it follows the player")
    var en:=actor_of("unit-yellow-cap");en.x=sim.state.player.x+40;en.y=sim.state.player.y;en.aggro=true;sim.state.player.quiet=0.0 # fixture: in combat
    if sim.campaign.in_combat():
        check(sim.campaign.apply_skill(sim.state.player,"focus",.15) and float(sim.state.player.focus_time)>0,"Player Focus starts its buff (%.0f s)" % float(sim.state.player.focus_time))
        check(effects_on(pview).size()==2,"Focus plays on the player too")
    # ---- Cooldowns: the cast starts each skill's own catalog cooldown.
    for key in ["lightning","fire","frost","strike","heal","focus"]:
        check(near(sim.player_upgrade_value("cooldown_"+key),float(sim.catalog.skills[key].cooldown)),"%s player cooldown %s s" % [key,sim.catalog.skills[key].cooldown])
    # ---- Enemy casts on the player: a normal Yellow Cap and the Gray Cat boss.
    fresh();stage(3);sim.campaign.reveal_circle(Vector2(px,py),400.0)
    var y2:=actor_of("unit-yellow-cap")
    y2.x=sim.state.player.x+40;y2.y=sim.state.player.y;sim.state.player.hp=1e7
    game.world._process(0);clear_effects();await frames(1)
    var php: float=sim.state.player.hp
    casts.clear()
    check(sim.campaign.apply_skill(y2,"lightning",float(sim.catalog.skills.lightning.power)) and sim.state.player.hp<php,"A Yellow Cap's Lightning damages the player")
    var lfx: Array=effects_on(game.world)
    check(lfx.size()==1 and contact(lfx[0],set.style("lightning")).distance_to(sim.position_of(sim.state.player))<.5 and lfx[0].z_index>actors_z,"…and strikes the player's feet, drawn over the player")
    # A boss attack: one wind-up marker at the aim, then one Lightning effect on the hit, wherever the player moved.
    fresh();stage(3);sim.campaign.reveal_circle(Vector2(px,py),400.0)
    var boss:=actor_of("boss-gray-cat")
    sim.state.player.x=boss.x+60;sim.state.player.y=boss.y;sim.state.player.hp=1e7;sim.state.player.quiet=0.0
    boss.aggro=true;boss.skill_timer=0.0;boss.skill_index=0;boss.telegraph=false # fixture: its turn
    sim.campaign.reveal_circle(sim.position_of(boss),200.0)
    game.world._process(0);clear_effects();await frames(1)
    casts.clear();warnings.clear()
    sim.campaign.step(.05)
    check(warnings.size()==1 and warnings[0][1]=="lightning" and casts.is_empty(),"Boss wind-up: one warning marker, no skill effect yet")
    var wfx: Array=effects_on(game.world)
    check(wfx.size()==1 and wfx[0].z_index<actors_z and wfx[0].modulate.r>wfx[0].modulate.b,"…a small tinted ground marker at the aim, not the Lightning sheet")
    clear_effects();await frames(1)
    sim.state.player.x+=20 # the player moves during the wind-up
    php=sim.state.player.hp
    for i in range(20):sim.state.player.quiet=0.0;sim.campaign.step(.05)
    var hits: Array=casts.filter(func(c):return c[0]==boss.id)
    check(hits.size()==1 and sim.state.player.hp<php,"The attack resolves once with real damage (%d effect events)" % hits.size())
    check(warnings.size()==1,"…and no second warning")
    var bfx: Array=effects_on(game.world).filter(func(n):return n.z_index>actors_z)
    check(bfx.size()==1 and contact(bfx[0],set.style("lightning")).distance_to(sim.position_of(sim.state.player))<.5,"The bolt lands on the player where they now stand")
    # A boss self-cast: Heal with no wind-up marker, on the boss, scaled with it.
    var robot_g:=group("boss-cyan-robot")
    fresh();stage(2)
    var robot:=actor_of("boss-cyan-robot")
    sim.campaign.reveal_circle(sim.position_of(robot),200.0)
    game.world._process(0);clear_effects();await frames(1)
    var rmax: float=sim.campaign.actor_max_hp(robot);robot.hp=rmax*.5
    casts.clear();warnings.clear()
    check(sim.campaign.apply_skill(robot,"heal",1.0) and robot.hp>rmax*.5 and warnings.is_empty(),"Boss Heal restores HP with no attack warning (%d)" % robot_g)
    var rfx: Array=effects_on(game.world.views[robot.id])
    check(rfx.size()==1 and near(rfx[0].scale.x,.75*2.0) and near(rfx[0].position.y,-(52-32)*1.5),"…on the 2× robot's feet at its scale")
    clear_effects()

# ---------------------------------------------------------------- §6 research on both tabs
func research_buttons(id: String) -> Array:
    return game.action_buttons.filter(func(b):return b.kind=="upgrade" and b.id==id and is_instance_valid(b.node))
func research_checks() -> void:
    fresh()
    var g: int=sim.campaign.stage().groups[0]
    sim.campaign.discover_spot(g,2)
    sim.state.coins=1000.0 # fixture
    game.group=g;game.enemy_variant=2;game.enemy_tab=0;game._open("enemy");await frames(3)
    check(research_buttons("reveal_stats").size()==1 and research_buttons("reveal_drops").size()==1,"Overview keeps Reveal Stats and Reveal Drops")
    check(not labels_text(game.rows).contains(game.fmt(sim.enemy_definition(g,2).hp)),"Stats stay hidden before research")
    game.enemy_tab=1;game._refresh_panel();await frames(2)
    check(research_buttons("reveal_stats").size()==1 and research_buttons("reveal_drops").size()==1,"Upgrades lists the same two research upgrades")
    check(labels_text(game.rows).contains(tr("SECTION_RESEARCH")),"…under a Research heading")
    var price: int=sim.upgrade_cost("reveal_stats",g)
    var coins: float=sim.state.coins
    var buy: Button=research_buttons("reveal_stats")[0].node
    check(buy.text==game.fmt_cost(price) and not buy.disabled,"Same price on Upgrades (%s)" % buy.text)
    buy.pressed.emit();await frames(2)
    check(sim.level("reveal_stats",g)==1 and near(sim.state.coins,coins-price),"Bought from Upgrades: level 1, charged once (%s)" % price)
    game._refresh_panel();await frames(2)
    var owned: Array=research_buttons("reveal_stats")
    check(owned.size()==1 and owned[0].node.disabled and owned[0].node.text==tr("UPGRADE_MAX"),"Upgrades now shows it owned (Max, disabled)")
    check(not sim.buy_upgrade("reveal_stats",g) and near(sim.state.coins,coins-price),"A second purchase is refused and charges nothing")
    game.enemy_tab=0;game._refresh_panel();await frames(2)
    check(research_buttons("reveal_stats").is_empty() and labels_text(game.rows).contains(game.fmt(sim.enemy_definition(g,2).hp)),"Overview shows the revealed stats, no purchase card")
    check(research_buttons("reveal_drops").size()==1,"Drops are still for sale on Overview")
    coins=sim.state.coins
    var drops_price: int=sim.upgrade_cost("reveal_drops",g)
    research_buttons("reveal_drops")[0].node.pressed.emit();await frames(2)
    check(sim.level("reveal_drops",g)==1 and near(sim.state.coins,coins-drops_price),"Drops bought from Overview, charged once")
    game.enemy_tab=1;game._refresh_panel();await frames(2)
    check(research_buttons("reveal_drops")[0].node.text==tr("UPGRADE_MAX"),"…and Upgrades shows it owned at once")
    var status: Dictionary=sim.campaign.farming_guide_status(int(sim.state.stage))
    check(int(status.researched)>=1,"The Farming Guide counts the type as researched (%d / %d)" % [int(status.researched),int(status.types)])
    game._close()

# ---------------------------------------------------------------- §7 joystick contrast
func joystick_checks() -> void:
    fresh()
    await frames(2)
    var stick: Control=game.stick
    check(stick.offset_left==-90.0 and stick.offset_top==-196.0 and stick.offset_right==90.0 and stick.offset_bottom==-16.0 and stick.anchor_left==.5 and stick.anchor_top==1.0,"Position and anchors unchanged (bottom centre)")
    check(stick.size==Vector2(180,180) and stick.radius==64.0,"Touch size and movement radius unchanged")
    var plate: NinePatchRect=stick.get_node("Backplate");var base: NinePatchRect=stick.get_node("Base");var knob: NinePatchRect=stick.get_node("Knob");var rim: NinePatchRect=knob.get_node("Rim")
    for n in [plate,base,knob,rim]:check(n.mouse_filter==Control.MOUSE_FILTER_IGNORE,"%s takes no touches (input stays on the joystick)" % n.name)
    check(plate.get_index()<base.get_index() and rim.show_behind_parent,"Backplate under the ring, rim under the knob")
    check(plate.modulate.a>=.25 and plate.modulate.a<=.5 and lum(plate.modulate)<.01,"The backplate is a restrained dark tint (alpha %.2f)" % plate.modulate.a)
    check(base.modulate.a>=.75,"The ring is more opaque (%.2f, was 0.65)" % base.modulate.a)
    # On snow the white ring alone barely differs from the ground; the dark plate inside it gives the contrast.
    check(contrast(over(plate.modulate,SNOW),SNOW)>=1.4,"On snow the backplate separates the pad from the ground (%.2f:1)" % contrast(over(plate.modulate,SNOW),SNOW))
    var knob_col:=Color(knob.modulate.r,knob.modulate.g,knob.modulate.b,knob.modulate.a)
    var rim_col:=Color(rim.self_modulate.r*knob.modulate.r,rim.self_modulate.g*knob.modulate.g,rim.self_modulate.b*knob.modulate.b,rim.self_modulate.a*knob.modulate.a)
    for ground in [SNOW,RAIN_GRASS,Color(.85,.75,.45),Color(.45,.3,.2)]:
        var pad:=over(plate.modulate,ground)
        var k:=over(knob_col,pad);var r:=over(rim_col,pad)
        check(contrast(k,r)>=2.5 or contrast(k,pad)>=1.8,"Knob reads on %s (knob/rim %.1f:1, knob/pad %.1f:1)" % [ground,contrast(k,r),contrast(k,pad)])
    # Movement is unchanged.
    stick._drag(stick.size*.5+Vector2(64,0))
    check(stick.direction.is_equal_approx(Vector2.RIGHT),"Dragging to the edge still moves full right")
    stick.release()
    check(stick.direction==Vector2.ZERO and knob.position.is_equal_approx(stick.size*.5-knob.size*.5),"Release recentres the knob")

# ---------------------------------------------------------------- §8 Focused Farming guidance
## Change 25: the Focused Farming pointer is Guided only (finished Guided here); Basic and None get
## the confirmation alone.
func focus_setup(mode: String) -> int:
    fresh(mode)
    if mode=="guided":sim.campaign.guided.data().done=sim.campaign.guided.STEPS.duplicate() # fixture: Guided finished
    var g: int=sim.campaign.stage().groups[0]
    sim.campaign.discover_spot(g,2)
    sim.state.gems=500.0;sim.state.coins=1000.0 # fixture
    return g
## Press the Focused Farming buy button; the panel's periodic refresh (0.25 s) is applied at once.
## Change 65: the purchase is the one global Player upgrade (Player Upgrades → Player); the enemy panel that
## was open is shown again afterwards. focus_notice keeps the confirmation the purchase panel showed.
var focus_notice:=""
func buy_focus() -> void:
    var reopen: bool=game.sheet.visible and game.panel=="enemy"
    var keep:=[game.group,game.enemy_tab,game.enemy_variant]
    game.player_tab=0;game._open("upgrades");await frames(4)
    for b in game.rows.find_children("*","Button",true,false):
        if b.get_meta("guide","")=="buy_focus" and not b.disabled:b.pressed.emit();break
    game._refresh_panel()
    await frames(6)
    focus_notice=game.notice.text
    if reopen:
        game.group=keep[0];game.enemy_tab=keep[1];game.enemy_variant=keep[2];game._open("enemy")
        await frames(6)
func open_upgrades(g: int) -> void:
    game.group=g;game.enemy_variant=2;game.enemy_tab=1;game._open("enemy")
    await frames(10)
func focus_checks() -> void:
    var g:=await focus_setup("guided")
    var guide=game.guide
    await open_upgrades(g)
    check(research_buttons("focus").is_empty() and guide._panel_control("focus_toggle")==null and guide._panel_control("focus_locked")!=null,"Before the purchase: Farm shown locked, no purchase in the enemy panel (Change 65)")
    await buy_focus()
    check(sim.level("focus",g)==1 and sim.campaign.focus_hint==g and sim.state.tutorial.seen.has("focus_unlocked"),"First purchase starts the hint (session) and records it in the profile")
    check(focus_notice==tr("FOCUS_UNLOCKED") and tr("FOCUS_UNLOCKED")=="Focused Farming unlocked","Confirmation on the panel: \"%s\"" % focus_notice)
    var toggle: Button=guide._panel_control("focus_toggle",true)
    check(toggle!=null and toggle.text.begins_with(tr("FOCUS_GROUP").split(" ")[0]),"The Farm button appears in the same panel")
    check(labels_text(game.rows).contains(tr("FOCUS_HINT_PANEL")),"One line under it says how to use it")
    check(guide.pending=="focus" and guide.step=="focus_tap" and guide.target==toggle,"The guide's step is to tap Farm, on the live button")
    check(guide.pointer.visible and guide.suspended_by=="","The pointer shows (Guided)")
    var tip_rect: Rect2=guide.pointer.get_global_rect()
    check(tip_rect.grow(40).intersects(toggle.get_global_rect()),"…next to the Farm button")
    check(guide.pointer.mouse_filter==Control.MOUSE_FILTER_IGNORE and guide.highlight.mouse_filter==Control.MOUSE_FILTER_IGNORE,"Guidance takes no input")
    # Overview shows the same button, so the hint follows the tab.
    game.enemy_tab=0;game._refresh_panel();await frames(4)
    check(guide.step=="focus_tap" and guide.target==guide._panel_control("focus_toggle",true) and guide.pointer.visible,"Overview tab: still pointing at its Farm button")
    # Closing the panel points at the way back.
    game._close();await frames(4)
    var hud: Control=map_node("EnemyUpgrades")
    if hud.visible and game.combat_group==g:
        check(guide.step=="focus_open" and guide.target==hud and guide.pointer.visible,"Panel closed: pointer on the HUD Upgrades button for this enemy")
    else:
        check(guide.step=="focus_find" and guide.target==map_node("MiniMap"),"Panel closed: pointer on the minimap (map, then the enemy)")
    check(guide.card.visible and guide.intro_button.visible and not guide.title.text.is_empty(),"A short caption with Got it: \"%s\"" % guide.title.text)
    # Another panel suspends it.
    game._open("settings");await frames(4)
    check(not guide.pointer.visible and not guide.card.visible and guide.suspended_by=="settings","Settings open: hidden, still pending")
    game._close()
    # Another enemy's panel suspends it too.
    var other: int=sim.campaign.stage().groups[1]
    sim.campaign.discover_spot(other,2)
    game.group=other;game.enemy_tab=0;game._open("enemy");await frames(8)
    check(not guide.pointer.visible and guide.pending=="focus","Another enemy's panel: no pointer (never toward a control not shown)")
    game._close()
    # Turning Farm on completes it.
    await open_upgrades(g)
    guide._panel_control("focus_toggle",true).pressed.emit();await frames(6)
    check(int(sim.state.focus)==g,"Farm turned on")
    check(sim.campaign.focus_hint==-1 and guide.pending!="focus" and not guide.pointer.visible,"…the hint ends at once")
    check(not labels_text(game.rows).contains(tr("FOCUS_HINT_PANEL")),"…and the panel line goes")
    game._close()
    # Once per profile: a second type's purchase, a reload and a Prestige never repeat it.
    sim.state.focus=-1
    await open_upgrades(other)
    check(not sim.buy_upgrade("focus") and sim.focus_owned() and sim.campaign.focus_hint==-1 and guide._panel_control("focus_toggle")!=null,"Another type needs no purchase (Change 65: global) and shows nothing new")
    game._close()
    check(not sim.state.has("focus_hint") and sim.state.tutorial.seen.has("focus_unlocked"),"Only the seen flag is saved; the hint itself never is")
    # Got it dismisses it.
    g=await focus_setup("guided")
    sim.campaign.guided.data().done=sim.campaign.guided.STEPS.duplicate()
    await open_upgrades(g)
    await buy_focus()
    game._close();await frames(4)
    check(guide.pending=="focus" and guide.intro_button.visible,"Guided mode: the same hint, with Got it")
    guide.intro_button.pressed.emit();await frames(4)
    check(sim.campaign.focus_hint==-1 and not guide.pointer.visible and not guide.card.visible,"Got it dismisses it for good")
    # It retires after its time on screen.
    g=await focus_setup("guided")
    await open_upgrades(g)
    await buy_focus()
    guide.focus_shown=guide.FOCUS_HINT_SECONDS # fixture: time on screen spent
    await frames(3)
    check(sim.campaign.focus_hint==-1 and not guide.pointer.visible,"After %.0f s on screen it retires (no permanent HUD text)" % guide.FOCUS_HINT_SECONDS)
    game._close()
    # An undiscovered spot: no pointer at a disabled button.
    g=await focus_setup("guided")
    sim.campaign.discover_spot(g,2)
    var variant:=-1
    for v in sim.campaign.variants(g):
        if not sim.campaign.spot_discovered(g,v):variant=v;break
    if variant>=0:
        await open_upgrades(g)
        await buy_focus()
        game.enemy_variant=variant;game._refresh_panel();await frames(4)
        check(guide.step=="focus_spot" and not guide.pointer.visible,"An undiscovered spot: \"find it first\", no pointer at the disabled button")
        game._close()
    # Basic and None: the confirmation only.
    g=await focus_setup("basic")
    await open_upgrades(g)
    await buy_focus()
    check(focus_notice==tr("FOCUS_UNLOCKED") and sim.campaign.focus_hint==-1 and not guide.pointer.visible,"Onboarding Basic: the confirmation, no pointer (Change 25)")
    game._close()
    g=await focus_setup("none")
    await open_upgrades(g)
    await buy_focus()
    check(focus_notice==tr("FOCUS_UNLOCKED") and sim.campaign.focus_hint==-1 and not guide.pointer.visible and not labels_text(game.rows).contains(tr("FOCUS_HINT_PANEL")),"Onboarding None: the confirmation, no pointer and no hint line")
    game._close()
    # Focus mechanics unchanged: the toggle still farms the chosen spot and movement stops it.
    sim.focus(g,2)
    check(int(sim.state.focus)==g,"Focus still toggles on")
    sim.focus(g,2)
    check(int(sim.state.focus)==-1,"…and off")
