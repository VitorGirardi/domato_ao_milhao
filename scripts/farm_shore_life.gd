class_name FarmShoreLife
extends Node3D
## Cosmetic wildlife, bounded pools and fixed seed; never modifies saved land.
var plants:Array[Node3D]=[]
var lilies:Array[Node3D]=[]
var fish:Array[Dictionary]=[]
var clock:=0.0
var scenes:Dictionary={}

func setup() -> void:
	name="ShoreLife"
	for key in ["reeds","lilies","bank_stones"]:
		scenes[key]=load("res://assets/models/lake_%s.glb"%key)
	# Leave the fishing approach, swimming crossing and bridge completely open.
	for z in [-24.0,-18.0,-9.0,-3.0,3.0,40.0,47.0,54.0]:
		for side in [-1.0,1.0]:
			if side>0 and absf(z+15)<6:continue
			var p:=Vector2(FarmRegion.legacy_river_x(z)+side*4.3,z)
			_place("reeds",p,.8+float(plants.size()%3)*.13)
			_place("bank_stones",p+Vector2(side*1.5,1.6),.75)
	for z in [-12.0,0.0,18.0,39.0,48.0]:
		_place("lilies",Vector2(FarmRegion.legacy_river_x(z)-2.5,z),.8)
	for i in 14:
		var angle:=TAU*float(i)/14.0
		var p:=Vector2(285,260)+Vector2(cos(angle)*48,sin(angle)*32)*1.03
		if p.distance_to(Vector2(280,295))<10:continue
		_place("reeds",p,1.05)
		_place("bank_stones",p+Vector2(cos(angle),sin(angle))*2.0,.95)
		_place("lilies",Vector2(285,260)+Vector2(cos(angle)*48,sin(angle)*32)*.78,1.1)
	for i in 12:
		var z:float=-10+(i/3)*14
		_add_fish(Vector3(FarmRegion.legacy_river_x(z),-.35,z),i,Vector2(1.5,3.0))
	for i in 12:
		_add_fish(Vector3(279+float(i%3)*2.2,4.7,282-float(i/3)*3.0),i+12,Vector2(3,2))

func _place(key:String,p:Vector2,size:float) -> void:
	var level:=FarmRegion.water_level(p)
	var ground:=FarmLandscape.ground_height(p)
	if key=="lilies" and (level==-INF or level-ground<.25):return
	var node:Node3D=scenes[key].instantiate();add_child(node)
	node.position=Vector3(p.x,level+.04 if key=="lilies" else ground-.06,p.y)
	node.scale=Vector3.ONE*size;node.rotation.y=float(get_child_count())*2.399
	if key=="reeds":plants.append(node)
	if key=="lilies":lilies.append(node);node.set_meta("water_y",node.position.y)
	# Low rocks have matching solid footprints; plants never block swimming.
	if key=="bank_stones":
		var body:=StaticBody3D.new();node.add_child(body)
		for center in [Vector3(-.30,.04,0),Vector3(.22,.04,-.16)]:
			var collider:=CollisionShape3D.new();var shape:=SphereShape3D.new()
			shape.radius=.30;collider.shape=shape;collider.position=center
			body.add_child(collider)

func _add_fish(home:Vector3,index:int,radius:Vector2) -> void:
	var node:Node3D=load("res://assets/models/resource_fish.glb").instantiate()
	node.scale=Vector3.ONE*(.8+float(index%3)*.15);add_child(node)
	fish.append({"node":node,"home":home,"phase":index*2.399,"radius":radius})
	_animate_fish(fish.back(),0)

func _animate_fish(record:Dictionary,time:float) -> void:
	var t:float=time*.45+float(record.phase)
	var radius:Vector2=record.radius
	var at:Vector3=record.home+Vector3(sin(t)*radius.x,sin(t*2)*.06,cos(t)*radius.y)
	var p:=Vector2(at.x,at.z);var level:=FarmRegion.water_level(p)
	var floor_y:=FarmLandscape.ground_height(p)
	record.node.visible=level!=-INF and level-floor_y>.5
	at.y=level-.22+sin(t*2)*.04 if level!=-INF else floor_y
	record.node.position=at
	# The Blender fish faces +X.
	record.node.rotation.y=atan2(sin(t)*radius.y,cos(t)*radius.x)
	record.node.rotation.z=sin(time*5+float(record.phase))*.045

func _process(delta:float) -> void:
	clock+=delta
	var camera:=get_viewport().get_camera_3d()
	if camera==null:return
	for i in plants.size():
		var node:=plants[i]
		node.visible=camera.global_position.distance_squared_to(node.global_position)<180*180
		if node.visible:node.rotation.z=sin(clock*1.4+i)*.025
	for i in lilies.size():
		var node:=lilies[i]
		node.visible=camera.global_position.distance_squared_to(node.global_position)<140*140
		if node.visible:node.position.y=float(node.get_meta("water_y"))+sin(clock*1.8+i)*.018
	for record in fish:
		if camera.global_position.distance_squared_to(record.home)>75*75:
			record.node.visible=false;continue
		_animate_fish(record,clock)
