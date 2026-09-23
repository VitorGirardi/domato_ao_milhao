extends SceneTree
func _initialize() -> void:
	# Every valid claim, at its maximum expansion, keeps a flat construction plane.
	for z in range(-38,41):
		for x in range(-32,43):
			assert(is_zero_approx(FarmLandscape.height_at(Vector2(x,z))))
	assert((FarmLandscape.WALK_MAX-FarmLandscape.WALK_MIN).x*(FarmLandscape.WALK_MAX-FarmLandscape.WALK_MIN).y>75*82*2)
	for z in range(-62,67):
		for x in range(-34,71):
			var p:=Vector2(x,z);var h:=FarmLandscape.height_at(p)
			assert(h>=0 and h<4)
			assert(absf(h-FarmLandscape.height_at(p+Vector2(1,0)))<.5)
			assert(absf(h-FarmLandscape.height_at(p+Vector2(0,1)))<.5)
	for z in range(-40,41):assert(FarmLandscape.road_distance(Vector2(-27,z))==0)
	for x in range(-26,43):assert(FarmLandscape.road_distance(Vector2(x,30))==0)
	print("V020_TERRAIN_OK: all legal build coordinates flat; expanded area, gentle slopes, unchanged road positions")
	quit()
