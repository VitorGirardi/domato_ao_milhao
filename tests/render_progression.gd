extends SceneTree
func _initialize() -> void:
	call_deferred("review")
func review() -> void:
	root.size=Vector2i(1200,800)
	var state:=FarmState.new()
	state.claim(Vector2.ZERO)
	state.money=10000
	for data in [["barn",Vector2(-7,-5)],["coop",Vector2(5,-5)],["workshop",Vector2(0,5)]]:
		assert(state.place(data[0],data[1],0).is_empty())
	var world:=FarmWorld.new()
	root.add_child(world)
	var camera:=Camera3D.new()
	world.add_child(camera)
	camera.current=true
	for level in [1,2]:
		if level==2:
			for i in range(3): assert(state.upgrade_building(i).is_empty())
		world.rebuild(state)
		assert(world.chickens.size()==(3 if level==1 else 6))
		for i in range(3):
			var item:Dictionary=state.items[i]
			var at:=Vector3(item.x,0,item.z)
			var offset:=Vector3(7,4.4,9) if i==0 else Vector3(-5,3.6,7)
			camera.position=at+offset
			camera.look_at(at+Vector3.UP*(1.8 if i==0 else 1.3))
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://test-results/%s-level%d-v011.png"%[item.kind,level])
	print("PROGRESSION_RENDER_OK: three buildings in two levels, six visible hens")
	quit()
