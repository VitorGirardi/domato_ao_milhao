extends SceneTree
## Independent layout and input QA. Runner must use isolated APPDATA.
var game:Node3D
var failures:Array[String]=[]
var capture:=false
var actions:Array[String]=[]

func _initialize() -> void:
	capture="--capture" in OS.get_cmdline_user_args()
	call_deferred("run")

func check(ok:bool,message:String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func settle() -> void:
	for i in range(6):await process_frame

func rect(control:Control) -> Rect2:
	var t:=control.get_global_transform_with_canvas()
	return Rect2(t*Vector2.ZERO,control.size*t.get_scale())

func fits(control:Control,label:String) -> void:
	check(root.get_visible_rect().grow(1).encloses(rect(control)),label+" outside viewport: "+str(rect(control)))

func modal_bounds(label:String) -> void:
	fits(game.hud.modal,label)
	check(rect(game.hud.modal).get_center().distance_to(root.get_visible_rect().get_center())<1,label+" not centered")
	check(rect(game.hud.modal_shade).grow(1).encloses(root.get_visible_rect()),label+" shade does not cover viewport")

func screenshot(label:String) -> void:
	if not capture or DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/fullscreen/"+label+".png")

func click_at(at:Vector2) -> void:
	var motion:=InputEventMouseMotion.new();motion.position=at;motion.global_position=at
	root.push_input(motion,true)
	for pressed in [true,false]:
		var event:=InputEventMouseButton.new();event.position=at;event.global_position=at
		event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed
		root.push_input(event,true)
	await settle()

func f11(echo:bool=false) -> void:
	var event:=InputEventKey.new();event.keycode=KEY_F11;event.physical_keycode=KEY_F11;event.pressed=true;event.echo=echo
	Input.parse_input_event(event)
	await settle()
	event=InputEventKey.new();event.keycode=KEY_F11;event.physical_keycode=KEY_F11;event.pressed=false
	Input.parse_input_event(event)
	await settle()

func run() -> void:
	if not OS.get_user_data_dir().contains("test-results"):
		push_error("Run with isolated APPDATA containing test-results")
		quit(2);return
	DirAccess.make_dir_recursive_absolute("res://test-results/fullscreen")
	root.mode=Window.MODE_WINDOWED
	game=load("res://scenes/main.tscn").instantiate()
	game.save_path="user://qa_fullscreen.json"
	root.add_child(game)
	root.mode=Window.MODE_WINDOWED
	await settle()
	game.set_physics_process(false)
	game.hud.action.connect(func(value:String):actions.append(value))
	for requested in [Vector2i(1280,720),Vector2i(1366,768),Vector2i(1920,1080),Vector2i(1920,1200),Vector2i(2560,1080),Vector2i(1280,960),Vector2i(1280,1024),Vector2i(3840,2160)]:
		root.size=requested
		await settle()
		var tag:="%dx%d"%[root.size.x,root.size.y]
		print("FULLSCREEN_SIZE requested=",requested," actual=",root.size," logical=",root.get_visible_rect().size)
		check(root.size==requested,"OS limited requested size "+str(requested)+" to "+str(root.size))
		game.front_end.has_save=false;game.front_end.show_title();await settle()
		modal_bounds(tag+" title")
		await screenshot(tag+"-title")
		await click_at(game.hud.modal.get_global_transform_with_canvas()*Vector2(280,505))
		check(game.hud.modal_kind=="settings",tag+" settings click failed")
		modal_bounds(tag+" settings")
		await click_at(rect(game.front_end.controls.volume).get_center())
		check(absf(game.front_end.pending.volume-.5)<.1,tag+" slider transform failed")
		for key in ["music","ambience","effects"]:fits(game.front_end.controls[key],tag+" "+key)
		await screenshot(tag+"-audio-settings")
		await click_at(game.hud.modal.get_global_transform_with_canvas()*Vector2(620,135))
		check(game.front_end.controls.video_page.visible and not game.front_end.controls.audio_page.visible,tag+" video tab click failed")
		await click_at(rect(game.front_end.controls.sensitivity).get_center())
		check(absf(game.front_end.pending.sensitivity-1.4)<.1,tag+" sensitivity slider transform failed")
		await screenshot(tag+"-video-settings")

		game._action("close");await settle()
		check(game.hud.modal_kind=="title",tag+" settings close failed")
		await click_at(game.hud.modal.get_global_transform_with_canvas()*Vector2(280,440))
		check(game.hud.modal_kind=="new_farm",tag+" new game click failed")
		modal_bounds(tag+" new farm")
		game._action("front:back")
		game.hud.welcome(game.state,false)
		await settle()
		modal_bounds(tag+" welcome")
		await screenshot(tag+"-welcome")
		game.hud.close_modal();game.session_started=true
		if not game.state.claimed:game.state.claim(Vector2(4,-2))
		game.build_mode=true;game._update_ui()
		await settle()
		fits(game.hud.tool_panel,tag+" toolbar")
		fits(game.hud.buttons.stable,tag+" last tool")
		fits(game.hud.select_panel,tag+" selection")
		actions.clear()
		await click_at(rect(game.hud.buttons.inspect).get_center())
		check(actions.has("tool:inspect"),tag+" transformed tool click failed")
		await screenshot(tag+"-build")
		# Embedded dropdown is a Window and must be checked independently.
		await click_at(rect(game.hud.paint_selector).get_center())
		var popup:PopupMenu=game.hud.paint_selector.get_popup()
		check(popup.visible,tag+" dropdown did not open")
		if popup.visible:
			check(popup.size.x>0 and popup.size.y>0,tag+" empty dropdown")
			await screenshot(tag+"-dropdown")
			popup.hide()
		game.build_mode=false;game._update_ui();await settle()
		fits(game.hud.walking.controls,tag+" walking controls")
		fits(game.hud.walking.horse_panel,tag+" horse stamina")
		fits(game.weapons.status,tag+" weapon status")
		check(rect(game.weapons.reticle).get_center().distance_to(root.get_visible_rect().get_center())<1,tag+" reticle off center")
		game.weapons.status.visible=true;game.weapons.status.text="P-8 · 8 / 24\nR recarregar · P guardar"
		game.hud.walking.attention.visible=true;game.hud.walking.attention.text="Ninho cheio · Coletar ovos"
		check(not rect(game.weapons.status).intersects(rect(game.hud.walking.attention)),tag+" weapon overlaps attention")
		await screenshot(tag+"-walk")
		fits(game.navigator.mini,tag+" minimap")
		game._action("map");await settle();modal_bounds(tag+" valley map")
		var point:=Vector2(100,-80)
		await click_at(game.navigator.large.get_global_transform_with_canvas()*game.navigator.large.project(point))
		check(game.navigator.waypoint.distance_to(point)<1,tag+" map click transform incorrect")
		await screenshot(tag+"-map")
		var map_key:=InputEventKey.new();map_key.physical_keycode=KEY_M;map_key.keycode=KEY_M;map_key.pressed=true
		root.push_input(map_key,true);await settle()
		check(game.hud.modal_kind.is_empty(),tag+" M did not close map")
		game.hud.menu(game.state);await settle();modal_bounds(tag+" menu")
		actions.clear()
		await click_at(game.hud.modal.get_global_transform_with_canvas()*Vector2(305,165))
		check(actions.has("close") and game.hud.modal_kind.is_empty(),tag+" transformed modal click failed")
		game.hud.staff_panel(game.state);await settle();modal_bounds(tag+" staff")
		game.hud.close_modal()
	# Actual OS transitions: welcome LineEdit owns keyboard focus.
	if DisplayServer.get_name()!="headless":
		root.size=Vector2i(1280,720);await settle()
		game.hud.welcome(game.state,false);game.hud.text_input.grab_focus();await settle()
		var old_text:String=game.hud.text_input.text
		for cycle in range(10):
			await f11()
			check(root.mode==Window.MODE_EXCLUSIVE_FULLSCREEN or root.mode==Window.MODE_FULLSCREEN,"F11 failed to enter fullscreen cycle "+str(cycle))
			var full_mode:=root.mode
			await f11(true)
			check(root.mode==full_mode,"F11 echo changed mode")
			modal_bounds("fullscreen cycle "+str(cycle))
			if cycle==0:await screenshot("native-fullscreen")
			await f11()
			check(root.mode==Window.MODE_WINDOWED,"F11 failed to leave fullscreen")
			check(root.size==Vector2i(1280,720),"window size not restored")
		check(game.hud.modal_kind=="welcome" and game.hud.text_input.text==old_text,"F11 disturbed focused welcome form")
		# The shooting ray and reticle still agree after all resize/transitions.
		game.hud.close_modal();game.build_mode=false;game.actor.stop_emote()
		game.player.position=Vector3(-28.8,0,18)
		game.camera.position=Vector3(-24.5,2.6,20.4)
		game.camera.look_at(Vector3(-33.2,1.56,18))
		FarmArmory.buy_pistol(game.state,game.state.armory)
		var draw:=InputEventKey.new();draw.physical_keycode=KEY_P;draw.pressed=true
		game.weapons.handle_input(draw);await settle()
		await f11();await settle()
		check(game.weapons.armed,"F11 holstered a drawn weapon")
		check(game.weapons.shoot() and game.state.armory.hits==1,"Reticle/ray disagree after fullscreen transitions")
		await screenshot("fullscreen-pistol")
		game.weapons.holster()
		game.horse.mount(game.player,game.avatar,game.actor)
		var inventory:Dictionary=game.state.armory.duplicate()
		await f11();await f11()
		check(game.horse.mounted and game.state.armory==inventory and not game.weapons.armed,"Fullscreen transition disturbed mounted state")
		# Report a short frame-time sample; this is a local smoke check, not an FPS guarantee.
		var frames:Array[float]=[]
		for frame in range(60):
			var started:=Time.get_ticks_usec();await process_frame
			frames.append((Time.get_ticks_usec()-started)/1000.0)
		frames.sort()
		print("FULLSCREEN_FRAMETIME_MS median=",frames[30]," p95=",frames[57]," max=",frames[59])
	game.session_started=false
	game.audio.stop_all();await create_timer(.2).timeout
	game.queue_free();await process_frame;await create_timer(.2).timeout
	print("FULLSCREEN_QA_OK" if failures.is_empty() else "FULLSCREEN_QA_FAILED: "+str(failures))
	quit(0 if failures.is_empty() else 1)
