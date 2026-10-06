class_name FarmRosa
extends RefCounted
## Independent story: existing delivery orders and trust are never rewritten.
const STEPS := [
	{"title":"1 · Ferramentas para recomeçar","quote":"Minha horta ficou abandonada. Com ferro eu conserto as ferramentas; as cenouras alimentam quem vier ajudar.","cargo":{"iron":3,"carrot":8},"pay":180},
	{"title":"2 · Sementes e um mutirão","quote":"Os canteiros estão limpos! Traga trigo e milho para separar sementes e preparar a refeição do mutirão.","cargo":{"wheat":12,"corn":12},"pay":220},
	{"title":"3 · Uma mesa entre amigos","quote":"Olha só as primeiras folhas! Quero agradecer ao pessoal com um café de inauguração. Você traz leite e ovos?","cargo":{"milk":6,"egg":8},"pay":300}
]
static func fresh() -> Dictionary:return {"stage":0,"active":false}
static func valid(data:Variant) -> bool:
	if not data is Dictionary or data.size()!=2:return false
	return FarmResources._integer(data.get("stage"),3) and data.get("active") is bool and not (data.stage==3 and data.active)
static func step(state:FarmState) -> Dictionary:return STEPS[mini(int(state.rosa_story.stage),2)]
static func quote(state:FarmState) -> String:
	if state.rosa_story.stage==3:return "Toda vez que rego estas plantas, lembro da sua ajuda. O canteiro da amizade já está no seu catálogo de Jardim!"
	if not state.residents.rosa.met:return "Você deve ser nosso novo vizinho! Entre, tenho uma história para contar."
	return step(state).quote
static func act(state:FarmState,action:String) -> String:
	if not state.claimed or not state.residents.rosa.met:return "Converse com Dona Rosa primeiro."
	if state.rosa_story.stage>=3:return "A horta já floresceu. Obrigada pela amizade!"
	if action=="story_accept":
		if state.rosa_story.active:return "Esta ajuda já está combinada."
		state.rosa_story.active=true;return ""
	if action!="story_deliver" or not state.rosa_story.active:return "Combine a ajuda antes de entregar."
	var cargo:=FarmPickupCargo.contents(state).duplicate();var request:Dictionary=step(state).cargo
	for product in request:
		if int(cargo.get(product,0))<int(request[product]):return "Falta %s na caçamba."%FarmResidents.title(product)
	for product in request:
		cargo[product]-=int(request[product])
		if cargo[product]==0:cargo.erase(product)
	var payment:int=step(state).pay
	state.pickup.cargo=cargo;state.money+=payment;state.revenue+=payment
	state.rosa_story.stage+=1;state.rosa_story.active=false
	state.refresh_journey()
	return ""
static func routine(elapsed:float) -> Dictionary:
	var hour:=FarmDayNight.hour_at(elapsed)
	if hour<6 or hour>=18:return {"at":Vector2(1.8,5.4),"activity":"Descansando na varanda"}
	if hour<11:return {"at":Vector2(-4.1,5.8),"activity":"Cuidando da horta"}
	if hour<15:return {"at":Vector2(0,7),"activity":"Recebendo os vizinhos"}
	return {"at":Vector2(4.1,5.8),"activity":"Passeando pelo quintal"}
