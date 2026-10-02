extends SceneTree

func _initialize() -> void:
	# Sample the interpolated render/collision surface, not just analytical terrain.
	for ix in range(185):
		for iz in range(33):
			var p:=Vector2(397+ix*.25,-4+iz*.25)
			var ceiling:=5.001 if ix in [0,184] else 4.681
			assert(FarmLandscape.ground_height(p)<=ceiling,"Ground intersects bridge plank: %s"%p)
	assert(is_equal_approx(FarmLandscape.ground_height(Vector2(397,0)),5))
	assert(is_equal_approx(FarmLandscape.ground_height(Vector2(443,0)),5))
	for x in [397.01,400.0,420.0,442.99]:
		assert(FarmLandscape.height_at(Vector2(x,0))==5)
		assert(not FarmRegion.water_blocked(Vector2(x,0)))
	print("BRIDGE_CLEARANCE_OK: terrain stays below all planks and walking deck stays at y=5")
	quit()
