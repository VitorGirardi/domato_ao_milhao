class_name FarmCameraControl
extends Node
## One exploration cursor policy, shared with menus and the weapon aim owner.
var game:Node3D
var cursor_released:=false
var look_delay:=0.0
var focus_allowed:=true
var alt_pending:=false
var alt_chord:=false
var center:Label

func setup(host:Node3D) -> void:
	game=host
	game.hud.modal_changed.connect(sync_cursor)
	center=Label.new();center.text="·";center.mouse_filter=Control.MOUSE_FILTER_IGNORE
	center.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	center.position=Vector2(-8,-14);center.size=Vector2(16,28)
	center.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	center.add_theme_font_size_override("font_size",22)
	center.add_theme_color_override("font_color",Color("fff7df"))
	game.hud.root.add_child(center);center.visible=false
	sync_cursor()

func free_mode() -> bool:
	return is_instance_valid(game) and game.preferences.data.get("free_camera",true)

func available() -> bool:
	return game.session_started and not game.quitting and not game.build_mode and game.hud.modal_kind.is_empty() and not game.falls.local_down()

func focused() -> bool:
	return focus_allowed and (game.qa_mode or DisplayServer.get_name()=="headless" or (game.get_window().has_focus() and game.get_window().mode!=Window.MODE_MINIMIZED))

func captured() -> bool:
	return free_mode() and available() and focused() and not cursor_released

func sync_cursor() -> void:
	if not is_instance_valid(game) or not is_instance_valid(game.hud):return
	var blocked:=not available() or not focused()
	if blocked and game.weapons.aiming:game.weapons._end_aim()
	var aiming:bool=game.weapons.aiming and not blocked
	var mode:=Input.MOUSE_MODE_CAPTURED if captured() or aiming else Input.MOUSE_MODE_VISIBLE
	if Input.mouse_mode!=mode:Input.mouse_mode=mode
	if is_instance_valid(center):center.visible=captured() and not game.weapons.armed

func handle_input(event:InputEvent) -> bool:
	if event is InputEventKey:
		if event.physical_keycode!=KEY_ALT and event.pressed and alt_pending:alt_chord=true
		if event.physical_keycode==KEY_ALT:
			if event.echo:return false
			if event.pressed:
				alt_pending=free_mode() and available() and focused();alt_chord=false
				return alt_pending
			var toggle:=alt_pending and not alt_chord and free_mode() and available() and focused()
			alt_pending=false
			if not toggle:return false
			cursor_released=not cursor_released
			game.weapons._end_aim();look_delay=2.0;sync_cursor()
			return true
	if event is InputEventMouseMotion and captured():
		look_delay=2.0
		if game.weapons.armed and game.weapons.aiming:game.weapons.handle_input(event)
		else:
			game.yaw-=event.relative.x*.005*float(game.preferences.data.sensitivity)
			game.pitch=clampf(game.pitch+event.relative.y*.003*float(game.preferences.data.sensitivity),.2,1.0)
		return true
	return false

func update(delta:float) -> void:
	sync_cursor();look_delay=maxf(0,look_delay-delta)
	if not captured() or look_delay>0 or game.weapons.aiming:return
	var heading:=0.0
	if game.pickup.mounted:
		if absf(game.pickup.speed)<1:return
		heading=game.pickup.rotation.y+PI
	elif game._mounted():
		# Horse steering is camera-relative: never recenter against lateral or backward input.
		if absf(game.horse.speed)<1 or absf(Input.get_axis("left","right"))>.05 or Input.get_action_strength("back")>.05:return
		heading=game.horse.heading+PI
	else:return
	game.yaw=lerp_angle(game.yaw,heading,1-exp(-delta*1.6))

func _process(_delta:float) -> void:sync_cursor()

func _exit_tree() -> void:
	if is_instance_valid(game) and is_instance_valid(game.weapons):game.weapons._end_aim()
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
