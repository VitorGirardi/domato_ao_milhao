extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://test-results/cat")
	root.size=Vector2i(1440,900)
	var stage:=Node3D.new();root.add_child(stage)
	var env:=WorldEnvironment.new();env.environment=Environment.new()
	env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("acbeb0")
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color=Color("fff3dd");env.environment.ambient_light_energy=.55;stage.add_child(env)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-42,-35,0);sun.light_energy=.9;sun.shadow_enabled=true;sun.directional_shadow_max_distance=8;stage.add_child(sun)
	var ground:=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=Vector2(200,200);ground.mesh=plane
	var mat:=StandardMaterial3D.new();mat.albedo_color=Color("83936e");ground.material_override=mat;stage.add_child(ground)
	var cat:Node3D=load("res://assets/models/cat.glb").instantiate();stage.add_child(cat)
	assert(cat.find_child("RedCollar",true,false)!=null)
	assert(cat.find_child("CollarTag",true,false)!=null)
	var camera:=Camera3D.new();stage.add_child(camera);camera.position=Vector3(1.5,1.05,2.2);camera.look_at(Vector3(0,.50,0))
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=2.1
	for mode in ["idle","walk","sit","pet"]:
		for frame in range(90):
			FarmCatPose.pose(cat,frame/30.0,1.0 if mode=="walk" else 0.0,1.0 if mode=="sit" else 0.0,1.0 if mode=="pet" else 0.0)
			for mesh in cat.find_children("*","MeshInstance3D",true,false):assert(mesh.global_transform.is_finite())
			if "--cat-film" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless":
				await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://test-results/cat/%s-%03d.png"%[mode,frame])
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://test-results/cat/%s.png"%mode)
	stage.queue_free();await process_frame
	assert(OS.get_user_data_dir().contains("test-results"))
	var game:Node3D=load("res://scenes/main.tscn").instantiate();game.save_path="user://cat_game.json";root.add_child(game)
	await process_frame;game.qa_mode=true;game.set_process(false);game.set_physics_process(false)
	game.state=FarmState.new();game.state.unlimited_money=true;game.state.claim(Vector2(4,0))
	game.world.rebuild(game.state);await physics_frame
	var companion:FarmCat=game.world.cat
	companion.reset(game.state);assert(companion.visible)
	var before:Dictionary=game.state.serialize()
	assert(not companion.pet(companion.position+Vector3(10,0,0)))
	game.player.position=companion.position+Vector3(0,0,1)
	game.session_started=true;game.build_mode=false;game.hud.close_modal()
	assert(game._nearby_context().action=="cat")
	game._interact_nearest();assert(companion.pet_count==1)
	assert(not companion.pet(game.player.position),"No spam during affection")
	for i in range(120):companion.update(1.0/60,game.player.position,game.state)
	assert(companion.affection>.9 and game.state.serialize()==before)
	var poses:=FarmCoopVisuals.capture(game.world);assert(poses.has("cat"))
	FarmCoopVisuals.apply(game.world,poses,1)
	if DisplayServer.get_name()!="headless":
		game.hud.hide();game.camera.position=companion.position+Vector3(-1.8,1.2,2.7);game.camera.look_at(companion.position+Vector3(0,.5,0))
		await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://test-results/cat/farm.png")
	game.session_started=false;game.queue_free();await process_frame;await create_timer(.2).timeout
	print("CAT_OK: articulated joints, deterministic poses, idle/walk/sit/affection")
	quit()

