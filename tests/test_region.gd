extends SceneTree
var game: Node3D
func _initialize() -> void: call_deferred("run")

func capture(label: String, from: Vector3, target: Vector3) -> void:
	game.camera.position=from; game.camera.look_at(target); game.camera.fov=65
	if DisplayServer.get_name()=="headless": return
	await create_timer(.4).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/region-"+label+".png")

func ride_between(start: Vector2, finish: Vector2) -> void:
	game.horse.position=Vector3(start.x,FarmLandscape.height_at(start)+.1,start.y)
	var heading:Vector2=(finish-start).normalized()
	game.horse.heading=atan2(heading.x,heading.y)
	game.horse.mount(game.player,game.avatar,game.actor)
	var arrived:=false
	for step in range(1100):
		await physics_frame
		var at:=Vector2(game.player.position.x,game.player.position.z)
		if at.distance_to(finish)<1.5: arrived=true; break
		var direction:Vector2=(finish-at).normalized()
		game.horse.drive(game.player,game.avatar,game.actor,Vector3(direction.x,0,direction.y),1.0/60,true)
		assert(game.player.position.y>FarmLandscape.height_at(at)-1.0,"Rider fell through terrain")
	assert(arrived,"Horse blocked on route %s -> %s, at %s"%[start,finish,game.player.position])
	game.horse.reset_rider(game.player,game.avatar,game.actor)

func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	# The original playable valley and every purchasable parcel keep their elevations.
	for z in range(-145,146,5):
		for x in range(-34,181,5):
			var p:=Vector2(x,z)
			assert(is_equal_approx(FarmLandscape.base_height(p),FarmLandscape.legacy_height(p)))
	for route in FarmRegion.ROUTES:
		for i in range(route.size()-1):
			var a:Vector3=route[i]; var b:Vector3=route[i+1]
			for step in range(11):
				var at:=a.lerp(b,step/10.0); var p:=Vector2(at.x,at.z)
				assert(not FarmRegion.water_blocked(p),"Road enters deep water: %s"%p)
				assert(absf(FarmLandscape.height_at(p+Vector2(.5,0))-FarmLandscape.height_at(p))<.4,"Road slope X: %s"%p)
				assert(absf(FarmLandscape.height_at(p+Vector2(0,.5))-FarmLandscape.height_at(p))<.4,"Road slope Z: %s"%p)
	assert(FarmRegion.water_blocked(Vector2(FarmRegion.river_x(40),40)))
	assert(FarmRegion.water_blocked(Vector2(285,260)))
	assert(not FarmRegion.water_blocked(Vector2(420,0)))
	assert(FarmLandscape.height_at(Vector2(420,0))==5)
	assert(FarmLandscape.terrain_height(Vector2(420,0))<2)
	game=load("res://scenes/main.tscn").instantiate(); game.save_path="user://qa_region.json"
	root.add_child(game); await process_frame
	game.qa_mode=true; game.set_process(false); game.set_physics_process(false)
	game.session_started=true; game.build_mode=false; game.hud.close_modal()
	game.state=FarmState.new(); game.state.claim(Vector2(4,-2)); game.state.unlimited_money=true
	game.state.place("barn",Vector2(8,-8),0); game.world.rebuild(game.state)
	var saved:Dictionary=game.state.serialize()
	game.hud.root.visible=false; game.world.build_grid.visible=false; game.ghost.visible=false
	game.world.day_night.update_cycle(80,Vector3(700,90,-320))
	await physics_frame; await physics_frame
	# Raycast the rendered/collidable terrain, including the bridge deck and destinations.
	for entry in FarmRegion.PLACES.values():
		var p:Vector2=entry.at
		if entry.name=="Mina da Pedra Clara": p.y+=5
		var h:=FarmLandscape.height_at(p)
		var query:=PhysicsRayQueryParameters3D.create(Vector3(p.x,h+15,p.y),Vector3(p.x,h-15,p.y))
		var hit:Dictionary=game.world.get_world_3d().direct_space_state.intersect_ray(query)
		assert(not hit.is_empty(),"No floor at %s"%entry.name)
		assert(absf(hit.position.y-h)<1.5,"Floor does not match walking height at %s"%entry.name)
	await ride_between(Vector2(388,0),Vector2(452,0))
	await ride_between(Vector2(452,0),Vector2(388,0))
	await ride_between(Vector2(618,-261.5),Vector2(662,-283.5))
	game.horse.restore(game.state.horse)
	await capture("mirante",Vector3(700,124,-326),Vector3(365,8,30))
	await capture("estrada",Vector3(307,13,27),Vector3(480,16,-30))
	await capture("lago",Vector3(239,13,306),Vector3(305,6,249))
	await capture("mina",Vector3(900,84,-200),Vector3(900,84,-224))
	await capture("ponte",Vector3(379,12,35),Vector3(438,5,-9))
	game.world.day_night.update_cycle(300,Vector3(700,90,-320))
	await capture("noite",Vector3(700,124,-326),Vector3(365,8,30))
	game.hud.root.visible=true; game.navigator.show(); game.navigator.refresh()
	if DisplayServer.get_name()!="headless":
		await create_timer(.3).timeout; await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://test-results/region-map.png")
	assert(game.state.serialize()==saved,"Exploration mutated the farm")
	var restored:=FarmState.new(); assert(restored.restore(saved) and restored.unlimited_money)
	print("REGION_OK: old valley preserved, roads dry and walkable, bridge, destination collision, save and visual captures")
	game.session_started=false; game.audio.set_process(false); game.audio.stop_all()
	await create_timer(.2).timeout
	game.queue_free(); await process_frame; await create_timer(.2).timeout; quit()
