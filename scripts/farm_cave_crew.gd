class_name FarmCaveCrew
extends RefCounted

const NAMES:=["Grunho","Ferrugem","Vigia"]
const ORES:=["copper","iron","amethyst"]
const GIFTS:=["carrot","corn","cheese"]
const QUANTITIES:=[6,4,2]
const COSTS:=[240,600,1200]
const DENS:=[Vector2(897,-231),Vector2(886,-249),Vector2(898,-319)]
const WORK:=[Vector2(897,-234),Vector2(886,-252),Vector2(898,-322)]
const PERIOD:=120.0
const MEAL:=600.0
const FUEL_LIMIT:=1800.0

static func fresh() -> Array:
	var result:Array=[]
	for i in range(3):result.append({"joined":false,"paused":false,"fuel":0.0,"progress":0.0,"produced":0})
	return result

static func valid(data:Variant,resources:Dictionary,claimed:Variant) -> bool:
	if not claimed is bool or not data is Array or data.size()!=3:return false
	var total:=0
	for i in range(3):
		var entry:Variant=data[i]
		if not entry is Dictionary or entry.size()!=5:return false
		if not entry.get("joined") is bool or not entry.get("paused") is bool:return false
		for key in ["fuel","progress"]:
			if not (entry.get(key) is float or entry.get(key) is int) or not is_finite(float(entry[key])) or entry[key]<0:return false
		if entry.fuel>FUEL_LIMIT or entry.progress>=PERIOD:return false
		if not FarmResources._integer(entry.get("produced"),FarmResources.MAX_COUNTER):return false
		total+=int(entry.produced)
		if not entry.joined and (entry.paused or entry.fuel!=0 or entry.progress!=0 or entry.produced!=0):return false
		if entry.joined and (not claimed or not resources.mine_owned or not resources.pickaxe or resources.gallery_level<i):return false
	return total<=int(resources.mined)

static func normalized(data:Array) -> Array:
	var result:=data.duplicate(true)
	for entry in result:
		entry.fuel=float(entry.fuel);entry.progress=float(entry.progress);entry.produced=int(entry.produced)
	return result

static func active(state:FarmState,i:int) -> bool:
	var entry:Dictionary=state.cave_crew[i]
	return entry.joined and not entry.paused and entry.fuel>0 and state.resources.stock[ORES[i]]<FarmResources.STOCK_LIMIT and state.resources.mined<FarmResources.MAX_COUNTER and entry.produced<FarmResources.MAX_COUNTER

static func tick(state:FarmState,delta:float) -> void:
	if not state.claimed or not is_finite(delta) or delta<=0:return
	for i in range(3):
		if not active(state,i):continue
		var entry:Dictionary=state.cave_crew[i]
		var room:=mini(FarmResources.STOCK_LIMIT-int(state.resources.stock[ORES[i]]),mini(FarmResources.MAX_COUNTER-int(state.resources.mined),FarmResources.MAX_COUNTER-int(entry.produced)))
		var span:=minf(delta,minf(float(entry.fuel),float(room)*PERIOD-float(entry.progress)))
		var progress:=float(entry.progress)+span
		var count:=floori((progress+.000001)/PERIOD)
		entry.progress=maxf(0,progress-count*PERIOD)
		entry.fuel=maxf(0,float(entry.fuel)-span)
		entry.produced+=count;state.resources.stock[ORES[i]]+=count;state.resources.mined+=count

static func run(state:FarmState,action:String) -> String:
	var parts:=action.split(":")
	if parts.size()!=3 or parts[0]!="cave" or parts[1] not in ["recruit","feed","pause"] or parts[2] not in ["0","1","2"]:return "Ajudante desconhecido."
	var i:=int(parts[2])
	if not state.claimed or not state.resources.mine_owned or not state.resources.pickaxe or state.resources.gallery_level<i:return "Compre a mina, a picareta e abra esta galeria primeiro."
	var entry:Dictionary=state.cave_crew[i]
	if parts[1]=="recruit":
		if entry.joined:return "Este ajudante já está com você."
		if state.money<COSTS[i]:return "Falta dinheiro para preparar o abrigo."
		if state.stock(GIFTS[i])<QUANTITIES[i]:return "Traga a comida favorita dele da fazenda."
		state.money-=COSTS[i];state.consume_stock(GIFTS[i],QUANTITIES[i])
		entry.joined=true;entry.fuel=MEAL
		return ""
	if not entry.joined:return "Conquiste a confiança dele primeiro."
	if parts[1]=="pause":entry.paused=not entry.paused;return ""
	if entry.fuel>FUEL_LIMIT-MEAL:return "Ele já tem comida suficiente. Espere consumir mais."
	if state.stock("wheat")<5 or state.stock("egg")<2:return "A refeição precisa de 5 trigos e 2 ovos."
	state.consume_stock("wheat",5);state.consume_stock("egg",2);entry.fuel+=MEAL
	return ""
