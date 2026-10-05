class_name FarmChapterWorld
extends Node3D
## Shared chapter props and host-authoritative, on-foot animal escort.
const NENA_AT:=Vector2(-27,22)
const RESCUE_AT:=Vector2(-27,-28)
const REPAIR_AT:=FarmResourceSites.FISH_SPOTS[3]+Vector2(3,3)
var game:Node3D
var hen:Node3D
var nena:Node3D
var nena_actor:=FarmAvatar.new()
var fence:Node3D
var bench:Node3D
var debris:Node3D
var basket:Node3D
var nena_label:Label3D
var hen_label:Label3D
var repair_label:Label3D
var follow_peer:=0
var trail:Array[Vector3]=[]
var hen_target:=Vector3.ZERO
var state_id:=0
var session_key:=""
var last_stage:=-1
var clock:=0.0
var sync_clock:=0.0

func setup(g:Node3D) -> void:
	game=g;name="ChapterWorld";process_priority=14
	nena=_model("vendor",NENA_AT)
	nena.rotation.y=PI
	FarmAvatar.prepare_model(nena);nena_actor.setup(nena)
	basket=_model("chapter_delivery_basket",NENA_AT+Vector2(1.1,.1))
	hen=_model("chicken",RESCUE_AT)
	fence=_model("chapter_rescue_fence",RESCUE_AT+Vector2(-1.5,0));fence.rotation.y=PI/2
	bench=_model("chapter_fishing_bench",REPAIR_AT)
	bench.rotation.y=-PI/2
	debris=_model("chapter_fishing_debris",REPAIR_AT)
	nena_label=_label(nena,2.5)
	hen_label=_label(hen,1.5)
	repair_label=_label(self,2.0);repair_label.position+=_ground(REPAIR_AT)
	reset()

func _model(key:String,at:Vector2) -> Node3D:
	var scene:=load("res://assets/models/%s.glb"%key) as PackedScene
	var node:=scene.instantiate() as Node3D
	add_child(node);node.position=_ground(at)
	return node

func _label(parent:Node3D,height:float) -> Label3D:
	var label:=Label3D.new();parent.add_child(label);label.position.y=height
	label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.font_size=42;label.pixel_size=.0055
	label.modulate=Color("fff0b4");label.outline_modulate=Color("26372d")
	label.visibility_range_end=30;label.visibility_range_end_margin=5
	return label

func _ground(at:Vector2) -> Vector3:return Vector3(at.x,FarmLandscape.height_at(at),at.y)
func own_id() -> int:return multiplayer.get_unique_id() if game.network.active else 1
func authority() -> bool:return not game.network.active or game.network.hosting
func _key() -> String:return "%s:%s:%s"%[game.network.active,game.network.hosting,game.session_started]
func stage() -> int:return int(game.state.chapter.stage)
func reset() -> void:
	follow_peer=0;trail.clear();last_stage=-1;sync_clock=0
	state_id=game.state.get_instance_id();session_key=_key()
	if hen:hen.position=_ground(RESCUE_AT);hen_target=hen.position
	_refresh()

func destination() -> Dictionary:
	var at:=NENA_AT;var title:="Dona Nena · primeiros laços"
	if stage()==2 or stage()==3:
		at=Vector2(hen.position.x,hen.position.z) if stage()==2 or follow_peer==0 else NENA_AT
		title="Pipoca · galinha perdida" if at!=NENA_AT else "Levar Pipoca à Dona Nena"
	elif stage()==4:at=REPAIR_AT;title="Recuperar o pesqueiro"
	elif stage()==5:at=FarmResourceSites.FISH_SPOTS[3];title="Primeira pesca no riacho"
	elif stage()==6:return {}
	return {"key":"chapter","name":title,"at":at,"icon":"book","group":"Locais"}

func nearby() -> Dictionary:
	if game==null or not game.session_started:return {}
	var id:=own_id();var action:="";var text:=""
	if stage() in [0,1] and _near(id,NENA_AT):
		action="accept" if stage()==0 else "deliver"
		text="Conversar com Dona Nena" if stage()==0 else "Entregar 6 cenouras à Dona Nena"
	elif stage()==3 and _near(id,NENA_AT):action="return_animal";text="Devolver Pipoca à Dona Nena"
	elif stage() in [2,3] and _near(id,Vector2(hen.position.x,hen.position.z)):
		action="rescue";text="Chamar Pipoca para seguir você"
	elif stage()==4 and _near(id,REPAIR_AT):action="repair";text="Recuperar o pesqueiro"
	return {} if action.is_empty() else {"action":"chapter","value":action,"text":text}

func request(action:String) -> void:
	if not game.session_started or (game.network.active and not game.network.ready_session):return
	if not authority():_request.rpc_id(1,action)
	else:
		var message:=apply(own_id(),action)
		if not message.is_empty():game.hud.toast(message)

@rpc("any_peer","call_remote","reliable",0)
func _request(action:String) -> void:
	var id:=multiplayer.get_remote_sender_id()
	if not game.network.active or not game.network.hosting or not game.network.ready_session or id!=game.network.accepted:return
	var message:=apply(id,action)
	if not message.is_empty():_reply.rpc_id(id,message)

@rpc("authority","call_remote","reliable",0)
func _reply(message:String) -> void:game.hud.toast(message)

func _position(id:int) -> Vector3:return game.player.position if id==own_id() else game.network.target
func _near(id:int,at:Vector2,reach:float=3.0) -> bool:
	var pos:=_position(id)
	return Vector2(pos.x,pos.z).distance_to(at)<=reach and absf(pos.y-FarmLandscape.height_at(Vector2(pos.x,pos.z)))<2.2
func _valid_actor(id:int) -> bool:
	if game.falls.is_player_down(id) or FarmWater.swimming_at(_position(id)):return false
	if id==own_id():return not game.build_mode and not game._mounted() and not game.pickup.mounted and not game.actor.airborne and game.hud.modal_kind.is_empty()
	return game.network.active and game.network.ready_session and id==game.network.accepted and Time.get_ticks_msec()-game.network.motion_received_at<=1500 and not game.network.remote_airborne and game.network.mounts.rider!=id

func apply(id:int,action:String) -> String:
	if not authority() or not game.session_started or (game.network.active and not game.network.ready_session):return "Aguarde a fazenda carregar."
	if id!=own_id() and id!=game.network.accepted:return "Jogador desconectado."
	if not _valid_actor(id):return "Aproxime-se a pé para ajudar."
	if action in ["accept","deliver","return_animal"] and nena.get_meta("temporary_down",false):return "Espere Dona Nena se recuperar."
	if action in ["rescue","return_animal"] and hen.get_meta("temporary_down",false):return "Espere Pipoca se recuperar."
	if action not in ["accept","deliver","rescue","return_animal","repair"]:return "Ação inválida."
	var at:=REPAIR_AT if action=="repair" else (Vector2(hen.position.x,hen.position.z) if action=="rescue" else NENA_AT)
	if not _near(id,at):return "Aproxime-se do objetivo da missão."
	if action=="return_animal" and (stage()!=3 or Vector2(hen.position.x,hen.position.z).distance_to(NENA_AT)>4.5):return "Traga Pipoca até Dona Nena. Caminhe devagar e espere por ela."
	if action=="rescue" and stage()==3:
		follow_peer=id;trail.clear();trail.append(_position(id));_send_motion()
		return "Pipoca está seguindo você. Leve-a a pé até Dona Nena."
	var before:Dictionary=game.state.serialize().duplicate(true)
	var error:String=FarmChapter.act(game.state,action)
	if not error.is_empty():return error
	if not game._save_game(false,true):
		game.state.restore(before);return "Não foi possível salvar. Tente novamente."
	if action=="rescue":follow_peer=id;trail.clear();trail.append(_position(id))
	if action=="return_animal":follow_peer=0;trail.clear()
	if game.network.active:game.network.broadcast_state()
	game._resource_refresh();_refresh();_send_motion()
	return {"accept":"Dona Nena espera 6 cenouras. Acompanhe a missão no mapa.","deliver":"Entrega feita! Pipoca se perdeu ao norte da fazenda.","rescue":"Pipoca está seguindo você. Caminhe até Dona Nena e espere por ela.","return_animal":"Pipoca voltou para casa! Agora vamos cuidar do pesqueiro.","repair":"Pesqueiro recuperado! Você recebeu uma vara. Pesque no Riacho da Fazenda."}[action]

func _refresh() -> void:
	var current:=stage();last_stage=current
	visible=game.session_started and game.state.claimed
	hen.visible=current>=2;fence.visible=current in [2,3]
	basket.visible=current>=2;bench.visible=current>=5;debris.visible=current<5
	nena_label.text="Dona Nena\n"+({0:"! Primeiros laços",1:"6 cenouras para a entrega",2:"Pipoca se perdeu!",3:"Traga Pipoca para casa",4:"Vamos recuperar o pesqueiro",5:"Experimente sua vara nova",6:"Obrigada pela ajuda!"}[current])
	hen_label.text="Pipoca · E para chamar" if current in [2,3] else "Pipoca · de volta ao lar"
	repair_label.text="Pesqueiro · E para recuperar" if current==4 else ("Pesqueiro recuperado" if current>=5 else "Pesqueiro precisando de cuidado")
	if current>=4 and follow_peer==0 and not hen.get_meta("temporary_down",false):hen.position=_ground(NENA_AT+Vector2(1.6,1.4));hen_target=hen.position

func _walkable(at:Vector3) -> bool:
	var point:=Vector2(at.x,at.z)
	if FarmRegion.water_blocked(point):return false
	for area in game.state.scenery_obstacles:
		if area.grow(.2).has_point(point):return false
	for item in game.state.items:
		if item.kind in ["plot","path"]:continue
		if game.state.item_rect(item.kind,Vector2(item.x,item.z),item.turn).grow(.25).has_point(point):return false
	return true

func _escort(delta:float) -> bool:
	if follow_peer==0 or hen.get_meta("temporary_down",false):return false
	if not _valid_actor(follow_peer):return false
	var player_at:=_position(follow_peer)
	var distance:=hen.position.distance_to(player_at)
	# A horse, vehicle or teleport cannot pull the hen across the map or water.
	if distance>18:return false
	if trail.is_empty() or trail.back().distance_to(player_at)>.75:
		if trail.is_empty() or trail.back().distance_to(player_at)<4:trail.append(player_at)
	if trail.size()>160:trail.resize(160)
	while not trail.is_empty() and hen.position.distance_to(trail[0])<.65:trail.pop_front()
	if trail.is_empty() or distance<1.6:return false
	var direction:Vector3=trail[0]-hen.position;direction.y=0
	if direction.length()<.01:return false
	var step:=direction.normalized()*minf(3.4*delta,direction.length())
	for angle in [0.0,.45,-.45,.9,-.9]:
		var candidate:=hen.position+step.rotated(Vector3.UP,angle)
		candidate.y=FarmLandscape.height_at(Vector2(candidate.x,candidate.z))
		if absf(candidate.y-hen.position.y)>.35 or not _walkable(candidate):continue
		hen.rotation.y=lerp_angle(hen.rotation.y,atan2(candidate.x-hen.position.x,candidate.z-hen.position.z),minf(1,delta*8))
		hen.position=candidate;return true
	return false

func _send_motion() -> void:
	if game.network.active and game.network.hosting and game.network.accepted!=0:_motion.rpc_id(game.network.accepted,hen.position,hen.rotation.y,follow_peer)

@rpc("authority","call_remote","unreliable_ordered",0)
func _motion(at:Vector3,angle:float,leader:int) -> void:
	if authority() or not game.network.ready_session:return
	hen_target=at;hen.rotation.y=angle;follow_peer=leader

func _process(delta:float) -> void:
	if game==null:return
	if session_key!=_key() or (authority() and state_id!=game.state.get_instance_id()):reset()
	visible=game.session_started and game.state.claimed
	if not game.session_started:return
	if last_stage!=stage():_refresh()
	clock+=delta
	if not nena.get_meta("temporary_down",false):nena_actor.update_blink(delta)
	var moving:=false
	if authority():
		if follow_peer!=0 and follow_peer!=own_id() and follow_peer!=game.network.accepted:follow_peer=0;trail.clear()
		if stage()==3:moving=_escort(minf(delta,.05))
		sync_clock+=delta
		if sync_clock>=.1:sync_clock=0;_send_motion()
	elif not hen.get_meta("temporary_down",false):
		moving=hen.position.distance_to(hen_target)>.04
		hen.position=hen.position.lerp(hen_target,1-exp(-delta*12))
	if hen.visible and not hen.get_meta("temporary_down",false):FarmHenMotion.pose(hen,clock,delta,moving,not moving)
