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
	assert(scene.update_button.disabled == not (scene.update_available or scene.needs_repair))
	assert(scene.play_button.disabled == not scene.can_play)
	assert(scene.update_button.get_global_rect().end.x <= root.size.x)
	assert(scene.status.get_global_rect().end.y <= root.size.y)
	# Exercise the actual button: updating must finish in the launcher, not launch.
	if not scene.update_button.disabled:scene.update_button.pressed.emit()
	deadline = Time.get_ticks_msec() + 90000
	while scene.busy and Time.get_ticks_msec() < deadline:
		await process_frame
	assert(not scene.busy and not scene.playing, "Updating launched or blocked on the game")
	assert(scene.result.get("OK", false))
	assert(scene.update_button.text == "ATUALIZADO" and scene.update_button.disabled)
	assert(not scene.play_button.disabled)
	# Equal version and stale/offline results must not enable Update.
	var operation:String=scene.operation
	scene._start("update");assert(not scene.busy and scene.operation==operation)
	scene.checked=false;scene._refresh();assert(scene.update_button.disabled and not scene.play_button.disabled)
	scene.checked=true;scene.update_available=true;scene._refresh();assert(not scene.update_button.disabled)
	scene.busy=true;scene._refresh();assert(scene.play_button.disabled and scene.update_button.disabled)
	scene.busy=false;scene.update_available=false;scene._refresh()
	assert(scene.play_button.text.contains(scene.current))
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("LAUNCHER_SCREENSHOT"))
	print("LAUNCHER_UI_OK")
	quit()
