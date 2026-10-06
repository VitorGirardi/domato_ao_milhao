extends SceneTree
func _initialize() -> void:call_deferred("run")
func fixture(mode:String="survival") -> FarmState:
	var s:=FarmState.new_farm(mode);s.money=20000;s.farm_xp=950
	assert(s.claim(Vector2(4,0)).is_empty());s.land_size=40
	for entry in [["coop",Vector2(-6,0)],["corral",Vector2(3,0)],["pigsty",Vector2(13,0)]]:
		assert(s.place(entry[0],entry[1],0).is_empty())
	s.items[1].dairy.owned=true;s.items[2].pigs.count=3
	return s
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	var s:=fixture();var money:=s.money;var saved:=s.serialize()
	for i in range(3):
		assert(not s.items[i].has("animal_care"))
		assert(FarmAnimalCare.care(s,i).is_empty())
		assert(FarmAnimalCare.seconds(s.items[i])==480 and s.items[i].animal_care.visits==1)
		var before:=s.serialize();assert(not FarmAnimalCare.care(s,i).is_empty() and s.serialize()==before)
	assert(s.money==money)
	# Exact first cycles: care speeds only production, not food/water consumption.
	var normal:=fixture()
	s.tick(37.5);normal.tick(37.5)
	assert(s.items[0].flock.nest==2 and normal.items[0].flock.nest==0)
	s.tick(12.5);normal.tick(12.5)
	assert(s.items[1].dairy.milk==2 and normal.items[1].dairy.milk==0)
	for i in range(3):
		assert(is_equal_approx(FarmAnimalCare.needs(s.items[i]).food,FarmAnimalCare.needs(normal.items[i]).food))
		assert(is_equal_approx(FarmAnimalCare.needs(s.items[i]).water,FarmAnimalCare.needs(normal.items[i]).water))
	# Cross expiry and depletion in one step versus 1000 small steps, at both hen capacities.
	for level in [1,2]:
		for i in range(3):
			var a:Dictionary=saved.items[i].duplicate(true)
			if i==0 and level==2:a.flock.names.append_array(["A","B","C"]);a.level=2
			a.animal_care={"seconds":17.25,"visits":2}
			FarmAnimalCare.needs(a).food=7.5;FarmAnimalCare.needs(a).water=8.5
			var b:=a.duplicate(true)
			FarmAnimalCare.tick(a,100)
			for j in range(1000):FarmAnimalCare.tick(b,.1)
			assert(is_equal_approx(FarmAnimalCare.needs(a).food,FarmAnimalCare.needs(b).food))
			assert(is_equal_approx(FarmAnimalCare.needs(a).water,FarmAnimalCare.needs(b).water))
			assert(a.animal_care==b.animal_care)
			if i==0:assert(a.flock.nest==b.flock.nest and is_equal_approx(a.egg_time,b.egg_time))
			if i==1:assert(a.dairy.milk==b.dairy.milk and is_equal_approx(a.dairy.timer,b.dairy.timer))
	assert(is_equal_approx(FarmAnimalCare.production_wait({"animal_care":{"seconds":5}},60),59))
	assert(is_equal_approx(FarmAnimalCare.production_wait({"animal_care":{"seconds":100}},60),50))
	# Save/load never applies wall-clock decay. Old farms acquire no mandatory new fields.
	assert(FarmCoop.save_farm("user://animals.json",s))
	var loaded:=FarmCoop.load_farm("user://animals.json");assert(loaded!=null)
	for i in range(3):assert(loaded.items[i].animal_care==s.items[i].animal_care)
	var old:=saved.duplicate(true);old.version=27;assert(loaded.restore(old))
	for item in loaded.items:assert(not item.has("animal_care"))
	for value in [null,{}, {"seconds":481,"visits":1},{"seconds":NAN,"visits":1},{"seconds":1,"visits":0},{"seconds":0,"visits":1.2},{"seconds":0,"visits":true},{"seconds":0,"visits":-1}]:
		var invalid:=saved.duplicate(true);invalid.items[0].animal_care=value
		var before:=loaded.serialize();assert(not loaded.restore(invalid) and loaded.serialize()==before)
	# Needs, unowned pens, invalid commands and fallen animals cannot grant comfort.
	s=fixture()
	for i in range(3):
		FarmAnimalCare.needs(s.items[i]).water=24.9
		assert(not FarmAnimalCare.care(s,i).is_empty());FarmAnimalCare.needs(s.items[i]).water=100.0
		var species:String=["chicken","cow","pig"][i]
		var key:=FarmFallTargets.item_key(s,i,species,-1 if i==1 else 0)
		s.temporary_down[key]=true;assert(not FarmAnimalCare.care(s,i).is_empty());s.temporary_down.clear()
	assert(not FarmCoopCommands.run(s,{"action":"animal:care","index":-1}).is_empty())
	assert(not FarmCoopCommands.run(s,{"action":"animal:care","index":1.5}).is_empty())
	assert(not FarmCoopCommands.run(s,{"action":"animal:care_cheat","index":0}).is_empty())
	s.items[1].dairy.owned=false;s.items[2].pigs.count=0
	assert(not FarmAnimalCare.care(s,1).is_empty() and not FarmAnimalCare.care(s,2).is_empty())
	# Sandbox and an occupied moved/rotated enclosure retain mode, stock and care.
	s=fixture("sandbox");assert(FarmAnimalCare.care(s,2).is_empty())
	var stock:=s.stock("milk");assert(s.move_item(2,Vector2(13,8),1).is_empty())
	assert(s.items[2].animal_care.visits==1 and s.stock("milk")==stock and s.unlimited_money)
	assert(loaded.restore(JSON.parse_string(JSON.stringify(s.serialize()))))
	assert(loaded.game_mode=="sandbox" and loaded.items[2].animal_care.visits==1)
	assert(FarmAnimalCare.night(240) and not FarmAnimalCare.night(0))
	print("ANIMAL_CARE_OK: economy, expiry/depletion boundaries, save migration, invalid snapshots, down gates, command allowlist, move and sandbox")
	quit()
