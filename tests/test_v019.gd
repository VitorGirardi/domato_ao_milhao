extends SceneTree
func _initialize() -> void:
	var f:=FarmState.new()
	assert(f.farm_xp==0 and FarmLevels.level(0)==1)
	f.claim(Vector2(4,-2))
	var original:=f.serialize()
	for kind in ["coop","barn","workshop","corral","cheesery"]:
		assert(not f.place(kind,Vector2(4,0),0).is_empty())
		assert(f.serialize()==original,"Locked placement must not charge or mutate")
	assert(f.place("plot",Vector2(4,0),0).is_empty())
	for i in range(3):
		if i>0:f.tend(0)
		f.tend(0);f.tick(32);f.tend(0)
		assert(f.farm_xp==(i+1)*10)
	assert(FarmLevels.level(f.farm_xp)==2 and not f.level_notice.is_empty())
	f.tend(0);f.tend(0);f.sell_product("carrot",1)
	assert(f.farm_xp==30,"Planting, watering and selling never mint XP")
	assert(f.deliver_contract() and f.farm_xp==60)
	assert(not f.deliver_contract() and f.farm_xp==60)
	assert(f.place("coop",Vector2(10,-6),0).is_empty())
	f.items[1].flock.nest=4;f.care_coop(1,"collect")
	assert(f.farm_xp==68)
	f.care_coop(1,"collect");assert(f.farm_xp==68)
	f.hire_staff(1);f.items[1].flock.nest=3;FarmStaff.service(f)
	assert(f.farm_xp==74,"Zeca collection awards the same XP per egg")
	FarmStaff.service(f);assert(f.farm_xp==74)
	# Boundaries and legacy migration with each retained building.
	for i in range(1,6):
		assert(FarmLevels.level(FarmLevels.THRESHOLDS[i]-1)==i)
		assert(FarmLevels.level(FarmLevels.THRESHOLDS[i])==i+1)
		var old:=FarmState.new();old.claim(Vector2(4,-2));old.money=5000;old.farm_xp=950
		assert(old.place(FarmLevels.BUILDINGS[i],Vector2(4,0),0).is_empty())
		var data:=old.serialize();data.version=13;data.erase("farm_xp")
		var migrated:=FarmState.new();assert(migrated.restore(data))
		assert(FarmLevels.level(migrated.farm_xp)>=i+1 and migrated.money==old.money)
		assert(migrated.level_notice.is_empty())
		var xp:=migrated.farm_xp
		assert(migrated.restore(JSON.parse_string(JSON.stringify(migrated.serialize()))))
		assert(migrated.farm_xp==xp,"Migration awards only once")
		assert(migrated.move_item(0,Vector2(4,2),1).is_empty())
		assert(migrated.remove_item(0).is_empty())
		assert(FarmLevels.unlocked(migrated,FarmLevels.BUILDINGS[i]))
	# Production shares collection methods with Raul and Chico.
	var dairy:=FarmState.new();dairy.claim(Vector2(4,-2));dairy.farm_xp=950;dairy.money=5000
	assert(dairy.place("corral",Vector2(0,-6),0).is_empty())
	assert(dairy.place("cheesery",Vector2(10,2),0).is_empty())
	FarmDairy.care(dairy,0,"buy");dairy.items[0].dairy.milk=4
	FarmDairy.care(dairy,0,"milk");assert(dairy.farm_xp==962)
	FarmDairy.care(dairy,0,"milk");assert(dairy.farm_xp==962)
	FarmCheese.start(dairy,1,2);FarmCheese.tick(dairy.items[1].cheese,90)
	assert(FarmCheese.collect(dairy,1)==2 and dairy.farm_xp==978)
	FarmCheese.collect(dairy,1);assert(dairy.farm_xp==978)
	dairy.cheese_order.active=true;dairy.cheese_stock=3
	assert(FarmCheese.deliver(dairy) and dairy.farm_xp==1008)
	assert(not FarmCheese.deliver(dairy) and dairy.farm_xp==1008)
	f.accept_order("nena")
	var offer:=FarmTrade.offer("nena",f.trade.nena)
	for key in offer.needs:f.inventory[key]=offer.needs[key]
	assert(f.deliver_order("nena").is_empty() and f.farm_xp==104)
	assert(not f.deliver_order("nena").is_empty() and f.farm_xp==104)
	var saved:=f.serialize();var restored:=FarmState.new()
	assert(restored.restore(JSON.parse_string(JSON.stringify(saved))) and restored.farm_xp==104)
	var before_invalid:=restored.serialize()
	for invalid in [-1,1.5,"30",null,INF,1000000001]:
		var damaged:=saved.duplicate(true);damaged.farm_xp=invalid
		assert(not restored.restore(damaged) and restored.serialize()==before_invalid)
	var missing:=saved.duplicate(true);missing.erase("farm_xp");assert(not restored.restore(missing))
	print("V019_LEVELS_OK: production, orders, thresholds, atomic locks, migration and invalid saves")
	quit()
