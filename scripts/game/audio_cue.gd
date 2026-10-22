class_name AudioCue
extends Resource
## One semantic sound (Change 12). Gameplay code requests the id; the audio service owns the stream,
## category, priority and repeat throttle. Edit the assignments in resources/game/audio_cues.tres.
@export var id: String = ""
@export var stream: AudioStream
## gameplay: repeatable action, UI, combat and pickup sounds. special: milestones and notifications.
## Each category has its own mute in Settings; the sound-effect volume applies to both.
@export_enum("gameplay", "special") var category: String = "gameplay"
## When several cues are requested in the same frame, only the highest priority audible one plays.
@export var priority: int = 0
## Real-time seconds before the same cue may play again.
@export_range(0.0, 10.0, 0.05) var cooldown: float = 0.0
@export_range(-24.0, 6.0, 0.5) var volume_db: float = 0.0
