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
const PALETTE = ["#ca6244", "#4e8f87", "#ddb65d", "#e8dfc2", "#7b83a6"]
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
	if ignore_index<0 and money < int(ITEMS[kind].cost):
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
		item.watered = true
		refresh_journey()
		return "Regado! A natureza cuida do resto."
	return "Crescendo... %d%%" % int(float(item.growth) * 100)

func tick(delta: float) -> bool:
	if not claimed:
		return false
	elapsed += delta
	var eggs := false
	for item in items:
		if item.kind == "plot" and item.planted and item.watered:
			item.growth = minf(1.0, float(item.growth) + delta / float(CROPS[item.crop].seconds))
		if item.kind == "coop":
			item.egg_time += delta
			while item.egg_time >= 45.0:
				item.egg_time -= 45.0
				inventory.egg += 2
				eggs = true
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
	return {"version": 1, "money": money, "claimed": claimed,
		"center": [center.x, center.y], "land_size": land_size,
		"items": items.duplicate(true), "inventory": inventory.duplicate(),
		"elapsed": elapsed, "revenue": revenue, "harvests": harvests,
		"farm_name": farm_name, "contract_done": contract_done, "milestones": milestones.duplicate()}

func restore(data: Variant) -> bool:
	# Validate before mutating live state. Invalid files never partially replace it.
	if not data is Dictionary or data.get("version") != 1:
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
	if not data.get("farm_name") is String or data.farm_name.length() > 32:
		return false
	if not data.get("inventory") is Dictionary or not data.get("items") is Array or data.items.size() > 1200:
		return false
	if not data.get("milestones",{}) is Dictionary:
		return false
	for value in data.get("milestones",{}).values():
		if not value is bool: return false
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
		var area := item_rect(item.kind, Vector2(item.x, item.z), int(item.turn))
		var land := Rect2(Vector2(data.center[0], data.center[1]) - Vector2.ONE * float(data.land_size) / 2, Vector2.ONE * float(data.land_size))
		if not land.encloses(area):
			return false
	for i in range(data.items.size()):
		var first: Dictionary = data.items[i]
		var area := item_rect(first.kind,Vector2(first.x,first.z),int(first.turn)).grow(-0.05)
		for j in range(i):
			var other: Dictionary = data.items[j]
			if area.intersects(item_rect(other.kind,Vector2(other.x,other.z),int(other.turn))):
				return false
	money = int(data.money)
	claimed = data.claimed
	center = Vector2(data.center[0], data.center[1])
	land_size = float(data.land_size)
	items = data.items.duplicate(true)
	inventory = data.inventory.duplicate()
	for key in inventory:
		inventory[key] = int(inventory[key])
	elapsed = float(data.elapsed)
	revenue = int(data.revenue)
	harvests = int(data.harvests)
	farm_name = data.farm_name
	contract_done = data.contract_done
	milestones=data.get("milestones",{}).duplicate()
	refresh_journey()
	return true

func _number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))
