class_name FarmSkills
extends RefCounted
## Farm-owned practice; only authoritative, completed manual actions award XP.
const KEYS:=["fishing","farming","mining","handling"]
const NAMES:={"fishing":"Pesca","farming":"Agricultura","mining":"Mineração","handling":"Manejo de animais"}
const THRESHOLDS:=[0,30,100,240,480]
const RANKS:=["Iniciante","Aprendiz","Praticante","Experiente","Mestre"]
const MAX_XP:=1000000000

static func fresh() -> Dictionary:
	return {"fishing":0,"farming":0,"mining":0,"handling":0}

static func valid(data:Variant) -> bool:
	if not data is Dictionary or data.size()!=KEYS.size():return false
	for key in KEYS:
		if not FarmResources._integer(data.get(key),MAX_XP):return false
	return true

static func normalized(data:Dictionary) -> Dictionary:
	var result:=fresh()
	for key in KEYS:result[key]=int(data[key])
	return result

static func level(xp:int) -> int:
	var result:=1
	for i in range(1,THRESHOLDS.size()):
		if xp>=THRESHOLDS[i]:result=i+1
	return result

static func earn(s:FarmState,key:String,amount:int) -> void:
	if not KEYS.has(key) or amount<=0:return
	var before:=level(s.skills[key])
	s.skills[key]=mini(MAX_XP,int(s.skills[key])+amount)
	var after:=level(s.skills[key])
	if after>before:s.skill_notice="%s chegou ao nível %d! Confira o benefício no Caderno."%[NAMES[key],after]

static func crop_bonus(s:FarmState) -> int:
	return int((level(s.skills.farming)-1)/2)

static func seed_cost(s:FarmState,crop:String) -> int:
	return maxi(1,int(FarmState.CROPS[crop].seed)-int(level(s.skills.farming)/2))

static func fish_weights(s:FarmState,spot:int) -> Array:
	var weights:Array=FarmResources.FISH_WEIGHTS[spot].duplicate()
	var shift:=2*(level(s.skills.fishing)-1)
	weights[0]-=2*shift;weights[1]+=shift;weights[2]+=shift
	return weights

static func mining_interval(rank:int) -> int:
	return [0,20,10,7,5][clampi(rank,1,5)-1]

static func mining_yield(s:FarmState) -> int:
	var interval:=mining_interval(level(s.skills.mining))
	var action_number:=int(s.skills.mining/10)+1
	return 2 if interval>0 and action_number%interval==0 else 1

static func comfort_bonus(s:FarmState) -> int:
	return 2*(level(s.skills.handling)-1)

static func benefit(key:String,rank:int) -> String:
	match key:
		"fishing":return "Chances normais de captura." if rank==1 else "+%d pontos de chance para truta e dourado, cada."%(2*(rank-1))
		"farming":return "Sementes e colheitas normais." if rank==1 else "Replantio manual: -$%d por semente. Canteiros: +%d produto(s) por colheita manual."%[int(rank/2),int((rank-1)/2)]
		"mining":return "Um minério por extração." if rank==1 else "Um minério extra a cada %d extrações manuais."%mining_interval(rank)
		"handling":return "Conforto normal dos animais." if rank==1 else "Cuidados de conforto repõem até %d pontos de ração e água."%(2*(rank-1))
	return ""
