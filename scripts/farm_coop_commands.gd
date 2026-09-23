class_name FarmCoopCommands
extends RefCounted
## Only this allowlist may mutate the authoritative cooperative farm.
const SIMPLE:=["tool:expand","remove","route_confirm","apply_text","apply_hen_name","upgrade","professional_watering","sell","contract","sell_milk","staff_hire","staff_assign","staff_pause","staff_dismiss","crew_hire","crew_pause","crew_dismiss","irrigation_apply","cultivation_apply","cultivation_renew","raul:confirm","raul:pause","chico:confirm","chico:pause","cheese:start","cheese:collect","cheese:sell","cheese:accept","cheese:cancel","cheese:deliver"]
const PREFIXES:=["pigs:buy","pigs:food","pigs:water","parcel_buy:","evolution_buy:","paint:","deposit:","withdraw:","sell_product:","accept_order:","deliver_order:","cancel_order:","care:","dairy:buy","dairy:milk","dairy:food","dairy:water","crew_train:"]

static func mutates(value:String) -> bool:
	if value in SIMPLE:return true
	for prefix in PREFIXES:
		if value.begins_with(prefix):return true
	return false

static func capture(game:Node3D,value:String) -> Dictionary:
	var h:FarmHUD=game.hud
	var c:Dictionary={"action":value,"index":game.selected,"hen":game.selected_hen}
	if value in ["apply_text","apply_hen_name"]:c.text=h.text_input.text if is_instance_valid(h.text_input) else ""
	if value=="route_confirm":c.plan=game.route.duplicate(true)
	if value.begins_with("evolution_buy:"):c.index=int(value.get_slice(":",1))
	if value.begins_with("paint:"):c.part=["walls","roof","door"][h.paint_selector.selected]
	if value.begins_with("sell_product:"):
		var key:=value.get_slice(":",1)
		c.quantity=int(h.sale_quantities[key].value) if h.sale_quantities.has(key) else 0
	if value=="sell_milk":c.quantity=int(h.milk_quantity.value)
	if value=="cheese:sell":c.quantity=int(h.cheese_quantity.value)
	if value.begins_with("staff_"):c.site=h.staff_target
	if value=="irrigation_apply":c.plots=h.irrigation_draft.duplicate()
	if value=="cultivation_apply":c.draft=h.cultivation_draft.duplicate(true)
	if value.begins_with("cheese:"):
		c.index=h.building_index;c.batch=h.cheese_batch
	if value=="raul:confirm":c.operation=h.raul_confirm;c.site=h.raul_site;c.budget=h.raul_budget
	if value=="chico:confirm":c.operation=h.chico_confirm;c.site=h.chico_site;c.budget=h.chico_budget;c.batch=h.chico_batch
	return c

static func structural(action:String) -> bool:
	return action in ["claim","place","move_item","remove","route_confirm","tool:expand","apply_text","apply_hen_name"] or action.begins_with("parcel_buy:") or action.begins_with("evolution_buy:") or action.begins_with("paint:")

static func run(s:FarmState,c:Dictionary) -> String:
	# Validate types before any indexed access or conversion of untrusted requests.
	if not c.get("action") is String:return "Ação inválida."
	var action:String=c.action
	if action not in ["claim","place","move_item"] and not mutates(action):return "Ação desconhecida."
	for key in ["index","hen","quantity","site","budget","batch","turn"]:
		if c.has(key) and (not c[key] is int or abs(c[key])>1000000000):return "Valor inválido."
	for key in ["text","part","kind","crop","operation"]:
		if c.has(key) and (not c[key] is String or c[key].length()>200):return "Texto inválido."
	var i:int=c.get("index",-1)
	var item:Dictionary=s.items[i] if i>=0 and i<s.items.size() else {}
	var key:=action.get_slice(":",1)
	var q:int=c.get("quantity",0)
	var needs_item:=action in ["move_item","remove","apply_text","apply_hen_name","cheese:start","cheese:collect"] or action.begins_with("evolution_buy:") or action.begins_with("paint:") or action.begins_with("care:") or action.begins_with("dairy:") or action.begins_with("pigs:")
	if needs_item and item.is_empty():return "Essa construção não existe mais."
	if action in ["claim","place","move_item"]:
		if not c.get("at") is Vector2 or not c.at.is_finite() or c.at.length()>500:return "Posição inválida."
		var turn:int=c.get("turn",0)
		if turn<0 or turn>3:return "Rotação inválida."
		if action=="claim":return s.claim(c.at)
		if action=="move_item":return s.move_item(i,c.at,turn)
		if not FarmState.ITEMS.has(c.get("kind","")) or not FarmState.CROPS.has(c.get("crop","carrot")):return "Construção ou cultura inválida."
		return s.place(c.kind,c.at,turn,c.get("crop","carrot"))
	if action.begins_with("parcel_buy:"):return FarmParcels.buy(s,key)
	if action.begins_with("evolution_buy:"):return s.upgrade_building(i)
	if action.begins_with("paint:"):return s.paint_item(i,c.get("part",""),int(key))
	if action.begins_with("deposit:") or action.begins_with("withdraw:"):
		if not s.inventory.has(key):return "Produto inválido."
		s.transfer_reserve(key,action.begins_with("deposit:"));return ""
	if action.begins_with("sell_product:"):return "" if s.sell_product(key,q)>0 else "Estoque insuficiente para essa venda."
	if action.begins_with("accept_order:"):return s.accept_order(key)
	if action.begins_with("deliver_order:"):return s.deliver_order(key)
	if action.begins_with("cancel_order:"):return s.cancel_order(key)
	if action.begins_with("care:"):
		if item.kind!="coop" or key not in ["food","water","collect"]:return "Cuidado inválido."
		return s.care_coop(i,key)
	if action.begins_with("pigs:"):
		if item.kind!="pigsty" or key not in ["buy","food","water"]:return "Cuidado inválido."
		return FarmPigs.care(s,i,key)
	if action.begins_with("dairy:"):
		if item.kind!="corral" or key not in ["buy","milk","food","water"]:return "Cuidado inválido."
		return FarmDairy.care(s,i,key)
	if action.begins_with("crew_train:"):return s.train_worker(key)
	match action:
		"tool:expand":return s.expand()
		"remove":return s.remove_item(i)
		"route_confirm":
			if not c.get("plan") is Array or c.plan.is_empty() or c.plan.size()>64:return "Traçado inválido."
			for piece in c.plan:
				if not piece is Dictionary or piece.get("kind") not in ["path","fence"]:return "Peça inválida."
				for field in ["x","z","turn"]:
					if not (piece.get(field) is float or piece.get(field) is int) or not is_finite(float(piece[field])):return "Traçado inválido."
				if absf(piece.x)>250 or absf(piece.z)>250 or piece.turn not in [0,1,2,3]:return "Traçado fora do mapa."
			return s.place_batch(c.plan)
		"apply_text":
			if item.kind!="sign":return "Selecione uma placa."
			item.text=c.get("text","").strip_edges().left(40)
		"apply_hen_name":return s.rename_hen(i,c.get("hen",-1),c.get("text",""))
		"upgrade":return s.buy_watering_upgrade()
		"professional_watering":return s.buy_professional_watering()
		"sell":s.sell_all()
		"contract":return "" if s.deliver_contract() else "Faltam produtos ou a entrega já foi concluída."
		"sell_milk":return "" if FarmDairy.sell(s,q)>0 else "Leite insuficiente."
		"staff_hire":return s.hire_staff(c.get("site",-1))
		"staff_assign":return s.assign_staff(c.get("site",-1))
		"staff_pause":return s.pause_staff()
		"staff_dismiss":s.dismiss_staff()
		"crew_hire":return s.hire_field_staff()
		"crew_pause":return s.pause_field_staff()
		"crew_dismiss":s.dismiss_field_staff()
		"irrigation_apply":
			if not c.get("plots") is Array:return "Seleção inválida."
			return s.configure_irrigation(c.plots)
		"cultivation_apply":
			var draft:Variant=c.get("draft")
			if not draft is Dictionary or not draft.get("plans") is Array or not draft.get("tasks") is Dictionary or not draft.get("limit") is int:return "Rotina inválida."
			return FarmCultivation.configure(s,draft.plans,draft.tasks,draft.limit)
		"cultivation_renew":return FarmCultivation.renew(s)
		"raul:confirm","chico:confirm":
			var dairy:=action.begins_with("raul:")
			var operation:String=c.get("operation","")
			match operation:
				"hire":return FarmDairyWorker.hire(s) if dairy else FarmCheeseWorker.hire(s)
				"apply","renew":return FarmDairyWorker.configure(s,c.get("site",-1),c.get("budget",0),operation=="renew") if dairy else FarmCheeseWorker.configure(s,c.get("site",-1),c.get("batch",0),c.get("budget",0),operation=="renew")
				"dismiss":
					if dairy:FarmDairyWorker.dismiss(s)
					else:FarmCheeseWorker.dismiss(s)
				_:return "Operação inválida."
		"raul:pause","chico:pause":
			var worker:Dictionary=s.dairy_worker if action.begins_with("raul:") else s.cheese_worker
			if not worker.hired:return "Contrate o funcionário primeiro."
			worker.paused=not (worker.paused and worker.site>=0);worker.reason="manual" if worker.paused else ""
		"cheese:start":return FarmCheese.start(s,i,c.get("batch",0))
		"cheese:collect":
			if item.kind!="cheesery":return "Escolha uma queijaria."
			FarmCheese.collect(s,i)
		"cheese:sell":return "" if FarmCheese.sell(s,q)>0 else "Queijo insuficiente."
		"cheese:accept":
			if not s.claimed:return "Escolha seu terreno."
			s.cheese_order.active=true
		"cheese:cancel":s.cheese_order.active=false
		"cheese:deliver":return "" if FarmCheese.deliver(s) else "Falta queijo ou encomenda ativa."
	return ""
