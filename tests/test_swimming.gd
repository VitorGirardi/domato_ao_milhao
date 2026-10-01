extends SceneTree
var game:Node3D
func _initialize() -> void:call_deferred("run")

func step(direction:Vector3,count:int) -> void:
	for i in range(count):
		await physics_frame
		game.player.velocity=FarmWater.velocity(game.player.position,game.player.velocity,direction,1.0/60,false)
		game.player.move_and_slide()
		game.actor.swimming=FarmWater.swimming_at(game.player.position)
		game.actor.airborne=not game.player.is_on_floor() and not game.actor.swimming
		game.actor.animate(1.0/60,direction.length()>.1,false)

func capture(label:String,from:Vector3,target:Vector3) -> void:
	if DisplayServer.get_name()=="headless":return
	game.camera.position=from;game.camera.look_at(target)
	await create_timer(.3).timeout;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/water-"+label+".png")

func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	game=load("res://scenes/main.tscn").instantiate();game.save_path="user://swimming.json";root.add_child(game);await process_frame
	game.qa_mode=true;game.set_process(false);game.set_physics_process(false)
	game.session_started=true;game.build_mode=false;game.hud.close_modal()
	game.hud.root.visible=false;game.world.build_grid.visible=false;game.ghost.visible=false
	game.world.day_night.update_cycle(80,Vector3(285,7,260))
	await physics_frame;await physics_frame
	# Exact ground interpolation must match real collision between sample vertices.
	for at in [Vector2(622.7,-270.3),Vector2(652.3,-282.8),Vector2(284.1,261.4),Vector2(810,-235)]:
		var h:=FarmLandscape.ground_height(at)
		var query:=PhysicsRayQueryParameters3D.create(Vector3(at.x,h+.5,at.y),Vector3(at.x,h-.5,at.y))
		var hit:Dictionary=game.world.get_world_3d().direct_space_state.intersect_ray(query)
		assert(not hit.is_empty() and absf(hit.position.y-h)<.015,"Terrain sampling differs from collision")
	var bank:=Vector2(285,297)
	game.player.position=Vector3(bank.x,FarmLandscape.height_at(bank)+.1,bank.y);game.player.velocity=Vector3.ZERO
	game.avatar.rotation.y=PI
	RenderingServer.set_render_loop_enabled(false)
	await step(Vector3.FORWARD,600)
	assert(game.player.position.z<276,"Bank still blocks entry into lake")
	assert(game.actor.swimming,"Deep lake must use swimming")
	await step(Vector3.ZERO,240)
	assert(absf(game.player.position.y-3.85)<.12,"Buoyancy must settle below surface")
	assert(not game.player.is_on_floor(),"Swimmer must float above the lake bed")
	assert(not game._try_jump(),"Swimming must not trigger ground jump")
	RenderingServer.set_render_loop_enabled(true)
	await capture("swimming",game.player.position+Vector3(6,5,8),game.player.position+Vector3(0,1.3,0))
	RenderingServer.set_render_loop_enabled(false)
	await step(Vector3.BACK,750)
	assert(game.player.position.z>295 and not game.actor.swimming,"Must walk out onto dry shore")
	assert(game.player.is_on_floor(),"Exit must restore physical floor contact")
	var river:=Vector2(FarmRegion.river_x(85),85)
	game.player.position=Vector3(river.x,2,river.y);game.player.velocity=Vector3.ZERO
	await step(Vector3.ZERO,300)
	assert(game.actor.swimming and absf(game.player.position.y-.85)<.12)
	assert(game.player.position.z>86,"River current should move swimmer downstream")
	assert(not FarmWater.swimming_at(Vector3(420,5,0)),"Bridge must remain dry")
	RenderingServer.set_render_loop_enabled(true)
	await capture("river",game.player.position+Vector3(7,5,8),game.player.position+Vector3(0,1.2,0))
	await capture("waterfall",Vector3(830,77,-233),Vector3(810,76,-265))
	game.session_started=false;game.audio.set_process(false);game.audio.stop_all()
	game.queue_free();await process_frame;await create_timer(.2).timeout
	print("SWIMMING_OK: actual terrain, shore entry/exit, buoyancy, river current, bridge and captures")
	quit()
