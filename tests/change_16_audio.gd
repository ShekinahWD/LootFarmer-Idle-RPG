extends Node
## Change 16 audio check, WINDOWED (not in the headless suite: the audio service never decodes the
## track headless). Real playback of the music track through the Settings volume: volume 0 holds the
## position instead of stopping, any volume above 0 resumes from there without a restart (also after
## dragging the slider through 0 several times), the game's pause holds and resumes it, a pause at
## volume 0 stays silent, and re-entering the game scene keeps the same playback.
## Run: godot --path . res://tests/change_16_audio.tscn -- --probe --profile=probe-c16-audio --no-autosave --first-run-complete
var checks:=0
var failures:=0
var game
func check(ok: bool,label_: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(label_)
    else:print("  ok  ",label_)
func _ready() -> void:call_deferred("run")
func wait(seconds: float) -> void:
    await get_tree().create_timer(seconds,true).timeout
func state() -> Dictionary:return AudioService.music_state()
func run() -> void:
    SettingsState.mute_all_sfx()
    SettingsState.set_music_volume(.5)
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game)
    game.sim.state.tutorial.mode="none";game.sim.suspended=false
    await wait(1.5)
    var s: Dictionary=state()
    check(s.stream!=null and s.started and not s.held and float(s.position)>.8,"The music plays (%.2f s in)" % float(s.position))
    SettingsState.set_music_volume(0.0)
    await wait(.3)
    var held: float=float(state().position)
    check(state().held and not AudioService.music_playing(),"Volume 0 holds the track (paused, not stopped)")
    await wait(1.0)
    check(absf(float(state().position)-held)<.05,"…its position stays at %.2f s while silent" % held)
    # Dragging the slider through 0 several times, ending above it.
    for v in [0.0,.1,0.0,.25,0.0,.4]:SettingsState.set_music_volume(v)
    await wait(1.0)
    s=state()
    check(not s.held and AudioService.music_playing(),"Raising the volume resumes playback (the old code stayed stopped for good)")
    check(float(s.position)>held+.5 and float(s.position)<held+2.0,"…from where it was (%.2f s → %.2f s), not from the start" % [held,float(s.position)])
    check(near_db(float(s.volume_db),linear_to_db(.4)-8.0),"…at the new volume (%.1f dB)" % float(s.volume_db))
    # The game's pause (the HUD button) holds it; Settings stays usable while paused.
    game._pause()
    await wait(.3)
    var paused_at: float=float(state().position)
    check(get_tree().paused and state().held,"Pause holds the music")
    SettingsState.set_music_volume(.7)
    await wait(.8)
    check(state().held and absf(float(state().position)-paused_at)<.05,"Changing the volume while paused keeps it held")
    game._pause()
    await wait(.8)
    s=state()
    check(not get_tree().paused and not s.held and float(s.position)>paused_at+.4 and float(s.position)<paused_at+1.6,"Resume continues it (%.2f s → %.2f s)" % [paused_at,float(s.position)])
    # A pause and resume at volume 0 stays silent and keeps its place.
    SettingsState.set_music_volume(0.0)
    game._pause();await wait(.2);game._pause();await wait(.5)
    var quiet: float=float(state().position)
    await wait(.6)
    check(state().held and absf(float(state().position)-quiet)<.05,"After a pause at volume 0 the music stays held, not silently running")
    SettingsState.set_music_volume(.5)
    await wait(.5)
    # Re-entering the game scene (a reload or Hard Reset) keeps the same playback.
    var before: float=float(state().position)
    game.queue_free();await get_tree().process_frame
    game=load("res://scenes/game/main.tscn").instantiate();add_child(game)
    game.sim.state.tutorial.mode="none";game.sim.suspended=false
    await wait(.6)
    s=state()
    check(not s.held and float(s.position)>=before and float(s.position)<before+1.5,"Re-entering the game scene keeps the track playing from %.2f s (now %.2f s)" % [before,float(s.position)])
    print("CHANGE_16_AUDIO_CHECKS ",checks," FAILURES ",failures)
    game.queue_free();await get_tree().process_frame
    AudioService.stop_all_sfx()
    await wait(.1)
    get_tree().quit(1 if failures else 0)
func near_db(a: float,b: float) -> bool:return absf(a-b)<.05
