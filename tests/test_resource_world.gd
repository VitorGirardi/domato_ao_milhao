extends SceneTree
var game:Node3D
func _initialize() -> void:call_deferred("run")
func capture(label:String,from:Vector3,target:Vector3) -> void:
	game._update_ui()
	game.camera.position=from;game.camera.look_at(target);game.camera.fov=62
	if DisplayServer.get_name()=="headless":return
	await create_timer(.25).timeout;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/resource-"+label+".png")
func gate_hit() -> Dictionary:
	var ray:=PhysicsRayQueryParameters3D.create(Vector3(900,82,-215),Vector3(900,82,-222))
	ray.exclude=[game.player.get_rid()]
	return game.world.get_world_3d().direct_space_state.intersect_ray(ray)
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	game=load("res://scenes/main.tscn").instantiate();game.save_path="user://qa_resource_world.json";root.add_child(game)
	await process_frame;game.qa_mode=true;game.set_process(false);game.set_physics_process(false)
	game.session_started=true;game.build_mode=false;game.hud.close_modal()
	game.state=FarmState.new();game.state.claim(Vector2(4,-2));game.state.money=5000
	game.world.rebuild(game.state);game.player.position=FarmResourceSites.point(FarmResourceSites.MINE_AT)
	game.actor.airborne=false;game.gathering.reset();game.resource_view.refresh_world()
	await physics_frame;await physics_frame
	assert(not gate_hit().is_empty(),"Unowned mine must have a physical gate")
	assert(FarmResources.buy(game.state,"rod").is_empty());assert(FarmResources.buy(game.state,"pickaxe").is_empty())
	assert(game.gathering.apply(1,"resource:buy:mine")=="Compra concluída.")
	await physics_frame;await physics_frame
	assert(gate_hit().is_empty(),"Buying the mine must open its entrance")
	var region:FarmRegionScenery=game.world.landscape.get_node("ValeESerra")
	assert(region.mine_open and not region.mine_barrier.visible)
	for p in FarmResourceSites.FISH_SPOTS:
		assert(not FarmRegion.water_blocked(p),"Fishing markers must be reachable on dry ground")
		var ground:=FarmResourceSites.point(p)
		var query:=PhysicsRayQueryParameters3D.create(ground+Vector3.UP*3,ground-Vector3.UP*3)
		assert(not game.world.get_world_3d().direct_space_state.intersect_ray(query).is_empty())
	# Walk a real capsule through the purchased opening, not merely a raycast.
	RenderingServer.set_render_loop_enabled(false)
	for step in range(110):
		await physics_frame;game.player.velocity=Vector3(0,-1,-4);game.player.move_and_slide()
	RenderingServer.set_render_loop_enabled(true)
	assert(game.player.position.z < -222,"Player cannot enter purchased mine")
	await capture("mina-aberta",Vector3(900,85,-204),Vector3(900,83,-225))
	game.player.position=FarmResourceSites.point(FarmResourceSites.FISH_SPOTS[0]);game.gathering.last_request.clear()
	assert(game.gathering.apply(1,"gather:fish:0").is_empty());await process_frame
	await capture("pesca",game.player.position+Vector3(-6,5,8),game.player.position+Vector3(0,1,-3))
	game.gathering.handle("gather:cancel")
	game.player.position=Vector3(900,81,-224);game.gathering.last_request.clear()
	assert(game.gathering.apply(1,"gather:mine:0").is_empty());await process_frame
	await capture("mineracao",Vector3(900,84,-219),Vector3(898,82,-225))
	game.gathering.handle("gather:cancel");game._action("resources")
	assert(game.hud.modal_kind=="resources")
	await capture("loja",Vector3(900,85,-208),Vector3(900,83,-223))
	var saved:=FarmState.new();assert(saved.restore(JSON.parse_string(JSON.stringify(game.state.serialize()))))
	assert(saved.resources.mine_owned and saved.resources.rod and saved.resources.pickaxe)
	game.state=FarmState.new();game.resource_view.refresh_world();await physics_frame;await physics_frame
	assert(not gate_hit().is_empty(),"Switching to an unowned farm must close the mine")
	game.session_started=false;game.audio.set_process(false);game.audio.stop_all();game.gathering.reset()
	game.queue_free();await process_frame;await create_timer(.2).timeout
	print("RESOURCE_WORLD_OK: dry fishing sites, mine gate purchase, physical entry, tool poses, shop, save and farm switch")
	quit()
