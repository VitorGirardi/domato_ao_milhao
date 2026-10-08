class_name FarmPickup
extends CharacterBody3D
## Solo driving prototype. Its parked pose belongs to the selected farm save.
const HOME:=Vector2(-20,27)
const MAX_SPEED:=20.0
const REVERSE_SPEED:=6.0
const BODY_SIZE:=Vector3(2.55,2.3,5.95)
const MAX_SLOPE:=deg_to_rad(48.0)
const FORD_DEPTH:=1.0
var game:Node3D
var model:Node3D
var wheels:Dictionary={}
var driver_door:Node3D
var transition:=FarmVehicleTransition.new()
var mounted:=false
var speed:=0.0
var steering:=0.0
var wheel_spin:=0.0
var speed_label:Label
var instruments:=FarmPickupHUD.new()
var blocked_reason:=""
var cargo_visual:=Node3D.new()
var cargo_stamp:=""
var custom_stamp:=""
var accessories:=Node3D.new()
var collision_box:BoxShape3D
var body_shell:CollisionShape3D
var engine_sound:AudioStreamPlayer3D
var motor:FarmEngineAudio
var audio_throttle:=0.0
var airborne:=false
var suspension:=0.0
var suspension_speed:=0.0
const GRAVITY:=22.0

static func defaults() -> Dictionary:return {"x":HOME.x,"z":HOME.y,"angle":PI*.5,"cargo":{},"garage":FarmGarage.defaults()}
static func valid(value:Variant) -> bool:
	if not value is Dictionary:return false
	for key in ["x","z","angle"]:
		if not (value.get(key) is float or value.get(key) is int) or not is_finite(float(value[key])):return false
	var custom:Dictionary=value.get("garage",FarmGarage.defaults()) if value.get("garage",{}) is Dictionary else {}
	if not FarmGarage.valid(custom):return false
	if not FarmPickupCargo.valid(value.get("cargo",{}),120 if custom.bed else 60):return false
	return value.x>=FarmLandscape.WALK_MIN.x+4 and value.x<=FarmLandscape.WALK_MAX.x-4 and value.z>=FarmLandscape.WALK_MIN.y+4 and value.z<=FarmLandscape.WALK_MAX.y-4 and absf(value.angle)<=PI

func setup(owner_game:Node3D) -> void:
	game=owner_game;name="FarmPickup"
	model=load("res://assets/models/farm_pickup.glb").instantiate();add_child(model)
	driver_door=model.find_child("DriverDoor",true,false)
	cargo_visual.name="Cargo";model.add_child(cargo_visual)
	accessories.name="CustomParts";model.add_child(accessories)
	for key in ["FL","FR","RL","RR"]:wheels[key]=model.find_child("Wheel_"+key,true,false)
	var support:=CollisionShape3D.new();var capsule:=CapsuleShape3D.new()
	capsule.radius=.65;capsule.height=2.7;support.shape=capsule;support.position.y=1.35;add_child(support)
	body_shell=CollisionShape3D.new();collision_box=BoxShape3D.new();collision_box.size=BODY_SIZE
	body_shell.shape=collision_box;body_shell.position.y=2.05;add_child(body_shell)
	floor_snap_length=.25;floor_stop_on_slope=true;floor_max_angle=MAX_SLOPE;floor_constant_speed=false
	instruments.setup(game.hud);speed_label=instruments.speed
	motor=FarmEngineAudio.new();add_child(motor);motor.setup(self);engine_sound=motor.idle
	restore(game.state.pickup)

func restore(data:Dictionary) -> void:
	reset_driver()
	var saved:Dictionary=data if valid(data) else defaults()
	var point:=Vector2(saved.x,saved.z)
	if water_depth(point)>FORD_DEPTH:saved=defaults();point=HOME
	rotation=Vector3(0,saved.angle,0);position=Vector3(point.x,FarmLandscape.height_at(point)+.06,point.y)
	velocity=Vector3.ZERO;speed=0;steering=0;wheel_spin=0;blocked_reason=""
	airborne=false;suspension=0;suspension_speed=0
	model.rotation=ground_tilt(position,rotation.y)
	cargo_stamp="";custom_stamp="";refresh_customization();refresh_cargo();_animate(0)

func store() -> void:
	if game.network.active:return
	game.state.pickup.x=position.x;game.state.pickup.z=position.z;game.state.pickup.angle=wrapf(rotation.y,-PI,PI)

func available() -> bool:
	return game!=null and not game.network.active and game.session_started

func nearby() -> bool:
	return available() and not mounted and not game._mounted() and game.player.position.distance_to(position)<4.2 and absf(game.player.position.y-position.y)<1.5

func enter() -> bool:
	if transition.active:return false
	if not nearby() or game.build_mode or not game.hud.modal_kind.is_empty() or game.falls.local_down() or game.actor.airborne or game.actor.swimming:return false
	var outside:=door_stand()
	if to_local(game.player.position).x> -1.5 or game.player.position.distance_to(outside)>1.35 or not door_clear(outside) or not approach_clear(outside):
		game.hud.toast("Aproxime-se pela porta do motorista em um lugar aberto.");return false
	game._cancel_route();game.gathering.reset();game.weapons.holster();game.actor.stop_emote();game.actor.action_time=0
	game.companions.end_horse_call()
	mounted=true;speed=0;velocity=Vector3.ZERO
	add_collision_exception_with(game.player);game.player.add_collision_exception_with(self)
	game.yaw=rotation.y+PI;game.pitch=.32
	transition.begin(self,false,outside);transition.apply(self,0)
	return true

func exit_vehicle() -> bool:
	if not mounted:return true
	if transition.active:return false
	if airborne or absf(speed)>1.2:
		game.hud.toast("Pare a camionetinha antes de sair. Espaço freia.");return false
	var outside:=door_stand()
	if door_clear(outside):
		transition.begin(self,true,outside);return true
	game.hud.toast("A porta está bloqueada. Estacione em um lugar mais aberto.")
	return false

func reset_driver() -> void:
	transition.clear(self)
	if mounted and game!=null:
		remove_collision_exception_with(game.player);game.player.remove_collision_exception_with(self)
		game.avatar.position=Vector3.ZERO;game.avatar.rotation=Vector3(0,rotation.y,0);game.actor.animate(0,false,false)
		game.player.velocity=Vector3.ZERO
	mounted=false;speed=0;velocity=Vector3.ZERO
	if is_instance_valid(instruments):instruments.visible=false
	if is_instance_valid(motor):motor.stop()

static func water_depth(point:Vector2) -> float:
	if FarmRegion.on_bridge(point):return 0.0
	var level:=FarmRegion.water_level(point)
	return maxf(0,level-FarmLandscape.ground_height(point)) if level>-INF else 0.0

func surface_problem(at:Vector3,angle:float) -> String:
	if not valid({"x":at.x,"z":at.z,"angle":wrapf(angle,-PI,PI)}):return "Limite do vale"
	var basis:=Basis(Vector3.UP,angle)
	if water_depth(Vector2(at.x,at.z))>FORD_DEPTH:return "Água profunda · procure uma ponte"
	# Tires may ford shallow water. Deep water is communicated rather than an
	# invisible stop several meters before the bumper reaches the shoreline.
	for x in [-1.18,0.0,1.18]:
		for z in [-1.85,0.0,1.84]:
			var sample:=at+basis*Vector3(x,0,z);var point:=Vector2(sample.x,sample.z)
			if water_depth(point)>FORD_DEPTH+.75:return "Água profunda · procure uma ponte"
	var tilt:=ground_tilt(at,angle)
	if (Basis.from_euler(tilt)*Vector3.UP).dot(Vector3.UP)<cos(slope_limit()):return "Terreno muito íngreme · use a estrada"
	return ""

func surface_allowed(at:Vector3,angle:float) -> bool:
	return surface_problem(at,angle).is_empty()

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
	return Vector3(clampf(atan2(FarmLandscape.height_at(center-forward)-FarmLandscape.height_at(center+forward),3.7),-1.3,1.3),0,clampf(atan2(FarmLandscape.height_at(center+side)-FarmLandscape.height_at(center-side),2.36),-1.3,1.3))

func parking_clear(at:Vector3) -> bool:
	if not surface_allowed(at,rotation.y):return false
	var half:=Vector2(absf(cos(rotation.y))*1.4+absf(sin(rotation.y))*3.2,absf(sin(rotation.y))*1.4+absf(cos(rotation.y))*3.2)
	var area:=Rect2(Vector2(at.x,at.z)-half,half*2)
	for item in game.state.items:
		if item.kind not in ["plot","path","garage"] and game.state.item_rect(item.kind,Vector2(item.x,item.z),item.turn).intersects(area):return false
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
	if transition.active:
		speed=0;velocity=Vector3.ZERO;audio_throttle=0
		if active and transition.apply(self,clampf(delta,0,.05)):
			var leaving:=transition.exiting;var outside:=transition.outside
			transition.clear(self)
			if leaving:
				if door_clear(outside):
					reset_driver();game.player.position=outside;store()
				else:
					_pose_driver(0);game.hud.toast("A saída ficou bloqueada. Libere espaço ao lado da porta.")
			else:_pose_driver(0)
		_animate(0);return
	audio_throttle=throttle if active and not brake else 0.0
	delta=clampf(delta,0,.05)
	if not active:
		speed=0;velocity=Vector3.ZERO;steering=move_toward(steering,0,delta*2)
		_pose_driver(delta);_animate(0);return
	steering=move_toward(steering,clampf(turn,-1,1)*.5,delta*1.8)
	var custom:=FarmGarage.config(game.state)
	var target:=(22.0 if custom.engine else MAX_SPEED)*throttle if throttle>=0 else REVERSE_SPEED*throttle
	var grounded:=is_on_floor() and not airborne
	if grounded or not airborne:
		speed=move_toward(speed,0 if brake else target,delta*((30 if custom.tires else 22) if brake else (10 if custom.engine else 7) if throttle!=0 else 4))
	blocked_reason=""
	var before:=global_transform
	var candidate:=wrapf(rotation.y-steering*speed/3.7*delta,-PI,PI)
	if not airborne and turn_clear(candidate):rotation.y=candidate
	var forward:=global_basis.z
	velocity.x=forward.x*speed;velocity.z=forward.z*speed
	# Carry the upward speed actually acquired on the slope across its crest.
	# Snapping at speed erased that momentum and glued the truck to downhill roads.
	if grounded:velocity.y=get_real_velocity().y
	velocity.y-=GRAVITY*delta
	floor_snap_length=.25 if absf(speed)<7 else 0.0
	var impact_speed:=velocity.y
	# Align the collision shell before movement, not one physics frame behind it.
	_animate(0)
	move_and_slide()
	blocked_reason=surface_problem(position,rotation.y)
	if not blocked_reason.is_empty():
		global_transform=before;velocity=Vector3.ZERO;speed=0
	elif get_slide_collision_count()>0:
		for i in range(get_slide_collision_count()):
			if get_slide_collision(i).get_normal().y<cos(slope_limit()):
				speed=0;blocked_reason="Obstáculo à frente · recue ou contorne";break
	if is_on_floor() and airborne and impact_speed < -2:
		suspension_speed=-minf(impact_speed*-0.32,3.0)
	airborne=not is_on_floor() and position.y-FarmLandscape.height_at(Vector2(position.x,position.z))>.18
	var travel:=position.distance_to(before.origin)
	wheel_spin+=travel*signf(speed)/.65
	_animate(delta);_pose_driver(delta);store()

func _pose_driver(delta:float) -> void:
	game.player.position=position;game.player.velocity=Vector3.ZERO
	game.actor.airborne=false;game.actor.swimming=false;game.actor.animate(delta,false,false)
	game.avatar.global_transform=Transform3D(global_basis*model.basis,model.to_global(Vector3(-.53,.35,-.02)))
	game.actor.pose_bone("Spine",Vector3(.06,0,0))
	for side in ["L","R"]:
		var sign_value:=1.0 if side=="R" else -1.0
		game.actor.pose_bone("Thigh."+side,Vector3(-1.3,0,sign_value*.1))
		game.actor.pose_bone("Shin."+side,Vector3(1.5,0,0))
		game.actor.pose_bone("Foot."+side,Vector3(-.15,0,0))
		game.actor.pose_bone("UpperArm."+side,Vector3(-.6,0,-sign_value*.2))
		game.actor.pose_bone("Forearm."+side,Vector3(-1,0,0))
		game.actor.reach_rein_hand(side,model.to_global(Vector3(-.53+sign_value*.22,2.30,.50)),1)

func _animate(delta:float) -> void:
	if is_instance_valid(model):
		if not airborne:
			var tilt:=ground_tilt(position,rotation.y)
			model.rotation=model.rotation.lerp(tilt,1.0-exp(-delta*12)) if delta>0 else model.rotation
		elif delta>0:
			model.rotation.x=move_toward(model.rotation.x,.22*signf(speed),delta*.35)
		if delta>0:
			suspension_speed+=(-suspension*85-suspension_speed*12)*delta
			suspension=clampf(suspension+suspension_speed*delta,-.22,.12)
		model.position.y=suspension
		body_shell.basis=model.basis;body_shell.position=model.basis*Vector3.UP*2.05
	for key in wheels:
		if is_instance_valid(wheels[key]):wheels[key].rotation=Vector3(wheel_spin,-steering if key.begins_with("F") else 0,0)
	update_hud()

func update_hud() -> void:
	if game==null:return
	game.hud.walking.controls.visible=not mounted
	if mounted:game.hud.walking.interaction.visible=false
	if is_instance_valid(instruments):instruments.update_drive(self)

func _physics_process(delta:float) -> void:
	if game==null:return
	visible=not game.network.active
	collision_layer=1 if visible else 0
	if mounted and (game.falls.local_down() or game.network.active or not game.session_started):reset_driver()
	if not mounted and visible:
		velocity=Vector3(0,velocity.y-22*delta,0);move_and_slide()
	if not mounted:_animate(delta)
	_update_sound(delta)
	refresh_cargo()

func _update_sound(delta:float=0.016) -> void:
	var focused:=DisplayServer.get_name()=="headless" or (get_window().has_focus() and get_window().mode!=Window.MODE_MINIMIZED)
	var playing:bool=mounted and not transition.active and available() and game.hud.modal_kind.is_empty() and focused
	motor.update(delta,speed,audio_throttle,airborne,playing)

func cargo_access() -> bool:
	return available() and not transition.active and game.state.claimed and (mounted or nearby()) and absf(speed)<=1.2 and not game.build_mode and not game.falls.local_down()

func transitioning() -> bool:return transition.active

func door_stand() -> Vector3:
	var at:=to_global(Vector3(-2.25,0,-.25))
	at.y=FarmLandscape.height_at(Vector2(at.x,at.z))+.12
	return at

func door_clear(outside:Vector3) -> bool:
	if not game.horse.safe_spot(Vector2(outside.x,outside.z),game.player,game.state,game.world.landscape):return false
	var query:=PhysicsShapeQueryParameters3D.new();var shape:=BoxShape3D.new()
	shape.size=Vector3(.22,1.4,1.8);query.shape=shape;query.collision_mask=1
	query.exclude=[get_rid(),game.player.get_rid()]
	for i in range(9):
		var hinge:=model.global_transform*Transform3D(Basis(Vector3.UP,i/8.0*1.15),Vector3(-1.08,1.85,.965))
		query.transform=hinge*Transform3D(Basis.IDENTITY,Vector3(0,.12,-.895))
		if not get_world_3d().direct_space_state.intersect_shape(query,1).is_empty():return false
	return true

func approach_clear(outside:Vector3) -> bool:
	var query:=PhysicsShapeQueryParameters3D.new();var shape:=CapsuleShape3D.new()
	shape.radius=.35;shape.height=2.58;query.shape=shape;query.collision_mask=1;query.exclude=[game.player.get_rid()]
	for i in range(1,13):
		var at:Vector3=game.player.position.lerp(outside,i/12.0)
		query.transform=Transform3D(Basis.IDENTITY,at+Vector3.UP*1.4)
		if not get_world_3d().direct_space_state.intersect_shape(query,1).is_empty():return false
	return true

func near_market() -> bool:
	return Vector2(position.x,position.z).distance_to(Vector2(-24,15))<=15

func cargo_action(action:String) -> void:
	if not cargo_access():
		game.hud.toast("Estacione e aproxime-se da camionetinha para acessar a caçamba.");return
	if action=="pickup:cargo":FarmPickupCargo.show(self);return
	if game.hud.modal_kind!="pickup_cargo":return
	var key:=action.get_slice(":",2);var error:=""
	if action.begins_with("pickup:load:"):
		var amount:=mini(10,mini(game.state.stock(key),FarmGarage.capacity(game.state)-FarmPickupCargo.count(FarmPickupCargo.contents(game.state))))
		error=FarmPickupCargo.transfer(game.state,key,amount,true)
	elif action.begins_with("pickup:unload:"):
		error=FarmPickupCargo.transfer(game.state,key,mini(10,int(FarmPickupCargo.contents(game.state).get(key,0))),false)
	elif action=="pickup:sell":
		if not near_market():error="Leve a camionetinha ao armazém da Lúcia."
		else:
			var total:=FarmPickupCargo.sell(game.state)
			if total>0:game.hud.toast("Carga vendida · $%d"%total)
	else:return
	if not error.is_empty():game.hud.toast(error)
	refresh_cargo();FarmPickupCargo.show(self)
	game._save_game(false)

func cargo_box(parent:Node3D,at:Vector3,size:Vector3,color:Color) -> void:
	var mesh:=MeshInstance3D.new();var box:=BoxMesh.new();box.size=size;mesh.mesh=box;mesh.position=at
	var mat:=StandardMaterial3D.new();mat.albedo_color=color;mat.roughness=.9;mesh.material_override=mat;parent.add_child(mesh)

func refresh_cargo() -> void:
	if game==null or not cargo_visual.is_inside_tree():return
	var cargo:=FarmPickupCargo.contents(game.state);var stamp:=str(cargo)
	if stamp==cargo_stamp:return
	cargo_stamp=stamp
	for child in cargo_visual.get_children():child.free()
	var units:Array[String]=[]
	for key in FarmPickupCargo.KEYS:
		for i in range(int(cargo.get(key,0))):units.append(key)
	for index in range(ceili(units.size()/10.0)):
		var crate:=Node3D.new();crate.position=Vector3(-.52+(index%2)*1.04,1.53+(index/6)*.44,-1.32-((index%6)/2)*.58);cargo_visual.add_child(crate)
		var wood:=Color("946238")
		cargo_box(crate,Vector3(0,.035,0),Vector3(.88,.07,.51),wood)
		for side in [-1,1]:
			for y in [.13,.3]:
				cargo_box(crate,Vector3(side*.42,y,0),Vector3(.055,.12,.51),wood)
				cargo_box(crate,Vector3(0,y,side*.23),Vector3(.87,.12,.055),wood)
		for i in range(mini(10,units.size()-index*10)):
			var key:String=units[index*10+i];var color:Color=Color("de943c")
			if key in ["wheat","corn","cheese"]:color=Color("e2c96b")
			elif key in ["egg","milk","quartz"]:color=Color("eee6cc")
			elif key in FarmResources.FISH_KEYS:color=Color("7396a1")
			elif key in FarmResources.ORE_KEYS:color=Color("816e64")
			cargo_product(crate,key,Vector3(-.3+(i%5)*.15,.17+(i%3)*.025,-.11+(i/5)*.22),color)

func cargo_product(parent:Node3D,key:String,at:Vector3,color:Color) -> void:
	var node:=MeshInstance3D.new();node.position=at
	if key in ["carrot","milk","cheese"]:
		var cylinder:=CylinderMesh.new();cylinder.radial_segments=10;cylinder.height=.20
		cylinder.top_radius=.055;cylinder.bottom_radius=.012 if key=="carrot" else .055
		if key=="cheese":cylinder.top_radius=.075;cylinder.bottom_radius=.075;cylinder.height=.12
		node.mesh=cylinder
		if key=="carrot":cargo_box(parent,at+Vector3(0,.13,0),Vector3(.04,.08,.05),Color("628d44"))
		elif key=="milk":cargo_box(parent,at+Vector3(0,.12,0),Vector3(.07,.04,.07),Color("81958f"))
	else:
		var sphere:=SphereMesh.new();sphere.radius=.065;sphere.height=.20;sphere.radial_segments=8;sphere.rings=4
		if key in FarmResources.ORE_KEYS:sphere.radial_segments=5;sphere.rings=2;sphere.height=.16
		node.mesh=sphere
		if key in FarmResources.FISH_KEYS:node.rotation.x=PI/2
	var mat:=StandardMaterial3D.new();mat.albedo_color=color;mat.roughness=.85;node.material_override=mat;parent.add_child(node)

func slope_limit() -> float:
	return deg_to_rad(55.0) if game!=null and FarmGarage.config(game.state).tires else MAX_SLOPE

func refresh_customization() -> void:
	if game==null or not is_instance_valid(model):return
	var data:=FarmGarage.config(game.state);var stamp:=str(data)
	if stamp==custom_stamp:return
	custom_stamp=stamp;floor_max_angle=slope_limit()
	for mesh in model.find_children("*","MeshInstance3D",true,false):
		if mesh.get_parent()==accessories or mesh.mesh==null:continue
		for surface in range(mesh.mesh.get_surface_count()):
			var original:Material=mesh.mesh.surface_get_material(surface)
			if original!=null and original.resource_name.begins_with("Faded pasture green"):
				var paint:=original.duplicate() as StandardMaterial3D;paint.albedo_color=Color(FarmGarage.COLORS[int(data.paint)]);mesh.set_surface_override_material(surface,paint)
	for wheel in wheels.values():wheel.scale.x=1.22 if data.tires else 1.0
	for child in accessories.get_children():child.free()
	if data.bed:
		for side in [-1,1]:cargo_box(accessories,Vector3(side*1.12,2.05,-1.9),Vector3(.1,.15,1.95),Color("5b665e"))
		cargo_box(accessories,Vector3(0,2.05,-2.85),Vector3(2.24,.15,.1),Color("5b665e"))
	if data.engine:
		cargo_box(accessories,Vector3(0,2.12,1.6),Vector3(.72,.22,.75),Color("404d44"))
		for i in range(4):cargo_box(accessories,Vector3(-.24+i*.16,2.25,1.6),Vector3(.06,.035,.54),Color("c6c7b4"))
	if data.rack:
		for side in [-1,1]:cargo_box(accessories,Vector3(side*.85,3.48,.1),Vector3(.09,.25,1.8),Color("4c5c50"))
		for z in [-.65,-.15,.35,.85]:cargo_box(accessories,Vector3(0,3.58,z),Vector3(1.8,.09,.12),Color("9c794d"))
