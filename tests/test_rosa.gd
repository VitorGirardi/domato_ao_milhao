extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var state:=FarmState.new_farm("survival");state.claim(Vector2(4,-2))
	assert(FarmRosa.valid(state.rosa_story) and not FarmLevels.unlocked(state,"rosa_bed"))
	assert(not FarmRosa.act(state,"story_accept").is_empty())
	FarmResidents.act(state,"rosa","meet");FarmResidents.act(state,"rosa","accept")
	var normal:=FarmResidents.order(state,"rosa").duplicate();var original:=state.serialize()
	for stage in range(3):
		assert(FarmRosa.act(state,"story_accept").is_empty())
		var before:=state.serialize();assert(not FarmRosa.act(state,"story_accept").is_empty() and state.serialize()==before)
		var request:Dictionary=FarmRosa.step(state).cargo
		state.pickup.cargo={request.keys()[0]:request.values()[0]};before=state.serialize()
		assert(not FarmRosa.act(state,"story_deliver").is_empty() and state.serialize()==before)
		state.pickup.cargo=request.duplicate();state.pickup.cargo.quartz=2
		var money:=state.money;var pay:int=FarmRosa.step(state).pay
		assert(FarmRosa.act(state,"story_deliver").is_empty())
		assert(state.money==money+pay and state.pickup.cargo=={"quartz":2})
		assert(state.rosa_story.stage==stage+1 and FarmResidents.influence(state)==(stage+1)*5)
		assert(state.residents.rosa.active and FarmResidents.order(state,"rosa")==normal)
		before=state.serialize();assert(not FarmRosa.act(state,"story_deliver").is_empty() and state.serialize()==before)
		var loaded:=FarmState.new();assert(loaded.restore(JSON.parse_string(JSON.stringify(state.serialize()))));assert(loaded.rosa_story==state.rosa_story)
	assert(FarmLevels.unlocked(state,"rosa_bed") and FarmResidents.trust(state,"rosa")=="Amigo da casa")
	assert(state.place("rosa_bed",Vector2(8,6),0).is_empty())
	var saved:=state.serialize();var bad:=saved.duplicate(true);bad.rosa_story.stage=4
	assert(not state.restore(bad) and state.serialize()==saved)
	bad=saved.duplicate(true);bad.rosa_story.active=true;assert(not state.restore(bad) and state.serialize()==saved)
	bad=saved.duplicate(true);bad.residents.rosa=FarmResidents.fresh().rosa;assert(not state.restore(bad) and state.serialize()==saved)
	var old:=original.duplicate(true);old.version=24;old.erase("rosa_story");assert(state.restore(old) and state.rosa_story==FarmRosa.fresh() and state.residents.rosa.active)
	var sandbox:=FarmState.new_farm("sandbox");sandbox.claim(Vector2(4,-2));FarmResidents.act(sandbox,"rosa","meet");FarmRosa.act(sandbox,"story_accept")
	assert(FarmLevels.unlocked(sandbox,"rosa_bed") and not FarmRosa.act(sandbox,"story_deliver").is_empty())
	assert(FarmRosa.routine(0).activity=="Cuidando da horta" and FarmRosa.routine(240).activity=="Descansando na varanda")
	print("ROSA_OK: story atomicity, independent accepted order, trust, influence, unlock, migration and sandbox")
	quit()
