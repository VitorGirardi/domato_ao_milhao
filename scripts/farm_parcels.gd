class_name FarmParcels
extends RefCounted
const LOTS:={
	"east":{"name":"Clareira do Bosque","center":Vector2(58,-12),"size":24,"price":1800,"direction":"Leste · perto do bosque"},
	"north":{"name":"Campo dos Ipês","center":Vector2(12,-58),"size":24,"price":1400,"direction":"Norte · seguindo a estrada"},
	"south":{"name":"Campina do Sol","center":Vector2(12,60),"size":24,"price":1600,"direction":"Sul · além da estrada"}
}
static func area(key:String) -> Rect2:
	var lot:Dictionary=LOTS[key]
	return Rect2(lot.center-Vector2.ONE*lot.size/2,Vector2.ONE*lot.size)
static func valid(value:Variant) -> bool:
	if not value is Array or value.size()>LOTS.size():return false
	var seen:Array=[]
	for key in value:
		if not key is String or not LOTS.has(key) or key in seen:return false
		seen.append(key)
	return true
static func buy(state:FarmState,key:String) -> String:
	if not state.claimed:return "Escolha sua primeira fazenda antes de comprar outro terreno."
	if not LOTS.has(key):return "Terreno desconhecido."
	if key in state.owned_parcels:return "Este terreno já é seu."
	if state.money<int(LOTS[key].price):return "Faltam moedas para este terreno."
	state.money-=int(LOTS[key].price);state.owned_parcels.append(key)
	return ""
static func show(hud:FarmHUD,state:FarmState) -> void:
	var p:=FarmGameUI.open(hud,"parcels","Terrenos do vale","seed",800,610)
	hud.label(p,"Sua fazenda pode ter novos vizinhos: você mesmo!",Vector2(28,111),Vector2(740,30),19)
	var i:=0
	for key in LOTS:
		var lot:Dictionary=LOTS[key];var owned:bool=key in state.owned_parcels
		var card:=FarmGameUI.card(hud,p,Rect2(28,159+i*118,744,105))
		FarmGameUI.icon(card,"check" if owned else "seed",Rect2(15,22,50,50))
		hud.label(card,lot.name,Vector2(80,11),Vector2(420,30),23)
		hud.label(card,"%s · 24 × 24 m"%lot.direction,Vector2(80,46),Vector2(420,26),16)
		var b:=FarmGameUI.action(hud,card,"Seu terreno" if owned else "Comprar · $%d"%lot.price,Rect2(515,26,211,48),"parcel_buy:"+key,not owned)
		b.disabled=owned or not state.claimed
		i+=1
	hud.label(p,"A compra limpa a vegetação e libera construções nesse terreno.",Vector2(28,520),Vector2(744,26),17)
	FarmGameUI.action(hud,p,"Voltar ao vale",Rect2(248,558,304,40),"close")
