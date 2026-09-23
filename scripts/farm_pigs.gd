class_name FarmPigs
extends RefCounted
const CAPACITY:=3
const COST:=240
const NAMES:=["Bolota","Paçoca","Jujuba"]

static func fresh() -> Dictionary:
	return {"count":0,"food":100.0,"water":100.0}

static func valid(data:Variant) -> bool:
	if not data is Dictionary:return false
	var count:Variant=data.get("count")
	if not (count is int or count is float) or not is_finite(float(count)) or count!=floorf(float(count)) or count<0 or count>CAPACITY:return false
	for key in ["food","water"]:
		var value:Variant=data.get(key)
		if not (value is int or value is float) or not is_finite(float(value)) or value<0 or value>100:return false
	return true

static func tick(data:Dictionary,delta:float) -> void:
	if not is_finite(delta) or delta<=0:return
	data.food=maxf(0,float(data.food)-delta*float(data.count)/6.0)
	data.water=maxf(0,float(data.water)-delta*float(data.count)/4.8)

static func food_cost(data:Dictionary) -> int:
	return maxi(0,ceili((100.0-float(data.food))*.12-.000001))

static func status(data:Dictionary) -> String:
	if data.count==0:return "Uma nova companhia para a fazenda"
	if data.food<=0 and data.water<=0:return "Precisam de ração e água"
	if data.food<=0:return "Precisam de ração"
	if data.water<=0:return "Precisam de água"
	return "Repor em breve" if minf(data.food,data.water)<25 else "Bem cuidados"

static func care(state:FarmState,index:int,action:String) -> String:
	if index<0 or index>=state.items.size() or state.items[index].kind!="pigsty":return "Escolha um chiqueiro."
	var data:Dictionary=state.items[index].pigs
	if action=="buy":
		if data.count>=CAPACITY:return "O chiqueiro já tem três porcos."
		if state.money<COST:return "Faltam moedas para comprar o porco."
		state.money-=COST;data.count=int(data.count)+1;return ""
	if action not in ["food","water"]:return "Cuidado inválido."
	if data.count==0:return "Compre o primeiro porco."
	if action=="food":
		var cost:=food_cost(data)
		if state.money<cost:return "Faltam moedas para a ração."
		state.money-=cost;data.food=100.0
	else:data.water=100.0
	return ""
