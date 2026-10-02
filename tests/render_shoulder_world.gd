extends SceneTree
## Real world, camera, HUD and weapon poses; isolated from player saves.
var game:Node3D
func _initialize() -> void:call_deferred("run")
func capture(label:String) -> void:
	await process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://test-results/shoulder-world/"+label+".png")
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	DirAccess.make_dir_recursive_absolute("res://test-results/shoulder-world")
	root.size=Vector2i(1440,900)
	game=load("res://scenes/main.tscn").instantiate();game.save_path="user://shoulder_visual.json";root.add_child(game)
	await process_frame
	game.qa_mode=true;game.session_started=true;game.set_process(false);game.set_physics_process(false)
	game.weapons.set_physics_process(false);game.world.set_process(false);game.falls.set_process(false);game.falls.set_physics_process(false)
	game.build_mode=false;game.hud.close_modal();game.world.build_grid.visible=false;game.ghost.visible=false
	assert(game.state.claim(Vector2(4,0)).is_empty());game.world.rebuild(game.state)
	game.player.position=Vector3(8,FarmLandscape.height_at(Vector2(8,8)),8)
	game.world.day_night.update_cycle(100,game.player.position)
	game.state.armory.pistol=true;game.state.armory.magazine=8;game.state.armory.reserve=32
	game.yaw=0;game.pitch=.65;game.walk_distance=9
	game._update_ui()
	await physics_frame;await physics_frame
	for model in ["farmer","farmer_woman"]:
		if model=="farmer_woman":
			game.avatar.visible=false
			game.avatar=load("res://assets/models/farmer_woman.glb").instantiate();game.player.add_child(game.avatar)
			game.actor=FarmAvatar.new();game.actor.setup(game.avatar,game.world)
			game.weapons.pistol.reparent(game.actor.hand_socket)
		for mode in ["right","left","up","down","reload","released"]:
			game.weapons.armed=true;game.weapons.aiming=mode!="released"
			game.weapons.shoulder_side=-1 if mode=="left" else 1
			game.weapons.aim_pitch=-.55 if mode=="up" else (.6 if mode=="down" else .08)
			game.weapons.reload_left=0
			for i in 90:
				game.actor.animate(1.0/60,false,false)
				game.weapons._physics_process(1.0/60)
				game._update_camera(1.0/60)
			game.weapons.reload_left=game.weapons.RELOAD_TIME*.5 if mode=="reload" else 0
			game.weapons._physics_process(0);game.weapons._pose_player(1)
			for side in ["R","L"]:
				var target:Vector3=game.weapons.pistol.global_transform*(FarmPistolPose.GRIP_R if side=="R" else FarmPistolPose.GRIP_L)
				assert(game.actor.rein_grip_world(side).distance_to(target)<.055,"Integrated palm grip drift")
			assert(game.avatar.visible,"Shoulder camera must preserve the third person avatar")
			assert(game.camera.position.distance_to(game.player.position)>2,"Camera must stay outside the player")
			await capture(model+"-"+mode)
	game.session_started=false;game.audio.set_process(false);game.audio.stop_all();game.queue_free()
	await process_frame;await create_timer(.2).timeout
	print("SHOULDER_WORLD_OK: both avatars, shoulders, vertical aim, reload and release")
	quit()
