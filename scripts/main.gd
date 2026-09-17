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
var session_started := false
var save_timer := 0.0
var ui_timer := 0.0
var silly_timer := 0.0
var next_silly := 75.0
var sound := AudioStreamPlayer.new()
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

func _ready() -> void:
	qa_mode = OS.is_debug_build() and "--qa" in OS.get_cmdline_user_args()
	if qa_mode: save_path="user://qa_farm_v08.json"
	get_tree().auto_accept_quit = false
	_inputs()
	world = FarmWorld.new()
	add_child(world)
	var loaded := false if qa_mode else _load_game()
	next_silly=state.elapsed+75
	world.rebuild(state)
	add_child(feedback)
	feedback.setup(world)
	_player()
	add_child(camera)
	camera.current = true
	camera.fov = 49
	camera.far = 250
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
	add_child(sound)
	hud = FarmHUD.new()
	add_child(hud)
	hud.action.connect(_action)
	hud.welcome(state,loaded)
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

func _physics_process(delta: float) -> void:
	if not is_instance_valid(hud):
		return
	var movement := Vector2.ZERO
	if hud.modal_kind.is_empty() and session_started:
		movement = Input.get_vector("left","right","forward","back")
	var right := Vector3(cos(yaw),0,-sin(yaw))
	var back := Vector3(sin(yaw),0,cos(yaw))
	var direction := right * movement.x + back * movement.y
	if actor.action_time>0 and not build_mode: direction=Vector3.ZERO
	if build_mode:
		focus += direction * delta * build_distance * 0.45
		focus.x = clampf(focus.x,-25,38)
		focus.z = clampf(focus.z,-30,35)
		player.velocity.x = 0
		player.velocity.z = 0
	else:
		var speed := 7.5 if Input.is_action_pressed("run") else 4.5
		player.velocity.x = direction.x * speed
		player.velocity.z = direction.z * speed
		if direction.length() > 0.1:
			avatar.rotation.y = lerp_angle(avatar.rotation.y,atan2(direction.x,direction.z),delta*12)
	player.velocity.y -= 18*delta
	player.move_and_slide()
	actor.animate(delta,not build_mode and Vector2(player.velocity.x,player.velocity.z).length()>0.2,Input.is_action_pressed("run"))
	player.position.x = clampf(player.position.x,-31,44)
	player.position.z = clampf(player.position.z,-39,43)
	if player.position.y < -3:
		player.position.y = 1
	_update_camera(delta)

func _process(delta: float) -> void:
	if not is_instance_valid(hud):
		return
	action_cooldown=maxf(0,action_cooldown-delta)
	if session_started and not build_mode and hud.modal_kind.is_empty():
		var staff_spent:=int(state.staff.spent)
		var staff_eggs:=int(state.staff.eggs)
		if state.tick(delta):
			hud.toast("Tem novidade no ninho! Visite o galinheiro para coletar os ovos.")
		if state.staff.spent>staff_spent:
			hud.toast("Zeca concluiu o trato • +%d ovos no estoque • -$%d"%[state.staff.eggs-staff_eggs,state.staff.spent-staff_spent])
		if not state.trade_notices.is_empty():
			hud.toast("Prazo de %s encerrado. Sem multa. Veja novos pedidos em J."%state.trade_notices[0] if state.trade_notices.size()==1 else "%d prazos encerrados. Sem multa; consulte o quadro com J."%state.trade_notices.size())
			state.trade_notices.clear()
		if not state.staff_notice.is_empty():
			hud.toast(state.staff_notice)
			state.staff_notice=""
		world.update_staff(state,delta)
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
	var target := focus if build_mode else player.position + Vector3(0,1.1,0)
	var distance := build_distance if build_mode else walk_distance
	var angle := pitch if build_mode else clampf(pitch,0.2,1.0)
	var desired := target + Vector3(sin(yaw)*cos(angle),sin(angle),cos(yaw)*cos(angle))*distance
	if not build_mode and is_inside_tree():
		var query := PhysicsRayQueryParameters3D.create(target,desired,1,[player.get_rid()])
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			desired = hit.position + hit.normal * 0.35
	camera.position = desired if immediate else camera.position.lerp(desired,1-exp(-delta*10))
	if camera.position.distance_to(target)>0.01:
		camera.look_at(target)
	avatar.visible = build_mode or camera.position.distance_to(target)>1.7

func _ensure_player_space() -> void:
	var start := Vector2(player.position.x,player.position.z)
	for radius in range(0,16):
		for step in range(16):
			var angle := float(step)/16*TAU
			var candidate := start+Vector2(sin(angle),cos(angle))*radius
			if candidate.x < -31 or candidate.x > 44 or candidate.y < -39 or candidate.y > 43:
				continue
			var valid := true
			for item in state.items:
				if item.kind in ["plot","path"]: continue
				if state.item_rect(item.kind,Vector2(item.x,item.z),item.turn).grow(0.5).has_point(candidate):
					valid=false
					break
			if valid:
				player.position=Vector3(candidate.x,0.2,candidate.y)
				return

func _input(event: InputEvent) -> void:
	# Release must be caught even over a HUD panel, where unhandled input is consumed.
	if dragging and event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and not event.pressed:
		_update_pointer()
		if get_viewport().gui_get_hovered_control()!=null or not pointer_valid:
			_cancel_route()
			hud.toast("Traçado cancelado. Solte sobre o terreno para revisar.")
		else: _finish_route()
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if dragging or not route.is_empty():
				_cancel_route()
				if hud.modal_kind=="route": hud.close_modal()
				get_viewport().set_input_as_handled()
				return
			if not hud.modal_kind.is_empty():
				if hud.modal_kind != "welcome": hud.close_modal()
			elif tool != "inspect":
				tool="inspect"
				move_index=-1
			else:
				hud.menu(state)
			get_viewport().set_input_as_handled()
			return
		if not hud.modal_kind.is_empty():
			return
		match event.physical_keycode:
			KEY_TAB: _action("mode")
			KEY_E: _interact_nearest()
			KEY_F: _action("market")
			KEY_J: _action("market_orders")
			KEY_H: _action("staff")
			KEY_F5: _action("save")
			KEY_M: _action("move")
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
	if not hud.modal_kind.is_empty():
		return
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		yaw -= event.relative.x*0.005
		pitch=clampf(pitch+event.relative.y*0.003,0.2,1.3)
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
		var nearest:=_nearest()
		if player.position.distance_to(FarmWorld.TRADE_BOARD_AT)<2.8:
			hover_hint="[E] Quadro dos vizinhos • Encomendas e reputação"
		elif nearest>=0:
			var item:Dictionary=state.items[nearest]
			hover_hint="[E]  "+_interaction_text(item)
		elif player.position.distance_to(Vector3(-24,0,14))<4:
			hover_hint="[E] Conversar com Seu Tonico • Armazém do Vale"

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
			else:
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
	var area:=state.item_rect(item.kind,Vector2(item.x,item.z),item.turn)
	var position_2d:=Vector2(player.position.x,player.position.z)
	var closest:=position_2d.clamp(area.position,area.end)
	return position_2d.distance_to(closest)

func _nearest() -> int:
	nearby_hen=-1
	var best:=-1
	var distance:=2.6
	if selected>=0 and selected<state.items.size() and state.items[selected].kind in ["plot","sign","barn","coop"]:
		var current_distance:=_distance_to_item(selected)
		if current_distance<distance:
			best=selected
			distance=current_distance
	for i in range(state.items.size()):
		if state.items[i].kind not in ["plot","sign","barn","coop"]: continue
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

func _interaction_text(item: Dictionary) -> String:
	if item.kind=="sign": return "Editar placa"
	if item.kind=="barn": return "Abrir reserva e bancada do celeiro"
	if item.kind=="coop": return "Galinhas • %d ovos no ninho • Cuidar"%int(item.flock.nest)
	if not item.planted: return "Plantar %s • $%d"%[FarmState.CROPS[crop].name,FarmState.CROPS[crop].seed]
	if item.growth>=1: return "Colher "+FarmState.CROPS[item.crop].name
	if not item.watered: return "Regar "+FarmState.CROPS[item.crop].name
	return "%s crescendo • %d%%"%[FarmState.CROPS[item.crop].name,int(item.growth*100)]

func _interact_nearest() -> void:
	if build_mode: return
	if player.position.distance_to(FarmWorld.TRADE_BOARD_AT)<2.8:
		hud.market(state,"orders")
		return
	if player.position.distance_to(Vector3(-24,0,14))<4:
		hud.market(state)
		return
	selected=_nearest()
	selected_hen=nearby_hen
	if selected>=0:
		_tend_selected()
	else:
		hud.toast("Aproxime-se de um canteiro, placa ou do armazém.")

func _tend_selected() -> void:
	if selected<0 or selected>=state.items.size(): return
	var item:Dictionary=state.items[selected]
	if item.kind=="plot":
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
			feedback.water(at,origin,build_mode)
			for target in water_targets:
				if target==selected: continue
				var neighbor:Dictionary=state.items[target]
				feedback.water(Vector3(neighbor.x,0,neighbor.z),origin,false)
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
	elif item.kind=="barn": hud.barn(state)
	elif item.kind=="coop": hud.coop(state,selected,selected_hen)

func _action(value: String) -> void:
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
		var before_money:=state.money
		var error:=""
		var message:=""
		if value.begins_with("accept_order:"):
			error=state.accept_order(key)
			message="Encomenda aceita! O prazo avança só enquanto você joga."
		elif value.begins_with("deliver_order:"):
			error=state.deliver_order(key)
			message="Entrega concluída! +$%d e +1 reputação com %s."%[state.money-before_money,FarmTrade.NEIGHBORS[key].name]
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
		if selected_hen<0 or selected_hen>=3: return
		hud.hen_editor(state.items[selected].flock.names[selected_hen])
		return
	if value.begins_with("tool:"):
		if not session_started: return
		var key:=value.get_slice(":",1)
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
		hud.barn(state)
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
			if state.count_items("barn")>0: hud.barn(state)
		"upgrade":
			var error:=state.buy_watering_upgrade()
			hud.barn(state)
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
			var farm_name:=hud.text_input.text.strip_edges()
			state.farm_name=farm_name if not farm_name.is_empty() else "Meu pedacinho de mundo"
			session_started=true
			hud.close_modal()
			if state.claimed: hud.toast("Bem-vindo de volta! A fazenda estava esperando.")
		"mode":
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
			state=FarmState.new()
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
			hud.welcome(state,false)
			_save_game(false,true)
		"quit":
			if _save_game(false): get_tree().quit()
	_update_ui()

func _update_ui() -> void:
	hud.update(state,build_mode,selected,tool,crop,hover_hint)
	var step:=state.journey_step()
	if session_started and journey_seen>=0 and step>journey_seen:
		hud.toast("Etapa concluída: "+FarmState.JOURNEY[journey_seen].title+"!")
	journey_seen=step

func _journey_action() -> void:
	var step:=state.journey_step()
	if step>=FarmState.JOURNEY.size(): return
	var key:String=FarmState.JOURNEY[step].action
	if key=="market":
		if FarmState.JOURNEY[step].key=="contract" and state.inventory.carrot<6 and state.reserve.carrot>0:
			hud.barn(state)
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
				return true
	return false

func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_CLOSE_REQUEST:
		if _save_game(false): get_tree().quit()

func _chime(kind: String = "build") -> void:
	var stream:=AudioStreamWAV.new()
	stream.format=AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate=22050
	var bytes:=PackedByteArray()
	bytes.resize(4410*2)
	for i in range(4410):
		var t:=float(i)/22050
		var frequency:=660.0 if t<0.1 else 880.0
		if kind=="harvest": frequency=[523.25,659.25,783.99][mini(2,int(t/0.066))]
		if kind=="plant": frequency=360+t*400
		var wave:=sin(t*TAU*frequency)
		if kind=="water": wave=(sin(t*TAU*(900-t*2500))*0.35+sin(i*1.719)*sin(i*0.827)*0.3)
		var sample:=int(wave*exp(-t*15)*6500)
		bytes.encode_s16(i*2,sample)
	stream.data=bytes
	sound.stream=stream
	sound.volume_db=-15
	sound.play()

func _qa() -> void:
	# In-engine integration run. Isolated state; never reads/writes the player's save.
	await get_tree().process_frame
	await get_tree().process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://test-results/welcome.png")
	_action("start")
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
	await _qa_v08()
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
	state=FarmState.new()
	assert(_load_game() and state.money==saved_money)
	assert(state.reserve==saved_reserve and state.watering_upgrade and state.items[0].door_paint==2)
	_qa_saved_flock(state.items[1].flock,saved_flock)
	assert(state.trade==saved_trade and state.active_orders()>0)
	assert(state.staff==saved_staff and state.staff.hired)
	var damaged:=FileAccess.open(save_path,FileAccess.WRITE)
	damaged.store_string("{damaged")
	damaged.close()
	state=FarmState.new()
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
	var balance:=state.money
	_action("upgrade")
	assert(state.watering_upgrade and state.money==balance-300)
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
	_process(15)
	build_mode=true
	assert(flock.food==100 and flock.water==100 and flock.nest==0)
	assert(state.inventory.egg==eggs+6 and state.money==balance-10)
	assert(state.staff.services==1 and state.staff.eggs==6 and world.staff_actor.action_kind=="harvest")
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

func _qa_v08() -> void:
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
		get_viewport().get_texture().get_image().save_png("res://test-results/characters-v08-game.png")
	print("V08_CHARACTER_OK: continuous body skins, 20-bone humanoids, walking/watering regression, chicken gait pivots, game capture")

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
