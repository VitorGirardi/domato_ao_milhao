extends SceneTree

func _initialize() -> void:call_deferred("run")

func run() -> void:
	var stage:=Node3D.new();root.add_child(stage)
	var camera:=Camera3D.new();stage.add_child(camera);camera.position=Vector3(4,2.8,4);camera.look_at(Vector3(0,1,.2));camera.current=true;camera.fov=38
	var environment:=WorldEnvironment.new();var env:=Environment.new();env.background_mode=Environment.BG_COLOR;env.background_color=Color("819b93");env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color.WHITE;env.ambient_light_energy=.8;environment.environment=env;stage.add_child(environment)
	var light:=DirectionalLight3D.new();stage.add_child(light);light.rotation_degrees=Vector3(-40,-25,0)
	var ground:=MeshInstance3D.new();ground.mesh=PlaneMesh.new();stage.add_child(ground)
	for model_id in FarmCharacters.IDS:
		var model:=FarmCharacters.instantiate_model(model_id);stage.add_child(model)
		var actor:=FarmAvatar.new();actor.setup(model)
		actor.locomotion.enabled=true
		for kind in ["water","harvest"]:
			actor.play(kind)
			assert(is_equal_approx(actor.action_time,FarmWorkPose.duration(kind)))
			for frame in range(85):
				var phase:=float(frame)/84
				actor.action_time=FarmWorkPose.duration(kind)*(1-phase)+.00001
				actor.animate(0,false,false,false)
				assert(actor.work_pose_active)
				assert(is_zero_approx(actor.root.position.y))
				var sole:=actor.locomotion.sole_height(actor)
				assert(sole>-.01 and sole<.045,"Unplanted work feet: %s %f"%[kind,sole])
				await process_frame
				if kind=="water":
					for pair in [["R",FarmWorkPose.CAN_GRIP_R],["L",FarmWorkPose.CAN_GRIP_L]]:
						var error:=actor.rein_grip_world(pair[0]).distance_to(actor.can.global_transform*pair[1])
						assert(error<.05,"Water palm lost vessel: %s %f"%[pair[0],error])
				if frame in [0,21,42,63,84] and DisplayServer.get_name()!="headless":
					await RenderingServer.frame_post_draw
					root.get_texture().get_image().save_png("res://test-results/work-%s-%s-%02d.png"%[model_id,kind,frame])
			actor.action_time=0;actor.animate(.016,false,false,false)
			assert(not actor.work_pose_active and not actor.can.visible)
			# Canceled work must relinquish pelvis translation before swim/air poses.
			actor.play(kind);actor.animate(.3,false,false,false)
			actor.swimming=true;actor.animate(.016,false,false,false)
			assert(not actor.work_pose_active and not actor.can.visible)
			var pelvis:int=actor.bones.Pelvis
			assert(actor.skeleton.get_bone_pose_position(pelvis).is_equal_approx(actor.skeleton.get_bone_rest(pelvis).origin))
			actor.swimming=false;actor.action_time=0
		model.queue_free();await process_frame
	stage.queue_free();await process_frame
	print("WORK_ACTIONS_OK: both rigs, sampled actions, two-hand vessel contact, planted feet, cancellation")
	quit()
