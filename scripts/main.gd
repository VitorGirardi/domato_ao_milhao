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

func _ready() -> void:
	qa_mode = OS.is_debug_build() and "--qa" in OS.get_cmdline_user_args()
	if qa_mode: save_path="user://qa_farm_v02.json"
	get_tree().auto_accept_quit = false
	_inputs()
	world = FarmWorld.new()
	add_child(world)
	var loaded := false if qa_mode else _load_game()
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
	capsule.height = 1.85
	collision.shape = capsule
	collision.position.y = 0.95
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
		if state.tick(delta):
			hud.toast("Có-có-contabilidade: +2 ovos por galinheiro!")
		world.update_crops(state)
		silly_timer = maxf(0,silly_timer-delta)
		if state.elapsed > next_silly and not world.chickens.is_empty():
			next_silly = state.elapsed + 110
			silly_timer = 14
			hud.toast("A Maricota se declarou gerente. Vai fiscalizar você!")
		world.animate(delta,player.position,silly_timer>0)
	if session_started:
		save_timer += delta
		if save_timer >= 30:
			save_timer=0
			_save_game(false)
	_update_pointer()
	ui_timer += delta
	if ui_timer >= 0.15:
		ui_timer = 0
		_update_ui()

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

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
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
			_click_world()

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
	if get_viewport().gui_get_hovered_control()!=null:
		return
	if state.claimed and build_mode and tool=="inspect":
		var hovered:=_pick_item(mouse,Vector2(at.x,at.z))
		world.show_selection(state,hovered if hovered>=0 else selected)
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
	elif not build_mode:
		var nearest:=_nearest()
		if nearest>=0:
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
		if selected>=0:
			if not build_mode and _distance_to_item(selected)>3:
				hud.toast("Chegue mais perto ou use a câmera de construção.")
			else:
				_tend_selected()
	_update_ui()

func _pick_item(mouse: Vector2, ground: Vector2) -> int:
	var origin:=camera.project_ray_origin(mouse)
	var end:=origin+camera.project_ray_normal(mouse)*200
	var hit:=get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(origin,end,1,[player.get_rid()]))
	if not hit.is_empty() and hit.collider.has_meta("item_index"):
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
	var best:=-1
	var distance:=2.6
	if selected>=0 and selected<state.items.size() and state.items[selected].kind in ["plot","sign"]:
		var current_distance:=_distance_to_item(selected)
		if current_distance<distance:
			best=selected
			distance=current_distance
	for i in range(state.items.size()):
		if state.items[i].kind not in ["plot","sign"]: continue
		var d:=_distance_to_item(i)
		if d<distance and (best<0 or d+0.05<distance):
			best=i
			distance=d
	return best

func _interaction_text(item: Dictionary) -> String:
	if item.kind=="sign": return "Editar placa"
	if not item.planted: return "Plantar %s • $%d"%[FarmState.CROPS[crop].name,FarmState.CROPS[crop].seed]
	if item.growth>=1: return "Colher "+FarmState.CROPS[item.crop].name
	if not item.watered: return "Regar "+FarmState.CROPS[item.crop].name
	return "%s crescendo • %d%%"%[FarmState.CROPS[item.crop].name,int(item.growth*100)]

func _interact_nearest() -> void:
	if build_mode: return
	if player.position.distance_to(Vector3(-24,0,14))<4:
		hud.market(state)
		return
	selected=_nearest()
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

func _action(value: String) -> void:
	if move_index>=0 and value not in ["move","save"]:
		move_index=-1
		tool="inspect"
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
		if selected<0 or state.items[selected].kind not in ["barn","coop","sign","fence"]:
			hud.toast("Selecione uma construção com Cuidar para pintar.")
			return
		state.items[selected].paint=int(value.get_slice(":",1))
		world.rebuild(state)
		hud.toast("Uma cor nova, um lugar mais seu.")
		return
	match value:
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
				state.money+=int(FarmState.ITEMS[state.items[selected].kind].cost)/2
				state.items.remove_at(selected)
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
		hud.market(state)
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
	file.store_string(JSON.stringify(state.serialize()))
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
	assert(actor.parts.ArmR!=null and actor.parts.LegL!=null)
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
	assert(actor.can.visible and absf(actor.parts.ArmR.rotation.x)>0.1)
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
	var restored:=FarmState.new()
	assert(restored.restore(JSON.parse_string(JSON.stringify(state.serialize()))))
	assert(restored.items.size()==state.items.size())
	assert(_save_game(false))
	assert(_save_game(false))
	var saved_money:=state.money
	state=FarmState.new()
	assert(_load_game() and state.money==saved_money)
	var damaged:=FileAccess.open(save_path,FileAccess.WRITE)
	damaged.store_string("{damaged")
	damaged.close()
	state=FarmState.new()
	assert(_load_game() and state.money==saved_money)
	DirAccess.remove_absolute(save_path)
	DirAccess.remove_absolute(save_path+".bak")
	print("INTEGRATION_OK: terrain, construction, crops, sale, paint, signs, camera, movement, persistence")
	print("SAVE_OK: atomic replacement, disk reload, backup recovery")
	print("V02_OK: articulated character, watering, harvest feedback, growth stages, movement commit/cancel, tutorial, effect cleanup")
	print("RENDERER: ",RenderingServer.get_video_adapter_name())
	print("FPS: ",Engine.get_frames_per_second()," | physics movement test ms: ",Time.get_ticks_msec()-start)
	get_tree().quit()
