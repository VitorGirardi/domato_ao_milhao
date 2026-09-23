extends SceneTree
func _initialize() -> void:
	var state:=FarmState.new();var bag:=state.armory
	assert(FarmArmory.valid(bag) and not FarmArmory.fire(bag))
	assert(not FarmArmory.buy_ammo(state,bag).is_empty())
	state.money=849;var before:=state.serialize()
	assert(not FarmArmory.buy_pistol(state,bag).is_empty() and state.serialize()==before)
	state.money=1000
	assert(FarmArmory.buy_pistol(state,bag).is_empty() and state.money==150)
	assert(bag.magazine==8 and bag.reserve==24)
	before=state.serialize()
	assert(not FarmArmory.buy_pistol(state,bag).is_empty() and before==state.serialize())
	for i in range(8):assert(FarmArmory.fire(bag))
	assert(not FarmArmory.fire(bag) and bag.shots==8)
	FarmArmory.register_hit(bag);assert(bag.hits==1)
	assert(FarmArmory.reload_magazine(bag)==8 and bag.magazine==8 and bag.reserve==16)
	assert(FarmArmory.reload_magazine(bag)==0)
	bag.magazine=3;bag.reserve=2;assert(FarmArmory.reload_magazine(bag)==2 and bag.magazine==5 and bag.reserve==0)
	assert(FarmArmory.buy_ammo(state,bag).is_empty() and state.money==90)
	state.unlimited_money=true
	for i in range(3):assert(FarmArmory.buy_ammo(state,bag).is_empty())
	assert(bag.reserve==96 and state.money==1000000000)
	before=state.serialize();assert(not FarmArmory.buy_ammo(state,bag).is_empty() and state.serialize()==before)
	var loaded:=FarmState.new();assert(loaded.restore(JSON.parse_string(JSON.stringify(before))))
	assert(loaded.armory==bag and loaded.unlimited_money)
	var old:=before.duplicate(true);old.erase("armory")
	assert(loaded.restore(old) and loaded.armory==FarmArmory.fresh())
	old.version=14;old.erase("owned_parcels");old.erase("unlimited_money")
	assert(loaded.restore(old) and loaded.armory==FarmArmory.fresh())
	for field in ["magazine","reserve","shots","hits","version"]:
		for invalid in [-1,1.5,"8",null,INF]:
			var damaged:=before.duplicate(true);damaged.armory[field]=invalid
			var snapshot:=loaded.serialize()
			assert(not loaded.restore(damaged) and loaded.serialize()==snapshot)
	for invalid in [null,[],{},false]:
		var damaged:=before.duplicate(true);damaged.armory=invalid
		var snapshot:=loaded.serialize();assert(not loaded.restore(damaged) and loaded.serialize()==snapshot)
	for modification in [{"magazine":9},{"reserve":97},{"pistol":false},{"hits":9},{"version":2},{"pistol":1}]:
		var damaged:=before.duplicate(true);damaged.armory.merge(modification,true)
		var snapshot:=loaded.serialize();assert(not loaded.restore(damaged) and loaded.serialize()==snapshot)
	# Public shop never overlaps any legal farm envelope or purchased lot.
	assert(not FarmWeapons.SITE.intersects(Rect2(-32,-38,74,78)))
	for key in FarmParcels.LOTS:assert(not FarmWeapons.SITE.intersects(FarmParcels.area(key)))
	print("ARMORY_STATE_OK: purchase, duplicate, funds, infinite money, reload, ammo cap, legacy migration, invalid saves, site isolation")
	quit()
