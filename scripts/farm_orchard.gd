class_name FarmOrchard
extends RefCounted
## Pure orchard simulation: time advances only while playing and after watering.
const GROW_SECONDS:=180.0
const FRUIT_SECONDS:=120.0
const YIELD:=6
const PRICE:=16
const REWARD:=220
const XP:=30

static func fresh_item() -> Dictionary:
	return {"growth":0.0,"watered":false,"ready":0,"fruit_time":0.0}

static func fresh_journey() -> Dictionary:
	return {"stage":0,"harvested":0}

static func _number(value:Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

static func valid_item(data:Variant) -> bool:
	if not data is Dictionary or data.size()!=4 or not data.get("watered") is bool:return false
	for key in ["growth","ready","fruit_time"]:
		if not _number(data.get(key)):return false
	if data.growth<0 or data.growth>GROW_SECONDS or data.fruit_time<0 or data.fruit_time>FRUIT_SECONDS:return false
	if data.ready!=0 and data.ready!=YIELD:return false
	if data.growth<GROW_SECONDS and (data.ready!=0 or data.fruit_time!=0):return false
	if not data.watered and (data.ready!=0 or data.fruit_time!=0 or (data.growth!=0 and data.growth!=GROW_SECONDS)):return false
	if data.ready==YIELD and (not data.watered or data.growth!=GROW_SECONDS or data.fruit_time!=FRUIT_SECONDS):return false
	if data.ready==0 and data.fruit_time==FRUIT_SECONDS:return false
	return true

static func valid_journey(data:Variant) -> bool:
	if not data is Dictionary or data.size()!=2:return false
	for key in ["stage","harvested"]:
		if not _number(data.get(key)) or data[key]!=floorf(float(data[key])):return false
	return data.stage>=0 and data.stage<=2 and data.harvested>=0 and data.harvested<=YIELD and (data.stage!=0 or data.harvested==0) and (data.stage!=2 or data.harvested==YIELD)

static func _available(state:FarmState,index:int) -> bool:
	return state.claimed and index>=0 and index<state.items.size() and state.items[index].kind=="orchard" and valid_item(state.items[index].get("orchard"))

static func water(state:FarmState,index:int) -> String:
	if not _available(state,index):return "Escolha uma laranjeira produtiva da fazenda."
	var tree:Dictionary=state.items[index].orchard
	if tree.watered:return "Esta laranjeira já está regada."
	tree.watered=true
	return ""

static func harvest(state:FarmState,index:int,manual:bool=true) -> String:
	if not _available(state,index):return "Escolha uma laranjeira produtiva da fazenda."
	var tree:Dictionary=state.items[index].orchard
	if tree.ready!=YIELD:return "As laranjas ainda não estão maduras."
	if int(state.inventory.orange)>1000000000-YIELD:return "Seu estoque de laranjas está cheio. Venda ou transporte algumas antes de colher."
	state.inventory.orange+=YIELD
	tree.ready=0;tree.fruit_time=0.0;tree.watered=false
	if state.orchard_journey.stage==1:state.orchard_journey.harvested=mini(YIELD,int(state.orchard_journey.harvested)+YIELD)
	state.harvests+=1
	state.earn_xp(FarmLevels.HARVEST)
	if manual:FarmSkills.earn(state,"farming",10)
	state.refresh_journey()
	return ""

static func accept(state:FarmState) -> String:
	if not state.claimed:return "Escolha seu terreno antes de começar o pomar."
	if state.orchard_journey.stage!=0:return "Você já aceitou a primeira colheita."
	state.orchard_journey.stage=1
	state.orchard_journey.harvested=0
	return ""

static func deliver(state:FarmState) -> String:
	if not state.claimed or state.orchard_journey.stage!=1:return "Aceite a encomenda de Dona Nena com Lúcia no armazém."
	if state.orchard_journey.harvested<YIELD:return "Colha 6 laranjas do seu pomar depois de aceitar o pedido."
	if state.stock("orange")<YIELD:return "Separe 6 laranjas no estoque para Dona Nena."
	state.consume_stock("orange",YIELD)
	state.orchard_journey.stage=2
	state.money+=REWARD;state.revenue+=REWARD
	state.trade.nena.reputation+=1
	state.earn_xp(XP)
	state.refresh_journey()
	return ""

static func tick(state:FarmState,delta:float) -> bool:
	if not state.claimed or not is_finite(delta) or delta<=0:return false
	var changed:=false
	for item in state.items:
		if item.kind!="orchard":continue
		var tree:Dictionary=item.orchard
		if not tree.watered or tree.ready>0:continue
		var remaining:=delta
		if tree.growth<GROW_SECONDS:
			var span:=minf(remaining,GROW_SECONDS-float(tree.growth))
			tree.growth=minf(GROW_SECONDS,float(tree.growth)+span)
			remaining-=span
			if tree.growth>=GROW_SECONDS:changed=true
		if tree.growth>=GROW_SECONDS:
			tree.fruit_time=minf(FRUIT_SECONDS,float(tree.fruit_time)+remaining)
			if tree.fruit_time>=FRUIT_SECONDS:
				tree.ready=YIELD
				changed=true
	return changed

static func status(item:Dictionary) -> String:
	var tree:Dictionary=item.get("orchard",fresh_item())
	if tree.ready>0:return "Colher 6 laranjas"
	if not tree.watered:return "Precisa de água · regar"
	if tree.growth<GROW_SECONDS:return "Crescendo · %ds"%ceili(GROW_SECONDS-float(tree.growth))
	return "Laranjas amadurecendo · %ds"%ceili(FRUIT_SECONDS-float(tree.fruit_time))
