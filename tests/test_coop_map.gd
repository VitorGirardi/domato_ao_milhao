extends "res://tests/test_coop.gd"
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	mode=OS.get_cmdline_user_args()[0];flags=OS.get_cmdline_user_args()[1]
	game=load("res://scenes/main.tscn").instantiate();game.name="Main";game.save_path="user://map_solo.json";root.add_child(game)
	await process_frame;game.qa_mode=true;game.state.unlimited_money=true;game.state.farm_xp=100000
	if mode=="host":
		game.state.claim(Vector2(4,0));assert(game.state.place("coop",Vector2(4,0),0).is_empty())
		game.state.items[0].flock.nest=6;game.state.items[0].flock.water=10
	game._save_game(false,true);solo=FileAccess.get_file_as_string(game.save_path);n=game.network
	if mode=="host":
		n.host("Vitor");game.hud.close_modal();flag("host_ready")
		await until(func():return n.accepted!=0 and exists("selected"))
		game.navigator.handle("map:go:friend");assert(game.navigator.target_key=="friend")
		game.player.position=Vector3(12,0,8);flag("moved")
		await until(func():return exists("client_done") and n.accepted==0)
		game.navigator.refresh();assert(game.navigator.target_key.is_empty())
		n.leave("Fim")
	else:
		n.join("127.0.0.1","Ian");await until(func():return n.ready_session and game.world.cat.visible)
		game.hud.close_modal();game.navigator.handle("map:go:cat");assert(game.navigator.target_key=="cat")
		assert(FarmMapPlaces.notices(game.state.items[0]).contains("água"))
		game.navigator.handle("map:go:friend");assert(game.navigator.waypoint_name=="Vitor");flag("selected")
		await until(func():return exists("moved") and Vector2(n.remote.position.x,n.remote.position.z).distance_to(Vector2(12,8))<.5)
		game.navigator.refresh();assert(game.navigator.waypoint.distance_to(Vector2(12,8))<.5)
		flag("client_done");n.leave("Fim")
	assert(FileAccess.get_file_as_string(game.save_path)==solo)
	game.audio.stop_all();game.queue_free();await process_frame;await create_timer(.2).timeout
	print("COOP_QA_OK: map remote player, moving destination, cat, shared care notices and disconnect")
	quit()
