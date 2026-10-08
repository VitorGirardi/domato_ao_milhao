class_name FarmMiningPose
extends RefCounted
## A complete swing follows the authoritative job clock, not frame rate.
const PERIOD:=1.25
const CONTACT:=.58
const TIP:=Vector3(.39,.68,0)
const GRIP_R:=Vector3(0,.12,0)
const GRIP_L:=Vector3(0,.30,0)

static func sample(seconds:float,distance:float=1.5) -> Dictionary:
	var phase:=fposmod(seconds,PERIOD)/PERIOD
	var raised:=0.0
	if phase<.38:raised=smoothstep(0,.38,phase)
	elif phase<CONTACT:raised=1-smoothstep(.38,CONTACT,phase)
	elif phase<.70:raised=.08*sin((phase-CONTACT)/.12*PI)
	# The blade swings in the forward vertical plane beside the head.
	var shaft:=Vector3(0,cos(1.45),sin(1.45))
	var blade:=Vector3(0,-sin(1.45),cos(1.45))
	var resting:=Basis(blade,shaft,blade.cross(shaft))
	var raised_shaft:=Vector3(.55,.80,.24).normalized()
	var raised_blade:=Vector3(0,-raised_shaft.z,raised_shaft.y).normalized()
	var preparation:=Basis(raised_blade,raised_shaft,raised_blade.cross(raised_shaft))
	var basis:=Basis(resting.get_rotation_quaternion().slerp(preparation.get_rotation_quaternion(),raised)).scaled(Vector3.ONE*1.25)
	var impact:=Vector3(.05,.80,clampf(distance-.55,.65,1.0))
	var impact_shaft:=Vector3(0,cos(1.45),sin(1.45))
	var impact_blade:=Vector3(0,-sin(1.45),cos(1.45))
	var low:=impact-(impact_blade*TIP.x+impact_shaft*TIP.y)*1.25
	var high:=Vector3(.08,1.35,.15)
	var origin:=low.lerp(high,raised)
	return {"phase":phase,"raised":raised,"tool":Transform3D(basis,origin),"impact":impact}

static func apply(actor:FarmAvatar,tool:Node3D,seconds:float,target:Vector3) -> Dictionary:
	var distance:=Vector2(target.x-actor.root.global_position.x,target.z-actor.root.global_position.z).length()
	var frame:=sample(seconds,distance)
	# Blender-authored shoulders/torso lead the blow, knees accept its weight.
	FarmWorkPose.body(actor,"mine",float(frame.phase))
	tool.global_transform=actor.root.global_transform*frame.tool
	for iteration in range(3):
		actor.reach_rein_hand("R",tool.global_transform*GRIP_R,1)
		actor.reach_rein_hand("L",tool.global_transform*GRIP_L,1)
	frame["world_impact"]=actor.root.global_transform*frame.impact
	return frame
