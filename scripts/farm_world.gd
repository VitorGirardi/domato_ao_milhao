class_name FarmWorld
extends Node3D

var models: Dictionary = {}
var structures := Node3D.new()
var border := Node3D.new()
var item_nodes: Array[Node3D] = []
var chickens: Array[Dictionary] = []
var farmer: Node3D
var clock: float = 0.0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.seed = 24517
	for key in ["barn", "coop", "fence", "sign", "tree", "rock", "chicken", "farmer", "market", "carrot", "wheat", "corn", "flower"]:
		models[key] = load("res://assets/models/%s.glb" % key)
	add_child(structures)
	add_child(border)
	_environment()
	_landscape()

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
		return
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
			var crop_node := model(item.crop, root)
			crop_node.name = "Crop"
		elif item.kind == "path":
			box(root, Vector3(0,0.025,0), Vector3(1.98,0.05,1.98), material("c2a574"))
		else:
			var visual := model(item.kind, root)
			paint(visual, Color(FarmState.PALETTE[int(item.paint)]))
			if item.kind in ["barn", "coop", "fence", "sign"]:
				var body := StaticBody3D.new()
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
				for c in range(3):
					var hen := model("chicken", structures, Vector3(item.x + c - 1, 0, item.z + 2.4))
					chickens.append({"node": hen, "home": Vector3(item.x, 0, item.z), "phase": i * 2.0 + c * 2.1})
	update_crops(state)
	update_border(state)

func paint(root: Node, color: Color) -> void:
	if root is MeshInstance3D:
		for i in range(root.mesh.get_surface_count()):
			var source: Material = root.mesh.surface_get_material(i)
			if source != null and source.resource_name.begins_with("Paint"):
				var replacement: StandardMaterial3D = source.duplicate()
				replacement.albedo_color = color
				root.set_surface_override_material(i, replacement)
	for child in root.get_children():
		paint(child, color)

func update_crops(state: FarmState) -> void:
	for i in range(state.items.size()):
		var item: Dictionary = state.items[i]
		if item.kind == "plot" and i < item_nodes.size():
			var node := item_nodes[i].get_node_or_null("Crop") as Node3D
			if node:
				node.visible = item.planted
				node.scale = Vector3.ONE * (0.16 + float(item.growth) * 0.84)
				var soil := item_nodes[i].get_node("Soil") as MeshInstance3D
				soil.material_override.albedo_color = Color("594431" if item.watered else "88603c")

func animate(delta: float, player_pos: Vector3, silly: bool) -> void:
	clock += delta
	for chicken in chickens:
		var hen: Node3D = chicken.node
		var phase: float = chicken.phase
		var target: Vector3 = chicken.home + Vector3(sin(clock * 0.42 + phase) * 2.5, 0, 2.8 + cos(clock * 0.32 + phase) * 1.3)
		if silly and phase == chickens[0].phase:
			target = player_pos + Vector3(sin(clock) * 1.3, 0, cos(clock) * 1.3)
		var direction := target - hen.position
		direction.y = 0
		if direction.length() > 0.1:
			hen.rotation.y = lerp_angle(hen.rotation.y, atan2(direction.x, direction.z), delta * 4)
			hen.position += direction.normalized() * minf(direction.length(), delta * (2.8 if silly else 0.7))
			hen.position.y = abs(sin(clock * 13 + phase)) * 0.045
