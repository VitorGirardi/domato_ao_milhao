extends SceneTree
var game:Node3D
func _initialize() -> void:call_deferred("run")
func capture(key:String) -> void:
	if DisplayServer.get_name()=="headless":return
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/build-edit-"+key+".png")
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	game=load("res://scenes/main.tscn").instantiate();game.save_path="user://build-edit.json";root.add_child(game)
	await process_frame;game.qa_mode=true;game.set_process(false);game.set_physics_process(false)
	game.residents_world.set_process(false);game.pickup.set_physics_process(false)
	game.session_started=true;game.build_mode=true;game.hud.close_modal()
	game.state=FarmState.new_farm("survival");game.state.money=20000;game.state.farm_xp=950
	assert(game.state.claim(Vector2(4,0)).is_empty());game.state.land_size=40
	assert(game.state.place("barn",Vector2(8,-10),0).is_empty())
	assert(game.state.place("coop",Vector2(-6,-8),0).is_empty())
	game.state.items[0].level=2
	game.state.items[1].young_ages=[0.0,0.0,0.0]
	game.world.rebuild(game.state);await physics_frame
	game.camera.position=Vector3(-18,27,35);game.camera.look_at(Vector3(4,0,-2))
	game.selected=0;game.tool="inspect";game._update_ui()
	var menu:FarmBuildHUD=game.hud.construction
	assert(menu.move_tool.visible and menu.sell_tool.visible and menu.sell_button.text=="Vender $300")
	await capture("selected")
	menu.move_tool.pressed.emit();assert(game.tool=="select_move")
	if DisplayServer.get_name()!="headless":
		var motion:=InputEventMouseMotion.new();motion.position=game.camera.unproject_position(Vector3(8,1,-10))
		root.warp_mouse(motion.position);Input.parse_input_event(motion);root.push_input(motion,true)
		game._update_pointer();game._click_world();assert(game.move_index==0)
	menu.cancel_move.pressed.emit();game.selected=0;game._update_ui()
	menu.sell_tool.pressed.emit();assert(game.tool=="select_sell")
	if DisplayServer.get_name()!="headless":
		game._update_pointer();game._click_world();assert(game.hud.modal_kind=="build_sale")
		game._action("close")
	game._action("build:clear");game.selected=0;game._update_ui()
	var before:Dictionary=game.state.serialize()
	menu.move_button.pressed.emit();assert(game.move_index==0 and game.tool=="move")
	game.pointer=Vector2(-6,-8);game.pointer_valid=true;game._click_world()
	assert(game.move_index==0 and game.state.serialize()==before,"Occupied placement must preserve the structure")
	menu.cancel_move.pressed.emit();assert(game.state.serialize()==before and game.move_index==-1)
	game.selected=1;game._action("move");game.pointer=Vector2(-6,6);game.pointer_valid=true;game._click_world()
	assert(game.move_index==-1 and game.state.items[1].x==-6 and game.state.items[1].z==6)
	assert(game.state.items[1].young_ages==before.items[1].young_ages and game.state.money==before.money)
	var loaded:=FarmState.new();assert(loaded.restore(JSON.parse_string(FileAccess.get_file_as_string(game.save_path))))
	assert(loaded.items[1].z==6)
	game.selected=0;game._update_ui();menu.sell_button.pressed.emit()
	assert(game.hud.modal_kind=="build_sale");await capture("confirm")
	game._action("close");assert(game.state.items.size()==2)
	# Failed persistence leaves the building and wallet intact.
	menu.sell_button.pressed.emit();before=game.state.serialize()
	game.save_path="user://missing/farm.json";game._action("build:sell_confirm")
	assert(game.state.serialize()==before)
	game.save_path="user://build-edit.json";menu.sell_button.pressed.emit();game._action("build:sell_confirm")
	assert(game.state.items.size()==1 and game.state.money==before.money+300)
	game._action("build:sell_confirm");assert(game.state.money==before.money+300,"No repeated refund")
	assert(loaded.restore(JSON.parse_string(FileAccess.get_file_as_string(game.save_path))) and loaded.items.size()==1)
	# Production is checked again at confirmation, not only when the dialog opened.
	game.selected=0;game._update_ui();menu.sell_button.pressed.emit();game.state.items[0].flock.nest=1
	game._action("build:sell_confirm");assert(game.state.items.size()==1)
	if DisplayServer.get_name()!="headless":
		game._toggle_fullscreen(false);root.size=Vector2i(1024,640);await create_timer(.3).timeout
		game._update_ui();await capture("small")
	game.session_started=false;game.audio.stop_all();game.queue_free();await process_frame;await create_timer(.2).timeout
	print("BUILD_EDIT_OK: explicit tools, blocked/cancelled/free move, preserved young animals, confirmation, half refund, save and rollback")
	quit()
