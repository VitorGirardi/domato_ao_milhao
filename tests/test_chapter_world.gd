extends SceneTree
var game:Node3D
func _initialize() -> void:call_deferred("run")
func move_to(at:Vector2) -> void:
	game.player.position=FarmResourceSites.point(at)+Vector3(0,.1,0)
	game.player.velocity=Vector3.ZERO
func capture(title:String,at:Vector3,target:Vector3) -> void:
	if DisplayServer.get_name()=="headless":return
	game._update_ui()
	game.camera.position=at;game.camera.look_at(target)
	await process_frame;await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png("res://test-results/chapter-"+title+".png")
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	game=load("res://scenes/main.tscn").instantiate();game.save_path="user://chapter_world.json";root.add_child(game);await process_frame
	game.qa_mode=true;game.set_process(false);game.set_physics_process(false)
	game.session_started=true;game.build_mode=false;game.hud.close_modal()
	game.state=FarmState.new_farm("survival");game.state.claim(Vector2(4,0));game.state.inventory.carrot=6
	var chapter:FarmChapterWorld=game.chapter_world
	chapter.set_process(false);chapter.reset()
	game.gathering.set_process(false);game.gathering.reset()
	move_to(Vector2(4,0));assert(not chapter.apply(1,"accept").is_empty());assert(game.state.chapter.stage==0)
	game.falls.refresh_targets();assert(game.falls.knock_down("npc:nena"))
	move_to(chapter.NENA_AT);chapter.request("accept");assert(game.state.chapter.stage==0)
	game.falls.apply_poses();game.falls.reset()
	move_to(chapter.NENA_AT);game._interact_nearest();assert(game.state.chapter.stage==1)
	game._interact_nearest();assert(game.state.chapter.stage==2 and game.state.inventory.carrot==0)
	var earned:int=game.state.money
	game._interact_nearest();assert(game.state.money==earned)
	move_to(chapter.RESCUE_AT);game._interact_nearest();assert(game.state.chapter.stage==3)
	assert(chapter.follow_peer==1)
	game.falls.refresh_targets();assert(game.falls.knock_down("chapter:hen"))
	var resting:Vector3=chapter.hen.position
	chapter._process(.05);assert(chapter.hen.position==resting)
	game.falls.apply_poses();game.falls.reset()
	move_to(chapter.NENA_AT);assert(not chapter.apply(1,"return_animal").is_empty());assert(game.state.chapter.stage==3)
	# Walk the road: escort must genuinely travel, and never pay for teleporting.
	move_to(chapter.RESCUE_AT);chapter.request("rescue")
	for i in range(501):
		move_to(chapter.RESCUE_AT.lerp(chapter.NENA_AT,float(i)/500))
		chapter._process(.05)
	for i in range(80):chapter._process(.05)
	assert(Vector2(chapter.hen.position.x,chapter.hen.position.z).distance_to(chapter.NENA_AT)<4.5)
	chapter.request("return_animal");assert(game.state.chapter.stage==4 and game.state.money==earned+250)
	game._update_ui();game.world.day_night.update_cycle(100,game.player.position)
	await capture("nena",Vector3(-34,5,29),Vector3(-27,1.1,22))
	move_to(chapter.REPAIR_AT)
	var save_path:String=game.save_path;game.save_path="user://absent/chapter.json"
	chapter.request("repair");assert(game.state.chapter.stage==4 and not game.state.resources.rod)
	game.save_path=save_path
	chapter.request("repair");assert(game.state.chapter.stage==5 and game.state.resources.rod)
	assert(chapter.bench.visible and not chapter.debris.visible)
	move_to(FarmResourceSites.FISH_SPOTS[3]);game._update_ui()
	assert(game._nearby_context().value=="gather:fish:3")
	assert(game.gathering.apply(1,"gather:fish:3").is_empty())
	game.gathering._process(7.9);assert(game.state.chapter.stage==5)
	game.gathering._process(.2);assert(game.state.chapter.stage==6)
	assert(game.state.money==earned+450)
	var saved:=FarmState.new();assert(saved.restore(JSON.parse_string(FileAccess.get_file_as_string(game.save_path))))
	assert(saved.chapter.stage==6)
	assert(chapter.destination().is_empty())
	await capture("pesqueiro",Vector3(-24,8,-3),Vector3(-39,0,-14))
	game._action("chapter");assert(game.hud.modal_kind=="chapter")
	await capture("journal",game.camera.position,Vector3(-39,0,-14))
	game.hud.close_modal();game.state=FarmState.new_farm("sandbox");chapter._process(0)
	assert(chapter.follow_peer==0 and game.state.chapter.stage==0)
	game.session_started=false;game.audio.stop_all();game.queue_free();await process_frame
	print("CHAPTER_WORLD_OK: physical delivery, escorted rescue, restored bank, atomic fishing reward and farm isolation")
	quit()
