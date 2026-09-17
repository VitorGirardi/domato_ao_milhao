extends SceneTree
## Actual farm routine, rendered without loading or writing player saves.
func _initialize() -> void:
	call_deferred("preview")

func preview() -> void:
	root.size=Vector2i(960,640)
	var state:=FarmState.new()
	state.claim(Vector2.ZERO)
	state.place("coop",Vector2.ZERO,0)
	state.items[0].flock.nest=6
	state.hire_staff(0)
	var world:=FarmWorld.new()
	root.add_child(world)
	world.rebuild(state)
	var camera:=Camera3D.new()
	world.add_child(camera)
	camera.fov=50
	camera.position=Vector3(7,3.7,4.8)
	camera.look_at(Vector3(0,1,1.0))
	camera.current=true
	var start:=world.staff_root.position
	var travelled:=0.0
	var saw_egg:=false
	DirAccess.make_dir_recursive_absolute("res://test-results/staff-motion")
	for frame in range(190):
		for step in range(6):
			state.tick(1.0/60)
			world.update_animals(state)
			world.update_staff(state,1.0/60)
			world.animate(1.0/60,Vector3(10,0,10),state)
		travelled+=world.staff_root.position.distance_to(start)
		start=world.staff_root.position
		assert(world.staff_motion.walkable(start,state))
		saw_egg=saw_egg or world.staff_actor.carried_egg.visible
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://test-results/staff-motion/frame-%03d.png"%frame)
	assert(travelled>4 and saw_egg and state.inventory.egg==6 and state.staff.services==1)
	state.staff.paused=true
	var stopped:=world.staff_root.position
	var ledger:=state.staff.duplicate(true)
	world.update_staff(state,0.1)
	assert(stopped==world.staff_root.position and ledger==state.staff)
	# Merchant is an independent GLB with a facial morph, not the player model.
	assert(world.vendor_actor.root.scene_file_path.ends_with("vendor.glb"))
	camera.position=Vector3(-20,2.3,12.4)
	camera.look_at(Vector3(-24.5,1.45,14))
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/vendor-v09.png")
	print("STAFF_MOTION_OK: route, collision clearance, collect gesture, visible egg, one payment, pause, separate merchant")
	quit()
