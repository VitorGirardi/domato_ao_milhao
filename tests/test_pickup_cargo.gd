extends SceneTree
var game:Node3D
var truck:FarmPickup
func _initialize() -> void:call_deferred("run")

func place(point:Vector2,heading:float) -> void:
	truck.restore({"x":point.x,"z":point.y,"angle":heading})
	game.player.position=truck.door_stand();game.actor.airborne=false;game.actor.swimming=false
	assert(truck.enter())
	while truck.transitioning():truck.drive(.05,0,0,true,true)

func screenshot(label:String) -> void:
	if DisplayServer.get_name()=="headless":return
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/pickup-"+label+".png")

func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	var state:=FarmState.new_farm("survival");assert(state.claim(Vector2(4,-2)).is_empty())
	state.inventory.carrot=65
	assert(FarmPickupCargo.transfer(state,"carrot",60,true).is_empty())
	assert(state.inventory.carrot==5 and FarmPickupCargo.count(FarmPickupCargo.contents(state))==60)
	var before:=state.serialize()
	assert(not FarmPickupCargo.transfer(state,"carrot",1,true).is_empty() and state.serialize()==before)
	assert(not FarmPickupCargo.transfer(state,"carrot",61,false).is_empty() and state.serialize()==before)
	assert(not FarmPickupCargo.transfer(state,"unknown",1,true).is_empty() and state.serialize()==before)
	assert(FarmPickupCargo.transfer(state,"carrot",10,false).is_empty() and state.inventory.carrot==15)
	var loaded:=FarmState.new();assert(loaded.restore(JSON.parse_string(JSON.stringify(state.serialize()))))
	assert(loaded.pickup.cargo.carrot==50)
	var cash:=loaded.money;assert(FarmPickupCargo.sell(loaded)==600 and loaded.money==cash+600)
	assert(FarmPickupCargo.sell(loaded)==0 and loaded.money==cash+600)
	for key in FarmPickupCargo.KEYS:assert(FarmPickupCargo.price(key)>0)
	for invalid in [{"carrot":61},{"carrot":40,"milk":21},{"fake":1},{"milk":-1},{"corn":.5},null]:
		var data:=state.serialize();data.pickup.cargo=invalid;before=loaded.serialize()
		assert(not loaded.restore(data) and loaded.serialize()==before)
	var sandbox:=FarmState.new_farm("sandbox");sandbox.claim(Vector2(4,-2))
	assert(FarmPickupCargo.transfer(sandbox,"quartz",60,true).is_empty() and sandbox.resources.stock.quartz==0)
	assert(FarmPickupCargo.transfer(sandbox,"quartz",60,false).is_empty() and sandbox.resources.stock.quartz==0)
	state.resources.stock.quartz=10000;state.pickup.cargo={"quartz":1};before=state.serialize()
	assert(not FarmPickupCargo.transfer(state,"quartz",1,false).is_empty() and state.serialize()==before)
	game=load("res://scenes/main.tscn").instantiate();game.save_path="user://pickup-cargo.json";root.add_child(game)
	await process_frame;game.qa_mode=true;game.set_process(false);game.set_physics_process(false)
	game.session_started=true;game.build_mode=false;game.hud.close_modal()
	game.state=FarmState.new_farm("survival");game.state.claim(Vector2(4,-2))
	truck=game.pickup;truck.set_physics_process(false)
	await physics_frame;await physics_frame
	# Drive the real authored road segments in both directions, including the
	# serra incline which the old 2.5 m height-spread rule rejected at rest.
	for route in FarmRegion.ROUTES:
		for i in range(route.size()-1):
			for reverse in [false,true]:
				var a:Vector3=route[i+1] if reverse else route[i]
				var b:Vector3=route[i] if reverse else route[i+1]
				var p:=a.lerp(b,.35);place(Vector2(p.x,p.z),atan2(b.x-a.x,b.z-a.z))
				var start:=truck.position
				for frame in range(180):truck.drive(1.0/60,1,0,false,true)
				assert(Vector2(truck.position.x-start.x,truck.position.z-start.z).length()>10,"Road blocked near %s toward %s: %s"%[a,b,truck.blocked_reason])
	# Cross both physical bridges in both directions, not only a water predicate.
	for bridge in [Vector3(420,0,32),Vector3(FarmRegion.legacy_river_x(30),30,11)]:
		for side in [-1,1]:
			place(Vector2(bridge.x+side*bridge.z,bridge.y),-side*PI/2)
			for frame in range(420):truck.drive(1.0/60,1,0,false,true)
			assert((truck.position.x-bridge.x)*side < -bridge.z,"Bridge crossing stopped: %s"%bridge)
	var shallow_found:=false
	print("PICKUP_ROADS_OK: every route segment in both directions and both bridges")
	for offset in range(28,48):
		var p:=Vector2(FarmRegion.legacy_river_x(-15)+offset*.1,-15)
		var at:=Vector3(p.x,FarmLandscape.height_at(p),p.y)
		if FarmPickup.water_depth(p)>.3 and truck.surface_allowed(at,0):shallow_found=true;break
	assert(shallow_found,"Vehicle should reach water deeper than the old 30 cm limit")
	assert(truck.surface_problem(Vector3(285,0,260),0).contains("Água profunda"))
	place(FarmPickup.HOME,PI/2);game.state.inventory.carrot=30;game.state.milk_stock=20;game.state.resources.stock.copper=10
	var cargo_key:=InputEventKey.new();cargo_key.physical_keycode=KEY_V;cargo_key.pressed=true
	game._unhandled_input(cargo_key);assert(game.hud.modal_kind=="pickup_cargo")
	game.state.chapter.stage=1
	for key in ["carrot","carrot","carrot","milk","milk","copper"]:game._action("pickup:load:"+key)
	assert(FarmPickupCargo.count(FarmPickupCargo.contents(game.state))==60 and truck.cargo_visual.get_child_count()==6)
	assert(game.state.inventory.carrot==0 and game.state.milk_stock==0 and game.state.resources.stock.copper==0)
	assert(game._save_game(false,true));assert(game._load_game());assert(game.state.chapter.stage==1)
	assert(FarmPickupCargo.count(FarmPickupCargo.contents(game.state))==60 and truck.cargo_visual.get_child_count()==6)
	await screenshot("cargo-menu")
	# A newly created coop receives the cargo in its own stock; the solo load survives.
	game.network.coop_path="user://cargo_copy_coop.json"
	for path in [game.network.coop_path,game.network.coop_path+".bak"]:
		if FileAccess.file_exists(path):DirAccess.remove_absolute(path)
	game.network.host("Carga QA");assert(game.network.active)
	assert(FarmPickupCargo.count(FarmPickupCargo.contents(game.state))==0 and game.state.inventory.carrot==30)
	game.network.leave();game.session_started=true;game.build_mode=false;game.hud.close_modal()
	assert(FarmPickupCargo.count(FarmPickupCargo.contents(game.state))==60 and game.state.inventory.carrot==0)

	game.hud.close_modal();place(Vector2(30,25),0)
	game._action("pickup:cargo");before=game.state.serialize();game._action("pickup:sell")
	assert(game.state.serialize()==before,"Cargo cannot be sold remotely")
	game.hud.close_modal();truck.speed=5;game._action("pickup:cargo");assert(game.hud.modal_kind.is_empty())
	place(FarmPickup.HOME,PI/2)
	truck.speed=0;truck.steering=.3;truck._animate(0);game._update_ui()
	assert(truck.instruments.visible and truck.instruments.position.x>1000)
	assert(not game.hud.walking.interaction.visible and not game.hud.walking.controls.visible)
	assert(truck.instruments.wheel_angle>0)
	game._update_camera(1,true);game.hud.toast_time=0;game.hud.toast_panel.visible=false;await screenshot("dashboard")
	game.camera.position=truck.to_global(Vector3(-7,6,-9));game.camera.look_at(truck.position+Vector3.UP*1.5)
	game.hud.visible=false;await screenshot("loaded");game.hud.visible=true
	place(FarmPickup.HOME,PI/2);cash=game.state.money
	var value:=FarmPickupCargo.value(game.state);game._action("pickup:cargo");game._action("pickup:sell")
	assert(game.state.money==cash+value and FarmPickupCargo.count(FarmPickupCargo.contents(game.state))==0 and truck.cargo_visual.get_child_count()==0)
	game.hud.close_modal()
	assert(truck.exit_vehicle())
	while truck.transitioning():truck.drive(.05,0,0,true,true)
	game._update_ui()
	assert(not truck.instruments.visible and game.hud.walking.controls.visible)
	game.session_started=false;game.audio.stop_all();await create_timer(.15).timeout;game.queue_free();await process_frame
	print("PICKUP_CARGO_OK: real roads, bridges, ford depth, dashboard, visible cargo, capacity, sale proximity, save atomicity and both modes")
	quit()
