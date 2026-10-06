class_name FarmAnimalCare
extends RefCounted
## Optional comfort is saved with its enclosure; only active simulation ages it.
const DURATION:=480.0
const MULTIPLIER:=1.2
const KINDS:=["coop","corral","pigsty"]
const TITLES:={"coop":"Ninho aconchegante","corral":"Escovação da Mimosa","pigsty":"Banho de lama"}
const ACTIONS:={"coop":"Renovar a palha","corral":"Escovar a vaca","pigsty":"Preparar a lama"}

static func fresh() -> Dictionary:
	return {"seconds":0.0,"visits":0}

static func valid(value:Variant) -> bool:
	if not value is Dictionary or value.size()!=2:return false
	for key in ["seconds","visits"]:
		var n:Variant=value.get(key)
		if not (n is int or n is float) or not is_finite(float(n)) or n<0:return false
	return value.seconds<=DURATION and value.visits<=1000000 and value.visits==floorf(value.visits) and (value.visits>0 or value.seconds==0)

static func seconds(item:Dictionary) -> float:
	return float(item.get("animal_care",{}).get("seconds",0))

static func multiplier(item:Dictionary) -> float:
	return MULTIPLIER if seconds(item)>0 else 1.0

static func production_wait(item:Dictionary,progress:float) -> float:
	var boosted:=minf(seconds(item),maxf(0,progress)/MULTIPLIER)
	return boosted+maxf(0,progress-boosted*MULTIPLIER)

static func needs(item:Dictionary) -> Dictionary:
	return item.flock if item.kind=="coop" else item.dairy if item.kind=="corral" else item.pigs

static func count(item:Dictionary) -> int:
	return item.flock.names.size() if item.kind=="coop" else (1 if item.dairy.owned else 0) if item.kind=="corral" else int(item.pigs.count)

static func reason(state:FarmState,index:int) -> String:
	if index<0 or index>=state.items.size() or state.items[index].kind not in KINDS:return "Escolha um galinheiro, curral ou chiqueiro."
	var item:Dictionary=state.items[index]
	if count(item)==0:return "Este cercado ainda não tem animais."
	var species:String={"coop":"chicken","corral":"cow","pigsty":"pig"}[item.kind]
	if (state.temporary_down.get(FarmFallTargets.item_key(state,index,"cow"),false) if item.kind=="corral" else state.active_animals(species,index,count(item))<1):return "Espere os animais se recuperarem."
	if seconds(item)>0:return "O conforto ainda está ativo. Não precisa repetir."
	var data:=needs(item)
	if minf(data.food,data.water)<25:return "Reponha água e ração até pelo menos 25% primeiro."
	return ""

static func care(state:FarmState,index:int) -> String:
	var error:=reason(state,index)
	if not error.is_empty():return error
	var item:Dictionary=state.items[index]
	item.animal_care={"seconds":DURATION,"visits":mini(1000000,int(item.get("animal_care",{}).get("visits",0))+1)}
	return ""

static func tick(item:Dictionary,delta:float) -> bool:
	if not is_finite(delta) or delta<=0:return false
	var remaining:=delta
	var eggs:=false
	while remaining>.000001:
		var comfort:=seconds(item)
		var span:=minf(remaining,comfort) if comfort>0 else remaining
		var bonus:=MULTIPLIER if comfort>0 else 1.0
		match item.kind:
			"coop":eggs=FarmAnimals.tick(item,span,bonus) or eggs
			"corral":FarmDairy.tick(item.dairy,span,bonus)
			"pigsty":FarmPigs.tick(item.pigs,span)
		if item.has("animal_care"):item.animal_care.seconds=maxf(0,comfort-span)
		remaining-=span
	return eggs

static func night(elapsed:float) -> bool:
	var hour:=FarmDayNight.hour_at(elapsed)
	return hour>=20 or hour<6

static func activity(item:Dictionary,elapsed:float) -> String:
	if count(item)==0:return "Aguardando companhia"
	var data:=needs(item)
	if data.water<25:return "Procurando água"
	if data.food<25:return "De olho na ração"
	if night(elapsed):return "Hora de descansar"
	if seconds(item)>0:return "Confortáveis e tranquilos"
	return {"coop":"Ciscando pelo terreiro","corral":"Pastando sem pressa","pigsty":"Farejando o chiqueiro"}[item.kind]
