extends SceneTree

func _farm(mode:String="survival") -> FarmState:
	var farm:=FarmState.new_farm(mode)
	assert(farm.claim(Vector2(4,-2)).is_empty())
	farm.farm_xp=30 # Productive trees unlock at farm level 2.
	assert(farm.place("orchard",Vector2(4,-2),0).is_empty())
	return farm

func _initialize() -> void:
	var farm:=_farm()
	assert(farm.money==1100)
	assert(farm.item_rect("orchard",Vector2.ZERO,0).size==Vector2(4,4))
	assert(farm.ITEMS.orchard_young.size==Vector2(2,2))
	assert(farm.ITEMS.orchard_mature.decorative)
	var before:=farm.serialize()
	assert(not FarmOrchard.harvest(farm,0).is_empty())
	assert(not FarmOrchard.water(farm,-1).is_empty())
	assert(farm.serialize()==before)
	farm.tick(1000)
	assert(farm.items[0].orchard==FarmOrchard.fresh_item())
	assert(FarmOrchard.water(farm,0).is_empty())
	farm.tick(180)
	assert(farm.items[0].orchard.growth==180 and farm.items[0].orchard.ready==0)
	farm.tick(120)
	assert(FarmOrchard.harvest(farm,0).is_empty())
	assert(farm.inventory.orange==6 and farm.orchard_journey.harvested==0)
	assert(FarmOrchard.accept(farm).is_empty())
	assert(not FarmOrchard.deliver(farm).is_empty()) # Previous harvest is not the mission.
	assert(FarmOrchard.water(farm,0).is_empty())
	farm.tick(120)
	assert(FarmOrchard.harvest(farm,0).is_empty())
	assert(farm.orchard_journey.harvested==6)
	var money:=farm.money
	var xp:=farm.farm_xp
	assert(FarmOrchard.deliver(farm).is_empty())
	assert(farm.money==money+220 and farm.farm_xp==xp+30 and farm.trade.nena.reputation==1)
	assert(farm.inventory.orange==6)
	before=farm.serialize()
	assert(not FarmOrchard.deliver(farm).is_empty())
	assert(not FarmOrchard.accept(farm).is_empty())
	assert(farm.serialize()==before)
	assert(farm.sell_all()==96 and farm.inventory.orange==0)
	# Time-step invariance including the adulthood boundary.
	var large:=_farm()
	var small:=_farm()
	FarmOrchard.water(large,0);FarmOrchard.water(small,0)
	large.tick(250)
	for i in range(1000):small.tick(0.25)
	assert(large.items[0].orchard==small.items[0].orchard)
	var loaded:=FarmState.new()
	assert(loaded.restore(JSON.parse_string(JSON.stringify(large.serialize()))))
	assert(loaded.items[0].orchard==large.items[0].orchard)
	loaded.tick(50)
	assert(loaded.items[0].orchard.ready==6)
	# Old saves remain untouched and gain empty orange stock and mission.
	var legacy:=_farm().serialize()
	legacy.version=22;legacy.items=[];legacy.inventory.erase("orange");legacy.erase("orchard_journey")
	var legacy_copy:=legacy.duplicate(true)
	assert(loaded.restore(legacy))
	assert(loaded.inventory.orange==0 and loaded.orchard_journey==FarmOrchard.fresh_journey())
	assert(legacy==legacy_copy)
	# Every rejected restoration is atomic.
	for bad in [null,{},[],{"stage":2,"harvested":0},{"stage":1.5,"harvested":0},{"stage":0,"harvested":6},{"stage":1,"harvested":INF},{"stage":1,"harvested":7}]:
		var invalid:=large.serialize()
		invalid.orchard_journey=bad
		before=loaded.serialize()
		assert(not loaded.restore(invalid))
		assert(loaded.serialize()==before)
	for field in ["growth","watered","ready","fruit_time"]:
		for value in [null,"bad",INF,NAN,-1,9999]:
			var invalid:=large.serialize()
			invalid.items[0].orchard[field]=value
			before=loaded.serialize()
			assert(not loaded.restore(invalid))
			assert(loaded.serialize()==before)
	for bad in [null,[],{}, {"carrot":0,"wheat":0,"corn":0,"egg":0}, {"carrot":0,"wheat":0,"corn":0,"egg":0,"orange":1.5}]:
		var invalid:=large.serialize();invalid.inventory=bad
		assert(not loaded.restore(invalid))
	# Sandbox virtual stock never bypasses the actual harvest objective.
	var sandbox:=_farm("sandbox")
	assert(sandbox.stock("orange")==1000000000 and sandbox.inventory.orange==0)
	assert(FarmOrchard.accept(sandbox).is_empty())
	assert(not FarmOrchard.deliver(sandbox).is_empty())
	FarmOrchard.water(sandbox,0);sandbox.tick(300)
	assert(FarmOrchard.harvest(sandbox,0).is_empty())
	assert(FarmOrchard.deliver(sandbox).is_empty())
	assert(sandbox.inventory.orange==6 and sandbox.orchard_journey.stage==2)
	assert(loaded.restore(sandbox.serialize()) and loaded.infinite_resources())
	# A full physical counter must never make the next save invalid, in either mode.
	for mode in ["survival","sandbox"]:
		var full:=_farm(mode)
		FarmOrchard.accept(full);FarmOrchard.water(full,0);full.tick(300)
		full.inventory.orange=1000000000-5
		before=full.serialize()
		assert(not FarmOrchard.harvest(full,0).is_empty())
		assert(full.serialize()==before) # Fruit, mission, XP and counters remain intact.
		assert(loaded.restore(full.serialize()))
		full.inventory.orange-=1
		assert(FarmOrchard.harvest(full,0).is_empty())
		assert(full.inventory.orange==1000000000 and full.orchard_journey.harvested==6)
		assert(loaded.restore(full.serialize()))
	print("ORCHARD_OK: growth, watering, harvest, mission, migration, atomic validation and modes")
	quit()
