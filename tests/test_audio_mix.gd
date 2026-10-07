extends SceneTree
var capture:=AudioEffectCapture.new()
var game:Node3D

func _initialize() -> void:call_deferred("run")

func level() -> float:
	capture.clear_buffer();await create_timer(.6).timeout
	var samples:=capture.get_buffer(capture.get_frames_available())
	print("MIX_CAPTURE_FRAMES ",samples.size())
	assert(samples.size()>1000)
	var energy:=0.0
	for sample in samples:energy+=sample.length_squared()*.5
	return sqrt(energy/samples.size())

func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	game=load("res://scenes/main.tscn").instantiate();game.save_path="user://qa_audio_mix.json";root.add_child(game)
	await process_frame;game._action("start");game.build_mode=false
	game.set_process(false);game.set_physics_process(false);game.audio.set_process(false)
	game.pickup.set_physics_process(false);game.weapons.set_physics_process(false)
	game.player.set_physics_process(false)
	var snapshot:Dictionary=game.state.serialize()
	var mix:=FarmSettings.DEFAULTS.duplicate();mix.music=0;mix.ambience=0;mix.effects=1
	FarmAudio.apply_mix(mix)
	game.audio.listener.make_current();game.audio.listener.global_position=game.pickup.global_position+Vector3(0,1.5,0)
	var index:=AudioServer.get_bus_effect_count(0);capture.buffer_length=2;AudioServer.add_bus_effect(0,capture)
	await create_timer(.3).timeout
	var motor:FarmEngineAudio=game.pickup.motor
	for i in range(90):motor.update(1.0/60,0,0,false,true)
	var idle:float=await level()
	assert(idle>.015 and idle<.3,"Recorded motor must be audible at the driver's seat without clipping")
	var idle_rpm:=motor.rpm
	for i in range(90):motor.update(1.0/60,12,1,false,true)
	assert(motor.rpm>idle_rpm+300 and motor.gear>1)
	var accelerating:float=await level();assert(accelerating>.015 and accelerating<.3)
	var gear:=motor.gear
	for i in range(30):motor.update(.016,10.1,1,false,true)
	assert(motor.gear==gear,"Speed boundary must not chatter between gears")
	motor.update(.016,0,0,false,false)
	assert(not motor.idle.playing and not motor.load_voice.playing)
	await create_timer(.1).timeout;assert(await level()<.000001,"Paused motor is silent")
	game.weapons._shot_sound();var shot:float=await level();assert(shot>.008 and shot<.4)
	await create_timer(1.7).timeout
	game.audio.world_effect("pistol_shot",game.audio.listener.global_position+Vector3(0,0,90),-5,1,100)
	var distant:float=await level();assert(distant<shot*.3,"Remote shot attenuates with distance")
	await create_timer(1.7).timeout
	mix.effects=0;FarmAudio.apply_mix(mix);game.weapons._shot_sound()
	assert(await level()<.000001,"Gunshot respects Effects mute")
	for group in ["step_","grass_","chicken"]:
		var previous:=-1
		for i in range(30):
			var value:int=game.audio.variant(group,3);assert(value!=previous);previous=value
	assert(game.state.serialize()==snapshot,"Sound cannot change saves or economy")
	AudioServer.remove_bus_effect(0,index);game.audio.stop_all();game.queue_free();await process_frame
	print("AUDIO_MIX_OK: audible recorded motor, acceleration/gears, pause silence, shot distance/mute, variants, unchanged state; RMS ",idle," / ",accelerating," / ",shot," / ",distant)
	quit()
