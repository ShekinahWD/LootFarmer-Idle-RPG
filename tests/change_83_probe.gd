extends Node
## Change 83 focused checks (real main scene and simulation; state set directly is labelled "fixture"). No combat
## ladders, balance sweeps or player profiles: the Green Alien is put into each state directly.
## 1. Catalog: HP and attack x2 exactly, interval and other values unchanged; skills and Heal follow once.
## 2. Rage Mode: once at <= 20% after damage, +50% attack speed, damage taken / 1.3, heals +20%, one immediate
##    Heal with its cooldown, latched through healing and save/load, dropped at death; the next boss is normal.
## 3. The arena wall turns red with the rage and back for the next boss; geometry and blocking unchanged.
## 4. Danger warning: before the first updated encounter for new and old (unsealed / victorious) saves; held world;
##    No / re-arm / tap; Yes saves and replays the full ceremony; later fights skip both; interruptions.
## 5. Audio: boss / rage / main music routing, enrage cue, occasional laughs, the temporary recommended mix (kept
##    for the first celebration, restored otherwise, never saved, a deliberate change kept), the near-boss chip.
## 6. Boss Keys quest in Missions (after the discovery only), the final-boss map marker.
## 7. Victories: the first 10 s celebration (frozen, floor, dancers within 5 s, respawn held) then the ending
##    panel; Continue/links acknowledge once; deferred delivery; later victories non-blocking; floor lifecycle.
## 8. Game Completion: zero / partial / full, each category, latch through Prestige, old saves, Hard Reset.
## Run: Godot --headless --path . res://tests/change_83_probe.tscn -- --probe --profile=probe-c83 --no-autosave --first-run-complete
const LINKS=preload("res://resources/game/external_links.tres")
var checks:=0
var failures:=0
var game
var sim
var phases: Array=[]
var warnings: Array=[]
var victories: Array=[]
var rages: Array=[]
var events: Array=[]

func check(ok: bool,label_: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(label_)
    else:print("  ok  ",label_)
func frames(n:=4) -> void:
    for i in range(n):await get_tree().process_frame
func _ready() -> void:call_deferred("run")

func run() -> void:
    get_tree().create_timer(600.0,true,false,true).timeout.connect(func():push_error("CHANGE_83 watchdog");get_tree().quit(2))
    SettingsState.mute_all_sfx()
    SettingsState.set_music_volume(.8);SettingsState.set_sfx_volume(.6)
    TranslationServer.set_locale("en")
    get_window().size=Vector2i(540,960)
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game);sim=game.sim
    sim.final_ceremony.connect(func(p: String)->void:phases.append(p))
    sim.final_warning.connect(func(p: String)->void:warnings.append(p))
    sim.final_victory.connect(func(k: String)->void:victories.append(k))
    sim.final_rage.connect(func(id: String)->void:rages.append(id))
    sim.event.connect(func(k: String)->void:events.append(k))
    await frames(6)
    catalog_checks()
    await rage_checks()
    await warning_checks()
    await audio_checks()
    await quest_marker_checks()
    await victory_checks()
    await completion_checks()
    print("CHANGE_83_CHECKS %d FAILURES %d" % [checks,failures])
    SettingsState.set_music_volume(1.0);SettingsState.set_sfx_volume(1.0)
    game.queue_free();await frames(2);AudioService.stop_all_sfx()
    get_tree().quit(1 if failures>0 else 0)

# ---------------------------------------------------------------- fixtures (shared with the Change 82 probe)
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
    game.key_fx.clear()
    phases.clear();warnings.clear();victories.clear();rages.clear();events.clear()
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
func all_keys() -> void:
    sim.state.final_discovered=true
    sim.state.keys=[]
    for d in sim.catalog.groups:
        if d.boss and not d.final:sim.state.keys.append(str(d.id)) # fixture: 13 keys earned
## The whole introduction done earlier (fixture), so the fight starts on approach.
func introduced() -> void:
    all_keys();sim.state.final_unsealed=true;sim.state.final_warning_ok=true;sim.state.final_experience=true
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
func run_ceremony() -> void:
    var guard:=0
    while sim.campaign.ceremony_active() and guard<400:
        sim.step(.05);guard+=1
func calm_boss() -> void:
    var a:=alien();a.cooldown=99.0;a.skill_timer=99.0;a.summon_cd=99.0 # fixture: the boss holds its attacks
func engaged() -> Dictionary:
    fresh();spring_two();sturdy();introduced()
    place(Vector2(30,0));steps(.1)
    return alien()
func die() -> void:
    sim.state.player.hp=0.0
    sim._kill(sim.state.player)
func defeat() -> void:
    var a:=alien()
    a.hp=0.0;sim._kill(a)
func maxhp() -> float:return float(sim.enemy_definition(final_g()).hp)

# ================================================================ 1. Catalog
func catalog_checks() -> void:
    print("-- Green Alien values")
    var d: Dictionary=sim.catalog.groups[final_g()]
    # Change 84 then lowers the attack x7/9 (tools/change84_catalog.py); HP keeps the Change 83 x2.
    check(absf(float(d.hp)-91354.1071*2.0)<.01 and absf(float(d.damage)-622.7689*2.0/3.252*2.5293)<.01,"HP 91,354 -> %s (x2) and attack 622.8 -> %s (x2, then Change 84 x7/9)" % [d.hp,d.damage])
    check(is_equal_approx(float(d.interval),1.3) and int(d.respawn)==120 and d.skills==["focus","fire","strike"],"Interval, respawn and skills unchanged")
    check(sim.catalog.progression.balance.boss_tuning["boss-green-alien"]==[0.6,2.5293] and sim.catalog.progression.balance.boss_tuning["boss-sunflower"]==[0.3,1.356],"Only the Green Alien's tuning changed")
    check(is_equal_approx(float(sim.abilities.final_heal_fraction),.04) and is_equal_approx(float(sim.abilities.final_heal_below),.5) and is_equal_approx(float(sim.abilities.boss_skill_cooldown),10.0),"Heal: 4% of max HP below 50%, 10 s cooldown (existing values)")
    # A damage skill is definition damage x power: it doubles once with the hit.
    var def: Dictionary=sim.enemy_definition(final_g())
    check(absf(float(def.damage)-float(d.damage))<.001,"Skill base is the doubled hit, no extra multiplier")

# ================================================================ 2. Rage
func rage_checks() -> void:
    print("-- Rage Mode")
    var a:=engaged();calm_boss()
    check(bool(a.aggro) and sim.campaign.arena_active(),"Fixture: the fight is on, arena closed")
    a.hp=maxhp()*.25;steps(.1)
    check(not sim.campaign.enraged(a) and rages.is_empty(),"25% HP: not enraged")
    a.hp=maxhp()*.19;var before: float=a.hp
    steps(.05)
    check(sim.campaign.enraged(a) and rages==[str(a.id)],"<= 20% after damage: enraged once")
    var expected:=maxhp()*.04*1.2
    check(absf(float(a.hp)-before-expected)<maxhp()*.002,"One immediate Heal of 4%% x 1.2 (%.0f)" % [float(a.hp)-before])
    check(absf(float(a.skill_cds.heal)-10.0)<.2,"…which starts the normal Heal cooldown")
    steps(1.0)
    check(rages.size()==1,"No second trigger while it stays low")
    a.hp=maxhp()*.6;steps(.2)
    check(sim.campaign.enraged(a),"Latched above 20% (healed)")
    check(is_equal_approx(sim.campaign.attack_speed_factor(a),1.5),"Attack speed x1.5 (interval 1.3 -> %.3f s)" % [1.3/sim.campaign.attack_speed_factor(a)])
    a.cooldown=0.0;a.windup=0.0;sim.state.player.x=float(a.x)+10;sim.state.player.y=float(a.y)
    sim._start_attack(a,sim.state.player,float(sim.catalog.groups[final_g()].interval)/sim.campaign.attack_speed_factor(a))
    check(absf(float(a.cooldown)-1.3/1.5)<.001,"Its next attack starts 0.867 s after the last")
    calm_boss()
    var mult_rage: float=sim.campaign.damage_multiplier(sim.state.player,a)
    a.rage=false
    var mult_normal: float=sim.campaign.damage_multiplier(sim.state.player,a)
    a.rage=true
    check(absf(mult_rage*1.3-mult_normal)<1e-6,"Damage taken / 1.3 (defense +30%)")
    a.hp=maxhp()*.3;a.skill_cds.heal=0.0
    var h0: float=a.hp
    check(sim.campaign.apply_skill(a,"heal",float(sim.catalog.skills.heal.power)) and absf(float(a.hp)-h0-maxhp()*.048)<1.0,"A later Heal restores +20% (4.8%)")
    # Other values untouched.
    check(is_equal_approx(sim.campaign.attack_speed_factor(sim.state.player),1.0) and is_equal_approx(sim.campaign.damage_taken_factor(sim.state.player),1.0),"The player is never affected")
    # Save / load keeps the latch while this boss lives.
    SaveService.save_now();SaveService.load_and_apply();await frames(2)
    a=alien()
    check(sim.campaign.enraged(a),"Rage survives save / load")
    # Player death: since Change 86 it ends the encounter's Rage (tests/change_86_probe covers the details).
    die();steps(.2)
    check(not bool(alien().get("rage",false)),"A player death resets it (Change 86)")
    # Arena wall colour (needs a closed arena with this boss, enraged again at 20%).
    var p: Dictionary=sim.state.player
    p.respawn=0.0;steps(.1);sturdy();place(Vector2(30,0));steps(.2);calm_boss()
    alien().hp=maxhp()*.19;steps(.05);calm_boss()
    await frames(30);await wall_settled()
    check(sim.campaign.arena_active() and game.world.arena_fx.boss_enraged() and game.world.arena_fx.rage>.95,"The arena wall is red while it is enraged (%.2f)" % game.world.arena_fx.rage)
    check(is_equal_approx(sim.campaign.arena_radius(),118.0),"Radius 118 unchanged")
    var old_r: float=sim.campaign.arena_radius()
    # Defeat: rage dropped; the next boss starts normal.
    a=alien();a.hp=1.0;sim.state.final_ending_seen=true # fixture: the ending is not under test here
    defeat()
    check(not alien().has("rage"),"Defeat drops the latch")
    await wall_settled()
    check(not sim.campaign.arena_active() and game.world.arena_fx.phase=="" and game.world.arena_fx.rage<.01,"…and the wall opens and resets")
    a=alien();sim.state.boss_respawns.clear();a.respawn=0.0;steps(.1)
    check(float(alien().hp)>0 and not sim.campaign.enraged(alien()),"The next Green Alien begins normal")
    place(Vector2(30,0));steps(.2);await wall_settled()
    check(sim.campaign.arena_active() and game.world.arena_fx.rage<.01 and is_equal_approx(sim.campaign.arena_radius(),old_r),"Its wall is the normal colour")

# ================================================================ 4. Warning
func warning_checks() -> void:
    print("-- Danger warning")
    fresh();spring_two();sturdy();all_keys()
    var a:=alien()
    place(Vector2(80,0));sim.step(.05)
    check(warnings==["ask"] and sim.campaign.warning_pending==str(a.id) and not sim.campaign.ceremony_active() and phases.is_empty(),"New profile, first approach: the question, no ceremony yet")
    await frames(3)
    check(game.final_dialog.is_open() and game.final_dialog.kind=="warning" and sim.held,"The panel is open and holds the world")
    check(game.final_dialog.title.text=="FINAL BOSS — DANGER" and game.final_dialog.body.text.contains("no escape"),"Danger text")
    check(not sim.campaign.arena_active() and not bool(a.aggro) and AudioService.boss_music()==null,"No arena, combat or boss music while asking")
    # Recommended volume does not answer.
    game.final_dialog.button("audio").pressed.emit()
    check(game.final_dialog.is_open() and SettingsState.recommended_active() and is_equal_approx(SettingsState.music_volume,.4) and is_equal_approx(SettingsState.sfx_volume,1.0),"Set Recommended Volume: 40% / 100%, still asking")
    # No.
    game.final_dialog.button("no").pressed.emit();await frames(2)
    check(not game.final_dialog.is_open() and warnings.back()=="declined" and not bool(sim.state.final_warning_ok),"No: closed, nothing accepted")
    check(not SettingsState.recommended_active() and is_equal_approx(SettingsState.music_volume,.8) and is_equal_approx(SettingsState.sfx_volume,.6),"…and the temporary mix is restored")
    steps(1.0)
    check(warnings.size()==2 and not sim.campaign.ceremony_active() and not bool(alien().aggro),"Standing there: no re-prompt, no fight")
    place(Vector2(200,0));steps(.2);place(Vector2(80,0));sim.step(.05)
    check(warnings.back()=="ask","Walking away and back asks again")
    game.final_dialog.back();await frames(2)
    check(warnings.back()=="declined","Back is No")
    check(not sim.select_target(str(alien().id)) and warnings.back()=="ask","A tap asks again at once")
    # Reload while asking: not accepted.
    var snap: Dictionary=sim.snapshot()
    sim.restore(snap);sim.set_physics_process(false);await frames(2)
    check(not bool(sim.state.final_warning_ok) and sim.campaign.warning_pending=="","An unanswered question is not accepted after a reload")
    if game.final_dialog.is_open():game.final_dialog.close()
    sim.held=false # the UI derives it next frame
    # Yes.
    spring_two();sturdy();place(Vector2(200,0));steps(.1);place(Vector2(80,0));sim.step(.05);await frames(2)
    var keys_before: Array=sim.state.keys.duplicate()
    game.final_dialog.button("yes").pressed.emit();await frames(1)
    check(bool(sim.state.final_warning_ok) and sim.campaign.ceremony_active() and phases.back()=="start","Yes: saved, the full ceremony starts")
    # Interrupted ceremony: replays without asking.
    sim.restore(sim.snapshot());sim.set_physics_process(false);phases.clear();warnings.clear()
    spring_two();sturdy();place(Vector2(80,0));sim.step(.05)
    check(warnings.is_empty() and sim.campaign.ceremony_active(),"Interrupted ceremony: replays on the next approach, no question")
    run_ceremony()
    check(bool(sim.state.final_experience) and bool(sim.state.final_unsealed) and sim.state.keys==keys_before,"Completed: introduction saved, keys untouched")
    sim.step(.05)
    check(bool(alien().aggro) and sim.campaign.arena_active(),"…then the fight and the arena")
    # Later fights skip both.
    die();steps(.1);sim.state.player.respawn=0.0;steps(.1);sturdy();phases.clear();warnings.clear()
    place(Vector2(30,0));steps(.3)
    check(phases.is_empty() and warnings.is_empty() and bool(alien().aggro),"Later attempts: straight to combat")
    # Prestige keeps; Hard Reset clears.
    for key in ["final_warning_ok","final_experience","final_celebrated","final_ending_seen","completion_maxed"]:
        check(sim.campaign.has_method("final_ready") and sim.state.has(key),"State has "+key)
    # Old saves: a Change 82 unsealed / victorious profile sees it once.
    fresh();spring_two();sturdy();all_keys()
    var old: Dictionary=sim.snapshot()
    old.final_unsealed=true;old.erase("final_warning_ok");old.erase("final_experience");old.erase("final_celebrated");old.erase("final_ending_seen")
    old.group_kills[final_g()]=3 # fixture: defeated three times before this update
    sim.state.final_experience=true # fixture: the live profile must not leak into the loaded one
    sim.restore(old);sim.set_physics_process(false);await frames(2)
    check(not bool(sim.state.final_experience) and not bool(sim.state.final_warning_ok) and not bool(sim.state.final_ending_seen),"Old winner save: none of the new flags assumed")
    spring_two();sturdy();place(Vector2(80,0));sim.step(.05);await frames(2)
    check(warnings.back()=="ask" and game.final_dialog.is_open(),"…it gets the question on approach")
    var kills: int=int(sim.state.group_kills[final_g()])
    game.final_dialog.button("yes").pressed.emit();await frames(1)
    check(sim.campaign.ceremony_active(),"…and the full 13-key ceremony replays")
    run_ceremony()
    check(int(sim.state.group_kills[final_g()])==kills and sim.state.keys.size()==13 and bool(sim.state.final_experience),"…no kill, key or unlock changed")
    SaveService.hard_reset();sim.set_physics_process(false);await frames(2)
    check(not bool(sim.state.final_warning_ok) and not bool(sim.state.final_experience) and sim.state.completion_maxed.is_empty(),"Hard Reset clears the new flags")

# ================================================================ 5. Audio
func audio_checks() -> void:
    print("-- Audio")
    var normal: AudioStream=load("res://assets/sounds/EndGame - Music 1 (1).ogg")
    var rage: AudioStream=load("res://assets/sounds/EndGame - Music 1 (2).ogg")
    check(AudioService.has_cue("final_enraged") and AudioService.has_cue("final_laugh_1") and AudioService.has_cue("final_laugh_3") and AudioService.has_cue("final_laugh_5"),"Enraged and three laugh cues registered")
    check(normal.loop and rage.loop,"Both battle tracks loop")
    var a:=engaged();calm_boss();await frames(2)
    check(AudioService.boss_music()==normal,"Combat: EndGame - Music 1 (1)")
    a.hp=maxhp()*.15;steps(.05);await frames(2)
    check(AudioService.boss_music()==rage,"Rage: EndGame - Music 1 (2)")
    # Laughs while fighting (time forwarded on the audio node only).
    game.final_audio.laughs_requested.clear();game.final_audio.rage_quiet=0.0
    for i in range(6):game.final_audio._process(10.0)
    check(game.final_audio.laughs_requested.size()>=1 and game.final_audio.laughs_requested.size()<=3 and game.final_audio.laughs_requested.all(func(c):return c in ["final_laugh_1","final_laugh_3","final_laugh_5"]),"Occasional laughs: %s in 60 s" % [game.final_audio.laughs_requested])
    # Recommended mix during the fight, restored at the player's death.
    game.get_node("Safe/Layout/Map/FinalAudio").pressed.emit()
    check(SettingsState.recommended_active() and is_equal_approx(SettingsState.music_volume,.4),"Chip: recommended mix on")
    var saved: Dictionary=SettingsState.to_save_dict()
    check(is_equal_approx(float(saved.music_volume),.8) and is_equal_approx(float(saved.sfx_volume),.6),"The save keeps the player's own volumes")
    die();await frames(2)
    check(not SettingsState.recommended_active() and is_equal_approx(SettingsState.music_volume,.8) and is_equal_approx(SettingsState.sfx_volume,.6),"Death restores both")
    check(AudioService.boss_music()==null,"…and the main music returns")
    # A deliberate change in the meantime is kept.
    sim.state.player.respawn=0.0;steps(.1);sturdy();place(Vector2(30,0));steps(.2);calm_boss();await frames(2)
    game.get_node("Safe/Layout/Map/FinalAudio").pressed.emit()
    SettingsState.set_music_volume(.25)
    place(Vector2(600,0));die();await frames(2)
    check(is_equal_approx(SettingsState.music_volume,.25) and is_equal_approx(SettingsState.sfx_volume,.6),"A volume the player changed is kept; the other is restored")
    SettingsState.set_music_volume(.8)
    # Leaving restores (no fight).
    fresh();spring_two();sturdy();introduced();place(Vector2(200,0));calm_boss();await frames(2)
    check(game.get_node("Safe/Layout/Map/FinalAudio").visible,"Near the living boss: the chip shows")
    game.get_node("Safe/Layout/Map/FinalAudio").pressed.emit()
    place(Vector2(700,0));await frames(3)
    check(not SettingsState.recommended_active() and is_equal_approx(SettingsState.music_volume,.8),"Walking away restores it")
    check(not game.get_node("Safe/Layout/Map/FinalAudio").visible,"…and the chip hides")
    # Mute behaviour preserved.
    check(SettingsState.mute_gameplay and SettingsState.mute_special,"Mutes back to the player's own (Change 86: the mix turns them off while it lasts)")

# ================================================================ 6. Quest and marker
func quest_marker_checks() -> void:
    print("-- Boss Keys quest and marker")
    fresh();spring_two()
    game._open("missions");await frames(3)
    check(not labels(game.rows).contains("Final Boss ·"),"Before the discovery: no quest")
    game._close()
    sim.state.final_discovered=true;sim.state.keys=["boss-snowman","boss-bee"]
    sim.state.stage=1;sim.campaign.configure_stage();sim._reset_world()
    game._open("missions");await frames(3)
    var text:=labels(game.rows)
    check(text.contains("Final Boss · Green Alien") and text.contains("Boss keys: 2 / 13"),"On Winter I: the quest with 2 / 13")
    check(text.contains("Snowman · key collected") and text.contains("Defeat Cyan Robot — Winter II") and text.contains("Defeat Sunflower — Spring II"),"Held keys checked; missing ones name the boss and its stage")
    game._close()
    all_keys()
    game._open("missions");await frames(3)
    check(labels(game.rows).contains("Return to Green Alien — Spring II"),"13/13: return to the Green Alien")
    game._close()
    # Marker: 40% larger than a boss marker; others unchanged.
    var mv=game.get_node("Safe/Layout/Map/MiniMap")
    var bee:=-1
    for g in range(sim.catalog.groups.size()):
        if sim.catalog.groups[g].id=="boss-bee":bee=g
    check(is_equal_approx(mv._size_factor(final_g()),1.25*1.4) and is_equal_approx(mv._size_factor(bee),1.25) and is_equal_approx(mv._size_factor(0),1.0),"Final marker 1.4x a boss marker; others as before")

## Real time for the wall's colour blend / opening (headless frames are very short).
func wall_settled() -> void:
    var t0:=Time.get_ticks_msec()
    while Time.get_ticks_msec()-t0<1100:await get_tree().process_frame

func labels(node: Node) -> String:
    var out:=""
    for l in node.find_children("*","Label",true,false):out+=str(l.text)+"\n"
    for b in node.find_children("*","Button",true,false):out+=str(b.text)+"\n"
    return out

# ================================================================ 7. Victories
func victory_checks() -> void:
    print("-- Victories")
    var a:=engaged();calm_boss()
    # A few outfits owned (fixture), one twice.
    var outfits: Array=sim.campaign.floor_outfits()
    for id in outfits.slice(0,6):sim.state.items[id]={"qty":1,"merge":1.0,"extras":{}}
    sim.state.items[outfits[0]].qty=3
    check(outfits.size()==48 and sim.campaign.owned_floor_outfits().size()==6,"48 obtainable outfits; 6 owned (copies count once)")
    game.get_node("Safe/Layout/Map/FinalAudio").pressed.emit()
    a.hp=maxhp()*.15;steps(.05)
    defeat();await frames(2)
    check(victories==["first"] and sim.campaign.celebration_active(),"First victory: the celebration starts")
    check(not sim.campaign.arena_active() and AudioService.boss_music()==null,"Arena open; main music at once")
    check(SettingsState.recommended_active(),"The accepted mix stays for the celebration")
    var respawn: float=float(sim.state.boss_respawns[str(alien().id)].remaining)
    var clock: float=sim.state.clock
    sim.movement=Vector2.RIGHT;var pos: Vector2=sim.position_of(sim.state.player)
    steps(5.0)
    await frames(int(5.2*60))
    check(sim.state.clock==clock and sim.position_of(sim.state.player)==pos,"World frozen during it")
    check(game.world.dance_floor!=null and game.world.dance_floor.dancers.size()==6,"The floor with all 6 dancers within 5 s (%d)" % [game.world.dance_floor.dancers.size() if game.world.dance_floor!=null else -1])
    check(game.world.dance_floor.count_label.text=="Outfits dancing: 6 / 48","Caption: Outfits dancing: 6 / 48")
    steps(4.9)
    check(sim.campaign.celebration_active() and not game.final_dialog.is_open(),"No panel before 10 s")
    steps(.2);await frames(3)
    check(not sim.campaign.celebration_active() and bool(sim.state.final_celebrated) and game.final_dialog.is_open() and game.final_dialog.kind=="ending","At 10 s: the ending panel")
    check(not SettingsState.recommended_active() and is_equal_approx(SettingsState.music_volume,.8),"…and the player's volumes are back")
    check(float(sim.state.boss_respawns[str(alien().id)].remaining)==respawn,"The respawn clock waited")
    check(game.final_dialog.body.text.begins_with("You defeated the Green Alien and completed LootFarmer's main adventure."),"Ending text")
    # Links: stubbed opener. Change 88: Discord opens the invite and leaves the panel up (not an acknowledgment);
    # Continue Playing acknowledges once and the panel never comes back.
    var opened: Array=[]
    var links=LINKS
    links.opener=func(url: String)->int:opened.append(url);return OK
    links.reset_guard()
    game.final_dialog.button("discord").pressed.emit();await frames(2)
    check(opened==["https://discord.gg/JKjeP6PDAU"] and not bool(sim.state.final_ending_seen) and game.final_dialog.is_open(),"Discord opens the official invite and keeps the panel (Change 88)")
    game.final_dialog.button("continue").pressed.emit();await frames(2)
    check(bool(sim.state.final_ending_seen) and not game.final_dialog.is_open(),"Continue Playing acknowledges once")
    links.opener=func(url: String)->int:return OS.shell_open(url)
    sim.movement=Vector2.ZERO
    var pos2: Vector2=sim.position_of(sim.state.player)
    sim.movement=Vector2.RIGHT;steps(.5);sim.movement=Vector2.ZERO
    check(sim.position_of(sim.state.player)!=pos2,"Normal play resumes")
    check(game.world.dance_floor!=null,"The floor stays until the boss respawns")
    # Respawn: floor gone.
    sim.state.boss_respawns.clear();alien().respawn=0.0;steps(.1);await frames(3)
    check(float(alien().hp)>0 and game.world.dance_floor==null,"Respawn removes the floor")
    # Repeat victory: non-blocking.
    victories.clear();place(Vector2(30,0));steps(.2);calm_boss()
    game.get_node("Safe/Layout/Map/FinalAudio").pressed.emit()
    defeat();await frames(3)
    check(victories==["repeat"] and not sim.campaign.celebration_active() and not game.final_dialog.is_open(),"Later victory: no cutscene, no panel")
    check(not SettingsState.recommended_active(),"…the temporary mix ends with the fight")
    var c0: float=sim.state.clock
    steps(.5)
    check(sim.state.clock>c0 and game.world.dance_floor!=null,"…play continues, the floor shows")
    # Leaving the map frees it; returning shows it again (boss still down).
    sim.state.stage=7;sim.campaign.configure_stage();sim._reset_world();await frames(3)
    check(game.world.dance_floor==null,"Another map: no floor")
    spring_two();await frames(3)
    # (spring_two resets the world; a fresh world has the boss alive)
    check(game.world.dance_floor==null or not sim.campaign.floor_visible()==false,"Floor follows the boss state")
    # Deferred delivery: celebrated, never acknowledged.
    a=engaged();calm_boss()
    sim.state.final_celebrated=true;sim.state.final_ending_seen=false # fixture: the app closed during the panel
    defeat();await frames(2)
    check(victories.back()=="deferred" and not sim.campaign.celebration_active() and not game.final_dialog.is_open(),"Owed message: no cinematic again")
    steps(3.1);await frames(3)
    check(game.final_dialog.is_open() and game.final_dialog.kind=="ending","…the panel after a short wait")
    game.final_dialog.button("continue").pressed.emit();await frames(2)
    check(bool(sim.state.final_ending_seen) and not game.final_dialog.is_open(),"Continue acknowledges it")
    # Prestige keeps the acknowledgement; save/load too.
    SaveService.save_now();sim.state.final_ending_seen=false;SaveService.load_and_apply();await frames(2)
    check(bool(sim.state.final_ending_seen) and bool(sim.state.final_celebrated),"Saved acknowledgement and celebration")
    # An interrupted first celebration (reload) is not counted.
    a=engaged();calm_boss()
    defeat()
    check(sim.campaign.celebration_active(),"Celebration running")
    sim.restore(sim.snapshot());sim.set_physics_process(false)
    check(not bool(sim.state.final_celebrated) and not sim.campaign.celebration_active() and not sim.campaign.ending_due,"A reload drops it without saving anything")

# ================================================================ 8. Completion
func completion_checks() -> void:
    print("-- Game Completion")
    fresh()
    var c=sim.campaign.completion
    var s: Dictionary=c.summary()
    check(int(s.percent)<5 and not s.complete and int(s.cards.total)==sim.catalog.campaign.cards.size() and int(s.mastery.total)==40,"Fresh: near 0%%, 48 cards, 40 Mastery objectives (%d%%)" % int(s.percent))
    check(int(s.player.total)>0 and int(s.enemy.total)>int(s.player.total),"Tracks: player %d, enemy %d" % [int(s.player.total),int(s.enemy.total)])
    var ids: Array=[]
    for t in c.tracks():ids.append(t[1])
    check(not ids.has("coin_chance") and not ids.has("skill_auto_0") and ids.has("skill_auto_slots") and ids.has("map_detail"),"No zero-rank or retired upgrades; map upgrades included")
    # Every card owned only: 25%.
    sim.state.owned_cards=sim.catalog.campaign.cards.keys()
    c._summary_frame=-1;s=c.summary()
    check(bool(s.cards.complete) and int(s.percent)>=25 and int(s.percent)<30,"All cards: that part complete (%d%%)" % int(s.percent))
    # Every upgrade at its cap.
    for t in c.tracks():
        var cap:=int(sim.catalog.upgrades[t[1]].cap)
        sim.state.upgrades[sim._upgrade_key(t[1],int(t[2]))]=cap
    sim._stats_revision=-1
    c._summary_frame=-1;s=c.summary()
    check(bool(s.player.complete) and bool(s.enemy.complete) and not s.complete and int(s.percent)<=99,"Upgrades maxed but Mastery not: %d%%, not 100" % int(s.percent))
    c.evaluate(false)
    check(sim.state.completion_maxed.size()==c.tracks().size(),"Maxed tracks latched")
    # A Prestige-style reset of Coin upgrades does not take it back.
    sim.state.upgrades.clear();c._summary_frame=-1
    check(bool(c.summary().player.complete),"Latched through an upgrade reset")
    # Mastery all done.
    for st in range(1,9):
        for cat in sim.campaign.mastery.CATEGORIES:sim.state.mastery.done.append("%d:%s" % [st,cat])
        sim.state.mastery.done.append("map:%d" % st)
    sim.state.mastery.done.append("game")
    c._summary_frame=-1;s=c.summary()
    check(bool(s.complete) and int(s.percent)==100 and is_equal_approx(float(s.fraction),1.0),"All four: exactly 100%")
    # Old save without the field: nothing assumed.
    var old: Dictionary=sim.snapshot();old.erase("completion_maxed");old.upgrades={}
    sim.restore(old);sim.set_physics_process(false)
    c._summary_frame=-1;s=c.summary()
    check(not bool(s.player.complete) and not s.complete,"Old save: upgrades counted from their ranks only")
    game._open("mastery");await frames(3)
    check(labels(game.rows).contains("Game Completion") and labels(game.rows).contains("Enemy upgrades maxed:"),"Mastery panel shows the breakdown")
    game._close()
