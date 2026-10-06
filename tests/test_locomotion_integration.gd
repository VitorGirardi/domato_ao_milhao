extends SceneTree
var game:Node3D

func _initialize() -> void:call_deferred("run")

func capture(label:String) -> void:
	if DisplayServer.get_name()=="headless":return
	game.camera.position=game.player.position+Vector3(6,3.8,6)
	game.camera.look_at(game.player.position+Vector3(0,1.4,0))
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/locomotion/"+label+".png")

func settle() -> void:
	for i in range(35):
		await physics_frame
		game._physics_process(1.0/60)
	assert(game.player.is_on_floor() and not game.actor.airborne)

func walk(frames:int,running:bool=false) -> void:
	Input.action_press("forward")
	if running:Input.action_press("run")
	for i in range(frames):
		await physics_frame
		game._physics_process(1.0/60)
	Input.action_release("forward");Input.action_release("run")

func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	DirAccess.make_dir_recursive_absolute("res://test-results/locomotion")
	root.size=Vector2i(1440,900)
	game=load("res://scenes/main.tscn").instantiate();game.save_path="user://qa_locomotion.json"
	root.add_child(game);await process_frame
	game.qa_mode=true;game.set_process(false);game.set_physics_process(false)
	game.session_started=true;game.build_mode=false;game.hud.close_modal()
	game.weapons.set_physics_process(false);game.pickup.set_physics_process(false)
	game.falls.set_process(false);game.falls.set_physics_process(false)
	game.gathering.set_process(false);game.companions.set_process(false)
	game.world.set_process(false);game.audio.set_process(false);game.audio.stop_all()
	game.state=FarmState.new_farm("survival")
	assert(game.state.claim(Vector2(4,-2)).is_empty())
	assert(game._save_game(false,true))
	var disk:=FileAccess.get_file_as_string(game.save_path)
	var money:int=game.state.money
	game.hud.visible=false;game.ghost.visible=false;game.world.build_grid.visible=false
	game.world.day_night.update_cycle(80,Vector3(-27,1,0))
	for character in FarmCharacters.IDS:
		FarmCharacters.apply_to_game(game,character)
		assert(game.actor.locomotion.enabled and game.actor.locomotion_allowed.is_valid())
		game.player.position=Vector3(-27,FarmLandscape.height_at(Vector2(-27,10))+.05,10)
		game.player.velocity=Vector3.ZERO;game.yaw=0
		await settle()
		var start:Vector3=game.player.position
		await walk(70)
		assert(game.player.position.distance_to(start)>3)
		assert(game.actor.locomotion.active and game.actor.locomotion.gait_weight>.1)
		await capture(character+"-walk")
		await walk(50,true)
		assert(game.actor.locomotion.run_weight>.1)
		await capture(character+"-run")
		game.yaw=.45
		await walk(15)
		await capture(character+"-turn")
		for key in game.actor.bones:
			assert(game.actor.skeleton.get_bone_global_pose(game.actor.bones[key]).is_finite())
		await settle()
		assert(game.actor.root.position.length()<.1)
		# Weapon pose owns the rig while armed, including its frame-zero transition.
		game.weapons.armed=true
		game.actor.animate(.1,true,true)
		assert(not game.actor.locomotion.active)
		game.weapons.holster()
		# All resource and animal gestures use the same suppression contract.
		game.gathering.jobs[game.gathering.own_id()]={}
		game.actor.animate(.1,true,false);assert(not game.actor.locomotion.active)
		game.gathering.jobs.clear()
		game.companions.gestures[game.companions.own_id()]={}
		game.actor.animate(.1,true,false);assert(not game.actor.locomotion.active)
		game.companions.gestures.clear()
		game.actor.play("water");game.actor.animate(.1,false,false)
		assert(not game.actor.locomotion.active and game.actor.can.visible)
		game.actor.action_time=0;game.actor.airborne=false
		assert(game.actor.emote("six_seven"))
		game.actor.animate(.1,false,false);assert(not game.actor.locomotion.active)
		game.actor.stop_emote()
		game.actor.swimming=true;game.actor.animate(.2,true,false)
		assert(not game.actor.locomotion.active and game.actor.root.rotation.x>.2)
		game.actor.swimming=false;game.actor.airborne=true
		game.actor.animate(.1,true,false);assert(not game.actor.locomotion.active)
		game.actor.airborne=false;game.actor.landing=.22
		game.actor.animate(.01,false,false);assert(not game.actor.locomotion.active)
		game.actor.landing=0
		# Instant mount executes animate outside the player's physics loop.
		game.horse.mount(game.player,game.avatar,game.actor)
		game.horse.drive(game.player,game.avatar,game.actor,Vector3.ZERO,.1,true)
		assert(not game.actor.locomotion.active)
		game.horse.reset_rider(game.player,game.avatar,game.actor)
		game.pickup.restore(FarmPickup.defaults())
		game.player.position=game.pickup.position+Vector3(-2.5,.15,0)
		game.actor.airborne=false;game.actor.swimming=false
		await physics_frame
		assert(game.pickup.enter())
		assert(not game.actor.locomotion.active)
		game.pickup.reset_driver()
		assert(game.avatar.position.is_equal_approx(Vector3.ZERO))
		# A teleport must not accumulate displacement in the visual model or save.
		game.player.position=Vector3(-27,FarmLandscape.height_at(Vector2(-27,10))+.05,10)
		game.player.velocity=Vector3.ZERO;game.yaw=0
		await settle()
		assert(game.actor.root.position.length()<.1)
		await walk(15)
		assert(game.actor.locomotion.active)
		await capture(character+"-resumed")
	assert(game.state.money==money and FileAccess.get_file_as_string(game.save_path)==disk)
	assert(not game.state.serialize().has("locomotion"))
	game.session_started=false;game.audio.stop_all();game.queue_free()
	await process_frame;await create_timer(.1).timeout
	print("LOCOMOTION_INTEGRATION_OK: both characters, physical walk/run/turn, tool and mount gates, swim/jump/emote recovery and save isolation")
	quit()
