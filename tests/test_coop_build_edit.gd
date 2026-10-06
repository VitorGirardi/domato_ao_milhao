extends "res://tests/test_coop.gd"
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	mode=OS.get_cmdline_user_args()[0];flags=OS.get_cmdline_user_args()[1]
	game=load("res://scenes/main.tscn").instantiate();game.name="Main";game.save_path="user://build_edit_solo.json";root.add_child(game);await process_frame
	game.qa_mode=true;game.state=FarmState.new_farm("survival");game.state.farm_xp=950
	if mode=="host":
		game.state.claim(Vector2(4,0));game.state.land_size=40
		assert(game.state.place("barn",Vector2(8,-10),0).is_empty());game.state.items[0].level=2
	game._save_game(false,true);solo=FileAccess.get_file_as_string(game.save_path);n=game.network
	if mode=="host":
		n.host("Obras QA");game.hud.close_modal();flag("host_ready")
		await until(func():return n.accepted!=0 and exists("client_moved"))
		assert(game.state.items[0].x==0 and game.state.items[0].level==2)
		await until(func():return exists("review_open"))
		# A remote structural change invalidates the client's open sale review.
		n.request_command({"action":"move_item","index":0,"at":Vector2(8,-10),"turn":0})
		flag("host_moved")
		await until(func():return exists("client_sold"))
		assert(game.state.items.is_empty() and game.state.money==1260)
		assert(n.save_coop());n.leave("Fim")
	else:
		n.join("127.0.0.1","Visitante");await until(func():return n.ready_session)
		game.hud.close_modal();game.build_mode=true;game.selected=0;game.tool="inspect";game._update_ui()
		game.hud.construction.move_button.pressed.emit();game.pointer=Vector2(0,4);game.pointer_valid=true;game._click_world()
		await until(func():return not n.command_busy and game.state.items[0].x==0)
		assert(game.move_index==-1 and game.tool=="inspect");flag("client_moved")
		game.selected=0;game._update_ui();game.hud.construction.sell_button.pressed.emit()
		assert(game.hud.modal_kind=="build_sale");flag("review_open")
		await until(func():return exists("host_moved") and game.state.items[0].x==8)
		assert(game.hud.modal_kind!="build_sale");game._action("build:sell_confirm");assert(game.state.items.size()==1)
		game.selected=0;game._update_ui();game.hud.construction.sell_button.pressed.emit();game._action("build:sell_confirm")
		await until(func():return not n.command_busy and game.state.items.is_empty())
		assert(game.state.money==1260);flag("client_sold");await until(func():return not n.active)
	assert(FileAccess.get_file_as_string(game.save_path)==solo)
	game.session_started=false;game.audio.stop_all();await create_timer(.2).timeout;game.queue_free();await process_frame;await create_timer(.2).timeout
	print("COOP_QA_OK: ",mode," free move, stale review, confirmed half refund, replication and isolated solo save")
	quit()
