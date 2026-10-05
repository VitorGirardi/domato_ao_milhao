extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var gallery:Node3D=load("res://art/previews/houses_gallery.tscn").instantiate()
	root.add_child(gallery);await process_frame
	assert(gallery.houses.size()==2)
	for house in gallery.houses:
		var meshes:Array=house.find_children("*","MeshInstance3D",true,false)
		assert(meshes.size()>15)
		var bounds:=AABB();var first:=true;var vertices:=0
		for instance in meshes:
			var box:AABB=(house.global_transform.affine_inverse()*instance.global_transform)*instance.get_aabb()
			bounds=box if first else bounds.merge(box);first=false
			for surface in instance.mesh.get_surface_count():vertices+=instance.mesh.surface_get_array_len(surface)
		assert(absf(bounds.position.y)<.03,"Ground pivot must be at zero")
		assert(bounds.size.x<=8.1 and bounds.size.z<=8.1 and bounds.size.y<7)
		assert(bounds.position.x>=-4 and bounds.end.x<=4)
		assert(bounds.position.z>=-3.6 and bounds.end.z<=4.4,"Both stages fit the same grid after Z=-0.4 visual offset")
		assert(vertices<80000)
		print("HOUSE_ASSET ",house.name," bounds=",bounds," vertices=",vertices)
	for index in [2,0,1]:
		gallery.select_view(index)
		assert(gallery.islands[0].visible==(index in [0,2]))
		assert(gallery.islands[1].visible==(index in [1,2]))
		if DisplayServer.get_name()!="headless":
			await process_frame;await process_frame;await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://art/previews/house_%s.png"%["starter","upgrade","comparison"][index])
	gallery.toggle_light();assert(gallery.dusk)
	if DisplayServer.get_name()!="headless":
		await process_frame;await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://art/previews/house_evening.png")
	gallery.queue_free();await process_frame
	print("HOUSE_ART_OK: both models, dimensions, ground pivots and isolated preview")
	quit()
