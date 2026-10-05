class_name FarmGathering
extends Node
## Only the host advances work and commits rewards. Clients receive visual jobs.
var game:Node3D
var jobs:Dictionary={}
var last_request:Dictionary={}
var state_id:=0
var session_key:=""
var synced_peer:=0
var cancel_pending:=false

func setup(g:Node3D) -> void:
	game=g;name="Gathering";process_priority=12
	_remember_session()

func own_id() -> int:return multiplayer.get_unique_id() if game.network.active else 1
func authority() -> bool:return not game.network.active or game.network.hosting
func _key() -> String:return "%s:%s:%s"%[game.network.active,game.network.hosting,game.session_started]
func _remember_session() -> void:
	state_id=game.state.get_instance_id();session_key=_key()
func reset() -> void:
	if authority():
		for id in jobs:_send_event(id,{},"")
	jobs.clear();last_request.clear();synced_peer=0;cancel_pending=false
	_remember_session()
func handle(value:String) -> bool:
	if not value.begins_with("gather:") and not value.begins_with("resource:buy:") and not value.begins_with("resource:sell:"):return false
	request(value);return true
func request(action:String) -> void:
	if game.falls.local_down():return
	if not game.session_started:return
	if game.network.active and not game.network.ready_session:return
	if not authority():_request.rpc_id(1,action)
	else:
		var message:=apply(own_id(),action)
		if not message.is_empty():game.hud.toast(message)

@rpc("any_peer","call_remote","reliable",0)
func _request(action:String) -> void:
	var n:FarmNetwork=game.network;var sender:=multiplayer.get_remote_sender_id()
	if not n.active or not n.hosting or not n.ready_session or sender!=n.accepted:return
	var message:=apply(sender,action)
	if not message.is_empty():_reply.rpc_id(sender,message)

@rpc("authority","call_remote","reliable",0)
func _reply(message:String) -> void:
	game.hud.toast(message)

func position_for(id:int) -> Vector3:
	return game.player.position if id==own_id() else game.network.target
func _valid_actor(id:int) -> bool:
	if game.falls.is_player_down(id):return false
	if FarmWater.swimming_at(position_for(id)):return false
	if not game.session_started:return false
	if id==own_id():return not game.build_mode and game.hud.modal_kind.is_empty() and not game._mounted() and not game.actor.airborne
	var n:FarmNetwork=game.network
	return n.active and n.hosting and n.ready_session and id==n.accepted and Time.get_ticks_msec()-n.motion_received_at<=1500 and not n.remote_airborne and n.mounts.rider!=id
func _near(id:int,p:Vector2,reach:float=3.0) -> bool:
	var at:=position_for(id)
	return Vector2(at.x,at.z).distance_to(p)<=reach and absf(at.y-FarmLandscape.height_at(Vector2(at.x,at.z)))<=3.0
func _site(kind:String,index:int) -> Vector2:
	return FarmResourceSites.FISH_SPOTS[index] if kind=="fish" else FarmResourceSites.ORE_SPOTS[index]
func _can(kind:String,index:int) -> String:
	return FarmResources.can_catch(game.state,index) if kind=="fish" else FarmResources.can_extract(game.state,index)

func apply(id:int,action:String) -> String:
	if game.falls.is_player_down(id):return "Aguarde se recuperar."
	if session_key!=_key() or (authority() and state_id!=game.state.get_instance_id()):reset()
	if not authority() or not game.session_started or (game.network.active and not game.network.ready_session):return "Aguarde a fazenda carregar."
	if id!=own_id() and (not game.network.active or id!=game.network.accepted):return "Jogador desconectado."
	if action=="gather:cancel":
		_stop(id,"");return ""
	var now:=Time.get_ticks_msec()
	if now-int(last_request.get(id,-10000))<300:return "Espere um instante."
	last_request[id]=now
	var parts:=action.split(":")
	if parts.size()!=3:return "Ação inválida."
	if parts[0]=="resource":
		if jobs.has(id):return "Termine ou cancele a coleta primeiro."
		var before:Dictionary=game.state.serialize().duplicate(true)
		var error:=""
		if parts[1]=="buy":
			if parts[2]=="mine" and not _near(id,FarmResourceSites.MINE_AT):return "Aproxime-se da entrada da mina."
			if parts[2] in ["gallery_1","gallery_2"]:
				var gate_index:=0 if parts[2]=="gallery_1" else 1
				if not _near(id,FarmMineLayout.GALLERY_AT[gate_index]):return "Aproxime-se da passagem dentro da mina."
			error=FarmResources.buy(game.state,parts[2])
		elif parts[1]=="sell":
			if FarmResources.sell(game.state,parts[2])<=0:return "Não há esse recurso no estoque."
		else:return "Ação inválida."
		if not error.is_empty():return error
		if not _commit(before):return "Não foi possível salvar. Nenhum recurso foi alterado."
		return "Compra concluída." if parts[1]=="buy" else "Venda concluída."
	if parts[0]!="gather" or parts[1] not in ["fish","mine"]:return "Ação inválida."
	var count:=FarmResourceSites.FISH_SPOTS.size() if parts[1]=="fish" else FarmResources.NODE_COUNT
	if not parts[2].is_valid_int() or str(int(parts[2]))!=parts[2] or int(parts[2])<0 or int(parts[2])>=count:return "Ação inválida."
	var kind:String=parts[1];var index:=int(parts[2])
	if jobs.has(id):return "Você já está coletando."
	if not _valid_actor(id) or not _near(id,_site(kind,index),1.55 if kind=="mine" else 3.0):return "Aproxime-se do ponto de coleta, a pé."
	var error:=_can(kind,index)
	if not error.is_empty():return error
	if kind=="mine":
		for job in jobs.values():
			if job.kind==kind and job.index==index:return "Outro jogador está minerando este veio."
	var duration:=8.0 if kind=="fish" else 5.0
	var job:Dictionary={"kind":kind,"index":index,"remaining":duration,"duration":duration,"origin":position_for(id)}
	_event(id,job,"");_send_event(id,job,"")
	return ""

func _commit(before:Dictionary) -> bool:
	if not game._save_game(false,true):game.state.restore(before);return false
	if game.network.active:game.network.broadcast_state()
	game._resource_refresh()
	return true
func _send_event(id:int,job:Dictionary,message:String) -> void:
	if game.network.active and game.network.hosting and game.network.accepted!=0:_event.rpc_id(game.network.accepted,id,job,message)
@rpc("authority","call_remote","reliable",0)
func _event(id:int,job:Dictionary,message:String) -> void:
	if not authority() and session_key!=_key():reset()
	if job.is_empty():jobs.erase(id)
	else:jobs[id]=job.duplicate(true)
	if id==own_id():
		cancel_pending=false
		if not message.is_empty():game.hud.toast(message)
func _stop(id:int,message:String) -> void:
	if not jobs.has(id):return
	_event(id,{},message);_send_event(id,{},message)
func _still_valid(id:int,job:Dictionary) -> bool:
	return _valid_actor(id) and position_for(id).distance_to(job.origin)<=1.3 and _near(id,_site(job.kind,job.index),1.55 if job.kind=="mine" else 3.0)
func _process(delta:float) -> void:
	if game==null:return
	if session_key!=_key() or (authority() and state_id!=game.state.get_instance_id()):reset()
	if not game.session_started:return
	if authority() and game.network.active and synced_peer!=game.network.accepted:
		synced_peer=game.network.accepted
		if synced_peer!=0:
			for id in jobs:_send_event(id,jobs[id],"")
	for id in jobs.keys():
		var job:Dictionary=jobs[id]
		if not authority():
			job.remaining=maxf(0,job.remaining-delta)
			if id==own_id() and not cancel_pending and not _still_valid(id,job):
				cancel_pending=true;request("gather:cancel")
			continue
		if not _still_valid(id,job):_stop(id,"Coleta cancelada.");continue
		job.remaining=maxf(0,job.remaining-delta)
		if job.remaining>0:continue
		var error:=_can(job.kind,job.index)
		if not error.is_empty():_stop(id,error);continue
		var before:Dictionary=game.state.serialize().duplicate(true)
		if job.kind=="fish":
			FarmResources.catch_fish(game.state,job.index)
			if job.index==3 and int(game.state.chapter.stage)==5:
				FarmChapter.act(game.state,"catch_fish")
		else:FarmResources.extract(game.state,job.index)
		var reward:=""
		for key in game.state.resources.stock:
			var count:int=int(game.state.resources.stock[key])-int(before.resources.stock[key])
			if count>0:reward="%s x %d no estoque."%[FarmResources.NAMES[key],count]
		var saved:=_commit(before)
		if saved and int(before.chapter.stage)==5 and int(game.state.chapter.stage)==6:reward+=" Primeiros laços concluídos · +$200!"
		_stop(id,reward if saved else "Falha ao salvar. Nenhum recurso foi alterado.")
