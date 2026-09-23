extends SceneTree
## Combined armory and horse integration; requires isolated QA user data.
var game:Node3D
func _initialize() -> void:call_deferred("run")
func key(code:Key) -> InputEventKey:
	var event:=InputEventKey.new();event.physical_keycode=code;event.keycode=code;event.pressed=true
	return event
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	game=load("res://scenes/main.tscn").instantiate()
	game.save_path="user://qa_armory_horse.json"
	root.add_child(game);await process_frame
	game.session_started=true;game.build_mode=false;game.hud.close_modal()
	game.state=FarmState.new();game.state.unlimited_money=true
	game.state.claim(Vector2(4,-2));game.world.rebuild(game.state)
	game.horse.restore(FarmHorse.defaults())
	game.player.position=game.horse.position+Vector3(1.8,.1,0)
	await create_timer(.5).timeout
	assert(game.horse.can_mount(game.player))
	assert(FarmArmory.buy_pistol(game.state,game.state.armory).is_empty())
	assert(game.weapons.handle_input(key(KEY_P)) and game.weapons.armed)
	assert(game.weapons.shoot());assert(game.weapons.start_reload())
	var before:Dictionary=game.state.armory.duplicate()
	game._horse_interact()
	assert(game.horse.mounted and not game.weapons.armed and game.weapons.reload_left==0)
	assert(game.state.armory==before,"Mounting cancels reload without changing ammunition")
	assert(not game.weapons.handle_input(key(KEY_P)))
	assert(not game.weapons.shoot() and not game.weapons.start_reload())
	await create_timer(.2).timeout
	assert(game.horse.mounted and not game.weapons.pistol.visible)
	game.horse.store(game.state);assert(game._save_game(false))
	var disk:=FarmState.new()
	assert(disk.restore(JSON.parse_string(FileAccess.get_file_as_string(game.save_path))))
	assert(disk.horse==game.state.horse and disk.armory==before)
	game._horse_interact();assert(not game.horse.mounted)
	await create_timer(.4).timeout
	assert(game.weapons.handle_input(key(KEY_P)) and game.weapons.armed)
	assert(game.weapons.start_reload());await create_timer(1.4).timeout
	assert(game.state.armory.magazine==8 and game.state.armory.reserve==23)
	var modern:Dictionary=game.state.serialize()
	assert(modern.version==17 and modern.has("horse") and modern.has("armory"))
	var old:=modern.duplicate(true);old.version=15;old.erase("horse")
	assert(disk.restore(old) and disk.armory==game.state.armory and disk.horse==FarmHorse.defaults())
	old=modern.duplicate(true);old.erase("armory")
	assert(disk.restore(old) and disk.armory==FarmArmory.fresh() and disk.horse==game.state.horse)
	for damage in [{"horse":{}},{"armory":{}},{"horse":null},{"armory":null}]:
		var invalid:=modern.duplicate(true);invalid.merge(damage,true)
		var snapshot:=disk.serialize();assert(not disk.restore(invalid) and disk.serialize()==snapshot)
	# Both interactions are in range: the closest physical target owns E.
	game.weapons.holster()
	game.horse.restore({"x":-28.8,"z":22.0,"angle":0.0})
	game.player.position=Vector3(-30.2,.12,22)
	await create_timer(.4).timeout
	assert(game.weapons.near_shop() and game.horse.can_mount(game.player))
	game._update_ui()
	assert(game._nearby_context().action=="horse" and game.hud.walking.interaction.text=="E · Montar · Pé de Pano")
	assert(not game.weapons.handle_input(key(KEY_E)),"Closer horse must receive E")
	game._interact_nearest();assert(game.horse.mounted)
	assert(game.horse.dismount(game.player,game.avatar,game.actor,game.state,game.world.landscape))
	game.horse.restore({"x":-28.8,"z":22.0,"angle":0.0})
	game.player.position=Vector3(-31.4,.12,22)
	await create_timer(.4).timeout
	assert(game.weapons.near_shop() and game.horse.can_mount(game.player))
	game._update_ui()
	assert(game._nearby_context().action=="armory" and game.hud.walking.interaction.text=="E · Conversar com Damião")
	assert(game.weapons.handle_input(key(KEY_E)) and game.hud.modal_kind=="armory","Closer counter must receive E")
	game.hud.close_modal()
	game._interact_nearest();assert(game.hud.modal_kind=="armory","HUD button must match the keyboard interaction")
	game.hud.close_modal()
	print("ARMORY_HORSE_OK: holster on mount, blocked mounted inputs, interrupted reload, dismount, both inventories on disk, v15 migration, atomic rejection and nearest E interaction")
	game.session_started=false;game.queue_free();await process_frame;quit()
