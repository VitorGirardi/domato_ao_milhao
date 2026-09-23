extends SceneTree
var game:Node3D
var capture_enabled:=false
func _initialize() -> void:call_deferred("run")
func frame(label:String) -> void:
	await process_frame
	if not capture_enabled:return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/character-choice/"+label+".png")
func click_card(id:String) -> void:
	var card:Control=game.front_end.character_cards[id].button
	var at:Vector2=card.get_global_transform_with_canvas()*(card.size*.5)
	var motion:=InputEventMouseMotion.new();motion.position=at;Input.parse_input_event(motion)
	await process_frame
	for down in [true,false]:
		var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.position=at;event.pressed=down
		Input.parse_input_event(event);await process_frame
	assert(game.front_end.pending_character==id)
func verify_pose(actor:FarmAvatar) -> void:
	for key in actor.bones:assert(actor.skeleton.get_bone_global_pose(actor.bones[key]).is_finite())
	for side in ["L","R"]:
		var index:int=actor.bones["Hand."+side]
		var delta:Quaternion=actor.skeleton.get_bone_rest(index).basis.get_rotation_quaternion().inverse()*actor.skeleton.get_bone_pose_rotation(index)
		assert((delta*Vector3.UP).dot(Vector3.UP)>cos(deg_to_rad(20)),"Wrist must not bend sideways")
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	capture_enabled=DisplayServer.get_name()!="headless"
	DirAccess.make_dir_recursive_absolute("res://test-results/character-choice")
	assert(not FarmCharacters.valid("../../bad") and not FarmCharacters.valid(123))
	assert(FarmCharacters.save_choice("invalid")==ERR_INVALID_PARAMETER)
	assert(FarmCharacters.save_choice("farmer")==OK)
	assert(FarmCharacters.save_choice("farmer_woman","user://missing-directory/profile.cfg")!=OK)
	assert(FarmCharacters.load_choice()=="farmer")
	var broken:=ConfigFile.new();broken.set_value("character","id",["farmer_woman"]);assert(broken.save("user://qa_bad_profile.cfg")==OK)
	assert(FarmCharacters.load_choice("user://qa_bad_profile.cfg")=="farmer")
	game=load("res://scenes/main.tscn").instantiate();game.save_path="user://qa_character_choice.json";root.add_child(game)
	await process_frame;game.set_process(false);game.set_physics_process(false)
	root.mode=Window.MODE_WINDOWED;root.size=Vector2i(1440,900)
	game.front_end.has_save=false;game.front_end.new_game()
	game.hud.text_input.text="Fazenda Aurora"
	await click_card("farmer_woman");await click_card("farmer")
	game.front_end.character_cards.farmer_woman.button.grab_focus()
	for down in [true,false]:
		var event:=InputEventKey.new();event.keycode=KEY_SPACE;event.physical_keycode=KEY_SPACE;event.pressed=down
		Input.parse_input_event(event);await process_frame
	assert(game.front_end.pending_character=="farmer_woman","Keyboard must choose a card")
	for resolution in [Vector2i(1280,720),Vector2i(1280,1024),Vector2i(1920,1080),Vector2i(2560,1080)]:
		root.size=resolution;await process_frame;await process_frame
		var modal:Control=game.hud.modal
		var trans:=modal.get_global_transform_with_canvas()
		assert(root.get_visible_rect().grow(1).encloses(Rect2(trans*Vector2.ZERO,modal.size*trans.get_scale())),"Character selection cropped")
	root.size=Vector2i(1440,900);await process_frame
	assert(game.hud.text_input.text=="Fazenda Aurora")
	assert(FarmCharacters.load_choice()=="farmer","Preview must not change saved identity")
	await create_timer(.4).timeout;await frame("selection")
	game.front_end.review_new()
	assert(game.avatar.get_meta("character_id")=="farmer_woman")
	assert(FarmCharacters.load_choice()=="farmer_woman" and game.state.farm_name=="Fazenda Aurora")
	assert(game.weapons.pistol.get_parent()==game.actor.hand_socket)
	game.hud.visible=false;game.weapons.layer.visible=false
	game.player.position=Vector3(4,0,10);game.avatar.rotation=Vector3.ZERO;game.build_mode=false
	game.camera.position=game.player.position+Vector3(2.6,1.9,4.6);game.camera.look_at(game.player.position+Vector3(0,1.25,0));game.camera.fov=32
	for pose in ["idle","walk","run","jump","water","collect","plant","harvest","chicken","shuffle","victory","six_seven"]:
		game.actor.stop_emote();game.actor.action_time=0;game.actor.airborne=pose=="jump"
		if FarmEmotes.DANCES.has(pose):game.actor.emote(pose)
		elif pose in ["water","collect","plant","harvest"]:game.actor.play(pose)
		for i in range(20):game.actor.animate(.025,pose in ["walk","run"],pose=="run");verify_pose(game.actor)
		await frame(pose)
	game.actor.airborne=false;game.actor.stop_emote();game.actor.action_time=0
	FarmArmory.buy_pistol(game.state,game.state.armory)
	var draw:=InputEventKey.new();draw.physical_keycode=KEY_P;draw.pressed=true
	game.weapons.handle_input(draw);game.weapons._pose_player(1);verify_pose(game.actor);await frame("pistol")
	game.weapons.holster();game.horse.mount(game.player,game.avatar,game.actor)
	game.horse.pose_rider(game.avatar,game.actor)
	game.camera.position=game.horse.position+Vector3(5,3.4,5);game.camera.look_at(game.horse.position+Vector3(0,2,.2))
	for i in range(2):assert(game.horse.to_global(game.horse.rein_end(i)).distance_to(game.actor.rein_grip_world("L" if i==0 else "R"))<.001)
	await frame("mounted")
	game.horse.pat_time=.275;game.horse.pose_rider(game.avatar,game.actor);verify_pose(game.actor);await frame("pat")
	game.horse.reset_rider(game.player,game.avatar,game.actor)
	var inventory:Dictionary=game.state.armory.duplicate()
	FarmCharacters.apply_to_game(game,"farmer");FarmCharacters.apply_to_game(game,"farmer_woman")
	assert(game.state.armory==inventory and game.weapons.pistol.get_parent()==game.actor.hand_socket)
	game.front_end.has_save=true;game.front_end.new_game();game.front_end.select_character("farmer")
	game.front_end.handle("front:back")
	assert(FarmCharacters.load_choice()=="farmer_woman" and game.avatar.get_meta("character_id")=="farmer_woman")
	game.audio.stop_all();game.session_started=false;game.queue_free();await process_frame;await create_timer(.2).timeout
	game=load("res://scenes/main.tscn").instantiate();game.save_path="user://qa_character_choice.json";root.add_child(game)
	await process_frame;game.set_process(false);game.set_physics_process(false)
	assert(game.avatar.get_meta("character_id")=="farmer_woman","Restart must load local choice")
	assert(game.state.farm_name=="Fazenda Aurora")
	game.audio.stop_all();game.queue_free();await process_frame;await create_timer(.2).timeout
	print("CHARACTER_CHOICE_OK: profile, cards, persistence, all actions, wrist poses, weapon attachment, reins and cancellation")
	quit()
