extends "res://tests/test_coop.gd"
## Two real ENet peers must exchange positions beyond the legacy valley bounds.
const HIGH_AT := Vector3(700, 88, -325)
const MINE_AT := Vector3(900, 82, -216)

func check_destinations() -> void:
	for key in ["serra_view", "serra_mine", "valley_lake", "mountain_lake"]:
		game.navigator.handle("map:go:"+key)
		assert(game.navigator.target_key==key, "Missing authored region destination: "+key)
		assert(game.navigator.waypoint.distance_to(FarmRegion.PLACES[key].at)<.01)

func check_farm() -> void:
	assert(game.state.claimed and game.state.unlimited_money)
	assert(game.state.center==Vector2(4,0))
	assert(game.state.items.size()==1 and game.state.items[0].kind=="plot")
	assert(game.state.items[0].x==4 and game.state.items[0].z==0)
	assert(not game.state.items[0].planted and game.state.inventory.carrot==17)

func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	mode=OS.get_cmdline_user_args()[0];flags=OS.get_cmdline_user_args()[1]
	game=load("res://scenes/main.tscn").instantiate();game.name="Main"
	game.save_path="user://region_solo.json";root.add_child(game)
	await process_frame
	game.qa_mode=true;game.state.unlimited_money=true
	if mode=="host":
		game.state.claim(Vector2(4,0))
		assert(game.state.place("plot",Vector2(4,0),0).is_empty())
		game.state.items[0].planted=false;game.state.inventory.carrot=17
	game._save_game(false,true)
	solo=FileAccess.get_file_as_string(game.save_path);n=game.network
	# Prevent gravity/collision from shifting the exact network samples. Network
	# _process and ENet remain active; physical traversal has a separate test.
	game.set_physics_process(false)
	if mode=="host":
		n.host("Vitor");game.hud.close_modal();flag("host_ready")
		await until(func():return n.accepted!=0 and exists("client_ready"))
		check_destinations();check_farm()
		game.navigator.handle("map:go:friend")
		game.player.position=HIGH_AT;game.player.velocity=Vector3.ZERO
		flag("host_on_serra")
		await until(func():return exists("guest_on_mine") and n.remote.position.distance_to(MINE_AT)<.15)
		game.navigator.refresh()
		assert(game.navigator.waypoint.distance_to(Vector2(MINE_AT.x,MINE_AT.z))<.2)
		flag("guest_seen")
		await until(func():return exists("client_done") and n.accepted==0)
		check_farm()
		# A horse parked in the expansion survives save validation and reopening.
		game.horse.restore({"x":705.0,"z":-325.0,"angle":0.0})
		game.horse.store(game.state)
		assert(n.save_coop())
		var restored:=FarmCoop.load_farm(n.coop_path)
		assert(restored!=null and restored.unlimited_money)
		assert(restored.horse.x==705 and restored.horse.z== -325)
		assert(restored.inventory.carrot==17 and restored.items.size()==1)
		n.leave("Fim")
		assert(FileAccess.get_file_as_string(game.save_path)==solo)
		n.host("Vitor");game.hud.close_modal()
		check_farm()
		assert(game.horse.position.x==705 and game.horse.position.z== -325)
		n.leave("Fim")
	else:
		n.join("127.0.0.1","Ian")
		await until(func():return n.ready_session)
		game.hud.close_modal();check_destinations();check_farm()
		game.navigator.handle("map:go:friend");flag("client_ready")
		await until(func():return exists("host_on_serra") and n.remote.position.distance_to(HIGH_AT)<.15)
		game.navigator.refresh()
		assert(game.navigator.waypoint.distance_to(Vector2(HIGH_AT.x,HIGH_AT.z))<.2)
		game.player.position=MINE_AT;game.player.velocity=Vector3.ZERO;flag("guest_on_mine")
		await until(func():return exists("guest_seen"))
		check_farm();assert(not FileAccess.file_exists(n.coop_path))
		flag("client_done");n.leave("Fim")
	assert(FileAccess.get_file_as_string(game.save_path)==solo, "Region coop changed solo save")
	game.audio.stop_all();game.queue_free();await process_frame
	await create_timer(.2).timeout
	print("COOP_REGION_OK: "+mode+" distant/high remote positions, destinations, farm preservation, solo isolation and parked horse resume")
	quit()
