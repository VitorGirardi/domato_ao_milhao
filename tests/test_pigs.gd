extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	var state:=FarmState.new();state.unlimited_money=true;state.farm_xp=120
	assert(state.claim(Vector2(4,0)).is_empty())
	var legacy:=state.serialize();legacy.version=17
	var old:=FarmState.new();assert(old.restore(legacy))
	assert(state.place("pigsty",Vector2(4,0),0).is_empty())
	assert(FarmPigs.care(state,0,"food")!="")
	state.unlimited_money=false;state.money=239
	assert(FarmPigs.care(state,0,"buy")!="" and state.items[0].pigs.count==0)
	state.money=1000
	for i in range(3):assert(FarmPigs.care(state,0,"buy").is_empty())
	assert(state.money==280 and state.items[0].pigs.count==3)
	var before:=state.serialize();assert(FarmPigs.care(state,0,"buy")!="" and state.serialize()==before)
	assert(not state.remove_item(0).is_empty())
	assert(state.move_item(0,Vector2(6,0),1).is_empty() and state.items[0].pigs.count==3)
	var large:Dictionary=state.items[0].pigs.duplicate();var small:=large.duplicate()
	FarmPigs.tick(large,77)
	for i in range(770):FarmPigs.tick(small,.1)
	assert(is_equal_approx(large.food,small.food) and is_equal_approx(large.water,small.water))
	state.tick(77);assert(is_equal_approx(state.items[0].pigs.food,large.food))
	assert(FarmCoopCommands.run(state,{"action":"pigs:water","index":0}).is_empty())
	assert(FarmCoopCommands.run(state,{"action":"pigs:buy_bad","index":0})!="")
	assert(FarmCoopCommands.run(state,{"action":"pigs:food","index":-1})!="")
	var saved:=state.serialize();var copy:=FarmState.new();assert(copy.restore(JSON.parse_string(JSON.stringify(saved))))
	for invalid in [{"count":4,"food":100,"water":100},{"count":true,"food":100,"water":100},{"count":1.5,"food":100,"water":100},{"count":1,"food":NAN,"water":100},{"count":1,"food":100,"water":-1}]:
		assert(not FarmPigs.valid(invalid));var bad:=saved.duplicate(true);bad.items[0].pigs=invalid;assert(not copy.restore(bad))
	var bad_legacy:=saved.duplicate(true);bad_legacy.version=17;assert(not copy.restore(bad_legacy))
	state.unlimited_money=true;assert(FarmPigs.care(state,0,"food").is_empty() and state.unlimited_money)
	assert(FarmCoop.save_farm("user://pigs_roundtrip.json",state))
	var restored:=FarmCoop.load_farm("user://pigs_roundtrip.json");assert(restored.items[0].pigs.count==3 and restored.unlimited_money)
	var game:Node3D=load("res://scenes/main.tscn").instantiate();game.save_path="user://pigs_game.json";root.add_child(game)
	await process_frame;game.set_process(false);game.set_physics_process(false);game.audio.set_process(false)
	game.state=restored;game.world.rebuild(restored);game.hud.close_modal();game.selected=0;game.session_started=true
	game._tend_selected();assert(game.hud.modal_kind=="pigsty")
	game.hud.construction._choose_category("Animais")
	assert(game.hud.construction.cards.has("pigsty"))
	game.selected=0;game._action("tool:pigsty");assert(game.tool=="pigsty")
	game._action("pigsty");assert(game.hud.modal_kind=="pigsty")
	assert(game.world.pigsties.size()==1 and game.world.pigsties[0].pigs.size()==3)
	for i in range(180):game.world.animate(1.0/60,Vector3(99,0,99),game.state)
	var pose:=FarmCoopVisuals.capture(game.world)
	for slot in range(3):assert(pose.has("pig_0_%d"%slot))
	FarmCoopVisuals.apply(game.world,pose,1.0)
	if DisplayServer.get_name()!="headless":
		DirAccess.make_dir_recursive_absolute("res://test-results/pigs-game")
		for size in [Vector2i(1280,720),Vector2i(1920,1080)]:
			root.mode=Window.MODE_WINDOWED;root.size=size;await create_timer(.15).timeout
			assert(game.hud.modal_kind=="pigsty")
			await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://test-results/pigs-game/panel-%d.png"%size.x)
		game.hud.close_modal();game._update_ui()
		await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://test-results/pigs-game/catalog.png")
		game.hud.hide();game.camera.position=Vector3(14,7,9);game.camera.look_at(Vector3(6,.8,0))
		await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://test-results/pigs-game/farm.png")
	game.session_started=false;game.queue_free();await process_frame;await create_timer(.2).timeout
	print("PIGS_GAME_OK: purchase limits, care, economy, step independence, legacy/save validation, occupied move, UI and replicated poses")
	quit()
