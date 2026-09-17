class_name FarmDairyWorker
extends RefCounted
const HIRE:=140
const FEE:=2
static func fresh() -> Dictionary:
	return {"hired":false,"paused":true,"reason":"","site":-1,"budget":60,"spent":0,"total_spent":0,"services":0,"collected":0}
static func valid(w:Variant,items:Array) -> bool:
	if not w is Dictionary or not w.get("hired") is bool or not w.get("paused") is bool: return false
	if w.get("reason") not in ["","manual","funds","budget","removed","blocked","cow"]: return false
	for key in ["budget","spent","total_spent","services","collected"]:
		if not FarmCultivation.integer(w.get(key)): return false
	if w.spent>w.budget or w.spent>w.total_spent: return false
	var site:Variant=w.get("site")
	if not (site is float or site is int) or not is_finite(float(site)) or site!=floorf(site) or site< -1 or site>=items.size(): return false
	if site>=0 and items[int(site)].kind!="corral": return false
	return (w.hired or w.paused) and (site>=0 or w.paused)
static func hire(state:FarmState) -> String:
	var w:=state.dairy_worker
	if w.hired: return "Raul já faz parte da equipe."
	if state.money<HIRE: return "Faltam moedas para contratar."
	state.money-=HIRE;w.hired=true;w.paused=true;w.reason="manual"
	return ""
static func configure(state:FarmState,site:int,budget:int,renew:bool=false) -> String:
	var w:=state.dairy_worker
	if not w.hired: return "Contrate Raul primeiro."
	if site<0 or site>=state.items.size() or state.items[site].kind!="corral": return "Escolha um curral."
	if budget<0 or (not renew and budget<w.spent): return "O limite deve cobrir o valor já gasto."
	w.site=site;w.budget=budget
	if renew:w.spent=0
	w.paused=false;w.reason=""
	return ""
static func cost(state:FarmState,kind:String) -> int:
	var w:=state.dairy_worker
	if w.site<0:return 0
	return FEE+(ceili((100-state.items[int(w.site)].dairy.food)*.12-.000001) if kind=="food" else 0)
static func job(state:FarmState) -> String:
	var w:=state.dairy_worker
	if not w.hired or w.paused or w.site<0: return ""
	var data:Dictionary=state.items[int(w.site)].dairy
	if not data.owned:w.reason="cow";return ""
	var kind:="water" if data.water<=35 else ("food" if data.food<=35 else ("milk" if data.milk>=4 else ""))
	w.reason=""
	if kind.is_empty():return ""
	var price:=cost(state,kind)
	if state.money<price:w.paused=true;w.reason="funds";return ""
	if int(w.spent)+price>int(w.budget):w.paused=true;w.reason="budget";return ""
	return kind
static func complete(state:FarmState,site:int,kind:String) -> bool:
	var w:=state.dairy_worker
	if site!=int(w.site) or kind.is_empty() or job(state)!=kind:return false
	var price:=cost(state,kind)
	var liters:int=state.items[site].dairy.milk if kind=="milk" else 0
	# Care charges only feed; service and ledger commit with the same completed task.
	if not FarmDairy.care(state,site,kind).is_empty():return false
	state.money-=FEE;w.spent+=price;w.total_spent+=price;w.services+=1;w.collected+=liters
	return true
static func dismiss(state:FarmState) -> void:
	state.dairy_worker.hired=false;state.dairy_worker.paused=true;state.dairy_worker.reason="manual"
static func remove(state:FarmState,index:int) -> void:
	var w:=state.dairy_worker
	if w.site==index: w.site=-1;w.paused=true;w.reason="removed"
	elif w.site>index: w.site-=1
static func status(state:FarmState) -> String:
	var w:=state.dairy_worker
	if not w.hired: return "Disponível para contratar"
	if w.site<0: return "Escolha um curral"
	if w.paused: return {"funds":"Pausado · sem saldo","budget":"Pausado · orçamento esgotado","removed":"Escolha um curral","blocked":"Pausado · caminho bloqueado"}.get(w.reason,"Pausado por você")
	if w.reason=="cow": return "Aguardando uma vaca"
	return "Em serviço"
