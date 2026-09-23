class_name FarmWeapons
extends Node3D
## Self-contained shop, NPC, practice targets and third-person pistol controller.
## Kept separate from the map builder; site is outside all buyable land.
const SHOP_AT:=Vector3(-33.5,0,22)
const SITE:=Rect2(-35,8,3,18)
const SHOT_INTERVAL:=0.28
const RELOAD_TIME:=1.25
var game:Node3D
var npc:Node3D
var npc_actor:=FarmAvatar.new()
var pistol:Node3D
var muzzle:MeshInstance3D
var armed:=false
var aiming:=false
var cooldown:=0.0
var reload_left:=0.0
var recoil:=0.0
var hit_time:=0.0
var elapsed:=0.0
var targets:Array[Node3D]=[]
var flashes:Array[Dictionary]=[]
var sound:=AudioStreamPlayer.new()
var layer:=CanvasLayer.new()
var status:Label
var reticle:Label
var last_state:FarmState
var walk_pitch:=0.78

func setup(host:Node3D) -> void:
	game=host;last_state=game.state
	process_physics_priority=10 # Pose after the main actor's walk/idle update.
	_reserve_site()
	_build_shop()
	pistol=load("res://assets/models/pistol_p8.glb").instantiate()
	game.actor.hand_socket.add_child(pistol);pistol.visible=false
	muzzle=MeshInstance3D.new();var flash:=SphereMesh.new();flash.radius=.06;flash.height=.12
	muzzle.mesh=flash;var light:=StandardMaterial3D.new();light.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;light.albedo_color=Color("ffe29b")
	muzzle.material_override=light;pistol.add_child(muzzle);muzzle.position=Vector3(0,.184,.235);muzzle.visible=false
	add_child(sound);sound.volume_db=-16
	_build_hud()
	game.hud.action.connect(_shop_action)

func _reserve_site() -> void:
	# Authoring hook for this small public site, applied to runtime scenery only.
	# No player item or property is removed, relocated or claimed.
	var scenery:Array[Dictionary]=[]
	for record in game.world.landscape.scenery:
		if not SITE.grow(float(record.radius)+.4).has_point(record.p):scenery.append(record)
	game.world.landscape.scenery=scenery
	var grass:Array[Vector2]=[]
	for p in game.world.landscape.decoration_points:
		if not SITE.has_point(p):grass.append(p)
	game.world.landscape.decoration_points=grass
	game.world.landscape.property_stamp="armory-site"
	game.world.landscape.refresh(game.state)

func _asset(key:String,at:Vector3) -> Node3D:
	var model:Node3D=load("res://assets/models/%s.glb"%key).instantiate()
	add_child(model);model.position=at
	model.position.y=FarmLandscape.height_at(Vector2(at.x,at.z))
	return model

func _solid(parent:Node3D,at:Vector3,size:Vector3) -> StaticBody3D:
	var body:=StaticBody3D.new();var collision:=CollisionShape3D.new();var shape:=BoxShape3D.new()
	shape.size=size;collision.shape=shape;collision.position=at;body.add_child(collision);parent.add_child(body)
	return body

func _build_shop() -> void:
	npc=_asset("gunsmith",SHOP_AT);npc.rotation.y=PI/2;FarmAvatar.prepare_model(npc);npc_actor.setup(npc)
	_solid(npc,Vector3(0,1.05,0),Vector3(1.0,2.1,.60))
	var bench:=_asset("gunsmith_bench",SHOP_AT+Vector3(1.0,0,0));bench.rotation.y=PI/2
	_solid(bench,Vector3(0,.55,0),Vector3(2.15,1.1,.8))
	var display:Node3D=load("res://assets/models/pistol_p8.glb").instantiate()
	bench.add_child(display);display.position=Vector3(-.35,1.15,0);display.rotation=Vector3(0,.6,PI/2)
	var label:=Label3D.new();label.text="DAMIÃO\nArmeiro do vale";label.font_size=30;label.pixel_size=.0056
	label.position=Vector3(0,2.70,0);label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.modulate=Color("fff0ce");label.outline_size=5;npc.add_child(label)
	for i in range(3):
		var target:=_asset("practice_target",Vector3(-33.2,0,10+i*4))
		target.rotation.y=PI/2 # Faces east, toward the road.
		var body:=_solid(target,Vector3(0,1.56,0),Vector3(1,.10,1))
		body.set_meta("practice_target",target)
		targets.append(target)

func _build_hud() -> void:
	layer.layer=12;add_child(layer)
	var ui:=Control.new();ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);ui.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(ui)
	status=Label.new();status.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	status.position=Vector2(-368,145);status.size=Vector2(344,96);status.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	status.add_theme_font_size_override("font_size",19);status.add_theme_color_override("font_color",Color("fff7df"));status.add_theme_color_override("font_shadow_color",Color("183024"));status.add_theme_constant_override("shadow_offset_x",2);status.add_theme_constant_override("shadow_offset_y",2)
	status.mouse_filter=Control.MOUSE_FILTER_IGNORE;game.hud.root.add_child(status)
	reticle=Label.new();reticle.set_anchors_and_offsets_preset(Control.PRESET_CENTER);reticle.position=Vector2(-24,-24);reticle.size=Vector2(48,48);reticle.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;reticle.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;reticle.add_theme_font_size_override("font_size",30);reticle.mouse_filter=Control.MOUSE_FILTER_IGNORE;ui.add_child(reticle)

func active() -> bool:
	if game==null or game.network.active or not game.session_started or game.build_mode or not game.hud.modal_kind.is_empty():return false
	# Horse is optional so the armory also works before the mount feature lands.
	var mount:Variant=game.get("horse")
	return mount==null or not mount.mounted

func near_shop() -> bool:
	var p:Vector3=game.player.position;var door:=SHOP_AT+Vector3(2.8,0,0)
	return Vector2(p.x-door.x,p.z-door.z).length()<3.2 and absf(p.y-npc.position.y)<3

func shop_has_priority() -> bool:
	if not active() or not near_shop():return false
	var mount:Variant=game.get("horse")
	if mount!=null and mount.can_mount(game.player):
		var counter:=SHOP_AT+Vector3(1,0,0)
		if game.player.position.distance_to(mount.position)<game.player.position.distance_to(counter):return false
	return true

func holster() -> void:
	if armed and game!=null:game.pitch=walk_pitch
	armed=false;aiming=false;reload_left=0;recoil=0
	if pistol:pistol.visible=false

func handle_input(event:InputEvent) -> bool:
	if not active():return false
	if event is InputEventMouseMotion and armed and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		var sensitivity:=float(game.preferences.data.sensitivity)
		game.yaw-=event.relative.x*.004*sensitivity
		game.pitch=clampf(game.pitch+event.relative.y*.003*sensitivity,-.35,.80)
		return true
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_P:
				if armed:holster()
				elif game.state.armory.pistol:
					game.actor.stop_emote();walk_pitch=game.pitch;game.pitch=.12;armed=true
				else:game.hud.toast("Damião vende a P-8 na margem oeste da estrada, perto do armazém.")
				return true
			KEY_E:
				if shop_has_priority():
					holster();show_shop();return true
				holster()
			KEY_R:
				if armed:start_reload();return true
			KEY_TAB,KEY_B:holster()
	if event is InputEventMouseButton and armed:
		if event.button_index==MOUSE_BUTTON_LEFT:
			if event.pressed:shoot()
			return true
	return false

func start_reload() -> bool:
	if not active() or not armed or reload_left>0:return false
	if not FarmArmory.can_reload(game.state.armory):
		game.hud.toast("Carregador cheio." if game.state.armory.magazine==FarmArmory.CAPACITY else "Sem munição na reserva. Fale com Damião.");return false
	reload_left=RELOAD_TIME;return true

func _physics_process(delta:float) -> void:
	if game==null:return
	elapsed+=delta
	if last_state!=game.state:
		holster();last_state=game.state;cooldown=0
	if not active():
		holster()
	else:
		cooldown=maxf(0,cooldown-delta);recoil=maxf(0,recoil-delta);hit_time=maxf(0,hit_time-delta)
		if reload_left>0:
			reload_left=maxf(0,reload_left-delta)
			if reload_left==0:FarmArmory.reload_magazine(game.state.armory)
		if armed and (game.actor.action_time>0 or game.actor.airborne or game.actor.emote_time>0):holster()
		if armed:_pose_player(delta)
	npc_actor.animate(delta,false,false)
	if near_shop():npc_actor.pose_bone("Head",Vector3(0,sin(elapsed*.7)*.08,0),.1)
	for i in range(flashes.size()-1,-1,-1):
		flashes[i].time-=delta
		if flashes[i].time<=0:flashes[i].node.queue_free();flashes.remove_at(i)
	status.visible=active() and game.state.armory.pistol
	status.text=("P-8  ·  %d / %d\n"%[game.state.armory.magazine,game.state.armory.reserve])+(("RECARREGANDO…" if reload_left>0 else "Clique: disparar · R: recarregar\nSegure direito: mirar · P: guardar") if armed else "P: sacar pistola")
	reticle.visible=active() and armed and reload_left<=0;reticle.text="×" if hit_time>0 else "+";reticle.modulate=Color("f4bf64") if hit_time>0 else Color("fff4da")
	muzzle.visible=armed and recoil>SHOT_INTERVAL-.055

func aim_point() -> Vector3:
	var viewport:=get_viewport().get_visible_rect().size*.5
	var origin:Vector3=game.camera.project_ray_origin(viewport)
	var end:Vector3=origin+game.camera.project_ray_normal(viewport)*70
	var ray:=PhysicsRayQueryParameters3D.create(origin,end,1,[game.player.get_rid()])
	var hit:=get_world_3d().direct_space_state.intersect_ray(ray)
	return hit.position if not hit.is_empty() else end

func _pose_player(delta:float) -> void:
	var actor:FarmAvatar=game.actor
	aiming=Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	var target:=aim_point();var direction:Vector3=target-game.player.position
	game.avatar.rotation.y=lerp_angle(game.avatar.rotation.y,atan2(direction.x,direction.z),1-exp(-delta*22))
	var pitch:=clampf(atan2(target.y-(game.player.position.y+1.55),Vector2(direction.x,direction.z).length()),-.8,.7)
	var kick:=recoil/SHOT_INTERVAL
	var lowering:=.60 if reload_left>0 else 0.0
	actor.pose_bone("UpperArm.R",Vector3(-1.17-pitch*.65-kick*.15+lowering,0,-.08),1)
	actor.pose_bone("Forearm.R",Vector3(-.25,0,0),1)
	actor.pose_bone("Hand.R",Vector3(-.10,0,0),1)
	actor.pose_bone("UpperArm.L",Vector3(-1.00-pitch*.5+lowering,.2,.34),1)
	actor.pose_bone("Forearm.L",Vector3(-.72-(sin(reload_left/RELOAD_TIME*PI)*.5 if reload_left>0 else 0.0),-.28,0),1)
	actor.can.visible=false;actor.carried_egg.visible=false
	var hand:Transform3D=actor.skeleton.get_bone_global_pose(actor.bones["Hand.R"])
	var grip:Vector3=hand*actor.hand_grip
	var basis:Basis=(Basis(Vector3.RIGHT,-pitch-kick*.12+lowering)*Basis(Vector3.FORWARD,.45 if reload_left>0 else 0.0)).scaled(Vector3.ONE*1.1)
	pistol.transform=hand.affine_inverse()*Transform3D(basis,grip)
	pistol.visible=true

func shoot() -> bool:
	if not active() or not armed or reload_left>0 or cooldown>0 or game.actor.action_time>0 or game.actor.airborne:return false
	if not FarmArmory.fire(game.state.armory):game.hud.toast("Carregador vazio. R para recarregar.");return false
	cooldown=SHOT_INTERVAL;recoil=SHOT_INTERVAL
	_pose_player(1.0)
	var origin:Vector3=pistol.global_transform*Vector3(0,.184,.235)
	var end:=aim_point()
	# Cast from the muzzle as well: camera visibility never shoots through cover.
	var ray:=PhysicsRayQueryParameters3D.create(origin,end,1,[game.player.get_rid()])
	ray.hit_from_inside=true
	var hit:=get_world_3d().direct_space_state.intersect_ray(ray)
	if not hit.is_empty():
		end=hit.position
		if hit.collider.has_meta("practice_target"):
			FarmArmory.register_hit(game.state.armory);hit_time=.2
			var target:Node3D=hit.collider.get_meta("practice_target")
			var tween:=create_tween();tween.tween_property(target,"rotation:x",-.14,.06);tween.tween_property(target,"rotation:x",0.0,.24)
	_tracer(origin,end);_shot_sound()
	return true

func _tracer(from:Vector3,to:Vector3) -> void:
	var line:=MeshInstance3D.new();var mesh:=ImmediateMesh.new()
	var mat:=StandardMaterial3D.new();mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mat.albedo_color=Color("fbd88e")
	mesh.surface_begin(Mesh.PRIMITIVE_LINES,mat);mesh.surface_add_vertex(from);mesh.surface_add_vertex(to);mesh.surface_end();line.mesh=mesh;add_child(line)
	flashes.append({"node":line,"time":.07})
	var spark:=MeshInstance3D.new();var sphere:=SphereMesh.new();sphere.radius=.045;sphere.height=.09;spark.mesh=sphere;spark.material_override=mat;add_child(spark);spark.global_position=to;flashes.append({"node":spark,"time":.12})

func _shot_sound() -> void:
	var wav:=AudioStreamWAV.new();wav.format=AudioStreamWAV.FORMAT_16_BITS;wav.mix_rate=22050
	var bytes:=PackedByteArray();bytes.resize(3308*2)
	var rng:=RandomNumberGenerator.new();rng.seed=game.state.armory.shots+37
	for i in range(3308):
		var t:=float(i)/22050;var sample:float=(rng.randf_range(-1,1)*exp(-t*70)*.65+sin(t*TAU*90)*exp(-t*40)*.35)*.65
		bytes.encode_s16(i*2,int(clampf(sample,-1,1)*32767))
	wav.data=bytes;sound.stream=wav;sound.play()

func show_shop() -> void:
	if not game.session_started or game.build_mode or not near_shop():return
	var hud:FarmHUD=game.hud;var bag:Dictionary=game.state.armory
	var p:=FarmGameUI.open(hud,"armory","Damião · Armeiro do vale","pistol",820,620)
	hud.label(p,"“Ferramenta boa exige mão firme.”",Vector2(30,111),Vector2(760,32),23)
	hud.label(p,"Pistola P-8 · peça única do catálogo   |   Saldo: %s"%hud.money_text(game.state),Vector2(30,151),Vector2(760,30),18)
	var gun_card:=FarmGameUI.card(hud,p,Rect2(30,202,760,143))
	FarmGameUI.icon(gun_card,"pistol",Rect2(16,23,90,90))
	hud.label(gun_card,"P-8 do Vale",Vector2(126,16),Vector2(340,36),27)
	hud.label(gun_card,"8 no carregador + 24 de reserva\nSemiautomática · disparo único.",Vector2(126,62),Vector2(350,63),17)
	var buy:=FarmGameUI.action(hud,gun_card,"Comprada" if bag.pistol else "Comprar · $%d"%FarmArmory.PRICE,Rect2(495,47,239,50),"armory:buy",true);buy.disabled=bag.pistol
	var ammo_card:=FarmGameUI.card(hud,p,Rect2(30,363,760,107))
	hud.label(ammo_card,"Caixa de 24 munições",Vector2(20,14),Vector2(430,32),23)
	hud.label(ammo_card,"Reserva: %d / %d · Acertos: %d"%[bag.reserve,FarmArmory.MAX_RESERVE,bag.hits],Vector2(20,55),Vector2(430,26),17)
	var ammo:=FarmGameUI.action(hud,ammo_card,"Comprar · $%d"%FarmArmory.AMMO_PRICE,Rect2(495,27,239,50),"armory:ammo");ammo.disabled=not bag.pistol or bag.reserve+FarmArmory.AMMO_PACK>FarmArmory.MAX_RESERVE
	hud.label(p,"P: sacar/guardar · Botão direito: mirar · Clique: disparar · R: recarregar\nExperimente nos três alvos ao lado da banca.",Vector2(30,490),Vector2(760,62),17)
	FarmGameUI.action(hud,p,"Voltar ao vale",Rect2(240,565,340,40),"close")

func _shop_action(value:String) -> void:
	if game.network.active:return
	if not value.begins_with("armory:"):return
	if game.hud.modal_kind!="armory" or not near_shop() or not game.session_started:return
	var error:String
	if value=="armory:buy":error=FarmArmory.buy_pistol(game.state,game.state.armory)
	elif value=="armory:ammo":error=FarmArmory.buy_ammo(game.state,game.state.armory)
	else:return
	if error.is_empty():
		game._save_game(false);game.hud.toast("Fechado. P para sacar a P-8." if value=="armory:buy" else "Munição guardada na reserva.")
	else:game.hud.toast(error)
	show_shop()
