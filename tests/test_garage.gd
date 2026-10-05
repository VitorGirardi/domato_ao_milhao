extends SceneTree
var game:Node3D
func _initialize() -> void:call_deferred("run")
func capture(label:String) -> void:
	if DisplayServer.get_name()=="headless":return
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/garage-"+label+".png")
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	var state:=FarmState.new_farm("survival");state.claim(Vector2(4,-2));state.money=10000
	assert(not state.place("garage",Vector2(4,-2),0).is_empty())
	state.farm_xp=280;assert(state.place("garage",Vector2(4,-2),0).is_empty())
	var before:=state.serialize();assert(not FarmGarage.purchase(state,"bed").is_empty() and state.serialize()==before)
	state.resources.stock.iron=28;state.resources.stock.copper=11
	state.money=0;before=state.serialize();assert(not FarmGarage.purchase(state,"engine").is_empty() and state.serialize()==before)
	state.money=9300
	var cash:=state.money
	for key in FarmGarage.UPGRADES:assert(FarmGarage.purchase(state,key).is_empty())
	assert(state.money==cash-2930 and state.resources.stock.iron==0 and state.resources.stock.copper==0)
	before=state.serialize();assert(not FarmGarage.purchase(state,"engine").is_empty() and state.serialize()==before)
	assert(FarmGarage.personalize(state,"name","Trovão da Roça").is_empty())
	assert(FarmGarage.personalize(state,"paint",1).is_empty())
	state.inventory.carrot=120;assert(FarmPickupCargo.transfer(state,"carrot",120,true).is_empty())
	var restored:=FarmState.new();assert(restored.restore(JSON.parse_string(JSON.stringify(state.serialize()))))
	assert(FarmGarage.capacity(restored)==120 and FarmGarage.config(restored).name=="Trovão da Roça" and FarmPickupCargo.count(restored.pickup.cargo)==120)
	before=restored.serialize()
	for bad in [{"name":""},{"paint":5},{"engine":1},{"bed":false},{"name":"a\nb"}]:
		var data:=state.serialize()
		for key in bad:data.pickup.garage[key]=bad[key]
		assert(not restored.restore(data) and restored.serialize()==before)
	var old:=state.serialize();old.pickup.erase("garage");old.pickup.cargo={};assert(restored.restore(old) and FarmGarage.capacity(restored)==60)
	var sandbox:=FarmState.new_farm("sandbox");sandbox.claim(Vector2(4,-2));assert(sandbox.place("garage",Vector2(4,-2),0).is_empty())
	for key in FarmGarage.UPGRADES:assert(FarmGarage.purchase(sandbox,key).is_empty())
	assert(sandbox.resources.stock.iron==0 and sandbox.resources.stock.copper==0)
	game=load("res://scenes/main.tscn").instantiate();game.save_path="user://garage.json";root.add_child(game)
	await process_frame;game.qa_mode=true;game.set_process(false);game.set_physics_process(false)
	game.session_started=true;game.hud.close_modal();game.build_mode=false;game.state=sandbox
	game.world.rebuild(game.state);game.pickup.set_physics_process(false)
	await physics_frame;await physics_frame
	var truck:FarmPickup=game.pickup
	# Drive physically into the bay from the front, stop inside and unload safely.
	truck.restore({"x":4,"z":12,"angle":PI});game.player.position=truck.position+Vector3(2.5,.1,0);game.actor.airborne=false;game.actor.swimming=false
	assert(truck.enter())
	for i in range(180):
		truck.drive(1.0/60,1 if truck.position.z>2 else 0,0,truck.position.z<=2,true)
	assert(truck.position.z<2 and truck.position.z> -3,"Garage entrance blocked: "+str(truck.position))
	truck.speed=0;truck.store();var parked:=truck.position;truck.ensure_parking();assert(truck.position.distance_to(parked)<.1)
	assert(truck.exit_vehicle());assert(FarmGarage.inside_bay(game.state.items[0],Vector2(game.player.position.x,game.player.position.z)))
	game._action("garage:open");assert(game.hud.modal_kind=="garage")
	assert(FarmGarage.can_service(truck));game.hud.text_input.text="Trovão";game._action("garage:name");game._action("garage:paint:1")
	assert(FarmGarage.config(game.state).name=="Trovão" and FarmGarage.config(game.state).paint==1)
	assert(truck.floor_max_angle>FarmPickup.MAX_SLOPE and truck.wheels.FL.scale.x>1)
	assert(truck.accessories.get_child_count()>0)
	assert(FarmPickupCargo.transfer(game.state,"carrot",120,true).is_empty());truck.refresh_cargo();assert(truck.cargo_visual.get_child_count()==12)
	assert(game._save_game(false,true));assert(game._load_game());assert(FarmGarage.config(game.state).name=="Trovão" and FarmGarage.capacity(game.state)==120)
	game.hud.close_modal();game.actor.airborne=false;assert(truck.enter());game._update_ui();game._update_camera(1,true)
	assert(truck.instruments.title.text=="TROVÃO" and not truck.instruments.service.disabled)
	game.hud.toast_time=0;game.hud.toast_panel.visible=false;await capture("parked-dashboard")
	truck.instruments.service.pressed.emit();assert(game.hud.modal_kind=="garage");game.hud.toast_time=0;game.hud.toast_panel.visible=false;await capture("menu");game.hud.close_modal()
	game.camera.position=Vector3(12,6,9);game.camera.look_at(Vector3(4,2,-2));game.hud.visible=false;await capture("world")
	truck.position=Vector3(4,.06,5);truck.rotation.y=PI;truck._animate(0)
	game.camera.position=Vector3(11,5,9);game.camera.look_at(truck.position+Vector3.UP*1.7);await capture("customized");game.hud.visible=true
	var painted:=false
	for mesh in truck.model.find_children("*","MeshInstance3D",true,false):
		for surface in range(mesh.mesh.get_surface_count()):
			var paint:Material=mesh.get_surface_override_material(surface)
			if paint is StandardMaterial3D and paint.albedo_color.is_equal_approx(Color(FarmGarage.COLORS[1])):painted=true
	assert(painted,"Customization must visibly recolor the pickup")
	# Menu alone is not authority: a remote car, moving car or coop cannot buy.
	truck.position.x=30;game._action("garage:open");before=game.state.serialize();game.hud.text_input.text="Remoto";game._action("garage:name");assert(game.state.serialize()==before)
	game.hud.close_modal();game.build_mode=true;game.selected=0;game._action("build:open");assert(game.hud.modal_kind=="garage")
	game.hud.close_modal();game._action("map");assert(game.navigator.destinations().any(func(entry):return entry.key=="garage:0"))
	game.hud.close_modal();game.network.active=true;game._action("garage:open");before=game.state.serialize();game._action("garage:paint:2");assert(game.state.serialize()==before);game.network.active=false
	game.session_started=false;game.audio.stop_all();await create_timer(.15).timeout;game.queue_free();await process_frame
	print("GARAGE_OK: real parking, clear exit, catalog, levels, purchases, materials, upgrades, cargo, customization, saves and coop gate")
	quit()
