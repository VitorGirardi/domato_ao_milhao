extends "res://tests/test_coop.gd"
var watching_local:=false
var watching_kind:=""
var observed:=false

func barrier(key:String) -> void:
	print("WORK_BARRIER ",mode," ",key)
	flag(mode+"_"+key)
	await until(func():return exists(("client" if mode=="host" else "host")+"_"+key))

func sample_work() -> void:
	if watching_kind.is_empty() or observed:return
	# Resolve the current rig every frame, including after identity replacement.
	var performer:FarmAvatar=game.actor if watching_local else n.remote_actor
	if performer==null or performer.action_kind!=watching_kind or performer.action_time<=0 or not performer.work_pose_active:return
	assert(not performer.locomotion.active)
	if watching_kind=="water":assert(performer.can.visible)
	for key in performer.bones:
		assert(performer.skeleton.get_bone_global_pose(performer.bones[key]).is_finite())
	observed=true
	print("WORK_POSE_SEEN ",mode," ",watching_kind," local=",watching_local," remaining=",performer.action_time)

func perform(stage:String,owner_mode:String,index:int,kind:String) -> void:
	watching_local=mode==owner_mode;watching_kind=kind;observed=false
	# Both observers are armed before either peer can submit the request.
	await barrier(stage+"_ready")
	if mode==owner_mode:n.request_tend(index,kind,"carrot")
	var deadline:=Time.get_ticks_msec()+10000
	while not observed:
		if Time.get_ticks_msec()>deadline:
			push_error("Work stage %s failed on %s: toast=%s versions=%s"%[stage,mode,game.hud.toast_label.text,n.plot_versions])
			quit(1);return
		await process_frame
	await barrier(stage+"_seen")
	await until(func():return (game.actor if watching_local else n.remote_actor).action_time<=0)
	await until(func():return game.state.items[index].watered if kind=="water" else not game.state.items[index].planted)
	await barrier(stage+"_complete")
	watching_kind=""

func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	mode=OS.get_cmdline_user_args()[0];flags=OS.get_cmdline_user_args()[1]
	game=load("res://scenes/main.tscn").instantiate();game.name="Main"
	game.save_path="user://work_solo.json";root.add_child(game);await process_frame
	game.qa_mode=true;game.state=FarmState.new_farm("survival")
	process_frame.connect(sample_work)
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
	await perform("host_water","host",0,"water")
	await perform("guest_water","client",1,"water")
	if mode=="host":
		# Artificial growth must update optimistic plot versions before publishing,
		# just as the host's normal simulation tick does.
		FarmCoop.tick(game.state,180);n.track_plots();n.broadcast_state()
	await until(func():return game.state.items[0].growth>=1 and game.state.items[1].growth>=1)
	await barrier("ripe")
	await perform("host_harvest","host",0,"harvest")
	await perform("guest_harvest","client",1,"harvest")
	await until(func():return game.state.inventory.carrot==6 and game.state.harvests==2 and game.state.skills.farming==20)
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
