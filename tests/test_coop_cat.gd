extends "res://tests/test_coop.gd"
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	mode=OS.get_cmdline_user_args()[0];flags=OS.get_cmdline_user_args()[1]
	game=load("res://scenes/main.tscn").instantiate();game.name="Main";game.save_path="user://cat_solo.json";root.add_child(game)
	await process_frame;game.qa_mode=true;game.state.unlimited_money=true
	if mode=="host":game.state.claim(Vector2(4,0))
	game._save_game(false,true);solo=FileAccess.get_file_as_string(game.save_path);n=game.network
	if mode=="host":
		n.host("Vitor");game.hud.close_modal();flag("host_ready")
		await until(func():return exists("far_attempt"))
		assert(game.world.cat.pet_count==0,"Remote affection must require proximity")
		flag("far_denied")
		await until(func():return game.world.cat.pet_count==1)
		flag("pet_accepted")
		await until(func():return exists("seen"))
		assert(game.world.cat.pet_count==1,"Repeated affection during the same reaction is ignored")
		await until(func():return exists("client_done") and n.accepted==0)
		n.leave("Fim");assert(FileAccess.get_file_as_string(game.save_path)==solo)
	else:
		n.join("127.0.0.1","Ian");await until(func():return n.ready_session and game.world.cat.visible)
		game.hud.close_modal();game.player.position=Vector3(60,0,60)
		await create_timer(.35).timeout;n.pet_cat();await create_timer(.35).timeout;flag("far_attempt")
		await until(func():return exists("far_denied"))
		game.player.position=game.world.cat.position+Vector3(0,0,1)
		await create_timer(.35).timeout;n.pet_cat()
		await until(func():return exists("pet_accepted"))
		for i in range(8):n.pet_cat()
		await create_timer(.45).timeout
		assert(n.visual_state.has("cat"))
		var head:Node3D=game.world.cat.model.find_child("CatHead",true,false)
		assert(absf(head.rotation.x)>.05,"Client sees host affection pose")
		flag("seen");await create_timer(.2).timeout;flag("client_done");n.leave("Fim")
		assert(FileAccess.get_file_as_string(game.save_path)==solo)
	game.audio.stop_all();game.queue_free();await process_frame;await create_timer(.2).timeout
	print("COOP_QA_OK: ",mode," shared feline, visitor affection, distance validation, spam rejection, replicated pose and solo-save isolation")
	quit()
