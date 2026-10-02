class_name FarmCombatNet
extends Node
## Requests carry aim only. The host owns inventory, cadence, impacts and falls.
var weapons:FarmWeapons
var game:Node3D
var bags:Dictionary={}
var client_bag:=FarmArmory.fresh()
var timers:Dictionary={}
var reloads:Dictionary={}
var poses:Dictionary={}
var send_left:=0.0
var remote_pistol:Node3D
var remote_flash:MeshInstance3D
var seen_shots:=0

func setup(owner_weapons:FarmWeapons) -> void:
	weapons=owner_weapons;game=weapons.game
	process_physics_priority=15;process_priority=20

func inventory() -> Dictionary:
	if game.network.hosting:return game.state.armory
	return client_bag

func reset() -> void:
	bags.clear();timers.clear();reloads.clear();poses.clear();client_bag=FarmArmory.fresh()
	weapons.holster();remove_remote()

func remove_remote() -> void:
	if is_instance_valid(remote_pistol):remote_pistol.queue_free()
	remote_pistol=null;remote_flash=null

func release(id:int) -> void:
	bags.erase(id);timers.erase(id);reloads.erase(id);poses.erase(id);remove_remote()

func bag_for(id:int) -> Dictionary:
	if id==1:return game.state.armory
	if not bags.has(id):
		bags[id]=FarmArmory.fresh()
		if game.state.infinite_resources():
			FarmArmory.buy_pistol(game.state,bags[id]);bags[id].reserve=FarmArmory.MAX_RESERVE
	return bags[id]

func allowed(id:int) -> bool:
	var net:FarmNetwork=game.network
	return net.active and net.ready_session and id in [1,net.accepted] and (game.get("falls")==null or not game.falls.is_player_down(id)) and net.mounts.rider!=id

func request(kind:String,origin:=Vector3.ZERO,end:=Vector3.ZERO) -> bool:
	var net:FarmNetwork=game.network
	if not net.ready_session:return false
	if net.hosting:return apply_request(1,kind,origin,end)
	_request.rpc_id(1,kind,origin,end)
	return true

@rpc("any_peer","call_remote","reliable",0)
func _request(kind:String,origin:Vector3,end:Vector3) -> void:
	var net:FarmNetwork=game.network
	var id:=multiplayer.get_remote_sender_id()
	if net.hosting and id==net.accepted:apply_request(id,kind,origin,end)

func apply_request(id:int,kind:String,origin:Vector3,end:Vector3) -> bool:
	var net:FarmNetwork=game.network
	if not net.hosting or not allowed(id):return false
	var bag:=bag_for(id)
	var now:=Time.get_ticks_msec()
	var position:Vector3=game.player.position if id==1 else net.target
	if id!=1 and now-net.motion_received_at>1500:return false
	match kind:
		"buy","ammo":
			if weapons.npc.get_meta("temporary_down",false):return false
			if position.distance_to(FarmWeapons.SHOP_AT+Vector3(2.8,0,0))>4.5:return false
			var before:=bag.duplicate(true)
			var money:int=game.state.money
			var error:=FarmArmory.buy_pistol(game.state,bag) if kind=="buy" else FarmArmory.buy_ammo(game.state,bag)
			if error.is_empty() and not net.save_coop():
				bag.clear();bag.merge(before);game.state.money=money;error="Falha ao salvar a compra."
			send_bag(id,error);net.broadcast_state()
			return error.is_empty()
		"reload":
			if reloads.has(id) or not FarmArmory.can_reload(bag):return false
			reloads[id]=now+int(FarmWeapons.RELOAD_TIME*1000)
			send_bag(id);return true
		"fire":
			if now<int(timers.get(id,0)) or reloads.has(id):return false
			if not origin.is_finite() or not end.is_finite() or origin.distance_to(position+Vector3.UP*1.4)>2.1:return false
			var length:=origin.distance_to(end)
			if length<.05 or length>76:return false
			if (id==1 and (game.actor.airborne or game.actor.action_time>0 or not weapons.armed)) or (id!=1 and net.remote_airborne):return false
			# Reject a muzzle placed through cover, even if the aim itself is valid.
			var query:=PhysicsRayQueryParameters3D.create(position+Vector3.UP*1.3,origin,1,[game.player.get_rid()])
			if not game.get_world_3d().direct_space_state.intersect_ray(query).is_empty():return false
			if not FarmArmory.fire(bag):send_bag(id,"Carregador vazio. R para recarregar.");return false
			timers[id]=now+int(FarmWeapons.SHOT_INTERVAL*1000)
			end=origin+(end-origin).normalized()*minf(length,70)
			end=weapons.resolve_shot(origin,end,id,bag)
			send_bag(id);show_shot(id,origin,end)
			if net.accepted!=0:_shot.rpc_id(net.accepted,id,origin,end)
			return true
	return false

func send_bag(id:int,message:String="") -> void:
	var left:=maxf(0,float(int(reloads.get(id,0))-Time.get_ticks_msec())/1000)
	if id==1:receive_bag(game.state.armory,left,message)
	else:_bag.rpc_id(id,bag_for(id),left,message)

@rpc("authority","call_remote","reliable",0)
func _bag(value:Dictionary,left:float,message:String) -> void:
	if game.network.active and game.network.ready_session and FarmArmory.valid(value):receive_bag(value,left,message)

func receive_bag(value:Dictionary,left:float,message:String) -> void:
	client_bag=value.duplicate(true);weapons.reload_left=left
	if not message.is_empty():game.hud.toast(message)
	if game.hud.modal_kind=="armory":weapons.show_shop()

func initial() -> void:
	if game.network.hosting and game.network.accepted!=0:send_bag(game.network.accepted)

@rpc("authority","call_remote","reliable",0)
func _shot(id:int,origin:Vector3,end:Vector3) -> void:
	if game.network.active and game.network.ready_session:show_shot(id,origin,end)

func show_shot(id:int,origin:Vector3,end:Vector3) -> void:
	seen_shots+=1;weapons._tracer(origin,end);weapons._shot_sound()
	if id==multiplayer.get_unique_id():weapons.recoil=FarmWeapons.SHOT_INTERVAL
	else:
		var pose:Dictionary=poses.get(id,{"armed":true,"aiming":false,"pitch":0.0,"reload":0.0,"kick":0.0})
		pose.kick=FarmWeapons.SHOT_INTERVAL;pose.armed=true;poses[id]=pose

@rpc("any_peer","call_remote","unreliable_ordered",1)
func _pose(armed:bool,aiming:bool,pitch:float) -> void:
	var net:FarmNetwork=game.network
	var id:=multiplayer.get_remote_sender_id()
	if not net.ready_session or id!=net.accepted or not is_finite(pitch):return
	if net.hosting and (not allowed(id) or not bag_for(id).pistol):armed=false
	var previous:Dictionary=poses.get(id,{})
	poses[id]={"armed":armed,"aiming":aiming,"pitch":clampf(pitch,-.8,.7),"reload":float(previous.get("reload",0)),"kick":float(previous.get("kick",0)),"blend":float(previous.get("blend",0))}

func _physics_process(delta:float) -> void:
	var net:FarmNetwork=game.network
	if not net.active or not net.ready_session:return
	if net.hosting:
		for id in reloads.keys():
			if not allowed(id):reloads.erase(id);send_bag(id)
			elif Time.get_ticks_msec()>=int(reloads[id]):
				FarmArmory.reload_magazine(bag_for(id),game.state.infinite_resources());reloads.erase(id);send_bag(id)
	send_left-=delta
	if net.accepted!=0 and send_left<=0:
		send_left=.05
		_pose.rpc_id(net.accepted,weapons.armed,weapons.aiming,weapons.pose_pitch)
		if net.hosting:_reload_pose.rpc_id(net.accepted,float(weapons.reload_left),maxf(0,float(int(reloads.get(net.accepted,0))-Time.get_ticks_msec())/1000))

func _process(delta:float) -> void:
	if game.network.active and game.network.ready_session:animate_remote(delta)

@rpc("authority","call_remote","unreliable_ordered",1)
func _reload_pose(host_left:float,guest_left:float) -> void:
	if not game.network.active or not game.network.ready_session:return
	var pose:Dictionary=poses.get(1,{})
	if not pose.is_empty():pose.reload=host_left
	weapons.reload_left=guest_left

func animate_remote(delta:float) -> void:
	var net:FarmNetwork=game.network
	if not is_instance_valid(net.remote) or net.remote_actor==null:return
	var pose:Dictionary=poses.get(net.accepted,{})
	var visible:bool=not pose.is_empty() and bool(pose.get("armed",false)) and net.mounts.rider!=net.accepted and (game.get("falls")==null or not game.falls.is_player_down(net.accepted))
	if not visible:
		if is_instance_valid(remote_pistol):remote_pistol.visible=false
		return
	if not is_instance_valid(remote_pistol):
		remote_pistol=load("res://assets/models/pistol_p8.glb").instantiate();net.remote_actor.hand_socket.add_child(remote_pistol)
		remote_flash=MeshInstance3D.new();var sphere:=SphereMesh.new();sphere.radius=.06;sphere.height=.12;remote_flash.mesh=sphere
		var mat:=StandardMaterial3D.new();mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mat.albedo_color=Color("ffe29b");remote_flash.material_override=mat
		remote_pistol.add_child(remote_flash);remote_flash.position=Vector3(0,.184,.235)
	remote_pistol.visible=true
	pose.kick=maxf(0,float(pose.get("kick",0))-delta)
	if net.hosting:pose.reload=maxf(0,float(int(reloads.get(net.accepted,0))-Time.get_ticks_msec())/1000)
	pose.blend=lerpf(float(pose.get("blend",0)),1.0 if pose.get("aiming",false) else 0.0,1-exp(-delta*14))
	var kick:float=pose.kick/FarmWeapons.SHOT_INTERVAL
	FarmPistolPose.apply(net.remote_actor,remote_pistol,float(pose.pitch),maxf(float(pose.blend),kick),float(pose.reload)/FarmWeapons.RELOAD_TIME,kick)
	remote_flash.visible=float(pose.kick)>FarmWeapons.SHOT_INTERVAL-.055
