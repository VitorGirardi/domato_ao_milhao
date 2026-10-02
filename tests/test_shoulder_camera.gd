extends SceneTree

func _initialize() -> void:call_deferred("run")

func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	var rig:=FarmShoulderCamera.new()
	var origin:=Vector3(120,100,120)
	var normal:=origin+Vector3.UP*1.1
	var pose:=rig.compose(origin,normal,9,.78,0,0,1,.08,1,true)
	assert(pose.target.is_equal_approx(normal))
	assert(is_equal_approx(pose.offset.length(),9))
	pose=rig.compose(origin,normal,9,.78,0,1,1,.08,1,true)
	assert(is_equal_approx(pose.target.x-origin.x,.95))
	assert(is_equal_approx(pose.target.y-origin.y,1.95))
	assert(is_equal_approx(pose.offset.length(),3.2))
	var camera:=Camera3D.new();root.add_child(camera);camera.position=pose.target+pose.offset;camera.look_at(pose.target)
	root.size=Vector2i(1440,900)
	var player_head_screen:=camera.unproject_position(origin+Vector3.UP*2.3)
	assert(player_head_screen.x<root.size.x*.42,"Right shoulder did not leave center clear")
	pose=rig.compose(origin,normal,9,.78,0,1,-1,.08,.016)
	assert(pose.target.x>origin.x,"Shoulder switch snapped across the player")
	for i in 90:pose=rig.compose(origin,normal,9,.78,0,1,-1,.08,.016)
	assert(pose.target.x<origin.x-.94)
	var prior_distance:float=pose.offset.length()
	for i in 21:
		pose=rig.compose(origin,normal,9,.78,0,1.0-float(i)/20,-1,.08,.016)
		assert(pose.offset.length()>=prior_distance-.00001)
		prior_distance=pose.offset.length()
	assert(pose.target.is_equal_approx(normal))
	assert(is_equal_approx(pose.offset.length(),9))
	camera.queue_free()
	# Exercise the actual physics helper against a side wall and a rear wall.
	var game=load("res://scenes/main.tscn").instantiate();game.save_path="user://shoulder_camera.json";root.add_child(game);await process_frame
	game.qa_mode=true;game.set_process(false);game.set_physics_process(false);game.weapons.set_physics_process(false)
	game.player.position=origin
	var wall:=StaticBody3D.new();var collision:=CollisionShape3D.new();var box:=BoxShape3D.new()
	box.size=Vector3(.2,5,8);collision.shape=box;wall.add_child(collision);game.add_child(wall);wall.position=origin+Vector3(.6,2,0)
	await physics_frame;await physics_frame
	var shoulder:Vector3=game._camera_clear_position(origin+Vector3.UP*1.95,origin+Vector3(.95,1.95,0))
	assert(shoulder.x<origin.x+.5,"Shoulder pivot crossed the side wall")
	wall.position=origin+Vector3(0,2,1.8);box.size=Vector3(8,5,.2)
	await physics_frame;await physics_frame
	var rear:Vector3=game._camera_clear_position(origin+Vector3.UP*1.95,origin+Vector3(0,1.95,3.2))
	assert(rear.z<origin.z+1.7,"Camera crossed the rear wall")
	# Full blend zero preserves normal walking and construction camera placement.
	wall.queue_free();await physics_frame;await physics_frame
	game.build_mode=false;game.pitch=.78;game.yaw=0;game.walk_distance=9
	game._update_camera(1,true)
	assert(game.camera.position.is_equal_approx(origin+Vector3(0,1.1+sin(.78)*9,cos(.78)*9)))
	game.build_mode=true;game.focus=origin;game.build_distance=20;game._update_camera(1,true)
	assert(game.camera.position.is_equal_approx(origin+Vector3(0,sin(.78)*20,cos(.78)*20)))
	print("SHOULDER_CAMERA_OK: shoulder framing, eased swap/return, side/rear collision, walk/build baseline")
	game.queue_free();await process_frame;quit()
