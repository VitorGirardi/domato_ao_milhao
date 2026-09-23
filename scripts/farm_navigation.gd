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
var selected_item:Dictionary={}
var category:="Todos"
var destination_list:VBoxContainer
var list_signature:=""
var filters:Array[Button]=[]

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
	if game.state.claimed:values.append({"key":"home","name":"Minha fazenda","at":game.state.center,"icon":"barn","group":"Locais"})
	values.append({"key":"horse","name":"Pé de Pano","at":Vector2(game.horse.position.x,game.horse.position.z),"icon":"map_horse","group":"Companhia"})
	values.append({"key":"market","name":"Armazém da Lúcia","at":Vector2(-24,15),"icon":"coins","group":"Locais"})
	values.append({"key":"armory","name":"Damião · Armeiro","at":Vector2(-33.5,22),"icon":"pistol","group":"Locais"})
	if game.world.cat.visible:
		var cat:Vector3=game.world.cat.position
		values.append({"key":"cat","name":"Gato da fazenda","at":Vector2(cat.x,cat.z),"icon":"map_cat","group":"Companhia"})
	if game.network.active and game.network.accepted!=0 and is_instance_valid(game.network.remote):
		var other:Vector3=game.network.remote.position
		values.append({"key":"friend","name":game.network.remote_name,"at":Vector2(other.x,other.z),"icon":"worker","group":"Companhia"})
	for i in range(game.state.items.size()):
		var item:Dictionary=game.state.items[i]
		if item.kind in FarmMapPlaces.ICONS:
			values.append({"key":"%s:%d"%[item.kind,i],"name":FarmState.ITEMS[item.kind].name,"at":FarmStable.entrance(item) if item.kind=="stable" else Vector2(item.x,item.z),"icon":FarmMapPlaces.ICONS[item.kind],"group":"Fazenda","notice":FarmMapPlaces.notices(item)})
	for key in FarmParcels.LOTS:
		var lot:Dictionary=FarmParcels.LOTS[key]
		values.append({"key":key,"name":lot.name+(" · seu" if key in game.state.owned_parcels else " · à venda"),"at":lot.center,"group":"Locais"})
	for key in FarmTrails.STOPS:
		var stop:Dictionary=FarmTrails.STOPS[key]
		values.append({"key":key,"name":stop.name,"at":stop.at,"group":"Locais"})
	return values

func select(point:Vector2,title:String,key:String="") -> void:
	waypoint=point;waypoint_name=title;target_key=key
	stable_target={}
	selected_item={}
	if ":" in key:
		var index:=int(key.get_slice(":",1))
		if index>=0 and index<game.state.items.size():selected_item=game.state.items[index]
	if key.begins_with("stable:"):stable_target=game.state.items[int(key.trim_prefix("stable:"))]
	refresh()

func handle(action:String) -> void:
	if action=="map":show()
	elif action.begins_with("map:filter:"):
		category=action.trim_prefix("map:filter:");rebuild_list()
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
	large.place_picked.connect(func(key:String):handle("map:go:"+key))
	hud.label(panel,"PARA ONDE VAMOS?",Vector2(747,110),Vector2(410,29),20)
	filters.clear()
	for i in range(4):
		var title:String=["Todos","Fazenda","Companhia","Locais"][i]
		var tab:=FarmGameUI.action(hud,panel,title,Rect2(747+i*105,146,102,35),"map:filter:"+title)
		tab.add_theme_font_size_override("font_size",13)
		filters.append(tab)
	var scroll:=ScrollContainer.new();scroll.position=Vector2(747,193);scroll.size=Vector2(420,425);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;panel.add_child(scroll)
	destination_list=VBoxContainer.new();destination_list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;destination_list.add_theme_constant_override("separation",5);scroll.add_child(destination_list)
	rebuild_list()
	detail=hud.label(panel,"",Vector2(747,630),Vector2(420,57),17)
	detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	FarmGameUI.action(hud,panel,"Limpar destino",Rect2(747,692,198,40),"map:clear")
	FarmGameUI.action(hud,panel,"Voltar ao vale",Rect2(956,692,211,40),"close",true)
	hud.label(panel,"Clique para marcar • Scroll aproxima • Linha direta, não é rota",Vector2(24,736),Vector2(697,25),16)
	hud.label(panel,"Branco: você   •   Ícones: locais e companhia   •   ! Cuidados ou coleta",Vector2(24,765),Vector2(1100,25),15)
	refresh()

func refresh() -> void:
	if mini==null:return
	var p:=Vector2(game.player.position.x,game.player.position.z)
	var places:=destinations()
	if is_instance_valid(destination_list):
		var signature:=""
		for entry in places:signature+=entry.key+entry.name+entry.get("notice","")
		if signature!=list_signature:list_signature=signature;rebuild_list()
	if not selected_item.is_empty() and not target_key.is_empty():
		var index:=-1
		for i in range(game.state.items.size()):
			if is_same(game.state.items[i],selected_item):index=i;break
		# Network snapshots replace dictionaries; recover by kind and placement.
		if index<0:
			for i in range(game.state.items.size()):
				var item:Dictionary=game.state.items[i]
				if item.kind==selected_item.kind and item.x==selected_item.x and item.z==selected_item.z:index=i;break
		if index<0:waypoint_name="";target_key="";selected_item={};stable_target={}
		else:
			selected_item=game.state.items[index];target_key="%s:%d"%[selected_item.kind,index]
	if not target_key.is_empty():
		var found:=false
		for entry in places:
			if entry.key==target_key:waypoint=entry.at;found=true;break
		if not found:waypoint_name="";target_key=""
	for view in [mini,large]:
		if not is_instance_valid(view):continue
		view.trees=game.world.landscape.trunk_points;view.locations=places
		view.state=game.state;view.player_at=p;view.horse_at=Vector2(game.horse.position.x,game.horse.position.z);view.heading=game.avatar.rotation.y
		view.destination=waypoint;view.has_destination=not waypoint_name.is_empty();view.queue_redraw()
	var text:="Escolha um destino ou clique no mapa."
	if not waypoint_name.is_empty():
		var distance:=p.distance_to(waypoint)
		text="%s · %s"%[waypoint_name,"Chegou!" if distance<4 else "%d m · %s"%[roundi(distance),FarmMapPlaces.direction(waypoint-p)]]
	status.text=("Chegou! · "+waypoint_name if p.distance_to(waypoint)<4 else "%d m · %s · %s"%[roundi(p.distance_to(waypoint)),FarmMapPlaces.direction(waypoint-p),waypoint_name]) if not waypoint_name.is_empty() else "Norte ↑  •  Explore o vale"
	status.tooltip_text=text
	if is_instance_valid(detail):
		for entry in places:
			if entry.key==target_key and not entry.get("notice","").is_empty():text+="\n"+entry.notice
		detail.text=text

func rebuild_list() -> void:
	if not is_instance_valid(destination_list):return
	for tab in filters:
		if is_instance_valid(tab):tab.modulate=Color("ffdc87") if tab.text==category else Color.WHITE
	for child in destination_list.get_children():destination_list.remove_child(child);child.queue_free()
	var places:=destinations()
	var p:=Vector2(game.player.position.x,game.player.position.z)
	places.sort_custom(func(a:Dictionary,b:Dictionary):return p.distance_squared_to(a.at)<p.distance_squared_to(b.at))
	for entry in places:
		if category!="Todos" and entry.get("group","")!=category:continue
		var text:String=entry.name
		if not entry.get("notice","").is_empty():text="! "+text
		var button:=FarmGameUI.action(game.hud,destination_list,text,Rect2(0,0,400,40),"map:go:"+entry.key)
		button.add_theme_font_size_override("font_size",15)
		button.alignment=HORIZONTAL_ALIGNMENT_LEFT
		button.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		button.tooltip_text=entry.name+" · %d m"%roundi(p.distance_to(entry.at))+"\n"+entry.get("notice","")
		if entry.has("icon"):
			button.icon=load("res://assets/ui/%s.svg"%entry.icon)
			button.expand_icon=true;button.add_theme_constant_override("icon_max_width",26)
		button.custom_minimum_size.y=40;button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
