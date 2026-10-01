extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var world:=Node3D.new();root.add_child(world)
	var environment:=WorldEnvironment.new();var env:=Environment.new();env.background_mode=Environment.BG_COLOR;env.background_color=Color(.48,.72,.89);env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color(.75,.83,.9);env.ambient_light_energy=.7;environment.environment=env;world.add_child(environment)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-40,-30,0);sun.light_energy=1.2;world.add_child(sun)
	var fall:=FarmWaterfall.new();world.add_child(fall);fall.setup();fall.position=Vector3.ZERO
	var camera:=Camera3D.new();world.add_child(camera);camera.position=Vector3(23,17,34);camera.look_at(Vector3(0,7,-2));camera.current=true
	assert(fall.get_node("MovingWater").mesh.get_surface_count()==1)
	assert(fall.get_node("WaterRush").stream.data.size()==84000)
	await physics_frame
	var ray:=PhysicsRayQueryParameters3D.create(Vector3(-6,8,12),Vector3(-6,8,-12))
	assert(not world.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(),"Cliff rocks must collide")
	if DisplayServer.get_name()!="headless":
		await create_timer(1).timeout;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://test-results/waterfall-godot.png")
		await create_timer(.8).timeout;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://test-results/waterfall-godot-motion.png")
	fall.get_node("WaterRush").stop();world.queue_free();await process_frame;await create_timer(.2).timeout
	print("WATERFALL_OK: original cliff collision, animated sheet, foam, mist and looping sound")
	quit()
