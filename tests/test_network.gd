extends SceneTree
var game:Node3D
var mode:=""
var flags:=""
var original:=""
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> void:
	if not ok:push_error("NETWORK_QA: "+message);quit(1)
func flag(name:String) -> void:
	var f:=FileAccess.open(flags.path_join(name),FileAccess.WRITE);f.store_string("ok");f.close()
func until(test:Callable,seconds:float=65) -> bool:
	var end:=Time.get_ticks_msec()+int(seconds*1000)
	while not test.call():
		if Time.get_ticks_msec()>end:return false
		await process_frame
	return true
func run() -> void:
	check(OS.get_user_data_dir().contains("test-results"),"isolated save required")
	var args:=OS.get_cmdline_user_args();mode=args[0];flags=args[1]
	game=load("res://scenes/main.tscn").instantiate();game.name="Main";game.save_path="user://network_qa.json";root.add_child(game)
	await process_frame
	game.qa_mode=true
	game.state.farm_name="Fazenda Host QA" if mode=="host" else "Solo Ian QA"
	game.state.unlimited_money=true
	if mode=="host":
		game.state.claim(Vector2(4,0));game.world.rebuild(game.state)
		game.player.position=Vector3(4,.2,7)
	game._save_game(false,true)
	original=FileAccess.get_file_as_string(game.save_path)
	var n:FarmNetwork=game.network
	if mode=="host":
		n.host("Vitor QA");game.hud.close_modal();check(n.active and n.hosting,"host")
		flag("host_ready")
		check(await until(func():return n.accepted!=0),"client joins")
		var first:=n.accepted
		Input.action_press("forward");await create_timer(.7).timeout;Input.action_release("forward")
		check(game._try_jump(),"host jump")
		await create_timer(1.2).timeout
		game.actor.emote("six_seven");n.send_emote("six_seven")
		check(await until(func():return FileAccess.file_exists(flags.path_join("client_checked"))),"client receives motion/emote")
		check(n.motion_count>0 and n.emote_count>0,"host receives client")
		check(await until(func():return n.accepted==0),"guest leaves")
		check(await until(func():return n.accepted!=0 and n.accepted!=first),"guest reconnects")
		check(await until(func():return FileAccess.file_exists(flags.path_join("rejoined"))),"guest handshake complete")
		n.leave("QA host shutdown")
		check(FileAccess.get_file_as_string(game.save_path)==original,"host save unchanged")
		flag("host_done")
	else:
		n.join("not an ip","Ian QA");check(not n.active,"invalid address")
		n.join("127.0.0.1","Ian QA")
		check(await until(func():return n.ready_session),"welcome")
		check(game.state.farm_name=="Fazenda Host QA" and n.remote_name=="Vitor QA","snapshot and name")
		game._action("mode");check(not game.build_mode,"building blocked")
		game._action("save");game._save_game(false,true)
		check(FileAccess.get_file_as_string(game.save_path)==original,"guest cannot save host snapshot")
		check(await until(func():return n.emote_count>0 and n.motion_count>5),"host animations received")
		Input.action_press("right");await create_timer(.5).timeout;Input.action_release("right")
		game.actor.emote("heart");n.send_emote("heart")
		await create_timer(.4).timeout
		if DisplayServer.get_name()!="headless":
			game.set_physics_process(false)
			var center:Vector3=(game.player.position+n.remote.position)*.5+Vector3.UP*1.3
			game.camera.position=center+Vector3(7,5,12);game.camera.look_at(center)
			game.hud.toast_time=0;game.hud.toast_panel.visible=false
			await process_frame;await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(flags.path_join("visit-client.png"))
		flag("client_checked")
		n.leave("QA guest exit");check(game.state.farm_name=="Solo Ian QA","restore personal farm")
		await create_timer(.5).timeout
		n.join("127.0.0.1","Ian QA");check(await until(func():return n.ready_session),"rejoin")
		flag("rejoined")
		check(await until(func():return not n.active),"host disconnect noticed")
		check(game.state.farm_name=="Solo Ian QA" and FileAccess.get_file_as_string(game.save_path)==original,"disconnect preserves save")
		n.join("127.0.0.1","Ian QA");n.leave("Conexão cancelada.");check(not n.active,"cancel")
		n.join("127.0.0.1","Ian QA")
		check(await until(func():return not n.active,18),"connection failure timeout")
		check(game.state.farm_name=="Solo Ian QA","failed connection restores solo")
	game.audio.stop_all();await create_timer(.2).timeout
	game.queue_free();await process_frame;await create_timer(.2).timeout
	print("NETWORK_QA_OK: "+mode+" connection, motion, emote, reconnect and save isolation")
	quit()

