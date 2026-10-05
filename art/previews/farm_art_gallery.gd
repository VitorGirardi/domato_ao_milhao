extends Node3D
## Art approval gallery only. Never loads the main scene or reads a farm save.
const KEYS := ["barn_starter","barn_upgrade","fence_rustic","fence_painted","gate_rustic","gate_painted","well","wash_tub","raised_bed","trellis","orchard_young","orchard_mature","compost","produce_crates"]
const TITLES := ["O começo da fazenda", "Uma fazenda bem cuidada", "Celeiros: guardar, produzir, crescer", "Cercas que contam a evolução", "Da horta ao pomar", "Pequenos lugares de trabalho"]
const NOTES := ["Casa simples, madeira antiga, pomar jovem e as primeiras colheitas.", "Uma visão do conjunto: casa melhorada, celeiro, horta e pomar adulto.", "Madeira rústica à esquerda · primeira melhoria à direita", "Módulos de 2 m · portões com dobradiça preparada para futura animação", "Canteiro, treliça, árvores em duas fases, compostagem e caixas de colheita", "Poço, tanque com bomba, compostagem e produção pronta para sair da horta"]
const SHORT := ["1 · Começo","2 · Evolução","3 · Celeiros","4 · Cercas","5 · Horta / pomar","6 · Detalhes"]
var rooms:Array[Node3D]=[]
var assets:Dictionary={}
var camera:=Camera3D.new()
var sun:=DirectionalLight3D.new()
var environment:=Environment.new()
var selected:=1
var yaw:=.35
var elevation:=.5
var distance:=49.0
var target:=Vector3(0,1.3,0)
var dusk:=false
var title:Label
var note:Label
var light_button:Button
var buttons:Array[Button]=[]

func _ready() -> void:
	for key in KEYS:assets[key]=load("res://assets/models/farm_art_%s.glb"%key)
	for key in ["starter","upgrade"]:assets["house_"+key]=load("res://assets/models/farm_house_%s.glb"%key)
	environment.background_mode=Environment.BG_COLOR;environment.background_color=Color("b6cbbf")
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.ambient_light_color=Color("d5e6db");environment.ambient_light_energy=.25
	var world:=WorldEnvironment.new();world.environment=environment;add_child(world)
	sun.rotation_degrees=Vector3(-48,-35,0);sun.light_color=Color("fff1d5");sun.light_energy=.4
	sun.shadow_enabled=true;sun.directional_shadow_max_distance=100;add_child(sun)
	for i in 6:
		var room:=Node3D.new();room.name="ArtStage%d"%i;add_child(room);rooms.append(room)
	_farm(rooms[0],false);_farm(rooms[1],true)
	_ground(rooms[2],Vector2(26,15))
	_prop(rooms[2],"barn_starter",Vector3(-6.5,0,0));_prop(rooms[2],"barn_upgrade",Vector3(6.5,0,0))
	_label(rooms[2],"CELEIRO INICIAL",Vector3(-6.5,.15,6));_label(rooms[2],"PRIMEIRA MELHORIA",Vector3(6.5,.15,6))
	_ground(rooms[3],Vector2(20,12))
	for row in 2:
		var suffix:="rustic" if row==0 else "painted"
		var z:float=-3 if row==0 else 3
		_prop(rooms[3],"gate_"+suffix,Vector3(0,0,z))
		for x in [-4.675,-2.675,2.675,4.675]:_prop(rooms[3],"fence_"+suffix,Vector3(x,0,z))
		_label(rooms[3],"MADEIRA RÚSTICA" if row==0 else "CERCA PINTADA",Vector3(-6.5,.15,z+1.4))
	_ground(rooms[4],Vector2(22,15))
	for entry in [["raised_bed",Vector3(-6,0,3)],["trellis",Vector3(-5,0,-2)],["orchard_young",Vector3(0,0,-2)],["orchard_mature",Vector3(6,0,-2)],["compost",Vector3(0,0,4)],["produce_crates",Vector3(6,0,4)]]:_prop(rooms[4],entry[0],entry[1])
	for entry in [["CANTEIRO",Vector3(-6,.15,5)],["TRELIÇA",Vector3(-5,.15,-.3)],["POMAR JOVEM",Vector3(0,.15,.5)],["POMAR ADULTO",Vector3(6,.15,-.7)],["COMPOSTEIRA",Vector3(0,.15,5.5)],["CAIXAS DE COLHEITA",Vector3(6,.15,6.1)]]:_label(rooms[4],entry[0],entry[1])
	_ground(rooms[5],Vector2(19,13))
	_prop(rooms[5],"well",Vector3(-4,0,-1));_prop(rooms[5],"wash_tub",Vector3(3.5,0,-1))
	_prop(rooms[5],"compost",Vector3(-3,0,3.5));_prop(rooms[5],"produce_crates",Vector3(3,0,3.5))
	_label(rooms[5],"ÁGUA, CUIDADO E COLHEITA",Vector3(0,.15,5.3))
	add_child(camera);camera.current=true;camera.fov=43;camera.near=.15;camera.far=140
	_ui();select_view(1)

func _prop(parent:Node3D,key:String,at:Vector3,angle:float=0) -> Node3D:
	var node:Node3D=assets[key].instantiate();parent.add_child(node);node.position=at;node.rotation.y=angle;return node

func _box(parent:Node3D,at:Vector3,size:Vector3,color:Color) -> void:
	var node:=MeshInstance3D.new();var mesh:=BoxMesh.new();mesh.size=size;node.mesh=mesh;node.position=at
	var material:=StandardMaterial3D.new();material.albedo_color=color;material.roughness=1;node.material_override=material;parent.add_child(node)

func _ground(parent:Node3D,size:Vector2) -> void:
	_box(parent,Vector3(0,-.2,0),Vector3(size.x,.4,size.y),Color("829461"))
	_box(parent,Vector3(0,-.55,0),Vector3(size.x-.25,.3,size.y-.25),Color("81684b"))

func _label(parent:Node3D,text:String,at:Vector3) -> void:
	var label:=Label3D.new();label.text=text;label.position=at;label.font_size=32;label.pixel_size=.012
	label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.modulate=Color("fff3d6");label.outline_modulate=Color("2e493b");parent.add_child(label)

func _farm(parent:Node3D,upgraded:bool) -> void:
	_ground(parent,Vector2(35,28))
	var suffix:="upgrade" if upgraded else "starter"
	_prop(parent,"house_"+suffix,Vector3(-8,0,2))
	_prop(parent,"barn_"+suffix,Vector3(6.5,0,-5))
	_box(parent,Vector3(0,.01,6),Vector3(2,.04,15),Color("b69a6a"))
	_box(parent,Vector3(-4,.01,6),Vector3(8,.04,1.5),Color("b69a6a"))
	_box(parent,Vector3(3.4,.01,.7),Vector3(7,.04,1.5),Color("b69a6a"))
	var fence:="painted" if upgraded else "rustic"
	_prop(parent,"gate_"+fence,Vector3(0,0,11.5))
	for side in [-1,1]:
		for j in 7:_prop(parent,"fence_"+fence,Vector3(side*(2.675+j*2),0,11.5))
	_prop(parent,"well",Vector3(-2.5,0,-3))
	for x in [6,10]:
		_prop(parent,"raised_bed",Vector3(x,0,5))
		if upgraded:_prop(parent,"trellis",Vector3(x,0,7.5))
	_prop(parent,"wash_tub",Vector3(13,0,4))
	_prop(parent,"compost",Vector3(14,0,8))
	_prop(parent,"produce_crates",Vector3(8.5,0,1))
	for at in [Vector3(-13,0,-7),Vector3(-8,0,-8),Vector3(14,0,-8)]:_prop(parent,"orchard_mature" if upgraded else "orchard_young",at)

func _ui() -> void:
	var layer:=CanvasLayer.new();add_child(layer)
	var root:=Control.new();root.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(root);root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin:=MarginContainer.new();root.add_child(margin);margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	for entry in [["margin_left",24],["margin_right",24],["margin_top",18]]:margin.add_theme_constant_override(entry[0],entry[1])
	var stack:=VBoxContainer.new();stack.add_theme_constant_override("separation",6);margin.add_child(stack)
	var eyebrow:=Label.new();eyebrow.text="DO MATO AO MILHÃO   /   CADERNO DE ARTE DA FAZENDA";eyebrow.add_theme_font_size_override("font_size",13);eyebrow.add_theme_color_override("font_color",Color("294535"));stack.add_child(eyebrow)
	title=Label.new();title.add_theme_font_size_override("font_size",28);title.add_theme_color_override("font_color",Color("233b31"));stack.add_child(title)
	note=Label.new();note.add_theme_font_size_override("font_size",16);note.add_theme_color_override("font_color",Color("344d40"));stack.add_child(note)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",8);stack.add_child(row)
	for i in 6:
		var button:=_button(SHORT[i]);row.add_child(button);buttons.append(button);button.pressed.connect(select_view.bind(i))
	light_button=_button("L · Fim de tarde");row.add_child(light_button);light_button.pressed.connect(toggle_light)
	var reset_button:=_button("R · Reenquadrar");row.add_child(reset_button);reset_button.pressed.connect(func():select_view(selected))
	var footer:=Label.new();root.add_child(footer);footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE);footer.offset_top=-36;footer.offset_left=24
	footer.text="Botão direito: girar · Roda: aproximar · Artes para aprovação, ainda sem integração no jogo"
	footer.add_theme_font_size_override("font_size",15);footer.add_theme_color_override("font_color",Color("294535"))

func _button(text:String) -> Button:
	var button:=Button.new();button.text=text;button.custom_minimum_size.y=36;button.add_theme_font_size_override("font_size",14)
	for key in ["normal","hover","pressed","focus"]:
		var style:=StyleBoxFlat.new();style.bg_color=Color("f4e9cc");style.set_corner_radius_all(6);style.content_margin_left=10;style.content_margin_right=10
		button.add_theme_stylebox_override(key,style)
	for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:button.add_theme_color_override(key,Color("284333"))
	return button

func select_view(index:int) -> void:
	selected=clampi(index,0,5);yaw=.32 if selected<2 else .3;elevation=.56 if selected<2 else .43
	distance=[57.0,57.0,34.0,26.0,29.0,25.0][selected];target=Vector3(0,1,0)
	for i in rooms.size():rooms[i].visible=i==selected
	title.text=TITLES[selected];note.text=NOTES[selected]
	for i in 6:buttons[i].modulate=Color("f4cd7c") if selected==i else Color.WHITE
	_camera()

func toggle_light() -> void:
	dusk=not dusk;sun.light_color=Color("ffbf83") if dusk else Color("fff1d5");sun.light_energy=.35 if dusk else .4
	sun.rotation_degrees.x=-18 if dusk else -48;environment.ambient_light_color=Color("9bb6cc") if dusk else Color("d5e6db")
	light_button.text="L · Luz do dia" if dusk else "L · Fim de tarde"

func _camera() -> void:
	camera.position=target+Vector3(sin(yaw)*cos(elevation),sin(elevation),cos(yaw)*cos(elevation))*distance;camera.look_at(target)

func _unhandled_input(event:InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode>=KEY_1 and event.physical_keycode<=KEY_6:select_view(event.physical_keycode-KEY_1)
		elif event.physical_keycode==KEY_R:select_view(selected)
		elif event.physical_keycode==KEY_L:toggle_light()
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		yaw-=event.relative.x*.006;elevation=clampf(elevation+event.relative.y*.004,.12,1.2);_camera()
	if event is InputEventMouseButton and event.pressed:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP:distance=maxf(10,distance-1.5);_camera()
		if event.button_index==MOUSE_BUTTON_WHEEL_DOWN:distance=minf(75,distance+1.5);_camera()
