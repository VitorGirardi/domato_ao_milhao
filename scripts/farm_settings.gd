class_name FarmSettings
extends RefCounted
const DEFAULTS:={"volume":0.8,"music":.65,"ambience":.8,"effects":.85,"sensitivity":1.0,"fullscreen":true,"quality":1,"fps":60}
var data:Dictionary=DEFAULTS.duplicate()
var path:="user://settings.cfg"

static func normalized(value:Dictionary) -> Dictionary:
	var result:=DEFAULTS.duplicate()
	for key in ["volume","music","ambience","effects","sensitivity"]:
		var n:Variant=value.get(key)
		if (n is int or n is float) and is_finite(float(n)):
			result[key]=clampf(n,.25 if key=="sensitivity" else 0,2.5 if key=="sensitivity" else 1)
	if value.get("fullscreen") is bool:result.fullscreen=value.fullscreen
	if value.get("quality") in [0,1,2]:result.quality=int(value.quality)
	if value.get("fps") in [0,30,60,120]:result.fps=int(value.fps)
	return result

func load_preferences() -> void:
	var file:=ConfigFile.new()
	if file.load(path)!=OK:return
	var value:Dictionary={}
	for key in DEFAULTS:value[key]=file.get_value("game",key,DEFAULTS[key])
	data=normalized(value)

func save_preferences() -> Error:
	var file:=ConfigFile.new()
	for key in data:file.set_value("game",key,data[key])
	return file.save(path)

func apply(game:Node3D,window:bool=true) -> void:
	FarmAudio.apply_mix(data)
	AudioServer.set_bus_mute(0,data.volume<=0)
	AudioServer.set_bus_volume_db(0,linear_to_db(maxf(.001,data.volume)))
	Engine.max_fps=int(data.fps)
	game.get_viewport().msaa_3d=[Viewport.MSAA_DISABLED,Viewport.MSAA_4X,Viewport.MSAA_8X][int(data.quality)]
	for node in game.world.get_children():
		if node is DirectionalLight3D:node.shadow_enabled=data.quality>0
	if window and DisplayServer.get_name()!="headless":
		var currently_full:=game.get_window().mode in [Window.MODE_FULLSCREEN,Window.MODE_EXCLUSIVE_FULLSCREEN]
		if currently_full!=data.fullscreen:game._toggle_fullscreen(false)
