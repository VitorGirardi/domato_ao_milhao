extends "res://tests/test_coop.gd"

func motion(speed:float,heading:float,frames:int) -> void:
	game.avatar.rotation.y=heading
	game.player.velocity=Vector3(sin(heading),0,cos(heading))*speed
	if speed>5:Input.action_press("run")
	else:Input.action_release("run")
	for i in range(frames):
		await physics_frame
		game.player.position+=game.player.velocity/60
		game.player.position.y=FarmLandscape.height_at(Vector2(game.player.position.x,game.player.position.z))+.05

func sync_step(key:String) -> void:
	flag(mode+"_"+key)
	await until(func():return exists(("client" if mode=="host" else "host")+"_"+key))

func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	mode=OS.get_cmdline_user_args()[0];flags=OS.get_cmdline_user_args()[1]
	game=load("res://scenes/main.tscn").instantiate();game.name="Main"
	game.save_path="user://locomotion_solo.json";root.add_child(game);await process_frame
	game.qa_mode=true;game.set_physics_process(false)
	game.weapons.set_physics_process(false)
	game.state=FarmState.new_farm("sandbox")
	FarmCharacters.apply_to_game(game,"farmer" if mode=="host" else "farmer_woman")
	assert(game._save_game(false,true))
	solo=FileAccess.get_file_as_string(game.save_path);n=game.network
	if mode=="host":
		n.host("Vitor");game.hud.close_modal();flag("host_ready")
		await until(func():return n.accepted!=0 and exists("client_ready"))
	else:
		n.join("127.0.0.1","Ian");await until(func():return n.ready_session)
		game.hud.close_modal();flag("client_ready")
	game.player.position=Vector3(30 if mode=="host" else 36,0,-15)
	game.player.position.y=FarmLandscape.height_at(Vector2(game.player.position.x,game.player.position.z))+.05
	game.actor.airborne=false;game.actor.swimming=false
	await sync_step("start")
	await until(func():return n.remote_actor!=null and n.remote_actor.locomotion.enabled)
	assert(n.remote_character==("farmer_woman" if mode=="host" else "farmer"))
	await motion(4.5,0,70)
	await sync_step("walk")
	await until(func():return n.remote_actor.locomotion.active and n.remote_actor.locomotion.gait_weight>.2)
	var phase:float=n.remote_actor.locomotion.phase
	await create_timer(.2).timeout
	assert(absf(n.remote_actor.locomotion.phase-phase)>.001)
	await motion(7.5,0,65)
	await sync_step("run")
	await until(func():return n.remote_actor.locomotion.run_weight>.2)
	await motion(4.5,.65,50)
	await sync_step("turn")
	await until(func():return absf(angle_difference(n.remote_model.rotation.y,.65))<.05)
	for key in n.remote_actor.bones:
		assert(n.remote_actor.skeleton.get_bone_global_pose(n.remote_actor.bones[key]).is_finite())
	await motion(0,.65,65)
	await sync_step("stop")
	await until(func():return n.remote_actor.locomotion.gait_weight<.02)
	assert(n.remote_actor.root.position.length()<.1)
	# The normal combat RPC supplies the armed flag that suppresses locomotion.
	game.weapons.armed=true
	await sync_step("armed")
	await until(func():return game.weapons.combat.poses.get(n.accepted,{}).get("armed",false))
	await until(func():return not n.remote_actor.locomotion.active)
	assert(n.remote_actor.locomotion.enabled)
	await sync_step("armed_seen")
	game.weapons.holster()
	await sync_step("holstered")
	await until(func():return not game.weapons.combat.poses.get(n.accepted,{}).get("armed",false))
	await motion(4.5,0,50)
	await sync_step("resumed")
	await until(func():return n.remote_actor.locomotion.active and n.remote_actor.locomotion.gait_weight>.2)
	assert(n.motion_count>5 and not game.state.serialize().has("locomotion"))
	Input.action_release("run");game.player.velocity=Vector3.ZERO
	if mode=="host":
		await until(func():return exists("client_done") and n.accepted==0)
		n.leave("Fim")
	else:
		flag("client_done");n.leave("Fim")
	assert(FileAccess.get_file_as_string(game.save_path)==solo)
	game.session_started=false;game.audio.stop_all();game.queue_free()
	await process_frame;await create_timer(.2).timeout
	print("COOP_QA_OK: COOP_LOCOMOTION_OK: "+mode+" both rigs, walk/run/turn/stop, combat suppression, resume and unchanged solo saves")
	quit()
