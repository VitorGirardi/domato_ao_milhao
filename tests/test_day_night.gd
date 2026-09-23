extends SceneTree
var game: Node3D
func _initialize() -> void: call_deferred("run")
func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/night-"+label+".png")
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	assert(FarmDayNight.clock_text(0) == "DIA 01   •   08:00")
	assert(FarmDayNight.clock_text(319.999) == "DIA 01   •   23:59")
	assert(FarmDayNight.clock_text(320) == "DIA 02   •   00:00")
	assert(FarmDayNight.clock_text(480) == "DIA 02   •   08:00")
	assert(is_equal_approx(FarmDayNight.daylight(0), FarmDayNight.daylight(24)))
	game = load("res://scenes/main.tscn").instantiate(); game.save_path="user://qa_night.json"
	root.add_child(game); await process_frame
	game.qa_mode=true; game.set_process(false); game.set_physics_process(false)
	game.session_started=true; game.hud.close_modal(); game.build_mode=false
	game.state=FarmState.new(); game.state.claim(Vector2(4,-2)); game.state.unlimited_money=true; game.state.farm_xp=950; game.state.land_size=40
	for entry in [["barn",Vector2(8,-10)],["coop",Vector2(18,-6)],["stable",Vector2(-6,-8)],["corral",Vector2(18,8)]]:
		assert(game.state.place(entry[0],entry[1],0).is_empty())
	game.state.items[-1].dairy.owned=true
	for i in range(9):
		assert(game.state.place("plot",Vector2(4+(i%3)*2,2+(i/3)*2),0,"corn").is_empty())
		game.state.items[-1].growth=1; game.state.items[-1].watered=true
	game.world.rebuild(game.state)
	game.player.position=Vector3(-26.3,0.2,5)
	game.avatar.rotation.y=PI
	game.world.build_grid.visible=false; game.ghost.visible=false
	game.camera.position=Vector3(-36,8,30); game.camera.look_at(Vector3(-12,1,0)); game.camera.fov=64
	var cycle: FarmDayNight = game.world.day_night
	assert(cycle.lamps.size()>=20)
	assert(cycle.local_lights.size()==FarmDayNight.MAX_LOCAL_LIGHTS)
	var count:=cycle.get_child_count()
	var before:Dictionary=game.state.serialize()
	for entry in [[12.0,"day"],[18.5,"sunset"],[23.0,"night"],[30.0,"dawn"]]:
		game.state.elapsed=(float(entry[0])-8.0)*20.0
		cycle.update_cycle(game.state.elapsed,game.player.position)
		game._update_ui()
		await capture(entry[1])
		if entry[1]=="night":
			assert(cycle.night_amount>0.99 and cycle.sun.light_energy<0.01)
			assert(cycle.moon.light_energy>0.1 and cycle.local_lights[0].light_energy>1)
			assert(cycle.lantern_material.emission_energy_multiplier>2)
		if entry[1]=="day":
			assert(cycle.sun.light_energy>0.6 and cycle.moon.light_energy<0.01)
			assert(cycle.local_lights[0].light_energy<0.01)
	var last: Color
	for minute in range(1441):
		cycle.update_cycle(float(minute)/3.0,game.player.position)
		var color:=cycle.sky.sky_horizon_color
		if minute>0: assert(absf(color.r-last.r)+absf(color.g-last.g)+absf(color.b-last.b)<0.035)
		last=color
	game.state.elapsed=280
	var saved:Dictionary=game.state.serialize(); var restored:=FarmState.new()
	assert(restored.restore(saved) and restored.elapsed==280)
	game.world.rebuild(restored); game.world.rebuild(restored)
	assert(cycle.get_child_count()==count and cycle.displayed_hour==22)
	assert(game.state.inventory==before.inventory)
	assert(game._save_game(false,true))
	print("DAY_NIGHT_OK: full clock, midnight, smooth palette, lamp pool, save, rebuild; lamps=",cycle.lamps.size())
	game.session_started=false; game.queue_free(); await process_frame
	quit()

