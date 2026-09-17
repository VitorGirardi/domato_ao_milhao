class_name FarmCheeseWorker
extends RefCounted
const HIRE:=160
const FEE:=4
static func fresh() -> Dictionary:
	return {"hired":false,"paused":true,"reason":"","site":-1,"batch_size":4,"budget":40,"spent":0,"total_spent":0,"started":0,"collected":0}
static func valid(w:Variant,items:Array) -> bool:
	if not w is Dictionary or not w.get("hired") is bool or not w.get("paused") is bool: return false
	if w.get("reason") not in ["","manual","funds","budget","removed","blocked","milk"]: return false
	for key in ["budget","spent","total_spent","started","collected","batch_size"]:
		if not FarmCultivation.integer(w.get(key)): return false
	if w.batch_size<1 or w.batch_size>4 or w.spent>w.budget or w.spent>w.total_spent: return false
	var site:Variant=w.get("site")
	if not (site is float or site is int) or not is_finite(float(site)) or site!=floorf(site) or site< -1 or site>=items.size(): return false
	if site>=0 and items[int(site)].kind!="cheesery": return false
	return (w.hired or w.paused) and (site>=0 or w.paused)
static func hire(state:FarmState) -> String:
	var w:=state.cheese_worker
	if w.hired: return "Chico já faz parte da equipe."
	if state.money<HIRE: return "Faltam moedas para contratar."
	state.money-=HIRE;w.hired=true;w.paused=true;w.reason="manual"
	return ""
static func configure(state:FarmState,site:int,batch:int,budget:int,renew:bool=false) -> String:
	var w:=state.cheese_worker
	if not w.hired: return "Contrate Chico primeiro."
	if site<0 or site>=state.items.size() or state.items[site].kind!="cheesery": return "Escolha uma queijaria."
	if batch<1 or batch>4 or budget<0 or (not renew and budget<w.spent): return "O limite deve cobrir o valor já gasto."
	w.site=site;w.batch_size=batch;w.budget=budget
	if renew:w.spent=0
	w.paused=false;w.reason=""
	return ""
static func job(state:FarmState) -> String:
	var w:=state.cheese_worker
	if not w.hired or w.paused or w.site<0: return ""
	var data:Dictionary=state.items[int(w.site)].cheese
	if data.ready>0: return "collect"
	if data.batch>0: w.reason="";return ""
	if state.milk_stock<int(w.batch_size)*2: w.reason="milk";return ""
	if state.money<FEE: w.paused=true;w.reason="funds";return ""
	if int(w.spent)+FEE>int(w.budget): w.paused=true;w.reason="budget";return ""
	w.reason=""
	return "start"
static func complete(state:FarmState,site:int,kind:String) -> bool:
	var w:=state.cheese_worker
	if site!=int(w.site) or job(state)!=kind: return false
	if kind=="collect":
		var amount:=FarmCheese.collect(state,site)
		w.collected+=amount
		return amount>0
	if kind!="start": return false
	if not FarmCheese.start(state,site,int(w.batch_size)).is_empty(): return false
	state.money-=FEE;w.spent+=FEE;w.total_spent+=FEE;w.started+=1
	return true
static func dismiss(state:FarmState) -> void:
	state.cheese_worker.hired=false;state.cheese_worker.paused=true;state.cheese_worker.reason="manual"
static func remove(state:FarmState,index:int) -> void:
	var w:=state.cheese_worker
	if w.site==index: w.site=-1;w.paused=true;w.reason="removed"
	elif w.site>index: w.site-=1
static func status(state:FarmState) -> String:
	var w:=state.cheese_worker
	if not w.hired: return "Disponível para contratar"
	if w.site<0: return "Escolha uma queijaria"
	if w.paused: return {"funds":"Pausado · sem saldo","budget":"Pausado · orçamento esgotado","removed":"Escolha uma queijaria","blocked":"Pausado · caminho bloqueado"}.get(w.reason,"Pausado por você")
	if w.reason=="milk": return "Aguardando %d L de leite"%(int(w.batch_size)*2)
	return "Em serviço"
