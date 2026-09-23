extends "res://tests/test_coop.gd"
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	mode=OS.get_cmdline_user_args()[0];flags=OS.get_cmdline_user_args()[1]
	game=load("res://scenes/main.tscn").instantiate();game.name="Main";game.save_path="user://night_solo.json";root.add_child(game);await process_frame
	game.qa_mode=true;game.state.unlimited_money=true
	if mode=="host":
		game.state.claim(Vector2(4,0));game.state.elapsed=300
	game._save_game(false,true);solo=FileAccess.get_file_as_string(game.save_path);n=game.network
	if mode=="host":
		n.host("Vitor");game.hud.close_modal();flag("host_ready")
		await until(func():return n.accepted!=0 and exists("night_seen"))
		game.state.elapsed=320;n.broadcast_state()
		await until(func():return exists("midnight_seen"))
		game.state.elapsed=440;n.broadcast_state()
		await until(func():return exists("dawn_seen"))
		assert(n.save_coop())
		var loaded:=FarmCoop.load_farm(n.coop_path)
		assert(loaded!=null and FarmDayNight.hour_at(loaded.elapsed)>=6)
		flag("host_done");await until(func():return n.accepted==0)
		n.leave("Fim")
	else:
		n.join("127.0.0.1","Ian");await until(func():return n.ready_session)
		game.hud.close_modal()
		await until(func():return game.world.day_night.night_amount>0.99)
		assert(FarmDayNight.hour_at(game.state.elapsed)>23);flag("night_seen")
		await until(func():return game.state.elapsed>=320)
		assert(FarmDayNight.day_at(game.state.elapsed)==2)
		assert(game.world.day_night.night_amount>0.99);flag("midnight_seen")
		await until(func():return game.state.elapsed>=440 and game.world.day_night.night_amount<0.9)
		flag("dawn_seen");await until(func():return exists("host_done"))
		n.leave("Fim");await process_frame;await process_frame
		assert(game.world.day_night.night_amount<0.01)
	assert(FileAccess.get_file_as_string(game.save_path)==solo)
	game.session_started=false;game.audio.stop_all();await create_timer(.3).timeout;game.queue_free();await process_frame;await create_timer(.3).timeout
	print("COOP_QA_OK: ",mode," shared night, midnight, dawn, persistence and solo restoration")
	quit()
