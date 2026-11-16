extends Node
## Change 86 focused checks (real main scene and simulation; state set directly is labelled "fixture"). No combat
## ladders, balance sweeps or player profiles.
## 1. Recommended audio: Music 40%, Sound Effects 100%, both mutes off (every category audible); the save keeps the
##    player's own values including mutes; restored at death (after the death laugh) and after the first victory's
##    celebration; a change the player makes meanwhile is kept.
## 2. Rage reset: a player death ends Rage (latch, aura, red wall, rage music, attack speed, mitigation, healing);
##    the boss recovers and the next fight starts normal and enrages again at 20%.
## 3. "ENRAGED!" floating text: one per activation, 5 s (pop-in, hold, fade), non-blocking, above the HP bar, name
##    and skill icons, inside the screen at 540x960 and 432x960 portrait (windowed runs save stills to
##    generated/evidence/change_86/).
## 4. Death laugh: every defeat by the Green Alien (normal or enraged, or by its helper) plays one of Laugh 01/03/05
##    at once, alongside the arena-open cue; muted Gameplay Sounds silence it; no random laugh while it plays; a
##    defeat by anything else does not laugh.
## Run: Godot --headless --path . res://tests/change_86_probe.tscn -- --probe --profile=probe-c86 --no-autosave --first-run-complete
const LAUGHS:=["final_laugh_1","final_laugh_3","final_laugh_5"]
var checks:=0
var failures:=0
var game
var sim
var rages: Array=[]
var defeats: Array=[]
var windowed:=false

func check(ok: bool,label_: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(label_)
    else:print("  ok  ",label_)
func frames(n:=4) -> void:
    for i in range(n):await get_tree().process_frame
func _ready() -> void:call_deferred("run")

func run() -> void:
    get_tree().create_timer(300.0,true,false,true).timeout.connect(func():push_error("CHANGE_86 watchdog");get_tree().quit(2))
    windowed=DisplayServer.get_name()!="headless"
    TranslationServer.set_locale("en")
    get_window().size=Vector2i(540,960)
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    sim.final_rage.connect(func(id: String)->void:rages.append(id))
    sim.final_defeated_player.connect(func(id: String)->void:defeats.append(id))
    await frames(6)
    settings_checks()
    await rage_reset_checks()
    await text_checks()
    await laugh_checks()
    await death_restore_checks()
    print("CHANGE_86_CHECKS %d FAILURES %d" % [checks,failures])
    SettingsState.restore_recommended()
    SettingsState.set_music_volume(1.0);SettingsState.set_sfx_volume(1.0);SettingsState.set_mute_gameplay(false);SettingsState.set_mute_special(false)
    game.queue_free();await frames(2);AudioService.stop_all_sfx()
    get_tree().quit(1 if failures>0 else 0)

# ---------------------------------------------------------------- fixtures (as in the Change 83-85 probes)
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
    rages.clear();defeats.clear()
    game.final_audio.death_laugh_until_ms=0;game.final_audio.restore_due=false;game.final_audio.death_laughs.clear()
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
func real_wait(seconds: float) -> void:
    var t0:=Time.get_ticks_msec()
    while Time.get_ticks_msec()-t0<seconds*1000.0:await get_tree().process_frame
func maxhp() -> float:return float(sim.enemy_definition(final_g()).hp)
func enrage() -> void:
    alien().hp=maxhp()*.19;steps(.05);calm_boss() # fixture: the fight brought it to 19%
## The boss's basic attack lands on a player at 1 HP (fixture), through the real attack resolution.
func boss_kills_player(attacker: Dictionary) -> void:
    var p: Dictionary=sim.state.player
    p.hp=1.0;p.x=float(attacker.x)+10;p.y=float(attacker.y)
    attacker.target="player";attacker.windup=.0001
    sim._resolve_attack(attacker,.05)
func own_settings(music: float,sfx: float,mute_g: bool,mute_s: bool) -> void:
    SettingsState.restore_recommended()
    SettingsState.set_music_volume(music);SettingsState.set_sfx_volume(sfx);SettingsState.set_mute_gameplay(mute_g);SettingsState.set_mute_special(mute_s)
func settings_are(music: float,sfx: float,mute_g: bool,mute_s: bool) -> bool:
    return is_equal_approx(SettingsState.music_volume,music) and is_equal_approx(SettingsState.sfx_volume,sfx) and SettingsState.mute_gameplay==mute_g and SettingsState.mute_special==mute_s

# ================================================================ 1. Recommended audio
func settings_checks() -> void:
    print("-- Recommended audio")
    own_settings(.8,.6,true,true)
    SettingsState.apply_recommended()
    check(settings_are(.4,1.0,false,false),"Recommended: Music 40%, Sound Effects 100%, Gameplay and Special Sounds unmuted")
    check(AudioService.category_audible("gameplay") and AudioService.category_audible("special"),"Every sound category audible (laughs, enrage, arena cues, notices)")
    var saved: Dictionary=SettingsState.to_save_dict()
    check(is_equal_approx(float(saved.music_volume),.8) and is_equal_approx(float(saved.sfx_volume),.6) and bool(saved.mute_gameplay) and bool(saved.mute_special),"The save keeps the player's own values, mutes included")
    SettingsState.restore_recommended()
    check(settings_are(.8,.6,true,true),"Restore: 80% / 60% and both mutes back on")
    # A deliberate change during the encounter is kept.
    SettingsState.apply_recommended()
    SettingsState.set_sfx_volume(.5);SettingsState.set_mute_special(true)
    SettingsState.restore_recommended()
    check(settings_are(.8,.5,true,true),"A volume and a mute the player changed meanwhile are kept; the rest restored")
    own_settings(.7,.9,false,true)
    SettingsState.apply_recommended()
    SettingsState.set_mute_gameplay(true)
    SettingsState.restore_recommended()
    check(settings_are(.7,.9,true,true),"Muting Gameplay Sounds during the encounter is kept")
    # The first victory keeps the mix for its celebration; its end restores it (mutes included).
    own_settings(.8,.6,true,true)
    SettingsState.apply_recommended()
    game.final_audio._victory("first")
    check(SettingsState.recommended_active() and settings_are(.4,1.0,false,false),"First victory: the mix stays for the celebration")
    game.final_audio._victory("celebrated")
    check(not SettingsState.recommended_active() and settings_are(.8,.6,true,true),"Celebration ended: the player's own settings, mutes included")

# ================================================================ 2. Rage reset at death
func rage_reset_checks() -> void:
    print("-- Rage reset after the player's death")
    own_settings(.8,.6,true,true)
    var a:=engaged();calm_boss()
    enrage();a=alien()
    await real_wait(1.2)
    check(sim.campaign.enraged(a) and rages.size()==1,"Fixture: enraged at 19%")
    check(game.world.rage_fx.boss_id==str(a.id),"…aura on")
    check(sim.campaign.arena_active() and game.world.arena_fx.rage>.95,"…arena closed and its wall red (%s, %.2f)" % [sim.campaign.arena_active(),game.world.arena_fx.rage])
    check(game.final_audio.wanted_track()==game.final_audio.RAGE_TRACK,"…rage music")
    boss_kills_player(a)
    check(float(sim.state.player.hp)<=0 and defeats==[str(a.id)],"The Green Alien defeats the player (final_defeated_player)")
    check(not a.has("rage") and not sim.campaign.enraged(a),"Rage latch cleared at once")
    check(is_equal_approx(sim.campaign.attack_speed_factor(a),1.0) and is_equal_approx(sim.campaign.damage_taken_factor(a),1.0),"Attack speed and damage taken back to normal")
    a.skill_cds={};var h0: float=float(a.hp)
    a.hp=maxhp()*.3;h0=float(a.hp)
    sim.campaign.apply_skill(a,"heal",float(sim.catalog.skills.heal.power))
    check(absf(float(a.hp)-h0-maxhp()*.04)<1.0,"Healing back to 4% (no +20%)")
    await frames(30)
    check(game.world.rage_fx.boss_id=="" and not game.world.rage_fx.visible,"Red aura gone")
    check(game.final_audio.wanted_track()==null,"Rage music released")
    # The boss recovers (its return heals it), the player comes back: the next fight starts normal.
    a.hp=maxhp()*.3
    sim.state.player.respawn=0.0;steps(.1);sturdy()
    steps(25.0);a=alien()
    check(float(a.hp)>=maxhp()*.99 and not sim.campaign.enraged(a),"The boss recovers to full HP, not enraged (%.0f%%)" % [float(a.hp)/maxhp()*100.0])
    place(Vector2(30,0));steps(.2);calm_boss()
    var t0:=Time.get_ticks_msec()
    while Time.get_ticks_msec()-t0<1400:await get_tree().process_frame
    check(sim.campaign.arena_active() and game.world.arena_fx.rage<.01 and not sim.campaign.enraged(alien()),"New fight: arena closed, wall its normal colour, not enraged")
    check(game.final_audio.wanted_track()==game.final_audio.NORMAL_TRACK,"…normal battle music")
    enrage()
    check(sim.campaign.enraged(alien()) and rages.size()==2,"It enrages again at 20% (a second activation)")
    await real_wait(1.2)
    check(game.world.rage_fx.boss_id==str(alien().id),"…aura again")
    check(game.world.arena_fx.rage>.5,"…red wall again (%.2f)" % game.world.arena_fx.rage)

# ================================================================ 3. ENRAGED! text
## In the map's own viewport (the world draws in a SubViewport, the map area of the screen).
func view_screen_rect(view,local: Rect2) -> Rect2:
    return view.get_viewport().get_canvas_transform()*view.get_global_transform()*local

func text_checks() -> void:
    print("-- ENRAGED! floating text")
    for size in [Vector2i(540,960),Vector2i(432,960)]:
        get_window().size=size
        await frames(4)
        var a:=engaged();calm_boss()
        game.world.follow_player()
        await frames(10)
        enrage();a=alien()
        await frames(2)
        var t=game.world.enraged_text
        check(t!=null and is_instance_valid(t) and t.label.text=="ENRAGED!" and t.flames.size()==2 and t.flames[0].texture==game.world.textures.get("skill_fire"),"%dx%d: one ENRAGED! text with fire on both sides" % [size.x,size.y])
        if t==null or not is_instance_valid(t):continue
        check(not sim.held and not get_tree().paused and not game.final_dialog.is_open(),"…non-blocking (world not held, nothing modal)")
        var c0: float=float(sim.state.clock);steps(.2)
        check(float(sim.state.clock)>c0,"…combat time keeps running")
        # Move it to its hold phase and measure.
        await real_wait(1.8) # the arena close pull-back eases the camera back first
        if not is_instance_valid(t):continue
        t.age=1.5;await frames(2);t._process(0.0)
        var view=game.world.views[str(a.id)]
        var r: Rect2=t.screen_rect()
        var vp: Rect2=view.get_viewport().get_visible_rect()
        print("  map viewport ",vp.size," (headless keeps its own window size; windowed runs use the requested one)")
        var hp_top: float=view_screen_rect(view,Rect2(view._hp.position,view._hp.size)).position.y
        var icons_top:=INF
        for s in view._skills.get_children():
            var half: float=view.skill_icon_size*.62
            icons_top=minf(icons_top,view_screen_rect(view,Rect2(s.position-Vector2.ONE*half,Vector2.ONE*half*2)).position.y)
        var name_rect: Rect2=view_screen_rect(view,Rect2(view._name.position,view._name.size*view._name.scale))
        var stack: Rect2=view_screen_rect(view,Rect2(view._hp.position,view._hp.size)).merge(name_rect)
        for s in view._skills.get_children():
            var half: float=view.skill_icon_size*.62
            stack=stack.merge(view_screen_rect(view,Rect2(s.position-Vector2.ONE*half,Vector2.ONE*half*2)))
        check(not r.intersects(stack) and (r.end.y<=stack.position.y or t.below),"…%s the HP bar, name and skill icons, never over them (text %.0f..%.0f px, stack %.0f..%.0f px)" % ["below" if t.below else "above",r.position.y,r.end.y,stack.position.y,stack.end.y])
        check(r.position.x>=vp.position.x and r.end.x<=vp.end.x and r.position.y>=vp.position.y and r.end.y<=vp.end.y,"…inside the %.0f x %.0f map (%.0f..%.0f, %.0f..%.0f px)" % [vp.size.x,vp.size.y,r.position.x,r.end.x,r.position.y,r.end.y])
        check(r.size.y>=36.0 and r.size.x<=vp.size.x*.9,"…large: %.0f x %.0f px" % [r.size.x,r.size.y])
        var hud: Array=game.map_hud_rects()
        var hit:=""
        for h in hud:
            if r.intersects(h):hit+=str(h)+" "
        check(hud.size()>=5 and hit=="","…clear of all %d HUD controls over the map (rails, banner, toast, joystick) %s" % [hud.size(),hit])
        if windowed:
            await frames(2)
            var dir:="res://generated/evidence/change_86"
            DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
            var path:=dir+"/enraged_%dx%d.png" % [size.x,size.y]
            get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
            print("  saved ",path)
    get_window().size=Vector2i(540,960)
    await frames(4)
    # Timeline: pop-in, hold, gradual fade, gone at 5 s.
    var script: GDScript=load("res://scripts/game/enraged_text.gd")
    check(is_equal_approx(script.LIFE,5.0) and script.alpha_at(0.0)<.01 and is_equal_approx(script.alpha_at(2.5),1.0) and script.alpha_at(4.2)<1.0 and script.alpha_at(4.2)>script.alpha_at(4.8) and script.alpha_at(4.99)<.02,"5 s: fades in, holds, fades out gradually")
    check(script.pop_at(.2)>script.pop_at(.02) and is_equal_approx(script.pop_at(1.0),1.0),"Animated entrance (pop) settling at full size")
    var t2=game.world.enraged_text
    if t2!=null and is_instance_valid(t2):
        t2.age=4.9;t2._process(0.0)
        check(is_instance_valid(t2) and t2.modulate.a<.1,"At 4.9 s almost faded")
        t2._process(.2);await frames(2)
        check(not is_instance_valid(t2) or t2.is_queued_for_deletion(),"Gone after 5 s")
    steps(2.0);await frames(2)
    check(game.world.enraged_text==null or not is_instance_valid(game.world.enraged_text),"No second text without a new activation")
    # Real-time duration: about 5 s of frames.
    var a3:=engaged();calm_boss();enrage();await frames(2)
    var t3=game.world.enraged_text
    var start:=Time.get_ticks_msec()
    while t3!=null and is_instance_valid(t3) and Time.get_ticks_msec()-start<7000:await get_tree().process_frame
    var lasted:=(Time.get_ticks_msec()-start)/1000.0
    check(lasted>4.6 and lasted<5.6,"On screen for %.1f s" % lasted)

# ================================================================ 4. Death laugh
func laugh_checks() -> void:
    print("-- Death laugh")
    own_settings(.8,.6,false,false)
    var a:=engaged();calm_boss()
    AudioService.reset_history();await frames(1)
    boss_kills_player(a)
    check(game.final_audio.death_laughs.size()==1 and game.final_audio.death_laughs[0] in LAUGHS,"Normal boss defeats the player: one laugh (%s)" % [game.final_audio.death_laughs])
    check(AudioService.played_log.size()>0 and AudioService.played_log[0] in LAUGHS,"…played at once, in the death step")
    await frames(2)
    check(AudioService.played_log.has("arena_open") and AudioService.played_log.filter(func(c):return c in LAUGHS).size()==1,"…the arena-open cue of the same frame plays too, not instead (%s)" % [AudioService.played_log.slice(0,4)])
    check(game.final_audio.death_laugh_playing(),"…and is marked as playing for its length")
    # No random laugh on top of it.
    game.final_audio.laughs_requested.clear();game.final_audio.laugh_clock=0.0;game.final_audio.rage_quiet=0.0
    var p: Dictionary=sim.state.player
    p.respawn=0.0;steps(.1);sturdy();place(Vector2(30,0));steps(.2);calm_boss()
    game.final_audio.laugh_clock=0.0;game.final_audio._process(.1)
    check(game.final_audio.laughs_requested.is_empty(),"No random laugh while the death laugh plays")
    # Enraged, every time.
    fresh();a=engaged();calm_boss();enrage();a=alien()
    AudioService.reset_history()
    boss_kills_player(a)
    check(game.final_audio.death_laughs.size()==1 and float(sim.state.player.hp)<=0,"Enraged boss defeats the player: it laughs too")
    # A second defeat in a row laughs again (no cue cooldown skips it).
    sim.state.player.respawn=0.0;steps(.1);sturdy();place(Vector2(30,0));steps(.2);calm_boss()
    game.final_audio.death_laugh_until_ms=0
    boss_kills_player(alien())
    check(game.final_audio.death_laughs.size()==2,"Every defeat: a second one right after laughs again")
    # Its helper's blow counts; a defeat by anything else does not.
    fresh();a=engaged();calm_boss()
    var rule: SummonRule=sim.abilities.summon_rule(str(sim.catalog.groups[final_g()].id))
    sim.spawn_helpers(a,rule,sim.campaign.group_id(rule.helper_id),1)
    var helper: Dictionary=sim.helpers_of(str(a.id))[0] if not sim.helpers_of(str(a.id)).is_empty() else {}
    check(not helper.is_empty(),"Fixture: one Green Alien helper")
    if not helper.is_empty():
        boss_kills_player(helper)
        check(game.final_audio.death_laughs.size()==1 and defeats==[str(a.id)],"Its summoned helper's killing blow: the Green Alien laughs")
    fresh();spring_two();sturdy()
    var other: Dictionary={}
    for e in sim.state.enemies:
        if not bool(sim.catalog.groups[int(e.group)].final) and not sim.is_helper(e) and float(e.hp)>0:other=e;break
    boss_kills_player(other)
    check(float(sim.state.player.hp)<=0 and game.final_audio.death_laughs.is_empty() and defeats.is_empty(),"Another enemy's kill: no laugh")
    # Muted Gameplay Sounds silence it (the player's preference).
    own_settings(.8,.6,true,false)
    a=engaged();calm_boss();AudioService.reset_history()
    boss_kills_player(a)
    check(game.final_audio.death_laughs.is_empty() and not AudioService.played_log.any(func(c):return c in LAUGHS),"Gameplay Sounds muted: no laugh")

# ================================================================ 1b. Recommended mix and the death laugh
func death_restore_checks() -> void:
    print("-- Death: laugh under the recommended mix, then the player's settings")
    own_settings(.8,.6,true,true)
    var a:=engaged();calm_boss();await frames(2)
    game.get_node("Safe/Layout/Map/FinalAudio").pressed.emit()
    check(settings_are(.4,1.0,false,false),"Chip: recommended mix with sounds unmuted")
    AudioService.reset_history()
    boss_kills_player(a);await frames(2)
    check(game.final_audio.death_laughs.size()==1,"The laugh plays although the player's own settings mute Gameplay Sounds")
    check(SettingsState.recommended_active() and settings_are(.4,1.0,false,false) and game.final_audio.restore_due,"The restore waits for the laugh (it is not cut off)")
    game.final_audio.death_laugh_until_ms=Time.get_ticks_msec() # fixture: the laugh has just ended
    await frames(3)
    check(not SettingsState.recommended_active() and settings_are(.8,.6,true,true),"After it: the player's own settings, mutes included")
    # A death without the Green Alien's blow restores at once, as before.
    own_settings(.8,.6,true,true)
    a=engaged();calm_boss();await frames(2)
    game.get_node("Safe/Layout/Map/FinalAudio").pressed.emit()
    sim.state.player.hp=0.0;sim._kill(sim.state.player);await frames(2)
    check(not SettingsState.recommended_active() and settings_are(.8,.6,true,true),"Any other death: restored at once")
