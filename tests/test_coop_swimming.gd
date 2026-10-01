extends "res://tests/test_coop.gd"
## Real ENet movement and renderer pose: river and lake immersion in both peers.
const RIVER_AT := Vector3(446, .85, 45)
const LAKE_AT := Vector3(810, 66.85, -235)

func place_actor(at:Vector3,swimming:bool) -> void:
	game.player.position=at
	game.player.velocity=Vector3(.6,0,0) if swimming else Vector3.ZERO
	game.actor.airborne=false
	game.actor.swimming=swimming

func seen(at:Vector3,swimming:bool) -> bool:
	if not is_instance_valid(n.remote) or n.remote.position.distance_to(at)>.12:return false
	if n.remote_actor.swimming!=swimming:return false
	var pitch:float=n.remote_actor.root.rotation.x
	return pitch>.55 if swimming else absf(pitch)<.035

func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	mode=OS.get_cmdline_user_args()[0];flags=OS.get_cmdline_user_args()[1]
	game=load("res://scenes/main.tscn").instantiate();game.name="Main"
	game.save_path="user://swimming_solo.json";root.add_child(game);await process_frame
	game.qa_mode=true;game.state.unlimited_money=true
	if mode=="host":
		game.state.claim(Vector2(4,0));game.state.resources.rod=true
	game._save_game(false,true);solo=FileAccess.get_file_as_string(game.save_path)
	n=game.network
	# Freeze local physics to send repeatable submerged poses through the real
	# network path. Buoyancy and shore traversal have separate physical tests.
	game.set_physics_process(false)
	assert(FarmWater.swimming_at(RIVER_AT) and FarmWater.swimming_at(LAKE_AT))
	var dry:=FarmResourceSites.point(FarmResourceSites.FISH_SPOTS[1])
	assert(not FarmWater.swimming_at(dry))
	if mode=="host":
		n.host("Vitor");game.hud.close_modal();flag("host_ready")
		await until(func():return n.accepted!=0 and exists("client_ready"))
		place_actor(RIVER_AT,true);flag("host_in_river")
		await until(func():return exists("client_in_lake") and seen(LAKE_AT,true))
		assert(n.remote.position.y<FarmRegion.water_level(Vector2(LAKE_AT.x,LAKE_AT.z))-.65)
		assert(not n.remote_actor.airborne)
		assert(not game.gathering._valid_actor(n.accepted),"Host must reject collection by swimming guest")
		assert(not game.gathering._valid_actor(1),"Swimming host cannot collect either")
		game.gathering.last_request.clear()
		assert(not game.gathering.apply(n.accepted,"gather:fish:1").is_empty())
		assert(game.gathering.jobs.is_empty())
		flag("host_saw_swim")
		await until(func():return exists("client_saw_swim"))
		place_actor(dry,false);flag("host_dry")
		await until(func():return exists("client_dry") and seen(dry,false))
		assert(game.gathering._valid_actor(n.accepted),"Guest becomes eligible again on land")
		flag("host_saw_dry")
		await until(func():return exists("client_done"))
		assert(game.state.resources.caught==0 and game.state.resources.mined==0)
		n.leave("Fim")
	else:
		n.join("127.0.0.1","Ian");await until(func():return n.ready_session)
		game.hud.close_modal();flag("client_ready")
		place_actor(LAKE_AT,true);flag("client_in_lake")
		await until(func():return exists("host_in_river") and seen(RIVER_AT,true))
		assert(n.remote.position.y<1.35 and not n.remote_actor.airborne)
		flag("client_saw_swim")
		await until(func():return exists("host_saw_swim"))
		place_actor(dry,false);flag("client_dry")
		await until(func():return exists("host_dry") and seen(dry,false))
		await until(func():return exists("host_saw_dry"))
		assert(not FileAccess.file_exists(n.coop_path))
		flag("client_done");await until(func():return not n.active)
	assert(FileAccess.get_file_as_string(game.save_path)==solo,"Swimming coop changed the solo save")
	game.audio.stop_all();game.queue_free();await process_frame;await create_timer(.2).timeout
	print("COOP_QA_OK: COOP_SWIMMING_OK: "+mode+" submerged river/lake remote pose, dry pose recovery, host collection guard and solo isolation")
	quit()
