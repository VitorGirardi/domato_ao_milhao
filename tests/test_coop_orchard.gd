extends "res://tests/test_coop.gd"

const TREE_AT:=Vector2(4,3.5)
const MARKET_AT:=Vector2(-24,14)
const FAR_AT:=Vector2(60,60)

func move_to(at:Vector2) -> void:
	game.player.position=Vector3(at.x,FarmLandscape.height_at(at)+.1,at.y)
	game.player.velocity=Vector3.ZERO
	game.actor.airborne=false;game.actor.swimming=false

func command(action:String) -> void:
	n.request_command({"action":action,"index":0})
	await until(func():return not n.command_busy)

func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	mode=OS.get_cmdline_user_args()[0];flags=OS.get_cmdline_user_args()[1]
	game=load("res://scenes/main.tscn").instantiate();game.name="Main"
	game.save_path="user://orchard_solo.json";root.add_child(game);await process_frame
	game.qa_mode=true;game.set_physics_process(false)
	game.state=FarmState.new_farm("survival")
	if mode=="host":
		game.state.farm_xp=FarmLevels.THRESHOLDS[1]
		assert(game.state.claim(Vector2(4,0)).is_empty())
		assert(game.state.place("orchard",Vector2(4,0),0).is_empty())
	assert(game._save_game(false,true))
	solo=FileAccess.get_file_as_string(game.save_path);n=game.network
	if mode=="host":
		n.host("Vitor");assert(n.active and n.hosting);game.hud.close_modal();flag("host_ready")
		await until(func():return n.accepted!=0 and exists("client_ready"))
		var balance:int=game.state.money
		var reputation:int=game.state.trade.nena.reputation
		await until(func():return exists("accepted"))
		assert(game.state.orchard_journey.stage==1 and game.state.orchard_journey.harvested==0)
		await until(func():return exists("far_water"))
		assert(not game.state.items[0].orchard.watered)
		assert(game.state.money==balance);flag("far_water_checked")
		await until(func():return exists("watered"))
		assert(game.state.items[0].orchard.watered)
		# Advance authoritative simulation, then replicate its mature fruit state.
		game.state.tick(300);game.world.update_orchards(game.state)
		assert(game.state.items[0].orchard.ready==6)
		n.broadcast_state();flag("ripe")
		await until(func():return exists("far_harvest"))
		assert(game.state.items[0].orchard.ready==6 and game.state.inventory.orange==0)
		assert(game.state.orchard_journey.harvested==0);flag("far_harvest_checked")
		await until(func():return exists("harvested"))
		assert(game.state.items[0].orchard.ready==0 and game.state.inventory.orange==6)
		assert(game.state.harvests==1 and game.state.orchard_journey.harvested==6)
		flag("harvest_checked")
		await until(func():return exists("far_deliver"))
		assert(game.state.orchard_journey.stage==1 and game.state.inventory.orange==6)
		assert(game.state.money==balance);flag("far_deliver_checked")
		var xp:int=game.state.farm_xp
		await until(func():return exists("delivered"))
		assert(game.state.orchard_journey.stage==2 and game.state.inventory.orange==0)
		assert(game.state.money==balance+220 and game.state.revenue==220)
		assert(game.state.trade.nena.reputation==reputation+1 and game.state.farm_xp==xp+30)
		assert(n.save_coop())
		var saved:=FarmCoop.load_farm(n.coop_path)
		assert(saved!=null and saved.orchard_journey.stage==2 and saved.orchard_journey.harvested==6)
		assert(saved.inventory.orange==0 and saved.money==balance+220 and saved.items[0].orchard.growth==180)
		flag("delivery_checked")
		await until(func():return exists("client_done") and n.accepted==0)
		n.leave("Fim")
		assert(game.state.orchard_journey.stage==0 and game.state.inventory.orange==0)
		assert(game.state.items[0].orchard==FarmOrchard.fresh_item())
	else:
		n.join("127.0.0.1","Ian");await until(func():return n.ready_session);game.hud.close_modal()
		move_to(FAR_AT);await create_timer(.6).timeout;flag("client_ready")
		await command("orchard:accept")
		await until(func():return game.state.orchard_journey.stage==1);flag("accepted")
		await command("orchard:water");flag("far_water")
		await until(func():return exists("far_water_checked"))
		move_to(TREE_AT);await create_timer(.6).timeout
		await command("orchard:water")
		await until(func():return game.state.items[0].orchard.watered);flag("watered")
		await until(func():return exists("ripe") and game.state.items[0].orchard.ready==6)
		move_to(FAR_AT);await create_timer(.6).timeout
		await command("orchard:harvest");flag("far_harvest")
		await until(func():return exists("far_harvest_checked"))
		move_to(TREE_AT);await create_timer(.6).timeout
		await command("orchard:harvest")
		await until(func():return game.state.inventory.orange==6)
		# A replay and a fresh duplicate must both fail to create a second crop.
		n._command.rpc_id(1,n.sequence,n.structure_version,{"action":"orchard:harvest","index":0})
		await command("orchard:harvest");flag("harvested")
		await until(func():return exists("harvest_checked"))
		move_to(FAR_AT);await create_timer(.6).timeout
		await command("orchard:deliver");flag("far_deliver")
		await until(func():return exists("far_deliver_checked"))
		move_to(MARKET_AT);await create_timer(.6).timeout
		await command("orchard:deliver")
		await until(func():return game.state.orchard_journey.stage==2)
		n._command.rpc_id(1,n.sequence,n.structure_version,{"action":"orchard:deliver"})
		await command("orchard:deliver")
		assert(game.state.inventory.orange==0 and game.state.orchard_journey.harvested==6)
		flag("delivered");await until(func():return exists("delivery_checked"))
		assert(not FileAccess.file_exists(n.coop_path));flag("client_done");n.leave("Fim")
	assert(FileAccess.get_file_as_string(game.save_path)==solo)
	game.session_started=false;game.audio.set_process(false);game.audio.stop_all()
	await create_timer(.2).timeout;game.queue_free();await process_frame;await create_timer(.2).timeout
	print("COOP_QA_OK: COOP_ORCHARD_OK: "+mode+" distance, shared watering/growth/harvest, replay rejection, unique reward and separate saves")
	quit()
