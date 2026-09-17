extends SceneTree
## Render the actual GLB assets with Godot, without reading the player's save.

func _initialize() -> void:
	call_deferred("render_preview")

func render_preview() -> void:
	root.size=Vector2i(1440,900)
	var scene:=Node3D.new()
	root.add_child(scene)
	var env:=WorldEnvironment.new()
	env.environment=Environment.new()
	env.environment.background_mode=Environment.BG_COLOR
	env.environment.background_color=Color("f3ead9")
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color=Color("fff4df")
	env.environment.ambient_light_energy=0.35
	scene.add_child(env)
	var light:=DirectionalLight3D.new()
	light.rotation_degrees=Vector3(-40,-30,0)
	light.light_energy=0.55
	light.shadow_enabled=true
	scene.add_child(light)
	var floor_mesh:=MeshInstance3D.new()
	var plane:=PlaneMesh.new()
	plane.size=Vector2(200,200)
	floor_mesh.mesh=plane
	var mat:=StandardMaterial3D.new()
	mat.albedo_color=Color("eee4d1")
	floor_mesh.material_override=mat
	scene.add_child(floor_mesh)
	var actors:Array[FarmAvatar]=[]
	for i in range(3):
		var model_name:String=["farmer","helper","vendor"][i]
		var packed:PackedScene=load("res://assets/models/%s.glb"%model_name)
		var actor:Node3D=packed.instantiate()
		FarmAvatar.prepare_model(actor)
		actor.position.x=(i-1)*1.7
		scene.add_child(actor)
		var animator:=FarmAvatar.new()
		animator.setup(actor)
		actors.append(animator)
		assert(animator.skeleton.get_bone_count()==20)
		var body:MeshInstance3D=actor.find_child("BodySkin",true,false)
		assert(body!=null and body.skin!=null)
		# A zero model-space rotation must reproduce the imported local rest,
		# including downward-facing leg bones. Identity is not the local rest.
		for key in animator.bones:
			animator.pose_bone(key,Vector3.ZERO)
			var index:int=animator.bones[key]
			assert(absf(animator.skeleton.get_bone_pose_rotation(index).normalized().dot(animator.skeleton.get_bone_rest(index).basis.get_rotation_quaternion().normalized()))>0.99999)
		animator.animate(1,false,false)
	var camera:=Camera3D.new()
	camera.position=Vector3(0,1.65,9.5)
	camera.fov=31
	scene.add_child(camera)
	camera.look_at(Vector3(0,1.25,0))
	camera.current=true
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/characters-v09-front.png")
	for frame in range(9):
		for animator in actors:
			animator.blink_elapsed=frame*0.0275
			animator.update_blink(0)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://test-results/blink-%02d.png"%frame)
	for animator in actors:
		animator.blink_elapsed=0.09
		animator.update_blink(0)
		assert(animator.face_mesh.get_blend_shape_value(animator.blink_index)>0.99)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/characters-v09-blink.png")
	for animator in actors:
		animator.update_blink(0.2)
		assert(animator.face_mesh.get_blend_shape_value(animator.blink_index)==0.0)
		assert(animator.blink_wait>=2.5 and animator.blink_wait<=5.5)
	camera.position=Vector3(3.1,2.0,9.1)
	camera.look_at(Vector3(0,1.3,0))
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/characters-v09-angle.png")
	# Deliberately bend elbow and knee, and raise the opposite arm to inspect seams.
	for animator in actors:
		animator.pose_bone("UpperArm.R",Vector3(-0.65,0,-0.28))
		animator.pose_bone("Forearm.R",Vector3(-1.25,0,0))
		animator.pose_bone("UpperArm.L",Vector3(-0.25,0,-0.95))
		animator.pose_bone("Forearm.L",Vector3(-0.7,0,0))
		animator.pose_bone("Thigh.R",Vector3(-0.85,0,0))
		animator.pose_bone("Shin.R",Vector3(1.30,0,0))
		animator.pose_bone("Foot.R",Vector3(-0.4,0,0))
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/characters-v09-bend.png")
	for animator in actors:
		animator.play("water")
		animator.animate(0.55,false,false)
		var basis:=animator.root.global_transform.basis.inverse()*animator.can.global_transform.basis
		assert(basis.y.normalized().dot(Vector3.UP)>0.8,"Watering vessel must remain upright")
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/characters-v09-water.png")
	actors[1].play("collect")
	actors[1].animate(1.2,false,false)
	assert(actors[1].carried_egg.visible)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/characters-v09-collect.png")
	for animator in actors: animator.root.visible=false
	var world:=FarmWorld.new()
	for i in range(3):
		var hen:Node3D=load("res://assets/models/chicken.glb").instantiate()
		scene.add_child(hen)
		hen.position.x=(i-1)*0.95
		hen.rotation.y=-0.5 if i==0 else (0.7 if i==1 else 2.5)
		world._color_hen(hen,i)
		assert(hen.find_child("LegL",true,false)!=null)
	camera.position=Vector3(2.0,1.55,4.9)
	camera.look_at(Vector3(0,.5,0))
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/chickens-v09.png")
	for orphan in [world.structures,world.border,world.build_grid,world.selection]: orphan.free()
	world.free()
	print("CHARACTER_RENDER_OK: three skinned GLBs, 20 bones each, front/angle/bent joints, upright watering can, collection pose and Blink")
	quit()
