extends "res://tests/test_coop.gd"
func move_to(at:Vector2) -> void:
	game.player.position=Vector3(at.x,FarmLandscape.height_at(at)+.1,at.y)
	game.player.velocity=Vector3.ZERO;game.actor.airborne=false;game.actor.swimming=false
func command() -> void:
	await until(func():return not n.command_busy)
	n.request_command({"action":"young:adopt","index":0})
	await until(func():return not n.command_busy)
	await create_timer(.15).timeout
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	mode=OS.get_cmdline_user_args()[0];flags=OS.get_cmdline_user_args()[1]
	game=load("res://scenes/main.tscn").instantiate();game.name="Main";game.save_path="user://animals_solo.json";root.add_child(game)
	await process_frame;game.qa_mode=true;game.set_physics_process(false)
	game.state=FarmState.new_farm("survival");game.state.farm_xp=950;game.state.money=20000;game.state.inventory.egg=6
	if mode=="host":
		assert(game.state.claim(Vector2(4,0)).is_empty());game.state.land_size=40;assert(game.state.place("coop",Vector2(4,0),0).is_empty())
		assert(game.state.place("corral",Vector2(-6,0),0).is_empty());assert(FarmYoung.adopt(game.state,1).is_empty())
		assert(game.state.place("pigsty",Vector2(14,0),0).is_empty());assert(FarmYoung.adopt(game.state,2).is_empty())
	assert(game._save_game(false,true));solo=FileAccess.get_file_as_string(game.save_path);n=game.network
	if mode=="host":
		n.host("Vitor");game.hud.close_modal();flag("host_ready")
		await until(func():return exists("far_done"))
		assert(not game.state.items[0].has("young_ages"));flag("far_checked")
		await until(func():return exists("near_ready"))
		var path:String=n.coop_path;n.coop_path="user://missing_animals/coop.json";flag("disk_broken")
		await until(func():return exists("failed_done"))
		assert(not game.state.items[0].has("young_ages"));n.coop_path=path;flag("disk_fixed")
		await until(func():return exists("cared"))
		assert(game.state.items[0].young_ages.size()==6 and FarmYoung.progress(game.state.items[0],3)<.1)
		assert(n.save_coop());var loaded:=FarmCoop.load_farm(path)
		assert(loaded.items[0].young_ages.size()==6);flag("saved")
		await until(func():return exists("client_done") and n.accepted==0)
		n.leave("Fim");assert(not game.state.items[0].has("young_ages"))
	else:
		n.join("127.0.0.1","Ian");await until(func():return n.ready_session);game.hud.close_modal()
		move_to(Vector2(60,60));await create_timer(.6).timeout
		assert(FarmYoung.progress(game.state.items[1])<.1 and game.state.items[1].dairy.milk==0)
		assert(game.world.cows[0].node.scale.x<.55 and game.world.pigsties[0].pigs[0].node.scale.x<.5)
		await command();assert(not game.state.items[0].has("young_ages"));flag("far_done")
		await until(func():return exists("far_checked"))
		move_to(Vector2(4,3.5));await create_timer(.6).timeout;flag("near_ready")
		await until(func():return exists("disk_broken"));await command()
		assert(not game.state.items[0].has("young_ages"));flag("failed_done")
		await until(func():return exists("disk_fixed"))
		game.selected=0;game._action("young:open");assert(game.hud.modal_kind=="young")
		game._action("young:adopt");await until(func():return not n.command_busy and game.state.items[0].has("young_ages"))
		assert(game.state.items[0].young_ages.size()==6)
		n._command.rpc_id(1,n.sequence,n.structure_version,{"action":"young:adopt","index":0})
		await command();assert(game.state.items[0].young_ages.size()==6);flag("cared")
		await until(func():return exists("saved"))
		assert(not FileAccess.file_exists(n.coop_path));flag("client_done");n.leave("Fim")
	assert(FileAccess.get_file_as_string(game.save_path)==solo)
	game.session_started=false;game.audio.set_process(false);game.audio.stop_all();game.queue_free();await process_frame;await create_timer(.2).timeout
	print("COOP_QA_OK: YOUNG_NETWORK_OK: "+mode+" remote distance, rollback, panel action, authoritative comfort, no duplicate/replay and isolated persistence")
	quit()
