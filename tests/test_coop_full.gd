extends "res://tests/test_coop.gd"
func locate(kind:String) -> int:
	for i in range(game.state.items.size()):
		if game.state.items[i].kind==kind:return i
	return -1
func build(kind:String) -> void:
	for z in range(-16,17,2):
		for x in range(-12,21,2):
			if game.state.can_place(kind,Vector2(x,z),0).is_empty():
				assert(game.state.place(kind,Vector2(x,z),0).is_empty());return
	assert(false,"No space for "+kind)
func command(c:Dictionary) -> void:
	n.request_command(c)
	await until(func():return not n.command_busy)
	await create_timer(.1).timeout
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	mode=OS.get_cmdline_user_args()[0];flags=OS.get_cmdline_user_args()[1]
	game=load("res://scenes/main.tscn").instantiate();game.name="Main";game.save_path="user://full_solo.json";root.add_child(game);await process_frame
	game.qa_mode=true;game.state.unlimited_money=true
	FarmCharacters.apply_to_game(game,"farmer_woman" if mode=="client" else "farmer")
	if mode=="host":
		game.state.farm_xp=10000;game.state.claim(Vector2(4,0));game.state.expand();game.state.expand();game.world.rebuild(game.state)
		for kind in ["plot","coop","corral","cheesery","barn","workshop"]:build(kind)
		game.state.inventory.carrot=10;game.state.items[locate("coop")].flock.nest=6
	game._save_game(false,true);solo=FileAccess.get_file_as_string(game.save_path);n=game.network
	if mode=="host":
		n.host("Vitor");game.hud.close_modal();flag("host_ready")
		await until(func():return n.accepted!=0 and exists("client_ready"))
		assert(n.remote_model.get_meta("character_id")=="farmer_woman")
		await until(func():return exists("economy_done"))
		assert(game.state.inventory.carrot==8 and game.state.inventory.egg==6)
		assert(game.state.items[locate("corral")].dairy.owned)
		assert(game.state.staff.hired and game.state.field_staff.hired and game.state.dairy_worker.hired and game.state.cheese_worker.hired)
		assert(game.state.count_items("sign")==1)
		# Remote removal must invalidate old index-based commands, not sell a different object.
		var old:=n.structure_version
		await command({"action":"remove","index":locate("sign")})
		var before:int=game.state.items.size()
		n.sequence+=1;n.apply_command(1,n.sequence,old,{"action":"remove","index":0})
		assert(game.state.items.size()==before);flag("stale_checked")
		await until(func():return n.mounts.rider==n.accepted)
		var horse_at:Vector3=game.horse.position
		await until(func():return game.horse.position.distance_to(horse_at)>1)
		assert(game.horse.stamina<100);flag("ride_checked")
		await until(func():return n.mounts.rider==0 and exists("dismounted"))
		await until(func():return exists("client_done"))
		n.leave("Fim");assert(FileAccess.get_file_as_string(game.save_path)==solo)
		var persisted:=FarmCoop.load_farm(n.coop_path);assert(persisted!=null and persisted.inventory.carrot==8 and persisted.staff.hired)
	else:
		n.join("127.0.0.1","Ian");await until(func():return n.ready_session)
		assert(n.remote_model.get_meta("character_id")=="farmer");game.hud.close_modal();flag("client_ready")
		await command({"action":"sell_product:carrot","quantity":2})
		var revenue:int=game.state.revenue
		n._command.rpc_id(1,n.sequence,n.structure_version,{"action":"sell_product:carrot","quantity":2})
		await create_timer(.3).timeout;assert(game.state.revenue==revenue and game.state.inventory.carrot==8)
		await command({"action":"care:collect","index":locate("coop")})
		await command({"action":"dairy:buy","index":locate("corral")})
		await command({"action":"staff_hire","site":locate("coop")})
		await command({"action":"crew_hire"})
		for role in ["raul","chico"]:await command({"action":role+":confirm","operation":"hire"})
		for z in range(-16,17,2):
			if game.state.count_items("sign")>0:break
			for x in range(-12,21,2):
				if game.state.can_place("sign",Vector2(x,z),0).is_empty():
					await command({"action":"place","kind":"sign","at":Vector2(x,z),"turn":0});break
		assert(game.state.count_items("sign")==1)
		await until(func():return not n.visual_state.is_empty())
		flag("economy_done");await until(func():return exists("stale_checked"))
		game.player.position=game.horse.position+Vector3(1.8,.2,0)
		await create_timer(.7).timeout
		n.mounts.request("mount");await until(func():return n.mounts.local_rider())
		n.mounts.request("sprint");await until(func():return game.horse.burst>0)
		Input.action_press("back")
		await until(func():return exists("ride_checked"));Input.action_release("back")
		if DisplayServer.get_name()!="headless":
			game._update_camera(1,true);game.hud.toast_time=0
			await process_frame;await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(flags.path_join("coop-horse.png"))
		n.mounts.request("dismount");await until(func():return n.mounts.rider==0);flag("dismounted")
		assert(not game.horse.mounted and game.avatar.position==Vector3.ZERO)
		if DisplayServer.get_name()!="headless":
			game._action("market");await process_frame;await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(flags.path_join("coop-market.png"))
		flag("client_done");await until(func():return not n.active)
		assert(FileAccess.get_file_as_string(game.save_path)==solo)
	game.audio.stop_all();await create_timer(.2).timeout;game.queue_free();await process_frame;await create_timer(.2).timeout
	print("COOP_QA_OK: ",mode," full commands, shared economy, workers, visual replication, female handshake, mount/sprint/dismount and persistence")
	quit()
