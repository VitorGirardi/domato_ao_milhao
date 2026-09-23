extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	root.size=Vector2i(1440,900)
	var game:Node3D=load("res://scenes/main.tscn").instantiate();game.save_path="user://map.json";root.add_child(game)
	await process_frame;game.qa_mode=true;game.set_process(false);game.set_physics_process(false)
	game.state=FarmState.new();game.state.unlimited_money=true;game.state.claim(Vector2(4,0));game.state.farm_xp=100000;game.state.land_size=40
	for pair in [["coop",Vector2(-6,-8)],["barn",Vector2(12,-12)],["cheesery",Vector2(4,-12)],["stable",Vector2(8,4)]]:
		assert(game.state.place(pair[0],pair[1],0).is_empty())
	assert(game.state.items.size()==4)
	game.state.items[0].flock.nest=6;game.state.items[0].flock.water=10
	game.state.items[2].cheese.ready=2
	game.world.rebuild(game.state);game.world.cat.reset(game.state)
	game.session_started=true;game.build_mode=false;game.hud.close_modal();game.player.position=Vector3(4,0,10)
	var nav:FarmNavigation=game.navigator
	var before:Dictionary=game.state.serialize()
	nav.handle("map:go:cat");assert(nav.target_key=="cat")
	game.world.cat.position.x+=3;nav.refresh();assert(nav.waypoint.x==game.world.cat.position.x)
	assert(FarmMapPlaces.notices(game.state.items[0]).contains("ovos") and FarmMapPlaces.notices(game.state.items[0]).contains("água"))
	assert(FarmMapPlaces.notices(game.state.items[2])=="Queijo pronto")
	assert(FarmMapPlaces.notices({"kind":"corral","dairy":{"owned":false,"water":0}}).is_empty())
	assert(FarmMapPlaces.notices({"kind":"pigsty","pigs":{"count":0,"food":0}}).is_empty())
	assert(FarmMapPlaces.notices({"kind":"pigsty","pigs":{"count":1,"food":24}})=="Pouca ração")
	assert(FarmMapPlaces.notices({"kind":"corral","dairy":{"owned":true,"milk":1}})=="Leite para ordenhar")
	nav.handle("map:go:stable:3");game.state.items[3].x+=2;nav.refresh()
	assert(nav.waypoint==FarmStable.entrance(game.state.items[3]))
	game.state.items=game.state.items.duplicate(true);nav.refresh();assert(nav.target_key=="stable:3")
	game.state.items.remove_at(3);nav.refresh();assert(nav.target_key.is_empty())
	nav.show();nav.handle("map:filter:Companhia");assert(nav.destination_list.get_child_count()==2)
	var view:FarmMapView=nav.large
	var cat:Dictionary=nav.destinations().filter(func(e:Dictionary):return e.key=="cat")[0]
	var click:=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true;click.position=view.project(cat.at)
	view._gui_input(click);assert(nav.target_key=="cat")
	var point:=Vector2(100,-80);assert(view.unproject(view.project(point)).distance_to(point)<.001)
	var wheel:=InputEventMouseButton.new();wheel.button_index=MOUSE_BUTTON_WHEEL_UP;wheel.pressed=true;wheel.position=view.project(Vector2(4,0))
	view._gui_input(wheel);assert(view.zoom>1)
	assert(view.unproject(view.project(point)).distance_to(point)<.001)
	assert(FarmMapPlaces.direction(Vector2(0,-10))=="N ↑" and FarmMapPlaces.direction(Vector2(10,0))=="L →")
	nav.select(Vector2(4,10),"Aqui");assert(nav.status.text.begins_with("Chegou!"))
	game.state.items[0].flock.nest=0;game.state.items[0].flock.water=100;nav.refresh()
	assert(FarmMapPlaces.notices(game.state.items[0]).is_empty())
	# Restore the fixture and capture both map scales without changing a real save.
	game.state.items[0].flock.nest=6;game.state.items[0].flock.water=10
	nav.handle("map:filter:Todos");nav.handle("map:go:cat");view.zoom=3;view.focus=Vector2(30,0);game._update_ui()
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://test-results/map-places.png")
	assert(before.inventory==game.state.serialize().inventory)
	game.session_started=false;game.queue_free();await process_frame;await create_timer(.2).timeout
	print("MAP_PLACES_OK: moving destinations, snapshot replacement, removal, care notices, filters and zoom")
	quit()

