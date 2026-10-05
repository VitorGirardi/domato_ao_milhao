extends Node3D
## Standalone art stage. No main scene, farm state, physics or save access.
const ASSETS:=["ore_copper","ore_iron","crystals","stalactites","roots","support","lantern","tools","wall"]
const TITLES:=["Galeria do Cobre","Galeria do Ferro","Salão dos Cristais"]
const NOTES:=["Pedra quente, cobre oxidado e raízes antigas.","Rocha fria, madeira envelhecida e vestígios de trabalho.","Quartzo azulado, pontas lilás e luz suave entre as pedras."]
var rooms:Array[Node3D]=[]
var models:Dictionary={}
var camera:=Camera3D.new()
var selected:=0
var yaw:=0.0
var elevation:=.12
var distance:=12.8
var title:Label
var note:Label
var buttons:Array[Button]=[]

func _ready() -> void:
	for key in ASSETS:models[key]=load("res://assets/models/cave_detail_%s.glb"%key)
	var environment:=WorldEnvironment.new();environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR
	environment.environment.background_color=Color("101a21")
	environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color=Color("aec2ca")
	environment.environment.ambient_light_energy=.24
	environment.environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	add_child(environment)
	var key:=DirectionalLight3D.new();key.rotation_degrees=Vector3(-48,-30,0)
	key.light_color=Color("dce6e5");key.light_energy=.3;key.shadow_enabled=true;add_child(key)
	for index in 3:
		var room:=Node3D.new();room.name=["CopperGallery","IronGallery","CrystalHall"][index]
		add_child(room);rooms.append(room);_room(room,index)
	add_child(camera);camera.current=true;camera.fov=58;camera.near=.1
	_ui();select_gallery(0)

func _prop(parent:Node3D,key:String,at:Vector3,angle:float=0,size:Vector3=Vector3.ONE) -> Node3D:
	var node:Node3D=models[key].instantiate();parent.add_child(node)
	node.position=at;node.rotation.y=angle;node.scale=size;return node

func _light(parent:Node3D,at:Vector3,color:Color,energy:float,radius:float) -> void:
	var lamp:=OmniLight3D.new();parent.add_child(lamp);lamp.position=at
	lamp.light_color=color;lamp.light_energy=energy;lamp.omni_range=radius
	lamp.omni_attenuation=1.3;lamp.shadow_enabled=false

func _room(parent:Node3D,index:int) -> void:
	var floor_node:=MeshInstance3D.new();var floor_mesh:=BoxMesh.new();floor_mesh.size=Vector3(9.2,.18,14.6)
	floor_node.mesh=floor_mesh;floor_node.position=Vector3(0,-.09,-.5)
	var ground:=StandardMaterial3D.new();ground.albedo_color=[Color("665344"),Color("414a4c"),Color("464251")][index]
	ground.roughness=.96;floor_node.material_override=ground;parent.add_child(floor_node)
	_prop(parent,"wall",Vector3(0,0,-7),0,Vector3(1.08,1.08,1))
	for z in [-3.5,3.0]:
		_prop(parent,"wall",Vector3(-4.3,0,z),PI/2,Vector3(1,1.08,1))
		_prop(parent,"wall",Vector3(4.3,0,z),-PI/2,Vector3(1,1.08,1))
	for z in [-7.0,-2.0,3.0]:
		var ceiling:=_prop(parent,"wall",Vector3(0,5.45,z),0,Vector3(1.08,1,1))
		ceiling.rotation.x=PI/2
	for z in [3.5,-3.7]:_prop(parent,"support",Vector3(0,0,z))
	# Hanging formations attach to the rocky roof, clear of the central route.
	for i in 6:
		_prop(parent,"stalactites",Vector3(-3.5+float(i%3)*3.5,5.45,-1.7-float(i/3)*3.8),i*.73,Vector3.ONE*(.65+float(i%2)*.2))
	if index!=2:
		for i in 3:
			_prop(parent,"roots",Vector3(-3.85,4.5,-4+float(i)*3.1),PI/2,Vector3.ONE*(1.0 if index==0 else .7))
	var ore:String=["ore_copper","ore_iron","crystals"][index]
	for i in 5:
		var side:float=-1 if i%2==0 else 1
		_prop(parent,ore,Vector3(side*(2.5+float(i%2)*.2),.03,2.0-float(i)*1.7),float(i)*1.1,Vector3.ONE*(.9+float(i%3)*.15))
	_prop(parent,"tools",Vector3(2.5,.02,4.65),-.65,Vector3.ONE*.9)
	if index==1:_prop(parent,"tools",Vector3(-2.5,.02,-3.6),.8,Vector3.ONE*.8)
	for i in 3:
		var at:=Vector3(-2.65 if i%2==0 else 2.65,.03,2.9-float(i)*3.6)
		_prop(parent,"lantern",at)
		_light(parent,at+Vector3(0,.45,.2),Color("ffbb70"),2.0 if index<2 else .8,7)
	if index==2:
		_prop(parent,"crystals",Vector3(0,0,-5.8),.35,Vector3.ONE*1.5)
		_light(parent,Vector3(-2,1.4,-2),Color("71c6e7"),1.5,6)
		_light(parent,Vector3(2,2,-5),Color("b395e4"),1.2,6)
	else:
		_light(parent,Vector3(0,3,-4),Color("e5c294") if index==0 else Color("a5bacb"),.6,8)

func _ui() -> void:
	var layer:=CanvasLayer.new();add_child(layer)
	var panel:=PanelContainer.new();panel.position=Vector2(24,24);layer.add_child(panel)
	var style:=StyleBoxFlat.new();style.bg_color=Color(.035,.06,.07,.94)
	style.content_margin_left=20;style.content_margin_right=20;style.content_margin_top=14;style.content_margin_bottom=14
	style.set_corner_radius_all(10);panel.add_theme_stylebox_override("panel",style)
	var box:=VBoxContainer.new();box.add_theme_constant_override("separation",8);panel.add_child(box)
	title=Label.new();title.add_theme_font_size_override("font_size",28);box.add_child(title)
	note=Label.new();note.add_theme_font_size_override("font_size",16);box.add_child(note)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",8);box.add_child(row)
	for i in 3:
		var button:=Button.new();button.text="%d · %s"%[i+1,["Cobre","Ferro","Cristais"][i]]
		button.custom_minimum_size=Vector2(125,36);button.pressed.connect(select_gallery.bind(i));row.add_child(button);buttons.append(button)
	var controls:=Label.new();controls.text="Prévia de arte · direito: girar · roda: aproximar · R: restaurar vista"
	controls.add_theme_font_size_override("font_size",14);box.add_child(controls)

func select_gallery(index:int) -> void:
	selected=clampi(index,0,2)
	for i in rooms.size():rooms[i].visible=i==selected
	for i in buttons.size():buttons[i].disabled=i==selected
	title.text=TITLES[selected];note.text=NOTES[selected]
	reset_camera()

func reset_camera() -> void:
	yaw=0;elevation=.12;distance=12.8;_camera()

func _camera() -> void:
	var target:=Vector3(0,2,-.7)
	camera.position=target+Vector3(sin(yaw)*cos(elevation),sin(elevation),cos(yaw)*cos(elevation))*distance
	camera.look_at(target)

func _unhandled_input(event:InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode>=KEY_1 and event.keycode<=KEY_3:select_gallery(event.keycode-KEY_1)
		if event.keycode==KEY_R:reset_camera()
	if event is InputEventMouseMotion and event.button_mask&MOUSE_BUTTON_MASK_RIGHT:
		yaw=clampf(yaw-event.relative.x*.004,-.35,.35)
		elevation=clampf(elevation+event.relative.y*.003,-.02,.3);_camera()
	if event is InputEventMouseButton and event.pressed:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP:distance=maxf(9,distance-.5);_camera()
		if event.button_index==MOUSE_BUTTON_WHEEL_DOWN:distance=minf(16,distance+.5);_camera()
