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
	print("ORCHARD_STAFF_OK")
	quit()
