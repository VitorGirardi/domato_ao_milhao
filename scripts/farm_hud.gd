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
	var quest := panel(root,Rect2(24,140,287,192))
	label(quest,"UM SONHO, UM TERRENO",Vector2(18,16),Vector2(250,25),14,MUTED)
	quest_label=label(quest,"Escolha onde tudo começa.\n\nSeu primeiro terreno custa $400.\nO restante vira semente de futuro.",Vector2(18,50),Vector2(250,125),16)
	quest_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	select_panel=panel(root,Rect2(1110,140,306,338))
	select_label=label(select_panel,"CADERNO DA FAZENDA",Vector2(18,15),Vector2(270,32),16)
	details_label=label(select_panel,"Selecione algo no terreno\npara cuidar ou personalizar.",Vector2(18,54),Vector2(270,132),16)
	details_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label(select_panel,"PINTURA",Vector2(18,196),Vector2(260,24),12,MUTED)
	for i in range(FarmState.PALETTE.size()):
		var b:=button(select_panel,"",Rect2(18+i*53,226,44,34),"paint:%d"%i)
		b.add_theme_stylebox_override("normal",style(Color(FarmState.PALETTE[i]),8))
		b.tooltip_text="Pintar construção selecionada"
	button(select_panel,"Editar placa",Rect2(18,281,128,39),"edit_sign")
	button(select_panel,"Remover",Rect2(158,281,130,39),"remove")
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
	if state.claimed:
		var plots:=0
		for item in state.items:
			if item.kind=="plot": plots+=1
		if plots==0:
			quest_label.text="01 / RAÍZES NO CHÃO\n\nConstrua seu primeiro canteiro.\nEscolha a semente na barra abaixo."
		elif state.harvests==0:
			quest_label.text="02 / TEMPO DE CUIDAR\n\nRegue um canteiro com Cuidar.\nUse TAB para o tempo passar.\nDepois, colha sua primeira safra."
		elif state.revenue==0:
			quest_label.text="03 / PRIMEIRO NEGÓCIO\n\nAbra o armazém do Seu Tonico\ne venda sua primeira colheita."
		elif state.land_size==24:
			quest_label.text="04 / PENSANDO GRANDE\n\nJunte $900 para expandir.\nFaturamento: $%d\nSua próxima conquista está perto!"%state.revenue
		else:
			quest_label.text="SEU PRIMEIRO IMPÉRIO!\n\nTerreno expandido. Continue\ncriando a fazenda do seu jeito.\nFaturamento: $%d"%state.revenue
	if selected>=0 and selected<state.items.size():
		var item:Dictionary=state.items[selected]
		select_label.text=FarmState.ITEMS[item.kind].name.to_upper()
		if item.kind=="plot":
			var status:="Pronto para replantar"
			if item.planted:
				status="Pronto para colher!" if item.growth>=1 else ("Crescendo: %d%%"%int(item.growth*100) if item.watered else "Precisa de água")
			details_label.text="%s\n%s\n\nClique com Cuidar ou use E\nperto do canteiro."%[FarmState.CROPS[item.crop].name,status]
		elif item.kind=="coop":
			details_label.text="3 galinhas, muita personalidade.\n2 ovos a cada 45 segundos.\n\nÁgua e ração incluídas nesta\nprimeira versão."
		elif item.kind=="sign":
			details_label.text='“%s”\n\nPinte ou escreva sua mensagem.'%item.text
		elif item.kind=="barn":
			details_label.text="O coração da propriedade.\n\nNesta versão, é decorativo.\nEscolha uma cor abaixo."
		else:
			details_label.text="Um toque seu na fazenda.\n\nRemover devolve metade\ndo custo de construção."
	else:
		select_label.text="CADERNO DA FAZENDA"
		details_label.text="WASD  mover câmera\nMouse direito  girar\nScroll  aproximar / afastar\nR / Q  girar construção\nEsc  cancelar ferramenta\n\nTAB  voltar ao fazendeiro"
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
	label(p,"PROTÓTIPO 0.1   •   UM JOGO FEITO PARA CRESCER",Vector2(34,561),Vector2(542,17),11,MUTED)

func market(state: FarmState) -> void:
	var p:=_modal("market",590)
	label(p,"ARMAZÉM DO VALE",Vector2(30,25),Vector2(530,27),13,MUTED)
	label(p,"Seu Tonico compra!",Vector2(30,62),Vector2(550,44),32)
	label(p,'“Dinheiro não nasce em árvore.\nMas às vezes nasce num canteiro.”',Vector2(30,115),Vector2(550,60),18)
	var keys:=["carrot","wheat","corn","egg"]
	for i in range(4):
		var key:String=keys[i]
		var title:String="Ovos" if key=="egg" else FarmState.CROPS[key].name
		var price:int=10 if key=="egg" else FarmState.CROPS[key].price
		label(p,"%s"%title,Vector2(30,204+i*35),Vector2(220,29),19)
		label(p,"%d un.    ×    $%d"%[state.inventory[key],price],Vector2(295,204+i*35),Vector2(265,29),18)
	var sell:=button(p,"Vender estoque  •  $%d"%state.sale_value(),Rect2(30,360,550,47),"sell",true)
	sell.disabled=state.sale_value()==0
	label(p,"PEDIDO ESPECIAL  •  6 CENOURAS POR $110",Vector2(30,427),Vector2(550,24),13,MUTED)
	var contract:=button(p,"Pedido entregue!" if state.contract_done else "Entregar para o bolo da Dona Nena",Rect2(30,458,550,43),"contract")
	contract.disabled=state.contract_done or state.inventory.carrot<6
	button(p,"Voltar ao campo",Rect2(30,526,550,42),"close")

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
