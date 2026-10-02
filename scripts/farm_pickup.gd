class_name FarmPickup
extends CharacterBody3D
## Solo driving prototype. Its parked pose belongs to the selected farm save.
const HOME:=Vector2(-20,27)
const MAX_SPEED:=20.0
const REVERSE_SPEED:=6.0
const BODY_SIZE:=Vector3(2.55,2.3,5.95)
var game:Node3D
var model:Node3D
var wheels:Dictionary={}
var mounted:=false
var speed:=0.0
var steering:=0.0
var wheel_spin:=0.0
var speed_label:Label
var collision_box:BoxShape3D
var body_shell:CollisionShape3D
var engine_sound:AudioStreamPlayer3D
var engine_playback:AudioStreamGeneratorPlayback
var sound_phase:=0.0

static func defaults() -> Dictionary:return {"x":HOME.x,"z":HOME.y,"angle":PI*.5}
static func valid(value:Variant) -> bool:
	if not value is Dictionary:return false
	for key in ["x","z","angle"]:
		if not (value.get(key) is float or value.get(key) is int) or not is_finite(float(value[key])):return false
	return value.x>=FarmLandscape.WALK_MIN.x+4 and value.x<=FarmLandscape.WALK_MAX.x-4 and value.z>=FarmLandscape.WALK_MIN.y+4 and value.z<=FarmLandscape.WALK_MAX.y-4 and absf(value.angle)<=PI

func setup(owner_game:Node3D) -> void:
	game=owner_game;name="FarmPickup"
	model=load("res://assets/models/farm_pickup.glb").instantiate();add_child(model)
	for key in ["FL","FR","RL","RR"]:wheels[key]=model.find_child("Wheel_"+key,true,false)
	var support:=CollisionShape3D.new();var capsule:=CapsuleShape3D.new()
	capsule.radius=.65;capsule.height=2.7;support.shape=capsule;support.position.y=1.35;add_child(support)
	body_shell=CollisionShape3D.new();collision_box=BoxShape3D.new();collision_box.size=BODY_SIZE
	body_shell.shape=collision_box;body_shell.position.y=2.05;add_child(body_shell)
	floor_snap_length=.8;floor_stop_on_slope=true;floor_max_angle=deg_to_rad(28);floor_constant_speed=true
	speed_label=game.hud.label(game.hud.walking.root,"",Vector2(440,675),Vector2(560,42),21,FarmHUD.CREAM)
	speed_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;speed_label.visible=false
	speed_label.add_theme_color_override("font_shadow_color",Color("20392a"));speed_label.add_theme_constant_override("shadow_offset_y",2)
	engine_sound=AudioStreamPlayer3D.new();engine_sound.bus=FarmAudio.EFFECTS_BUS;engine_sound.volume_db=-22;engine_sound.max_distance=35
	var generator:=AudioStreamGenerator.new();generator.mix_rate=22050;generator.buffer_length=.15;engine_sound.stream=generator;add_child(engine_sound)
	restore(game.state.pickup)

func restore(data:Dictionary) -> void:
	reset_driver()
	var saved:Dictionary=data if valid(data) else defaults()
	var point:=Vector2(saved.x,saved.z)
	if FarmRegion.water_blocked(point):saved=defaults();point=HOME
	rotation=Vector3(0,saved.angle,0);position=Vector3(point.x,FarmLandscape.height_at(point)+.06,point.y)
	velocity=Vector3.ZERO;speed=0;steering=0;wheel_spin=0
	_animate(0)

func store() -> void:
	if game.network.active:return
	game.state.pickup={"x":position.x,"z":position.z,"angle":wrapf(rotation.y,-PI,PI)}

func available() -> bool:
	return game!=null and not game.network.active and game.session_started

func nearby() -> bool:
	return available() and not mounted and not game._mounted() and game.player.position.distance_to(position)<4.2 and absf(game.player.position.y-position.y)<1.5

func enter() -> bool:
	if not nearby() or game.build_mode or not game.hud.modal_kind.is_empty() or game.falls.local_down() or game.actor.airborne or game.actor.swimming:return false
	game._cancel_route();game.gathering.reset();game.weapons.holster();game.actor.stop_emote();game.actor.action_time=0
	game.companions.end_horse_call()
	mounted=true;speed=0;velocity=Vector3.ZERO
	add_collision_exception_with(game.player);game.player.add_collision_exception_with(self)
	game.yaw=rotation.y+PI;game.pitch=.32
	_pose_driver(0)
	return true

func exit_vehicle() -> bool:
	if not mounted:return true
	if absf(speed)>1.2:
		game.hud.toast("Pare a camionetinha antes de sair. Espaço freia.");return false
	for radius in [2.2,3.4,4.6,6.0]:
		for angle in [-PI/2,PI/2,PI*.75,-PI*.75,PI,0.0]:
			var point:Vector2=Vector2(position.x,position.z)+Vector2(sin(rotation.y+angle),cos(rotation.y+angle))*radius
			if not game.horse.safe_spot(point,game.player,game.state,game.world.landscape):continue
			reset_driver();game.player.position=Vector3(point.x,FarmLandscape.height_at(point)+.12,point.y)
			store();return true
	game.hud.toast("A porta está bloqueada. Estacione em um lugar mais aberto.")
	return false

func reset_driver() -> void:
	if mounted and game!=null:
		remove_collision_exception_with(game.player);game.player.remove_collision_exception_with(self)
		game.avatar.position=Vector3.ZERO;game.avatar.rotation=Vector3(0,rotation.y,0);game.actor.animate(0,false,false)
		game.player.velocity=Vector3.ZERO
	mounted=false;speed=0;velocity=Vector3.ZERO
	if is_instance_valid(speed_label):speed_label.visible=false
	if is_instance_valid(engine_sound):engine_sound.stop();engine_playback=null

func surface_allowed(at:Vector3,angle:float) -> bool:
	# Every reachable parking position must also be valid when loading its save.
	if not valid({"x":at.x,"z":at.z,"angle":wrapf(angle,-PI,PI)}):return false
	var basis:=Basis(Vector3.UP,angle)
	var low:=INF;var high:=-INF
	for x in [-1.3,0.0,1.3]:
		for z in [-3.1,0.0,3.1]:
			var sample:=at+basis*Vector3(x,0,z);var point:=Vector2(sample.x,sample.z)
			if point.x<FarmLandscape.WALK_MIN.x+1 or point.x>FarmLandscape.WALK_MAX.x-1 or point.y<FarmLandscape.WALK_MIN.y+1 or point.y>FarmLandscape.WALK_MAX.y-1:return false
			if FarmRegion.water_blocked(point):return false
			var height:=FarmLandscape.height_at(point);low=minf(low,height);high=maxf(high,height)
	return high-low<2.5

func turn_clear(angle:float) -> bool:
	return clear_at(position,angle)

func clear_at(at:Vector3,angle:float) -> bool:
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=collision_box;query.collision_mask=1
	query.exclude=[get_rid(),game.player.get_rid()]
	var basis:=Basis(Vector3.UP,angle)*Basis.from_euler(ground_tilt(at,angle))
	query.transform=Transform3D(basis,at+basis*Vector3.UP*2.05)
	return get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()

func ground_tilt(at:Vector3,angle:float) -> Vector3:
	var center:=Vector2(at.x,at.z)
	var forward:=Vector2(sin(angle),cos(angle))*1.85
	var side:=Vector2(cos(angle),-sin(angle))*1.18
	return Vector3(clampf(atan2(FarmLandscape.height_at(center-forward)-FarmLandscape.height_at(center+forward),3.7),-.38,.38),0,clampf(atan2(FarmLandscape.height_at(center+side)-FarmLandscape.height_at(center-side),2.36),-.32,.32))

func parking_clear(at:Vector3) -> bool:
	if not surface_allowed(at,rotation.y):return false
	var half:=Vector2(absf(cos(rotation.y))*1.4+absf(sin(rotation.y))*3.2,absf(sin(rotation.y))*1.4+absf(cos(rotation.y))*3.2)
	var area:=Rect2(Vector2(at.x,at.z)-half,half*2)
	for item in game.state.items:
		if item.kind not in ["plot","path"] and game.state.item_rect(item.kind,Vector2(item.x,item.z),item.turn).intersects(area):return false
	return clear_at(at,rotation.y)

func ensure_parking() -> void:
	if mounted or game.network.active or parking_clear(position):return
	var origin:=Vector2(position.x,position.z)
	for radius in [4,8,12,18,26]:
		for i in range(16):
			var point:Vector2=origin+Vector2.from_angle(i*TAU/16)*radius
			var at:=Vector3(point.x,FarmLandscape.height_at(point)+.06,point.y)
			if parking_clear(at):position=at;velocity=Vector3.ZERO;store();return

func drive(delta:float,throttle:float,turn:float,brake:bool,active:bool) -> void:
	if not mounted:return
	delta=clampf(delta,0,.05)
	if not active:
		speed=0;velocity=Vector3.ZERO;steering=move_toward(steering,0,delta*2)
		_pose_driver(delta);_animate(0);return
	steering=move_toward(steering,clampf(turn,-1,1)*.5,delta*1.8)
	var target:=MAX_SPEED*throttle if throttle>=0 else REVERSE_SPEED*throttle
	speed=move_toward(speed,0 if brake else target,delta*(22 if brake else 7 if throttle!=0 else 4))
	var before:=global_transform
	var candidate:=wrapf(rotation.y-steering*speed/3.7*delta,-PI,PI)
	if turn_clear(candidate):rotation.y=candidate
	var forward:=global_basis.z
	velocity.x=forward.x*speed;velocity.z=forward.z*speed;velocity.y-=22*delta
	move_and_slide()
	if not surface_allowed(position,rotation.y):
		global_transform=before;velocity=Vector3.ZERO;speed=0
	elif get_slide_collision_count()>0:
		for i in range(get_slide_collision_count()):
			if absf(get_slide_collision(i).get_normal().y)<.65:speed=0;break
	var travel:=position.distance_to(before.origin)
	wheel_spin+=travel*signf(speed)/.65
	_pose_driver(delta);_animate(delta);store()

func _pose_driver(delta:float) -> void:
	game.player.position=position;game.player.velocity=Vector3.ZERO
	game.actor.airborne=false;game.actor.swimming=false;game.actor.animate(delta,false,false)
	game.avatar.global_transform=Transform3D(global_basis*model.basis,model.to_global(Vector3(-.53,.35,-.19)))
	game.actor.pose_bone("Spine",Vector3(.06,0,0))
	for side in ["L","R"]:
		var sign_value:=1.0 if side=="R" else -1.0
		game.actor.pose_bone("Thigh."+side,Vector3(-1.3,0,sign_value*.1))
		game.actor.pose_bone("Shin."+side,Vector3(1.5,0,0))
		game.actor.pose_bone("Foot."+side,Vector3(-.15,0,0))
		game.actor.pose_bone("UpperArm."+side,Vector3(-.6,0,-sign_value*.2))
		game.actor.pose_bone("Forearm."+side,Vector3(-1,0,0))
		game.actor.reach_rein_hand(side,model.to_global(Vector3(-.53+sign_value*.22,2.30,.50)),1)

func _animate(_delta:float) -> void:
	if is_instance_valid(model):
		model.rotation=ground_tilt(position,rotation.y)
		body_shell.basis=model.basis;body_shell.position=model.basis*Vector3.UP*2.05
	for key in wheels:
		if is_instance_valid(wheels[key]):wheels[key].rotation=Vector3(wheel_spin,-steering if key.begins_with("F") else 0,0)
	if is_instance_valid(speed_label):
		speed_label.visible=mounted and game.hud.modal_kind.is_empty() and game.session_started
		speed_label.text="CAMIONETINHA · %d km/h%s"%[roundi(absf(speed)*3.6)," · RÉ" if speed<-.2 else ""]

func _physics_process(delta:float) -> void:
	if game==null:return
	visible=not game.network.active
	collision_layer=1 if visible else 0
	if mounted and (game.falls.local_down() or game.network.active):reset_driver()
	if not mounted and visible:
		velocity=Vector3(0,velocity.y-22*delta,0);move_and_slide()
	_animate(delta)
	_update_sound()

func _update_sound() -> void:
	var playing:bool=mounted and available() and game.hud.modal_kind.is_empty()
	if not playing:
		engine_sound.stop();engine_playback=null;return
	if not engine_sound.playing:
		engine_sound.play();engine_playback=engine_sound.get_stream_playback()
	if engine_playback==null:return
	var rpm:=26+absf(speed)*3.2
	for i in range(engine_playback.get_frames_available()):
		sound_phase=fmod(sound_phase+rpm/22050,1)
		var sample:=sin(sound_phase*TAU)*.24+sin(sound_phase*TAU*2)*.12+sin(sound_phase*TAU*5)*.045
		engine_playback.push_frame(Vector2.ONE*sample)
