class_name FarmCoopMount
extends Node
## One shared horse, one rider at a time. Only the host accepts mount/input/sprint.
var network:FarmNetwork
var rider:=0
var direction:=Vector3.ZERO
var input_at:=0
var timer:=0.0
var frame:=0
var received:=-1
var waiting:=false
var last_request:Dictionary={}
var serial:=0
var input_active:=true
var published_transition:=""
var state_revision:=0
var received_revision:=-1

func setup(n:FarmNetwork) -> void:
	network=n;name="CoopMount"

func local_rider() -> bool:return rider!=0 and rider==multiplayer.get_unique_id()
func body(id:int) -> CharacterBody3D:return network.game.player if id==multiplayer.get_unique_id() else network.remote as CharacterBody3D
func model(id:int) -> Node3D:return network.game.avatar if id==multiplayer.get_unique_id() else network.remote_model
func actor(id:int) -> FarmAvatar:return network.game.actor if id==multiplayer.get_unique_id() else network.remote_actor

func request(action:String) -> void:
	if network.game.falls.local_down() or network.game.falls.is_down("horse"):return
	if not network.ready_session or waiting:return
	serial+=1;waiting=true
	if network.hosting:apply_request(1,serial,action)
	else:_request.rpc_id(1,serial,action)

@rpc("any_peer","call_remote","reliable",0)
func _request(number:int,action:String) -> void:
	var sender:=multiplayer.get_remote_sender_id()
	if network.hosting and sender==network.accepted:apply_request(sender,number,action)

func apply_request(sender:int,number:int,action:String) -> void:
	if not network.active or number<=int(last_request.get(sender,0)):return
	last_request[sender]=number
	var g:Node3D=network.game
	var h:FarmHorse=g.horse
	var message:=""
	if g.falls.is_player_down(sender) or g.falls.is_down("horse"):
		if sender==1:_answer("Aguarde se recuperar.")
		else:_answer.rpc_id(sender,"Aguarde se recuperar.")
		return
	match action:
		"mount":
			if rider!=0:message="Pé de Pano já está com outro jogador."
			elif not is_instance_valid(body(sender)) or body(sender).position.distance_to(h.position)>2.8 or not h.approach_clear(body(sender)):message="Chegue perto do Pé de Pano."
			elif (sender==1 and g.actor.airborne) or (sender!=1 and (network.remote_airborne or Time.get_ticks_msec()-network.motion_received_at>1000)):message="Espere estar no chão."
			else:
				rider=sender;direction=Vector3.ZERO;h.mount(body(sender),model(sender),actor(sender),true);h.store(g.state)
				message="WASD cavalgar · Shift tapinha · E desmontar"
		"dismount":
			if rider!=sender:message="Você não está montado."
			elif not h.dismount(body(sender),model(sender),actor(sender),g.state,g.world.landscape,true):message="Procure espaço livre para desmontar."
			else:direction=Vector3.ZERO;message="Desmontou."
		"sprint":
			if rider!=sender:message="Monte primeiro."
			elif not h.encourage():message="Espere o cavalo recuperar o fôlego."
			else:message="Bora, Pé de Pano!"
		_:message="Comando de montaria inválido."
	send_initial()
	if sender==1:_answer(message)
	else:_answer.rpc_id(sender,message)
	network.save_coop()

@rpc("authority","call_remote","reliable",2)
func _answer(message:String) -> void:
	waiting=false
	if network.active:network.game.hud.toast(message)

@rpc("authority","call_remote","reliable",2)
func _state(owner_id:int,position:Vector3,heading:float,host_at:Vector3,guest_at:Vector3,kind:String="",origin:Vector3=Vector3.ZERO,target:Vector3=Vector3.ZERO,elapsed:float=0.0,revision:int=0) -> void:
	if not network.active or network.hosting or revision<=received_revision:return
	received_revision=revision
	var h:FarmHorse=network.game.horse
	var owner_changed:=rider!=owner_id
	var entry_basis:=model(owner_id).global_basis if owner_id!=0 else Basis.IDENTITY
	if rider!=owner_id:
		if rider!=0 and is_instance_valid(body(rider)):h.reset_rider(body(rider),model(rider),actor(rider))
		rider=owner_id
		h.position=position;h.heading=heading;h.rotation.y=heading
		if rider!=0:h.mount(body(rider),model(rider),actor(rider))
		else:
			network.game.player.position=guest_at;network.remote.position=host_at;network.target=host_at
	if rider!=0:
		if not kind.is_empty():
			if owner_changed or kind!=h.transition_kind:
				h.begin_transition(kind,body(rider),model(rider),origin,target)
				h.transition_basis=entry_basis
			h.transition_elapsed=clampf(maxf(h.transition_elapsed,elapsed),0,FarmHorseMountPose.DURATION)
			h.render_transition(actor(rider))
		elif h.transition_active():h.clear_transition()

@rpc("any_peer","call_remote","unreliable_ordered",4)
func _input_direction(value:Vector3,active:bool=true) -> void:
	if not network.hosting or rider!=multiplayer.get_remote_sender_id() or rider!=network.accepted:return
	if network.game.falls.is_down("horse") or network.game.falls.is_player_down(rider):return
	if not value.is_finite() or value.length()>1.01 or absf(value.y)>.001:return
	direction=value;input_active=active;input_at=Time.get_ticks_msec()

func input_direction() -> Vector3:
	var g:Node3D=network.game
	if g.falls.local_down() or g.falls.is_down("horse"):return Vector3.ZERO
	if not g.hud.modal_kind.is_empty():return Vector3.ZERO
	var input:=Input.get_vector("left","right","forward","back")
	return Vector3(cos(g.yaw),0,-sin(g.yaw))*input.x+Vector3(sin(g.yaw),0,cos(g.yaw))*input.y

func _physics_process(delta:float) -> void:
	if network==null or not network.ready_session:return
	var g:Node3D=network.game
	var h:FarmHorse=g.horse
	if network.hosting:
		if rider==network.accepted and rider!=0:
			if Time.get_ticks_msec()-input_at>350:direction=Vector3.ZERO
			h.drive(body(rider),model(rider),actor(rider),direction,delta,input_active and Time.get_ticks_msec()-input_at<=350);h.store(g.state)
		elif rider==0:
			h.life.update(h,delta,true,g.state,g.world.landscape,g.player);h.ensure_parking(g.state,g.world.landscape);h.store(g.state)
		if rider!=0 and not h.mounted:
			rider=0;direction=Vector3.ZERO;send_initial();network.save_coop()
		if published_transition!=h.transition_kind:
			published_transition=h.transition_kind;send_initial()
	else:
		if local_rider():
			# Host frames own position; input is the only driving request sent by the guest.
			h.animate(delta,h.speed,h.burst>0);actor(rider).animate(delta,false,false);h.pose_rider(model(rider),actor(rider))
		elif rider!=0:
			h.animate(delta,h.speed,h.burst>0);actor(rider).animate(delta,false,false);h.pose_rider(model(rider),actor(rider))
	timer-=delta
	if timer<=0:
		timer=.05
		if network.hosting and network.accepted!=0:
			frame+=1;_frame.rpc_id(network.accepted,frame,rider,h.position,h.heading,h.stamina,h.burst,h.pat_time,h.speed,h.transition_elapsed,state_revision)
		elif local_rider():_input_direction.rpc_id(1,input_direction(),g.hud.modal_kind.is_empty())

@rpc("authority","call_remote","unreliable_ordered",4)
func _frame(number:int,owner_id:int,position:Vector3,heading:float,stamina:float,burst:float,pat:float,speed:float,transition_elapsed:float=0.0,revision:int=0) -> void:
	# Reliable state (channel 2) and motion (channel 4) can arrive in either order.
	# A frame must belong to the exact mount/dismount state already installed.
	if not network.ready_session or network.hosting or number<=received or owner_id!=rider or revision!=received_revision:return
	received=number
	var h:FarmHorse=network.game.horse
	var sprint_started:=pat>0 and h.pat_time<=0
	h.position=position;h.heading=heading;h.rotation.y=heading;h.stamina=stamina;h.burst=burst;h.pat_time=pat;h.speed=speed
	if h.transition_active():
		h.transition_elapsed=clampf(maxf(h.transition_elapsed,transition_elapsed),0,FarmHorseMountPose.DURATION);h.render_transition(actor(rider))
		if h.transition_kind=="mount" and transition_elapsed>=FarmHorseMountPose.DURATION:h.clear_transition()
	if rider!=0 and not h.transition_active():
		body(rider).position=position;model(rider).rotation.y=heading
		if rider!=multiplayer.get_unique_id():network.target=position;network.target_yaw=heading
	else:h.animate(.05,speed,false)
	if sprint_started:h.encouraged.emit()

func send_initial() -> void:
	state_revision+=1
	if network.accepted==0:return
	var h:FarmHorse=network.game.horse
	published_transition=h.transition_kind
	_state.rpc_id(network.accepted,rider,h.position,h.heading,network.game.player.position,network.remote.position,h.transition_kind,h.transition_origin,h.transition_target,h.transition_elapsed,state_revision)

func force_dismount() -> void:
	if not network.hosting or rider==0:return
	var g:Node3D=network.game
	var h:FarmHorse=g.horse
	var id:=rider
	if is_instance_valid(body(id)):
		if not h.dismount(body(id),model(id),actor(id),g.state,g.world.landscape):
			release(id)
			var found:=false
			for radius in [4.0,6.0,9.0,14.0,22.0]:
				for step in range(24):
					var point:Vector2=Vector2(h.position.x,h.position.z)+Vector2(sin(step*TAU/24),cos(step*TAU/24))*radius
					if h.safe_spot(point,body(id),g.state,g.world.landscape):
						body(id).position=Vector3(point.x,h.ground_at(point)+.12,point.y);found=true;break
				if found:break
		body(id).velocity=Vector3.ZERO
		if id!=1:network.target=body(id).position
	rider=0;direction=Vector3.ZERO;waiting=false
	h.store(g.state)
	send_initial()

func release(id:int) -> void:
	last_request.erase(id)
	if rider!=id:return
	var h:FarmHorse=network.game.horse
	if is_instance_valid(body(id)):h.reset_rider(body(id),model(id),actor(id))
	rider=0;direction=Vector3.ZERO;h.store(network.game.state)
	if network.hosting:network.save_coop()

func reset() -> void:
	if rider!=0:release(rider)
	waiting=false;serial=0;received=-1;frame=0;last_request.clear();direction=Vector3.ZERO
	state_revision=0;received_revision=-1;published_transition="";input_active=true
