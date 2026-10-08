class_name FarmWorkPose
extends RefCounted
## Authored Blender curves; clocks are visual and never award or consume stock.
const WATER_DURATION:=1.2
const WATER_POUR_START:=.30
const WATER_POUR_END:=.84
const HARVEST_DURATION:=1.4
const HARVEST_CONTACT:=.63
const CAN_GRIP_R:=Vector3(0,.68,-.06)
const CAN_GRIP_L:=Vector3(-.22,.40,0)
static var clips:Dictionary={}

static func data() -> Dictionary:
	if clips.is_empty():
		var source:GDScript=load("res://assets/animations/work_actions.gd")
		clips=source.get_script_constant_map()["DATA"]
	return clips

static func duration(kind:String) -> float:
	return WATER_DURATION if kind=="water" else HARVEST_DURATION

static func sample(kind:String,phase:float) -> Dictionary:
	var frames:Array=data()[kind].frames
	var at:=clampf(phase,0,1)*(frames.size()-1)
	var index:=mini(floori(at),frames.size()-2)
	var result:Dictionary={}
	for bone in frames[index]:
		var a:Array=frames[index][bone];var b:Array=frames[index+1][bone]
		result[bone]=Vector3(a[0],a[1],a[2]).lerp(Vector3(b[0],b[1],b[2]),at-index)
	return result

static func release(actor:FarmAvatar) -> void:
	if not actor.work_pose_active:return
	actor.work_pose_active=false
	var index:int=actor.bones.Pelvis
	actor.skeleton.set_bone_pose_position(index,actor.skeleton.get_bone_rest(index).origin)
	for bone in ["Pelvis","Clavicle.L","Clavicle.R"]:actor.pose_bone(bone,Vector3.ZERO)

static func body(actor:FarmAvatar,kind:String,phase:float) -> void:
	var pose:=sample(kind,phase)
	for bone in pose:actor.pose_bone(bone,pose[bone])
	# Correct only the articulated pelvis; physics root/camera remain untouched.
	var index:int=actor.bones.Pelvis
	var rest:=actor.skeleton.get_bone_rest(index).origin
	actor.skeleton.set_bone_pose_position(index,rest)
	var offset:=clampf(.025-actor.locomotion.sole_height(actor),-.5,.05)
	var parent:=actor.skeleton.get_bone_parent(index)
	var basis:=actor.skeleton.get_bone_global_pose(parent).basis
	actor.skeleton.set_bone_pose_position(index,rest+basis.inverse()*Vector3(0,offset,0))
	actor.root.position.y=0
	actor.work_pose_active=true

static func apply(actor:FarmAvatar,kind:String,seconds:float) -> void:
	var phase:=clampf(seconds/duration(kind),0,1)
	body(actor,kind,phase)
	actor.carried_egg.visible=false
	actor.can.visible=kind=="water"
	if kind!="water":return
	# One hand carries the top handle; the other supports the vessel side.
	# The prop has an independent rigid transform, so IK cannot stretch it.
	var lift:=smoothstep(0,.23,phase)*(1-smoothstep(.75,1,phase))
	var pour:=smoothstep(.18,.30,phase)*(1-smoothstep(.70,.82,phase))
	var vessel_basis:=Basis(Vector3.RIGHT,pour*.60).scaled(Vector3.ONE*.78)
	var right:=Vector3(.12,lerpf(1.48,1.56,lift),lerpf(.32,.46,lift))
	var vessel:=actor.root.global_transform*Transform3D(vessel_basis,right-vessel_basis*CAN_GRIP_R)
	for iteration in range(3):
		actor.reach_rein_hand("R",vessel*CAN_GRIP_R,1)
		actor.reach_rein_hand("L",vessel*CAN_GRIP_L,1)
	# BoneAttachment updates after animation, so compute its expected basis now.
	var hand:=actor.skeleton.global_transform*actor.skeleton.get_bone_global_pose(actor.bones["Hand.R"])
	actor.can.transform=hand.affine_inverse()*vessel
