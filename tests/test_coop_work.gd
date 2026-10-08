extends "res://tests/test_coop.gd"

func barrier(key:String) -> void:
	flag(mode+"_"+key)
	await until(func():return exists(("client" if mode=="host" else "host")+"_"+key))

func observe(peer_local:bool,kind:String) -> void:
	var performer:FarmAvatar=game.actor if peer_local else n.remote_actor
	await until(func():return performer.action_kind==kind and performer.action_time>.15)
	await create_timer(.35).timeout
	assert(not performer.locomotion.active)
	if kind=="water":assert(performer.can.visible)
	for key in performer.bones:
		assert(performer.skeleton.get_bone_global_pose(performer.bones[key]).is_finite())

func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	mode=OS.get_cmdline_user_args()[0];flags=OS.get_cmdline_user_args()[1]
	game=load("res://scenes/main.tscn").instantiate();game.name="Main"
	game.save_path="user://work_solo.json";root.add_child(game);await process_frame
	game.qa_mode=true;game.state=FarmState.new_farm("survival")
	game.state.unlimited_money=true
	FarmCharacters.apply_to_game(game,"farmer" if mode=="host" else "farmer_woman")
	if mode=="host":
		assert(game.state.claim(Vector2(4,0)).is_empty())
		for x in [4,6]:
			assert(game.state.place("plot",Vector2(x,0),0).is_empty())
		for item in game.state.items:item.planted=true;item.watered=false;item.crop="carrot";item.growth=0.0
	assert(game._save_game(false,true));solo=FileAccess.get_file_as_string(game.save_path);n=game.network
	if mode=="host":
		n.host("Vitor");game.hud.close_modal();flag("host_ready")
		await until(func():return n.accepted!=0 and exists("client_ready"))
	else:
		n.join("127.0.0.1","Ian");await until(func():return n.ready_session)
		game.hud.close_modal();flag("client_ready")
	game.player.position=Vector3(4 if mode=="host" else 6,.12,2)
	await create_timer(.8).timeout
	await barrier("start")
	if mode=="host":n.request_tend(0,"water","carrot")
	await observe(mode=="host","water")
	await barrier("host_water_seen")
	await create_timer(1).timeout
	if mode=="client":n.request_tend(1,"water","carrot")
	await observe(mode=="client","water")
	await barrier("guest_water_seen")
	await create_timer(1.1).timeout
	if mode=="host":
		FarmCoop.tick(game.state,180);n.broadcast_state()
	await until(func():return game.state.items[0].growth>=1 and game.state.items[1].growth>=1)
	await barrier("ripe")
	if mode=="host":n.request_tend(0,"harvest","carrot")
	await observe(mode=="host","harvest")
	await barrier("host_harvest_seen")
	if mode=="client":n.request_tend(1,"harvest","carrot")
	await observe(mode=="client","harvest")
	await barrier("guest_harvest_seen")
	await until(func():return game.state.inventory.carrot==6 and game.state.harvests==2)
	await create_timer(1.6).timeout
	assert(not game.actor.can.visible and not n.remote_actor.can.visible)
	assert(game.actor.locomotion.active and n.remote_actor.locomotion.active)
	await barrier("done")
	if mode=="host":
		await until(func():return n.accepted==0);n.leave("Fim")
	else:n.leave("Fim")
	assert(FileAccess.get_file_as_string(game.save_path)==solo)
	game.session_started=false;game.audio.stop_all();await create_timer(.2).timeout
	game.queue_free();await process_frame;await create_timer(.2).timeout
	print("COOP_QA_OK: COOP_WORK_OK ",mode," authoritative water/harvest, both rigs, local/remote poses, resume and isolated solo saves")
	quit()
