extends SceneTree
var capture:=AudioEffectCapture.new()

func _initialize() -> void:call_deferred("run")

func level() -> float:
	await create_timer(.7).timeout
	var samples:=capture.get_buffer(capture.get_frames_available())
	assert(samples.size()>1000,"Audio mixer produced no samples")
	var energy:=0.0
	for sample in samples:energy+=sample.length_squared()*.5
	return sqrt(energy/samples.size())

func run() -> void:
	FarmAudio.ensure_buses()
	var stage:=Node3D.new();root.add_child(stage)
	var camera:=Camera3D.new();stage.add_child(camera);camera.current=true
	root.audio_listener_enable_3d=true
	var listener:=AudioListener3D.new();stage.add_child(listener);listener.position=Vector3(0,0,6);listener.make_current()
	var motor:=FarmEngineAudio.new();stage.add_child(motor);motor.setup(stage)
	var mix:Dictionary=FarmSettings.DEFAULTS.duplicate();mix.music=0;mix.ambience=0;mix.effects=1;FarmAudio.apply_mix(mix)
	var effect_index:=AudioServer.get_bus_effect_count(0);capture.buffer_length=2;AudioServer.add_bus_effect(0,capture)
	await create_timer(.15).timeout
	assert(not motor.impact(10,Vector3.ZERO),"Stopped vehicle must not emit impacts")
	motor.update(.1,10,1,false,true);motor.idle.stop();motor.load_voice.stop()
	assert(not motor.impact(1.9,Vector3.ZERO))
	assert(not motor.impact(NAN,Vector3.ZERO) and not motor.impact(10,Vector3.INF))
	capture.clear_buffer();assert(motor.impact(3,Vector3.ZERO))
	assert(not motor.impact(20,Vector3.ZERO),"Wall contact spam restarted impact")
	var soft:float=await level()
	motor.update(.7,0,0,false,true);motor.idle.stop();motor.load_voice.stop()
	capture.clear_buffer();assert(motor.impact(18,Vector3.ZERO))
	var hard:float=await level()
	assert(soft>.0005 and hard>soft*1.8 and hard<.25,"Impact intensity must be audible, proportional and bounded: %f / %f"%[soft,hard])
	# Muting Effects must silence the same 3D voice, not bypass the bus.
	motor.update(.7,0,0,false,true);motor.idle.stop();motor.load_voice.stop()
	mix.effects=0;FarmAudio.apply_mix(mix)
	capture.clear_buffer();assert(motor.impact(18,Vector3.ZERO));assert(await level()<.000001)
	motor.update(.7,0,0,false,true);motor.idle.stop();motor.load_voice.stop()
	mix.effects=1;FarmAudio.apply_mix(mix)
	assert(motor.impact(18,Vector3.ZERO));motor.update(.016,0,0,false,false)
	assert(not motor.impact_voice.playing and not motor.active)
	await create_timer(.1).timeout;capture.clear_buffer();assert(await level()<.000001)
	assert(motor.impact_count==4)
	AudioServer.remove_bus_effect(0,effect_index);capture=null
	motor.stop();stage.queue_free();await process_frame;await create_timer(.1).timeout
	print("PICKUP_IMPACT_AUDIO_OK: original signal, intensity, threshold, cooldown, Effects mute, pause/reset; RMS ",soft," / ",hard)
	quit()
