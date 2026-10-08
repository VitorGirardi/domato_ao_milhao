extends SceneTree
var game:Node3D
func _initialize() -> void:call_deferred("run")
func mouse(button:int,pressed:bool) -> InputEventMouseButton:
	var event:=InputEventMouseButton.new();event.button_index=button;event.pressed=pressed;return event
func key(code:int) -> InputEventKey:
	var event:=InputEventKey.new();event.physical_keycode=code;event.pressed=true;return event
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	game=load("res://scenes/main.tscn").instantiate();game.save_path="user://shoulder_aim.json";root.add_child(game);await process_frame
	game.preferences.data.free_camera=false
	game.qa_mode=true;game.session_started=true;game.build_mode=false;game.hud.close_modal()
	game.set_process(false);game.set_physics_process(false);game.world.set_process(false);game.companions.set_process(false)
	game.weapons.set_physics_process(false);game.falls.set_process(false);game.falls.set_physics_process(false)
	game.state.unlimited_money=true;FarmArmory.buy_pistol(game.state,game.state.armory)
	var w:FarmWeapons=game.weapons
	assert(w.handle_input(key(KEY_P)) and w.armed)
	assert(not w.handle_input(key(KEY_Q)),"Q consumed outside aiming")
	var prior_mouse:=Input.mouse_mode
	assert(w.handle_input(mouse(MOUSE_BUTTON_RIGHT,true)) and w.aiming)
	assert(w.cursor_owned,"Aim did not acquire mouse ownership")
	if DisplayServer.get_name()!="headless":assert(Input.mouse_mode==Input.MOUSE_MODE_CAPTURED,"Aim did not capture the mouse")
	w._physics_process(.1);assert(w.aim_blend>0 and w.aim_blend<1,"Aim transition snapped")
	var side:=w.shoulder_side;assert(w.handle_input(key(KEY_Q)) and w.shoulder_side==-side)
	var orbit_pitch:float=game.pitch;var aim_pitch:=w.aim_pitch
	var motion:=InputEventMouseMotion.new();motion.relative=Vector2(30,20)
	assert(w.handle_input(motion));assert(w.aim_pitch>aim_pitch and game.pitch==orbit_pitch,"Aim modified exploration pitch")
	game.hud.modal_kind="settings";w._input(mouse(MOUSE_BUTTON_RIGHT,false));assert(not w.aiming,"Release over modal left aim held");assert(Input.mouse_mode==prior_mouse,"Release over modal did not restore mouse mode")
	w._physics_process(.1);assert(not w.armed);game.hud.close_modal()
	# Camera selection sees manual actor capsules even when solid colliders are absent.
	game.player.position=Vector3(120,100,0);game.camera.position=Vector3(120,102,-3)
	game.avatar.visible=false;game.falls.refresh_targets()
	assert(game.falls.trace_hit(Vector3(120,101,-4),Vector3(120,101,4),2).key=="player:1","Camera-hidden local avatar became immune")
	game.avatar.visible=true
	game.camera.look_at(Vector3(120,102,10));game.falls.refresh_targets()
	var target:Node3D=game.falls.targets["npc:vendor"].body;target.global_position=Vector3(120,100,10)
	await physics_frame;await physics_frame
	assert(w.aim_point().distance_to(Vector3(120,102,10))<1,"Reticle failed to select NPC capsule")
	for character in FarmCharacters.IDS:
		target.global_position=Vector3(120,100,10)
		FarmCharacters.apply_to_game(game,character);w.armed=true;w.aiming=true;w.aim_blend=1;w.cooldown=0
		var before:int=game.state.armory.magazine
		assert(w.shoot() and game.state.armory.magazine==before-1)
		assert(game.falls.is_down("npc:vendor"),"Crosshair hit failed for "+character)
		game.falls.reset();game.falls.refresh_targets()
	# Camera can see past cover while the physical muzzle cannot shoot through it.
	target.global_position=Vector3(120,100,10)
	var wall:=StaticBody3D.new();var shape:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(6,6,.3);shape.shape=box;wall.add_child(shape);game.add_child(wall);wall.position=Vector3(120,102,2)
	game.camera.position=Vector3(120,102,3);game.camera.look_at(Vector3(120,102,10))
	await physics_frame;await physics_frame
	assert(w.aim_point().distance_to(Vector3(120,102,10))<1)
	w.cooldown=0;assert(w.shoot());assert(not game.falls.is_down("npc:vendor"),"Muzzle shot passed through nearby wall")
	wall.queue_free();await physics_frame;await physics_frame
	# The practice target remains hittable through the same camera/shot path.
	target.position=Vector3(160,100,10)
	var practice:Node3D=w.targets[0];practice.position=Vector3(120,100,10);practice.rotation=Vector3(PI/2,0,0)
	game.camera.position=Vector3(120,102,-3);game.camera.look_at(practice.global_transform*Vector3(0,1.56,0))
	await physics_frame;await physics_frame
	var hits:int=game.state.armory.hits;w.cooldown=0;assert(w.shoot());assert(game.state.armory.hits==hits+1,"Practice range stopped recording hits")
	w.holster();w._physics_process(1);assert(w.aim_blend<.001 and not w.pistol.visible)
	game.session_started=false;game.weapons.sound.stop();game.audio.stop_all()
	# Drain stopped voices on the mixer thread before freeing their players.
	await create_timer(.2).timeout
	game.queue_free();await process_frame
	await create_timer(.2).timeout
	print("SHOULDER_AIM_OK: event-driven input, shoulder switching, smooth blend, HUD release, both characters, NPC reticle, muzzle cover and practice range")
	quit()







