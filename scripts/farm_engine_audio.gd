class_name FarmEngineAudio
extends Node
## Two recorded engine layers. Audio gears do not change vehicle physics.
var idle:=AudioStreamPlayer3D.new()
var load_voice:=AudioStreamPlayer3D.new()
var rpm:=850.0
var gear:=1
var shift_left:=0.0
var gain:=0.0

func setup(truck:Node3D) -> void:
	for entry in [[idle,"engine_idle"],[load_voice,"engine_load"]]:
		var voice:AudioStreamPlayer3D=entry[0]
		voice.stream=FarmAudio.loop_clip(entry[1]);voice.bus=FarmAudio.EFFECTS_BUS
		voice.unit_size=6;voice.max_distance=42;voice.max_db=0;voice.volume_db=-60
		truck.add_child(voice);voice.position=Vector3(0,1.1,1.3)

func stop() -> void:
	idle.stop();load_voice.stop();gain=0;rpm=850;gear=1;shift_left=0

func update(delta:float,speed:float,throttle:float,airborne:bool,active:bool) -> void:
	if not active:stop();return
	if not idle.playing:idle.play();load_voice.play()
	var velocity:=absf(speed)
	# Hysteresis prevents repeated shifts near a speed boundary.
	var thresholds:=[0.0,5.0,10.0,16.0]
	var next:=gear
	if gear<4 and velocity>thresholds[gear]+.65:next+=1
	elif gear>1 and velocity<thresholds[gear-1]-.85:next-=1
	if next!=gear:gear=next;shift_left=.24
	shift_left=maxf(0,shift_left-delta)
	var start:float=thresholds[gear-1]
	var ratio:=clampf((velocity-start)/6.0,0,1)
	var demand:=clampf(absf(throttle),0,1)
	var target:float=850+ratio*1350+demand*420+(500*demand if airborne else 0)
	if shift_left>0:target*=.82
	rpm=lerpf(rpm,target,1-exp(-delta*7))
	gain=move_toward(gain,1,delta*3)
	var load_amount:=clampf(demand*.65+ratio*.3,0,1)
	idle.pitch_scale=clampf(rpm/1200,.72,1.7)
	load_voice.pitch_scale=clampf(rpm/1850,.72,1.48)
	idle.volume_db=-7+linear_to_db(maxf(.001,gain*(1-load_amount*.62)))
	load_voice.volume_db=-8+linear_to_db(maxf(.001,gain*(.10+load_amount*.9)))
