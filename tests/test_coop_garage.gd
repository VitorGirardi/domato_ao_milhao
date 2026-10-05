extends "res://tests/test_coop.gd"
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	mode=OS.get_cmdline_user_args()[0];flags=OS.get_cmdline_user_args()[1]
	game=load("res://scenes/main.tscn").instantiate();game.name="Main";game.save_path="user://garage_coop_solo.json";root.add_child(game);await process_frame
	game.qa_mode=true;game.state=FarmState.new_farm("sandbox")
	if mode=="host":game.state.claim(Vector2(4,0))
	game._save_game(false,true);solo=FileAccess.get_file_as_string(game.save_path);n=game.network
	if mode=="host":
		n.host("Garagem QA");game.hud.close_modal();flag("host_ready")
		await until(func():return n.accepted!=0 and game.state.count_items("garage")==1)
		assert(game.state.items[0].kind=="garage");n.request_command({"action":"move_item","index":0,"at":Vector2(4,0),"turn":1})
		await until(func():return exists("client_checked"))
		assert(not FarmGarage.config(game.state).engine)
		n.leave("Fim")
	else:
		n.join("127.0.0.1","Garagista");await until(func():return n.ready_session)
		n.request_command({"action":"place","kind":"garage","at":Vector2(4,0),"turn":0,"crop":"carrot"})
		await until(func():return game.state.count_items("garage")==1 and game.state.items[0].turn==1)
		game._action("garage:open");var before:Dictionary=game.state.serialize();game._action("garage:buy:engine");assert(game.state.serialize()==before)
		assert(not game.pickup.visible);flag("client_checked");await until(func():return not n.active)
	assert(FileAccess.get_file_as_string(game.save_path)==solo)
	game.session_started=false;game.audio.stop_all();await create_timer(.3).timeout;game.queue_free();await process_frame;await create_timer(.3).timeout
	print("COOP_QA_OK: ",mode," garage construction and rotation replicated, solo upgrades gated, original farm preserved")
	quit()
