class_name FarmCheeseWorkerMotion
extends RefCounted
var node:Node3D
var actor:FarmAvatar
var label:Label3D
var milk:Node3D
var tray:Node3D
var route:=FarmStaffMotion.new()
var phase:="idle"
var kind:=""
var anchor:=""
var work_time:=0.0
var idle_time:=0.0
var patrol_side:=1.0
func reset() -> void:
	phase="idle";kind="";work_time=0;idle_time=0;route.reset(0)
	if actor:actor.action_time=0
	if milk:milk.visible=false;tray.visible=false
func point(item:Dictionary,offset:Vector3) -> Vector3:
	return Vector3(item.x,0,item.z)+offset.rotated(Vector3.UP,int(item.turn)*PI/2)
func travel(state:FarmState,target:Vector3,next_phase:String) -> void:
	route.plan(node.position,target,state);phase=next_phase
	if route.blocked:
		state.cheese_worker.paused=true;state.cheese_worker.reason="blocked";reset()
func walk(state:FarmState,delta:float) -> bool:
	var remaining:=delta*1.5
	var moving:=false
	while not route.path.is_empty() and remaining>0:
		var direction:Vector3=route.path[0]-node.position;direction.y=0
		if direction.length()<.04:route.path.remove_at(0);continue
		var step:=minf(remaining,direction.length())
		var next:Vector3=node.position+direction.normalized()*step
		if not route.walkable(next,state):
			state.cheese_worker.paused=true;state.cheese_worker.reason="blocked";reset();break
		node.position=next;node.rotation.y=lerp_angle(node.rotation.y,atan2(direction.x,direction.z),minf(delta*9,1));remaining-=step;moving=true
	actor.animate(delta,moving,false)
	return node.position.distance_to(route.target)<.16
func work_pose(delta:float,mixing:bool=false) -> void:
	var blend:=1-exp(-delta*16)
	for side in ["L","R"]:
		actor.pose_bone("UpperArm."+side,Vector3(-.62,0,0),blend)
		actor.pose_bone("Forearm."+side,Vector3(-.95+(sin(work_time*8)*.22 if mixing and side=="R" else 0),0,0),blend)
	actor.carried_egg.visible=false;actor.can.visible=false
func update(world:FarmWorld,state:FarmState,delta:float) -> void:
	var w:=state.cheese_worker
	if not w.hired or w.site<0:
		if is_instance_valid(node):node.visible=false
		reset();return
	var item:Dictionary=state.items[int(w.site)]
	if not is_instance_valid(node):
		node=Node3D.new();world.add_child(node)
		var visual:=world.model("cheesemaker",node);FarmAvatar.prepare_model(visual)
		actor=FarmAvatar.new();actor.setup(visual,world)
		milk=world.model("milk_can",visual,Vector3(0,.95,.58));milk.visible=false
		tray=world.model("cheese_tray",visual,Vector3(0,1.04,.62));tray.visible=false
		label=Label3D.new();label.position.y=2.65;label.font_size=27;label.pixel_size=.007;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;node.add_child(label)
		node.position=point(item,Vector3(-1.5,0,3.85))
	node.visible=true
	var next_anchor:=str([w.site,item.x,item.z,item.turn,w.batch_size])
	if next_anchor!=anchor:
		anchor=next_anchor;reset()
	if not route.walkable(node.position,state):
		var found:=false
		for i in range(128):
			var candidate:=point(item,Vector3(sin(i*TAU/16),0,cos(i*TAU/16))*(4.2+int(i/16)*.7))
			if route.walkable(candidate,state):node.position=candidate;found=true;reset();break
		if not found:w.paused=true;w.reason="blocked"
	label.text="CHICO · "+FarmCheeseWorker.status(state).to_upper()
	if delta<=0:return
	delta=minf(delta,.1)
	if w.paused:reset();actor.animate(delta,false,false);return
	var available:=FarmCheeseWorker.job(state)
	if w.paused:reset();return
	if not kind.is_empty() and available!=kind:reset()
	if phase=="patrol" and not available.is_empty():reset()
	if phase=="idle":
		kind=available
		if kind.is_empty():
			actor.animate(delta,false,false);idle_time+=delta
			if state.items[int(w.site)].cheese.batch>0:label.text="CHICO · LOTE EM PREPARO"
			if idle_time>5:
				patrol_side*=-1;travel(state,point(item,Vector3(patrol_side*1.5,0,3.85)),"patrol");idle_time=0
			return
		travel(state,point(item,Vector3(-1.5 if kind=="start" else 0,0,3.85)),"fetch" if kind=="start" else "collect_walk")
	if phase in ["fetch","bring","collect_walk","store","patrol"]:
		label.text="CHICO · "+{"fetch":"BUSCANDO LEITE","bring":"LEVANDO LEITE","collect_walk":"BUSCANDO QUEIJOS","store":"GUARDANDO QUEIJOS","patrol":"CONFERINDO A QUEIJARIA"}[phase]
		var arrived:=walk(state,delta)
		if w.paused:return
		if milk.visible or tray.visible:work_pose(delta)
		if arrived:
			phase={"fetch":"load","bring":"mix","collect_walk":"collect","store":"put","patrol":"idle"}[phase]
			work_time=2.2 if phase=="mix" else 1.2
		return
	actor.animate(delta,false,false);work_time-=delta
	node.rotation.y=lerp_angle(node.rotation.y,int(item.turn)*PI/2+PI,minf(delta*8,1))
	label.text="CHICO · "+{"load":"PEGANDO O LEITE","mix":"PREPARANDO O LOTE","collect":"RECOLHENDO QUEIJOS","put":"GUARDANDO NO ESTOQUE"}.get(phase,"TRABALHANDO")
	work_pose(delta,phase=="mix")
	if work_time>0:return
	match phase:
		"load":milk.visible=true;travel(state,point(item,Vector3(0,0,3.85)),"bring")
		"mix":FarmCheeseWorker.complete(state,int(w.site),"start");reset()
		"collect":tray.visible=true;travel(state,point(item,Vector3(1.5,0,3.85)),"store")
		"put":FarmCheeseWorker.complete(state,int(w.site),"collect");reset()
