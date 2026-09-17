class_name FarmCheeseWorkerHUD
extends RefCounted
static func show(hud:FarmHUD,state:FarmState) -> void:
	var w:=state.cheese_worker
	var p:=FarmGameUI.open(hud,"chico","Chico Queijeiro","cheese",850,658)
	hud.label(p,FarmCheeseWorker.status(state),Vector2(28,113),Vector2(794,36),25)
	if not w.hired:
		FarmGameUI.icon(p,"worker",Rect2(323,169,160,150))
		hud.label(p,"Contratar · $160",Vector2(28,339),Vector2(794,42),29).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		hud.label(p,"$4 por lote iniciado · coleta grátis\nBusca leite do estoque e guarda os queijos. Você decide as vendas.",Vector2(28,407),Vector2(794,75),21).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		FarmGameUI.action(hud,p,"Contratar Chico",Rect2(28,554,794,55),"chico:review_hire",true).disabled=state.money<160
		return
	hud.label(p,"QUEIJARIA",Vector2(28,171),Vector2(396,25),15,FarmHUD.MUTED)
	var sites:=OptionButton.new();sites.position=Vector2(28,207);sites.size=Vector2(388,45);p.add_child(sites)
	sites.add_theme_font_size_override("font_size",20)
	for skin in ["normal","hover","pressed"]:sites.add_theme_stylebox_override(skin,hud.style(Color("faf0d5"),6,Color("9b875f")))
	var popup:=sites.get_popup()
	popup.add_theme_stylebox_override("panel",hud.style(Color("faf0d5"),8,FarmHUD.INK))
	popup.add_theme_color_override("font_color",FarmHUD.INK)
	hud.chico_site=-1
	for i in range(state.items.size()):
		if state.items[i].kind=="cheesery":
			sites.add_item("Queijaria %d"%(sites.item_count+1),i)
			if hud.chico_site<0:hud.chico_site=i
			if i==int(w.site):sites.select(sites.item_count-1);hud.chico_site=i
	if sites.item_count==0:sites.add_item("Construa uma queijaria (G)");sites.disabled=true
	sites.item_selected.connect(func(n:int):hud.chico_site=sites.get_item_id(n))
	hud.label(p,"QUEIJOS POR LOTE",Vector2(444,171),Vector2(378,25),15,FarmHUD.MUTED)
	var batch:=FarmCheeseHUD.quantity(hud,p,4,Vector2(444,207));batch.value=w.batch_size;hud.chico_batch=int(w.batch_size)
	batch.value_changed.connect(func(n:float):hud.chico_batch=int(n))
	hud.label(p,"2 L por queijo\n$4 por lote",Vector2(594,213),Vector2(229,52),17)
	hud.label(p,"LIMITE TOTAL DE SERVIÇOS",Vector2(28,285),Vector2(460,27),15,FarmHUD.MUTED)
	var budget:=SpinBox.new();budget.position=Vector2(28,321);budget.size=Vector2(180,48);budget.min_value=0;budget.max_value=maxi(10000,int(w.budget));budget.step=4;budget.rounded=true;budget.update_on_text_changed=true;budget.value=w.budget;p.add_child(budget)
	hud.chico_budget=int(w.budget);budget.value_changed.connect(func(n:float):hud.chico_budget=int(n))
	hud.label(p,"Usado: $%d / $%d · disponível: $%d"%[w.spent,w.budget,maxi(0,w.budget-w.spent)],Vector2(228,329),Vector2(594,33),22)
	hud.label(p,"Alterar a rotina mantém o gasto usado. Renovar libera uma nova verba.",Vector2(28,392),Vector2(794,29),18,FarmHUD.MUTED)
	hud.label(p,"%d lotes iniciados · %d queijos recolhidos · $%d em serviços"%[w.started,w.collected,w.total_spent],Vector2(28,439),Vector2(794,35),22)
	FarmGameUI.action(hud,p,"Aplicar rotina",Rect2(28,495,388,47),"chico:review_apply",true).disabled=hud.chico_site<0
	FarmGameUI.action(hud,p,"Renovar orçamento…",Rect2(434,495,388,47),"chico:review_renew").disabled=hud.chico_site<0
	FarmGameUI.action(hud,p,"Retomar" if w.paused else "Pausar",Rect2(28,572,246,45),"chico:pause")
	FarmGameUI.action(hud,p,"Dispensar…",Rect2(292,572,246,45),"chico:review_dismiss")
	FarmGameUI.action(hud,p,"Equipe",Rect2(556,572,266,45),"crew")
static func review(hud:FarmHUD,state:FarmState,kind:String) -> void:
	hud.chico_confirm=kind
	var p:=FarmGameUI.open(hud,"chico_confirm","Chico · confirmar","worker",780,470)
	var title:="Contratação · $160"
	var text:="$4 por lote iniciado, mais o leite do seu estoque.\nColeta grátis. Sem venda automática.\nDepois de contratar, escolha queijaria, lote e limite de gastos."
	if kind=="dismiss":
		title="Dispensar Chico?"
		text="Encerra o trabalho dele. Seu leite e seus queijos ficam.\nO lote já iniciado continua produzindo. Contratação sem reembolso.\nRecontratar custa $160; gastos e resultados são preservados."
	elif kind in ["apply","renew"]:
		title="%d queijos por lote · %d L"%[hud.chico_batch,hud.chico_batch*2]
		text="Taxa: $4 por lote iniciado. Limite total: $%d.\n"%hud.chico_budget
		text+=("Renovar zera o usado desta verba; mantém o histórico total." if kind=="renew" else "Mantém $%d já usados nesta verba."%state.cheese_worker.spent)
		text+="\nEspera pelo lote completo de leite. Coleta grátis. Não vende queijos."
	hud.label(p,title,Vector2(28,123),Vector2(724,44),28)
	hud.label(p,text,Vector2(28,191),Vector2(724,135),20).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	FarmGameUI.action(hud,p,"Voltar sem alterar",Rect2(28,376,310,50),"chico")
	FarmGameUI.action(hud,p,"Confirmar",Rect2(356,376,396,50),"chico:confirm",true)
