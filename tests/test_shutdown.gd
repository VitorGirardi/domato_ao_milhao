extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	var game:Node3D=load("res://scenes/main.tscn").instantiate()
	game.save_path="user://qa_shutdown.json";root.add_child(game)
	await process_frame
	game._action("start");game.state.farm_name="Fazenda do som"
	game._action("quit")
	assert(game.quitting and not game.session_started and game.audio.shutting_down)
	assert(not game.audio.music.playing and not game.audio.wind.playing and not game.audio.river.playing)
	assert(JSON.parse_string(FileAccess.get_file_as_string(game.save_path)).farm_name=="Fazenda do som")
	var emitted:int=game.audio.emitted_events;game.audio.play_effect("harvest")
	assert(game.audio.emitted_events==emitted)
	print("SHUTDOWN_QA_OK: saved farm, stopped loops and blocked new effects before engine exit")
	# _request_quit exits after the audio mixer has drained.
