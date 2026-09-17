class_name FarmState
extends RefCounted
## Pure simulation. Coordinates are X/Z in meters; all persistence is JSON.

const CROPS = {
	"carrot": {"name": "Cenoura", "seconds": 32.0, "seed": 4, "price": 12, "yield": 3},
	"wheat": {"name": "Trigo", "seconds": 46.0, "seed": 6, "price": 17, "yield": 3},
	"corn": {"name": "Milho", "seconds": 62.0, "seed": 8, "price": 24, "yield": 3}
}
const ITEMS = {
	"plot": {"name": "Canteiro", "cost": 20, "size": Vector2(2, 2)},
	"barn": {"name": "Celeiro", "cost": 240, "size": Vector2(6, 6)},
	"coop": {"name": "Galinheiro", "cost": 180, "size": Vector2(4, 4)},
	"fence": {"name": "Cerca", "cost": 12, "size": Vector2(2, 0.4)},
	"sign": {"name": "Placa", "cost": 25, "size": Vector2(2, 1)},
	"path": {"name": "Caminho", "cost": 5, "size": Vector2(2, 2)}
}
const PALETTE = ["#ca6244", "#4e8f87", "#ddb65d", "#e8dfc2", "#7b83a6", "#344d52", "#785239"]
const JOURNEY = [
	{"key":"land", "title":"Um lugar para chamar de seu", "body":"Escolha uma área do vale.\nSeu primeiro terreno custa $400.", "button":"Escolher meu terreno", "action":"land"},
	{"key":"plots", "title":"Raízes no chão", "body":"Construa 3 canteiros.\nCada um já vem com sementes.\nCenouras crescem mais rápido!", "button":"Plantar meus canteiros", "action":"plots"},
	{"key":"water", "title":"Uma dose de cuidado", "body":"Regue 3 canteiros com Cuidar.\nOs marcadores azuis indicam\nquem está precisando de água.", "button":"Cuidar dos canteiros", "action":"water"},
	{"key":"harvest", "title":"Hora de colher", "body":"TAB faz o tempo passar.\nQuando aparecer COLHER,\nuse Cuidar ou E de perto.", "button":"Caminhar pela fazenda", "action":"harvest"},
	{"key":"sale", "title":"Seu primeiro negócio", "body":"Seu Tonico compra a produção.\nAbra o armazém e transforme\nsua colheita em moedas.", "button":"Visitar o armazém", "action":"market"},
	{"key":"contract", "title":"O bolo da Dona Nena", "body":"Entregue 6 cenouras por $110.\nSepare o pedido antes de\nvender o restante do estoque!", "button":"Ver pedido especial", "action":"market"},
	{"key":"coop", "title":"Companhia no quintal", "body":"Construa seu primeiro\ngalinheiro por $180.\nA Maricota vem de brinde!", "button":"Construir galinheiro", "action":"coop"},
	{"key":"expand", "title":"Um sonho maior", "body":"Junte $900 para expandir.\nMais espaço para construir\na fazenda do seu jeito.", "button":"Planejar expansão", "action":"expand"}
]
var money: int = 1600
var claimed: bool = false
var center: Vector2 = Vector2(4, -2)
var land_size: float = 24.0
var items: Array = []
var inventory: Dictionary = {"carrot": 0, "wheat": 0, "corn": 0, "egg": 0}
var elapsed: float = 0.0
var revenue: int = 0
var harvests: int = 0
var farm_name: String = "Meu pedacinho de mundo"
var contract_done: bool = false
var milestones: Dictionary = {}
var reserve: Dictionary = {"carrot":0, "wheat":0, "corn":0, "egg":0}
var watering_upgrade := false
var trade:Dictionary=FarmTrade.fresh()
var trade_notices:Array[String]=[]
var staff:Dictionary=FarmStaff.fresh()
var staff_notice:=""

func hire_staff(index: int) -> String:
	if staff.hired: return "Zeca já trabalha aqui."
	if not claimed or index<0 or index>=items.size() or items[index].kind!="coop": return "Construa e escolha um galinheiro primeiro."
	if money<FarmStaff.HIRE_COST: return "Faltam moedas para contratar o Zeca."
	money-=FarmStaff.HIRE_COST
	staff.spent+=FarmStaff.HIRE_COST
	staff.hired=true
	staff.paused=false
	staff.coop=index
	staff.timer=0.0
	staff.reason=""
	return ""

func assign_staff(index: int) -> String:
	if not staff.hired: return "Contrate o Zeca primeiro."
	if index<0 or index>=items.size() or items[index].kind!="coop": return "Escolha um galinheiro válido."
	if staff.coop==index: return ""
	staff.coop=index
	staff.timer=0.0
	return ""

func pause_staff() -> String:
	if not staff.hired: return "Contrate o Zeca primeiro."
	if staff.paused and staff.coop<0: return "Escolha um galinheiro antes de retomar."
	staff.paused=not staff.paused
	staff.reason="manual" if staff.paused else ""
	return ""

func dismiss_staff() -> void:
	staff.hired=false
	staff.paused=true
	staff.coop=-1
	staff.timer=0.0
	staff.reason=""

func accept_order(key: String) -> String:
	if not claimed: return "Escolha seu terreno antes de aceitar encomendas."
	if not trade.has(key): return "Vizinho desconhecido."
	var record:Dictionary=trade[key]
	if not record.active.is_empty(): return "Você já tem uma encomenda deste vizinho."
	var level:=FarmTrade.tier(int(record.reputation))
	record.active={"tier":level,"accepted_at":elapsed,"deadline":elapsed+FarmTrade.duration(level)}
	record.last_result=""
	return ""

func deliver_order(key: String) -> String:
	if not trade.has(key): return "Vizinho desconhecido."
	var record:Dictionary=trade[key]
	if record.active.is_empty(): return "Aceite a encomenda primeiro."
	if elapsed>=float(record.active.deadline):
		_expire_orders()
		return "O prazo terminou. Nenhum produto foi retirado."
	var requested:=FarmTrade.offer(key,record)
	if not FarmTrade.can_supply(requested,inventory): return "Faltam produtos no estoque. Retire reservas no celeiro, se precisar."
	for product in requested.needs: inventory[product]-=int(requested.needs[product])
	money+=int(requested.reward)
	revenue+=int(requested.reward)
	record.reputation+=1
	record.cycle+=1
	record.active={}
	record.last_result="delivered"
	refresh_journey()
	return ""

func cancel_order(key: String) -> String:
	if not trade.has(key) or trade[key].active.is_empty(): return "Nenhuma encomenda ativa deste vizinho."
	trade[key].active={}
	trade[key].cycle+=1
	trade[key].last_result="cancelled"
	return ""

func _expire_orders() -> void:
	for key in trade:
		var record:Dictionary=trade[key]
		if not record.active.is_empty() and elapsed>=float(record.active.deadline):
			record.active={}
			record.cycle+=1
			record.last_result="expired"
			trade_notices.append(FarmTrade.NEIGHBORS[key].name)

func active_orders() -> int:
	var count:=0
	for record in trade.values():
		if not record.active.is_empty(): count+=1
	return count

func sell_product(key: String, quantity: int) -> int:
	if not FarmTrade.PRICES.has(key) or quantity<=0 or quantity>int(inventory.get(key,0)): return 0
	var total:=quantity*int(FarmTrade.PRICES[key])
	inventory[key]-=quantity
	money+=total
	revenue+=total
	refresh_journey()
	return total

func line_plan(kind: String, start: Vector2, finish: Vector2, rotation: int = 0) -> Array:
	if kind not in ["fence","path"]: return []
	start=start.snapped(Vector2(2,2))
	finish=finish.snapped(Vector2(2,2))
	var offset:=finish-start
	var along_x:=absf(offset.x)>=absf(offset.y)
	var length:float=offset.x if along_x else offset.y
	var steps:=mini(63,int(absf(length)/2))
	var direction:=Vector2(signf(length)*2,0) if along_x else Vector2(0,signf(length)*2)
	var rotation_value:=rotation if steps==0 else (0 if along_x else 1)
	var plan:Array=[]
	for i in range(steps+1):
		var at:=start+direction*i
		plan.append({"kind":kind,"x":at.x,"z":at.y,"turn":rotation_value})
	return plan

func batch_error(plan: Array) -> String:
	if plan.is_empty() or plan.size()>64: return "Trace de 1 a 64 peças."
	var cost:=0
	for i in range(plan.size()):
		var piece:Dictionary=plan[i]
		if piece.get("kind","") not in ["fence","path"]: return "Traçado inválido."
		var error:=can_place(piece.kind,Vector2(piece.x,piece.z),piece.turn,-2)
		if not error.is_empty(): return "Peça %d: %s"%[i+1,error]
		var area:=item_rect(piece.kind,Vector2(piece.x,piece.z),piece.turn).grow(-0.05)
		for j in range(i):
			var other:Dictionary=plan[j]
			if area.intersects(item_rect(other.kind,Vector2(other.x,other.z),other.turn)):
				return "O traçado sobrepõe suas próprias peças."
		cost+=int(ITEMS[piece.kind].cost)
	if money<cost: return "O traçado custa $%d. Você tem $%d."%[cost,money]
	return ""

func batch_cost(plan: Array) -> int:
	var cost:=0
	for piece in plan: cost+=int(ITEMS[piece.kind].cost)
	return cost

func place_batch(plan: Array) -> String:
	var error:=batch_error(plan)
	if not error.is_empty(): return error
	# Validate everything first; a rejected route never charges or leaves partial pieces.
	for piece in plan: place(piece.kind,Vector2(piece.x,piece.z),piece.turn)
	return ""

func reserve_count() -> int:
	var total:=0
	for value in reserve.values(): total+=int(value)
	return total

func reserve_capacity() -> int:
	return count_items("barn")*60

func transfer_reserve(key: String, deposit: bool) -> int:
	if not reserve.has(key) or count_items("barn")==0: return 0
	var amount:=mini(int(inventory[key]),maxi(0,reserve_capacity()-reserve_count())) if deposit else int(reserve[key])
	reserve[key]+=amount if deposit else -amount
	inventory[key]+=-amount if deposit else amount
	return amount

func buy_watering_upgrade() -> String:
	if count_items("barn")==0: return "Construa um celeiro para usar a bancada."
	if watering_upgrade: return "Seu regador já está melhorado."
	if money<300: return "A melhoria custa $300."
	money-=300
	watering_upgrade=true
	return ""

func water_targets(index: int) -> Array:
	var result:Array=[]
	if index<0 or index>=items.size(): return result
	var target:Dictionary=items[index]
	if target.kind!="plot" or not target.planted or target.watered or target.growth>=1: return result
	for i in range(items.size()):
		var item:Dictionary=items[i]
		if item.kind!="plot" or not item.planted or item.watered or item.growth>=1: continue
		if i==index or (watering_upgrade and Vector2(item.x-target.x,item.z-target.z).length()<=2.01): result.append(i)
	return result

func remove_item(index: int) -> String:
	if index<0 or index>=items.size(): return "Selecione uma construção."
	if items[index].kind=="coop" and items[index].flock.nest>0:
		return "Colete os ovos antes de remover o galinheiro."
	if items[index].kind=="barn" and reserve_count()>reserve_capacity()-60:
		return "Retire a reserva do celeiro antes de removê-lo."
	money+=int(ITEMS[items[index].kind].cost)/2
	items.remove_at(index)
	if staff.coop==index:
		staff.coop=-1
		staff.paused=true
		staff.timer=0.0
		staff.reason="removed"
	elif staff.coop>index: staff.coop-=1
	return ""

func care_coop(index: int, action: String) -> String:
	if index<0 or index>=items.size() or items[index].kind!="coop": return "Selecione um galinheiro."
	var flock:Dictionary=items[index].flock
	match action:
		"food":
			var cost:=FarmAnimals.food_cost(flock)
			if cost==0: return "O comedouro já está cheio."
			if money<cost: return "Faltam moedas para repor a ração."
			money-=cost
			flock.food=100.0
			return "Comedouro cheio! -$%d"%cost
		"water":
			if flock.water>=100: return "O bebedouro já está cheio."
			flock.water=100.0
			return "Água fresquinha, por conta da casa."
		"collect":
			var amount:=int(flock.nest)
			if amount==0: return "O ninho ainda está vazio."
			inventory.egg+=amount
			flock.nest=0
			return "+%d ovos no estoque!"%amount
	return "Cuidado desconhecido."

func rename_hen(index: int, hen: int, value: String) -> String:
	if index<0 or index>=items.size() or items[index].kind!="coop" or hen<0 or hen>=3: return "Selecione uma galinha."
	value=value.strip_edges()
	if not FarmAnimals.valid_name(value): return "Use um nome de 1 a 24 caracteres."
	items[index].flock.names[hen]=value
	return ""

func paint_item(index: int, part: String, color: int) -> String:
	if index<0 or index>=items.size() or items[index].kind not in ["barn","coop","fence","sign"]:
		return "Selecione uma construção para pintar."
	if part not in ["walls","roof","door"] or color<0 or color>=PALETTE.size(): return "Pintura inválida."
	if part!="walls" and items[index].kind not in ["barn","coop"]: return "Esta peça só tem pintura principal."
	if items[index].kind=="barn" and not items[index].has("door_paint"):
		items[index].door_paint=int(items[index].paint)
	var key:="paint" if part=="walls" else part+"_paint"
	items[index][key]=color
	return ""

func claim(at: Vector2) -> String:
	if claimed:
		return "Você já tem um terreno. Use Expandir para crescer."
	if at.x < -12 or at.x > 22 or at.y < -18 or at.y > 20:
		return "Escolha uma área plana, longe do rio e da estrada."
	if money < 400:
		return "Faltam moedas para comprar este terreno."
	center = at.snapped(Vector2(2, 2))
	claimed = true
	money -= 400
	refresh_journey()
	return ""

func bounds() -> Rect2:
	return Rect2(center - Vector2.ONE * land_size / 2, Vector2.ONE * land_size)

func item_rect(kind: String, at: Vector2, turn: int) -> Rect2:
	var size: Vector2 = ITEMS[kind].size
	if turn % 2 != 0:
		size = Vector2(size.y, size.x)
	return Rect2(at - size / 2, size)

func can_place(kind: String, at: Vector2, turn: int, ignore_index: int = -1) -> String:
	if not claimed:
		return "Escolha seu terreno primeiro."
	if not ITEMS.has(kind):
		return "Construção desconhecida."
	var area := item_rect(kind, at, turn)
	if not bounds().encloses(area):
		return "Fora da sua propriedade."
	if _reserved(area):
		return "Mantenha a estrada e o armazém do vizinho livres."
	for index in range(items.size()):
		if index==ignore_index: continue
		var item: Dictionary = items[index]
		if area.grow(-0.05).intersects(item_rect(item.kind, Vector2(item.x, item.z), item.turn)):
			return "Este espaço já está ocupado."
	if ignore_index==-1 and money < int(ITEMS[kind].cost):
		return "Moedas insuficientes."
	return ""

func _reserved(area: Rect2) -> bool:
	return area.intersects(Rect2(-29.2,-42,4.4,84)) or area.intersects(Rect2(-36,28.2,72,3.6)) or area.intersects(Rect2(-26,11,5,6))

func can_move(index: int, at: Vector2, turn: int) -> String:
	if index<0 or index>=items.size(): return "Selecione uma construção primeiro."
	return can_place(items[index].kind,at.snapped(Vector2(2,2)),turn,index)

func move_item(index: int, at: Vector2, turn: int) -> String:
	var error:=can_move(index,at,turn)
	if not error.is_empty(): return error
	at=at.snapped(Vector2(2,2))
	items[index].x=at.x
	items[index].z=at.y
	items[index].turn=posmod(turn,4)
	return ""

func count_items(kind: String, only_watered: bool = false) -> int:
	var total:=0
	for item in items:
		if item.kind==kind and (not only_watered or (item.planted and item.watered)):
			total+=1
	return total

func refresh_journey() -> void:
	var facts={"land":claimed, "plots":count_items("plot")>=3,
		"water":count_items("plot",true)>=3, "harvest":harvests>0,
		"sale":revenue>0, "contract":contract_done,
		"coop":count_items("coop")>0, "expand":land_size>24}
	for key in facts:
		if facts[key]: milestones[key]=true

func journey_step() -> int:
	for i in range(JOURNEY.size()):
		if not milestones.get(JOURNEY[i].key,false): return i
	return JOURNEY.size()

func place(kind: String, at: Vector2, turn: int, crop: String = "carrot") -> String:
	at = at.snapped(Vector2(2, 2))
	var error := can_place(kind, at, turn)
	if not error.is_empty():
		return error
	if not CROPS.has(crop):
		return "Semente desconhecida."
	money -= int(ITEMS[kind].cost)
	items.append({"kind": kind, "x": at.x, "z": at.y, "turn": posmod(turn, 4),
		"paint": 0, "text": "Aqui o fiado só amanhã", "crop": crop,
		"growth": 0.0, "watered": false, "planted": kind == "plot", "egg_time": 0.0})
	if kind=="coop": items[-1].flock=FarmAnimals.fresh()
	refresh_journey()
	return ""

func tend(index: int, crop: String = "carrot") -> String:
	if index < 0 or index >= items.size():
		return "Nada ao alcance."
	var item: Dictionary = items[index]
	if item.kind != "plot":
		return ""
	if not item.planted:
		if not CROPS.has(crop):
			return "Semente desconhecida."
		var cost: int = CROPS[crop].seed
		if money < cost:
			return "Faltam moedas para sementes."
		money -= cost
		item.crop = crop
		item.growth = 0.0
		item.planted = true
		item.watered = false
		refresh_journey()
		return "Sementes plantadas. Agora é só regar!"
	if float(item.growth) >= 1.0:
		inventory[item.crop] += int(CROPS[item.crop]["yield"])
		harvests += 1
		item.planted = false
		item.watered = false
		item.growth = 0.0
		refresh_journey()
		return "+3 %s no estoque!" % CROPS[item.crop].name
	if not item.watered:
		var targets:=water_targets(index)
		for target in targets: items[target].watered=true
		refresh_journey()
		return "%d canteiros regados de uma vez!"%targets.size() if targets.size()>1 else "Regado! A natureza cuida do resto."
	return "Crescendo... %d%%" % int(float(item.growth) * 100)

func tick(delta: float) -> bool:
	if not claimed:
		return false
	var eggs := false
	var remaining:=maxf(0,delta)
	# Split at service boundaries so large and small simulation steps agree.
	while remaining>0.0000001:
		var active:=FarmStaff.running(staff)
		var span:=minf(remaining,FarmStaff.INTERVAL-float(staff.timer)) if active else remaining
		elapsed+=span
		_expire_orders()
		for item in items:
			if item.kind=="plot" and item.planted and item.watered:
				item.growth=minf(1.0,float(item.growth)+span/float(CROPS[item.crop].seconds))
			if item.kind=="coop":
				if FarmAnimals.tick(item,span): eggs=true
		if active:
			staff.timer+=span
			if staff.timer>=FarmStaff.INTERVAL-0.0000001:
				staff.timer=0.0
				FarmStaff.service(self)
		remaining-=span
	_expire_orders()
	return eggs

func sale_value() -> int:
	var total: int = int(inventory.egg) * 10
	for key in CROPS:
		total += int(inventory[key]) * int(CROPS[key].price)
	return total

func sell_all() -> int:
	var total := sale_value()
	money += total
	revenue += total
	for key in inventory:
		inventory[key] = 0
	refresh_journey()
	return total

func deliver_contract() -> bool:
	if contract_done or int(inventory.carrot) < 6:
		return false
	inventory.carrot -= 6
	money += 110
	revenue += 110
	contract_done = true
	trade.nena.reputation+=1
	refresh_journey()
	return true

func expand() -> String:
	if not claimed:
		return "Escolha seu terreno primeiro."
	if land_size >= 40:
		return "Sua propriedade já ocupa o limite deste protótipo!"
	if money < 900:
		return "A expansão custa 900 moedas."
	money -= 900
	land_size += 8
	refresh_journey()
	return ""

func serialize() -> Dictionary:
	return {"version": 5, "money": money, "claimed": claimed,
		"center": [center.x, center.y], "land_size": land_size,
		"items": items.duplicate(true), "inventory": inventory.duplicate(),
		"elapsed": elapsed, "revenue": revenue, "harvests": harvests,
		"farm_name": farm_name, "contract_done": contract_done, "milestones": milestones.duplicate(),
		"reserve":reserve.duplicate(), "watering_upgrade":watering_upgrade,"trade":trade.duplicate(true),"staff":staff.duplicate(true)}

func restore(data: Variant) -> bool:
	# Validate before mutating live state. Invalid files never partially replace it.
	if not data is Dictionary or not _number(data.get("version")) or data.version<1 or data.version>5 or float(data.version)!=floorf(float(data.version)):
		return false
	for key in ["money", "land_size", "elapsed", "revenue", "harvests"]:
		if not _number(data.get(key)) or float(data[key]) < 0:
			return false
	if not data.get("center") is Array or data.center.size() != 2:
		return false
	if not _number(data.center[0]) or not _number(data.center[1]):
		return false
	if data.center[0] < -12 or data.center[0] > 22 or data.center[1] < -18 or data.center[1] > 20:
		return false
	if float(data.land_size) not in [24.0, 32.0, 40.0]:
		return false
	if not data.get("claimed") is bool or not data.get("contract_done") is bool:
		return false
	if data.version>=4 and not data.has("trade"): return false
	if data.has("trade") and not FarmTrade.valid(data.trade,float(data.elapsed)): return false
	if not data.get("farm_name") is String or data.farm_name.length() > 32:
		return false
	if not data.get("inventory") is Dictionary or not data.get("items") is Array or data.items.size() > 1200:
		return false
	if not data.get("milestones",{}) is Dictionary:
		return false
	for value in data.get("milestones",{}).values():
		if not value is bool: return false
	if not data.get("watering_upgrade",false) is bool: return false
	var saved_reserve:Variant=data.get("reserve",{"carrot":0,"wheat":0,"corn":0,"egg":0})
	if not saved_reserve is Dictionary or saved_reserve.size()!=4: return false
	var stored_total:=0
	var barn_count:=0
	for key in reserve:
		if not _number(saved_reserve.get(key)) or saved_reserve[key]<0 or float(saved_reserve[key])!=floorf(float(saved_reserve[key])): return false
		stored_total+=int(saved_reserve[key])
	for key in inventory:
		if not _number(data.inventory.get(key)) or float(data.inventory[key]) < 0:
			return false
	for item in data.items:
		if not item is Dictionary or not ITEMS.has(item.get("kind", "")) or not CROPS.has(item.get("crop", "")):
			return false
		for key in ["x", "z", "turn", "paint", "growth", "egg_time"]:
			if not _number(item.get(key)):
				return false
		if not item.get("watered") is bool or not item.get("planted") is bool or not item.get("text") is String:
			return false
		if item.text.length() > 40 or item.growth < 0 or item.growth > 1 or item.egg_time < 0 or item.egg_time >= 45:
			return false
		if item.paint < 0 or item.paint >= PALETTE.size() or item.turn < 0 or item.turn > 3:
			return false
		for part in ["roof_paint","door_paint"]:
			var color:Variant=item.get(part,-1)
			if not _number(color) or color < -1 or color>=PALETTE.size() or float(color)!=floorf(float(color)): return false
		if item.kind=="barn": barn_count+=1
		if item.kind=="coop":
			if data.version>=3 and not item.has("flock"): return false
			if item.has("flock") and not FarmAnimals.valid(item.flock): return false
		var area := item_rect(item.kind, Vector2(item.x, item.z), int(item.turn))
		var land := Rect2(Vector2(data.center[0], data.center[1]) - Vector2.ONE * float(data.land_size) / 2, Vector2.ONE * float(data.land_size))
		if not land.encloses(area):
			return false
	if stored_total>barn_count*60: return false
	for i in range(data.items.size()):
		var first: Dictionary = data.items[i]
		var area := item_rect(first.kind,Vector2(first.x,first.z),int(first.turn)).grow(-0.05)
		for j in range(i):
			var other: Dictionary = data.items[j]
			if area.intersects(item_rect(other.kind,Vector2(other.x,other.z),int(other.turn))):
				return false
	if data.version>=5 and not data.has("staff"): return false
	if data.has("staff") and not FarmStaff.valid(data.staff,data.items): return false
	money = int(data.money)
	claimed = data.claimed
	center = Vector2(data.center[0], data.center[1])
	land_size = float(data.land_size)
	items = data.items.duplicate(true)
	for item in items:
		if item.kind=="coop":
			if not item.has("flock"): item.flock=FarmAnimals.fresh()
			item.flock.nest=int(item.flock.nest)
	inventory = data.inventory.duplicate()
	for key in inventory:
		inventory[key] = int(inventory[key])
	elapsed = float(data.elapsed)
	revenue = int(data.revenue)
	harvests = int(data.harvests)
	farm_name = data.farm_name
	contract_done = data.contract_done
	milestones=data.get("milestones",{}).duplicate()
	reserve=saved_reserve.duplicate()
	for key in reserve: reserve[key]=int(reserve[key])
	watering_upgrade=data.get("watering_upgrade",false)
	trade=data.get("trade",FarmTrade.fresh(contract_done)).duplicate(true)
	for record in trade.values():
		record.reputation=int(record.reputation)
		record.cycle=int(record.cycle)
		if not record.active.is_empty():
			record.active.tier=int(record.active.tier)
			record.active.accepted_at=float(record.active.accepted_at)
			record.active.deadline=float(record.active.deadline)
	trade_notices.clear()
	staff=data.get("staff",FarmStaff.fresh()).duplicate(true)
	for key in ["coop","services","eggs","spent"]: staff[key]=int(staff[key])
	staff.timer=float(staff.timer)
	staff_notice=""
	_expire_orders()
	refresh_journey()
	return true

func _number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))
