extends Node
## Change 83: the Green Alien's sound, derived from the simulation every frame (no state of its own to get stuck).
##
## Music (AudioService.set_boss_music): "EndGame - Music 1 (1)" while the unlocked Green Alien is really engaged
## (campaign.engaged_final(): never during the warning, the ceremony or a cancelled approach), crossfading to
## "EndGame - Music 1 (2)" when it enrages. The moment the encounter ends (victory, the player's death, a reset,
## a map change) the boss track is released quickly and the main music returns from where it held; the
## celebration floor always plays over the main music.
##
## Laughter: while the encounter runs (not enraging this second, not celebrating), one of Laugh 01/03/05 at random
## every LAUGH_MIN..LAUGH_MAX seconds of unpaused play (the first one LAUGH_FIRST in); the audio service's cue
## cooldowns keep them from overlapping. A local RNG: the simulation's own RNG stream is never consumed.
##
## Recommended mix (SettingsState, only after an explicit tap, never saved): kept while the player is at the
## Green Alien (asking, ceremony, fight, arena, within NEAR_RADIUS of the living boss) and through the first
## victory's 10 s celebration; restored when the fight ends otherwise (a later victory, the player's death, "No"
## on the warning) and whenever the player is no longer there.
const NORMAL_TRACK:=preload("res://assets/sounds/EndGame - Music 1 (1).ogg")
const RAGE_TRACK:=preload("res://assets/sounds/EndGame - Music 1 (2).ogg")
## Mix against the main track (background_music.wav plays at -8 dB with a much lower mean level).
const NORMAL_MIX_DB:=-13.0
const RAGE_MIX_DB:=-12.5
const SWITCH_FADE:=1.2
const RELEASE_FADE:=.5
const LAUGHS:=["final_laugh_1","final_laugh_3","final_laugh_5"]
const LAUGH_FIRST:=Vector2(8.0,14.0)
const LAUGH_MIN:=18.0
const LAUGH_MAX:=32.0
## No laugh within this many seconds after the enrage cue.
const RAGE_QUIET:=6.0
const NEAR_RADIUS:=300.0

var sim
var laugh_clock:=-1.0
var rage_quiet:=0.0
var rng:=RandomNumberGenerator.new()
## Probes: laugh cues requested, most recent last.
var laughs_requested: Array=[]

func _ready() -> void:
    process_mode=Node.PROCESS_MODE_PAUSABLE
    rng.randomize()

func setup(value) -> void:
    sim=value
    sim.final_rage.connect(func(_id: String)->void:
        rage_quiet=RAGE_QUIET
        AudioService.play("final_enraged"))
    sim.final_victory.connect(_victory)
    sim.final_warning.connect(func(phase: String)->void:
        if phase=="declined":SettingsState.restore_recommended())
    sim.arena_changed.connect(func(active: bool,reason: String)->void:
        if not active and reason=="death":SettingsState.restore_recommended())

func _victory(kind: String) -> void:
    # The boss music stops at once (the encounter ended in this step); the main music returns.
    AudioService.set_boss_music(null,0.0,RELEASE_FADE)
    match kind:
        "first":pass # the accepted mix stays for the 10 s celebration
        "celebrated","repeat","deferred":SettingsState.restore_recommended()

## The music the encounter wants now (null: the main music).
func wanted_track() -> AudioStream:
    if sim==null or sim.state.is_empty() or sim.campaign.celebration_active():return null
    var boss: Dictionary=sim.campaign.engaged_final()
    if boss.is_empty():return null
    return RAGE_TRACK if sim.campaign.enraged(boss) else NORMAL_TRACK

## The player is at the Green Alien (where an accepted recommended mix stays).
func at_final_boss() -> bool:
    if sim==null or sim.state.is_empty():return false
    var c=sim.campaign
    if c.warning_pending!="" or c.ceremony_active() or c.arena_active() or c.celebration_active() or not c.engaged_final().is_empty():return true
    return near_living_boss()

## The living Green Alien (discovered) is on this map within NEAR_RADIUS of the player.
func near_living_boss() -> bool:
    if sim==null or sim.state.is_empty() or not bool(sim.state.final_discovered):return false
    for e in sim.state.enemies:
        if bool(sim.catalog.groups[int(e.group)].final) and not sim.is_helper(e) and float(e.hp)>0:
            return sim.position_of(e).distance_to(sim.position_of(sim.state.player))<=NEAR_RADIUS
    return false

func _process(delta: float) -> void:
    if sim==null or sim.state.is_empty():return
    var want:=wanted_track()
    if want!=AudioService.boss_music():
        AudioService.set_boss_music(want,RAGE_MIX_DB if want==RAGE_TRACK else NORMAL_MIX_DB,SWITCH_FADE if want!=null else RELEASE_FADE)
    if SettingsState.recommended_active() and not at_final_boss():SettingsState.restore_recommended()
    if sim.held or sim.suspended:return
    rage_quiet=maxf(0.0,rage_quiet-delta)
    if want==null:
        laugh_clock=-1.0
        return
    if laugh_clock<0:laugh_clock=rng.randf_range(LAUGH_FIRST.x,LAUGH_FIRST.y)
    laugh_clock-=delta
    if laugh_clock<=0 and rage_quiet<=0:
        var cue: String=LAUGHS[rng.randi_range(0,LAUGHS.size()-1)]
        laughs_requested.append(cue)
        AudioService.play(cue)
        laugh_clock=rng.randf_range(LAUGH_MIN,LAUGH_MAX)
