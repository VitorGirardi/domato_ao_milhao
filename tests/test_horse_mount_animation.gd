extends SceneTree
var game:Node3D
func _initialize() -> void:call_deferred("run")
func capture(label:String) -> void:
	if DisplayServer.get_name()=="headless":return
	game.camera.position=game.horse.position+Vector3(-5,3.6,5)
	game.camera.look_at(game.horse.position+Vector3(0,1.8,0))
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/horse-mount-"+label+".png")
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	game=load("res://scenes/main.tscn").instantiate();game.save_path="user://horse_mount.json";root.add_child(game)
	await process_frame;await physics_frame;await physics_frame
	game.qa_mode=true;game.set_process(false);game.set_physics_process(false)
	game.session_started=true;game.build_mode=false;game.hud.close_modal();game.hud.root.visible=false
	game.ghost.visible=false;game.world.build_grid.visible=false
	for character in ["farmer","farmer_woman"]:
		FarmCharacters.apply_to_game(game,character)
		for side in [-1.0,1.0]:
			game.horse.restore(FarmHorse.defaults());game.horse.animate(0,0,false)
			game.player.position=game.horse.position+Vector3(side*1.65,.12,0)
			var original:Vector3=game.player.position
			assert(game.horse.approach_clear(game.player))
			game.horse.mount(game.player,game.avatar,game.actor,true)
			assert(game.horse.transition_active() and game.horse.mounted)
			assert(game.player.position.distance_to(original)<.001,"Mount must not teleport root")
			assert(not game.horse.encourage())
			game.horse.drive(game.player,game.avatar,game.actor,Vector3.ONE,.5,false)
			assert(game.horse.transition_elapsed==0,"Menu pause advanced mount")
			var previous:Vector3=game.player.position
			for frame in range(65):
				game.horse.drive(game.player,game.avatar,game.actor,Vector3.ZERO,.025,true)
				assert(game.player.position.distance_to(previous)<.23,"Discontinuous physical mount root")
				previous=game.player.position
				if frame==31:
					var boot:=FarmHorseMountPose.sole(game.actor,"L" if side<0 else "R")
					assert(boot.distance_to(game.horse.model.to_global(Vector3(side*.49,1.23,.10)))<.16,"Support boot missed stirrup")
				if side<0 and frame in [12,30,44]:await capture(character+"-"+str(frame))
			assert(not game.horse.transition_active() and game.horse.mounted)
			assert(not game.horse.rider_collision.disabled and not game.horse.rider_upper_collision.disabled)
			assert(game.horse.dismount(game.player,game.avatar,game.actor,game.state,game.world.landscape,true))
			assert(game.horse.mounted,"Dismount released authority before landing")
			for frame in range(65):game.horse.drive(game.player,game.avatar,game.actor,Vector3.ZERO,.025,true)
			assert(not game.horse.mounted and not game.horse.transition_active())
			assert(game.avatar.position.is_zero_approx() and not game.horse.rider_collision.disabled)
		# Cancellation is immediate for temporary falls, switching farms and disconnect.
		game.player.position=game.horse.position+Vector3(-1.65,.12,0)
		game.horse.mount(game.player,game.avatar,game.actor,true)
		game.horse.drive(game.player,game.avatar,game.actor,Vector3.ZERO,.7,true)
		game.horse.reset_rider(game.player,game.avatar,game.actor)
		assert(not game.horse.transition_active() and not game.horse.mounted and not game.horse.rider_collision.disabled)
	var wall:=StaticBody3D.new();var shape:=CollisionShape3D.new();var box:=BoxShape3D.new()
	box.size=Vector3(.3,3,2);shape.shape=box;wall.add_child(shape);game.add_child(wall)
	wall.position=game.horse.position+Vector3(-1.1,1.5,0)
	game.player.position=game.horse.position+Vector3(-1.8,.12,0)
	await physics_frame;await physics_frame
	assert(not game.horse.approach_clear(game.player),"Mount crossed a blocked approach")
	wall.queue_free()
	print("HORSE_MOUNT_ANIMATION_OK: both rigs/sides, continuous root, pause, safe descent, cancellation and blocked approach")
	game.session_started=false;game.audio.stop_all();await create_timer(.3).timeout
	game.queue_free();await process_frame;await create_timer(.2).timeout;quit()
