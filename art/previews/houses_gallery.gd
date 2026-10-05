extends Node3D
## Isolated art viewer. No game scene, farm state, saves or vehicle dependencies.
const FILES := ["farm_house_starter", "farm_house_upgrade"]
const TITLES := ["Um começo de verdade", "O primeiro grande cuidado", "A mesma fazenda, uma nova fase"]
const NOTES := ["Madeira, remendos e um alpendre para chamar de seu.", "Paredes claras, telhas de barro e uma varanda mais acolhedora.", "Casa inicial à esquerda · primeira melhoria à direita"]
var houses:Array[Node3D]=[]
var islands:Array[Node3D]=[]
var camera:=Camera3D.new()
var environment:=Environment.new()
var sun:=DirectionalLight3D.new()
var selected:=2
var yaw:=.62
var elevation:=.42
var distance:=29.0
var dusk:=false
var title:Label
var note:Label
var buttons:Array[Button]=[]
var light_button:Button

func _ready() -> void:
	environment.background_mode=Environment.BG_COLOR;environment.background_color=Color("b6cbbf")
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color=Color("d5e6db");environment.ambient_light_energy=.25
	environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	var world:=WorldEnvironment.new();world.environment=environment;add_child(world)
	sun.rotation_degrees=Vector3(-48,-35,0);sun.light_color=Color("fff1d5");sun.light_energy=.4
	sun.shadow_enabled=true;sun.directional_shadow_max_distance=70;add_child(sun)
	for i in 2:
		var island:=Node3D.new();island.name="InitialHouse" if i==0 else "FirstUpgrade"
		add_child(island);islands.append(island)
		var grass:=CylinderMesh.new();grass.top_radius=6.2;grass.bottom_radius=6.05;grass.height=.3;grass.radial_segments=64
		_mesh(island,grass,Vector3(0,-.16,0),Color("829461"))
		var earth:=CylinderMesh.new();earth.top_radius=6.05;earth.bottom_radius=5.75;earth.height=.45;earth.radial_segments=64
		_mesh(island,earth,Vector3(0,-.53,0),Color("806345"))
		var scene:=load("res://assets/models/%s.glb"%FILES[i]) as PackedScene
		var house:=scene.instantiate() as Node3D;island.add_child(house);houses.append(house)
		for j in 3:
			var stone:=CylinderMesh.new();stone.top_radius=.34;stone.bottom_radius=.39;stone.height=.08;stone.radial_segments=7
			_mesh(island,stone,Vector3(sin(j*2.1)*.1,.01,4.35+j*.6),Color("c4b18a")).rotation.y=j*.81
	add_child(camera);camera.current=true;camera.fov=43;camera.near=.15;camera.far=100
	_ui();select_view(2)

func _mesh(parent:Node3D,mesh:Mesh,at:Vector3,color:Color) -> MeshInstance3D:
	var node:=MeshInstance3D.new();node.mesh=mesh;node.position=at
	var material:=StandardMaterial3D.new();material.albedo_color=color;material.roughness=.92
	node.material_override=material;parent.add_child(node);return node

func _ui() -> void:
	var layer:=CanvasLayer.new();add_child(layer)
	var root:=Control.new();root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(root)
	var margin:=MarginContainer.new();root.add_child(margin);margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	margin.add_theme_constant_override("margin_left",28);margin.add_theme_constant_override("margin_top",24);margin.add_theme_constant_override("margin_right",28)
	var stack:=VBoxContainer.new();margin.add_child(stack);stack.add_theme_constant_override("separation",8)
	var eyebrow:=Label.new();eyebrow.text="DO MATO AO MILHÃO   /   ESTUDO DE ARTE";eyebrow.add_theme_font_size_override("font_size",14);eyebrow.add_theme_color_override("font_color",Color("294535"));stack.add_child(eyebrow)
	title=Label.new();title.add_theme_font_size_override("font_size",30);title.add_theme_color_override("font_color",Color("233b31"));stack.add_child(title)
	note=Label.new();note.add_theme_font_size_override("font_size",17);note.add_theme_color_override("font_color",Color("344d40"));stack.add_child(note)
	var bar:=HBoxContainer.new();stack.add_child(bar);bar.add_theme_constant_override("separation",10)
	for i in 3:
		var button:=_button(["1 · Casa inicial","2 · Primeira melhoria","3 · Comparar"][i]);bar.add_child(button);buttons.append(button)
		button.pressed.connect(select_view.bind(i))
	light_button=_button("L · Luz do fim da tarde");bar.add_child(light_button);light_button.pressed.connect(toggle_light)
	var reset_button:=_button("R · Reenquadrar");bar.add_child(reset_button);reset_button.pressed.connect(func():select_view(selected))
	var footer:=Label.new();root.add_child(footer);footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_top=-45;footer.offset_left=28;footer.offset_right=-28
	footer.text="Arraste com botão direito para girar · Scroll aproxima · Prévia independente, ainda sem construção ou interiores"
	footer.add_theme_font_size_override("font_size",15);footer.add_theme_color_override("font_color",Color("fff6da"))
	footer.add_theme_color_override("font_shadow_color",Color("294535"));footer.add_theme_constant_override("shadow_offset_y",2)

func _button(text:String) -> Button:
	var button:=Button.new();button.text=text;button.custom_minimum_size=Vector2(0,42)
	button.add_theme_font_size_override("font_size",16)
	for key in ["normal","hover","pressed","focus"]:
		var style:=StyleBoxFlat.new();style.bg_color=Color("315848") if key in ["pressed","focus"] else Color("f4e9cc")
		style.set_corner_radius_all(7);style.content_margin_left=14;style.content_margin_right=14
		button.add_theme_stylebox_override(key,style)
	button.add_theme_color_override("font_color",Color("284333"));button.add_theme_color_override("font_hover_color",Color("284333"));button.add_theme_color_override("font_pressed_color",Color("fff5d9"))
	return button

func select_view(index:int) -> void:
	selected=clampi(index,0,2);yaw=.62 if selected!=2 else .22;elevation=.42;distance=29 if selected==2 else 19.2
	for i in 2:
		islands[i].visible=selected==2 or selected==i
		islands[i].position=Vector3(-6.6 if i==0 else 6.6,0,0) if selected==2 else Vector3.ZERO
	title.text=TITLES[selected];note.text=NOTES[selected]
	for i in 3:buttons[i].modulate=Color("f4cd7c") if selected==i else Color.WHITE
	_camera()

func toggle_light() -> void:
	dusk=not dusk
	sun.light_color=Color("ffbf83") if dusk else Color("fff1d5")
	sun.light_energy=.35 if dusk else .4;sun.rotation_degrees.x=-18 if dusk else -48
	environment.ambient_light_color=Color("9bb6cc") if dusk else Color("d5e6db")
	environment.ambient_light_energy=.25
	light_button.text="L · Luz do dia" if dusk else "L · Luz do fim da tarde"

func _camera() -> void:
	var target:=Vector3(0,1.5,0)
	camera.position=target+Vector3(sin(yaw)*cos(elevation),sin(elevation),cos(yaw)*cos(elevation))*distance
	camera.look_at(target)

func _unhandled_input(event:InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_1:select_view(0)
			KEY_2:select_view(1)
			KEY_3:select_view(2)
			KEY_R:select_view(selected)
			KEY_L:toggle_light()
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		yaw-=event.relative.x*.006;elevation=clampf(elevation+event.relative.y*.004,.1,1.2);_camera()
	if event is InputEventMouseButton and event.pressed:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP:distance=maxf(9,distance-1);_camera()
		if event.button_index==MOUSE_BUTTON_WHEEL_DOWN:distance=minf(40,distance+1);_camera()
