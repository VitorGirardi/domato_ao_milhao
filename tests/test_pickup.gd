extends SceneTree
var game:Node3D
func _initialize() -> void:call_deferred("run")
func capture(label:String) -> void:
	if DisplayServer.get_name()=="headless":return
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/pickup-"+label+".png")
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	var state:=FarmState.new();var data:=state.serialize();data.erase("pickup")
	assert(state.restore(data) and state.pickup==FarmPickup.defaults())
	for bad in [null,{}, {"x":0,"z":0,"angle":NAN},{"x":"0","z":0,"angle":0},{"x":2000,"z":0,"angle":0}]:
		var before:=state.serialize();data=before.duplicate(true);data.pickup=bad
		assert(not state.restore(data) and state.serialize()==before)
	game=load("res://scenes/main.tscn").instantiate();game.save_path="user://qa_pickup.json";root.add_child(game)
	await process_frame;game.set_process(false);game.set_physics_process(false)
	game.qa_mode=true;game.session_started=true;game.build_mode=false;game.hud.close_modal()
	game.state=FarmState.new_farm("survival","farmer");assert(game.state.claim(Vector2(4,-2)).is_empty())
	var truck:FarmPickup=game.pickup
	truck.set_physics_process(false);truck.restore(FarmPickup.defaults())
	game.player.position=truck.position+Vector3(-2.5,.15,0);game.actor.airborne=false
	await physics_frame
	for key in truck.wheels:assert(is_instance_valid(truck.wheels[key]))
	game.camera.position=truck.to_global(Vector3(-8,5,9));game.camera.look_at(truck.position+Vector3.UP*1.5)
	game.avatar.visible=false;game.hud.visible=false;await capture("model");game.avatar.visible=true
	assert(truck.enter() and truck.mounted)
	await capture("cab")
	assert(not game.weapons.active() and not game._try_jump() and not game.companions.allowed())
	# Exercise the real input/physics integration, including pause and engine audio.
	game.set_physics_process(true);truck.set_physics_process(true)
	Input.action_press("forward")
	for i in range(30):await physics_frame
	Input.action_release("forward")
	assert(truck.speed>0)
	game.hud.menu(game.state)
	for i in range(3):await physics_frame
	assert(truck.speed==0 and not truck.engine_sound.playing)
	game.hud.close_modal();game.set_physics_process(false);truck.set_physics_process(false)
	game._action("mode");assert(not game.build_mode)
	var start:=truck.position
	for i in range(120):
		truck.drive(1.0/60,1,0,false,true);await physics_frame
	assert(truck.position.distance_to(start)>8,"Pickup must drive along the road")
	assert(truck.speed>8 and truck.speed<=FarmPickup.MAX_SPEED)
	assert(not truck.exit_vehicle(),"Cannot eject a driver at speed")
	game.hud.visible=true;game._update_ui();game._update_camera(1,true);game.hud.toast_time=0;game.hud.toast_panel.visible=false
	await capture("driving")
	var angle:=truck.rotation.y
	for i in range(30):truck.drive(1.0/60,1,1,false,true);await physics_frame
	assert(absf(angle_difference(angle,truck.rotation.y))>.03,"Steering must turn the vehicle")
	for i in range(90):truck.drive(1.0/60,0,0,true,true);await physics_frame
	assert(is_zero_approx(truck.speed));assert(truck.exit_vehicle())
	assert(not truck.mounted and game.avatar.position.is_equal_approx(Vector3.ZERO))
	assert(game.player.position.distance_to(truck.position)>2)
	truck.store();assert(game._save_game(false,true))
	var saved:Dictionary=game.state.pickup.duplicate();game.state=FarmState.new();assert(game._load_game())
	assert(game.state.game_mode=="survival" and not game.state.unlimited_money,"Loading must preserve the farm mode")
	# JSON numbers can differ in their last bit between platform parsers.
	for key in ["x","z","angle"]:
		assert(absf(game.state.pickup[key]-saved[key])<.000001,"Saved pickup %s changed: %.16f -> %.16f"%[key,saved[key],game.state.pickup[key]])
	assert(Vector2(truck.position.x,truck.position.z).distance_to(Vector2(saved.x,saved.z))<.01)
	# A wall stops the body at speed; no teleport through thin obstacles.
	truck.restore({"x":30.0,"z":25.0,"angle":0.0})
	var wall:=StaticBody3D.new();var shape:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(12,5,.25)
	shape.shape=box;wall.add_child(shape);game.add_child(wall);wall.position=Vector3(30,2.5,36)
	game.player.position=truck.position+Vector3(-2.5,.15,0);game.actor.airborne=false;await physics_frame
	assert(truck.enter())
	for i in range(180):truck.drive(1.0/60,1,0,false,true);await physics_frame
	assert(truck.position.z<33.1,"Vehicle must stop before a thin wall")
	assert(not truck.surface_allowed(Vector3(285,5,260),0),"Vehicle must reject deep lake water")
	assert(not truck.surface_allowed(Vector3(FarmLandscape.WALK_MAX.x,0,0),0),"Whole body stays inside map")
	assert(not truck.surface_allowed(Vector3(FarmLandscape.WALK_MAX.x-3.5,0,0),0),"Driving respects the saved position bounds")
	var at:=truck.position;truck.drive(.05,1,1,false,false);assert(truck.position==at and truck.speed==0)
	game._reset_farm(FarmState.new_farm("sandbox"));assert(not truck.mounted and game.state.pickup==FarmPickup.defaults())
	# Existing farm buildings must not trap the parked prototype.
	var occupied:=truck.position
	game.state.items.append({"kind":"barn","x":occupied.x,"z":occupied.z,"turn":0})
	truck.ensure_parking();assert(truck.position.distance_to(occupied)>4)
	assert(truck.parking_clear(truck.position))
	# Prototype is hidden and has no collision in cooperative play.
	game.network.active=true;truck._physics_process(0)
	assert(not truck.visible and truck.collision_layer==0 and not truck.nearby())
	game.network.active=false;game.session_started=false;game.audio.stop_all();game.free()
	print("PICKUP_OK: original model, driving, steering, braking, safe exits, collisions, water/bounds, modes and persistence")
	quit()
