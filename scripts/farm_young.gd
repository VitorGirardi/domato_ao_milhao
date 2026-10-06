class_name FarmYoung
extends RefCounted
const DURATIONS:={"coop":480.0,"corral":1440.0,"pigsty":960.0}
const PRICES:={"coop":300,"corral":280,"pigsty":140}
const ACTIONS:=["young:adopt"]

static func progress(item:Dictionary,slot:int=0) -> float:
	if not item.has("young_ages"):return 1.0
	if slot<0 or slot>=item.young_ages.size():return 1.0
	return clampf(float(item.young_ages[slot])/DURATIONS[item.kind],0,1)

static func adults(item:Dictionary) -> int:
	var result:=0
	for i in range(FarmAnimalCare.count(item)):
		if progress(item,i)>=1:result+=1
	return result

static func productivity(item:Dictionary) -> float:
	return float(adults(item))/maxi(1,FarmAnimalCare.count(item))

static func ages(item:Dictionary) -> Array:
	if item.has("young_ages"):return item.young_ages.duplicate()
	var result:Array=[]
	for i in range(FarmAnimalCare.count(item)):result.append(DURATIONS[item.kind])
	return result

static func valid(item:Dictionary) -> bool:
	if not item.has("young_ages"):return true
	if item.kind not in DURATIONS or not item.young_ages is Array:return false
	if item.kind=="coop" and not item.has("flock"):return false
	if item.young_ages.size()!=FarmAnimalCare.count(item):return false
	for age in item.young_ages:
		if not (age is int or age is float) or not is_finite(float(age)) or age<0 or age>DURATIONS[item.kind]:return false
	if item.kind=="corral" and progress(item)<1 and (item.dairy.milk>0 or item.dairy.timer>0):return false
	return true

static func reason(s:FarmState,index:int) -> String:
	if index<0 or index>=s.items.size() or s.items[index].kind not in DURATIONS:return "Escolha um cercado."
	var item:Dictionary=s.items[index]
	if item.kind=="coop" and item.level!=1:return "O galinheiro já tem suas seis vagas."
	if item.kind=="corral" and item.dairy.owned:return "A bezerra precisa de um curral vazio."
	if item.kind=="pigsty" and item.pigs.count>=3:return "As três vagas do chiqueiro estão ocupadas."
	var species:String={"coop":"chicken","corral":"cow","pigsty":"pig"}[item.kind]
	if FarmAnimalCare.count(item)>0 and s.active_animals(species,index,FarmAnimalCare.count(item))<1:return "Espere os animais se recuperarem."
	if s.money<PRICES[item.kind]:return "Faltam moedas para criar o filhote."
	if item.kind=="coop" and s.stock("egg")<6:return "Separe 6 ovos do estoque para a nova ninhada."
	return ""

static func adopt(s:FarmState,index:int) -> String:
	var error:=reason(s,index)
	if not error.is_empty():return error
	var item:Dictionary=s.items[index]
	var saved_ages:=ages(item)
	s.money-=PRICES[item.kind]
	match item.kind:
		"coop":
			s.consume_stock("egg",6);item.level=2
			item.flock.names.append_array(["Paçoca","Jurema","Dona Geminha"])
			saved_ages.append_array([0.0,0.0,0.0])
		"corral":item.dairy.owned=true;saved_ages.append(0.0)
		"pigsty":item.pigs.count=int(item.pigs.count)+1;saved_ages.append(0.0)
	item.young_ages=saved_ages
	return ""

static func growing(item:Dictionary) -> bool:
	return item.has("young_ages") and adults(item)<FarmAnimalCare.count(item)

static func supplied(item:Dictionary) -> bool:
	var data:=FarmAnimalCare.needs(item)
	return data.food>0 and data.water>0

static func boundary(item:Dictionary,span:float) -> float:
	if not growing(item) or not supplied(item):return span
	for age in item.young_ages:
		if age<DURATIONS[item.kind]:span=minf(span,DURATIONS[item.kind]-float(age))
	var data:=FarmAnimalCare.needs(item)
	var food_seconds:=6.0;var water_seconds:=4.8
	if item.kind=="coop":
		var factor:=2.0 if item.flock.names.size()==6 else 1.0
		food_seconds=3.6/factor;water_seconds=3.0/factor
	elif item.kind=="pigsty":food_seconds/=maxi(1,int(data.count));water_seconds/=maxi(1,int(data.count))
	return minf(span,minf(float(data.food)*food_seconds,float(data.water)*water_seconds))

static func advance(item:Dictionary,span:float) -> void:
	if not item.has("young_ages"):return
	for i in range(item.young_ages.size()):
		item.young_ages[i]=minf(DURATIONS[item.kind],float(item.young_ages[i])+span)
		if DURATIONS[item.kind]-item.young_ages[i]<.000001:item.young_ages[i]=DURATIONS[item.kind]

static func label(item:Dictionary,slot:int) -> String:
	var p:=progress(item,slot)
	if p>=1:return "Adulto"
	return ("Filhote" if p<.5 else "Jovem")+" · %d%%"%floori(p*100)
