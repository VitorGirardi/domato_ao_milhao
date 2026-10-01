extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var stage:=Node3D.new();root.add_child(stage)
	var world:=WorldEnvironment.new();var env:=Environment.new();env.background_mode=Environment.BG_COLOR;env.background_color=Color("7d9997");env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color.WHITE;env.ambient_light_energy=.7;world.environment=env;stage.add_child(world)
	var light:=DirectionalLight3D.new();stage.add_child(light);light.rotation_degrees=Vector3(-45,-30,0)
	var camera:=Camera3D.new();stage.add_child(camera);camera.position=Vector3(5,3.5,6);camera.look_at(Vector3(0,1.1,.4));camera.current=true;camera.fov=35
	var ground:=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=Vector2(20,20);ground.mesh=plane;stage.add_child(ground)
	for model_id in FarmCharacters.IDS:
		var model:=FarmCharacters.instantiate_model(model_id);stage.add_child(model)
		var avatar:=FarmAvatar.new();avatar.setup(model)
		var tool:Node3D=load("res://assets/models/resource_pickaxe.glb").instantiate();stage.add_child(tool)
		var ore:Node3D=load("res://assets/models/resource_ore_copper.glb").instantiate();stage.add_child(ore);ore.position.z=1.5
		for phase in [0.0,.38,.58,.68]:
			avatar.animate(1,false,false,false)
			var pose:=FarmMiningPose.apply(avatar,tool,phase*FarmMiningPose.PERIOD,ore.position)
			var right:=avatar.rein_grip_world("R").distance_to(tool.global_transform*FarmMiningPose.GRIP_R)
			var left:=avatar.rein_grip_world("L").distance_to(tool.global_transform*FarmMiningPose.GRIP_L)
			print(model_id," phase ",phase," hand errors ",right," ",left)
			assert(right<.045 and left<.045,"Both palms must hold distinct handle positions")
			if phase==.58:assert((tool.global_transform*FarmMiningPose.TIP).distance_to(pose.world_impact)<.001,"Pick tip must contact target at impact")
			if DisplayServer.get_name()!="headless":
				await process_frame;await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://test-results/mining-%s-%02d.png"%[model_id,roundi(phase*100)])
		for step in range(121):
			avatar.animate(1,false,false,false)
			FarmMiningPose.apply(avatar,tool,float(step)/120.0*FarmMiningPose.PERIOD,Vector3(0,0,1.55))
			for grip in [["R",FarmMiningPose.GRIP_R],["L",FarmMiningPose.GRIP_L]]:
				var error:=avatar.rein_grip_world(grip[0]).distance_to(tool.global_transform*grip[1])
				assert(error<.045,"Palm lost the handle during a swing: %f"%error)
		model.queue_free();tool.queue_free();ore.queue_free();await process_frame
	print("MINING_POSE_OK: both rigs, separate palm grips, preparation/contact/recoil, blade contact")
	quit()
