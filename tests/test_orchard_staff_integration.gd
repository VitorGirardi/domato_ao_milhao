extends SceneTree
var game:Node3D

func _initialize() -> void:call_deferred("run")

func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	game=load("res://scenes/main.tscn").instantiate()
	game.save_path="user://orchard-staff-integration.json"
	root.add_child(game);await process_frame
	game.qa_mode=true;game.session_started=true;game.build_mode=false
	game.set_process(false);game.set_physics_process(false);game.pickup.set_physics_process(false)
	game.state=FarmState.new_farm("survival")
	assert(game.state.claim(Vector2(4,-2)).is_empty())
	game.state.farm_xp=1000
	assert(game.state.place("orchard",Vector2(4,-2),0).is_empty())
	assert(game.state.place("orchard",Vector2(10,-2),0).is_empty())
	assert(game.state.place("coop",Vector2(-2,-2),0).is_empty())
	game.world.rebuild(game.state)
	game._action("orchard_staff:open")
	assert(game.hud.modal_kind=="orchard_staff")
	var before:Dictionary=game.state.serialize()
	game._action("orchard_staff:apply")
	assert(game.state.serialize()==before)
	game.state.orchard_journey={"stage":2,"harvested":6}
	FarmOrchardStaffHUD.update(game.hud,game.state)
	var checks:Dictionary=game.hud.modal.get_meta("orchard_staff_checks")
	checks[0].button_pressed=true;checks[1].button_pressed=false
	assert(FarmCoopCommands.capture(game,"orchard_staff:apply").trees==[0])
	before=game.state.serialize()
	var good_path:String=game.save_path
	game.save_path="user://missing-orchard-staff-directory/cannot-save.json"
	game._action("orchard_staff:apply")
	assert(game.state.serialize()==before,"Failed persistence must not charge for hiring")
	game.save_path=good_path
	game._action("orchard_staff:apply")
	assert(game.state.staff.hired and game.state.orchard_staff.trees==[0])
	assert(game.state.money==before.money-120)
	assert(game.state.residents==before.residents and game.state.pickup==before.pickup)
	game._action("close")
	for i in range(500):
		game.world.update_staff(game.state,.1)
		if game.state.orchard_staff.services==1:break
	assert(game.state.items[0].orchard.watered and not game.state.items[1].orchard.watered)
	assert(game.state.orchard_staff.services==1 and game.state.orchard_staff.spent==2)
	game.state.tick(300)
	for i in range(500):
		game.world.update_staff(game.state,.1)
		if game.state.orchard_staff.services==2:break
	assert(game.state.inventory.orange==6 and game.state.orchard_staff.spent==4)
	game._action("orchard_staff:pause")
	before=game.state.serialize()
	for i in range(100):game.world.update_staff(game.state,.1)
	assert(game.state.serialize()==before)
	game._action("orchard_staff:open")
	checks=game.hud.modal.get_meta("orchard_staff_checks")
	checks[1].button_pressed=true
	var check_id:int=checks[1].get_instance_id()
	game._update_ui()
	assert(game.hud.modal.get_meta("orchard_staff_checks")[1].get_instance_id()==check_id and checks[1].button_pressed)
	assert(game._save_game(false,true));assert(game._load_game())
	assert(game.state.orchard_staff.paused and game.state.orchard_staff.services==2)
	assert(game.state.orchard_staff.trees==[0],"Unsaved UI draft must not become the active routine")
	game.hud.staff_target=2;game._action("staff_assign")
	assert(not game.state.orchard_staff.enabled)
	game._action("staff_pause")
	assert(FarmStaff.running(game.state.staff) and not FarmOrchardStaff.active(game.state))
	game.session_started=false;game.audio.stop_all()
	await create_timer(1.6).timeout
	game.queue_free();await process_frame;game=null;await create_timer(.2).timeout
	print("ORCHARD_STAFF_INTEGRATION_OK: UI selection, persisted hiring, disk rollback, actual work, pause, draft, saves and single Zeca")
	quit()
