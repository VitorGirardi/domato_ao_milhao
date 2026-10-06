extends "res://tests/test_coop.gd"
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	mode=OS.get_cmdline_user_args()[0];flags=OS.get_cmdline_user_args()[1]
	game=load("res://scenes/main.tscn").instantiate();game.name="Main";game.save_path="user://residents_coop_solo.json";root.add_child(game);await process_frame
	game.qa_mode=true;game.state=FarmState.new_farm("sandbox")
	if mode=="host":
		game.state.claim(Vector2(4,0));FarmResidents.act(game.state,"rosa","meet");FarmResidents.act(game.state,"rosa","accept")
		game.state.pickup.cargo={"carrot":8};FarmResidents.act(game.state,"rosa","deliver")
		FarmRosa.act(game.state,"story_accept");game.state.pickup.cargo=FarmRosa.step(game.state).cargo.duplicate();assert(FarmRosa.act(game.state,"story_deliver").is_empty())
	game._save_game(false,true);solo=FileAccess.get_file_as_string(game.save_path);n=game.network
	if mode=="host":
		n.host("Vizinhos QA");game.hud.close_modal();flag("host_ready")
		await until(func():return n.accepted!=0 and exists("client_checked"))
		assert(FarmResidents.influence(game.state)==10 and game.state.residents.rosa.done==1)
		assert(game.state.rosa_story.stage==1)
		assert(not game.residents_world.transact("rosa","story_accept").is_empty())
		var before:Dictionary=game.state.residents.duplicate(true)
		assert(not game.residents_world.transact("rosa","accept").is_empty());assert(game.state.residents==before)
		assert(n.save_coop());n.leave("Fim")
		var restored:=FarmCoop.load_farm(n.coop_path);assert(restored!=null and FarmResidents.influence(restored)==10 and restored.rosa_story.stage==1)
	else:
		n.join("127.0.0.1","Visitante");await until(func():return n.ready_session)
		assert(FarmResidents.influence(game.state)==10 and game.state.residents.rosa.known)
		assert(game.navigator.destinations().any(func(entry):return entry.key=="resident_rosa"))
		assert(game.state.rosa_story.stage==1)
		assert(not game.residents_world.transact("rosa","story_accept").is_empty())
		var before:Dictionary=game.state.residents.duplicate(true);game._action("resident:accept:rosa");assert(game.state.residents==before)
		game._action("residents");assert(game.hud.modal_kind=="residents" and not game.pickup.visible)
		flag("client_checked");await until(func():return not n.active)
	assert(FileAccess.get_file_as_string(game.save_path)==solo)
	game.session_started=false;game.audio.stop_all();await create_timer(.3).timeout;game.queue_free();await process_frame;await create_timer(.3).timeout
	print("COOP_QA_OK: ",mode," residents snapshot, solo actions refused, coop resume, original farm preserved")
	quit()
