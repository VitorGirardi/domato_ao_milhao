extends SceneTree
## Real field interaction, animation ownership, feedback timing and repeat input.
var game:Node3D

func _initialize() -> void:call_deferred("run")

func advance(seconds:float) -> void:
	# Use elapsed time, not sixty rendered timer waits per second: CI's software
	# renderer may draw only a few frames per second in the full authored world.
	var remaining:=seconds
	var before:=Time.get_ticks_usec()
	while remaining>.00001:
		await process_frame
		var now:=Time.get_ticks_usec()
		var step:=minf(remaining,maxf(.00001,(now-before)/1000000.0))
		before=now;remaining-=step
		game.actor.animate(step,false,false)
		game.action_cooldown=maxf(0,game.action_cooldown-step)
	await process_frame

func capture(label:String) -> void:
	if DisplayServer.get_name()=="headless":return
	game.camera.position=game.player.position+Vector3(4,2.8,-4)
	game.camera.look_at(game.player.position+Vector3(0,1,0))
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/work-"+label+".png")

func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	DirAccess.make_dir_recursive_absolute("res://test-results")
	game=load("res://scenes/main.tscn").instantiate();game.save_path="user://qa_work_integration.json"
	root.add_child(game);await process_frame
	game.qa_mode=true;game.set_process(false);game.set_physics_process(false)
	game.audio.set_process(false);game.audio.stop_all()
	game.weapons.set_physics_process(false);game.pickup.set_physics_process(false)
	game.gathering.set_process(false);game.companions.set_process(false)
	game.session_started=true;game.build_mode=false;game.hud.close_modal()
	game.hud.visible=false;game.ghost.visible=false
	for character in FarmCharacters.IDS:
		FarmCharacters.apply_to_game(game,character)
		game.state=FarmState.new_farm("survival",character)
		game.state.unlimited_money=true
		assert(game.state.claim(Vector2(4,0)).is_empty())
		assert(game.state.place("plot",Vector2(4,0),0).is_empty())
		game.world.rebuild(game.state);game.world.build_grid.visible=false
		game.selected=0;game.crop="carrot";game.action_cooldown=0
		game.player.position=Vector3(4,FarmLandscape.height_at(Vector2(4,2.3)),2.3)
		game.actor.airborne=false;game.actor.swimming=false
		game._tend_selected()
		assert(game.state.items[0].planted)
		await advance(.7)
		game.action_cooldown=0;game._tend_selected()
		assert(game.state.items[0].watered and game.actor.action_kind=="water")
		var before:Dictionary=game.state.serialize()
		game.action_cooldown=0;game._tend_selected()
		assert(game.state.serialize()==before,"Repeated E cannot restart work or spend resources")
		await advance(.48)
		assert(game.actor.can.visible and not game.actor.locomotion.active)
		for side in ["L","R"]:
			var grip:Vector3=FarmWorkPose.CAN_GRIP_L if side=="L" else FarmWorkPose.CAN_GRIP_R
			assert(game.actor.rein_grip_world(side).distance_to(game.actor.can.to_global(grip))<.065,"Rendered vessel must remain in both hands")
		await capture(character+"-water")
		await advance(.8)
		assert(game.actor.action_time==0 and not game.actor.can.visible)
		game.state.items[0].growth=1.0;game.world.update_crops(game.state)
		game._tend_selected()
		assert(game.state.harvests==1 and game.state.inventory.carrot==3)
		assert(game.actor.action_kind=="harvest" and game.actor.action_time>1)
		before=game.state.serialize();game.action_cooldown=0
		game._tend_selected()
		assert(game.state.serialize()==before,"Harvest cannot become an accidental second planting")
		await advance(.68)
		assert(not game.actor.locomotion.active)
		await capture(character+"-harvest")
		await advance(.85)
		assert(game.actor.action_time==0 and game.actor.locomotion.active)
		for key in game.actor.bones:
			assert(game.actor.skeleton.get_bone_global_pose(game.actor.bones[key]).is_finite())
		assert(game.state.harvests==1 and game.state.inventory.carrot==3)
		assert(game._save_game(false,true))
		var saved:=FarmState.new()
		assert(saved.restore(JSON.parse_string(FileAccess.get_file_as_string(game.save_path))))
		assert(saved.harvests==1 and saved.inventory.carrot==3 and saved.game_mode=="survival")
	game.session_started=false;game.audio.stop_all()
	await create_timer(1.6).timeout
	game.queue_free();await process_frame;await create_timer(.2).timeout
	print("WORK_INTEGRATION_OK: both characters plant, water, harvest, reject repeated input, resume locomotion and preserve economy/save")
	quit()
