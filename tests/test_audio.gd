extends SceneTree
## Run with isolated APPDATA, --headless and --audio-driver Dummy.
func _initialize() -> void:call_deferred("run")

func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	var game:Node3D=load("res://scenes/main.tscn").instantiate()
	game.save_path="user://qa_audio.json";root.add_child(game)
	await process_frame
	var audio:FarmAudio=game.get("audio")
	if audio==null:audio=FarmAudio.new();game.add_child(audio);audio.setup(game)
	assert(audio.clips.size()==24 and audio.effects.size()==4 and audio.animals.size()==4)
	var count:=AudioServer.bus_count
	FarmAudio.ensure_buses();FarmAudio.ensure_buses();assert(AudioServer.bus_count==count)
	assert(audio.music.bus=="Music" and audio.wind.bus=="Ambience" and audio.effects[0].bus=="Effects")
	assert(is_equal_approx(audio.clips.manha_no_vale.get_length(),96.0))
	for key in audio.clips:
		var clip:AudioStreamWAV=audio.clips[key]
		assert(clip.get_length()>0 and clip.mix_rate==32000)
		if key in ["manha_no_vale","wind","river"]:
			assert(clip.loop_mode==AudioStreamWAV.LOOP_FORWARD and clip.loop_end>0)
	var mix:=FarmSettings.DEFAULTS.duplicate();mix.music=0;mix.ambience=.3;mix.effects=.9
	FarmAudio.apply_mix(mix)
	assert(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")))
	assert(not AudioServer.is_bus_mute(AudioServer.get_bus_index("Effects")))
	assert(is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Ambience")),linear_to_db(.3)))
	FarmAudio.apply_mix(FarmSettings.DEFAULTS)
	audio.set_process(false);game._action("start");game.build_mode=false;game.player.position=Vector3(4,.3,10)
	for i in range(40):await physics_frame
	assert(game.player.is_on_floor())
	game.set_physics_process(false);game.set_process(false)
	audio.last_position=game.player.position;audio.distance_walked=0
	var baseline:=audio.step_count
	for i in range(5):game.player.position.x+=.6;audio._process(.016)
	assert(audio.step_count>=baseline+1,"Walking distance produces footsteps")
	baseline=audio.step_count
	for i in range(30):audio._process(.016)
	assert(audio.step_count==baseline,"Standing still produces no steps")
	game.hud.menu(game.state);game.player.position.x+=3;audio._process(1)
	assert(audio.step_count==baseline and audio.distance_walked==0,"Menus stop footsteps")
	game.hud.close_modal();game.player.position=Vector3(-33,0,5)
	for i in range(10):audio._process(.1)
	var near:float=audio.river.volume_db
	game.player.position.x=130
	for i in range(20):audio._process(.1)
	assert(audio.river.volume_db<near-15,"River falls off with distance")
	for i in range(30):audio.play_effect("harvest")
	assert(audio.effects.size()==4,"Repeated actions do not create unbounded voices")
	var snapshot:Dictionary=game.state.serialize()
	audio._nearby_call(game.horse.position);assert(audio.animals[0].stream!=null)
	assert(game.state.serialize()==snapshot,"Audio never mutates the farm")
	game.session_started=false;game.queue_free();await process_frame
	print("AUDIO_QA_OK: 24 clips, exact musical loop, buses/mutes, bounded voices, footsteps, idle/menu silence, river distance and unchanged state")
	quit()
