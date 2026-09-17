class_name FarmIrrigationMotion
extends RefCounted

var route:=FarmStaffMotion.new()
var plot:=-1
var watering:=false

func reset() -> void:
	plot=-1
	watering=false
	route.reset(0)

func update(world:FarmWorld,state:FarmState,delta:float) -> void:
	delta=minf(delta,0.1)
	var actor:=world.staff_actor
	var node:=world.staff_root
	if state.staff.paused: return
	if watering:
		actor.animate(delta,false,false,false)
		world.staff_label.text="ZECA • REGANDO"
		if actor.action_time<=0:
			state.irrigate(plot) # Recheck funds and dryness at completion; never charge twice.
			world.update_crops(state)
			watering=false
			plot=-1
		return
	if plot<0:
		var best:=INF
		for index in state.irrigation.plots:
			var item:Dictionary=state.items[int(index)]
			if not item.planted or item.watered or item.growth>=1: continue
			var distance:=node.position.distance_to(Vector3(item.x,0,item.z))
			if distance<best: best=distance; plot=int(index)
		if plot<0:
			world.staff_label.text="ZECA • CANTEIROS EM DIA"
			actor.animate(delta,false,false,false)
			return
		var item:Dictionary=state.items[plot]
		for offset in [Vector3(0,0,1.6),Vector3(1.6,0,0),Vector3(0,0,-1.6),Vector3(-1.6,0,0)]:
			route.plan(node.position,Vector3(item.x,0,item.z)+offset,state)
			if not route.blocked: break
		if route.blocked:
			state.staff.paused=true
			state.staff.reason="manual"
			state.staff_notice="Zeca pausou: caminho bloqueado até o canteiro. Libere a passagem e retome em H."
			world.staff_label.text="ZECA • CAMINHO BLOQUEADO"
			plot=-1
			return
	var item:Dictionary=state.items[plot]
	if item.watered or not item.planted or item.growth>=1:
		plot=-1
		return
	var moving:=false
	var remaining:=delta*1.6
	while not route.path.is_empty() and remaining>0:
		var direction:=route.path[0]-node.position
		direction.y=0
		if direction.length()<0.04: route.path.remove_at(0); continue
		var step:=minf(remaining,direction.length())
		var next:=node.position+direction.normalized()*step
		if not route.walkable(next,state):
			plot=-1
			return
		node.position=next
		node.rotation.y=lerp_angle(node.rotation.y,atan2(direction.x,direction.z),minf(delta*8,1))
		remaining-=step
		moving=true
	world.staff_label.text="ZECA • INDO REGAR"
	actor.animate(delta,moving,false,false)
	if node.position.distance_to(route.target)<0.16:
		if state.money<2:
			state.irrigate(plot) # Pauses and reports insufficient funds without altering crop.
			return
		var at:=Vector3(item.x,0,item.z)
		var face:=at-node.position
		node.rotation.y=atan2(face.x,face.z)
		actor.play("water")
		actor.animate(0.001,false,false,false)
		watering=true
		world.irrigation_feedback.water(at,actor.can.global_position,false,"",actor.can)
