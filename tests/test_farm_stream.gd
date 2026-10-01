extends SceneTree
## Exercises the actual player input path, including main's walk-boundary clamp.
var game:Node3D
func _initialize() -> void:call_deferred("run")
func tick(action:String,count:int) -> void:
	if not action.is_empty():Input.action_press(action)
	for i in range(count):
		await physics_frame
		game._physics_process(1.0/60)
	if not action.is_empty():Input.action_release(action)

func place(at:Vector2) -> void:
	game.player.position=Vector3(at.x,FarmLandscape.height_at(at)+.12,at.y)
	game.player.velocity=Vector3.ZERO;game.actor.action_time=0;game.actor.swimming=false

func cross_water(from_east:bool) -> void:
	var z:=22.0;var center:=FarmRegion.legacy_river_x(z)
	var sign_value:=1.0 if from_east else -1.0
	place(Vector2(center+sign_value*5,z))
	var action:="left" if from_east else "right"
	var entered:=false
	Input.action_press(action)
	for i in range(330):
		await physics_frame;game._physics_process(1.0/60)
		if game.actor.swimming:entered=true;break
	Input.action_release(action)
	assert(entered,"Cannot enter the farm stream from bank %s at %s"%[from_east,game.player.position])
	assert(game.player.position.x< -34,"Old farm clamp still prevents stream entry")
	# Reach the center before testing the stable buoyant depth.
	Input.action_press(action)
	for i in range(180):
		await physics_frame;game._physics_process(1.0/60)
		if absf(game.player.position.x-center)<.15:break
	Input.action_release(action)
	await tick("",150)
	var level:=FarmRegion.water_level(Vector2(game.player.position.x,game.player.position.z))
	assert(game.actor.swimming and absf(game.player.position.y-(level-1.15))<.15,"Stream should support swimming below the visible surface")
	assert(not game.player.is_on_floor(),"Swimmer stood on a solid water surface")
	var exited:=false
	Input.action_press(action)
	for i in range(420):
		await physics_frame;game._physics_process(1.0/60)
		if (game.player.position.x-center)*sign_value< -4.9:exited=true;break
	Input.action_release(action)
	await tick("",30)
	print("stream bank crossed ",from_east," position ",game.player.position)
	assert(exited and not game.actor.swimming and game.player.is_on_floor(),"Cannot leave the opposite bank: %s"%game.player.position)

func cross_bridge(from_east:bool,mounted:bool) -> void:
	var center:=FarmRegion.legacy_river_x(30)
	var sign_value:=1.0 if from_east else -1.0
	var start:=Vector2(center+sign_value*9,30)
	place(start)
	if mounted:
		game.horse.position=game.player.position;game.horse.heading=-PI/2 if from_east else PI/2
		game.horse.mount(game.player,game.avatar,game.actor)
	var arrived:=false;var on_deck:=false
	Input.action_press("left" if from_east else "right")
	for i in range(460):
		await physics_frame;game._physics_process(1.0/60)
		assert(not game.actor.swimming,"Walking on the bridge triggered swimming")
		if absf(game.player.position.x-center)<4:
			on_deck=true
			assert(game.player.position.y>-.10,"Capsule fell through the farm bridge")
		if (game.player.position.x-center)*sign_value< -8:arrived=true;break
	Input.action_release("left" if from_east else "right")
	print("bridge crossed ",from_east," mounted ",mounted," position ",game.player.position)
	assert(arrived and on_deck,"Bridge blocked %s rider=%s at %s"%[from_east,mounted,game.player.position])
	if mounted:game.horse.reset_rider(game.player,game.avatar,game.actor)

func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	assert(FarmLandscape.WALK_MIN.x<=-65)
	for z in [-60.0,0.0,22.0,60.0]:
		var at:=Vector2(FarmRegion.legacy_river_x(z),z)
		var level:=FarmRegion.water_level(at)
		assert(absf(level-(FarmLandscape.legacy_height(Vector2(-42,z))-.1))<.001,"Farm water must sit below the banks")
		assert(level-FarmLandscape.ground_height(at)>1.5,"Stream has no usable depth")
	var bridge:=Vector2(FarmRegion.legacy_river_x(30),30)
	assert(is_equal_approx(FarmRegion.bridge_height(bridge),.05))
	game=load("res://scenes/main.tscn").instantiate();game.save_path="user://qa_farm_stream.json";root.add_child(game);await process_frame
	game.qa_mode=true;game.set_process(false);game.set_physics_process(false)
	game.session_started=true;game.build_mode=false;game.hud.close_modal();game.yaw=0
	await physics_frame;await physics_frame
	RenderingServer.set_render_loop_enabled(false)
	await cross_water(true);await cross_water(false)
	await cross_bridge(true,false);await cross_bridge(false,false)
	await cross_bridge(true,true);await cross_bridge(false,true)
	RenderingServer.set_render_loop_enabled(true)
	game.session_started=false;game.audio.set_process(false);game.audio.stop_all()
	game.queue_free();await process_frame;await create_timer(.2).timeout
	print("FARM_STREAM_OK: main input crosses old farm boundary, swimming and both banks, depressed water, capsule and horse bridge both ways")
	quit()
