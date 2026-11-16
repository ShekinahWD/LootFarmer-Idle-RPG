extends Node
## Change 85 focused checks (real main scene and simulation; state set directly is labelled "fixture"). No combat
## ladders, balance sweeps or player profiles.
## 1. Every type and variant: the icons shown (campaign.shown_skills, the world's icon row) are exactly the skills
##    its AI can select. Normal enemies and bosses: each listed skill is selectable by the Change 78 rotation and
##    the rotation selects only listed skills. Final boss: the skills final_choice and Heal actually return, found
##    by driving its choice, are the six it shows (Focus, Fire, Strike, Heal, Frost, Lightning).
## 2. Gameplay untouched: definitions (drops, mastery, rotation) keep the catalog lists; the final kit's order and
##    filter are the old ones.
## 3. Layout: the Green Alien's six icons sit in one row inside its HP bar's width, between the name and the
##    banner rows, never overlapping; more icons than fit wrap above; one- and two-icon rows are unchanged.
##    Windowed runs also save a 540x960 portrait still to generated/evidence/change_85/.
## Run: Godot --headless --path . res://tests/change_85_probe.tscn -- --probe --profile=probe-c85 --no-autosave --first-run-complete
var checks:=0
var failures:=0
var game
var sim

func check(ok: bool,label_: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(label_)
    else:print("  ok  ",label_)
func frames(n:=4) -> void:
    for i in range(n):await get_tree().process_frame
func _ready() -> void:call_deferred("run")

func run() -> void:
    get_tree().create_timer(300.0,true,false,true).timeout.connect(func():push_error("CHANGE_85 watchdog");get_tree().quit(2))
    SettingsState.mute_all_sfx()
    TranslationServer.set_locale("en")
    get_window().size=Vector2i(540,960)
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    await frames(6)
    rotation_checks()
    final_checks()
    await layout_checks()
    print("CHANGE_85_CHECKS %d FAILURES %d" % [checks,failures])
    game.queue_free();await frames(2);AudioService.stop_all_sfx()
    get_tree().quit(1 if failures>0 else 0)

# ---------------------------------------------------------------- fixtures (as in the Change 83/84 probes)
func fresh() -> void:
    get_tree().paused=false
    if game.final_dialog.is_open():game.final_dialog.close()
    sim.held=false
    sim.new_profile();sim.set_physics_process(false);sim.suspended=false;SaveService.write_blocked=false
    sim.state.tutorial.mode="none"
    sim.campaign.onboarding.reveal_all(true)
    sim.state.tutorial.seen.append("road_ahead")
    sim.state.tutorial.seen.append("final_intro")
    game._close();game.banner.queue.clear();game.banner._finish();game.toast_queue.clear();game.toast_important.clear();game.get_node("Toast").hide();game.toast_time=0.0
    SettingsState.restore_recommended()
func spring_two() -> void:
    sim.state.stage=8;sim.state.unlocked_stage=8;sim.state.spawns=[0,1,2];sim.state.camps["8"]=[0,1,2]
    sim.campaign.configure_stage();sim._reset_world() # fixture: Spring II reached, its camps owned
func alien() -> Dictionary:
    for a in sim.state.enemies:
        if bool(sim.catalog.groups[int(a.group)].final) and not sim.is_helper(a):return a
    return {}
func final_g() -> int:
    for g in range(sim.catalog.groups.size()):
        if bool(sim.catalog.groups[g].final):return g
    return -1
func introduced() -> void:
    sim.state.final_discovered=true
    sim.state.keys=[]
    for d in sim.catalog.groups:
        if d.boss and not d.final:sim.state.keys.append(str(d.id))
    sim.state.final_unsealed=true;sim.state.final_warning_ok=true;sim.state.final_experience=true
func sturdy() -> void:
    sim.state.player_level=500;sim._stats_revision=-1;sim.state.player.hp=sim.stats().hp
func place(offset: Vector2) -> void:
    var a:=alien()
    sim.state.player.x=float(a.home_x)+offset.x;sim.state.player.y=float(a.home_y)+offset.y
    sim.campaign.reveal()
func steps(seconds: float,dt:=.05) -> void:
    var t:=0.0
    while t<seconds-1e-6:
        sim.step(dt);t+=dt
func calm_boss() -> void:
    var a:=alien();a.cooldown=99.0;a.skill_timer=99.0;a.summon_cd=99.0 # fixture: the boss holds its attacks
func engaged() -> Dictionary:
    fresh();spring_two();sturdy();introduced()
    place(Vector2(30,0));steps(.1)
    return alien()

# ================================================================ 1a. Rotation types
## A probe actor of this type and variant, hurt and next to the player, in combat (fixture), so every skill's own
## condition (Heal below its threshold, Focus in combat, attacks in reach) holds.
func probe_actor(g: int,v: int) -> Dictionary:
    var p: Dictionary=sim.state.player
    p.hp=sim.stats().hp;p.quiet=0.0
    var d: Dictionary=sim.enemy_definition(g,v)
    return {"id":"probe-%d-%d" % [g,v],"group":g,"variant":v,"hp":float(d.hp)*.3,"x":float(p.x)+5,"y":float(p.y),"aggro":true,"skill_index":0}

func rotation_checks() -> void:
    print("-- Shown skills = rotation skills (every type and variant)")
    fresh()
    var mismatched: Array=[]
    var unselectable: Array=[]
    var pairs:=0
    for g in range(sim.catalog.groups.size()):
        if bool(sim.catalog.groups[g].final):continue
        for v in [0,1,2,3,sim.HELPER_VARIANT]:
            if v==sim.HELPER_VARIANT and sim.abilities.helper_rule(str(sim.catalog.groups[g].id))==null:continue
            var d: Dictionary=sim.enemy_definition(g,v)
            pairs+=1
            if sim.campaign.shown_skills(d)!=Array(d.skills):mismatched.append("%s/%d" % [sim.catalog.groups[g].id,v])
            var a:=probe_actor(g,v)
            for i in range(d.skills.size()):
                a.skill_index=i
                if sim.campaign.enemy_skill_choice(a,d)!=i:unselectable.append("%s/%d:%s" % [sim.catalog.groups[g].id,v,d.skills[i]])
    check(mismatched.is_empty(),"%d type/variant pairs show exactly their rotation %s" % [pairs,mismatched])
    check(unselectable.is_empty(),"Every shown rotation skill is selectable by the rotation %s" % [unselectable])
    var helpers_empty:=true
    for rule in sim.abilities.summons:
        var hg: int=sim.campaign.group_id(rule.helper_id)
        if hg>=0 and not sim.campaign.shown_skills(sim.enemy_definition(hg,sim.HELPER_VARIANT)).is_empty():helpers_empty=false
    check(helpers_empty,"Summoned helpers cast nothing and show nothing")

# ================================================================ 1b/2. Final boss kit
func final_checks() -> void:
    print("-- Final boss: shown skills = skills its kit really casts")
    var d: Dictionary=sim.catalog.groups[final_g()]
    var def: Dictionary=sim.enemy_definition(final_g())
    var shown: Array=sim.campaign.shown_skills(def)
    check(shown==["focus","fire","strike","heal","frost","lightning"],"Green Alien shows Focus, Fire, Strike, Heal, Frost, Lightning (%s)" % [shown])
    var a:=engaged();calm_boss()
    var seen:={}
    a.hp=float(def.hp)*.4;a.skill_cds={}
    seen[sim.campaign.final_choice(a)]=true
    a.skill_cds={"heal":99.0}
    sim.state.player.x=float(a.x)+10;sim.state.player.y=float(a.y);sim.state.player.quiet=0.0
    for i in range(400):seen[sim.campaign.final_choice(a)]=true
    seen.erase("")
    var cast: Array=seen.keys();cast.sort()
    var expect: Array=shown.duplicate();expect.sort()
    check(cast==expect,"Driven final_choice selects exactly the shown six (%s)" % [cast])
    check(sim.campaign.final_skill_pool()==Array(sim.abilities.final_attack_pool)+["focus"],"Kit order and filter unchanged (attack pool, then Focus)")
    check(Array(def.skills)==["focus","fire","strike"] and Array(d.skills)==["focus","fire","strike"],"Definition and catalog list unchanged (skill drops, mastery, map icon)")
    var cd_ok:=true
    for key in shown:
        if not is_equal_approx(sim.campaign.enemy_skill_cooldown(d,key),10.0):cd_ok=false
    check(cd_ok and is_equal_approx(float(sim.abilities.final_heal_below),.5) and is_equal_approx(float(sim.abilities.final_heal_fraction),.04) and absf(float(d.damage)-968.7388)<.001,"Cooldowns (10 s), Heal rule and attack unchanged")

# ================================================================ 3. Layout
func icon_bounds(view) -> Array:
    var out: Array=[]
    var cell: float=view.skill_icon_size*1.24+1
    for s in view._skills.get_children():
        out.append(Rect2(s.position-Vector2.ONE*(cell-1)*.5,Vector2.ONE*(cell-1)))
    return out

func layout_ok(view,label_: String) -> void:
    var rects:=icon_bounds(view)
    var bar_w: float=view.hp_bar_width*view.visual_scale
    var inside:=true
    var apart:=true
    for i in range(rects.size()):
        if rects[i].position.x< -bar_w*.5-.01 or rects[i].end.x>bar_w*.5+.01:inside=false
        for j in range(i+1,rects.size()):
            if rects[i].grow(-.01).intersects(rects[j]):apart=false
    var bottom:=-INF
    for r in rects:bottom=maxf(bottom,r.end.y)
    var below_top: float=view._name.position.y if view._name.visible else view._hp.position.y
    var top:=INF
    for r in rects:top=minf(top,r.position.y)
    var above_ok: bool=(not view._gate.visible) or view._gate.position.y+6<=top+.01
    check(inside and apart and bottom<=below_top+.01 and above_ok,"%s: %d icons inside the %.0f-unit bar width, apart, above the %s, below the banner" % [label_,rects.size(),bar_w,"name" if view._name.visible else "HP bar"])

func layout_checks() -> void:
    print("-- Icon layout")
    var a:=engaged();calm_boss()
    game.world._process(0);await frames(3)
    var view=game.world.views.get(str(a.id))
    check(view!=null and view.skill_icons.size()==6 and view._skills.get_child_count()==6 and view._skills.visible,"World: six icons over the Green Alien")
    if view==null:return
    var tex_ok:=true
    var keys:=["focus","fire","strike","heal","frost","lightning"]
    for i in range(6):
        if view.skill_icons[i]==null or view.skill_icons[i]!=game.world.textures.get("skill_"+keys[i]):tex_ok=false
    check(tex_ok,"…in order, each its own skill icon")
    var ys:={}
    for s in view._skills.get_children():ys[snappedf(s.position.y,.01)]=true
    check(ys.size()==1,"…in one row")
    layout_ok(view,"Green Alien")
    view.gate=true;view._process(0)
    layout_ok(view,"Green Alien with a World banner (fixture)")
    view.gate=false
    # One- and two-icon rows and the wrap rule on an ordinary boss view (fixture icons, restored).
    var other=null
    for e in sim.state.enemies:
        if game.world.views.has(e.id) and not bool(sim.catalog.groups[int(e.group)].final) and not sim.is_helper(e):other=game.world.views[e.id];break
    check(other!=null,"Fixture: another enemy view on the map")
    if other!=null:
        var saved: Array=other.skill_icons
        var was_disclosed: bool=other.disclosed
        other.disclosed=true # fixture: a view hidden by the fog lays out nothing
        var heal_tex: Texture2D=game.world.textures.get("skill_heal")
        var cell: float=other.skill_icon_size*1.24+1
        other.skill_icons=[heal_tex,heal_tex];other._process(0)
        var two:=icon_bounds(other)
        check(absf(two[0].get_center().x+cell*.5)<.01 and absf(two[1].get_center().x-cell*.5)<.01 and is_equal_approx(two[0].position.y,two[1].position.y),"Two icons: the old single row, centred")
        other.skill_icons=[heal_tex,heal_tex,heal_tex,heal_tex,heal_tex,heal_tex];other._process(0)
        var ys2:={}
        for s in other._skills.get_children():ys2[snappedf(s.position.y,.01)]=true
        check(ys2.size()>1,"Six icons on a scale-%.1f enemy wrap into %d rows" % [other.visual_scale,ys2.size()])
        layout_ok(other,"Wrapped six on a scale-%.1f enemy" % other.visual_scale)
        other.skill_icons=saved;other.disclosed=was_disclosed;other._process(0)
    # Portrait screen: the row's on-screen width at the current zoom, and a still for review.
    var zoom: float=game.world.get_viewport().get_canvas_transform().get_scale().x
    var row_px: float=(view.skill_icon_size*1.24+1)*6*zoom
    check(row_px<540*.5,"On a 540-wide portrait screen the row is %.0f px wide (zoom %.2f)" % [row_px,zoom])
    if DisplayServer.get_name()!="headless":
        # fixture for the still: the clearing around the boss explored, the boss a little hurt (HP bar shown),
        # notices cleared, the camera on the player.
        a.hp=float(sim.enemy_definition(final_g()).hp)*.8
        sim.campaign.reveal_circle(sim.position_of(a),220.0);sim.touch()
        game.banner.queue.clear();game.banner._finish();game.toast_queue.clear();game.get_node("Toast").hide()
        game.world.follow_player()
        await frames(30)
        var dir:="res://generated/evidence/change_85"
        DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
        get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(dir+"/green_alien_icons_540x960.png"))
        print("  saved ",dir,"/green_alien_icons_540x960.png")
