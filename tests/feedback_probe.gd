extends Node
var checks:=0
var failures:=0
func check(ok: bool,description: String) -> void:
    checks+=1
    if not ok:
        failures+=1
        push_error(description)
func _ready() -> void:
    call_deferred("run")
func run() -> void:
    var game=load("res://scenes/game/main.tscn").instantiate()
    add_child(game)
    game.sim.set_physics_process(false)
    game.sim.new_profile()
    await get_tree().process_frame
    game.sim.history("HISTORY_ITEM","wood_sword",2,0)
    game.sim.history("HISTORY_CURRENCY","",3,0)
    game._refresh_loot_notifications()
    var history=game.get_node("Safe/Layout/Map/History")
    check(history.get_child_count()==2,"Item and gem notifications are shown")
    check(history.get_child(0).text=="+3.00" and history.get_child(0).icon!=null,"Gem icon and quantity")
    check(history.get_child(1).icon!=null,"Item uses item icon")
    check(history.get_child(0).get_theme_stylebox("normal") is StyleBoxEmpty,"Transparent notification background")
    game.sim.state.clock+=30
    game._process(5)
    check(history.visible and history.get_child_count()==2,"Loot remains visible after 30 seconds")
    check(not game.get_node("Safe/Layout/Map/GemPickup").visible,"Separate pickup pulse ends after four seconds")
    game.sim.history("HISTORY_CURRENCY","",2,0)
    check(game.get_node("Safe/Layout/Map/GemPickup/Amount").text=="+2.00","New pickup pulse starts with new amount")
    game.sim.history("HISTORY_CURRENCY","",1,0)
    check(game.get_node("Safe/Layout/Map/GemPickup/Amount").text=="+3.00","Rapid gem pickups accumulate")
    game.sim.history("HISTORY_SOLD","wood_sword",1,10)
    game._refresh_loot_notifications()
    check(history.get_child_count()==3,"Sales do not appear as coin notifications")
    history.get_child(0).pressed.emit()
    check(game.panel=="history","Persistent loot opens full history")
    var actor=load("res://scenes/game/actor.tscn").instantiate()
    var holder:=Node2D.new()
    add_child(holder)
    holder.add_child(actor)
    actor.show_hit(5,false)
    actor.show_hit(8,false,true)
    check(holder.get_child_count()==3,"Consecutive hits have independent labels")
    var label=holder.get_child(1)
    actor.queue_free()
    await get_tree().create_timer(.65).timeout
    check(is_instance_valid(label) and label.modulate.a>.9,"Damage remains readable after original half-second and actor deletion")
    await get_tree().create_timer(1.25).timeout
    check(not is_instance_valid(label),"Damage label cleans up after longer fade")
    print("FEEDBACK_PROBE checks=%d failures=%d" % [checks,failures])
    get_tree().quit(1 if failures else 0)
