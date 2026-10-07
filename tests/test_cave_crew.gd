extends SceneTree

func _initialize() -> void:call_deferred("run")
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	var state:=FarmState.new();state.claim(Vector2(4,0));state.money=20000
	var before:=state.serialize()
	assert(not FarmCaveCrew.run(state,"cave:recruit:0").is_empty() and state.serialize()==before)
	state.resources.mine_owned=true;state.resources.pickaxe=true
	state.inventory.carrot=6
	assert(FarmCoopCommands.run(state,{"action":"cave:recruit:0"}).is_empty())
	assert(state.money==19760 and state.stock("carrot")==0 and state.cave_crew[0].fuel==600)
	before=state.serialize()
	assert(not FarmCaveCrew.run(state,"cave:recruit:0").is_empty() and state.serialize()==before)
	state.tick(119);assert(state.resources.stock.copper==0)
	state.tick(1);assert(state.resources.stock.copper==1 and state.cave_crew[0].produced==1)
	assert(FarmCaveCrew.run(state,"cave:pause:0").is_empty())
	state.tick(200);assert(state.cave_crew[0].fuel==480 and state.resources.stock.copper==1)
	FarmCaveCrew.run(state,"cave:pause:0");state.tick(1000)
	assert(state.resources.stock.copper==5 and state.cave_crew[0].fuel==0 and state.resources.mined==5)
	state.inventory.wheat=5;state.inventory.egg=2
	assert(FarmCaveCrew.run(state,"cave:feed:0").is_empty())
	assert(state.stock("wheat")==0 and state.stock("egg")==0)
	var one_step:=FarmState.new();assert(one_step.restore(state.serialize()))
	state.tick(600)
	for i in range(600):one_step.tick(1)
	assert(state.cave_crew==one_step.cave_crew and state.resources==one_step.resources)
	state.resources.gallery_level=2;state.inventory.corn=4;state.cheese_stock=2
	for i in [1,2]:assert(FarmCaveCrew.run(state,"cave:recruit:%d"%i).is_empty())
	state.tick(120)
	assert(state.resources.stock.iron==1 and state.resources.stock.amethyst==1)
	assert(FarmResources.extract(state,9).is_empty() and FarmResources.extract(state,10).is_empty())
	assert(FarmPickupCargo.price("gold")==110 and FarmPickupCargo.price("amethyst")==165)
	assert(FarmResources.sell(state,"amethyst")==330)
	var copy:=FarmState.new();assert(copy.restore(JSON.parse_string(JSON.stringify(state.serialize()))))
	assert(copy.cave_crew==state.cave_crew)
	before=copy.serialize()
	for bad in [null,{},[],[{}, {}, {}]]:
		var payload:=before.duplicate(true);payload.cave_crew=bad
		assert(not copy.restore(payload) and copy.serialize()==before)
	for key in ["fuel","progress","produced"]:
		for bad in [NAN,INF,-1,true,"bad"]:
			var payload:=before.duplicate(true);payload.cave_crew[0][key]=bad
			assert(not copy.restore(payload) and copy.serialize()==before)
	var payload:=before.duplicate(true);payload.cave_crew[0].progress=120
	assert(not copy.restore(payload))
	payload=before.duplicate(true);payload.resources.gallery_level=0
	assert(not copy.restore(payload))
	# Real v30 shape, copied without mutating caller data. Preserve the original nine veins.
	var old:=FarmState.new();old.claim(Vector2(4,0));old.resources.pickaxe=true;old.resources.mine_owned=true
	old.resources.mined=3;old.resources.stock.quartz=3;old.resources.node_ready[2]=100
	var legacy:=old.serialize();legacy.version=30;legacy.erase("cave_crew")
	legacy.resources.stock.erase("gold");legacy.resources.stock.erase("amethyst");legacy.resources.node_ready.resize(9)
	var original:=legacy.duplicate(true)
	assert(copy.restore(legacy) and legacy==original and copy.resources.stock.quartz==3 and copy.resources.node_ready[2]==100)
	assert(copy.resources.node_ready.size()==11 and copy.resources.stock.amethyst==0 and copy.cave_crew==FarmCaveCrew.fresh())
	var sandbox:=FarmState.new();sandbox.game_mode="sandbox";sandbox.unlimited_money=true;sandbox.claim(Vector2(4,0));sandbox.unlock_sandbox()
	for i in range(3):assert(FarmCaveCrew.run(sandbox,"cave:recruit:%d"%i).is_empty())
	assert(sandbox.stock("gold")==1000000000 and sandbox.stock("amethyst")==1000000000)
	assert(copy.restore(sandbox.serialize()))
	print("CAVE_CREW_OK: gifts, fuel, pause, timestep equivalence, rare ores, sales, strict saves, v30 migration and Sandbox")
	quit()
