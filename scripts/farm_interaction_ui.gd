class_name FarmInteractionUI
extends RefCounted

static func orchard(hud: FarmHUD, state: FarmState, index: int) -> void:
	if index < 0 or index >= state.items.size() or state.items[index].kind != "orchard": return
	hud.building_index = index
	var item: Dictionary = state.items[index]
	var data: Dictionary = item.get("orchard", {})
	var mature := float(data.get("growth", 0)) >= FarmOrchard.GROW_SECONDS
	var ready := int(data.get("ready", 0))
	var watered := bool(data.get("watered", false))
	var p := FarmGameUI.open(hud, "orchard", "Laranjeira do pomar", "seed", 760, 542)
	p.set_meta("orchard_status", hud.label(p, FarmOrchard.status(item), Vector2(26, 118), Vector2(708, 38), 25))
	var description := "Regue a muda para ela crescer. Depois de adulta, começa a formar frutas."
	if mature: description = "Regue uma vez por safra. Colha as laranjas maduras e cuide da próxima colheita."
	var detail := hud.label(p, description, Vector2(26, 172), Vector2(708, 58), 20)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p.set_meta("orchard_detail", detail)
	var progress := float(data.get("fruit_time", 0)) / FarmOrchard.FRUIT_SECONDS if mature else float(data.get("growth", 0)) / FarmOrchard.GROW_SECONDS
	FarmGameUI.meter(hud, p, Rect2(26, 251, 708, 18), 1.0 if ready > 0 else progress, Color("d4a44d") if mature else Color("759558"))
	p.set_meta("orchard_meter", p.get_child(-1))
	p.set_meta("orchard_phase", hud.label(p, "Frutificação" if mature else "Crescimento da árvore", Vector2(26, 282), Vector2(440, 30), 19))
	hud.label(p, "%d laranjas por safra" % FarmOrchard.YIELD, Vector2(470, 282), Vector2(264, 30), 19)
	var water := FarmGameUI.action(hud, p, "Já regada" if watered else "Regar • grátis", Rect2(26, 336, 344, 48), "orchard:water")
	water.disabled = watered or ready > 0
	var harvest := FarmGameUI.action(hud, p, "Colher %d laranjas" % ready if ready > 0 else "Aguardando frutas", Rect2(390, 336, 344, 48), "orchard:harvest", ready > 0)
	harvest.disabled = ready <= 0
	p.set_meta("orchard_water", water)
	p.set_meta("orchard_harvest", harvest)
	hud.label(p, "Aproxime-se a pé para regar e colher. As frutas vão para o estoque.", Vector2(26, 412), Vector2(708, 28), 16)
	FarmGameUI.action(hud,p,"Zeca · cuidar do pomar",Rect2(26,471,708,44),"orchard_staff:open")

static func update_orchard(hud: FarmHUD, state: FarmState) -> void:
	if hud.modal_kind != "orchard" or not is_instance_valid(hud.modal): return
	var index := hud.building_index
	if index < 0 or index >= state.items.size() or state.items[index].kind != "orchard": return
	var p := hud.modal
	if not p.has_meta("orchard_status"): return
	var item: Dictionary = state.items[index]
	var data: Dictionary = item.get("orchard", {})
	var mature := float(data.get("growth", 0)) >= FarmOrchard.GROW_SECONDS
	var ready := int(data.get("ready", 0))
	var watered := bool(data.get("watered", false))
	p.get_meta("orchard_status").text = FarmOrchard.status(item)
	p.get_meta("orchard_detail").text = "Regue uma vez por safra. Colha as laranjas maduras e cuide da próxima colheita." if mature else "Regue a muda para ela crescer. Depois de adulta, começa a formar frutas."
	p.get_meta("orchard_phase").text = "Frutificação" if mature else "Crescimento da árvore"
	var progress := float(data.get("fruit_time", 0)) / FarmOrchard.FRUIT_SECONDS if mature else float(data.get("growth", 0)) / FarmOrchard.GROW_SECONDS
	var meter: ColorRect = p.get_meta("orchard_meter")
	meter.size.x = 702 * clampf(1.0 if ready > 0 else progress, 0, 1)
	meter.color = Color("d4a44d") if mature else Color("759558")
	var water: Button = p.get_meta("orchard_water")
	water.text = "Já regada" if watered else "Regar • grátis"
	water.disabled = watered or ready > 0
	var harvest: Button = p.get_meta("orchard_harvest")
	harvest.text = "Colher %d laranjas" % ready if ready > 0 else "Aguardando frutas"
	harvest.disabled = ready <= 0

static func evolution(hud:FarmHUD,p:Control,state:FarmState,index:int,rect:Rect2) -> void:
	if index<0: return
	var item:Dictionary=state.items[index]
	var level:=FarmProgression.level(item)
	if level==2:
		FarmGameUI.icon(p,"check",Rect2(rect.position.x,rect.position.y,36,36))
		hud.label(p,"Nível 2",rect.position+Vector2(44,5),rect.size-Vector2(44,0),21)
	else:
		FarmGameUI.action(hud,p,"Evoluir • $%d"%FarmProgression.UPGRADES[item.kind].cost,rect,"evolution:%d"%index)

static func house(hud:FarmHUD,state:FarmState,index:int) -> void:
	if index<0 or index>=state.items.size() or state.items[index].kind!="house": return
	hud.building_index=index
	var p:=FarmGameUI.open(hud,"house","Casa da fazenda","barn",720,370)
	hud.label(p,"Seu cantinho no vale",Vector2(26,116),Vector2(668,36),25)
	hud.label(p,"Personalize o quintal e renove a fachada da sua casa.\nConstrução decorativa, sem interior nesta versão.",Vector2(26,166),Vector2(668,70),20)
	evolution(hud,p,state,index,Rect2(26,266,330,46))

static func barn(hud:FarmHUD,state:FarmState,index:int) -> void:
	hud.building_index=hud.building_choice(state,index,"barn")
	var p:=FarmGameUI.open(hud,"barn","Celeiro","barn",840,616)
	hud.label(p,"Reserva  %d / %d"%[state.reserve_count(),state.reserve_capacity()],Vector2(26,114),Vector2(365,32),22)
	FarmGameUI.meter(hud,p,Rect2(414,120,396,18),float(state.reserve_count())/maxi(1,state.reserve_capacity()),Color("759558"))
	var keys:=["carrot","wheat","corn","egg"]
	for i in range(4):
		var key:String=keys[i]
		var c:=FarmGameUI.card(hud,p,Rect2(26+(i%2)*402,166+(i/2)*179,386,163))
		FarmGameUI.icon(c,key,Rect2(12,14,62,62))
		hud.label(c,FarmTrade.NAMES[key],Vector2(87,11),Vector2(280,27),21)
		hud.label(c,"Disponível",Vector2(88,47),Vector2(125,21),13,FarmHUD.MUTED)
		hud.label(c,"Na reserva",Vector2(242,47),Vector2(125,21),13,FarmHUD.MUTED)
		hud.label(c,state.stock_text(key),Vector2(88,68),Vector2(120,35),28)
		hud.label(c,str(state.reserve[key]),Vector2(242,68),Vector2(120,35),28)
		var deposit:=FarmGameUI.action(hud,c,"Guardar →",Rect2(12,112,174,39),"deposit:"+key)
		var withdraw:=FarmGameUI.action(hud,c,"← Retirar",Rect2(198,112,174,39),"withdraw:"+key)
		deposit.disabled=state.stock(key)<=0 or state.reserve_count()>=state.reserve_capacity()
		withdraw.disabled=state.reserve[key]<=0
		deposit.tooltip_text="Guarda toda a quantidade que couber. A reserva não é vendida."
		withdraw.tooltip_text="Devolve a reserva deste produto ao estoque disponível."
	FarmGameUI.action(hud,p,"Leite e queijo",Rect2(26,536,228,42),"cheese_shop")
	FarmGameUI.icon(p,"lock",Rect2(270,552,28,28))
	hud.label(p,"Reserva protegida",Vector2(306,553),Vector2(246,28),16)
	evolution(hud,p,state,hud.building_index,Rect2(564,543,246,43))

static func coop(hud:FarmHUD,state:FarmState,index:int,selected_hen:int) -> void:
	if hud.building_index!=index: hud.coop_tab="care"
	hud.building_index=index
	var flock:Dictionary=state.items[index].flock
	var p:=FarmGameUI.open(hud,"coop","Galinheiro","chicken",820,602)
	FarmGameUI.action(hud,p,"Cuidados",Rect2(26,112,230,42),"coop_tab:care",hud.coop_tab=="care")
	FarmGameUI.action(hud,p,"Galinhas • %d"%flock.names.size(),Rect2(270,112,230,42),"coop_tab:hens",hud.coop_tab=="hens")
	evolution(hud,p,state,index,Rect2(552,112,240,42))
	if hud.coop_tab=="care":
		for i in range(3):
			var key:String=["egg","wheat","water"][i]
			var c:=FarmGameUI.card(hud,p,Rect2(26+i*262,180,244,300))
			FarmGameUI.icon(c,key,Rect2(82,20,80,80))
			hud.label(c,["Ovos no ninho","Ração","Água"][i],Vector2(16,112),Vector2(212,30),21).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
			var quantity:String=("%d / %d"%[flock.nest,FarmAnimals.capacity(flock)]) if i==0 else "%d%%"%roundi(flock.food if i==1 else flock.water)
			hud.label(c,quantity,Vector2(16,148),Vector2(212,40),31).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
			var amount:float=float(flock.nest)/FarmAnimals.capacity(flock) if i==0 else float(flock.food if i==1 else flock.water)/100
			FarmGameUI.meter(hud,c,Rect2(22,203,200,15),amount,Color("d4a44d") if i!=2 else Color("6aaab9"))
			var cost:=FarmAnimals.food_cost(flock)
			var text:String=("Coletar %d"%flock.nest) if i==0 else ("Repor • $%d"%cost if i==1 else "Encher • grátis")
			if i==0 and flock.nest==0: text="Ninho vazio"
			elif i==1 and cost==0: text="Ração completa"
			elif i==2 and flock.water>=100: text="Água completa"
			var b:=FarmGameUI.action(hud,c,text,Rect2(14,240,216,45),"care:"+["collect","food","water"][i],i==0)
			b.disabled=flock.nest==0 if i==0 else (cost==0 or state.money<cost if i==1 else flock.water>=100)
			b.tooltip_text="Sem água ou ração, a produção fica mais lenta."
		var status:="Ninho cheio! Colete os ovos." if flock.nest>=FarmAnimals.capacity(flock) else "%d ovos a cada %d s • %s"%[FarmAnimals.eggs_per_cycle(flock),roundi(45/FarmAnimals.rate(flock)),FarmAnimals.status(flock)]
		hud.label(p,status,Vector2(28,506),Vector2(764,30),19)
	else:
		for i in range(flock.names.size()):
			var c:=FarmGameUI.card(hud,p,Rect2(26+(i%2)*394,180+(i/2)*112,374,98))
			FarmGameUI.icon(c,"chicken",Rect2(12,15,60,60)).modulate=Color(FarmAnimals.COLORS[i])
			hud.label(c,flock.names[i],Vector2(83,14),Vector2(275,27),19)
			var b:=FarmGameUI.action(hud,c,"Renomear",Rect2(83,48,163,35),"rename_hen:%d"%i)
			b.tooltip_text=FarmAnimals.TRAITS[i]
	FarmGameUI.action(hud,p,"Zeca • cuidar",Rect2(26,547,245,38),"staff_coop")
	hud.label(p,"Esc  voltar ao campo",Vector2(524,553),Vector2(266,25),15,FarmHUD.MUTED)

static func workshop(hud:FarmHUD,state:FarmState,index:int) -> void:
	hud.building_index=hud.building_choice(state,index,"workshop")
	var p:=FarmGameUI.open(hud,"workshop","Oficina rural","workshop",820,566)
	var equipped:=false
	for item in state.items:
		if item.kind=="workshop" and FarmProgression.level(item)==2: equipped=true
	for i in range(2):
		var owned:bool=state.watering_upgrade if i==0 else state.professional_watering
		var c:=FarmGameUI.card(hud,p,Rect2(26+i*394,118,374,335))
		FarmGameUI.icon(c,"water",Rect2(34,26,92,92))
		for x in range(3):
			for z in range(3):
				var active:bool=i==1 or x==1 or z==1
				hud.panel(c,Rect2(211+x*32,27+z*32,27,27),Color("6eaaa6") if active else Color("dfd3b3"))
		hud.label(c,["Regador em cruz","Regador profissional"][i],Vector2(20,147),Vector2(336,35),24)
		hud.label(c,"5 canteiros" if i==0 else "9 canteiros • inclui diagonais",Vector2(20,192),Vector2(336,29),18)
		var requirement:="" if i==0 or owned else ("Requer oficina nível 2" if not equipped else ("Requer regador em cruz" if not state.watering_upgrade else ""))
		var text:="✓ Equipado" if owned else (requirement if not requirement.is_empty() else "Comprar • $%d"%(300 if i==0 else 450))
		var b:=FarmGameUI.action(hud,c,text,Rect2(16,265,342,49),"upgrade" if i==0 else "professional_watering",not owned)
		b.disabled=owned or not requirement.is_empty() or state.money<(300 if i==0 else 450)
		b.tooltip_text="Melhoria permanente para sua rega manual. Não altera o alcance do ajudante."
		if owned: FarmGameUI.icon(c,"check",Rect2(20,226,28,28))
	FarmGameUI.icon(p,"coins",Rect2(26,489,40,40))
	hud.label(p,hud.money_text(state),Vector2(79,493),Vector2(330,35),25)
	evolution(hud,p,state,hud.building_index,Rect2(542,487,252,44))

static func market(hud:FarmHUD,state:FarmState,tab:String) -> void:
	hud.market_tab=tab
	var p:=FarmGameUI.open(hud,"market","Armazém da Lúcia","harvest",940,744 if tab=="orders" else 834)
	FarmGameUI.action(hud,p,"Vender",Rect2(26,111,208,43),"market_sales",tab=="sales")
	FarmGameUI.action(hud,p,"Encomendas • %d"%state.active_orders(),Rect2(247,111,254,43),"market_orders",tab=="orders")
	FarmGameUI.icon(p,"coins",Rect2(698,112,36,36))
	hud.label(p,hud.money_text(state),Vector2(743,115),Vector2(170,34),24)
	FarmGameUI.action(hud,p,"Leite e queijo",Rect2(519,111,164,43),"cheese_shop")
	if tab=="orders":
		hud._orders(state,p)
		return
	hud.sale_quantities.clear(); hud.sale_buttons.clear()
	var keys:=["carrot","wheat","corn","egg","orange"]
	for i in range(keys.size()):
		var key:String=keys[i]
		var price:int=FarmTrade.PRICES[key]
		var c:=FarmGameUI.card(hud,p,Rect2(26+(i%2)*450,170+(i/2)*164,436,156))
		FarmGameUI.icon(c,key,Rect2(14,12,62,62))
		hud.label(c,FarmTrade.NAMES[key],Vector2(88,12),Vector2(210,30),22)
		hud.label(c,"$%d / un."%price,Vector2(88,48),Vector2(156,26),17,FarmHUD.MUTED)
		hud.label(c,"%s un."%state.stock_text(key),Vector2(292,25),Vector2(131,39),25)
		var quantity:=SpinBox.new()
		quantity.position=Vector2(14,96); quantity.size=Vector2(88,43)
		quantity.min_value=1; quantity.max_value=maxi(1,int(state.stock(key))); quantity.step=1; quantity.rounded=true
		quantity.update_on_text_changed=true; quantity.value=1; quantity.editable=state.stock(key)>0
		quantity.get_line_edit().add_theme_stylebox_override("normal",hud.style(Color("ffffff"),5,Color("8ba494")))
		c.add_child(quantity); hud.sale_quantities[key]=quantity
		var sale:=FarmGameUI.action(hud,c,"Vender 1 • $%d"%price,Rect2(114,96,308,43),"sell_product:"+key,true)
		sale.disabled=state.stock(key)<=0; hud.sale_buttons[key]=sale
		quantity.value_changed.connect(func(amount:float): sale.text="Vender %d • $%d"%[int(amount),int(amount)*price])
	var orchard:=FarmGameUI.card(hud,p,Rect2(476,498,436,156))
	FarmGameUI.icon(orchard,"orange",Rect2(14,12,62,62))
	hud.label(orchard,"Primeira colheita",Vector2(88,12),Vector2(330,30),22)
	hud.label(orchard,"Uma encomenda para o seu pomar",Vector2(88,48),Vector2(330,28),16,FarmHUD.MUTED)
	FarmGameUI.action(hud,orchard,"Ver missão do pomar",Rect2(14,96,408,43),"orchard:open",true)
	var all:=FarmGameUI.action(hud,p,("Vender 1 de cada • $%d" if state.infinite_resources() else "Vender tudo • $%d")%state.sale_value(),Rect2(26,678,436,48),"sell",true)
	all.disabled=state.sale_value()==0
	all.tooltip_text="Vende apenas o estoque disponível; não inclui reserva nem ovos no ninho."
	var contract:=FarmGameUI.action(hud,p,"✓ Pedido entregue" if state.contract_done else "Entregar 6 cenouras • $110",Rect2(476,678,436,48),"contract")
	contract.disabled=state.contract_done or state.stock("carrot")<6
	contract.tooltip_text="Entregue 6 cenouras. Sem prazo. Recompensa: $110 e +1 reputação."
	FarmGameUI.icon(p,"lock",Rect2(26,771,28,28))
	hud.label(p,"%d produtos protegidos na reserva"%state.reserve_count(),Vector2(67,773),Vector2(530,27),17)
	FarmGameUI.action(hud,p,"Pesca e mineração",Rect2(636,764,276,43),"resources")
