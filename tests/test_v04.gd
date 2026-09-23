extends SceneTree

var checks:=0
var failures:=0

func check(condition: bool, message: String) -> void:
	checks+=1
	if not condition:
		failures+=1
		push_error("FAILED: "+message)

func make_farm() -> FarmState:
	var farm:=FarmState.new();farm.farm_xp=950
	farm.claim(Vector2(4,0))
	farm.place("coop",Vector2(4,0),0)
	return farm

func _initialize() -> void:
	var farm:=make_farm()
	var flock:Dictionary=farm.items[0].flock
	check(flock.food==100 and flock.water==100 and flock.nest==0,"New coop starts supplied with empty nest")
	check(flock.names==["Maricota","Clotilde","Pipoca"],"Three named hens")
	check(FarmAnimals.rate(flock)==1 and FarmAnimals.status(flock)=="Bem cuidadas","Good care gives normal production")
	check(not farm.tick(44) and flock.nest==0,"Eggs not produced before first cycle")
	check(farm.tick(1) and flock.nest==2 and farm.inventory.egg==0,"First eggs arrive in nest, not inventory")
	check(not farm.tick(45) and flock.nest==4,"More eggs do not repeat first-nest notification")
	check(is_equal_approx(flock.food,75) and is_equal_approx(flock.water,70),"Food and water drain at defined rates")
	check(farm.sell_all()==0 and flock.nest==4,"Market cannot sell uncollected eggs")
	var snapshot:=farm.serialize()
	check(not farm.remove_item(0).is_empty() and farm.serialize()==snapshot,"Removal cannot destroy eggs")
	check(farm.care_coop(0,"collect")=="+4 ovos no estoque!" and flock.nest==0 and farm.inventory.egg==4,"Collection transfers exact count")
	farm.care_coop(0,"collect")
	check(farm.inventory.egg==4,"Repeated collection cannot duplicate eggs")
	check(farm.sell_all()==40 and farm.inventory.egg==0,"Collected eggs sell at existing price")
	var balance:=farm.money
	check(FarmAnimals.food_cost(flock)==2,"Food refill price proportional to missing amount")
	farm.care_coop(0,"food")
	check(flock.food==100 and farm.money==balance-2,"Feeding charges quoted price and fills trough")
	balance=farm.money
	farm.care_coop(0,"food")
	check(farm.money==balance,"Full feeder cannot be charged again")
	farm.care_coop(0,"water")
	check(flock.water==100 and farm.money==balance,"Water refill is free")
	farm.care_coop(0,"water")
	check(farm.money==balance and flock.water==100,"Repeated water fill is idempotent")
	farm.items[0].egg_time=0
	flock.food=0
	check(FarmAnimals.rate(flock)==0.5 and FarmAnimals.status(flock)=="Com fome","Missing feed halves production")
	farm.tick(89)
	check(flock.nest==0,"Hungry hens need longer to lay")
	farm.tick(1)
	check(flock.nest==2,"Hungry hens still produce after 90 seconds")
	farm.care_coop(0,"collect")
	flock.water=0
	farm.items[0].egg_time=0
	check(FarmAnimals.rate(flock)==0.25,"Missing both supplies quarters production without death")
	farm.tick(180)
	check(flock.nest==2 and flock.names.size()==3,"No animal deaths when neglected")
	farm.care_coop(0,"food")
	farm.care_coop(0,"water")
	check(FarmAnimals.rate(flock)==1,"Care immediately restores normal production")
	farm.tick(10000)
	check(flock.nest==12 and farm.items[0].egg_time==0,"Full nest caps at 12 with no production backlog")
	check(flock.food==0 and flock.water==0,"Supplies continue draining while nest is full")
	check(farm.items[0].egg_time>=0 and farm.items[0].egg_time<45,"Egg progress remains valid after very large tick")
	farm.care_coop(0,"collect")
	farm.tick(0.01)
	check(flock.nest==0,"Collecting full nest does not release hidden backlog")
	farm.money=0
	snapshot=farm.serialize()
	farm.care_coop(0,"food")
	check(farm.serialize()==snapshot,"Insufficient feed budget leaves all state unchanged")
	farm.care_coop(0,"water")
	check(flock.water==100 and farm.money==0,"Player can refill water while broke")
	check(FarmAnimals.rate(flock)==0.5,"Free water helps recover production while broke")
	snapshot=farm.serialize()
	farm.care_coop(-1,"food")
	farm.care_coop(0,"unknown")
	check(farm.serialize()==snapshot,"Invalid care action and index are atomic")
	check(farm.rename_hen(0,0,"  Dona Có-Có  ").is_empty() and flock.names[0]=="Dona Có-Có","Rename trims and preserves Unicode")
	check(not farm.rename_hen(0,1,"").is_empty(),"Empty name rejected")
	check(not farm.rename_hen(0,1,"   ").is_empty(),"Whitespace name rejected")
	check(not farm.rename_hen(0,1,"a".repeat(25)).is_empty(),"Overlong name rejected")
	check(not farm.rename_hen(0,1,"Linha\nOutra").is_empty(),"Multiline name rejected")
	check(not farm.rename_hen(0,3,"Oops").is_empty(),"Invalid hen rejected")
	check(not farm.rename_hen(-1,0,"Oops").is_empty(),"Invalid coop rejected")
	check(farm.rename_hen(0,2,"a".repeat(24)).is_empty(),"Maximum-length name accepted")
	var saved_flock:Dictionary=flock.duplicate(true)
	check(farm.move_item(0,Vector2(8,0),1).is_empty() and farm.items[0].flock==saved_flock,"Moving and rotating preserves animal data")
	farm.paint_item(0,"roof",2)
	check(farm.items[0].flock==saved_flock,"Painting preserves animal data")
	var restored:=FarmState.new()
	check(restored.restore(JSON.parse_string(JSON.stringify(farm.serialize()))),"Version 3 JSON roundtrip")
	check(restored.items[0].flock==saved_flock,"Names, supplies and nest survive serialization")
	var before:=restored.serialize()
	for bad in [null,{}, {"food":-1,"water":100,"nest":0,"names":["A","B","C"]}, {"food":100,"water":101,"nest":0,"names":["A","B","C"]}]:
		var data:=farm.serialize()
		data.items[0].flock=bad
		check(not restored.restore(data) and restored.serialize()==before,"Malformed needs rejected without partial restore")
	for pair in [["nest",13],["nest",0.5],["food",INF],["water","full"],["names",["A","B"]],["names",["A","","C"]],["names",["A",true,"C"]]]:
		var data:=farm.serialize()
		data.items[0].flock[pair[0]]=pair[1]
		check(not restored.restore(data) and restored.serialize()==before,"Invalid animal field rejected atomically")
	var missing:=farm.serialize()
	missing.items[0].erase("flock")
	check(not restored.restore(missing),"Current save cannot silently lose animal data")
	for version in [1,2]:
		var legacy:=farm.serialize()
		legacy.version=version
		legacy.inventory.egg=17
		legacy.items[0].egg_time=40
		legacy.items[0].erase("flock")
		check(restored.restore(JSON.parse_string(JSON.stringify(legacy))),"Legacy schema %d accepted"%version)
		check(restored.inventory.egg==17 and restored.items[0].egg_time==40,"Migration preserves stored eggs and production progress")
		check(restored.items[0].flock==FarmAnimals.fresh(),"Legacy coop receives full supplies and empty nest")
		restored.tick(5)
		check(restored.inventory.egg==17 and restored.items[0].flock.nest==2,"Migrated production continues without duplicating old eggs")
	var large:=make_farm()
	var small:=make_farm()
	large.items[0].flock.food=10
	large.items[0].flock.water=8
	small.items[0].flock=large.items[0].flock.duplicate(true)
	large.tick(150)
	for i in range(1500): small.tick(0.1)
	check(large.items[0].flock.nest==small.items[0].flock.nest,"Frame partition does not change production")
	check(is_equal_approx(large.items[0].egg_time,small.items[0].egg_time),"Partial production consistent across depletion boundaries")
	check(large.items[0].flock.food==0 and small.items[0].flock.water==0,"Resource exhaustion stable across frame sizes")
	var multi:=make_farm()
	multi.place("coop",Vector2(10,0),0)
	multi.rename_hen(0,0,"Chefa")
	multi.items[0].flock.food=0
	check(multi.items[1].flock.names[0]=="Maricota" and multi.items[1].flock.food==100,"Coops do not share mutable needs or names")
	multi.tick(90)
	check(multi.items[0].flock.nest==2 and multi.items[1].flock.nest==4,"Each coop produces at its own welfare rate")
	multi.care_coop(0,"collect")
	check(multi.items[1].flock.nest==4 and multi.inventory.egg==2,"Collection targets one coop")
	check(multi.remove_item(0).is_empty() and multi.items.size()==1,"Empty coop can be removed")
	check(FarmAnimals.valid(multi.items[0].flock),"Remaining flock stays valid after removing another coop")
	print("V04_SIMULATION: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
