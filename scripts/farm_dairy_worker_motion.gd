class_name FarmDairyWorkerMotion
extends RefCounted
var node:Node3D
var actor:FarmAvatar
var label:Label3D
var can:Node3D
var sack:Node3D
var stream:MeshInstance3D
var liquid:MeshInstance3D
var liquid_material:StandardMaterial3D
var route:=FarmStaffMotion.new()
var phase:="idle"
var kind:=""
var anchor:=""
var work_time:=0.0
var gate_open:=0.0
var local_path:Array[Vector3]=[]
func reset() -> void:
	phase="idle";kind="";work_time=0;local_path.clear();route.reset(0)
	if actor:actor.action_time=0;actor.root.position.y=0
	if can:can.visible=false;can.rotation=Vector3.ZERO;can.position=Vector3(0,.80,.58)
	if sack:sack.visible=false
	if stream:stream.visible=false
func point(item:Dictionary,offset:Vector3) -> Vector3:
	return Vector3(item.x,0,item.z)+offset.rotated(Vector3.UP,int(item.turn)*PI/2)
func local(item:Dictionary,at:Vector3) -> Vector3:
	return (at-Vector3(item.x,0,item.z)).rotated(Vector3.UP,-int(item.turn)*PI/2)
func inside(item:Dictionary) -> bool:
	return local(item,node.position).z<3.65
func safe(at:Vector3,state:FarmState,site:int) -> bool:
	var p:=local(state.items[site],at)
	# Only the gate corridor and the clear aisle beside the cow are traversable.
	if not ((absf(p.x)<.72 and p.z>=2.0 and p.z<=3.9) or (p.x>=.50 and p.x<=2.15 and p.z>=-1.5 and p.z<=2.2) or (p.x>=0 and p.x<=1.7 and p.z>=2.0 and p.z<=2.2)):return false
	for i in range(state.items.size()):
		var item:Dictionary=state.items[i]
		if i==site or item.kind in ["plot","path"]:continue
		if state.item_rect(item.kind,Vector2(item.x,item.z),item.turn).grow(.48).has_point(Vector2(at.x,at.z)):return false
	return true
func walk(state:FarmState,delta:float,interior:bool) -> bool:
	var target:Vector3
	if interior:
		if local_path.is_empty():actor.animate(delta,false,false);return true
		target=point(state.items[int(state.dairy_worker.site)],local_path[0])
	else:
		if route.path.is_empty():actor.animate(delta,false,false);return not route.blocked
		target=route.path[0]
	var direction:=target-node.position;direction.y=0
	var next:=node.position+direction.normalized()*minf(delta*1.4,direction.length())
	var allowed:=safe(next,state,int(state.dairy_worker.site)) if interior else route.walkable(next,state)
	if not allowed:
		state.dairy_worker.paused=true;state.dairy_worker.reason="blocked";return false
	node.position=next
	if direction.length()>.02:node.rotation.y=lerp_angle(node.rotation.y,atan2(direction.x,direction.z),minf(delta*9,1))
	actor.animate(delta,direction.length()>.02,false)
	if node.position.distance_to(target)<.025:
		if interior:local_path.remove_at(0)
		else:route.path.remove_at(0)
	return local_path.is_empty() if interior else route.path.is_empty()
func leave() -> void:
	phase="exit";kind=""
	local_path.assign([Vector3(1.65,0,2.1),Vector3(0,0,2.1),Vector3(0,0,3.85)])
	if actor:actor.root.position.y=0
func carry_pose(delta:float) -> void:
	for side in ["L","R"]:
		actor.pose_bone("UpperArm."+side,Vector3(-.8,0,.75 if side=="L" else -.75),1-exp(-delta*16))
		actor.pose_bone("Forearm."+side,Vector3(-.55,0,0),1-exp(-delta*16))
func update(world:FarmWorld,state:FarmState,delta:float) -> void:
	var w:=state.dairy_worker
	# Release stale assignments after moving, dismissing or loading a save.
	for c in world.cows:c["attending"]=false
	if not w.hired or w.site<0:
		if is_instance_valid(node):node.visible=false
		reset();update_gates(world,delta);return
	var item:Dictionary=state.items[int(w.site)]
	var cow:Dictionary={}
	for c in world.cows:
		if c.index==int(w.site):cow=c;break
	if cow.is_empty():return
	if not is_instance_valid(node):
		node=Node3D.new();world.add_child(node)
		var visual:=world.model("dairyman",node);FarmAvatar.prepare_model(visual)
		actor=FarmAvatar.new();actor.setup(visual,world)
		can=world.model("milk_can",visual,Vector3(0,.80,.58));can.visible=false
		sack=world.model("feed_sack",visual,Vector3(0,.90,.60));sack.visible=false
		liquid=can.find_child("Milk",true,false)
		liquid_material=StandardMaterial3D.new();liquid_material.albedo_color=Color("fff0ce")
		if liquid:liquid.material_override=liquid_material
		stream=MeshInstance3D.new();var jet:=CylinderMesh.new();jet.top_radius=.018;jet.bottom_radius=.03;jet.height=.52
		stream.mesh=jet;stream.material_override=liquid_material;stream.position=Vector3(0,.93,.9);stream.visible=false;visual.add_child(stream)
		label=Label3D.new();label.position.y=2.65;label.font_size=27;label.pixel_size=.007;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;node.add_child(label)
		node.position=point(item,Vector3(0,0,3.85))
	node.visible=true
	var next_anchor:=str([w.site,item.x,item.z,item.turn])
	if next_anchor!=anchor:
		anchor=next_anchor;reset();node.position=point(item,Vector3(0,0,3.85))
	cow.attending=inside(item) or phase in ["approach","wait","enter","work","exit"]
	update_gates(world,delta)
	label.text="RAUL · "+FarmDairyWorker.status(state).to_upper()
	if delta<=0:return
	delta=minf(delta,.1)
	var available:=FarmDairyWorker.job(state)
	if phase!="exit" and (w.paused or (not kind.is_empty() and available!=kind)):
		if inside(item):leave()
		else:reset()
	if phase=="idle":
		if inside(item):leave()
		elif not available.is_empty():
			kind=available;route.plan(node.position,point(item,Vector3(0,0,3.85)),state)
			if route.blocked:w.paused=true;w.reason="blocked";reset();return
			phase="approach"
		else:actor.animate(delta,false,false);return
	cow.attending=true
	if phase=="approach":
		label.text="RAUL · INDO AO CURRAL"
		if walk(state,delta,false):phase="wait"
	elif phase=="wait":
		actor.animate(delta,false,false);label.text="RAUL · CHAMANDO MIMOSA"
		if cow.get("dock_ready",false) and cow.get("gate_amount",0.0)>.98:
			var target:=Vector3(.75,0,-1.05) if kind=="milk" else (Vector3(2.1,0,-1.4) if kind=="food" else Vector3(2.1,0,1.45))
			local_path.assign([Vector3(0,0,2.1),Vector3(1.65,0,2.1),target]);phase="enter";can.visible=kind=="water";sack.visible=kind=="food";liquid_material.albedo_color=Color("72bcc5") if kind=="water" else Color("fff0ce")
	elif phase in ["enter","exit"]:
		label.text="RAUL · "+("LEVANDO LEITE" if can.visible else ("SAINDO DO CURRAL" if phase=="exit" else "CUIDANDO DA MIMOSA"))
		if walk(state,delta,true):
			if phase=="exit":reset()
			else:phase="work";work_time=5.0 if kind=="milk" else 2.5
		if can.visible or sack.visible:carry_pose(delta)
	elif phase=="work":
		actor.animate(delta,false,false);work_time-=delta
		label.text="RAUL · "+{"milk":"ORDENHANDO","food":"REPONDO RAÇÃO","water":"ENCHENDO ÁGUA"}.get(kind,"TRABALHANDO")
		var angle:float=int(item.turn)*PI/2+(-.90 if kind=="milk" else (PI if kind=="food" else PI/2))
		node.rotation.y=lerp_angle(node.rotation.y,angle,minf(delta*10,1))
		if kind=="milk":
			actor.root.position.y=-.32*clampf((5.0-work_time)*3,0,1)
			for side in ["L","R"]:
				actor.pose_bone("Thigh."+side,Vector3(-.85,0,0))
				actor.pose_bone("Shin."+side,Vector3(1.5,0,0))
				actor.pose_bone("Foot."+side,Vector3(-.65,0,0))
				actor.pose_bone("UpperArm."+side,Vector3(-.95,0,1.0 if side=="L" else -1.0))
				actor.pose_bone("Forearm."+side,Vector3(.10+sin(work_time*9+(PI if side=="R" else 0))*.12,0,0))
			actor.pose_bone("Spine",Vector3(.32,0,0))
			can.visible=true;can.position=Vector3(0,.34,.82)
		else:
			carry_pose(delta);actor.pose_bone("Spine",Vector3(.15,0,0))
			if kind=="water":can.rotation.x=.65;stream.visible=true
			if kind=="food":sack.rotation.x=.65
		if work_time<=0:
			var completed:=FarmDairyWorker.complete(state,int(w.site),kind)
			can.visible=completed and kind=="milk";can.position=Vector3(0,.80,.58);can.rotation=Vector3.ZERO;sack.visible=false;sack.rotation=Vector3.ZERO;stream.visible=false
			leave()
func update_gates(world:FarmWorld,delta:float) -> void:
	for cow in world.cows:
		var amount:float=move_toward(float(cow.get("gate_amount",0)),1.0 if cow.get("attending",false) else 0.0,maxf(0,delta)*1.5)
		cow.gate_amount=amount
		if cow.get("gate"):
			cow.gate.basis=cow.gate_rest*Basis(Vector3.UP,-amount*PI/2)
		if cow.get("gate_collision"):cow.gate_collision.disabled=amount>.95
