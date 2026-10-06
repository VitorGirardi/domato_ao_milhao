class_name FarmOrchardStaff
extends RefCounted

static func fresh() -> Dictionary:
	return {"enabled":false,"paused":true,"trees":[],"services":0,"oranges":0,"spent":0,"reason":""}

static func unlocked(state:FarmState) -> bool:
	return state.infinite_resources() or state.orchard_journey.stage==2

static func active(state:FarmState) -> bool:
	return state.orchard_staff.enabled and not state.orchard_staff.paused and state.staff.hired

static func valid(data:Variant,items:Array) -> bool:
	if not data is Dictionary or data.size()!=7:return false
	if not data.get("enabled") is bool or not data.get("paused") is bool or not data.get("trees") is Array:return false
	if data.trees.size()>64 or (not data.enabled and not data.paused):return false
	if data.enabled and data.trees.is_empty() and not data.paused:return false
	if data.get("reason") not in ["","manual","funds","removed","blocked"]:return false
	for key in ["services","oranges","spent"]:
		var value:Variant=data.get(key)
		if not (value is int or value is float) or not is_finite(float(value)) or value<0 or value>1000000000 or value!=floorf(float(value)):return false
	if data.oranges>data.services*FarmOrchard.YIELD:return false
	var seen:Array[int]=[]
	for index in data.trees:
		if not (index is int or index is float) or not is_finite(float(index)) or index!=floorf(float(index)) or index<0 or index>=items.size():return false
		if int(index) in seen or items[int(index)].kind!="orchard":return false
		seen.append(int(index))
	return true

static func _exclusive(state:FarmState) -> void:
	state.staff.paused=true;state.staff.timer=0.0
	if not state.field_staff.hired:state.irrigation.enabled=false

static func configure(state:FarmState,indices:Array) -> String:
	if not state.claimed:return "Escolha seu terreno primeiro."
	if not unlocked(state):return "Conclua a primeira colheita para liberar Zeca no pomar."
	if indices.is_empty() or indices.size()>64:return "Escolha de 1 a 64 laranjeiras produtivas."
	var candidate:=state.orchard_staff.duplicate(true)
	candidate.trees=indices.duplicate();candidate.enabled=true;candidate.paused=false;candidate.reason=""
	if not valid(candidate,state.items):return "Selecione laranjeiras produtivas distintas da fazenda."
	var cost:=FarmStaff.HIRE_COST if not state.staff.hired and not state.infinite_resources() else 0
	if state.money<cost:return "Contratar Zeca custa $120."
	state.money-=cost;state.staff.spent+=cost;state.staff.hired=true
	for i in range(candidate.trees.size()):candidate.trees[i]=int(candidate.trees[i])
	state.orchard_staff=candidate
	_exclusive(state)
	return ""

static func pause(state:FarmState) -> String:
	var worker:Dictionary=state.orchard_staff
	if not worker.enabled or not state.staff.hired:return "Ative Zeca no pomar primeiro."
	if worker.paused and worker.trees.is_empty():return "Escolha as laranjeiras antes de retomar."
	worker.paused=not worker.paused
	worker.reason="manual" if worker.paused else ""
	if not worker.paused:_exclusive(state)
	return ""

static func stop(state:FarmState) -> void:
	state.orchard_staff.enabled=false;state.orchard_staff.paused=true;state.orchard_staff.reason=""

static func job(state:FarmState,index:int) -> String:
	if not active(state) or state.temporary_down.get("npc:staff",false) or index not in state.orchard_staff.trees:return ""
	if index<0 or index>=state.items.size() or state.items[index].kind!="orchard":return ""
	var tree:Dictionary=state.items[index].orchard
	if tree.ready==FarmOrchard.YIELD:return "harvest"
	return "water" if not tree.watered else ""

static func complete(state:FarmState,index:int,kind:String) -> String:
	if kind not in ["water","harvest"] or job(state,index)!=kind:return "Nenhum serviço disponível nesta laranjeira."
	var worker:Dictionary=state.orchard_staff
	var cost:=0 if state.infinite_resources() else FarmCrew.fee(state.staff)
	if kind=="harvest" and state.inventory.orange>1000000000-FarmOrchard.YIELD:return "Estoque de laranjas cheio."
	if worker.services>=1000000000 or worker.spent>1000000000-cost or (kind=="harvest" and worker.oranges>1000000000-FarmOrchard.YIELD):return "Limite de serviços atingido."
	if state.money<cost:
		worker.paused=true;worker.reason="funds"
		return "Zeca pausou: faltam moedas para cuidar do pomar."
	var error:=FarmOrchard.water(state,index) if kind=="water" else FarmOrchard.harvest(state,index)
	if not error.is_empty():return error
	state.money-=cost;state.staff.spent+=cost
	worker.spent+=cost;worker.services+=1;worker.reason=""
	if kind=="harvest":worker.oranges+=FarmOrchard.YIELD
	return ""

static func remove(state:FarmState,index:int) -> void:
	var trees:Array=[]
	for selected in state.orchard_staff.trees:
		if selected!=index:trees.append(int(selected)-1 if selected>index else int(selected))
	state.orchard_staff.trees=trees
	if state.orchard_staff.enabled and trees.is_empty():
		state.orchard_staff.paused=true;state.orchard_staff.reason="removed"
