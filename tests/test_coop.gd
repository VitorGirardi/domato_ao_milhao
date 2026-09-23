extends SceneTree
var game:Node3D
var flags:String
var mode:String
var n:FarmNetwork
var solo:String
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> void:
	assert(ok,message)
func flag(key:String) -> void:
	var f:=FileAccess.open(flags.path_join(key),FileAccess.WRITE);f.store_string("ok");f.close()
func until(test:Callable,seconds:float=60) -> void:
	var end:=Time.get_ticks_msec()+int(seconds*1000)
	while not test.call():
		assert(Time.get_ticks_msec()<end,"Coop timeout")
		await process_frame
func exists(key:String) -> bool:return FileAccess.file_exists(flags.path_join(key))
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	mode=OS.get_cmdline_user_args()[0];flags=OS.get_cmdline_user_args()[1]
	game=load("res://scenes/main.tscn").instantiate();game.name="Main";game.save_path="user://coop_test_solo.json";root.add_child(game);await process_frame
	game.qa_mode=true;game.state.unlimited_money=true
	if mode=="host":
		game.state.claim(Vector2(4,0))
		assert(game.state.place("plot",Vector2(4,0),0).is_empty())
		assert(game.state.place("plot",Vector2(6,0),0).is_empty())
		for item in game.state.items:item.planted=false
	game._save_game(false,true);solo=FileAccess.get_file_as_string(game.save_path)
	n=game.network
	if mode=="host":
		game.player.position=Vector3(4,.2,2);n.host("Vitor");game.hud.close_modal();flag("host_ready")
		await until(func():return n.accepted!=0 and exists("client_ready"))
		await create_timer(.4).timeout
		n.request_tend(0,"plant","carrot");assert(game.state.items[0].planted);flag("planted")
		await until(func():return game.state.items[0].watered and game.state.items[1].planted)
		n.request_tend(1,"water","corn");assert(game.state.items[1].watered)
		FarmCoop.tick(game.state,180);n.broadcast_state();flag("ripe")
		await until(func():return exists("race_sent"))
		# A stale competing action must not harvest twice or plant the newly empty plot.
		n.sequence+=1;n.apply_tend(1,n.sequence,0,"harvest","carrot",2)
		await until(func():return game.state.inventory.carrot==3)
		await create_timer(.5).timeout
		assert(game.state.harvests==1 and game.state.inventory.carrot==3 and not game.state.items[0].planted)
		assert(n.harvest_actions==1)
		await until(func():return exists("client_done"))
		assert(game.state.inventory.corn==3 and game.state.harvests==2)
		assert(n.save_coop());n.leave("Encerrado")
		assert(FileAccess.get_file_as_string(game.save_path)==solo)
		var restored:=FarmCoop.load_farm(n.coop_path)
		assert(restored!=null and restored.inventory.carrot==3 and restored.inventory.corn==3)
		n.host("Vitor");game.hud.close_modal()
		assert(game.state.inventory.carrot==3 and game.state.harvests==2)
		# Refused save rolls back the action and does not replace the primary file.
		var path:=n.coop_path;n.coop_path="user://missing_folder/coop.json"
		await create_timer(1).timeout
		n.request_tend(0,"plant","wheat");assert(not game.state.items[0].planted)
		n.coop_path=path;n.leave("Fim")
	else:
		n.join("127.0.0.1","Ian");await until(func():return n.ready_session)
		await create_timer(.6).timeout;flag("client_ready")
		await until(func():return game.state.items[0].planted)
		n.request_tend(1,"plant","corn")
		await until(func():return game.state.items[1].crop=="corn")
		await create_timer(1).timeout;n.request_tend(0,"water","carrot")
		await until(func():return game.state.items[0].growth>=1 and game.state.items[1].growth>=1)
		await create_timer(1.3).timeout
		n.request_tend(0,"harvest","carrot")
		# Deliberately replay exactly the same request.
		n._tend_request.rpc_id(1,n.sequence,0,"harvest","carrot",2);flag("race_sent")
		await until(func():return game.state.inventory.carrot==3)
		await create_timer(1).timeout
		n.request_tend(1,"harvest","corn")
		await until(func():return game.state.inventory.corn==3)
		assert(game.state.harvests==2 and not FileAccess.file_exists(n.coop_path))
		# Attempts from far away must not plant another crop.
		game.player.position=Vector3(80,.2,60);await create_timer(1).timeout
		n.request_tend(0,"plant","wheat");await create_timer(.5).timeout;assert(not game.state.items[0].planted)
		if DisplayServer.get_name()!="headless":
			n.show_stock();await process_frame;await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(flags.path_join("coop-stock.png"))
		flag("client_done");await until(func():return not n.active)
		assert(FileAccess.get_file_as_string(game.save_path)==solo)
	game.audio.stop_all();await create_timer(.2).timeout;game.queue_free();await process_frame;await create_timer(.2).timeout
	print("COOP_QA_OK: "+mode+" plant/water/growth/harvest, shared inventory, competing/replayed requests, distance, disk rollback and coop resume")
	quit()
