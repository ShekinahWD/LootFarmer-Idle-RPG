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
var _sfx_players: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer
## Most recent first: cue ids that actually played (for probes; never read by gameplay).
var played_log: Array[String] = []


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


func _process(_delta: float) -> void:
    if not _pending.is_empty():
        flush()


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
        if best == "" or int(cue.priority) > int(_cues[best].priority):
            best = id
    _pending.clear()
    if best == "":
        return ""
    _last_played_ms[best] = now
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


## Forgets cooldowns, pending requests and the log (probes).
func reset_history() -> void:
    _pending.clear()
    _last_played_ms.clear()
    played_log.clear()


func play_music() -> void:
    _music_wanted = true
    # Headless runs (probes) keep the routing state but never decode or hold the track.
    if _music_stream == null or DisplayServer.get_name() == "headless":
        return
    if _music_player.stream != _music_stream:
        _music_player.stream = _music_stream
    _apply_music_volume()
    if not _music_player.playing:
        _music_player.play()
    _music_player.stream_paused = SettingsState.music_volume <= 0.0


func stop_music() -> void:
    _music_wanted = false
    _music_player.stop()


func music_playing() -> bool:
    return _music_player.playing and not _music_player.stream_paused


## The configured track, whether the game asked for music, and the player's current level (probes).
func music_state() -> Dictionary:
    return {"stream": _music_stream, "wanted": _music_wanted, "volume_db": _music_player.volume_db}


func _next_free_sfx_player() -> AudioStreamPlayer:
    for player in _sfx_players:
        if not player.playing:
            return player
    return _sfx_players[0]


## Non-looping imports restart; the shipped track is imported with a forward loop.
func _on_music_finished() -> void:
    if _music_wanted and _music_stream != null:
        _music_player.play()


func _on_settings_changed() -> void:
    _apply_music_volume()
    if _music_wanted and _music_player.playing:
        _music_player.stream_paused = SettingsState.music_volume <= 0.0
    for player in _sfx_players:
        if not player.playing:
            continue
        if not category_audible(String(player.get_meta("category", "gameplay"))):
            player.stop()
        else:
            player.volume_db = _volume_to_db(SettingsState.sfx_volume) + float(player.get_meta("mix_db", 0.0))


func _apply_music_volume() -> void:
    _music_player.volume_db = _volume_to_db(SettingsState.music_volume) + _music_mix_db if SettingsState.music_volume > 0.0 else SILENT_DB


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
    _cues.clear()
    _music_stream = null
