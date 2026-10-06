class_name FarmYoungHUD
extends RefCounted

static func show(hud:FarmHUD,state:FarmState,index:int) -> void:
	if index<0 or index>=state.items.size() or state.items[index].kind not in FarmYoung.DURATIONS:return
	hud.building_index=index
	var item:Dictionary=state.items[index]
	var icon:String={"coop":"chicken","corral":"cow","pigsty":"pig"}[item.kind]
	var p:=FarmGameUI.open(hud,"young","Do filhote ao adulto",icon,820,650)
	var description:String={"coop":"Amplie para seis vagas com 3 pintinhos · $300 + 6 ovos", "corral":"Crie a Mimosa desde bezerra · $280", "pigsty":"Acolha um leitão na próxima vaga · $140"}[item.kind]
	hud.label(p,description,Vector2(28,118),Vector2(764,32),22)
	var minutes:=int(FarmYoung.DURATIONS[item.kind])/60
	hud.label(p,"Cresce em %d min de jogo ativo, com água e ração.\nSem suprimentos, o crescimento pausa. Continua ao reabastecer.\nOvos e leite só depois de adulto. Porquinhos são companhia."%minutes,Vector2(28,161),Vector2(764,83),18)
	var rows:Array=[]
	for slot in range(FarmAnimalCare.count(item)):
		var card:=FarmGameUI.card(hud,p,Rect2(28+(slot%2)*390,262+(slot/2)*78,374,68))
		var name_text:String=item.flock.names[slot] if item.kind=="coop" else str(item.dairy.name) if item.kind=="corral" else FarmPigs.NAMES[slot]
		hud.label(card,name_text,Vector2(12,5),Vector2(177,25),18)
		var status:=hud.label(card,FarmYoung.label(item,slot),Vector2(190,5),Vector2(172,25),16)
		FarmGameUI.meter(hud,card,Rect2(12,44,350,10),FarmYoung.progress(item,slot),Color("83ae72"))
		rows.append({"status":status,"meter":card.get_child(-1),"slot":slot})
	p.set_meta("young_rows",rows)
	p.set_meta("young_status",hud.label(p,"",Vector2(28,507),Vector2(764,30),17))
	FarmGameUI.action(hud,p,"Voltar ao cercado",Rect2(28,564,254,50),"animal:back")
	var caption:String={"coop":"Confirmar · $300 + 6 ovos","corral":"Confirmar bezerra · $280","pigsty":"Confirmar leitão · $140"}[item.kind]
	p.set_meta("young_button",FarmGameUI.action(hud,p,caption,Rect2(300,564,492,50),"young:adopt",true))
	update(hud,state)

static func update(hud:FarmHUD,state:FarmState) -> void:
	if hud.modal_kind!="young" or not is_instance_valid(hud.modal):return
	var i:=hud.building_index
	if i<0 or i>=state.items.size():return
	var item:Dictionary=state.items[i]
	var p:=hud.modal
	if not p.has_meta("young_rows"):return
	for row in p.get_meta("young_rows"):
		row.status.text=FarmYoung.label(item,row.slot)
		row.meter.size.x=344*FarmYoung.progress(item,row.slot)
	var reason:=FarmYoung.reason(state,i)
	p.get_meta("young_button").disabled=not reason.is_empty()
	p.get_meta("young_button").tooltip_text=reason
	p.get_meta("young_status").text=("Crescimento pausado · reponha água e ração." if FarmYoung.growing(item) and not FarmYoung.supplied(item) else reason) if not reason.is_empty() or FarmYoung.growing(item) else "Aproxime-se a pé para confirmar. Saldo: "+hud.money_text(state)
