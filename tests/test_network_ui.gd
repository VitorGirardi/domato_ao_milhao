extends SceneTree
var game:Node3D
func _initialize() -> void:call_deferred("run")
func capture(path:String) -> void:
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/"+path+".png")
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	game=load("res://scenes/main.tscn").instantiate();game.save_path="user://ui_qa.json";root.add_child(game);await process_frame
	game.qa_mode=true
	game.preferences.data.fullscreen=false;game.preferences.apply(game)
	game._action("net:menu");assert(game.hud.modal_kind=="network")
	await capture("network-menu")
	game._action("close");assert(game.hud.modal_kind=="title")
	game._action("net:menu");game.network.name_input.text="Vitor";game._action("net:host")
	assert(game.network.active and game.hud.modal_kind=="network_session")
	await capture("network-host")
	game._action("close");game._pause_for_focus_loss();assert(game.hud.modal_kind=="network_session")
	game._action("net:leave");assert(not game.network.active)
	game._action("net:back");assert(game.hud.modal_kind=="title")
	await capture("network-title")
	game.audio.stop_all();await create_timer(.2).timeout;game.queue_free();await process_frame;await create_timer(.2).timeout
	print("NETWORK_UI_OK: menu, close, host, focus loss, leave, return title")
	quit()
