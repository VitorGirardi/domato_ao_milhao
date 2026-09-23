class_name FarmArmory
extends RefCounted
## Persisted inventory and atomic transactions. Animation timers stay runtime-only.
const PRICE:=850
const AMMO_PRICE:=60
const AMMO_PACK:=24
const CAPACITY:=8
const MAX_RESERVE:=96
const MAX_COUNTER:=1000000000

static func fresh() -> Dictionary:
	return {"version":1,"pistol":false,"magazine":0,"reserve":0,"shots":0,"hits":0}

static func valid(value:Variant) -> bool:
	if not value is Dictionary or value.size()!=6:return false
	if not value.get("pistol") is bool:return false
	for key in ["version","magazine","reserve","shots","hits"]:
		var n:Variant=value.get(key)
		if not (n is int or n is float) or not is_finite(float(n)) or n<0 or n!=floorf(float(n)):return false
	if value.version!=1 or value.magazine>CAPACITY or value.reserve>MAX_RESERVE:return false
	if value.shots>MAX_COUNTER or value.hits>value.shots:return false
	if not value.pistol and (value.magazine!=0 or value.reserve!=0 or value.shots!=0 or value.hits!=0):return false
	return true

static func normalized(value:Dictionary) -> Dictionary:
	var result:=value.duplicate()
	for key in ["version","magazine","reserve","shots","hits"]:result[key]=int(result[key])
	return result

static func buy_pistol(state:FarmState,bag:Dictionary) -> String:
	if bag.pistol:return "Você já tem a P-8."
	if state.money<PRICE:return "A P-8 custa $%d."%PRICE
	state.money-=PRICE
	bag.pistol=true;bag.magazine=CAPACITY;bag.reserve=AMMO_PACK
	return ""

static func buy_ammo(state:FarmState,bag:Dictionary) -> String:
	if not bag.pistol:return "Compre a pistola primeiro."
	if bag.reserve+AMMO_PACK>MAX_RESERVE:return "Use a reserva antes de comprar outra caixa."
	if state.money<AMMO_PRICE:return "A caixa custa $%d."%AMMO_PRICE
	state.money-=AMMO_PRICE;bag.reserve+=AMMO_PACK
	return ""

static func can_reload(bag:Dictionary) -> bool:
	return bag.pistol and bag.magazine<CAPACITY and bag.reserve>0

static func reload(bag:Dictionary) -> int:
	if not can_reload(bag):return 0
	var amount:=mini(CAPACITY-int(bag.magazine),int(bag.reserve))
	bag.magazine+=amount;bag.reserve-=amount
	return amount

static func fire(bag:Dictionary) -> bool:
	if not bag.pistol or bag.magazine<=0:return false
	bag.magazine-=1;bag.shots=mini(MAX_COUNTER,int(bag.shots)+1)
	return true

static func register_hit(bag:Dictionary) -> void:
	bag.hits=mini(int(bag.shots),int(bag.hits)+1)
