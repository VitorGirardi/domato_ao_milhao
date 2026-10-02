extends SceneTree
var game:Node3D
func _initialize() -> void:call_deferred("run")
func capture(label:String) -> void:
	if DisplayServer.get_name()=="headless":return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/farms-"+label+".png")
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	game=load("res://scenes/main.tscn").instantiate()
	game.save_path="user://qa_slots/legacy.json"
	DirAccess.make_dir_recursive_absolute("user://qa_slots")
	root.add_child(game);await process_frame
	game.set_process(false);game.set_physics_process(false)
	root.mode=Window.MODE_WINDOWED;root.size=Vector2i(1440,900)
	# Preserve a pre-feature farm, including its finite stored balance and progress.
	var legacy:=FarmState.new();legacy.farm_name="Fazenda antiga";legacy.farm_xp=280
	var data:=legacy.serialize();data.erase("game_mode");data.erase("character_id")
	var file:=FileAccess.open(game.farm_saves.legacy_path,FileAccess.WRITE)
	file.store_string(JSON.stringify(data));file.close()
	var original:=FileAccess.get_file_as_string(game.farm_saves.legacy_path)
	game.front_end.open_farm(game.farm_saves.legacy_path)
	assert(game.state.unlimited_money and game.state.farm_xp==280)
	game._action("front:title")
	original=FileAccess.get_file_as_string(game.farm_saves.legacy_path)
	game._action("front:new");game.hud.text_input.text="Survival do teste"
	game.front_end.select_character("farmer_woman")
	await capture("new")
	game._action("front:new_review")
	assert(game.session_started and game.state.game_mode=="survival")
	assert(game.state.money==1600 and not game.state.unlimited_money and not game.state.claimed)
	assert(not FarmLevels.unlocked(game.state,"cheesery"))
	assert(game.avatar.get_meta("character_id")=="farmer_woman")
	var survival_path:String=game.save_path
	assert(game.state.claim(Vector2(4,-2)).is_empty())
	assert(game.state.money==1200)
	game._action("front:title")
	var survival_bytes:=FileAccess.get_file_as_string(survival_path)
	game._action("front:new");game.hud.text_input.text="Sandbox do teste"
	game.front_end.mode_picker.select(1);game.front_end.mode_picker.item_selected.emit(1)
	game.front_end.select_character("farmer");game._action("front:new_review")
	assert(game.state.game_mode=="sandbox" and game.state.unlimited_money)
	assert(FarmLevels.unlocked(game.state,"cheesery") and game.state.farm_xp==0)
	assert(game.state.resources.gallery_level==2 and game.state.resources.rod and game.state.armory.pistol)
	var sandbox_path:String=game.save_path
	assert(sandbox_path!=survival_path)
	assert(FileAccess.get_file_as_string(survival_path)==survival_bytes)
	assert(FileAccess.get_file_as_string(game.farm_saves.legacy_path)==original)
	game._action("front:title");game._action("front:farms")
	assert(game.hud.modal_kind=="farms" and game.front_end.listed_paths.size()>=3)
	await capture("list")
	game.front_end.open_farm(survival_path)
	assert(not game.state.unlimited_money and game.state.money==1200 and game.state.claimed)
	assert(game.avatar.get_meta("character_id")=="farmer_woman")
	assert(game.farm_saves.active_path()==survival_path)
	assert(game._load_game() and not game.state.unlimited_money)
	assert(FarmCoop.save_farm(FarmCoop.path_for(survival_path),game.state))
	assert(not FarmCoop.load_farm(FarmCoop.path_for(survival_path)).unlimited_money)
	# Mission CTA closes the overlay before activating placement.
	game._action("objectives");assert(game.hud.modal_kind=="objectives")
	game._action("journey");assert(game.hud.modal_kind.is_empty() and game.tool=="plot")
	game.build_mode=false;game.pitch=.45;game._update_ui();game._update_camera(1,true);game.hud.toast_time=0;game.hud.toast_panel.visible=false
	await capture("hud")
	assert(game.hud.walking.shortcuts[0].position.x==24)
	assert(game.navigator.mini.get_parent().position.x==1164)
	game.hud.walking.shortcuts[0].grab_focus();await process_frame
	assert(game.hud.walking.shortcuts[0].modulate==Color.WHITE)
	# A damaged primary recovers from backup, which must survive the next write.
	assert(game._save_game(false,true));assert(game._save_game(false,true))
	file=FileAccess.open(survival_path,FileAccess.WRITE);file.store_string("broken");file.close()
	var recovered:FarmState=game.farm_saves.read_farm(survival_path)
	assert(recovered!=null and recovered.money==1200 and not recovered.unlimited_money)
	var backup:=FileAccess.get_file_as_string(survival_path+".bak")
	game.state=recovered;assert(game._save_game(false,true))
	assert(FileAccess.get_file_as_string(survival_path+".bak")==backup)
	# A failed new-slot allocation leaves the current farm untouched.
	game._action("front:title");game._action("front:new")
	var good_legacy:String=game.farm_saves.legacy_path
	game.farm_saves.legacy_path=survival_path.path_join("blocked.json")
	game.front_end.review_new()
	assert(game.save_path==survival_path and game.state.money==1200)
	game.farm_saves.legacy_path=good_legacy
	# Invalid modes cannot enable cheats; old-schema roundtrips remain valid.
	data=game.state.serialize();data.game_mode="invalid"
	assert(not FarmState.new().restore(data))
	game.front_end.open_farm(sandbox_path)
	assert(game.state.unlimited_money and game.state.game_mode=="sandbox")
	print("FARM_SLOTS_OK: legacy preservation, independent farms, modes, backups, failures, coop, mission CTA and HUD")
	game.session_started=false;game.free();quit()
