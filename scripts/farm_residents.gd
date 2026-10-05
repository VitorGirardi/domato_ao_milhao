class_name FarmResidents
extends RefCounted
## Save-owned delivery progression. Only actual truck cargo can fulfill an order.
const PEOPLE := {
	"rosa":{"name":"Dona Rosa","role":"Horta e mesa farta","hint":"Siga a estrada do norte, além do moinho.","quote":"Uma boa vizinhança começa com uma cesta na porta.","at":Vector2(38,-126),"turn":0,"height":2.0,"need":0,"model":"farmer_woman","color":"899b65","orders":[{"carrot":8},{"carrot":12,"corn":8},{"carrot":18,"cheese":4}]},
	"bento":{"name":"Seu Bento","role":"Cozinha da estrada","hint":"Na saída leste, antes da estrada para a ponte.","quote":"Quem chega pela estrada nunca sai daqui com fome.","at":Vector2(176,-36),"turn":0,"height":2.0,"need":10,"model":"farmer","color":"bd925f","orders":[{"wheat":12,"egg":6},{"corn":16,"milk":8},{"wheat":24,"cheese":8}]},
	"lia":{"name":"Lia","role":"Almoço à beira do lago","hint":"Contorne o Lago do Sossego pela estrada ao sul.","quote":"Peixe fresco, uma prosa e o lago. Não preciso de mais.","at":Vector2(314,332),"turn":2,"height":7.0,"need":25,"model":"farmer_woman","color":"5e9399","orders":[{"tilapia":6,"carrot":8},{"trout":4,"corn":12},{"dorado":3,"cheese":6}]}
}
const COOLDOWN:=120.0
static func fresh() -> Dictionary:
	var data:Dictionary={}
	for key in PEOPLE:data[key]={"known":false,"met":false,"done":0,"active":false,"ready_at":0.0}
	return data
static func valid(data:Variant) -> bool:
	if not data is Dictionary or data.size()!=PEOPLE.size():return false
	for key in PEOPLE:
		var row:Variant=data.get(key)
		if not row is Dictionary or row.size()!=5:return false
		if not row.get("known") is bool or not row.get("met") is bool or not row.get("active") is bool:return false
		if not FarmResources._integer(row.get("done"),1000000):return false
		var ready:Variant=row.get("ready_at")
		if not (ready is int or ready is float) or not is_finite(float(ready)) or ready<0 or ready>1e12:return false
		if (row.met and not row.known) or ((row.active or row.done>0) and not row.met):return false
	return true
static func normalized(data:Dictionary) -> Dictionary:
	var result:=fresh()
	for key in PEOPLE:
		var row:Dictionary=data[key]
		result[key]={"known":bool(row.known),"met":bool(row.met),"done":int(row.done),"active":bool(row.active),"ready_at":float(row.ready_at)}
	return result
static func influence(state:FarmState) -> int:
	var total:=0
	for row in state.residents.values():total+=int(row.done)*5
	return total
static func trust(state:FarmState,key:String) -> String:
	var done:=int(state.residents[key].done)
	return "Amigo da casa" if done>=3 else "De confiança" if done>=1 else "Primeira visita"
static func order(state:FarmState,key:String) -> Dictionary:
	return PEOPLE[key].orders[mini(int(state.residents[key].done),2)]
static func reward(state:FarmState,key:String) -> int:
	var result:=50
	for product in order(state,key):result+=ceili(FarmPickupCargo.price(product)*int(order(state,key)[product])*1.4)
	return result
static func title(product:String) -> String:
	return FarmPickupCargo.TITLES[FarmPickupCargo.KEYS.find(product)]
static func entry(key:String) -> Vector2:
	return PEOPLE[key].at+Vector2(0,7).rotated(-int(PEOPLE[key].turn)*PI/2)
static func parking(key:String) -> Vector2:
	return PEOPLE[key].at+Vector2(0,14).rotated(-int(PEOPLE[key].turn)*PI/2)
static func reserved(point:Vector2,extra:float=0) -> bool:
	for key in PEOPLE:
		if point.distance_to(PEOPLE[key].at)<19+extra:return true
	return false
static func ground(point:Vector2,original:float) -> float:
	for person in PEOPLE.values():
		var distance:=point.distance_to(person.at)
		if distance<24:return lerpf(float(person.height),original,smoothstep(16,24,distance))
	return original
static func act(state:FarmState,key:String,action:String) -> String:
	if not state.claimed or not PEOPLE.has(key):return "Escolha sua fazenda e encontre o morador."
	var row:Dictionary=state.residents[key]
	if row.done>=1000000:return "Você já completou todas as entregas desta casa."
	if action=="meet":row.known=true;row.met=true;return ""
	if not row.met:return "Converse com o morador primeiro."
	if influence(state)<int(PEOPLE[key].need):return "Ganhe %d de influência com entregas para receber esta indicação."%int(PEOPLE[key].need)
	if action=="accept":
		if row.active:return "Este pedido já está aceito."
		if state.elapsed<float(row.ready_at):return "O morador está abastecido. Volte daqui a pouco."
		row.active=true;return ""
	if action!="deliver" or not row.active:return "Aceite o pedido antes de entregar."
	var requested:=order(state,key);var cargo:=FarmPickupCargo.contents(state).duplicate()
	for product in requested:
		if int(cargo.get(product,0))<int(requested[product]):return "Falta %s na caçamba. Carregue perto da camionetinha com V."%title(product)
	var payment:=reward(state,key)
	for product in requested:
		cargo[product]-=int(requested[product])
		if cargo[product]==0:cargo.erase(product)
	state.pickup.cargo=cargo;state.money+=payment;state.revenue+=payment
	row.done+=1;row.active=false;row.ready_at=state.elapsed+COOLDOWN
	state.refresh_journey()
	return ""
