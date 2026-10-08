extends SceneTree

func _initialize() -> void:call_deferred("run")

func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	var state:=FarmState.new()
	var empty:=state.serialize()
	var empty_copy:=FarmState.new()
	assert(empty_copy.restore(JSON.parse_string(JSON.stringify(empty))),"Unclaimed save must survive JSON numeric conversion")
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
	assert(FarmResources.buy(state,"quartz")!="" and FarmResources.catch_fish(state,-1)!="" and FarmResources.catch_fish(state,4)!="" and FarmResources.extract(state,FarmResources.NODE_COUNT)!="")
	assert(state.serialize()==before)
	seed(4721)
	for spot in range(FarmResourceSites.FISH_SPOTS.size()):
		for i in range(100):assert(FarmResources.catch_fish(state,spot).is_empty())
	assert(state.resources.caught==400 and state.farm_xp==1200)
	for key in FarmResources.FISH_KEYS:assert(state.resources.stock[key]>0)
	# Distinct authored habitats produce different dominant species on a fixed seed.
	for spot in [0,2,3]:
		var habitat:=FarmState.new();habitat.claimed=true;habitat.resources.rod=true
		seed(22)
		for i in range(500):assert(FarmResources.catch_fish(habitat,spot).is_empty())
		assert(habitat.resources.stock.tilapia>habitat.resources.stock.dorado if spot!=2 else habitat.resources.stock.dorado>habitat.resources.stock.tilapia)
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
	for key in FarmResources.FISH_KEYS+["copper","iron","quartz"]:
		assert(FarmResources.sell(state,key)>0)
		assert(FarmResources.sell(state,key)==0)
	assert(state.money==initial_money+expected and state.revenue==initial_revenue+expected and FarmResources.value(state)==0)
	var inventory_before:=state.inventory.duplicate()
	assert(FarmResources.sell(state,"rod")==0 and state.inventory==inventory_before)
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
	# Version 19 retains stock, tools, counters and its three original cooldowns.
	var legacy19:=saved.duplicate(true);legacy19.version=19
	legacy19.resources.erase("gallery_level")
	legacy19.resources.stock.erase("gold");legacy19.resources.stock.erase("amethyst")
	legacy19.resources.node_ready=legacy19.resources.node_ready.slice(0,3)
	var legacy_before:=legacy19.duplicate(true)
	assert(restored.restore(legacy19) and restored.resources==FarmResources.normalized(saved.resources))
	assert(legacy19==legacy_before and restored.serialize().version==FarmState.SAVE_VERSION)
	var old_empty:=empty.duplicate(true);old_empty.version=19
	old_empty.resources.stock.erase("gold");old_empty.resources.stock.erase("amethyst")
	old_empty.resources.erase("gallery_level");old_empty.resources.node_ready=[0.0,0.0,0.0]
	assert(empty_copy.restore(JSON.parse_string(JSON.stringify(old_empty))))
	before=restored.serialize()
	for variant in range(5):
		var broken:=legacy19.duplicate(true)
		match variant:
			0:broken.resources.node_ready.append(0.0)
			1:broken.resources.gallery_level=1
			2:broken.resources.stock.copper=-1
			3:broken.resources.node_ready[0]=INF
			4:broken.resources.erase("rod")
		assert(not restored.restore(broken) and restored.serialize()==before)
	# Gallery purchases enforce order, ownership, money and materials atomically.
	var progression:=FarmState.new();progression.claim(Vector2(4,0));progression.money=10000
	before=progression.serialize()
	assert(FarmResources.buy(progression,"gallery_1")!="" and progression.serialize()==before)
	for kind in ["pickaxe","mine"]:assert(FarmResources.buy(progression,kind).is_empty())
	before=progression.serialize()
	for kind in ["gallery_1","gallery_2"]:assert(FarmResources.buy(progression,kind)!="" and progression.serialize()==before)
	for node in range(3,9):assert(FarmResources.extract(progression,node)!="" and progression.serialize()==before)
	for i in range(8):
		assert(FarmResources.extract(progression,0).is_empty());progression.elapsed+=120
	progression.money=1199;before=progression.serialize()
	assert(FarmResources.buy(progression,"gallery_1")!="" and progression.serialize()==before)
	progression.money=5000
	assert(FarmResources.buy(progression,"gallery_1").is_empty())
	assert(progression.money==3800 and progression.resources.stock.copper==0 and progression.resources.gallery_level==1)
	before=progression.serialize()
	assert(FarmResources.buy(progression,"gallery_1")!="" and progression.serialize()==before)
	for node in range(6,9):assert(FarmResources.extract(progression,node)!="" and progression.serialize()==before)
	assert(FarmResources.buy(progression,"gallery_2")!="" and progression.serialize()==before)
	for node in range(3,6):assert(FarmResources.extract(progression,node).is_empty())
	for i in range(8):
		progression.elapsed+=120;assert(FarmResources.extract(progression,1).is_empty())
	assert(progression.resources.stock.iron==10)
	assert(FarmResources.buy(progression,"gallery_2").is_empty())
	assert(progression.money==800 and progression.resources.stock.iron==0 and progression.resources.gallery_level==2)
	before=progression.serialize()
	assert(FarmResources.buy(progression,"gallery_2")!="" and progression.serialize()==before)
	for node in range(6,9):assert(FarmResources.extract(progression,node).is_empty())
	assert(progression.skills.mining==220)
	# The twentieth manual extraction now grants the level-three ore bonus.
	assert(progression.resources.stock.iron==2 and progression.resources.stock.quartz==2)
	assert(restored.restore(JSON.parse_string(JSON.stringify(progression.serialize()))))
	assert(restored.resources==progression.resources)
	before=restored.serialize()
	for value in [-1,3,1.5,true,NAN]:
		var broken:=before.duplicate(true);broken.resources.gallery_level=value
		assert(not restored.restore(broken) and restored.serialize()==before)
	var locked:=before.duplicate(true);locked.resources.gallery_level=0
	assert(not restored.restore(locked) and restored.serialize()==before)
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
	before=author.serialize()
	assert(FarmResources.buy(author,"gallery_1")!="" and author.serialize()==before)
	for i in range(8):
		assert(FarmResources.extract(author,0).is_empty());author.elapsed+=120
	assert(FarmResources.buy(author,"gallery_1").is_empty())
	assert(author.resources.stock.copper==0 and author.money==1000000000)
	assert(FarmCoop.save_farm("user://resources_roundtrip.json",author))
	var loaded:=FarmCoop.load_farm("user://resources_roundtrip.json")
	assert(loaded.resources==author.resources and loaded.unlimited_money)
	print("RESOURCES_OK: purchases, fish, ore, sales, cooldown, atomic validation, v1..19 migration, galleries and unlimited money")
	quit()
