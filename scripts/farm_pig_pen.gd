class_name FarmPigPen
extends RefCounted
const HOMES:=[Vector3(1.05,-.015,.2),Vector3(-1.72,.015,.93),Vector3(-1.66,.06,-1.30)]

static func collider(parent:Node3D,index:int,at:Vector3,size:Vector3) -> StaticBody3D:
	var body:=StaticBody3D.new();body.set_meta("item_index",index);parent.add_child(body)
	var shape:=CollisionShape3D.new();var volume:=BoxShape3D.new();volume.size=size
	shape.shape=volume;shape.position=at;body.add_child(shape)
	return body

static func setup(root:Node3D,visual:Node3D,index:int) -> Dictionary:
	# Closed enclosure: care is performed from outside. Reserve the gate for a
	# later enter/exit interaction instead of letting pigs escape through it.
	for wall in [[Vector3(0,.55,2.7),Vector3(7.6,1.1,.2)],
		[Vector3(0,.55,-2.7),Vector3(7.6,1.1,.2)],
		[Vector3(-3.7,.55,0),Vector3(.2,1.1,5.4)],[Vector3(3.7,.55,0),Vector3(.2,1.1,5.4)],
		[Vector3(-1.66,1.15,-1.45),Vector3(3.2,2.3,1.9)],
		[Vector3(2.6,.23,-1.56),Vector3(1.7,.46,.9)],
		[Vector3(2.8,.23,1.37),Vector3(1.25,.46,.85)]]:
		collider(root,index,wall[0],wall[1])
	var result:Dictionary={"node":visual,"index":index,"pigs":[],"food":visual.find_child("FeedFill",true,false),"water":visual.find_child("WaterFill",true,false),"clock":index*1.31}
	for slot in range(FarmPigs.CAPACITY):
		var pig:Node3D=load("res://assets/models/pig.glb").instantiate();pig.name="Pig%d"%slot;root.add_child(pig)
		pig.position=HOMES[slot];pig.set_meta("item_index",index)
		var body:=collider(pig,index,Vector3(0,.55,0),Vector3(.8,1.1,1.45))
		result.pigs.append({"node":pig,"body":body,"slot":slot})
	return result

static func update(pen:Dictionary,data:Dictionary) -> void:
	for part in ["food","water"]:
		var fill:Node3D=pen[part];fill.visible=data[part]>0
		fill.scale.y=maxf(.01,float(data[part])/100.0)
	for pig in pen.pigs:
		pig.node.visible=pig.slot<int(data.count)
		pig.body.collision_layer=1 if pig.node.visible else 0

static func animate(pen:Dictionary,delta:float,player:Vector3) -> void:
	if delta<=0:return
	pen.clock+=delta
	for entry in pen.pigs:
		var pig:Node3D=entry.node
		if not pig.visible:continue
		var time:float=pen.clock+entry.slot*2.1
		var walking:bool=entry.slot==0 and fposmod(time,12.0)>6.0
		if walking and pig.global_position.distance_to(player)>1.6:
			var target:Vector3=HOMES[0]+Vector3(.15*sin(time*.4),0,-.20*absf(sin(time*.4)))
			var direction:=target-pig.position
			walking=direction.length()>.04
			if walking:
				pig.position=pig.position.move_toward(target,delta*.25)
				pig.rotation.y=rotate_toward(pig.rotation.y,atan2(direction.x,direction.z),delta*.8)
		else:walking=false
		FarmLivestockPose.pig(pig,time,walking)
