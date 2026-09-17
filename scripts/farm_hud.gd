class_name FarmHUD
extends CanvasLayer

signal action(value: String)
const INK := Color("294739")
const CREAM := Color("fff7e4")
const MUTED := Color("7b806b")
var root := Control.new()
var world_hud:=Control.new()
var build_hud:=Control.new()
var walking:=FarmWalkHUD.new()
var coop_tab:="care"
var cultivation_draft:Dictionary={}
var cultivation_budget:SpinBox
var milk_quantity:SpinBox
var money_label: Label
var clock_label: Label
var mode_label: Label
var quest_label: Label
var quest_title: Label
var quest_counter: Label
var quest_button: Button
var quest_progress: ProgressBar
var move_button: Button
var paint_selector: OptionButton
var barn_button: Button
var coop_button: Button
var market_tab:="sales"
var market_neighbor:="nena"
var sale_quantities:Dictionary={}
var sale_buttons:Dictionary={}
var order_action:Button
var staff_target:=-1
var staff_choice:OptionButton
var staff_primary:Button
var irrigation_draft:Array=[]
var building_index:=-1
var stock_label: Label
var hint_label: Label
var toast_label: Label
var toast_panel: Panel
var toast_time := 0.0
var tool_panel: Panel
var select_panel: Panel
var select_label: Label
var details_label: Label
var mode_button: Button
var tool_title: Label
var hint_panel: Panel
var walk_tip: Label
var buttons: Dictionary = {}
var crop_buttons: Dictionary = {}
var overlay: ColorRect
var modal: Panel
var text_input: LineEdit
var modal_kind := ""
var current_tool := "inspect"
var current_crop := "carrot"

func _ready() -> void:
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var theme := Theme.new()
	theme.default_font_size = 18
	theme.set_color("font_color", "Label", INK)
	theme.set_color("font_color", "Button", INK)
	theme.set_color("font_hover_color", "Button", INK)
	theme.set_color("font_pressed_color", "Button", INK)
	theme.set_color("font_focus_color", "Button", INK)
	theme.set_color("font_disabled_color", "Button", MUTED)
	theme.set_color("font_color", "LineEdit", INK)
	theme.set_color("caret_color", "LineEdit", INK)
	theme.set_stylebox("normal", "LineEdit", style(Color("fffaf0"), 9))
	root.theme = theme
	root.add_child(world_hud)
	world_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	world_hud.mouse_filter=Control.MOUSE_FILTER_IGNORE
	world_hud.add_child(build_hud)
	build_hud.mouse_filter=Control.MOUSE_FILTER_IGNORE
	build_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	walking.setup(self)

func style(color: Color, radius: int = 14, border_color: Color = Color("e3d9b9")) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	s.set_border_width_all(1)
	s.border_color = border_color
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	s.shadow_color = Color(0.06, 0.15, 0.08, 0.12)
	s.shadow_size = 5
	return s

func panel(parent: Control, rect: Rect2, color: Color = CREAM) -> Panel:
	var p := Panel.new()
	p.position = rect.position
	p.size = rect.size
	p.add_theme_stylebox_override("panel", style(color))
	parent.add_child(p)
	return p

func label(parent: Control, text: String, pos: Vector2, size: Vector2, font_size: int = 18, color: Color = INK) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.size = size
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l

func button(parent: Control, text: String, rect: Rect2, value: String, primary: bool = false) -> Button:
	var b := Button.new()
	b.text = text
	b.position = rect.position
	b.size = rect.size
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_stylebox_override("normal", style(Color("e9b957") if primary else Color("f4edd9"), 9))
	b.add_theme_stylebox_override("hover", style(Color("f2cb77") if primary else Color("e9dfc4"), 9, Color("b19a61")))
	b.add_theme_stylebox_override("pressed", style(Color("deb061"), 9))
	b.add_theme_stylebox_override("disabled", style(Color("ede7d8"), 9))
	b.add_theme_font_size_override("font_size", 17)
	b.pressed.connect(func(): action.emit(value))
	parent.add_child(b)
	return b

func _build() -> void:
	var brand := panel(build_hud, Rect2(24, 22, 287, 98), Color("294b3c"))
	label(brand, "DO MATO", Vector2(21,10), Vector2(260,31), 29, CREAM)
	label(brand, "AO MILHÃO", Vector2(21,40), Vector2(260,34), 29, Color("edbd64"))
	label(brand, "SEU PEQUENO GRANDE COMEÇO", Vector2(22,79), Vector2(256,15), 10, Color("d2dcc8"))
	var time_panel := panel(build_hud, Rect2(328,22,244,60))
	clock_label = label(time_panel, "DIA 01   •   08:00", Vector2(17,12), Vector2(211,34),20)
	var mode_panel := panel(build_hud, Rect2(588,22,242,60),Color("e7eddb"))
	mode_label = label(mode_panel, "CONHEÇA O VALE", Vector2(16,14),Vector2(212,30),17)
	var wallet := panel(build_hud, Rect2(1110,22,306,98))
	label(wallet,"SEU PATRIMÔNIO COMEÇA AQUI",Vector2(18,12),Vector2(272,20),11,MUTED)
	money_label=label(wallet,"$ 1.600",Vector2(18,32),Vector2(265,45),32)
	stock_label=label(wallet,"Estoque vazio • novas possibilidades",Vector2(18,77),Vector2(273,16),11,MUTED)
	button(build_hud,"Armazém  [F]",Rect2(854,22,234,46),"market",true)
	button(build_hud,"Salvar  [F5]",Rect2(854,77,114,39),"save")
	button(build_hud,"Menu",Rect2(980,77,108,39),"menu")
	button(build_hud,"Ajudante [H]",Rect2(588,88,242,32),"staff")
	var quest := panel(build_hud,Rect2(24,140,287,279))
	quest_counter=label(quest,"SEU PRIMEIRO CAPÍTULO",Vector2(18,16),Vector2(250,25),12,MUTED)
	quest_title=label(quest,"Um lugar para chamar de seu",Vector2(18,47),Vector2(250,48),18)
	quest_title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	quest_label=label(quest,"",Vector2(18,103),Vector2(250,92),15)
	quest_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	quest_button=button(quest,"Escolher meu terreno",Rect2(18,205,251,39),"journey",true)
	quest_button.add_theme_font_size_override("font_size",14)
	quest_progress=ProgressBar.new()
	quest_progress.position=Vector2(18,260)
	quest_progress.size=Vector2(250,7)
	quest_progress.show_percentage=false
	quest_progress.add_theme_font_size_override("font_size",1)
	quest_progress.add_theme_constant_override("outline_size",0)
	quest_progress.max_value=FarmState.JOURNEY.size()
	for key in ["background","fill"]:
		var bar_style:=StyleBoxFlat.new()
		bar_style.bg_color=Color("e4ddc5") if key=="background" else Color("729464")
		bar_style.set_corner_radius_all(3)
		quest_progress.add_theme_stylebox_override(key,bar_style)
	quest_progress.size=Vector2(250,7)
	quest.add_child(quest_progress)
	quest_progress.set_deferred("size",Vector2(250,7))
	select_panel=panel(build_hud,Rect2(1110,140,306,466))
	select_label=label(select_panel,"CADERNO DA FAZENDA",Vector2(18,15),Vector2(270,32),16)
	details_label=label(select_panel,"Selecione algo no terreno\npara cuidar ou personalizar.",Vector2(18,54),Vector2(270,132),16)
	details_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label(select_panel,"PINTURA • ESCOLHA A PARTE",Vector2(18,188),Vector2(270,24),12,MUTED)
	paint_selector=OptionButton.new()
	paint_selector.position=Vector2(18,216)
	paint_selector.size=Vector2(270,32)
	paint_selector.add_theme_font_size_override("font_size",15)
	paint_selector.add_theme_color_override("font_color",INK)
	paint_selector.add_theme_stylebox_override("normal",style(Color("f4edd9"),8))
	for part in ["Paredes / cor principal","Telhado","Portas"]: paint_selector.add_item(part)
	select_panel.add_child(paint_selector)
	for i in range(FarmState.PALETTE.size()):
		var b:=button(select_panel,"",Rect2(18+i*39,258,34,30),"paint:%d"%i)
		b.add_theme_stylebox_override("normal",style(Color(FarmState.PALETTE[i]),8))
		b.tooltip_text="Pintar construção selecionada"
	move_button=button(select_panel,"Mover seleção  [M]",Rect2(18,304,270,39),"move")
	button(select_panel,"Editar placa",Rect2(18,354,128,39),"edit_sign")
	button(select_panel,"Remover",Rect2(158,354,130,39),"remove")
	barn_button=button(select_panel,"Estoque do celeiro",Rect2(18,407,270,39),"barn",true)
	coop_button=button(select_panel,"Cuidar das galinhas",Rect2(18,407,270,39),"coop",true)
	tool_panel=panel(build_hud,Rect2(24,720,1392,157))
	tool_title=label(tool_panel,"CONSTRUA SEU COMEÇO",Vector2(18,12),Vector2(305,25),13,MUTED)
	walk_tip=label(tool_panel,"A vida acontece no seu ritmo. Cuide dos canteiros e descubra o vale.",Vector2(18,49),Vector2(1340,26),15,MUTED)
	walk_tip.visible=false
	label(tool_panel,"SEMENTE",Vector2(560,13),Vector2(85,24),12,MUTED)
	var crops=["carrot","wheat","corn"]
	for i in range(crops.size()):
		var key:String=crops[i]
		crop_buttons[key]=button(tool_panel,FarmState.CROPS[key].name,Rect2(653+i*117,8,109,33),"crop:"+key)
	mode_button=button(tool_panel,"Caminhar  [TAB]",Rect2(1150,8,221,34),"mode",true)
	var tools=["inspect","plot","barn","coop","fence","sign","path","expand","workshop","corral"]
	var names=["Cuidar","Canteiro","Celeiro","Galinheiro","Cerca","Placa","Caminho","Expandir","Oficina rural","Curral"]
	var costs=["Selecionar / regar","$20 • sementes","$240","$180 • 3 galinhas","$12","$25 • seu texto","$5","$900 • +8 m","$180 • melhorias","$650 • 1 vaga"]
	for i in range(tools.size()):
		var b:=button(tool_panel,"%d  %s\n%s"%[(i+1)%10,names[i],costs[i]],Rect2(18+i*136,51,129,83),"tool:"+tools[i])
		b.add_theme_font_size_override("font_size",14)
		buttons[tools[i]]=b
	hint_panel=panel(build_hud,Rect2(330,654,767,46),Color("294b3c"))
	hint_label=label(hint_panel,"WASD mover  •  Mouse direito girar  •  Scroll zoom",Vector2(14,8),Vector2(738,32),15,CREAM)
	hint_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	toast_panel=panel(root,Rect2(420,137,600,53),Color("fff0be"))
	toast_label=label(toast_panel,"",Vector2(14,8),Vector2(572,36),17)
	toast_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	toast_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	toast_panel.visible=false
	toast_panel.z_index=10
	_set_active_buttons()

func _process(delta: float) -> void:
	toast_time=maxf(0,toast_time-delta)
	toast_panel.visible=toast_time>0
	var width:=620.0 if toast_label.text.length()<75 else 800.0
	toast_panel.position=Vector2((1440-width)/2,6 if not modal_kind.is_empty() else 145)
	toast_panel.size.x=width
	toast_label.size=Vector2(width-28,36)

func toast(message: String) -> void:
	toast_label.text=message
	toast_time=4.0

func update(state: FarmState, build_mode: bool, selected: int, tool: String, crop: String, hover_hint: String) -> void:
	build_hud.visible=build_mode or not state.claimed
	walking.root.visible=not build_mode and state.claimed
	money_label.text="$ %s" % _money(state.money)
	var total:=state.milk_stock
	for value in state.inventory.values():
		total+=int(value)
	stock_label.text="%d produtos no estoque   •   Venda: $%d"%[total,state.sale_value()]
	var day:=1+int(state.elapsed/240)
	var hour:=8+int(fmod(state.elapsed,240)/20)
	var minute:=int(fmod(state.elapsed,20)*3)
	clock_label.text="DIA %02d   •   %02d:%02d"%[day,hour,minute]
	mode_label.text="CONSTRUÇÃO • PAUSADO" if build_mode else "VIDA NO CAMPO"
	if not state.claimed:
		mode_label.text="ESCOLHA SEU TERRENO"
	mode_button.text="Caminhar  [TAB]" if build_mode else "Construir  [TAB]"
	tool_panel.position.y=720 if build_mode else 792
	tool_panel.size.y=157 if build_mode else 85
	hint_panel.position.y=654 if build_mode else 730
	tool_title.text="CONSTRUA SEU COMEÇO" if build_mode else "VIVA SUA FAZENDA"
	walk_tip.visible=not build_mode
	for b in buttons.values(): b.visible=build_mode
	select_panel.visible=state.claimed and build_mode
	if current_tool!=tool or current_crop!=crop:
		current_tool=tool
		current_crop=crop
		_set_active_buttons()
	var step:=state.journey_step()
	quest_progress.value=step
	quest_button.visible=step<FarmState.JOURNEY.size()
	if step<FarmState.JOURNEY.size():
		var goal:Dictionary=FarmState.JOURNEY[step]
		quest_counter.text="SEU PRIMEIRO CAPÍTULO   %02d / 08"%(step+1)
		quest_title.text=goal.title
		quest_label.text=goal.body
		quest_button.text=goal.button
		if goal.key=="plots": quest_label.text+="\nCanteiros: %d / 3"%mini(3,state.count_items("plot"))
		if goal.key=="water": quest_label.text+="\nRegados: %d / 3"%mini(3,state.count_items("plot",true))
		if goal.key=="contract":
			quest_label.text+="\nCenouras: %d / 6"%mini(6,int(state.inventory.carrot))
			if state.inventory.carrot<6 and state.reserve.carrot>0:
				quest_label.text="Você tem cenouras reservadas.\nRetire no celeiro antes de\nentregar o pedido de $110.\nEstoque: %d / 6"%int(state.inventory.carrot)
				quest_button.text="Retirar no celeiro"
	else:
		quest_counter.text="CAPÍTULO CONCLUÍDO!"
		quest_title.text="Seu primeiro império"
		quest_label.text="Você plantou, cuidou e prosperou.\nContinue criando sua fazenda!\n\nFaturamento: $%d"%state.revenue
	move_button.disabled=selected<0 or tool=="move"
	barn_button.visible=selected>=0 and selected<state.items.size() and state.items[selected].kind in ["barn","workshop"]
	barn_button.text="Estoque do celeiro" if selected<0 or selected>=state.items.size() or state.items[selected].kind!="workshop" else "Bancada de melhorias"
	coop_button.visible=selected>=0 and selected<state.items.size() and state.items[selected].kind=="coop"
	var multipart:bool=selected>=0 and selected<state.items.size() and state.items[selected].kind in ["barn","coop","workshop"]
	paint_selector.set_item_disabled(1,not multipart)
	var has_door:bool=multipart and state.items[selected].kind!="workshop"
	paint_selector.set_item_disabled(2,not has_door)
	if not has_door and paint_selector.selected==2: paint_selector.select(0)
	if not multipart: paint_selector.select(0)
	move_button.text="Esc cancela a mudança" if tool=="move" else "Mover seleção  [M]"
	if selected>=0 and selected<state.items.size():
		var item:Dictionary=state.items[selected]
		select_label.text=FarmState.ITEMS[item.kind].name.to_upper()
		if FarmProgression.UPGRADES.has(item.kind): select_label.text+=" • NÍVEL %d"%FarmProgression.level(item)
		if item.kind=="plot":
			var status:="Pronto para replantar"
			if item.planted:
				status="Pronto para colher!" if item.growth>=1 else ("Crescendo: %d%%"%int(item.growth*100) if item.watered else "Precisa de água")
			details_label.text="%s\n%s\n\nClique com Cuidar ou use E\nperto do canteiro."%[FarmState.CROPS[item.crop].name,status]
		elif item.kind=="corral":
			details_label.text="Uma vaga para vaca\n[E] Comprar, cuidar e coletar leite.\nLeite no curral: %d / 8 L"%item.dairy.milk
		elif item.kind=="coop":
			details_label.text="%s\nRação: %d%% • Água: %d%%\nNinho: %d / %d ovos\n\nUse Cuidar das galinhas."%[FarmAnimals.status(item.flock),roundi(item.flock.food),roundi(item.flock.water),int(item.flock.nest),FarmAnimals.capacity(item.flock)]
		elif item.kind=="sign":
			details_label.text='“%s”\n\nPinte ou escreva sua mensagem.'%item.text
		elif item.kind=="barn":
			details_label.text="Estoque e reserva de produtos\nReserva: %d / %d unidades\n\n[E] Conferir estoque pela porta."%[state.reserve_count(),state.reserve_capacity()]
		elif item.kind=="workshop":
			details_label.text="Bancada de ferramentas\nRegador em área: $300\n\n[E] Acessar pela entrada."
		else:
			details_label.text="Um toque seu na fazenda.\n\nRemover devolve metade\ndo custo de construção."
	else:
		select_label.text="CADERNO DA FAZENDA"
		details_label.text="WASD mover • Scroll zoom\nBotão direito gira a câmera\nR / Q giram a construção\nM move a seleção • Esc cancela\nTAB volta ao fazendeiro"
	if not state.claimed:
		hint_label.text="Mova o mouse no vale e clique para comprar seu terreno • $400"
	elif not hover_hint.is_empty():
		hint_label.text=hover_hint
	elif build_mode:
		hint_label.text="Clique para construir / cuidar  •  R / Q girar  •  TAB caminhar"
	else:
		hint_label.text="WASD andar • Espaço pular • E cuidar • TAB construir"

func _set_active_buttons() -> void:
	for key in buttons:
		buttons[key].add_theme_stylebox_override("normal",style(Color("dfba6d") if key==current_tool else Color("f4edd9"),9))
	for key in crop_buttons:
		crop_buttons[key].add_theme_stylebox_override("normal",style(Color("d8e4c5") if key==current_crop else Color("f4edd9"),8))

func _money(value: int) -> String:
	var text:=str(value)
	var result:=""
	for i in range(text.length()):
		if i>0 and (text.length()-i)%3==0: result+="."
		result+=text[i]
	return result

func close_modal() -> void:
	world_hud.visible=true
	if is_instance_valid(overlay): overlay.queue_free()
	overlay=null
	modal=null
	text_input=null
	modal_kind=""

func _modal(kind: String, height: float = 530) -> Panel:
	close_modal()
	modal_kind=kind
	world_hud.visible=false
	overlay=ColorRect.new()
	overlay.color=Color(0.025,0.07,0.045,0.68)
	root.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal=panel(overlay,Rect2(415,(900-height)/2,610,height))
	return modal

func welcome(state: FarmState, has_save: bool) -> void:
	var p:=_modal("welcome",590)
	label(p,"BEM-VINDO AO VALE DAS POSSIBILIDADES",Vector2(34,28),Vector2(540,28),13,MUTED)
	label(p,"Do Mato\nao Milhão",Vector2(32,67),Vector2(545,112),46)
	label(p,"Um terreno vazio. Um chapéu de palha.\nE uma vontade danada de prosperar.",Vector2(34,192),Vector2(540,65),21)
	label(p,"01   Escolha seu lugar no vale.\n02   Construa, plante e cuide dos seus animais.\n03   Venda a colheita e faça seu mundo crescer.",Vector2(34,284),Vector2(540,95),18)
	label(p,"COMO VAI SE CHAMAR SUA FAZENDA?",Vector2(34,399),Vector2(540,24),12,MUTED)
	text_input=LineEdit.new()
	text_input.position=Vector2(34,432)
	text_input.size=Vector2(542,44)
	text_input.max_length=32
	text_input.text=state.farm_name
	p.add_child(text_input)
	button(p,"Voltar para minha fazenda" if has_save else "Escolher meu pedaço de terra",Rect2(34,494,542,55),"start",true)
	label(p,"VERSÃO 0.14.0   •   CURRAL E LEITE",Vector2(34,561),Vector2(542,17),11,MUTED)

func coop(state:FarmState,index:int,selected_hen:int=-1) -> void:
	FarmInteractionUI.coop(self,state,index,selected_hen)

func staff_panel(state: FarmState) -> void:
	var p:=FarmGameUI.open(self,"staff","Zeca do Trato","worker",760,620)
	var worker:Dictionary=state.staff
	label(p,"GALINHEIRO",Vector2(28,142),Vector2(704,27),15,MUTED)
	staff_choice=OptionButton.new()
	staff_choice.position=Vector2(28,185)
	staff_choice.size=Vector2(704,46)
	staff_choice.add_theme_font_size_override("font_size",17)
	for key in ["normal","hover","pressed","disabled"]:
		staff_choice.add_theme_stylebox_override(key,style(Color("ede7d8") if key=="disabled" else Color("f4edd9"),9))
	p.add_child(staff_choice)
	var coops:Array[int]=[]
	for i in range(state.items.size()):
		if state.items[i].kind=="coop":
			coops.append(i)
			staff_choice.add_item("Galinheiro %d • posição (%d, %d)"%[coops.size(),state.items[i].x,state.items[i].z],i)
	if staff_target not in coops: staff_target=int(worker.coop) if worker.coop in coops else (coops[0] if not coops.is_empty() else -1)
	if coops.is_empty():
		staff_choice.add_item("Construa um galinheiro para começar",-1)
		staff_choice.disabled=true
	else: staff_choice.select(coops.find(staff_target))
	staff_choice.item_selected.connect(func(index: int): staff_target=staff_choice.get_item_id(index); staff_panel(state))

	var status:="Irrigação anterior" if state.legacy_irrigation() else FarmStaff.status(worker)
	label(p,status,Vector2(28,255),Vector2(704,34),24)
	for i in range(3):
		var c:=FarmGameUI.card(self,p,Rect2(28+i*240,308,224,104))
		FarmGameUI.icon(c,["egg","coins","chicken"][i],Rect2(13,13,42,42))
		label(c,[str(worker.eggs),"$%d"%worker.spent,str(worker.services)][i],Vector2(70,17),Vector2(137,35),27)
		label(c,["Ovos coletados","Total gasto","Tratos feitos"][i],Vector2(16,68),Vector2(200,26),16)
	label(p,"$%d por trato + ração • a cada %d s"%[FarmCrew.fee(worker),FarmStaff.interval(worker)],Vector2(28,431),Vector2(704,29),20)
	var details:=label(p,"Coleta ovos e repõe água e ração. Sem serviço, sem cobrança.",Vector2(28,465),Vector2(704,25),16,MUTED)
	details.mouse_filter=Control.MOUSE_FILTER_PASS
	details.tooltip_text="Repõe suprimentos ao chegarem a 25%. Ração: até $8. Pause quando quiser."
	if not worker.hired:
		staff_primary=FarmGameUI.action(self,p,"Contratar • $120",Rect2(28,516,344,45),"staff_hire_review",true)
		staff_primary.disabled=staff_target<0 or state.money<FarmStaff.HIRE_COST
	else:
		var assign:=FarmGameUI.action(self,p,"Atribuir galinheiro",Rect2(28,516,224,43),"staff_assign")
		assign.disabled=staff_target<0 or (staff_target==worker.coop and not state.legacy_irrigation())
		assign.tooltip_text="Atribuir encerra a irrigação anterior do Zeca."
		staff_primary=FarmGameUI.action(self,p,"Retomar" if worker.paused else "Pausar",Rect2(268,516,224,43),"staff_pause",true)
		staff_primary.disabled=worker.coop<0
		FarmGameUI.action(self,p,"Dispensar…",Rect2(508,516,224,43),"staff_dismiss_review")
	FarmGameUI.action(self,p,"Equipe e treinamento →",Rect2(392,572,340,32),"crew")

func staff_confirmation(dismiss: bool) -> void:
	var p:=_modal("staff_confirm",370)
	label(p,"Dispensar o Zeca?" if dismiss else "Uma mãozinha no galinheiro",Vector2(30,28),Vector2(550,43),27)
	var body:="Pagar $120 pela contratação.\nDepois: $2 por rodada com serviço, mais a ração usada.\nZeca confere o galinheiro escolhido a cada 15 segundos.\nSem serviço, sem cobrança. Pause quando quiser."
	if dismiss: body="Dispensar é grátis e encerra as cobranças.\nSeus ovos, animais e construções permanecem.\nA contratação anterior não é reembolsada.\nRecontratar custa $120."
	label(p,body,Vector2(30,94),Vector2(550,135),17)
	button(p,"Confirmar dispensa" if dismiss else "Contratar por $120",Rect2(30,248,550,46),"staff_dismiss" if dismiss else "staff_hire",true)
	button(p,"Voltar sem alterar",Rect2(30,308,550,38),"staff")

func hen_editor(initial: String) -> void:
	var p:=_modal("hen_name",285)
	label(p,"Um nome com personalidade",Vector2(28,26),Vector2(554,43),27)
	label(p,"De 1 a 24 caracteres. O cargo de gerente é vitalício!",Vector2(28,81),Vector2(554,32),16,MUTED)
	text_input=LineEdit.new()
	text_input.position=Vector2(28,127)
	text_input.size=Vector2(554,45)
	text_input.max_length=24
	text_input.text=initial
	p.add_child(text_input)
	text_input.grab_focus()
	button(p,"Cancelar",Rect2(28,210,165,45),"coop")
	button(p,"Salvar nome",Rect2(209,210,373,45),"apply_hen_name",true)

func confirm_route(state: FarmState, plan: Array) -> void:
	var p:=_modal("route",370)
	label(p,"Conferir o traçado",Vector2(30,28),Vector2(550,44),29)
	label(p,"%d peças  •  Total: $%d  •  Saldo: $%d"%[plan.size(),state.batch_cost(plan),state.money],Vector2(30,90),Vector2(550,36),20)
	var error:=state.batch_error(plan)
	var description:=label(p,"Tudo livre! Confirme para construir.\nNenhuma moeda foi gasta na prévia." if error.is_empty() else error+"\nCancele e tente outro traçado.",Vector2(30,150),Vector2(550,95),18)
	description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	button(p,"Cancelar",Rect2(30,283,170,49),"route_cancel")
	var confirm:=button(p,"Construir por $%d"%state.batch_cost(plan),Rect2(218,283,362,49),"route_confirm",true)
	confirm.disabled=not error.is_empty()

func building_choice(state:FarmState,index:int,kind:String) -> int:
	if index>=0 and index<state.items.size() and state.items[index].kind==kind: return index
	for i in range(state.items.size()):
		if state.items[i].kind==kind: return i
	return -1

func evolution_button(parent:Control,state:FarmState,index:int,rect:Rect2) -> void:
	if index<0: return
	var level:=FarmProgression.level(state.items[index])
	var b:=button(parent,"Nível 2 • Concluído" if level==2 else "Evoluir • Ver melhoria",rect,"evolution:%d"%index,true)
	b.disabled=level==2

func evolution(state:FarmState,index:int) -> void:
	building_index=index
	var item:Dictionary=state.items[index]
	var offer:Dictionary=FarmProgression.UPGRADES[item.kind]
	var p:=_modal("evolution",510)
	label(p,"EVOLUÇÃO DA FAZENDA • NÍVEL 1 → 2",Vector2(30,24),Vector2(550,27),13,MUTED)
	label(p,offer.title,Vector2(30,65),Vector2(550,43),29)
	label(p,offer.benefit,Vector2(30,128),Vector2(550,116),16)
	label(p,"Construção em (%d, %d) • Saldo: $%d\nMantém o lugar, a pintura e o conteúdo da construção.\nA remoção devolve metade do valor investido na estrutura."%[item.x,item.z,state.money],Vector2(30,263),Vector2(550,91),16)
	var buy:=button(p,"Confirmar evolução • $%d"%offer.cost,Rect2(30,375,550,46),"evolution_buy:%d"%index,true)
	buy.disabled=state.money<int(offer.cost) or FarmProgression.level(item)==2
	button(p,"Voltar sem comprar",Rect2(30,440,550,43),"building_back")

func barn(state:FarmState,index:int=-1) -> void:
	FarmInteractionUI.barn(self,state,index)

func workshop(state:FarmState,index:int=-1) -> void:
	FarmInteractionUI.workshop(self,state,index)

func irrigation_panel(state:FarmState) -> void:
	var cost:=FarmCrew.fee(state.irrigation_worker())
	var p:=_modal("irrigation",740)
	label(p,("BENTO" if state.field_staff.hired else "ZECA")+" • ROTINA DE IRRIGAÇÃO",Vector2(30,25),Vector2(550,29),13,MUTED)
	label(p,"Escolha os canteiros",Vector2(30,65),Vector2(550,43),29)
	label(p,"$%d por canteiro regado, cobrado só ao concluir.\nAtende os selecionados quando estiverem plantados e secos.\n%s"%[cost,"Bento rega enquanto Zeca pode cuidar das galinhas." if state.field_staff.hired else "Zeca fica na irrigação até você mudar a tarefa."],Vector2(30,120),Vector2(550,87),16)
	var scroll:=ScrollContainer.new()
	scroll.position=Vector2(30,224)
	scroll.size=Vector2(550,305)
	p.add_child(scroll)
	var rows:=VBoxContainer.new()
	rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	scroll.add_child(rows)
	var count_label:=label(p,"%d selecionados • nenhum custo para ativar"%irrigation_draft.size(),Vector2(30,548),Vector2(550,29),16)
	for i in range(state.items.size()):
		var item:Dictionary=state.items[i]
		if item.kind!="plot": continue
		var check:=CheckBox.new()
		check.text="%s (%d, %d) • %s"%[FarmState.CROPS[item.crop].name,item.x,item.z,"regado" if item.watered else "seco"]
		check.custom_minimum_size.y=44
		check.button_pressed=i in irrigation_draft
		check.add_theme_color_override("font_color",INK)
		check.add_theme_color_override("font_hover_color",INK)
		rows.add_child(check)
		check.toggled.connect(func(on:bool):
			if on and i not in irrigation_draft: irrigation_draft.append(i)
			elif not on: irrigation_draft.erase(i)
			count_label.text="%d selecionados • nenhum custo para ativar"%irrigation_draft.size())
	if rows.get_child_count()==0: label(p,"Construa canteiros para escolher nesta lista.",Vector2(40,243),Vector2(520,40),17)
	button(p,"Ativar rotina • $%d por canteiro"%cost,Rect2(30,594,550,46),"irrigation_apply",true)
	button(p,"Voltar sem alterar",Rect2(30,662,550,44),"staff")

func market(state:FarmState,tab:String="sales") -> void:
	FarmInteractionUI.market(self,state,tab)

func _orders(state: FarmState, p: Panel) -> void:
	for i in range(FarmTrade.KEYS.size()):
		var key:String=FarmTrade.KEYS[i]
		var person:Dictionary=FarmTrade.NEIGHBORS[key]
		var record:Dictionary=state.trade[key]
		var select:=FarmGameUI.action(self,p,"%s\n%d entregas"%[person.name,int(record.reputation)],Rect2(26,182+i*143,231,122),"neighbor:"+key,market_neighbor==key)
		select.tooltip_text=person.ranch+" • "+FarmTrade.rank_name(record.reputation)
	var record:Dictionary=state.trade[market_neighbor]
	var person:Dictionary=FarmTrade.NEIGHBORS[market_neighbor]
	var request:=FarmTrade.offer(market_neighbor,record)
	var active:bool=not record.active.is_empty()
	var c:=FarmGameUI.card(self,p,Rect2(277,182,635,430))
	label(c,request.title,Vector2(22,20),Vector2(590,40),27).tooltip_text=person.quote
	label(c,"PRODUTOS • DISPONÍVEL / PEDIDO",Vector2(22,78),Vector2(590,26),14,MUTED)
	var row:=0
	for product in request.needs:
		var need:int=request.needs[product]
		var available:int=state.inventory[product]
		FarmGameUI.icon(c,product,Rect2(22,119+row*63,46,46))
		label(c,FarmTrade.NAMES[product],Vector2(85,124+row*63),Vector2(300,32),22)
		label(c,"%d / %d"%[available,need],Vector2(417,124+row*63),Vector2(187,32),25,INK if available>=need else Color("a95734"))
		row+=1
	FarmGameUI.icon(c,"coins",Rect2(22,264,38,38))
	label(c,"$%d  + 1 reputação"%request.reward,Vector2(77,268),Vector2(520,36),25).tooltip_text="Venda comum: $%d"%request.base
	label(c,"Restam %s"%FarmTrade.time_label(float(record.active.deadline)-state.elapsed) if active else "Prazo: %d min após aceitar"%int(request.seconds/60),Vector2(22,319),Vector2(590,28),19).tooltip_text="Tempo de jogo ativo. Pausa nos menus e na construção."
	order_action=FarmGameUI.action(self,c,"Entregar • $%d"%request.reward if active else "Aceitar encomenda",Rect2(22,366,379,45),("deliver_order:" if active else "accept_order:")+market_neighbor,true)
	order_action.disabled=not FarmTrade.can_supply(request,state.inventory) if active else not state.claimed
	order_action.tooltip_text="Usa o estoque disponível. Retire reservas no celeiro para entregar."
	if active:
		FarmGameUI.action(self,c,"Desistir",Rect2(417,366,194,45),"cancel_order:"+market_neighbor).tooltip_text="Cancela sem multa e sem perder produtos ou reputação."
	var footer:="Sem multa se desistir ou perder o prazo."
	if record.last_result=="expired": footer="Prazo encerrado. Um novo pedido está disponível."
	elif record.last_result=="delivered": footer="Entrega concluída! Novo pedido disponível."
	elif record.last_result=="cancelled": footer="Pedido cancelado sem multa."
	label(p,footer,Vector2(28,644),Vector2(884,29),17,MUTED)

func editor_dialog(kind: String, initial: String) -> void:
	var p:=_modal(kind,286)
	label(p,"Uma placa com personalidade",Vector2(28,26),Vector2(550,42),27)
	label(p,"Até 40 caracteres. Capriche na criatividade!",Vector2(28,79),Vector2(550,32),16,MUTED)
	text_input=LineEdit.new()
	text_input.position=Vector2(28,126)
	text_input.size=Vector2(554,45)
	text_input.max_length=40
	text_input.text=initial
	p.add_child(text_input)
	text_input.grab_focus()
	button(p,"Cancelar",Rect2(28,209,160,45),"close")
	button(p,"Pronto!",Rect2(204,209,378,45),"apply_text",true)

func menu(state: FarmState) -> void:
	var p:=_modal("menu",470)
	label(p,state.farm_name,Vector2(30,28),Vector2(550,46),28)
	label(p,"Uma pausa à sombra da árvore.",Vector2(30,85),Vector2(550,34),18,MUTED)
	button(p,"Continuar jogando",Rect2(30,144,550,47),"close",true)
	button(p,"Salvar fazenda",Rect2(30,205,550,43),"save")
	button(p,"Começar outra fazenda…",Rect2(30,264,550,43),"reset_ask")
	button(p,"Salvar e sair",Rect2(30,323,550,43),"quit")
	label(p,"TAB câmeras   •   F armazém   •   F5 salvar\nFeito com Godot e Blender. Modelos originais.",Vector2(30,395),Vector2(550,55),15,MUTED)

func confirm_reset() -> void:
	var p:=_modal("reset",280)
	label(p,"Um novo começo?",Vector2(28,25),Vector2(554,43),28)
	label(p,"Isso substitui a fazenda salva neste computador.\nSua propriedade atual será apagada.",Vector2(28,91),Vector2(554,64),18)
	button(p,"Manter minha fazenda",Rect2(28,201,269,47),"close",true)
	button(p,"Começar do zero",Rect2(313,201,269,47),"reset_confirm")
