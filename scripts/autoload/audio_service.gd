extends Node
## Sparse semantic-audio service (Playbook section 85). The game registers its cue set once
## (configure); callers then request semantic cue ids and never choose files, volumes or throttles.
##
## Change 12: two sound-effect categories with independent mutes (gameplay, special) under one
## sound-effect volume, plus a music volume. Everything requested during one frame is collected and
## only the highest-priority audible cue plays, so one state transition never stacks sounds (a click
## under a confirm, a step cue under Prestige ready). Each cue has a real-time cooldown. The decision
## logic also runs headless and records what it played (played_log) for probes.

const SFX_POOL_SIZE: int = 6
const SILENT_DB: float = -80.0
const LOG_SIZE: int = 64

## Cue id -> {stream, category, priority, cooldown, volume_db}.
var _cues: Dictionary = {}
var _music_stream: AudioStream
var _music_mix_db: float = 0.0
var _music_wanted: bool = false
var _pending: Array[String] = []
var _last_played_ms: Dictionary = {}
var _last_stream_ms: Dictionary = {}
var _sfx_players: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer
## Most recent first: cue ids that actually played (for probes; never read by gameplay).
var played_log: Array[String] = []
## Change 83: an encounter track that temporarily replaces the main music (the Green Alien's battle and Rage
## tracks). Two players crossfade between encounter tracks; the main track fades out and holds its place
## (stream pause, never restarted) while one plays, and fades back in when it is released. The same Music
## volume, mute-at-0 and pause rules apply; headless runs keep the routing state only (probes read it).
const BOSS_FADE_SECONDS: float = 1.2
var _boss_players: Array[AudioStreamPlayer] = []
var _boss_levels: Array[float] = [0.0, 0.0]
var _boss_current: int = -1
var _boss_wanted: AudioStream
var _boss_mix_db: float = 0.0
var _base_level: float = 1.0
var _fade_seconds: float = BOSS_FADE_SECONDS
## Most recent first: encounter tracks requested (resource paths, "" for a release), for probes.
var music_log: Array[String] = []


func _ready() -> void:
    # Requests are flushed while the game is paused too, so the pause menu keeps its clicks.
    process_mode = Node.PROCESS_MODE_ALWAYS
    for i in range(SFX_POOL_SIZE):
        var player := AudioStreamPlayer.new()
        player.process_mode = Node.PROCESS_MODE_ALWAYS
        add_child(player)
        _sfx_players.append(player)
    # The music holds its place while the game is paused (stream pause, never stop and restart).
    _music_player = AudioStreamPlayer.new()
    _music_player.process_mode = Node.PROCESS_MODE_PAUSABLE
    add_child(_music_player)
    _music_player.finished.connect(_on_music_finished)
    for i in range(2):
        var boss := AudioStreamPlayer.new()
        boss.process_mode = Node.PROCESS_MODE_PAUSABLE
        add_child(boss)
        _boss_players.append(boss)
    SettingsState.settings_changed.connect(_on_settings_changed)


## Registers a cue set resource (AudioCueSet): its music track and every cue.
func configure(cue_set: Resource) -> void:
    if cue_set == null:
        return
    for cue in cue_set.cues:
        if cue != null and String(cue.id) != "":
            register_cue(cue.id, cue.stream, cue.category, cue.priority, cue.cooldown, cue.volume_db)
    _music_stream = cue_set.music
    _music_mix_db = float(cue_set.music_volume_db)


func register_cue(id: String, stream: AudioStream, category: String = "gameplay", priority: int = 0, cooldown: float = 0.0, volume_db: float = 0.0) -> void:
    _cues[id] = {"stream": stream, "category": category, "priority": priority, "cooldown": cooldown, "volume_db": volume_db}


func has_cue(id: String) -> bool:
    return _cues.has(id)


func cue_category(id: String) -> String:
    return String(_cues.get(id, {}).get("category", ""))


## Requests one semantic cue. It plays at the end of the frame unless a higher-priority audible cue
## was requested in the same frame, its category is muted, the volume is 0 or it is cooling down.
func play(id: String) -> void:
    if _cues.has(id) and not _pending.has(id):
        _pending.append(id)


## Older call name kept for callers outside the game scripts.
func play_sfx(id: String) -> void:
    play(id)


func category_audible(category: String) -> bool:
    if SettingsState.sfx_volume <= 0.0:
        return false
    return not (SettingsState.mute_special if category == "special" else SettingsState.mute_gameplay)


func _process(delta: float) -> void:
    if not _pending.is_empty():
        flush()
    _step_boss_music(delta)


## Change 83: plays an encounter track in place of the main music (null releases it). Requesting the track
## already wanted does nothing; another one crossfades from the start of the new track.
func set_boss_music(stream: AudioStream, mix_db: float = 0.0, fade_seconds: float = BOSS_FADE_SECONDS) -> void:
    if stream == _boss_wanted:
        return
    _boss_wanted = stream
    _boss_mix_db = mix_db
    _fade_seconds = maxf(0.05, fade_seconds)
    music_log.push_front(stream.resource_path if stream != null else "")
    if music_log.size() > LOG_SIZE:
        music_log.pop_back()
    if stream == null:
        _boss_current = -1
        return
    var next := 0 if _boss_current != 0 else 1
    _boss_current = next
    var player := _boss_players[next]
    player.stream = stream
    _boss_levels[next] = 0.0
    if DisplayServer.get_name() != "headless":
        player.volume_db = SILENT_DB
        player.play()


## The encounter track wanted now (null: the main music).
func boss_music() -> AudioStream:
    return _boss_wanted


func _step_boss_music(delta: float) -> void:
    if is_inside_tree() and get_tree().paused:
        return
    var rate := delta / _fade_seconds
    var base_target := 0.0 if _boss_wanted != null else 1.0
    _base_level = move_toward(_base_level, base_target, rate)
    for i in range(_boss_players.size()):
        var target := 1.0 if i == _boss_current and _boss_wanted != null else 0.0
        _boss_levels[i] = move_toward(_boss_levels[i], target, rate)
        var player := _boss_players[i]
        if _boss_levels[i] <= 0.0 and target == 0.0:
            if player.playing or player.stream_paused:
                player.stop()
                player.stream_paused = false
            if i != _boss_current:
                player.stream = null
    _apply_boss_volumes()


func _apply_boss_volumes() -> void:
    for i in range(_boss_players.size()):
        var player := _boss_players[i]
        player.volume_db = _volume_to_db(SettingsState.music_volume * _boss_levels[i]) + _boss_mix_db if SettingsState.music_volume > 0.0 and _boss_levels[i] > 0.0 else SILENT_DB
        if player.stream != null and (player.playing or player.stream_paused):
            player.stream_paused = SettingsState.music_volume <= 0.0
    if _music_player.stream != null and (_music_player.playing or _music_player.stream_paused):
        _apply_music_volume()
        _music_player.stream_paused = music_should_hold()


## Resolves this frame's requests now (called every frame; probes may call it directly).
## Returns the cue id that played, or "".
func flush() -> String:
    var best := ""
    var now := Time.get_ticks_msec()
    for id in _pending:
        var cue: Dictionary = _cues[id]
        if not category_audible(String(cue.category)):
            continue
        if now - int(_last_played_ms.get(id, -1000000)) < int(float(cue.cooldown) * 1000.0):
            continue
        # Change 15: cues that share one sound (the notification family) share its cooldown, so two
        # notifications a frame apart never play the same file twice.
        if cue.stream != null and now - int(_last_stream_ms.get(cue.stream.get_instance_id(), -1000000)) < int(float(cue.cooldown) * 1000.0):
            continue
        if best == "" or int(cue.priority) > int(_cues[best].priority):
            best = id
    _pending.clear()
    if best == "":
        return ""
    _last_played_ms[best] = now
    if _cues[best].stream != null:
        _last_stream_ms[_cues[best].stream.get_instance_id()] = now
    played_log.push_front(best)
    if played_log.size() > LOG_SIZE:
        played_log.pop_back()
    var cue: Dictionary = _cues[best]
    if cue.stream != null:
        var player := _next_free_sfx_player()
        player.stream = cue.stream
        player.volume_db = _volume_to_db(SettingsState.sfx_volume) + float(cue.volume_db)
        player.set_meta("category", cue.category)
        player.set_meta("mix_db", float(cue.volume_db))
        player.play()
    return best


## Change 86: plays one cue at once, outside the frame's one-cue competition (so a higher-priority cue requested in
## the same frame, such as the arena opening, cannot drop it) and outside its own cooldown. Its category mute and
## the volume still apply, and a settings change still updates or stops it like any sound. Any sound-effect player
## still playing one of `replace` stops first (two laughs never overlap). The player is reserved until it ends, so a
## burst of other cues never steals it. Returns whether it played.
func play_now(id: String, replace: Array = []) -> bool:
    if not _cues.has(id):
        return false
    var cue: Dictionary = _cues[id]
    if not category_audible(String(cue.category)):
        return false
    var streams: Array = []
    for other in replace:
        if _cues.has(other) and _cues[other].stream != null:
            streams.append(_cues[other].stream)
    for player in _sfx_players:
        if player.playing and streams.has(player.stream):
            player.stop()
            player.set_meta("reserved", false)
    _pending.erase(id)
    var now := Time.get_ticks_msec()
    _last_played_ms[id] = now
    played_log.push_front(id)
    if played_log.size() > LOG_SIZE:
        played_log.pop_back()
    if cue.stream != null:
        _last_stream_ms[cue.stream.get_instance_id()] = now
        var player := _next_free_sfx_player()
        player.stream = cue.stream
        player.volume_db = _volume_to_db(SettingsState.sfx_volume) + float(cue.volume_db)
        player.set_meta("category", cue.category)
        player.set_meta("mix_db", float(cue.volume_db))
        player.set_meta("reserved", true)
        player.play()
    return true


## Seconds a cue's sound lasts (0 without a stream).
func cue_length(id: String) -> float:
    var stream: AudioStream = _cues.get(id, {}).get("stream", null)
    return stream.get_length() if stream != null else 0.0


## Forgets cooldowns, pending requests and the log (probes).
func reset_history() -> void:
    _pending.clear()
    _last_played_ms.clear()
    _last_stream_ms.clear()
    played_log.clear()


func play_music() -> void:
    _music_wanted = true
    _sync_music()


func stop_music() -> void:
    _music_wanted = false
    _music_player.stop()
    _music_player.stream_paused = false


## Change 16: one place decides the music player's state. A paused stream reports playing == false
## in Godot 4, so the old code left the music stopped for good once the volume touched 0 (the next
## volume change saw "not playing" and never unpaused it). Now the track starts only when it has not
## started yet; otherwise it is paused or resumed in place: Music volume 0 holds its position, any
## volume above 0 resumes it (no restart), and while the game is paused the track holds its place.
## Re-entering the game scene (Hard Reset, scene reload) keeps the same playback.
func _sync_music() -> void:
    # Headless runs (probes) keep the routing state but never decode or hold the track.
    if not _music_wanted or _music_stream == null or DisplayServer.get_name() == "headless":
        return
    if _music_player.stream != _music_stream:
        _music_player.stream = _music_stream
        _music_player.stream_paused = false
    _apply_music_volume()
    if not _music_player.playing and not _music_player.stream_paused:
        _music_player.play()
    _music_player.stream_paused = music_should_hold()


## Re-applies the music state after the game's pause changes (the engine resumes a pausable player on
## unpause even when the Music volume is 0; this holds it again).
func refresh_music() -> void:
    _sync_music()


## The track holds its place while the Music volume is 0 or the game is paused.
func music_should_hold() -> bool:
    return SettingsState.music_volume <= 0.0 or (is_inside_tree() and get_tree().paused) or (_base_level <= 0.0 and _boss_wanted != null)


func music_playing() -> bool:
    return _music_player.playing and not _music_player.stream_paused


## The configured track, whether the game asked for music, and the player's current level (probes).
func music_state() -> Dictionary:
    return {"stream": _music_stream, "wanted": _music_wanted, "volume_db": _music_player.volume_db,
        "held": _music_player.stream_paused, "position": _music_player.get_playback_position(),
        "started": _music_player.playing or _music_player.stream_paused}


func _next_free_sfx_player() -> AudioStreamPlayer:
    for player in _sfx_players:
        if not player.playing:
            player.set_meta("reserved", false)
            return player
    # Every player busy: take the first one not reserved by play_now (Change 86).
    for player in _sfx_players:
        if not bool(player.get_meta("reserved", false)):
            return player
    return _sfx_players[0]


## Non-looping imports restart; the shipped track is imported with a forward loop.
func _on_music_finished() -> void:
    if _music_wanted and _music_stream != null:
        _music_player.play()


func _on_settings_changed() -> void:
    _apply_music_volume()
    _sync_music()
    for player in _sfx_players:
        if not player.playing:
            continue
        if not category_audible(String(player.get_meta("category", "gameplay"))):
            player.stop()
        else:
            player.volume_db = _volume_to_db(SettingsState.sfx_volume) + float(player.get_meta("mix_db", 0.0))


func _apply_music_volume() -> void:
    _music_player.volume_db = _volume_to_db(SettingsState.music_volume * _base_level) + _music_mix_db if SettingsState.music_volume > 0.0 and _base_level > 0.0 else SILENT_DB


func _volume_to_db(value: float) -> float:
    return linear_to_db(value) if value > 0.0 else SILENT_DB


func stop_all_sfx() -> void:
    _pending.clear()
    for player in _sfx_players:
        player.stop()
        player.stream = null


func _exit_tree() -> void:
    for player in _sfx_players:
        if is_instance_valid(player):
            player.stop()
            player.stream = null
    if is_instance_valid(_music_player):
        _music_player.stop()
        _music_player.stream = null
    for player in _boss_players:
        if is_instance_valid(player):
            player.stop()
            player.stream = null
    _cues.clear()
    _music_stream = null
