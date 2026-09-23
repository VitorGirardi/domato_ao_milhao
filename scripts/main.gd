extends Node3D

const SAVE_PATH := "user://farm_v1.json"
var save_path := SAVE_PATH
var state := FarmState.new()
var world: FarmWorld
var hud: FarmHUD
var player := CharacterBody3D.new()
var avatar: Node3D
var actor:=FarmAvatar.new()
var feedback:=FarmFeedback.new()
var camera := Camera3D.new()
var build_mode := true
var focus := Vector3(4,0,-2)
var yaw := 0.48
var pitch := 0.78
var build_distance := 49.0
var walk_distance := 9.0
var selected := -1
var tool := "inspect"
var crop := "carrot"
var turn := 0
var ghost := Node3D.new()
var ghost_mat := StandardMaterial3D.new()
var ghost_key := ""
var pointer := Vector2.ZERO
var pointer_valid := false
var hover_hint := ""
var field_alerts:=FarmFieldAlerts.new()
var session_started := false
var quitting:=false
var focus_check_pending:=false
var save_timer := 0.0
var ui_timer := 0.0
var silly_timer := 0.0
var next_silly := 75.0
var audio:=FarmAudio.new()
var qa_mode := false
var move_index: int = -1
var action_cooldown := 0.0
var journey_seen := -1
var dragging := false
var drag_start := Vector2.ZERO
var route: Array = []
var route_ghost:=Node3D.new()
var route_key:=""
var selected_hen := -1
var picked_hen := -1
var nearby_hen := -1
var silly_kind := "inspect"
var silly_event_index := 0
var picked_trade_board:=false
var trail_journey:=FarmTrails.new()
var weapons:=FarmWeapons.new()
var horse:=FarmHorse.new()
var navigator:=FarmNavigation.new()
var preferences:=FarmSettings.new()
var front_end:=FarmFrontEnd.new()
var network:=FarmNetwork.new()
var companions:=FarmCompanions.new()
var windowed_rect:=Rect2i()
var windowed_mode:=Window.MODE_WINDOWED

func _ready() -> void:
	qa_mode = OS.is_debug_build() and "--qa" in OS.get_cmdline_user_args()
	if qa_mode: save_path="user://qa_farm_v025.json"
	get_tree().auto_accept_quit = false
	_inputs()
	world = FarmWorld.new()
	add_child(world)
	var loaded := false if qa_mode else _load_game()
	state.unlimited_money=not qa_mode
	next_silly=state.elapsed+75
	world.rebuild(state)
	add_child(feedback)
	feedback.setup(world)
	_player()
	add_child(horse);horse.restore(state.horse)
	add_child(camera)
	camera.current = true
	camera.fov = 49
	camera.far = 600
	if state.claimed:
		focus = Vector3(state.center.x,0,state.center.y)
		player.position = focus + Vector3(0,0.2,8)
		_ensure_player_space()
	add_child(ghost)
	add_child(route_ghost)
	ghost_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ghost_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ghost_mat.albedo_color = Color(0.65,0.85,0.35,0.35)
	ghost_mat.no_depth_test = false
	ghost_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	hud = FarmHUD.new()
	add_child(hud)
	hud.action.connect(_action)
	navigator.setup(self)
	add_child(weapons)
	weapons.setup(self)
	add_child(audio);audio.setup(self);weapons.sound.bus=FarmAudio.EFFECTS_BUS
	front_end.setup(self,loaded)
	add_child(network);network.setup(self)
	add_child(companions);companions.setup(self)
	preferences.load_preferences();preferences.apply(self)
	front_end.show_title()
	_update_camera(1.0, true)
	_update_ui()
	if qa_mode:
		call_deferred("_qa")

func _inputs() -> void:
	for entry in [["forward",KEY_W],["back",KEY_S],["left",KEY_A],["right",KEY_D],["run",KEY_SHIFT]]:
		if not InputMap.has_action(entry[0]):
			InputMap.add_action(entry[0])
			var event := InputEventKey.new()
			event.physical_keycode = entry[1]
			InputMap.action_add_event(entry[0],event)

func _player() -> void:
	add_child(player)
	player.position = Vector3(4,0.2,10)
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.37
	capsule.height = 2.58
	collision.shape = capsule
	collision.position.y = 1.29
	player.add_child(collision)
	avatar = world.model("farmer",player)
	actor.setup(avatar,world)

func _mounted() -> bool:
	return horse.mounted and (not network.active or network.mounts.local_rider())

func _try_jump() -> bool:
	actor.stop_emote()
	if _mounted() or not session_started or build_mode or not hud.modal_kind.is_empty() or not player.is_on_floor() or actor.action_time>0: return false
	player.velocity.y=6.8
	actor.airborne=true
	actor.landing=0.0
	return true

func _physics_process(delta: float) -> void:
	if not is_instance_valid(hud):
		return
	var movement := Vector2.ZERO
	if hud.modal_kind.is_empty() and session_started:
		movement = Input.get_vector("left","right","forward","back")
	if movement.length()>0 or build_mode or not hud.modal_kind.is_empty(): actor.stop_emote()
	var right := Vector3(cos(yaw),0,-sin(yaw))
	var back := Vector3(sin(yaw),0,cos(yaw))
	var direction := right * movement.x + back * movement.y
	if _mounted():
		if network.active and not network.hosting:
			_update_camera(delta);return
		horse.drive(player,avatar,actor,direction,delta,session_started and hud.modal_kind.is_empty())
		horse.store(state);_update_camera(delta);return
	if not network.active and horse.is_inside_tree():horse.life.update(horse,delta,session_started and hud.modal_kind.is_empty() and not build_mode,state,world.landscape,player)
	if actor.action_time>0 and not build_mode: direction=Vector3.ZERO
	if build_mode:
		focus += direction * delta * build_distance * 0.45
		focus.x = clampf(focus.x,-32,178)
		focus.z = clampf(focus.z,-143,143)
		player.velocity.x = 0
		player.velocity.z = 0
	else:
		var speed := 7.5 if Input.is_action_pressed("run") else 4.5
		player.velocity.x = direction.x * speed
		player.velocity.z = direction.z * speed
		if direction.length() > 0.1:
			avatar.rotation.y = lerp_angle(avatar.rotation.y,atan2(direction.x,direction.z),delta*12)
	var was_airborne:=actor.airborne
	player.velocity.y -= 18*delta
	player.move_and_slide()
	actor.airborne=not player.is_on_floor() and not build_mode
	if was_airborne and player.is_on_floor(): actor.landing=0.22
	actor.animate(delta,not build_mode and Vector2(player.velocity.x,player.velocity.z).length()>0.2,Input.is_action_pressed("run"))
	player.position.x = clampf(player.position.x,FarmLandscape.WALK_MIN.x,FarmLandscape.WALK_MAX.x)
	player.position.z = clampf(player.position.z,FarmLandscape.WALK_MIN.y,FarmLandscape.WALK_MAX.y)
	if player.position.y < -3:
		player.position.y = 1
	_update_camera(delta)

func _process(delta: float) -> void:
	if not is_instance_valid(hud):
		return
	# Some Windows transitions retain the focus flag while minimizing.
	if session_started and not qa_mode and DisplayServer.get_name()!="headless" and hud.modal_kind.is_empty() and not focus_check_pending:
		if get_window().mode==Window.MODE_MINIMIZED or not get_window().has_focus():_check_focus_pause()
	action_cooldown=maxf(0,action_cooldown-delta)
	if session_started and not network.active and not build_mode and hud.modal_kind.is_empty():
		var discovery:=trail_journey.discover(Vector2(player.position.x,player.position.z))
		if not discovery.is_empty():hud.toast(discovery)
		state.tick(delta)
		if not state.trade_notices.is_empty():
			hud.toast("Prazo de %s encerrado. Sem multa. Veja novos pedidos em J."%state.trade_notices[0] if state.trade_notices.size()==1 else "%d prazos encerrados. Sem multa; consulte o quadro com J."%state.trade_notices.size())
			state.trade_notices.clear()
		world.update_staff(state,delta)
		var alert:=field_alerts.poll(state)
		if not alert.is_empty(): hud.toast(alert)
		elif not state.staff_notice.is_empty(): hud.toast(state.staff_notice)
		state.staff_notice=""
		world.update_crops(state)
		silly_timer = maxf(0,silly_timer-delta)
		if state.elapsed > next_silly and not world.chickens.is_empty():
			_start_silly()
		world.animate(delta,player.position,state,silly_kind if silly_timer>0 else "")
	if session_started:
		save_timer += delta
		if save_timer >= 30:
			save_timer=0
			_save_game(false)
	_update_pointer()
	world.update_animals(state)
	world.day_night.update_cycle(state.elapsed,player.position)
	ui_timer += delta
	if ui_timer >= 0.15:
		ui_timer = 0
		_update_ui()

func _start_silly() -> void:
	if world.chickens.is_empty(): return
	next_silly=state.elapsed+110
	silly_timer=14
	silly_kind=["inspect","dance","meeting"][silly_event_index%3]
	silly_event_index+=1
	var first:Dictionary=world.chickens[0]
	var name:String=state.items[first.coop].flock.names[0]
	var messages={"inspect":"%s assumiu a gerência. Fiscalização a caminho!", "dance":"%s inventou a dança do ovo. O talento é discutível.", "meeting":"%s convocou uma reunião. Pauta única: mais milho."}
	hud.toast(messages[silly_kind]%name)

func _update_camera(delta: float, immediate: bool = false) -> void:
	var target := focus if build_mode else player.position + Vector3(0,2.0 if _mounted() else 1.1,0)
	var distance := build_distance if build_mode else (walk_distance+3.0 if _mounted() else walk_distance)
	var angle := pitch if build_mode else clampf(pitch,0.2,1.0)
	if weapons.armed and not build_mode:
		target-=Vector3(cos(yaw),0,-sin(yaw))*.85
		target+=Vector3.UP*.55
		distance=5.2 if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) else 6.5
		angle=clampf(pitch,-.35,.80)
	var desired := target + Vector3(sin(yaw)*cos(angle),sin(angle),cos(yaw)*cos(angle))*distance
	if not build_mode and is_inside_tree():
		desired=_camera_clear_position(target,desired)
	var next_position:=desired if immediate else camera.position.lerp(desired,1-exp(-delta*10))
	# Smoothing must not leave the camera behind a newly encountered wall.
	# Contract immediately; the unobstructed return still eases out normally.
	if not build_mode and is_inside_tree():next_position=_camera_clear_position(target,next_position)
	camera.position=next_position
	if camera.position.distance_to(target)>0.01:
		camera.look_at(target)
	avatar.visible = build_mode or camera.position.distance_to(target)>1.7

func _camera_clear_position(target:Vector3,candidate:Vector3) -> Vector3:
	if target.distance_squared_to(candidate)<.000001:return candidate
	var query:=PhysicsRayQueryParameters3D.create(target,candidate,1,[player.get_rid(),horse.obstacle.get_rid()])
	query.hit_from_inside=true
	var hit:=get_world_3d().direct_space_state.intersect_ray(query)
	return candidate if hit.is_empty() else hit.position+hit.normal*.35

func _ensure_player_space() -> void:
	var start := Vector2(player.position.x,player.position.z)
	for radius in range(0,16):
		for step in range(16):
			var angle := float(step)/16*TAU
			var candidate := start+Vector2(sin(angle),cos(angle))*radius
			if candidate.x<FarmLandscape.WALK_MIN.x or candidate.x>FarmLandscape.WALK_MAX.x or candidate.y<FarmLandscape.WALK_MIN.y or candidate.y>FarmLandscape.WALK_MAX.y:
				continue
			var valid := world.landscape.clear_for_player(candidate)
			for item in state.items:
				if item.kind in ["plot","path"]: continue
				if state.item_rect(item.kind,Vector2(item.x,item.z),item.turn).grow(0.5).has_point(candidate):
					valid=false
					break
			if valid:
				player.position=Vector3(candidate.x,FarmLandscape.height_at(candidate)+.2,candidate.y)
				return

func _toggle_fullscreen(persist:bool=true) -> void:
	var window:=get_window()
	if window.mode in [Window.MODE_FULLSCREEN,Window.MODE_EXCLUSIVE_FULLSCREEN]:
		var usable:=DisplayServer.screen_get_usable_rect(window.current_screen)
		var target_size:=windowed_rect.size if windowed_rect.has_area() else Vector2i(1280,800)
		target_size=target_size.min(Vector2i(Vector2(usable.size)*.9))
		var target_position:=windowed_rect.position if windowed_rect.has_area() else usable.position+(usable.size-target_size)/2
		target_position=target_position.clamp(usable.position,usable.end-target_size)
		window.mode=windowed_mode
		if windowed_mode==Window.MODE_WINDOWED:
			window.size=target_size
			window.position=target_position
	else:
		windowed_rect=Rect2i(window.position,window.size)
		windowed_mode=window.mode
		window.mode=Window.MODE_EXCLUSIVE_FULLSCREEN

	if persist:
		preferences.data.fullscreen=window.mode in [Window.MODE_FULLSCREEN,Window.MODE_EXCLUSIVE_FULLSCREEN]
		preferences.save_preferences()
		if is_instance_valid(hud) and hud.modal_kind=="settings" and front_end.controls.has("fullscreen"):
			front_end.controls.fullscreen.button_pressed=preferences.data.fullscreen

func _input(event: InputEvent) -> void:
	# Works even while a menu or text field owns keyboard focus.
	if event is InputEventKey and event.pressed and (event.physical_keycode==KEY_F11 or event.keycode==KEY_F11):
		if not event.echo:_toggle_fullscreen()
		get_viewport().set_input_as_handled()
		return
	# Release must be caught even over a HUD panel, where unhandled input is consumed.
	if dragging and event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and not event.pressed:
		_update_pointer()
		if get_viewport().gui_get_hovered_control()!=null or not pointer_valid:
			_cancel_route()
			hud.toast("Traçado cancelado. Solte sobre o terreno para revisar.")
		else: _finish_route()
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if network.active:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode==KEY_ESCAPE:
				if not network.ready_session:network.leave("Conexão cancelada.")
				elif hud.modal_kind.is_empty() and build_mode and (tool!="inspect" or move_index>=0 or dragging or not route.is_empty()):_action("build:clear")
				elif hud.modal_kind.is_empty():network.session_menu()
				else:hud.close_modal()
				get_viewport().set_input_as_handled();return
			if event.physical_keycode==KEY_I:network.show_stock();return
	if weapons.game!=null and weapons.handle_input(event):
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if front_end.escape():get_viewport().set_input_as_handled();return
			if dragging or not route.is_empty():
				_cancel_route()
				if hud.modal_kind=="route": hud.close_modal()
				get_viewport().set_input_as_handled()
				return
			if not hud.modal_kind.is_empty():
				if hud.modal_kind != "welcome": hud.close_modal()
			elif tool != "inspect" or move_index>=0:
				_action("build:clear")
			else:
				hud.menu(state)
			get_viewport().set_input_as_handled()
			return
		if event.physical_keycode==KEY_M and hud.modal_kind=="valley_map":
			hud.close_modal();get_viewport().set_input_as_handled();return
		if not hud.modal_kind.is_empty():
			return
		match event.physical_keycode:
			KEY_SHIFT:
				if network.active:
					if _mounted():network.mounts.request("sprint")
				elif _mounted() and horse.encourage():hud.toast("Bora, Pé de Pano!")
			KEY_SPACE: _try_jump()
			KEY_TAB: _action("mode")
			KEY_E: _interact_nearest()
			KEY_C: companions.request("whistle")
			KEY_V: companions.request("follow")
			KEY_F: _action("market")
			KEY_J: _action("market_orders")
			KEY_H: _action("staff")
			KEY_T: _action("parcels")
			KEY_B: _action("emotes")
			KEY_F5: _action("save")
			KEY_M: _action("move" if build_mode else "map")
			KEY_R: turn=posmod(turn+1,4)
			KEY_Q: turn=posmod(turn-1,4)
			KEY_1: _action("tool:inspect")
			KEY_2: _action("tool:plot")
			KEY_3: _action("tool:barn")
			KEY_4: _action("tool:coop")
			KEY_5: _action("tool:fence")
			KEY_6: _action("tool:sign")
			KEY_7: _action("tool:path")
			KEY_8: _action("tool:expand")
			KEY_9: _action("tool:workshop")
			KEY_0: _action("tool:corral")
			KEY_G: _action("tool:cheesery")
			KEY_K: _action("tool:stable")
	if not hud.modal_kind.is_empty():
		return
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		yaw -= event.relative.x*0.005*float(preferences.data.sensitivity)
		pitch=clampf(pitch+event.relative.y*0.003*float(preferences.data.sensitivity),0.2,1.3)
	if event is InputEventMouseButton and event.pressed:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP:
			if build_mode: build_distance=clampf(build_distance-3,20,78)
			else: walk_distance=clampf(walk_distance-0.7,3,14)
		if event.button_index==MOUSE_BUTTON_WHEEL_DOWN:
			if build_mode: build_distance=clampf(build_distance+3,20,78)
			else: walk_distance=clampf(walk_distance+0.7,3,14)
		if event.button_index==MOUSE_BUTTON_LEFT:
			_update_pointer()
			if build_mode and tool in ["fence","path"] and move_index<0 and state.claimed:
				_begin_route()
			else: _click_world()

func _begin_route() -> void:
	if not pointer_valid: return
	dragging=true
	drag_start=pointer
	_update_route()

func _update_route() -> void:
	route=state.line_plan(tool,drag_start,pointer,turn)
	var key:=str(route)
	if key!=route_key:
		route_key=key
		for child in route_ghost.get_children(): child.free()
		for piece in route:
			var size:Vector2=FarmState.ITEMS[piece.kind].size
			var box:=world.box(route_ghost,Vector3(piece.x,0.2,piece.z),Vector3(size.x,0.22,size.y),ghost_mat)
			box.rotation.y=piece.turn*PI/2
	var error:=state.batch_error(route)
	ghost_mat.albedo_color=Color(0.7,0.95,0.45,0.55) if error.is_empty() else Color(0.95,0.22,0.12,0.55)
	route_ghost.visible=true
	ghost.visible=false
	hover_hint="%d peças • $%d • Solte para revisar • Esc cancela"%[route.size(),state.batch_cost(route)] if error.is_empty() else error

func _finish_route() -> void:
	if not dragging: return
	_update_route()
	dragging=false
	hud.confirm_route(state,route)

func _cancel_route() -> void:
	dragging=false
	route.clear()
	route_key=""
	route_ghost.visible=false
	for child in route_ghost.get_children(): child.queue_free()

func _update_pointer() -> void:
	ghost.visible = false
	for land in state.owned_areas():
		if land.has_point(pointer):
			world.build_grid.position=Vector3(land.get_center().x,.045,land.get_center().y)
			world.build_grid.scale=Vector3(land.size.x,1,land.size.y)
	world.build_grid.visible=session_started and state.claimed and build_mode and hud.modal_kind.is_empty() and (FarmState.ITEMS.has(tool) or move_index>=0)
	world.show_selection(state,selected if build_mode else _nearest())
	if not hud.modal_kind.is_empty(): world.selection.visible=false
	hover_hint = ""
	pointer_valid = false
	if not session_started or not hud.modal_kind.is_empty():
		return
	var mouse := get_viewport().get_mouse_position()
	var ray := camera.project_ray_origin(mouse)
	var direction := camera.project_ray_normal(mouse)
	if direction.y>=-0.01:
		return
	var at: Vector3 = ray + direction * (-ray.y / direction.y)
	pointer = Vector2(at.x,at.z).snapped(Vector2(2,2))
	pointer_valid = true
	if dragging:
		_update_route()
		return
	if get_viewport().gui_get_hovered_control()!=null:
		return
	if state.claimed and build_mode and tool=="inspect":
		var hovered:=_pick_item(mouse,Vector2(at.x,at.z))
		world.show_selection(state,hovered if hovered>=0 else selected)
		if picked_trade_board: hover_hint="Quadro dos vizinhos • Clique para ver encomendas • J"
	if not state.claimed:
		_preview("land")
		ghost.position = Vector3(pointer.x,0.06,pointer.y)
		ghost.rotation.y=0
		var valid:bool=pointer.x>=-12 and pointer.x<=22 and pointer.y>=-18 and pointer.y<=20
		ghost_mat.albedo_color=Color(0.84,0.92,0.43,0.32) if valid else Color(0.9,0.2,0.12,0.38)
		ghost.visible=true
		hover_hint="24 × 24 metros • $400 • Clique para começar" if valid else "Procure uma área plana no centro do vale"
	elif build_mode and (FarmState.ITEMS.has(tool) or move_index>=0):
		var kind:String=state.items[move_index].kind if move_index>=0 else tool
		_preview(kind)
		ghost.position=Vector3(pointer.x,0.08,pointer.y)
		ghost.rotation.y=turn*PI/2
		var error:=state.can_move(move_index,pointer,turn) if move_index>=0 else state.can_place(kind,pointer,turn)
		ghost_mat.albedo_color=Color(0.7,0.95,0.45,0.48) if error.is_empty() else Color(0.95,0.22,0.12,0.5)
		ghost.visible=true
		if error.is_empty():
			hover_hint="Mover %s • Grátis • Clique confirma • Esc cancela"%FarmState.ITEMS[kind].name if move_index>=0 else "%s • $%d • Clique para colocar • R gira"%[FarmState.ITEMS[kind].name,FarmState.ITEMS[kind].cost]
		else: hover_hint=error
		if tool in ["fence","path"] and move_index<0 and error.is_empty():
			hover_hint="Segure e arraste em linha • Solte para conferir o custo"
	elif not build_mode:
		var context:=_nearby_context()
		hover_hint=str(context.get("text",""))

func _preview(kind: String) -> void:
	if ghost_key==kind:
		return
	ghost_key=kind
	for child in ghost.get_children(): child.free()
	if kind=="land":
		world.box(ghost,Vector3.ZERO,Vector3(24,0.05,24),ghost_mat)
	elif kind in ["plot","path"]:
		world.box(ghost,Vector3.ZERO,Vector3(2,0.1,2),ghost_mat)
	else:
		var visual:=world.model(kind,ghost)
		_ghost_material(visual)

func _ghost_material(node: Node) -> void:
	if node is MeshInstance3D:
		node.material_override=ghost_mat
		node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in node.get_children(): _ghost_material(child)

func _click_world() -> void:
	if network.active and network.click_world():return
	if not pointer_valid:
		return
	if move_index>=0:
		var error:=state.move_item(move_index,pointer,turn)
		if not error.is_empty():
			hud.toast(error)
			return
		selected=move_index
		move_index=-1
		tool="inspect"
		world.rebuild(state)
		_ensure_player_space()
		hud.toast("Novo lugar, mesma história. Tudo preservado!")
		_update_ui()
		return
	if not state.claimed:
		var error:=state.claim(pointer)
		if not error.is_empty():
			hud.toast(error)
			return
		focus=Vector3(state.center.x,0,state.center.y)
		player.position=focus+Vector3(0,0.1,8)
		world.update_border(state)
		tool="plot"
		hud.toast("É seu! Agora vamos plantar o primeiro sonho.")
		_chime()
		_save_game(false)
		return
	if build_mode and FarmState.ITEMS.has(tool):
		var error:=state.place(tool,pointer,turn,crop)
		if error.is_empty():
			selected=state.items.size()-1
			world.rebuild(state)
			_ensure_player_space()
			_chime()
			if tool=="sign":
				hud.editor_dialog("sign",state.items[selected].text)
			elif tool=="plot":
				feedback.planted(Vector3(pointer.x,0,pointer.y))
				hud.toast("Sementes no chão. Use Cuidar para regar!")
			else: hud.toast("%s construído!"%FarmState.ITEMS[tool].name)
		else:
			hud.toast(error)
	else:
		var mouse:=get_viewport().get_mouse_position()
		var ray:=camera.project_ray_origin(mouse)
		var direction:=camera.project_ray_normal(mouse)
		var at:Vector3=ray+direction*(-ray.y/direction.y)
		selected=_pick_item(mouse,Vector2(at.x,at.z))
		selected_hen=picked_hen
		if picked_trade_board:
			if build_mode or player.position.distance_to(FarmWorld.TRADE_BOARD_AT)<3:
				hud.market(state,"orders")
			else: hud.toast("Chegue mais perto do quadro ou use J para consultar.")
			return
		if selected>=0:
			var distance:=_distance_to_item(selected)
			if selected_hen>=0:
				for hen in world.chickens:
					if hen.coop==selected and hen.hen==selected_hen: distance=minf(distance,player.position.distance_to(hen.node.position))
			if not build_mode and distance>3:
				hud.toast("Chegue mais perto ou use a câmera de construção.")
			elif not build_mode:
				_tend_selected()
	_update_ui()

func _pick_item(mouse: Vector2, ground: Vector2) -> int:
	picked_hen=-1
	picked_trade_board=false
	var origin:=camera.project_ray_origin(mouse)
	var end:=origin+camera.project_ray_normal(mouse)*200
	var hit:=get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(origin,end,3,[player.get_rid()]))
	if not hit.is_empty() and hit.collider.has_meta("trade_board"):
		picked_trade_board=true
		return -1
	if not hit.is_empty() and hit.collider.has_meta("item_index"):
		picked_hen=int(hit.collider.get_meta("hen_index",-1))
		return int(hit.collider.get_meta("item_index"))
	return _find_item(ground)

func _find_item(at: Vector2) -> int:
	for i in range(state.items.size()-1,-1,-1):
		var item:Dictionary=state.items[i]
		if state.item_rect(item.kind,Vector2(item.x,item.z),item.turn).grow(0.15).has_point(at):
			return i
	return -1

func _distance_to_item(i: int) -> float:
	var item:Dictionary=state.items[i]
	if item.kind in ["barn","workshop","corral","cheesery","stable","pigsty"]:
		var door:=Vector3(item.x,0,item.z)+Vector3(0,0,3.0 if item.kind in ["barn","corral","cheesery","stable","pigsty"] else 1.9).rotated(Vector3.UP,item.turn*PI/2)
		return Vector2(player.position.x-door.x,player.position.z-door.z).length()
	var area:=state.item_rect(item.kind,Vector2(item.x,item.z),item.turn)
	var position_2d:=Vector2(player.position.x,player.position.z)
	var closest:=position_2d.clamp(area.position,area.end)
	return position_2d.distance_to(closest)

func _nearest() -> int:
	nearby_hen=-1
	var best:=-1
	var distance:=2.6
	if selected>=0 and selected<state.items.size() and state.items[selected].kind in ["plot","sign","barn","coop","workshop","corral","cheesery","stable","pigsty"]:
		var current_distance:=_distance_to_item(selected)
		if current_distance<distance:
			best=selected
			distance=current_distance
	for i in range(state.items.size()):
		if state.items[i].kind not in ["plot","sign","barn","coop","workshop","corral","cheesery","stable","pigsty"]: continue
		var d:=_distance_to_item(i)
		if d<distance and (best<0 or d+0.05<distance):
			best=i
			distance=d
	for hen in world.chickens:
		var d:float=player.position.distance_to(hen.node.position)
		if d<distance:
			best=hen.coop
			nearby_hen=hen.hen
			distance=d
	return best

func _nearby_context() -> Dictionary:
	if build_mode or not state.claimed: return {}
	if _mounted():return {"text":"Desmontar · Pé de Pano","action":"horse"}
	if not network.active and weapons.shop_has_priority():return {"text":"Conversar com Damião","action":"armory"}
	if horse.can_mount(player):
		var nearby:=_nearest()
		if nearby<0 or state.items[nearby].kind!="stable" or player.position.distance_to(horse.position)<=_distance_to_item(nearby):return {"text":"Montar · Pé de Pano","action":"horse"}
	if player.position.distance_to(FarmWorld.TRADE_BOARD_AT)<2.8: return {"text":"Ver encomendas","action":"orders"}
	if player.position.distance_to(Vector3(-24,0,14))<4: return {"text":"Conversar com Lúcia","action":"market"}
	var index:=_nearest()
	if world.cat.can_pet(player.position) and player.position.distance_to(world.cat.position)<1.25 and (index<0 or player.position.distance_to(world.cat.position)<_distance_to_item(index)):
		return {"text":"Fazer carinho no gato","action":"cat"}
	if index<0:return {}
	var item:Dictionary=state.items[index]
	var context:Dictionary={"text":"","action":"item","index":index,"hen":nearby_hen,"ready":true,"seeds":false}
	match item.kind:
		"barn": context.text="Abrir celeiro"
		"coop": context.text="Cuidar das galinhas"
		"cheesery": context.text="Queijo pronto · Recolher" if item.cheese.ready>0 else ("Queijo · faltam %ds"%ceili(item.cheese.remaining) if item.cheese.batch>0 else "Fazer queijo")
		"corral": context.text="Cuidar da vaca"
		"pigsty": context.text="Cuidar dos porcos"
		"workshop": context.text="Abrir oficina"
		"stable": context.text="Ver estrebaria"
		"sign": context.text="Editar placa"
		"plot":
			if not item.planted:
				context.text="Plantar %s · $%d"%[FarmState.CROPS[crop].name,FarmState.CROPS[crop].seed]
				context.seeds=true
			elif item.growth>=1: context.text="Colher "+FarmState.CROPS[item.crop].name
			elif not item.watered: context.text="Regar "+FarmState.CROPS[item.crop].name
			else:
				context.text="%s crescendo · %d%%"%[FarmState.CROPS[item.crop].name,int(item.growth*100)]
				context.ready=false
			if actor.airborne or action_cooldown>0: context.ready=false
	return context

func _interact_nearest() -> void:
	actor.stop_emote()
	if not hud.modal_kind.is_empty(): return
	var context:=_nearby_context()
	if context.is_empty(): return
	match context.action:
		"armory": weapons.holster();weapons.show_shop()
		"horse": _horse_interact()
		"cat":
			weapons.holster()
			companions.request("pet")
		"orders": hud.market(state,"orders")
		"market": hud.market(state)
		"item":
			if not context.ready: return
			selected=int(context.index); selected_hen=int(context.hen)
			_tend_selected()

func _tend_selected() -> void:
	if _mounted():return
	actor.stop_emote()
	if not build_mode and actor.airborne: return
	if selected<0 or selected>=state.items.size(): return
	var item:Dictionary=state.items[selected]
	if item.kind=="plot":
		if network.active:
			network.request_tend(selected,FarmCoop.operation(item),crop);return
		if action_cooldown>0: return
		var old_crop:String=item.crop
		var before:bool=item.planted
		var was_watered:bool=item.watered
		var previous_harvests:=state.harvests
		var water_targets:=state.water_targets(selected)
		var message:=state.tend(selected,crop)
		hud.toast(message)
		if item.crop!=old_crop: world.replace_crop(selected,item.crop)
		world.update_crops(state)
		var kind:=""
		var at:=Vector3(item.x,0,item.z)
		if not build_mode and (state.harvests>previous_harvests or item.watered!=was_watered or item.planted!=before):
			var facing:=at-player.position
			if facing.length()>0.01: avatar.rotation.y=atan2(facing.x,facing.z)
		if state.harvests>previous_harvests:
			feedback.harvest(at,old_crop)
			kind="harvest"
		elif not was_watered and item.watered:
			var origin:=avatar.global_transform*Vector3(0.47,1.1,1.0)
			feedback.water(at,origin,build_mode,"Regado!",null if build_mode else actor.can)
			for target in water_targets:
				if target==selected: continue
				var neighbor:Dictionary=state.items[target]
				feedback.water(Vector3(neighbor.x,0,neighbor.z),origin,false,"Regado!",null if build_mode else actor.can)
			kind="water"
		elif not before and item.planted:
			feedback.planted(at)
			kind="plant"
		if not kind.is_empty():
			action_cooldown=0.35 if build_mode else 0.75
			if not build_mode:
				var direction:=at-player.position
				if direction.length()>0.01: avatar.rotation.y=atan2(direction.x,direction.z)
				actor.play(kind)
			_chime(kind)
		_update_ui()
	elif item.kind=="sign":
		hud.editor_dialog("sign",item.text)
	elif item.kind=="barn": hud.barn(state,selected)
	elif item.kind=="workshop": hud.workshop(state,selected)
	elif item.kind=="coop": hud.coop(state,selected,selected_hen)
	elif item.kind=="cheesery": FarmCheeseHUD.show(hud,state,selected)
	elif item.kind=="corral": FarmDairyHUD.show(hud,state,selected)
	elif item.kind=="pigsty": FarmPigHUD.show(hud,state,selected)
	elif item.kind=="stable": FarmStable.show(hud,state,horse,selected)

func _action(value: String) -> void:
	if network.handle(value):return
	if quitting:return
	if value=="close" and front_end.escape():return
	if value.begins_with("front:"):
		front_end.handle(value);return
	if value=="map" or value.begins_with("map:"):
		navigator.handle(value);return
	if _mounted() and (value=="emotes" or value.begins_with("emote:") or value.begins_with("tool:") or value=="move"):
		hud.toast("Desmonte com E para fazer isso.");return
	if value=="parcels":
		actor.stop_emote();FarmParcels.show(hud,state);return
	if value.begins_with("parcel_buy:"):
		var error:=FarmParcels.buy(state,value.get_slice(":",1))
		if error.is_empty():
			world.update_border(state);_save_game(false);hud.toast("Terreno comprado! A clareira está pronta para construir.")
		else:hud.toast(error)
		FarmParcels.show(hud,state);return
	if value=="farm_levels":
		actor.stop_emote();FarmLevelsHUD.show(hud,state);return
	if value=="emotes":
		if not session_started or build_mode or actor.airborne or actor.action_time>0 or not hud.modal_kind.is_empty(): return
		actor.stop_emote(); FarmEmotes.show(hud)
		return
	if value.begins_with("emote:"):
		if hud.modal_kind!="emotes" or build_mode or not session_started: return
		var key:=value.get_slice(":",1)
		hud.close_modal(); actor.emote(key)
		network.send_emote(key)
		return
	actor.stop_emote()
	if value=="raul": FarmDairyWorkerHUD.show(hud,state);return
	if value.begins_with("raul:"):
		var act:=value.get_slice(":",1)
		if act.begins_with("review_"):
			if hud.modal_kind=="raul": FarmDairyWorkerHUD.review(hud,state,act.trim_prefix("review_"))
			return
		var w:=state.dairy_worker
		if act=="confirm" and hud.modal_kind=="raul_confirm":
			var error:=""
			match hud.raul_confirm:
				"hire": error=FarmDairyWorker.hire(state)
				"apply","renew": error=FarmDairyWorker.configure(state,hud.raul_site,hud.raul_budget,hud.raul_confirm=="renew")
				"dismiss": FarmDairyWorker.dismiss(state)
			if not error.is_empty():hud.toast(error)
		elif act=="pause" and hud.modal_kind=="raul" and w.hired:
			if w.paused and w.site>=0:w.paused=false;w.reason=""
			else:w.paused=true;w.reason="manual"
		else:return
		world.raul_motion.reset();world.raul_motion.update(world,state,0)
		FarmDairyWorkerHUD.show(hud,state);_update_ui();return
	if value=="chico": FarmCheeseWorkerHUD.show(hud,state);return
	if value.begins_with("chico:"):
		var act:=value.get_slice(":",1)
		if act.begins_with("review_"):
			if hud.modal_kind=="chico": FarmCheeseWorkerHUD.review(hud,state,act.trim_prefix("review_"))
			return
		var w:=state.cheese_worker
		if act=="confirm" and hud.modal_kind=="chico_confirm":
			var error:=""
			match hud.chico_confirm:
				"hire": error=FarmCheeseWorker.hire(state)
				"apply","renew": error=FarmCheeseWorker.configure(state,hud.chico_site,hud.chico_batch,hud.chico_budget,hud.chico_confirm=="renew")
				"dismiss": FarmCheeseWorker.dismiss(state)
			if not error.is_empty():hud.toast(error)
		elif act=="pause" and hud.modal_kind=="chico" and w.hired:
			if w.paused and w.site>=0:w.paused=false;w.reason=""
			else:w.paused=true;w.reason="manual"
		else:return
		world.chico_motion.reset();world.update_cheese_worker(state,0)
		FarmCheeseWorkerHUD.show(hud,state);_update_ui();return
	if value=="cheese_shop": FarmCheeseHUD.shop(hud,state);return
	if value=="cheese_market": FarmCheeseHUD.stock(hud,state);return
	if value=="cheese_orders": FarmCheeseHUD.orders(hud,state);return
	if value.begins_with("cheese:"):
		var act:=value.get_slice(":",1)
		match act:
			"review":
				if hud.modal_kind=="cheesery": FarmCheeseHUD.review(hud,state)
			"back": FarmCheeseHUD.show(hud,state,hud.building_index)
			"start":
				if hud.modal_kind!="cheese_confirm": return
				var error:=FarmCheese.start(state,hud.building_index,hud.cheese_batch)
				FarmCheeseHUD.show(hud,state,hud.building_index)
				hud.toast(error if not error.is_empty() else "Leite no tacho! Feche o menu para produzir.")
			"collect":
				if hud.modal_kind!="cheesery": return
				var amount:=FarmCheese.collect(state,hud.building_index)
				FarmCheeseHUD.show(hud,state,hud.building_index);hud.toast("%d queijo(s) recolhidos"%amount)
			"sell":
				if hud.modal_kind!="cheese_stock": return
				var earned:=FarmCheese.sell(state,int(hud.cheese_quantity.value))
				FarmCheeseHUD.stock(hud,state);hud.toast("Queijo vendido · +$%d"%earned)
			"accept","cancel","deliver":
				if hud.modal_kind!="cheese_orders": return
				if act=="accept" and state.claimed: state.cheese_order.active=true
				elif act=="cancel": state.cheese_order.active=false
				elif act=="deliver" and FarmCheese.deliver(state): hud.toast("Dona Nena aprovou! +1 reputação")
				FarmCheeseHUD.orders(hud,state)
		_update_ui();return
	if value=="milk_market":
		FarmDairyHUD.stock(hud,state)
		return
	if value=="sell_milk":
		var earned:=FarmDairy.sell(state,int(hud.milk_quantity.value))
		FarmDairyHUD.stock(hud,state); hud.toast("Leite vendido · +$%d"%earned); _update_ui()
		return
	if value=="coop" and selected>=0 and selected<state.items.size() and state.items[selected].kind=="pigsty":
		FarmPigHUD.show(hud,state,selected);return
	if value=="pigsty":
		FarmPigHUD.show(hud,state,selected);return
	if value.begins_with("pigs:"):
		var act:=value.get_slice(":",1)
		if act=="review":FarmPigHUD.confirm(hud,state,selected);return
		if act=="back":FarmPigHUD.show(hud,state,selected);return
		var error:=FarmPigs.care(state,selected,act)
		world.update_animals(state);FarmPigHUD.show(hud,state,selected)
		hud.toast(error if not error.is_empty() else "Porcos cuidados!");_update_ui();return
	if value.begins_with("dairy:"):
		var act:=value.get_slice(":",1)
		if act=="review": FarmDairyHUD.confirm(hud,state,selected); return
		if act=="back": FarmDairyHUD.show(hud,state,selected); return
		var error:=FarmDairy.care(state,selected,act)
		FarmDairyHUD.show(hud,state,selected)
		hud.toast(error if not error.is_empty() else {"buy":"Mimosa chegou ao curral!","milk":"Leite guardado no estoque","food":"Ração reposta","water":"Água fresquinha"}.get(act,"Pronto"))
		world.animate(0,player.position,state); _update_ui()
		return
	if value=="nearby_interact":
		_interact_nearest()
		return
	if value=="objectives":
		FarmWalkHUD.objectives(hud,state)
		return
	if value=="field_attention":
		if state.dairy_worker.hired and state.dairy_worker.paused and state.dairy_worker.reason in ["funds","budget","removed","blocked"]: FarmDairyWorkerHUD.show(hud,state)
		elif state.cheese_worker.hired and state.cheese_worker.paused and state.cheese_worker.reason in ["funds","budget","removed","blocked"]: FarmCheeseWorkerHUD.show(hud,state)
		elif not FarmFieldAlerts.paused_text(state).is_empty(): FarmCrewHUD.show(hud,state)
		else:
			var full:=FarmFieldAlerts.full_coops(state)
			if not full.is_empty():
				selected=full[0]; hud.coop(state,selected)
			else:
				var cheese:=FarmFieldAlerts.ready_cheeseries(state)
				if not cheese.is_empty():
					selected=cheese[0];FarmCheeseHUD.show(hud,state,selected)
		return
	if (dragging or not route.is_empty()) and value!="route_confirm":
		_cancel_route()
		if hud.modal_kind=="route": hud.close_modal()
	if move_index>=0 and value not in ["move","save"]:
		move_index=-1
		tool="inspect"
	if value.begins_with("neighbor:"):
		var key:=value.get_slice(":",1)
		if FarmTrade.NEIGHBORS.has(key):
			hud.market_neighbor=key
			hud.market(state,"orders")
		return
	if value in ["cultivation","cultivation_edit"]:
		if value=="cultivation" or hud.cultivation_draft.is_empty(): FarmCultivationHUD.prepare(hud,state)
		FarmCultivationHUD.show(hud,state)
		return
	if value=="cultivation_report":
		FarmCultivationHUD.report(hud,state)
		return
	if value=="cultivation_review":
		var candidate:Dictionary=hud.cultivation_draft.duplicate(true)
		candidate.enabled=true
		if not state.field_staff.hired or not FarmCultivation.valid(candidate,state.items):
			hud.toast("Escolha canteiros e ao menos uma tarefa para Bento.")
			return
		FarmCultivationHUD.review(hud,state)
		return
	if value in ["cultivation_apply","cultivation_renew"]:
		var draft:Dictionary=hud.cultivation_draft
		var error:String=FarmCultivation.renew(state) if value=="cultivation_renew" else FarmCultivation.configure(state,draft.plans,draft.tasks,int(draft.limit))
		if not error.is_empty(): hud.toast(error); return
		world.field_anchor=""
		world.update_staff(state,0)
		FarmCultivationHUD.report(hud,state)
		return
	if value=="cultivation_renew_review":
		FarmCultivationHUD.review(hud,state,true)
		return
	if value.begins_with("coop_tab:"):
		hud.coop_tab=value.get_slice(":",1)
		if selected>=0 and selected<state.items.size() and state.items[selected].kind=="coop": hud.coop(state,selected,selected_hen)
		return
	if value=="crew":
		FarmCrewHUD.show(hud,state)
		return
	if value in ["crew_hire_review","crew_dismiss_review"] or value.begins_with("crew_train_review:"):
		var kind:="hire" if value=="crew_hire_review" else ("dismiss" if value=="crew_dismiss_review" else value.get_slice(":",1))
		FarmCrewHUD.confirm(hud,state,kind)
		return
	if value in ["crew_hire","crew_pause","crew_dismiss"] or value.begins_with("crew_train:"):
		var error:=""
		match value:
			"crew_hire": error=state.hire_field_staff()
			"crew_pause": error=state.pause_field_staff()
			"crew_dismiss": state.dismiss_field_staff()
			_: error=state.train_worker(value.get_slice(":",1))
		world.update_staff(state,0)
		FarmCrewHUD.show(hud,state)
		if not error.is_empty(): hud.toast(error)
		_update_ui()
		return
	if value.begins_with("evolution:"):
		var index:=int(value.get_slice(":",1))
		if index>=0 and index<state.items.size() and FarmProgression.UPGRADES.has(state.items[index].kind): hud.evolution(state,index)
		return
	if value.begins_with("evolution_buy:"):
		var index:=int(value.get_slice(":",1))
		var error:=state.upgrade_building(index)
		if not error.is_empty(): hud.toast(error); return
		world.rebuild(state)
		selected=index
		_action("building_back")
		hud.toast("Construção evoluída para o nível 2!")
		_update_ui()
		return
	if value=="building_back":
		var index:=hud.building_index
		if index<0 or index>=state.items.size(): hud.close_modal(); return
		selected=index
		match state.items[index].kind:
			"barn": hud.barn(state,index)
			"coop": hud.coop(state,index,selected_hen)
			"workshop": hud.workshop(state,index)
		return
	if value=="professional_watering":
		var error:=state.buy_professional_watering()
		hud.workshop(state,selected)
		hud.toast("Regador profissional instalado: até 9 canteiros!" if error.is_empty() else error)
		return
	if value=="irrigation":
		hud.irrigation_draft=state.irrigation.plots.duplicate()
		hud.irrigation_panel(state)
		return
	if value=="irrigation_apply":
		var error:=state.configure_irrigation(hud.irrigation_draft)
		if not error.is_empty(): hud.toast(error); return
		world.staff_anchor=""
		world.field_anchor=""
		world.update_staff(state,0)
		if state.field_staff.hired: FarmCrewHUD.show(hud,state)
		else: hud.staff_panel(state)
		hud.toast("Irrigação: $%d por canteiro. Feche a janela para começar."%FarmCrew.fee(state.irrigation_worker()))
		return
	if value.begins_with("staff"):
		if not session_started: return
		var error:=""
		match value:
			"staff_hire_review":
				hud.staff_confirmation(false)
				return
			"staff_dismiss_review":
				hud.staff_confirmation(true)
				return
			"staff_hire": error=state.hire_staff(hud.staff_target)
			"staff_assign": error=state.assign_staff(hud.staff_target)
			"staff_pause": error=state.pause_staff()
			"staff_dismiss": state.dismiss_staff()
			"staff_coop": hud.staff_target=selected
			"staff": hud.staff_target=int(state.staff.coop)
		hud.staff_panel(state)
		world.update_staff(state,0)
		if not error.is_empty(): hud.toast(error)
		_update_ui()
		return
	if value.begins_with("sell_product:"):
		var key:=value.get_slice(":",1)
		if hud.modal_kind!="market" or hud.market_tab!="sales" or not hud.sale_quantities.has(key): return
		var quantity:=int(hud.sale_quantities[key].value)
		var earned:=state.sell_product(key,quantity)
		hud.market(state)
		hud.toast("Venda concluída: +$%d. O restante ficou com você."%earned if earned>0 else "Não há essa quantidade no estoque.")
		if earned>0: _chime()
		_update_ui()
		return
	if value.begins_with("accept_order:") or value.begins_with("deliver_order:") or value.begins_with("cancel_order:"):
		var key:=value.get_slice(":",1)
		if not state.trade.has(key): return
		var before_money:=state.revenue
		var error:=""
		var message:=""
		if value.begins_with("accept_order:"):
			error=state.accept_order(key)
			message="Encomenda aceita! O prazo avança só enquanto você joga."
		elif value.begins_with("deliver_order:"):
			error=state.deliver_order(key)
			message="Entrega concluída! +$%d e +1 reputação com %s."%[state.revenue-before_money,FarmTrade.NEIGHBORS[key].name]
			if error.is_empty(): _chime("harvest")
		else:
			error=state.cancel_order(key)
			message="Encomenda cancelada. Nada foi cobrado ou retirado."
		hud.market_neighbor=key
		hud.market(state,"orders")
		hud.toast(message if error.is_empty() else error)
		_update_ui()
		return
	if value.begins_with("care:"):
		if selected<0 or selected>=state.items.size() or state.items[selected].kind!="coop": return
		var item:Dictionary=state.items[selected]
		var care:=value.get_slice(":",1)
		var eggs_before:=int(state.inventory.egg)
		var water_before:=float(item.flock.water)
		var food_before:=float(item.flock.food)
		var message:=state.care_coop(selected,care)
		world.update_animals(state)
		var at:=Vector3(item.x,0,item.z)
		if state.inventory.egg>eggs_before:
			feedback.collect_eggs(at,int(state.inventory.egg)-eggs_before)
			_chime("harvest")
		elif item.flock.water>water_before:
			feedback.water(at+Vector3(1.6,0,-0.8).rotated(Vector3.UP,item.turn*PI/2),at+Vector3.UP,true,"Água fresca!")
			_chime("water")
		elif item.flock.food>food_before:
			feedback.floating_text(at,"Hora do rango!",Color("ffde7c"))
			_chime("plant")
		hud.coop(state,selected,selected_hen)
		hud.toast(message)
		_update_ui()
		return
	if value.begins_with("rename_hen:"):
		if selected<0 or selected>=state.items.size() or state.items[selected].kind!="coop": return
		selected_hen=int(value.get_slice(":",1))
		if selected_hen<0 or selected_hen>=state.items[selected].flock.names.size(): return
		hud.hen_editor(state.items[selected].flock.names[selected_hen])
		return
	if value=="build:clear":
		selected=-1;move_index=-1;tool="inspect";_cancel_route();_update_ui();return
	if value=="build:open":
		if build_mode and selected>=0 and selected<state.items.size():_tend_selected()
		return
	if value.begins_with("tool:"):
		if not session_started: return
		var key:=value.get_slice(":",1)
		if not FarmLevels.unlocked(state,key):
			FarmLevelsHUD.show(hud,state)
			return
		if key=="expand":
			var error:=state.expand()
			if error.is_empty():
				world.update_border(state)
				hud.toast("Mais terra, mais possibilidades. A fazenda cresceu!")
				_chime()
			else: hud.toast(error)
			return
		tool=key
		if not build_mode:
			build_mode=true
			focus=player.position
			pitch=0.78
		_update_ui()
		return
	if value.begins_with("crop:"):
		crop=value.get_slice(":",1)
		_update_ui()
		return
	if value.begins_with("paint:"):
		var part:String=["walls","roof","door"][hud.paint_selector.selected]
		var error:=state.paint_item(selected,part,int(value.get_slice(":",1)))
		if error.is_empty(): world.paint(world.item_nodes[selected],state.items[selected])
		hud.toast("Uma cor nova, um lugar mais seu." if error.is_empty() else error)
		return
	if value.begins_with("deposit:") or value.begins_with("withdraw:"):
		var amount:=state.transfer_reserve(value.get_slice(":",1),value.begins_with("deposit:"))
		hud.barn(state,selected)
		hud.toast("%d produtos transferidos. A reserva está protegida da venda geral."%amount)
		_update_ui()
		return
	match value:
		"coop":
			if selected>=0 and selected<state.items.size() and state.items[selected].kind=="coop": hud.coop(state,selected,selected_hen)
		"apply_hen_name":
			if hud.modal_kind!="hen_name": return
			var error:=state.rename_hen(selected,selected_hen,hud.text_input.text)
			if not error.is_empty():
				hud.toast(error)
				return
			world.update_animals(state)
			hud.coop(state,selected,selected_hen)
			hud.toast("Nome novo, a mesma personalidade!")
		"route_confirm":
			var error:=state.place_batch(route)
			if not error.is_empty():
				hud.confirm_route(state,route)
				hud.toast(error)
				return
			var count:=route.size()
			_cancel_route()
			hud.close_modal()
			selected=state.items.size()-1
			world.rebuild(state)
			_ensure_player_space()
			hud.toast("%d peças prontas. Ficou um capricho!"%count)
			_chime()
		"route_cancel": hud.close_modal()
		"barn":
			if selected>=0 and selected<state.items.size() and state.items[selected].kind=="workshop": hud.workshop(state,selected)
			elif selected>=0 and selected<state.items.size() and state.items[selected].kind=="stable":FarmStable.show(hud,state,horse,selected)
			elif state.count_items("barn")>0: hud.barn(state,selected)
		"upgrade":
			var error:=state.buy_watering_upgrade()
			hud.workshop(state,selected)
			hud.toast("Regador melhorado! Até 5 canteiros por rega." if error.is_empty() else error)
		"move":
			if selected<0 or selected>=state.items.size():
				hud.toast("Selecione uma construção com Cuidar para mover.")
				return
			if not build_mode:
				focus=Vector3(state.items[selected].x,0,state.items[selected].z)
				pitch=0.78
			build_mode=true
			move_index=selected
			turn=state.items[selected].turn
			tool="move"
			hud.toast("Escolha o novo lugar. R gira • Esc cancela • Sem custo.")
		"journey": _journey_action()
		"start":
			var farm_name:String=hud.text_input.text.strip_edges() if hud.modal_kind=="welcome" and is_instance_valid(hud.text_input) else state.farm_name
			state.farm_name=farm_name if not farm_name.is_empty() else "Meu pedacinho de mundo"
			session_started=true
			hud.close_modal()
			if state.claimed: hud.toast("Bem-vindo de volta! A fazenda estava esperando.")
		"mode":
			if _mounted() and not horse.dismount(player,avatar,actor,state,world.landscape):
				hud.toast("Procure um espaço livre para desmontar.");return
			if not state.claimed:
				hud.toast("Primeiro, escolha seu pedacinho de terra.")
				return
			build_mode=not build_mode
			tool="inspect"
			if build_mode:
				focus=player.position
				pitch=0.78
			else: pitch=0.45
		"market":
			if session_started: hud.market(state)
		"market_sales":
			if session_started: hud.market(state)
		"market_orders":
			if session_started: hud.market(state,"orders")
		"sell":
			var earned:=state.sell_all()
			hud.market(state)
			hud.toast("Negócio fechado! +$%d para sua fazenda."%earned)
			_chime()
		"contract":
			if state.deliver_contract():
				hud.market(state)
				hud.toast("Dona Nena aprovou as cenouras. +$110!")
				_chime()
		"close": hud.close_modal()
		"save": _save_game(true)
		"menu":
			if session_started: hud.menu(state)
		"edit_sign":
			if selected>=0 and state.items[selected].kind=="sign": hud.editor_dialog("sign",state.items[selected].text)
			else: hud.toast("Selecione uma placa no terreno primeiro.")
		"apply_text":
			if selected>=0 and state.items[selected].kind=="sign":
				state.items[selected].text=hud.text_input.text.strip_edges().left(40)
				world.rebuild(state)
			hud.close_modal()
		"remove":
			if selected>=0:
				var error:=state.remove_item(selected)
				if not error.is_empty():
					hud.toast(error)
					return
				selected=-1
				world.rebuild(state)
				hud.toast("Espaço livre. Metade do custo voltou para você.")
		"reset_ask": hud.confirm_reset()
		"reset_confirm":
			_reset_farm()
			hud.welcome(state,false)
			_save_game(false,true)
		"quit":_request_quit()
	_update_ui()

func _update_ui() -> void:
	hud.update(state,build_mode,selected,tool,crop,hover_hint)
	hud.walking.update(hud,state,_nearby_context(),crop)
	hud.walking.mount_status(_mounted(),horse.stamina,horse.burst)
	hud.walking.visit_mode(network.active)
	if network.active:hud.mode_label.text="CONSTRUÇÃO · COOPERATIVO" if build_mode else "FAZENDA COOPERATIVA"
	navigator.refresh()
	if not network.active and horse.is_inside_tree():horse.ensure_parking(state,world.landscape)
	var step:=state.journey_step()
	if session_started and journey_seen>=0 and step>journey_seen:
		hud.toast("Etapa concluída: "+FarmState.JOURNEY[journey_seen].title+"!")
	journey_seen=step
	if session_started and not state.level_notice.is_empty() and hud.toast_time<=0:
		hud.toast(state.level_notice);state.level_notice="";_chime()

func _journey_action() -> void:
	var step:=state.journey_step()
	if step>=FarmState.JOURNEY.size(): return
	var key:String=FarmState.JOURNEY[step].action
	if key=="market":
		if FarmState.JOURNEY[step].key=="contract" and state.inventory.carrot<6 and state.reserve.carrot>0:
			hud.barn(state,selected)
		else: hud.market(state)
	elif key=="harvest":
		if build_mode: _action("mode")
	elif key=="plots":
		crop="carrot"
		_action("tool:plot")
		focus=Vector3(state.center.x,0,state.center.y)
	elif key=="coop":
		_action("tool:coop")
		focus=Vector3(state.center.x,0,state.center.y)
	else:
		_action("tool:inspect")
		focus=Vector3(state.center.x,0,state.center.y)
		if key=="water":
			for i in range(state.items.size()):
				var item:Dictionary=state.items[i]
				if item.kind=="plot" and item.planted and not item.watered:
					selected=i
					focus=Vector3(item.x,0,item.z)
					break
		elif key=="expand": hud.toast("Use Expandir na barra quando tiver $900.")

func _save_game(notify: bool, force: bool = false) -> bool:
	if network.active:return network.save_coop()
	if not session_started and not force: return true
	var temporary:=save_path+".tmp"
	var file:=FileAccess.open(temporary,FileAccess.WRITE)
	if file==null:
		hud.toast("Não foi possível salvar. Verifique espaço e permissões.")
		return false
	file.store_string(JSON.stringify(state.serialize(),"",true,true))
	file.flush()
	var error:=file.get_error()
	file.close()
	if error!=OK:
		hud.toast("Falha ao gravar a fazenda. O salvamento anterior foi mantido.")
		return false
	# Keep a known-good backup and replace via rename to avoid half-written JSON.
	if FileAccess.file_exists(save_path):
		DirAccess.copy_absolute(save_path,save_path+".bak")
	var result:=DirAccess.rename_absolute(temporary,save_path)
	if result!=OK:
		hud.toast("Não foi possível concluir o salvamento.")
		return false
	if notify: hud.toast("Fazenda salva. Seu sonho está bem guardado.")
	return true

func _load_game() -> bool:
	for path in [save_path,save_path+".bak"]:
		if FileAccess.file_exists(path):
			var parser:=JSON.new()
			if parser.parse(FileAccess.get_file_as_string(path))==OK and state.restore(parser.data):
				if not qa_mode:state.unlimited_money=true
				if is_instance_valid(horse) and horse.is_inside_tree() and not _mounted():horse.restore(state.horse)
				return true
	return false

func _request_quit() -> void:
	if quitting or not _save_game(false):return
	quitting=true;session_started=false;audio.stop_all()
	if network.active and network.peer:network.peer.close()
	# Let the audio mixer release loop playbacks before destroying the engine.
	await get_tree().create_timer(.15).timeout
	get_tree().quit()

func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_CLOSE_REQUEST:
		_request_quit()
	elif what==NOTIFICATION_APPLICATION_FOCUS_OUT and session_started and not qa_mode and DisplayServer.get_name()!="headless" and not focus_check_pending:
		_check_focus_pause()

func _check_focus_pause() -> void:
	focus_check_pending=true
	# Fullscreen switches can briefly change focus without the player leaving the game.
	await get_tree().create_timer(.2).timeout
	focus_check_pending=false
	if get_window().mode==Window.MODE_MINIMIZED or not get_window().has_focus():_pause_for_focus_loss()

func _pause_for_focus_loss() -> void:
	if not session_started or not is_instance_valid(hud) or not hud.modal_kind.is_empty():return
	_cancel_route()
	move_index=-1
	if tool=="move":tool="inspect"
	player.velocity=Vector3.ZERO
	for action_name in ["forward","back","left","right","run"]:Input.action_release(action_name)
	weapons.holster()
	if network.active:network.session_menu()
	else:
		hud.menu(state)
		hud.toast("Jogo pausado enquanto você estava fora da janela.")

func _chime(kind: String = "build") -> void:
	audio.play_effect(kind if kind in ["build","harvest","plant","water"] else "build")

func _qa() -> void:
	if "--qa-v026" in OS.get_cmdline_user_args():
		await _qa_v026();get_tree().quit();return
	if "--qa-title-photo" in OS.get_cmdline_user_args():
		await _qa_title_photo();get_tree().quit();return
	if "--qa-v025" in OS.get_cmdline_user_args():
		_action("start");await _qa_v025();get_tree().quit();return
	if "--qa-v024" in OS.get_cmdline_user_args():
		_action("start");await _qa_v024();get_tree().quit();return
	if "--qa-horse-preview" in OS.get_cmdline_user_args():
		_action("start");await _qa_horse_preview();get_tree().quit();return
	if "--qa-v023" in OS.get_cmdline_user_args():
		_action("start");await _qa_v023();get_tree().quit();return
	if "--qa-v022" in OS.get_cmdline_user_args():
		_action("start");await _qa_v022();get_tree().quit();return
	if "--qa-v021" in OS.get_cmdline_user_args():
		_action("start");await _qa_v021();get_tree().quit();return
	if "--qa-v020" in OS.get_cmdline_user_args():
		_action("start");await _qa_v020();get_tree().quit();return
	if "--qa-v019" in OS.get_cmdline_user_args():
		_action("start");await _qa_v019();get_tree().quit();return
	if "--qa-v018" in OS.get_cmdline_user_args():
		_action("start");state.farm_xp=950
		await _qa_v018()
		get_tree().quit()
		return
	if "--qa-v017" in OS.get_cmdline_user_args():
		_action("start");state.farm_xp=950
		await _qa_v017()
		get_tree().quit()
		return
	if "--qa-v016" in OS.get_cmdline_user_args():
		_action("start");state.farm_xp=950
		await _qa_v016()
		get_tree().quit()
		return
	if "--qa-v015" in OS.get_cmdline_user_args():
		_action("start");state.farm_xp=950
		await _qa_v015()
		get_tree().quit()
		return
	# In-engine integration run. Isolated state; never reads/writes the player's save.
	await get_tree().process_frame
	await get_tree().process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://test-results/welcome.png")
	_action("start");state.farm_xp=950
	pointer=Vector2(4,-2)
	pointer_valid=true
	_click_world()
	assert(state.claimed and state.money==1200)
	var placements=[
		["barn",Vector2(-2,-8),0],["coop",Vector2(12,-8),0],
		["sign",Vector2(0,8),0],
		["plot",Vector2(2,-2),0],["plot",Vector2(4,-2),0],["plot",Vector2(6,-2),0],
		["plot",Vector2(2,0),0],["plot",Vector2(4,0),0],["plot",Vector2(6,0),0],
		["plot",Vector2(2,2),0],["plot",Vector2(4,2),0],["plot",Vector2(6,2),0],
		["fence",Vector2(-6,8),0],["fence",Vector2(-4,8),0],["fence",Vector2(4,8),0],["fence",Vector2(6,8),0],
		["path",Vector2(-2,6),0],["path",Vector2(-2,4),0],["path",Vector2(-2,2),0],["path",Vector2(-2,0),0],["path",Vector2(-2,-2),0]]
	for i in range(placements.size()):
		var p:Array=placements[i]
		_action("tool:"+p[0])
		pointer=p[1]
		pointer_valid=true
		turn=p[2]
		crop=["carrot","wheat","corn"][i%3]
		_click_world()
		assert(state.items.size()==i+1)
		if not hud.modal_kind.is_empty(): hud.close_modal()
	for i in range(state.items.size()):
		if state.items[i].kind=="plot": state.tend(i)
	state.tick(63)
	world.rebuild(state)
	focus=Vector3(4,0,-2)
	build_distance=40
	tool="inspect"
	selected=0
	_update_ui()
	_update_camera(1,true)
	await get_tree().process_frame
	await get_tree().process_frame
	assert(_pick_item(camera.unproject_position(Vector3(-2,2,-8)),Vector2(100,100))==0)
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://test-results/construction.png")
	state.tend(3)
	assert(state.harvests==1)
	var total:=state.sale_value()
	_action("market")
	assert(hud.modal_kind=="market")
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://test-results/market.png")
	_action("sell")
	assert(state.revenue==total)
	_action("close")
	_action("paint:1")
	assert(state.items[0].paint==1)
	selected=2
	_action("edit_sign")
	assert(hud.modal_kind=="sign")
	hud.text_input.text="Cuidado com a gerente!"
	_action("apply_text")
	assert(state.items[2].text=="Cuidado com a gerente!")
	var before_move:Dictionary=state.items[2].duplicate(true)
	var balance_before_move:=state.money
	_action("move")
	assert(move_index==2)
	assert(state.items[2]==before_move)
	pointer=Vector2(-2,-8)
	pointer_valid=true
	_click_world()
	assert(move_index==2 and state.items[2]==before_move)
	var cancel:=InputEventKey.new()
	cancel.keycode=KEY_ESCAPE
	cancel.pressed=true
	_unhandled_input(cancel)
	assert(move_index==-1 and state.items[2]==before_move)
	_action("move")
	pointer=Vector2(8,8)
	pointer_valid=true
	turn=1
	_click_world()
	assert(move_index==-1 and state.items[2].x==8 and state.items[2].turn==1)
	assert(state.items[2].text==before_move.text and state.money==balance_before_move)
	_action("journey")
	assert(hud.modal_kind=="market")
	_action("close")
	_action("mode")
	assert(not build_mode)
	player.position=Vector3(4,0.2,7)
	yaw=0.32
	pitch=0.38
	_update_camera(1,true)
	_update_ui()
	for i in range(60): await get_tree().process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://test-results/walking.png")
	assert(actor.bones.has("UpperArm.R") and actor.bones.has("Thigh.L"))
	await get_tree().create_timer(1.5).timeout
	assert(hud.quest_progress.size.y<=10)
	player.position=Vector3(4,0.2,4.8)
	yaw=-0.65
	_update_camera(1,true)
	selected=10
	state.items[10].growth=0.10
	state.items[10].watered=false
	state.items[4].growth=0.52
	world.update_crops(state)
	assert(world.item_nodes[10].get_node("Crop/Sprout").visible)
	assert(world.item_nodes[4].get_node("Crop/Young").visible)
	assert(world.item_nodes[5].get_node("Crop/Ripe").visible)
	_tend_selected()
	assert(state.items[10].watered and actor.action_kind=="water")
	for i in range(12): await get_tree().physics_frame
	assert(actor.can.visible and actor.skeleton.get_bone_pose_rotation(actor.bones["UpperArm.R"]).angle_to(actor.skeleton.get_bone_rest(actor.bones["UpperArm.R"]).basis.get_rotation_quaternion())>0.1)
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://test-results/watering-v02.png")
	for i in range(60): await get_tree().physics_frame
	assert(not actor.can.visible)
	state.items[10].growth=1.0
	var harvest_before:=state.harvests
	var hen_before:Node3D=world.chickens[0].node
	_tend_selected()
	assert(state.harvests==harvest_before+1)
	assert(is_instance_valid(hen_before) and world.chickens[0].node==hen_before)
	_tend_selected()
	assert(not state.items[10].planted)
	for i in range(12): await get_tree().physics_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://test-results/harvest-v02.png")
	for i in range(100): await get_tree().physics_frame
	assert(feedback.get_child_count()==0)
	var start:=Time.get_ticks_msec()
	Input.action_press("forward")
	var old_position:=player.position
	for i in range(30): await get_tree().physics_frame
	Input.action_release("forward")
	assert(player.position.distance_to(old_position)>0.5)
	state.elapsed=next_silly+1
	_process(0.1)
	assert(silly_timer>0)
	await _qa_v03()
	await _qa_v04()
	await _qa_v05()
	await _qa_v06()
	await _qa_v09()
	await _qa_v010()
	await _qa_v011()
	await _qa_crew()
	await _qa_v012()
	await _qa_v013()
	await _qa_v014()
	await _qa_v015()
	await _qa_v016()
	await _qa_v017()
	await _qa_v018()
	await _qa_v019()
	var restored:=FarmState.new()
	assert(restored.restore(JSON.parse_string(JSON.stringify(state.serialize()))))
	assert(restored.items.size()==state.items.size())
	assert(_save_game(false))
	assert(_save_game(false))
	var saved_money:=state.money
	var saved_reserve:=state.reserve.duplicate()
	var saved_flock:Dictionary=state.items[1].flock.duplicate(true)
	var saved_trade:Dictionary=state.trade.duplicate(true)
	var saved_staff:Dictionary=state.staff.duplicate(true)
	state=FarmState.new();state.farm_xp=950
	assert(_load_game() and state.money==saved_money)
	assert(state.reserve==saved_reserve and state.watering_upgrade and state.items[0].door_paint==2)
	_qa_saved_flock(state.items[1].flock,saved_flock)
	assert(state.trade==saved_trade and state.active_orders()>0)
	assert(state.staff==saved_staff and state.staff.hired)
	var damaged:=FileAccess.open(save_path,FileAccess.WRITE)
	damaged.store_string("{damaged")
	damaged.close()
	state=FarmState.new();state.farm_xp=950
	assert(_load_game() and state.money==saved_money)
	assert(state.reserve==saved_reserve and state.watering_upgrade and state.items[0].roof_paint==5)
	_qa_saved_flock(state.items[1].flock,saved_flock)
	assert(state.trade==saved_trade and state.active_orders()>0)
	assert(state.staff==saved_staff and state.staff.hired)
	DirAccess.remove_absolute(save_path)
	DirAccess.remove_absolute(save_path+".bak")
	print("INTEGRATION_OK: terrain, construction, crops, sale, paint, signs, camera, movement, persistence")
	print("SAVE_OK: atomic replacement, disk reload, backup recovery")
	print("V02_OK: articulated character, watering, harvest feedback, growth stages, movement commit/cancel, tutorial, effect cleanup")
	print("RENDERER: ",RenderingServer.get_video_adapter_name())
	print("FPS: ",Engine.get_frames_per_second()," | physics movement test ms: ",Time.get_ticks_msec()-start)
	get_tree().quit()

func _qa_saved_flock(actual: Dictionary, expected: Dictionary) -> void:
	assert(actual.names==expected.names and actual.nest==expected.nest)
	# Decimal JSON round trips can differ by a few units in the last float digit.
	assert(absf(float(actual.food)-float(expected.food))<0.000000001)
	assert(absf(float(actual.water)-float(expected.water))<0.000000001)

func _qa_v03() -> void:
	_action("mode")
	_action("tool:fence")
	focus=Vector3(4,0,-2)
	yaw=0.42
	pitch=0.78
	build_distance=40
	_update_camera(1,true)
	var before:=state.serialize()
	pointer=Vector2(-4,-12)
	pointer_valid=true
	_begin_route()
	pointer=Vector2(8,-12)
	_update_route()
	assert(route.size()==7 and state.serialize()==before)
	_finish_route()
	assert(hud.modal_kind=="route" and not dragging and state.serialize()==before)
	await get_tree().process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://test-results/route-v03.png")
	var cancel:=InputEventKey.new()
	cancel.keycode=KEY_ESCAPE
	cancel.pressed=true
	_unhandled_input(cancel)
	assert(route.is_empty() and hud.modal_kind.is_empty() and state.serialize()==before)
	# Drive the actual mouse input path, including release before confirmation.
	if DisplayServer.get_name()!="headless":
		await _qa_mouse(camera.unproject_position(Vector3(-4,0,-12)),true)
		assert(dragging)
		await _qa_mouse(camera.unproject_position(Vector3(8,0,-12)),false)
	else:
		pointer=Vector2(-4,-12)
		_begin_route()
		pointer=Vector2(8,-12)
		_finish_route()
	assert(hud.modal_kind=="route" and route.size()==7)
	_action("route_confirm")
	assert(state.items.size()==before.items.size()+7 and state.money==before.money-84)
	assert(hud.modal_kind.is_empty() and route.is_empty())
	var after:=state.serialize()
	pointer=Vector2(-4,-12)
	pointer_valid=true
	_begin_route()
	pointer=Vector2(8,-12)
	_finish_route()
	_action("route_confirm")
	assert(state.serialize()==after and hud.modal_kind=="route")
	_action("route_cancel")
	_action("tool:path")
	pointer=Vector2(10,0)
	pointer_valid=true
	_begin_route()
	pointer=Vector2(10,6)
	_finish_route()
	_action("route_confirm")
	assert(state.items.size()==after.items.size()+4 and state.money==after.money-20)
	# Releasing over the toolbar cancels even though GUI input would be consumed.
	if DisplayServer.get_name()!="headless":
		await _qa_mouse(camera.unproject_position(Vector3(14,0,2)),true)
		assert(dragging)
		after=state.serialize()
		await _qa_mouse(Vector2(600,770),false)
		assert(not dragging and route.is_empty() and state.serialize()==after)
	_action("tool:inspect")
	selected=0
	_update_ui()
	hud.paint_selector.select(0)
	_action("paint:1")
	hud.paint_selector.select(1)
	_action("paint:5")
	hud.paint_selector.select(2)
	_action("paint:2")
	assert(state.items[0].paint==1 and state.items[0].roof_paint==5 and state.items[0].door_paint==2)
	var materials:=_qa_painted_surfaces(world.item_nodes[0])
	assert(materials.has("Paint") and materials.has("Roof") and materials.has("DoorBarn"))
	assert(materials.Paint.is_equal_approx(Color(FarmState.PALETTE[1])))
	assert(materials.Roof.is_equal_approx(Color(FarmState.PALETTE[5])))
	assert(materials.DoorBarn.is_equal_approx(Color(FarmState.PALETTE[2])))
	state.inventory.carrot=70
	_action("barn")
	assert(hud.modal_kind=="barn")
	_action("deposit:carrot")
	assert(state.reserve.carrot==60 and state.inventory.carrot==10)
	_action("close")
	_action("remove")
	assert(state.items[0].kind=="barn" and state.reserve.carrot==60)
	_action("market")
	_action("sell")
	assert(state.reserve.carrot==60 and state.inventory.carrot==0)
	_action("close")
	_update_ui()
	assert(hud.quest_button.text=="Retirar no celeiro")
	_action("journey")
	assert(hud.modal_kind=="barn")
	_action("close")
	_action("barn")
	assert(state.place("workshop",Vector2(-6,-2),0).is_empty())
	var balance:=state.money
	_action("upgrade")
	assert(state.watering_upgrade and state.money==balance-300)
	assert(hud.modal_kind=="workshop")
	state.remove_item(state.items.size()-1)
	_action("barn")
	await get_tree().process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://test-results/barn-v03.png")
	_action("withdraw:carrot")
	assert(state.reserve.carrot==0 and state.inventory.carrot==60)
	_action("deposit:carrot")
	_action("close")
	_action("mode")
	player.position=Vector3(-2,0.2,-4)
	selected=0
	_interact_nearest()
	assert(hud.modal_kind=="barn")
	_action("close")
	_action("mode")
	# Five plots in a cross receive water from the same player action.
	for index in [4,6,7,8,10]:
		state.items[index].planted=true
		state.items[index].watered=false
		state.items[index].growth=0
	selected=7
	action_cooldown=0
	_tend_selected()
	for index in [4,6,7,8,10]: assert(state.items[index].watered)
	assert(feedback.get_child_count()>=26*5)
	await get_tree().create_timer(1.6).timeout
	assert(feedback.get_child_count()==0)
	selected=0
	focus=Vector3(2,0,-3)
	yaw=0.35
	pitch=0.65
	build_distance=32
	_update_camera(1,true)
	_update_ui()
	hud.toast_time=0
	await get_tree().process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://test-results/farm-v03.png")
	print("V03_INTEGRATION_OK: mouse drag, release over HUD, price confirmation, cancel, independent materials, barn, protected reserve, tool upgrade, area watering")

func _qa_v04() -> void:
	selected=1
	selected_hen=-1
	tool="inspect"
	focus=Vector3(12,0,-6)
	yaw=0.30
	pitch=0.70
	build_distance=20
	_update_camera(1,true)
	var flock:Dictionary=state.items[1].flock
	flock.food=12.0
	flock.water=0.0
	flock.nest=6
	state.items[1].egg_time=12.0
	world.update_animals(state)
	var view:Dictionary=world.coop_views[1]
	assert(view.feed.visible and not view.water.visible)
	assert(view.eggs[5].visible and not view.eggs[6].visible)
	assert(view.badge.text.contains("6 OVOS"))
	await get_tree().physics_frame
	if DisplayServer.get_name()!="headless":
		var hen:Node3D=world.chickens[2].node
		var at:=camera.unproject_position(hen.position+Vector3(0,0.5,0))
		await _qa_mouse(at,true)
		await _qa_mouse(at,false)
		assert(selected==1 and selected_hen==2 and hud.modal_kind=="coop")
	else: _action("coop")
	var frozen:=state.serialize()
	_process(5)
	assert(state.serialize()==frozen)
	await get_tree().process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://test-results/coop-care-v04.png")
	_action("rename_hen:0")
	assert(hud.modal_kind=="hen_name")
	hud.text_input.text="   "
	_action("apply_hen_name")
	assert(hud.modal_kind=="hen_name" and flock.names[0]=="Maricota")
	hud.text_input.text="Dona Có-Có"
	_action("apply_hen_name")
	assert(hud.modal_kind=="coop" and flock.names[0]=="Dona Có-Có")
	assert(world.chickens[0].label.text=="Dona Có-Có")
	var balance:=state.money
	var cost:=FarmAnimals.food_cost(flock)
	_action("care:food")
	assert(flock.food==100 and state.money==balance-cost)
	_action("care:water")
	assert(flock.water==100 and state.money==balance-cost and view.water.visible)
	var previous_eggs:=int(state.inventory.egg)
	_action("care:collect")
	assert(flock.nest==0 and state.inventory.egg==previous_eggs+6)
	assert(not view.eggs[0].visible)
	_action("care:collect")
	assert(state.inventory.egg==previous_eggs+6)
	_action("close")
	flock.nest=4
	var before:Dictionary=flock.duplicate(true)
	_action("move")
	pointer=Vector2(12,-8)
	pointer_valid=true
	turn=1
	_click_world()
	assert(move_index==-1 and state.items[1].turn==1 and state.items[1].flock==before)
	assert(world.coop_views[1].eggs[3].visible and not world.coop_views[1].eggs[4].visible)
	_action("remove")
	assert(state.items[1].kind=="coop" and state.items[1].flock==before)
	# E can open the coop, while the mouse can identify an individual hen.
	_action("mode")
	player.position=Vector3(12,0.2,-5.1)
	selected=1
	_interact_nearest()
	assert(hud.modal_kind=="coop")
	_action("close")
	_action("mode")
	silly_event_index=0
	var seen:Array=[]
	for i in range(3):
		_start_silly()
		seen.append(silly_kind)
		assert(hud.toast_label.text.contains("Dona Có-Có"))
		var peak:=0.0
		for frame in range(60):
			world.animate(1.0/60,player.position,state,silly_kind)
			peak=maxf(peak,absf(world.chickens[0].node.rotation.z))
		if silly_kind=="dance": assert(peak>0.15)
	assert(seen==["inspect","dance","meeting"])
	for frame in range(120): world.animate(1.0/60,player.position,state)
	for hen in world.chickens: assert(world._hen_walkable(hen.node.position,state))
	var before_neighbor:=state.money
	assert(state.place("coop",Vector2(12,-4),0).is_empty())
	world.rebuild(state)
	assert(world.chickens.size()==6)
	for hen in world.chickens: assert(world._hen_walkable(hen.node.position,state))
	assert(state.remove_item(state.items.size()-1).is_empty())
	state.money=before_neighbor
	# Restore front-facing presentation and show actual needs models and nest eggs.
	assert(state.move_item(1,Vector2(12,-8),0).is_empty())
	world.rebuild(state)
	player.position=Vector3(9,0.2,-4.5)
	selected=1
	focus=Vector3(12,0,-6.5)
	yaw=0.40
	pitch=0.57
	build_distance=20
	_update_camera(1,true)
	_update_ui()
	if DisplayServer.get_name()!="headless": Input.warp_mouse(Vector2(600,770))
	await get_tree().create_timer(1.6).timeout
	hud.toast_time=0
	await get_tree().process_frame
	assert(feedback.get_child_count()==0)
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://test-results/animals-v04.png")
	_action("coop")
	await get_tree().process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://test-results/coop-ready-v04.png")
	_action("close")
	print("V04_INTEGRATION_OK: Blender props, hen picking, rename validation, paused needs, feeding, water, collection, movement, humor, obstacle steering")

func _qa_v05() -> void:
	state.inventory={"carrot":12,"wheat":12,"corn":12,"egg":12}
	var kept_reserve:=state.reserve.duplicate()
	_action("market")
	assert(hud.modal_kind=="market" and hud.market_tab=="sales")
	hud.sale_quantities.carrot.value=3
	assert(hud.sale_buttons.carrot.text=="Vender 3 • $36")
	hud.sale_quantities.wheat.value=2
	assert(hud.sale_buttons.wheat.text=="Vender 2 • $34" and hud.sale_buttons.carrot.text=="Vender 3 • $36")
	# Type into the actual quantity field, without requiring Enter before selling.
	await get_tree().process_frame
	var edit:LineEdit=hud.sale_quantities.carrot.get_line_edit()
	edit.grab_focus()
	edit.select_all()
	await get_tree().process_frame
	var key:=InputEventKey.new()
	key.keycode=KEY_5
	key.unicode=53
	key.pressed=true
	Input.parse_input_event(key)
	await get_tree().process_frame
	await get_tree().process_frame
	key.pressed=false
	Input.parse_input_event(key)
	assert(hud.sale_quantities.carrot.value==5 and hud.sale_buttons.carrot.text=="Vender 5 • $60")
	var balance:=state.money
	hud.sale_buttons.carrot.pressed.emit()
	assert(state.money==balance+60 and state.inventory.carrot==7 and state.inventory.wheat==12)
	assert(state.reserve==kept_reserve)
	hud.sale_quantities.wheat.value=2
	hud.sale_buttons.wheat.pressed.emit()
	assert(state.inventory.wheat==10)
	await get_tree().process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://test-results/sales-v05.png")
	_action("market_orders")
	_action("neighbor:nena")
	assert(hud.market_tab=="orders" and hud.market_neighbor=="nena")
	hud.order_action.pressed.emit()
	assert(state.active_orders()==1 and not hud.order_action.disabled)
	var frozen:=state.serialize()
	build_mode=false
	_process(7)
	assert(state.serialize()==frozen)
	build_mode=true
	_action("neighbor:bento")
	hud.order_action.pressed.emit()
	assert(state.active_orders()==2)
	var stock:=state.inventory.duplicate()
	balance=state.money
	_action("cancel_order:bento")
	assert(state.active_orders()==1 and state.inventory==stock and state.money==balance)
	_action("neighbor:nena")
	var reward:int=FarmTrade.offer("nena",state.trade.nena).reward
	hud.order_action.pressed.emit()
	assert(state.trade.nena.reputation==1 and state.money==balance+reward)
	stock=state.inventory.duplicate()
	balance=state.money
	_action("deliver_order:nena")
	assert(state.inventory==stock and state.money==balance)
	state.inventory.carrot=6
	_action("market_sales")
	_action("contract")
	assert(state.contract_done and state.trade.nena.reputation==2)
	_action("neighbor:lola")
	hud.order_action.pressed.emit()
	assert(state.trade.lola.active.size()>0)
	_action("close")
	frozen=state.serialize()
	_process(7)
	assert(state.serialize()==frozen) # Build mode also pauses deadlines.
	state.elapsed=float(state.trade.lola.active.deadline)-0.5
	next_silly=state.elapsed+1000
	stock=state.inventory.duplicate()
	balance=state.money
	build_mode=false
	_process(0.5)
	assert(state.trade.lola.active.is_empty() and state.trade.lola.last_result=="expired")
	assert(state.money==balance and state.inventory==stock and state.trade_notices.is_empty())
	assert(hud.toast_label.text.contains("Sem multa"))
	build_mode=true
	_action("neighbor:nena")
	assert(FarmTrade.offer("nena",state.trade.nena).tier==1)
	hud.order_action.pressed.emit()
	assert(state.trade.nena.active.deadline==state.elapsed+600)
	assert(hud.order_action.disabled) # Twelve wheat required, ten available.
	await get_tree().process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://test-results/orders-v05.png")
	_action("close")
	# Physical noticeboard uses both ray picking and nearby E interaction.
	player.position=FarmWorld.TRADE_BOARD_AT+Vector3(2,0.2,0)
	build_mode=false
	_interact_nearest()
	assert(hud.modal_kind=="market" and hud.market_tab=="orders")
	_action("close")
	build_mode=true
	tool="inspect"
	focus=FarmWorld.TRADE_BOARD_AT+Vector3(0,0,-1)
	yaw=1.15
	pitch=0.52
	build_distance=20
	_update_camera(1,true)
	await get_tree().physics_frame
	if DisplayServer.get_name()!="headless":
		var at:=camera.unproject_position(FarmWorld.TRADE_BOARD_AT+Vector3(0,1.7,0))
		await _qa_mouse(at,true)
		await _qa_mouse(at,false)
		assert(picked_trade_board and hud.modal_kind=="market" and hud.market_tab=="orders")
		_action("close")
		Input.warp_mouse(Vector2(600,770))
	hud.toast_time=0
	_update_ui()
	await get_tree().process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://test-results/board-v05.png")
	var shortcut:=InputEventKey.new()
	shortcut.physical_keycode=KEY_J
	shortcut.pressed=true
	_unhandled_input(shortcut)
	assert(hud.modal_kind=="market" and hud.market_tab=="orders")
	_action("close")
	print("V05_INTEGRATION_OK: selective sale, typed quantity, offer UI, acceptance, delivery, reputation tier, paused deadline, expiry, physical board and keyboard shortcut")

func _qa_v06() -> void:
	selected=1
	var shortcut:=InputEventKey.new()
	shortcut.physical_keycode=KEY_H
	shortcut.pressed=true
	_unhandled_input(shortcut)
	assert(hud.modal_kind=="staff" and hud.staff_target==1 and not hud.staff_primary.disabled)
	var snapshot:=state.serialize()
	hud.staff_primary.pressed.emit()
	assert(hud.modal_kind=="staff_confirm" and state.serialize()==snapshot)
	await get_tree().process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://test-results/staff-hire-v06.png")
	_action("staff")
	assert(state.serialize()==snapshot)
	_action("staff_hire_review")
	_action("staff_hire")
	assert(state.staff.hired and state.staff.coop==1 and state.money==snapshot.money-120)
	assert(world.staff_root.visible and world.staff_actor.bones.has("Head"))
	snapshot=state.serialize()
	build_mode=false
	_process(30)
	assert(state.serialize()==snapshot)
	build_mode=true
	_action("close")
	_process(30)
	assert(state.serialize()==snapshot)
	var flock:Dictionary=state.items[1].flock
	flock.food=10.0
	flock.water=20.0
	flock.nest=6
	state.items[1].egg_time=0.0
	var eggs:=int(state.inventory.egg)
	var balance:=state.money
	build_mode=false
	# The simulation batch starts after the caretaker has physically reached the nest.
	state.staff.timer=8.0
	for step in range(240): world.update_staff(state,1.0/60)
	state.staff.timer=0.0
	assert(state.staff_accessible)
	_process(15)
	build_mode=true
	assert(flock.food==100 and flock.water==100 and flock.nest==0)
	assert(state.inventory.egg==eggs+6 and state.money==balance-10)
	assert(state.staff.services==1 and state.staff.eggs==6 and (world.staff_motion.pending_service or world.staff_motion.collecting))
	var service_ledger:=state.staff.duplicate(true)
	var staff_start:=world.staff_root.position
	for frame in range(360):
		world.update_staff(state,1.0/60)
		if world.staff_actor.action_kind=="collect": break
	assert(world.staff_root.position.distance_to(staff_start)<0.2)
	assert(world.staff_actor.action_kind=="collect" and state.staff==service_ledger)
	_action("staff")
	hud.staff_primary.pressed.emit()
	assert(state.staff.paused and world.staff_label.text.contains("PAUSADO"))
	_action("close")
	var ledger:=state.staff.duplicate(true)
	build_mode=false
	_process(30)
	build_mode=true
	assert(state.staff==ledger and state.money==balance-10)
	_action("staff")
	hud.staff_primary.pressed.emit()
	assert(not state.staff.paused)
	_action("close")
	flock.nest=4
	flock.food=0.0
	state.money=9
	build_mode=false
	_process(15)
	build_mode=true
	assert(state.staff.paused and state.staff.reason=="funds" and state.money==9)
	assert(flock.nest>=4 and hud.toast_label.text.contains("Zeca pausou"))
	state.money=balance-10
	_action("staff")
	hud.staff_primary.pressed.emit()
	_action("close")
	build_mode=false
	_process(15)
	build_mode=true
	assert(not state.staff.paused and flock.nest==0)
	# Drive the workplace selector and preserve the employee through reassignment.
	assert(state.place("coop",Vector2(12,-4),0).is_empty())
	world.rebuild(state)
	_action("staff")
	hud.staff_choice.select(1)
	hud.staff_choice.item_selected.emit(1)
	assert(hud.staff_target==state.items.size()-1)
	_action("staff_assign")
	assert(state.staff.coop==state.items.size()-1)
	hud.staff_choice.select(0)
	hud.staff_choice.item_selected.emit(0)
	_action("staff_assign")
	assert(state.staff.coop==1)
	assert(state.remove_item(state.items.size()-1).is_empty())
	world.rebuild(state)
	_action("staff_dismiss_review")
	snapshot=state.serialize()
	_action("staff")
	assert(state.serialize()==snapshot)
	_action("staff_dismiss_review")
	_action("staff_dismiss")
	assert(not state.staff.hired and not world.staff_root.visible and state.money==snapshot.money)
	_action("staff_hire_review")
	_action("staff_hire")
	assert(state.staff.hired and state.money==snapshot.money-120)
	_action("close")
	focus=Vector3(12,0,-6.5)
	player.position=Vector3(9,0.2,-4.5)
	yaw=0.40
	pitch=0.57
	build_distance=20
	_update_camera(1,true)
	_update_pointer()
	_update_ui()
	hud.toast_time=0
	world.update_staff(state,0)
	await get_tree().process_frame
	if DisplayServer.get_name()!="headless":
		Input.warp_mouse(Vector2(600,770))
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://test-results/helper-v06.png")
	_action("staff")
	await get_tree().process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://test-results/staff-v06.png")
	_action("close")
	print("V06_INTEGRATION_OK: shortcut, hiring confirmation/cancel, care, costs, menu/build pause, low funds, assignment selector, dismiss/cancel, rehire and Blender character")

func _qa_v09() -> void:
	# Real in-game skins; the isolated renderer also checks bent-joint poses.
	for model_node in [avatar,world.staff_actor.root]:
		var skin:MeshInstance3D=model_node.find_child("BodySkin",true,false)
		assert(skin!=null and skin.skin!=null)
		assert(model_node.find_children("*","Skeleton3D",true,false)[0].get_bone_count()==20)
	for hen in world.chickens:
		assert(hen.node.find_child("LegL",true,false)!=null and hen.node.find_child("LegR",true,false)!=null)
	avatar.rotation.y=0.15
	world.staff_root.rotation.y=0.15
	focus=Vector3(10.5,0,-5)
	player.position=Vector3(9,0.2,-4.5)
	yaw=0.15
	pitch=0.25
	build_distance=10
	_update_camera(1,true)
	for frame in range(12): await get_tree().physics_frame
	hud.toast_time=0
	_update_pointer()
	_update_ui()
	await get_tree().process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://test-results/characters-v09-game.png")
	print("V09_CHARACTER_OK: continuous body skins, 20-bone humanoids, walking/watering regression, chicken gait pivots, game capture")

func _qa_mouse(at: Vector2, pressed: bool) -> void:
	get_viewport().warp_mouse(at)
	await get_tree().process_frame
	await get_tree().process_frame
	var event:=InputEventMouseButton.new()
	event.position=at
	event.global_position=at
	event.button_index=MOUSE_BUTTON_LEFT
	event.pressed=pressed
	Input.parse_input_event(event)
	await get_tree().process_frame
	await get_tree().process_frame

func _qa_painted_surfaces(node: Node) -> Dictionary:
	var found:Dictionary={}
	if node is MeshInstance3D:
		for surface in range(node.mesh.get_surface_count()):
			var source:Material=node.mesh.surface_get_material(surface)
			var replacement:Material=node.get_surface_override_material(surface)
			if source and replacement: found[source.resource_name]=replacement.albedo_color
	for child in node.get_children(): found.merge(_qa_painted_surfaces(child))
	return found

func _qa_v010() -> void:
	var previous:=state.serialize()
	state=FarmState.new();state.farm_xp=950
	state.claim(Vector2(4,-2))
	state.money=5000
	for entry in [["coop",Vector2(-4,-4)],["plot",Vector2(2,0)],["plot",Vector2(4,0)],["barn",Vector2(8,-8)],["workshop",Vector2(-4,4)]]:
		assert(state.place(entry[0],entry[1],0).is_empty())
	state.inventory.carrot=12
	state.hire_staff(0)
	world.rebuild(state)
	build_mode=true
	selected=3
	_action("barn")
	assert(hud.modal_kind=="barn")
	_action("deposit:carrot")
	assert(state.reserve.carrot==12 and state.inventory.carrot==0)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://test-results/barn-v010.png")
	_action("withdraw:carrot")
	assert(state.inventory.carrot==12)
	selected=4
	_action("barn")
	assert(hud.modal_kind=="workshop")
	var cash:=state.money
	_action("upgrade")
	assert(state.watering_upgrade and state.money==cash-300)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://test-results/workshop-v010.png")
	_action("irrigation")
	var checks:=hud.modal.find_children("*","CheckBox",true,false)
	assert(checks.size()==2)
	for check in checks: check.button_pressed=true
	assert(hud.irrigation_draft==[1,2])
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://test-results/irrigation-menu-v010.png")
	cash=state.money
	_action("irrigation_apply")
	assert(state.irrigation.enabled and state.money==cash)
	var frozen:=state.serialize()
	_process(10)
	assert(state.serialize()==frozen)
	_action("close")
	focus=Vector3(1,0,-1)
	yaw=0.2; pitch=0.55; build_distance=16
	_update_camera(1,true)
	var captured:=false
	for frame in range(1000):
		world.update_staff(state,1.0/60)
		if frame%20==0: await get_tree().process_frame
		if world.staff_actor.can.visible and not captured:
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://test-results/irrigation-v010.png")
			captured=true
		if state.irrigation.watered==2: break
	assert(captured and state.irrigation.watered==2 and state.money==cash-4)
	assert(state.items[1].watered and state.items[2].watered and state.staff.services==0)
	var snapshot:=state.serialize()
	for frame in range(120): world.update_staff(state,1.0/60)
	assert(state.serialize()==snapshot)
	_action("staff")
	_action("staff_pause")
	assert(state.staff.paused)
	_action("close")
	assert(state.restore(previous))
	world.rebuild(state)
	selected=1
	print("V010_INTEGRATION_OK: barn stock, workshop upgrade, checkbox selection, paused menus, walking irrigation, exact charge, no duplicate watering, pause")

func _qa_v011() -> void:
	var previous:=state.serialize()
	state=FarmState.new();state.farm_xp=950
	state.claim(Vector2(4,-2))
	state.money=10000
	for entry in [["barn",Vector2(8,-8)],["coop",Vector2(-4,-4)],["workshop",Vector2(-4,4)]]:
		assert(state.place(entry[0],entry[1],0).is_empty())
	world.rebuild(state)
	build_mode=true
	for i in range(3):
		selected=i
		var snapshot:=state.serialize()
		_action("evolution:%d"%i)
		assert(hud.modal_kind=="evolution")
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://test-results/evolution-confirm-v011.png")
		_action("building_back")
		assert(state.serialize()==snapshot)
		_action("evolution:%d"%i)
		_action("evolution_buy:%d"%i)
		assert(FarmProgression.level(state.items[i])==2)
		assert(world.item_nodes[i].get_node_or_null("Level2Details")!=null)
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://test-results/%s-menu-v011.png"%state.items[i].kind)
	assert(world.chickens.size()==6)
	selected=1
	_action("rename_hen:5")
	assert(hud.modal_kind=="hen_name")
	_action("close")
	selected=2
	_action("upgrade")
	_action("professional_watering")
	assert(state.professional_watering)
	_action("close")
	assert(not _try_jump(),"No jumping in construction")
	build_mode=false
	player.position=Vector3(4,0.2,7)
	player.velocity=Vector3.ZERO
	for frame in range(35): await get_tree().physics_frame
	assert(player.is_on_floor())
	_action("market")
	assert(not _try_jump(),"No jumping through menus")
	_action("close")
	actor.play("water")
	assert(not _try_jump(),"No jumping during work")
	actor.action_time=0
	var ground:=player.position.y
	var event:=InputEventKey.new()
	event.physical_keycode=KEY_SPACE
	event.keycode=KEY_SPACE
	event.pressed=true
	_unhandled_input(event)
	assert(player.velocity.y>6 and actor.airborne)
	var peak:=ground
	DirAccess.make_dir_recursive_absolute("res://test-results/jump-v011")
	for frame in range(80):
		await get_tree().physics_frame
		peak=maxf(peak,player.position.y)
		if frame==8: assert(not _try_jump(),"No double jump")
		if frame%4==0:
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://test-results/jump-v011/frame-%02d.png"%frame)
	assert(peak-ground>1.0 and peak-ground<1.5 and player.is_on_floor())
	assert(absf(player.position.y-ground)<0.05 and not actor.airborne)
	player.position=Vector3(8,6,-8)
	player.velocity=Vector3.ZERO
	for frame in range(100): await get_tree().physics_frame
	assert(player.is_on_floor() and player.position.y>4.3,"Roof supports the character above the visible barn")
	build_mode=true
	assert(state.restore(previous))
	world.rebuild(state)
	selected=1
	print("V011_INTEGRATION_OK: evolution preview/cancel/purchase, visual additions, six hens, sixth name, tool unlock, space jump, no double jump, menu/work gates, landing")

func _qa_crew() -> void:
	var previous:=state.serialize()
	state=FarmState.new();state.farm_xp=950
	state.claim(Vector2(4,-2))
	state.money=10000
	state.place("coop",Vector2(-4,-4),0)
	state.place("plot",Vector2(2,0),0)
	state.place("plot",Vector2(4,0),0)
	state.hire_staff(0)
	world.rebuild(state)
	build_mode=true
	_action("crew")
	assert(hud.modal_kind=="crew")
	var money:=state.money
	_action("crew_hire_review")
	assert(hud.modal_kind=="crew_confirm")
	_action("crew")
	assert(state.money==money and not state.field_staff.hired)
	_action("crew_hire_review")
	_action("crew_hire")
	assert(state.money==money-120 and world.field_root.visible and world.staff_root.visible)
	for kind in ["coop","field"]:
		_action("crew_train_review:"+kind)
		var snapshot:=state.serialize()
		_action("crew")
		assert(snapshot==state.serialize())
		_action("crew_train_review:"+kind)
		_action("crew_train:"+kind)
	assert(state.staff.level==2 and state.field_staff.level==2)
	_action("irrigation")
	var checks:=hud.modal.find_children("*","CheckBox",true,false)
	for check in checks: check.button_pressed=true
	_action("irrigation_apply")
	assert(hud.modal_kind=="crew" and not state.legacy_irrigation())
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://test-results/crew-menu-v011.png")
	var frozen:=state.serialize()
	_process(5)
	assert(state.serialize()==frozen)
	_action("close")
	focus=Vector3(0,0,-2)
	yaw=0.1; pitch=0.55; build_distance=17
	_update_camera(1,true)
	state.items[0].flock.nest=4
	money=state.money
	var captured:=false
	var field_start:=world.field_root.position
	var coop_start:=world.staff_root.position
	for frame in range(1800):
		state.tick(1.0/60)
		world.update_staff(state,1.0/60)
		if frame%20==0: await get_tree().process_frame
		if world.field_actor.can.visible and not captured:
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://test-results/crew-working-v011.png")
			captured=true
		if state.field_staff.watered==2 and state.staff.services==1: break
	assert(captured and state.field_staff.watered==2 and state.staff.services==1 and state.inventory.egg==4)
	assert(state.money==money-3,"Two trained regas and one trained coop service cost exactly three coins")
	assert(field_start.distance_to(world.field_root.position)>0.4 and coop_start.distance_to(world.staff_root.position)>0.4)
	_action("crew_pause")
	assert(state.field_staff.paused and not state.staff.paused)
	var stopped:=world.field_root.position
	for frame in range(100): world.update_staff(state,1.0/60)
	assert(world.field_root.position==stopped)
	_action("crew_dismiss_review")
	_action("crew")
	assert(state.field_staff.hired)
	_action("close")
	assert(state.restore(previous))
	world.rebuild(state)
	selected=1
	print("CREW_INTEGRATION_OK: hire and training confirmations, cancellation, two distinct workers moving concurrently, selected irrigation, coop collection, exact costs, independent pause, menus, persistence")

func _qa_v012() -> void:
	var previous:=state.serialize()
	state=FarmState.new();state.farm_xp=950
	state.claim(Vector2(4,-2)); state.money=10000
	state.place("coop",Vector2(-4,-4),0)
	state.place("plot",Vector2(2,0),0)
	state.place("plot",Vector2(4,0),0)
	assert(state.place("barn",Vector2(8,-8),0).is_empty())
	assert(state.place("workshop",Vector2(-4,4),0).is_empty())
	state.hire_staff(0); state.hire_field_staff()
	state.items[1].planted=true; state.items[1].growth=1.0
	world.rebuild(state); build_mode=true
	_action("cultivation")
	var checks:=hud.modal.find_children("*","CheckBox",true,false)
	for check in checks:
		if check.has_meta("plot") and int(check.get_meta("plot"))==1:
			check.button_pressed=true
			var choice:=check.get_parent().get_child(2) as OptionButton
			choice.select(1); choice.item_selected.emit(1)
	hud.cultivation_budget.get_line_edit().text="12"
	hud.cultivation_budget.get_line_edit().text_changed.emit("12")
	await get_tree().process_frame
	await get_tree().process_frame
	assert(hud.cultivation_draft.limit==12 and hud.cultivation_draft.plans[0].crop=="wheat")
	await _qa_ui_capture("routine-v012")
	var frozen:=state.serialize()
	_action("cultivation_review")
	assert(hud.modal_kind=="cultivation_confirm")
	await _qa_ui_capture("routine-confirm-v012")
	_action("cultivation_edit")
	assert(frozen==state.serialize())
	_action("cultivation_review"); _action("cultivation_apply")
	assert(state.cultivation.enabled and state.cultivation.limit==12)
	_process(5); assert(state.cultivation.spent==0)
	_action("close")
	focus=Vector3(1,0,0); yaw=0.1; pitch=0.55; build_distance=17
	_update_camera(1,true)
	var money:=state.money
	var captured:Array=[]
	for frame in range(3600):
		state.tick(1.0/60)
		world.update_staff(state,1.0/60)
		if frame%20==0: await get_tree().process_frame
		var motion=world.field_motion
		if motion.watering and world.field_actor.action_time<0.32 and motion.job_kind not in captured:
			captured.append(motion.job_kind)
			await _qa_ui_capture("bento-"+motion.job_kind+"-v012")
		if state.cultivation.actions.water==1: break
	assert(state.cultivation.actions=={"water":1,"harvest":1,"plant":1})
	assert(state.cultivation.spent==12 and state.money==money-12)
	assert(state.inventory.carrot==3 and state.items[1].crop=="wheat" and state.items[1].watered)
	assert(captured.size()==3 and state.items[2].crop=="carrot" and not state.items[2].watered)
	state.items[1].growth=1.0
	for frame in range(120): world.update_staff(state,1.0/60)
	assert(state.field_staff.paused and state.field_staff.reason=="budget" and not state.staff.paused)
	_action("cultivation_report")
	await _qa_ui_capture("routine-report-v012")
	_action("cultivation_renew_review"); _action("cultivation_report")
	assert(state.cultivation.spent==12)
	_action("cultivation_renew_review"); _action("cultivation_renew")
	assert(state.cultivation.spent==0 and state.cultivation.services==6 and state.cultivation.seeds==6)
	var restored:=FarmState.new()
	assert(restored.restore(JSON.parse_string(JSON.stringify(state.serialize()))) and restored.cultivation==state.cultivation)
	_action("crew"); await _qa_ui_capture("crew-v012")
	state.inventory={"carrot":12,"wheat":18,"corn":9,"egg":6}
	state.reserve={"carrot":0,"wheat":8,"corn":0,"egg":6}
	hud.barn(state,3); await _qa_ui_capture("barn-v012")
	state.items[0].flock.nest=12; state.items[0].flock.food=44; state.items[0].flock.water=33
	hud.coop(state,0,-1); await _qa_ui_capture("coop-v012")
	hud.workshop(state,4); await _qa_ui_capture("workshop-v012")
	hud.market(state); await _qa_ui_capture("market-v012")
	_action("market_orders"); await _qa_ui_capture("orders-v012")
	_action("close")
	assert(state.restore(previous)); world.rebuild(state); selected=1
	print("V012_INTEGRATION_OK: UI crop and budget inputs, review cancellation, animated harvest/replant/water, exact costs, independent budget pause, renewal, report, persistence, game menus")

func _qa_ui_capture(filename:String) -> void:
	if DisplayServer.get_name()=="headless": return
	hud.toast_time=0
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://test-results/"+filename+".png")

func _qa_v013() -> void:
	var previous:=state.serialize()
	state=FarmState.new();state.farm_xp=950; state.claim(Vector2(4,-2)); state.money=10000
	assert(state.place("barn",Vector2(8,-8),0).is_empty())
	assert(state.place("coop",Vector2(-4,-4),0).is_empty())
	assert(state.place("plot",Vector2(2,0),0).is_empty())
	world.rebuild(state)
	build_mode=false; _action("close"); selected=-1
	player.position=Vector3(2,0,1.6)
	actor.airborne=false; action_cooldown=0
	_update_ui()
	assert(hud.walking.root.visible and not hud.build_hud.visible)
	assert(hud.walking.interaction.text.contains("Regar") and not hud.walking.seed_panel.visible)
	var target:=_nearby_context()
	assert(target.index==2)
	hud.walking.interaction.pressed.emit()
	assert(state.items[2].watered)
	action_cooldown=0; _update_ui()
	assert(hud.walking.interaction.disabled and not hud.walking.interaction.text.begins_with("E"))
	state.items[2].growth=1.0; _update_ui()
	assert(hud.walking.interaction.text.contains("Colher"))
	hud.walking.interaction.pressed.emit()
	action_cooldown=0; _update_ui()
	assert(hud.walking.seed_panel.visible)
	hud.walking.seeds.wheat.pressed.emit()
	assert(crop=="wheat")
	_interact_nearest()
	assert(state.items[2].crop=="wheat")
	player.position=Vector3(8,0,-3.5); selected=-1
	_update_ui()
	assert(hud.walking.interaction.text=="E · Abrir celeiro")
	yaw=0.4; pitch=0.45; _update_camera(1,true)
	await _qa_ui_capture("walk-barn-v013")
	hud.walking.interaction.pressed.emit()
	assert(hud.modal_kind=="barn" and not hud.world_hud.visible)
	_action("close")
	_action("objectives")
	assert(hud.modal_kind=="objectives")
	var frozen:=state.serialize(); _process(5); assert(state.serialize()==frozen)
	await _qa_ui_capture("walk-objective-v013")
	_action("close")
	state.items[1].flock.nest=12; _update_ui()
	assert(hud.walking.attention.visible and hud.walking.attention.text.contains("Ninho"))
	hud.walking.attention.pressed.emit()
	assert(hud.modal_kind=="coop" and selected==1)
	_action("close")
	state.hire_field_staff(); state.field_staff.paused=true; state.field_staff.reason="budget"
	_update_ui()
	assert(hud.walking.attention.text.contains("Bento"))
	await _qa_ui_capture("walk-alert-v013")
	hud.walking.attention.pressed.emit()
	assert(hud.modal_kind=="crew")
	_action("close")
	player.position=Vector3(18,0,7); selected=-1; _update_ui()
	assert(not hud.walking.interaction.visible)
	_action("mode"); assert(hud.build_hud.visible and not hud.walking.root.visible)
	_action("mode"); assert(hud.walking.root.visible)
	assert(state.restore(previous)); world.rebuild(state); build_mode=true
	_update_ui()
	print("V013_INTEGRATION_OK: compact HUD, nearby exact target, water/harvest/seed actions, growing disabled, objectives pause, alert destinations, camera modes")

func _qa_v014() -> void:
	var previous:=state.serialize()
	state=FarmState.new();state.farm_xp=950; state.claim(Vector2(4,-2)); state.money=10000
	assert(state.place("corral",Vector2(4,0),0).is_empty())
	world.rebuild(state); build_mode=true; selected=0
	FarmDairyHUD.show(hud,state,0)
	var money:=state.money
	_action("dairy:review"); _action("dairy:back")
	assert(state.money==money and not state.items[0].dairy.owned)
	await _qa_ui_capture("corral-buy-v014")
	_action("dairy:review"); _action("dairy:buy")
	assert(state.items[0].dairy.owned and state.money==money-480 and world.cows.size()==1)
	var frozen:=state.serialize();_process(60);assert(state.serialize()==frozen)
	state.tick(60)
	_action("dairy:milk");assert(state.milk_stock==2)
	_action("milk_market")
	hud.milk_quantity.value=1;money=state.money
	_action("sell_milk");assert(state.milk_stock==1 and state.money==money+18)
	await _qa_ui_capture("milk-stock-v014")
	_action("close");state.tick(240)
	FarmDairyHUD.show(hud,state,0)
	await _qa_ui_capture("corral-menu-v014")
	_action("close");build_mode=true
	focus=Vector3(4,0,0);yaw=.5;pitch=.62;build_distance=14;_update_camera(1,true)
	hud.world_hud.visible=false
	feedback.visible=false; world.irrigation_feedback.visible=false
	for i in range(90):world.animate(1.0/60,player.position,state)
	await _qa_ui_capture("corral-world-v014")
	feedback.visible=true; world.irrigation_feedback.visible=true
	assert(world.cows[0].head and world.cows[0].tail)
	await get_tree().physics_frame
	var ray:=PhysicsRayQueryParameters3D.create(Vector3(1,4,1),Vector3(1,-1,1),1)
	var hit:=get_world_3d().direct_space_state.intersect_ray(ray)
	assert(not hit.is_empty() and hit.position.y<.2,"Corral interior has no invisible raised floor")
	build_mode=false;player.position=Vector3(4,0,4.0);_update_ui()
	assert(_nearby_context().text=="Cuidar da vaca")
	_interact_nearest();assert(hud.modal_kind=="dairy")
	var saved:=state.serialize();assert(state.restore(JSON.parse_string(JSON.stringify(saved))))
	assert(state.milk_stock==1 and state.items[0].dairy.milk==8)
	_action("close");assert(state.restore(previous));world.rebuild(state);build_mode=true;_update_ui()
	print("V014_INTEGRATION_OK: cow purchase/cancel, menu pause, milk collection/sale, real assets, nearby E, persistence")

func _qa_v015() -> void:
	var previous:=state.serialize()
	state=FarmState.new();state.farm_xp=950;state.claim(Vector2(4,-2));world.rebuild(state)
	build_mode=false;_action("close");player.position=Vector3(4,0.3,-2)
	player.velocity=Vector3.ZERO;actor.action_time=0;actor.airborne=false;actor.landing=0
	focus=Vector3(4,0,-2);yaw=0.0;pitch=.36;walk_distance=5.5;avatar.rotation.y=0
	for i in range(40): await get_tree().physics_frame
	_update_camera(1,true);_update_ui()
	var key:=InputEventKey.new();key.physical_keycode=KEY_B;key.keycode=KEY_B;key.unicode=98;key.pressed=true
	Input.parse_input_event(key);await get_tree().process_frame
	await get_tree().process_frame
	print("EMOTE_GATE ",session_started," ",build_mode," ",actor.airborne," ",actor.action_time," ",hud.modal_kind)
	assert(hud.modal_kind=="emotes")
	var frozen:=state.serialize();_process(5);assert(frozen==state.serialize())
	await _qa_ui_capture("emotes-wheel-v015")
	_action("emote:six_seven")
	assert(actor.emote_kind=="six_seven" and actor.action_time==0 and hud.modal_kind.is_empty())
	var stationary:=player.position
	DirAccess.make_dir_recursive_absolute("res://test-results/dances-v015")
	for dance in FarmEmotes.DANCES:
		assert(actor.emote(dance))
		var hand_low:=0.0;var hand_high:=0.0
		for frame in range(32):
			actor.animate(.05,false,false)
			var height:float=actor.skeleton.get_bone_global_pose(actor.bones["Hand.L"]).origin.y-actor.skeleton.get_bone_global_pose(actor.bones["Hand.R"]).origin.y
			hand_low=minf(hand_low,height);hand_high=maxf(hand_high,height)
			await get_tree().process_frame
			if DisplayServer.get_name()!="headless":
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png("res://test-results/dances-v015/%s-%02d.png"%[dance,frame])
		if dance=="six_seven":assert(hand_low< -.08 and hand_high>.08,"Six Seven alternates hand heights")
		assert(player.position.distance_to(stationary)<.05 and not actor.can.visible)
	actor.emote("six_seven")
	Input.action_press("forward");await get_tree().physics_frame;await get_tree().physics_frame
	Input.action_release("forward")
	assert(actor.emote_time==0 and player.velocity.length()>0)
	for i in range(5): await get_tree().physics_frame
	actor.emote("six_seven")
	assert(_try_jump() and actor.emote_time==0)
	assert(not actor.emote("victory"))
	for i in range(70): await get_tree().physics_frame
	actor.emote("victory");_action("market")
	assert(actor.emote_time==0 and hud.modal_kind=="market")
	_action("close")
	actor.play("water");assert(not actor.emote("six_seven"));actor.action_time=0
	actor.emote("six_seven");actor.animate(6.1,false,false);assert(actor.emote_time==0 and actor.root.position.y==0)
	var count:=actor.root.get_child_count()
	for reaction_key in FarmEmotes.REACTIONS: assert(actor.emote(reaction_key))
	assert(actor.root.get_child_count()==count and actor.reaction.visible)
	actor.emote("laugh");await _qa_ui_capture("emote-reaction-v015")
	actor.animate(3,false,false);assert(not actor.reaction.visible)
	actor.emote("six_seven");_interact_nearest();assert(actor.emote_time==0)
	build_mode=true;_action("emotes");assert(hud.modal_kind.is_empty())
	await _qa_cow_v015()
	assert(state.restore(previous));world.rebuild(state);_update_ui()
	print("V015_INTEGRATION_OK: B wheel, paused selection, four grounded dances including Six Seven, alternating hands, movement/jump/menu/interact cancellation, work and airborne gates, expiry, bounded reactions, no economy/save changes")

func _qa_cow_v015() -> void:
	state=FarmState.new();state.farm_xp=950;state.claim(Vector2(4,-2));state.money=5000
	assert(state.place("corral",Vector2(4,0),0).is_empty())
	assert(FarmDairy.care(state,0,"buy").is_empty())
	world.rebuild(state);build_mode=true;hud.close_modal()
	player.position=Vector3(4,0,7)
	focus=Vector3(4,0,0);yaw=-.85;pitch=.45;build_distance=12;_update_camera(1,true)
	hud.world_hud.visible=false;hud.build_hud.visible=false;hud.walking.root.visible=false
	feedback.visible=false;world.irrigation_feedback.visible=false
	var cow:Dictionary=world.cows[0]
	assert(cow.bones.has("CowNeck"))
	var mouth:MeshInstance3D=cow.node.find_child("Muzzle",true,false)
	var upright:float=mouth.to_global(mouth.get_aabb().get_center()).y
	var phases:Dictionary={};var distance:=0.0;var lowest:=upright
	var frozen:=state.serialize()
	DirAccess.make_dir_recursive_absolute("res://test-results/cow-v015")
	for frame in range(2400):
		var before:Vector3=cow.node.position
		world.animate(1.0/60,player.position,state)
		distance+=before.distance_to(cow.node.position)
		phases[cow.motion.phase]=true
		lowest=minf(lowest,mouth.to_global(mouth.get_aabb().get_center()).y)
		assert(cow.node.position.x>=-1.18 and cow.node.position.x<=.48)
		assert(cow.node.position.z>=-.01 and cow.node.position.z<=.43)
		# 1.72 m covers the cow's full turn, leaving fences and relocated fixtures clear.
		assert(cow.node.position.x-1.72> -3.61 and cow.node.position.x+1.72<2.325)
		assert(cow.node.position.z-1.72> -1.71 and cow.node.position.z+1.72<2.61)
		if frame%30==0 and DisplayServer.get_name()!="headless":
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://test-results/cow-v015/%03d.png"%(frame/30))
	assert(distance>3.0 and phases.has_all(["walk","rest","graze"]))
	print("COW_HEIGHT ",upright," -> ",lowest)
	assert(lowest<upright-.65 and lowest>.08,"Muzzle lowers toward grass and stays above ground")
	assert(state.serialize()==frozen,"Visual grazing does not create feed or milk")
	cow.motion.phase="walk";cow.motion.graze=0
	var stopped:Transform3D=cow.node.transform
	for i in range(120):world.animate(1.0/60,cow.node.global_position,state)
	assert(cow.node.transform.is_equal_approx(stopped),"Wait for farmer instead of pushing")
	var pose:Transform3D=cow.bones.CowNeck.node.transform
	world.animate(0,player.position,state)
	assert(cow.node.transform.is_equal_approx(stopped) and cow.bones.CowNeck.node.transform.is_equal_approx(pose))
	print("COW_V015_OK: walk/graze/rest, safe turn envelope, lowered muzzle, player obstruction, zero-delta pause, unchanged economy; distance=",distance," muzzle=",lowest)
	feedback.visible=true;world.irrigation_feedback.visible=true

func _qa_v016() -> void:
	var previous:=state.serialize()
	state=FarmState.new();state.farm_xp=950;state.claim(Vector2(4,-2));state.money=5000;state.milk_stock=8
	world.rebuild(state);build_mode=true;_action("close")
	var key:=InputEventKey.new();key.keycode=KEY_G;key.physical_keycode=KEY_G;key.pressed=true
	Input.parse_input_event(key);await get_tree().process_frame;await get_tree().process_frame
	assert(tool=="cheesery")
	turn=0;pointer=Vector2(4,0);pointer_valid=true;_click_world()
	assert(state.items.size()==1 and state.items[0].kind=="cheesery" and state.money==4100)
	_update_ui();await _qa_ui_capture("cheesery-build-v016")
	selected=0;build_mode=false;player.position=Vector3(4,0,4.2);_update_ui()
	assert(_nearby_context().text=="Fazer queijo")
	_interact_nearest();assert(hud.modal_kind=="cheesery")
	var q:SpinBox=hud.modal.find_children("*","SpinBox",true,false)[0]
	q.value=4
	_action("cheese:review");assert(state.milk_stock==8 and hud.modal_kind=="cheese_confirm")
	await _qa_ui_capture("cheese-confirm-v016")
	_action("cheese:back");assert(state.milk_stock==8)
	q=hud.modal.find_children("*","SpinBox",true,false)[0];q.value=4
	_action("cheese:review");_action("cheese:start")
	assert(state.milk_stock==0 and state.items[0].cheese.batch==4)
	_action("cheese:start");assert(state.items[0].cheese.batch==4)
	var frozen:=state.serialize();_process(30);assert(state.serialize()==frozen)
	_action("close");build_mode=true;_process(30);assert(state.serialize()==frozen)
	state.tick(45);FarmCheeseHUD.show(hud,state,0)
	await _qa_ui_capture("cheese-progress-v016")
	var disk:Variant=JSON.parse_string(JSON.stringify(state.serialize()))
	assert(state.restore(disk) and state.items[0].cheese.remaining==45)
	state.tick(45);_action("close");build_mode=false;_update_ui()
	assert(hud.walking.attention.visible and hud.walking.attention.text.begins_with("Queijo pronto"))
	_action("field_attention");assert(hud.modal_kind=="cheesery")
	await _qa_ui_capture("cheese-ready-v016")
	_action("cheese:collect");_action("cheese:collect");assert(state.cheese_stock==4)
	_action("market");_action("cheese_shop");assert(hud.modal_kind=="dairy_shop")
	await _qa_ui_capture("cheese-shop-v016")
	_action("cheese_market");hud.cheese_quantity.value=1
	var money:=state.money;_action("cheese:sell")
	assert(state.money==money+52 and state.cheese_stock==3)
	_action("cheese_orders");_action("cheese:accept")
	await _qa_ui_capture("cheese-order-v016")
	assert(state.cheese_order.active)
	_action("cheese:cancel");assert(not state.cheese_order.active and state.cheese_stock==3)
	_action("cheese:accept");_action("cheese:deliver")
	assert(state.money==money+244 and state.cheese_stock==0 and state.trade.nena.reputation==1)
	_action("cheese:deliver");assert(state.money==money+244)
	_action("close");build_mode=true;focus=Vector3(4,0,0);yaw=.55;pitch=.48;build_distance=14
	_update_camera(1,true);hud.world_hud.visible=false;hud.build_hud.visible=false;hud.walking.root.visible=false
	await _qa_ui_capture("cheesery-world-v016")
	assert(state.restore(previous));world.rebuild(state);build_mode=true;_update_ui()
	print("V016_INTEGRATION_OK: G placement, E entrance, quantity/review/cancel/start, no duplicate input/collection/payment, menu/build pause, saved batch, partial sale, cheese orders, Blender model")

func _qa_v017() -> void:
	var previous:=state.serialize()
	state=FarmState.new();state.farm_xp=950;state.claim(Vector2(4,-2));state.money=5000;state.milk_stock=16
	assert(state.place("cheesery",Vector2(4,0),0).is_empty())
	world.rebuild(state);build_mode=true;_action("close");selected=0;tool="inspect";move_index=-1;ghost.visible=false
	_action("chico");_action("chico:review_hire")
	var money:=state.money
	_action("chico");assert(state.money==money and not state.cheese_worker.hired)
	_action("chico:review_hire");_action("chico:confirm")
	assert(state.cheese_worker.hired and state.money==money-160)
	var controls:=hud.modal.find_children("*","SpinBox",true,false)
	controls[0].value=2;controls[1].value=8
	_action("chico:review_apply");await _qa_ui_capture("chico-confirm-v017")
	_action("chico:confirm");assert(state.cheese_worker.site==0 and state.cheese_worker.budget==8 and state.cheese_worker.batch_size==2)
	await _qa_ui_capture("chico-manager-v017")
	var frozen:=state.serialize();_process(20);assert(state.serialize()==frozen)
	_action("close");_process(20);assert(state.serialize()==frozen)
	focus=Vector3(4,1,2.8);yaw=-.65;pitch=.35;build_distance=10;_update_camera(1,true)
	player.position=Vector3(15,0,10);hud.world_hud.visible=false;hud.build_hud.visible=false;hud.walking.root.visible=false
	DirAccess.make_dir_recursive_absolute("res://test-results/chico-v017")
	var phases:Dictionary={};var walked:=0.0
	for frame in range(2600):
		var before:Vector3=world.chico_motion.node.position
		state.tick(.1);world.update_staff(state,.1)
		walked+=before.distance_to(world.chico_motion.node.position)
		phases[world.chico_motion.phase]=true
		assert(world.chico_motion.route.walkable(world.chico_motion.node.position,state))
		if frame%5==0 and (frame<120 or (frame>930 and frame<1080)) and DisplayServer.get_name()!="headless":
			await get_tree().process_frame;await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://test-results/chico-v017/%04d.png"%frame)
	var w:=state.cheese_worker
	assert(w.started==2 and w.collected==4 and w.spent==8 and w.total_spent==8 and state.milk_stock==8 and state.cheese_stock==4)
	assert(w.paused and w.reason=="budget" and walked>8 and phases.has_all(["bring","mix","store","put"]))
	var held:=state.serialize();world.update_staff(state,30);assert(state.serialize()==held)
	_action("chico");await _qa_ui_capture("chico-budget-v017")
	_action("chico:review_apply");_action("chico:confirm");FarmCheeseWorker.job(state);assert(w.spent==8 and w.paused)
	_action("chico:review_renew");_action("chico");assert(w.spent==8)
	_action("chico:review_renew");_action("chico:confirm");assert(w.spent==0 and w.total_spent==8)
	_action("close");world.update_staff(state,.1)
	w.paused=true;w.reason="manual";var milk:=state.milk_stock;money=state.money
	for i in range(50):world.update_staff(state,.1)
	assert(state.milk_stock==milk and state.money==money)
	assert(state.place("fence",Vector2(2,4),0).is_empty());world.rebuild(state);w.paused=false;w.reason=""
	for i in range(50):world.update_staff(state,.1)
	assert(w.paused and w.reason=="blocked" and state.milk_stock==milk and w.spent==0)
	assert(state.remove_item(1).is_empty());world.rebuild(state)
	_action("chico");_action("chico:pause")
	for i in range(200):world.update_staff(state,.1)
	assert(w.started==3 and w.spent==4 and state.milk_stock==4)
	var disk:Variant=JSON.parse_string(JSON.stringify(state.serialize()))
	assert(state.restore(disk) and state.cheese_worker.started==3 and state.items[0].cheese.batch==2)
	_action("chico");_action("chico:review_dismiss");_action("chico:confirm")
	assert(not state.cheese_worker.hired and state.items[0].cheese.batch==2)
	assert(state.restore(previous));world.rebuild(state);build_mode=true;_update_ui()
	print("V017_INTEGRATION_OK: hire/cancel, draft quantity/budget, animated routes and props, exact fees, free collection, cap, renewal/cancel, manual pause, blocked path/resume, persistence and dismissal; walked=",walked)

func _qa_v018() -> void:
	var previous:=state.serialize()
	state=FarmState.new();state.farm_xp=950;state.claim(Vector2(4,-2));state.money=10000
	assert(state.place("corral",Vector2(4,0),0).is_empty())
	assert(state.place("cheesery",Vector2(-4,0),0).is_empty())
	assert(FarmDairy.care(state,0,"buy").is_empty())
	state.items[0].dairy.milk=4
	world.rebuild(state);build_mode=true;_action("close");selected=0;tool="inspect";move_index=-1;ghost.visible=false
	_action("raul");_action("raul:review_hire");var money:=state.money
	_action("raul");assert(state.money==money and not state.dairy_worker.hired)
	_action("raul:review_hire");_action("raul:confirm")
	assert(state.dairy_worker.hired and state.money==money-140)
	var controls:=hud.modal.find_children("*","SpinBox",true,false);controls[0].value=60
	_action("raul:review_apply");await _qa_ui_capture("raul-confirm-v018")
	_action("raul:confirm");assert(state.dairy_worker.site==0 and state.dairy_worker.budget==60)
	await _qa_ui_capture("raul-manager-v018")
	var frozen:=state.serialize();_process(20);assert(state.serialize()==frozen)
	_action("close");_process(20);assert(state.serialize()==frozen)
	FarmCheeseWorker.hire(state);FarmCheeseWorker.configure(state,1,2,40)
	focus=Vector3(4,.8,0);yaw=.80;pitch=.47;build_distance=9;_update_camera(1,true)
	player.position=Vector3(15,0,10);hud.world_hud.visible=false;hud.build_hud.visible=false;hud.walking.root.visible=false
	DirAccess.make_dir_recursive_absolute("res://test-results/raul-v018")
	var phases:Dictionary={};var tasks:Dictionary={};var captured:=0;var walked:=0.0
	for frame in range(7000):
		var before:Vector3=world.raul_motion.node.position
		state.tick(.1);world.update_staff(state,.1);world.animate(.1,player.position,state)
		var motion:=world.raul_motion
		walked+=before.distance_to(motion.node.position);phases[motion.phase]=true
		if motion.phase=="work":tasks[motion.kind]=true
		assert(not state.dairy_worker.paused,"Unexpected pause: "+state.dairy_worker.reason)
		if motion.inside(state.items[0]):
			assert(motion.safe(motion.node.position,state,0),"Worker must stay in clear aisle")
			assert(world.cows[0].dock_ready,"Cow must hold for interior access")
		if frame%5==0 and (frame<230 or (motion.phase=="work" and motion.kind!="milk" and not tasks.has("captured_"+motion.kind))) and DisplayServer.get_name()!="headless":
			await get_tree().process_frame;await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://test-results/raul-v018/%04d.png"%frame);captured+=1
			if motion.phase=="work" and motion.kind!="milk" and motion.work_time<1.5:tasks["captured_"+motion.kind]=true
	assert(phases.has_all(["wait","enter","work","exit"]) and tasks.has_all(["milk","water","food"]) and walked>20)
	assert(state.cheese_stock>0 and state.cheese_worker.started>0 and state.dairy_worker.collected>=8,"Cow to cheese chain")
	assert(state.dairy_worker.spent==state.dairy_worker.total_spent and state.dairy_worker.spent<=60)
	print("V018_CHAIN: milk=",state.dairy_worker.collected," cheese=",state.cheese_stock," cost=",state.dairy_worker.spent," tasks=",tasks)
	_action("raul");await _qa_ui_capture("raul-report-v018")
	var spent:int=state.dairy_worker.spent
	_action("raul:review_apply");_action("raul:confirm");assert(state.dairy_worker.spent==spent)
	_action("raul:review_renew");_action("raul");assert(state.dairy_worker.spent==spent)
	_action("raul:review_renew");_action("raul:confirm");assert(state.dairy_worker.spent==0)
	_action("close");state.dairy_worker.paused=true;state.dairy_worker.reason="manual"
	var held:=state.serialize()
	for i in range(100):world.raul_motion.update(world,state,.1);world.animate(.1,player.position,state)
	assert(state.serialize()==held,"Pause must not spend or transfer milk")
	var saved:Variant=JSON.parse_string(JSON.stringify(state.serialize()))
	assert(state.restore(saved) and state.dairy_worker.spent==0)
	_action("raul");_action("raul:review_dismiss");_action("raul:confirm");assert(not state.dairy_worker.hired)
	# Rotated pens, interrupted milking and obstruction must preserve the ledger.
	for turn in range(4):
		state=FarmState.new();state.farm_xp=950;state.claim(Vector2(4,-2));state.money=5000
		assert(state.place("corral",Vector2(4,0),turn).is_empty())
		FarmDairy.care(state,0,"buy");state.items[0].dairy.milk=4
		FarmDairyWorker.hire(state);FarmDairyWorker.configure(state,0,20)
		world.rebuild(state)
		var interrupted:=false
		for frame in range(700):
			world.update_staff(state,.1);world.animate(.1,player.position,state)
			if world.raul_motion.phase=="work" and not interrupted:
				assert(state.dairy_worker.spent==0 and state.milk_stock==0)
				state.dairy_worker.paused=true;state.dairy_worker.reason="manual";interrupted=true
			if frame==300:
				assert(state.dairy_worker.spent==0 and state.milk_stock==0 and not world.raul_motion.inside(state.items[0]))
				state.dairy_worker.paused=false;state.dairy_worker.reason=""
		assert(interrupted and state.dairy_worker.spent==2 and state.milk_stock==4)
		assert(not world.raul_motion.inside(state.items[0]) and not world.cows[0].gate_collision.disabled)
	# A fence across the entrance prevents billing and emits an actionable pause.
	state=FarmState.new();state.farm_xp=950;state.claim(Vector2(4,-2));state.money=5000
	state.place("corral",Vector2(4,0),0);FarmDairy.care(state,0,"buy");state.items[0].dairy.milk=4
	FarmDairyWorker.hire(state);FarmDairyWorker.configure(state,0,20)
	assert(state.place("fence",Vector2(4,4),0).is_empty());world.rebuild(state)
	for frame in range(40):world.update_staff(state,.1);world.animate(.1,player.position,state)
	assert(state.dairy_worker.paused and state.dairy_worker.reason=="blocked" and state.dairy_worker.spent==0 and state.milk_stock==0)
	state.remove_item(1);world.rebuild(state);state.dairy_worker.paused=false;state.dairy_worker.reason=""
	for frame in range(500):world.update_staff(state,.1);world.animate(.1,player.position,state)
	assert(state.dairy_worker.spent==2 and state.milk_stock==4)
	assert(state.restore(previous));world.rebuild(state);build_mode=true;_update_ui()
	print("V018_INTEGRATION_OK: UI hire/cancel, budget, gate, cow docking, paths, milking/water/feed, milk-to-cheese, pause, renewal and persistence; walked=",walked)

func _qa_v019() -> void:
	var previous:=state.serialize()
	state=FarmState.new();state.claim(Vector2(4,-2));world.rebuild(state)
	hud.close_modal();build_mode=true;selected=-1;tool="inspect";_update_ui()
	assert(state.farm_xp==0 and "Nível 2" in hud.buttons.coop.text)
	var funds:=state.money
	_action("tool:corral")
	assert(hud.modal_kind=="farm_levels" and tool=="inspect" and state.money==funds)
	await _qa_ui_capture("levels-v019-locked")
	_action("close")
	for pos in [Vector2(2,0),Vector2(4,0),Vector2(6,0)]:
		assert(state.place("plot",pos,0).is_empty())
	for i in range(3):state.tend(i)
	state.tick(32)
	for i in range(3):state.tend(i)
	assert(state.farm_xp==30 and FarmLevels.level(state.farm_xp)==2)
	world.rebuild(state);_update_ui()
	_action("tool:coop")
	assert(hud.modal_kind.is_empty() and tool=="coop" and "Nível 2" not in hud.buttons.coop.text)
	assert(state.place("coop",Vector2(10,-6),0).is_empty())
	world.rebuild(state);_update_ui()
	await _qa_ui_capture("levels-v019-build")
	build_mode=false;player.position=Vector3(4,0,5);focus=player.position;_update_camera(0,true);_update_ui()
	assert(hud.walking.farm_levels.root.visible)
	await _qa_ui_capture("levels-v019-walk")
	_action("farm_levels");assert(hud.modal_kind=="farm_levels")
	await _qa_ui_capture("levels-v019-unlocked")
	_action("close")
	assert(_save_game(false))
	state.farm_xp=0
	assert(_load_game() and state.farm_xp==30)
	assert(state.level_notice.is_empty())
	assert(state.restore(previous));world.rebuild(state);build_mode=true;_update_ui()
	print("V019_INTEGRATION_OK: new farm, locked action, first unlock, HUD, progression screen and disk XP persistence")

func _qa_v020() -> void:
	var previous:=state.serialize()
	hud.close_modal();state=FarmState.new();state.claim(Vector2(4,-2));state.money=10000;state.farm_xp=950;state.land_size=40
	for entry in [["barn",Vector2(-6,-8)],["coop",Vector2(10,-8)],["workshop",Vector2(-6,4)],["corral",Vector2(10,6)],["cheesery",Vector2(-6,12)]]:
		assert(state.place(entry[0],entry[1],0).is_empty())
	FarmDairy.care(state,3,"buy")
	for z in [-2,0,2]:
		for x in [0,2,4]:
			assert(state.place("plot",Vector2(x,z),0,["carrot","wheat","corn"][int(x/2)]).is_empty())
			state.items[-1].growth=.8;state.items[-1].watered=true
	world.rebuild(state);build_mode=true;selected=-1;tool="inspect"
	focus=Vector3(4,0,0);yaw=.55;pitch=.67;build_distance=64;_update_camera(0,true);_update_ui()
	await _qa_ui_capture("valley-v020-overview")
	var meadow_started:=Time.get_ticks_msec()
	for repetition in range(10):world.landscape.refresh(state)
	assert(world.landscape.meadow.get_child_count()>=3)
	print("V020_MEADOW_REFRESH: ten rebuilds ms=",Time.get_ticks_msec()-meadow_started)
	# Explicit triangle-floor checks in the larger walking area.
	await get_tree().physics_frame
	for p in [Vector2(0,0),Vector2(60,30),Vector2(2,-55),Vector2(20,60)]:
		var query:=PhysicsRayQueryParameters3D.create(Vector3(p.x,8,p.y),Vector3(p.x,-2,p.y))
		var hit:=get_world_3d().direct_space_state.intersect_ray(query)
		assert(not hit.is_empty() and absf(hit.position.y-FarmLandscape.height_at(p))<.1)
	for p in world.landscape.trunk_points:assert(not state.bounds().grow(.6).has_point(p))
	for patch in world.landscape.meadow.get_children():
		for i in range(patch.multimesh.instance_count):
			var pos:Vector3=patch.multimesh.get_instance_transform(i).origin
			for item in state.items:assert(not state.item_rect(item.kind,Vector2(item.x,item.z),item.turn).grow(.64).has_point(Vector2(pos.x,pos.z)))
	build_mode=false;player.position=Vector3(7,.1,17);yaw=.25;pitch=.27;walk_distance=9;_update_camera(0,true);_update_ui()
	await _qa_ui_capture("valley-v020-farm")
	player.position=Vector3(-33,.1,1);yaw=1.5;pitch=.32;walk_distance=8;_update_camera(0,true)
	await _qa_ui_capture("valley-v020-river")
	player.position=Vector3(57,FarmLandscape.height_at(Vector2(57,30))+.1,30);yaw=.45;pitch=.25;walk_distance=8;_update_camera(0,true)
	await _qa_ui_capture("valley-v020-grove")
	_ensure_player_space()
	assert(player.position.x>44 and player.position.y>=FarmLandscape.height_at(Vector2(player.position.x,player.position.z)))
	var start:=player.position;Input.action_press("forward")
	for frame in range(45):await get_tree().physics_frame
	Input.action_release("forward")
	assert(player.position.distance_to(start)>1 and player.position.x>44 and player.position.y>-.1)
	var started:=Time.get_ticks_msec()
	for frame in range(90):await get_tree().process_frame
	print("V020_RENDER_SAMPLE: 90 frames ms=",Time.get_ticks_msec()-started," draw_calls=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	assert(state.restore(previous));world.rebuild(state);build_mode=true;_update_ui()
	print("V020_LANDSCAPE_OK: continuous floor, expanded walking, protected land, vegetation clearance, four rendered views")

func _qa_v021() -> void:
	var previous:=state.serialize()
	hud.close_modal();state=FarmState.new();state.farm_xp=950;state.unlimited_money=true;world.rebuild(state)
	var wild:=world.landscape.nature.get_child_count()
	state.claim(Vector2(4,-2));world.update_border(state)
	assert(world.landscape.nature.get_child_count()<wild)
	var trees:=world.landscape.trunk_points.size()
	assert(state.expand().is_empty());world.update_border(state)
	assert(world.landscape.trunk_points.size()<trees)
	for p in world.landscape.trunk_points:assert(not state.bounds().grow(.65).has_point(p))
	build_mode=false;player.position=Vector3(22,.1,17);yaw=.6;pitch=.28;walk_distance=10;_update_camera(0,true);_update_ui()
	assert(hud.walking.wallet.text=="$ ∞")
	await _qa_ui_capture("valley-v021-clearing")
	_action("parcels");assert(hud.modal_kind=="parcels")
	await _qa_ui_capture("valley-v021-parcels")
	_action("parcel_buy:east");assert("east" in state.owned_parcels)
	_action("close")
	assert(state.place("coop",FarmParcels.LOTS.east.center,0).is_empty())
	world.rebuild(state);state.hire_staff(0);state.items[0].flock.nest=4;world.rebuild(state)
	for i in range(600):state.tick(.1);world.update_staff(state,.1);world.animate(.1,player.position,state)
	assert(state.staff.eggs>=4 and state.inventory.egg>=4)
	player.position=Vector3(58,.1,4);yaw=.3;pitch=.35;walk_distance=12;_update_camera(0,true);_update_ui()
	await _qa_ui_capture("valley-v021-owned")
	assert(_save_game(false));state=FarmState.new();assert(_load_game())
	assert(state.unlimited_money and "east" in state.owned_parcels and state.items.size()==1)
	world.rebuild(state)
	assert(not world.landscape.birds.is_empty())
	build_mode=true;_update_ui();hud.world_hud.visible=false;set_physics_process(false)
	var bird:Dictionary=world.landscape.birds[0]
	var outward:Vector3=bird.node.global_position-bird.node.get_parent().global_position;outward.y=0
	camera.position=bird.node.global_position+outward.normalized()*3.2+Vector3.UP*.8;camera.look_at(bird.node.global_position)
	await _qa_ui_capture("valley-v021-bird")
	camera.position=Vector3(-34,1.6,8);camera.look_at(Vector3(-41,-.15,2))
	await _qa_ui_capture("valley-v0211-bank-close")
	camera.position=Vector3(-49,1.6,-25);camera.look_at(Vector3(-42,-.15,-30))
	await _qa_ui_capture("valley-v0211-bank-opposite")
	# Fixed camera and deterministic advection times show downstream flow clearly.
	camera.position=Vector3(-31,7,8);camera.look_at(Vector3(-42,0,0));world.landscape.set_process(false)
	for i in range(16):
		world.landscape.water_material.set_shader_parameter("flow_time",i*.18)
		await _qa_ui_capture("valley-v021-flow-%02d"%i)
	world.landscape.set_process(true);hud.world_hud.visible=true;set_physics_process(true)
	assert(state.restore(previous));world.rebuild(state);build_mode=true;_update_ui()
	print("V021_INTEGRATION_OK: claim/expansion clearing, parcels UI, remote coop worker, infinite money, reload, birds and flowing river")

func _qa_v022() -> void:
	state=FarmState.new();state.claim(Vector2(4,-2));state.unlimited_money=true
	world.rebuild(state);hud.close_modal();build_mode=false;set_physics_process(false)
	assert(world.landscape.trail_signs.size()>=9)
	var journey:=FarmTrails.new()
	for key in FarmTrails.STOPS:
		var stop:Dictionary=FarmTrails.STOPS[key]
		assert(not journey.discover(stop.at).is_empty())
		assert(journey.discover(stop.at).is_empty())
		for p in world.landscape.trunk_points:assert(p.distance_to(stop.at)>float(stop.radius))
	# Walk every route using the player's actual collision shape and terrain.
	for route_points in FarmTrails.ROUTES:
		var start:Vector2=route_points[0]
		player.position=Vector3(start.x,FarmLandscape.height_at(start)+.1,start.y)
		for i in range(1,route_points.size()):
			var finish:Vector2=route_points[i]
			for step in range(1200):
				var delta_2d:=finish-Vector2(player.position.x,player.position.z)
				if delta_2d.length()<.18:break
				var speed:=minf(7.5,delta_2d.length()*60)
				player.velocity=Vector3(delta_2d.normalized().x*speed,player.velocity.y-18.0/60,delta_2d.normalized().y*speed)
				player.move_and_slide()
				await get_tree().physics_frame
			assert(Vector2(player.position.x,player.position.z).distance_to(finish)<.25,"Trail blocked")
	assert(_save_game(false));assert(_load_game());assert(state.unlimited_money)
	hud.world_hud.visible=false;avatar.visible=false
	var views:=[
		[Vector3(-19,10,-68),Vector3(-10,3,-84),"mill"],
		[Vector3(66,6,47),Vector3(59,1,38),"picnic"],
		[Vector3(32,5,78),Vector3(39,1,84),"cart"],
		[Vector3(-18,4,-58),Vector3(-3,1,-55),"junction"]
	]
	for view in views:
		var at:Vector3=view[0];at.y+=FarmLandscape.height_at(Vector2(at.x,at.z))
		var target:Vector3=view[1];target.y+=FarmLandscape.height_at(Vector2(target.x,target.z))
		camera.position=at;camera.look_at(target)
		await _qa_ui_capture("valley-v022-"+view[2])
	var before:float=world.landscape.trail_rotor.rotation.z
	await get_tree().create_timer(.2).timeout
	assert(absf(world.landscape.trail_rotor.rotation.z-before)>.01)
	print("V022_INTEGRATION_OK: 6 routes walked with player collision; 9 signs, 3 discoveries, animated mill, infinite wallet and isolated save reload")

func _horse_interact() -> void:
	if network.active:
		network.mounts.request("dismount" if _mounted() else "mount");return
	if not session_started or build_mode or not hud.modal_kind.is_empty():return
	if horse.mounted:
		if not horse.dismount(player,avatar,actor,state,world.landscape):hud.toast("Procure espaço livre ao lado do cavalo.")
	elif horse.can_mount(player) and actor.action_time<=0:
		weapons.holster()
		horse.mount(player,avatar,actor);hud.toast("WASD cavalgar · Shift dá um tapinha para galopar · E desmontar")
	_update_ui()

func _qa_v023() -> void:
	state=FarmState.new();state.claim(Vector2(4,-2));state.unlimited_money=true
	world.rebuild(state);hud.close_modal();build_mode=false
	horse.restore(FarmHorse.defaults());player.position=horse.position+Vector3(1.8,.1,0)
	for i in range(60):await get_tree().physics_frame
	assert(horse.can_mount(player));_horse_interact();assert(horse.mounted)
	set_physics_process(false)
	assert(not _try_jump());_action("emotes");assert(hud.modal_kind.is_empty())
	assert(horse.encourage());assert(horse.stamina==75 and horse.pat_time>0)
	assert(not horse.encourage())
	for i in range(12):
		horse.drive(player,avatar,actor,Vector3.FORWARD*-1,1.0/60,true)
		await get_tree().physics_frame
	hud.world_hud.visible=false
	camera.position=horse.position+Vector3(5,3.8,6);camera.look_at(horse.position+Vector3(0,1.8,0))
	await _qa_ui_capture("horse-v023-mounted")
	var paused_pos:=player.position;var paused_stamina:=horse.stamina;var paused_burst:=horse.burst
	for i in range(10):horse.drive(player,avatar,actor,Vector3.ZERO,1.0/60,false);await get_tree().physics_frame
	assert(player.position.distance_to(paused_pos)<.1 and horse.stamina==paused_stamina and horse.burst==paused_burst)
	# Full circuit with the real mounted collision shape, including long curves.
	var route_points:Array=FarmTrails.ROUTES[6]
	var start:Vector2=route_points[0];player.position=Vector3(start.x,FarmLandscape.height_at(start)+.08,start.y)
	var travelled:=0.0
	for i in range(1,route_points.size()):
		var finish:Vector2=route_points[i]
		horse.heading=atan2(finish.x-player.position.x,finish.y-player.position.z)
		for step in range(2400):
			var offset:=finish-Vector2(player.position.x,player.position.z)
			if offset.length()<.6:break
			if offset.length()<3:horse.burst=0;horse.speed=minf(horse.speed,3)
			elif horse.burst<=0 and horse.stamina>=25:horse.encourage()
			var old:=player.position
			horse.drive(player,avatar,actor,Vector3(offset.x,0,offset.y).normalized(),1.0/60,true)
			travelled+=player.position.distance_to(old)
			await get_tree().physics_frame
		assert(Vector2(player.position.x,player.position.z).distance_to(finish)<.7,"Mounted route blocked at "+str(finish))
	horse.store(state);assert(_save_game(false))
	var saved_horse:=state.horse.duplicate();assert(_load_game())
	for key in saved_horse:assert(is_equal_approx(float(state.horse[key]),float(saved_horse[key])))
	assert(horse.dismount(player,avatar,actor,state,world.landscape))
	assert(not horse.mounted and avatar.position==Vector3.ZERO)
	camera.position=horse.position+Vector3(5,3,6);camera.look_at(horse.position+Vector3(0,1.5,0))
	await _qa_ui_capture("horse-v023-parked")
	# A blocked exit must keep the rider mounted rather than teleport through walls.
	horse.mount(player,avatar,actor)
	var cage:=StaticBody3D.new();var collision:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(12,5,12);collision.shape=box;cage.add_child(collision);cage.position=horse.position+Vector3.UP*2;add_child(cage)
	await get_tree().physics_frame
	assert(not horse.dismount(player,avatar,actor,state,world.landscape) and horse.mounted)
	cage.free();await get_tree().physics_frame
	assert(horse.dismount(player,avatar,actor,state,world.landscape))
	avatar.visible=false
	for view in [[Vector3(111,8,-98),Vector3(100,1,-77),"orchard"],[Vector3(139,8,63),Vector3(153,1,75),"stones"],[Vector3(75,8,105),Vector3(77,1,122),"flowers"]]:
		var from:Vector3=view[0];from.y+=FarmLandscape.height_at(Vector2(from.x,from.z))
		var target:Vector3=view[1];target.y+=FarmLandscape.height_at(Vector2(target.x,target.z))
		camera.position=from;camera.look_at(target);await _qa_ui_capture("horse-v023-"+view[2])
	print("V023_INTEGRATION_OK: mount, tap boost, stamina, pause, blocked dismount, real circuit riding, save reload and expanded environments; distance=",travelled)

func _qa_horse_preview() -> void:
	state=FarmState.new();state.claim(Vector2(4,-2));state.unlimited_money=true;world.rebuild(state)
	horse.restore(FarmHorse.defaults());hud.close_modal();build_mode=false;player.position=horse.position+Vector3(1.8,.1,0)
	for i in range(60):await get_tree().physics_frame
	_horse_interact();assert(horse.mounted);set_physics_process(false)
	player.position=Vector3(0,FarmLandscape.height_at(Vector2(0,30))+.05,30);horse.position=player.position;horse.heading=PI/2
	for i in range(24):
		if i==4:assert(horse.encourage())
		horse.drive(player,avatar,actor,Vector3(1,0,0),.07,true)
		camera.position=horse.position+Vector3(5,2.8,6);camera.look_at(horse.position+Vector3(0,1.8,0))
		hud.world_hud.visible=i==0;_update_ui()
		await _qa_ui_capture("horse-v023-ride-%02d"%i)
	assert(hud.walking.horse_panel.visible and hud.walking.horse_stamina.value<100)
	print("HORSE_PREVIEW_OK")

func _qa_v024() -> void:
	state=FarmState.new();state.claim(Vector2(4,-2));state.unlimited_money=true;state.farm_xp=950
	world.rebuild(state);hud.close_modal();build_mode=false
	horse.restore(FarmHorse.defaults());player.position=horse.position+Vector3(1.8,.1,0)
	for i in range(60):await get_tree().physics_frame
	_update_ui();_action("map");assert(hud.modal_kind=="valley_map")
	var saved:=state.serialize()
	_action("map:go:orchard");assert(navigator.waypoint==FarmTrails.STOPS.orchard.at)
	assert(navigator.status.text.contains("m"))
	await _qa_ui_capture("map-v024-full")
	_action("map:clear");assert(navigator.waypoint_name.is_empty())
	navigator.large.picked.emit(Vector2(50,90));assert(navigator.waypoint==Vector2(50,90))
	assert(state.serialize()==saved)
	_action("map:go:horse");horse.position.x+=1;navigator.refresh();assert(navigator.waypoint.x==horse.position.x)
	_action("close");_horse_interact();assert(horse.mounted)
	_action("map");assert(hud.modal_kind=="valley_map")
	var mounted_at:=player.position
	horse.drive(player,avatar,actor,Vector3.FORWARD,.1,false)
	assert(Vector2(player.position.x,player.position.z).distance_to(Vector2(mounted_at.x,mounted_at.z))<.01)
	_action("close");navigator.select(FarmTrails.STOPS.mill.at,"Mirante dos Ventos")
	set_physics_process(false)
	player.position=Vector3(0,FarmLandscape.height_at(Vector2(0,30))+.05,30);horse.position=player.position;horse.heading=PI/2
	for i in range(24):
		if i==4:assert(horse.encourage())
		horse.drive(player,avatar,actor,Vector3(1,0,0),.07,true)
		camera.position=horse.position+Vector3(5,2.8,6);camera.look_at(horse.position+Vector3(0,1.8,0))
		_update_ui()
		await _qa_ui_capture("map-v024-ride-%02d"%i)
	assert(horse.skin!=null and horse.skin_bones.size()==10)
	assert(horse.dismount(player,avatar,actor,state,world.landscape))
	_update_ui()
	for angle in [0.0,1.57,3.14]:
		horse.animate(.1,0,false)
		camera.position=horse.position+Vector3(sin(angle)*6,2.7,cos(angle)*6);camera.look_at(horse.position+Vector3(0,1.4,0))
		await _qa_ui_capture("horse-v024-angle-%d"%int(angle*100))
	print("V024_INTEGRATION_OK: destinations, map pause while mounted, no state mutation, horse tracking, continuous skin, riding and dismount")

func _qa_v025() -> void:
	state=FarmState.new();state.claim(Vector2(4,-2));state.unlimited_money=true;state.farm_xp=950
	assert(state.place("stable",Vector2(2,-4),0).is_empty());world.rebuild(state)
	hud.close_modal();build_mode=false;set_physics_process(false)
	horse.restore({"x":2.0,"z":2.0,"angle":0.0});horse.life.reset(horse);player.position=Vector3(10,.1,9)
	for i in range(5):await get_tree().physics_frame
	horse.stamina=30
	horse.life.mode="graze";horse.life.remaining=30
	for i in range(24):horse.life.update(horse,.07,true,state,world.landscape,player)
	assert(horse.life.graze>.9 and horse.stamina>50)
	camera.position=Vector3(11,6,13);camera.look_at(Vector3(2,1.3,-1));_update_ui()
	await _qa_ui_capture("stable-v025-graze")
	var pose:Transform3D=horse.parts.HorseNeck.transform;var snapshot:=state.serialize();var stamina:=horse.stamina
	horse.life.update(horse,5,false,state,world.landscape,player)
	assert(horse.parts.HorseNeck.transform==pose and horse.stamina==stamina and state.serialize()==snapshot)
	selected=0;_tend_selected();assert(hud.modal_kind=="stable");await _qa_ui_capture("stable-v025-menu");hud.close_modal()
	_action("map");_action("map:go:stable:0");assert(navigator.waypoint.distance_to(FarmStable.entrance(state.items[0]))<.001)
	await _qa_ui_capture("stable-v025-map");hud.close_modal()
	# Bounded walking on a clear public lane, no manual teleport during the simulation.
	horse.restore({"x":20.0,"z":30.0,"angle":PI/2});player.position=Vector3(10,.1,40)
	horse.life.mode="walk";horse.life.remaining=30;horse.life.goal=Vector2(23,30)
	var origin:=horse.position
	for i in range(24):
		horse.life.update(horse,.1,true,state,world.landscape,player)
		assert(Vector2(horse.position.x,horse.position.z).distance_to(horse.life.anchor)<=4.51)
		camera.position=horse.position+Vector3(6,3.1,5);camera.look_at(horse.position+Vector3(0,1.5,0));_update_ui()
		await _qa_ui_capture("stable-v025-walk-%02d"%i)
	assert(horse.position.distance_to(origin)>1)
	# A real obstacle blocks the full swept body, not only its feet.
	var blocker:=StaticBody3D.new();var collision:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(.25,3,7);collision.shape=box;blocker.add_child(collision);add_child(blocker);blocker.position=horse.position+Vector3(2,1.5,0)
	for i in range(3):await get_tree().physics_frame
	assert(not horse.life.safe_step(horse,Vector2(horse.position.x+3,horse.position.z),PI/2,state,world.landscape))
	blocker.queue_free()
	horse.stamina=30;horse.life.mode="look";horse.life.remaining=30
	horse.life.update(horse,1,true,state,world.landscape,player);assert(is_equal_approx(horse.stamina,37))
	# Approaching stops walking, then mounting clears the grazing pose.
	player.position=horse.position+Vector3(1.7,.1,0)
	horse.life.mode="walk";horse.life.remaining=10;horse.life.update(horse,.1,true,state,world.landscape,player)
	assert(horse.life.mode=="look")
	horse.mount(player,avatar,actor);assert(horse.mounted and horse.parts.HorseNeck.position==horse.part_home.HorseNeck)
	horse.drive(player,avatar,actor,Vector3.ZERO,.1,true)
	assert(horse.dismount(player,avatar,actor,state,world.landscape))
	assert(state.items[0].kind=="stable")
	print("V025_INTEGRATION_OK: stable render/menu/map, graze, bounded walking, obstacle sweep, pause, recovery, approach/mount/dismount")

func _reset_farm() -> void:
	actor.stop_emote();weapons.holster();player.velocity=Vector3.ZERO
	navigator.waypoint_name="";navigator.target_key="";navigator.stable_target={}
	field_alerts=FarmFieldAlerts.new()
	if horse.mounted:horse.reset_rider(player,avatar,actor)
	state=FarmState.new();state.unlimited_money=not qa_mode
	horse.restore(state.horse)
	world.rebuild(state)
	selected=-1
	journey_seen=-1
	build_mode=true
	tool="inspect"
	focus=Vector3(4,0,-2)
	player.position=Vector3(4,0.2,10)
	next_silly=75
	silly_timer=0
	silly_event_index=0
	selected_hen=-1
	session_started=false

func _qa_title_photo() -> void:
	state=FarmState.new();state.claim(Vector2(4,-2));state.farm_xp=950;state.unlimited_money=true;state.land_size=40
	for entry in [["barn",Vector2(8,-10)],["coop",Vector2(18,-6)],["stable",Vector2(-6,-8)],["corral",Vector2(18,8)]]:
		assert(state.place(entry[0],entry[1],0).is_empty())
	state.items[-1].dairy.owned=true
	for i in range(9):
		assert(state.place("plot",Vector2(4+(i%3)*2,2+(i/3)*2),0,["carrot","wheat","corn"][i%3]).is_empty())
		state.items[-1].growth=1;state.items[-1].watered=true
	world.rebuild(state);set_physics_process(false);set_process(false);hud.visible=false
	world.border.visible=false;world.build_grid.visible=false;world.selection.visible=false;ghost.visible=false
	player.position=Vector3(9,.15,9);avatar.rotation.y=-.8;actor.animate(.1,false,false)
	horse.restore({"x":12.0,"z":7.0,"angle":-.8});horse.animate(.1,0,false)
	for node in world.find_children("*","Label3D",true,false):node.visible=false
	horse.label.visible=false
	camera.position=Vector3(-10,8,22);camera.look_at(Vector3(6,1,-2));camera.fov=46
	await _qa_ui_capture("title-v026-photo")
	print("TITLE_PHOTO_OK")

func _qa_v026() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	assert(hud.modal_kind=="title" and not session_started and not front_end.has_save)
	var before:=state.serialize()
	for i in range(6):await get_tree().process_frame
	assert(state.serialize()==before)
	await _qa_ui_capture("menu-v026-new")
	_action("front:settings");assert(hud.modal_kind=="settings")
	var previous:=preferences.data.duplicate()
	front_end.controls.volume.value=.25;_action("front:back")
	assert(hud.modal_kind=="title" and preferences.data==previous)
	_action("front:settings");front_end.controls.volume.value=.45;front_end.controls.sensitivity.value=1.5
	front_end.controls.quality.select(0);front_end.controls.quality.item_selected.emit(0)
	front_end.controls.fps.select(2);front_end.controls.fps.item_selected.emit(2)
	await _qa_ui_capture("menu-v026-settings")
	_action("front:apply");assert(preferences.data.volume==.45 and preferences.data.sensitivity==1.5)
	assert(get_viewport().msaa_3d==Viewport.MSAA_DISABLED and Engine.max_fps==120)
	var loaded:=FarmSettings.new();loaded.path=preferences.path;loaded.load_preferences();assert(loaded.data==preferences.data)
	_action("front:settings");_action("front:defaults");_action("front:apply")
	_action("front:controls");assert(hud.modal_kind=="controls");await _qa_ui_capture("menu-v026-controls");_action("close");assert(hud.modal_kind=="title")
	_action("front:new");hud.text_input.text="Fazenda Horizonte";await _qa_ui_capture("menu-v026-name")
	_action("front:new_review");assert(session_started and state.farm_name=="Fazenda Horizonte" and not state.claimed)
	assert(FileAccess.file_exists(save_path))
	state.claim(Vector2(4,-2));state.unlimited_money=true;state.farm_xp=550;world.rebuild(state)
	state.armory.pistol=true;state.armory.magazine=7
	assert(_save_game(false))
	_action("front:title");assert(not session_started and front_end.has_save and hud.modal_kind=="title")
	await _qa_ui_capture("menu-v026-continue")
	var saved:=FileAccess.get_file_as_string(save_path)
	_action("front:new");hud.text_input.text="Fazenda Outra";_action("front:new_review")
	assert(hud.modal_kind=="new_confirm" and FileAccess.get_file_as_string(save_path)==saved)
	await _qa_ui_capture("menu-v026-confirm")
	# Force a write failure using an isolated directory where the temporary file should be.
	var original_path:=save_path
	var failed_path:="res://test-results/qa_new_failure.json"
	DirAccess.make_dir_recursive_absolute(failed_path+".tmp")
	save_path=failed_path
	var retained:=state
	_action("front:new_commit")
	assert(state==retained and hud.modal_kind=="new_confirm" and FileAccess.get_file_as_string(original_path)==saved)
	DirAccess.remove_absolute(failed_path+".tmp");save_path=original_path
	_action("front:cancel_new");assert(hud.modal_kind=="title" and FileAccess.get_file_as_string(save_path)==saved)
	# Simulate startup loading from disk rather than continuing only the in-memory state.
	state=FarmState.new();assert(_load_game())
	front_end.setup(self,true);front_end.resume_session=false;front_end.show_title()
	_action("front:continue");assert(session_started and state.armory.magazine==7 and state.farm_name=="Fazenda Horizonte")
	_action("menu");_action("front:settings");_action("front:back");assert(hud.modal_kind=="menu" and session_started)
	_action("front:title");_action("front:new");hud.text_input.text="Fazenda Renovada";_action("front:new_review");_action("front:new_commit")
	assert(session_started and state.farm_name=="Fazenda Renovada" and not state.claimed and not state.armory.pistol)
	var archive:=save_path.get_base_dir().path_join("farms_archive")
	var found:=false
	for name in DirAccess.get_files_at(archive):
		var data:Variant=JSON.parse_string(FileAccess.get_file_as_string(archive.path_join(name)))
		if data is Dictionary and data.get("farm_name")=="Fazenda Horizonte" and data.armory.magazine==7:found=true
	assert(found,"Previous farm archived before replacement")
	assert(JSON.parse_string(FileAccess.get_file_as_string(save_path)).farm_name=="Fazenda Renovada")
	session_started=false
	print("V026_INTEGRATION_OK: startup pause, title, continue, cancel new, archived old farm, new save, settings apply/cancel/persist, controls and pause menu")
