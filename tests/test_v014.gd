extends SceneTree
var checks:=0
func check(ok:bool,why:String) -> void:
	checks+=1; assert(ok,why)
func _initialize() -> void:
	var farm:=FarmState.new(); farm.claim(Vector2(4,-2)); farm.money=5000
	check(farm.place("corral",Vector2(4,0),0).is_empty(),"Build corral")
	var data:Dictionary=farm.items[0].dairy
	var money:=farm.money
	farm.tick(120)
	check(data.milk==0 and data.food==100,"Empty pen has no production or consumption")
	check(FarmDairy.care(farm,0,"buy").is_empty() and farm.money==money-480,"Single cow purchase")
	money=farm.money
	check(not FarmDairy.care(farm,0,"buy").is_empty() and farm.money==money,"No duplicate purchase")
	farm.tick(60)
	check(data.milk==2 and data.food==90 and data.water==87.5,"Milk and needs tick")
	check(FarmDairy.care(farm,0,"milk").is_empty() and farm.milk_stock==2 and data.milk==0,"Collect exactly once")
	check(not FarmDairy.care(farm,0,"milk").is_empty() and farm.milk_stock==2,"No duplicate collection")
	check(FarmDairy.sell(farm,1)==18 and farm.milk_stock==1,"Partial sale")
	check(FarmDairy.sell(farm,2)==0 and farm.milk_stock==1,"Oversale rejected")
	var price:=farm.sale_value()
	check(price==18 and farm.sell_all()==18 and farm.milk_stock==0,"Bulk includes milk")
	farm.tick(240)
	check(data.milk==8 and data.timer==0,"Capacity halts production")
	var stored:int=data.milk; farm.tick(60)
	check(data.milk==stored,"No overflow")
	FarmDairy.care(farm,0,"milk")
	data.food=0; data.water=100
	farm.tick(60)
	check(data.milk==0,"Food depleted pauses production")
	farm.money=0
	check(not FarmDairy.care(farm,0,"food").is_empty() and data.food==0 and farm.money==0,"Feed purchase atomic")
	farm.money=100; money=farm.money
	check(FarmDairy.care(farm,0,"food").is_empty() and farm.money==money-12,"Feed refill cost")
	data.water=0; farm.tick(60)
	check(data.milk==0,"Water depleted pauses production")
	check(FarmDairy.care(farm,0,"water").is_empty() and farm.money==money-12,"Water is free")
	farm.tick(60); check(data.milk==2,"Production resumes")
	var restored:=FarmState.new()
	check(restored.restore(JSON.parse_string(JSON.stringify(farm.serialize()))) and restored.items[0].dairy.milk==data.milk and restored.items[0].dairy.owned and is_equal_approx(restored.items[0].dairy.food,data.food) and is_equal_approx(restored.items[0].dairy.water,data.water) and is_equal_approx(restored.items[0].dairy.timer,data.timer) and restored.milk_stock==farm.milk_stock,"Save persists cow, needs, milk")
	var before:=restored.serialize(); var bad:=farm.serialize(); bad.items[0].dairy.milk=9
	check(not restored.restore(bad) and restored.serialize()==before,"Corrupt capacity rejected atomically")
	bad=farm.serialize();bad.items[0].dairy.milk=1.5
	check(not restored.restore(bad),"Fractional milk invalid")
	bad=farm.serialize();bad.milk_stock=-1
	check(not restored.restore(bad),"Negative stock invalid")
	check(not farm.remove_item(0).is_empty(),"Occupied pen protected from deletion")
	check(farm.move_item(0,Vector2(4,-4),1).is_empty() and farm.items[0].dairy==data,"Move keeps animal and milk")
	var old:=FarmState.new().serialize();old.version=9;old.erase("milk_stock")
	check(restored.restore(old) and restored.milk_stock==0,"Old save migration")
	var large:=FarmDairy.fresh();large.owned=true
	var small:=large.duplicate(); FarmDairy.tick(large,535)
	for i in range(535): FarmDairy.tick(small,1)
	check(large.milk==small.milk and absf(large.food-small.food)<0.00001 and absf(large.water-small.water)<0.00001,"Tick partition independent")
	print("V014_STATE_OK: %d checks"%checks)
	quit()
