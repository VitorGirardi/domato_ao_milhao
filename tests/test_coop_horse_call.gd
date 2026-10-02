extends "res://tests/test_coop.gd"
const HORSE_START:=Vector2(20,0)
const GUEST_AT:=Vector2(110,0)
func ground(at:Vector2) -> Vector3:return Vector3(at.x,FarmLandscape.height_at(at)+.1,at.y)
func observe_arrival() -> void:
	var previous:Vector3=game.horse.position
	var moved:=0.0;var samples:=0
	var deadline:=Time.get_ticks_msec()+60000
	while game.horse.position.distance_to(ground(GUEST_AT))>5.5:
		await process_frame
		var step:float=previous.distance_to(game.horse.position)
		assert(step<3.0,"Shared horse teleported while answering a distant call")
		if step>.01:samples+=1;moved+=step
		previous=game.horse.position
		assert(Time.get_ticks_msec()<deadline,"Shared horse never reached the remote caller: %s"%game.horse.position)
	assert(moved>60 and samples>20,"Both peers must observe the approach, not only the final position")
	print("DISTANT_CALL_APPROACH ",mode," travelled ",moved," samples ",samples)

func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	mode=OS.get_cmdline_user_args()[0];flags=OS.get_cmdline_user_args()[1]
	game=load("res://scenes/main.tscn").instantiate();game.name="Main";game.save_path="user://horse_call_solo.json";root.add_child(game)
	await process_frame;game.qa_mode=true;game.state.unlimited_money=true
	if mode=="host":game.state.claim(Vector2(4,0))
	game._save_game(false,true);solo=FileAccess.get_file_as_string(game.save_path);n=game.network
	var c:FarmCompanions=game.companions
	if mode=="host":
		n.host("Vitor");game.hud.close_modal();game.player.position=ground(Vector2(18,-10))
		game.horse.position=ground(HORSE_START);game.horse.life.reset(game.horse)
		flag("host_ready")
		await until(func():return exists("caller_ready") and n.accepted!=0)
		await until(func():return c.horse_owner==n.accepted)
		assert(game.horse.position.distance_to(n.target)>60,"Fixture must exercise a formerly rejected distant call")
		flag("call_accepted")
		await observe_arrival();flag("host_arrived")
		await until(func():return n.mounts.rider==n.accepted and n.accepted!=0)
		assert(game.horse.mounted)
		game.player.position=game.horse.position+Vector3(1.7,0,0)
		await create_timer(.5).timeout
		assert(not c.apply(1,"whistle"),"Host stole a guest's mounted horse with a whistle")
		n.mounts.request("mount");await create_timer(.3).timeout
		assert(n.mounts.rider==n.accepted and game.horse.mounted,"Occupied saddle changed owner")
		flag("mounted_protected")
		await until(func():return exists("client_done") and n.accepted==0)
		n.leave("Fim")
	else:
		n.join("127.0.0.1","Ian");await until(func():return n.ready_session)
		game.hud.close_modal();game.player.position=ground(GUEST_AT)
		await until(func():return game.horse.position.distance_to(ground(HORSE_START))<3)
		await create_timer(.7).timeout
		assert(game.player.position.distance_to(game.horse.position)>60)
		assert(c.allowed(),"Remote caller must be on foot and grounded")
		flag("caller_ready");c.request("whistle")
		await until(func():return exists("call_accepted") and c.gestures.has(c.own_id()))
		await observe_arrival();flag("client_arrived")
		await until(func():return exists("host_arrived"))
		game.player.position=game.horse.position+Vector3(1.6,0,0)
		await create_timer(.6).timeout;n.mounts.request("mount")
		await until(func():return n.mounts.local_rider())
		c.request("whistle")
		await until(func():return exists("mounted_protected"))
		assert(n.mounts.local_rider() and game.horse.mounted)
		flag("client_done");n.leave("Fim")
	assert(FileAccess.get_file_as_string(game.save_path)==solo,"Shared horse activity changed the solo save")
	game.audio.stop_all();game.companions.reset();game.queue_free();await process_frame;await create_timer(.2).timeout
	print("COOP_QA_OK: ",mode," distant guest whistle, continuous shared approach, arrival and mounted ownership protection")
	quit()
