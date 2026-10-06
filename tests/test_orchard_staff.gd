extends SceneTree

func fixture(mode:String="survival") -> FarmState:
	var state:=FarmState.new_farm(mode)
	state.claim(Vector2(4,-2));state.farm_xp=30
	assert(state.place("orchard",Vector2(4,-2),0).is_empty())
	assert(state.place("coop",Vector2(-2,-2),0).is_empty())
	return state

func _initialize() -> void:
	var state:=fixture()
	var before:=state.serialize()
	assert(not FarmOrchardStaff.configure(state,[0]).is_empty())
	assert(state.serialize()==before)
	state.orchard_journey={"stage":2,"harvested":6}
	var money:=state.money
	assert(FarmOrchardStaff.configure(state,[0]).is_empty())
	assert(state.money==money-120 and state.staff.hired and state.staff.paused)
	assert(FarmOrchardStaff.job(state,0)=="water")
	money=state.money
	assert(FarmOrchardStaff.complete(state,0,"water").is_empty())
	assert(state.money==money-2 and state.orchard_staff.services==1)
	before=state.serialize()
	assert(not FarmOrchardStaff.complete(state,0,"water").is_empty())
	assert(state.serialize()==before)
	state.tick(300)
	state.inventory.orange=999999999
	before=state.serialize()
	assert(not FarmOrchardStaff.complete(state,0,"harvest").is_empty())
	assert(state.serialize()==before)
	state.inventory.orange=0;state.money=0
	assert(not FarmOrchardStaff.complete(state,0,"harvest").is_empty())
	assert(state.orchard_staff.paused and state.orchard_staff.reason=="funds" and state.items[0].orchard.ready==6)
	state.money=50;state.staff.level=2
	assert(FarmOrchardStaff.pause(state).is_empty())
	assert(FarmOrchardStaff.complete(state,0,"harvest").is_empty())
	assert(state.money==49 and state.inventory.orange==6 and state.orchard_staff.spent==3)
	var loaded:=FarmState.new()
	assert(loaded.restore(JSON.parse_string(JSON.stringify(state.serialize()))))
	assert(loaded.orchard_staff==state.orchard_staff)
	before=state.serialize()
	assert(not state.assign_staff(0).is_empty())
	assert(before==state.serialize())
	assert(state.assign_staff(1).is_empty())
	assert(not state.orchard_staff.enabled)
	assert(state.pause_staff().is_empty() and not state.staff.paused)
	assert(FarmOrchardStaff.configure(state,[0]).is_empty() and state.staff.paused)
	assert(state.remove_item(0).is_empty())
	assert(state.orchard_staff.trees.is_empty() and state.orchard_staff.reason=="removed")
	assert(loaded.restore(state.serialize()))
	state.dismiss_staff()
	assert(not state.orchard_staff.enabled and not state.staff.hired)
	assert(loaded.restore(state.serialize()))
	var old:=state.serialize();old.version=24;old.erase("orchard_staff")
	assert(loaded.restore(old) and loaded.orchard_staff==FarmOrchardStaff.fresh())
	for mode in ["sandbox","survival"]:
		var farm:=fixture(mode)
		farm.orchard_journey={"stage":2,"harvested":6}
		assert(FarmOrchardStaff.configure(farm,[0]).is_empty())
		for bad in [null,{}, {"enabled":true,"paused":false,"trees":[0,0],"services":0,"oranges":0,"spent":0,"reason":""}]:
			var invalid:=farm.serialize();invalid.orchard_staff=bad
			before=loaded.serialize()
			assert(not loaded.restore(invalid) and loaded.serialize()==before)
		var invalid:=farm.serialize();invalid.staff.paused=false;invalid.staff.coop=1
		assert(not loaded.restore(invalid))
		for field in ["services","oranges","spent"]:
			for value in [-1,INF,NAN,1.5,"bad",true]:
				invalid=farm.serialize();invalid.orchard_staff[field]=value
				before=loaded.serialize()
				assert(not loaded.restore(invalid) and loaded.serialize()==before)
		for field in ["field_staff","irrigation"]:
			invalid=farm.serialize();invalid[field]=null
			assert(not loaded.restore(invalid))
	# Remove an earlier unrelated item and remap all selected tree indices.
	var remap:=fixture("sandbox")
	assert(remap.place("orchard",Vector2(10,-2),0).is_empty())
	assert(FarmOrchardStaff.configure(remap,[0,2]).is_empty())
	assert(remap.remove_item(1).is_empty())
	assert(remap.orchard_staff.trees==[0,1] and FarmOrchardStaff.active(remap))
	assert(loaded.restore(remap.serialize()))
	# Legacy irrigation switches Zeca's job, while Bento remains independent.
	var irrigation:=fixture("sandbox")
	assert(irrigation.place("plot",Vector2(10,-2),0).is_empty())
	assert(FarmOrchardStaff.configure(irrigation,[0]).is_empty())
	assert(irrigation.assign_staff(1).is_empty())
	assert(FarmOrchardStaff.configure(irrigation,[0]).is_empty())
	assert(irrigation.configure_irrigation([2]).is_empty())
	assert(not irrigation.orchard_staff.enabled)
	irrigation.hire_field_staff()
	assert(FarmOrchardStaff.configure(irrigation,[0]).is_empty())
	assert(irrigation.configure_irrigation([2]).is_empty())
	assert(irrigation.orchard_staff.enabled and irrigation.irrigation.enabled)
	assert(loaded.restore(irrigation.serialize()))
	var sandbox:=fixture("sandbox")
	assert(FarmOrchardStaff.configure(sandbox,[0]).is_empty())
	assert(FarmOrchardStaff.complete(sandbox,0,"water").is_empty())
	assert(sandbox.orchard_staff.spent==0 and sandbox.staff.spent==0)
	_test_rosa_save26()
	print("ORCHARD_STAFF_OK")
	quit()

func _test_rosa_save26() -> void:
	# Rosa 0.53 wrote version 26 without orchard_staff. Upgrade that real schema,
	# retaining a story in progress, an independent resident order and the truck.
	for mode in ["survival","sandbox"]:
		var old_farm:=fixture(mode)
		assert(FarmResidents.act(old_farm,"rosa","meet").is_empty())
		assert(FarmResidents.act(old_farm,"rosa","accept").is_empty())
		old_farm.pickup.cargo=FarmResidents.order(old_farm,"rosa").duplicate()
		assert(FarmResidents.act(old_farm,"rosa","deliver").is_empty())
		old_farm.elapsed+=FarmResidents.COOLDOWN
		assert(FarmResidents.act(old_farm,"rosa","accept").is_empty())
		for stage in range(2):
			assert(FarmRosa.act(old_farm,"story_accept").is_empty())
			old_farm.pickup.cargo=FarmRosa.step(old_farm).cargo.duplicate()
			assert(FarmRosa.act(old_farm,"story_deliver").is_empty())
		assert(FarmRosa.act(old_farm,"story_accept").is_empty())
		old_farm.pickup.garage={"name":"Pomar da Rosa","paint":2,"bed":true,"tires":true,"engine":true,"rack":true}
		old_farm.pickup.x=10.0;old_farm.pickup.z=2.0;old_farm.pickup.angle=.7
		old_farm.pickup.cargo={"orange":33,"quartz":2}
		old_farm.orchard_journey={"stage":2,"harvested":6}
		var previous:=old_farm.serialize()
		previous.version=26;previous.erase("orchard_staff")
		var previous_bytes:=JSON.stringify(previous)
		var upgraded:=FarmState.new()
		assert(upgraded.restore(JSON.parse_string(previous_bytes)))
		assert(JSON.stringify(previous)==previous_bytes)
		assert(upgraded.orchard_staff==FarmOrchardStaff.fresh())
		assert(upgraded.rosa_story.stage==2 and upgraded.rosa_story.active)
		assert(upgraded.residents.rosa.done==1 and upgraded.residents.rosa.active)
		assert(JSON.stringify(upgraded.residents)==JSON.stringify(old_farm.residents))
		assert(upgraded.pickup==JSON.parse_string(JSON.stringify(old_farm.pickup)))
		assert(upgraded.game_mode==mode and upgraded.infinite_resources()==(mode=="sandbox"))
		assert(upgraded._money==old_farm._money and upgraded.revenue==old_farm.revenue)
		assert(FarmGarage.capacity(upgraded)==120)
		assert(FarmOrchardStaff.configure(upgraded,[0]).is_empty())
		assert(FarmOrchardStaff.complete(upgraded,0,"water").is_empty())
		var saved:=upgraded.serialize()
		assert(saved.version==FarmState.SAVE_VERSION and saved.orchard_staff.enabled)
		var reloaded:=FarmState.new()
		assert(reloaded.restore(JSON.parse_string(JSON.stringify(saved))))
		assert(reloaded.orchard_staff==upgraded.orchard_staff)
		assert(reloaded.rosa_story==upgraded.rosa_story)
		assert(reloaded.residents==upgraded.residents)
		assert(JSON.stringify(reloaded.pickup)==JSON.stringify(upgraded.pickup))
		assert(reloaded.items[0].orchard.watered and FarmOrchardStaff.active(reloaded))
		assert(reloaded.stock("orange")== (1000000000 if mode=="sandbox" else 0))
		# Both progressions remain functional after the current-version round trip.
		reloaded.pickup.cargo=FarmRosa.step(reloaded).cargo.duplicate()
		assert(FarmRosa.act(reloaded,"story_deliver").is_empty())
		reloaded.tick(300)
		assert(FarmOrchardStaff.complete(reloaded,0,"harvest").is_empty())
		assert(reloaded.rosa_story.stage==3 and reloaded.orchard_staff.oranges==6)
		var invalid:=saved.duplicate(true);invalid.erase("orchard_staff")
		var before:=reloaded.serialize()
		assert(not reloaded.restore(invalid) and reloaded.serialize()==before)
