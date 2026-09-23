extends SceneTree
func _initialize() -> void:
	var view:=FarmMapView.new();view.size=Vector2(700,612);view.full=true
	for point in [Vector2.ZERO,FarmLandscape.WALK_MIN,FarmLandscape.WALK_MAX,Vector2(160,-20)]:
		assert(view.unproject(view.project(point)).distance_to(point)<.001)
		assert(Rect2(Vector2.ZERO,view.size).has_point(view.project(point)))
	view.full=false;view.size=Vector2(238,190);view.player_at=Vector2(142,-95)
	assert(view.project(view.player_at).distance_to(view.size/2)<.001)
	assert(view.project(view.player_at+Vector2(0,-10)).y<view.size.y/2)
	view.free()
	var horse_scene:PackedScene=load("res://assets/models/horse.glb")
	var model:=horse_scene.instantiate()
	var skeleton:=model.find_child("Skeleton3D",true,false) as Skeleton3D
	assert(skeleton!=null and skeleton.get_bone_count()==10)
	for key in ["HorseBody","HorseNeck","FrontL","FrontR","HindL","HindR","FrontLLower","FrontRLower","HindLLower","HindRLower"]:
		assert(skeleton.find_bone("Skin"+key)>=0)
		assert(model.find_child(key,true,false)!=null)
	assert(model.find_child("HorseContinuousSkin",true,false)!=null)
	model.free()
	print("NAVIGATION_UNIT_OK: round-trip projection, north, centered minimap and continuous horse rig")
	quit()
