extends SceneTree
func _initialize() -> void:
	var state:=FarmState.new();state.claim(Vector2(4,-2));state.money=2000
	assert(FarmLevels.required("stable")==5)
	assert(not state.place("stable",Vector2(2,-4),0).is_empty())
	state.farm_xp=550
	assert(state.place("stable",Vector2(2,-4),0).is_empty() and state.money==1450)
	var entry:=FarmStable.entrance(state.items[0])
	assert(entry.distance_to(Vector2(2,1.2))<.001)
	assert(FarmStable.nearby(state,entry)==0 and FarmStable.nearby(state,Vector2(70,70))==-1)
	assert(state.move_item(0,Vector2(2,-4),1).is_empty())
	assert(FarmStable.entrance(state.items[0]).distance_to(Vector2(7.2,-4))<.001)
	assert(state.paint_item(0,"walls",1).is_empty() and state.items[0].paint==1)
	var restored:=FarmState.new();assert(restored.restore(JSON.parse_string(JSON.stringify(state.serialize()))))
	assert(restored.items[0].kind=="stable" and restored.serialize().version==17)
	var old:=state.serialize();old.version=16;old.items=[]
	assert(restored.restore(old) and restored.items.is_empty())
	var bad:=old.duplicate(true);bad.version=18;var before:=restored.serialize()
	assert(not restored.restore(bad) and restored.serialize()==before)
	print("STABLE_STATE_OK: level gate, finite cost, rotated entrance, move, save17 and legacy16")
	quit()
