class_name FarmLandscape
extends Node3D
## Scenery never changes farm coordinates or saved item footprints.
const WALK_MIN:=Vector2(-34,-94)
const WALK_MAX:=Vector2(108,96)
const CLEAR:=Rect2(-33,-42,79,86) # Every legal plot plus worker clearance.
var rng:=RandomNumberGenerator.new()
var meshes:Dictionary={}
var meadow:=Node3D.new()
var decoration_points:Array[Vector2]=[]
var trunk_points:Array[Vector2]=[]
var solid_bounds:Array[Rect2]=[]
var ground:MeshInstance3D
var nature:=Node3D.new()
var scenery:Array[Dictionary]=[]
var birds:Array[Dictionary]=[]
var runtime_obstacles:Array[Rect2]=[]
var property_stamp:="unset"
var lot_labels:Dictionary={}
var water_material:ShaderMaterial
var flow_clock:=0.0

static func base_height(p:Vector2) -> float:
	var edge:=maxf(p.x-46,maxf(p.y-44,-42-p.y))
	var near_height:=smoothstep(0,22,edge)*(1.4+sin(p.x*.075)*cos(p.y*.065)*1.2)
	var distant:=smoothstep(0,44,maxf(absf(p.x)-78,absf(p.y)-78))
	var river_x:=-42+sin(p.y*.065)*2.6
	var result:=near_height+distant*smoothstep(7,25,absf(p.x-river_x))*(13+6*sin(p.x*.039+p.y*.032)+4*cos(p.y*.083-p.x*.017))
	for key in FarmParcels.LOTS:
		var lot:Rect2=FarmParcels.area(key)
		var offset:Vector2=(p-lot.get_center()).abs()-lot.size/2-Vector2.ONE*3
		result*=smoothstep(0,8,maxf(offset.x,offset.y))
	return result

static func height_at(p:Vector2) -> float:
	var river_x:=-42+sin(p.y*.065)*2.6
	var channel:=1-smoothstep(2.9,4.3,absf(p.x-river_x))
	return base_height(p)-channel*.65

static func road_distance(p:Vector2) -> float:
	var trunk:=-27+sin(p.y*.07)*smoothstep(42,66,absf(p.y))*3
	var lane:=30+sin(p.x*.09)*smoothstep(44,75,p.x)*3
	return minf(absf(p.x-trunk),absf(p.y-lane))

func setup(world:FarmWorld) -> void:
	name="ValleyLandscape";rng.seed=202020
	for key in ["oak","poplar","shrub","grass","daisy","lavender","stone","bird"]:
		var scene:PackedScene=load("res://assets/models/valley_%s.glb"%key)
		var root:=scene.instantiate()
		var mesh_node:=_find_mesh(root)
		assert(mesh_node!=null)
		meshes[key]=mesh_node.mesh
		root.free()
	_terrain()
	_river()
	add_child(nature)
	_bosques()
	_horizon(world)
	_landmarks(world)
	add_child(meadow)
	for i in range(39000):
		var p:=Vector2(rng.randf_range(-34,112),rng.randf_range(-98,100))
		if road_distance(p)<3.15 or Rect2(-27,10,7,9).has_point(p): continue
		# Islands of vegetation rather than evenly scattered dots.
		if rng.randf()<.15:continue
		decoration_points.append(p)
	refresh(FarmState.new())

func _find_mesh(node:Node) -> MeshInstance3D:
	if node is MeshInstance3D:return node
	for child in node.get_children():
		var found:=_find_mesh(child)
		if found!=null:return found
	return null

func _terrain() -> void:
	var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in range(-140,140,2):
		for x in range(-140,140,2):
			for p in [Vector2(x,z),Vector2(x+2,z),Vector2(x,z+2),Vector2(x+2,z),Vector2(x+2,z+2),Vector2(x,z+2)]:
				surface.add_vertex(Vector3(p.x,height_at(p),p.y))
	surface.generate_normals();surface.index()
	ground=MeshInstance3D.new();ground.name="ContinuousMeadow";ground.mesh=surface.commit()
	var mat:=ShaderMaterial.new();mat.shader=load("res://assets/shaders/valley_ground.gdshader")
	ground.material_override=mat;add_child(ground)
	ground.create_trimesh_collision()

func _river() -> void:
	var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(140):
		var z:float=-140+i*2;var nz:=z+2
		var x:=-42+sin(z*.065)*2.6;var nx:=-42+sin(nz*.065)*2.6
		for p in [Vector2(x-3.3,z),Vector2(x+3.3,z),Vector2(nx-3.3,nz),Vector2(x+3.3,z),Vector2(nx+3.3,nz),Vector2(nx-3.3,nz)]:
			# Water sits inside the carved channel, outside the walking bank.
			surface.add_vertex(Vector3(p.x,-.10+base_height(Vector2(-42,p.y)),p.y))
	surface.generate_normals()
	var water:=MeshInstance3D.new();water.name="LivingRiver";water.mesh=surface.commit()
	water_material=ShaderMaterial.new();water_material.shader=load("res://assets/shaders/valley_water.gdshader")
	water.material_override=water_material;add_child(water)

func _instance_batch(key:String,transforms:Array[Transform3D],parent:Node3D,far:float=0) -> void:
	if transforms.is_empty():return
	var node:=MultiMeshInstance3D.new();node.name=key.capitalize()+"Patch"
	var mm:=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.mesh=meshes[key];mm.instance_count=transforms.size()
	for i in range(transforms.size()):mm.set_instance_transform(i,transforms[i])
	node.multimesh=mm;node.visibility_range_end=far
	if key=="grass":
		var mat:=ShaderMaterial.new();mat.shader=load("res://assets/shaders/valley_grass.gdshader");node.material_override=mat
	if key in ["grass","daisy","lavender"]:node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)

func _transform(p:Vector2,s:float,angle:float) -> Transform3D:
	return Transform3D(Basis(Vector3.UP,angle).scaled(Vector3.ONE*s),Vector3(p.x,height_at(p),p.y))

func _bosques() -> void:
	var occupied:Array[Vector2]=[]
	var centers:=[Vector2(54,-36),Vector2(63,8),Vector2(39,-54),Vector2(-9,-55),Vector2(20,56),Vector2(60,56),Vector2(-12,59),Vector2(-53,-30),Vector2(-54,40),Vector2(-12,-22),Vector2(22,-18),Vector2(26,16),Vector2(-12,10),Vector2(6,3),Vector2(90,-40),Vector2(88,62),Vector2(30,86),Vector2(16,-80)]
	for center in centers:
		for i in range(22):
			var p:Vector2=center+Vector2(rng.randfn(0,7),rng.randfn(0,6))
			if road_distance(p)<4.8 or p.distance_to(Vector2(57,38))<5 or Rect2(-28,9,9,12).has_point(p):continue
			if p.distance_to(Vector2(4,-2))<4:continue
			if absf(p.x-(-42+sin(p.y*.065)*2.6))<6:continue
			var blocked:=false
			for other in occupied:
				if other.distance_to(p)<4.5:blocked=true;break
			if blocked:continue
			occupied.append(p)
			var key:="poplar" if i%4==0 else "oak"
			var scale_value:=rng.randf_range(1.5,2.1) if i%3==0 else rng.randf_range(.9,1.3)
			scenery.append({"key":key,"p":p,"scale":scale_value,"angle":rng.randf()*TAU,"radius":2.8*scale_value,"bird":key=="oak" and scale_value>1.4})
			scenery.append({"key":"shrub","p":p+Vector2(1.1,.7),"scale":1.0,"angle":rng.randf()*TAU,"radius":1.1,"bird":false})
	for i in range(85):
		var z:=rng.randf_range(-73,75);var x:=-42+sin(z*.065)*2.6
		var p:=Vector2(x+(1 if i%2==0 else -1)*rng.randf_range(4.4,6.3),z)
		var scale_value:=rng.randf_range(.3,1.1)
		scenery.append({"key":"stone","p":p,"scale":scale_value,"angle":rng.randf()*TAU,"radius":scale_value,"bird":false})

static func cleared(record:Dictionary,state:FarmState) -> bool:
	for land in state.owned_areas():
		if land.grow(float(record.radius)+.65).has_point(record.p):return true
	return false

func _refresh_nature(state:FarmState) -> void:
	var stamp:="%s:%s:%s:%s"%[state.claimed,state.center,state.land_size,state.owned_parcels]
	if stamp!=property_stamp:
		property_stamp=stamp
		for child in nature.get_children():child.free()
		birds.clear();trunk_points.clear();runtime_obstacles.clear()
		var groups:Dictionary={"oak":[],"poplar":[],"shrub":[],"stone":[]}
		for record in scenery:
			if cleared(record,state):continue
			var p:Vector2=record.p;var scale_value:float=record.scale
			groups[record.key].append(_transform(p,scale_value,record.angle))
			if record.key in ["oak","poplar"]:
				trunk_points.append(p)
				var body:=StaticBody3D.new();body.name="TreeTrunk";body.position=Vector3(p.x,height_at(p),p.y)
				var collision:=CollisionShape3D.new();var shape:=CylinderShape3D.new();shape.radius=.34*scale_value;shape.height=2.4*scale_value
				collision.position.y=shape.height/2;collision.shape=shape;body.add_child(collision);nature.add_child(body)
				if WALK_MIN.x<=p.x and p.x<=WALK_MAX.x and WALK_MIN.y<=p.y and p.y<=WALK_MAX.y:runtime_obstacles.append(Rect2(p-Vector2.ONE*(shape.radius+.4),Vector2.ONE*(shape.radius+.4)*2))
				if record.bird:_perch(record)
			elif record.key=="stone" and scale_value>.6:
				var body:=StaticBody3D.new();body.position=Vector3(p.x,height_at(p)+scale_value*.3,p.y)
				var collision:=CollisionShape3D.new();var shape:=SphereShape3D.new();shape.radius=scale_value*.65
				collision.shape=shape;body.add_child(collision);nature.add_child(body)
		for key in groups:
			var batch:Array[Transform3D]=[];batch.assign(groups[key]);_instance_batch(key,batch,nature)
	state.scenery_obstacles=runtime_obstacles.duplicate()

func _perch(record:Dictionary) -> void:
	var scale_value:float=record.scale;var p:Vector2=record.p
	var root:=Node3D.new();root.position=Vector3(p.x,height_at(p),p.y);root.rotation.y=record.angle;nature.add_child(root)
	# Exposed branch, lower than the crown so the bird is visible from the ground.
	var branch:=MeshInstance3D.new();var wood:=CylinderMesh.new();wood.top_radius=.045;wood.bottom_radius=.09;wood.height=2.7*scale_value
	branch.mesh=wood;branch.position=Vector3(1.25*scale_value,2.75*scale_value,0);branch.rotation.z=-PI/2
	var mat:=StandardMaterial3D.new();mat.albedo_color=Color("785235");branch.material_override=mat;root.add_child(branch)
	var bird:=MeshInstance3D.new();bird.mesh=meshes.bird;bird.scale=Vector3.ONE*1.9
	var home:=Vector3(2.4*scale_value,2.82*scale_value,0)
	bird.position=home;root.add_child(bird)
	birds.append({"node":bird,"home":home,"phase":birds.size()*1.73})

func _process(delta:float) -> void:
	flow_clock+=delta
	if water_material!=null:water_material.set_shader_parameter("flow_time",flow_clock)
	for bird in birds:
		var t:=flow_clock+float(bird.phase)
		var hop:=maxf(0,sin(t*2.1)) if fmod(t,7.0)<1.5 else 0.0
		bird.node.position=bird.home+Vector3(sin(t*.7)*.04,hop*.10,0)
		bird.node.rotation.y=sin(t*.65)*.55
		bird.node.rotation.x=sin(t*3.4)*.10 if fmod(t,9.0)>7 else 0

func clear_for_player(p:Vector2) -> bool:
	for trunk in trunk_points:
		if p.distance_to(trunk)<.95:return false
	for area in solid_bounds:
		if area.grow(.4).has_point(p):return false
	return true

func refresh(state:FarmState) -> void:
	_refresh_nature(state)
	for key in lot_labels:lot_labels[key].text=FarmParcels.LOTS[key].name+("\nSEU TERRENO" if key in state.owned_parcels else "\nÀ VENDA · [T]")
	for child in meadow.get_children():child.free()
	var groups:Dictionary={"grass":[],"daisy":[],"lavender":[]}
	# Rasterize footprints once. Avoid testing every blade against every building.
	var occupied:Dictionary={}
	for item in state.items:
		var area:=state.item_rect(item.kind,Vector2(item.x,item.z),item.turn).grow(.65)
		for z in range(floori(area.position.y),ceili(area.end.y)):
			for x in range(floori(area.position.x),ceili(area.end.x)):occupied[Vector2i(x,z)]=true
	for i in range(decoration_points.size()):
		var p:=decoration_points[i]
		if occupied.has(Vector2i(floori(p.x),floori(p.y))):continue
		var owned:=false
		for land in state.owned_areas():
			if land.grow(.4).has_point(p):owned=true;break
		if owned:continue
		var key:="grass" if i%43!=0 else ("daisy" if i%2==0 else "lavender")
		var scale_value:=.65+fmod(float(i)*.371,.65)
		if key!="grass":scale_value*=.65
		groups[key].append(_transform(p,scale_value,fmod(i*2.39,TAU)))
	for key in groups:
		# Chunk grass for distance culling: the whole meadow need not render at once.
		var chunks:Dictionary={}
		for transform in groups[key]:
			var cell:=Vector2i(floori(transform.origin.x/16),floori(transform.origin.z/16))
			if not chunks.has(cell):chunks[cell]=[]
			chunks[cell].append(transform)
		for chunk in chunks.values():
			var batch:Array[Transform3D]=[];batch.assign(chunk);_instance_batch(key,batch,meadow,65)

func _horizon(world:FarmWorld) -> void:
	# Irregular ridgelines instead of a necklace of identical spheres.
	for ring in range(2):
		var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in range(96):
			var a:=i*TAU/96;var b:=(i+1)*TAU/96;var radius:float=167+ring*48
			var h1:=20+ring*8+sin(a*5+ring)*6+cos(a*9)*3
			var h2:=20+ring*8+sin(b*5+ring)*6+cos(b*9)*3
			var p1:=Vector3(sin(a)*radius,h1,cos(a)*radius)
			var p2:=Vector3(sin(b)*radius,h2,cos(b)*radius)
			var base1:=Vector3(sin(a)*(radius-35),-4,cos(a)*(radius-35))
			var base2:=Vector3(sin(b)*(radius-35),-4,cos(b)*(radius-35))
			for v in [base1,p1,base2,p1,p2,base2]:surface.add_vertex(v)
		surface.generate_normals();surface.index()
		var ridge:=MeshInstance3D.new();ridge.mesh=surface.commit()
		var mat:=world.material("677f72" if ring==1 else "61734b");mat.cull_mode=BaseMaterial3D.CULL_DISABLED
		ridge.material_override=mat;add_child(ridge)

func _landmarks(world:FarmWorld) -> void:
	for key in FarmParcels.LOTS:
		var land:=FarmParcels.area(key)
		var text:=Label3D.new();text.position=Vector3(land.get_center().x,1.8,land.end.y+2)
		text.font_size=36;text.pixel_size=.018;text.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		text.modulate=Color("ffedb3");text.outline_modulate=Color("304b32");add_child(text);lot_labels[key]=text
	# A shaded rest stop at the east trail; no decorative object on buildable land.
	var root:=Node3D.new();root.name="EastRestStop";root.position=Vector3(57,height_at(Vector2(57,38)),38);add_child(root)
	var wood:=world.material("92704b");var trim:=world.material("e1c995")
	world.box(root,Vector3(0,.60,0),Vector3(2.8,.16,.65),wood)
	world.box(root,Vector3(0,1.0,.30),Vector3(2.8,.48,.13),wood)
	for x in [-1.05,1.05]:world.box(root,Vector3(x,.3,0),Vector3(.16,.6,.52),trim)
	solid_bounds.append(Rect2(55.6,37.6,2.8,.8))
	var body:=StaticBody3D.new();var collider:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=Vector3(2.8,1.25,.8)
	collider.shape=shape;collider.position.y=.625;body.add_child(collider);root.add_child(body)
	# Road signs make the expanded playable outskirts understandable.
	for entry in [[Vector2(-30,46),"ARMAZÉM ↑",0.0],[Vector2(49,26),"BOSQUE →",0.0],[Vector2(-30,-46),"VALE DO IPÊ",0.0]]:
		var p:Vector2=entry[0];var sign_root:=Node3D.new();sign_root.position=Vector3(p.x,height_at(p),p.y);add_child(sign_root)
		world.box(sign_root,Vector3(0,.65,0),Vector3(.12,1.3,.12),wood)
		world.box(sign_root,Vector3(0,1.35,0),Vector3(2.4,.55,.12),wood)
		var text:=Label3D.new();text.text=entry[1];text.position=Vector3(0,1.35,.07);text.font_size=36;text.pixel_size=.009;text.modulate=Color("fff0cd");text.outline_size=0;sign_root.add_child(text)
