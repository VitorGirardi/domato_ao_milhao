class_name FarmIrrigationMotion
extends RefCounted

var route:=FarmStaffMotion.new()
var plot:=-1
var watering:=false
var job_kind:="water"

func reset() -> void:
	plot=-1
	watering=false
	route.reset(0)

func update(world:FarmWorld,state:FarmState,delta:float, field:bool=false) -> void:
	delta=minf(delta,0.1)
	var actor:=world.field_actor if field else world.staff_actor
	var node:=world.field_root if field else world.staff_root
	var label:=world.field_label if field else world.staff_label
	var worker:=state.irrigation_worker()
	var name:="BENTO" if field else "ZECA"
	var efficiency:=FarmCrew.speed(worker)
	var automated:bool=field and state.cultivation.enabled
	if worker.paused: return
	if watering:
		actor.animate(delta*efficiency,false,false,false)
		label.text=name+" • "+{"water":"REGANDO","harvest":"COLHENDO","plant":"PLANTANDO"}[job_kind]
		if actor.action_time<=0:
			var crop:String=state.items[plot].crop if plot>=0 and plot<state.items.size() else "carrot"
			var result:String=FarmCultivation.complete(state,plot,job_kind) if automated else state.irrigate(plot)
			if result.is_empty() and job_kind!="water":
				var item:Dictionary=state.items[plot]
				var at:=Vector3(item.x,0,item.z)
				if job_kind=="plant":
					world.replace_crop(plot,item.crop)
					world.irrigation_feedback.planted(at)
				else: world.irrigation_feedback.harvest(at,crop)
			world.update_crops(state)
			watering=false
			plot=-1
		return
	if plot<0:
		var best:=INF
		for index in state.irrigation.plots:
			var item:Dictionary=state.items[int(index)]
			var available:String=FarmCultivation.job(state,int(index)) if automated else ("water" if item.planted and not item.watered and item.growth<1 else "")
			if available.is_empty(): continue
			var distance:=node.position.distance_to(Vector3(item.x,0,item.z))
			if distance<best: best=distance; plot=int(index); job_kind=available
		if plot<0:
			label.text=name+(" • AGUARDANDO A LAVOURA" if automated else " • CANTEIROS EM DIA")
			actor.animate(delta*efficiency,false,false,false)
			return
		var item:Dictionary=state.items[plot]
		for offset in [Vector3(0,0,1.6),Vector3(1.6,0,0),Vector3(0,0,-1.6),Vector3(-1.6,0,0)]:
			route.plan(node.position,Vector3(item.x,0,item.z)+offset,state)
			if not route.blocked: break
		if route.blocked:
			worker.paused=true
			worker.reason="manual"
			state.staff_notice="Ajudante pausou: caminho bloqueado até o canteiro. Libere a passagem e retome em H."
			label.text=name+" • CAMINHO BLOQUEADO"
			plot=-1
			return
	var item:Dictionary=state.items[plot]
	if (automated and FarmCultivation.job(state,plot)!=job_kind) or (not automated and (item.watered or not item.planted or item.growth>=1)):
		plot=-1
		return
	var moving:=false
	var remaining:=delta*1.6*efficiency
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
		node.position.y=FarmLandscape.height_at(Vector2(node.position.x,node.position.z))
		node.rotation.y=lerp_angle(node.rotation.y,atan2(direction.x,direction.z),minf(delta*8,1))
		remaining-=step
		moving=true
	label.text=name+" • INDO "+{"water":"REGAR","harvest":"COLHER","plant":"PLANTAR"}[job_kind]
	actor.animate(delta*efficiency,moving,false,false)
	if node.position.distance_to(route.target)<0.16:
		if automated and not FarmCultivation.authorize(state,plot,job_kind).is_empty(): return
		if not automated and state.money<FarmCrew.fee(worker):
			state.irrigate(plot) # Pauses and reports insufficient funds without altering crop.
			return
		var at:=Vector3(item.x,0,item.z)
		var face:=at-node.position
		node.rotation.y=atan2(face.x,face.z)
		actor.play(job_kind)
		actor.animate(0.001,false,false,false)
		watering=true
		if job_kind=="water": world.irrigation_feedback.water(at,actor.can.global_position,false,"",actor.can)
