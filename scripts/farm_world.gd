class_name FarmWorld
extends Node3D

const TRADE_BOARD_AT:=Vector3(-22.1,0,15.4)

var models: Dictionary = {}
var structures := Node3D.new()
var border := Node3D.new()
var item_nodes: Array[Node3D] = []
var chickens: Array[Dictionary] = []
var farmer: Node3D
var clock: float = 0.0
var rng := RandomNumberGenerator.new()
var build_grid:=MeshInstance3D.new()
var selection:=Node3D.new()
var selection_edges: Array[MeshInstance3D]=[]
var highlighted_index: int = -1
var paint_materials: Dictionary = {}
var coop_views: Dictionary = {}

func _ready() -> void:
	rng.seed = 24517
	for key in ["barn", "coop", "fence", "sign", "tree", "rock", "chicken", "farmer", "market", "carrot", "wheat", "corn", "flower", "sprout", "watering_can", "harvest_carrot", "harvest_wheat", "harvest_corn", "feeder", "waterer", "nest", "egg"]:
		models[key] = load("res://assets/models/%s.glb" % key)
	models["trade_board"]=load("res://assets/models/trade_board.glb")
	add_child(structures)
	add_child(border)
	_environment()
	_landscape()
	_build_guides()

func _build_guides() -> void:
	add_child(build_grid)
	var plane:=PlaneMesh.new()
	plane.size=Vector2.ONE
	build_grid.mesh=plane
	var shader:=Shader.new()
	shader.code="""shader_type spatial;
render_mode unshaded, cull_disabled;
varying vec3 world_pos;
void vertex(){world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 vec2 p=abs(fract((world_pos.xz+1.0)/2.0)*2.0-1.0);
 float line=smoothstep(0.97,0.995,max(p.x,p.y));
 ALBEDO=vec3(1.0,0.94,0.7); ALPHA=line*0.25;
}"""
	var grid_material:=ShaderMaterial.new()
	grid_material.shader=shader
	build_grid.material_override=grid_material
	build_grid.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	build_grid.visible=false
	add_child(selection)
	var gold:=material("ffe092")
	gold.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	for i in range(4):
		var edge:=box(selection,Vector3.ZERO,Vector3.ONE,gold)
		edge.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		selection_edges.append(edge)
	selection.visible=false

func show_selection(state: FarmState, index: int) -> void:
	if index!=highlighted_index:
		highlighted_index=index
		update_crops(state)
	selection.visible=index>=0 and index<state.items.size()
	if not selection.visible: return
	var item:Dictionary=state.items[index]
	var rect:=state.item_rect(item.kind,Vector2(item.x,item.z),item.turn).grow(0.10)
	selection.position=Vector3(rect.get_center().x,0.19,rect.get_center().y)
	for i in range(4):
		var horizontal:=i<2
		selection_edges[i].scale=Vector3(rect.size.x,0.045,0.075) if horizontal else Vector3(0.075,0.045,rect.size.y)
		selection_edges[i].position=Vector3(0,0,rect.size.y/2*(1 if i==0 else -1)) if horizontal else Vector3(rect.size.x/2*(1 if i==2 else -1),0,0)

func material(hex: String, roughness: float = 0.9) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = Color(hex)
	result.roughness = roughness
	return result

func box(parent: Node3D, pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = mat
	node.position = pos
	parent.add_child(node)
	return node

func model(key: String, parent: Node3D, pos: Vector3 = Vector3.ZERO) -> Node3D:
	var node: Node3D = models[key].instantiate()
	node.position = pos
	parent.add_child(node)
	return node

func _environment() -> void:
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("70b4cd")
	sky_mat.sky_horizon_color = Color("cbe2d0")
	sky_mat.ground_bottom_color = Color("78906b")
	sky_mat.ground_horizon_color = Color("cbe2d0")
	sky.sky_material = sky_mat
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("dee7d4")
	env.ambient_light_energy = 0.4
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	environment.environment = env
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_color = Color("fff2d5")
	sun.light_energy = 0.65
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 110
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	add_child(sun)

func _landscape() -> void:
	var ground_shader := Shader.new()
	ground_shader.code = """shader_type spatial;
render_mode specular_disabled;
varying vec3 world_pos;
void vertex(){ world_pos = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz; }
void fragment(){
 float n = sin(world_pos.x * 0.13) * cos(world_pos.z * 0.17) * 0.5 + 0.5;
 float f = fract(sin(dot(floor(world_pos.xz*2.0), vec2(12.9898,78.233)))*43758.5453);
 ALBEDO = mix(vec3(0.28,0.46,0.12), vec3(0.39,0.56,0.18), n) + (f-0.5)*0.022;
 ROUGHNESS = 1.0;
}"""
	var ground_mat := ShaderMaterial.new()
	ground_mat.shader = ground_shader
	box(self, Vector3(0, -0.2, 0), Vector3(180, 0.4, 180), ground_mat)
	var body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(180, 0.4, 180)
	collision.shape = shape
	body.position.y = -0.2
	body.add_child(collision)
	add_child(body)
	var dirt := material("b99a68")
	box(self, Vector3(-27, 0.01, 0), Vector3(4.2, 0.07, 82), dirt)
	box(self, Vector3(0, 0.011, 30), Vector3(72, 0.075, 3.5), dirt)
	_river()
	for i in range(105):
		var pos := Vector3(rng.randf_range(-60, 65), 0, rng.randf_range(-62, 58))
		if pos.x > -31 and pos.x < 45 and pos.z > -40 and pos.z < 43:
			continue
		if pos.x < -35 and pos.x > -46:
			continue
		var tree := model("tree", self, pos)
		tree.scale = Vector3.ONE * rng.randf_range(0.8, 1.8)
		tree.rotation.y = rng.randf() * TAU
	for i in range(20):
		var angle := float(i) / 20 * TAU
		var hill := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radial_segments = 12
		sphere.rings = 6
		sphere.radius = 1
		sphere.height = 2
		hill.mesh = sphere
		hill.position = Vector3(sin(angle) * 81, -2, cos(angle) * 81)
		hill.scale = Vector3(rng.randf_range(19, 32), rng.randf_range(9, 17), rng.randf_range(19, 27))
		hill.material_override = material("71944f" if i % 2 == 0 else "638746")
		add_child(hill)
	for i in range(28):
		var pos := Vector3(rng.randf_range(-25, 40), 0, rng.randf_range(-37, 40))
		if pos.x > -21 and pos.x < 32 and pos.z > -32 and pos.z < 32:
			continue
		model("flower", self, pos).scale *= rng.randf_range(0.8, 1.4)
	for pos in [Vector3(-34,0,-20), Vector3(42,0,-35), Vector3(39,0,39), Vector3(-34,0,24)]:
		model("rock", self, pos).scale *= 1.6
	model("market", self, Vector3(-24, 0, 14)).rotation.y = PI / 2
	var vendor := model("farmer", self, Vector3(-24.5, 0, 14))
	vendor.rotation.y = PI / 2
	var board := Label3D.new()
	board.text = "SEU TONICO\nArmazém do Vale"
	board.font_size = 60
	board.pixel_size = 0.015
	board.position = Vector3(-24, 3.5, 14)
	board.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	board.modulate = Color("fff1ce")
	board.outline_modulate = Color("344737")
	add_child(board)
	_trade_board()
	for i in range(9):
		var cloud := Node3D.new()
		cloud.position = Vector3(rng.randf_range(-70, 70), rng.randf_range(24, 33), rng.randf_range(-65, 45))
		add_child(cloud)
		for j in range(3):
			var mesh := SphereMesh.new()
			mesh.radial_segments = 10
			mesh.rings = 5
			var node := MeshInstance3D.new()
			node.mesh = mesh
			node.material_override = material("f2efd7")
			node.position.x = j * 2.3
			node.scale = Vector3(7, 2.5 + j % 2, 4)
			node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			cloud.add_child(node)

func _trade_board() -> void:
	var root:=Node3D.new()
	root.position=TRADE_BOARD_AT
	root.rotation.y=PI/2
	add_child(root)
	model("trade_board",root)
	var body:=StaticBody3D.new()
	body.set_meta("trade_board",true)
	var shape:=CollisionShape3D.new()
	var box_shape:=BoxShape3D.new()
	box_shape.size=Vector3(2.5,2.6,0.30)
	shape.shape=box_shape
	shape.position.y=1.3
	body.add_child(shape)
	root.add_child(body)
	for entry in [["ENCOMENDAS",Vector3(0,2.22,0.19),0.005],["Nena",Vector3(-0.70,1.57,0.19),0.0035],["Bento",Vector3(0,1.57,0.19),0.0035],["Lola",Vector3(0.70,1.57,0.19),0.0035]]:
		var text:=Label3D.new()
		text.text=entry[0]
		text.position=entry[1]
		text.pixel_size=entry[2]
		text.font_size=32
		text.modulate=Color("fff7df") if entry[0]=="ENCOMENDAS" else Color("294739")
		text.outline_size=0
		root.add_child(text)

func _river() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(64):
		var z: float = -80 + i * 2.5
		var next_z: float = z + 2.5
		var x: float = -42 + sin(z * 0.065) * 2.6
		var nx: float = -42 + sin(next_z * 0.065) * 2.6
		var a := Vector3(x - 3.2, 0.04, z)
		var b := Vector3(x + 3.2, 0.04, z)
		var c := Vector3(nx - 3.2, 0.04, next_z)
		var d := Vector3(nx + 3.2, 0.04, next_z)
		for point in [a,b,c,b,d,c]:
			surface.add_vertex(point)
	surface.generate_normals()
	var river := MeshInstance3D.new()
	river.mesh = surface.commit()
	var water := material("4caaa9", 0.2)
	water.cull_mode = BaseMaterial3D.CULL_DISABLED
	river.material_override = water
	add_child(river)

func update_border(state: FarmState) -> void:
	for child in border.get_children():
		child.free()
	if not state.claimed:
		build_grid.visible=false
		return
	build_grid.position=Vector3(state.center.x,0.045,state.center.y)
	build_grid.scale=Vector3(state.land_size,1,state.land_size)
	var edge := material("f1d991")
	var half := state.land_size / 2
	for i in range(int(state.land_size / 2)):
		var t: float = -half + i * 2 + 0.65
		for side in [-1, 1]:
			box(border, Vector3(state.center.x + t, 0.065, state.center.y + side * half), Vector3(1.25,0.055,0.09), edge)
			box(border, Vector3(state.center.x + side * half,0.065,state.center.y+t), Vector3(0.09,0.055,1.25), edge)

func rebuild(state: FarmState) -> void:
	for node in structures.get_children():
		node.free()
	item_nodes.clear()
	chickens.clear()
	coop_views.clear()
	for i in range(state.items.size()):
		var item: Dictionary = state.items[i]
		var root := Node3D.new()
		root.position = Vector3(item.x, 0, item.z)
		root.rotation.y = int(item.turn) * PI / 2
		structures.add_child(root)
		item_nodes.append(root)
		if item.kind == "plot":
			var soil := box(root, Vector3(0,0.065,0), Vector3(1.86,0.14,1.86), material("765033"))
			soil.name = "Soil"
			for x in [-0.6,0,0.6]:
				box(root, Vector3(x,0.14,0),Vector3(0.22,0.08,1.7),material("8e633d"))
			var crop_root:=Node3D.new()
			crop_root.name="Crop"
			root.add_child(crop_root)
			var sprout:=model("sprout",crop_root,Vector3(0,0.14,0))
			sprout.name="Sprout"
			var young:=model(item.crop,crop_root,Vector3(0,0.14,0))
			young.name="Young"
			_tint_model(young,material("5b953f"))
			var ripe:=model(item.crop,crop_root,Vector3(0,0.14,0))
			ripe.name="Ripe"
			var badge:=Label3D.new()
			badge.name="Badge"
			badge.font_size=30
			badge.pixel_size=0.007
			badge.position=Vector3(0,1.7,0)
			badge.billboard=BaseMaterial3D.BILLBOARD_ENABLED
			badge.outline_modulate=Color("294739")
			badge.outline_size=9
			root.add_child(badge)
		elif item.kind == "path":
			box(root, Vector3(0,0.025,0), Vector3(1.98,0.05,1.98), material("c2a574"))
		else:
			var visual := model(item.kind, root)
			paint(visual,item)
			if item.kind in ["barn", "coop", "fence", "sign"]:
				var body := StaticBody3D.new()
				body.set_meta("item_index",i)
				var shape := CollisionShape3D.new()
				var box_shape := BoxShape3D.new()
				var size: Vector2 = FarmState.ITEMS[item.kind].size
				var height: float = 1.05 if item.kind=="fence" else (1.8 if item.kind=="sign" else (3.3 if item.kind=="barn" else 2.2))
				box_shape.size = Vector3(size.x * 0.85, height, size.y * 0.82)
				shape.shape = box_shape
				shape.position.y = height / 2
				body.add_child(shape)
				root.add_child(body)
			if item.kind == "sign":
				var label := Label3D.new()
				label.text = str(item.text).replace(" ", " ")
				label.font_size = 44
				label.pixel_size = 0.0038
				label.width = 450
				label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				label.position = Vector3(0,1.41,0.105)
				label.modulate = Color("fff2d3")
				label.outline_size = 0
				root.add_child(label)
			if item.kind == "coop":
				_build_coop(i,item,root,state)
	update_crops(state)
	update_border(state)
	update_animals(state)

func _build_coop(index: int, item: Dictionary, root: Node3D, state: FarmState) -> void:
	var feeder:=model("feeder",root,Vector3(-1.4,0,1.55))
	var waterer:=model("waterer",root,Vector3(1.6,0,-0.8))
	var nest:=model("nest",root,Vector3(1.25,0,1.55))
	var eggs:Array[Node3D]=[]
	for n in range(FarmAnimals.NEST_CAPACITY):
		eggs.append(model("egg",nest,Vector3((n%4-1.5)*0.19,0.17,(n/4-1)*0.18)))
	var badge:=Label3D.new()
	badge.font_size=32
	badge.pixel_size=0.008
	badge.position=Vector3(0,3.15,0)
	badge.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	badge.outline_modulate=Color("294739")
	root.add_child(badge)
	coop_views[index]={"feed":feeder.find_child("Feed",true,false),"water":waterer.find_child("Water",true,false),"eggs":eggs,"badge":badge}
	for c in range(3):
		var start:=Vector3(c-1,0,2.6).rotated(Vector3.UP,root.rotation.y)+root.position
		if not _hen_walkable(start,state):
			for attempt in range(160):
				var angle:float=attempt*TAU/16+c*0.4
				var radius:float=2.6+int(attempt/16)*1.5
				var candidate:=root.position+Vector3(sin(angle),0,cos(angle))*radius
				if _hen_walkable(candidate,state):
					start=candidate
					break
		var hen:=model("chicken",structures,start)
		_color_hen(hen,c)
		var body:=StaticBody3D.new()
		body.collision_layer=2
		body.collision_mask=0
		body.set_meta("item_index",index)
		body.set_meta("hen_index",c)
		var shape:=CollisionShape3D.new()
		var capsule:=CapsuleShape3D.new()
		capsule.radius=0.32
		capsule.height=1.05
		shape.shape=capsule
		shape.position.y=0.5
		body.add_child(shape)
		hen.add_child(body)
		var label:=Label3D.new()
		label.position.y=1.25
		label.font_size=28
		label.pixel_size=0.006
		label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		label.outline_modulate=Color("294739")
		hen.add_child(label)
		chickens.append({"node":hen,"home":root.position,"turn":root.rotation.y,"phase":index*2.0+c*2.1,"coop":index,"hen":c,"label":label})

func _color_hen(node: Node, color_index: int) -> void:
	if node is MeshInstance3D:
		for surface in range(node.mesh.get_surface_count()):
			var source:Material=node.mesh.surface_get_material(surface)
			if source and (source.resource_name.begins_with("White") or source.resource_name.begins_with("Cream")):
				var key:="hen:%d:%d"%[source.get_instance_id(),color_index]
				if not paint_materials.has(key):
					var replacement:StandardMaterial3D=source.duplicate()
					replacement.albedo_color=Color(FarmAnimals.COLORS[color_index])
					paint_materials[key]=replacement
				node.set_surface_override_material(surface,paint_materials[key])
	for child in node.get_children(): _color_hen(child,color_index)

func update_animals(state: FarmState) -> void:
	for index in coop_views:
		var flock:Dictionary=state.items[index].flock
		var view:Dictionary=coop_views[index]
		view.feed.visible=flock.food>0
		view.feed.scale.y=maxf(0.05,float(flock.food)/100.0)
		view.feed.position.y=0.105+float(flock.food)*0.00095
		view.water.visible=flock.water>0
		view.water.position.y=0.07+float(flock.water)*0.0007
		for i in range(view.eggs.size()): view.eggs[i].visible=i<int(flock.nest)
		view.badge.text="%d OVOS • COLETAR"%int(flock.nest) if flock.nest>0 else ""
		if minf(flock.food,flock.water)<25:
			var need:="REPOR ÁGUA E RAÇÃO" if flock.food<25 and flock.water<25 else ("REPOR RAÇÃO" if flock.food<25 else "REPOR ÁGUA")
			view.badge.text+=("\n" if flock.nest>0 else "")+need
		view.badge.modulate=Color("ffe092") if flock.nest>0 else Color("9ee4ef")
		view.badge.visible=not view.badge.text.is_empty()
	for chicken in chickens:
		chicken.label.text=state.items[chicken.coop].flock.names[chicken.hen]
		chicken.label.visible=highlighted_index==chicken.coop

func paint(root: Node, item: Dictionary) -> void:
	if root is MeshInstance3D:
		for i in range(root.mesh.get_surface_count()):
			var source: Material = root.mesh.surface_get_material(i)
			if source==null: continue
			var index:=-1
			if source.resource_name.begins_with("Paint"): index=int(item.paint)
			elif source.resource_name.begins_with("Roof"): index=int(item.get("roof_paint",-1))
			elif source.resource_name.begins_with("Door"):
				index=int(item.get("door_paint",-1))
				if index<0 and item.kind=="barn": index=int(item.paint)
			if index>=0:
				var key:="%d:%d"%[source.get_instance_id(),index]
				if not paint_materials.has(key):
					var replacement: StandardMaterial3D = source.duplicate()
					replacement.albedo_color = Color(FarmState.PALETTE[index])
					paint_materials[key]=replacement
				root.set_surface_override_material(i,paint_materials[key])
	for child in root.get_children():
		paint(child,item)

func replace_crop(index: int, kind: String) -> void:
	if index<0 or index>=item_nodes.size(): return
	var root:=item_nodes[index].get_node_or_null("Crop") as Node3D
	if not root: return
	root.get_node("Young").free()
	root.get_node("Ripe").free()
	var young:=model(kind,root,Vector3(0,0.14,0))
	young.name="Young"
	_tint_model(young,material("5b953f"))
	var ripe:=model(kind,root,Vector3(0,0.14,0))
	ripe.name="Ripe"

func update_crops(state: FarmState) -> void:
	for i in range(state.items.size()):
		var item: Dictionary = state.items[i]
		if item.kind == "plot" and i < item_nodes.size():
			var node := item_nodes[i].get_node_or_null("Crop") as Node3D
			if node:
				node.visible = item.planted
				var sprout:=node.get_node("Sprout") as Node3D
				var young:=node.get_node("Young") as Node3D
				var ripe:=node.get_node("Ripe") as Node3D
				sprout.visible=item.growth<0.33
				young.visible=item.growth>=0.33 and item.growth<0.75
				ripe.visible=item.growth>=0.75
				sprout.scale=Vector3.ONE*(0.65+float(item.growth))
				young.scale=Vector3.ONE*(0.4+float(item.growth)*0.6)
				ripe.scale=Vector3.ONE*(0.6+float(item.growth)*0.4)
				var badge:=item_nodes[i].get_node("Badge") as Label3D
				badge.text=("REGAR" if not item.watered else "COLHER") if i==highlighted_index else ("•" if not item.watered else "◆")
				badge.visible=item.planted and (not item.watered or item.growth>=1)
				badge.modulate=Color("9ee4ef") if not item.watered else Color("ffe092")
				var soil := item_nodes[i].get_node("Soil") as MeshInstance3D
				soil.material_override.albedo_color = Color("594431" if item.watered else "88603c")

func _tint_model(node: Node, color: Material) -> void:
	if node is MeshInstance3D: node.material_override=color
	for child in node.get_children(): _tint_model(child,color)

func animate(delta: float, player_pos: Vector3, state: FarmState, event: String = "") -> void:
	clock += delta
	for chicken in chickens:
		var hen: Node3D = chicken.node
		var phase: float = chicken.phase
		var local:=Vector3(sin(clock*0.30+phase)*2.5,0,2.8+cos(clock*0.22+phase)*0.6)
		var resting:=sin(clock*0.55+phase)>0.35
		if chicken.hen==1 and resting: local=Vector3(-2.0,0,1.7)
		var target:Vector3=chicken.home+local.rotated(Vector3.UP,chicken.turn)
		var is_manager:bool=chicken.coop==chickens[0].coop and chicken.hen==0
		if event=="inspect" and is_manager:
			target = player_pos + Vector3(sin(clock) * 1.3, 0, cos(clock) * 1.3)
		elif event=="meeting" and chicken.coop==chickens[0].coop:
			target=chicken.home+Vector3((chicken.hen-1)*0.75,0,2.3).rotated(Vector3.UP,chicken.turn)
		var direction := target - hen.position
		direction.y = 0
		var dancing:bool=event=="dance" and is_manager
		hen.rotation.x=sin(clock*7+phase)*0.18 if resting and chicken.hen==1 else 0.0
		hen.rotation.z=sin(clock*9)*0.2 if dancing else 0.0
		hen.position.y=absf(sin(clock*9))*0.26 if dancing else 0.0
		if resting and chicken.hen==2 and event.is_empty(): continue
		if direction.length() > 0.1:
			hen.rotation.y = lerp_angle(hen.rotation.y, atan2(direction.x, direction.z), delta * 4)
			var step:=direction.normalized()*minf(direction.length(),delta*(2.0 if event=="inspect" and is_manager else 0.65))
			for angle in [0.0,PI/4,-PI/4,PI/2,-PI/2]:
				var candidate:=hen.position+step.rotated(Vector3.UP,angle)
				if _hen_walkable(candidate,state):
					hen.position.x=candidate.x
					hen.position.z=candidate.z
					break
			if not dancing: hen.position.y=abs(sin(clock*13+phase))*0.045

func _hen_walkable(at: Vector3, state: FarmState) -> bool:
	if at.x < -31 or at.x>44 or at.z < -39 or at.z>43: return false
	for item in state.items:
		if item.kind in ["plot","path"]: continue
		var rect:=state.item_rect(item.kind,Vector2(item.x,item.z),item.turn).grow(0.18)
		if rect.has_point(Vector2(at.x,at.z)): return false
	return true
