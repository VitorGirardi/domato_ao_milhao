class_name FarmCrew
extends RefCounted

const HIRE_COST:=120
const TRAIN_COST:=240

static func fresh() -> Dictionary:
	return {"hired":false,"paused":true,"level":1,"spent":0,"watered":0,"reason":""}

static func level(worker:Dictionary) -> int:
	return int(worker.get("level",1))

static func valid_level(value:Variant) -> bool:
	return (value is int or value is float) and (value==1 or value==2)

static func fee(worker:Dictionary) -> int:
	return 1 if level(worker)==2 else 2

static func speed(worker:Dictionary) -> float:
	return 1.4 if level(worker)==2 else 1.0

static func valid(data:Variant) -> bool:
	if not data is Dictionary or not data.get("hired") is bool or not data.get("paused") is bool: return false
	if not valid_level(data.get("level")): return false
	if data.get("reason") not in ["","manual","funds","removed"]: return false
	if not data.hired and not data.paused: return false
	for key in ["spent","watered"]:
		var value:Variant=data.get(key)
		if not (value is int or value is float) or not is_finite(float(value)) or value<0 or float(value)!=floorf(float(value)): return false
	return true
