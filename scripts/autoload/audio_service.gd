extends Node
## Sparse semantic-audio service. Register game-specific streams at startup;
## gameplay code then requests semantic event IDs instead of owning players.

const SFX_POOL_SIZE: int = 6
const SILENT_DB: float = -80.0

var _sfx_streams: Dictionary = {}
var _music_streams: Dictionary = {}
var _sfx_players: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer
var _current_music_track: String = ""


func _ready() -> void:
    for i in range(SFX_POOL_SIZE):
        var player := AudioStreamPlayer.new()
        add_child(player)
        _sfx_players.append(player)
    _music_player = AudioStreamPlayer.new()
    add_child(_music_player)
    _music_player.finished.connect(_on_music_finished)
    SettingsState.settings_changed.connect(_on_settings_changed)


func register_sfx(event_id: String, stream: AudioStream) -> void:
    _sfx_streams[event_id] = stream


func register_music(track_id: String, stream: AudioStream) -> void:
    _music_streams[track_id] = stream


func play_sfx(event_id: String) -> void:
    if not SettingsState.sfx_enabled:
        return
    var stream: AudioStream = _sfx_streams.get(event_id)
    if stream == null:
        return
    var player := _next_free_sfx_player()
    player.stream = stream
    player.volume_db = _volume_to_db(SettingsState.sfx_volume)
    player.play()


func play_music(track_id: String) -> void:
    _current_music_track = track_id
    var stream: AudioStream = _music_streams.get(track_id)
    if stream == null:
        _music_player.stop()
        return
    if _music_player.stream != stream:
        _music_player.stream = stream
    _apply_music_volume()
    if SettingsState.music_enabled and not _music_player.playing:
        _music_player.play()


func stop_music() -> void:
    _current_music_track = ""
    _music_player.stop()


func _next_free_sfx_player() -> AudioStreamPlayer:
    for player in _sfx_players:
        if not player.playing:
            return player
    return _sfx_players[0]


func _on_music_finished() -> void:
    if _current_music_track == "" or not SettingsState.music_enabled:
        return
    var stream: AudioStream = _music_streams.get(_current_music_track)
    if stream == null:
        return
    _music_player.stream = stream
    _apply_music_volume()
    _music_player.play()


func _on_settings_changed() -> void:
    _apply_music_volume()
    if not SettingsState.music_enabled:
        _music_player.stop()
    elif _current_music_track != "" and _music_streams.get(_current_music_track) != null and not _music_player.playing:
        _music_player.play()
    for player in _sfx_players:
        if not SettingsState.sfx_enabled:
            player.stop()
        else:
            player.volume_db = _volume_to_db(SettingsState.sfx_volume)


func _apply_music_volume() -> void:
    var enabled := SettingsState.music_enabled and SettingsState.music_volume > 0.0
    _music_player.volume_db = _volume_to_db(SettingsState.music_volume) if enabled else SILENT_DB


func _volume_to_db(value: float) -> float:
    return linear_to_db(value) if value > 0.0 else SILENT_DB
