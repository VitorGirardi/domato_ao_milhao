extends SceneTree
func _initialize() -> void:call_deferred("run")
func bounds(node:Node3D) -> AABB:
	var result:=AABB()
	var meshes:=node.find_children("*","MeshInstance3D",true,false)
	for mesh in meshes:
		var box:AABB=mesh.global_transform*mesh.get_aabb()
		result=result.merge(box) if result.size!=Vector3.ZERO else box
	return result
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/ui/build")
	var viewport:=SubViewport.new();viewport.size=Vector2i(256,256);viewport.transparent_bg=true;viewport.own_world_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
	var world:=Node3D.new();viewport.add_child(world)
	var env:=WorldEnvironment.new();env.environment=Environment.new();env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color("ffefd2");env.environment.ambient_light_energy=0.8;world.add_child(env)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-40,-30,0);sun.light_energy=1.1;world.add_child(sun)
	var camera:=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;world.add_child(camera);camera.current=true
	for key in ["pigsty","barn","coop","workshop","corral","cheesery","stable","fence","sign"]:
		var model:Node3D=load("res://assets/models/%s.glb"%key).instantiate();world.add_child(model)
		await process_frame
		var box:=bounds(model);var center:=box.get_center()
		camera.size=maxf(box.size.y,maxf(box.size.x,box.size.z))*1.52
		camera.position=center+Vector3(9,7,12);camera.look_at(center)
		await process_frame;await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png("res://assets/ui/build/%s.png"%key)
		model.free()
	print("BUILD_THUMBNAILS_OK");quit()
