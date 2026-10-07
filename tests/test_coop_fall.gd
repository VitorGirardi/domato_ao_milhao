extends "res://tests/test_coop.gd"
func ground(x:float,z:float) -> Vector3:return Vector3(x,FarmLandscape.height_at(Vector2(x,z))+.06,z)
func host_shot(at:Vector3,expected:String) -> void:
	game.weapons.armed=true;game.actor.airborne=false;game.actor.action_time=0
	var origin:Vector3=game.player.position+Vector3.UP*1.4
	var hit:Dictionary=game.falls.trace_hit(origin,at,1)
	assert(hit.get("key","")==expected,"Fixture ray hit %s, expected %s"%[hit,expected])
	assert(game.weapons.combat.apply_request(1,"fire",origin,at))
	assert(game.falls.is_down(expected),"Validated pistol failed to knock target down")
func finish_falls() -> void:
	game.falls.advance(60)
	assert(not game.falls.records.is_empty(),"Recovery animation must remain active after 60 seconds")
	for record in game.falls.records.values():assert(record.age>=60 and record.age<62)
	game.falls.advance(2.1)
	assert(game.falls.records.is_empty())
	game.falls.sync_to(n.accepted)
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	mode=OS.get_cmdline_user_args()[0];flags=OS.get_cmdline_user_args()[1]
	game=load("res://scenes/main.tscn").instantiate();game.name="Main";game.save_path="user://fall_solo.json";root.add_child(game)
	await process_frame;game.qa_mode=true;game.state.unlimited_money=true
	game._save_game(false,true);solo=FileAccess.get_file_as_string(game.save_path);n=game.network
	var combat:FarmCombatNet=game.weapons.combat
	if mode=="host":
		n.host("Vitor");game.hud.close_modal()
		FarmArmory.buy_pistol(game.state,game.state.armory)
		game.player.position=ground(-29,22);await create_timer(.3).timeout
		host_shot(game.weapons.npc.global_position+Vector3.UP*1.8,"npc:armorer")
		game.horse.position=ground(20,0);game.horse.life.reset(game.horse)
		game.player.position=ground(20,-5);flag("host_ready")
		await until(func():return exists("late_join_received"))
		assert(game.falls.is_down("npc:armorer"))
		game.horse.position=ground(20,0);game.horse.life.reset(game.horse);n.mounts.send_initial();flag("mount_now")
		await until(func():return n.mounts.rider==n.accepted and n.accepted!=0 and exists("guest_mounted"))
		host_shot(game.horse.position+Vector3.UP,"horse")
		assert(n.mounts.rider==0 and not game.horse.mounted)
		await until(func():return exists("horse_seen"))
		# NPC has already been down during joining; set a common boundary to test exactly 60/62.
		for record in game.falls.records.values():record.age=0.0
		finish_falls()
		assert(not game.falls.knock_down("horse") and not game.falls.knock_down("npc:armorer"))
		await until(func():return exists("world_recovered"))
		game.falls.advance(3.1)
		game.player.position=ground(2,0);flag("player_stage")
		await until(func():return exists("guest_in_place"))
		await create_timer(.25).timeout
		var guest_key:String=game.falls.player_key(n.accepted)
		host_shot(n.target+Vector3.UP*1.3,guest_key)
		var fixed:Vector3=n.target
		await until(func():return exists("guest_frozen"))
		assert(n.target.distance_to(fixed)<.05 and n.remote.position.distance_to(fixed)<.1)
		assert(combat.bag_for(n.accepted).magazine==8,"Fallen guest fired")
		game.falls.records[guest_key].age=0.0;finish_falls()
		assert(not game.falls.knock_down(guest_key))
		await until(func():return exists("guest_recovered"))
		game.falls.advance(3.1);game.falls.sync_to(n.accepted);flag("shoot_host")
		await until(func():return game.falls.local_down())
		var host_at:Vector3=game.player.position
		Input.action_press("forward");await create_timer(.3).timeout;Input.action_release("forward")
		assert(game.player.position.distance_to(host_at)<.05 and game.player.velocity.length()<.01)
		assert(not combat.apply_request(1,"fire",host_at+Vector3.UP*1.4,n.target+Vector3.UP))
		await until(func():return exists("host_fall_seen"))
		game.falls.records["player:1"].age=0.0;finish_falls()
		assert(not game.falls.knock_down("player:1"))
		flag("host_recovered")
		await until(func():return exists("client_done") and n.accepted==0)
		assert(game.state.armory.magazine==5,"Unexpected host ammunition consumption")
		assert(n.save_coop());n.leave();assert(FileAccess.get_file_as_string(game.save_path)==solo)
	else:
		n.join("127.0.0.1","Ian");await until(func():return n.ready_session)
		await until(func():return game.falls.is_down("npc:armorer"))
		assert(game.weapons.npc.get_meta("temporary_down",false));assert(not game.weapons.near_shop())
		assert(not game.falls.knock_down("horse"),"Guest can directly decide falls")
		flag("late_join_received");await until(func():return exists("mount_now"))
		game.player.position=ground(21.8,0);await create_timer(.5).timeout
		n.mounts.request("mount");await create_timer(.5).timeout
		assert(n.mounts.local_rider(),"Mount fixture failed: horse %s player %s"%[game.horse.position,game.player.position]);flag("guest_mounted")
		await until(func():return game.falls.is_down("horse") and n.mounts.rider==0)
		assert(not game.horse.mounted and game.player.collision_layer!=0 and not game.falls.local_down())
		assert(not FarmWater.swimming_at(game.player.position));flag("horse_seen")
		await until(func():return not game.falls.is_down("horse") and not game.falls.is_down("npc:armorer"))
		assert(absf(game.weapons.npc.rotation.x)<.01 and absf(game.weapons.npc.rotation.z)<.01,"Late-join NPC did not recover upright")
		assert(not game.horse.get_meta("temporary_down",false));flag("world_recovered")
		# Buy the visitor's own gun once the armorer has recovered.
		game.player.position=ground(-30.7,22);await create_timer(.6).timeout;combat.request("buy")
		await until(func():return combat.inventory().pistol)
		await until(func():return exists("player_stage"))
		game.player.position=ground(10,0);await create_timer(.6).timeout;flag("guest_in_place")
		await until(func():return game.falls.local_down())
		var fixed:Vector3=game.player.position
		Input.action_press("forward");await create_timer(.35).timeout;Input.action_release("forward")
		assert(game.player.position.distance_to(fixed)<.05 and game.player.velocity.length()<.01)
		n._motion.rpc_id(1,fixed+Vector3(8,0,0),0.0,true,true,false,"",0.0)
		combat.request("fire",fixed+Vector3.UP*1.4,n.remote.position+Vector3.UP)
		await create_timer(.15).timeout;flag("guest_frozen")
		await until(func():return not game.falls.local_down())
		assert(game.player.collision_layer!=0 and combat.inventory().magazine==8);flag("guest_recovered")
		await until(func():return exists("shoot_host"))
		game.weapons.armed=true;await create_timer(.15).timeout
		combat.request("fire",game.player.position+Vector3.UP*1.4,n.remote.position+Vector3.UP*1.3)
		await until(func():return game.falls.is_player_down(1))
		assert(combat.inventory().magazine==7);flag("host_fall_seen")
		await until(func():return exists("host_recovered") and not game.falls.is_player_down(1))
		assert(combat.inventory().magazine==7 and game.player.collision_layer!=0)
		n.leave();assert(FileAccess.get_file_as_string(game.save_path)==solo);flag("client_done")
	game.session_started=false;game.audio.stop_all();await create_timer(.2).timeout
	game.queue_free();await process_frame;await create_timer(.2).timeout
	print("COOP_QA_OK: ",mode," pistol falls, late join, horse dismount, frozen players, 60-second lifecycle, immunity and preserved saves")
	quit()


