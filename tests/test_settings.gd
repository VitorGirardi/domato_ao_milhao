extends SceneTree
func _initialize() -> void:
	var good:=FarmSettings.normalized({"volume":9,"sensitivity":-1,"quality":2,"fps":120,"fullscreen":false,"music":0,"ambience":99,"effects":-.4})
	assert(good.music==0 and good.ambience==1 and good.effects==0)
	assert(good.volume==1 and good.sensitivity==.25 and good.quality==2 and not good.fullscreen and good.fps==120)
	var bad:=FarmSettings.normalized({"volume":NAN,"sensitivity":"bad","quality":99,"fps":-1,"fullscreen":"false","music":INF,"effects":"loud","ambience":false})
	assert(bad==FarmSettings.DEFAULTS)
	var settings:=FarmSettings.new();settings.path="res://test-results/qa_settings.cfg";settings.data=good
	assert(settings.save_preferences()==OK)
	var restored:=FarmSettings.new();restored.path=settings.path;restored.load_preferences();assert(restored.data==good)
	DirAccess.remove_absolute(settings.path)
	print("SETTINGS_STATE_OK: clamp, malformed values, default recovery, config persistence")
	quit()
