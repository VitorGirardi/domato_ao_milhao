extends "res://tests/test_coop.gd"

func command(value:Dictionary) -> void:
	await until(func():return not n.command_busy)
	n.request_command(value);await until(func():return not n.command_busy)
	await create_timer(.15).timeout

func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	mode=OS.get_cmdline_user_args()[0];flags=OS.get_cmdline_user_args()[1]
	game=load("res://scenes/main.tscn").instantiate();game.name="Main";game.save_path="user://pigs_solo.json";root.add_child(game)
	await process_frame;game.qa_mode=true;game.state.unlimited_money=true
	if mode=="host":
		game.state.claim(Vector2(4,0));game.state.farm_xp=120
	game._save_game(false,true);solo=FileAccess.get_file_as_string(game.save_path);n=game.network
	if mode=="host":
		n.host("Vitor");game.hud.close_modal();flag("host_ready")
		await until(func():return exists("bought"))
		assert(game.state.items[0].kind=="pigsty" and game.state.items[0].pigs.count==1)
		var path:=n.coop_path;n.coop_path="user://missing_pigs_folder/coop.json"
		await command({"action":"pigs:buy","index":0})
		assert(game.state.items[0].pigs.count==1,"Failed disk save must roll back purchase")
		n.coop_path=path
		game.state.items[0].pigs.food=20;game.state.items[0].pigs.water=20;n.broadcast_state();flag("needs_care")
		await until(func():return exists("cared"))
		assert(game.state.items[0].pigs.food>95 and game.state.items[0].pigs.water>95)
		await command({"action":"pigs:buy","index":0})
		flag("host_bought");await until(func():return exists("full"))
		assert(game.state.items[0].pigs.count==3)
		assert(n.save_coop());flag("saved")
		await until(func():return exists("client_done") and n.accepted==0)
		n.leave("Fim");assert(FileAccess.get_file_as_string(game.save_path)==solo)
		var persisted:=FarmCoop.load_farm(path);assert(persisted.items[0].pigs.count==3)
	else:
		n.join("127.0.0.1","Ian");await until(func():return n.ready_session)
		game.hud.close_modal()
		await command({"action":"place","kind":"pigsty","at":Vector2(4,0),"turn":0})
		assert(game.state.items.size()==1)
		game.selected=0;game._action("pigs:review");assert(game.hud.modal_kind=="pig_confirm")
		game._action("pigs:back");assert(game.state.items[0].pigs.count==0)
		game._action("pigs:buy");await until(func():return game.state.items[0].pigs.count==1 and not n.command_busy)
		var seq:=n.sequence
		n._command.rpc_id(1,seq,n.structure_version,{"action":"pigs:buy","index":0})
		await create_timer(.2).timeout;assert(game.state.items[0].pigs.count==1);flag("bought")
		await until(func():return exists("needs_care") and game.state.items[0].pigs.food<30)
		await command({"action":"pigs:food","index":0});await command({"action":"pigs:water","index":0});flag("cared")
		await until(func():return exists("host_bought") and game.state.items[0].pigs.count==2)
		await command({"action":"pigs:buy","index":0});assert(game.state.items[0].pigs.count==3)
		await command({"action":"pigs:buy","index":0});assert(game.state.items[0].pigs.count==3)
		await command({"action":"remove","index":0});assert(game.state.items.size()==1)
		await until(func():return n.visual_state.has("pig_0_2"))
		assert(game.world.pigsties[0].pigs[2].node.visible)
		if DisplayServer.get_name()!="headless":
			game.selected=0;game._tend_selected();await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(flags.path_join("coop-pigs.png"))
		flag("full");await until(func():return exists("saved"));flag("client_done");n.leave("Fim")
		assert(FileAccess.get_file_as_string(game.save_path)==solo)
	game.audio.stop_all();game.queue_free();await process_frame;await create_timer(.2).timeout
	print("COOP_QA_OK: ",mode," pigsty placement, remote UI purchase/cancel, replay protection, care, host purchase, capacity, visual replication and isolated save rollback")
	quit()
