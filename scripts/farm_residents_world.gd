class_name FarmResidentsWorld
extends Node3D
var game:Node3D
var people:Dictionary={}
var labels:Dictionary={}
var actors:Dictionary={}
var homes:Dictionary={}
var art:=FarmBuildArt.new()
var discovery_clock:=0.0
var rosa_garden:Node3D
var rosa_stage:=-1
var delivery_label:Label3D
func setup(owner_game:Node3D) -> void:
	game=owner_game;name="ResidentsWorld"
	for key in FarmResidents.PEOPLE:
		var person:Dictionary=FarmResidents.PEOPLE[key]
		var home:=Node3D.new();add_child(home);home.position=ground(person.at);home.rotation.y=int(person.turn)*PI/2;homes[key]=home
		var item:Dictionary={"kind":"house","level":2 if key=="bento" else 1,"paint":2 if key=="lia" else 0,"roof_paint":1 if key=="rosa" else 0}
		var visual:=art.instantiate(item,home);game.world.paint(visual,item);art.add_collision(item,visual,-1)
		var bounds:=Rect2(person.at-Vector2(4,4),Vector2(8,8));game.world.landscape.solid_bounds.append(bounds);game.state.scenery_obstacles.append(bounds.grow(.4))
		# Low garden details stay beside the entrance, outside the parking area.
		for side in ([] if key=="rosa" else [-1,1]):
			var garden:=art.instantiate({"kind":"produce_crates" if key=="bento" else "wash_tub" if key=="lia" else "raised_bed"},home)
			garden.position+=Vector3(side*5.7,0,-1);art.add_collision({"kind":"produce_crates" if key=="bento" else "wash_tub" if key=="lia" else "raised_bed"},garden,-1)
		var npc:=Node3D.new();add_child(npc);npc.position=ground(FarmResidents.entry(key));npc.rotation.y=home.rotation.y
		var model:=FarmCharacters.instantiate_model(person.model);npc.add_child(model)
		var actor:=FarmAvatar.new();actor.setup(model);people[key]=npc;actors[key]=actor
		for mesh in npc.find_children("*","MeshInstance3D",true,false):
			for surface in range(mesh.mesh.get_surface_count()):
				var source:Material=mesh.mesh.surface_get_material(surface)
				if source is StandardMaterial3D and ("Shirt" in source.resource_name or "Overall" in source.resource_name):
					var material:StandardMaterial3D=source.duplicate();material.albedo_color=Color(person.color);mesh.set_surface_override_material(surface,material)
		var label:=Label3D.new();npc.add_child(label);label.position.y=3.1;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.font_size=40;label.pixel_size=.006
		label.modulate=Color("fff0b4");label.outline_modulate=Color("26372d");label.visibility_range_end=45;labels[key]=label
		# Painted ground guides are visual only: no raised pad or invisible barrier.
		var park:=FarmResidents.parking(key)
		for side in [-1,1]:game.world.box(self,ground(park+Vector2(side*2.5,0))+Vector3.UP*.025,Vector3(.10,.035,6),game.world.material("e8d6a0"))
	var box:=art.instantiate({"kind":"produce_crates"},homes.rosa);box.position=Vector3(2,0,7);art.add_collision({"kind":"produce_crates"},box,-1)
	delivery_label=Label3D.new();box.add_child(delivery_label);delivery_label.position.y=2.2;delivery_label.text="Caixa de Dona Rosa\nE · Pedidos e horta";delivery_label.font_size=34;delivery_label.pixel_size=.006;delivery_label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;delivery_label.visibility_range_end=28
	refresh()
func ground(at:Vector2) -> Vector3:return Vector3(at.x,FarmLandscape.height_at(at),at.y)
func near(key:String) -> bool:
	return game.player.position.distance_to(ground(FarmResidents.entry(key)))<3.1 or (key=="rosa" and game.player.position.distance_to(people[key].position)<3.1)
func actor_ready() -> bool:
	return game.session_started and game.state.claimed and not game.build_mode and not game.pickup.mounted and not game._mounted() and not game.actor.airborne and not game.actor.swimming and not game.falls.local_down()
func truck_ready(key:String) -> bool:
	return not game.network.active and not game.pickup.mounted and absf(game.pickup.speed)<.5 and game.pickup.position.distance_to(ground(FarmResidents.parking(key)))<8.0
func nearby() -> Dictionary:
	if not actor_ready():return {}
	for key in people:
		if near(key) and not people[key].get_meta("temporary_down",false):return {"action":"resident","value":key,"text":"Conversar com "+FarmResidents.PEOPLE[key].name}
	return {}
func transact(key:String,action:String) -> String:
	if game.network.active:return "As entregas de camionetinha estão disponíveis no solo."
	if not FarmResidents.PEOPLE.has(key) or not actor_ready() or not near(key):return "Aproxime-se do morador a pé."
	if people[key].get_meta("temporary_down",false):return "Espere o morador se recuperar."
	if action!="meet" and game.hud.modal_kind!=("rosa_story" if action.begins_with("story_") else "resident_"+key):return "Converse com o morador antes de confirmar."
	if action in ["deliver","story_deliver"] and not truck_ready(key):return "Estacione a camionetinha perto da casa."
	var before:Dictionary=game.state.serialize()
	var error:=FarmRosa.act(game.state,action) if key=="rosa" and action.begins_with("story_") else FarmResidents.act(game.state,key,action)
	if not error.is_empty():return error
	if not game._save_game(false,true):game.state.restore(before);return "Não foi possível salvar. A entrega foi desfeita."
	game.pickup.refresh_cargo();game._update_ui();refresh()
	return ""
func handle(action:String) -> void:
	if action=="residents":FarmResidentsHUD.board(game);return
	var verb:=action.get_slice(":",1);var key:=action.get_slice(":",2)
	if not FarmResidents.PEOPLE.has(key):return
	if verb=="mark":
		if not game.state.residents[key].known:return
		game.navigator.select(FarmResidents.entry(key),"Casa de "+FarmResidents.PEOPLE[key].name,"resident_"+key);game.hud.close_modal();return
	if verb=="talk":
		if not actor_ready() or not near(key):return
		if not game.network.active:
			var error:=transact(key,"meet")
			if not error.is_empty():game.hud.toast(error);return
		FarmResidentsHUD.visit(game,key);return
	if key=="rosa" and verb=="story":
		if actor_ready() and near(key):FarmRosaHUD.show(game)
		return
	if key=="rosa" and verb in ["story_accept","story_deliver"]:
		var previous_influence:=FarmResidents.influence(game.state)
		var story_error:=transact(key,verb)
		if not story_error.is_empty():game.hud.toast(story_error);return
		FarmRosaHUD.show(game)
		var story_message:="Ajuda combinada! Traga os produtos na caçamba, sem prazo." if verb=="story_accept" else "A horta ganhou vida! +5 influência." if game.state.rosa_story.stage<3 else "Amizade floresceu! Canteiro da amizade liberado em TAB → Jardim."
		for person in FarmResidents.PEOPLE.values():
			if previous_influence<int(person.need) and FarmResidents.influence(game.state)>=int(person.need):story_message+=" %s agora aceita pedidos!"%person.name
		game.hud.toast(story_message)
		return
	if verb not in ["accept","deliver"]:return
	var payment:=FarmResidents.reward(game.state,key);var old_influence:=FarmResidents.influence(game.state)
	var error:=transact(key,verb)
	if not error.is_empty():game.hud.toast(error);return
	FarmResidentsHUD.visit(game,key)
	var message:="Pedido aceito! Carregue os produtos com V e volte sem pressa."
	if verb=="deliver":
		message="Entrega concluída! +$%d e +5 influência."%payment
		for person in FarmResidents.PEOPLE.values():
			if old_influence<int(person.need) and FarmResidents.influence(game.state)>=int(person.need):message+=" %s agora aceita seus pedidos!"%person.name
	game.hud.toast(message)
func refresh() -> void:
	if game==null:return
	refresh_rosa_garden()
	for key in labels:
		var row:Dictionary=game.state.residents[key]
		labels[key].text=FarmResidents.PEOPLE[key].name+"\n"+("! Entrega aguardada" if row.active else "E · Conversar")
func discover() -> void:
	if game.network.active or not game.session_started or not game.state.claimed:return
	var changed:PackedStringArray=[];var before:Dictionary=game.state.residents.duplicate(true)
	for key in people:
		if not game.state.residents[key].known and game.player.position.distance_to(ground(FarmResidents.entry(key)))<20:
			game.state.residents[key].known=true;changed.append(FarmResidents.PEOPLE[key].name)
	if changed.is_empty():return
	if not game._save_game(false,true):game.state.residents=before;return
	game.hud.toast("Casa descoberta · "+", ".join(changed)+" · Marcada no mapa");refresh()
func _process(delta:float) -> void:
	if game==null:return
	visible=game.session_started
	if not visible:return
	discovery_clock+=delta
	if discovery_clock>=.5:discovery_clock=0;discover();refresh()
	for key in actors:
		if people[key].get_meta("temporary_down",false):continue
		if key=="rosa":animate_rosa(delta)
		else:actors[key].animate(delta,false,false)

func refresh_rosa_garden() -> void:
	var stage:int=game.state.rosa_story.stage
	if stage==rosa_stage:return
	rosa_stage=stage
	if is_instance_valid(rosa_garden):rosa_garden.free()
	rosa_garden=Node3D.new();homes.rosa.add_child(rosa_garden)
	for side in [-1,1]:
		var bed:=art.instantiate({"kind":"raised_bed"},rosa_garden);bed.position=Vector3(side*5.7,0,4)
		for mesh in bed.find_children("*","MeshInstance3D",true,false):
			if str(mesh.name).begins_with("Carrot") or str(mesh.name).begins_with("Lettuce"):mesh.visible=stage>=2
		art.add_collision({"kind":"raised_bed"},bed,-1)
		if stage==0:
			for n in range(4):game.world.box(rosa_garden,Vector3(side*5.7+.15*n,.5,4),Vector3(.05,.9,.05),game.world.material("8f8155"))
	if stage>=1:
		var tools:=art.instantiate({"kind":"compost"},rosa_garden);tools.position=Vector3(-6,0,-3);art.add_collision({"kind":"compost"},tools,-1)
	if stage>=3:
		var flowers:=art.instantiate({"kind":"rosa_bed"},rosa_garden);flowers.position=Vector3(6,0,-2);art.add_collision({"kind":"rosa_bed"},flowers,-1)
func animate_rosa(delta:float) -> void:
	var npc:Node3D=people.rosa;var actor:FarmAvatar=actors.rosa
	var schedule:=FarmRosa.routine(game.state.elapsed)
	var destination:Vector3=ground(FarmResidents.PEOPLE.rosa.at+schedule.at)
	var talking:bool=game.hud.modal_kind in ["resident_rosa","rosa_story"]
	var moving:bool=not talking and npc.position.distance_to(destination)>.08
	if moving:
		var direction:=destination-npc.position
		npc.rotation.y=lerp_angle(npc.rotation.y,atan2(direction.x,direction.z),minf(1,delta*5))
		npc.position=npc.position.move_toward(destination,delta*1.1)
		npc.position.y=FarmLandscape.height_at(Vector2(npc.position.x,npc.position.z))
	elif not talking and schedule.activity=="Cuidando da horta" and game.state.rosa_story.stage>=2:
		var bed_direction:=ground(FarmResidents.PEOPLE.rosa.at+Vector2(-5.7,4))-npc.position
		npc.rotation.y=lerp_angle(npc.rotation.y,atan2(bed_direction.x,bed_direction.z),minf(1,delta*5))
		if actor.action_time<=0:actor.play("water")
	actor.animate(delta,moving,false)
	labels.rosa.text="Dona Rosa\n"+("E · Conversar" if talking else str(schedule.activity))
