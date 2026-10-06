extends SceneTree
var game:Node3D
func _initialize() -> void:call_deferred("run")
func capture(key:String) -> void:
	if DisplayServer.get_name()=="headless":return
	game.hud.toast_time=0;game.hud.toast_panel.visible=false;await create_timer(.15).timeout;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/rosa-"+key+".png")
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	game=load("res://scenes/main.tscn").instantiate();game.save_path="user://rosa.json";root.add_child(game);await process_frame
	game.qa_mode=true;game.set_process(false);game.set_physics_process(false);game.residents_world.set_process(false)
	game.state=FarmState.new_farm("survival");game.state.claim(Vector2(4,-2));game.world.rebuild(game.state)
	game.session_started=true;game.build_mode=false;game.hud.close_modal();game.pickup.set_physics_process(false)
	var world:FarmResidentsWorld=game.residents_world;world.refresh()
	game.player.position=world.ground(FarmResidents.entry("rosa"));game.actor.airborne=false;game.actor.swimming=false
	game.pickup.position=world.ground(FarmResidents.parking("rosa"));game.pickup.speed=0;game.pickup.store()
	game.camera.position=world.ground(FarmResidents.entry("rosa"))+Vector3(13,10,16);game.camera.look_at(world.homes.rosa.position+Vector3(0,1,2))
	game.hud.visible=false;await capture("abandoned");game.hud.visible=true
	# Follow a full day, then test the stationary delivery point while Rosa is away.
	var visited:Dictionary={}
	for elapsed in [0,100,160,240,440]:
		game.state.elapsed=elapsed
		for frame in range(600):world.animate_rosa(1.0/60)
		var npc:Node3D=world.people.rosa;visited[str(npc.position.round())]=true
		assert(absf(npc.position.y-FarmLandscape.height_at(Vector2(npc.position.x,npc.position.z)))<.01)
		assert(npc.position.z>=world.homes.rosa.position.z+5.3,"Routine crossed house")
	assert(visited.size()>=3)
	world.handle("resident:talk:rosa");assert(game.hud.modal_kind=="resident_rosa")
	world.handle("resident:story:rosa");assert(game.hud.modal_kind=="rosa_story")
	var stopped:Vector3=world.people.rosa.position;world.animate_rosa(1);assert(world.people.rosa.position==stopped)
	for stage in range(3):
		world.handle("resident:story_accept:rosa");assert(game.state.rosa_story.active)
		game.state.pickup.cargo=FarmRosa.step(game.state).cargo.duplicate();game.pickup.refresh_cargo()
		var before:Dictionary=game.state.serialize()
		game.pickup.speed=2;assert(not world.transact("rosa","story_deliver").is_empty() and game.state.serialize()==before);game.pickup.speed=0
		game.network.active=true;assert(not world.transact("rosa","story_deliver").is_empty() and game.state.serialize()==before);game.network.active=false
		var path:String=game.save_path;game.save_path="user://missing/rosa.json";assert(not world.transact("rosa","story_deliver").is_empty() and game.state.serialize()==before);game.save_path=path
		FarmRosaHUD.show(game);await capture("stage-%d"%stage)
		var result:=world.transact("rosa","story_deliver");assert(result.is_empty(),result);FarmRosaHUD.show(game);assert(game.state.rosa_story.stage==stage+1 and world.rosa_stage==stage+1)
		before=game.state.serialize();world.handle("resident:story_deliver:rosa");assert(game.state.serialize()==before)
		assert(game._load_game() and game.state.rosa_story.stage==stage+1)
	await capture("complete");game.hud.close_modal();game.hud.visible=false;await capture("garden");game.hud.visible=true
	assert(game.state.place("rosa_bed",Vector2(8,6),0).is_empty());game.world.rebuild(game.state)
	game.player.position=Vector3.ZERO;var before:Dictionary=game.state.serialize();world.handle("resident:story_accept:rosa");assert(game.state.serialize()==before)
	game.session_started=false;game.audio.set_process(false);game.audio.stop_all();await create_timer(1.6).timeout;game.queue_free();await process_frame;game=null;await create_timer(.2).timeout
	print("ROSA_WORLD_OK: routine, doorway availability, scenes, atomic save rollback, coop gates, story reload and decoration")
	quit()
