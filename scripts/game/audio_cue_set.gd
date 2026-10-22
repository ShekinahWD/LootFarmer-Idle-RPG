class_name AudioCueSet
extends Resource
## The game's sound assignments (Change 12): one looping music track and the semantic cues.
@export var music: AudioStream
## Mix level of the music under the Music volume slider (a restrained background loop).
@export_range(-30.0, 0.0, 0.5) var music_volume_db: float = -8.0
@export var cues: Array[AudioCue] = []
