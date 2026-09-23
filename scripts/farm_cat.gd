class_name FarmCat
extends Node3D
## One companion per farm. Transient behavior never alters saves/economy.
var model:Node3D
var clock:=0.0
var affection:=0.0
var sitting:=0.0
var walking:=0.0
var pet_remaining:=0.0
var anchored:=false
var home:=Vector2.ZERO
var cycle:=0
var remaining:=3.0
var destination:=Vector2.ZERO
var pet_count:=0
var following:=false
var roam_valley:=false

func _ready() -> void:
	model=load("res://assets/models/cat.glb").instantiate();model.scale=Vector3.ONE*.72;add_child(model)
	visible=false

func clear_at(point:Vector2,state:FarmState) -> bool:
	if not state.claimed:return false
	if following or roam_valley:
		if not Rect2(FarmLandscape.WALK_MIN, FarmLandscape.WALK_MAX-FarmLandscape.WALK_MIN).grow(-.6).has_point(point):return false
		if not get_parent().landscape.clear_for_player(point):return false
	elif not state.bounds().grow(-.6).has_point(point):return false
	for item in state.items:
		if state.item_rect(item.kind,Vector2(item.x,item.z),item.turn).grow(.45).has_point(point):return false
	var shape:=SphereShape3D.new();shape.radius=.37
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1
	query.transform.origin=Vector3(point.x,FarmLandscape.height_at(point)+.4,point.y)
	for hit in get_world_3d().direct_space_state.intersect_shape(query,16):
		if not hit.collider is CharacterBody3D:return false
	return true

func reset(state:FarmState) -> void:
	anchored=false;visible=false;roam_valley=false;pet_remaining=0;walking=0;sitting=0;affection=0
	if not state.claimed:return
	for i in range(80):
		var angle:=i*2.39996
		var point:=state.center+Vector2(sin(angle),cos(angle))*(1.5+sqrt(float(i))*.65)
		if clear_at(point,state):
			home=point;destination=point;position=Vector3(point.x,FarmLandscape.height_at(point),point.y)
			anchored=true;visible=true;return

func can_pet(player:Vector3) -> bool:
	return visible and player.is_finite() and position.distance_to(player)<1.8 and pet_remaining<=0

func pet(player:Vector3) -> bool:
	if not can_pet(player):return false
	pet_remaining=3.2;remaining=5.0;destination=Vector2(position.x,position.z)
	var direction:=player-position
	if Vector2(direction.x,direction.z).length()>.01:rotation.y=atan2(direction.x,direction.z)
	pet_count+=1
	return true

func update(delta:float,player:Vector3,state:FarmState) -> void:
	if not state.claimed:visible=false;anchored=false;return
	if not anchored or (not roam_valley and home.distance_to(state.center)>state.land_size):reset(state)
	if not anchored or delta<=0:return
	clock+=delta;remaining-=delta;pet_remaining=maxf(0,pet_remaining-delta)
	var at:=Vector2(position.x,position.z)
	if not clear_at(at,state):
		# A construction may occupy the resting spot; relocate only after edits.
		reset(state);return
	if remaining<=0 and not following:
		cycle+=1;remaining=4.0+float(cycle%3)
		var angle:=cycle*2.39996
		destination=home+Vector2(sin(angle),cos(angle))*1.6
		if cycle%3!=1 or not clear_at(destination,state):destination=at
	var direction:=destination-at
	var stepping:=direction.length()>.10 and pet_remaining<=0 and (following or position.distance_to(player)>1.1)
	sitting=move_toward(sitting,1.0 if not stepping and cycle%3==2 and pet_remaining<=0 and not following else 0.0,delta*1.8)
	if stepping and sitting<.05:
		var next:=at+direction.normalized()*minf(minf(delta,.1)*(2.6 if following else .65),direction.length())
		if clear_at(next,state):
			position=Vector3(next.x,FarmLandscape.height_at(next),next.y)
			rotation.y=rotate_toward(rotation.y,atan2(direction.x,direction.y),delta*3)
		else:destination=at;stepping=false
	else:stepping=false
	walking=move_toward(walking,1.0 if stepping else 0.0,delta*6)
	affection=move_toward(affection,1.0 if pet_remaining>0 else 0.0,delta*3)
	FarmCatPose.pose(model,clock,walking,sitting,affection)
