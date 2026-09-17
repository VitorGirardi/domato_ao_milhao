class_name FarmDairyWorkerHUD
extends RefCounted
static func show(hud:FarmHUD,state:FarmState) -> void:
	var w:=state.dairy_worker
	var p:=FarmGameUI.open(hud,"raul","Raul do Curral","cow",850,658)
	hud.label(p,FarmDairyWorker.status(state),Vector2(28,113),Vector2(794,36),25)
	if not w.hired:
		FarmGameUI.icon(p,"worker",Rect2(323,169,160,150))
		hud.label(p,"Contratar · $140",Vector2(28,339),Vector2(794,42),29).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		hud.label(p,"$2 por tarefa + ração · tudo dentro do seu limite\nCuida da vaca e guarda leite para a queijaria. Sem vendas automáticas.",Vector2(28,407),Vector2(794,75),21).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		FarmGameUI.action(hud,p,"Contratar Raul",Rect2(28,554,794,55),"raul:review_hire",true).disabled=state.money<140
		return
	hud.label(p,"CURRAL",Vector2(28,171),Vector2(396,25),15,FarmHUD.MUTED)
	var sites:=OptionButton.new();sites.position=Vector2(28,207);sites.size=Vector2(388,45);p.add_child(sites)
	sites.add_theme_font_size_override("font_size",20)
	for skin in ["normal","hover","pressed"]:sites.add_theme_stylebox_override(skin,hud.style(Color("faf0d5"),6,Color("9b875f")))
	var popup:=sites.get_popup();popup.add_theme_stylebox_override("panel",hud.style(Color("faf0d5"),8,FarmHUD.INK));popup.add_theme_color_override("font_color",FarmHUD.INK)
	hud.raul_site=-1
	for i in range(state.items.size()):
		if state.items[i].kind=="corral":
			sites.add_item("Curral %d"%(sites.item_count+1),i)
			if hud.raul_site<0:hud.raul_site=i
			if i==int(w.site):sites.select(sites.item_count-1);hud.raul_site=i
	if sites.item_count==0:sites.add_item("Construa um curral (0)");sites.disabled=true
	sites.item_selected.connect(func(n:int):hud.raul_site=sites.get_item_id(n))
	FarmGameUI.icon(p,"milk",Rect2(460,172,62,62))
	FarmGameUI.icon(p,"wheat",Rect2(580,172,62,62))
	FarmGameUI.icon(p,"water",Rect2(700,172,62,62))
	hud.label(p,"Ordenha · ração · água",Vector2(444,240),Vector2(378,27),18)
	hud.label(p,"LIMITE · SERVIÇOS + RAÇÃO",Vector2(28,285),Vector2(460,27),15,FarmHUD.MUTED)
	var budget:=SpinBox.new();budget.position=Vector2(28,321);budget.size=Vector2(180,48);budget.min_value=0;budget.max_value=maxi(10000,int(w.budget));budget.step=1;budget.rounded=true;budget.update_on_text_changed=true;budget.value=w.budget;p.add_child(budget)
	hud.raul_budget=int(w.budget);budget.value_changed.connect(func(n:float):hud.raul_budget=int(n))
	hud.label(p,"Usado: $%d / $%d · disponível: $%d"%[w.spent,w.budget,maxi(0,w.budget-w.spent)],Vector2(228,329),Vector2(594,33),22)
	hud.label(p,"Alterar a rotina mantém o gasto usado. Renovar libera uma nova verba.",Vector2(28,392),Vector2(794,29),18,FarmHUD.MUTED)
	hud.label(p,"%d tarefas · %d L recolhidos · $%d gastos no total"%[w.services,w.collected,w.total_spent],Vector2(28,439),Vector2(794,35),22)
	FarmGameUI.action(hud,p,"Aplicar rotina",Rect2(28,495,388,47),"raul:review_apply",true).disabled=hud.raul_site<0
	FarmGameUI.action(hud,p,"Renovar orçamento…",Rect2(434,495,388,47),"raul:review_renew").disabled=hud.raul_site<0
	FarmGameUI.action(hud,p,"Retomar" if w.paused else "Pausar",Rect2(28,572,246,45),"raul:pause")
	FarmGameUI.action(hud,p,"Dispensar…",Rect2(292,572,246,45),"raul:review_dismiss")
	FarmGameUI.action(hud,p,"Equipe",Rect2(556,572,266,45),"crew")
static func review(hud:FarmHUD,state:FarmState,kind:String) -> void:
	hud.raul_confirm=kind
	var p:=FarmGameUI.open(hud,"raul_confirm","Raul · confirmar","worker",780,470)
	var title:="Contratação · $140"
	var text:="$2 por tarefa concluída + ração (até $12).\nO limite inclui ambos. Água sem custo de material.\nOrdenha a partir de 4 L; repõe água e ração aos 35%."
	if kind=="dismiss":
		title="Dispensar Raul?"
		text="Encerra a rotina; sua vaca e o leite ficam com você.\nContratação sem reembolso. Recontratar custa $140.\nO orçamento usado e o histórico são preservados."
	elif kind in ["apply","renew"]:
		title="Cuidado automático · limite $%d"%hud.raul_budget
		text="Ordenha a partir de 4 L. Água e ração aos 35%.\n"
		text+=("Renovar zera o usado desta verba; mantém o histórico." if kind=="renew" else "Mantém $%d já usados nesta verba."%state.dairy_worker.spent)
		text+="\n$2 por tarefa + ração, dentro do limite. Leite vai para o estoque."
	hud.label(p,title,Vector2(28,123),Vector2(724,44),28)
	hud.label(p,text,Vector2(28,191),Vector2(724,135),20).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	FarmGameUI.action(hud,p,"Voltar sem alterar",Rect2(28,376,310,50),"raul")
	FarmGameUI.action(hud,p,"Confirmar",Rect2(356,376,396,50),"raul:confirm",true)
