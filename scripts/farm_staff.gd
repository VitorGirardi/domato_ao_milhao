class_name FarmStaff
extends RefCounted
## One caretaker, assigned to one coop. Charges only for completed work.

const HIRE_COST:=120
const SERVICE_COST:=2
const INTERVAL:=15.0
const REFILL_AT:=25.0

static func fresh() -> Dictionary:
	return {"hired":false,"paused":true,"coop":-1,"timer":0.0,"services":0,"eggs":0,"spent":0,"reason":""}

static func valid(data: Variant, items: Array) -> bool:
	if not data is Dictionary: return false
	if not data.get("hired") is bool or not data.get("paused") is bool: return false
	for key in ["coop","services","eggs","spent"]:
		var value:Variant=data.get(key)
		if not (value is int or value is float) or not is_finite(float(value)) or float(value)!=floorf(float(value)): return false
		if value<(-1 if key=="coop" else 0): return false
	var timer:Variant=data.get("timer")
	if not (timer is int or timer is float) or not is_finite(float(timer)) or timer<0 or timer>=INTERVAL: return false
	if data.get("reason") not in ["","manual","funds","removed"]: return false
	if data.coop>=items.size(): return false
	if data.coop>=0 and items[int(data.coop)].kind!="coop": return false
	if not data.hired and (not data.paused or data.coop!=-1 or timer!=0): return false
	if data.coop==-1 and not data.paused: return false
	return true

static func running(data: Dictionary) -> bool:
	return data.hired and not data.paused and data.coop>=0

static func quote(flock: Dictionary) -> int:
	var needs_food:bool=flock.food<=REFILL_AT+0.0000001
	if not needs_food and flock.water>REFILL_AT+0.0000001 and flock.nest==0: return 0
	return SERVICE_COST+(FarmAnimals.food_cost(flock) if needs_food else 0)

static func service(farm) -> void:
	var worker:Dictionary=farm.staff
	if not running(worker): return
	var flock:Dictionary=farm.items[int(worker.coop)].flock
	var cost:=quote(flock)
	if cost==0: return
	if farm.money<cost:
		worker.paused=true
		worker.reason="funds"
		farm.staff_notice="Zeca pausou: faltam moedas para o trato. Confira em H."
		return
	# All work and payment commit together; no partial charge or product loss.
	farm.money-=cost
	worker.spent+=cost
	worker.services+=1
	worker.eggs+=int(flock.nest)
	farm.inventory.egg+=int(flock.nest)
	flock.nest=0
	if flock.food<=REFILL_AT+0.0000001: flock.food=100.0
	if flock.water<=REFILL_AT+0.0000001: flock.water=100.0
	worker.reason=""

static func status(data: Dictionary) -> String:
	if not data.hired: return "Disponível para contratação"
	if data.coop<0: return "Escolha um galinheiro"
	if data.paused:
		return "Pausado • saldo insuficiente" if data.reason=="funds" else "Pausado • sem cobranças"
	return "De olho no galinheiro"
