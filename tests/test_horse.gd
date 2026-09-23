extends SceneTree
func _initialize() -> void:
	var state:=FarmState.new();state.claim(Vector2(4,-2));state.horse={"x":160.0,"z":-20.0,"angle":1.5}
	var restored:=FarmState.new();assert(restored.restore(JSON.parse_string(JSON.stringify(state.serialize()))))
	assert(restored.horse==state.horse)
	var before:=restored.serialize()
	for bad in [null,{}, {"x":"160","z":0,"angle":0}, {"x":999,"z":0,"angle":0}, {"x":0,"z":0,"angle":NAN}]:
		var data:=before.duplicate(true);data.horse=bad
		assert(not restored.restore(data) and restored.serialize()==before)
	var old:=before.duplicate(true);old.version=15;old.erase("horse")
	assert(restored.restore(old) and restored.horse==FarmHorse.defaults())
	var extension:=old.duplicate(true);extension.armory={"version":1,"ammo":17,"owned":["pistol"]}
	assert(restored.restore(extension) and restored.serialize().armory==extension.armory)
	var horse:=FarmHorse.new();horse.mounted=true
	assert(horse.encourage() and horse.stamina==75 and horse.burst==3.5)
	assert(not horse.encourage())
	horse.pat_time=0;horse.stamina=24
	assert(not horse.encourage())
	horse.mounted=false;horse.position=Vector3(FarmHorse.HOME.x,0,FarmHorse.HOME.y)
	var scenery:=FarmLandscape.new()
	state.items.append({"kind":"barn","x":FarmHorse.HOME.x,"z":FarmHorse.HOME.y,"turn":0})
	horse.ensure_parking(state,scenery)
	assert(Vector2(horse.position.x,horse.position.z).distance_to(FarmHorse.HOME)>2)
	assert(horse.parking_clear(Vector2(horse.position.x,horse.position.z),state,scenery))
	scenery.meadow.free();scenery.nature.free();scenery.free()
	horse.obstacle.free();horse.shape_node.free();horse.label.free();horse.free()
	assert((FarmLandscape.WALK_MAX-FarmLandscape.WALK_MIN).x*(FarmLandscape.WALK_MAX-FarmLandscape.WALK_MIN).y>60000)
	print("HORSE_STATE_OK: atomic malformed save rejection, legacy migration, limited boost and expanded area")
	quit()
