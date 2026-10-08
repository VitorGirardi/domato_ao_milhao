extends SceneTree
var game:Node3D
var truck:FarmPickup
func _initialize() -> void:call_deferred("run")

func place(point:Vector2,heading:float) -> void:
	truck.restore({"x":point.x,"z":point.y,"angle":heading})
	game.player.position=truck.door_stand();game.actor.airborne=false;game.actor.swimming=false
	assert(truck.enter())
	while truck.transitioning():truck.drive(.05,0,0,true,true)

func screenshot(label:String) -> void:
	if DisplayServer.get_name()=="headless":return
	RenderingServer.set_render_loop_enabled(true)
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/pickup-"+label+".png")
	RenderingServer.set_render_loop_enabled(false)

func run() -> void:
	game=load("res://scenes/main.tscn").instantiate();game.save_path="user://physics-probe.json";root.add_child(game)
	await process_frame;game.qa_mode=true;game.set_process(false);game.set_physics_process(false)
	game.session_started=true;game.build_mode=false;game.hud.close_modal()
	truck=game.pickup;truck.set_physics_process(false)
	await physics_frame
	# Preserve every physics step; only draw the frame used for visual review.
	RenderingServer.set_render_loop_enabled(false)
	var highs:=[]
	for throttle in [.3,1.0]:
		place(Vector2(580,-250),1.86)
		var peak:=0.0;var air:=0;var landed:=false;var captured:=false
		for frame in range(1500 if throttle<1 else 460):
			await physics_frame
			truck.drive(1.0/60,throttle,0,false,true)
			var clearance:=truck.position.y-FarmLandscape.height_at(Vector2(truck.position.x,truck.position.z))
			peak=maxf(peak,clearance)
			if truck.airborne:
				air+=1
				if clearance>.3 and not captured and DisplayServer.get_name()!="headless":
					game.camera.position=truck.position+Vector3(-9,4,7);game.camera.look_at(truck.position+Vector3.UP)
					game.hud.visible=false;await screenshot("airborne");game.hud.visible=true;captured=true
			elif air>0:landed=true
			if truck.position.x>685:break
		if throttle==1:
			assert(air>5 and peak>.3 and landed,"Fast crest must launch and land: %s / %s / %s"%[air,peak,landed])
			highs.append(peak)
			assert(not truck.airborne)
		else:
			assert(air==0,"Slow driving must stay planted")
		print("CREST throttle=",throttle," clearance=",peak," air_frames=",air," landed=",landed)
	# A suspended vehicle cannot steer, brake in midair or eject its driver.
	truck.position.y+=4;truck.airborne=true;truck.speed=15;truck.velocity.y=3
	var heading:=truck.rotation.y
	truck.drive(1.0/60,0,1,true,true)
	assert(truck.speed==15 and truck.rotation.y==heading and not truck.exit_vehicle())
	assert(truck.velocity.y<3 and truck.velocity.y>0)
	RenderingServer.set_render_loop_enabled(true)
	game.session_started=false;game.audio.stop_all();game.free()
	print("PICKUP_PHYSICS_OK: real crest slow/fast, inertia, flight, landing and airborne controls")
	quit()
