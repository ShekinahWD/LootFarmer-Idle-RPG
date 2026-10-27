extends Node
## Non-gating CPU investigation; no claim about mobile GPU frame time.
func _ready() -> void:call_deferred("run")
func run() -> void:
    var sim:=LootSimulation.new();add_child(sim);sim.set_physics_process(false)
    for st in range(1,9):
        sim.new_profile();sim.state.tutorial.mode="none";sim.suspended=false
        sim.state.stage=st;sim.state.unlocked_stage=st;sim._reset_world();sim.campaign.reveal()
        var start:=Time.get_ticks_usec()
        for i in range(600):sim.step(.016)
        print("SIM_CPU stage=",st," weather=",sim.campaign.stage().weather," actors=",sim.state.enemies.size()," us_per_step=",float(Time.get_ticks_usec()-start)/600)
    var weather=load("res://scripts/game/season_weather.gd").new();weather.sim=sim
    sim.state.stage=4;weather._process(.1)
    var wet: bool=weather.style!=null
    sim.state.stage=1;weather._process(.1)
    print("WEATHER_TRANSITION rain_to_dry=",wet and weather.style==null)
    weather.free();get_tree().quit()
