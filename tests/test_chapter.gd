extends SceneTree

func _initialize() -> void:
	var farm:=FarmState.new_farm("survival")
	assert(not FarmChapter.act(farm,"accept").is_empty())
	assert(farm.chapter.stage==0)
	assert(farm.claim(Vector2(4,-2)).is_empty())
	var original_money:=farm.money
	assert(FarmChapter.act(farm,"accept").is_empty())
	var before:=farm.serialize()
	assert(not FarmChapter.act(farm,"deliver").is_empty())
	assert(farm.serialize()==before)
	farm.inventory.carrot=8
	assert(FarmChapter.act(farm,"deliver").is_empty())
	assert(farm.inventory.carrot==2 and farm.money==original_money+180)
	assert(farm.trade.nena.reputation==1 and not farm.contract_done)
	for action in ["rescue","return_animal","repair","catch_fish"]:
		# Invalid and repeated requests must never consume stock or pay twice.
		before=farm.serialize()
		assert(not FarmChapter.act(farm,"deliver").is_empty())
		assert(farm.serialize()==before)
		if action=="catch_fish":
			assert(farm.resources.rod)
			assert(FarmResources.catch_fish(farm,3).is_empty())
		assert(FarmChapter.act(farm,action).is_empty())
		var restored:=FarmState.new()
		assert(restored.restore(JSON.parse_string(JSON.stringify(farm.serialize()))))
		assert(restored.chapter==farm.chapter)
		assert(not FarmChapter.act(restored,action).is_empty())
	assert(farm.chapter.stage==6 and farm.money==original_money+630)
	assert(farm.revenue==630 and farm.resources.caught==1)
	before=farm.serialize()
	for action in FarmChapter.ACTIONS:assert(not FarmChapter.act(farm,action).is_empty())
	assert(farm.serialize()==before)
	# Missing optional chapter preserves all legacy progress and starts the chapter.
	var legacy:=farm.serialize()
	legacy.erase("chapter")
	assert(farm.restore(legacy) and farm.chapter==FarmChapter.fresh())
	assert(farm.money==original_money+630 and farm.resources.caught==1)
	# Reject malformed progress atomically, including JSON floats and unknown fields.
	for malformed in [null,[],{}, {"stage":-1},{"stage":7},{"stage":1.5},{"stage":true},{"stage":"1"},{"stage":INF},{"stage":NAN},{"stage":1,"reward":100}]:
		assert(not FarmChapter.valid(malformed))
		var broken:=farm.serialize()
		broken.chapter=malformed
		before=farm.serialize()
		assert(not farm.restore(broken))
		assert(farm.serialize()==before)
	var unclaimed:=FarmState.new_farm("survival").serialize()
	unclaimed.chapter.stage=1
	assert(not farm.restore(unclaimed))
	var no_rod:=farm.serialize()
	no_rod.chapter.stage=5;no_rod.resources=FarmResources.fresh()
	assert(not farm.restore(no_rod))
	# Sandbox consumes virtual stock, legacy unlimited money still requires carrots.
	var sandbox:=FarmState.new_farm("sandbox")
	assert(sandbox.claim(Vector2(4,-2)).is_empty())
	for action in FarmChapter.ACTIONS:assert(FarmChapter.act(sandbox,action).is_empty())
	assert(sandbox.inventory.carrot==0 and sandbox.infinite_resources())
	var restored_sandbox:=FarmState.new()
	assert(restored_sandbox.restore(sandbox.serialize()))
	assert(restored_sandbox.chapter.stage==6 and restored_sandbox.resources.rod)
	var original:=FarmState.new()
	original.unlimited_money=true
	assert(original.claim(Vector2(4,-2)).is_empty())
	assert(FarmChapter.act(original,"accept").is_empty())
	assert(not FarmChapter.act(original,"deliver").is_empty())
	assert(original.chapter.stage==1)
	print("CHAPTER_OK: sequenced rewards, resource modes, save migration and atomic validation")
	quit()
