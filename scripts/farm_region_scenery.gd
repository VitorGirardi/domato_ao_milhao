class_name FarmRegionScenery
extends Node3D
## Geometry and vegetation for the authored eastern region; no save ownership.
var landscape: FarmLandscape
var world: FarmWorld

func setup(owner_landscape: FarmLandscape, owner_world: FarmWorld) -> void:
	name = "ValeESerra"
	landscape = owner_landscape; world = owner_world
	_water()
	_vegetation()
	_bridge()
	_lookout()
	_cave()
	for key in FarmRegion.PLACES:
		var place: Dictionary = FarmRegion.PLACES[key]
		landscape._trail_sign(world, place.at+Vector2(5, 5), place.name.to_upper(), "53765c")
	landscape._trail_sign(world, Vector2(165, -25), "SERRA / RIO AZUL →\nLAGOS / MINA · MAPA [M]", "53765c")
	landscape._trail_sign(world, Vector2(253, 17), "SERRA: LESTE →\nLAGO: SUL ↓", "94733e")

func _water() -> void:
	var surface := SurfaceTool.new(); surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in range(-650, 650, 4):
		var a := FarmRegion.river_x(z); var b := FarmRegion.river_x(z+4)
		for p in [Vector2(a-19,z),Vector2(a+19,z),Vector2(b-19,z+4),Vector2(a+19,z),Vector2(b+19,z+4),Vector2(b-19,z+4)]:
			surface.add_vertex(Vector3(p.x, 2, p.y))
	for i in range(FarmRegion.LAKES.size()):
		var lake: Vector4 = FarmRegion.LAKES[i]
		for j in range(96):
			var a := TAU*j/96.0; var b := TAU*(j+1)/96.0
			for p in [Vector2(lake.x,lake.y),Vector2(lake.x+cos(b)*lake.z*1.13,lake.y+sin(b)*lake.w*1.13),Vector2(lake.x+cos(a)*lake.z*1.13,lake.y+sin(a)*lake.w*1.13)]:
				surface.add_vertex(Vector3(p.x,FarmRegion.LAKE_LEVELS[i],p.y))
	surface.generate_normals()
	var water := MeshInstance3D.new(); water.name = "RioAzulELagos"; water.mesh = surface.commit()
	water.material_override = landscape.water_material; water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(water)

func _vegetation() -> void:
	var random := RandomNumberGenerator.new(); random.seed = 360036
	var batches: Dictionary = {}
	var trunks := StaticBody3D.new(); trunks.name = "TroncosDaSerra"; add_child(trunks)
	for i in range(14500):
		var p := Vector2(random.randf_range(-28, 1100), random.randf_range(-570, 570))
		if FarmRegion.weight(p) < .98 or FarmRegion.reserved(p): continue
		var forest := sin(p.x*.034)*cos(p.y*.024) + sin(p.y*.013+p.x*.019)
		var is_tree := i < 5000 and forest > -.15
		var key := ("poplar" if i%5==0 else "oak") if is_tree else ("shrub" if i%4==0 else "stone")
		if not is_tree and i%3!=0: continue
		var s := random.randf_range(1.0,2.0) if is_tree else random.randf_range(.45,1.1)
		var cell := Vector2i(floori(p.x/96), floori(p.y/96))
		var batch_key := "%s_%d_%d"%[key,cell.x,cell.y]
		if not batches.has(batch_key): batches[batch_key] = {"key":key,"transforms":[]}
		batches[batch_key].transforms.append(landscape._transform(p,s,random.randf()*TAU))
		if is_tree and Rect2(FarmRegion.MIN,FarmRegion.MAX-FarmRegion.MIN).has_point(p):
			var collision := CollisionShape3D.new(); var shape := CylinderShape3D.new()
			shape.radius = .30*s; shape.height = 3*s; collision.shape = shape
			collision.position = Vector3(p.x,FarmLandscape.height_at(p)+1.5*s,p.y); trunks.add_child(collision)
			landscape.solid_bounds.append(Rect2(p-Vector2.ONE*.35*s,Vector2.ONE*.7*s))
	for batch in batches.values():
		var transforms: Array[Transform3D] = []; transforms.assign(batch.transforms)
		landscape._instance_batch(batch.key,transforms,self,950 if batch.key in ["oak","poplar"] else 230)
	# Local patches keep close ground alive without drawing every blade in the valley.
	var grass_chunks: Dictionary = {}
	for i in range(26000):
		var p := Vector2(random.randf_range(182,1040),random.randf_range(-440,440))
		if FarmRegion.reserved(p): continue
		var cell := Vector2i(floori(p.x/32),floori(p.y/32))
		if not grass_chunks.has(cell): grass_chunks[cell] = []
		grass_chunks[cell].append(landscape._transform(p,random.randf_range(.8,1.4),random.randf()*TAU))
	for chunk in grass_chunks.values():
		var transforms: Array[Transform3D] = []; transforms.assign(chunk)
		landscape._instance_batch("grass",transforms,self,95)

func _model(asset: String, at: Vector3) -> Node3D:
	var model: Node3D=load("res://assets/models/"+asset+".glb").instantiate()
	model.position=at; add_child(model); return model

func _collision(parent: Node3D, pos: Vector3, size: Vector3) -> void:
	var body:=StaticBody3D.new(); var collision:=CollisionShape3D.new(); var shape:=BoxShape3D.new()
	shape.size=size; collision.shape=shape; collision.position=pos
	body.add_child(collision); parent.add_child(body)

func _bridge() -> void:
	var model:=_model("region_bridge",Vector3(420,5,0))
	_collision(model,Vector3(0,-.3,0),Vector3(46,.6,8))
	for z in [-4.0,4.0]: _collision(model,Vector3(0,.7,z),Vector3(46,1.4,.25))

func _lookout() -> void:
	var p:Vector2=FarmRegion.PLACES.serra_view.at
	var model:=_model("region_lookout",Vector3(p.x,FarmLandscape.height_at(p),p.y))
	_collision(model,Vector3(0,-.12,0),Vector3(12,.24,10))
	for x in [-5.9,5.9]: _collision(model,Vector3(x,.7,0),Vector3(.2,1.4,10))
	_collision(model,Vector3(0,.7,-4.9),Vector3(12,1.4,.2))

func _cave() -> void:
	var p:Vector2=FarmRegion.PLACES.serra_mine.at
	var model:=_model("region_mine",Vector3(p.x,FarmLandscape.height_at(p),p.y))
	# Broad closed collision until mining/purchase is delivered; barrier is separate in the GLB.
	_collision(model,Vector3(0,4,-5),Vector3(16,8,12))
	landscape.solid_bounds.append(Rect2(p+Vector2(-8,-11),Vector2(16,12)))
	var label:=Label3D.new(); label.text="NÃO ENTRE"; label.font_size=48; label.pixel_size=.009
	label.position=Vector3(0,1.65,1.10); label.modulate=Color("ffe6a0"); label.outline_size=8
	model.add_child(label)
