class_name FarmCheese
extends RefCounted
const PRICE:=52
const SECONDS:=90.0
const MAX_BATCH:=4
static func fresh() -> Dictionary:
	return {"batch":0,"remaining":0.0,"ready":0}
static func valid(data:Variant) -> bool:
	if not data is Dictionary: return false
	for key in ["batch","ready"]:
		if not FarmCultivation.integer(data.get(key)) or data[key]>MAX_BATCH: return false
	var time:Variant=data.get("remaining")
	if not (time is float or time is int) or not is_finite(float(time)) or time<0 or time>SECONDS: return false
	return (data.batch>0 and time>0 and data.ready==0) or (data.batch==0 and time==0)
static func valid_order(data:Variant) -> bool:
	return data is Dictionary and data.get("active") is bool and FarmCultivation.integer(data.get("cycle"))
static func tick(data:Dictionary,delta:float) -> void:
	if data.batch<=0: return
	data.remaining=maxf(0,float(data.remaining)-maxf(0,delta))
	if data.remaining<=0.000001:
		data.ready=int(data.batch);data.batch=0;data.remaining=0.0
static func start(state:FarmState,index:int,amount:int) -> String:
	if index<0 or index>=state.items.size() or state.items[index].kind!="cheesery": return "Escolha uma queijaria."
	var data:Dictionary=state.items[index].cheese
	if data.batch>0 or data.ready>0: return "Recolha o lote antes de produzir outro."
	if amount<1 or amount>MAX_BATCH: return "Escolha de 1 a 4 queijos."
	if state.milk_stock<amount*2: return "Falta leite no estoque. Colete no curral."
	state.milk_stock-=amount*2;data.batch=amount;data.remaining=SECONDS
	return ""
static func collect(state:FarmState,index:int) -> int:
	if index<0 or index>=state.items.size() or state.items[index].kind!="cheesery": return 0
	var data:Dictionary=state.items[index].cheese
	var amount:=int(data.ready)
	state.cheese_stock+=amount;data.ready=0
	state.earn_xp(amount*FarmLevels.CHEESE)
	return amount
static func sell(state:FarmState,amount:int) -> int:
	if amount<1 or amount>state.cheese_stock: return 0
	state.cheese_stock-=amount;state.money+=amount*PRICE;state.revenue+=amount*PRICE
	state.refresh_journey()
	return amount*PRICE
static func order_amount(state:FarmState) -> int:
	return 3+int(state.cheese_order.cycle)%3
static func deliver(state:FarmState) -> bool:
	var amount:=order_amount(state)
	if not state.cheese_order.active or state.cheese_stock<amount: return false
	state.cheese_stock-=amount;state.money+=amount*64;state.revenue+=amount*64
	state.cheese_order.active=false;state.cheese_order.cycle+=1
	state.earn_xp(FarmLevels.ORDER)
	state.trade.nena.reputation+=1;state.refresh_journey()
	return true
