class_name FarmAnimals
extends RefCounted
## Shared needs for the three hens in each coop. All time is active simulation time.

const NEST_CAPACITY := 12
const FOOD_SECONDS := 360.0
const WATER_SECONDS := 300.0
const TRAITS := ["Fiscal do terreiro", "Especialista em lanches", "Sonhadora profissional"]
const COLORS := ["fff2d9", "a86b39", "555c68"]

static func fresh() -> Dictionary:
	return {"food":100.0,"water":100.0,"nest":0,"names":["Maricota","Clotilde","Pipoca"]}

static func valid(value: Variant) -> bool:
	if not value is Dictionary: return false
	for key in ["food","water","nest"]:
		var number:Variant=value.get(key)
		if not (number is int or number is float) or not is_finite(float(number)) or number<0: return false
	if value.food>100 or value.water>100 or value.nest>NEST_CAPACITY or float(value.nest)!=floorf(float(value.nest)): return false
	if not value.get("names") is Array or value.names.size()!=3: return false
	for name in value.names:
		if not name is String or not valid_name(name): return false
	return true

static func valid_name(value: String) -> bool:
	if value.strip_edges().is_empty() or value.length()>24: return false
	for character in value:
		if character.unicode_at(0)<32: return false
	return true

static func rate(flock: Dictionary) -> float:
	return (1.0 if flock.food>0 else 0.5)*(1.0 if flock.water>0 else 0.5)

static func status(flock: Dictionary) -> String:
	if flock.food<=0 and flock.water<=0: return "Precisam de água e ração"
	if flock.food<=0: return "Com fome"
	if flock.water<=0: return "Com sede"
	if minf(flock.food,flock.water)<25: return "Repor em breve"
	return "Bem cuidadas"

static func food_cost(flock: Dictionary) -> int:
	return maxi(0,ceili((100.0-float(flock.food))*0.08-0.000001))

static func tick(item: Dictionary, delta: float) -> bool:
	var flock:Dictionary=item.flock
	var before:=int(flock.nest)
	var remaining:=maxf(0,delta)
	# Split only at depletion boundaries so one large tick equals many small ticks.
	while remaining>0.000001:
		var span:=remaining
		if flock.food>0: span=minf(span,float(flock.food)*FOOD_SECONDS/100.0)
		if flock.water>0: span=minf(span,float(flock.water)*WATER_SECONDS/100.0)
		if flock.nest<NEST_CAPACITY:
			var progress:float=float(item.egg_time)+span*rate(flock)
			var cycles:=int(floorf((progress+0.0000001)/45.0))
			flock.nest=mini(NEST_CAPACITY,int(flock.nest)+cycles*2)
			item.egg_time=0.0 if flock.nest==NEST_CAPACITY else maxf(0,progress-cycles*45.0)
		flock.food=maxf(0,float(flock.food)-span*100.0/FOOD_SECONDS)
		flock.water=maxf(0,float(flock.water)-span*100.0/WATER_SECONDS)
		if flock.food<0.000001: flock.food=0.0
		if flock.water<0.000001: flock.water=0.0
		remaining-=span
	return before==0 and flock.nest>0
