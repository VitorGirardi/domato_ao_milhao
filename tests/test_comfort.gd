extends SceneTree
## Regressions against real camera collision, input and game state. QA profile only.
var game:Node3D
func _initialize() -> void:call_deferred("run")
func key(code:Key) -> InputEventKey:
	var event:=InputEventKey.new();event.physical_keycode=code;event.keycode=code;event.pressed=true;return event
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	game=load("res://scenes/main.tscn").instantiate();game.save_path="user://qa_comfort.json"
	root.add_child(game);await process_frame
	game.qa_mode=true;game.set_process(false);game.set_physics_process(false)
	game.session_started=true;game.build_mode=false;game.hud.close_modal()
	game.state=FarmState.new();game.state.unlimited_money=true;game.state.claim(Vector2(4,-2));game.world.rebuild(game.state)
	# High above scenery: the only occluder is the test wall, with a real physics shape.
	game.player.position=Vector3(0,80,0);game.yaw=0;game.pitch=.2;game.walk_distance=9
	game._update_camera(1,true)
	var distant:Vector3=game.camera.position
	var wall:=StaticBody3D.new();var collision:=CollisionShape3D.new();var shape:=BoxShape3D.new()
	shape.size=Vector3(8,8,.4);collision.shape=shape;wall.add_child(collision);game.add_child(wall);wall.position=Vector3(0,82,4)
	await physics_frame;await process_frame
	game._update_camera(1.0/60)
	assert(game.camera.position.z<3.8,"A newly blocking wall must retract the camera on the first frame")
	var target:Vector3=game.player.position+Vector3.UP*1.1
	var ray:=PhysicsRayQueryParameters3D.create(target,game.camera.position,1,[game.player.get_rid(),game.horse.obstacle.get_rid()])
	assert(game.get_world_3d().direct_space_state.intersect_ray(ray).is_empty())
	# Same protection applies to a mounted camera and shoulder aim.
	game.horse.mounted=true;game.camera.position=distant;game._update_camera(1.0/60)
	assert(game.camera.position.z<3.8);game.horse.mounted=false
	game.weapons.armed=true;game.camera.position=distant;game._update_camera(1.0/60)
	assert(game.camera.position.z<3.8);game.weapons.holster();game.pitch=.2
	var close_position:Vector3=game.camera.position
	wall.queue_free();await physics_frame;await process_frame
	game._update_camera(1.0/60)
	assert(game.camera.position.z>close_position.z and game.camera.position.z<distant.z,"Removing cover eases the camera back instead of snapping")
	for i in range(90):game._update_camera(1.0/60)
	assert(game.camera.position.distance_to(distant)<.01)
	# Sensitivity has the same multiplier in walking orbit and pistol aiming.
	game.player.position=Vector3(4,.1,6)
	FarmArmory.buy_pistol(game.state,game.state.armory)
	var mouse:=InputEventMouseButton.new();mouse.button_index=MOUSE_BUTTON_RIGHT;mouse.pressed=true
	Input.parse_input_event(mouse);await process_frame
	var motion:=InputEventMouseMotion.new();motion.relative=Vector2(12,4)
	var samples:Array[Vector2]=[]
	for sensitivity in [.5,2.0]:
		game.preferences.data.sensitivity=sensitivity
		game.weapons.armed=true;game.yaw=0;game.pitch=.1
		assert(game.weapons.handle_input(motion));samples.append(Vector2(game.yaw,game.pitch-.1))
	assert(samples[1].is_equal_approx(samples[0]*4),"Aim must honor the chosen mouse sensitivity")
	game.weapons.holster();samples.clear()
	for sensitivity in [.5,2.0]:
		game.preferences.data.sensitivity=sensitivity;game.yaw=0;game.pitch=.4
		game._unhandled_input(motion);samples.append(Vector2(game.yaw,game.pitch-.4))
	assert(samples[1].is_equal_approx(samples[0]*4))
	mouse.pressed=false;Input.parse_input_event(mouse)
	# Losing focus pauses progression, releases movement and cancels reload without spending ammo.
	game.weapons.handle_input(key(KEY_P));assert(game.weapons.shoot());assert(game.weapons.start_reload())
	var ammo:Dictionary=game.state.armory.duplicate();var elapsed:float=game.state.elapsed
	Input.action_press("forward");game.player.velocity=Vector3(4,0,0)
	game._pause_for_focus_loss()
	assert(game.hud.modal_kind=="menu" and not Input.is_action_pressed("forward") and game.player.velocity==Vector3.ZERO)
	assert(not game.weapons.armed and game.weapons.reload_left==0 and game.state.armory==ammo)
	game._process(1.0);assert(game.state.elapsed==elapsed)
	game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN);assert(game.hud.modal_kind=="menu","Returning focus requires explicit resume")
	game.hud.close_modal();game.horse.mount(game.player,game.avatar,game.actor);game.horse.encourage()
	var stamina:float=game.horse.stamina;var burst:float=game.horse.burst
	game._pause_for_focus_loss();game.horse.drive(game.player,game.avatar,game.actor,Vector3.FORWARD,.1,false)
	assert(game.horse.mounted and game.horse.speed==0 and game.horse.stamina==stamina and game.horse.burst==burst)
	game.horse.reset_rider(game.player,game.avatar,game.actor)
	# In-progress placement is discarded; committed farm data is untouched.
	game.hud.close_modal();game.build_mode=true;game.tool="move";game.move_index=0
	game.route=game.state.line_plan("path",Vector2(0,0),Vector2(4,0),0);game.dragging=true
	var before:Dictionary=game.state.serialize()
	game._pause_for_focus_loss()
	assert(not game.dragging and game.route.is_empty() and game.move_index==-1 and game.tool=="inspect")
	assert(game.state.serialize()==before)
	# Existing dialogs and focused text are not replaced by an automatic pause.
	game.hud.editor_dialog("sign","Texto em edição")
	var field:LineEdit=game.hud.text_input;game._pause_for_focus_loss()
	assert(game.hud.text_input==field and field.text=="Texto em edição" and game.hud.modal_kind=="sign")
	game.hud.close_modal();game.build_mode=false;game.qa_mode=false
	if DisplayServer.get_name()=="headless":
		# A renderer without an OS window must not pause ordinary headless simulations.
		game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
		await create_timer(.3).timeout
		assert(not game.focus_check_pending and game.hud.modal_kind.is_empty())
	else:
		game.set_process(true);root.show()
		root.mode=Window.MODE_WINDOWED;root.grab_focus();await create_timer(.2).timeout
		assert(root.has_focus())
		var dropdown:PopupMenu=game.hud.paint_selector.get_popup()
		dropdown.popup(Rect2i(400,200,250,120));await create_timer(.35).timeout
		assert(dropdown.visible and game.hud.modal_kind.is_empty(),"An in-game dropdown must not be mistaken for leaving the application")
		dropdown.hide()
		game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
		await create_timer(.3).timeout
		assert(game.hud.modal_kind.is_empty(),"A brief focus notification must not pause an already focused window")
		for i in range(2):
			game._input(key(KEY_F11));await create_timer(.35).timeout
			assert(game.hud.modal_kind.is_empty(),"F11 must not create an unexpected pause")
		root.mode=Window.MODE_MINIMIZED;await create_timer(.5).timeout
		assert(root.mode==Window.MODE_MINIMIZED and game.hud.modal_kind=="menu","Minimizing the running game must pause it even if the OS retains its focus flag")
		root.mode=Window.MODE_WINDOWED;root.grab_focus();await create_timer(.2).timeout
		assert(game.hud.modal_kind=="menu","Restoring the window must not auto-resume")
	game.hud.close_modal();game.session_started=false;game._pause_for_focus_loss();assert(game.hud.modal_kind.is_empty())
	print("COMFORT_QA_OK: immediate camera occlusion, smooth recovery, mounted/armed camera, sensitivity, focus pause, movement release, reload and construction cancellation, dialog preservation")
	game.queue_free();await process_frame
	# AudioServer releases stopped loop playbacks on its next mix tick.
	await create_timer(.15).timeout;quit()
