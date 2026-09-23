extends SceneTree
## Deterministic visual QA of the real runtime rig. No player state or save is loaded.
var horse:FarmHorse
var camera:Camera3D
func _initialize() -> void:call_deferred("run")
func frame(label:String) -> void:
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/horse-anatomy/"+label+".png")
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	root.mode=Window.MODE_WINDOWED;root.size=Vector2i(1280,900)
	DirAccess.make_dir_recursive_absolute("res://test-results/horse-anatomy")
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
	assert(horse.skin_bones.size()==10 and horse.parts.size()==11)
	for node in ["ReinL","ReinR"]:assert(horse.model.find_child(node,true,false)!=null)
	horse.gait=0;horse.animate(0,0,false);await frame("idle-three-quarter")
	camera.position=Vector3(6,1.65,.15);camera.look_at(Vector3(0,1.45,.15));await frame("idle-side")
	for running in [false,true]:
		for phase in range(8):
			horse.gait=TAU*phase/8.0;horse.animate(0,8 if not running else 14,running)
			for key in horse.skin_bones:
				assert(horse.skin.get_bone_global_pose(horse.skin_bones[key]).is_finite())
			await frame(("gallop" if running else "walk")+"-%02d"%phase)
	horse.gait=0;horse.animate(0,0,false)
	var state:=FarmState.new();var landscape:=FarmLandscape.new();var player:=CharacterBody3D.new();player.position=Vector3(50,0,50)
	horse.life.reset(horse);horse.life.mode="graze";horse.life.remaining=60
	for amount in [0.5,1.0]:
		horse.life.graze=amount;horse.life.update(horse,0,true,state,landscape,player)
		assert(horse.parts.HorseNeck.position.is_equal_approx(horse.part_home.HorseNeck))
		await frame("graze-%d"%int(amount*100))
	landscape.meadow.free();landscape.nature.free();landscape.free();player.free()
	horse.parts.HorseNeck.position=horse.part_home.HorseNeck;horse.parts.HorseNeck.rotation=Vector3(0,.18,0);horse.sync_skin()
	camera.position=Vector3(4,2.4,5);camera.look_at(Vector3(0,1.45,.15));await frame("look-three-quarter")
	stage.queue_free();await process_frame
	var game:Node3D=load("res://scenes/main.tscn").instantiate();game.save_path="user://qa_horse_anatomy.json";root.add_child(game)
	await process_frame;game.set_physics_process(false);game.hud.visible=false;game.weapons.layer.visible=false;game.avatar.visible=false
	horse=game.horse;horse.label.visible=false;horse.life.remaining=60
	game.camera.position=horse.position+Vector3(4,2.7,4.7);game.camera.look_at(horse.position+Vector3(0,1.40,.15))
	game.camera.fov=38;horse.gait=0;horse.animate(0,0,false)
	await frame("in-game-idle")
	horse.gait=PI/2;horse.animate(0,14,true);await frame("in-game-gallop")
	game.session_started=false;game.queue_free();await process_frame
	print("HORSE_ANATOMY_OK: runtime rig, 16 gait poses, actual grazing transitions, reins, head turn and game scene")
	quit()
