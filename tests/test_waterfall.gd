extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var world:=Node3D.new();root.add_child(world)
	var environment:=WorldEnvironment.new();var env:=Environment.new();env.background_mode=Environment.BG_COLOR;env.background_color=Color(.48,.72,.89);env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color(.75,.83,.9);env.ambient_light_energy=.7;environment.environment=env;world.add_child(environment)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-40,-30,0);sun.light_energy=1.2;world.add_child(sun)
	var fall:=FarmWaterfall.new();world.add_child(fall);fall.setup();fall.position=Vector3.ZERO
	var camera:=Camera3D.new();world.add_child(camera);camera.position=Vector3(23,17,34);camera.look_at(Vector3(0,7,-2));camera.current=true
	assert(fall.get_node("MovingWater").mesh.get_surface_count()==1)
	var stream:AudioStreamWAV=fall.get_node("WaterRush").stream
	assert(stream.mix_rate==32000 and stream.get_length()>10)
	assert(stream.loop_mode==AudioStreamWAV.LOOP_FORWARD)
	assert(stream.loop_end==roundi(stream.get_length()*stream.mix_rate))
	assert(not stream.data.is_empty()) # Imported data may be QOA-compressed, not raw PCM.
	await physics_frame
	var ray:=PhysicsRayQueryParameters3D.create(Vector3(-6,8,12),Vector3(-6,8,-12))
	assert(not world.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(),"Cliff rocks must collide")
	# Solid capsule sweeps exercise both sides at swimming and climbing heights.
	var swimmer:=CharacterBody3D.new();var capsule:=CapsuleShape3D.new();capsule.radius=.35;capsule.height=1.65
	var collider:=CollisionShape3D.new();collider.shape=capsule;swimmer.add_child(collider);world.add_child(swimmer)
	await physics_frame
	for height in [-.5,4.0,8.0,12.0]:
		var wall_z:float=1.0-height*.52
		for side in [-1.0,1.0]:
			swimmer.position=Vector3(side*16,height,wall_z)
			var hit:=swimmer.move_and_collide(Vector3(-side*16,0,0))
			assert(hit!=null,"Capsule entered through side rock at height "+str(height))
			assert(absf(swimmer.position.x)>4.9,"Side hull must stop actor before the hidden interior")
	swimmer.position=Vector3(0,-.5,10)
	assert(swimmer.move_and_collide(Vector3(0,0,-15))!=null,"Closed wall must back the underwater curtain")
	swimmer.position=Vector3(-4,-.5,8)
	assert(swimmer.move_and_collide(Vector3(8,0,0))==null,"Swimming across the plunge pool must remain free")
	swimmer.queue_free()
	# Preview surface has the same level as the lake; geometry ends below it.
	var pool:=MeshInstance3D.new();var surface:=PlaneMesh.new();surface.size=Vector2(80,65);pool.mesh=surface
	var water:=StandardMaterial3D.new();water.albedo_color=Color(.045,.30,.44);water.roughness=.3;pool.material_override=water;world.add_child(pool);pool.position=Vector3(0,0,18)
	if DisplayServer.get_name()!="headless":
		await create_timer(1).timeout;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://test-results/waterfall-godot.png")
		await create_timer(.8).timeout;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://test-results/waterfall-godot-motion.png")
	fall.get_node("WaterRush").stop();world.queue_free();await process_frame;await create_timer(.2).timeout
	print("WATERFALL_OK: solid side capsules, sealed underwater wall, free plunge pool, submerged sheet, foam and looping sound")
	quit()
