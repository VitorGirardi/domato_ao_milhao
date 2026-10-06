extends SceneTree

func _initialize() -> void: call_deferred("run")

func step(actor: FarmAvatar, delta: float, velocity: Vector3, running: bool) -> void:
	actor.root.position += velocity * delta
	var before := actor.root.position
	actor.animate(delta,velocity.length_squared() > .001,running,false)
	assert(is_equal_approx(actor.root.position.x,before.x) and is_equal_approx(actor.root.position.z,before.z),"Visual gait moved the physical position")
	assert(is_zero_approx(actor.root.position.y),"Locomotion must not float the model root")
	assert(absf(actor.locomotion.turn) <= 4.001)
	assert(actor.locomotion.sole_height(actor) >= -.015,"Support sole penetrated ground")
	assert(actor.locomotion.sole_height(actor) <= .045,"Both soles floated above ground")

func run() -> void:
	var content := FarmLocomotion.data()
	for key in ["idle","walk","run"]:
		assert(content.has(key) and content[key].duration > 0)
		var frames: Array = content[key].frames
		assert(frames.size() >= 3)
		assert(frames[0] == frames[-1],"Clip must close continuously")
		var first := FarmLocomotion.sample(content[key],0)
		var endpoint := FarmLocomotion.sample(content[key],1)
		for bone in first: assert(first[bone].is_equal_approx(endpoint[bone]))
	for model in ["farmer","farmer_woman"]:
		var node: Node3D = load("res://assets/models/%s.glb" % model).instantiate()
		root.add_child(node)
		var actor := FarmAvatar.new()
		actor.setup(node)
		assert(not actor.locomotion.enabled and not actor.locomotion.active)
		actor.locomotion.enabled = true
		step(actor,1.0/60,Vector3.ZERO,false)
		for frame in range(180): step(actor,1.0/60,Vector3(0,0,4.5),false)
		assert(absf(actor.locomotion.speed-4.5) < .01)
		assert(actor.locomotion.gait_weight > .99)
		var before_phase: float = actor.locomotion.phase
		step(actor,1.0/60,Vector3(0,0,4.5),true)
		assert(fposmod(actor.locomotion.phase-before_phase,1) < .05,"Run toggle reset gait phase")
		for frame in range(180):
			node.rotation.y += .01
			step(actor,1.0/60,Vector3(0,0,7.5),true)
		assert(actor.locomotion.run_weight > .99)
		before_phase = actor.locomotion.phase
		for frame in range(120): step(actor,1.0/60,Vector3.ZERO,false)
		assert(is_equal_approx(actor.locomotion.phase,before_phase),"Stopped feet keep cycling")
		assert(actor.locomotion.gait_weight == 0 and actor.locomotion.speed < .01)
		# Facing wraps through +/-PI without a turn spike, and excessive turns clamp.
		actor.locomotion.previous_heading = PI-.001
		node.rotation.y = -PI+.001
		step(actor,1.0/60,Vector3.ZERO,false)
		assert(absf(actor.locomotion.turn) < .1)
		node.rotation.y += PI
		step(actor,1.0/60,Vector3.ZERO,false)
		assert(absf(actor.locomotion.turn) <= 4)
		# Teleport or a dropped frame resets measured speed, never fabricates strides.
		before_phase = actor.locomotion.phase
		node.position.x += 100
		step(actor,1.0/60,Vector3.ZERO,false)
		assert(actor.locomotion.speed == 0 and actor.locomotion.phase == before_phase)
		step(actor,.5,Vector3(0,0,4.5),false)
		assert(actor.locomotion.speed == 0)
		# Old work/mount/weapon/emote poses own every channel after exclusion.
		actor.locomotion_allowed = func() -> bool: return false
		actor.animate(.016,false,false,false)
		assert(not actor.locomotion.active and actor.locomotion.pelvis_offset == 0)
		var pelvis: int = actor.bones.Pelvis
		assert(actor.skeleton.get_bone_pose_position(pelvis).is_equal_approx(actor.skeleton.get_bone_rest(pelvis).origin))
		actor.locomotion_allowed = Callable()
		actor.play("water"); actor.animate(.016,false,false,false)
		assert(not actor.locomotion.active and actor.can.visible)
		actor.action_time = 0; actor.airborne = true; actor.animate(.016,false,false,false)
		assert(not actor.locomotion.active)
		actor.airborne = false; actor.swimming = true; actor.animate(.016,false,false,false)
		assert(not actor.locomotion.active)
		actor.swimming = false
		assert(actor.emote("six_seven")); actor.animate(.016,false,false,false)
		assert(not actor.locomotion.active)
		actor.stop_emote(); actor.animate(.016,false,false,false)
		assert(actor.locomotion.active)
		node.free()
	await process_frame
	print("LOCOMOTION_OK: both rigs, loop endpoints, grounded feet, distance phase, smooth walk/run/stop, turn bounds, teleport and special-pose isolation")
	quit()
