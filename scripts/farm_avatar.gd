class_name FarmAvatar
extends RefCounted

var root: Node3D
var skeleton:Skeleton3D
var bones:Dictionary={}
var rest_rotations:Dictionary={}
var can: Node3D
var hand_socket:BoneAttachment3D
var hand_grip:Vector3
var carried_egg:Node3D
var time := 0.0
var action_time := 0.0
var airborne:=false
var landing:=0.0
var action_kind := ""
var emote_kind:=""
var emote_time:=0.0
var emote_elapsed:=0.0
var reaction:Sprite3D
var reaction_time:=0.0
var face_mesh:MeshInstance3D
var blink_index:=-1
var blink_wait:=2.0
var blink_elapsed:=-1.0
var blink_rng:=RandomNumberGenerator.new()

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
	face_mesh=root.find_child("HeadSkin",true,false)
	blink_index=face_mesh.find_blend_shape_by_name("Blink")
	assert(blink_index>=0,"Character requires the Blink facial shape")
	blink_rng.randomize()
	blink_wait=blink_rng.randf_range(1.0,4.0)
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
	hand_grip=hand_rest.affine_inverse()*(hand_rest.origin+Vector3(0.025,-0.085,0.045))
	carried_egg=load("res://assets/models/egg.glb").instantiate()
	hand_socket.add_child(carried_egg)
	carried_egg.visible=false
	can.visible=false
	reaction=Sprite3D.new()
	reaction.pixel_size=.016; reaction.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	reaction.no_depth_test=true; reaction.shaded=false
	reaction.position=Vector3(0,3.25,0); reaction.visible=false
	root.add_child(reaction)
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

func stop_emote() -> void:
	emote_kind=""; emote_time=0; emote_elapsed=0
	if root: root.position.y=0

func emote(kind:String) -> bool:
	if action_time>0 or airborne: return false
	if FarmEmotes.DANCES.has(kind):
		emote_kind=kind; emote_time=6.0; emote_elapsed=0
		return true
	if FarmEmotes.REACTIONS.has(kind):
		reaction.texture=load("res://assets/ui/emote_%s.svg"%kind)
		reaction_time=2.8; reaction.visible=true
		return true
	return false

func play(kind: String) -> void:
	stop_emote()
	action_kind=kind
	action_time=2.2 if kind=="collect" else (1.15 if kind=="water" else 0.55)

func animate(delta: float, moving: bool, running: bool, blink:bool=true) -> void:
	if moving or airborne or action_time>0: stop_emote()
	emote_time=maxf(0,emote_time-delta)
	if emote_time<=0 and not emote_kind.is_empty(): stop_emote()
	emote_elapsed+=delta
	reaction_time=maxf(0,reaction_time-delta)
	if reaction:
		reaction.visible=reaction_time>0
		reaction.position.y=3.15+sin((2.8-reaction_time)*2)*.13
		reaction.modulate.a=minf(1,reaction_time*3)
	if blink: update_blink(delta)
	time+=delta
	landing=maxf(0,landing-delta)
	action_time=maxf(0,action_time-delta)
	var phase:=time*(11 if running else 8)
	var stride:=sin(phase)*(0.60 if running else 0.40) if moving else 0.0
	var blend:=1-exp(-delta*16)
	if emote_time>0:
		FarmEmotes.pose(self,emote_kind,emote_elapsed,blend)
		can.visible=false;carried_egg.visible=false
		return
	var active:=action_time>0
	var collecting:=active and action_kind=="collect"
	var bending:=collecting or (active and action_kind in ["plant","harvest"])
	var reach:=sin(clampf(1.0-action_time/(2.2 if collecting else 0.55),0,1)*PI) if bending else 0.0
	for side in ["L","R"]:
		var sign_value:=1.0 if side=="R" else -1.0
		var thigh:float=-stride*sign_value
		var knee:float=maxf(0,-sin(phase)*sign_value)*(1.1 if running else 0.72) if moving else 0.025
		if airborne or landing>0:
			var tuck:=1.0 if airborne else landing/0.22
			thigh=-0.42*tuck
			knee=0.85*tuck
		if bending:
			thigh=-reach*0.75
			knee=reach*1.5
		pose_bone("Thigh."+side,Vector3(thigh,0,0),blend)
		pose_bone("Shin."+side,Vector3(knee,0,0),blend)
		pose_bone("Foot."+side,Vector3(-knee-thigh if bending else -knee*0.45-thigh*0.2,0,0),blend)
		var shoulder:float=stride*sign_value*0.7
		var elbow:float=-0.65 if running and moving else -0.14
		if airborne:
			shoulder=-0.5
			elbow=-0.65
		if active:
			shoulder=-0.58 if action_kind=="water" and side=="R" else -0.38
			elbow=-0.74 if action_kind=="water" and side=="R" else -0.50
			if bending:
				shoulder=-0.7-reach*0.5
				elbow=-0.15
		pose_bone("UpperArm."+side,Vector3(shoulder,0,-sign_value*0.28),blend)
		pose_bone("Forearm."+side,Vector3(elbow,0,0),blend)
		pose_bone("Hand."+side,Vector3(-0.08 if active else 0,0,0),blend)
	pose_bone("Spine",Vector3(reach*0.75 if bending else (0.10 if active else (0.06 if running and moving else 0)),0,0),blend)
	pose_bone("Chest",Vector3(0.09 if active else 0,0,0),blend)
	pose_bone("Neck",Vector3(-0.05 if active else 0,0,0),blend)
	pose_bone("Head",Vector3(0.04 if active else sin(time*1.4)*0.018,0,0),blend)
	root.position.y=-reach*0.2 if bending else (abs(sin(phase*2))*0.018 if moving else 0)
	if airborne: root.position.y=0
	elif landing>0: root.position.y=-0.06*landing/0.22
	if can:
		can.visible=active and action_kind=="water"
		# Keep the vessel upright independently of the wrist's imported rest axes.
		# Pivot about the handle; positive X tilt lowers the forward-facing spout.
		var hand_pose:=skeleton.get_bone_global_pose(bones["Hand.R"])
		var grip:=hand_pose*hand_grip
		var pour:=sin(clampf(1.0-action_time/1.15,0,1)*PI)*0.45 if can.visible else 0.0
		var vessel_basis:=Basis(Vector3.RIGHT,pour).scaled(Vector3.ONE*0.62)
		can.transform=hand_pose.affine_inverse()*Transform3D(vessel_basis,grip-vessel_basis*Vector3(0,0.68,-0.06))
		carried_egg.visible=collecting and action_time<1.15
		carried_egg.transform=hand_pose.affine_inverse()*Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*0.8),grip)

func update_blink(delta:float) -> void:
	if blink_elapsed<0:
		blink_wait-=delta
		if blink_wait<=0: blink_elapsed=0.0
	else:
		blink_elapsed+=delta
		if blink_elapsed>=0.22:
			blink_elapsed=-1.0
			blink_wait=blink_rng.randf_range(2.5,5.5)
	var amount:=0.0
	if blink_elapsed>=0:
		amount=smoothstep(0.0,0.075,blink_elapsed)*(1.0-smoothstep(0.105,0.22,blink_elapsed))
	face_mesh.set_blend_shape_value(blink_index,amount)
