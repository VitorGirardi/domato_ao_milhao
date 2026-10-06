extends "res://tests/test_coop.gd"

func command(payload:Dictionary) -> void:
	n.request_command(payload)
	await until(func():return not n.command_busy)

func work_until(count:int) -> void:
	var deadline:=Time.get_ticks_msec()+60000
	while game.state.orchard_staff.services<count:
		assert(Time.get_ticks_msec()<deadline,"Zeca did not complete orchard task")
		game.world.update_staff(game.state,.1)
		await process_frame
	n.broadcast_state()

func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	mode=OS.get_cmdline_user_args()[0];flags=OS.get_cmdline_user_args()[1]
	game=load("res://scenes/main.tscn").instantiate();game.name="Main"
	game.save_path="user://orchard_staff_solo.json";root.add_child(game);await process_frame
	game.qa_mode=true;game.set_physics_process(false)
	game.state=FarmState.new_farm("survival")
	if mode=="host":
		game.state.claim(Vector2(4,0));game.state.farm_xp=30;game.state.money=2000
		assert(game.state.place("orchard",Vector2(4,0),0).is_empty())
		assert(game.state.place("coop",Vector2(-4,0),0).is_empty())
		game.state.orchard_journey={"stage":2,"harvested":6}
	assert(game._save_game(false,true))
	solo=FileAccess.get_file_as_string(game.save_path);n=game.network
	if mode=="host":
		n.host("Vitor");n.set_process(false);game.hud.close_modal();flag("host_ready")
		await until(func():return n.accepted!=0 and exists("client_ready"))
		var initial:int=game.state.money
		await until(func():return exists("applied"))
		assert(game.state.money==initial-120 and game.state.staff.hired)
		assert(game.state.orchard_staff.enabled and game.state.staff.paused)
		game.state.scenery_obstacles.clear()
		game.world.update_staff(game.state,0)
		game.world.staff_root.position=Vector3(4,FarmLandscape.height_at(Vector2(4,4)),4)
		await work_until(1)
		assert(game.state.items[0].orchard.watered and game.state.orchard_staff.spent==2)
		assert(game.state.money==initial-122)
		flag("watered")
		await until(func():return exists("malformed_checked"))
		assert(game.state.money==initial-122 and game.state.orchard_staff.services==1)
		game.state.tick(300);game.world.update_orchards(game.state)
		await work_until(2)
		assert(game.state.inventory.orange==6 and game.state.orchard_staff.oranges==6)
		assert(game.state.money==initial-124 and game.state.orchard_staff.spent==4)
		var poses:=FarmCoopVisuals.capture(game.world)
		assert(poses.has("staff_root") and poses.staff_root.size()>1)
		var pose_file:=FileAccess.open(flags.path_join("staff_pose.bin"),FileAccess.WRITE)
		pose_file.store_var(poses.staff_root[0].transform);pose_file.close()
		n._visuals.rpc_id(n.accepted,n.structure_version,var_to_bytes(poses).compress(FileAccess.COMPRESSION_GZIP))
		flag("harvested")
		await until(func():return exists("paused"))
		var before:Dictionary=game.state.serialize()
		for i in range(100):game.world.update_staff(game.state,.1)
		assert(game.state.serialize()==before)
		flag("pause_checked")
		await until(func():return exists("stopped"))
		assert(not game.state.orchard_staff.enabled)
		assert(game.state.assign_staff(1).is_empty())
		assert(game.state.pause_staff().is_empty())
		assert(not game.state.staff.paused and not FarmOrchardStaff.active(game.state))
		n.broadcast_state()
		assert(n.save_coop())
		var saved:=FarmCoop.load_farm(n.coop_path)
		assert(saved!=null and saved.orchard_staff.services==2 and saved.inventory.orange==6)
		flag("done_checked")
		await until(func():return exists("client_done") and n.accepted==0)
		n.leave("Fim")
		assert(game.state.orchard_staff==FarmOrchardStaff.fresh())
	else:
		n.join("127.0.0.1","Ian");await until(func():return n.ready_session)
		game.hud.close_modal();flag("client_ready")
		await command({"action":"orchard_staff:apply","trees":[0]})
		await until(func():return game.state.orchard_staff.enabled)
		var balance:int=game.state.money
		await command({"action":"orchard_staff:apply","trees":[0]})
		assert(game.state.money==balance);flag("applied")
		await until(func():return exists("watered") and game.state.orchard_staff.services==1)
		await command({"action":"orchard_staff:apply","trees":"0"})
		await command({"action":"orchard_staff:apply","trees":[0,0]})
		await command({"action":"orchard_staff:complete","index":0,"kind":"harvest"})
		assert(game.state.orchard_staff.services==1 and game.state.inventory.orange==0)
		flag("malformed_checked")
		await until(func():return exists("harvested") and game.state.inventory.orange==6)
		assert(game.state.orchard_staff.services==2 and game.state.orchard_staff.spent==4)
		assert(game.world.staff_root!=null and is_instance_valid(game.world.staff_root))
		var pose_file:=FileAccess.open(flags.path_join("staff_pose.bin"),FileAccess.READ)
		var expected:Transform3D=pose_file.get_var();pose_file.close()
		await until(func():return game.world.staff_root.transform.origin.distance_to(expected.origin)<.02)
		await command({"action":"orchard_staff:pause"})
		await until(func():return game.state.orchard_staff.paused);flag("paused")
		await until(func():return exists("pause_checked"))
		await command({"action":"orchard_staff:stop"})
		await until(func():return not game.state.orchard_staff.enabled);flag("stopped")
		await until(func():return exists("done_checked"))
		assert(not FileAccess.file_exists(n.coop_path));flag("client_done");n.leave("Fim")
	assert(FileAccess.get_file_as_string(game.save_path)==solo)
	game.session_started=false;game.audio.set_process(false);game.audio.stop_all()
	await create_timer(.2).timeout;game.queue_free();await process_frame;await create_timer(.2).timeout
	print("COOP_QA_OK: ORCHARD_STAFF_COOP_OK: "+mode)
	quit()
