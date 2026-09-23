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

func setup(n:FarmNetwork) -> void:
	network=n;name="CoopMount"

func local_rider() -> bool:return rider!=0 and rider==multiplayer.get_unique_id()
func body(id:int) -> CharacterBody3D:return network.game.player if id==multiplayer.get_unique_id() else network.remote as CharacterBody3D
func model(id:int) -> Node3D:return network.game.avatar if id==multiplayer.get_unique_id() else network.remote_model
func actor(id:int) -> FarmAvatar:return network.game.actor if id==multiplayer.get_unique_id() else network.remote_actor

func request(action:String) -> void:
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
	match action:
		"mount":
			if rider!=0:message="Pé de Pano já está com outro jogador."
			elif not is_instance_valid(body(sender)) or body(sender).position.distance_to(h.position)>2.8:message="Chegue perto do Pé de Pano."
			elif (sender==1 and g.actor.airborne) or (sender!=1 and (network.remote_airborne or Time.get_ticks_msec()-network.motion_received_at>1000)):message="Espere estar no chão."
			else:
				rider=sender;direction=Vector3.ZERO;h.mount(body(sender),model(sender),actor(sender));h.store(g.state)
				message="WASD cavalgar · Shift tapinha · E desmontar"
		"dismount":
			if rider!=sender:message="Você não está montado."
			elif not h.dismount(body(sender),model(sender),actor(sender),g.state,g.world.landscape):message="Procure espaço livre para desmontar."
			else:rider=0;direction=Vector3.ZERO;message="Desmontou."
		"sprint":
			if rider!=sender:message="Monte primeiro."
			elif not h.encourage():message="Espere o cavalo recuperar o fôlego."
			else:message="Bora, Pé de Pano!"
		_:message="Comando de montaria inválido."
	if network.accepted!=0:_state.rpc_id(network.accepted,rider,h.position,h.heading,network.game.player.position,network.remote.position)
	if sender==1:_answer(message)
	else:_answer.rpc_id(sender,message)
	network.save_coop()

@rpc("authority","call_remote","reliable",2)
func _answer(message:String) -> void:
	waiting=false
	if network.active:network.game.hud.toast(message)

@rpc("authority","call_remote","reliable",2)
func _state(owner_id:int,position:Vector3,heading:float,host_at:Vector3,guest_at:Vector3) -> void:
	if not network.active or network.hosting:return
	var h:FarmHorse=network.game.horse
	if rider!=owner_id:
		if rider!=0 and is_instance_valid(body(rider)):h.reset_rider(body(rider),model(rider),actor(rider))
		rider=owner_id
		h.position=position;h.heading=heading;h.rotation.y=heading
		if rider!=0:h.mount(body(rider),model(rider),actor(rider))
		else:
			network.game.player.position=guest_at;network.remote.position=host_at;network.target=host_at

@rpc("any_peer","call_remote","unreliable_ordered",4)
func _input_direction(value:Vector3) -> void:
	if not network.hosting or rider!=multiplayer.get_remote_sender_id() or rider!=network.accepted:return
	if not value.is_finite() or value.length()>1.01 or absf(value.y)>.001:return
	direction=value;input_at=Time.get_ticks_msec()

func input_direction() -> Vector3:
	var g:Node3D=network.game
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
			h.drive(body(rider),model(rider),actor(rider),direction,delta,true);h.store(g.state)
		elif rider==0:
			h.life.update(h,delta,true,g.state,g.world.landscape,g.player);h.ensure_parking(g.state,g.world.landscape);h.store(g.state)
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
			frame+=1;_frame.rpc_id(network.accepted,frame,rider,h.position,h.heading,h.stamina,h.burst,h.pat_time,h.speed)
		elif local_rider():_input_direction.rpc_id(1,input_direction())

@rpc("authority","call_remote","unreliable_ordered",4)
func _frame(number:int,owner_id:int,position:Vector3,heading:float,stamina:float,burst:float,pat:float,speed:float) -> void:
	if not network.ready_session or network.hosting or number<=received or owner_id!=rider:return
	received=number
	var h:FarmHorse=network.game.horse
	var sprint_started:=pat>0 and h.pat_time<=0
	h.position=position;h.heading=heading;h.rotation.y=heading;h.stamina=stamina;h.burst=burst;h.pat_time=pat;h.speed=speed
	if rider!=0:
		body(rider).position=position;model(rider).rotation.y=heading
		if rider!=multiplayer.get_unique_id():network.target=position;network.target_yaw=heading
	else:h.animate(.05,speed,false)
	if sprint_started:h.encouraged.emit()

func send_initial() -> void:
	if network.accepted==0:return
	var h:FarmHorse=network.game.horse
	_state.rpc_id(network.accepted,rider,h.position,h.heading,network.game.player.position,network.remote.position)

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
