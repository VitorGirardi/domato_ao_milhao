class_name FarmSaves
extends RefCounted
## Each farm owns its JSON and backup. The original save stays at its old path.
var legacy_path := "user://farm_v1.json"

func directory() -> String:
	return legacy_path.get_base_dir().path_join("farms")

func read_farm(path:String) -> FarmState:
	for candidate in [path,path+".bak"]:
		if not FileAccess.file_exists(candidate):continue
		var parser:=JSON.new()
		var farm:=FarmState.new()
		if parser.parse(FileAccess.get_file_as_string(candidate))==OK and farm.restore(parser.data):
			# Legacy farms retain the author's unlimited wallet without losing progress.
			if farm.game_mode=="legacy":farm.unlimited_money=true
			return farm
	return null

func paths() -> Array[String]:
	var result:Array[String]=[]
	if FileAccess.file_exists(legacy_path) or FileAccess.file_exists(legacy_path+".bak"):result.append(legacy_path)
	var files:=DirAccess.get_files_at(directory()) if DirAccess.dir_exists_absolute(directory()) else PackedStringArray()
	for file in files:
		var primary:=file.trim_suffix(".bak")
		if not primary.ends_with(".json") or primary.ends_with("_coop.json"):continue
		var path:=directory().path_join(primary)
		if path not in result:result.append(path)
	result.sort()
	return result

func active_path() -> String:
	var config:=ConfigFile.new()
	if config.load(directory().path_join("active.cfg"))==OK:
		var path:String=str(config.get_value("farm","path",""))
		if path in paths() and read_farm(path)!=null:return path
	return legacy_path

func select_path(path:String) -> Error:
	var error:=ensure_directory()
	if error!=OK:return error
	var config:=ConfigFile.new()
	config.set_value("farm","path",path)
	var target:=directory().path_join("active.cfg")
	error=config.save(target+".tmp")
	return DirAccess.rename_absolute(target+".tmp",target) if error==OK else error

func ensure_directory() -> Error:
	var parent:=directory()
	while not DirAccess.dir_exists_absolute(parent):
		if FileAccess.file_exists(parent):return ERR_CANT_CREATE
		var above:=parent.get_base_dir()
		if above==parent or above.is_empty():break
		parent=above
	return DirAccess.make_dir_recursive_absolute(directory())

func new_path() -> String:
	if ensure_directory()!=OK:return ""
	return directory().path_join("farm_%d_%s.json"%[int(Time.get_unix_time_from_system()),Crypto.new().generate_random_bytes(8).hex_encode()])

static func mode_label(farm:FarmState) -> String:
	return "Survival" if farm.game_mode=="survival" else "Sandbox" if farm.game_mode=="sandbox" else "Original · dinheiro infinito"
