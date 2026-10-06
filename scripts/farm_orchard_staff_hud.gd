class_name FarmOrchardStaffHUD
extends RefCounted

static func show(hud:FarmHUD,state:FarmState) -> void:
	var draft:Dictionary={}
	var old_signatures:Dictionary={}
	var scroll_position:=0
	if hud.modal_kind=="orchard_staff" and is_instance_valid(hud.modal):
		for index in hud.modal.get_meta("orchard_staff_checks",{}):
			draft[index]=hud.modal.get_meta("orchard_staff_checks")[index].button_pressed
		old_signatures=hud.modal.get_meta("orchard_staff_signatures",{})
		var old_scroll:ScrollContainer=hud.modal.get_meta("orchard_staff_scroll",null)
		if is_instance_valid(old_scroll):scroll_position=old_scroll.scroll_vertical
	var p:=FarmGameUI.open(hud,"orchard_staff","Zeca · cuidar do pomar","worker",860,758)
	p.set_meta("orchard_staff_state",state)
	var unlocked:=FarmOrchardStaff.unlocked(state)
	var routine:Dictionary=state.orchard_staff
	var status:="Escolha as laranjeiras que Zeca vai cuidar."
	if routine.enabled:status="Pomar pausado" if routine.paused else "Rotina do pomar ativa"
	if routine.reason=="funds":status="Pausado: faltou dinheiro para o próximo serviço."
	if routine.reason=="removed":status="As árvores da rotina foram removidas. Escolha outras."
	if not unlocked:status="Conclua a missão Primeira colheita para liberar."
	p.set_meta("orchard_staff_status",hud.label(p,status,Vector2(26,110),Vector2(808,34),23))
	var cost:="Grátis no Sandbox · contratação e serviços sem cobrança."
	if not state.infinite_resources():
		cost="%s · $%d por serviço concluído."%["Zeca já contratado" if state.staff.hired else "Contratação única: $120",FarmCrew.fee(state.staff)]
	p.set_meta("orchard_staff_cost",hud.label(p,cost,Vector2(26,153),Vector2(808,29),18))
	hud.label(p,"Ele rega e colhe as árvores escolhidas. O galinheiro fica pausado.",Vector2(26,190),Vector2(808,29),18,FarmHUD.MUTED)
	var scroll:=ScrollContainer.new()
	scroll.position=Vector2(26,235);scroll.size=Vector2(808,253)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	p.add_child(scroll);p.set_meta("orchard_staff_scroll",scroll)
	var list:=VBoxContainer.new();list.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation",6);scroll.add_child(list)
	var checks:Dictionary={};var signatures:Dictionary={}
	for index in range(state.items.size()):
		var item:Dictionary=state.items[index]
		if item.kind!="orchard":continue
		var signature:="%s:%s:%s"%[item.x,item.z,item.turn]
		signatures[index]=signature
		var check:=CheckButton.new()
		check.text="Laranjeira %d · (%d, %d) · %s"%[index+1,item.x,item.z,FarmOrchard.status(item)]
		check.tooltip_text=check.text;check.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		check.custom_minimum_size=Vector2(740,44)
		check.button_pressed=bool(draft[index]) if draft.has(index) and old_signatures.get(index)==signature else index in routine.trees
		check.disabled=not unlocked
		list.add_child(check);checks[index]=check
		check.toggled.connect(func(_pressed:bool):_update_selection(hud,hud.modal.get_meta("orchard_staff_state",state)))
	if checks.is_empty():
		var empty:=Label.new();empty.text="Construa uma Laranjeira produtiva em Tab → Jardim."
		empty.custom_minimum_size=Vector2(740,60);empty.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		list.add_child(empty)
	p.set_meta("orchard_staff_checks",checks);p.set_meta("orchard_staff_signatures",signatures)
	scroll.set_deferred("scroll_vertical",scroll_position)
	p.set_meta("orchard_staff_selection",hud.label(p,"",Vector2(26,501),Vector2(808,28),19))
	p.set_meta("orchard_staff_totals",hud.label(p,"Histórico: %d serviços · %d laranjas · $%d gastos"%[routine.services,routine.oranges,routine.spent],Vector2(26,538),Vector2(808,28),18,FarmHUD.MUTED))
	var apply:=FarmGameUI.action(hud,p,"Atualizar rotina" if routine.enabled else ("Iniciar rotina" if state.staff.hired or state.infinite_resources() else "Contratar Zeca e iniciar · $120"),Rect2(26,581,808,46),"orchard_staff:apply",true)
	p.set_meta("orchard_staff_apply",apply)
	var pause:=FarmGameUI.action(hud,p,"Retomar pomar" if routine.paused else "Pausar pomar",Rect2(26,644,256,43),"orchard_staff:pause")
	pause.disabled=not routine.enabled
	p.set_meta("orchard_staff_pause",pause)
	var stop:=FarmGameUI.action(hud,p,"Encerrar rotina",Rect2(302,644,256,43),"orchard_staff:stop")
	stop.disabled=not routine.enabled;stop.tooltip_text="Zeca continua contratado. Escolha o galinheiro na equipe para trocar a tarefa."
	p.set_meta("orchard_staff_stop",stop)
	FarmGameUI.action(hud,p,"Equipe",Rect2(578,644,256,43),"crew")
	FarmGameUI.action(hud,p,"Missão Primeira colheita",Rect2(26,703,392,34),"orchard:open")
	FarmGameUI.action(hud,p,"Fechar e continuar jogando",Rect2(438,703,396,34),"close")
	update(hud,state)

static func update(hud:FarmHUD,state:FarmState) -> void:
	if hud.modal_kind!="orchard_staff" or not is_instance_valid(hud.modal):return
	var p:=hud.modal
	if not p.has_meta("orchard_staff_apply"):return
	p.set_meta("orchard_staff_state",state)
	var signatures:Dictionary={}
	for index in range(state.items.size()):
		var item:Dictionary=state.items[index]
		if item.kind=="orchard":signatures[index]="%s:%s:%s"%[item.x,item.z,item.turn]
	if signatures!=p.get_meta("orchard_staff_signatures",{}):
		show(hud,state);return
	var routine:Dictionary=state.orchard_staff
	var status:="Escolha as laranjeiras que Zeca vai cuidar."
	if routine.enabled:status="Pomar pausado" if routine.paused else "Rotina do pomar ativa"
	if routine.reason=="funds":status="Pausado: faltou dinheiro para o próximo serviço."
	if routine.reason=="removed":status="As árvores da rotina foram removidas. Escolha outras."
	if routine.reason=="blocked":status="Caminho bloqueado. Libere o acesso às laranjeiras."
	if not FarmOrchardStaff.unlocked(state):status="Conclua a missão Primeira colheita para liberar."
	p.get_meta("orchard_staff_status").text=status
	p.get_meta("orchard_staff_cost").text="Grátis no Sandbox · contratação e serviços sem cobrança." if state.infinite_resources() else "%s · $%d por serviço concluído."%["Zeca já contratado" if state.staff.hired else "Contratação única: $120",FarmCrew.fee(state.staff)]
	p.get_meta("orchard_staff_totals").text="Histórico: %d serviços · %d laranjas · $%d gastos"%[routine.services,routine.oranges,routine.spent]
	p.get_meta("orchard_staff_apply").text="Atualizar rotina" if routine.enabled else ("Iniciar rotina" if state.staff.hired or state.infinite_resources() else "Contratar Zeca e iniciar · $120")
	p.get_meta("orchard_staff_pause").text="Retomar pomar" if routine.paused else "Pausar pomar"
	p.get_meta("orchard_staff_pause").disabled=not routine.enabled
	p.get_meta("orchard_staff_stop").disabled=not routine.enabled
	var checks:Dictionary=p.get_meta("orchard_staff_checks",{})
	for index in checks:
		var item:Dictionary=state.items[index]
		checks[index].text="Laranjeira %d · (%d, %d) · %s"%[index+1,item.x,item.z,FarmOrchard.status(item)]
	_update_selection(hud,state)

static func _update_selection(hud:FarmHUD,state:FarmState) -> void:
	if hud.modal_kind!="orchard_staff" or not is_instance_valid(hud.modal):return
	var p:=hud.modal
	if not p.has_meta("orchard_staff_apply"):return
	var checks:Dictionary=p.get_meta("orchard_staff_checks",{})
	var selected:=0
	for check in checks.values():
		if check.button_pressed:selected+=1
	var unlocked:=FarmOrchardStaff.unlocked(state)
	for check in checks.values():check.disabled=not unlocked or (selected>=64 and not check.button_pressed)
	var summary:Label=p.get_meta("orchard_staff_selection")
	summary.text="%d selecionadas · até 64 laranjeiras por rotina"%selected
	var apply:Button=p.get_meta("orchard_staff_apply")
	apply.disabled=not unlocked or selected==0 or selected>64 or (not state.staff.hired and not state.infinite_resources() and state.money<120)
