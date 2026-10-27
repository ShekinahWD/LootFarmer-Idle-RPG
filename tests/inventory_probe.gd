extends Node
## Dock inventory interaction and layout (kept, repaired in Change 11): a supply tap uses one charge,
## the cooldown shows on the slot, a hold opens details, a scroll does neither, and square slots fit
## portrait screens with a full equipment and supply row.
var checks:=0
var failures:=0
func check(ok: bool,label_: String) -> void:
    checks+=1
    if not ok:
        failures+=1
        push_error(label_)
func touch(slot,pressed: bool,point:=Vector2(40,40)) -> void:
    var event:=InputEventScreenTouch.new()
    event.index=0
    event.pressed=pressed
    event.position=point
    slot._gui_input(event)
func _ready() -> void:
    call_deferred("run")
func run() -> void:
    var game=load("res://scenes/game/main.tscn").instantiate()
    add_child(game)
    game.sim.set_physics_process(false)
    game.sim.new_profile()
    game.sim.state.tutorial.mode="none";game.sim.suspended=false # fixture: onboarding chooser answered
    game.sim.add_item("potion",5)
    game.sim.state.player.hp=30
    game._refresh_slots()
    for i in range(10):await get_tree().process_frame
    var slot=game.dock.get_node("Inventory/SupplyColumn/SupplyScroll/Supplies").get_child(0)
    touch(slot,true)
    touch(slot,false)
    check(game.sim.quantity("potion")==4 and not game.sheet.visible,"Tap consumes once without opening details")
    touch(slot,true)
    touch(slot,false)
    check(game.sim.quantity("potion")==4,"Cooldown prevents a second use")
    game._update_supply_cooldowns()
    check(slot.get_node("Cooldown").text!="","Cooldown is visible on slot")
    touch(slot,true)
    slot._process(.51)
    touch(slot,false)
    check(game.sheet.visible and game.selected=="potion" and game.sim.quantity("potion")==4,"Hold opens details without consuming")
    game._close()
    game.sim.state.use_cd=0
    touch(slot,true)
    slot._move(Vector2(40,80))
    touch(slot,false,Vector2(40,80))
    check(game.sim.quantity("potion")==4 and not game.sheet.visible,"Scrolling gesture neither consumes nor opens details")
    for i in range(9):game.sim.state.gear.append("")
    for i in range(4):game.sim.state.supplies.append("") # fixture: all five supply slots (Change 11)
    game._refresh_slots()
    for viewport_size in [Vector2i(720,1280),Vector2i(600,1100),Vector2i(720,1600)]:
        get_tree().root.size=viewport_size
        for i in range(4):await get_tree().process_frame
        game._layout_inventory()
        for i in range(4):await get_tree().process_frame
        var inv=game.dock.get_node("Inventory")
        for path in ["GearColumn/GearScroll/Gear","SupplyColumn/SupplyScroll/Supplies"]:
            var grid=inv.get_node(path)
            var scroll=grid.get_parent()
            check(grid.size.x<=scroll.size.x,"Grid fits scroll width")
            for cell in grid.get_children():
                check(is_equal_approx(cell.size.x,cell.size.y) and cell.size.x>=88,"Square readable slot")
                check(cell.get_node("Icon").get_rect().end.y<cell.get_node("Count").position.y,"Icon and quantity do not overlap")
        check(inv.get_node("Divider").size.y>200,"Visible divider spans expanded inventory")
        check(game.get_node("Safe/Layout/Dock").get_global_rect().end.y<=game.size.y+1,"Full inventory fits portrait screen")
    print("INVENTORY_PROBE checks=%d failures=%d" % [checks,failures])
    get_tree().quit(1 if failures else 0)
