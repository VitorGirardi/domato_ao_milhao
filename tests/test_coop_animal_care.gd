extends "res://tests/test_coop.gd"
func move_to(at:Vector2) -> void:
	game.player.position=Vector3(at.x,FarmLandscape.height_at(at)+.1,at.y)
	game.player.velocity=Vector3.ZERO;game.actor.airborne=false;game.actor.swimming=false
func command() -> void:
	await until(func():return not n.command_busy)
	n.request_command({"action":"animal:care","index":0})
	await until(func():return not n.command_busy)
	await create_timer(.15).timeout
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	mode=OS.get_cmdline_user_args()[0];flags=OS.get_cmdline_user_args()[1]
	game=load("res://scenes/main.tscn").instantiate();game.name="Main";game.save_path="user://animals_solo.json";root.add_child(game)
	await process_frame;game.qa_mode=true;game.set_physics_process(false)
	game.state=FarmState.new_farm("survival");game.state.farm_xp=950;game.state.money=20000
	if mode=="host":
		assert(game.state.claim(Vector2(4,0)).is_empty());assert(game.state.place("coop",Vector2(4,0),0).is_empty())
	assert(game._save_game(false,true));solo=FileAccess.get_file_as_string(game.save_path);n=game.network
	if mode=="host":
		n.host("Vitor");game.hud.close_modal();flag("host_ready")
		await until(func():return exists("far_done"))
		assert(not game.state.items[0].has("animal_care"));flag("far_checked")
		await until(func():return exists("near_ready"))
		var path:String=n.coop_path;n.coop_path="user://missing_animals/coop.json";flag("disk_broken")
		await until(func():return exists("failed_done"))
		assert(not game.state.items[0].has("animal_care"));n.coop_path=path;flag("disk_fixed")
		await until(func():return exists("cared"))
		assert(game.state.items[0].animal_care.visits==1 and FarmAnimalCare.seconds(game.state.items[0])>470)
		assert(n.save_coop());var loaded:=FarmCoop.load_farm(path)
		assert(loaded.items[0].animal_care.visits==1);flag("saved")
		await until(func():return exists("client_done") and n.accepted==0)
		n.leave("Fim");assert(not game.state.items[0].has("animal_care"))
	else:
		n.join("127.0.0.1","Ian");await until(func():return n.ready_session);game.hud.close_modal()
		move_to(Vector2(60,60));await create_timer(.6).timeout
		await command();assert(not game.state.items[0].has("animal_care"));flag("far_done")
		await until(func():return exists("far_checked"))
		move_to(Vector2(4,3.5));await create_timer(.6).timeout;flag("near_ready")
		await until(func():return exists("disk_broken"));await command()
		assert(not game.state.items[0].has("animal_care"));flag("failed_done")
		await until(func():return exists("disk_fixed"))
		game.selected=0;game._action("animal:open");assert(game.hud.modal_kind=="animal_care")
		game._action("animal:care");await until(func():return not n.command_busy and game.state.items[0].has("animal_care"))
		assert(game.state.items[0].animal_care.visits==1)
		n._command.rpc_id(1,n.sequence,n.structure_version,{"action":"animal:care","index":0})
		await command();assert(game.state.items[0].animal_care.visits==1);flag("cared")
		await until(func():return exists("saved"))
		assert(not FileAccess.file_exists(n.coop_path));flag("client_done");n.leave("Fim")
	assert(FileAccess.get_file_as_string(game.save_path)==solo)
	game.session_started=false;game.audio.set_process(false);game.audio.stop_all();game.queue_free();await process_frame;await create_timer(.2).timeout
	print("COOP_QA_OK: ANIMAL_CARE_NETWORK_OK: "+mode+" remote distance, rollback, panel action, authoritative comfort, no duplicate/replay and isolated persistence")
	quit()
