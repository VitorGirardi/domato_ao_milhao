class_name FarmHorseMountPose
extends RefCounted
const DATA=preload("res://assets/animations/horse_mount.gd").DATA
const DURATION:float=1.6

static func sample(phase:float) -> Dictionary:
	var cursor:=clampf(phase,0,1)*(DATA.frames.size()-1)
	var index:=mini(int(cursor),DATA.frames.size()-2)
	var result:Dictionary={}
	for key in DATA.frames[index]:
		var a:Array=DATA.frames[index][key];var b:Array=DATA.frames[index+1][key]
		result[key]=Vector3(a[0],a[1],a[2]).lerp(Vector3(b[0],b[1],b[2]),cursor-index)
	return result

static func apply(actor:FarmAvatar,values:Dictionary,side:float) -> void:
	FarmWorkPose.release(actor)
	actor.locomotion.release(actor)
	for key:String in values:
		if key in ["Travel","Facing"]:continue
		var bone:=key
		var value:Vector3=values[key]
		if side>0:
			if key.ends_with(".L"):bone=key.trim_suffix(".L")+".R"
			elif key.ends_with(".R"):bone=key.trim_suffix(".R")+".L"
			value.y=-value.y;value.z=-value.z
		actor.pose_bone(bone,value)
	actor.can.visible=false;actor.carried_egg.visible=false

static func sole(actor:FarmAvatar,side:String) -> Vector3:
	var index:int=actor.bones["Foot."+side]
	var rest:=actor.skeleton.get_bone_global_rest(index)
	var offset:=rest.affine_inverse()*(rest.origin+Vector3(0,-.15,.05))
	return actor.skeleton.to_global(actor.skeleton.get_bone_global_pose(index)*offset)

static func plant_stirrup(actor:FarmAvatar,side:String,target:Vector3,weight:float) -> void:
	var skeleton:=actor.skeleton
	var joints:Array[int]=[actor.bones["Shin."+side],actor.bones["Thigh."+side]]
	var original:Array[Quaternion]=[]
	for joint in joints:original.append(skeleton.get_bone_pose_rotation(joint))
	var goal:=skeleton.to_local(target)
	for iteration in range(12):
		for joint in joints:
			var pose:=skeleton.get_bone_global_pose(joint)
			var from:=skeleton.to_local(sole(actor,side))-pose.origin
			var to:=goal-pose.origin
			if from.length()<.001 or to.length()<.001:continue
			var turn:=Quaternion(from.normalized(),to.normalized())
			var parent:=skeleton.get_bone_global_pose(skeleton.get_bone_parent(joint)).basis.get_rotation_quaternion()
			skeleton.set_bone_pose_rotation(joint,parent.inverse()*turn*pose.basis.get_rotation_quaternion())
	for i in range(joints.size()):skeleton.set_bone_pose_rotation(joints[i],original[i].slerp(skeleton.get_bone_pose_rotation(joints[i]),weight))
