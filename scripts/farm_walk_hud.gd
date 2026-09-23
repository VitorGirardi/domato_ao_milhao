class_name FarmWalkHUD
extends RefCounted

var farm_levels:=FarmLevelsHUD.new()
var root:Control
var clock:Label
var wallet:Label
var objective:Button
var interaction:Button
var seed_panel:Panel
var seeds:Dictionary={}
var attention:Button
var controls:Label
var target:Dictionary={}
var horse_panel:Panel
var horse_stamina:ProgressBar
var horse_title:Label

func setup(hud:FarmHUD) -> void:
	root=Control.new(); root.mouse_filter=Control.MOUSE_FILTER_IGNORE
	hud.world_hud.add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	farm_levels.setup(hud,root,Rect2(470,22,500,70))
	var time_panel:=FarmGameUI.card(hud,root,Rect2(24,22,242,50))
	clock=hud.label(time_panel,"",Vector2(15,10),Vector2(220,32),20)
	var cash:=FarmGameUI.card(hud,root,Rect2(1154,22,262,50))
	FarmGameUI.icon(cash,"coins",Rect2(12,9,33,33))
	wallet=hud.label(cash,"",Vector2(57,9),Vector2(190,33),24)
	objective=FarmGameUI.action(hud,root,"Objetivo",Rect2(24,86,335,43),"objectives")
	objective.add_theme_font_size_override("font_size",16)
	attention=FarmGameUI.action(hud,root,"",Rect2(986,86,430,48),"field_attention",true)
	attention.add_theme_font_size_override("font_size",16)
	interaction=FarmGameUI.action(hud,root,"",Rect2(470,737,500,60),"nearby_interact",true)
	interaction.add_theme_font_size_override("font_size",23)
	seed_panel=FarmGameUI.card(hud,root,Rect2(470,671,500,54))
	for i in range(3):
		var key:String=["carrot","wheat","corn"][i]
		var b:=FarmGameUI.action(hud,seed_panel,FarmState.CROPS[key].name,Rect2(8+i*164,7,156,40),"crop:"+key)
		b.icon=load("res://assets/ui/%s.svg"%key); b.expand_icon=true
		b.add_theme_constant_override("icon_max_width",23)
		seeds[key]=b
	controls=hud.label(root,"WASD andar   •   Shift correr   •   Espaço pular   •   Mouse direito girar",Vector2(370,815),Vector2(700,28),16,FarmHUD.CREAM)
	controls.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	controls.add_theme_color_override("font_shadow_color",Color("20392a")); controls.add_theme_constant_override("shadow_offset_y",2)
	horse_panel=FarmGameUI.card(hud,root,Rect2(1030,737,386,70));horse_panel.visible=false
	horse_title=hud.label(horse_panel,"Pé de Pano",Vector2(16,8),Vector2(350,27),18)
	horse_stamina=ProgressBar.new();horse_stamina.position=Vector2(16,43);horse_stamina.size=Vector2(350,12);horse_stamina.show_percentage=false;horse_panel.add_child(horse_stamina)
	for entry in [["background",Color("d8cfb6")],["fill",Color("6d9650")]]:
		var style:=StyleBoxFlat.new();style.bg_color=entry[1];style.set_corner_radius_all(4);horse_stamina.add_theme_stylebox_override(entry[0],style)
	for i in range(7):
		FarmGameUI.action(hud,root,["F · Armazém","H · Ajudante","TAB · Construir","F5 · Salvar","Esc · Menu","B · Emotes","T · Terrenos"][i],Rect2(139+i*166,854,156,32),["market","staff","mode","save","menu","emotes","parcels"][i]).add_theme_font_size_override("font_size",14)

func update(hud:FarmHUD,state:FarmState,context:Dictionary,crop:String) -> void:
	farm_levels.update(state)
	target=context
	clock.text=hud.clock_label.text
	wallet.text=hud.money_text(state)
	var step:=state.journey_step()
	objective.text="Objetivo · "+FarmState.JOURNEY[step].title if step<FarmState.JOURNEY.size() else "Objetivos concluídos ✓"
	objective.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	objective.tooltip_text="Ver objetivo e próxima ação"
	interaction.visible=not context.is_empty()
	interaction.disabled=not context.get("ready",true)
	interaction.text=("E · " if context.get("ready",true) else "")+str(context.get("text",""))
	seed_panel.visible=context.get("seeds",false)
	for key in seeds:
		seeds[key].modulate=Color.WHITE if key==crop else Color("b9b9a4")
	var paused:=FarmFieldAlerts.paused_text(state)
	var full:=FarmFieldAlerts.full_coops(state)
	var cheese:=FarmFieldAlerts.ready_cheeseries(state)
	attention.visible=not paused.is_empty() or not full.is_empty() or not cheese.is_empty()
	attention.text=paused if not paused.is_empty() else ("Ninho cheio · Coletar ovos" if full.size()==1 else "%d ninhos cheios · Ver"%full.size())
	if paused.is_empty() and full.is_empty() and not cheese.is_empty(): attention.text="Queijo pronto · Recolher lote"
	if paused.length()>48: attention.text="Ajudantes pausados · Ver equipe"
	attention.tooltip_text=paused if not paused.is_empty() else "A produção volta após a coleta."
	if hud.toast_time>0 and not paused.is_empty() and hud.toast_label.text.begins_with(paused): attention.visible=false

static func objectives(hud:FarmHUD,state:FarmState) -> void:
	var p:=FarmGameUI.open(hud,"objectives","Seu próximo passo","book",720,410)
	var step:=state.journey_step()
	var title:="Primeiro capítulo concluído!"
	var body:="Continue expandindo e melhorando sua fazenda."
	if step<FarmState.JOURNEY.size():
		title=FarmState.JOURNEY[step].title; body=hud.quest_label.text
	hud.label(p,title,Vector2(28,117),Vector2(664,44),26)
	hud.label(p,body,Vector2(28,175),Vector2(664,106),19).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	FarmGameUI.action(hud,p,"Voltar ao campo",Rect2(28,326,270,48),"close")
	if step<FarmState.JOURNEY.size(): FarmGameUI.action(hud,p,hud.quest_button.text,Rect2(312,326,380,48),"journey",true)

func mount_status(mounted:bool,stamina:float,burst:float) -> void:
	horse_panel.visible=mounted
	horse_stamina.value=stamina
	horse_title.text="Pé de Pano · %s · %d%%"%["Galope" if burst>0 else "Fôlego",int(stamina)]
	controls.text="WASD cavalgar   •   Shift tapinha / galope   •   E desmontar" if mounted else "WASD andar   •   Shift correr   •   Espaço pular   •   Mouse direito girar"
