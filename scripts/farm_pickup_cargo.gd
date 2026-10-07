class_name FarmPickupCargo
extends RefCounted
const CAPACITY:=60
const KEYS:=["carrot","wheat","corn","egg","milk","cheese","tilapia","trout","dorado","copper","iron","quartz","orange","gold","amethyst"]
const TITLES:=["Cenoura","Trigo","Milho","Ovos","Leite","Queijo","Tilápia","Truta","Dourado","Cobre","Ferro","Quartzo","Laranjas","Ouro","Ametista"]

static func count(cargo:Dictionary) -> int:
	var total:=0
	for amount in cargo.values():total+=int(amount)
	return total

static func valid(cargo:Variant,limit:int=CAPACITY) -> bool:
	if not cargo is Dictionary:return false
	for key in cargo:
		if key not in KEYS or not FarmResources._integer(cargo[key],limit):return false
	return count(cargo)<=limit

static func contents(state:FarmState) -> Dictionary:
	return state.pickup.get("cargo",{})

static func transfer(state:FarmState,key:String,amount:int,loading:bool) -> String:
	if not state.claimed or key not in KEYS or amount<=0:return "Carga inválida."
	var cargo:=contents(state).duplicate()
	if loading:
		if amount>state.stock(key):return "Não há essa quantidade no estoque."
		if count(cargo)+amount>FarmGarage.capacity(state):return "A caçamba está cheia."
		state.consume_stock(key,amount);cargo[key]=int(cargo.get(key,0))+amount
	else:
		if amount>int(cargo.get(key,0)):return "Essa quantidade não está na caçamba."
		if not state.infinite_resources():
			var limit:=FarmResources.STOCK_LIMIT if state.resources.stock.has(key) else 1000000000
			if state.stock(key)+amount>limit:return "Não há espaço no estoque; a carga continua no carro."
			if key=="milk":state.milk_stock+=amount
			elif key=="cheese":state.cheese_stock+=amount
			elif state.inventory.has(key):state.inventory[key]+=amount
			else:state.resources.stock[key]+=amount
		cargo[key]=int(cargo[key])-amount
		if cargo[key]==0:cargo.erase(key)
	state.pickup.cargo=cargo
	return ""

static func price(key:String) -> int:
	if key=="milk":return FarmDairy.MILK_PRICE
	if key=="cheese":return FarmCheese.PRICE
	return int(FarmTrade.PRICES[key]) if FarmTrade.PRICES.has(key) else int(FarmResources.PRICES.get(key,0))

static func value(state:FarmState) -> int:
	var total:=0
	for key in contents(state):total+=int(contents(state)[key])*price(key)
	return total

static func sell(state:FarmState) -> int:
	var total:=value(state)
	if total<=0:return 0
	state.pickup.cargo={};state.money+=total;state.revenue+=total;state.refresh_journey()
	return total

static func show(vehicle:FarmPickup) -> void:
	var h:FarmHUD=vehicle.game.hud;var state:FarmState=vehicle.game.state
	var p:=FarmGameUI.open(h,"pickup_cargo","Caçamba da camionetinha","barn",970,760)
	h.label(p,"%d / %d unidades · Estoque → caçamba → armazém"%[count(contents(state)),FarmGarage.capacity(state)],Vector2(26,107),Vector2(920,30),20)
	for i in range(KEYS.size()):
		var key:String=KEYS[i];var amount:=int(contents(state).get(key,0))
		var card:=FarmGameUI.card(h,p,Rect2(26+(i%3)*310,151+(i/3)*90,302,84))
		h.label(card,TITLES[i],Vector2(12,3),Vector2(278,23),18)
		h.label(card,"Estoque %s · Carga %d"%[state.stock_text(key),amount],Vector2(12,25),Vector2(278,20),14,FarmHUD.MUTED)
		var load_count:=mini(10,mini(state.stock(key),FarmGarage.capacity(state)-count(contents(state))))
		var put:=FarmGameUI.action(h,card,"+ %d"%load_count,Rect2(12,49,132,29),"pickup:load:"+key)
		put.disabled=load_count<=0
		var take:=FarmGameUI.action(h,card,"− %d"%mini(10,amount),Rect2(158,49,132,29),"pickup:unload:"+key)
		take.disabled=amount==0
		for button in [put,take]:
			for style_name in ["normal","hover","pressed","disabled"]:
				var compact := button.get_theme_stylebox(style_name) as StyleBoxFlat
				compact.content_margin_top=4
				compact.content_margin_bottom=4
			button.size.y=29
	h.label(p,"Vender perto da Lúcia. Descarregar devolve ao estoque, sem perder produtos.",Vector2(26,618),Vector2(916,28),17,FarmHUD.MUTED)
	var sell_button:=FarmGameUI.action(h,p,"Vender carga · $%d"%value(state) if vehicle.near_market() else "Leve a carga ao armazém da Lúcia",Rect2(26,669,600,48),"pickup:sell",true)
	sell_button.disabled=not vehicle.near_market() or count(contents(state))==0
	FarmGameUI.action(h,p,"Garagem",Rect2(642,669,145,48),"garage:open").disabled=not FarmGarage.can_service(vehicle)
	FarmGameUI.action(h,p,"Voltar",Rect2(799,669,145,48),"close")
