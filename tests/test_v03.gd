extends SceneTree

var checks:=0
var failures:=0

func check(condition: bool, message: String) -> void:
	checks+=1
	if not condition:
		failures+=1
		push_error("FAILED: "+message)

func _initialize() -> void:
	var farm:=FarmState.new()
	farm.claim(Vector2(4,0))
	var line:=farm.line_plan("fence",Vector2(-4,-8),Vector2(4,-6))
	check(line.size()==5 and line[4].x==4 and line[4].z==-8,"Drag locks to dominant axis with two-meter spacing")
	check(farm.batch_cost(line)==60,"Preview shows total cost")
	var before:=farm.serialize()
	check(farm.batch_error(line).is_empty() and farm.serialize()==before,"Preview is read-only")
	check(farm.place_batch(line).is_empty(),"Valid route builds")
	check(farm.money==1140 and farm.items.size()==5,"Route charges exactly once per piece")
	before=farm.serialize()
	check(not farm.place_batch(line).is_empty() and farm.serialize()==before,"Repeated route cannot overlap or charge twice")
	line=farm.line_plan("path",Vector2(0,-2),Vector2(0,20))
	check(not farm.place_batch(line).is_empty() and farm.serialize()==before,"Boundary failure leaves no partial route")
	line=farm.line_plan("path",Vector2(0,-2),Vector2(4,-2))
	farm.money=14
	before=farm.serialize()
	check(not farm.place_batch(line).is_empty() and farm.serialize()==before,"Insufficient total money rejects entire route")
	farm.money=15
	check(farm.place_batch(line).is_empty() and farm.money==0,"Exact budget succeeds without negative balance")
	line=farm.line_plan("fence",Vector2(8,4),Vector2(8,0))
	check(line.size()==3 and line[2].z==0 and line[0].turn==1,"Reverse vertical drag rotates fence correctly")
	check(farm.line_plan("fence",Vector2(0,0),Vector2(0,0),3)[0].turn==3,"Single piece respects manual rotation")
	check(farm.line_plan("barn",Vector2.ZERO,Vector2.ONE).is_empty(),"Batch tool only supports fences and paths")
	check(farm.line_plan("path",Vector2.ZERO,Vector2(99999,0)).size()==64,"Very long drag is bounded")
	farm.money=2000
	var duplicate:=[{"kind":"path","x":8,"z":4,"turn":0},{"kind":"path","x":8,"z":4,"turn":0}]
	before=farm.serialize()
	check(not farm.place_batch(duplicate).is_empty() and farm.serialize()==before,"Duplicate route pieces are rejected atomically")
	check(farm.place("barn",Vector2(10,8),0).is_empty(),"Build barn for reserve and workbench")
	var barn_index:=farm.items.size()-1
	farm.inventory.carrot=80
	check(farm.transfer_reserve("carrot",true)==60,"Reserve caps at 60 products per barn")
	check(farm.inventory.carrot==20 and farm.reserve.carrot==60,"Transfer conserves products")
	check(farm.transfer_reserve("carrot",true)==0,"Full reserve refuses extra products")
	check(farm.sell_all()==240 and farm.reserve.carrot==60,"Sell all excludes protected reserve")
	check(not farm.deliver_contract(),"Contract cannot silently consume reserved products")
	before=farm.serialize()
	check(not farm.remove_item(barn_index).is_empty() and farm.serialize()==before,"Demolition cannot destroy reserved products")
	check(farm.move_item(barn_index,Vector2(10,8),1).is_empty() and farm.reserve.carrot==60,"Moving barn preserves reserve")
	check(farm.transfer_reserve("carrot",false)==60 and farm.inventory.carrot==60,"Withdrawal returns full product quantity")
	check(farm.deliver_contract() and farm.inventory.carrot==54,"Withdrawn products can satisfy contracts")
	check(farm.transfer_reserve("unknown",true)==0,"Unknown product is rejected")
	var balance:=farm.money
	check(farm.buy_watering_upgrade().is_empty() and farm.money==balance-300,"Upgrade has exact one-time cost")
	balance=farm.money
	check(not farm.buy_watering_upgrade().is_empty() and farm.money==balance,"Upgrade cannot charge twice")
	check(farm.paint_item(barn_index,"walls",1).is_empty(),"Paint walls")
	check(farm.items[barn_index].paint==1 and farm.items[barn_index].door_paint==0,"Wall paint does not change original door")
	farm.paint_item(barn_index,"roof",5)
	farm.paint_item(barn_index,"door",2)
	check(farm.items[barn_index].paint==1 and farm.items[barn_index].roof_paint==5 and farm.items[barn_index].door_paint==2,"All three paint channels are independent")
	check(not farm.paint_item(0,"roof",1).is_empty(),"Fence cannot receive roof color")
	check(not farm.paint_item(barn_index,"door",999).is_empty(),"Invalid color rejected")
	farm.transfer_reserve("carrot",true)
	var restored:=FarmState.new()
	check(restored.restore(JSON.parse_string(JSON.stringify(farm.serialize()))),"Version 2 schema roundtrip")
	check(restored.reserve==farm.reserve and restored.watering_upgrade,"Reserve and upgrade persist")
	check(restored.items[barn_index].door_paint==2 and restored.items[barn_index].roof_paint==5,"Independent colors persist")
	var invalid:=farm.serialize()
	invalid.reserve.carrot=61
	check(not restored.restore(invalid),"Over-capacity save rejected")
	invalid=farm.serialize()
	invalid.reserve.carrot=0.5
	check(not restored.restore(invalid),"Fractional reserve rejected")
	invalid=farm.serialize()
	invalid.items[barn_index].roof_paint=88
	check(not restored.restore(invalid),"Invalid saved paint rejected")
	invalid=farm.serialize()
	invalid.watering_upgrade="yes"
	check(not restored.restore(invalid),"Invalid saved upgrade rejected")
	check(restored.reserve==farm.reserve and restored.watering_upgrade,"Invalid restores preserve live state")
	var legacy:=farm.serialize()
	legacy.version=1
	legacy.erase("reserve")
	legacy.erase("watering_upgrade")
	for item in legacy.items:
		item.erase("door_paint")
		item.erase("roof_paint")
	check(restored.restore(legacy) and restored.reserve_count()==0 and not restored.watering_upgrade,"Old save gets empty reserve and basic watering can")
	check(restored.inventory==farm.inventory and restored.money==farm.money,"Migration preserves old inventory and money")
	farm.transfer_reserve("carrot",false)
	check(farm.remove_item(barn_index).is_empty() and farm.watering_upgrade,"Empty barn removable without losing permanent upgrade")
	check(farm.transfer_reserve("carrot",true)==0,"No reserve access without barn")
	var garden:=FarmState.new()
	garden.claim(Vector2(4,0))
	for at in [Vector2(4,0),Vector2(2,0),Vector2(6,0),Vector2(4,-2),Vector2(4,2),Vector2(6,2),Vector2(8,0)]: garden.place("plot",at,0)
	check(garden.water_targets(0)==[0],"Basic watering affects one plot")
	garden.tend(0)
	check(garden.count_items("plot",true)==1,"Basic action does not water neighbors")
	garden.items[0].watered=false
	garden.watering_upgrade=true
	check(garden.water_targets(0).size()==5,"Improved watering covers cross, excluding diagonal and distant plots")
	garden.tend(0)
	check(garden.count_items("plot",true)==5,"Improved action waters all five plots")
	check(garden.milestones.get("water",false),"Area watering advances care objective")
	garden.tick(32)
	garden.tend(0)
	check(garden.inventory.carrot==3 and garden.harvests==1,"Upgrade does not mass-harvest or duplicate yields")
	garden.tend(0)
	check(garden.items[0].planted and not garden.items[0].watered,"Replant still requires explicit watering")
	var broke:=FarmState.new()
	check(not broke.buy_watering_upgrade().is_empty() and broke.money==1600,"Upgrade requires barn")
	broke.claim(Vector2(4,0))
	broke.place("barn",Vector2(4,0),0)
	broke.money=299
	check(not broke.buy_watering_upgrade().is_empty() and broke.money==299,"Upgrade respects budget")
	print("V03_SIMULATION: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
