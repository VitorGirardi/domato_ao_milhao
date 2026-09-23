class_name FarmHorse
extends Node3D
signal encouraged
var rider_actor:FarmAvatar
const HOME:=Vector2(-30,5)
var reins:=ImmediateMesh.new()
var rein_ends:Array=[]
var rein_material:=StandardMaterial3D.new()
var life:=FarmHorseLife.new()
var part_home:Dictionary={}
var mounted:=false
var stamina:=100.0
var burst:=0.0
var pat_time:=0.0
var gait:=0.0
var speed:=0.0
var heading:=0.0
var model:Node3D
var obstacle:=StaticBody3D.new()
var shape_node:=CollisionShape3D.new()
var parts:Dictionary={}
var body_home:=Vector3.ZERO
var label:=Label3D.new()
var walk_shape:Shape3D
var rider_collision:CollisionShape3D
var snapshot:Dictionary={}
var skin:Skeleton3D
var skin_bones:Dictionary={}
var skin_rest:Dictionary={}

static func defaults() -> Dictionary:return {"x":HOME.x,"z":HOME.y,"angle":0.0}
static func valid(value:Variant) -> bool:
	if not value is Dictionary:return false
	for key in ["x","z","angle"]:
		if not (value.get(key) is float or value.get(key) is int) or not is_finite(float(value[key])):return false
	return value.x>=FarmLandscape.WALK_MIN.x+1 and value.x<=FarmLandscape.WALK_MAX.x-1 and value.z>=FarmLandscape.WALK_MIN.y+1 and value.z<=FarmLandscape.WALK_MAX.y-1 and absf(value.angle)<=TAU

func _ready() -> void:
	model=load("res://assets/models/horse.glb").instantiate();add_child(model)
	for key in ["HorseBody","HorseNeck","HorseTail","FrontL","FrontR","HindL","HindR","FrontLLower","FrontRLower","HindLLower","HindRLower"]:
		parts[key]=model.find_child(key,true,false);assert(parts[key]!=null,key)
	skin=model.find_child("Skeleton3D",true,false) as Skeleton3D
	assert(skin!=null,"Continuous horse rig missing")
	for key in parts:
		var index:=skin.find_bone("Skin"+key)
		if index>=0:
			skin_bones[key]=index;skin_rest[key]=skin.get_bone_global_rest(index).basis.get_rotation_quaternion()
	for key in parts:part_home[key]=parts[key].position
	body_home=parts.HorseBody.position
	var strings:=MeshInstance3D.new();strings.mesh=reins;add_child(strings)
	rein_material.albedo_color=Color("493325");rein_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	for side in [-1.0,1.0]:
		var original:=model.find_child("ReinL" if side<0 else "ReinR",true,false) as Node3D
		assert(original!=null);original.visible=false
		rein_ends.append([parts.HorseNeck.to_local(to_global(Vector3(side*.1725,2.18,1.62))),parts.HorseBody.to_local(to_global(Vector3(side*.25,2.06,.32)))])
	var shape:=BoxShape3D.new();shape.size=Vector3(1.05,2.4,2.8);shape_node.shape=shape;shape_node.position=Vector3(0,1.2,.15)
	obstacle.add_child(shape_node);add_child(obstacle)
	label.text="PÉ DE PANO";label.position=Vector3(0,3.1,0);label.font_size=32;label.pixel_size=.012;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;add_child(label)
	restore(defaults())

func restore(data:Dictionary) -> void:
	heading=data.angle;rotation.y=heading;position=Vector3(data.x,FarmLandscape.height_at(Vector2(data.x,data.z)),data.z)
	snapshot=data.duplicate();burst=0;speed=0;life.reset(self)

func store(state:FarmState) -> void:
	state.horse={"x":position.x,"z":position.z,"angle":wrapf(heading,-PI,PI)}
	snapshot=state.horse.duplicate()

func can_mount(player:CharacterBody3D) -> bool:
	return not mounted and player.position.distance_to(position)<2.8 and player.is_on_floor()

func mount(player:CharacterBody3D,avatar:Node3D,actor:FarmAvatar) -> void:
	rider_actor=actor
	mounted=true;obstacle.collision_layer=0;label.visible=false
	parts.HorseNeck.position=part_home.HorseNeck;parts.HorseNeck.rotation=Vector3.ZERO;life.reset(self)
	rider_collision=player.get_child(0) as CollisionShape3D;walk_shape=rider_collision.shape
	var shape:=BoxShape3D.new();shape.size=Vector3(1.15,3.65,3.25)
	rider_collision.shape=shape;rider_collision.position=Vector3(0,1.825,.15);rider_collision.rotation.y=heading
	player.position=position+Vector3.UP*.06;player.velocity=Vector3.ZERO;avatar.rotation.y=heading
	actor.stop_emote();actor.action_time=0;actor.airborne=false

func safe_spot(p:Vector2,player:CharacterBody3D,state:FarmState,landscape:FarmLandscape) -> bool:
	if p.x<FarmLandscape.WALK_MIN.x+.6 or p.x>FarmLandscape.WALK_MAX.x-.6 or p.y<FarmLandscape.WALK_MIN.y+.6 or p.y>FarmLandscape.WALK_MAX.y-.6:return false
	if not landscape.clear_for_player(p):return false
	for item in state.items:
		if item.kind not in ["plot","path"] and state.item_rect(item.kind,Vector2(item.x,item.z),item.turn).grow(.5).has_point(p):return false
	var query:=PhysicsShapeQueryParameters3D.new();var capsule:=CapsuleShape3D.new();capsule.radius=.39;capsule.height=2.58
	query.shape=capsule;query.transform=Transform3D(Basis.IDENTITY,Vector3(p.x,FarmLandscape.height_at(p)+1.40,p.y));query.exclude=[player.get_rid()];query.collision_mask=1
	return get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()

func dismount(player:CharacterBody3D,avatar:Node3D,actor:FarmAvatar,state:FarmState,landscape:FarmLandscape) -> bool:
	if not mounted:return true
	# Search beside, behind and ahead. Never eject the rider through a building.
	for radius in [1.65,2.4,3.2]:
		for angle in [PI/2,-PI/2,PI,0.0,PI*.75,-PI*.75]:
			var offset:Vector3=Vector3(sin(heading+angle),0,cos(heading+angle))*radius
			var p:=Vector2(position.x+offset.x,position.z+offset.z)
			if not safe_spot(p,player,state,landscape):continue
			mounted=false;burst=0;pat_time=0;speed=0
			rider_collision.shape=walk_shape;rider_collision.position=Vector3(0,1.29,0);rider_collision.rotation=Vector3.ZERO
			player.position=Vector3(p.x,FarmLandscape.height_at(p)+.12,p.y);player.velocity=Vector3.ZERO
			avatar.position=Vector3.ZERO;avatar.rotation=Vector3(0,heading,0);actor.animate(1,false,false)
			obstacle.collision_layer=1;label.visible=true;store(state);life.reset(self);return true
	return false

func encourage() -> bool:
	if not mounted or pat_time>0 or stamina<25:return false
	stamina-=25;burst=3.5;pat_time=.55
	encouraged.emit()
	return true

func drive(player:CharacterBody3D,avatar:Node3D,actor:FarmAvatar,direction:Vector3,delta:float,active:bool) -> void:
	if active:
		burst=maxf(0,burst-delta);pat_time=maxf(0,pat_time-delta)
		stamina=minf(100,stamina+delta*(7 if burst<=0 else 0))
	var moving:=active and direction.length()>.01
	var target_speed:=14.0 if burst>0 else 8.0
	speed=move_toward(speed,target_speed if moving else 0,delta*(11 if moving else 19))
	if moving:heading=lerp_angle(heading,atan2(direction.x,direction.z),1-exp(-delta*5))
	var forward:=Vector3(sin(heading),0,cos(heading))
	player.velocity.x=forward.x*speed;player.velocity.z=forward.z*speed
	if not active:player.velocity.x=0;player.velocity.z=0;speed=0
	player.velocity.y-=18*delta;rider_collision.rotation.y=heading;player.move_and_slide()
	player.position.x=clampf(player.position.x,FarmLandscape.WALK_MIN.x+.8,FarmLandscape.WALK_MAX.x-.8)
	player.position.z=clampf(player.position.z,FarmLandscape.WALK_MIN.y+.8,FarmLandscape.WALK_MAX.y-.8)
	position=player.position;rotation.y=heading;avatar.rotation.y=heading
	var actual:=Vector2(player.get_real_velocity().x,player.get_real_velocity().z).length()
	animate(delta if active else 0,actual,burst>0)
	actor.animate(delta if active else 0,false,false)
	pose_rider(avatar,actor)

func pose_rider(avatar:Node3D,actor:FarmAvatar) -> void:
	rider_actor=actor
	avatar.position=Vector3(0,1.04+(parts.HorseBody.position.y-body_home.y),-.04)
	var tap:=sin(clampf(1-pat_time/.55,0,1)*PI) if pat_time>0 else 0.0
	actor.pose_bone("Spine",Vector3((.08 if burst<=0 else .17)+tap*.35,0,0))
	actor.pose_bone("Chest",Vector3.ZERO)
	for side in ["L","R"]:
		var sign_value:=1.0 if side=="R" else -1.0
		actor.pose_bone("Thigh."+side,Vector3(-.72,0,sign_value*.85))
		actor.pose_bone("Shin."+side,Vector3(1.05,0,0))
		actor.pose_bone("Foot."+side,Vector3(-.38,0,0))
		actor.pose_bone("UpperArm."+side,Vector3(-.60,0,-sign_value*.45))
		actor.pose_bone("Forearm."+side,Vector3(-.85,0,0))
		actor.pose_bone("Hand."+side,Vector3.ZERO)
	if pat_time>0:
		actor.reach_rein_hand("R",to_global(Vector3(.28,2.30,.76)),tap)
	update_reins()

func animate(delta:float,velocity:float,running:bool) -> void:
	gait+=delta*(12 if running else lerpf(2.5,7,clampf(velocity/6,0,1)))
	var moving:=velocity>.3;var amount:=minf(1,velocity)
	parts.HorseBody.position=body_home+Vector3(0,absf(sin(gait if running else gait*2))*(.045 if running else .015)*amount,0)
	parts.HorseNeck.rotation.x=sin(gait*(.65 if not moving else 1))*(.045 if not moving else .025)
	parts.HorseTail.rotation.z=sin(gait*.45)*.16
	for i in range(4):
		var key:String=["FrontL","FrontR","HindL","HindR"][i]
		# Four separate footfalls at a walk; paired gathered/extended phases at a gallop.
		var phase:float=gait+([0.0,.45,PI,PI+.45][i] if running else [0.0,PI,PI*.5,PI*1.5][i])
		parts[key].rotation.x=sin(phase)*(.58 if running else .37)*amount
		parts[key+"Lower"].rotation.x=maxf(0,-sin(phase))*.65*amount

	sync_skin()

func sync_skin() -> void:
	# Match the continuous skin to the same joint motions as the tack and eyes.
	for key in skin_bones:
		var index:int=skin_bones[key]
		var rest:Quaternion=skin_rest[key]
		var pose:Quaternion=parts[key].quaternion
		skin.set_bone_pose_rotation(index,skin.get_bone_rest(index).basis.get_rotation_quaternion()*rest.inverse()*pose*rest)
		skin.set_bone_pose_position(index,skin.get_bone_rest(index).origin+parts[key].position-part_home[key])
	var body_index:int=skin_bones.HorseBody
	skin.set_bone_pose_position(body_index,skin.get_bone_rest(body_index).origin+parts.HorseBody.position-body_home)
	update_reins()

func rein_end(index:int) -> Vector3:
	if mounted and rider_actor!=null:
		# The left hand holds both reins while the right gives the neck a pat.
		var side:="L" if index==0 or pat_time>0 else "R"
		return to_local(rider_actor.rein_grip_world(side))
	return to_local(parts.HorseBody.to_global(rein_ends[index][1]))

func update_reins() -> void:
	reins.clear_surfaces()
	for index in range(rein_ends.size()):
		var start:=to_local(parts.HorseNeck.to_global(rein_ends[index][0]))
		var end:=rein_end(index)
		# Round leather cord retains its width from every camera angle.
		reins.surface_begin(Mesh.PRIMITIVE_TRIANGLES,rein_material)
		var points:Array[Vector3]=[]
		for i in range(17):
			var t:=i/16.0
			var point:=start.lerp(end,t)
			if mounted and pat_time>0 and index==1:
				# Bring the right cord around the flank of the neck before crossing to the left palm.
				var guide:=Vector3(.38,end.y-.08,.40)
				point=start.lerp(guide,t/.65) if t<.65 else guide.lerp(end,(t-.65)/.35)
			points.append(point-Vector3.UP*sin(t*PI)*(.09 if mounted else .16))
		for i in range(16):
			var tangent:Vector3=(points[i+1]-points[i]).normalized()
			var across:=tangent.cross(Vector3.UP).normalized()*.009
			if across.length_squared()<.000001:across=Vector3.RIGHT*.009
			var up:=tangent.cross(across).normalized()*.009
			for j in range(6):
				var a:=across*cos(j*TAU/6)+up*sin(j*TAU/6)
				var b:=across*cos((j+1)*TAU/6)+up*sin((j+1)*TAU/6)
				for vertex in [points[i]+a,points[i+1]+a,points[i+1]+b,points[i]+a,points[i+1]+b,points[i]+b]:
					reins.surface_add_vertex(vertex)
		reins.surface_end()

func reset_rider(player:CharacterBody3D,avatar:Node3D,actor:FarmAvatar) -> void:
	if not mounted:return
	mounted=false;burst=0;pat_time=0;speed=0
	rider_collision.shape=walk_shape;rider_collision.position=Vector3(0,1.29,0);rider_collision.rotation=Vector3.ZERO
	player.velocity=Vector3.ZERO;avatar.position=Vector3.ZERO;avatar.rotation=Vector3(0,heading,0)
	actor.animate(1,false,false);obstacle.collision_layer=1;label.visible=true

func parking_clear(p:Vector2,state:FarmState,landscape:FarmLandscape) -> bool:
	if p.x<FarmLandscape.WALK_MIN.x+2 or p.x>FarmLandscape.WALK_MAX.x-2 or p.y<FarmLandscape.WALK_MIN.y+2 or p.y>FarmLandscape.WALK_MAX.y-2:return false
	for item in state.items:
		if item.kind not in ["plot","path"] and state.item_rect(item.kind,Vector2(item.x,item.z),item.turn).grow(1.8).has_point(p):return false
	for i in range(8):
		if not landscape.clear_for_player(p+Vector2(sin(i*TAU/8),cos(i*TAU/8))*1.4):return false
	return true

func ensure_parking(state:FarmState,landscape:FarmLandscape) -> void:
	if mounted:return
	var origin:=Vector2(position.x,position.z)
	if parking_clear(origin,state,landscape):return
	for center in [origin,HOME]:
		for radius in range(2,16,2):
			for i in range(12):
				var p:Vector2=center+Vector2(sin(i*TAU/12),cos(i*TAU/12))*radius
				if parking_clear(p,state,landscape):
					position=Vector3(p.x,FarmLandscape.height_at(p),p.y);store(state);return
