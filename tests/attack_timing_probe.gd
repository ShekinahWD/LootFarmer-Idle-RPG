extends Node
var checks:=0
var failures:=0
var hits:=0
func check(ok: bool,label_: String) -> void:
    checks+=1
    if not ok:
        failures+=1
        push_error(label_)
func _ready() -> void:
    call_deferred("run")
func run() -> void:
    var sim:=LootSimulation.new()
    add_child(sim)
    sim.set_physics_process(false)
    sim.feedback.connect(func(_id: String,_amount: float,_healing: bool)->void:hits+=1)
    var view=load("res://scenes/game/actor.tscn").instantiate()
    add_child(view)
    view.set_process(false)
    view.attack_texture=load("res://assets/PixelPlainsAnimationPack/Wood set/Sword 1 64x32.png")
    for enemy_attack in [false,true]:
        for interval in [1.0,0.5,1.0/3.0,1.6,1.8,2.0]:
            sim.new_profile()
            var a: Dictionary=sim.state.enemies[0] if enemy_attack else sim.state.player
            var target: Dictionary=sim.state.player if enemy_attack else sim.state.enemies[0]
            a.hp=10000
            target.hp=10000
            target.x=a.x+10
            target.y=a.y
            hits=0
            sim._start_attack(a,target,interval)
            view.actor=a
            var slash_entries:=0
            var last_frame:=-1
            var no_second_swing:=true
            var aligned:=true
            for i in range(ceili(interval/.001)+2):
                var previous_hits:=hits
                sim._actor_timers(a,.001)
                sim._resolve_attack(a,.001)
                view._process(0)
                var slash=view.get_node("Visual/Attack")
                var frame:=int(slash.region_rect.position.x/64)
                if slash.visible:
                    no_second_swing=no_second_swing and frame<=4
                    if frame==2 and last_frame!=2:slash_entries+=1
                if hits>previous_hits:aligned=aligned and slash.visible and frame==2
                last_frame=frame
            check(hits==1,"Exactly one damage event per attack")
            check(slash_entries==1 and no_second_swing,"Exactly one visual swing")
            check(aligned,"Damage aligns with contact frame")
            check(a.attack_duration<=interval and not view.get_node("Visual/Attack").visible,"Recovery ends before next cooldown")
    var coin: AtlasTexture=load("res://resources/game/coin.tres")
    var gem: AtlasTexture=load("res://resources/game/gem.tres")
    check(coin.region.size==Vector2(16,16) and gem.region.size==Vector2(14,12),"Currency atlas crops remove transparent padding")
    print("ATTACK_TIMING_PROBE checks=%d failures=%d" % [checks,failures])
    get_tree().quit(1 if failures else 0)
