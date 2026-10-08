class_name FarmDairy
extends RefCounted
const COW_COST:=480
const MILK_PRICE:=18
const CAPACITY:=8
const CYCLE:=60.0
static func fresh() -> Dictionary:
	return {"owned":false,"name":"Mimosa","food":100.0,"water":100.0,"milk":0,"timer":0.0}
static func valid(data:Variant) -> bool:
	if not data is Dictionary or not data.get("owned") is bool or not data.get("name") is String: return false
	if not FarmAnimals.valid_name(data.name): return false
	for key in ["food","water","milk","timer"]:
		if not FarmCultivation.integer(data.get(key)) and (key=="milk" or not (data.get(key) is float or data.get(key) is int)): return false
		if not is_finite(float(data[key])) or data[key]<0: return false
	return data.food<=100 and data.water<=100 and data.milk<=CAPACITY and data.timer<CYCLE and (data.owned or (data.milk==0 and data.timer==0))
static func tick(data:Dictionary,delta:float,bonus:float=1.0) -> void:
	if not data.owned: return
	var span:=maxf(0,delta)
	var productive:=minf(span,minf(float(data.food)*6,float(data.water)*4.8))
	if data.milk<CAPACITY:
		var progress:float=data.timer+productive*bonus
		var cycles:=int(floorf((progress+0.00000001)/CYCLE))
		data.milk=mini(CAPACITY,int(data.milk)+cycles*2)
		data.timer=0.0 if data.milk==CAPACITY else maxf(0,progress-cycles*CYCLE)
	data.food=maxf(0,float(data.food)-span/6)
	data.water=maxf(0,float(data.water)-span/4.8)
static func care(state:FarmState,index:int,action:String,manual:bool=true) -> String:
	if index<0 or index>=state.items.size() or state.items[index].kind!="corral": return "Escolha um curral."
	if action=="milk" and state.temporary_down.get(FarmFallTargets.item_key(state,index,"cow"),false):return "Espere Mimosa se recuperar para ordenhar."
	var data:Dictionary=state.items[index].dairy
	if action=="buy":
		if data.owned: return "Este curral já tem uma vaca."
		if state.money<COW_COST: return "Faltam moedas para comprar a vaca."
		state.money-=COW_COST; data.owned=true
		if state.items[index].has("young_ages"):state.items[index].young_ages.append(FarmYoung.DURATIONS.corral)
		return ""
	if not data.owned: return "Compre a primeira vaca."
	match action:
		"food":
			var cost:=ceili((100-data.food)*0.12-0.000001)
			if state.money<cost: return "Faltam moedas para a ração."
			state.money-=cost; data.food=100.0
		"water": data.water=100.0
		"milk":
			if data.milk==0: return "Ainda não há leite para coletar."
			state.earn_xp(int(data.milk)*FarmLevels.MILK)
			if manual:FarmSkills.earn(state,"handling",int(data.milk)*2)
			state.milk_stock+=int(data.milk); data.milk=0
		_: return "Ação desconhecida."
	return ""
static func sell(state:FarmState,amount:int) -> int:
	if amount<=0 or amount>state.stock("milk"): return 0
	var total:=amount*MILK_PRICE
	state.consume_stock("milk",amount); state.money+=total; state.revenue+=total
	state.refresh_journey()
	return total
