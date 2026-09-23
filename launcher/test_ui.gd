extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: Control = load("res://main.tscn").instantiate()
	root.add_child(scene)
	var deadline := Time.get_ticks_msec() + 90000
	while scene.busy and Time.get_ticks_msec() < deadline:
		await process_frame
	assert(not scene.busy, "Launcher did not finish checking")
	assert(scene.latest.begins_with("v"), "Public release query failed")
	assert(not scene.update_button.disabled)
	assert(scene.play_button.disabled == scene.current.is_empty())
	assert(scene.update_button.get_global_rect().end.x <= root.size.x)
	assert(scene.status.get_global_rect().end.y <= root.size.y)
	# Exercise the actual button: updating must finish in the launcher, not launch.
	scene.update_button.pressed.emit()
	deadline = Time.get_ticks_msec() + 90000
	while scene.busy and Time.get_ticks_msec() < deadline:
		await process_frame
	assert(not scene.busy and not scene.playing, "Updating launched or blocked on the game")
	assert(scene.operation == "update" and scene.result.get("OK", false))
	assert(scene.update_button.text == "ATUALIZAR")
	assert(not scene.play_button.disabled)
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("LAUNCHER_SCREENSHOT"))
	print("LAUNCHER_UI_OK")
	quit()
