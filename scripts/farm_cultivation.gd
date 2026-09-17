class_name FarmCultivation
extends RefCounted
## Budget is a cumulative authorization, renewed explicitly, never by time or load.

static func fresh() -> Dictionary:
	return {"enabled":false,"plans":[],"tasks":{"water":true,"harvest":true,"plant":true},"limit":100,"spent":0,"services":0,"seeds":0,"actions":{"water":0,"harvest":0,"plant":0},"produced":{"carrot":0,"wheat":0,"corn":0},"sown":{"carrot":0,"wheat":0,"corn":0}}

static func integer(value:Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value>=0 and float(value)==floorf(float(value))

static func valid(data:Variant,items:Array) -> bool:
	if not data is Dictionary or not data.get("enabled") is bool or not data.get("plans") is Array or not data.get("tasks") is Dictionary: return false
	for key in ["water","harvest","plant"]:
		if not data.tasks.get(key) is bool: return false
	for key in ["limit","spent","services","seeds"]:
		if not integer(data.get(key)): return false
	if data.limit>1000000 or data.spent>data.services+data.seeds: return false
	for group in ["actions","produced","sown"]:
		if not data.get(group) is Dictionary: return false
		for key in (["water","harvest","plant"] if group=="actions" else ["carrot","wheat","corn"]):
			if not integer(data[group].get(key)): return false
	var seen:Array=[]
	for plan in data.plans:
		if not plan is Dictionary or not integer(plan.get("index")) or plan.index>=items.size(): return false
		if int(plan.index) in seen or items[int(plan.index)].kind!="plot" or not FarmState.CROPS.has(plan.get("crop","")): return false
		seen.append(int(plan.index))
	if data.enabled and (seen.is_empty() or not (data.tasks.water or data.tasks.harvest or data.tasks.plant)): return false
	return true

static func configure(farm,plans:Array,tasks:Dictionary,limit:int) -> String:
	if not farm.field_staff.hired: return "Contrate Bento em H → Equipe primeiro."
	var candidate:Dictionary=farm.cultivation.duplicate(true)
	candidate.enabled=true
	candidate.plans=plans.duplicate(true)
	candidate.tasks=tasks.duplicate()
	candidate.limit=limit
	if not valid(candidate,farm.items): return "Escolha canteiros, culturas, ao menos uma tarefa e orçamento de $0 a $1.000.000."
	farm.cultivation=candidate
	farm.irrigation.enabled=true
	farm.irrigation.plots=[]
	for plan in plans: farm.irrigation.plots.append(int(plan.index))
	farm.field_staff.paused=false
	farm.field_staff.reason=""
	return ""

static func plan_for(farm,index:int) -> Dictionary:
	for plan in farm.cultivation.plans:
		if int(plan.index)==index: return plan
	return {}

static func job(farm,index:int) -> String:
	if not farm.cultivation.enabled or not farm.field_staff.hired or index<0 or index>=farm.items.size(): return ""
	if plan_for(farm,index).is_empty(): return ""
	var item:Dictionary=farm.items[index]
	var tasks:Dictionary=farm.cultivation.tasks
	if not item.planted: return "plant" if tasks.plant else ""
	if item.growth>=1: return "harvest" if tasks.harvest else ""
	if not item.watered and tasks.water: return "water"
	return ""

static func cost(farm,index:int,action:String) -> int:
	var seed_cost:=0
	if action=="plant":
		var plan:=plan_for(farm,index)
		if plan.is_empty(): return 0
		seed_cost=int(FarmState.CROPS[plan.crop].seed)
	return FarmCrew.fee(farm.field_staff)+seed_cost

static func authorize(farm,index:int,action:String) -> String:
	if farm.field_staff.paused or action.is_empty() or job(farm,index)!=action: return "Tarefa não está disponível."
	var price:=cost(farm,index,action)
	var reason:="budget" if farm.cultivation.spent+price>farm.cultivation.limit else ("funds" if farm.money<price else "")
	if reason.is_empty(): return ""
	farm.field_staff.paused=true
	farm.field_staff.reason=reason
	farm.staff_notice="Bento pausou: a próxima tarefa custa $%d. %s"%[price,"Renove ou aumente o orçamento em H → Equipe → Rotina." if reason=="budget" else "Falta saldo na fazenda. Retome quando houver moedas."]
	return farm.staff_notice

static func complete(farm,index:int,action:String) -> String:
	var error:=authorize(farm,index,action)
	if not error.is_empty(): return error
	var item:Dictionary=farm.items[index]
	var price:=cost(farm,index,action)
	var fee:=FarmCrew.fee(farm.field_staff)
	var ledger:Dictionary=farm.cultivation
	# Recheck and commit the full service and seed price atomically at completion.
	farm.money-=price
	farm.field_staff.spent+=price
	ledger.spent+=price
	ledger.services+=fee
	ledger.seeds+=price-fee
	ledger.actions[action]+=1
	match action:
		"water":
			item.watered=true
			farm.field_staff.watered+=1
			farm.irrigation.watered+=1
			farm.irrigation.spent+=fee
		"harvest":
			var amount:int=FarmState.CROPS[item.crop]["yield"]
			farm.inventory[item.crop]+=amount
			ledger.produced[item.crop]+=amount
			farm.harvests+=1
			item.planted=false; item.watered=false; item.growth=0.0
		"plant":
			item.crop=plan_for(farm,index).crop
			item.planted=true; item.watered=false; item.growth=0.0
			ledger.sown[item.crop]+=1
	farm.refresh_journey()
	return ""

static func renew(farm) -> String:
	if not farm.field_staff.hired or not farm.cultivation.enabled: return "Ative a rotina de Bento primeiro."
	if farm.cultivation.limit<=0: return "Defina um orçamento maior que zero."
	farm.cultivation.spent=0
	farm.field_staff.paused=false
	farm.field_staff.reason=""
	return ""

static func remove(farm,index:int) -> void:
	var remaining:Array=[]
	for plan in farm.cultivation.plans:
		if int(plan.index)==index: continue
		var changed:Dictionary=plan.duplicate()
		if changed.index>index: changed.index=int(changed.index)-1
		remaining.append(changed)
	farm.cultivation.plans=remaining
	if remaining.is_empty() and farm.cultivation.enabled:
		farm.cultivation.enabled=false
		farm.field_staff.paused=true
		farm.field_staff.reason="removed"
