extends "res://tests/test_coop.gd"
var chapter:FarmChapterWorld

func move_to(at:Vector2) -> void:
	game.player.position=Vector3(at.x,FarmLandscape.height_at(at)+.1,at.y)
	game.player.velocity=Vector3.ZERO
	game.actor.airborne=false

func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	mode=OS.get_cmdline_user_args()[0];flags=OS.get_cmdline_user_args()[1]
	game=load("res://scenes/main.tscn").instantiate();game.name="Main"
	game.save_path="user://chapter_solo.json";root.add_child(game);await process_frame
	game.qa_mode=true;game.state.unlimited_money=false;game.set_physics_process(false)
	chapter=game.get_node_or_null("ChapterWorld") as FarmChapterWorld
	if chapter==null:
		chapter=FarmChapterWorld.new();game.add_child(chapter);chapter.setup(game)
	if mode=="host":
		assert(game.state.claim(Vector2(4,0)).is_empty())
		game.state.inventory.carrot=12
	game._save_game(false,true);solo=FileAccess.get_file_as_string(game.save_path);n=game.network
	if mode=="host":
		n.host("Vitor");game.hud.close_modal();flag("host_ready")
		await until(func():return n.accepted!=0 and exists("client_ready"))
		var balance:int=game.state.money
		await until(func():return exists("far_accept"))
		assert(game.state.chapter.stage==0);flag("far_accept_checked")
		await until(func():return game.state.chapter.stage==1)
		await until(func():return exists("far_deliver"))
		assert(game.state.chapter.stage==1 and game.state.inventory.carrot==12)
		assert(game.state.money==balance);flag("far_deliver_checked")
		await until(func():return exists("delivered"))
		assert(game.state.chapter.stage==2 and game.state.inventory.carrot==6)
		assert(game.state.money==balance+180 and game.state.trade.nena.reputation==1)
		assert(game.state.revenue==180)
		var saved:=FarmCoop.load_farm(n.coop_path)
		assert(saved!=null and saved.chapter.stage==2 and saved.inventory.carrot==6)
		flag("delivery_checked")
		await until(func():return game.state.chapter.stage==3 and chapter.follow_peer==n.accepted)
		await until(func():return exists("return_denied"))
		assert(game.state.chapter.stage==3 and game.state.money==balance+180)
		# A valid fishing stage still cannot be completed by a forged chapter RPC.
		game.state.chapter.stage=5;game.state.resources.rod=true
		n.broadcast_state();flag("fish_stage")
		await until(func():return exists("forged_fish"))
		assert(game.state.chapter.stage==5 and game.state.resources.caught==0)
		assert(game.state.money==balance+180)
		game.state.chapter.stage=3;chapter.reset();n.broadcast_state();flag("resume_rescue")
		await until(func():return chapter.follow_peer==n.accepted and exists("following_again"))
		await until(func():return exists("client_done") and n.accepted==0)
		await until(func():return chapter.follow_peer==0 and chapter.trail.is_empty())
		assert(game.state.chapter.stage==3 and game.state.money==balance+180)
		assert(n.save_coop());saved=FarmCoop.load_farm(n.coop_path)
		assert(saved!=null and saved.chapter.stage==3 and saved.inventory.carrot==6)
		n.leave("Fim")
		chapter.reset();assert(chapter.follow_peer==0 and chapter.trail.is_empty())
	else:
		n.join("127.0.0.1","Ian");await until(func():return n.ready_session);game.hud.close_modal()
		move_to(Vector2(60,60));await create_timer(.6).timeout;flag("client_ready")
		chapter._request.rpc_id(1,"accept");await create_timer(.6).timeout;flag("far_accept")
		await until(func():return exists("far_accept_checked"))
		move_to(FarmChapterWorld.NENA_AT);await create_timer(.6).timeout
		chapter.request("accept");await until(func():return game.state.chapter.stage==1)
		move_to(Vector2(60,60));await create_timer(.6).timeout
		chapter._request.rpc_id(1,"deliver");await create_timer(.6).timeout;flag("far_deliver")
		await until(func():return exists("far_deliver_checked"))
		move_to(FarmChapterWorld.NENA_AT);await create_timer(.6).timeout
		chapter.request("deliver");chapter._request.rpc_id(1,"deliver")
		await until(func():return game.state.chapter.stage==2)
		await create_timer(.5).timeout
		assert(game.state.inventory.carrot==6 and game.state.trade.nena.reputation==1)
		flag("delivered");await until(func():return exists("delivery_checked"))
		move_to(FarmChapterWorld.RESCUE_AT);await create_timer(.6).timeout
		chapter.request("rescue")
		await until(func():return game.state.chapter.stage==3 and chapter.follow_peer==chapter.own_id())
		move_to(FarmChapterWorld.NENA_AT);await create_timer(.6).timeout
		chapter.request("return_animal");await create_timer(.6).timeout;flag("return_denied")
		await until(func():return exists("fish_stage") and game.state.chapter.stage==5)
		move_to(FarmChapterWorld.REPAIR_AT);await create_timer(.6).timeout
		chapter._request.rpc_id(1,"catch_fish");await create_timer(.6).timeout
		assert(game.state.chapter.stage==5 and game.state.resources.caught==0);flag("forged_fish")
		await until(func():return exists("resume_rescue") and game.state.chapter.stage==3)
		move_to(FarmChapterWorld.RESCUE_AT);await create_timer(.6).timeout
		chapter.request("rescue")
		await until(func():return chapter.follow_peer==chapter.own_id())
		flag("following_again");await create_timer(.5).timeout
		assert(not FileAccess.file_exists(n.coop_path));flag("client_done");n.leave("Fim")
	assert(FileAccess.get_file_as_string(game.save_path)==solo)
	game.session_started=false;game.audio.set_process(false);game.audio.stop_all()
	await create_timer(.2).timeout;game.queue_free();await process_frame;await create_timer(.2).timeout
	print("COOP_QA_OK: COOP_CHAPTER_OK: "+mode+" distance, duplicate rewards, forged fish, shared saves and escort disconnect")
	quit()
