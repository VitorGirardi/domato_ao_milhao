extends SceneTree
var checks:=0
func check(value:bool,why:String) -> void:
	checks+=1
	if not value: push_error(why);quit(1);assert(value,why)
func _initialize() -> void:
	var farm:=FarmState.new();farm.claim(Vector2(4,-2));farm.money=5000;farm.milk_stock=8
	check(farm.place("cheesery",Vector2(4,0),0).is_empty() and farm.money==4100,"Building price")
	check(not FarmCheese.start(farm,0,0).is_empty() and not FarmCheese.start(farm,0,5).is_empty(),"Batch bounds")
	check(not FarmCheese.start(farm,-1,1).is_empty(),"Invalid target")
	check(FarmCheese.start(farm,0,4).is_empty() and farm.milk_stock==0,"Consume milk once")
	check(not FarmCheese.start(farm,0,1).is_empty() and farm.milk_stock==0,"No second active batch")
	check(not farm.remove_item(0).is_empty(),"Cannot delete consumed input")
	farm.tick(35)
	check(farm.items[0].cheese.remaining==55 and farm.items[0].cheese.ready==0,"Progress only by active time")
	check(FarmCheese.collect(farm,0)==0,"Cannot collect early")
	var moved:Dictionary=farm.items[0].cheese.duplicate()
	check(farm.move_item(0,Vector2(6,-2),1).is_empty() and farm.items[0].cheese==moved,"Moving preserves batch")
	var restored:=FarmState.new()
	check(restored.restore(JSON.parse_string(JSON.stringify(farm.serialize()))) and restored.items[0].cheese.remaining==55,"In-progress save")
	restored.tick(1000)
	check(restored.items[0].cheese.ready==4 and restored.items[0].cheese.batch==0,"No overproduction on large tick")
	check(not restored.remove_item(0).is_empty(),"Uncollected cheese protected")
	var alerts:=FarmFieldAlerts.new()
	check(alerts.poll(restored).begins_with("Queijo pronto") and alerts.poll(restored).is_empty(),"One ready notification")
	check(FarmCheese.collect(restored,0)==4 and FarmCheese.collect(restored,0)==0 and restored.cheese_stock==4,"Collect once")
	check(FarmCheese.sell(restored,5)==0 and FarmCheese.sell(restored,-1)==0,"No excessive/negative sales")
	check(FarmCheese.sell(restored,1)==52 and restored.cheese_stock==3,"Partial cheese sale")
	check(not FarmCheese.deliver(restored),"Must accept before delivery")
	restored.cheese_order.active=true
	check(restored.active_orders()==1,"Count cheese order")
	var money:=restored.money;var reputation:int=restored.trade.nena.reputation
	check(FarmCheese.deliver(restored) and restored.money==money+192 and restored.cheese_stock==0 and restored.trade.nena.reputation==reputation+1,"Delivery consumes and pays exactly")
	check(not FarmCheese.deliver(restored) and restored.money==money+192,"No duplicate reward")
	check(FarmCheese.order_amount(restored)==4,"Next cheese request")
	restored.cheese_order.active=true
	check(not FarmCheese.deliver(restored),"Insufficient stock keeps order")
	var disk:=restored.serialize();var copy:=FarmState.new()
	check(copy.restore(disk) and copy.cheese_order==restored.cheese_order,"Order persisted")
	var baseline:=copy.serialize()
	for bad_value in [-1,1.5,"3",INF]:
		var bad:=disk.duplicate(true);bad.cheese_stock=bad_value
		check(not copy.restore(bad) and copy.serialize()==baseline,"Invalid stock rejected atomically")
	for bad_data in [{"batch":5,"remaining":90,"ready":0},{"batch":2,"remaining":0,"ready":0},{"batch":1,"remaining":20,"ready":1},{"batch":0,"remaining":1,"ready":0}]:
		var bad:=disk.duplicate(true);bad.items[0].cheese=bad_data
		check(not copy.restore(bad) and copy.serialize()==baseline,"Invalid batch rejected atomically")
	var old:=FarmState.new();old.milk_stock=7
	var old_disk:=old.serialize();old_disk.version=10;old_disk.erase("cheese_stock");old_disk.erase("cheese_order")
	check(copy.restore(old_disk) and copy.cheese_stock==0 and not copy.cheese_order.active and copy.milk_stock==7,"v10 migration preserves milk")
	var missing:=disk.duplicate(true);missing.erase("cheese_stock")
	check(not copy.restore(missing),"v11 requires cheese stock")
	copy.cheese_stock=2;copy.milk_stock=3;copy.inventory.carrot=1
	check(copy.sale_value()==170 and copy.sell_all()==170 and copy.cheese_stock==0 and copy.milk_stock==0,"Bulk sale includes cheese exactly once")
	var a:=FarmCheese.fresh();a.batch=3;a.remaining=90
	var b:=a.duplicate();FarmCheese.tick(a,95)
	for i in range(950):FarmCheese.tick(b,.1)
	check(a==b,"Tick partition independent")
	check(restored.remove_item(0).is_empty(),"Can remove empty cheesery")
	print("V016_STATE_OK: %d checks"%checks);quit()
