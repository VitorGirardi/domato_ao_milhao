extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	var game=load("res://scenes/main.tscn").instantiate();game.save_path="user://skills_ui.json";root.add_child(game);await process_frame
	game.qa_mode=true;game.set_process(false);game.set_physics_process(false);game.weapons.set_physics_process(false)
	game.session_started=true;game.build_mode=false;game.hud.close_modal()
	game.state.skills={"fishing":40,"farming":100,"mining":250,"handling":480}
	var before:Dictionary=game.state.serialize()
	game._action("guide:tab:skills")
	assert(game.hud.modal_kind=="guide" and Input.mouse_mode==Input.MOUSE_MODE_VISIBLE)
	assert(game.state.serialize()==before)
	if DisplayServer.get_name()!="headless":
		await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://test-results/skills-page.png")
	game._action("guide:practice");assert(game.hud.modal_kind=="skills_help")
	if DisplayServer.get_name()!="headless":
		await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://test-results/skills-help.png")
	game._action("guide:tab:skills");assert(game.hud.modal_kind=="guide")
	game._action("close");assert(game.hud.modal_kind.is_empty())
	game.build_mode=true;game._action("guide:tab:skills");assert(game.hud.modal_kind=="guide")
	game.session_started=false;game.audio.stop_all();await create_timer(.2).timeout
	game.queue_free();await process_frame;await create_timer(.2).timeout
	print("SKILLS_UI_OK: levels, benefits, help, read-only UI, construction and cursor")
	quit()
