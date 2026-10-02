class_name FarmPistolPose
extends RefCounted
## Blender pose controls, followed by palm IK to the physical grip of the P-8.
const SOURCE=preload("res://assets/animations/pistol_pose.gd")
const GRIP_R:=Vector3(.038,.065,-.044)
const GRIP_L:=Vector3(-.078,.065,-.01)
const SCALE:=1.1

static func _sample(key:String,frame:float) -> Vector3:
	var lo:=clampi(int(frame),0,60)
	var hi:=mini(lo+1,60)
	var a:Array=SOURCE.DATA[key][lo]
	var b:Array=SOURCE.DATA[key][hi]
	return Vector3(a[0],a[1],a[2]).lerp(Vector3(b[0],b[1],b[2]),frame-lo)

static func apply(actor:FarmAvatar,pistol:Node3D,pitch:float,aim_weight:float,reload_fraction:float,kick:float) -> void:
	var frame:=clampf(aim_weight,0,1)*30
	var reloading:=sin(clampf(reload_fraction,0,1)*PI)
	var origin:=_sample("weapon",frame).lerp(_sample("weapon",60),reloading)
	var angles:=_sample("rotation",frame).lerp(_sample("rotation",60),reloading)
	var elevation:=clampf(pitch,-.85,.85)*clampf(aim_weight,0,1)
	# Keep the grip in front of the face when looking up; a shoulder orbit
	# would pull this short cartoon rig through its forehead.
	origin.y+=elevation*(.08 if elevation>0 else .35)
	origin.z+=absf(elevation)*.07
	angles.x-=elevation+clampf(kick,0,1)*.08
	origin.z-=clampf(kick,0,1)*.035
	actor.pose_bone("Spine",Vector3.ZERO)
	actor.pose_bone("Chest",Vector3.ZERO)
	actor.pose_bone("Neck",Vector3(-elevation*.15,0,0))
	actor.pose_bone("Head",Vector3(-elevation*.15,0,0))
	for key in ["UpperArm.R","UpperArm.L","Forearm.R","Forearm.L"]:
		actor.pose_bone(key,_sample(key,frame).lerp(_sample(key,60),reloading))
	actor.pose_bone("Hand.R",Vector3.ZERO)
	actor.pose_bone("Hand.L",Vector3.ZERO)
	var placement:=actor.root.global_transform*Transform3D(Basis.from_euler(angles).scaled(Vector3.ONE*SCALE),origin)
	# Position is independent of the moving hand attachment; IK cannot drag the gun.
	for iteration in range(3):
		actor.reach_rein_hand("R",placement*GRIP_R,1)
		actor.reach_rein_hand("L",placement*GRIP_L,1)
	# BoneAttachment follows on the next skeleton update. Express the prop against
	# the computed hand bone now to avoid a one-frame lag in both local/remote poses.
	if pistol.get_parent()==actor.hand_socket:
		var hand:=actor.skeleton.global_transform*actor.skeleton.get_bone_global_pose(actor.bones["Hand.R"])
		pistol.transform=hand.affine_inverse()*placement
		actor.hand_socket.global_transform=hand
	else:pistol.global_transform=placement
	actor.can.visible=false;actor.carried_egg.visible=false
	pistol.visible=true


