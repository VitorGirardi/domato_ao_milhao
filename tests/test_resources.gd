extends SceneTree

func _initialize() -> void:call_deferred("run")

func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	var state:=FarmState.new()
	var empty:=state.serialize()
	assert(FarmResources.buy(state,"rod")!="" and FarmResources.catch_fish(state,0)!="" and FarmResources.extract(state,0)!="")
	assert(state.serialize()==empty)
	assert(state.claim(Vector2(4,0)).is_empty())
	var no_tools:=state.serialize()
	assert(FarmResources.catch_fish(state,0)!="" and FarmResources.extract(state,0)!="" and state.serialize()==no_tools)
	var pick_only:=FarmState.new();pick_only.claimed=true
	assert(FarmResources.buy(pick_only,"pickaxe").is_empty())
	assert(FarmResources.extract(pick_only,0)!="" and pick_only.resources.mined==0)
	var mine_only:=FarmState.new();mine_only.claimed=true
	assert(FarmResources.buy(mine_only,"mine").is_empty())
	assert(FarmResources.extract(mine_only,0)!="" and mine_only.resources.mined==0)
	state.money=149
	assert(FarmResources.buy(state,"rod")!="" and state.money==149)
	state.money=3000
	for kind in ["rod","pickaxe","mine"]:
		assert(FarmResources.buy(state,kind).is_empty())
		var before:=state.serialize()
		assert(FarmResources.buy(state,kind)!="" and state.serialize()==before)
	assert(state.money==1170 and FarmResources.value(state)==0)
	var before:=state.serialize()
	assert(FarmResources.buy(state,"quartz")!="" and FarmResources.catch_fish(state,-1)!="" and FarmResources.catch_fish(state,3)!="" and FarmResources.extract(state,3)!="")
	assert(state.serialize()==before)
	seed(4721)
	for spot in range(3):
		for i in range(100):assert(FarmResources.catch_fish(state,spot).is_empty())
	assert(state.resources.caught==300 and state.farm_xp==900)
	for key in FarmResources.FISH_KEYS:assert(state.resources.stock[key]>0)
	# Distinct authored habitats produce different dominant species on a fixed seed.
	for spot in [0,2]:
		var habitat:=FarmState.new();habitat.claimed=true;habitat.resources.rod=true
		seed(22)
		for i in range(500):assert(FarmResources.catch_fish(habitat,spot).is_empty())
		assert(habitat.resources.stock.tilapia>habitat.resources.stock.dorado if spot==0 else habitat.resources.stock.dorado>habitat.resources.stock.tilapia)
	for node in range(3):
		assert(FarmResources.extract(state,node).is_empty())
		before=state.serialize()
		assert(FarmResources.extract(state,node)!="" and state.serialize()==before)
	state.tick(119.99)
	assert(FarmResources.extract(state,0)!="")
	state.tick(.01)
	assert(FarmResources.extract(state,0).is_empty())
	assert(state.resources.mined==4)
	var saved:Dictionary=JSON.parse_string(JSON.stringify(state.serialize()))
	var restored:=FarmState.new()
	assert(restored.restore(saved) and restored.resources==state.resources)
	assert(FarmResources.extract(restored,0)!="")
	var expected:=FarmResources.value(state)
	var initial_money:=state.money
	var initial_revenue:=state.revenue
	for key in FarmResources.FISH_KEYS+FarmResources.ORE_KEYS:
		assert(FarmResources.sell(state,key)>0)
		assert(FarmResources.sell(state,key)==0)
	assert(state.money==initial_money+expected and state.revenue==initial_revenue+expected and FarmResources.value(state)==0)
	assert(FarmResources.sell(state,"rod")==0 and state.inventory.size()==4)
	# Invalid payloads must leave the entire live farm untouched, including money.
	var invalid:Array=[]
	var missing:=saved.duplicate(true);missing.erase("resources");invalid.append(missing)
	for item in [NAN,INF,-1.0,1.5,true,10001]:
		var bad:=saved.duplicate(true);bad.resources.stock.tilapia=item;invalid.append(bad)
	for item in [NAN,INF,-1.0,1.5,true,1000000001]:
		var bad:=saved.duplicate(true);bad.resources.caught=item;invalid.append(bad)
	for item in [NAN,INF,-1.0,100000.0,true]:
		var bad:=saved.duplicate(true);bad.resources.node_ready[0]=item;invalid.append(bad)
	for field in ["rod","pickaxe","mine_owned"]:
		var bad:=saved.duplicate(true);bad.resources[field]=false;invalid.append(bad)
	var bad:=saved.duplicate(true);bad.resources.stock.extra=0;invalid.append(bad)
	bad=saved.duplicate(true);bad.resources.node_ready=[];invalid.append(bad)
	bad=saved.duplicate(true);bad.resources.mined=0;invalid.append(bad)
	bad=saved.duplicate(true);bad.resources.caught=0;invalid.append(bad)
	bad=saved.duplicate(true);bad.claimed=false;invalid.append(bad)
	before=restored.serialize()
	for payload in invalid:
		assert(not restored.restore(payload))
		assert(restored.serialize()==before)
	# Legacy migration cannot retain another farm's resources.
	for version in range(1,19):
		var legacy:=empty.duplicate(true);legacy.version=version;legacy.erase("resources")
		assert(restored.restore(legacy) and restored.resources==FarmResources.fresh())
	# Capacity guards never consume cooldown or award XP.
	assert(restored.restore(saved))
	restored.resources.stock.tilapia=FarmResources.STOCK_LIMIT
	before=restored.serialize();assert(FarmResources.catch_fish(restored,0)!="" and restored.serialize()==before)
	restored.resources.stock.copper=FarmResources.STOCK_LIMIT;restored.elapsed+=120
	before=restored.serialize();assert(FarmResources.extract(restored,0)!="" and restored.serialize()==before)
	# Normal author play keeps unlimited money while sales still track revenue.
	var author:=FarmState.new();author.unlimited_money=true
	assert(author.claim(Vector2(4,0)).is_empty())
	for kind in ["rod","pickaxe","mine"]:assert(FarmResources.buy(author,kind).is_empty())
	assert(author.money==1000000000 and author.unlimited_money)
	assert(FarmResources.extract(author,2).is_empty())
	assert(FarmResources.sell(author,"quartz")==65 and author.revenue==65 and author.money==1000000000)
	assert(FarmCoop.save_farm("user://resources_roundtrip.json",author))
	var loaded:=FarmCoop.load_farm("user://resources_roundtrip.json")
	assert(loaded.resources==author.resources and loaded.unlimited_money)
	print("RESOURCES_OK: purchases, fish, ore, sales, cooldown, atomic validation, v1..18 migration and unlimited money")
	quit()
