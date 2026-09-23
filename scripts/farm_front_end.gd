class_name FarmFrontEnd
extends RefCounted
var game:Node3D
var has_save:=false
var return_to:="title"
var pending_name:=""
var resume_session:=false
var controls:Dictionary={}
var pending:Dictionary={}
var pending_character:="farmer"
var character_cards:Dictionary={}

func setup(owner_game:Node3D,loaded:bool) -> void:
	game=owner_game;has_save=loaded
	pending_character=FarmCharacters.load_choice()
	FarmCharacters.apply_to_game(game,pending_character)

func show_title() -> void:
	var hud:FarmHUD=game.hud
	game.session_started=false
	var p:=hud._modal("title",900)
	p.position=Vector2.ZERO;p.size=Vector2(1440,900);p.add_theme_stylebox_override("panel",StyleBoxEmpty.new())
	var backdrop:=TextureRect.new();backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;backdrop.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if ResourceLoader.exists("res://assets/ui/title_valley.png"):backdrop.texture=load("res://assets/ui/title_valley.png")
	hud.modal_shade.add_child(backdrop);backdrop.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var shade:=TextureRect.new();var texture:=GradientTexture2D.new();var gradient:=Gradient.new()
	gradient.offsets=PackedFloat32Array([0,.42,1]);gradient.colors=PackedColorArray([Color(.025,.06,.045,.98),Color(.025,.06,.045,.82),Color(.025,.06,.045,.05)])
	texture.gradient=gradient;texture.fill_from=Vector2.ZERO;texture.fill_to=Vector2(1,0);shade.texture=texture
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shade.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;shade.mouse_filter=Control.MOUSE_FILTER_IGNORE;hud.modal_shade.add_child(shade)
	hud.label(p,"DO MATO",Vector2(86,105),Vector2(650,82),68,Color("fff6df"))
	hud.label(p,"AO MILHÃO",Vector2(86,181),Vector2(650,89),76,Color("edbc61"))
	hud.label(p,"Comece com um terreno.\nTermine comprando a vizinhança.",Vector2(92,292),Vector2(530,72),23,Color("dbdec9"))
	var first:=FarmGameUI.action(hud,p,"Continuar" if has_save else "Novo jogo",Rect2(92,410,390,60),"front:continue" if has_save else "front:new",true)
	first.add_theme_font_size_override("font_size",26);first.focus_mode=Control.FOCUS_ALL
	if has_save:
		var caption:=hud.label(p,"%s · Nível %d"%[game.state.farm_name,FarmLevels.level(game.state.farm_xp)],Vector2(96,373),Vector2(510,26),16,Color("dbdec9"))
		caption.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	var entries:Array=[["Novo jogo","front:new"],["Configurações","front:settings"],["Controles","front:controls"],["Sair","front:quit"]] if has_save else [["Configurações","front:settings"],["Controles","front:controls"],["Sair","front:quit"]]
	entries.push_front(["Jogar junto", "net:menu"])
	for i in range(entries.size()):
		var button:=FarmGameUI.action(hud,p,entries[i][0],Rect2(92,484+i*63,390,52),entries[i][1])
		button.add_theme_font_size_override("font_size",22);button.focus_mode=Control.FOCUS_ALL
	hud.label(p,"VERSÃO %s   •   F11 TELA CHEIA / JANELA"%ProjectSettings.get_setting("application/config/version"),Vector2(92,839),Vector2(700,25),14,Color("d3d7bd"))
	hud.label(p,"UM NOVO DIA NO VALE",Vector2(980,827),Vector2(380,35),18,Color("fff6df"))
	hud.toast_time=0;hud.toast_panel.visible=false

func back() -> void:
	if return_to=="pause":game.hud.menu(game.state)
	else:show_title()

func new_game() -> void:
	return_to="title"
	var hud:FarmHUD=game.hud
	var p:=FarmGameUI.open(hud,"new_farm","Seu novo começo","seed",940,800)
	hud.label(p,"Nome da fazenda",Vector2(32,112),Vector2(876,30),20)
	hud.text_input=LineEdit.new();hud.text_input.position=Vector2(32,148);hud.text_input.size=Vector2(876,48)
	hud.text_input.max_length=32;hud.text_input.placeholder_text="Meu pedacinho de mundo";hud.text_input.text=pending_name;p.add_child(hud.text_input)
	hud.label(p,"Quem vai cuidar desse pedacinho de mundo?",Vector2(32,212),Vector2(876,35),23)
	character_cards.clear()
	for i in range(2):
		var id:String=FarmCharacters.IDS[i]
		var card:=Button.new();card.position=Vector2(32+i*446,257);card.size=Vector2(430,416)
		card.toggle_mode=true;card.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND;card.focus_mode=Control.FOCUS_ALL
		var normal:=StyleBoxFlat.new();normal.bg_color=Color("e5e1cb");normal.set_corner_radius_all(18);normal.set_border_width_all(2);normal.border_color=Color("c1c5a5")
		var selected:StyleBoxFlat=normal.duplicate();selected.bg_color=Color("f4ead0");selected.border_color=Color("b67c25");selected.set_border_width_all(4)
		var hover:StyleBoxFlat=normal.duplicate();hover.border_color=Color("6b9479");hover.set_border_width_all(3)
		card.add_theme_stylebox_override("normal",normal);card.add_theme_stylebox_override("hover",hover)
		card.add_theme_stylebox_override("pressed",selected);card.add_theme_stylebox_override("hover_pressed",selected)
		card.add_theme_stylebox_override("focus",hover);p.add_child(card)
		var portrait:=FarmCharacterPreview.new();portrait.character_id=id;portrait.position=Vector2(32,12);portrait.size=Vector2(366,320);card.add_child(portrait)
		var name_label:=hud.label(card,"Fazendeiro" if i==0 else "Fazendeira",Vector2(20,335),Vector2(390,34),25,Color("294d3d"));name_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		var choice:=hud.label(card,"",Vector2(20,373),Vector2(390,24),16,Color("48694c"));choice.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		name_label.mouse_filter=Control.MOUSE_FILTER_IGNORE;choice.mouse_filter=Control.MOUSE_FILTER_IGNORE
		character_cards[id]={"button":card,"label":choice}
		card.pressed.connect(func():select_character(id))
	select_character(pending_character)
	hud.label(p,"Mesmo talento, mesmas aventuras. Escolha quem combina com você.",Vector2(32,681),Vector2(876,28),17)
	FarmGameUI.action(hud,p,"Voltar",Rect2(32,735,250,46),"front:back")
	FarmGameUI.action(hud,p,"Criar minha fazenda",Rect2(300,735,608,46),"front:new_review",true)

func select_character(id:String) -> void:
	if not FarmCharacters.valid(id):return
	pending_character=id
	for key in character_cards:
		character_cards[key].button.set_pressed_no_signal(key==id)
		character_cards[key].label.text="SELECIONADO" if key==id else "Escolher personagem"

func review_new() -> void:
	if game.hud.modal_kind!="new_farm":return
	pending_name=game.hud.text_input.text.strip_edges()
	if pending_name.is_empty():pending_name="Meu pedacinho de mundo"
	if not has_save:commit_new();return
	var hud:FarmHUD=game.hud
	var p:=FarmGameUI.open(hud,"new_confirm","Começar outra fazenda?","seed",770,430)
	var text:=hud.label(p,"A partida atual será substituída por “%s”.\n\nVamos guardar uma cópia da fazenda atual antes de começar."%pending_name,Vector2(32,124),Vector2(706,160),21)
	text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	FarmGameUI.action(hud,p,"Manter minha fazenda",Rect2(32,342,340,49),"front:cancel_new",true)
	FarmGameUI.action(hud,p,"Confirmar novo jogo",Rect2(394,342,344,49),"front:new_commit")

func commit_new() -> void:
	if has_save:
		var archive:String=game.save_path.get_base_dir().path_join("farms_archive")
		if DirAccess.make_dir_recursive_absolute(archive)!=OK:
			game.hud.toast("Não foi possível guardar a fazenda atual. Nada foi substituído.");return
		var copy:String=archive.path_join("farm_%d_%d.json"%[int(Time.get_unix_time_from_system()),Time.get_ticks_usec()])
		var file:=FileAccess.open(copy,FileAccess.WRITE)
		if file==null:game.hud.toast("Não foi possível guardar a fazenda atual. Nada foi substituído.");return
		file.store_string(JSON.stringify(game.state.serialize(),"",true,true));file.flush()
		var error:=file.get_error();file.close()
		if error!=OK:game.hud.toast("Não foi possível guardar a fazenda atual. Nada foi substituído.");return
	# Write the new state atomically before replacing the running scene.
	var previous_character:=FarmCharacters.load_choice()
	if FarmCharacters.save_choice(pending_character)!=OK:
		game.hud.toast("Não foi possível salvar o personagem. A fazenda foi preservada.");return
	var previous:FarmState=game.state
	game.state=FarmState.new();game.state.unlimited_money=not game.qa_mode;game.state.farm_name=pending_name
	if not game._save_game(false,true):
		game.state=previous;FarmCharacters.save_choice(previous_character);return
	game.state=previous;game._reset_farm();game.state.farm_name=pending_name
	FarmCharacters.apply_to_game(game,pending_character)
	has_save=true;resume_session=false;game._action("start");game._update_ui()

func _slider(parent:Control,key:String,title:String,y:float) -> void:
	var hud:FarmHUD=game.hud
	hud.label(parent,title,Vector2(32,y),Vector2(380,32),21)
	var slider:=HSlider.new();slider.position=Vector2(422,y+5);slider.size=Vector2(300,30)
	slider.min_value=.25 if key=="sensitivity" else 0;slider.max_value=2.5 if key=="sensitivity" else 1
	slider.step=.05;slider.value=pending[key];parent.add_child(slider)
	var value:=hud.label(parent,"%d%%"%roundi(slider.value*100),Vector2(744,y+2),Vector2(75,30),18)
	slider.value_changed.connect(func(n:float):pending[key]=n;value.text="%d%%"%roundi(n*100))
	controls[key]=slider

func settings_tab(audio_tab:bool) -> void:
	controls.audio_page.visible=audio_tab;controls.video_page.visible=not audio_tab
	controls.audio_tab.button_pressed=audio_tab;controls.video_tab.button_pressed=not audio_tab

func show_settings() -> void:
	var hud:FarmHUD=game.hud
	var p:=FarmGameUI.open(hud,"settings","Configurações","workshop",850,710)
	pending=game.preferences.data.duplicate();controls.clear()
	controls.audio_tab=FarmGameUI.action(hud,p,"Som",Rect2(32,111,380,47),"front:audio_tab")
	controls.video_tab=FarmGameUI.action(hud,p,"Jogo e vídeo",Rect2(432,111,386,47),"front:video_tab")
	for button in [controls.audio_tab,controls.video_tab]:
		button.toggle_mode=true
		button.add_theme_stylebox_override("pressed",hud.style(Color("a38443"),6,Color("36533f")))
	for key in ["audio_page","video_page"]:
		var page:=Control.new();page.size=Vector2(850,575);page.mouse_filter=Control.MOUSE_FILTER_IGNORE;p.add_child(page);controls[key]=page
	for i in range(4):
		_slider(controls.audio_page,["volume","music","ambience","effects"][i],["Volume geral","Música","Ambiente e animais","Efeitos e passos"][i],202+i*75)
	hud.label(controls.audio_page,"A música continua suave nos menus. Zero silencia a categoria.",Vector2(32,524),Vector2(786,32),17)
	_slider(controls.video_page,"sensitivity","Sensibilidade da câmera",202)
	var fullscreen:=CheckButton.new();fullscreen.text="Tela cheia";fullscreen.position=Vector2(32,290);fullscreen.size=Vector2(340,40);fullscreen.button_pressed=pending.fullscreen;controls.video_page.add_child(fullscreen)
	fullscreen.toggled.connect(func(value:bool):pending.fullscreen=value);controls.fullscreen=fullscreen
	hud.label(controls.video_page,"F11 alterna a qualquer momento",Vector2(422,297),Vector2(385,32),17)
	for i in range(2):
		hud.label(controls.video_page,["Qualidade gráfica","Limite de FPS"][i],Vector2(32,368+i*76),Vector2(350,34),21)
		var options:=OptionButton.new();options.position=Vector2(422,362+i*76);options.size=Vector2(380,45);controls.video_page.add_child(options)
		for state in ["normal","hover","pressed"]:
			options.add_theme_stylebox_override(state,hud.style(Color("faf0d5"),6,Color("9c875f")))
		options.add_theme_color_override("font_color",FarmHUD.INK)
		var values:Array=["Leve · sem sombras","Padrão","Caprichado"] if i==0 else ["30","60","120","Sem limite"]
		for text in values:options.add_item(text)
		if i==0:
			options.select(int(pending.quality));options.item_selected.connect(func(index:int):pending.quality=index);controls.quality=options
		else:
			options.select([30,60,120,0].find(int(pending.fps)));options.item_selected.connect(func(index:int):pending.fps=[30,60,120,0][index]);controls.fps=options
	hud.label(p,"As alterações entram em vigor ao aplicar.",Vector2(32,577),Vector2(780,28),17)
	FarmGameUI.action(hud,p,"Cancelar",Rect2(32,636,225,47),"front:back")
	FarmGameUI.action(hud,p,"Padrões",Rect2(273,636,225,47),"front:defaults")
	FarmGameUI.action(hud,p,"Aplicar e voltar",Rect2(514,636,304,47),"front:apply",true)
	settings_tab(true)

func show_controls() -> void:
	var hud:FarmHUD=game.hud
	var p:=FarmGameUI.open(hud,"controls","Controles do vale","book",920,630)
	var rows:=["WASD   Andar / cavalgar","Mouse direito   Girar câmera","Espaço   Pular","Shift   Correr / tapinha no cavalo","E   Interagir / montar / desmontar","M   Mapa (a pé ou montado)","TAB   Construir / caminhar","R / Q   Girar construção","M   Mover construção selecionada","F5   Salvar fazenda","F11   Tela cheia / janela","Esc   Voltar / pausar"]
	for i in range(rows.size()):hud.label(p,rows[i],Vector2(32+(i/6)*440,127+(i%6)*54),Vector2(425,40),18)
	hud.label(p,"F · Armazém    H · Equipe    B · Emotes    T · Terrenos",Vector2(32,469),Vector2(856,30),18)
	hud.label(p,"P · Sacar/guardar P-8    Clique · Atirar    R · Recarregar",Vector2(32,507),Vector2(856,30),17)
	FarmGameUI.action(hud,p,"Voltar",Rect2(300,566,320,43),"front:back",true)

func escape() -> bool:
	match game.hud.modal_kind:
		"title":return true
		"network":show_title();return true
		"settings","controls","new_farm":back();return true
		"new_confirm":new_game();return true
	return false

func handle(action:String) -> void:
	match action:
		"front:continue":
			if not has_save:return
			if not resume_session:game.build_mode=not game.state.claimed;game.pitch=.45 if game.state.claimed else .78
			game._action("start");resume_session=true
		"front:new":
			pending_character=FarmCharacters.load_choice();new_game()
		"front:new_review":review_new()
		"front:new_commit":
			if game.hud.modal_kind=="new_confirm":commit_new()
		"front:cancel_new":pending_name="";show_title()
		"front:settings","front:controls":
			return_to="pause" if game.session_started else "title"
			if action=="front:settings":show_settings()
			else:show_controls()
		"front:back":back()
		"front:audio_tab":settings_tab(true)
		"front:video_tab":settings_tab(false)
		"front:defaults":
			for key in ["volume","music","ambience","effects","sensitivity"]:controls[key].value=FarmSettings.DEFAULTS[key]
			controls.fullscreen.button_pressed=true
			controls.quality.select(1);controls.fps.select(1);pending=FarmSettings.DEFAULTS.duplicate()
		"front:apply":
			var previous:Dictionary=game.preferences.data
			game.preferences.data=FarmSettings.normalized(pending)
			if game.preferences.save_preferences()!=OK:game.preferences.data=previous;game.hud.toast("Não foi possível salvar as configurações.");return
			game.preferences.apply(game);back()
		"front:title":
			if not game._save_game(false):return
			has_save=true;resume_session=true;show_title()
		"front:quit":game._action("quit")
