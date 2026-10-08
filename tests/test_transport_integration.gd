extends SceneTree
var game:Node3D
func _initialize() -> void:call_deferred("run")

func complete() -> void:
	for i in range(65):
		if not game.pickup.transitioning():break
		game._physics_process(.05)
	assert(not game.pickup.transitioning())
	game._process(0)

func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	game=load("res://scenes/main.tscn").instantiate();game.save_path="user://transport_integration.json"
	root.add_child(game);await process_frame
	game.qa_mode=true;game.set_process(false);game.set_physics_process(false)
	game.pickup.set_physics_process(false)
	game.state=FarmState.new_farm("sandbox");assert(game.state.claim(Vector2(4,0)).is_empty())
	game.session_started=true;game.build_mode=false;game.hud.close_modal()
	game.pickup.restore({"x":30,"z":25,"angle":0})
	game.player.position=game.pickup.door_stand();game.actor.airborne=false
	await physics_frame
	game._interact_nearest()
	assert(game.pickup.transitioning() and game._nearby_context().action=="wait")
	game._action("mode");assert(not game.build_mode)
	game._action("menu")
	var elapsed:float=game.pickup.transition.elapsed
	game._physics_process(.05)
	assert(game.pickup.transition.elapsed==elapsed)
	game.hud.close_modal();complete()
	assert(game.pickup.mounted)
	game._action("front:title")
	assert(game.pending_vehicle_action=="front:title" and game.pickup.transitioning() and game.session_started)
	complete()
	assert(not game.pickup.mounted and game.pending_vehicle_action.is_empty() and not game.session_started)
	# A newly occupied door cancels a deferred menu instead of opening it later.
	game.session_started=true;game.hud.close_modal();game.actor.airborne=false
	game._interact_nearest();complete();assert(game.pickup.mounted)
	game._action("net:menu");assert(game.pending_vehicle_action=="net:menu")
	var blocker:=StaticBody3D.new();var shape:=CollisionShape3D.new();var box:=BoxShape3D.new()
	box.size=Vector3(.8,2,.8);shape.shape=box;blocker.add_child(shape);game.add_child(blocker)
	blocker.position=game.pickup.door_stand()+Vector3.UP;await physics_frame
	complete()
	assert(game.pickup.mounted and game.pending_vehicle_action.is_empty() and game.hud.modal_kind.is_empty())
	blocker.free();game.pickup.reset_driver()
	game.session_started=false;game.audio.stop_all();await create_timer(.2).timeout
	game.queue_free();await process_frame;await create_timer(.2).timeout
	print("TRANSPORT_INTEGRATION_OK: real interaction, input gate, menu pause, deferred title and blocked-exit cancellation")
	quit()
