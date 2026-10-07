extends "res://tests/test_coop.gd"
func grounded(x:float,z:float) -> Vector3:return Vector3(x,FarmLandscape.height_at(Vector2(x,z))+.05,z)
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	mode=OS.get_cmdline_user_args()[0];flags=OS.get_cmdline_user_args()[1]
	game=load("res://scenes/main.tscn").instantiate();game.name="Main";game.save_path="user://combat_solo.json";root.add_child(game)
	await process_frame;game.qa_mode=true;game.state.unlimited_money=true
	game._save_game(false,true);solo=FileAccess.get_file_as_string(game.save_path);n=game.network
	var combat:FarmCombatNet=game.weapons.combat
	if mode=="host":
		n.host("Vitor");game.hud.close_modal();game.player.position=grounded(30,-10)
		FarmArmory.buy_pistol(game.state,game.state.armory);flag("host_ready")
		await until(func():return exists("guest_shot"))
		assert(combat.seen_shots==1 and game.state.armory.magazine==8,"Guest consumed host magazine")
		assert(combat.bag_for(n.accepted).magazine==7)
		assert(is_instance_valid(combat.remote_pistol) and combat.remote_pistol.visible,"Guest gun not visible to host")
		flag("shot_seen")
		await until(func():return exists("guest_reloaded"))
		assert(combat.bag_for(n.accepted).magazine==8 and combat.bag_for(n.accepted).reserve==23)
		assert(game.state.armory.reserve==24)
		flag("inventory_seen")
		await until(func():return exists("client_done") and n.accepted==0)
		n.leave();assert(FileAccess.get_file_as_string(game.save_path)==solo)
	else:
		n.join("127.0.0.1","Ian");await until(func():return n.ready_session)
		game.player.position=grounded(-30.7,22);await create_timer(.7).timeout
		assert(not combat.inventory().pistol);combat.request("buy")
		await until(func():return combat.inventory().pistol)
		game.player.position=grounded(20,0);await create_timer(.7).timeout
		game.weapons.armed=true;await create_timer(.3).timeout
		var origin:Vector3=game.player.position+Vector3.UP*1.4
		combat.request("fire",origin,origin+Vector3(20,0,0))
		combat.request("fire",origin,origin+Vector3(20,0,0))
		await until(func():return combat.seen_shots==1 and combat.inventory().magazine==7)
		# Reliable duplicate request must not consume an extra bullet within cadence.
		assert(combat.inventory().reserve==24);flag("guest_shot")
		await until(func():return exists("shot_seen"))
		combat.request("reload");await until(func():return combat.inventory().magazine==8)
		assert(combat.inventory().reserve==23);flag("guest_reloaded")
		await until(func():return exists("inventory_seen"))
		n.leave();assert(FileAccess.get_file_as_string(game.save_path)==solo);flag("client_done")
	game.session_started=false;game.audio.stop_all();await create_timer(.2).timeout
	game.queue_free();await process_frame;await create_timer(.2).timeout
	print("COOP_QA_OK: ",mode," authoritative shots, replicated pistol, personal ammo and solo preservation")
	quit()
