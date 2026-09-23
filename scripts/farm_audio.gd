class_name FarmAudio
extends Node
signal animal_called(kind:String)
## Bounded voices and distance-driven ambience; no production or save mutations.
const MUSIC_BUS:="Music"
const AMBIENCE_BUS:="Ambience"
const EFFECTS_BUS:="Effects"
const NAMES:=["manha_no_vale","wind","river","water","plant","harvest","build","ui_tick","ui_confirm","ui_back","bird_0","bird_1","bird_2","chicken","cow","horse_snort","horse_neigh","horse_sprint","step_0","step_1","step_2","step_3","hoof_0","hoof_1","hoof_2","hoof_3"]
var shutting_down:=false
var game:Node3D
var clips:Dictionary={}
var music:=AudioStreamPlayer.new()
var wind:=AudioStreamPlayer.new()
var river:=AudioStreamPlayer.new()
var effects:Array[AudioStreamPlayer]=[]
var animals:Array[AudioStreamPlayer3D]=[]
var listener:=AudioListener3D.new()
var rng:=RandomNumberGenerator.new()
var distance_walked:=0.0
var last_position:=Vector3.ZERO
var previous_grounded:=true
var previous_mounted:=false
var event_wait:=1.0
var call_timers:={"horse":2.0,"chicken":1.5,"cow":3.5,"bird":4.0}
var call_cursor:=0
var horse_voice:AudioStreamPlayer3D
var ui_cooldown:=0.0
var step_count:=0
var emitted_events:=0
var effect_cursor:=0
var animal_cursor:=0

static func ensure_buses() -> void:
	var limited:=false
	for i in range(AudioServer.get_bus_effect_count(0)):
		if AudioServer.get_bus_effect(0,i) is AudioEffectHardLimiter:limited=true
	if not limited:
		var limiter:=AudioEffectHardLimiter.new();limiter.ceiling_db=-1;limiter.release=.1
		AudioServer.add_bus_effect(0,limiter)
	for bus in [MUSIC_BUS,AMBIENCE_BUS,EFFECTS_BUS]:
		if AudioServer.get_bus_index(bus)>=0:continue
		AudioServer.add_bus();var index:=AudioServer.bus_count-1
		AudioServer.set_bus_name(index,bus);AudioServer.set_bus_send(index,"Master")

static func apply_mix(data:Dictionary) -> void:
	ensure_buses()
	for entry in [[MUSIC_BUS,"music"],[AMBIENCE_BUS,"ambience"],[EFFECTS_BUS,"effects"]]:
		var index:=AudioServer.get_bus_index(entry[0]);var value:float=data.get(entry[1],.7)
		AudioServer.set_bus_mute(index,value<=0)
		AudioServer.set_bus_volume_db(index,linear_to_db(maxf(.001,value)))

func setup(owner_game:Node3D) -> void:
	game=owner_game;rng.randomize();ensure_buses()
	for key in NAMES:
		var clip:AudioStreamWAV=load("res://assets/audio/%s.wav"%key)
		if key in ["manha_no_vale","wind","river"]:
			clip=clip.duplicate();clip.loop_mode=AudioStreamWAV.LOOP_FORWARD
			clip.loop_begin=0;clip.loop_end=roundi(clip.get_length()*clip.mix_rate)
		clips[key]=clip
	for entry in [[music,"manha_no_vale",MUSIC_BUS,-7.0],[wind,"wind",AMBIENCE_BUS,-24.0],[river,"river",AMBIENCE_BUS,-70.0]]:
		var voice:AudioStreamPlayer=entry[0];add_child(voice);voice.stream=clips[entry[1]];voice.bus=entry[2];voice.volume_db=entry[3];voice.play()
	for i in range(4):
		var voice:=AudioStreamPlayer.new();voice.bus=EFFECTS_BUS;add_child(voice);effects.append(voice)
	for i in range(4):
		var voice:=AudioStreamPlayer3D.new();voice.bus=AMBIENCE_BUS;voice.unit_size=6;voice.max_distance=32
		game.add_child(voice);animals.append(voice)
	horse_voice=AudioStreamPlayer3D.new();horse_voice.bus=AMBIENCE_BUS;horse_voice.unit_size=6;horse_voice.max_distance=32
	game.horse.add_child(horse_voice);horse_voice.position=Vector3(0,2,1.1)
	if game.horse.has_signal("encouraged"):game.horse.connect("encouraged",_horse_sprint)
	game.player.add_child(listener);listener.position=Vector3(0,1.5,0)
	last_position=game.player.position
	game.hud.action.connect(ui_action)

func play_effect(key:String,gain:float=-13.0,pitch:float=1.0) -> void:
	if shutting_down or not clips.has(key) or effects.is_empty():return
	var voice:=effects[effect_cursor%effects.size()];effect_cursor+=1
	voice.stop();voice.stream=clips[key];voice.volume_db=gain;voice.pitch_scale=pitch;voice.play()
	emitted_events+=1

func ui_action(value:String) -> void:
	if ui_cooldown>0:return
	ui_cooldown=.075
	var key:="ui_back" if value in ["close","front:back","front:cancel_new"] else "ui_tick"
	if value in ["front:apply","front:continue","start"]:key="ui_confirm"
	play_effect(key,-18)

func spatial(key:String,at:Vector3) -> void:
	if shutting_down or animals.is_empty():return
	var voice:=animals[animal_cursor%animals.size()];animal_cursor+=1
	voice.stop();voice.stream=clips[key];voice.global_position=at;voice.volume_db=-8
	voice.pitch_scale=rng.randf_range(.95,1.05);voice.play();emitted_events+=1;animal_called.emit(key)

func _process(delta:float) -> void:
	if not is_instance_valid(game) or not is_instance_valid(game.hud):return
	ui_cooldown=maxf(0,ui_cooldown-delta)
	var active:bool=game.session_started and game.hud.modal_kind.is_empty() and not game.build_mode
	var focused:bool=DisplayServer.get_name()=="headless" or (game.get_window().has_focus() and game.get_window().mode!=Window.MODE_MINIMIZED)
	# Smooth changes keep settings, pause and build mode from producing abrupt jumps.
	var music_target:float=-7 if not game.session_started else (-11 if active else -17)
	if not focused:music_target=-60
	music.volume_db=move_toward(music.volume_db,music_target,delta*14)
	wind.volume_db=move_toward(wind.volume_db,-24.0 if active and focused else -60.0,delta*18)
	var pos:Vector3=game.player.global_position
	var river_x:float=-42+sin(pos.z*.065)*2.6
	var strength:float=clampf(1-absf(pos.x-river_x)/26,0,1) if active and focused else 0
	river.volume_db=move_toward(river.volume_db,-13+linear_to_db(maxf(.003,strength)),delta*25)
	if active:
		listener.make_current();listener.global_basis=game.camera.global_basis
	var travel:float=Vector2(pos.x-last_position.x,pos.z-last_position.z).length()
	last_position=pos
	if not active or not focused:
		distance_walked=0;previous_grounded=game.player.is_on_floor();previous_mounted=game._mounted()
		for voice in animals:voice.stop()
		horse_voice.stop()
		return
	var grounded:bool=game.player.is_on_floor()
	var mounted:bool=game._mounted()
	if mounted and not previous_mounted:_horse_call("horse_neigh")
	if previous_mounted!=mounted or travel>=2:distance_walked=0
	if travel<2 and (grounded or mounted):
		distance_walked+=travel
		var stride:float=1.45 if not mounted else (2.15 if game.horse.burst>0 else 1.75)
		if distance_walked>=stride:
			distance_walked=fmod(distance_walked,stride);step_count+=1
			play_effect(("hoof_" if mounted else "step_")+str(step_count%4),-17 if mounted else -22,rng.randf_range(.94,1.06))
	if grounded and not previous_grounded and not mounted:play_effect("step_2",-17,.88)
	previous_grounded=grounded;previous_mounted=mounted
	for kind in call_timers:call_timers[kind]=maxf(0,call_timers[kind]-delta)
	event_wait-=delta
	if event_wait<=0:event_wait=1.3 if _nearby_call(pos) else .5

func _horse_call(key:String) -> void:
	if shutting_down:return
	horse_voice.stop();horse_voice.stream=clips[key];horse_voice.volume_db=-10
	horse_voice.pitch_scale=1.0;horse_voice.play()
	call_timers.horse=rng.randf_range(16,24);emitted_events+=1;animal_called.emit(key)

func _horse_sprint() -> void:
	previous_mounted=true
	_horse_call("horse_sprint")
	play_effect("step_0",-17,1.15) # The soft hand pat; no whip.

func _nearby_call(pos:Vector3) -> bool:
	var nearest:Dictionary={}
	for bird in game.world.landscape.birds:
		if is_instance_valid(bird.node):_candidate(nearest,"bird",bird.node.global_position,pos,28)
	for chicken in game.world.chickens:
		if is_instance_valid(chicken.node):_candidate(nearest,"chicken",chicken.node.global_position,pos,22)
	for cow in game.world.cows:
		if is_instance_valid(cow.node) and cow.node.visible:_candidate(nearest,"cow",cow.node.global_position+Vector3.UP,pos,26)
	if not game.horse.mounted:_candidate(nearest,"horse",game.horse.global_position+Vector3.UP*2,pos,22)
	# Each species has its own timer: many birds can never silence a cow or hen.
	for offset in range(4):
		var index:=(call_cursor+offset)%4
		var kind:String=["horse","chicken","cow","bird"][index]
		if call_timers[kind]>0 or not nearest.has(kind):continue
		call_cursor=(index+1)%4
		call_timers[kind]=rng.randf_range(10,17) if kind in ["chicken","bird"] else rng.randf_range(16,24)
		if kind=="horse":_horse_call("horse_neigh" if rng.randf()<.6 else "horse_snort")
		else:spatial("bird_"+str(rng.randi_range(0,2)) if kind=="bird" else kind,nearest[kind].at)
		return true
	return false

func _candidate(nearest:Dictionary,kind:String,at:Vector3,pos:Vector3,radius:float) -> void:
	var distance:=at.distance_to(pos)
	if distance<radius and (not nearest.has(kind) or distance<nearest[kind].distance):nearest[kind]={"at":at,"distance":distance}

func stop_all() -> void:
	shutting_down=true;set_process(false)
	music.stop();wind.stop();river.stop()
	if is_instance_valid(horse_voice):horse_voice.stop()
	for voice in effects:voice.stop()
	for voice in animals:voice.stop()
