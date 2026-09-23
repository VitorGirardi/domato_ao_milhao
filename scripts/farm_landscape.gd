class_name FarmLandscape
extends Node3D
## Scenery never changes farm coordinates or saved item footprints.
const WALK_MIN:=Vector2(-34,-62)
const WALK_MAX:=Vector2(70,66)
const CLEAR:=Rect2(-33,-42,79,86) # Every legal plot plus worker clearance.
var rng:=RandomNumberGenerator.new()
var meshes:Dictionary={}
var meadow:=Node3D.new()
var decoration_points:Array[Vector2]=[]
var trunk_points:Array[Vector2]=[]
var solid_bounds:Array[Rect2]=[]
var ground:MeshInstance3D

static func base_height(p:Vector2) -> float:
	var edge:=maxf(p.x-46,maxf(p.y-44,-42-p.y))
	var near_height:=smoothstep(0,22,edge)*(1.4+sin(p.x*.075)*cos(p.y*.065)*1.2)
	var distant:=smoothstep(0,44,maxf(absf(p.x)-78,absf(p.y)-78))
	var river_x:=-42+sin(p.y*.065)*2.6
	return near_height+distant*smoothstep(7,25,absf(p.x-river_x))*(13+6*sin(p.x*.039+p.y*.032)+4*cos(p.y*.083-p.x*.017))

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
	for key in ["oak","poplar","shrub","grass","daisy","lavender","stone"]:
		var scene:PackedScene=load("res://assets/models/valley_%s.glb"%key)
		var root:=scene.instantiate()
		var mesh_node:=_find_mesh(root)
		assert(mesh_node!=null)
		meshes[key]=mesh_node.mesh
		root.free()
	_terrain()
	_river()
	_bosques()
	_horizon(world)
	_landmarks(world)
	add_child(meadow)
	for i in range(7200):
		var p:=Vector2(rng.randf_range(-34,76),rng.randf_range(-66,72))
		if road_distance(p)<3.15 or Rect2(-27,10,7,9).has_point(p): continue
		# Islands of vegetation rather than evenly scattered dots.
		if sin(p.x*.24+cos(p.y*.18))*cos(p.y*.27)<-.05: continue
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
	var mat:=ShaderMaterial.new();mat.shader=load("res://assets/shaders/valley_water.gdshader")
	water.material_override=mat;add_child(water)

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
	var groups:Dictionary={"oak":[],"poplar":[],"shrub":[],"stone":[]}
	# Woodland clearings, orchard edge and riverside groves.
	var centers:=[Vector2(54,-36),Vector2(63,8),Vector2(39,-54),Vector2(-9,-55),Vector2(20,56),Vector2(60,56),Vector2(-12,59),Vector2(-53,-30),Vector2(-54,40)]
	for center in centers:
		for i in range(25):
			var p:Vector2=center+Vector2(rng.randfn(0,7),rng.randfn(0,6))
			if CLEAR.grow(1.5).has_point(p) or road_distance(p)<4.5 or p.distance_to(Vector2(57,38))<5:continue
			if absf(p.x-(-42+sin(p.y*.065)*2.6))<6:continue
			var occupied:=false
			for other in trunk_points:
				if other.distance_to(p)<2.8:occupied=true;break
			if occupied:continue
			trunk_points.append(p)
			var key:="poplar" if i%4==0 else "oak"
			var s:=rng.randf_range(.8,1.4)
			groups[key].append(_transform(p,s,rng.randf()*TAU))
			_trunk_collision(p,.34*s)
			groups.shrub.append(_transform(p+Vector2(1.1,.7),rng.randf_range(.7,1.3),rng.randf()*TAU))
	for i in range(85):
		var z:=rng.randf_range(-73,75);var x:=-42+sin(z*.065)*2.6
		var p:=Vector2(x+(1 if i%2==0 else -1)*rng.randf_range(4.4,6.3),z)
		var stone_scale:=rng.randf_range(.3,1.1)
		groups.stone.append(_transform(p,stone_scale,rng.randf()*TAU))
		if p.x>=WALK_MIN.x-1 and stone_scale>.6:
			var body:=StaticBody3D.new();body.position=Vector3(p.x,height_at(p)+stone_scale*.3,p.y)
			var collision:=CollisionShape3D.new();var shape:=SphereShape3D.new();shape.radius=stone_scale*.65
			collision.shape=shape;body.add_child(collision);add_child(body)
			solid_bounds.append(Rect2(p-Vector2.ONE*stone_scale*.7,Vector2.ONE*stone_scale*1.4))
	for key in groups:
		var batch:Array[Transform3D]=[];batch.assign(groups[key]);_instance_batch(key,batch,self)

func _trunk_collision(p:Vector2,radius:float) -> void:
	var body:=StaticBody3D.new();body.name="TreeTrunk";body.position=Vector3(p.x,height_at(p)+1.2,p.y)
	var collision:=CollisionShape3D.new();var shape:=CylinderShape3D.new();shape.radius=radius;shape.height=2.4
	collision.shape=shape;body.add_child(collision);add_child(body)

func clear_for_player(p:Vector2) -> bool:
	for trunk in trunk_points:
		if p.distance_to(trunk)<.95:return false
	for area in solid_bounds:
		if area.grow(.4).has_point(p):return false
	return true

func refresh(state:FarmState) -> void:
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
		var key:="grass" if i%7!=0 else ("daisy" if i%2==0 else "lavender")
		var scale_value:=.65+fmod(float(i)*.371,.65)
		if key!="grass":scale_value*=.65
		groups[key].append(_transform(p,scale_value,fmod(i*2.39,TAU)))
	for key in groups:
		var batch:Array[Transform3D]=[];batch.assign(groups[key]);_instance_batch(key,batch,meadow)

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
