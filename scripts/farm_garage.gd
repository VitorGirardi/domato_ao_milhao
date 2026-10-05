class_name FarmGarage
extends RefCounted
const COLORS:=["59836a","b35e42","4e7892","d5b96c","e5ddc4"]
const COLOR_NAMES:=["Verde pasto","Vermelho barro","Azul riacho","Amarelo milho","Creme"]
const UPGRADES:={
	"bed":{"title":"Caçamba reforçada","detail":"60 → 120 unidades · duas camadas de caixas","cost":900,"ore":"iron","amount":12},
	"tires":{"title":"Pneus de roça","detail":"Mais aderência em encostas · frenagem reforçada","cost":650,"ore":"copper","amount":8},
	"engine":{"title":"Motor preparado","detail":"Aceleração mais forte · 72 → 79 km/h","cost":1200,"ore":"iron","amount":16},
	"rack":{"title":"Bagageiro de teto","detail":"Acessório visual de madeira e metal","cost":180,"ore":"copper","amount":3}
}
static func defaults() -> Dictionary:return {"name":"Camionetinha","paint":0,"bed":false,"tires":false,"engine":false,"rack":false}
static func config(state:FarmState) -> Dictionary:return state.pickup.get("garage",defaults())
static func valid(data:Variant) -> bool:
	if not data is Dictionary or data.size()!=6:return false
	if not data.get("name") is String or data.name.strip_edges().is_empty() or data.name.length()>24:return false
	for ch in data.name:
		if ch.unicode_at(0)<32 or ch.unicode_at(0)==127:return false
	if not FarmResources._integer(data.get("paint"),COLORS.size()-1):return false
	for key in UPGRADES:
		if not data.get(key) is bool:return false
	return true
static func capacity(state:FarmState) -> int:return 120 if config(state).bed else 60
static func entrance(item:Dictionary) -> Vector2:
	var offset:=Vector3(0,0,5.5).rotated(Vector3.UP,int(item.turn)*PI/2)
	return Vector2(item.x+offset.x,item.z+offset.z)
static func nearby(state:FarmState,point:Vector2) -> int:
	for i in range(state.items.size()):
		var item:Dictionary=state.items[i]
		if item.kind=="garage" and point.distance_to(Vector2(item.x,item.z))<=8:return i
	return -1
static func purchase(state:FarmState,key:String) -> String:
	if not state.claimed or state.count_items("garage")==0:return "Construa uma garagem na sua fazenda."
	if not UPGRADES.has(key):return "Melhoria desconhecida."
	var data:=config(state).duplicate();var offer:Dictionary=UPGRADES[key]
	if data[key]:return "Essa melhoria já está instalada."
	if state.money<int(offer.cost):return "Moedas insuficientes."
	if state.stock(offer.ore)<int(offer.amount):return "Separe %d unidades de %s."%[offer.amount,"ferro" if offer.ore=="iron" else "cobre"]
	state.money-=int(offer.cost);state.consume_stock(offer.ore,int(offer.amount));data[key]=true;state.pickup.garage=data
	return ""
static func personalize(state:FarmState,field:String,value:Variant) -> String:
	if state.count_items("garage")==0:return "Construa uma garagem na sua fazenda."
	var data:=config(state).duplicate()
	if field not in ["name","paint"]:return "Personalização inválida."
	data[field]=value
	if not valid(data):return "Use um nome de 1 a 24 caracteres e uma cor disponível."
	state.pickup.garage=data;return ""
static func can_service(vehicle:FarmPickup) -> bool:
	return vehicle.cargo_access() and nearby(vehicle.game.state,Vector2(vehicle.position.x,vehicle.position.z))>=0
static func handle(game:Node3D,action:String) -> void:
	if action=="garage:open":show(game);return
	if game.hud.modal_kind!="garage" or not can_service(game.pickup):game.hud.toast("Estacione a camionetinha na garagem e aproxime-se dela.");return
	var error:=""
	if action.begins_with("garage:buy:"):error=purchase(game.state,action.get_slice(":",2))
	elif action.begins_with("garage:paint:"):error=personalize(game.state,"paint",int(action.get_slice(":",2)))
	elif action=="garage:name":error=personalize(game.state,"name",game.hud.text_input.text.strip_edges())
	else:return
	game.pickup.refresh_customization();game.pickup.refresh_cargo();show(game)
	game.hud.toast("Camionetinha atualizada!" if error.is_empty() else error)
	if error.is_empty():game._save_game(false)
static func show(game:Node3D) -> void:
	var h:FarmHUD=game.hud;var state:FarmState=game.state;var data:=config(state)
	var p:=FarmGameUI.open(h,"garage","Garagem da fazenda","map_pickup",1000,780)
	var ready:=can_service(game.pickup)
	var hint:="Estacionada · melhorias permanentes desta fazenda" if ready else "Traga o carro até a garagem, pare e fique perto dele para personalizar."
	if game.network.active:hint="A garagem aparece no cooperativo; a camionetinha e suas melhorias são do solo."
	h.label(p,hint,Vector2(26,106),Vector2(948,46),18)
	var i:=0
	for key in UPGRADES:
		var offer:Dictionary=UPGRADES[key];var card:=FarmGameUI.card(h,p,Rect2(26+(i%2)*480,163+(i/2)*151,468,139))
		h.label(card,offer.title,Vector2(14,8),Vector2(440,30),22)
		h.label(card,offer.detail,Vector2(14,43),Vector2(440,28),15)
		var cost:="Instalada" if data[key] else "Instalar · $%d + %d %s"%[offer.cost,offer.amount,"ferro" if offer.ore=="iron" else "cobre"]
		if state.game_mode=="sandbox" and not data[key]:cost="Instalar · liberada no Sandbox"
		var button:=FarmGameUI.action(h,card,cost,Rect2(14,83,440,40),"garage:buy:"+key,true)
		button.disabled=not ready or data[key];i+=1
	h.label(p,"Pintura · escolha sem custo",Vector2(26,476),Vector2(920,28),21)
	for color in range(COLORS.size()):
		var b:=FarmGameUI.action(h,p,COLOR_NAMES[color],Rect2(26+color*191,514,182,45),"garage:paint:%d"%color)
		b.add_theme_font_size_override("font_size",16);b.disabled=not ready
		b.add_theme_color_override("font_color",FarmHUD.INK if color>=3 else FarmHUD.CREAM)
		b.add_theme_stylebox_override("normal",h.style(Color(COLORS[color]),8,Color("f4cc72") if data.paint==color else Color("355041")))
	h.label(p,"Nome da camionetinha",Vector2(26,582),Vector2(600,29),21)
	h.text_input=LineEdit.new();h.text_input.max_length=24;h.text_input.text=data.name;h.text_input.position=Vector2(26,621);h.text_input.size=Vector2(646,44);h.text_input.editable=ready;p.add_child(h.text_input)
	FarmGameUI.action(h,p,"Salvar nome",Rect2(688,621,286,44),"garage:name",true).disabled=not ready
	FarmGameUI.action(h,p,"Voltar para a fazenda",Rect2(278,704,444,44),"close")

static func inside_bay(item:Dictionary,point:Vector2) -> bool:
	var offset:=Vector3(point.x-item.x,0,point.y-item.z).rotated(Vector3.UP,-int(item.turn)*PI/2)
	return absf(offset.x)<2.9 and offset.z> -2.7 and offset.z<4.3
