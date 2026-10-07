class_name FarmCaveCreature
extends RefCounted
## Rigid Blender skin, animated around model-space axes. Gait follows distance.
var root:Node3D
var skeleton:Skeleton3D
var bones:Dictionary={}
var rests:Dictionary={}
var phase:=0.0
var clock:=0.0
var movement:=0.0
var work:=0.0
var load_pose:=0.0
var carried:Node3D

func setup(parent:Node3D,tier:int) -> void:
	root=load("res://assets/models/cave_helper_%s.glb"%["grunho","ferrugem","vigia"][tier]).instantiate()
	parent.add_child(root)
	skeleton=_skeleton(root)
	assert(skeleton!=null)
	for i in range(skeleton.get_bone_count()):
		var key:=skeleton.get_bone_name(i)
		bones[key]=i;rests[key]=skeleton.get_bone_global_rest(i).basis.get_rotation_quaternion()
	carried=load("res://assets/models/resource_ore_%s.glb"%["copper","iron","amethyst"][tier]).instantiate()
	root.add_child(carried);carried.scale=Vector3.ONE*.23;carried.position=Vector3(0,1.0+tier*.23,.55)
	animate(0,0,false,false)

func _skeleton(node:Node) -> Skeleton3D:
	if node is Skeleton3D:return node
	for child in node.get_children():
		var found:=_skeleton(child)
		if found!=null:return found
	return null

func pose(key:String,angles:Vector3,blend:float) -> void:
	if not bones.has(key):return
	var index:int=bones[key]
	var rest:Quaternion=rests[key]
	var rotation:=Quaternion(Vector3.RIGHT,angles.x)*Quaternion(Vector3.UP,angles.y)*Quaternion(Vector3.BACK,angles.z)
	var local_rest:=skeleton.get_bone_rest(index).basis.get_rotation_quaternion()
	var desired:=local_rest*rest.inverse()*rotation*rest
	skeleton.set_bone_pose_rotation(index,skeleton.get_bone_pose_rotation(index).slerp(desired,blend))

func animate(delta:float,distance:float,mining:bool,carrying:bool) -> void:
	clock+=delta;phase+=distance*TAU/.8
	var blend:=1.0-exp(-delta*12) if delta>0 else 1.0
	movement=lerpf(movement,clampf(distance/maxf(delta,.001)/.65,0,1),blend)
	work=lerpf(work,1.0 if mining else 0.0,blend)
	load_pose=lerpf(load_pose,1.0 if carrying else 0.0,blend)
	# Slow anticipation, quick strike, then a relaxed recovery.
	var stroke:=fposmod(clock,1.8)/1.8
	var strike:=smoothstep(.1,.55,stroke)-smoothstep(.55,.65,stroke)
	var impact:=sin(clampf((stroke-.55)/.14,0,1)*PI)*work
	pose("Body",Vector3(.06+work*(.12-strike*.1)+impact*.10,0,sin(phase)*movement*.025),blend)
	pose("Head",Vector3(-.04+sin(clock*1.7)*.025+work*strike*.06,sin(clock*.55)*.07*(1-work),0),blend)
	pose("Jaw",Vector3(sin(clock*2.2)*.035,0,0),blend)
	for side in ["L","R"]:
		var sign_value:=1.0 if side=="L" else -1.0
		var swing:=sin(phase)*sign_value*movement
		pose("Thigh."+side,Vector3(swing*.42,0,0),blend)
		pose("Shin."+side,Vector3(maxf(0,-swing)*.62,0,0),blend)
		pose("Foot."+side,Vector3(-maxf(0,-swing)*.30-swing*.14,0,0),blend)
		pose("AuxThigh."+side,Vector3(-swing*.3,0,0),blend)
		pose("AuxShin."+side,Vector3(maxf(0,swing)*.42,0,0),blend)
		var arm:=lerpf(-swing*.3,-.6-strike*.95,work)
		pose("UpperArm."+side,Vector3(lerpf(arm,-.65,load_pose),0,sign_value*.03),blend)
		pose("Forearm."+side,Vector3(-.1-work*strike*.40-load_pose*.7,0,0),blend)
		pose("Hand."+side,Vector3(work*impact*.1,0,0),blend)
		pose("Feeler."+side,Vector3(sin(clock*2+sign_value)*.07+impact*.12,0,sin(clock*1.3)*.04),blend)
	carried.visible=load_pose>.2
