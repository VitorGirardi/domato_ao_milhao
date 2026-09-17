class_name FarmInteractionUI
extends RefCounted

static func evolution(hud:FarmHUD,p:Control,state:FarmState,index:int,rect:Rect2) -> void:
	if index<0: return
	var item:Dictionary=state.items[index]
	var level:=FarmProgression.level(item)
	if level==2:
		FarmGameUI.icon(p,"check",Rect2(rect.position.x,rect.position.y,36,36))
		hud.label(p,"Nível 2",rect.position+Vector2(44,5),rect.size-Vector2(44,0),21)
	else:
		FarmGameUI.action(hud,p,"Evoluir • $%d"%FarmProgression.UPGRADES[item.kind].cost,rect,"evolution:%d"%index)

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
		hud.label(c,str(state.inventory[key]),Vector2(88,68),Vector2(120,35),28)
		hud.label(c,str(state.reserve[key]),Vector2(242,68),Vector2(120,35),28)
		var deposit:=FarmGameUI.action(hud,c,"Guardar →",Rect2(12,112,174,39),"deposit:"+key)
		var withdraw:=FarmGameUI.action(hud,c,"← Retirar",Rect2(198,112,174,39),"withdraw:"+key)
		deposit.disabled=state.inventory[key]<=0 or state.reserve_count()>=state.reserve_capacity()
		withdraw.disabled=state.reserve[key]<=0
		deposit.tooltip_text="Guarda toda a quantidade que couber. A reserva não é vendida."
		withdraw.tooltip_text="Devolve a reserva deste produto ao estoque disponível."
	FarmGameUI.action(hud,p,"Leite · %d L"%state.milk_stock,Rect2(26,536,228,42),"milk_market")
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
	hud.label(p,"$%s"%hud._money(state.money),Vector2(79,493),Vector2(330,35),25)
	evolution(hud,p,state,hud.building_index,Rect2(542,487,252,44))

static func market(hud:FarmHUD,state:FarmState,tab:String) -> void:
	hud.market_tab=tab
	var p:=FarmGameUI.open(hud,"market","Armazém da Lúcia","harvest",940,744 if tab=="orders" else 680)
	FarmGameUI.action(hud,p,"Vender",Rect2(26,111,208,43),"market_sales",tab=="sales")
	FarmGameUI.action(hud,p,"Encomendas • %d"%state.active_orders(),Rect2(247,111,254,43),"market_orders",tab=="orders")
	FarmGameUI.icon(p,"coins",Rect2(698,112,36,36))
	hud.label(p,"$%s"%hud._money(state.money),Vector2(743,115),Vector2(170,34),24)
	FarmGameUI.action(hud,p,"Leite · %d L"%state.milk_stock,Rect2(519,111,164,43),"milk_market")
	if tab=="orders":
		hud._orders(state,p)
		return
	hud.sale_quantities.clear(); hud.sale_buttons.clear()
	var keys:=["carrot","wheat","corn","egg"]
	for i in range(4):
		var key:String=keys[i]
		var price:int=FarmTrade.PRICES[key]
		var c:=FarmGameUI.card(hud,p,Rect2(26+(i%2)*450,179+(i/2)*172,436,156))
		FarmGameUI.icon(c,key,Rect2(14,12,62,62))
		hud.label(c,FarmTrade.NAMES[key],Vector2(88,12),Vector2(210,30),22)
		hud.label(c,"$%d / un."%price,Vector2(88,48),Vector2(156,26),17,FarmHUD.MUTED)
		hud.label(c,"%d un."%state.inventory[key],Vector2(292,25),Vector2(131,39),25)
		var quantity:=SpinBox.new()
		quantity.position=Vector2(14,96); quantity.size=Vector2(88,43)
		quantity.min_value=1; quantity.max_value=maxi(1,int(state.inventory[key])); quantity.step=1; quantity.rounded=true
		quantity.update_on_text_changed=true; quantity.value=1; quantity.editable=state.inventory[key]>0
		quantity.get_line_edit().add_theme_stylebox_override("normal",hud.style(Color("ffffff"),5,Color("8ba494")))
		c.add_child(quantity); hud.sale_quantities[key]=quantity
		var sale:=FarmGameUI.action(hud,c,"Vender 1 • $%d"%price,Rect2(114,96,308,43),"sell_product:"+key,true)
		sale.disabled=state.inventory[key]<=0; hud.sale_buttons[key]=sale
		quantity.value_changed.connect(func(amount:float): sale.text="Vender %d • $%d"%[int(amount),int(amount)*price])
	var all:=FarmGameUI.action(hud,p,"Vender tudo • $%d"%state.sale_value(),Rect2(26,537,436,48),"sell",true)
	all.disabled=state.sale_value()==0
	all.tooltip_text="Vende apenas o estoque disponível; não inclui reserva nem ovos no ninho."
	var contract:=FarmGameUI.action(hud,p,"✓ Pedido entregue" if state.contract_done else "Entregar 6 cenouras • $110",Rect2(476,537,436,48),"contract")
	contract.disabled=state.contract_done or state.inventory.carrot<6
	contract.tooltip_text="Entregue 6 cenouras. Sem prazo. Recompensa: $110 e +1 reputação."
	FarmGameUI.icon(p,"lock",Rect2(26,615,28,28))
	hud.label(p,"%d produtos protegidos na reserva"%state.reserve_count(),Vector2(67,617),Vector2(570,27),17)
