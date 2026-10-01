class_name FarmResources
extends RefCounted
## Host-side transactions. Activity duration and proximity are enforced by the game.
const FISH_KEYS := ["tilapia", "trout", "dorado"]
const ORE_KEYS := ["copper", "iron", "quartz"]
const NODE_ORES := ["copper", "iron", "quartz", "copper", "iron", "iron", "iron", "quartz", "quartz"]
const NODE_LEVELS := [0,0,0,1,1,1,2,2,2]
const NODE_COUNT := 9
const NAMES := {"tilapia":"Tilápia", "trout":"Truta", "dorado":"Dourado", "copper":"Cobre", "iron":"Ferro", "quartz":"Quartzo", "rod":"Vara de pesca", "pickaxe":"Picareta", "mine":"Mina da Pedra Clara", "gallery_1":"Galeria do Ferro", "gallery_2":"Salão dos Cristais"}
const PRICES := {"tilapia":18, "trout":28, "dorado":45, "copper":24, "iron":40, "quartz":65, "rod":150, "pickaxe":180, "mine":1500, "gallery_1":1200, "gallery_2":3000}
const STOCK_LIMIT := 10000
const MAX_COUNTER := 1000000000
const COOLDOWN := 120.0
const FISH_WEIGHTS := [[75,20,5], [40,45,15], [20,35,45]]

static func fresh() -> Dictionary:
	return {"rod":false, "pickaxe":false, "mine_owned":false, "gallery_level":0, "stock":{"tilapia":0,"trout":0,"dorado":0,"copper":0,"iron":0,"quartz":0}, "node_ready":[0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0], "caught":0, "mined":0}

static func _integer(value:Variant, maximum:int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value>=0 and value<=maximum and float(value)==floorf(float(value))

static func valid(data:Variant, elapsed:float) -> bool:
	if not is_finite(elapsed) or elapsed<0 or not data is Dictionary or data.size()!=8:return false
	for key in ["rod","pickaxe","mine_owned"]:
		if not data.get(key) is bool:return false
	if not _integer(data.get("gallery_level"),2):return false
	if data.gallery_level>0 and not (data.pickaxe and data.mine_owned):return false
	if not data.get("stock") is Dictionary or data.stock.size()!=6:return false
	for key in FISH_KEYS+ORE_KEYS:
		if not _integer(data.stock.get(key),STOCK_LIMIT):return false
	for key in ["caught","mined"]:
		if not _integer(data.get(key),MAX_COUNTER):return false
	if not data.get("node_ready") is Array or data.node_ready.size()!=NODE_COUNT:return false
	for ready in data.node_ready:
		if not (ready is int or ready is float) or not is_finite(float(ready)) or ready<0 or ready>elapsed+COOLDOWN:return false
	if not data.rod and data.caught>0:return false
	if not (data.pickaxe and data.mine_owned) and data.mined>0:return false
	var fish_total:=0
	var ore_total:=0
	for key in FISH_KEYS:fish_total+=int(data.stock[key])
	for key in ORE_KEYS:ore_total+=int(data.stock[key])
	if fish_total>data.caught or ore_total>data.mined:return false
	for i in range(NODE_COUNT):
		if (data.mined==0 or data.gallery_level<NODE_LEVELS[i]) and data.node_ready[i]!=0:return false
	return true

static func normalized(data:Dictionary) -> Dictionary:
	var result:=data.duplicate(true)
	for key in result.stock:result.stock[key]=int(result.stock[key])
	for i in range(NODE_COUNT):result.node_ready[i]=float(result.node_ready[i])
	result.gallery_level=int(result.gallery_level)
	result.caught=int(result.caught);result.mined=int(result.mined)
	return result

static func buy(state:FarmState, kind:String) -> String:
	if kind not in ["rod","pickaxe","mine","gallery_1","gallery_2"]:return "Compra desconhecida."
	if not state.claimed:return "Escolha seu terreno primeiro."
	if kind.begins_with("gallery_"):
		var level:=1 if kind=="gallery_1" else 2
		if not state.resources.mine_owned or not state.resources.pickaxe:return "Compre a mina e uma picareta primeiro."
		if state.resources.gallery_level>=level:return "Esta galeria já está aberta."
		if state.resources.gallery_level!=level-1:return "Abra a Galeria do Ferro primeiro."
		var ore:="copper" if level==1 else "iron"
		var quantity:=8 if level==1 else 10
		if state.money<int(PRICES[kind]):return "%s custa $%d."%[NAMES[kind],PRICES[kind]]
		if state.resources.stock[ore]<quantity:return "Você precisa de %d unidades de %s."%[quantity,NAMES[ore]]
		state.money-=int(PRICES[kind])
		state.resources.stock[ore]-=quantity
		state.resources.gallery_level=level
		return ""
	var field:="mine_owned" if kind=="mine" else kind
	if state.resources[field]:return "Você já possui %s."%NAMES[kind]
	if state.money<int(PRICES[kind]):return "%s custa $%d."%[NAMES[kind],PRICES[kind]]
	state.money-=int(PRICES[kind]);state.resources[field]=true
	return ""

static func can_catch(state:FarmState, spot:int) -> String:
	if spot<0 or spot>=3:return "Ponto de pesca desconhecido."
	if not state.claimed:return "Escolha seu terreno primeiro."
	if not state.resources.rod:return "Compre uma vara de pesca no armazém."
	if state.resources.caught>=MAX_COUNTER:return "Limite de capturas atingido."
	for key in FISH_KEYS:
		if state.resources.stock[key]>=STOCK_LIMIT:return "Venda seus peixes antes de pescar mais."
	return ""

static func catch_fish(state:FarmState, spot:int) -> String:
	var error:=can_catch(state,spot)
	if not error.is_empty():return error
	var roll:=randi_range(0,99)
	var index:=0
	while index<2 and roll>=int(FISH_WEIGHTS[spot][index]):
		roll-=int(FISH_WEIGHTS[spot][index]);index+=1
	state.resources.stock[FISH_KEYS[index]]+=1
	state.resources.caught+=1;state.earn_xp(3)
	return ""

static func can_extract(state:FarmState, node:int) -> String:
	if node<0 or node>=NODE_COUNT:return "Veio desconhecido."
	if not state.claimed:return "Escolha seu terreno primeiro."
	if not state.resources.mine_owned:return "Compre a Mina da Pedra Clara antes de entrar."
	if not state.resources.pickaxe:return "Compre uma picareta no armazém."
	if state.resources.gallery_level<NODE_LEVELS[node]:return "Abra esta galeria antes de extrair."
	if not is_finite(state.elapsed) or state.elapsed<0:return "Relógio da fazenda inválido."
	if state.elapsed<float(state.resources.node_ready[node]):return "Este veio está se recuperando."
	if state.resources.mined>=MAX_COUNTER or state.resources.stock[NODE_ORES[node]]>=STOCK_LIMIT:return "Venda seus minérios antes de extrair mais."
	return ""

static func extract(state:FarmState, node:int) -> String:
	var error:=can_extract(state,node)
	if not error.is_empty():return error
	state.resources.stock[NODE_ORES[node]]+=1
	state.resources.node_ready[node]=state.elapsed+COOLDOWN
	state.resources.mined+=1;state.earn_xp(5)
	return ""

static func sell(state:FarmState, key:String) -> int:
	if not state.claimed or key not in FISH_KEYS+ORE_KEYS:return 0
	var count:=int(state.resources.stock[key])
	if count<=0:return 0
	var total:=count*int(PRICES[key])
	state.resources.stock[key]=0;state.money+=total;state.revenue+=total
	state.refresh_journey()
	return total

static func value(state:FarmState) -> int:
	var total:=0
	for key in FISH_KEYS+ORE_KEYS:total+=int(state.resources.stock[key])*int(PRICES[key])
	return total
