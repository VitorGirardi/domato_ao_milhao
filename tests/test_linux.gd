extends SceneTree
## Real Linux engine, isolated saves; graphical modes also exercise fullscreen.
var game:Node3D
func _initialize() -> void:call_deferred("run")
func settle() -> void:
	await create_timer(.25).timeout
func capture(label:String) -> void:
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/linux/"+DisplayServer.get_name()+"-"+label+".png")
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	game=load("res://scenes/main.tscn").instantiate();game.save_path="user://qa_linux.json"
	root.add_child(game);await process_frame
	game.set_process(false);game.set_physics_process(false)
	assert(game.hud.modal_kind=="title")
	await settle();await capture("title")
	game.session_started=true;game.hud.close_modal();game.build_mode=false
	game.state.farm_name="Fazenda do Ian — Linux";game.state.unlimited_money=true
	assert(game._save_game(false,true))
	var file:=FileAccess.open(game.save_path,FileAccess.READ)
	var restored:=FarmState.new();assert(restored.restore(JSON.parse_string(file.get_as_text())))
	assert(restored.farm_name==game.state.farm_name and restored.unlimited_money)
	game.horse.mount(game.player,game.avatar,game.actor)
	game.horse.pose_rider(game.avatar,game.actor);assert(game.horse.encourage())
	game.camera.position=game.horse.position+Vector3(5,3.4,5)
	game.camera.look_at(game.horse.position+Vector3(0,2,.2))
	await settle();await capture("mounted")
	if DisplayServer.get_name()!="headless":
		for cycle in range(3):
			if root.mode in [Window.MODE_FULLSCREEN,Window.MODE_EXCLUSIVE_FULLSCREEN]:game._toggle_fullscreen(false)
			await settle();assert(root.mode==Window.MODE_WINDOWED)
			game._toggle_fullscreen(false);await settle()
			assert(root.mode in [Window.MODE_FULLSCREEN,Window.MODE_EXCLUSIVE_FULLSCREEN])
			assert(root.size.x>0 and root.size.y>0)
			assert(game.horse.mounted)
		await capture("fullscreen")
	print("LINUX_QA_OK: os=",OS.get_name()," display=",DisplayServer.get_name()," renderer=",RenderingServer.get_current_rendering_method()," size=",root.size)
	game.session_started=false;game.queue_free();await process_frame;await create_timer(.2).timeout
	quit()
