class_name FarmTemporaryFall
extends Node
## Temporary, host-authoritative play state. Never serialized into a farm save.
const DOWN_SECONDS:=60.0
const RECOVERY_SECONDS:=2.0
const PROTECTION_SECONDS:=3.0
var game:Node3D
var targets:Dictionary={}
var records:Dictionary={}
var protected:Dictionary={}
var sequence:=0
var received:=-1
var sync_wait:=0.0
var refresh_wait:=0.0
var last_state:FarmState
var star_mesh:ArrayMesh
var star_material:StandardMaterial3D

func setup(g:Node3D) -> void:
	game=g;name="TemporaryFall";process_priority=100;process_physics_priority=100
	last_state=game.state
	star_material=StandardMaterial3D.new();star_material.albedo_color=Color("ffe58b")
	star_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	star_material.cull_mode=BaseMaterial3D.CULL_DISABLED
	var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(10):
		var a:=TAU*i/10;var b:=TAU*(i+1)/10
		surface.add_vertex(Vector3.ZERO)
		surface.add_vertex(Vector3(cos(a),sin(a),0)*(.14 if i%2==0 else .065))
		surface.add_vertex(Vector3(cos(b),sin(b),0)*(.14 if (i+1)%2==0 else .065))
	star_mesh=surface.commit()
	refresh_targets()

func authority() -> bool:return not game.network.active or game.network.hosting
func own_id() -> int:return multiplayer.get_unique_id() if game.network.active else 1
func player_key(id:int=0) -> String:return "player:%d"%(own_id() if id==0 else id)
func local_down() -> bool:return is_player_down()
func is_player_down(id:int=0) -> bool:return is_down(player_key(id))
func is_down(key:String) -> bool:return records.has(key)

func refresh_targets() -> void:
	if game==null or not is_instance_valid(game.world):return
	targets=FarmFallTargets.collect(game)
	FarmFallTargets.add(targets,player_key(),game.player,game.avatar,game.actor,"human",.43,2.58,-1,true)
	if game.network.active and is_instance_valid(game.network.remote):
		FarmFallTargets.add(targets,player_key(game.network.accepted),game.network.remote,game.network.remote_model,game.network.remote_actor,"human",.43,2.58,-1,true)
	for key in records:
		var record:Dictionary=records[key]
		if not targets.has(key):continue
		if record.has("entry") and is_instance_valid(record.entry.model) and record.entry.model==targets[key].model:continue
		_bind(key,record)

func _colliders(node:Node,result:Array[CollisionObject3D]) -> void:
	if node is CollisionObject3D:result.append(node)
	for child in node.get_children():_colliders(child,result)

func _bind(key:String,record:Dictionary) -> void:
	var entry:Dictionary=targets[key].duplicate()
	entry.body.global_position=record.position
	entry.body.set_meta("temporary_down",true);entry.model.set_meta("temporary_down",true)
	if entry.actor:
		entry.actor.stop_emote();entry.actor.action_time=0;entry.actor.airborne=false;entry.actor.swimming=false
		entry.model.rotation.x=0;entry.model.rotation.z=0
		if entry.model!=entry.body:entry.model.position.y=0
	entry.base_transform=record.get("pose_base",entry.model.transform)
	entry.model.transform=entry.base_transform
	record.pose_base=entry.base_transform
	var support:=_support_at(record.position)
	if support.y>FarmLandscape.height_at(Vector2(support.x,support.z))+.2:entry.ground_y=support.y
	FarmFallPose.prepare(entry)
	if record.has("part_rest"):
		for part_name in record.part_rest:
			if entry.fall_pose.parts.has(part_name):entry.fall_pose.parts[part_name].rest=record.part_rest[part_name]
	else:
		record.part_rest={}
		for part_name in entry.fall_pose.parts:record.part_rest[part_name]=entry.fall_pose.parts[part_name].rest
	var colliders:Array[CollisionObject3D]=[];_colliders(entry.body,colliders)
	entry.layers=[]
	for collider in colliders:
		entry.layers.append([collider,collider.collision_layer]);collider.collision_layer=0
	entry.props=[]
	var props:Array=[]
	if key=="npc:dairy":props=[game.world.raul_motion.can,game.world.raul_motion.sack,game.world.raul_motion.stream,game.world.raul_motion.liquid]
	if key=="npc:cheese":props=[game.world.chico_motion.milk,game.world.chico_motion.tray]
	for prop in props:
		if is_instance_valid(prop):entry.props.append([prop,prop.visible]);prop.visible=false
	record.entry=entry
	if not record.has("stars") or not is_instance_valid(record.stars):
		var stars:=Node3D.new();add_child(stars);record.stars=stars
		for i in range(3):
			var star:=MeshInstance3D.new();star.mesh=star_mesh;star.material_override=star_material;stars.add_child(star)

func _restore(record:Dictionary) -> void:
	if record.has("entry"):
		var entry:Dictionary=record.entry
		if is_instance_valid(entry.model):
			FarmFallPose.reset(entry);entry.model.set_meta("temporary_down",false)
		if is_instance_valid(entry.body):entry.body.set_meta("temporary_down",false)
		for pair in entry.get("layers",[]):
			if is_instance_valid(pair[0]):pair[0].collision_layer=pair[1]
		for pair in entry.get("props",[]):
			if is_instance_valid(pair[0]):pair[0].visible=pair[1]
	if record.has("stars") and is_instance_valid(record.stars):record.stars.queue_free()

func reset() -> void:
	for record in records.values():_restore(record)
	records.clear();protected.clear();sequence=0;received=-1;sync_wait=0
	if game!=null:
		game.state.temporary_down.clear();last_state=game.state

func blocks_command(command:Dictionary) -> bool:
	var action:String=command.get("action","")
	if action not in ["move_item","move","remove"]:return false
	var index:int=command.get("index",-1)
	refresh_targets()
	for key in records:
		if targets.has(key) and int(targets[key].get("item_index",-1))==index and index>=0:return true
	return false

func force_dismount() -> void:
	if game.network.active:
		game.network.mounts.force_dismount()
	elif game.horse.mounted:
		if not game.horse.dismount(game.player,game.avatar,game.actor,game.state,game.world.landscape):
			game.horse.reset_rider(game.player,game.avatar,game.actor)
			game.player.position=_safe_recovery(game.player.position)

func _stop_local_actions() -> void:
	game.weapons.holster();game.hud.close_modal();game._cancel_route()
	game.build_mode=false;game.tool="inspect";game.move_index=-1

func knock_down(key:String) -> bool:
	if not authority() or is_down(key) or float(protected.get(key,0))>0:return false
	refresh_targets()
	if not targets.has(key):return false
	var id:=int(key.get_slice(":",1)) if key.begins_with("player:") else 0
	if key=="horse" or (id!=0 and ((game.network.active and game.network.mounts.rider==id) or (not game.network.active and game.horse.mounted))):
		force_dismount();refresh_targets()
	if not targets.has(key):return false
	if id!=0:
		game.gathering._stop(id,"")
		game.companions.gestures.erase(id)
		if game.companions.horse_owner==id:game.companions.end_horse_call()
		if game.companions.follow_owner==id:
			game.companions.follow_owner=0;game.world.cat.following=false
		if id==own_id():
			_stop_local_actions()
	if key=="horse":game.companions.end_horse_call()
	if key=="cat":game.companions.follow_owner=0;game.world.cat.following=false;game.companions.path.clear()
	var entry:Dictionary=targets[key]
	var record:Dictionary={"age":0.0,"position":entry.body.global_position}
	records[key]=record;_bind(key,record);_sync_flags();sync_wait=0
	if game.network.active and game.network.accepted!=0:sync_to(game.network.accepted)
	return true

func _support_at(at:Vector3) -> Vector3:
	var excluded:Array[RID]=[]
	for entry in targets.values():
		var bodies:Array[CollisionObject3D]=[];_colliders(entry.body,bodies)
		for body in bodies:excluded.append(body.get_rid())
	var query:=PhysicsRayQueryParameters3D.create(at+Vector3.UP*.15,at+Vector3.DOWN*80,1,excluded)
	var floor_hit:=game.get_world_3d().direct_space_state.intersect_ray(query)
	if not floor_hit.is_empty() and floor_hit.normal.y>.4:return floor_hit.position
	return at

func _safe_recovery(at:Vector3) -> Vector3:
	var flat:=Vector2(at.x,at.z)
	var capsule:=CapsuleShape3D.new();capsule.radius=.42;capsule.height=2.58
	var excluded:Array[RID]=[]
	for entry in targets.values():
		var bodies:Array[CollisionObject3D]=[];_colliders(entry.body,bodies)
		for body in bodies:excluded.append(body.get_rid())
	for radius in range(0,161,2):
		for i in range(1 if radius==0 else 24):
			var point:=flat+Vector2.from_angle(i*TAU/24)*radius
			if point.x<FarmLandscape.WALK_MIN.x+.5 or point.x>FarmLandscape.WALK_MAX.x-.5 or point.y<FarmLandscape.WALK_MIN.y+.5 or point.y>FarmLandscape.WALK_MAX.y-.5:continue
			if FarmRegion.water_blocked(point) or not game.world.landscape.clear_for_player(point):continue
			var position:=Vector3(point.x,FarmLandscape.height_at(point)+.06,point.y)
			var query:=PhysicsShapeQueryParameters3D.new();query.shape=capsule;query.collision_mask=1;query.exclude=excluded
			query.transform=Transform3D(Basis.IDENTITY,position+Vector3.UP*1.31)
			if game.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty():return position
	return at

func _start_recovery(key:String,record:Dictionary) -> void:
	if not record.has("entry") or not is_instance_valid(record.entry.model):return
	var entry:Dictionary=record.entry
	var at:Vector3=record.position
	var safe:=at
	# Ordinary land actors rise where they fell. Only an unsafe water position
	# needs a nearby dry return, instead of reviving below the lake surface.
	if FarmWater.immersion(at)>.12 or at.y<FarmLandscape.height_at(Vector2(at.x,at.z))-.5:
		safe=_safe_recovery(at)
	elif key.begins_with("player:"):
		var support:=_support_at(at)
		if at.y-support.y>.15:safe=support+Vector3.UP*.03
	if not safe.is_equal_approx(at):
		FarmFallPose.reset(entry);entry.body.global_position=safe
		entry.base_transform=entry.model.transform;record.pose_base=entry.base_transform;record.position=safe
		if game.network.active and key==player_key(game.network.accepted):game.network.target=safe
	if key.begins_with("player:") and int(key.get_slice(":",1))==own_id():game.player.velocity=Vector3.ZERO

func _sync_flags() -> void:
	game.state.temporary_down.clear()
	for key in records:game.state.temporary_down[key]=true

func advance(delta:float) -> void:
	for key in protected.keys():
		protected[key]=maxf(0,float(protected[key])-delta)
		if protected[key]<=0:protected.erase(key)
	for key in records.keys():
		var record:Dictionary=records[key]
		var before:float=record.age;record.age=minf(DOWN_SECONDS+RECOVERY_SECONDS,before+delta)
		if authority() and before<DOWN_SECONDS and record.age>=DOWN_SECONDS:_start_recovery(key,record)
		if authority() and record.age>=DOWN_SECONDS+RECOVERY_SECONDS:
			_restore(record);records.erase(key);protected[key]=PROTECTION_SECONDS;sync_wait=0
	_sync_flags()

func _process(delta:float) -> void:
	if game==null:return
	if last_state!=game.state:
		if not game.network.active:reset()
		last_state=game.state
	if not game.session_started:return
	refresh_wait-=delta
	if refresh_wait<=0:refresh_targets();refresh_wait=.2
	if game.network.active or (not game.build_mode and game.hud.modal_kind.is_empty()):advance(delta)
	if authority():
		for key in records.keys():
			if not targets.has(key):_restore(records[key]);records.erase(key)
		if game.network.active and game.network.accepted!=0:
			sync_wait-=delta
			if sync_wait<=0:sync_to(game.network.accepted);sync_wait=.25
	apply_poses()

func _physics_process(_delta:float) -> void:
	if game!=null and game.session_started:apply_poses()

func apply_poses() -> void:
	for record in records.values():
		if not record.has("entry"):continue
		var entry:Dictionary=record.entry
		if not is_instance_valid(entry.model) or not is_instance_valid(entry.body):continue
		if entry.body!=entry.model:entry.body.global_position=record.position
		if entry.body is CharacterBody3D:entry.body.velocity=Vector3.ZERO
		# Reapply articulation after interpolation; terrain fitting is cached.
		FarmFallPose.apply(entry,maxf(0,record.age-DOWN_SECONDS) if record.age>=DOWN_SECONDS else record.age,record.age>=DOWN_SECONDS)
		if record.has("stars") and is_instance_valid(record.stars):
			record.stars.visible=record.age>1 and record.age<DOWN_SECONDS
			record.stars.global_position=record.position+Vector3.UP*maxf(.6,float(entry.height)*.45)
			for i in range(3):
				var star:Node3D=record.stars.get_child(i);var angle:float=record.age*2+i*TAU/3
				star.position=Vector3(cos(angle)*.4,sin(angle*2)*.07,sin(angle)*.4)
				star.global_basis=game.camera.global_basis

func sync_to(peer_id:int) -> void:
	if not game.network.active or not game.network.hosting or peer_id==0:return
	var payload:Array=[]
	for key in records:
		var record:Dictionary=records[key]
		payload.append({"key":key,"age":record.age,"position":record.position,"pose_base":record.pose_base,"part_rest":record.part_rest})
	sequence+=1;_snapshot.rpc_id(peer_id,sequence,payload,protected)

@rpc("authority","call_remote","reliable",0)
func _snapshot(number:int,payload:Array,protection:Dictionary) -> void:
	if not game.network.ready_session or game.network.hosting or number<=received:return
	received=number;refresh_targets()
	var keep:Dictionary={}
	for data in payload:
		if not data is Dictionary or not data.get("key") is String or not data.get("position") is Vector3 or not data.get("pose_base") is Transform3D or not data.get("part_rest") is Dictionary:continue
		var key:String=data.key
		if not data.position.is_finite() or not is_finite(float(data.get("age",-1))) or float(data.age)<0:continue
		keep[key]=true
		if not records.has(key):
			records[key]={"age":float(data.age),"position":data.position,"pose_base":data.pose_base,"part_rest":data.part_rest}
			if targets.has(key):_bind(key,records[key])
			if key==player_key():_stop_local_actions()
		else:
			var record:Dictionary=records[key]
			if record.position.distance_to(data.position)>.01 and record.has("entry") and is_instance_valid(record.entry.model):
				FarmFallPose.reset(record.entry);record.entry.body.global_position=data.position;record.entry.base_transform=data.pose_base
			record.pose_base=data.pose_base;record.position=data.position;record.age=float(data.age)
	for key in records.keys():
		if not keep.has(key):_restore(records[key]);records.erase(key)
	protected=protection.duplicate();_sync_flags();apply_poses()

static func _sphere_hit(origin:Vector3,direction:Vector3,center:Vector3,radius:float) -> float:
	var offset:=origin-center;var b:=offset.dot(direction);var c:=offset.length_squared()-radius*radius
	if c<=0:return 0
	var discriminant:=b*b-c
	return -b-sqrt(discriminant) if discriminant>=0 and -b-sqrt(discriminant)>=0 else INF

static func _capsule_hit(origin:Vector3,direction:Vector3,foot:Vector3,radius:float,height:float) -> float:
	var lower:=foot+Vector3.UP*radius;var upper:=foot+Vector3.UP*maxf(radius,height-radius)
	var best:=minf(_sphere_hit(origin,direction,lower,radius),_sphere_hit(origin,direction,upper,radius))
	var offset:=origin-foot;var a:=direction.x*direction.x+direction.z*direction.z
	var b:=offset.x*direction.x+offset.z*direction.z;var c:=offset.x*offset.x+offset.z*offset.z-radius*radius
	if c<=0 and origin.y>=lower.y and origin.y<=upper.y:return 0
	if a>.000001 and b*b-a*c>=0:
		var distance:=(-b-sqrt(b*b-a*c))/a;var y:=origin.y+direction.y*distance
		if distance>=0 and y>=lower.y and y<=upper.y:best=minf(best,distance)
	return best

func trace_hit(origin:Vector3,end:Vector3,shooter_id:int) -> Dictionary:
	if not origin.is_finite() or not end.is_finite() or origin.distance_to(end)<.001:return {}
	refresh_targets()
	var excluded:Array[RID]=[]
	for entry in targets.values():
		var bodies:Array[CollisionObject3D]=[];_colliders(entry.body,bodies)
		for body in bodies:excluded.append(body.get_rid())
	var query:=PhysicsRayQueryParameters3D.create(origin,end,1,excluded);query.hit_from_inside=true
	var wall:=game.get_world_3d().direct_space_state.intersect_ray(query)
	if not wall.is_empty():end=wall.position
	var direction:Vector3=(end-origin).normalized();var distance:float=origin.distance_to(end)
	var result:Dictionary={"key":"","position":end}
	for key in targets:
		if key==player_key(shooter_id) or is_down(key):continue
		var entry:Dictionary=targets[key]
		var hit:=_capsule_hit(origin,direction,entry.body.global_position,entry.radius,entry.height)
		if hit<distance:
			distance=hit;result={"key":key,"position":origin+direction*hit}
	return result
