extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	DirAccess.make_dir_recursive_absolute("res://test-results/companions")
	var clear:=func(p:Vector2):return not Rect2(2,-2,2,4).has_point(p)
	var route:=FarmCompanionPath.route(Vector2.ZERO,Vector2(6,0),clear)
	assert(not route.is_empty())
	for point in route:assert(clear.call(point))
	assert(FarmCompanionPath.route(Vector2.ZERO,Vector2(100,0),clear).is_empty())
	var game:Node3D=load("res://scenes/main.tscn").instantiate();game.save_path="user://companions.json";root.add_child(game)
	await process_frame;game.qa_mode=true;game.set_process(false);game.set_physics_process(false);game.companions.set_process(false)
	game.state=FarmState.new();game.state.unlimited_money=true;game.state.claim(Vector2(4,0));game.world.rebuild(game.state)
	game.session_started=true;game.build_mode=false;game.hud.close_modal();await physics_frame
	var c:FarmCompanions=game.companions;var cat:FarmCat=game.world.cat
	cat.reset(game.state);assert(cat.visible)
	game.player.position=cat.position+Vector3(0,0,.9);game.actor.airborne=false
	var saved:Dictionary=game.state.serialize()
	assert(c.apply(1,"pet"));assert(not c.apply(1,"pet"))
	assert(c.purr.playing and c.purr.stream.get_length()>3)
	for character in FarmCharacters.IDS:
		FarmCharacters.apply_to_game(game,character)
		game.player.position=cat.position+Vector3(0,0,.9)
		for kind in ["pet","whistle"]:
			for i in range(60):
				game.actor.animate(1.0/60,false,false)
				FarmCompanions.pose(game.actor,kind,1.0,3.2 if kind=="pet" else 1.8,cat.position)
				FarmCatPose.pose(cat.model,1.0,0,0,1 if kind=="pet" else 0)
			var aim:Vector3=cat.position+Vector3(0,.54,.10*sin(6))
			if kind=="whistle":
				var mouth:Vector3=game.actor.skeleton.to_global(game.actor.skeleton.get_bone_global_pose(game.actor.bones.Head).origin+Vector3(.05,.08,.28))
				print("WHISTLE_DISTANCE ",game.actor.rein_grip_world("R").distance_to(mouth))
			if kind=="pet":
				print("PET_HAND_DISTANCE ",character," ",game.actor.rein_grip_world("R").distance_to(aim))
				assert(game.actor.rein_grip_world("R").distance_to(aim)<.20)
			if DisplayServer.get_name()!="headless":
				game.hud.hide();game.camera.position=cat.position+Vector3(-3,1.8,-3.2);game.camera.look_at(cat.position+Vector3(0,1.1,.4))
				await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://test-results/companions/%s-%s.png"%[character,kind])
	c.gestures.clear();game.actor.action_time=0;cat.pet_remaining=0
	assert(c.apply(1,"follow"));assert(cat.following)
	var start:=cat.position
	game.player.position=start+Vector3(5,0,0)
	for i in range(180):c.update_follow(1.0/60);cat.update(1.0/60,game.player.position,game.state)
	print("FOLLOW ",cat.position," ",start," ",c.path)
	assert(cat.position.distance_to(start)>1.5 and cat.position.distance_to(game.player.position)<3)
	c.last_request.clear();assert(c.apply(1,"follow"));assert(not cat.following)
	# Staying outside the property must not reset the animal to its farm spawn.
	var outside:=Vector2(30,0)
	for x in range(30,55):
		var candidate:=Vector2(x,0)
		if cat.clear_at(candidate,game.state):outside=candidate;break
	assert(cat.clear_at(outside,game.state))
	cat.home=outside;cat.destination=outside;cat.position=Vector3(outside.x,FarmLandscape.height_at(outside),outside.y)
	cat.update(.1,game.player.position,game.state)
	assert(Vector2(cat.position.x,cat.position.z).distance_to(outside)<.01)
	assert(game.state.serialize()==saved)
	game.horse.position=Vector3(5,0,9);game.horse.heading=PI;game.horse.rotation.y=PI;game.player.position=Vector3(5,0,0)
	await physics_frame
	assert(c.apply(1,"whistle"));assert(c.whistle.playing and c.whistle.stream.get_length()>1)
	var distance:float=game.horse.position.distance_to(game.player.position)
	for i in range(240):
		c.update_follow(1.0/60);game.horse.life.update(game.horse,1.0/60,true,game.state,game.world.landscape,game.player)
	assert(game.horse.position.distance_to(game.player.position)<distance-2)
	game.horse.mounted=true;c.last_request.clear();assert(not c.apply(1,"whistle"));game.horse.mounted=false
	c.reset();assert(c.follow_owner==0 and not c.purr.playing and not c.whistle.playing)
	game.session_started=false;game.audio.stop_all();await create_timer(.4).timeout;game.queue_free();await process_frame;await create_timer(.3).timeout
	print("COMPANIONS_OK: path detour, both characters contact/whistle, purr, follow/stay, horse approach, occupied mount and reset")
	quit()
