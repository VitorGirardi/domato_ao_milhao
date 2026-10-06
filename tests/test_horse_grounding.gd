extends SceneTree
var game:Node3D
func _initialize() -> void:call_deferred("run")
func check_feet(label:String) -> void:
	for key in FarmHorse.LEGS:
		var hoof:Vector3=game.horse.parts[key+"Lower"].to_global(Vector3(0,-.60,.03))
		var floor_y:float=game.horse.ground_at(Vector2(hoof.x,hoof.z))
		print(label," ",key," gap ",hoof.y-floor_y)
		assert(absf(hoof.y-floor_y-.105)<.065,"Hoof is not planted: "+label+" "+key)
func capture(label:String) -> void:
	if DisplayServer.get_name()=="headless":return
	game.camera.position=game.horse.position+Vector3(5,2.2,4)
	game.camera.look_at(game.horse.position+Vector3(0,1.4,0))
	await create_timer(.25).timeout;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/horse-grounding-"+label+".png")
func ride(start:Vector2,finish:Vector2) -> void:
	var direction:Vector2=(finish-start).normalized()
	game.horse.restore({"x":start.x,"z":start.y,"angle":atan2(direction.x,direction.y)})
	game.horse.mount(game.player,game.avatar,game.actor)
	var arrived:=false
	for step in range(500):
		await physics_frame
		game.horse.drive(game.player,game.avatar,game.actor,Vector3(direction.x,0,direction.y),1.0/60,true)
		if step>30:
			assert(game.player.is_on_floor(),"Horse became airborne on a continuous slope")
			for key in FarmHorse.LEGS:
				var hoof:Vector3=game.horse.parts[key+"Lower"].to_global(Vector3(0,-.60,.03))
				var gap:float=hoof.y-game.horse.ground_at(Vector2(hoof.x,hoof.z))
				assert(gap>.035 and gap<.45,"Moving hoof penetrated or floated above floor: %s"%gap)
		if Vector2(game.player.position.x,game.player.position.z).distance_to(finish)<1:
			arrived=true;break
	assert(arrived,"Could not traverse slope")
	game.horse.reset_rider(game.player,game.avatar,game.actor)

func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	game=load("res://scenes/main.tscn").instantiate();game.save_path="user://qa_grounding.json";root.add_child(game)
	await process_frame
	game.player.floor_snap_length=.65;game.player.floor_constant_speed=true;game.player.floor_stop_on_slope=true
	game.qa_mode=true;game.set_process(false);game.set_physics_process(false)
	game.session_started=true;game.build_mode=false;game.hud.close_modal();game.hud.root.visible=false
	game.ghost.visible=false;game.world.build_grid.visible=false
	game.world.day_night.update_cycle(80,Vector3(640,60,-270))
	await physics_frame;await physics_frame
	for entry in [[Vector2(640,-272.5),2.03,"uphill"],[Vector2(640,-272.5),-1.11,"downhill"],[Vector2(640,-272.5),.46,"crosshill"],[Vector2(420,0),PI/2,"bridge"],[Vector2(-30,5),0.0,"flat"]]:
		var at:Vector2=entry[0]
		game.horse.restore({"x":at.x,"z":at.y,"angle":entry[1]})
		game.horse.animate(0,0,false);check_feet(entry[2]+" parked")
		game.horse.mount(game.player,game.avatar,game.actor)
		for i in range(90):
			await physics_frame
			game.horse.drive(game.player,game.avatar,game.actor,Vector3.ZERO,1.0/60,true)
		assert(game.player.is_on_floor(),"Mounted physics lost the floor")
		check_feet(entry[2]+" mounted")
		assert(game.avatar.global_basis.is_equal_approx(game.horse.global_basis*game.horse.model.basis),"Rider left saddle orientation")
		await capture(entry[2])
		# Client representation receives the same root position/heading and calls
		# animate/pose_rider. It must derive the same contacts without moving root.
		var origin:Vector3=game.horse.position
		var pose:Transform3D=game.horse.model.transform
		game.horse.animate(0,0,false);game.horse.pose_rider(game.avatar,game.actor)
		assert(game.horse.position==origin and game.horse.model.transform.is_equal_approx(pose))
		game.horse.reset_rider(game.player,game.avatar,game.actor)
	RenderingServer.set_render_loop_enabled(false)
	await ride(Vector2(630,-267.5),Vector2(650,-277.5))
	await ride(Vector2(650,-277.5),Vector2(630,-267.5))
	RenderingServer.set_render_loop_enabled(true)
	print("HORSE_GROUNDING_OK: four planted feet, uphill/downhill/crosshill/bridge/flat, mounted floor, saddle and replicated pose")
	# Drain audio before freeing the fixture, including on fast headless runners.
	game.session_started=false;game.audio.stop_all()
	await create_timer(.2).timeout
	game.queue_free();await process_frame;await create_timer(.2).timeout;quit()
