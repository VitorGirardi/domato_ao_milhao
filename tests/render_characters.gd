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
	for i in range(2):
		var model_name:="farmer" if i==0 else "helper"
		var packed:PackedScene=load("res://assets/models/%s.glb"%model_name)
		var actor:Node3D=packed.instantiate()
		FarmAvatar.prepare_model(actor)
		actor.position.x=-0.95 if i==0 else 0.95
		scene.add_child(actor)
		for part in ["LegL","LegR","ArmL","ArmR","Body","Head"]: assert(actor.find_child(part,true,false)!=null)
	var camera:=Camera3D.new()
	camera.position=Vector3(0,1.65,6.8)
	camera.fov=31
	scene.add_child(camera)
	camera.look_at(Vector3(0,1.25,0))
	camera.current=true
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/characters-v07-front.png")
	camera.position=Vector3(3.1,2.0,6.1)
	camera.look_at(Vector3(0,1.3,0))
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/characters-v07-angle.png")
	print("CHARACTER_RENDER_OK: two GLBs, twelve articulation groups, front and angle previews")
	quit()
