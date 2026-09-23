class_name FarmHenMotion
extends RefCounted
## Visual-only pose. Call after navigation; time includes each hen's phase.
## Never changes the root transform, collisions, economy or network state.

static func pose(hen:Node3D,time:float,delta:float,stepping:bool,pecking:bool) -> void:
	if delta<=0: return
	if not hen.has_meta("hen_pose"):
		var skin:=hen.find_child("HenBody",true,false) as MeshInstance3D
		hen.set_meta("hen_pose",{"skin":skin,"peck":skin.find_blend_shape_by_name("Peck") if skin else -1,
			"left":hen.find_child("LegL",true,false),"right":hen.find_child("LegR",true,false),"amount":0.0})
	var data:Dictionary=hen.get_meta("hen_pose")
	var cycle:=fposmod(time,5.8)
	# Look around, scratch backwards twice, then reach down for three pecks.
	var forage:=pecking and not stepping
	var scratch:=forage and cycle<1.1
	var down:=smoothstep(1.25,1.65,cycle)*(1.0-smoothstep(3.25,3.75,cycle))
	var peck:=down*(.89+.11*cos((cycle-1.65)*TAU*2.2)) if forage else 0.0
	data.amount=move_toward(float(data.amount),peck,delta*4.5)
	if data.skin and data.peck>=0:data.skin.set_blend_shape_value(data.peck,data.amount)
	for side in range(2):
		var leg:Node3D=data.left if side==0 else data.right
		if not leg:continue
		var angle:=sin(time*13+(PI if side==0 else 0.0))*.38 if stepping else 0.0
		if scratch and side==int(floor(time/5.8))%2:
			angle=-absf(sin(cycle/1.1*TAU))*.48
		leg.rotation.x=lerpf(leg.rotation.x,angle,1.0-exp(-delta*22))
