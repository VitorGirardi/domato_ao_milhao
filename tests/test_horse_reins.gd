extends SceneTree
## Deterministic visual QA of the real runtime rig. No player state or save is loaded.
var horse:FarmHorse
var camera:Camera3D
func _initialize() -> void:call_deferred("run")
func frame(label:String) -> void:
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/horse-reins/"+label+".png")
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	root.mode=Window.MODE_WINDOWED;root.size=Vector2i(1280,900)
	DirAccess.make_dir_recursive_absolute("res://test-results/horse-reins")
	var stage:=Node3D.new();root.add_child(stage)
	var environment:=WorldEnvironment.new();var settings:=Environment.new()
	settings.background_mode=Environment.BG_COLOR;settings.background_color=Color("d5ddd6")
	settings.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	settings.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;settings.ambient_light_color=Color.WHITE;settings.ambient_light_energy=.4
	environment.environment=settings;stage.add_child(environment)
	var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-45,-30,0);light.light_energy=.65;light.shadow_enabled=true;stage.add_child(light)
	var floor_mesh:=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=Vector2(200,200);floor_mesh.mesh=plane
	var material:=StandardMaterial3D.new();material.albedo_color=Color("b6c0ad");floor_mesh.material_override=material;stage.add_child(floor_mesh)
	horse=FarmHorse.new();stage.add_child(horse);horse.position=Vector3.ZERO;horse.rotation=Vector3.ZERO;horse.label.visible=false
	camera=Camera3D.new();stage.add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=3.65
	camera.position=Vector3(5,2.4,4.8);camera.look_at(Vector3(0,1.45,.15));camera.current=true
	var player:=CharacterBody3D.new();stage.add_child(player)
	var collision:=CollisionShape3D.new();collision.shape=CapsuleShape3D.new();player.add_child(collision)
	var avatar:Node3D=load("res://assets/models/farmer.glb").instantiate();player.add_child(avatar)
	FarmAvatar.prepare_model(avatar)
	var actor:=FarmAvatar.new();actor.setup(avatar)
	horse.mount(player,avatar,actor)
	player.position=Vector3.ZERO
	camera.size=4.8
	var accepted:=[0]
	horse.encouraged.connect(func():accepted[0]+=1)
	assert(horse.encourage());assert(not horse.encourage());assert(accepted[0]==1)
	horse.pat_time=0
	for running in [false,true]:
		horse.burst=3.5 if running else 0
		for phase in range(8):
			horse.gait=TAU*phase/8.0;horse.animate(0,14 if running else 8,running)
			actor.animate(0,false,false);horse.pose_rider(avatar,actor)
			for side in range(2):
				assert(horse.to_global(horse.rein_end(side)).distance_to(actor.rein_grip_world("L" if side==0 else "R"))<.0001)
			for key in actor.bones:assert(actor.skeleton.get_bone_global_pose(actor.bones[key]).is_finite())
			camera.position=Vector3(6,3.1,1.3);camera.look_at(Vector3(0,2,.2))
			await frame(("gallop" if running else "walk")+"-%02d"%phase)
	camera.position=Vector3(0,3,7);camera.look_at(Vector3(0,2,.2));await frame("front")
	camera.position=Vector3(5,3.4,5);camera.look_at(Vector3(0,2,.2));await frame("three-quarter")
	for step in range(9):
		horse.pat_time=.55*(1-step/8.0);horse.pose_rider(avatar,actor)
		assert(horse.to_global(horse.rein_end(0)).distance_to(actor.rein_grip_world("L"))<.0001)
		if horse.pat_time>0:assert(horse.rein_end(1).is_equal_approx(horse.rein_end(0)))
		if step==4:assert(actor.rein_grip_world("R").distance_to(horse.to_global(Vector3(.28,2.30,.76)))<.08)
		await frame("pat-%02d"%step)
	horse.reset_rider(player,avatar,actor);horse.update_reins()
	for side in range(2):assert(horse.rein_end(side).is_equal_approx(horse.to_local(horse.parts.HorseBody.to_global(horse.rein_ends[side][1]))))
	avatar.visible=false;await frame("dismounted")
	stage.queue_free();await process_frame
	var game:Node3D=load("res://scenes/main.tscn").instantiate();game.save_path="user://qa_reins_visual.json";root.add_child(game)
	await process_frame
	game.set_process(false);game.set_physics_process(false);game.hud.visible=false;game.hud.close_modal();game.weapons.layer.visible=false
	horse=game.horse;horse.label.visible=false;horse.mount(game.player,game.avatar,game.actor)
	game.avatar.rotation.y=horse.heading
	game.camera.fov=38
	for shot in ["side","front","pat","returned"]:
		horse.burst=3.5;horse.pat_time=.275 if shot=="pat" else 0.0
		horse.animate(0,8,false);horse.pose_rider(game.avatar,game.actor)
		game.camera.position=horse.to_global(Vector3(6,3.3,1.5) if shot=="side" else (Vector3(0,3.1,7) if shot=="front" else Vector3(5,3.4,5)))
		game.camera.look_at(horse.position+Vector3(0,2,.2));await frame("game-"+shot)
	game.session_started=false;game.queue_free();await process_frame;await create_timer(.15).timeout
	print("HORSE_REINS_OK: both grips, 16 gait phases, pat left hold, saddle fallback, accepted signal")
	quit()
