class_name FarmBuildHUD
extends RefCounted
## A small categorized palette; actions belong to the selected object.
const CATEGORIES := {
	"Lavoura": ["plot"],
	"Animais": ["coop", "corral", "stable", "pigsty"],
	"Estruturas": ["barn", "workshop", "cheesery"],
	"Decoração": ["fence", "path", "sign"],
	"Terrenos": ["expand", "parcels"]
}
const ICONS := {"plot":"seed", "coop":"chicken", "corral":"cow", "stable":"barn", "pigsty":"barn", "barn":"barn", "workshop":"workshop", "cheesery":"cheese", "fence":"build_fence", "path":"build_path", "sign":"book", "expand":"build_expand", "parcels":"build_expand"}
var hud: FarmHUD
var root: Control
var catalog: Panel
var cards := {}
var tabs := {}
var category := "Estruturas"
var last_tool := ""
var last_selection := -1
var clock: Label
var wallet: Label
var level: Button
var selection: Panel
var selected_name: Label
var selected_icon: TextureRect
var select_button: Button
var open_button: Button
var paint_button: Button
var sign_button: Button
var paint_panel: Panel
var paint_open := false
var seed_panel: Control
var help_panel: Panel
var hint: Label
var claim_panel: Panel
var current_state: FarmState

func setup(owner: FarmHUD) -> void:
	hud = owner
	root = Control.new(); root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.build_hud.add_child(root); root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var header := hud.panel(root, Rect2(24,22,402,56), Color("294b3c"))
	FarmGameUI.icon(header,"barn",Rect2(12,9,36,36))
	hud.label(header,"CONSTRUIR",Vector2(60,11),Vector2(200,36),24,FarmHUD.CREAM)
	level = FarmGameUI.action(hud,header,"",Rect2(270,10,120,36),"farm_levels")
	level.add_theme_font_size_override("font_size",15)
	var time_panel := FarmGameUI.card(hud,root,Rect2(448,22,244,56))
	clock=hud.label(time_panel,"",Vector2(14,12),Vector2(220,32),18)
	var cash := FarmGameUI.card(hud,root,Rect2(918,22,184,56))
	FarmGameUI.icon(cash,"coins",Rect2(12,12,32,32));wallet=hud.label(cash,"",Vector2(55,11),Vector2(115,34),23)
	var help := FarmGameUI.action(hud,root,"?",Rect2(1120,22,50,56),"")
	_disconnect_action(help); help.pressed.connect(func():help_panel.visible=not help_panel.visible)
	FarmGameUI.action(hud,root,"Voltar  [TAB]",Rect2(1184,22,232,56),"mode",true)
	select_button=FarmGameUI.action(hud,root,"Selecionar",Rect2(24,94,170,44),"tool:inspect")
	select_button.tooltip_text="Clique em uma construção para mover, pintar ou remover. Atalho: 1"
	help_panel=FarmGameUI.card(hud,root,Rect2(1040,94,376,155));help_panel.visible=false
	hud.label(help_panel,"WASD mover câmera · Scroll zoom\nBotão direito girar câmera\nR / Q girar peça · Esc cancelar\nTAB voltar ao fazendeiro",Vector2(16,14),Vector2(344,124),17)
	catalog=hud.panel(root,Rect2(218,678,1004,198),Color("294b3c"))
	var tab_i := 0
	for title in CATEGORIES:
		var tab := FarmGameUI.action(hud,catalog,title,Rect2(14+tab_i*194,12,184,38),"")
		_disconnect_action(tab);tab.pressed.connect(_choose_category.bind(title));tabs[title]=tab;tab_i+=1
	seed_panel=Control.new();seed_panel.position=Vector2(270,106);seed_panel.size=Vector2(476,42);seed_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE;catalog.add_child(seed_panel)
	for i in range(3):
		var key:String=["carrot","wheat","corn"][i]
		var b:=FarmGameUI.action(hud,seed_panel,FarmState.CROPS[key].name,Rect2(i*158,0,150,40),"crop:"+key)
		b.icon=load("res://assets/ui/%s.svg"%key);b.expand_icon=true;b.add_theme_constant_override("icon_max_width",25)
		b.add_theme_font_size_override("font_size",15)
		b.set_meta("crop",key)
	var hint_panel:=hud.panel(root,Rect2(280,625,880,38),Color("294b3c"))
	hint=hud.label(hint_panel,"",Vector2(12,4),Vector2(856,30),15,FarmHUD.CREAM)
	hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;hint.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	selection=FarmGameUI.card(hud,root,Rect2(1100,156,316,235))
	selected_icon=FarmGameUI.icon(selection,"barn",Rect2(14,12,64,64))
	selected_name=hud.label(selection,"",Vector2(88,14),Vector2(211,57),21)
	selected_name.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	FarmGameUI.action(hud,selection,"Mover [M]",Rect2(14,90,140,42),"move")
	paint_button=FarmGameUI.action(hud,selection,"Pintar",Rect2(162,90,140,42),"")
	_disconnect_action(paint_button);paint_button.pressed.connect(func():paint_open=not paint_open;paint_panel.visible=paint_open)
	open_button=FarmGameUI.action(hud,selection,"Abrir",Rect2(14,143,140,42),"build:open",true)
	FarmGameUI.action(hud,selection,"Remover",Rect2(162,143,140,42),"remove").tooltip_text="Devolve metade do custo da construção."
	sign_button=FarmGameUI.action(hud,selection,"Editar texto",Rect2(14,143,140,42),"edit_sign")
	hud.label(selection,"Clique no terreno para selecionar outra peça.",Vector2(14,197),Vector2(288,24),12,FarmHUD.MUTED)
	paint_panel=FarmGameUI.card(hud,root,Rect2(1100,404,316,135));paint_panel.visible=false
	hud.label(paint_panel,"Escolha a cor",Vector2(14,8),Vector2(286,24),16)
	hud.paint_selector.reparent(paint_panel)
	hud.paint_selector.position=Vector2(14,38);hud.paint_selector.size=Vector2(288,32)
	for i in range(FarmState.PALETTE.size()):
		var swatch:=hud.button(paint_panel,"",Rect2(14+i*42,84,36,34),"paint:%d"%i)
		swatch.add_theme_stylebox_override("normal",hud.style(Color(FarmState.PALETTE[i]),6))
	claim_panel=FarmGameUI.card(hud,root,Rect2(390,698,660,126))
	hud.label(claim_panel,"Escolha seu pedaço de terra",Vector2(22,12),Vector2(616,42),27)
	hud.label(claim_panel,"Clique numa área livre do vale · Terreno inicial: $400",Vector2(22,66),Vector2(616,32),18)
	_rebuild_cards()

func _disconnect_action(button: Button) -> void:
	for connection in button.pressed.get_connections():button.pressed.disconnect(connection.callable)

func _choose_category(title: String) -> void:
	category=title;paint_open=false;paint_panel.visible=false
	hud.action.emit("build:clear")
	_rebuild_cards()
	if current_state!=null:_refresh_cards(current_state)

func _texture(key:String) -> Texture2D:
	var path:="res://assets/ui/build/%s.png"%key
	return load(path) if ResourceLoader.exists(path) else load("res://assets/ui/%s.svg"%ICONS.get(key,"barn"))

func _rebuild_cards() -> void:
	for card in cards.values():card.free()
	cards.clear()
	var i:=0
	for key in CATEGORIES[category]:
		if key not in ["expand","parcels"] and not FarmState.ITEMS.has(key):continue
		var b:=FarmGameUI.action(hud,catalog,"",Rect2(14+i*230,62,218,120),"parcels" if key=="parcels" else "tool:"+key)
		var picture:=TextureRect.new();picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;picture.texture=_texture(key);picture.position=Vector2(8,12)
		picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;picture.mouse_filter=Control.MOUSE_FILTER_IGNORE;picture.size=Vector2(90,90);b.add_child(picture)
		var title:="Expandir fazenda" if key=="expand" else ("Comprar terreno" if key=="parcels" else str(FarmState.ITEMS[key].name))
		var name_label:=hud.label(b,title,Vector2(105,14),Vector2(104,52),17,FarmHUD.CREAM)
		name_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		var cost:=hud.label(b,"",Vector2(105,73),Vector2(104,32),19,Color("f6d581"))
		b.set_meta("price",cost);b.set_meta("name_label",name_label);b.set_meta("picture",picture)
		cards[key]=b;i+=1

func _refresh_cards(state:FarmState) -> void:
	for title in tabs:
		tabs[title].add_theme_stylebox_override("normal",hud.style(Color("997a3e") if title==category else Color("365640"),6,Color("eabc5b") if title==category else Color("547058")))
	for key in cards:
		var b:Button=cards[key]
		var locked:=not FarmLevels.unlocked(state,key)
		var text:="Ver lotes" if key=="parcels" else ("$900" if key=="expand" else "$%d"%int(FarmState.ITEMS[key].cost))
		if locked:text="Nível %d"%FarmLevels.required(key)
		if key=="expand" and state.land_size>=40:text="Máximo"
		b.get_meta("price").text=text
		b.disabled=key=="expand" and state.land_size>=40
		b.get_meta("picture").modulate=Color("77776c") if locked else Color.WHITE
		var active:bool=key==hud.current_tool
		b.add_theme_stylebox_override("normal",hud.style(Color("7c6536") if active else Color("41634c"),8,Color("f0c466") if active else Color("6d8664")))
		b.tooltip_text="Requer nível %d"%FarmLevels.required(key) if locked else ("Aumentar a fazenda em 8 metros" if key=="expand" else "")

func update(state:FarmState,selected:int,tool:String,crop:String,hover_hint:String) -> void:
	current_state=state
	clock.text=hud.clock_label.text;wallet.text=hud.money_text(state);level.text="Nível %d"%FarmLevels.level(state.farm_xp)
	if tool!=last_tool:
		last_tool=tool
		for title in CATEGORIES:
			if tool in CATEGORIES[title] and category!=title:category=title;_rebuild_cards()
	if selected!=last_selection or tool!="inspect":paint_open=false
	last_selection=selected
	catalog.visible=state.claimed;claim_panel.visible=not state.claimed;select_button.visible=state.claimed
	selection.visible=state.claimed and selected>=0 and selected<state.items.size() and tool=="inspect"
	paint_panel.visible=selection.visible and paint_open
	seed_panel.visible=category=="Lavoura" and tool=="plot"
	for child in seed_panel.get_children():
		child.modulate=Color.WHITE if child.get_meta("crop")==crop else Color("b7c5ac")
	if selection.visible:
		var key:String=state.items[selected].kind
		selected_name.text=FarmState.ITEMS[key].name
		selected_icon.texture=_texture(key)
		paint_button.visible=key in ["barn","coop","workshop","fence","sign","stable"]
		if not paint_button.visible:paint_panel.visible=false
		open_button.visible=key in ["plot","barn","coop","workshop","corral","cheesery","stable","pigsty"]
		open_button.text="Cuidar" if key in ["plot","coop","corral","pigsty"] else "Abrir"
		sign_button.visible=key=="sign"
	_refresh_cards(state)
	if not state.claimed:hint.text="WASD mover câmera · Scroll aproximar"
	elif tool=="inspect":hint.text="Selecione uma construção no mapa para editar."
	else:hint.text=hover_hint if not hover_hint.is_empty() else "Clique para colocar · R / Q girar · Esc cancelar"
	help_panel.visible=help_panel.visible and hud.build_hud.visible
