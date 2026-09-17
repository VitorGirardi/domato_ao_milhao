extends SceneTree

func _initialize() -> void:
	call_deferred("review")

func review() -> void:
	root.size=Vector2i(1200,800)
	var state:=FarmState.new()
	state.claim(Vector2.ZERO)
	state.money=5000
	assert(state.place("workshop",Vector2.ZERO,0).is_empty())
	assert(state.place("coop",Vector2(-8,0),0).is_empty())
	assert(state.place("plot",Vector2(6,0),0).is_empty())
	for entry in [[Vector2(6,2),0],[Vector2(8,0),1],[Vector2(6,-2),0],[Vector2(4,0),1]]:
		assert(state.place("fence",entry[0],entry[1]).is_empty())
	state.hire_staff(1)
	var world:=FarmWorld.new()
	root.add_child(world)
	world.rebuild(state)
	var start:=world.staff_root.position
	assert(state.configure_irrigation([2]).is_empty())
	var cash:=state.money
	world.update_staff(state,0.1)
	assert(state.staff.paused and not state.items[2].watered and state.money==cash,"Blocked garden cannot charge")
	assert(world.staff_root.position==start,"Switching routines keeps Zeca in place")
	var camera:=Camera3D.new()
	world.add_child(camera)
	camera.position=Vector3(5,3.5,7)
	camera.look_at(Vector3(0,1.15,0))
	camera.current=true
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/workshop-building-v010.png")
	print("WORKSHOP_RENDER_OK: building, blocked irrigation has no charge, no teleport on routine switch")
	quit()
