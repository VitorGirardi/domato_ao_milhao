extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var gallery:Node3D=load("res://art/previews/farm_art_gallery.tscn").instantiate()
	root.add_child(gallery);await process_frame
	assert(gallery.assets.size()==16)
	var report:Array=[]
	for key in gallery.assets:
		var model:Node3D=gallery.assets[key].instantiate();root.add_child(model)
		var meshes:Array=model.find_children("*","MeshInstance3D",true,false)
		assert(not meshes.is_empty(),key)
		var bounds:=AABB();var first:=true;var vertices:=0
		for instance in meshes:
			assert(instance.mesh!=null)
			var box:AABB=(model.global_transform.affine_inverse()*instance.global_transform)*instance.get_aabb()
			bounds=box if first else bounds.merge(box);first=false
			for surface in instance.mesh.get_surface_count():
				vertices+=instance.mesh.surface_get_array_len(surface)
				assert(instance.mesh.surface_get_material(surface)!=null,key)
		assert(bounds.position.is_finite() and bounds.size.is_finite())
		assert(absf(bounds.position.y)<.06,"Ground pivot: "+key)
		assert(bounds.size.x<11 and bounds.size.y<9 and bounds.size.z<11,key)
		assert(vertices>20 and vertices<80000,key)
		if key.begins_with("gate_"):
			var hinges:Array=model.find_children("GateHinge*","Node3D",true,false)
			assert(not hinges.is_empty(),"Gate needs an authored hinge pivot")
		report.append({"asset":key,"meshes":meshes.size(),"vertices":vertices,"size":[bounds.size.x,bounds.size.y,bounds.size.z],"minimum":[bounds.position.x,bounds.position.y,bounds.position.z]})
		model.queue_free()
	var file:=FileAccess.open("res://art/previews/farm_art_manifest.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "));file.close()
	for index in 6:
		gallery.select_view(index)
		for other in 6:assert(gallery.rooms[other].visible==(index==other))
		if DisplayServer.get_name()!="headless":
			await process_frame;await process_frame;await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://art/previews/farm_art_%02d.png"%index)
	gallery.select_view(1);gallery.toggle_light();assert(gallery.dusk)
	if DisplayServer.get_name()!="headless":
		await process_frame;await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://art/previews/farm_art_evening.png")
	gallery.queue_free();await process_frame
	print("FARM_ART_OK: 16 original models, materials, bounds, pivots, gate hinges and six independent art stages")
	quit()
