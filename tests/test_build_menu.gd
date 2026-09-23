extends SceneTree
var game:Node3D
func _initialize() -> void:call_deferred("run")
func capture(key:String) -> void:
	if DisplayServer.get_name()=="headless":return
	await create_timer(.15).timeout;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/build-menu-"+key+".png")
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	game=load("res://scenes/main.tscn").instantiate();game.save_path="user://qa_build_menu.json";game.qa_mode=true
	root.add_child(game);await process_frame
	game.set_process(false);game.set_physics_process(false)
	game.session_started=true;game.hud.close_modal();game.build_mode=true
	game.state=FarmState.new();game.state.unlimited_money=true;game.state.farm_xp=950
	game.state.claim(Vector2(4,-2));game.state.land_size=40
	game.state.place("barn",Vector2(8,-10),0);game.state.place("coop",Vector2(18,-6),0)
	game.state.place("stable",Vector2(-6,-8),0);game.state.place("corral",Vector2(18,8),0)
	game.world.rebuild(game.state);game.selected=-1;game.tool="inspect"
	game.focus=Vector3(4,0,-2);game.camera.position=Vector3(-18,27,35);game.camera.look_at(Vector3(4,0,-2))
	game.hud.toast_time=0;game._update_ui();game.hud.toast_time=0
	var menu:FarmBuildHUD=game.hud.construction
	assert(not game.hud.legacy_build.visible and not menu.selection.visible)
	assert(menu.cards.size()==3 and menu.category=="Estruturas")
	assert(not menu.seed_panel.visible and not menu.paint_panel.visible and not menu.help_panel.visible)
	await process_frame
	assert(menu.cards["barn"].get_meta("picture").size==Vector2(90,90))
	await capture("catalog")
	menu.tabs["Animais"].pressed.emit()
	assert(menu.cards.has("coop") and menu.cards.has("corral") and menu.cards.has("stable") and menu.cards.has("pigsty"))
	assert(not menu.cards.has("barn"))
	await capture("animals")
	game.state.elapsed=280;game.world.day_night.update_cycle(280,game.player.position);game._update_ui();await capture("night")
	game.state.elapsed=0;game.world.day_night.update_cycle(0,game.player.position)
	menu.tabs["Lavoura"].pressed.emit();menu.cards["plot"].pressed.emit()
	assert(game.tool=="plot" and menu.seed_panel.visible)
	menu.seed_panel.get_child(2).pressed.emit();assert(game.crop=="corn");await capture("seeds")
	game._action("tool:stable");assert(menu.category=="Animais" and menu.cards.has("stable"))
	# Editing selects first; opening a care/storage modal is an explicit action.
	game._action("tool:inspect")
	if DisplayServer.get_name()!="headless":
		var motion:=InputEventMouseMotion.new();motion.position=game.camera.unproject_position(Vector3(8,1,-10))
		root.warp_mouse(motion.position);Input.parse_input_event(motion);root.push_input(motion,true)
		game._update_pointer();game._click_world()
		assert(game.selected==0 and game.hud.modal_kind.is_empty())
	else:game.selected=0;game._update_ui()
	assert(menu.selection.visible and not menu.paint_panel.visible)
	menu.paint_button.pressed.emit();assert(menu.paint_panel.visible)
	game.hud.paint_selector.select(1);game._action("paint:2")
	assert(game.state.items[0].get("roof_paint",-1)==2)
	game.hud.toast_time=0;await capture("paint")
	menu.open_button.pressed.emit();assert(game.hud.modal_kind=="barn")
	game.hud.close_modal();game._action("move");assert(game.move_index==0)
	game._action("build:clear");assert(game.move_index==-1 and game.selected==-1 and not menu.selection.visible)
	game.state.farm_xp=0;menu.tabs["Estruturas"].pressed.emit();game._update_ui()
	assert(menu.cards["barn"].get_meta("price").text.begins_with("Nível"))
	menu.cards["barn"].pressed.emit();assert(not game.hud.modal_kind.is_empty());game.hud.close_modal()
	game.state.farm_xp=950;game._action("build:clear")
	if DisplayServer.get_name()!="headless":
		game._toggle_fullscreen(false);root.size=Vector2i(1024,640);await create_timer(.3).timeout
		game._update_ui();game.hud.toast_time=0;await capture("small")
		var fit:float=game.hud.scale.x
		assert(menu.catalog.position.y+menu.catalog.size.y<=900)
		assert(fit>0 and menu.catalog.size.x*fit<=root.get_visible_rect().size.x)
	game._action("mode");assert(game.hud.walking.root.visible and not game.hud.build_hud.visible)
	print("BUILD_MENU_OK: categories, seed, shortcuts, selection actions, paint, modal, cancel, level lock, fit and walking")
	game.session_started=false;game.audio.stop_all();await create_timer(.2).timeout;game.queue_free();await process_frame;await create_timer(.2).timeout;quit()
