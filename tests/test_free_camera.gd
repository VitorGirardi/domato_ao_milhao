extends SceneTree
var game:Node3D
func _initialize() -> void:call_deferred("run")
func key(code:int) -> InputEventKey:
	var e:=InputEventKey.new();e.physical_keycode=code;e.keycode=code;e.pressed=true;return e
func alt() -> void:
	game._input(key(KEY_ALT))
	var release:=key(KEY_ALT);release.pressed=false;game._input(release)
func motion() -> InputEventMouseMotion:
	var e:=InputEventMouseMotion.new();e.relative=Vector2(20,8);return e
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	game=load("res://scenes/main.tscn").instantiate();game.save_path="user://camera.json";root.add_child(game);await process_frame
	game.qa_mode=true;game.set_process(false);game.set_physics_process(false);game.weapons.set_physics_process(false)
	var c:FarmCameraControl=game.camera_control
	assert(game.preferences.data.free_camera and not c.captured())
	game.build_mode=false;game.session_started=true;game.hud.close_modal();c.sync_cursor()
	assert(c.captured());var yaw:float=game.yaw
	game._input(motion());assert(is_equal_approx(game.yaw,yaw-.1),"Mouse alone must rotate exactly once")
	alt();assert(c.cursor_released and not c.captured())
	yaw=game.yaw;game._input(motion());assert(game.yaw==yaw,"Cursor mode rotated the camera")
	var echo:=key(KEY_ALT);echo.echo=true;game._input(echo);assert(c.cursor_released)
	alt();assert(c.captured())
	game.hud.menu(game.state);assert(not c.captured() and Input.mouse_mode==Input.MOUSE_MODE_VISIBLE)
	game.front_end.show_settings();game.front_end.settings_tab(false)
	assert(game.front_end.controls.free_camera.button_pressed)
	if DisplayServer.get_name()!="headless":
		await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://test-results/camera-settings.png")
	game.hud.close_modal();assert(c.captured())
	# Construction always keeps the cursor for placing and moving buildings.
	game.build_mode=true;c.sync_cursor();assert(not c.captured() and Input.mouse_mode==Input.MOUSE_MODE_VISIBLE)
	game.build_mode=false;c.sync_cursor()
	FarmArmory.buy_pistol(game.state,game.state.armory);game.weapons.armed=true
	var right:=InputEventMouseButton.new();right.button_index=MOUSE_BUTTON_RIGHT;right.pressed=true
	assert(game.weapons.handle_input(right) and game.weapons.aiming)
	yaw=game.yaw;game._input(motion());assert(is_equal_approx(game.yaw,yaw-.08),"Aim must consume motion once")
	alt();assert(not game.weapons.aiming and not c.captured())
	assert(not game.weapons.handle_input(right),"Cursor UI mode must not start weapon aim")
	alt();game.weapons.handle_input(right)
	game.hud.menu(game.state);assert(not game.weapons.aiming and Input.mouse_mode==Input.MOUSE_MODE_VISIBLE)
	game.weapons.holster();game.hud.close_modal()
	game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT);assert(not c.captured() and Input.mouse_mode==Input.MOUSE_MODE_VISIBLE)
	game.hud.menu(game.state);game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN);assert(not c.captured())
	game.hud.close_modal();assert(c.captured())
	game._input(key(KEY_ALT))
	var tab:=key(KEY_TAB);tab.alt_pressed=true;game._input(tab);game._unhandled_input(tab)
	var alt_release:=key(KEY_ALT);alt_release.pressed=false;game._input(alt_release)
	assert(not c.cursor_released and not game.build_mode,"Alt+Tab must not toggle cursor or building")
	# Smooth following waits for the player's look gesture and stops when parked.
	game.pickup.mounted=true;game.pickup.speed=5;game.pickup.rotation.y=0;game.yaw=0;c.look_delay=0
	c.update(.1);assert(absf(game.yaw)>.01 and absf(game.yaw)<.6)
	c.look_delay=2;yaw=game.yaw;c.update(.1);assert(game.yaw==yaw)
	game.pickup.speed=0;c.look_delay=0;c.update(.1);assert(game.yaw==yaw)
	game.pickup.mounted=false;game.horse.mounted=true;game.horse.speed=4;game.horse.heading=0;game.yaw=0
	c.update(.1);assert(absf(game.yaw)>.01 and absf(game.yaw)<.6)
	game.horse.mounted=false;game.horse.speed=0
	game.preferences.data.free_camera=false;c.sync_cursor();assert(not c.captured())
	yaw=game.yaw;game._input(motion());assert(game.yaw==yaw)
	Input.parse_input_event(right);await process_frame
	game._unhandled_input(motion());assert(game.yaw!=yaw,"Legacy RMB orbit must remain available")
	right.pressed=false;Input.parse_input_event(right)
	game.preferences.data.free_camera=true;game.front_end.show_controls()
	if DisplayServer.get_name()!="headless":
		await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://test-results/camera-controls.png")
	game.session_started=false;game.audio.stop_all();await create_timer(.2).timeout
	game.queue_free();await process_frame;await create_timer(.2).timeout
	assert(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE)
	print("FREE_CAMERA_OK: mouse-only orbit, Alt, menus, construction, aim, focus, smooth transport follow, legacy and clean cursor exit")
	quit()
