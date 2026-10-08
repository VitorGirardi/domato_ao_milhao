extends SceneTree
func _initialize() -> void:call_deferred("run")
func farm() -> FarmState:
	var s:=FarmState.new_farm("survival");s.money=20000;s.farm_xp=950
	assert(s.claim(Vector2(4,0)).is_empty());s.land_size=40
	return s
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	var s:=farm()
	assert(s.skills==FarmSkills.fresh())
	var before:=s.serialize()
	assert(not FarmResources.catch_fish(s,0).is_empty() and s.serialize()==before)
	s.resources.rod=true
	for i in range(3):assert(FarmResources.catch_fish(s,0).is_empty())
	assert(s.skills.fishing==30 and FarmSkills.level(s.skills.fishing)==2)
	assert(not s.skill_notice.is_empty())
	assert(s.resources.caught==3 and FarmResources.valid(s.resources,s.elapsed))
	for rank in range(1,6):
		s.skills.fishing=FarmSkills.THRESHOLDS[rank-1]
		for spot in range(4):
			var weights:=FarmSkills.fish_weights(s,spot)
			assert(weights[0]+weights[1]+weights[2]==100 and weights[0]>=0)
			assert(weights[2]==FarmResources.FISH_WEIGHTS[spot][2]+2*(rank-1))
	# Bonus ore increments both stock and lifetime yield; limits cannot overflow.
	s.resources.pickaxe=true;s.resources.mine_owned=true;s.skills.mining=490
	assert(FarmResources.extract(s,0).is_empty())
	assert(s.resources.stock.copper==2 and s.resources.mined==2 and s.skills.mining==500)
	before=s.serialize();assert(not FarmResources.extract(s,0).is_empty() and s.serialize()==before)
	s.elapsed=120;s.skills.mining=490;s.resources.stock.copper=9999;s.resources.mined=9999
	assert(FarmResources.extract(s,0).is_empty())
	assert(s.resources.stock.copper==10000 and s.resources.mined==10000 and s.skills.mining==500)
	assert(FarmResources.valid(s.resources,s.elapsed))
	# Agriculture bonuses apply to manual harvest/replant, never watering or attempts.
	s=farm();s.skills.farming=100
	assert(s.place("plot",Vector2(-6,0),0).is_empty())
	s.items[0].growth=1.0;s.items[0].watered=true
	assert(s.tend(0).begins_with("+4 "))
	assert(s.inventory.carrot==4 and s.skills.farming==110)
	var money:=s.money;s.tend(0);assert(s.money==money-3 and s.skills.farming==110)
	s.tend(0);s.tend(0);assert(s.skills.farming==110)
	assert(s.place("orchard",Vector2(4,0),0).is_empty())
	var tree:Dictionary=s.items[1].orchard
	tree.growth=FarmOrchard.GROW_SECONDS;tree.watered=true;tree.ready=6;tree.fruit_time=FarmOrchard.FRUIT_SECONDS
	assert(FarmOrchard.harvest(s,1,false).is_empty() and s.skills.farming==110)
	tree.watered=true;tree.ready=6;tree.fruit_time=FarmOrchard.FRUIT_SECONDS
	assert(FarmOrchard.harvest(s,1).is_empty() and s.skills.farming==120)
	# Comfort cannot be spammed; collection needs actual products, automation is excluded.
	s=farm();s.skills.handling=480
	assert(s.place("coop",Vector2(-6,0),0).is_empty())
	s.items[0].flock.food=40.0;s.items[0].flock.water=95.0
	assert(FarmAnimalCare.care(s,0).is_empty())
	assert(s.items[0].flock.food==48 and s.items[0].flock.water==100 and s.skills.handling==488)
	before=s.serialize();assert(not FarmAnimalCare.care(s,0).is_empty() and s.serialize()==before)
	s.items[0].flock.nest=2;s.care_coop(0,"collect");assert(s.skills.handling==490)
	s.care_coop(0,"collect");assert(s.skills.handling==490)
	assert(s.place("corral",Vector2(4,0),0).is_empty());s.items[1].dairy.owned=true;s.items[1].dairy.milk=4
	assert(FarmDairy.care(s,1,"milk",false).is_empty() and s.skills.handling==490)
	s.items[1].dairy.milk=4;assert(FarmDairy.care(s,1,"milk").is_empty() and s.skills.handling==498)
	# Save schema, JSON numbers, migration and failed restore all preserve isolation.
	var saved:Dictionary=JSON.parse_string(JSON.stringify(s.serialize()))
	var loaded:=FarmState.new();assert(loaded.restore(saved) and loaded.skills==s.skills and loaded.skill_notice.is_empty())
	assert(FarmCoop.save_farm("user://skills.json",s))
	assert(FarmCoop.load_farm("user://skills.json").skills==s.skills)
	var old:=saved.duplicate(true);old.version=31;old.erase("skills")
	assert(loaded.restore(old) and loaded.skills==FarmSkills.fresh() and loaded.inventory==s.inventory)
	before=loaded.serialize()
	for value in [null,{}, {"fishing":0,"farming":0,"mining":0,"handling":-1},{"fishing":0,"farming":0,"mining":0,"handling":true}]:
		var bad:=saved.duplicate(true);bad.skills=value
		assert(not loaded.restore(bad) and loaded.serialize()==before)
	for value in [NAN,INF,1.5,1000000001]:
		var bad:=saved.duplicate(true);bad.skills.fishing=value
		assert(not loaded.restore(bad) and loaded.serialize()==before)
	var missing:=saved.duplicate(true);missing.erase("skills");assert(not loaded.restore(missing))
	var sandbox:=FarmState.new_farm("sandbox")
	for key in FarmSkills.KEYS:assert(FarmSkills.level(sandbox.skills[key])==5)
	var legacy_sandbox:=sandbox.serialize();legacy_sandbox.version=31;legacy_sandbox.erase("skills")
	assert(loaded.restore(legacy_sandbox) and loaded.skills==sandbox.skills and loaded.infinite_resources())
	s.skills.fishing=FarmSkills.MAX_XP-1;FarmSkills.earn(s,"fishing",10);assert(s.skills.fishing==FarmSkills.MAX_XP)
	print("SKILLS_OK: actual practice, all bonuses, resource limits, automation exclusion, anti-repeat, migration, atomic saves and sandbox")
	quit()
