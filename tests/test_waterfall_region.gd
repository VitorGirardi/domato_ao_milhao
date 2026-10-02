extends SceneTree
## Actual authored terrain/water and the playable capsule around the plunge pool.
var game:Node3D
func _initialize() -> void:call_deferred("run")
func capture(label:String,from:Vector3) -> void:
	if DisplayServer.get_name()=="headless":return
	game.camera.position=from;game.camera.look_at(Vector3(810,74,-266))
	await create_timer(.3).timeout;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/waterfall-region-"+label+".png")
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	game=load("res://scenes/main.tscn").instantiate();game.save_path="user://waterfall_region_qa.json";root.add_child(game);await process_frame
	game.qa_mode=true;game.set_process(false);game.set_physics_process(false);game.session_started=true;game.build_mode=false;game.hud.close_modal()
	game.hud.root.visible=false;game.world.build_grid.visible=false;game.ghost.visible=false
	game.player.position=Vector3(810,66.85,-253);game.actor.swimming=true;game.actor.animate(.2,false,false)
	game.world.day_night.update_cycle(80,game.player.position)
	await physics_frame;await physics_frame
	# Check directly beneath the falling sheet as well as its front and shoulders.
	# No dry terrain may be exposed between the curtain and the existing lake.
	for at in [Vector2(810,-263),Vector2(806,-263),Vector2(814,-263),Vector2(810,-260),Vector2(806,-257),Vector2(815,-261),Vector2(810,-253)]:
		assert(FarmRegion.water_level(at)==68,"Plunge pool disconnected from lake")
		assert(FarmLandscape.ground_height(at)<66.5,"Exposed terrain below the falling sheet")
		assert(FarmWater.swimming_at(Vector3(at.x,66.85,at.y)),"Plunge pool must be deep enough to swim")
	# Sweep the game's own collision capsule: open water is free, rock is solid.
	game.player.position=Vector3(806,66.85,-255)
	assert(game.player.move_and_collide(Vector3(8,0,0))==null,"Invisible blocker across the pool")
	game.player.position=Vector3(810,66.85,-253)
	var frontal:KinematicCollision3D=game.player.move_and_collide(Vector3(0,0,-20))
	assert(frontal!=null and game.player.position.z> -265,"Player entered behind waterfall")
	assert(String(frontal.get_collider().name)=="SolidStone","Front must meet actual rock, not exposed terrain")
	for side in [-1.0,1.0]:
		game.player.position=Vector3(810+side*15,72,-267)
		var hit:KinematicCollision3D=game.player.move_and_collide(Vector3(-side*15,0,0))
		assert(hit!=null,"Player entered cliff from side")
		assert(absf(game.player.position.x-810)>5,"Side rock failed to seal hidden interior")
	game.player.position=Vector3(810,66.85,-258);game.actor.swimming=true;game.actor.animate(.2,false,false)
	await capture("front",Vector3(817,70,-247))
	await capture("side",Vector3(790,75,-262))
	game.session_started=false;game.audio.set_process(false);game.audio.stop_all();game.queue_free();await process_frame;await create_timer(.2).timeout
	print("WATERFALL_REGION_OK: submerged bed beneath curtain, connected deep pool, free swimming, solid front and side capsules")
	quit()
