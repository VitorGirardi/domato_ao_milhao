class_name FarmAvatar
extends RefCounted

var root: Node3D
var skeleton:Skeleton3D
var bones:Dictionary={}
var rest_rotations:Dictionary={}
var can: Node3D
var hand_socket:BoneAttachment3D
var can_rest:Transform3D
var time := 0.0
var action_time := 0.0
var action_kind := ""

static func prepare_model(node: Node) -> void:
	# Small facial patches should remain readable beneath the hat and moustache.
	if node is MeshInstance3D:
		for surface in range(node.mesh.get_surface_count()):
			var mat:Material=node.mesh.surface_get_material(surface)
			if mat is StandardMaterial3D and (mat.resource_name.ends_with("_White") or mat.resource_name.ends_with("_Eye")):
				var facial:StandardMaterial3D=mat.duplicate()
				facial.disable_receive_shadows=true
				node.set_surface_override_material(surface,facial)
	for child in node.get_children(): prepare_model(child)

func setup(model: Node3D, world: FarmWorld = null) -> void:
	root=model
	var found:=root.find_children("*","Skeleton3D",true,false)
	assert(found.size()==1,"Character requires one humanoid Skeleton3D")
	skeleton=found[0]
	for index in range(skeleton.get_bone_count()):
		var key:=skeleton.get_bone_name(index)
		bones[key]=index
		rest_rotations[key]=skeleton.get_bone_global_rest(index).basis.get_rotation_quaternion()
	for key in ["Head","Spine","UpperArm.R","Forearm.R","Hand.R","Thigh.L","Shin.L"]: assert(bones.has(key))
	hand_socket=BoneAttachment3D.new()
	hand_socket.bone_name="Hand.R"
	skeleton.add_child(hand_socket)
	if world!=null: can=world.model("watering_can",hand_socket)
	else:
		can=load("res://assets/models/watering_can.glb").instantiate()
		hand_socket.add_child(can)
	var hand_rest:=skeleton.get_bone_global_rest(bones["Hand.R"])
	var desired:=Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*0.62),hand_rest.origin+Vector3(0.035,-0.50,0.06))
	can_rest=hand_rest.affine_inverse()*desired
	can.transform=can_rest
	can.visible=false
	animate(1,false,false)

func pose_bone(key: String, angles: Vector3, blend: float = 1.0) -> void:
	var rest:Quaternion=rest_rotations[key]
	var model_rotation:=Quaternion(Vector3.RIGHT,angles.x)*Quaternion(Vector3.UP,angles.y)*Quaternion(Vector3.BACK,angles.z)
	var index:int=bones[key]
	# Imported poses contain the parent-relative rest rotation, not an identity
	# delta. Keep that basis when applying rotations around model-space axes.
	var local_rest:=skeleton.get_bone_rest(index).basis.get_rotation_quaternion()
	var local_rotation:=local_rest*rest.inverse()*model_rotation*rest
	skeleton.set_bone_pose_rotation(index,skeleton.get_bone_pose_rotation(index).slerp(local_rotation,blend))

func play(kind: String) -> void:
	action_kind=kind
	action_time=0.85 if kind=="water" else 0.55

func animate(delta: float, moving: bool, running: bool) -> void:
	time+=delta
	action_time=maxf(0,action_time-delta)
	var phase:=time*(11 if running else 8)
	var stride:=sin(phase)*(0.60 if running else 0.40) if moving else 0.0
	var blend:=1-exp(-delta*16)
	var active:=action_time>0
	for side in ["L","R"]:
		var sign_value:=1.0 if side=="R" else -1.0
		var thigh:float=-stride*sign_value
		var knee:float=maxf(0,-sin(phase)*sign_value)*(1.1 if running else 0.72) if moving else 0.025
		pose_bone("Thigh."+side,Vector3(thigh,0,0),blend)
		pose_bone("Shin."+side,Vector3(knee,0,0),blend)
		pose_bone("Foot."+side,Vector3(-knee*0.45-thigh*0.2,0,0),blend)
		var shoulder:float=stride*sign_value*0.7
		var elbow:float=-0.65 if running and moving else -0.14
		if active:
			shoulder=-0.58 if action_kind=="water" and side=="R" else -0.38
			elbow=-0.74 if action_kind=="water" and side=="R" else -0.50
		pose_bone("UpperArm."+side,Vector3(shoulder,0,-sign_value*0.28),blend)
		pose_bone("Forearm."+side,Vector3(elbow,0,0),blend)
		pose_bone("Hand."+side,Vector3(-0.08 if active else 0,0,0),blend)
	pose_bone("Spine",Vector3(0.10 if active else (0.06 if running and moving else 0),0,0),blend)
	pose_bone("Chest",Vector3(0.09 if active else 0,0,0),blend)
	pose_bone("Neck",Vector3(-0.05 if active else 0,0,0),blend)
	pose_bone("Head",Vector3(0.04 if active else sin(time*1.4)*0.018,0,0),blend)
	root.position.y=abs(sin(phase*2))*0.018 if moving else 0
	if can:
		can.visible=active and action_kind=="water"
		can.transform=can_rest*Transform3D(Basis(Vector3.RIGHT,-0.2+sin(time*8)*0.04),Vector3.ZERO)
