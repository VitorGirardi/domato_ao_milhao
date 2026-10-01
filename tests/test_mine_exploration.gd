extends SceneTree
## Integration: physical galleries, host transactions and restoration of closed gates.
var game:Node3D
const STATIONS := [Vector2(900,-233),Vector2(909,-256)]
func _initialize() -> void:call_deferred("run")
func move_to(at:Vector2) -> void:
	game.player.position=Vector3(at.x,81.15,at.y);game.player.velocity=Vector3.ZERO
func gate_hit(index:int) -> bool:
	var start:=Vector3(900,82,-234) if index==0 else Vector3(910,82,-256)
	var finish:=Vector3(900,82,-238) if index==0 else Vector3(914,82,-256)
	var ray:=PhysicsRayQueryParameters3D.create(start,finish);ray.exclude=[game.player.get_rid()]
	return not game.world.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()
func action(value:String) -> String:
	game.gathering.last_request.clear();return game.gathering.apply(1,value)
func refresh() -> void:
	game.resource_view.refresh_world();await physics_frame;await physics_frame
func capture(label:String,from:Vector3,target:Vector3) -> void:
	if DisplayServer.get_name()=="headless":return
	game._update_ui()
	game.world.day_night.update_cycle(game.state.elapsed,from)
	game.world.landscape.get_node("ValeESerra").update_lights(from)
	game.camera.position=from;game.camera.look_at(target);game.camera.fov=65
	await create_timer(.25).timeout;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/mine-"+label+".png")
func walk_to(at:Vector2) -> void:
	for step in range(120):
		await physics_frame
		var remaining:=at-Vector2(game.player.position.x,game.player.position.z)
		if remaining.length()<.25:return
		var direction:=remaining.normalized()
		game.player.velocity=Vector3(direction.x*12,-2,direction.y*12);game.player.move_and_slide()
	assert(false,"Gallery route is blocked at %s, toward %s"%[game.player.position,at])
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	game=load("res://scenes/main.tscn").instantiate();game.save_path="user://mine_exploration.json";root.add_child(game);await process_frame
	game.qa_mode=true;game.set_process(false);game.set_physics_process(false)
	game.session_started=true;game.build_mode=false;game.hud.close_modal()
	game.state=FarmState.new();game.state.claim(Vector2(4,0));game.state.money=12000
	for kind in ["pickaxe","mine"]:assert(FarmResources.buy(game.state,kind).is_empty())
	game.state.resources.stock.copper=8;game.state.resources.stock.iron=10;game.state.resources.mined=18
	game.world.rebuild(game.state);game.actor.airborne=false;game.gathering.reset();game.gathering.set_process(false)
	move_to(STATIONS[0]);await refresh()
	var rock_mesh:MeshInstance3D=game.world.landscape.get_node("ValeESerra").find_child("MineRockAndVegetation",true,false)
	var rock_body:StaticBody3D=rock_mesh.get_child(0)
	assert(rock_body.get_child(0).shape.backface_collision,"Mountain must collide from inside and outside")
	rock_body.collision_layer=1<<20
	var outside_ray:=PhysicsRayQueryParameters3D.create(Vector3(935,89,-260),Vector3(900,89,-260),1<<20)
	assert(not game.world.get_world_3d().direct_space_state.intersect_ray(outside_ray).is_empty(),"Exterior camera rays must hit the mountain")
	rock_body.collision_layer=1
	assert(gate_hit(0) and gate_hit(1),"Both unpurchased galleries must be physically closed")
	await capture("locked",Vector3(900,84,-226),Vector3(900,83,-236))
	assert(FarmResourceSites.nearby(game).value=="mine_gallery")
	game._action("mine_gallery");assert(game.hud.modal_kind=="mine_gallery")
	await capture("upgrades",Vector3(900,84,-226),Vector3(900,83,-236))
	game.hud.close_modal()
	move_to(FarmResourceSites.ORE_SPOTS[3]);assert(not action("gather:mine:3").is_empty())
	var before:Dictionary=game.state.serialize().duplicate(true)
	move_to(Vector2(900,-224));action("resource:buy:gallery_1")
	assert(game.state.serialize()==before,"Gallery purchase must require proximity")
	move_to(STATIONS[0]);var path:String=game.save_path;game.save_path="user://missing_mine_folder/fail.json"
	action("resource:buy:gallery_1");game.save_path=path
	assert(game.state.serialize()==before,"Failed save must roll back upgrade, materials and money")
	assert(action("resource:buy:gallery_1").contains("concluída"));await refresh()
	assert(not gate_hit(0) and gate_hit(1) and game.state.resources.gallery_level==1)
	assert(game.state.resources.stock.copper==0 and game.state.money==int(before.money)-1200)
	move_to(FarmResourceSites.ORE_SPOTS[3]);assert(action("gather:mine:3").is_empty());game.gathering._process(5.1)
	assert(game.state.resources.mined==19)
	move_to(FarmResourceSites.ORE_SPOTS[6]);assert(not action("gather:mine:6").is_empty())
	move_to(STATIONS[1]);assert(action("resource:buy:gallery_2").contains("concluída"));await refresh()
	assert(not gate_hit(0) and not gate_hit(1) and game.state.resources.gallery_level==2)
	assert(game.state.resources.stock.iron==0)
	move_to(FarmResourceSites.ORE_SPOTS[8]);assert(action("gather:mine:8").is_empty());game.gathering._process(5.1)
	assert(game.state.resources.mined==20)
	var restored:=FarmState.new();assert(restored.restore(JSON.parse_string(JSON.stringify(game.state.serialize()))))
	assert(restored.resources==game.state.resources and restored.resources.node_ready.size()==9)
	game.world.day_night.update_cycle(80,Vector3(900,82,-280))
	assert(game.world.day_night.sun.light_energy==0)
	game.world.day_night.update_cycle(80,Vector3(900,82,-214))
	assert(game.world.day_night.sun.light_energy>.6,"Leaving the mine restores exterior daylight")
	# Walk the actual player capsule through every authored bend, in both directions.
	move_to(Vector2(900,-224));RenderingServer.set_render_loop_enabled(false)
	for cell in FarmMineLayout.CELLS:await walk_to(Vector2(900,-220)+cell)
	assert(absf(game.player.position.y-81.05)<.5,"Mine floor must support the capsule")
	game.yaw=0;game.pitch=.7;game._update_camera(1,true)
	assert(game.camera.position.y<87.2,"Walking camera must stay below the cave roof")
	RenderingServer.set_render_loop_enabled(true)
	await capture("deep",Vector3(900,84,-280),Vector3(900,83,-289))
	RenderingServer.set_render_loop_enabled(false)
	for i in range(FarmMineLayout.CELLS.size()-1,-1,-1):await walk_to(Vector2(900,-220)+FarmMineLayout.CELLS[i])
	RenderingServer.set_render_loop_enabled(true)
	await capture("gallery",Vector3(884,84,-247),Vector3(884,83,-256))
	await capture("exterior",Vector3(942,111,-179),Vector3(900,87,-245))
	game.state=FarmState.new();game.state.claim(Vector2(4,0));game.state.resources.mine_owned=true
	await refresh();assert(gate_hit(0) and gate_hit(1),"Changing farms must close galleries")
	game.session_started=false;game.audio.set_process(false);game.audio.stop_all();game.gathering.reset()
	game.queue_free();await process_frame;await create_timer(.2).timeout
	print("MINE_EXPLORATION_OK: closed/open gates, proximity, save rollback, gallery ore, roundtrip, capsule route and farm switch")
	quit()
