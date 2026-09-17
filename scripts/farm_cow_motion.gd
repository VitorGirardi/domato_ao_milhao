class_name FarmCowMotion
extends RefCounted

# Keep the full turning envelope in the open middle of the pen.
const SPOTS:=[Vector3(-1.10,0,.35),Vector3(.40,0,.35),Vector3(-.40,0,.35)]

static func setup(cow:Dictionary,pen:Node3D) -> void:
	cow.node.position=Vector3(0,0,.35)
	cow.motion={"phase":"walk","target":0,"wait":0.0,"gait":0.0,"graze":0.0,"time":0.0}
	var material:=StandardMaterial3D.new()
	material.albedo_color=Color("77a745")
	for spot in SPOTS:
		for i in range(9):
			var tuft:=MeshInstance3D.new()
			var blade:=PrismMesh.new()
			blade.size=Vector3(.10,.22+(i%3)*.025,.07)
			tuft.mesh=blade;tuft.material_override=material
			tuft.position=spot+Vector3(sin(i*2.4)*.48,.11,cos(i*2.4)*.38)
			tuft.rotation.y=i*1.3
			pen.add_child(tuft)

static func animate(cow:Dictionary,delta:float,player_pos:Vector3) -> void:
	if delta<=0: return
	var motion:Dictionary=cow.motion
	var node:Node3D=cow.node
	motion.time+=delta
	var walking:=false
	if motion.phase=="walk" and motion.graze<.05:
		var direction:Vector3=SPOTS[motion.target]-node.position
		if direction.length()<.08:
			motion.phase="graze";motion.wait=6.0
		else:
			var desired:=atan2(direction.x,direction.z)
			var distance_to_farmer:float=node.global_position.distance_to(player_pos)
			if distance_to_farmer>1.9:
				walking=absf(angle_difference(node.rotation.y,desired))>.04
				node.rotation.y=rotate_toward(node.rotation.y,desired,delta*.95)
			var aligned:=absf(angle_difference(node.rotation.y,desired))<.18
			var local_player:Vector3=node.get_parent().to_local(player_pos)
			var next:Vector3=node.position+direction.normalized()*minf(delta*.42,direction.length())
			# Wait instead of pushing the farmer or turning through them.
			if aligned and Vector2(local_player.x-next.x,local_player.z-next.z).length()>1.75:
				node.position=next;walking=true
	elif motion.phase!="walk":
		motion.wait-=delta
		if motion.wait<=0:
			if motion.phase=="graze":
				motion.phase="rest";motion.wait=3.0
			else:
				motion.phase="walk";motion.target=(motion.target+1)%SPOTS.size()
	motion.graze=move_toward(motion.graze,1.0 if motion.phase=="graze" else 0.0,delta*.8)
	if walking: motion.gait+=delta*5.8
	for key in cow.bones:
		var bone:Dictionary=cow.bones[key]
		var angle:=0.0
		var axis:=Vector3.RIGHT
		if key.begins_with("Leg"):
			angle=sin(motion.gait+(0 if key in ["LegFL","LegBR"] else PI))*.24 if walking else 0.0
		elif key=="CowNeck":
			angle=motion.graze*1.12
		elif key=="CowHead":
			angle=motion.graze*(.12+sin(motion.time*7)*.025)
		elif key=="CowTail":
			axis=Vector3.UP;angle=sin(motion.time*2)*.18
		var target:Basis=bone.rest*Basis(axis,angle)
		bone.node.basis=bone.node.basis.slerp(target,1-exp(-delta*10))
