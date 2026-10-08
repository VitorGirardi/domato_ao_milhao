extends SceneTree
var game:Node3D
func _initialize() -> void:call_deferred("run")
func capture(label:String) -> void:
	if DisplayServer.get_name()=="headless":return
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/vehicle-"+label+".png")
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	game=load("res://scenes/main.tscn").instantiate();game.save_path="user://vehicle_entry.json";root.add_child(game)
	await process_frame;game.set_process(false);game.set_physics_process(false)
	game.qa_mode=true;game.session_started=true;game.build_mode=false;game.hud.close_modal();game.hud.visible=false
	game.state=FarmState.new_farm("sandbox");game.world.day_night.update_cycle(80,Vector3.ZERO)
	var truck:FarmPickup=game.pickup;truck.set_physics_process(false)
	for character in FarmCharacters.IDS:
		FarmCharacters.apply_to_game(game,character);truck.restore({"x":30,"z":25,"angle":0})
		game.player.position=truck.door_stand();game.actor.airborne=false;game.actor.swimming=false
		game.camera.position=truck.to_global(Vector3(-7,4,5));game.camera.look_at(truck.position+Vector3.UP*1.7)
		await physics_frame
		assert(truck.enter() and truck.transitioning() and truck.mounted)
		truck.drive(.05,1,1,false,false)
		assert(truck.transition.elapsed==0,"Pause freezes entry and throttle")
		var parked:=truck.position
		for i in range(61):
			truck.drive(.05,1,1,false,true)
			assert(truck.position==parked and truck.speed==0)
			if i in [16,31,59]:await capture(character+"-entry-"+str(i))
		assert(not truck.transitioning() and truck.mounted and is_zero_approx(truck.driver_door.rotation.y))
		for side in ["L","R"]:
			var target:=truck.model.to_global(Vector3(-.53+(-.22 if side=="L" else .22),2.3,.5))
			print("GRIP ",character," ",side," ",game.actor.rein_grip_world(side).distance_to(target));assert(game.actor.rein_grip_world(side).distance_to(target)<.12,"Driver palm must reach wheel")
		assert(truck.exit_vehicle() and truck.transitioning())
		for i in range(61):
			truck.drive(.05,0,0,true,true)
			if i==31:await capture(character+"-exit")
		assert(not truck.mounted and game.avatar.position.is_equal_approx(Vector3.ZERO))
		assert(game.player.position.distance_to(truck.door_stand())<.01)
		assert(truck.enter());truck.drive(.05,0,0,true,true);truck.reset_driver()
		assert(not truck.transitioning() and not truck.mounted and is_zero_approx(truck.driver_door.rotation.y))
		game.player.position=truck.door_stand();assert(truck.enter())
		game.session_started=false;truck._physics_process(0);game.session_started=true
		assert(not truck.mounted and not truck.transitioning(),"Session end cancels entry")
	# A wall in the leaf sweep blocks entry before any state or pose is changed.
	var wall:=StaticBody3D.new();var shape:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(.2,2,.3)
	shape.shape=box;wall.add_child(shape);game.add_child(wall);wall.position=truck.to_global(Vector3(-1.9,1.8,.5))
	game.player.position=truck.door_stand();await physics_frame
	assert(not truck.enter() and not truck.mounted)
	wall.free();game.player.position=truck.to_global(Vector3(2.5,.12,0));await physics_frame
	assert(not truck.enter(),"Cannot cross the body from passenger side")
	game.session_started=false;game.audio.stop_all();await create_timer(.2).timeout;game.queue_free();await process_frame
	print("VEHICLE_ENTRY_OK: both rigs, door sweep, throttle gate, grip, exit and reset")
	quit()
