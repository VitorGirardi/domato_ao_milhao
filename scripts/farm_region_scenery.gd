class_name FarmRegionScenery
extends Node3D
## Geometry and vegetation for the authored eastern region; no save ownership.
var landscape: FarmLandscape
var world: FarmWorld
var mine_gate:CollisionShape3D
var mine_barrier:Node3D
var mine_label:Label3D
var mine_open:=false
var gallery_gates:Array[CollisionShape3D]=[]
var gallery_panels:Array[Node3D]=[]
var gallery_bounds:Array[Rect2]=[]
var gallery_level:=-1
var mine_lights:Array[OmniLight3D]=[]
const MINE_BOUND:=Rect2(892,-231,16,12)

func setup(owner_landscape: FarmLandscape, owner_world: FarmWorld) -> void:
	name = "ValeESerra"
	landscape = owner_landscape; world = owner_world
	_water()
	var waterfall:=FarmWaterfall.new();add_child(waterfall);waterfall.setup()
	_vegetation()
	_bridge()
	_lookout()
	_cave()
	for key in FarmRegion.PLACES:
		# The nearby fishing marker already labels this narrow bank.
		if key=="farm_fishing":continue
		var place: Dictionary = FarmRegion.PLACES[key]
		landscape._trail_sign(world, place.at+Vector2(5, 5), place.name.to_upper(), "53765c")
	landscape._trail_sign(world, Vector2(165, -25), "SERRA / RIO AZUL →\nLAGOS / MINA · MAPA [M]", "53765c")
	landscape._trail_sign(world, Vector2(253, 17), "SERRA: LESTE →\nLAGO: SUL ↓", "94733e")

func _water() -> void:
	var surface := SurfaceTool.new(); surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in range(-650,650,4):
		var a:=FarmRegion.river_x(z);var b:=FarmRegion.river_x(z+4)
		for x in range(-19,19,2):
			for p in [Vector2(a+x,z),Vector2(a+x+2,z),Vector2(b+x,z+4),Vector2(a+x+2,z),Vector2(b+x+2,z+4),Vector2(b+x,z+4)]:
				_water_vertex(surface,p,2)
	for i in range(FarmRegion.LAKES.size()):
		var lake:Vector4=FarmRegion.LAKES[i]
		for ring in range(20):
			var inner:=ring/20.0*1.13;var outer:=(ring+1)/20.0*1.13
			for j in range(96):
				var a:=TAU*j/96.0;var b:=TAU*(j+1)/96.0
				var center:=Vector2(lake.x,lake.y);var va:=Vector2(cos(a)*lake.z,sin(a)*lake.w);var vb:=Vector2(cos(b)*lake.z,sin(b)*lake.w)
				for p in [center+va*inner,center+vb*outer,center+va*outer,center+va*inner,center+vb*inner,center+vb*outer]:
					_water_vertex(surface,p,FarmRegion.LAKE_LEVELS[i])
	# A single connected surface: extend the lake footprint beneath the fall.
	# Only add triangles outside the existing lake ellipse to avoid z-fighting.
	for z in range(-278,-248):
		for x in range(791,829):
			for tri in [[Vector2(x,z),Vector2(x+1,z),Vector2(x,z+1)],[Vector2(x+1,z),Vector2(x+1,z+1),Vector2(x,z+1)]]:
				var center:Vector2=(tri[0]+tri[1]+tri[2])/3.0
				if FarmRegion.plunge_distance(center)>1.15:continue
				if ((center-Vector2(810,-235))/Vector2(56,38)).length()<1.13:continue
				for p in tri:_water_vertex(surface,p,68)
	surface.generate_normals()
	var water := MeshInstance3D.new(); water.name = "RioAzulELagos"; water.mesh = surface.commit()
	water.material_override = landscape.water_material; water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(water)

func _water_vertex(surface:SurfaceTool,p:Vector2,level:float) -> void:
	var depth:=maxf(0,level-FarmLandscape.ground_height(p))
	surface.set_color(Color(clampf(depth/5.0,0,1),0,0,1))
	surface.add_vertex(Vector3(p.x,level,p.y))

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
	var local_bridge:=_model("region_bridge",Vector3(FarmRegion.legacy_river_x(30),.05,30))
	local_bridge.scale=Vector3(14.0/46.0,1,.75)
	_collision(local_bridge,Vector3(0,-.3,0),Vector3(46,.6,8))
	for z in [-4.0,4.0]:_collision(local_bridge,Vector3(0,.7,z),Vector3(46,1.4,.25))

func _lookout() -> void:
	var p:Vector2=FarmRegion.PLACES.serra_view.at
	var model:=_model("region_lookout",Vector3(p.x,FarmLandscape.height_at(p),p.y))
	_collision(model,Vector3(0,-.12,0),Vector3(12,.24,10))
	for x in [-5.9,5.9]: _collision(model,Vector3(x,.7,0),Vector3(.2,1.4,10))
	_collision(model,Vector3(0,.7,-4.9),Vector3(12,1.4,.2))

func _cave() -> void:
	var p:=Vector2(900,-220)
	var model:=_model("region_mine",FarmMineLayout.ORIGIN)
	# The Blender mountain also blocks walking/camera rays outside the tunnels.
	# Keep the purchase tape separate so its collision remains removable.
	var rock_mesh:=model.find_child("MineRockAndVegetation",true,false) as MeshInstance3D
	if rock_mesh!=null:
		rock_mesh.create_trimesh_collision()
		for body in rock_mesh.get_children():
			for collision in body.get_children():
				if collision is CollisionShape3D and collision.shape is ConcavePolygonShape3D:collision.shape.backface_collision=true
	# Collision follows the authored cell union, leaving every junction open.
	for cell in FarmMineLayout.CELLS:
		for step in [Vector2(8,0),Vector2(-8,0),Vector2(0,8),Vector2(0,-8)]:
			if cell+step in FarmMineLayout.CELLS:continue
			if cell==Vector2(0,-4) and step==Vector2(0,8):continue
			var center:Vector2=cell+step*.5
			var size:=Vector3(.4,6.4,8.4) if step.x!=0 else Vector3(8.4,6.4,.4)
			landscape.solid_bounds.append(Rect2(Vector2(900+center.x-size.x/2,-220+center.y-size.z/2),Vector2(size.x,size.z)))
	for i in range(2):
		var gate_root:=Node3D.new();gate_root.position=FarmMineLayout.GATES[i];gate_root.position.y=FarmMineLayout.floor_offset(gate_root.position.z);model.add_child(gate_root)
		if i==1:gate_root.rotation.y=PI/2
		var body:=StaticBody3D.new();gate_root.add_child(body)
		var collision:=CollisionShape3D.new();var gate_shape:=BoxShape3D.new();gate_shape.size=Vector3(8,6,.4)
		collision.shape=gate_shape;collision.position.y=3;body.add_child(collision);gallery_gates.append(collision)
		var panel:=Node3D.new();gate_root.add_child(panel);gallery_panels.append(panel)
		var material:=StandardMaterial3D.new();material.albedo_color=Color("75523a")
		for x in [-3.5,-2.5,-1.5,-.5,.5,1.5,2.5,3.5]:
			var mesh:=MeshInstance3D.new();var beam:=BoxMesh.new();beam.size=Vector3(.35,5.8,.25)
			mesh.mesh=beam;mesh.position=Vector3(x,2.9,0);mesh.material_override=material;panel.add_child(mesh)
		for y in [1.0,3.8]:
			var mesh:=MeshInstance3D.new();var beam:=BoxMesh.new();beam.size=Vector3(8,.28,.35)
			mesh.mesh=beam;mesh.position.y=y;mesh.material_override=material;panel.add_child(mesh)
		var label:=Label3D.new();label.text=FarmMineLayout.TITLES[i]+"\nLIBERAR PASSAGEM · E"
		label.position=Vector3(0,2.4,.3);label.font_size=38;label.pixel_size=.009;label.outline_size=8;panel.add_child(label)
		var center:Vector3=FarmMineLayout.ORIGIN+FarmMineLayout.GATES[i]
		var extent:=Vector2(8,.4) if i==0 else Vector2(.4,8)
		gallery_bounds.append(Rect2(Vector2(center.x,center.z)-extent/2,extent))
	update_galleries(0)
	var gate:=StaticBody3D.new();model.add_child(gate)
	mine_gate=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=Vector3(7,3,.45)
	mine_gate.shape=shape;mine_gate.position=Vector3(0,1.5,.7);gate.add_child(mine_gate)
	mine_barrier=model.find_child("MineBarrier",true,false)
	landscape.solid_bounds.append(MINE_BOUND)
	mine_label=Label3D.new();mine_label.text="NÃO ENTRE";mine_label.font_size=48;mine_label.pixel_size=.009
	mine_label.position=Vector3(0,1.65,1.10);mine_label.modulate=Color("ffe6a0");mine_label.outline_size=8
	model.add_child(mine_label)
	for at in [Vector3(3.4,3.3,-4),Vector3(-3.4,3.3,-12),Vector3(-8,3.3,-23.4),Vector3(-16,3.3,-16.6),Vector3(-19.4,3.3,-36),Vector3(-8,3.3,-32.6),Vector3(8,3.3,-39.4),Vector3(16,3.3,-32.6),Vector3(19.4,3.3,-52),Vector3(8,3.3,-48.6),Vector3(3.4,3.3,-60),Vector3(-3.4,3.3,-68),Vector3(0,3.3,-76),Vector3(19.4,3.3,-84),Vector3(12,3.3,-92),Vector3(-8,3.3,-88.6),Vector3(-16,3.3,-100),Vector3(0,3.3,-100)]:
		var light:=OmniLight3D.new();light.position=at;light.position.y+=FarmMineLayout.floor_offset(at.z);light.omni_range=10
		light.light_color=Color("9bbaf4") if at.z<-56 else Color("acd5ac") if at.z<-24 else Color("ffda9e");light.light_energy=1.1;model.add_child(light)
		light.distance_fade_enabled=true;light.distance_fade_begin=70;light.distance_fade_length=20
		mine_lights.append(light)
	update_lights(Vector3.ZERO)

func update_lights(observer:Vector3) -> void:
	# Compatibility rendering has a small per-mesh light budget. Select nearby
	# lanterns for each viewer so the deepest rooms receive their own light.
	var ordered:=mine_lights.duplicate()
	ordered.sort_custom(func(a:OmniLight3D,b:OmniLight3D):return a.global_position.distance_squared_to(observer)<b.global_position.distance_squared_to(observer))
	for i in range(ordered.size()):ordered[i].visible=i<4 and ordered[i].global_position.distance_to(observer)<24

func update_galleries(level:int) -> void:
	if gallery_level==level:return
	gallery_level=level
	for i in range(gallery_gates.size()):
		var opened:=level>i
		gallery_gates[i].set_deferred("disabled",opened);gallery_panels[i].visible=not opened
		if opened:landscape.solid_bounds.erase(gallery_bounds[i])
		elif gallery_bounds[i] not in landscape.solid_bounds:landscape.solid_bounds.append(gallery_bounds[i])

func update_mine(owned:bool) -> void:
	if mine_open==owned:return
	mine_open=owned;mine_gate.set_deferred("disabled",owned)
	if is_instance_valid(mine_barrier):mine_barrier.visible=not owned
	mine_label.visible=not owned
	if owned:landscape.solid_bounds.erase(MINE_BOUND)
	elif MINE_BOUND not in landscape.solid_bounds:landscape.solid_bounds.append(MINE_BOUND)
