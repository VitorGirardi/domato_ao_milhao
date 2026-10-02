extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://test-results/fall")
	root.size=Vector2i(1440,900)
	var stage:=Node3D.new();root.add_child(stage)
	var env:=WorldEnvironment.new();env.environment=Environment.new()
	env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("9ec9e5")
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color=Color.WHITE;env.environment.ambient_light_energy=.65;stage.add_child(env)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-45,-35,0);sun.light_energy=.9;sun.shadow_enabled=true;stage.add_child(sun)
	var plane:=MeshInstance3D.new();plane.mesh=PlaneMesh.new();plane.mesh.size=Vector2(50,50)
	var mat:=StandardMaterial3D.new();mat.albedo_color=Color("839b67");plane.material_override=mat;stage.add_child(plane)
	var entries:Array[Dictionary]=[]
	var kinds:=["human","horse","cow","pig","cat","chicken"]
	for i in kinds.size():
		var body:Node3D=FarmHorse.new() if kinds[i]=="horse" else Node3D.new()
		stage.add_child(body);body.position=Vector3((i%3)*4,0,(i/3)*5)
		var model:Node3D
		if kinds[i]=="horse":model=body.model
		else:
			model=load("res://assets/models/"+("farmer" if kinds[i]=="human" else kinds[i])+".glb").instantiate();body.add_child(model)
		var actor:FarmAvatar=null
		if kinds[i]=="human":actor=FarmAvatar.new();actor.setup(model)
		entries.append({"body":model if kinds[i] in ["cow","pig","chicken"] else body,"model":model,"actor":actor,"kind":kinds[i],"base_transform":model.transform,"ground_y":0.0})
	var camera:=Camera3D.new();stage.add_child(camera);camera.position=Vector3(12,13,18);camera.look_at(Vector3(4,.5,2))
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=15
	for phase in ["impact","collapse","down","recover","standing"]:
		var recovery:bool=phase in ["recover","standing"]
		var age:float={"impact":.16,"collapse":.55,"down":1.1,"recover":.9,"standing":2.0}[phase]
		for entry in entries:
			FarmFallPose.apply(entry,age,recovery)
			assert(entry.model.global_transform.is_finite())
			if phase=="down":assert(absf(entry.model.rotation.z)>1.2)
			if phase=="standing":assert(entry.model.transform.is_equal_approx(entry.base_transform))
		await process_frame
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://test-results/fall/"+phase+".png")
	# Animation/blinking may run between presentation passes. Reassert the pose
	# each call, but expensive terrain fitting must happen only once at rest.
	for entry in entries:
		FarmFallPose.apply(entry,10.0)
		var expected:Transform3D=entry.model.transform
		var fits:int=entry.fall_pose.fit_passes
		for i in range(120):
			entry.model.transform=entry.base_transform
			if entry.actor:
				entry.actor.animate(.016,true,false)
				entry.actor.face_mesh.set_blend_shape_value(entry.actor.blink_index,0)
			FarmFallPose.apply(entry,10.0+i*.016)
			assert(entry.model.transform.is_equal_approx(expected))
			assert(entry.fall_pose.fit_passes==fits)
			if entry.actor:assert(entry.actor.face_mesh.get_blend_shape_value(entry.actor.blink_index)>.99)
		if entry.body==entry.model:entry.model.get_parent_node_3d().position.x+=.3
		else:entry.body.position.x+=.3
		FarmFallPose.apply(entry,15.0)
		assert(entry.fall_pose.fit_passes==fits+1)
		FarmFallPose.reset(entry)
		assert(entry.model.transform.is_equal_approx(entry.base_transform))
	print("FALL_POSE_OK")
	quit()

