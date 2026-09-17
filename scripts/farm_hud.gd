class_name FarmHUD
extends CanvasLayer

signal action(value: String)
const INK := Color("294739")
const CREAM := Color("fff7e4")
const MUTED := Color("7b806b")
var root := Control.new()
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
	_build()

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
	var brand := panel(root, Rect2(24, 22, 287, 98), Color("294b3c"))
	label(brand, "DO MATO", Vector2(21,10), Vector2(260,31), 29, CREAM)
	label(brand, "AO MILHÃO", Vector2(21,40), Vector2(260,34), 29, Color("edbd64"))
	label(brand, "SEU PEQUENO GRANDE COMEÇO", Vector2(22,79), Vector2(256,15), 10, Color("d2dcc8"))
	var time_panel := panel(root, Rect2(328,22,244,60))
	clock_label = label(time_panel, "DIA 01   •   08:00", Vector2(17,12), Vector2(211,34),20)
	var mode_panel := panel(root, Rect2(588,22,242,60),Color("e7eddb"))
	mode_label = label(mode_panel, "CONHEÇA O VALE", Vector2(16,14),Vector2(212,30),17)
	var wallet := panel(root, Rect2(1110,22,306,98))
	label(wallet,"SEU PATRIMÔNIO COMEÇA AQUI",Vector2(18,12),Vector2(272,20),11,MUTED)
	money_label=label(wallet,"$ 1.600",Vector2(18,32),Vector2(265,45),32)
	stock_label=label(wallet,"Estoque vazio • novas possibilidades",Vector2(18,77),Vector2(273,16),11,MUTED)
	button(root,"Armazém  [F]",Rect2(854,22,234,46),"market",true)
	button(root,"Salvar  [F5]",Rect2(854,77,114,39),"save")
	button(root,"Menu",Rect2(980,77,108,39),"menu")
	button(root,"Ajudante [H]",Rect2(588,88,242,32),"staff")
	var quest := panel(root,Rect2(24,140,287,279))
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
	select_panel=panel(root,Rect2(1110,140,306,466))
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
	barn_button=button(select_panel,"Reserva e bancada",Rect2(18,407,270,39),"barn",true)
	coop_button=button(select_panel,"Cuidar das galinhas",Rect2(18,407,270,39),"coop",true)
	tool_panel=panel(root,Rect2(24,720,1392,157))
	tool_title=label(tool_panel,"CONSTRUA SEU COMEÇO",Vector2(18,12),Vector2(305,25),13,MUTED)
	walk_tip=label(tool_panel,"A vida acontece no seu ritmo. Cuide dos canteiros e descubra o vale.",Vector2(18,49),Vector2(1340,26),15,MUTED)
	walk_tip.visible=false
	label(tool_panel,"SEMENTE",Vector2(560,13),Vector2(85,24),12,MUTED)
	var crops=["carrot","wheat","corn"]
	for i in range(crops.size()):
		var key:String=crops[i]
		crop_buttons[key]=button(tool_panel,FarmState.CROPS[key].name,Rect2(653+i*117,8,109,33),"crop:"+key)
	mode_button=button(tool_panel,"Caminhar  [TAB]",Rect2(1150,8,221,34),"mode",true)
	var tools=["inspect","plot","barn","coop","fence","sign","path","expand"]
	var names=["Cuidar","Canteiro","Celeiro","Galinheiro","Cerca","Placa","Caminho","Expandir"]
	var costs=["Selecionar / regar","$20 • sementes","$240","$180 • 3 galinhas","$12","$25 • seu texto","$5","$900 • +8 m"]
	for i in range(tools.size()):
		var b:=button(tool_panel,"%d  %s\n%s"%[i+1,names[i],costs[i]],Rect2(18+i*171,51,160,83),"tool:"+tools[i])
		b.add_theme_font_size_override("font_size",14)
		buttons[tools[i]]=b
	hint_panel=panel(root,Rect2(330,654,767,46),Color("294b3c"))
	hint_label=label(hint_panel,"WASD mover  •  Mouse direito girar  •  Scroll zoom",Vector2(14,8),Vector2(738,32),15,CREAM)
	hint_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	toast_panel=panel(root,Rect2(420,137,600,53),Color("fff0be"))
	toast_label=label(toast_panel,"",Vector2(14,8),Vector2(572,36),17)
	toast_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	toast_panel.visible=false
	_set_active_buttons()

func _process(delta: float) -> void:
	toast_time=maxf(0,toast_time-delta)
	toast_panel.visible=toast_time>0

func toast(message: String) -> void:
	toast_label.text=message
	toast_time=4.0

func update(state: FarmState, build_mode: bool, selected: int, tool: String, crop: String, hover_hint: String) -> void:
	money_label.text="$ %s" % _money(state.money)
	var total:=0
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
	barn_button.visible=selected>=0 and selected<state.items.size() and state.items[selected].kind=="barn"
	coop_button.visible=selected>=0 and selected<state.items.size() and state.items[selected].kind=="coop"
	var multipart:bool=selected>=0 and selected<state.items.size() and state.items[selected].kind in ["barn","coop"]
	paint_selector.set_item_disabled(1,not multipart)
	paint_selector.set_item_disabled(2,not multipart)
	if not multipart: paint_selector.select(0)
	move_button.text="Esc cancela a mudança" if tool=="move" else "Mover seleção  [M]"
	if selected>=0 and selected<state.items.size():
		var item:Dictionary=state.items[selected]
		select_label.text=FarmState.ITEMS[item.kind].name.to_upper()
		if item.kind=="plot":
			var status:="Pronto para replantar"
			if item.planted:
				status="Pronto para colher!" if item.growth>=1 else ("Crescendo: %d%%"%int(item.growth*100) if item.watered else "Precisa de água")
			details_label.text="%s\n%s\n\nClique com Cuidar ou use E\nperto do canteiro."%[FarmState.CROPS[item.crop].name,status]
		elif item.kind=="coop":
			details_label.text="%s\nRação: %d%% • Água: %d%%\nNinho: %d / 12 ovos\n\nUse Cuidar das galinhas."%[FarmAnimals.status(item.flock),roundi(item.flock.food),roundi(item.flock.water),int(item.flock.nest)]
		elif item.kind=="sign":
			details_label.text='“%s”\n\nPinte ou escreva sua mensagem.'%item.text
		elif item.kind=="barn":
			details_label.text="Reserva: %d / %d produtos\nGuardados fora da venda geral.\n\nBancada: %s\nUse o botão abaixo ou E perto."%[state.reserve_count(),state.reserve_capacity(),"regador melhorado" if state.watering_upgrade else "regador por $300"]
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
		hint_label.text="WASD andar  •  Mouse direito girar  •  E cuidar  •  TAB construir"

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
	if is_instance_valid(overlay): overlay.queue_free()
	overlay=null
	modal=null
	text_input=null
	modal_kind=""

func _modal(kind: String, height: float = 530) -> Panel:
	close_modal()
	modal_kind=kind
	overlay=ColorRect.new()
	overlay.color=Color(0.05,0.12,0.08,0.43)
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
	label(p,"VERSÃO 0.9.0   •   PERSONAGENS E GALINHAS",Vector2(34,561),Vector2(542,17),11,MUTED)

func coop(state: FarmState, index: int, selected_hen: int = -1) -> void:
	var flock:Dictionary=state.items[index].flock
	var p:=_modal("coop",720)
	label(p,"GALINHEIRO • CUIDADOS E COMPANHIA",Vector2(30,21),Vector2(550,27),13,MUTED)
	label(p,"Seu pequeno bando",Vector2(30,58),Vector2(550,44),30)
	var status:=FarmAnimals.status(flock)+" • 2 ovos a cada %d s"%roundi(45.0/FarmAnimals.rate(flock))
	if flock.nest>=FarmAnimals.NEST_CAPACITY: status="Ninho cheio • Colete para retomar a produção"
	label(p,status,Vector2(30,111),Vector2(550,30),17)
	var cost:=FarmAnimals.food_cost(flock)
	label(p,"Ração: %d%%"%roundi(flock.food),Vector2(30,162),Vector2(170,32),19)
	label(p,"Água: %d%%"%roundi(flock.water),Vector2(30,216),Vector2(170,32),19)
	for i in range(2):
		var back:=ColorRect.new()
		back.color=Color("e4ddc5")
		back.position=Vector2(202,173+i*54)
		back.size=Vector2(118,9)
		p.add_child(back)
		var fill:=ColorRect.new()
		fill.color=Color("d5a442") if i==0 else Color("65aab5")
		fill.size=Vector2(118*float(flock.food if i==0 else flock.water)/100,9)
		back.add_child(fill)
	var feed:=button(p,"Comedouro cheio" if cost==0 else "Repor ração • $%d"%cost,Rect2(347,153,233,43),"care:food")
	feed.disabled=cost==0 or state.money<cost
	var water:=button(p,"Bebedouro cheio" if flock.water>=100 else "Encher água • Grátis",Rect2(347,207,233,43),"care:water")
	water.disabled=flock.water>=100
	label(p,"Sem água ou ração, a produção fica mais lenta.\nSeus animais não morrem; basta voltar a cuidar.",Vector2(30,268),Vector2(550,52),16,MUTED)
	label(p,"Ninho: %d / 12 ovos"%int(flock.nest),Vector2(30,341),Vector2(270,35),22)
	var collect:=button(p,"Coletar %d ovos"%int(flock.nest),Rect2(315,331,265,48),"care:collect",true)
	collect.disabled=flock.nest==0
	label(p,"CONHEÇA SUAS GALINHAS",Vector2(30,403),Vector2(550,25),12,MUTED)
	for i in range(3):
		if selected_hen==i: panel(p,Rect2(24,435+i*56,562,52),Color("f4e5b8"))
		var swatch:=ColorRect.new()
		swatch.color=Color(FarmAnimals.COLORS[i])
		swatch.position=Vector2(32,448+i*56)
		swatch.size=Vector2(17,17)
		p.add_child(swatch)
		label(p,flock.names[i],Vector2(62,436+i*56),Vector2(340,29),18)
		label(p,FarmAnimals.TRAITS[i],Vector2(62,464+i*56),Vector2(340,20),12,MUTED)
		button(p,"Renomear",Rect2(425,440+i*56,155,43),"rename_hen:%d"%i)
	label(p,"Cuidados compartilhados pelas três galinhas deste galinheiro.",Vector2(30,613),Vector2(550,23),13,MUTED)
	button(p,"Ajudante [H]",Rect2(30,652,265,44),"staff_coop")
	button(p,"Voltar ao terreiro",Rect2(310,652,270,44),"close")

func staff_panel(state: FarmState) -> void:
	var p:=_modal("staff",744)
	var worker:Dictionary=state.staff
	label(p,"GESTÃO • PRIMEIRO AJUDANTE",Vector2(30,21),Vector2(550,26),13,MUTED)
	label(p,"Zeca do Trato",Vector2(30,57),Vector2(550,43),31)
	label(p,"“A Maricota manda. Eu só organizo o sindicato.”",Vector2(30,105),Vector2(550,29),17,MUTED)
	label(p,"Cuida de um galinheiro por vez, a cada 15 segundos:\ncoleta ovos e repõe água e ração quando chegam a 25%.\nSem serviço, não cobra. Seus outros produtos ficam com você.",Vector2(30,151),Vector2(550,76),16)
	label(p,"GALINHEIRO ESCOLHIDO",Vector2(30,244),Vector2(550,24),12,MUTED)
	staff_choice=OptionButton.new()
	staff_choice.position=Vector2(30,275)
	staff_choice.size=Vector2(550,42)
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
	label(p,FarmStaff.status(worker),Vector2(30,333),Vector2(550,32),21)
	var info:="Contratação: $120 • Cada rodada com serviço: $2 + ração.\nRação custa até $8 por reposição. Água é grátis. Saldo: $%d"%state.money
	if worker.hired:
		info="%d rodadas • %d ovos coletados • Total gasto: $%d\nCusto por rodada com serviço: $2 + ração (até $8). Saldo: $%d"%[worker.services,worker.eggs,worker.spent,state.money]
	label(p,info,Vector2(30,377),Vector2(550,58),16)
	var detail:="A contratação é paga uma vez; recontratar custa outros $120."
	if worker.hired and worker.coop>=0:
		var index:=int(worker.coop)
		var at:Dictionary=state.items[index]
		var quote:=FarmStaff.quote(at.flock)
		detail="Atende (%d, %d) • próxima checagem em %ds\nServiço necessário agora: $%d • Ao faltar saldo, pausa sozinho."%[at.x,at.z,ceili(FarmStaff.INTERVAL-worker.timer),quote]
	elif worker.hired: detail="Galinheiro removido. Atribua outro e clique em Retomar."
	label(p,detail,Vector2(30,443),Vector2(550,52),15,MUTED)
	if not worker.hired:
		staff_primary=button(p,"Contratar • conferir custos",Rect2(30,511,550,46),"staff_hire_review",true)
		staff_primary.disabled=staff_target<0 or state.money<FarmStaff.HIRE_COST
	else:
		var assign:=button(p,"Atender este galinheiro",Rect2(30,511,270,44),"staff_assign")
		assign.disabled=staff_target<0 or staff_target==worker.coop
		staff_primary=button(p,"Retomar" if worker.paused else "Pausar",Rect2(310,511,270,44),"staff_pause",true)
		staff_primary.disabled=worker.coop<0
		button(p,"Dispensar…",Rect2(30,565,550,36),"staff_dismiss_review")
	label(p,"Construção, janelas e jogo fechado pausam o trabalho e os custos.",Vector2(30,632),Vector2(550,24),13,MUTED)
	button(p,"Voltar ao campo",Rect2(30,674,550,46),"close")

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

func barn(state: FarmState) -> void:
	var p:=_modal("barn",668)
	label(p,"CELEIRO • RESERVA E BANCADA",Vector2(30,23),Vector2(550,27),13,MUTED)
	label(p,"Guarde hoje, planeje amanhã",Vector2(30,59),Vector2(550,43),28)
	label(p,"Reserva compartilhada: %d / %d produtos\nO que está guardado fica fora de Vender estoque."%[state.reserve_count(),state.reserve_capacity()],Vector2(30,113),Vector2(550,61),17)
	label(p,"PRODUTO         ESTOQUE / RESERVA",Vector2(30,190),Vector2(550,24),12,MUTED)
	var keys:=["carrot","wheat","corn","egg"]
	for i in range(keys.size()):
		var key:String=keys[i]
		var title:String="Ovos" if key=="egg" else FarmState.CROPS[key].name
		label(p,"%s:  %d / %d"%[title,state.inventory[key],state.reserve[key]],Vector2(30,224+i*43),Vector2(276,31),17)
		var deposit:=button(p,"Guardar",Rect2(310,220+i*43,124,35),"deposit:"+key)
		var withdraw:=button(p,"Retirar",Rect2(446,220+i*43,134,35),"withdraw:"+key)
		for b in [deposit,withdraw]:
			b.add_theme_font_size_override("font_size",15)
			for key_style in ["normal","hover","pressed","disabled"]:
				var compact:StyleBoxFlat=b.get_theme_stylebox(key_style).duplicate()
				compact.content_margin_top=5
				compact.content_margin_bottom=5
				b.add_theme_stylebox_override(key_style,compact)
			b.set_deferred("size",Vector2(b.size.x,35))
		deposit.disabled=state.inventory[key]==0 or state.reserve_count()>=state.reserve_capacity()
		withdraw.disabled=state.reserve[key]==0
	label(p,"REGADOR MELHORADO",Vector2(30,414),Vector2(550,26),13,MUTED)
	label(p,"Uma rega alcança até 5 canteiros em cruz.\nA melhoria fica com você, mesmo se mover o celeiro.",Vector2(30,450),Vector2(550,56),17)
	var upgrade:=button(p,"Melhoria instalada!" if state.watering_upgrade else "Melhorar regador • $300",Rect2(30,519,550,46),"upgrade",true)
	upgrade.disabled=state.watering_upgrade or state.money<300
	button(p,"Voltar ao campo",Rect2(30,589,550,46),"close")

func market(state: FarmState, tab: String = "sales") -> void:
	market_tab=tab
	var p:=_modal("market",744)
	p.position.x=260
	p.size.x=920
	label(p,"ARMAZÉM DO VALE • NEGÓCIOS DA VIZINHANÇA",Vector2(30,22),Vector2(850,27),13,MUTED)
	label(p,"Dona Lúcia compra!" if tab=="sales" else "Um bom vizinho vale ouro",Vector2(30,58),Vector2(850,43),31)
	button(p,"Vender produtos",Rect2(30,117,280,45),"market_sales",tab=="sales")
	button(p,"Encomendas • %d"%state.active_orders(),Rect2(325,117,330,45),"market_orders",tab=="orders")
	label(p,"Saldo: $%s"%_money(state.money),Vector2(688,125),Vector2(200,31),20)
	if tab=="orders":
		_orders(state,p)
	else:
		sale_quantities.clear()
		sale_buttons.clear()
		for column in [[30,"PRODUTO"],[225,"ESTOQUE"],[360,"POR UNIDADE"],[508,"QUANTIDADE"]]:
			label(p,column[1],Vector2(column[0],183),Vector2(155,24),12,MUTED)
		var keys:=["carrot","wheat","corn","egg"]
		for i in range(4):
			var key:String=keys[i]
			var price:int=FarmTrade.PRICES[key]
			label(p,FarmTrade.NAMES[key],Vector2(30,228+i*60),Vector2(190,30),20)
			label(p,"%d un."%int(state.inventory[key]),Vector2(225,228+i*60),Vector2(115,30),19)
			label(p,"$%d"%price,Vector2(360,228+i*60),Vector2(125,30),19)
			var quantity:=SpinBox.new()
			quantity.position=Vector2(508,220+i*60)
			quantity.size=Vector2(115,43)
			quantity.min_value=1
			quantity.max_value=maxi(1,int(state.inventory[key]))
			quantity.step=1
			quantity.rounded=true
			quantity.update_on_text_changed=true
			quantity.value=1
			quantity.editable=state.inventory[key]>0
			quantity.get_line_edit().add_theme_stylebox_override("read_only",style(Color("eee8d6"),8))
			quantity.get_line_edit().add_theme_color_override("font_uneditable_color",MUTED)
			p.add_child(quantity)
			sale_quantities[key]=quantity
			var sale:=button(p,"Vender 1 • $%d"%price,Rect2(650,220+i*60,240,43),"sell_product:"+key)
			sale.disabled=state.inventory[key]<=0
			sale_buttons[key]=sale
			quantity.value_changed.connect(func(amount: float): sale.text="Vender %d • $%d"%[int(amount),int(amount)*price])
		var sell:=button(p,"Vender estoque inteiro • $%d"%state.sale_value(),Rect2(30,467,860,43),"sell",true)
		sell.disabled=state.sale_value()==0
		var note:="Reserva no celeiro: %d produtos • Fora das vendas e entregas."%state.reserve_count()
		if state.active_orders()>0: note+="\nVocê tem encomendas ativas. Confira os pedidos antes de vender."
		label(p,note,Vector2(30,521),Vector2(860,44),14,MUTED)
		label(p,"PEDIDO INICIAL • SEM PRAZO • 6 CENOURAS POR $110",Vector2(30,567),Vector2(860,22),12,MUTED)
		var contract:=button(p,"Pedido da Dona Nena entregue!" if state.contract_done else "Entregar para o bolo da Dona Nena • +1 reputação",Rect2(30,596,860,43),"contract")
		contract.disabled=state.contract_done or state.inventory.carrot<6
	button(p,"Voltar ao campo",Rect2(30,669,860,45),"close")

func _orders(state: FarmState, p: Panel) -> void:
	for i in range(FarmTrade.KEYS.size()):
		var key:String=FarmTrade.KEYS[i]
		var person:Dictionary=FarmTrade.NEIGHBORS[key]
		var record:Dictionary=state.trade[key]
		var text:="%s\n%s\n%s • %d entregas"%[person.name,person.ranch,FarmTrade.rank_name(record.reputation),int(record.reputation)]
		var select:=button(p,text,Rect2(30,190+i*139,237,123),"neighbor:"+key,market_neighbor==key)
		select.add_theme_font_size_override("font_size",15)
	var record:Dictionary=state.trade[market_neighbor]
	var person:Dictionary=FarmTrade.NEIGHBORS[market_neighbor]
	var request:=FarmTrade.offer(market_neighbor,record)
	var active:bool=not record.active.is_empty()
	panel(p,Rect2(290,186,600,453),Color("f6eed9"))
	label(p,request.title,Vector2(312,202),Vector2(555,40),27)
	label(p,person.specialty,Vector2(312,249),Vector2(555,27),16,MUTED)
	label(p,'“%s”'%person.quote,Vector2(312,282),Vector2(555,29),15,MUTED)
	var row:=0
	for product in request.needs:
		var need:int=request.needs[product]
		var available:int=state.inventory[product]
		label(p,"%s: %d / %d no estoque"%[FarmTrade.NAMES[product],available,need],Vector2(312,327+row*35),Vector2(555,30),19,INK if available>=need else Color("a95734"))
		row+=1
	label(p,"Recompensa: $%d • +1 reputação"%request.reward,Vector2(312,408),Vector2(555,37),23)
	label(p,"No armazém, esses produtos valem $%d."%request.base,Vector2(312,449),Vector2(555,27),15,MUTED)
	label(p,"Restam %s de jogo ativo"%FarmTrade.time_label(float(record.active.deadline)-state.elapsed) if active else "Prazo após aceitar: %d minutos de jogo ativo"%int(request.seconds/60),Vector2(312,486),Vector2(555,28),18)
	label(p,"O relógio pausa nos menus e na construção.",Vector2(312,518),Vector2(555,27),14,MUTED)
	order_action=button(p,"Entregar • $%d"%request.reward if active else "Aceitar encomenda",Rect2(312,560,346,46),("deliver_order:" if active else "accept_order:")+market_neighbor,true)
	order_action.disabled=not FarmTrade.can_supply(request,state.inventory) if active else not state.claimed
	if active:
		button(p,"Desistir",Rect2(674,560,193,46),"cancel_order:"+market_neighbor)
		order_action.tooltip_text="A entrega usa apenas o estoque; retire reservas no celeiro."
	else:
		var next_rank:="Pedidos maiores com 2 entregas" if record.reputation<2 else ("Melhores pedidos com 5 entregas" if record.reputation<5 else "Melhor faixa de pedidos liberada")
		label(p,next_rank,Vector2(312,611),Vector2(555,22),13,MUTED)
	var footer:="Desistir ou perder o prazo não tira moedas, produtos ou reputação."
	if record.last_result=="expired": footer="O último prazo terminou. Nada foi retirado; há outro pedido disponível."
	elif record.last_result=="delivered": footer="Entrega concluída! Sua reputação cresceu e há um novo pedido disponível."
	elif record.last_result=="cancelled": footer="Pedido cancelado sem multa. Você pode aceitar outra encomenda."
	label(p,footer,Vector2(30,640),Vector2(860,23),13,MUTED)

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
