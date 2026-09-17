class_name FarmTrade
extends RefCounted
## Offers are deterministic; accepting freezes the tier and starts active-play time.

const KEYS := ["nena","bento","lola"]
const PRICES := {"carrot":12,"wheat":17,"corn":24,"egg":10}
const NAMES := {"carrot":"Cenouras","wheat":"Trigo","corn":"Milho","egg":"Ovos"}
const NEIGHBORS := {
	"nena":{"name":"Dona Nena","ranch":"Padaria do Pomar","specialty":"Bolos, pães e café fresquinho", "quote":"O segredo do bolo é não contar o segredo.","color":"c78069"},
	"bento":{"name":"Seu Bento","ranch":"Moinho das Colinas","specialty":"Grãos e farinha para o vale", "quote":"Aqui a gente trabalha até o milho virar assunto.","color":"799384"},
	"lola":{"name":"Dona Lola","ranch":"Rancho Penas Douradas","specialty":"Ovos e festas da vizinhança", "quote":"Minhas galinhas são artistas. Cobram em milho.","color":"c2a34c"}
}
const RECIPES := {
	"nena":[{"title":"Bolo para a feira","needs":{"carrot":6,"egg":2}}, {"title":"Fornada da manhã","needs":{"wheat":6,"egg":4}}, {"title":"Bolo de milho da vó","needs":{"corn":6,"egg":2}}],
	"bento":[{"title":"Primeira moagem","needs":{"wheat":6}}, {"title":"Sacos para o moinho","needs":{"wheat":6,"corn":3}}, {"title":"Fubá da vizinhança","needs":{"corn":9}}],
	"lola":[{"title":"Café no rancho","needs":{"egg":4,"corn":3}}, {"title":"Cestas para a festa","needs":{"egg":6,"carrot":3}}, {"title":"Domingo em família","needs":{"egg":8}}]
}

static func fresh(completed_intro: bool = false) -> Dictionary:
	var records:Dictionary={}
	for key in KEYS:
		records[key]={"reputation":1 if key=="nena" and completed_intro else 0,"cycle":0,"active":{},"last_result":""}
	return records

static func tier(reputation: int) -> int:
	return 2 if reputation>=5 else (1 if reputation>=2 else 0)

static func rank_name(reputation: int) -> String:
	return ["Conhecido","Parceiro","Preferido"][tier(reputation)]

static func duration(level: int) -> float:
	return 480.0+level*120.0

static func offer(key: String, record: Dictionary) -> Dictionary:
	if not NEIGHBORS.has(key): return {}
	var active:Dictionary=record.active
	var level:=int(active.tier) if not active.is_empty() else tier(int(record.reputation))
	var recipe:Dictionary=RECIPES[key][int(record.cycle)%3]
	var needs:Dictionary={}
	var base:=0
	for product in recipe.needs:
		needs[product]=int(recipe.needs[product])*(1+level)
		base+=int(needs[product])*int(PRICES[product])
	var reward:=int((base*(125+level*10)+99)/100)
	return {"title":recipe.title,"needs":needs,"reward":reward,"base":base,"tier":level,"seconds":duration(level)}

static func can_supply(offer_data: Dictionary, inventory: Dictionary) -> bool:
	if offer_data.is_empty(): return false
	for product in offer_data.needs:
		if int(inventory.get(product,0))<int(offer_data.needs[product]): return false
	return true

static func time_label(seconds: float) -> String:
	var remaining:=maxi(0,ceili(seconds))
	return "%02d:%02d"%[remaining/60,remaining%60]

static func _integer(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value>=0 and float(value)==floorf(float(value))

static func valid(data: Variant, now: float) -> bool:
	if not data is Dictionary or data.size()!=KEYS.size(): return false
	for key in KEYS:
		var record:Variant=data.get(key)
		if not record is Dictionary: return false
		if not _integer(record.get("reputation")) or not _integer(record.get("cycle")): return false
		if record.get("last_result") not in ["","delivered","cancelled","expired"]: return false
		var active:Variant=record.get("active")
		if not active is Dictionary: return false
		if active.is_empty(): continue
		if not _integer(active.get("tier")) or active.tier>2 or active.tier>tier(int(record.reputation)): return false
		for field in ["accepted_at","deadline"]:
			var value:Variant=active.get(field)
			if not (value is int or value is float) or not is_finite(float(value)) or value<0: return false
		if active.accepted_at>now or active.deadline<=active.accepted_at: return false
		if not is_equal_approx(float(active.deadline)-float(active.accepted_at),duration(int(active.tier))): return false
	return true
