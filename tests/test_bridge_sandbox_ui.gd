extends SceneTree
var game:Node3D

func _initialize() -> void:call_deferred("run")

func capture(label:String) -> void:
	if DisplayServer.get_name()=="headless":return
	await create_timer(.2).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/sandbox-"+label+".png")

func infinity_count(node:Node) -> int:
	var count:=1 if node is Label and "∞" in node.text else 0
	for child in node.get_children():count+=infinity_count(child)
	return count

func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	game=load("res://scenes/main.tscn").instantiate();game.save_path="user://qa_bridge_sandbox.json"
	root.add_child(game);await process_frame
	game.set_process(false);game.set_physics_process(false)
	root.mode=Window.MODE_WINDOWED;root.size=Vector2i(1440,900)
	game.state=FarmState.new_farm("sandbox");game.state.claim(Vector2(4,-2))
	game.session_started=true;game.build_mode=false;game.hud.close_modal()
	game.world.rebuild(game.state);game.world.build_grid.visible=false;game.ghost.visible=false
	game.world.day_night.update_cycle(80,Vector3(420,5,0))
	game.hud.root.visible=false
	game.avatar.visible=false
	for x in [396.0,400.0,444.0]:
		game.player.position=Vector3(x,5,1)
		game.camera.position=Vector3(x,7.2,1);game.camera.look_at(Vector3(420,5,0));game.camera.fov=65
		await capture("bridge-"+str(int(x)))
	game.hud.root.visible=true
	game._update_ui()
	FarmResourceHUD.show(game);assert(infinity_count(game.hud.root)>=6);await capture("ores")
	game.hud.close_modal();FarmDairyHUD.stock(game.hud,game.state)
	assert(infinity_count(game.hud.root)>0);await capture("milk")
	game.hud.close_modal();FarmCheeseHUD.stock(game.hud,game.state)
	assert(infinity_count(game.hud.root)>0);await capture("cheese")
	game.hud.close_modal();game._action("market")
	assert(infinity_count(game.hud.root)>=4);await capture("market")
	# The host's transaction path must accept products with no physical stock.
	assert(FarmCoopCommands.run(game.state,{"action":"sell_product:egg","quantity":50}).is_empty())
	assert(FarmCoopCommands.run(game.state,{"action":"sell_milk","quantity":50}).is_empty())
	assert(FarmCoopCommands.run(game.state,{"action":"cheese:sell","quantity":50}).is_empty())
	assert(game.state.inventory.egg==0 and game.state.milk_stock==0 and game.state.cheese_stock==0)
	game.state=FarmState.new_farm("survival");game.state.claim(Vector2(4,-2))
	game.hud.close_modal();game._update_ui();FarmResourceHUD.show(game)
	await process_frame
	assert(infinity_count(game.hud.root)==0)
	print("BRIDGE_SANDBOX_UI_OK: bridge views, infinite resource labels, host transactions and survival UI")
	game.session_started=false;game.audio.set_process(false);game.audio.stop_all()
	await create_timer(.2).timeout;game.queue_free();await process_frame;await create_timer(.2).timeout;quit()
