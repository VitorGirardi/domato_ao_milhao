extends SceneTree
var actors:Array[FarmAvatar]=[]
var scene:Node3D
var camera:Camera3D
func _initialize() -> void:
	call_deferred("run")
func verify_wrist(actor:FarmAvatar) -> void:
	for side in ["L","R"]:
		var i:int=actor.bones["Hand."+side]
		var rest:Quaternion=actor.skeleton.get_bone_rest(i).basis.get_rotation_quaternion()
		var delta:Quaternion=rest.inverse()*actor.skeleton.get_bone_pose_rotation(i)
		assert((delta*Vector3.UP).dot(Vector3.UP)>cos(deg_to_rad(20)),"Wrist bends sideways instead of twisting forearm")
func run() -> void:
	root.size=Vector2i(1500,950)
	scene=Node3D.new();root.add_child(scene)
	var environment:=WorldEnvironment.new();environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR;environment.environment.background_color=Color("ded9ca")
	environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.environment.ambient_light_color=Color.WHITE;environment.environment.ambient_light_energy=.6;scene.add_child(environment)
	var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-35,-25,0);light.light_energy=.8;scene.add_child(light)
	for n in ["farmer","helper","vendor","cheesemaker","dairyman"]:
		var model:Node3D=load("res://assets/models/%s.glb"%n).instantiate();scene.add_child(model);FarmAvatar.prepare_model(model)
		var a:=FarmAvatar.new();a.setup(model);actors.append(a);model.visible=false
	camera=Camera3D.new();scene.add_child(camera);camera.current=true;camera.fov=28
	DirAccess.make_dir_recursive_absolute("res://test-results/wrists-v0182")
	var poses:=["idle","walk","run","water","collect","harvest","chicken","shuffle","victory","six_seven","carry_cheese","carry_dairy"]
	for index in range(actors.size()):
		var actor:=actors[index];actor.root.visible=true
		for pose in poses:
			actor.stop_emote();actor.action_time=0
			if FarmEmotes.DANCES.has(pose):actor.emote(pose)
			elif pose in ["water","collect","harvest"]:actor.play(pose)
			for frame in range(80 if pose=="six_seven" and index==0 else 24):
				actor.animate(.025,pose in ["walk","run"],pose=="run")
				if pose=="carry_cheese":
					var motion:=FarmCheeseWorkerMotion.new();motion.actor=actor;motion.work_time=frame*.025;motion.work_pose(.025,true)
				elif pose=="carry_dairy":
					var motion:=FarmDairyWorkerMotion.new();motion.actor=actor;motion.carry_pose(.025)
				verify_wrist(actor)
				if pose=="six_seven" and frame>=10:
					for side in ["L","R"]:
						var hand:int=actor.bones["Hand."+side]
						var skin_basis:Basis=actor.skeleton.get_bone_global_pose(hand).basis*actor.skeleton.get_bone_global_rest(hand).basis.inverse()
						assert((skin_basis*Vector3.BACK).dot(Vector3.UP)>.60,"Six Seven palm must face upward")
				if pose=="six_seven" and index==0 and frame%2==0:
					camera.position=Vector3(1.4,1.95,3.5);camera.look_at(Vector3(0,1.30,0))
					await capture("six-seven-%02d"%frame)
			camera.position=Vector3(0,1.7,4.8);camera.look_at(Vector3(0,1.35,0))
			await capture("%d-%s-front"%[index,pose])
			camera.position=Vector3(3.5,2.1,3.5);camera.look_at(Vector3(0,1.35,0))
			await capture("%d-%s-angle"%[index,pose])
		actor.root.visible=false
	print("WRIST_POSES_OK: five models, twelve poses, wrist alignment, front and three-quarter renders")
	quit()
func capture(label:String) -> void:
	if DisplayServer.get_name()=="headless":return
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/wrists-v0182/%s.png"%label)
