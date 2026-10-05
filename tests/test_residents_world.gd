extends SceneTree
var game:Node3D
func _initialize() -> void:call_deferred("run")
func capture(key:String) -> void:
	if DisplayServer.get_name()=="headless":return
	game.hud.toast_time=0;game.hud.toast_panel.visible=false
	await create_timer(.15).timeout;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/residents-"+key+".png")
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	game=load("res://scenes/main.tscn").instantiate();game.save_path="user://residents.json";root.add_child(game);await process_frame
	game.qa_mode=true;game.set_process(false);game.set_physics_process(false);game.residents_world.set_process(false)
	game.session_started=true;game.hud.close_modal();game.build_mode=false
	game.state=FarmState.new_farm("survival");game.state.claim(Vector2(4,-2));game.world.rebuild(game.state)
	game.pickup.set_physics_process(false);await physics_frame;await physics_frame
	var residents:FarmResidentsWorld=game.residents_world;assert(residents.people.size()==3)
	for key in residents.people:
		residents.actors[key].animate(1,false,false)
		assert(absf(residents.actors[key].root.global_position.y-residents.ground(FarmResidents.entry(key)).y)<.1)
	assert(not game.navigator.destinations().any(func(entry):return entry.key.begins_with("resident_")))
	for key in FarmResidents.PEOPLE:
		game.hud.close_modal()
		var park:=FarmResidents.parking(key);var direction:=Vector2(0,-1 if key!="lia" else 1)
		var start:=park-direction*14
		game.pickup.restore({"x":start.x,"z":start.y,"angle":PI if key!="lia" else 0.0})
		game.player.position=game.pickup.position+Vector3(2.5,.1,0);game.actor.airborne=false;game.actor.swimming=false
		assert(game.pickup.enter())
		for i in range(180):
			var distance:=Vector2(game.pickup.position.x,game.pickup.position.z).distance_to(park)
			game.pickup.drive(1.0/60,1 if distance>3 else 0,0,distance<=3,true)
		assert(game.pickup.position.distance_to(residents.ground(park))<5,"Blocked driveway: "+key+str(game.pickup.position))
		game.pickup.speed=0;assert(game.pickup.exit_vehicle())
		game.player.position=residents.ground(FarmResidents.entry(key))+Vector3(1,0,0);game.actor.airborne=false
		game.actor.animate(1,false,false)
		residents.discover();assert(game.state.residents[key].known)
		assert(game.navigator.destinations().any(func(entry):return entry.key=="resident_"+key))
		var context:=residents.nearby();assert(context.value==key)
		game._interact_nearest();assert(game.hud.modal_kind=="resident_"+key and game.state.residents[key].met)
		game.camera.position=residents.ground(park)+Vector3(14,8,13 if key!="lia" else -13);game.camera.look_at(residents.ground(FarmResidents.PEOPLE[key].at)+Vector3.UP*2)
		game.hud.visible=false;await capture(key+"-house");game.hud.visible=true
		if key!="rosa":continue
		game._action("resident:accept:rosa");assert(game.state.residents.rosa.active)
		game.state.pickup.cargo={"carrot":8};game.pickup.refresh_cargo();var before:Dictionary=game.state.serialize()
		game.pickup.position.x+=50;assert(not residents.transact("rosa","deliver").is_empty() and game.state.serialize()==before)
		game.pickup.position=residents.ground(park)+Vector3.UP*.06
		game.pickup.speed=3;assert(not residents.transact("rosa","deliver").is_empty());game.pickup.speed=0
		game.network.active=true;assert(not residents.transact("rosa","deliver").is_empty() and game.state.serialize()==before);game.network.active=false
		var saved_path:String=game.save_path;game.save_path="user://missing/fail.json"
		assert(not residents.transact("rosa","deliver").is_empty() and game.state.serialize()==before);game.save_path=saved_path
		FarmResidentsHUD.visit(game,"rosa");await capture("request")
		game._action("resident:deliver:rosa");assert(game.state.residents.rosa.done==1 and FarmResidents.influence(game.state)==5)
		before=game.state.serialize();game._action("resident:deliver:rosa");assert(game.state.serialize()==before)
		assert(game._load_game() and game.state.residents.rosa.done==1)
		game.hud.close_modal();game.build_mode=false
	game._action("residents");await capture("board")
	game._action("resident:mark:lia");assert(game.hud.modal_kind.is_empty() and game.navigator.target_key=="resident_lia")
	game.navigator.refresh();assert(game.navigator.target_key=="resident_lia")
	game._action("map");await capture("map")
	game.hud.close_modal();game.player.position=Vector3(0,0,0);var before:Dictionary=game.state.serialize();game._action("resident:accept:lia");assert(game.state.serialize()==before)
	game.session_started=false;game.audio.stop_all();await create_timer(.2).timeout;game.queue_free();await process_frame
	print("RESIDENTS_WORLD_OK: driveways, discovery, real conversations, stationary cargo delivery, remote and coop rejection, disk rollback, save reload, board and map")
	quit()
