extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	var game=load("res://scenes/main.tscn").instantiate();game.name="Main";game.save_path="user://combat_authority.json";root.add_child(game)
	await process_frame;game.qa_mode=true;game.state.unlimited_money=true
	var solo:Dictionary=game.state.armory.duplicate(true)
	game.network.host("Combat QA");game.hud.close_modal()
	var combat:FarmCombatNet=game.weapons.combat
	var at:=Vector3(20,FarmLandscape.height_at(Vector2(20,0)),0)
	game.player.position=at;game.actor.airborne=false;game.actor.action_time=0
	FarmArmory.buy_pistol(game.state,game.state.armory);game.weapons.armed=true
	await physics_frame
	var origin:=at+Vector3(0,1.4,0);var end:=origin+Vector3(30,0,0)
	assert(not combat.apply_request(1,"fire",Vector3(INF,0,0),end))
	assert(not combat.apply_request(1,"fire",origin,origin+Vector3(100,0,0)))
	assert(not combat.apply_request(1,"fire",origin+Vector3(3,0,0),end))
	assert(combat.apply_request(1,"fire",origin,end))
	assert(game.state.armory.magazine==7 and combat.seen_shots==1)
	assert(not combat.apply_request(1,"fire",origin,end))
	assert(combat.apply_request(1,"reload",Vector3.ZERO,Vector3.ZERO))
	assert(not combat.apply_request(1,"fire",origin,end))
	assert(combat.bag_for(99).magazine==0 and not combat.bag_for(99).pistol)
	assert(game.state.armory.magazine==7)
	# Reload uses a monotonic deadline, while SceneTreeTimer uses frame delta.
	# An expensive startup frame may finish a scene timer before that deadline.
	var limit:=Time.get_ticks_msec()+5000
	while combat.reloads.has(1) and Time.get_ticks_msec()<limit:await process_frame
	assert(not combat.reloads.has(1),"Authoritative reload must finish within five seconds")
	assert(game.state.armory.magazine==8 and game.state.armory.reserve==23,str(game.state.armory))
	game.network.leave();assert(game.state.armory==solo)
	print("COMBAT_AUTHORITY_OK");game.queue_free();await process_frame;quit()

