class_name FarmNavigation
extends RefCounted
var game:Node3D
var mini:FarmMapView
var large:FarmMapView
var status:Label
var detail:Label
var terrain:Texture2D
var waypoint:=Vector2.ZERO
var waypoint_name:=""
var target_key:=""
var stable_target:Dictionary={}

func setup(owner_game:Node3D) -> void:
	game=owner_game;terrain=FarmMapView.background()
	var p:=FarmGameUI.card(game.hud,game.hud.walking.root,Rect2(24,153,252,254))
	mini=FarmMapView.new();mini.position=Vector2(7,7);mini.size=Vector2(238,190);mini.terrain=terrain;p.add_child(mini)
	mini.gui_input.connect(func(event:InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:show())
	status=game.hud.label(p,"Explore o vale",Vector2(10,202),Vector2(232,20),14)
	status.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	var button:=FarmGameUI.action(game.hud,p,"M · Mapa do vale",Rect2(7,224,238,26),"map")
	button.add_theme_font_size_override("font_size",14)
	for style_key in ["normal","hover","pressed","disabled"]:
		var box:=button.get_theme_stylebox(style_key) as StyleBoxFlat
		box.content_margin_top=2;box.content_margin_bottom=2
	button.size.y=26

func destinations() -> Array:
	var values:Array=[]
	if game.state.claimed:values.append({"key":"home","name":"Minha fazenda","at":game.state.center})
	values.append({"key":"horse","name":"Pé de Pano","at":Vector2(game.horse.position.x,game.horse.position.z)})
	values.append({"key":"market","name":"Armazém da Lúcia","at":Vector2(-24,15)})
	values.append({"key":"armory","name":"Damião · Armeiro","at":Vector2(-33.5,22)})
	for i in range(game.state.items.size()):
		var item:Dictionary=game.state.items[i]
		if item.kind=="stable":values.append({"key":"stable:%d"%i,"name":"Estrebaria %d"%(i+1),"at":FarmStable.entrance(item)})
	for key in FarmParcels.LOTS:
		var lot:Dictionary=FarmParcels.LOTS[key]
		values.append({"key":key,"name":lot.name+(" · seu" if key in game.state.owned_parcels else " · à venda"),"at":lot.center})
	for key in FarmTrails.STOPS:
		var stop:Dictionary=FarmTrails.STOPS[key]
		values.append({"key":key,"name":stop.name,"at":stop.at})
	return values

func select(point:Vector2,title:String,key:String="") -> void:
	waypoint=point;waypoint_name=title;target_key=key
	stable_target={}
	if key.begins_with("stable:"):stable_target=game.state.items[int(key.trim_prefix("stable:"))]
	refresh()

func handle(action:String) -> void:
	if action=="map":show()
	elif action=="map:clear":waypoint_name="";target_key="";refresh()
	elif action.begins_with("map:go:"):
		for entry in destinations():
			if entry.key==action.trim_prefix("map:go:"):select(entry.at,entry.name,entry.key);return

func show() -> void:
	if not game.session_started:return
	game.actor.stop_emote()
	var hud:FarmHUD=game.hud
	var panel:=FarmGameUI.open(hud,"valley_map","Mapa do vale","book",1190,800)
	large=FarmMapView.new();large.full=true;large.terrain=terrain;large.position=Vector2(22,110);large.size=Vector2(700,612);panel.add_child(large)
	large.picked.connect(func(point:Vector2):select(point,"Ponto marcado"))
	hud.label(panel,"PARA ONDE VAMOS?",Vector2(747,110),Vector2(410,29),20)
	var scroll:=ScrollContainer.new();scroll.position=Vector2(747,149);scroll.size=Vector2(420,469);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;panel.add_child(scroll)
	var list:=VBoxContainer.new();list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;list.add_theme_constant_override("separation",4);scroll.add_child(list)
	for entry in destinations():
		var button:=FarmGameUI.action(hud,list,entry.name,Rect2(0,0,400,32),"map:go:"+entry.key)
		button.add_theme_font_size_override("font_size",15)
		for style_key in ["normal","hover","pressed","disabled"]:
			var box:=button.get_theme_stylebox(style_key) as StyleBoxFlat
			box.content_margin_top=3;box.content_margin_bottom=3
		button.custom_minimum_size.y=32;button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	detail=hud.label(panel,"",Vector2(747,630),Vector2(420,57),17)
	detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	FarmGameUI.action(hud,panel,"Limpar destino",Rect2(747,692,198,40),"map:clear")
	FarmGameUI.action(hud,panel,"Voltar ao vale",Rect2(956,692,211,40),"close",true)
	hud.label(panel,"Clique no mapa para marcar • Linha direta até o destino",Vector2(24,736),Vector2(697,25),16)
	hud.label(panel,"Branco: você   •   Marrom: cavalo   •   Dourado: seus terrenos",Vector2(24,765),Vector2(1100,25),15)
	refresh()

func refresh() -> void:
	if mini==null:return
	var p:=Vector2(game.player.position.x,game.player.position.z)
	if target_key.begins_with("stable:"):
		var found:=false
		for item in game.state.items:
			if is_same(item,stable_target):found=true;waypoint=FarmStable.entrance(item);break
		if not found:waypoint_name="";target_key="";stable_target={}
	if target_key=="horse":waypoint=Vector2(game.horse.position.x,game.horse.position.z)
	for view in [mini,large]:
		if not is_instance_valid(view):continue
		view.trees=game.world.landscape.trunk_points;view.locations=destinations()
		view.state=game.state;view.player_at=p;view.horse_at=Vector2(game.horse.position.x,game.horse.position.z);view.heading=game.avatar.rotation.y
		view.destination=waypoint;view.has_destination=not waypoint_name.is_empty();view.queue_redraw()
	var text:="Escolha um destino ou clique no mapa."
	if not waypoint_name.is_empty():
		var distance:=p.distance_to(waypoint)
		text="%s · %s"%[waypoint_name,"Chegou!" if distance<4 else "%d m"%roundi(distance)]
	status.text=text if not waypoint_name.is_empty() else "Norte ↑  •  Explore o vale"
	status.tooltip_text=text
	if is_instance_valid(detail):detail.text=text
