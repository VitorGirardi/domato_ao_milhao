class_name FarmCompanions
extends Node
var game:Node3D
var gestures:Dictionary={}
var last_request:Dictionary={}
var follow_owner:=0
var horse_owner:=0
var path:Array[Vector2]=[]
var plan_wait:=0.0
var horse_wait:=0.0
var request_wait:=0.0
var hint:Label
var purr:=AudioStreamPlayer3D.new()
var whistle:=AudioStreamPlayer3D.new()
var was_network:=false

func setup(g:Node3D) -> void:
	game=g;name="Companions";process_priority=10
	for data in [[purr,"cat_purr",-15.0],[whistle,"companion_whistle",-12.0]]:
		var voice:AudioStreamPlayer3D=data[0];game.add_child(voice)
		voice.stream=load("res://assets/audio/%s.wav"%data[1]);voice.bus=FarmAudio.EFFECTS_BUS
		voice.volume_db=data[2];voice.unit_size=3;voice.max_distance=22
	hint=game.hud.label(game.hud.walking.root,"",Vector2(370,792),Vector2(700,24),15,FarmHUD.CREAM)
	hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_shadow_color",Color("20392a"));hint.add_theme_constant_override("shadow_offset_y",2)

func own_id() -> int:return multiplayer.get_unique_id() if game.network.active else 1
func body(id:int) -> Node3D:return game.player if id==own_id() else game.network.remote
func actor(id:int) -> FarmAvatar:return game.actor if id==own_id() else game.network.remote_actor
func model(id:int) -> Node3D:return game.avatar if id==own_id() else game.network.remote_model
func allowed() -> bool:return game.session_started and not game.build_mode and game.hud.modal_kind.is_empty() and not game._mounted() and not game.actor.airborne

func request(kind:String) -> void:
	if not allowed() or request_wait>0:return
	request_wait=.3
	if game.network.active and not game.network.hosting:_request.rpc_id(1,kind)
	elif not apply(own_id(),kind):game.hud.toast("Aproxime-se do animal e espere a interação terminar.")

@rpc("any_peer","call_remote","reliable",0)
func _request(kind:String) -> void:
	var n:FarmNetwork=game.network;var sender:=multiplayer.get_remote_sender_id()
	if not n.active or not n.hosting or not n.ready_session or sender!=n.accepted:return
	if Time.get_ticks_msec()-n.motion_received_at>1500 or n.remote_airborne or n.mounts.rider==sender:return
	if not apply(sender,kind):_reply.rpc_id(sender,"Aproxime-se do animal; ele pode estar ocupado com outro jogador.")

@rpc("authority","call_remote","reliable",0)
func _reply(message:String) -> void:
	game.hud.toast(message)

func apply(id:int,kind:String) -> bool:
	if kind not in ["pet","follow","whistle"] or not is_instance_valid(body(id)):return false
	var now:=Time.get_ticks_msec();var key:="%d:%s"%[id,kind]
	if now-int(last_request.get(key,-10000))<(4000 if kind=="whistle" else 700):return false
	var at:Vector3=body(id).position
	if id!=own_id():at=game.network.target
	if kind in ["pet","whistle"] and gestures.has(id):return false
	var cat:FarmCat=game.world.cat
	if kind=="pet":
		if at.distance_to(cat.position)>1.25 or not cat.pet(at):return false
	elif kind=="follow":
		if follow_owner!=0 and follow_owner!=id:return false
		if not cat.visible or (follow_owner==0 and at.distance_to(cat.position)>2.2):return false
		follow_owner=0 if follow_owner==id else id;cat.following=follow_owner!=0;cat.roam_valley=true
		cat.home=Vector2(cat.position.x,cat.position.z);cat.destination=cat.home;path.clear();plan_wait=0
	else:
		if game.horse.mounted or at.distance_to(game.horse.position)>60:return false
		horse_owner=id;horse_wait=0;game.horse.life.call_remaining=25
	last_request[key]=now
	_event(id,kind,cat.position,follow_owner)
	if game.network.active and game.network.accepted!=0:_event.rpc_id(game.network.accepted,id,kind,cat.position,follow_owner)
	return true

@rpc("authority","call_remote","reliable",0)
func _event(id:int,kind:String,cat_at:Vector3,owner:int) -> void:
	follow_owner=owner
	if kind=="follow":
		if id==own_id():game.hud.toast("O gato vai acompanhar você." if owner!=0 else "O gato vai ficar por aqui.")
		return
	if not is_instance_valid(body(id)) or actor(id)==null:return
	var a:=actor(id);a.stop_emote();a.action_kind=kind;a.action_time=3.2 if kind=="pet" else 1.8
	gestures[id]={"kind":kind,"time":0.0,"at":cat_at}
	if id==own_id():game.weapons.holster()
	if kind=="pet":purr.global_position=cat_at+Vector3.UP*.4;purr.play()
	else:whistle.global_position=body(id).position+Vector3.UP*2;whistle.play()

func reset() -> void:
	for id in gestures:
		if actor(id)!=null and is_instance_valid(model(id)):actor(id).action_time=0;model(id).position.y=0
	gestures.clear();follow_owner=0;horse_owner=0;path.clear();last_request.clear()
	game.world.cat.following=false;game.horse.life.calling=false
	purr.stop();whistle.stop()

func _process(delta:float) -> void:
	if game==null:return
	request_wait=maxf(0,request_wait-delta)
	if was_network!=game.network.active:reset();was_network=game.network.active
	if DisplayServer.get_name()!="headless" and not game.get_window().has_focus():purr.stop();whistle.stop()
	hint.visible=allowed()
	hint.text="C · Assobiar para o cavalo"
	if follow_owner==own_id():hint.text+="   •   V · Gato: ficar aqui"
	elif follow_owner==0 and game.world.cat.visible and game.player.position.distance_to(game.world.cat.position)<2.2:hint.text+="   •   V · Gato: acompanhar"
	var active:bool=game.session_started and (game.network.active or (not game.build_mode and game.hud.modal_kind.is_empty()))
	if not active:
		for id in gestures:
			if actor(id)!=null and is_instance_valid(model(id)):actor(id).action_time=0;model(id).position.y=0
		gestures.clear();purr.stop();whistle.stop();return
	if not game.network.active or game.network.hosting:update_follow(delta)
	for id in gestures.keys():
		if not is_instance_valid(body(id)) or actor(id)==null:gestures.erase(id);continue
		var entry:Dictionary=gestures[id];entry.time+=delta
		var duration:=3.2 if entry.kind=="pet" else 1.8
		if entry.time>=duration or (id==own_id() and not game.hud.modal_kind.is_empty()):
			actor(id).action_time=0;model(id).position.y=0;gestures.erase(id)
			if entry.kind=="pet":purr.stop()
			continue
		pose(actor(id),entry.kind,entry.time,duration,entry.at)

func update_follow(delta:float) -> void:
	var cat:FarmCat=game.world.cat
	if follow_owner!=0:
		if not is_instance_valid(body(follow_owner)):follow_owner=0;cat.following=false;path.clear()
		else:
			cat.following=true;plan_wait-=delta
			var target:Vector3=body(follow_owner).position
			var distance:=cat.position.distance_to(target)
			if distance<1.5:path.clear();cat.destination=Vector2(cat.position.x,cat.position.z)
			elif plan_wait<=0:
				plan_wait=1.0
				var offset:Vector3=(cat.position-target).normalized()*1.25
				path=FarmCompanionPath.route(Vector2(cat.position.x,cat.position.z),Vector2(target.x+offset.x,target.z+offset.z),func(p:Vector2):return cat.clear_at(p,game.state),.8)
			if not path.is_empty():
				if Vector2(cat.position.x,cat.position.z).distance_to(path[0])<.15:path.pop_front()
				if not path.is_empty():cat.destination=path[0]
	if horse_owner!=0:
		var h:FarmHorse=game.horse
		if not is_instance_valid(body(horse_owner)) or h.mounted or h.life.call_remaining<=0:
			horse_owner=0;h.life.calling=false;h.speed=0;return
		horse_wait-=delta
		var target:Vector3=body(horse_owner).position
		if h.position.distance_to(target)<3.5:horse_owner=0;h.life.calling=false;h.speed=0;h.life.reset(h);return
		if horse_wait<=0:
			horse_wait=1.5
			var offset:Vector3=(h.position-target).normalized()*3.2
			var clear:=func(p:Vector2):return h.parking_clear(p,game.state,game.world.landscape)
			h.life.call_path=FarmCompanionPath.route(Vector2(h.position.x,h.position.z),Vector2(target.x+offset.x,target.z+offset.z),clear,1.5)
			h.life.calling=true

static func pose(a:FarmAvatar,kind:String,time:float,duration:float,target:Vector3) -> void:
	var weight:=smoothstep(0,.45,time)*(1-smoothstep(duration-.5,duration,time))
	a.can.visible=false;a.carried_egg.visible=false
	if kind=="pet":
		var direction:=target-a.root.global_position
		a.root.rotation.y=atan2(direction.x,direction.z)
		for side in ["L","R"]:
			a.pose_bone("Thigh."+side,Vector3(-.95,0,0),weight)
			a.pose_bone("Shin."+side,Vector3(1.9,0,0),weight)
			a.pose_bone("Foot."+side,Vector3(-.95,0,0),weight)
		a.root.position.y=0
		var foot:int=a.bones["Foot.L"]
		var rest_y:float=a.skeleton.to_global(a.skeleton.get_bone_global_rest(foot).origin).y
		var pose_y:float=a.skeleton.to_global(a.skeleton.get_bone_global_pose(foot).origin).y
		a.root.position.y=rest_y-pose_y
		a.pose_bone("Spine",Vector3(1.05,0,0),weight);a.pose_bone("Head",Vector3(.15,0,0),weight)
		a.pose_bone("Hand.R",Vector3.ZERO,weight,PI*.5)
		a.reach_rein_hand("R",target+Vector3(0,.54,.10*sin(time*6)),weight)
	else:
		a.pose_bone("Head",Vector3(-.07,0,0),weight)
		a.pose_bone("UpperArm.R",Vector3(-1.0,0,-.20),weight)
		a.pose_bone("Forearm.R",Vector3(-1.7,0,0),weight)
		var head:=a.skeleton.get_bone_global_pose(a.bones.Head)
		a.reach_rein_hand("R",a.skeleton.to_global(head.origin+Vector3(.05,.08,.28)),weight)
