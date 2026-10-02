extends SceneTree
var game:Node3D
func _initialize() -> void:call_deferred("run")
func capture(label:String,at:Vector3,target:Vector3) -> void:
	game.camera.position=at;game.camera.look_at(target)
	await process_frame;await process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://test-results/shore-"+label+".png")
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	root.size=Vector2i(1440,900)
	game=load("res://scenes/main.tscn").instantiate();game.save_path="user://shore.json";root.add_child(game)
	await process_frame
	game.qa_mode=true;game.session_started=true;game.build_mode=false
	game.set_process(false);game.set_physics_process(false);game.world.set_process(false)
	game.hud.close_modal();game.world.build_grid.visible=false;game.ghost.visible=false
	game.state.claim(Vector2(4,0));game.world.rebuild(game.state);game.state.resources.rod=true
	var shore:FarmShoreLife=game.world.landscape.get_node("ShoreLife")
	assert(shore.fish.size()==24 and shore.plants.size()>=24 and shore.lilies.size()>=12)
	var saved:Dictionary=game.state.serialize()
	var start:Vector3=shore.fish[0].node.position
	shore._animate_fish(shore.fish[0],2)
	assert(start.distance_to(shore.fish[0].node.position)>.1)
	for record in shore.fish:
		for time in [0.0,2.0,5.0,9.0]:
			shore._animate_fish(record,time)
			var p:Vector3=record.node.position
			assert(p.y<FarmRegion.water_level(Vector2(p.x,p.z)))
			assert(p.y>FarmLandscape.ground_height(Vector2(p.x,p.z)))
	assert(saved==game.state.serialize(),"Ambient life must not mutate progress")
	game.player.position=FarmResourceSites.point(FarmResourceSites.FISH_SPOTS[3]);game._update_ui()
	game.world.day_night.update_cycle(100,game.player.position)
	await capture("stream",Vector3(-26,12,40),Vector3(-41,0,8))
	await capture("water",Vector3(-36,3,-3),Vector3(-42,-.2,0))
	game.gathering.set_process(false)
	assert(game.gathering.apply(1,"gather:fish:3").is_empty())
	game.gathering.jobs[1].remaining=1.6
	game._update_ui()
	await capture("fishing",Vector3(-28,4,-8),Vector3(-42,1,-15))
	game.gathering.apply(1,"gather:cancel")
	game.player.position=FarmResourceSites.point(FarmResourceSites.FISH_SPOTS[0])
	game._update_ui()
	await capture("lake",Vector3(277,13,308),Vector3(285,5,280))
	game.session_started=false;game.audio.stop_all();game.queue_free();await process_frame
	print("SHORE_LIFE_OK: authored shores, bounded swimming fish, fishing and saves")
	quit()

