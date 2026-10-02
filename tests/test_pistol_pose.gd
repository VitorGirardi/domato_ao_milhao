extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	root.size=Vector2i(1200,850)
	DirAccess.make_dir_recursive_absolute("res://test-results/pistol")
	var stage:=Node3D.new();root.add_child(stage)
	var env:=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("99bdd1");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color.WHITE;env.environment.ambient_light_energy=.75;stage.add_child(env)
	var sun:=DirectionalLight3D.new();sun.rotation=Vector3(-.7,-.4,0);stage.add_child(sun)
	var actors:Array[FarmAvatar]=[]
	var guns:Array[Node3D]=[]
	for i in range(2):
		var model:Node3D=load("res://assets/models/"+(["farmer","farmer_woman"][i])+".glb").instantiate();stage.add_child(model);model.position.x=i*2.2
		var actor:=FarmAvatar.new();actor.setup(model);actors.append(actor)
		var gun:Node3D=load("res://assets/models/pistol_p8.glb").instantiate();actor.hand_socket.add_child(gun);guns.append(gun)
	var camera:=Camera3D.new();stage.add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=4.5
	for mode in ["ready","aim","up","down","reload"]:
		var pitch:float={"ready":0.0,"aim":0.0,"up":.7,"down":-.7,"reload":0.0}[mode]
		for i in range(2):
			actors[i].animate(.1,false,false)
			FarmPistolPose.apply(actors[i],guns[i],pitch,0 if mode=="ready" else 1,.5 if mode=="reload" else 0,0)
			for side in ["R","L"]:
				var target:Vector3=guns[i].global_transform*(FarmPistolPose.GRIP_R if side=="R" else FarmPistolPose.GRIP_L)
				var error:=actors[i].rein_grip_world(side).distance_to(target)
				print(mode," ",i," ",side," grip=",error)
				assert(error<.055,"Palm must contact the pistol grip")
			assert(guns[i].global_transform.is_finite())
		for view in ["front","side"]:
			camera.position=Vector3(1.1,2.7,5) if view=="front" else Vector3(5,2.5,2)
			camera.look_at(Vector3(1.1,1.5,0))
			await process_frame
			if DisplayServer.get_name()!="headless":
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://test-results/pistol/"+mode+"-"+view+".png")
	print("PISTOL_POSE_OK");quit()
