extends "res://tests/test_coop.gd"

func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	mode=OS.get_cmdline_user_args()[0];flags=OS.get_cmdline_user_args()[1]
	game=load("res://scenes/main.tscn").instantiate();game.name="Main";game.save_path="user://sandbox_solo.json"
	root.add_child(game);await process_frame
	game.qa_mode=true;game.set_physics_process(false)
	game.state=FarmState.new_farm("sandbox" if mode=="host" else "survival")
	game.state.claim(Vector2(4,0));game._save_game(false,true)
	solo=FileAccess.get_file_as_string(game.save_path);n=game.network
	if mode=="host":
		n.host("Vitor");game.hud.close_modal();flag("host_ready")
		await until(func():return exists("client_ready") and n.accepted!=0)
		await until(func():return game.state.revenue==500)
		assert(game.state.inventory.egg==0 and game.state.stock_text("egg")=="∞")
		assert(game.weapons.combat.bag_for(n.accepted).pistol)
		flag("sale_seen")
		await until(func():return exists("client_done") and n.accepted==0)
		assert(n.save_coop())
		var saved:=FarmCoop.load_farm(n.coop_path)
		assert(saved.stock_text("copper")=="∞" and saved.resources.gallery_level==2)
		n.leave("Fim")
	else:
		n.join("127.0.0.1","Ian");await until(func():return n.ready_session)
		game.hud.close_modal();flag("client_ready")
		assert(game.state.infinite_resources() and game.state.resources.gallery_level==2)
		n.show_stock();n.update_stock()
		for label in n.stock_labels.values():assert("∞" in label.text)
		game.hud.close_modal();n.request_command({"action":"sell_product:egg","quantity":50})
		await until(func():return exists("sale_seen") and game.state.revenue==500)
		assert(game.state.inventory.egg==0 and game.state.stock_text("egg")=="∞")
		flag("client_done");n.leave("Fim")
		assert(not game.state.infinite_resources() and game.state.stock("egg")==0)
	assert(FileAccess.get_file_as_string(game.save_path)==solo)
	game.session_started=false;game.audio.set_process(false);game.audio.stop_all()
	await create_timer(.2).timeout;game.queue_free();await process_frame;await create_timer(.2).timeout
	print("COOP_QA_OK: COOP_SANDBOX_OK: "+mode+" infinite stocks, host-authoritative sale, save and survival visitor restoration")
	quit()
