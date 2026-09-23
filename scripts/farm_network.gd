class_name FarmNetwork
extends Node
## Host-authoritative cooperative farm.
const PORT:=28729
const PROTOCOL:=5
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
var plot_versions:Dictionary={}
var last_sequence:Dictionary={}
var last_action:Dictionary={}
var sequence:=0
var revision:=0
var received_revision:=-1
var sync_timer:=0.0
var crop_visuals:Dictionary={}
var motion_received_at:=0
var coop_path:=""
var harvest_actions:=0
var stock_labels:Dictionary={}
var stock_button:Button
var structure_version:=0
var command_busy:=false
var remote_character:="farmer"
var mounts:=FarmCoopMount.new()
var plot_states:Dictionary={}
var visual_timer:=0.0
var visual_state:Dictionary={}

func setup(owner_game:Node3D) -> void:
	game=owner_game
	coop_path=FarmCoop.path_for(game.save_path)
	mounts.setup(self);add_child(mounts)
	name="NetworkSession"
	multiplayer.peer_connected.connect(_connected)
	multiplayer.peer_disconnected.connect(_disconnected)
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(func():leave("Não foi possível conectar. Confira o endereço e a rede."))
	multiplayer.server_disconnected.connect(func():leave("O anfitrião encerrou a sessão. Sua fazenda solo está preservada."))
	badge=game.hud.label(game.hud.root,"",Vector2(440,122),Vector2(610,35),18,FarmHUD.CREAM)
	stock_button=FarmGameUI.action(game.hud,game.hud.walking.root,"I · Estoque",Rect2(1223,854,156,32),"net:stock");stock_button.visible=false;stock_button.add_theme_font_size_override("font_size",14)
	badge.mouse_filter=Control.MOUSE_FILTER_IGNORE;badge.visible=false
	badge.add_theme_color_override("font_shadow_color",Color("20392a"));badge.add_theme_constant_override("shadow_offset_y",2)

func show_menu(message:String="") -> void:
	var p:=FarmGameUI.open(game.hud,"network","Jogar junto · 2 jogadores","worker",850,650)
	game.hud.label(p,"COOPERATIVO · FAZENDA",Vector2(32,112),Vector2(780,30),20)
	game.hud.label(p,"Construam, produzam e cuidem da fazenda juntos.\nCooperativo salvo à parte; sua fazenda solo fica preservada.",Vector2(32,153),Vector2(585,62),17)
	var character:=OptionButton.new();character.position=Vector2(630,159);character.size=Vector2(182,43)
	character.add_item("Fazendeiro");character.add_item("Fazendeira");character.select(1 if game.avatar.get_meta("character_id","farmer")=="farmer_woman" else 0);p.add_child(character)
	character.item_selected.connect(func(index:int):
		var id:String=FarmCharacters.IDS[index]
		if FarmCharacters.save_choice(id)==OK:FarmCharacters.apply_to_game(game,id)
		else:game.hud.toast("Não foi possível guardar a escolha do personagem."))
	game.hud.label(p,"Seu nome",Vector2(32,225),Vector2(180,32),18)
	name_input=LineEdit.new();name_input.position=Vector2(230,223);name_input.size=Vector2(580,43);name_input.max_length=20;name_input.text=local_name;p.add_child(name_input)
	FarmGameUI.action(game.hud,p,"Continuar cooperativo" if FarmCoop.load_farm(coop_path)!=null else "Criar cooperativo da minha fazenda",Rect2(32,288,786,52),"net:host",true)
	game.hud.label(p,"Endereço do anfitrião",Vector2(32,363),Vector2(240,30),18)
	address_input=LineEdit.new();address_input.position=Vector2(280,356);address_input.size=Vector2(538,45);address_input.placeholder_text="Ex.: 192.168.1.10 ou IP do Tailscale";address_input.max_length=64;address_input.add_theme_color_override("font_placeholder_color",FarmHUD.MUTED);p.add_child(address_input)
	FarmGameUI.action(game.hud,p,"Entrar na fazenda",Rect2(32,421,786,52),"net:join")
	status=game.hud.label(p,message if not message.is_empty() else "Mesma rede: use o IP mostrado pelo anfitrião.\nEm casas diferentes: conectem os PCs pelo Tailscale.",Vector2(32,493),Vector2(786,65),18);status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	FarmGameUI.action(game.hud,p,"Voltar",Rect2(32,568,786,46),"net:back")

func session_menu() -> void:
	var p:=FarmGameUI.open(game.hud,"network_session","Fazenda cooperativa","worker",850,480)
	var addresses:=PackedStringArray()
	for ip in IP.get_local_addresses():
		if ip.contains(".") and not ip.begins_with("127.") and not ip.begins_with("169.254."):addresses.append(ip)
	var text:String="Seu endereço: "+", ".join(addresses)+"\nPorta UDP: %d"%PORT if hosting else "Você está visitando a fazenda de "+remote_name
	game.hud.label(p,text,Vector2(32,122),Vector2(786,92),19).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	game.hud.label(p,"E · interagir    Tab · construir    I · estoque    F5 · salvar\nSó o anfitrião salva o cooperativo, separado da fazenda solo.",Vector2(32,227),Vector2(786,72),20)
	FarmGameUI.action(game.hud,p,"Voltar à fazenda",Rect2(32,330,380,50),"close",true)
	FarmGameUI.action(game.hud,p,"Salvar e encerrar" if hosting else "Sair do cooperativo",Rect2(430,330,388,50),"net:leave")

func handle(value:String) -> bool:
	if value.begins_with("net:"):
		match value:
			"net:menu":
				if active:session_menu()
				else:show_menu()
			"net:stock":
				if ready_session:show_stock()
			"net:host":host(name_input.text)
			"net:join":join(address_input.text,name_input.text)
			"net:back":game.front_end.show_title()
			"net:leave":leave("Visita encerrada. Sua fazenda solo está preservada.")
		return true
	if not active:return false
	if value=="menu":session_menu();return true
	if value=="mode" and mounts.local_rider():game.hud.toast("Desmonte com E antes de construir.");return true
	if value=="net:stock":show_stock();return true
	if value=="nearby_interact":return false
	if value=="save":
		if hosting:game.hud.toast("Cooperativo salvo." if save_coop() else "Falha ao salvar o cooperativo. Tente novamente.")
		else:game.hud.toast("O anfitrião salva o cooperativo automaticamente.")
		return true
	if value.begins_with("crop:"):return false
	if value=="close" and not ready_session:leave("Conexão cancelada.");return true
	if value=="quit":game._request_quit();return true
	if value=="close" or value=="emotes" or value.begins_with("emote:") or value=="map" or value.begins_with("map:"):return false
	if FarmCoopCommands.mutates(value):
		request_command(FarmCoopCommands.capture(game,value));return true
	if value in ["reset_ask","reset_confirm","start"] or value.begins_with("front:"):
		game.hud.toast("Saia do cooperativo antes de trocar ou reiniciar a fazenda.");return true
	return false

func _preserve(who:String) -> void:
	local_name=who.strip_edges().left(20).replace("\n", " ")
	if local_name.is_empty():local_name="Fazendeiro"
	structure_version=0;command_busy=false;sequence=0;revision=0;received_revision=-1;plot_versions.clear();last_sequence.clear();last_action.clear();crop_visuals.clear();plot_states.clear();visual_state.clear()
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
	var restored:=FarmCoop.load_farm(coop_path)
	if restored!=null:game.state=restored
	elif FileAccess.file_exists(coop_path) or FileAccess.file_exists(coop_path+".bak"):
		hosting=false;leave("Não foi possível ler o cooperativo. Os arquivos foram preservados.");return
	if not save_coop():
		hosting=false;leave("Não foi possível criar/salvar o cooperativo. Nada foi substituído.");return
	game.world.rebuild(game.state);game.horse.restore(game.state.horse)
	_start_visit(game.player.position)
	crop_visuals.clear();refresh_crops()
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
	game._ensure_player_space();game.hud.close_modal();game._update_camera(1,true);badge.visible=true;stock_button.visible=true;game._update_ui()

func _connected(id:int) -> void:
	if hosting:pending_peers[id]=Time.get_ticks_msec()

func _on_connected() -> void:
	_hello.rpc_id(1,PROTOCOL,local_name,str(game.avatar.get_meta("character_id","farmer")))

@rpc("any_peer","call_remote","reliable",0)
func _hello(version:int,who:String,character:String) -> void:
	var id:=multiplayer.get_remote_sender_id()
	if not hosting or not active or accepted!=0 or not pending_peers.has(id):return
	if version!=PROTOCOL:
		_reject.rpc_id(id,"Versões incompatíveis. Usem a mesma versão do jogo.");return
	accepted=id;pending_peers.erase(id);remote_name=who.strip_edges().left(20);remote_character=character if FarmCharacters.valid(character) else "farmer"
	var pos:Vector3=game.player.position+Vector3(2,0,0)
	_welcome.rpc_id(id,JSON.stringify(game.state.serialize()),local_name,pos,plot_versions,structure_version,str(game.avatar.get_meta("character_id","farmer")))
	_spawn_remote(remote_name,pos);game.hud.toast(remote_name+" chegou à fazenda!")

@rpc("authority","call_remote","reliable",0)
func _reject(reason:String) -> void:
	leave(reason)

@rpc("authority","call_remote","reliable",0)
func _welcome(snapshot:String,who:String,pos:Vector3,versions:Dictionary,topology:int,character:String) -> void:
	if hosting or not active or ready_session:return
	if snapshot.length()>2000000 or not pos.is_finite():leave("A fazenda recebida não é válida.");return
	var data:Variant=JSON.parse_string(snapshot)
	var restored:=FarmState.new()
	if not restored.restore(data):leave("Não foi possível carregar a fazenda compartilhada.");return
	game.state=restored;game.state.unlimited_money=true;game.world.rebuild(game.state);game.horse.restore(game.state.horse)
	remote_character=character if FarmCharacters.valid(character) else "farmer";structure_version=topology;remote_name=who.left(20);accepted=1;ready_session=true;plot_versions=versions;received_revision=-1
	_start_visit(pos);_spawn_remote(remote_name,pos-Vector3(2,0,0));_client_ready.rpc_id(1)

func _spawn_remote(who:String,pos:Vector3) -> void:
	_remove_remote();motion_received_at=0;remote_airborne=false;remote_moving=false
	remote=CharacterBody3D.new();game.add_child(remote);remote.position=pos;target=pos
	var collider:=CollisionShape3D.new();var capsule:=CapsuleShape3D.new();capsule.radius=.37;capsule.height=2.58;collider.shape=capsule;collider.position.y=1.29;remote.add_child(collider);remote.collision_layer=0;remote.collision_mask=1
	remote_model=FarmCharacters.instantiate_model(remote_character);remote.add_child(remote_model);remote_actor=FarmAvatar.new();remote_actor.setup(remote_model,game.world)
	var title:=Label3D.new();title.text=who;title.position.y=3.5;title.billboard=BaseMaterial3D.BILLBOARD_ENABLED;title.font_size=42;title.pixel_size=.008;title.modulate=Color("ffe6a0");remote.add_child(title)

func _remove_remote() -> void:
	if is_instance_valid(remote):remote.queue_free()
	remote=null;remote_actor=null

@rpc("any_peer","call_remote","unreliable_ordered",1)
func _motion(pos:Vector3,angle:float,moving:bool,running:bool,airborne:bool,dance:String,elapsed:float) -> void:
	if not ready_session or multiplayer.get_remote_sender_id()!=accepted or not is_instance_valid(remote):return
	if mounts.rider==accepted:return
	if not pos.is_finite() or not is_finite(angle) or absf(pos.x)>250 or absf(pos.z)>250 or pos.y< -4 or pos.y>30:return
	if not is_finite(elapsed):return
	if dance.is_empty():remote_actor.stop_emote()
	elif FarmEmotes.DANCES.has(dance):
		if remote_actor.emote_kind!=dance:remote_actor.airborne=false;remote_actor.emote(dance)
		remote_actor.emote_elapsed=clampf(elapsed,0,6);remote_actor.emote_time=maxf(.1,6-elapsed)
	target=pos;target_yaw=angle;remote_moving=moving;remote_running=running;remote_airborne=airborne;motion_count+=1;motion_received_at=Time.get_ticks_msec()

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
	if hosting:
		game.state.tick(delta);game.world.update_staff(game.state,delta);track_plots();game.world.animate(delta,game.player.position,game.state);game.world.update_crops(game.state)
		sync_timer-=delta
		if sync_timer<=0:
			sync_timer=.5;broadcast_state()
	if hosting and accepted!=0:
		visual_timer-=delta
		if visual_timer<=0:
			visual_timer=.1;_visuals.rpc_id(accepted,structure_version,var_to_bytes(FarmCoopVisuals.capture(game.world)).compress(FileAccess.COMPRESSION_GZIP))
	elif not hosting and not visual_state.is_empty():FarmCoopVisuals.apply(game.world,visual_state,minf(1,delta*15))
	badge.text="COOP · %s · %s"%[local_name,"2/2 jogadores · Esc opções" if accepted!=0 else "Aguardando amigo · Esc endereço"]
	send_timer-=delta
	if accepted!=0 and send_timer<=0:
		send_timer=.05
		_motion.rpc_id(accepted,game.player.position,game.avatar.rotation.y,Vector2(game.player.velocity.x,game.player.velocity.z).length()>.2,Input.is_action_pressed("run"),game.actor.airborne,game.actor.emote_kind,game.actor.emote_elapsed)
	if is_instance_valid(remote) and mounts.rider!=accepted:
		remote.position=remote.position.lerp(target,minf(delta*15,1));remote_model.rotation.y=lerp_angle(remote_model.rotation.y,target_yaw,minf(delta*15,1))
		remote_actor.airborne=remote_airborne;remote_actor.animate(delta,remote_moving,remote_running)

func _disconnected(id:int) -> void:
	mounts.release(id)
	pending_peers.erase(id);last_sequence.erase(id);last_action.erase(id)
	if hosting and id==accepted:
		accepted=0;_remove_remote();game.hud.toast("O visitante saiu. Você pode receber outro amigo.")

func leave(message:String="") -> void:
	if not active:return
	if hosting and ready_session and not save_coop():
		game.hud.toast("Falha ao salvar. A sessão continua aberta para tentar novamente.");return
	mounts.reset()
	active=false;ready_session=false;accepted=0;pending_peers.clear()
	if peer:peer.close()
	multiplayer.multiplayer_peer=OfflineMultiplayerPeer.new();peer=null
	_remove_remote();badge.visible=false;stock_button.visible=false;game.actor.stop_emote()
	game.state=saved_state;game.world.rebuild(game.state);game.horse.restore(game.state.horse)
	game.player.position=saved_position;game.player.velocity=Vector3.ZERO;game.build_mode=saved_build;game.pitch=saved_pitch;game.yaw=saved_yaw
	if saved_mounted:game.horse.mount(game.player,game.avatar,game.actor)
	game.session_started=false;hosting=false;last_message=message
	game._update_ui()
	show_menu(message)


func save_coop() -> bool:
	if not active or not hosting:return true
	return FarmCoop.save_farm(coop_path,game.state)

func context() -> Dictionary:
	if not ready_session:return {}
	var best:=-1
	var distance:=2.6
	for i in range(game.state.items.size()):
		if game.state.items[i].kind not in ["plot","barn"]:continue
		var d:float=game._distance_to_item(i)
		if d<distance:best=i;distance=d
	if best<0:return {}
	var item:Dictionary=game.state.items[best]
	if item.kind=="barn":return {"action":"coop_stock","text":"Estoque compartilhado","ready":true}
	var op:=FarmCoop.operation(item)
	var text:String={"plant":"Plantar "+FarmState.CROPS[game.crop].name,"water":"Regar "+FarmState.CROPS[item.crop].name,"harvest":"Colher "+FarmState.CROPS[item.crop].name}.get(op,"Crescendo · %d%%"%int(item.growth*100))
	return {"action":"coop_tend","text":text,"index":best,"op":op,"ready":not op.is_empty() and not game.actor.airborne and game.action_cooldown<=0 and game.actor.action_time<=0,"seeds":op=="plant"}

func interact() -> void:
	if not game.hud.modal_kind.is_empty():return
	var choice:=context()
	if choice.is_empty():return
	if choice.action=="coop_stock":show_stock();return
	if not choice.ready:return
	request_tend(choice.index,choice.op,game.crop)

func request_tend(index:int,op:String,crop:String) -> void:
	if not ready_session:return
	sequence+=1
	game.action_cooldown=.35
	var expected:=int(plot_versions.get(index,0))
	if hosting:apply_tend(1,sequence,index,op,crop,expected,structure_version)
	else:_tend_request.rpc_id(1,sequence,index,op,crop,expected,structure_version)

@rpc("any_peer","call_remote","reliable",0)
func _tend_request(seq:int,index:int,op:String,crop:String,expected:int,topology:int) -> void:
	var sender:=multiplayer.get_remote_sender_id()
	if not hosting or not ready_session or sender!=accepted:return
	if topology<0:return
	apply_tend(sender,seq,index,op,crop,expected,topology)

func apply_tend(sender:int,seq:int,index:int,op:String,crop:String,expected:int,topology:int=-1) -> void:
	if not hosting or not active:return
	if sender!=1 and sender!=accepted:return
	if seq<=int(last_sequence.get(sender,0)):return
	last_sequence[sender]=seq
	var error:=""
	var now:=Time.get_ticks_msec()
	if topology>=0 and topology!=structure_version:error="A fazenda mudou. Selecione o canteiro novamente."
	elif index<0 or index>=game.state.items.size() or game.state.items[index].kind!="plot":error="Canteiro inválido."
	elif not FarmState.CROPS.has(crop):error="Semente inválida."
	elif int(plot_versions.get(index,0))!=expected or FarmCoop.operation(game.state.items[index])!=op or op.is_empty():error="Esse canteiro já mudou. Confira a nova ação."
	elif now<int(last_action.get(sender,0)):error="Espere terminar a ação."
	else:
		var pos:Vector3=game.player.position if sender==1 else target
		var item:Dictionary=game.state.items[index]
		var area:Rect2=game.state.item_rect("plot",Vector2(item.x,item.z),item.turn)
		var flat:=Vector2(pos.x,pos.z)
		if flat.distance_to(flat.clamp(area.position,area.end))>2.65 or absf(pos.y-FarmLandscape.height_at(flat))>1.0:error="Aproxime-se do canteiro, no chão."
		elif (sender==1 and game.actor.airborne) or (sender!=1 and (remote_airborne or now-motion_received_at>5000)):error="Aguarde estar no chão perto do canteiro."
	if not error.is_empty():send_outcome(sender,index,"",crop,error);return
	var before:Dictionary=game.state.serialize()
	var affected:Array=game.state.water_targets(index) if op=="water" else [index]
	var item:Dictionary=game.state.items[index]
	var visual_crop:String=item.crop if op=="harvest" else crop
	var message:String=game.state.tend(index,crop)
	# Insufficient funds or unchanged state must never be acknowledged as success.
	if game.state.serialize()==before:send_outcome(sender,index,"",crop,message);return
	if not save_coop():
		game.state.restore(before);send_outcome(sender,index,"",crop,"Falha ao salvar. A ação foi desfeita; tente novamente.");return
	for changed in affected:
		plot_versions[changed]=int(plot_versions.get(changed,0))+1;plot_states[changed]=plot_stamp(game.state.items[changed])
	last_action[sender]=now+(1200 if op=="water" else 800)
	if op=="harvest":harvest_actions+=1
	refresh_crops();broadcast_state();send_outcome(sender,index,op,visual_crop,message)

func send_outcome(sender:int,index:int,op:String,crop:String,message:String) -> void:
	apply_outcome(sender,index,op,crop,message)
	if accepted!=0:_outcome.rpc_id(accepted,sender,index,op,crop,message)

@rpc("authority","call_remote","reliable",0)
func _outcome(sender:int,index:int,op:String,crop:String,message:String) -> void:
	if active and ready_session:apply_outcome(sender,index,op,crop,message)

func apply_outcome(sender:int,index:int,op:String,crop:String,message:String) -> void:
	var local:bool=sender==multiplayer.get_unique_id()
	if local:game.hud.toast(message)
	if op.is_empty() or index<0 or index>=game.state.items.size():return
	var item:Dictionary=game.state.items[index]
	var at:=Vector3(item.x,0,item.z)
	var performer:FarmAvatar=game.actor if local else remote_actor
	var model:Node3D=game.avatar if local else remote_model
	var body:Node3D=game.player if local else remote
	if performer==null or not is_instance_valid(body):return
	var direction:Vector3=at-body.position
	model.rotation.y=atan2(direction.x,direction.z);performer.play(op)
	match op:
		"plant":game.feedback.planted(at)
		"harvest":game.feedback.harvest(at,crop)
		"water":game.feedback.water(at,model.global_transform*Vector3(.47,1.1,1),false,"Regado!",performer.can)
	if local:game._chime(op)

func broadcast_state() -> void:
	if not hosting or not ready_session:return
	revision+=1;update_stock()
	if accepted!=0:_farm_update.rpc_id(accepted,revision,JSON.stringify(game.state.serialize()),plot_versions,structure_version)

@rpc("authority","call_remote","reliable",2)
func _farm_update(number:int,data:String,versions:Dictionary,topology:int) -> void:
	if not active or not ready_session or hosting or number<=received_revision or data.length()>2000000:return
	var restored:=FarmState.new()
	if not restored.restore(JSON.parse_string(data)):return
	received_revision=number;game.state=restored;plot_versions=versions
	if topology!=structure_version:
		structure_version=topology;rebuild_shared()
	refresh_crops();game.world.update_animals(game.state);game.world.update_staff(game.state,0)
	update_stock()

func refresh_crops() -> void:
	for i in range(game.state.items.size()):
		var item:Dictionary=game.state.items[i]
		if item.kind!="plot":continue
		if crop_visuals.get(i,"")!=item.crop:
			game.world.replace_crop(i,item.crop);crop_visuals[i]=item.crop
	game.world.update_crops(game.state)

func show_stock() -> void:
	var p:=FarmGameUI.open(game.hud,"coop_stock","Estoque compartilhado","barn",900,480)
	stock_labels.clear()
	var products:=["carrot","wheat","corn","egg","milk","cheese"]
	var names:=["Cenoura","Trigo","Milho","Ovos","Leite","Queijo"]
	for i in range(products.size()):
		var key:String=products[i]
		var x:=32+(i/3)*430
		var y:=120+(i%3)*76
		FarmGameUI.icon(p,key,Rect2(x,y,44,44))
		game.hud.label(p,names[i],Vector2(x+58,y+4),Vector2(210,35),23)
		stock_labels[key]=game.hud.label(p,str(stock_count(key))+" un.",Vector2(x+275,y+4),Vector2(120,35),24)
	game.hud.label(p,"Produção e vendas dos dois usam este estoque.",Vector2(32,355),Vector2(836,30),18)
	FarmGameUI.action(game.hud,p,"Voltar ao campo",Rect2(32,410,836,44),"close",true)

func stock_count(key:String) -> int:
	if key=="milk":return game.state.milk_stock
	if key=="cheese":return game.state.cheese_stock
	return int(game.state.inventory.get(key,0))

func update_stock() -> void:
	if game.hud.modal_kind!="coop_stock":return
	for key in stock_labels:
		if is_instance_valid(stock_labels[key]):stock_labels[key].text=str(stock_count(key))+" un."

func click_world() -> bool:
	if not game.pointer_valid:return true
	if game.move_index>=0:
		request_command({"action":"move_item","index":game.move_index,"at":game.pointer,"turn":game.turn});return true
	if not game.state.claimed:
		request_command({"action":"claim","at":game.pointer});return true
	if game.build_mode and FarmState.ITEMS.has(game.tool):
		request_command({"action":"place","kind":game.tool,"at":game.pointer,"turn":game.turn,"crop":game.crop});return true
	return false

func request_command(command:Dictionary) -> void:
	if not ready_session or command_busy:return
	sequence+=1;command_busy=true
	if hosting:apply_command(1,sequence,structure_version,command)
	else:_command.rpc_id(1,sequence,structure_version,command)

@rpc("any_peer","call_remote","reliable",0)
func _command(seq:int,topology:int,command:Dictionary) -> void:
	if hosting and ready_session and multiplayer.get_remote_sender_id()==accepted:
		apply_command(accepted,seq,topology,command)

func apply_command(sender:int,seq:int,topology:int,command:Dictionary) -> void:
	if not hosting or not ready_session or sender not in [1,accepted] or seq<=int(last_sequence.get(sender,0)):return
	last_sequence[sender]=seq
	if var_to_bytes(command).size()>32000:command_result(sender,false,"Pedido muito grande.",command);return
	if topology!=structure_version:command_result(sender,false,"A fazenda mudou. Confira a seleção e tente novamente.",command);return
	var before:Dictionary=game.state.serialize()
	var message:=FarmCoopCommands.run(game.state,command)
	var changed:bool=game.state.serialize()!=before
	if changed:
		# Every domain routine must leave a loadable farm; rollback before any replication.
		var check:=FarmState.new()
		if not check.restore(game.state.serialize()) or not save_coop():
			game.state.restore(before);command_result(sender,false,"Não foi possível salvar. A ação foi desfeita.",command);return
		if FarmCoopCommands.structural(command.action):
			structure_version+=1;plot_versions.clear();plot_states.clear();rebuild_shared()
		else:game.world.update_animals(game.state);game.world.update_staff(game.state,0)
		broadcast_state()
	command_result(sender,changed,message if not message.is_empty() else ("Feito! Fazenda compartilhada atualizada." if changed else "Nada mudou. Confira os requisitos."),command)

func command_result(sender:int,success:bool,message:String,command:Dictionary) -> void:
	if sender==1:_command_done(success,message,command)
	else:_command_done.rpc_id(sender,success,message,command)

@rpc("authority","call_remote","reliable",2)
func _command_done(success:bool,message:String,command:Dictionary) -> void:
	if not active:return
	command_busy=false
	if success:
		var action:String=command.get("action","")
		if action in ["place","move_item","remove","claim","route_confirm","apply_text","apply_hen_name"]:
			game.move_index=-1;game._cancel_route();game.hud.close_modal()
			if action=="claim":game.build_mode=true;game.tool="plot";game.focus=Vector3(game.state.center.x,0,game.state.center.y)
		else:refresh_panel()
		game._chime()
	game.hud.toast(message);game._update_ui()

func rebuild_shared() -> void:
	visual_state.clear()
	game.selected=-1;game.selected_hen=-1;game.move_index=-1;game._cancel_route()
	game.world.rebuild(game.state);crop_visuals.clear()
	if not game.horse.mounted:game._ensure_player_space()
	# An index-based editor must never silently retarget another building after removal.
	if game.hud.modal_kind not in ["","network_session","market","parcels","coop_stock"]:
		game.hud.close_modal();game.hud.toast("Construções atualizadas. Selecione novamente para editar.")

func refresh_panel() -> void:
	var h:FarmHUD=game.hud
	var s:FarmState=game.state
	var i:int=game.selected
	match h.modal_kind:
		"market":h.market(s,h.market_tab)
		"parcels":FarmParcels.show(h,s)
		"staff","staff_confirm":h.staff_panel(s)
		"crew","crew_confirm":FarmCrewHUD.show(h,s)
		"raul","raul_confirm":FarmDairyWorkerHUD.show(h,s)
		"chico","chico_confirm":FarmCheeseWorkerHUD.show(h,s)
		"cultivation","cultivation_confirm","cultivation_report":FarmCultivationHUD.report(h,s)
		"milk_stock":FarmDairyHUD.stock(h,s)
		"cheese_stock":FarmCheeseHUD.stock(h,s)
		"cheese_orders":FarmCheeseHUD.orders(h,s)
		"coop_stock":show_stock()
		"irrigation":
			if s.field_staff.hired:FarmCrewHUD.show(h,s)
			else:h.staff_panel(s)
		"barn":h.barn(s,h.building_index)
		"workshop":
			if i>=0 and i<s.items.size():h.workshop(s,i)
		"coop","dairy","dairy_confirm","cheesery","cheese_confirm","pigsty","pig_confirm":
			if i>=0 and i<s.items.size():game._tend_selected()

@rpc("authority","call_remote","reliable",3)
func _visuals(topology:int,packet:PackedByteArray) -> void:
	if not active or not ready_session or hosting or topology!=structure_version:return
	var decoded:Variant=bytes_to_var(packet.decompress_dynamic(4194304,FileAccess.COMPRESSION_GZIP))
	if decoded is Dictionary:visual_state=decoded

@rpc("any_peer","call_remote","reliable",0)
func _client_ready() -> void:
	if hosting and multiplayer.get_remote_sender_id()==accepted:mounts.send_initial()


func plot_stamp(item:Dictionary) -> Array:
	return [item.planted,item.watered,item.crop,item.growth>=1]

func track_plots() -> void:
	for i in range(game.state.items.size()):
		var item:Dictionary=game.state.items[i]
		if item.kind!="plot":continue
		var current:=plot_stamp(item)
		if plot_states.has(i) and plot_states[i]!=current:plot_versions[i]=int(plot_versions.get(i,0))+1
		plot_states[i]=current

# Affection is transient presentation, with proximity checked on the host.
func pet_cat() -> void:
	if not active or not ready_session:return
	if hosting:game.world.cat.pet(game.player.position)
	else:_pet_cat.rpc_id(1)

@rpc("any_peer","call_remote","reliable",0)
func _pet_cat() -> void:
	if not hosting or not ready_session or multiplayer.get_remote_sender_id()!=accepted:return
	if not is_instance_valid(remote) or Time.get_ticks_msec()-motion_received_at>1500:return
	game.world.cat.pet(target)
