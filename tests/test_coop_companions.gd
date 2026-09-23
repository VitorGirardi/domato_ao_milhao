extends "res://tests/test_coop.gd"
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	mode=OS.get_cmdline_user_args()[0];flags=OS.get_cmdline_user_args()[1]
	game=load("res://scenes/main.tscn").instantiate();game.name="Main";game.save_path="user://companions_solo.json";root.add_child(game)
	await process_frame;game.qa_mode=true;game.state.unlimited_money=true
	if mode=="host":game.state.claim(Vector2(4,0))
	game._save_game(false,true);solo=FileAccess.get_file_as_string(game.save_path);n=game.network
	var c:FarmCompanions=game.companions
	if mode=="host":
		n.host("Vitor");game.hud.close_modal();game.player.position=Vector3(18,0,0);flag("host_ready")
		await until(func():return game.world.cat.pet_count==1)
		assert(c.gestures.has(n.accepted) and c.purr.playing);flag("petted")
		await until(func():return c.follow_owner==n.accepted and n.accepted!=0)
		var start:Vector3=game.world.cat.position;flag("following")
		await until(func():return exists("moved") and game.world.cat.position.distance_to(start)>1.5)
		flag("follow_seen");await until(func():return exists("stay") and c.follow_owner==0)
		game.horse.position=Vector3(5,0,10);game.horse.heading=PI;game.horse.rotation.y=PI;flag("horse_ready")
		await until(func():return c.horse_owner==n.accepted and c.gestures.has(n.accepted))
		assert(c.whistle.playing);flag("whistled")
		await until(func():return game.horse.position.distance_to(Vector3(5,0,0))<7)
		flag("horse_seen");await until(func():return exists("client_done") and n.accepted==0)
		n.leave("Fim");assert(FileAccess.get_file_as_string(game.save_path)==solo)
	else:
		n.join("127.0.0.1","Ian");await until(func():return n.ready_session)
		print("CLIENT_READY cat ",game.world.cat.visible," host ",n.accepted)
		await until(func():return game.world.cat.visible)
		game.hud.close_modal();await create_timer(.8).timeout;game.player.position=game.world.cat.position+Vector3(0,0,.9)
		await create_timer(.4).timeout;print("PET_REQUEST ",c.allowed()," ",game.player.position," cat ",game.world.cat.position);c.request("pet")
		await until(func():return exists("petted") and c.gestures.has(c.own_id()))
		assert(c.purr.playing);await create_timer(3.5).timeout
		c.request("follow");await until(func():return exists("following") and c.follow_owner==c.own_id())
		game.player.position+=Vector3(5,0,0);flag("moved")
		await until(func():return exists("follow_seen"));c.request("follow");flag("stay")
		await until(func():return exists("horse_ready"));game.player.position=Vector3(5,0,0)
		await create_timer(.4).timeout;c.request("whistle")
		await until(func():return exists("whistled") and c.gestures.has(c.own_id()))
		assert(c.whistle.playing)
		await until(func():return exists("horse_seen"));flag("client_done");n.leave("Fim")
		assert(FileAccess.get_file_as_string(game.save_path)==solo)
	game.audio.stop_all();game.companions.reset();game.queue_free();await process_frame;await create_timer(.2).timeout
	print("COOP_QA_OK: ",mode," human pet gesture, purr, shared follow/stay, whistle gesture/audio and host horse arrival")
	quit()
