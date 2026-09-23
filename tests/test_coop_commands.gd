extends SceneTree
var s:=FarmState.new()
var count:=0
func _initialize() -> void:call_deferred("run")
func act(c:Dictionary) -> void:
	var before:=s.serialize()
	var result:=FarmCoopCommands.run(s,c)
	assert(s.serialize()!=before,"Command did not change state: "+str(c)+" "+result)
	var copy:=FarmState.new();assert(copy.restore(s.serialize()),"Invalid state: "+str(c))
	count+=1
func build(kind:String) -> int:
	for z in range(-16,17,2):
		for x in range(-12,21,2):
			if s.can_place(kind,Vector2(x,z),0).is_empty():
				act({"action":"place","kind":kind,"at":Vector2(x,z),"turn":0,"crop":"carrot"});return s.items.size()-1
	assert(false,"No site for "+kind);return -1
func run() -> void:
	s.unlimited_money=true;s.farm_xp=10000
	act({"action":"claim","at":Vector2(4,0)})
	act({"action":"tool:expand"});act({"action":"tool:expand"})
	var plot:=build("plot")
	var barn:=build("barn")
	var coop:=build("coop")
	var corral:=build("corral")
	var cheese:=build("cheesery")
	var shop:=build("workshop")
	act({"action":"evolution_buy:"+str(barn),"index":barn})
	act({"action":"evolution_buy:"+str(shop),"index":shop})
	act({"action":"upgrade"});act({"action":"professional_watering"})
	act({"action":"paint:2","part":"walls","index":barn})
	s.inventory.carrot=100
	act({"action":"deposit:carrot"});act({"action":"withdraw:carrot"})
	act({"action":"sell_product:carrot","quantity":2})
	act({"action":"contract"})
	for key in s.trade:
		act({"action":"accept_order:"+key})
		for product in s.inventory:s.inventory[product]=1000
		act({"action":"deliver_order:"+key})
		act({"action":"accept_order:"+key});act({"action":"cancel_order:"+key})
	s.items[coop].flock.food=20;s.items[coop].flock.water=10;s.items[coop].flock.nest=6
	for care in ["food","water","collect"]:act({"action":"care:"+care,"index":coop})
	act({"action":"apply_hen_name","index":coop,"hen":0,"text":"Ianinha"})
	act({"action":"dairy:buy","index":corral})
	s.items[corral].dairy.food=10;s.items[corral].dairy.water=10
	for care in ["food","water"]:act({"action":"dairy:"+care,"index":corral})
	FarmDairy.tick(s.items[corral].dairy,1000)
	act({"action":"dairy:milk","index":corral})
	s.milk_stock=100
	act({"action":"sell_milk","quantity":2})
	act({"action":"cheese:start","index":cheese,"batch":1})
	FarmCheese.tick(s.items[cheese].cheese,1000)
	act({"action":"cheese:collect","index":cheese})
	act({"action":"cheese:sell","quantity":1})
	s.cheese_stock=100
	act({"action":"cheese:accept"});act({"action":"cheese:deliver"})
	act({"action":"staff_hire","site":coop});act({"action":"staff_pause"});act({"action":"staff_pause"})
	act({"action":"crew_hire"})
	act({"action":"irrigation_apply","plots":[plot]})
	act({"action":"cultivation_apply","draft":{"plans":[{"index":plot,"crop":"corn"}],"tasks":{"plant":true,"water":true,"harvest":true},"limit":100}})
	act({"action":"crew_pause"});act({"action":"crew_pause"})
	for role in ["raul","chico"]:
		act({"action":role+":confirm","operation":"hire"})
		act({"action":role+":confirm","operation":"apply","site":corral if role=="raul" else cheese,"batch":1,"budget":100})
		act({"action":role+":pause"});act({"action":role+":pause"})
		act({"action":role+":confirm","operation":"dismiss"})
	act({"action":"staff_dismiss"});act({"action":"crew_dismiss"})
	act({"action":"remove","index":plot})
	var before:=s.serialize()
	for bad in [{"action":"place","kind":"bad","at":Vector2.ZERO},{"action":"dairy:buy","index":999},{"action":"route_confirm","plan":[{}]},{"action":"sell_product:carrot","quantity":-1},{"action":"reset_confirm"},{"action":"move_item","index":0,"at":Vector2(INF,0)}]:
		assert(not FarmCoopCommands.run(s,bad).is_empty());assert(s.serialize()==before)
	print("COOP_COMMANDS_OK: ",count," construction/trade/animal/worker mutations and malformed requests")
	quit()
