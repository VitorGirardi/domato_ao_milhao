extends "res://tests/test_coop.gd"
func move_to(at:Vector2) -> void:
	game.player.position=Vector3(at.x,FarmLandscape.height_at(at)+.1,at.y);game.player.velocity=Vector3.ZERO
func count_stock() -> int:
	var count:=0
	for value in game.state.resources.stock.values():count+=int(value)
	return count
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	mode=OS.get_cmdline_user_args()[0];flags=OS.get_cmdline_user_args()[1]
	game=load("res://scenes/main.tscn").instantiate();game.name="Main";game.save_path="user://gathering_solo.json";root.add_child(game);await process_frame
	game.qa_mode=true;game.state.unlimited_money=true;game.set_physics_process(false)
	if mode=="host":
		game.state.claim(Vector2(4,0))
		for kind in ["rod","pickaxe","mine"]:assert(FarmResources.buy(game.state,kind).is_empty())
	game._save_game(false,true);solo=FileAccess.get_file_as_string(game.save_path);n=game.network
	if mode=="host":
		n.host("Vitor");game.hud.close_modal();flag("host_ready")
		await until(func():return exists("client_ready") and n.accepted!=0)
		move_to(FarmResourceSites.ORE_SPOTS[0]);await create_timer(.4).timeout
		game.gathering.request("gather:mine:0");assert(game.gathering.jobs.has(1));flag("locked")
		await until(func():return exists("race_sent"));await create_timer(.5).timeout
		assert(game.gathering.jobs.size()==1 and count_stock()==0)
		await until(func():return count_stock()>0)
		var mined:=count_stock();flag("mined")
		await until(func():return exists("fishing") and game.gathering.jobs.has(n.accepted))
		assert(count_stock()==mined)
		await until(func():return exists("cancelled") and not game.gathering.jobs.has(n.accepted))
		assert(count_stock()==mined);flag("cancel_seen")
		await until(func():return count_stock()>mined)
		flag("fish_saved")
		# Give the shared QA farm the materials for both gallery transactions.
		game.state.resources.stock.copper+=8;game.state.resources.stock.iron+=10;game.state.resources.mined+=18
		n.broadcast_state();flag("gallery_materials")
		await until(func():return game.state.resources.gallery_level==1)
		assert(game.state.resources.stock.copper<8)
		move_to(Vector2(909,-256));await create_timer(.5).timeout
		game.gathering.request("resource:buy:gallery_2")
		assert(game.state.resources.gallery_level==2);flag("galleries_open")
		await until(func():return exists("client_done") and n.accepted==0)
		assert(n.save_coop());var saved:=FarmCoop.load_farm(n.coop_path)
		assert(saved.resources.stock==game.state.resources.stock and saved.resources.gallery_level==2)
		n.leave("Fim")
	else:
		n.join("127.0.0.1","Ian");await until(func():return n.ready_session);game.hud.close_modal()
		move_to(FarmResourceSites.ORE_SPOTS[0]);await create_timer(.4).timeout;flag("client_ready")
		await until(func():return exists("locked") and game.gathering.jobs.has(1))
		game.gathering.request("gather:mine:0");flag("race_sent")
		await create_timer(.7).timeout;assert(not game.gathering.jobs.has(game.gathering.own_id()))
		await until(func():return exists("mined") and count_stock()>0)
		move_to(FarmResourceSites.FISH_SPOTS[0]);await create_timer(.5).timeout
		game.gathering.request("gather:fish:0")
		await until(func():return game.gathering.jobs.has(game.gathering.own_id()));flag("fishing")
		await create_timer(.5).timeout;game.player.position.x+=2;flag("cancelled")
		await until(func():return exists("cancel_seen") and game.gathering.jobs.is_empty())
		move_to(FarmResourceSites.FISH_SPOTS[0]);await create_timer(.5).timeout
		game.gathering.request("gather:fish:0")
		await until(func():return exists("fish_saved") and game.gathering.jobs.is_empty())
		await until(func():return exists("gallery_materials") and game.state.resources.stock.copper>=8)
		move_to(Vector2(900,-233));await create_timer(.5).timeout
		game.gathering.request("resource:buy:gallery_1")
		await until(func():return exists("galleries_open") and game.state.resources.gallery_level==2)
		var region:FarmRegionScenery=game.world.landscape.get_node("ValeESerra")
		await until(func():return region.gallery_gates[0].disabled and region.gallery_gates[1].disabled)
		assert(not FileAccess.file_exists(n.coop_path));flag("client_done");n.leave("Fim")
	assert(FileAccess.get_file_as_string(game.save_path)==solo)
	game.session_started=false;game.audio.set_process(false);game.audio.stop_all();await create_timer(.2).timeout
	game.queue_free();await process_frame;await create_timer(.2).timeout
	print("COOP_QA_OK: COOP_GATHERING_OK: "+mode+" shared timed resources, node contention, remote cancellation, remote gallery upgrades, host save and solo preservation")
	quit()
