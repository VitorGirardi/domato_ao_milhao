extends SceneTree
## Uses an isolated APPDATA directory supplied by the runner. No player save.
var game:Node3D
var capture:=false
func _initialize() -> void:
	capture="--capture" in OS.get_cmdline_user_args()
	call_deferred("run")

func screenshot(label:String) -> void:
	if not capture:return
	await process_frame;await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://test-results/armory")
	root.get_texture().get_image().save_png("res://test-results/armory/%s.png"%label)

func key(code:Key) -> InputEventKey:
	var event:=InputEventKey.new();event.physical_keycode=code;event.keycode=code;event.pressed=true
	return event

func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"),"Run with APPDATA isolated inside test-results")
	root.size=Vector2i(1440,900)
	game=load("res://scenes/main.tscn").instantiate()
	# Redirect saving before _ready; this test never uses the normal farm file.
	game.save_path="user://qa_armory_integration.json"
	root.add_child(game)
	await process_frame;await physics_frame
	game.session_started=true;game.build_mode=false;game.hud.close_modal()
	game.state=FarmState.new();game.state.unlimited_money=true
	game.state.claim(Vector2(4,-2));game.world.rebuild(game.state)
	game.set_physics_process(false)
	game.player.position=FarmWeapons.SHOP_AT+Vector3(3.2,.05,0)
	game.camera.position=FarmWeapons.SHOP_AT+Vector3(7,3.3,-5)
	game.camera.look_at(FarmWeapons.SHOP_AT+Vector3(.5,1.1,0))
	await physics_frame;await process_frame
	assert(game.weapons.npc_actor.blink_index>=0 and game.weapons.npc_actor.bones.size()==20)
	assert(game.weapons.near_shop())
	game.hud.toast_time=0;game.hud.toast_panel.visible=false
	await screenshot("01-damiao-in-valley")
	assert(game.weapons.handle_input(key(KEY_E)) and game.hud.modal_kind=="armory")
	await screenshot("02-armory-shop")
	game.hud.action.emit("armory:buy")
	assert(game.state.armory.pistol and game.state.armory.magazine==8)
	var saved:Dictionary=game.state.serialize()
	game.hud.action.emit("armory:buy");assert(game.state.serialize()==saved)
	game.hud.close_modal()
	assert(game.weapons.handle_input(key(KEY_P)) and game.weapons.armed)
	game.player.position=Vector3(-28.8,0,18)
	game.camera.position=Vector3(-24.5,2.6,20.4)
	game.camera.look_at(Vector3(-33.2,1.56,18))
	for i in range(4):await physics_frame
	assert(game.weapons.shoot())
	assert(not game.weapons.shoot(),"Pistol cannot fire again during cooldown")
	await process_frame
	assert(game.state.armory.hits==1,"Muzzle ray must hit the target seen under the crosshair")
	game.hud.toast_time=0;game.hud.toast_panel.visible=false
	await screenshot("03-pistol-target-hit")
	assert(game.weapons.pistol.visible and game.weapons.pistol.global_position.distance_to(game.player.position)<3)
	assert(game.weapons.start_reload())
	await screenshot("04-reload-pose")
	game.hud.menu(game.state);await physics_frame;await process_frame
	assert(not game.weapons.armed and game.weapons.reload_left==0)
	assert(game.state.armory.magazine==7,"Interrupted reload does not create or consume rounds")
	assert(not game.weapons.shoot() and not game.weapons.handle_input(key(KEY_P)))
	game.hud.close_modal();game.weapons.handle_input(key(KEY_P))
	assert(game.weapons.start_reload())
	await create_timer(1.4).timeout
	assert(game.state.armory.magazine==8 and game.state.armory.reserve==23)
	assert(game._save_game(false))
	var disk:=FarmState.new()
	assert(disk.restore(JSON.parse_string(FileAccess.get_file_as_string(game.save_path))))
	assert(disk.armory==game.state.armory,"Purchased pistol and reloaded ammo survive disk round trip")
	# Cover between muzzle and target stops the bullet even if the camera sees it.
	var blocker:=Node3D.new();game.add_child(blocker);blocker.position=Vector3(-31,0,18)
	game.weapons._solid(blocker,Vector3(0,1,0),Vector3(.3,2.0,3))
	await physics_frame;await process_frame
	var hits:int=game.state.armory.hits
	assert(game.weapons.shoot());assert(game.state.armory.hits==hits)
	blocker.queue_free();await process_frame
	game.build_mode=true;await physics_frame;await process_frame
	assert(not game.weapons.armed and not game.weapons.pistol.visible)
	game.build_mode=false
	# Reset/load replaces the dictionary; the controller must cancel pending state.
	game.weapons.handle_input(key(KEY_P));game.state=FarmState.new()
	await physics_frame;await process_frame
	assert(not game.weapons.armed and not game.state.armory.pistol)
	var restored:=FarmState.new();assert(restored.restore(saved) and restored.armory.pistol)
	game.state=restored;await physics_frame;await process_frame
	game.weapons.handle_input(key(KEY_P));game.yaw=1.43
	game.set_physics_process(true)
	await create_timer(.5).timeout
	assert(game.weapons.armed and game.weapons.pistol.visible)
	await screenshot("05-shoulder-camera")
	print("ARMORY_INTEGRATION_OK: shop, purchase, rig/blink, target hit, cooldown, reload, interruption, cover, build mode, reset, persistence")
	game.session_started=false # Avoid normal autosave during teardown.
	game.queue_free();await process_frame
	quit()
