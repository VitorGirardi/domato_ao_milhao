class_name FarmLocomotion
extends RefCounted
## Visual-only distance driven gait. Never writes player velocity or root translation.
const DATA_PATH := "res://assets/animations/locomotion.gd"
static var clips: Dictionary = {}
var enabled := false
var suspended := false
var initialized := false
var active := false
var previous_position := Vector3.ZERO
var previous_heading := 0.0
var phase := 0.0
var travelled := 0.0
var speed := 0.0
var gait_weight := 0.0
var run_weight := 0.0
var turn := 0.0
var idle_time := 0.0
var pelvis_offset := 0.0
var sole_points: Dictionary = {}

static func data() -> Dictionary:
	if clips.is_empty():
		var source: GDScript = load(DATA_PATH)
		clips = source.get_script_constant_map()["DATA"]
	return clips

static func sample(clip: Dictionary, at: float) -> Dictionary:
	var frames: Array = clip.frames
	var position := fposmod(at,1.0) * (frames.size()-1)
	var first := mini(floori(position),frames.size()-2)
	var weight := position-first
	var result: Dictionary = {}
	for bone in frames[first]:
		var a: Array = frames[first][bone]
		var b: Array = frames[first+1][bone]
		result[bone] = Vector3(a[0],a[1],a[2]).lerp(Vector3(b[0],b[1],b[2]),weight)
	return result

func release(actor: FarmAvatar) -> void:
	initialized = false
	speed = 0; gait_weight = 0; run_weight = 0; turn = 0
	if not active: return
	active = false
	pelvis_offset = 0
	if actor.bones.has("Pelvis"):
		var index: int = actor.bones.Pelvis
		actor.skeleton.set_bone_pose_position(index,actor.skeleton.get_bone_rest(index).origin)
	# The legacy special poses never write these channels; restore what we own.
	for bone in ["Root","Pelvis","Clavicle.L","Clavicle.R"]:
		if actor.bones.has(bone): actor.pose_bone(bone,Vector3.ZERO)

func _sole_setup(actor: FarmAvatar) -> void:
	if not sole_points.is_empty(): return
	for side in ["L","R"]:
		var rest := actor.skeleton.get_bone_global_rest(actor.bones["Foot."+side])
		sole_points[side] = [rest.affine_inverse()*Vector3(rest.origin.x,.025,-.065),rest.affine_inverse()*Vector3(rest.origin.x,.025,.18)]

func sole_height(actor: FarmAvatar) -> float:
	_sole_setup(actor)
	var minimum := INF
	for side in ["L","R"]:
		var pose := actor.skeleton.get_bone_global_pose(actor.bones["Foot."+side])
		for point in sole_points[side]: minimum = minf(minimum,(pose*point).y)
	return minimum

func _support(actor: FarmAvatar) -> void:
	if not actor.bones.has("Pelvis"): return
	var index: int = actor.bones.Pelvis
	var rest := actor.skeleton.get_bone_rest(index).origin
	actor.skeleton.set_bone_pose_position(index,rest)
	# Seat one sole on the ground by shifting only the articulated pelvis. The
	# model root stays at zero, and the swing foot remains free to lift naturally.
	pelvis_offset = clampf(.025-sole_height(actor),-.22,.035)
	var parent := actor.skeleton.get_bone_parent(index)
	var basis := actor.skeleton.get_bone_global_pose(parent).basis if parent >= 0 else Basis.IDENTITY
	actor.skeleton.set_bone_pose_position(index,rest+basis.inverse()*Vector3(0,pelvis_offset,0))

func apply(actor: FarmAvatar, delta: float, running: bool) -> void:
	var position := actor.root.global_position
	var heading := actor.root.global_rotation.y
	if delta <= 0 or not is_finite(delta): return
	var distance := Vector2(position.x-previous_position.x,position.z-previous_position.z).length()
	var teleported := not initialized or delta > .3 or distance > maxf(2.0,delta*16)
	if teleported:
		initialized = true
		distance = 0
		speed = 0; gait_weight = 0; run_weight = 0; turn = 0
		previous_heading = heading
	var dt := minf(delta,.1)
	var observed := distance/delta
	speed = lerpf(speed,observed,1-exp(-dt*12))
	var wanted_run := smoothstep(3.8,7.0,speed) if running else 0.0
	run_weight = lerpf(run_weight,wanted_run,1-exp(-dt*7))
	gait_weight = lerpf(gait_weight,smoothstep(.03,.9,speed),1-exp(-dt*12))
	if speed < .01 and gait_weight < .001: gait_weight = 0
	var content := data()
	var stride := lerpf(float(content.walk.get("stride_length",2.8)),float(content.run.get("stride_length",4.2)),run_weight)
	phase = fposmod(phase+distance/maxf(.1,stride),1.0)
	travelled += distance
	var angular := clampf(wrapf(heading-previous_heading,-PI,PI)/delta,-4,4)
	turn = lerpf(turn,angular,1-exp(-dt*9))
	previous_position = position
	previous_heading = heading
	idle_time += dt
	var idle := sample(content.idle,idle_time/float(content.idle.duration))
	var walk := sample(content.walk,phase)
	var run := sample(content.run,phase)
	var blend := 1-exp(-dt*18)
	for bone in idle:
		if not actor.bones.has(bone) or bone == "Root": continue
		var resting: Vector3 = idle[bone]
		var moving: Vector3 = (walk.get(bone,resting) as Vector3).lerp(run.get(bone,resting),run_weight)
		var angles := resting.lerp(moving,gait_weight)
		if bone == "Spine": angles.z += clampf(-turn*.025,-.10,.10)*gait_weight
		if bone == "Chest": angles.y += clampf(-turn*.025,-.10,.10)*gait_weight
		if bone == "Head": angles.y += clampf(turn*.035,-.14,.14)*gait_weight
		if bone == "Neck": angles.y += clampf(turn*.015,-.06,.06)*gait_weight
		actor.pose_bone(bone,angles,blend)
	actor.root.position.y = 0
	_support(actor)
	active = true
