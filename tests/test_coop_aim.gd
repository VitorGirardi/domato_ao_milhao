extends "res://tests/test_coop.gd"
func grounded(x:float,z:float) -> Vector3:return Vector3(x,FarmLandscape.height_at(Vector2(x,z))+.05,z)
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	mode=OS.get_cmdline_user_args()[0];flags=OS.get_cmdline_user_args()[1]
	game=load("res://scenes/main.tscn").instantiate();game.name="Main";game.save_path="user://aim_solo.json";root.add_child(game);await process_frame
	game.qa_mode=true;game.state.unlimited_money=true
	FarmCharacters.apply_to_game(game,"farmer" if mode=="host" else "farmer_woman")
	game._save_game(false,true);solo=FileAccess.get_file_as_string(game.save_path);n=game.network
	var w:FarmWeapons=game.weapons;var combat:FarmCombatNet=w.combat
	if mode=="host":
		n.host("Vitor");game.hud.close_modal();game.player.position=grounded(30,-10)
		FarmArmory.buy_pistol(game.state,game.state.armory);flag("host_ready")
		await until(func():return exists("guest_aiming") and combat.poses.get(n.accepted,{}).get("aiming",false))
		assert(n.remote_character=="farmer_woman")
		await until(func():return is_instance_valid(combat.remote_pistol) and combat.remote_pistol.visible)
		assert(float(combat.poses[n.accepted].pitch)>.15,"Guest upward aim was not replicated")
		assert(n.remote_actor.skeleton.get_bone_pose_rotation(n.remote_actor.bones["UpperArm.L"]).get_angle()>.2,"Remote support arm remained idle")
		flag("guest_pose_seen")
		await until(func():return exists("guest_released") and not combat.poses[n.accepted].aiming)
		# Both genders are exercised as the local shooter and as the replicated avatar.
		w.armed=true;w.aiming=true;w.aim_pitch=-.3;flag("host_aiming")
		await until(func():return exists("host_pose_seen"))
		w.holster();flag("host_released")
		await until(func():return game.falls.is_player_down(1))
		assert(combat.seen_shots==1 and game.state.armory.magazine==8)
		assert(combat.bag_for(n.accepted).magazine==7)
		flag("host_hit")
		await until(func():return exists("client_done") and n.accepted==0)
		n.leave();assert(FileAccess.get_file_as_string(game.save_path)==solo)
	else:
		n.join("127.0.0.1","Ian");await until(func():return n.ready_session)
		game.player.position=grounded(-30.7,22);await create_timer(.7).timeout;combat.request("buy")
		await until(func():return combat.inventory().pistol)
		game.player.position=grounded(30,0);await create_timer(.7).timeout
		w.armed=true;w.aiming=true;w.aim_pitch=-.3;await create_timer(.5).timeout;flag("guest_aiming")
		await until(func():return exists("guest_pose_seen"))
		var release:=InputEventMouseButton.new();release.button_index=MOUSE_BUTTON_RIGHT;release.pressed=false;w._input(release);flag("guest_released")
		await until(func():return exists("host_aiming") and combat.poses.get(1,{}).get("aiming",false))
		assert(n.remote_character=="farmer")
		await until(func():return is_instance_valid(combat.remote_pistol) and combat.remote_pistol.visible and float(combat.poses[1].pitch)>.15)
		assert(n.remote_actor.skeleton.get_bone_pose_rotation(n.remote_actor.bones["UpperArm.L"]).get_angle()>.2)
		flag("host_pose_seen");await until(func():return exists("host_released"))
		# Shoot through the public weapon method, not an invented hit/death RPC.
		game.set_process(false);game.set_physics_process(false)
		game.camera.global_position=game.player.global_position+Vector3(1,2.0,2)
		game.camera.look_at(n.remote.global_position+Vector3.UP*1.5)
		w.armed=true;w.aiming=true;w.aim_blend=1;w.cooldown=0
		assert(w.shoot());await until(func():return exists("host_hit") and game.falls.is_player_down(1))
		await until(func():return combat.seen_shots==1 and combat.inventory().magazine==7)
		n.leave();assert(FileAccess.get_file_as_string(game.save_path)==solo);flag("client_done")
	game.audio.stop_all();game.queue_free();await process_frame;await create_timer(.2).timeout
	print("COOP_QA_OK: ",mode," both genders, remote two-hand aim/pitch, release, actual shoulder shot and personal ammo")
	quit()

