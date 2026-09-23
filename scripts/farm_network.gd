class_name FarmNetwork
extends Node
## First milestone: two-player visits. Farm snapshot is read-only on both peers.
const PORT:=28729
const PROTOCOL:=1
var game:Node3D
var active:=false
var ready_session:=false
var hosting:=false
var local_name:="Fazendeiro"
var remote_name:="Visitante"
var peer:ENetMultiplayerPeer
var remote:Node3D
var remote_model:Node3D
var remote_actor:FarmAvatar
var target:=Vector3.ZERO
var target_yaw:=0.0
var remote_moving:=false
var remote_running:=false
var remote_airborne:=false
var send_timer:=0.0
var join_timer:=0.0
var accepted:=0
var saved_state:FarmState
var saved_position:=Vector3.ZERO
var saved_build:=false
var saved_mounted:=false
var saved_pitch:=0.0
var saved_yaw:=0.0
var name_input:LineEdit
var address_input:LineEdit
var status:Label
var badge:Label
var last_message:=""
var motion_count:=0
var emote_count:=0
var pending_peers:Dictionary={}

func setup(owner_game:Node3D) -> void:
	game=owner_game
	name="NetworkSession"
	multiplayer.peer_connected.connect(_connected)
	multiplayer.peer_disconnected.connect(_disconnected)
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(func():leave("Não foi possível conectar. Confira o endereço e a rede."))
	multiplayer.server_disconnected.connect(func():leave("O anfitrião encerrou a sessão. Sua fazenda solo está preservada."))
	badge=game.hud.label(game.hud.root,"",Vector2(440,122),Vector2(610,35),18,FarmHUD.CREAM)
	badge.mouse_filter=Control.MOUSE_FILTER_IGNORE;badge.visible=false
	badge.add_theme_color_override("font_shadow_color",Color("20392a"));badge.add_theme_constant_override("shadow_offset_y",2)

func show_menu(message:String="") -> void:
	var p:=FarmGameUI.open(game.hud,"network","Jogar junto · 2 jogadores","worker",850,650)
	game.hud.label(p,"VISITA À FAZENDA",Vector2(32,112),Vector2(780,30),20)
	game.hud.label(p,"Andem, pulem e façam emotes juntos.\nProdução e construções ficam pausadas nesta etapa.",Vector2(32,153),Vector2(780,62),19)
	game.hud.label(p,"Seu nome",Vector2(32,225),Vector2(180,32),18)
	name_input=LineEdit.new();name_input.position=Vector2(230,223);name_input.size=Vector2(580,43);name_input.max_length=20;name_input.text=local_name;p.add_child(name_input)
	FarmGameUI.action(game.hud,p,"Hospedar minha fazenda",Rect2(32,288,786,52),"net:host",true)
	game.hud.label(p,"Endereço do anfitrião",Vector2(32,363),Vector2(240,30),18)
	address_input=LineEdit.new();address_input.position=Vector2(280,356);address_input.size=Vector2(538,45);address_input.placeholder_text="Ex.: 192.168.1.10 ou IP do Tailscale";address_input.max_length=64;address_input.add_theme_color_override("font_placeholder_color",FarmHUD.MUTED);p.add_child(address_input)
	FarmGameUI.action(game.hud,p,"Entrar na fazenda",Rect2(32,421,786,52),"net:join")
	status=game.hud.label(p,message if not message.is_empty() else "Mesma rede: use o IP mostrado pelo anfitrião.\nEm casas diferentes: conectem os PCs pelo Tailscale.",Vector2(32,493),Vector2(786,65),18);status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	FarmGameUI.action(game.hud,p,"Voltar",Rect2(32,568,786,46),"net:back")

func session_menu() -> void:
	var p:=FarmGameUI.open(game.hud,"network_session","Visita à fazenda","worker",850,480)
	var addresses:=PackedStringArray()
	for ip in IP.get_local_addresses():
		if ip.contains(".") and not ip.begins_with("127.") and not ip.begins_with("169.254."):addresses.append(ip)
	var text:String="Seu endereço: "+", ".join(addresses)+"\nPorta UDP: %d"%PORT if hosting else "Você está visitando a fazenda de "+remote_name
	game.hud.label(p,text,Vector2(32,122),Vector2(786,92),19).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	game.hud.label(p,"WASD · andar    Espaço · pular    B · emotes\nA visita não altera o save. Esc fecha este menu.",Vector2(32,227),Vector2(786,72),20)
	FarmGameUI.action(game.hud,p,"Continuar visita",Rect2(32,330,380,50),"close",true)
	FarmGameUI.action(game.hud,p,"Encerrar visita" if hosting else "Sair da visita",Rect2(430,330,388,50),"net:leave")

func handle(value:String) -> bool:
	if value.begins_with("net:"):
		match value:
			"net:menu":show_menu()
			"net:host":host(name_input.text)
			"net:join":join(address_input.text,name_input.text)
			"net:back":game.front_end.show_title()
			"net:leave":leave("Visita encerrada. Sua fazenda solo está preservada.")
		return true
	if not active:return false
	if value=="menu":session_menu();return true
	if value=="close" and not ready_session:leave("Conexão cancelada.");return true
	if value=="quit":game._request_quit();return true
	if value=="close" or value=="emotes" or value.begins_with("emote:") or value=="map" or value.begins_with("map:"):return false
	game.hud.toast("Visita: explore e use B para emotes. Fazenda protegida.");return true

func _preserve(who:String) -> void:
	local_name=who.strip_edges().left(20).replace("\n", " ")
	if local_name.is_empty():local_name="Fazendeiro"
	saved_state=game.state;saved_position=game.player.position;saved_build=game.build_mode;saved_pitch=game.pitch;saved_yaw=game.yaw
	var copy:=FarmState.new();copy.restore(saved_state.serialize());game.state=copy
	active=true;game.weapons.holster();game.actor.stop_emote();game._cancel_route()
	saved_mounted=game.horse.mounted
	if saved_mounted:
		game.horse.reset_rider(game.player,game.avatar,game.actor)
		game.player.position+=Vector3(3,0,0)

func host(who:String) -> void:
	if active:return
	peer=ENetMultiplayerPeer.new()
	var error:=peer.create_server(PORT,1)
	if error!=OK:show_menu("Não foi possível hospedar. A porta %d pode estar em uso."%PORT);return
	_preserve(who);hosting=true;ready_session=true;multiplayer.multiplayer_peer=peer
	_start_visit(game.player.position)
	session_menu()

func join(address:String,who:String) -> void:
	if active:return
	address=address.strip_edges()
	if not address.is_valid_ip_address():show_menu("Digite o IP local ou Tailscale do anfitrião.");return
	peer=ENetMultiplayerPeer.new()
	var error:=peer.create_client(address,PORT)
	if error!=OK:show_menu("Não foi possível iniciar a conexão.");return
	_preserve(who);hosting=false;ready_session=false;join_timer=12;multiplayer.multiplayer_peer=peer
	var p:=FarmGameUI.open(game.hud,"network_connect","Conectando…","worker",760,330)
	game.hud.label(p,"Aguardando a fazenda em "+address,Vector2(32,128),Vector2(690,55),22)
	FarmGameUI.action(game.hud,p,"Cancelar",Rect2(32,237,696,48),"net:leave")

func _start_visit(pos:Vector3) -> void:
	game.session_started=true;game.build_mode=false;game.pitch=.45;game.player.position=pos;game.player.velocity=Vector3.ZERO
	game._ensure_player_space();game.hud.close_modal();game._update_camera(1,true);badge.visible=true;game._update_ui()

func _connected(id:int) -> void:
	if hosting:pending_peers[id]=Time.get_ticks_msec()

func _on_connected() -> void:
	_hello.rpc_id(1,PROTOCOL,local_name)

@rpc("any_peer","call_remote","reliable",0)
func _hello(version:int,who:String) -> void:
	var id:=multiplayer.get_remote_sender_id()
	if not hosting or not active or accepted!=0 or not pending_peers.has(id):return
	if version!=PROTOCOL:
		_reject.rpc_id(id,"Versões incompatíveis. Usem a mesma versão do jogo.");return
	accepted=id;pending_peers.erase(id);remote_name=who.strip_edges().left(20)
	var pos:Vector3=game.player.position+Vector3(2,0,0)
	_welcome.rpc_id(id,JSON.stringify(game.state.serialize()),local_name,pos)
	_spawn_remote(remote_name,pos);game.hud.toast(remote_name+" chegou à fazenda!")

@rpc("authority","call_remote","reliable",0)
func _reject(reason:String) -> void:
	leave(reason)

@rpc("authority","call_remote","reliable",0)
func _welcome(snapshot:String,who:String,pos:Vector3) -> void:
	if hosting or not active or ready_session:return
	if snapshot.length()>2000000 or not pos.is_finite():leave("A fazenda recebida não é válida.");return
	var data:Variant=JSON.parse_string(snapshot)
	var restored:=FarmState.new()
	if not restored.restore(data):leave("Não foi possível carregar a fazenda compartilhada.");return
	game.state=restored;game.state.unlimited_money=true;game.world.rebuild(game.state);game.horse.restore(game.state.horse)
	remote_name=who.left(20);accepted=1;ready_session=true
	_start_visit(pos);_spawn_remote(remote_name,pos-Vector3(2,0,0))

func _spawn_remote(who:String,pos:Vector3) -> void:
	_remove_remote()
	remote=Node3D.new();game.add_child(remote);remote.position=pos;target=pos
	remote_model=game.world.model("farmer",remote);remote_actor=FarmAvatar.new();remote_actor.setup(remote_model,game.world)
	var title:=Label3D.new();title.text=who;title.position.y=3.5;title.billboard=BaseMaterial3D.BILLBOARD_ENABLED;title.font_size=42;title.pixel_size=.008;title.modulate=Color("ffe6a0");remote.add_child(title)

func _remove_remote() -> void:
	if is_instance_valid(remote):remote.queue_free()
	remote=null;remote_actor=null

@rpc("any_peer","call_remote","unreliable_ordered",1)
func _motion(pos:Vector3,angle:float,moving:bool,running:bool,airborne:bool,dance:String,elapsed:float) -> void:
	if not ready_session or multiplayer.get_remote_sender_id()!=accepted or not is_instance_valid(remote):return
	if not pos.is_finite() or not is_finite(angle) or absf(pos.x)>250 or absf(pos.z)>250 or pos.y< -4 or pos.y>30:return
	if not is_finite(elapsed):return
	if dance.is_empty():remote_actor.stop_emote()
	elif FarmEmotes.DANCES.has(dance):
		if remote_actor.emote_kind!=dance:remote_actor.airborne=false;remote_actor.emote(dance)
		remote_actor.emote_elapsed=clampf(elapsed,0,6);remote_actor.emote_time=maxf(.1,6-elapsed)
	target=pos;target_yaw=angle;remote_moving=moving;remote_running=running;remote_airborne=airborne;motion_count+=1

func send_emote(key:String) -> void:
	if active and ready_session and accepted!=0:_emote.rpc_id(accepted,key)

@rpc("any_peer","call_remote","reliable",0)
func _emote(key:String) -> void:
	if not ready_session or multiplayer.get_remote_sender_id()!=accepted or remote_actor==null:return
	if not FarmEmotes.DANCES.has(key) and not FarmEmotes.REACTIONS.has(key):return
	remote_actor.airborne=false;remote_actor.emote(key);emote_count+=1

func _process(delta:float) -> void:
	if not active:return
	if not ready_session:
		join_timer-=delta
		if join_timer<=0:leave("Tempo esgotado. Confira o IP, a rede e a liberação no firewall.")
		return
	for id in pending_peers.keys():
		if Time.get_ticks_msec()-int(pending_peers[id])>12000:peer.disconnect_peer(id);pending_peers.erase(id)
	badge.text="VISITA · %s · %s"%[local_name,"2/2 jogadores · Esc opções" if accepted!=0 else "Aguardando amigo · Esc endereço"]
	send_timer-=delta
	if accepted!=0 and send_timer<=0:
		send_timer=.05
		_motion.rpc_id(accepted,game.player.position,game.avatar.rotation.y,Vector2(game.player.velocity.x,game.player.velocity.z).length()>.2,Input.is_action_pressed("run"),game.actor.airborne,game.actor.emote_kind,game.actor.emote_elapsed)
	if is_instance_valid(remote):
		remote.position=remote.position.lerp(target,minf(delta*15,1));remote_model.rotation.y=lerp_angle(remote_model.rotation.y,target_yaw,minf(delta*15,1))
		remote_actor.airborne=remote_airborne;remote_actor.animate(delta,remote_moving,remote_running)

func _disconnected(id:int) -> void:
	pending_peers.erase(id)
	if hosting and id==accepted:
		accepted=0;_remove_remote();game.hud.toast("O visitante saiu. Você pode receber outro amigo.")

func leave(message:String="") -> void:
	if not active:return
	active=false;ready_session=false;accepted=0;pending_peers.clear()
	if peer:peer.close()
	multiplayer.multiplayer_peer=OfflineMultiplayerPeer.new();peer=null
	_remove_remote();badge.visible=false;game.actor.stop_emote()
	game.state=saved_state;game.world.rebuild(game.state);game.horse.restore(game.state.horse)
	game.player.position=saved_position;game.player.velocity=Vector3.ZERO;game.build_mode=saved_build;game.pitch=saved_pitch;game.yaw=saved_yaw
	if saved_mounted:game.horse.mount(game.player,game.avatar,game.actor)
	game.session_started=false;hosting=false;last_message=message
	game._update_ui()
	show_menu(message)

