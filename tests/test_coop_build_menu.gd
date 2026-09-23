extends "res://tests/test_coop.gd"
func mouse_build(at:Vector3) -> void:
	game.build_mode=true;game.hud.close_modal();game._action("tool:plot")
	await process_frame
	game.camera.position=at+Vector3(0,24,20);game.camera.look_at(at)
	var motion:=InputEventMouseMotion.new();motion.position=game.camera.unproject_position(at)
	root.warp_mouse(motion.position)
	Input.parse_input_event(motion)
	root.push_input(motion,true)
	game._update_pointer()
	assert(game.pointer_valid and game.pointer.distance_to(Vector2(at.x,at.z))<.1)
	assert(game.ghost.visible and game.world.build_grid.visible)
	game._click_world()
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	mode=OS.get_cmdline_user_args()[0];flags=OS.get_cmdline_user_args()[1]
	game=load("res://scenes/main.tscn").instantiate();game.name="Main";game.save_path="user://build_menu_solo.json";root.add_child(game);await process_frame
	game.qa_mode=true;game.state.unlimited_money=true
	if mode=="host":game.state.claim(Vector2(4,0));game.state.farm_xp=1000
	game._save_game(false,true);solo=FileAccess.get_file_as_string(game.save_path);n=game.network
	if mode=="host":
		n.host("Vitor");game.hud.close_modal();flag("host_ready")
		await until(func():return n.accepted!=0 and exists("client_built"))
		assert(game.state.count_items("plot")==1)
		await mouse_build(Vector3(8,0,0));assert(game.state.count_items("plot")==2)
		flag("host_built");await until(func():return exists("client_done"))
		n.leave("Fim")
	else:
		n.join("127.0.0.1","Ian");await until(func():return n.ready_session)
		game.hud.close_modal();await mouse_build(Vector3(4,0,0))
		await until(func():return game.state.count_items("plot")==1);flag("client_built")
		await until(func():return exists("host_built") and game.state.count_items("plot")==2)
		var escape:=InputEventKey.new();escape.keycode=KEY_ESCAPE;escape.pressed=true
		game._unhandled_input(escape)
		assert(game.tool=="inspect" and game.hud.modal_kind.is_empty())
		flag("client_done");await until(func():return not n.active)
	assert(FileAccess.get_file_as_string(game.save_path)==solo)
	game.session_started=false;game.audio.stop_all();await create_timer(.3).timeout;game.queue_free();await process_frame;await create_timer(.3).timeout
	print("COOP_QA_OK: ",mode," real pointer projection, build preview, mouse placement, replication, Escape cancel and solo preservation")
	quit()
