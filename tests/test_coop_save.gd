extends SceneTree
func _initialize() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	var path:="user://save_rules_coop.json"
	var state:=FarmState.new();state.farm_name="Coop primeiro"
	assert(FarmCoop.save_farm(path,state))
	state.farm_name="Coop segundo";assert(FarmCoop.save_farm(path,state))
	assert(FarmCoop.load_farm(path).farm_name=="Coop segundo")
	var f:=FileAccess.open(path,FileAccess.WRITE);f.store_string("broken");f.close()
	var recovered:=FarmCoop.load_farm(path);assert(recovered.farm_name=="Coop primeiro")
	assert(FarmCoop.save_farm(path,recovered))
	assert(JSON.parse_string(FileAccess.get_file_as_string(path+".bak")).farm.farm_name=="Coop primeiro")
	assert(not FarmCoop.save_farm("user://does_not_exist/coop.json",state))
	assert(FarmCoop.path_for("user://farm_v1.json")=="user://farm_v1_coop.json")
	print("COOP_SAVE_OK: atomic separate save, valid backup recovery and failure reporting")
	quit()
