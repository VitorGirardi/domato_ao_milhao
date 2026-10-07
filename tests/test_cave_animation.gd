extends SceneTree
var actors:Array[FarmCaveCreature]=[]
func _initialize() -> void:call_deferred("run")
func run() -> void:
	root.size=Vector2i(1440,900)
	var scene:=Node3D.new();root.add_child(scene)
	var environment:=WorldEnvironment.new();var env:=Environment.new();environment.environment=env
	env.background_mode=Environment.BG_COLOR;env.background_color=Color("182127")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("c5d6ec");env.ambient_light_energy=.8
	scene.add_child(environment)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-50,-25,0);sun.light_energy=1.6;scene.add_child(sun)
	var camera:=Camera3D.new();camera.position=Vector3(7,4,10);scene.add_child(camera);camera.look_at(Vector3(0,1.3,0));camera.current=true;camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=10
	for i in range(3):
		var actor:=FarmCaveCreature.new();actor.setup(scene,i);actor.root.position.x=(i-1)*3.2;actors.append(actor)
		assert(actor.bones.has("Foot.L") and actor.bones.has("Hand.R") and actor.bones.has("Feeler.R"))
	DirAccess.make_dir_recursive_absolute("res://test-results/cave-animation")
	for mode in ["idle","walk","work","carry"]:
		for step in range(90):
			for actor in actors:actor.animate(1.0/60,.012 if mode in ["walk","carry"] else 0,mode=="work",mode=="carry")
			if step in [29,59,89]:
				await process_frame
				for actor in actors:
					for index in range(actor.skeleton.get_bone_count()):assert(actor.skeleton.get_bone_global_pose(index).is_finite())
				if DisplayServer.get_name()!="headless":
					await RenderingServer.frame_post_draw
					root.get_texture().get_image().save_png("res://test-results/cave-animation/%s-%d.png"%[mode,step])
		for actor in actors:assert(actor.carried.visible==(mode=="carry"))
	var actor:=actors[0];var rest:=actor.skeleton.get_bone_pose_rotation(actor.bones["Thigh.L"])
	actor.animate(.1,.2,false,false)
	assert(actor.skeleton.get_bone_pose_rotation(actor.bones["Thigh.L"]).angle_to(rest)>.01)
	scene.queue_free();await process_frame
	print("CAVE_ANIMATION_OK: three editable rigs, idle/walk/work/carry poses, finite bones and gait response")
	quit()
