class_name FarmCultivationHUD
extends RefCounted

static func prepare(hud:FarmHUD,state:FarmState) -> void:
	hud.cultivation_draft=state.cultivation.duplicate(true)
	if hud.cultivation_draft.plans.is_empty():
		for index in state.irrigation.plots:
			hud.cultivation_draft.plans.append({"index":int(index),"crop":state.items[int(index)].crop})

static func show(hud:FarmHUD,state:FarmState) -> void:
	var draft:Dictionary=hud.cultivation_draft
	var p:=FarmGameUI.open(hud,"cultivation","Rotina do Bento","seed",900,770)
	FarmGameUI.action(hud,p,"Tarefas e canteiros",Rect2(26,112,413,42),"cultivation_edit",true)
	FarmGameUI.action(hud,p,"Resultados",Rect2(454,112,418,42),"cultivation_report")
	for i in range(3):
		var task:String=["water","harvest","plant"][i]
		var c:=FarmGameUI.card(hud,p,Rect2(26+i*286,175,273,60))
		FarmGameUI.icon(c,task if task!="plant" else "seed",Rect2(10,7,45,45))
		var toggle:=CheckBox.new()
		toggle.text=["Regar","Colher","Replantar"][i]
		toggle.position=Vector2(69,9); toggle.size=Vector2(193,42)
		toggle.button_pressed=bool(draft.tasks[task]); toggle.set_meta("task",task)
		c.add_child(toggle)
		toggle.toggled.connect(func(on:bool): draft.tasks[task]=on)
	hud.label(p,"Orçamento",Vector2(28,264),Vector2(215,32),22)
	hud.label(p,"Já usado: $%d"%state.cultivation.spent,Vector2(270,268),Vector2(288,30),18,FarmHUD.MUTED)
	var budget:=SpinBox.new()
	budget.position=Vector2(632,255); budget.size=Vector2(238,47)
	budget.min_value=0; budget.max_value=1000000; budget.step=1; budget.prefix="$"
	budget.update_on_text_changed=true; budget.value=draft.limit
	budget.get_line_edit().add_theme_stylebox_override("normal",hud.style(Color("ffffff"),5,Color("75978a")))
	budget.tooltip_text="Limite total para serviços e sementes. Salvar ou reabrir a rotina não zera o gasto."
	p.add_child(budget); hud.cultivation_budget=budget
	budget.value_changed.connect(func(amount:float): draft.limit=int(amount))
	hud.label(p,"CANTEIROS",Vector2(28,326),Vector2(426,24),14,FarmHUD.MUTED)
	hud.label(p,"PRÓXIMO PLANTIO",Vector2(606,326),Vector2(267,24),14,FarmHUD.MUTED)
	var scroll:=ScrollContainer.new()
	scroll.position=Vector2(26,357); scroll.size=Vector2(846,215); p.add_child(scroll)
	var rows:=VBoxContainer.new(); rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL; scroll.add_child(rows)
	for index in range(state.items.size()):
		var item:Dictionary=state.items[index]
		if item.kind!="plot": continue
		var current:Dictionary={"index":index,"crop":item.crop}
		var selected:=false
		for plan in draft.plans:
			if int(plan.index)==index: current=plan; selected=true; break
		var row:=HBoxContainer.new(); row.custom_minimum_size.y=52; rows.add_child(row)
		var check:=CheckBox.new(); check.text="(%d, %d)"%[item.x,item.z]; check.button_pressed=selected
		check.custom_minimum_size=Vector2(178,48); check.set_meta("plot",index); row.add_child(check)
		var condition:="Vazio" if not item.planted else ("Pronto para colher" if item.growth>=1 else ("Precisa de água" if not item.watered else "Crescendo"))
		var status:=Label.new(); status.text=condition; status.custom_minimum_size.x=357; row.add_child(status)
		var crops:=OptionButton.new(); crops.custom_minimum_size=Vector2(260,44); crops.disabled=not selected
		for key in FarmState.CROPS:
			crops.add_icon_item(load("res://assets/ui/%s.svg"%key),FarmState.CROPS[key].name)
		crops.add_theme_constant_override("icon_max_width",26)
		for mode in ["normal","hover","pressed","disabled"]:
			var face:=hud.style(Color("e0d5b6") if mode=="disabled" else Color("fff8e5"),5,Color("8c9e7d"))
			face.shadow_size=0
			crops.add_theme_stylebox_override(mode,face)
		crops.select(["carrot","wheat","corn"].find(current.crop)); row.add_child(crops)
		crops.item_selected.connect(func(choice:int): current.crop=["carrot","wheat","corn"][choice])
		check.toggled.connect(func(on:bool):
			crops.disabled=not on
			if on and current not in draft.plans: draft.plans.append(current)
			elif not on: draft.plans.erase(current))
	if rows.get_child_count()==0: hud.label(p,"Construa canteiros para começar.",Vector2(35,390),Vector2(795,36),22)
	hud.label(p,"$%d por tarefa concluída • replantio também paga sementes"%FarmCrew.fee(state.field_staff),Vector2(28,590),Vector2(843,29),18)
	hud.label(p,"A cultura escolhida entra no próximo plantio; a plantação atual é preservada.",Vector2(28,622),Vector2(843,26),15,FarmHUD.MUTED)
	FarmGameUI.action(hud,p,"Revisar e ativar",Rect2(454,673,418,52),"cultivation_review",true)
	FarmGameUI.action(hud,p,"Voltar à equipe",Rect2(26,673,413,52),"crew")

static func review(hud:FarmHUD,state:FarmState,renew:bool=false) -> void:
	var data:Dictionary=state.cultivation if renew else hud.cultivation_draft
	var p:=FarmGameUI.open(hud,"cultivation_confirm","Renovar orçamento" if renew else "Confirmar rotina","coins",750,495)
	var tasks:Array=[]
	for key in ["water","harvest","plant"]:
		if data.tasks[key]: tasks.append({"water":"Regar","harvest":"Colher","plant":"Replantar"}[key])
	hud.label(p,"%d canteiros • %s"%[data.plans.size()," + ".join(tasks)],Vector2(28,119),Vector2(695,34),22)
	var remaining:int=int(data.limit) if renew else maxi(0,int(data.limit)-int(state.cultivation.spent))
	hud.label(p,"Até $%d disponíveis"%remaining,Vector2(28,177),Vector2(695,42),30)
	hud.label(p,"$%d por tarefa + sementes no replantio"%FarmCrew.fee(state.field_staff),Vector2(28,235),Vector2(695,32),21)
	hud.label(p,"Sementes: cenoura $4 • trigo $6 • milho $8 / canteiro",Vector2(28,278),Vector2(695,28),18)
	hud.label(p,"Não retira moedas agora. Cobra ao concluir; pausa ao atingir o limite.",Vector2(28,325),Vector2(695,28),16,FarmHUD.MUTED)
	FarmGameUI.action(hud,p,"Renovar e retomar" if renew else "Ativar rotina",Rect2(384,402,337,51),"cultivation_renew" if renew else "cultivation_apply",true)
	FarmGameUI.action(hud,p,"Voltar",Rect2(28,402,336,51),"cultivation_report" if renew else "cultivation_edit")

static func report(hud:FarmHUD,state:FarmState) -> void:
	var data:Dictionary=state.cultivation
	var p:=FarmGameUI.open(hud,"cultivation_report","Resultados do Bento","harvest",900,670)
	FarmGameUI.action(hud,p,"Tarefas e canteiros",Rect2(26,112,413,42),"cultivation_edit")
	FarmGameUI.action(hud,p,"Resultados",Rect2(454,112,418,42),"cultivation_report",true)
	for i in range(3):
		var key:String=["carrot","wheat","corn"][i]
		var c:=FarmGameUI.card(hud,p,Rect2(26+i*286,179,273,146))
		FarmGameUI.icon(c,key,Rect2(15,21,62,62))
		hud.label(c,"%d colhidos"%data.produced[key],Vector2(89,25),Vector2(171,35),24)
		hud.label(c,"Plantios: %d"%data.sown[key],Vector2(90,65),Vector2(170,28),17,FarmHUD.MUTED)
		hud.label(c,FarmState.CROPS[key].name,Vector2(16,111),Vector2(242,27),18)
	hud.label(p,"Serviços: $%d"%data.services,Vector2(28,356),Vector2(274,36),23)
	hud.label(p,"Sementes: $%d"%data.seeds,Vector2(322,356),Vector2(274,36),23)
	hud.label(p,"Total: $%d"%(data.services+data.seeds),Vector2(644,356),Vector2(224,36),23)
	hud.label(p,"Regas: %d • Colheitas: %d • Plantios: %d"%[data.actions.water,data.actions.harvest,data.actions.plant],Vector2(28,408),Vector2(843,29),19)
	var status:="Rotina não ativada" if not data.enabled else ("Em pausa" if state.field_staff.paused else "Trabalhando")
	if data.enabled and state.field_staff.reason=="budget": status="Orçamento insuficiente para a próxima tarefa"
	elif data.enabled and state.field_staff.reason=="funds": status="Saldo da fazenda insuficiente"
	hud.label(p,status,Vector2(28,464),Vector2(842,29),20)
	hud.label(p,"Restam $%d / $%d"%[maxi(0,int(data.limit-data.spent)),data.limit],Vector2(28,507),Vector2(422,31),24)
	FarmGameUI.meter(hud,p,Rect2(462,514,410,18),float(maxi(0,int(data.limit-data.spent)))/maxi(1,int(data.limit)),Color("6c9960"))
	var renew:=FarmGameUI.action(hud,p,"Renovar orçamento…",Rect2(454,578,418,49),"cultivation_renew_review",true)
	renew.disabled=not data.enabled or data.limit<=0
	FarmGameUI.action(hud,p,"Equipe / pausar",Rect2(26,578,413,49),"crew")
