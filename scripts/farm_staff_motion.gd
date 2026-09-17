class_name FarmStaffMotion
extends RefCounted
## Presentation of the caretaker's existing service ledger; no extra charges.

var path:PackedVector3Array=[]
var target:=Vector3.INF
var pending_service:=false
var pending_eggs:=false
var collecting:=false
var blocked:=false
var last_eggs:=0

func reset(eggs:int) -> void:
	path.clear()
	target=Vector3.INF
	pending_service=false
	collecting=false
	blocked=false
	last_eggs=eggs

func walkable(at:Vector3,state:FarmState) -> bool:
	if at.x< -30 or at.x>43 or at.z< -38 or at.z>42: return false
	for item in state.items:
		if item.kind in ["plot","path"]: continue
		if state.item_rect(item.kind,Vector2(item.x,item.z),item.turn).grow(0.48).has_point(Vector2(at.x,at.z)): return false
	return true

func plan(start:Vector3,finish:Vector3,state:FarmState) -> void:
	path.clear()
	target=finish
	var cell:=0.5
	var lower:=Vector2i(floori(minf(start.x,finish.x)/cell)-14,floori(minf(start.z,finish.z)/cell)-14)
	var upper:=Vector2i(ceili(maxf(start.x,finish.x)/cell)+14,ceili(maxf(start.z,finish.z)/cell)+14)
	var grid:=AStarGrid2D.new()
	grid.region=Rect2i(lower,upper-lower+Vector2i.ONE)
	grid.cell_size=Vector2.ONE*cell
	grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	for x in range(lower.x,upper.x+1):
		for z in range(lower.y,upper.y+1):
			grid.set_point_solid(Vector2i(x,z),not walkable(Vector3(x*cell,0,z*cell),state))
	var from:=Vector2i(roundi(start.x/cell),roundi(start.z/cell))
	var to:=Vector2i(roundi(finish.x/cell),roundi(finish.z/cell))
	if grid.is_point_solid(from) or grid.is_point_solid(to):
		blocked=true
		return
	for point in grid.get_point_path(from,to): path.append(Vector3(point.x,0,point.y))
	blocked=path.is_empty()
	if not blocked and walkable(finish,state): path.append(finish)

func update(world:FarmWorld,state:FarmState,delta:float) -> void:
	delta=minf(delta,0.1)
	var worker:Dictionary=state.staff
	var actor:=world.staff_actor
	var node:=world.staff_root
	if worker.paused:
		actor.animate(delta,false,false,false)
		return
	if collecting:
		actor.animate(delta,false,false,false)
		world.staff_label.text="ZECA • RECOLHENDO OVOS" if pending_eggs else "ZECA • CONFERINDO O TRATO"
		if actor.action_time<=0: collecting=false
		return
	var item:Dictionary=state.items[int(worker.coop)]
	var origin:=Vector3(item.x,0,item.z)
	var turn:float=item.turn*PI/2
	var visit_nest:bool=pending_service or worker.timer>=8.0
	var local:=Vector3(1.25,0,2.6) if visit_nest else (Vector3(-3.0,0,3.0) if worker.timer<4 else Vector3(3.0,0,3.0))
	var destination:=origin+local.rotated(Vector3.UP,turn)
	if target.distance_to(destination)>0.1: plan(node.position,destination,state)
	var moving:=false
	var remaining:=minf(delta,0.1)*1.6
	while not path.is_empty() and remaining>0:
		var direction:=path[0]-node.position
		direction.y=0
		if direction.length()<0.04:
			path.remove_at(0)
			continue
		var step:=minf(remaining,direction.length())
		var candidate:=node.position+direction.normalized()*step
		if not walkable(candidate,state):
			path.clear(); blocked=true
			break
		node.position=candidate
		node.rotation.y=lerp_angle(node.rotation.y,atan2(direction.x,direction.z),minf(delta*8,1))
		remaining-=step
		moving=true
	world.staff_label.text="ZECA • CAMINHO BLOQUEADO" if blocked else ("ZECA • INDO AO NINHO" if visit_nest else "ZECA • RONDA DO GALINHEIRO")
	if visit_nest and node.position.distance_to(destination)<0.16:
		world.staff_label.text="ZECA • CONFERINDO O NINHO"
		var face:=origin+Vector3(1.25,0,1.55).rotated(Vector3.UP,turn)-node.position
		node.rotation.y=atan2(face.x,face.z)
		if pending_service:
			actor.play("collect" if pending_eggs else "harvest")
			pending_service=false
			collecting=true
	actor.animate(delta,moving,false,false)
