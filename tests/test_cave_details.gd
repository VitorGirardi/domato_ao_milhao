extends SceneTree
## Asset contract and screenshots only. Never instantiates the game or saves.
var meshes:=0
var vertices:=0
func _initialize() -> void:call_deferred("run")

func bounds(node:Node,transform:Transform3D=Transform3D.IDENTITY) -> AABB:
	var result:=AABB();var has_bounds:=false
	if node is Node3D:transform=transform*node.transform
	assert(not node is CollisionObject3D and not node is Camera3D and not node is Light3D,"Props must contain geometry only")
	if node is MeshInstance3D:
		assert(node.mesh!=null)
		meshes+=1
		for surface in node.mesh.get_surface_count():
			vertices+=node.mesh.surface_get_array_len(surface)
			assert(node.mesh.surface_get_material(surface)!=null)
		result=transform*node.mesh.get_aabb();has_bounds=true
	for child in node.get_children():
		var box:=bounds(child,transform)
		if box.size.length_squared()==0:continue
		result=result.merge(box) if has_bounds else box;has_bounds=true
	return result

func run() -> void:
	root.size=Vector2i(1440,900)
	var preview=load("res://art/previews/cave_gallery.tscn").instantiate()
	for key in preview.ASSETS:
		var prop:Node3D=load("res://assets/models/cave_detail_%s.glb"%key).instantiate()
		var box:=bounds(prop)
		assert(box.size.is_finite() and box.size.x>.05 and box.size.y>.05 and box.size.z>.01)
		if key in ["stalactites","roots"]:assert(absf(box.end.y)<.08,"Hanging origin must be at the top: "+key)
		else:assert(absf(box.position.y)<.08,"Ground origin must be at the bottom: "+key)
		if key=="wall":assert(box.size.x>=7.9 and box.size.y>=4.9 and box.size.z<1.5)
		if key=="support":assert(box.size.x>=6.5 and box.size.y>=5.0)
		print("CAVE_ASSET ",key," ",box)
		prop.free()
	assert(vertices<150000,"Decoration pack vertex budget")
	root.add_child(preview)
	DirAccess.make_dir_recursive_absolute("res://test-results/cave-details")
	for index in 3:
		preview.select_gallery(index)
		for i in 4:await process_frame
		assert(preview.rooms[index].visible)
		for other in 3:
			if other!=index:assert(not preview.rooms[other].visible)
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://test-results/cave-details/"+["copper","iron","crystals"][index]+".png")
	preview.queue_free();await process_frame
	print("CAVE_DETAILS_OK: nine Blender props, three isolated galleries; meshes=",meshes," vertices=",vertices)
	quit()
