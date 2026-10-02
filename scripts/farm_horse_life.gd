class_name FarmHorseLife
extends RefCounted
## Bounded, collision-tested wandering. No teleport, no hunger penalty.
var anchor:=Vector2.ZERO
var anchored:=false
var mode:="look"
var remaining:=3.0
var goal:=Vector2.ZERO
var graze:=0.0
var look:=0.0
var cycles:=0
var calling:=false
var call_path:Array[Vector2]=[]
var call_remaining:=0.0 # Compatibility with older QA/state users; calls have no expiry.
var call_blocked:=false
var call_blocked_at:=Vector2.ZERO

func reset(horse:FarmHorse) -> void:
	anchor=Vector2(horse.position.x,horse.position.z);anchored=true
	mode="look";remaining=3;graze=0;look=0

func safe_step(horse:FarmHorse,point:Vector2,heading:float,state:FarmState,landscape:FarmLandscape) -> bool:
	if not horse.parking_clear(point,state,landscape):return false
	var query:=PhysicsShapeQueryParameters3D.new();query.collision_mask=1
	query.exclude=[horse.obstacle.get_rid()]
	var slope:=Basis(Vector3.UP,heading)*horse.model.basis
	query.motion=Vector3(point.x,horse.ground_at(point),point.y)-horse.position
	var space:=horse.get_world_3d().direct_space_state
	# A flat full-length box catches every convex change in the hillside.
	# Rounded central feet plus an inclined upper body match mounted collision.
	var capsule:=CapsuleShape3D.new();capsule.radius=.48;capsule.height=2.5
	query.shape=capsule;query.transform=Transform3D(Basis.IDENTITY,horse.position+Vector3(0,1.45,0))
	if not space.intersect_shape(query,1).is_empty() or space.cast_motion(query)[0]<.999:return false
	var upper:=BoxShape3D.new();upper.size=Vector3(1.15,1.5,3.25)
	query.shape=upper
	query.transform=Transform3D(slope,horse.position+slope*Vector3(0,1.925,.15)+Vector3(0,horse.model.position.y,0))
	return space.intersect_shape(query,1).is_empty() and space.cast_motion(query)[0]>=.999

func update(horse:FarmHorse,delta:float,active:bool,state:FarmState,landscape:FarmLandscape,player:CharacterBody3D) -> void:
	if not anchored:reset(horse)
	if not active:return
	if calling:
		if horse.mounted:calling=false;call_path.clear();return
		var speed:=0.0
		if not call_path.is_empty():
			var at:=Vector2(horse.position.x,horse.position.z)
			var direction:=call_path[0]-at
			if direction.length()<.25:call_path.pop_front()
			else:
				var wanted:=atan2(direction.x,direction.y)
				var heading:=rotate_toward(horse.heading,wanted,delta*4.0)
				var pace:=7.0 if at.distance_to(call_path[-1])>24 else 2.5
				if absf(angle_difference(heading,wanted))>.12:pace=0
				var point:=at+direction.normalized()*minf(minf(delta,.1)*pace,direction.length())
				if safe_step(horse,point,heading,state,landscape):
					horse.position=Vector3(point.x,horse.ground_at(point),point.y);horse.heading=heading;horse.rotation.y=heading;speed=pace
				else:
					call_blocked=true;call_blocked_at=at+direction.normalized()*2.0;call_path.clear()
		horse.speed=speed;horse.animate(delta,speed,false);horse.store(state)
		return
	var at:=Vector2(horse.position.x,horse.position.z)
	if at.distance_to(anchor)>7:reset(horse)
	var stable:=FarmStable.nearby(state,at)
	horse.stamina=minf(100,horse.stamina+delta*(FarmStable.RECOVERY if stable>=0 else 7.0))
	var near_player:=horse.position.distance_to(player.position)<3.4
	remaining-=delta
	if near_player and mode=="walk":mode="look";remaining=3
	if remaining<=0:
		cycles+=1
		mode=["graze","look","walk","look"][cycles%4];remaining=6 if mode=="graze" else 4
		if mode=="walk":
			var angle:=cycles*2.39996
			goal=anchor+Vector2(sin(angle),cos(angle))*3.0
			if near_player or not horse.parking_clear(goal,state,landscape):mode="look"
	graze=move_toward(graze,1.0 if mode=="graze" and not near_player else 0.0,delta*.75)
	look=move_toward(look,sin(horse.gait*.25)*.18 if mode=="look" else 0.0,delta*.25)
	var speed:=0.0
	if mode=="walk" and graze<.05:
		var direction:=goal-at
		var heading:=atan2(direction.x,direction.y)
		var next_heading:=lerp_angle(horse.heading,heading,1-exp(-delta*3))
		var point:=at+Vector2(sin(next_heading),cos(next_heading))*minf(delta*.8,direction.length())
		if point.distance_to(anchor)>4.5 or direction.length()<.25 or not safe_step(horse,point,next_heading,state,landscape):mode="look";remaining=3
		else:
			horse.heading=next_heading;horse.rotation.y=next_heading
			horse.position=Vector3(point.x,horse.ground_at(point),point.y);speed=.8
	horse.animate(delta,speed,false)
	horse.parts.HorseNeck.rotation.x+=graze*1.48
	horse.parts.HorseNeck.rotation.y=look
	# Rotate at the anatomical shoulder hinge; translating the whole neck pinched the chest.
	horse.parts.HorseNeck.position=horse.part_home.HorseNeck
	horse.sync_skin()
	horse.store(state)
