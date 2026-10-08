extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	var game:Node3D=load("res://scenes/main.tscn").instantiate();game.save_path="user://collision.json";root.add_child(game)
	await process_frame;game.set_process(false);game.set_physics_process(false)
	game.qa_mode=true;game.session_started=true;game.build_mode=false;game.hud.close_modal()
	game.state=FarmState.new_farm("sandbox")
	var truck:FarmPickup=game.pickup;truck.set_physics_process(false)
	for direction in [1.0,-1.0]:
		truck.restore({"x":30,"z":25,"angle":0});game.player.position=truck.door_stand()
		game.actor.airborne=false;game.actor.swimming=false
		await physics_frame;assert(truck.enter())
		while truck.transitioning():truck.drive(.05,0,0,false,true)
		var wall:=StaticBody3D.new();var shape:=CollisionShape3D.new();var box:=BoxShape3D.new()
		box.size=Vector3(8,4,.4);shape.shape=box;wall.add_child(shape);game.add_child(wall)
		wall.position=truck.position+Vector3(0,2,5*direction)
		await physics_frame
		var initial:=truck.motor.impact_count;truck.speed=12 if direction>0 else -6
		for frame in range(100):
			await physics_frame
			truck.motor.update(1.0/60,truck.speed,direction,false,true)
			truck.drive(1.0/60,direction,0,false,true)
		assert(truck.motor.impact_count==initial+1,"A real frontal/reverse collision sounds once; pushing stays quiet")
		assert(absf(truck.speed)<1 and not truck.blocked_reason.is_empty())
		truck.reset_driver();assert(not truck.motor.impact_voice.playing)
		wall.free();await physics_frame
	game.session_started=false;game.audio.stop_all();game.queue_free();await process_frame
	print("PICKUP_COLLISION_OK: forward/reverse real wall contacts, no repeated pushing, reset stops sound");quit()
