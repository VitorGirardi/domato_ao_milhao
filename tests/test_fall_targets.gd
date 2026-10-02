extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	var state:=FarmState.new();state.claimed=true
	state.items=[{"kind":"coop","x":0,"z":0,"turn":0,"flock":FarmAnimals.fresh(),"egg_time":0.0},{"kind":"corral","x":10,"z":0,"turn":0,"dairy":FarmDairy.fresh()},{"kind":"pigsty","x":20,"z":0,"turn":0,"pigs":FarmPigs.fresh()}]
	state.items[1].dairy.owned=true;state.items[2].pigs.count=3
	var cow_key:=FarmFallTargets.item_key(state,1,"cow")
	state.temporary_down[cow_key]=true
	state.temporary_down[FarmFallTargets.item_key(state,0,"chicken",0)]=true
	state.temporary_down[FarmFallTargets.item_key(state,2,"pig",0)]=true
	var saved_cow:Dictionary=state.items[1].dairy.duplicate(true)
	state.tick(30)
	assert(state.items[1].dairy==saved_cow)
	assert(is_equal_approx(state.items[0].egg_time,20.0))
	assert(is_equal_approx(state.items[2].pigs.food,90.0))
	assert(not state.serialize().has("temporary_down"))
	state.temporary_down.clear();state.tick(1)
	assert(state.items[1].dairy!=saved_cow)
	state.items.remove_at(0)
	assert(FarmFallTargets.item_key(state,0,"cow")==cow_key)
	var game:Node3D=load("res://scenes/main.tscn").instantiate();game.save_path="user://fall_targets.json";root.add_child(game)
	await process_frame;game.set_process(false);game.set_physics_process(false)
	var targets:=FarmFallTargets.collect(game)
	assert(targets.has("npc:vendor") and targets.has("npc:armorer"))
	for key in targets:
		assert(is_instance_valid(targets[key].body) and is_instance_valid(targets[key].model))
	game.queue_free();await process_frame
	print("FALL_TARGETS_OK: stable IDs, reversible production suspension, transient save state, registry")
	quit()
