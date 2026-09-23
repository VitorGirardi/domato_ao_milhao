extends SceneTree
func _initialize() -> void:
	assert(FarmTrails.shader_segments().size()<=64)
	for route in FarmTrails.ROUTES:
		for i in range(route.size()-1):
			for step in range(101):
				var p:Vector2=route[i].lerp(route[i+1],step/100.0)
				assert(p.x>=FarmLandscape.WALK_MIN.x+2 and p.x<=FarmLandscape.WALK_MAX.x-2)
				assert(p.y>=FarmLandscape.WALK_MIN.y+2 and p.y<=FarmLandscape.WALK_MAX.y-2)
				for key in FarmParcels.LOTS:
					assert(not FarmParcels.area(key).grow(2.4).has_point(p),"Public trail crosses buildable parcel")
	for stop in FarmTrails.STOPS.values():
		var area:=Rect2(stop.at-Vector2.ONE*stop.radius,Vector2.ONE*stop.radius*2)
		assert(not area.intersects(FarmLandscape.CLEAR))
		for key in FarmParcels.LOTS:assert(not area.intersects(FarmParcels.area(key).grow(2)))
		assert(FarmTrails.distance_to_path(stop.at)<float(stop.radius))
	var journey:=FarmTrails.new()
	assert(journey.discover(Vector2(4,-2)).is_empty())
	for stop in FarmTrails.STOPS.values():
		assert(not journey.discover(stop.at).is_empty())
		assert(journey.discover(stop.at).is_empty())
	print("TRAILS_OK: routes keep parcel clearance, stops stay outside buildable areas, discoveries do not repeat")
	quit()
