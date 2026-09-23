extends "res://tests/test_coop_full.gd"
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	game=load("res://scenes/main.tscn").instantiate();game.save_path="user://automation_solo.json";root.add_child(game);await process_frame
	game.qa_mode=true;game.state.unlimited_money=true;game.state.farm_xp=10000
	game.state.claim(Vector2(4,0));game.state.expand();game.state.expand();game.world.rebuild(game.state)
	for kind in ["plot","coop","corral","cheesery"]:build(kind)
	game.state.items[locate("coop")].flock.nest=12
	game.state.items[locate("plot")].growth=1;game.state.items[locate("plot")].watered=true
	game.state.items[locate("corral")].dairy.owned=true;game.state.items[locate("corral")].dairy.milk=8
	game.state.milk_stock=8
	n=game.network;n.host("Automação QA");game.hud.close_modal()
	n.request_command({"action":"staff_hire","site":locate("coop")})
	n.request_command({"action":"crew_hire"})
	n.request_command({"action":"cultivation_apply","draft":{"plans":[{"index":locate("plot"),"crop":"carrot"}],"tasks":{"plant":true,"water":true,"harvest":true},"limit":100}})
	for role in ["raul","chico"]:
		n.request_command({"action":role+":confirm","operation":"hire"})
		n.request_command({"action":role+":confirm","operation":"apply","site":locate("corral" if role=="raul" else "cheesery"),"batch":1,"budget":100})
	game.set_process(false);game.set_physics_process(false);n.set_process(false);n.mounts.set_physics_process(false)
	for step in range(5500):
		n._process(.1)
		if step%60==0:await process_frame
		if game.state.staff.eggs>0 and game.state.cultivation.actions.harvest>0 and game.state.dairy_worker.collected>0 and game.state.cheese_worker.collected>0:break
	assert(game.state.staff.eggs>0,"Zeca: "+str(game.state.staff))
	assert(game.state.cultivation.actions.harvest>0,"Bento: "+str(game.state.cultivation)+str(game.state.field_staff))
	assert(game.state.dairy_worker.collected>0,"Raul: "+str(game.state.dairy_worker))
	assert(game.state.cheese_worker.collected>0,"Chico: "+str(game.state.cheese_worker))
	assert(n.save_coop());var saved:=FarmCoop.load_farm(n.coop_path)
	assert(saved!=null and saved.inventory==game.state.inventory and saved.cheese_stock==game.state.cheese_stock)
	print("COOP_AUTOMATION_OK: host completes Zeca/Bento/Raul/Chico work and persists their shared production")
	n.leave();game.audio.stop_all();game.queue_free();await process_frame;await create_timer(.2).timeout;quit()
