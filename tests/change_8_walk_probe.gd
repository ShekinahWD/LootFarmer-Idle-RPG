extends Node
## Change 8 map-movement smoke: on every stage, the simulation's own movement (with solid-scenery
## sliding) walks from the arrival camp, and from every camp, to every camp, every actor home and every
## boss home. Fails if a walk stalls (no arrival within a generous time) or a home lies inside a solid.
var sim
var failures:=0
var checks:=0
func _ready() -> void:call_deferred("run")
func run() -> void:
    sim=load("res://scripts/game/simulation.gd").new();add_child(sim);sim.set_physics_process(false)
    for stage in sim.catalog.stages:
        sim.state.stage=int(stage.id);sim.state.unlocked_stage=8;sim.campaign.configure_stage()
        var targets: Array=[]
        for camp in stage.spawns:targets.append(Vector2(camp[0],camp[1]))
        for g in stage.groups:
            for v in sim.campaign.variants(g):
                for i in range(1 if sim.catalog.groups[g].boss else 6):targets.append(sim.spawn_home(g,v,i))
        var stalls:=0;var inside:=0;var worst:=0.0
        for t in targets:
            if sim.campaign.solid_at(t):inside+=1
        for s in stage.spawns:
            var start:=Vector2(s[0],s[1])
            for t in targets:
                var a: Dictionary=sim._actor("walker",start.x,start.y,1,0)
                var limit:=int(start.distance_to(t)/(90*.1)*2.5)+40
                var n:=0
                while n<limit and sim.position_of(a).distance_to(t)>2:
                    var before: Vector2=sim.position_of(a)
                    sim._move(a,t,90,.1)
                    n+=1
                checks+=1
                if sim.position_of(a).distance_to(t)>2:
                    stalls+=1
                    var p: Vector2=sim.position_of(a)
                    var near:=[]
                    for o in sim.campaign.obstacle_list:
                        var q: Vector2=o.c if o.has("c") else Vector2(clampf(p.x,o.rect.position.x,o.rect.end.x),clampf(p.y,o.rect.position.y,o.rect.end.y))
                        if q.distance_to(p)<40:near.append(("circle r=%d at %s" % [o.r,o.c]) if o.has("c") else ("rect %s" % o.rect))
                    var trail: Array=[]
                    for k in range(4):
                        var before2: Vector2=sim.position_of(a);sim._move(a,t,90,.1);trail.append(sim.position_of(a))
                    if OS.get_cmdline_user_args().has("--verbose"):print("  STALL from ",start," to ",t," at ",p," near ",near," trail ",trail)
                worst=maxf(worst,float(n)/maxf(1,start.distance_to(t)/9.0))
        print("WALK stage=",stage.id," solids=",sim.campaign.obstacle_list.size()," targets=",targets.size()," stalls=",stalls," homes_inside=",inside," worst_detour=",snappedf(worst,.01))
        failures+=stalls+inside
    print("CHANGE_8_WALK checks=",checks," failures=",failures)
    get_tree().quit(1 if failures else 0)
