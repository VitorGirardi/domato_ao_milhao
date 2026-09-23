extends SceneTree
var checks:=0
func check(ok:bool,message:String) -> void:
	checks+=1
	if not ok: push_error(message); quit(1)
	assert(ok,message)

func _initialize() -> void:
	var farm:=FarmState.new();farm.farm_xp=950
	farm.claim(Vector2.ZERO)
	farm.money=5000
	assert(farm.place("barn",Vector2(-6,-6),0).is_empty())
	assert(farm.place("coop",Vector2(6,-6),0).is_empty())
	assert(farm.place("workshop",Vector2(-6,4),0).is_empty())
	var before:=farm.serialize()
	check(not farm.upgrade_building(-1).is_empty() and before==farm.serialize(),"Invalid selection is atomic")
	farm.money=359
	before=farm.serialize()
	check(not farm.upgrade_building(0).is_empty() and before==farm.serialize(),"Insufficient funds cannot partially upgrade")
	farm.money=5000
	farm.inventory.carrot=100
	farm.transfer_reserve("carrot",true)
	farm.paint_item(0,"walls",4)
	check(farm.upgrade_building(0).is_empty() and farm.money==4640 and farm.reserve_capacity()==120,"Barn evolution cost and doubled capacity")
	check(farm.items[0].paint==4 and farm.reserve.carrot==60,"Upgrade keeps paint and reserve")
	check(farm.transfer_reserve("carrot",true)==40 and not farm.remove_item(0).is_empty(),"Expanded reserve remains protected against removal")
	before=farm.serialize()
	check(not farm.upgrade_building(0).is_empty() and before==farm.serialize(),"Duplicate evolution cannot charge")
	farm.items[1].flock.nest=7
	farm.items[1].flock.food=65
	check(farm.upgrade_building(1).is_empty() and farm.items[1].flock.names.size()==6,"Coop includes three additional hens")
	check(farm.items[1].flock.nest==7 and farm.items[1].flock.food==65,"Coop upgrade preserves eggs and needs")
	check(farm.rename_hen(1,5,"Dona Omelete").is_empty(),"Sixth hen can be named")
	var once:Dictionary=farm.items[1].duplicate(true)
	var steps:Dictionary=once.duplicate(true)
	FarmAnimals.tick(once,200)
	for i in range(200): FarmAnimals.tick(steps,1)
	check(once.flock.nest==steps.flock.nest and absf(once.egg_time-steps.egg_time)<0.001 and absf(once.flock.food-steps.flock.food)<0.001,"Upgraded flock ticks consistently across depletion boundaries")
	var productive:Dictionary=farm.items[1].duplicate(true)
	productive.flock=FarmAnimals.fresh()
	productive.flock.names.append_array(["A","B","C"])
	productive.egg_time=0
	FarmAnimals.tick(productive,45)
	check(productive.flock.nest==4 and is_equal_approx(productive.flock.food,75.0),"Six hens produce four eggs and consume double supplies")
	check(not farm.buy_professional_watering().is_empty(),"Professional tool requires prerequisites")
	farm.buy_watering_upgrade()
	check(not farm.buy_professional_watering().is_empty(),"Base tool alone does not unlock professional tool")
	check(farm.upgrade_building(2).is_empty(),"Workshop reaches level two")
	var cash:=farm.money
	check(farm.buy_professional_watering().is_empty() and farm.money==cash-450,"Professional tool exact purchase")
	check(not farm.buy_professional_watering().is_empty() and farm.money==cash-450,"Duplicate tool purchase does not charge")
	for x in [0,2,4]:
		for z in [0,2,4]: assert(farm.place("plot",Vector2(x,z),0).is_empty())
	check(farm.water_targets(7).size()==9,"Professional tool includes all nine plots")
	farm.tend(7)
	check(farm.count_items("plot",true)==9,"All nine eligible plots receive water")
	var restored:=FarmState.new()
	check(restored.restore(JSON.parse_string(JSON.stringify(farm.serialize()))) and JSON.parse_string(JSON.stringify(restored.serialize()))==JSON.parse_string(JSON.stringify(farm.serialize())),"Schema 7 JSON preserves levels, names, reserve and equipment")
	for invalid_level in [0,3,1.5,"2"]:
		var invalid:=farm.serialize()
		invalid.items[0].level=invalid_level
		before=restored.serialize()
		check(not restored.restore(invalid) and before==restored.serialize(),"Invalid level fails atomically")
	var bad:=farm.serialize()
	bad.items[1].flock.names.pop_back()
	check(not restored.restore(bad),"Invalid upgraded flock rejected")
	bad=farm.serialize(); bad.professional_watering=true; bad.watering_upgrade=false
	check(not restored.restore(bad),"Tool dependency validated on load")
	var legacy:=FarmState.new();legacy.farm_xp=950
	legacy.claim(Vector2.ZERO); legacy.place("barn",Vector2.ZERO,0)
	var old:=legacy.serialize()
	old.version=6; old.erase("professional_watering"); old.items[0].erase("level")
	check(restored.restore(old) and restored.items[0].level==1 and not restored.professional_watering,"Version 6 defaults to level one without granting upgrades")
	farm.transfer_reserve("carrot",false)
	cash=farm.money
	check(farm.remove_item(0).is_empty() and farm.money==cash+300,"Removal refunds half base plus building investment")
	cash=farm.money
	check(farm.remove_item(1).is_empty() and farm.money==cash+340 and farm.professional_watering,"Removing equipped workshop refunds structure only and keeps tool")
	print("V011_STATE_OK: %d checks"%checks)
	quit()

