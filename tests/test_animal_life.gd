extends SceneTree
var game:Node3D
func _initialize() -> void:call_deferred("run")
func capture(key:String) -> void:
	if DisplayServer.get_name()=="headless":return
	game.hud.toast_time=0;game.hud.toast_panel.visible=false
	await create_timer(.1).timeout;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/animals-"+key+".png")
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	root.mode=Window.MODE_WINDOWED;root.size=Vector2i(1280,720)
	game=load("res://scenes/main.tscn").instantiate();game.save_path="user://animal_life.json";root.add_child(game)
	await process_frame;game.qa_mode=true;game.set_process(false);game.set_physics_process(false);game.residents_world.set_process(false);game.pickup.set_physics_process(false)
	game.state=FarmState.new_farm("survival");game.state.money=20000;game.state.farm_xp=950
	assert(game.state.claim(Vector2(4,0)).is_empty());game.state.land_size=40
	for e in [["coop",Vector2(-6,0)],["corral",Vector2(3,0)],["pigsty",Vector2(13,0)]]:assert(game.state.place(e[0],e[1],0).is_empty())
	game.state.items[1].dairy.owned=true;game.state.items[2].pigs.count=3
	# Normalize before rollback comparisons, as saves convert their own numeric fields.
	assert(game.state.restore(game.state.serialize()))
	game.world.rebuild(game.state);game.session_started=true;game.build_mode=false;game.hud.close_modal()
	game.actor.airborne=false;game.actor.swimming=false
	for i in range(3):
		game.selected=i;game._tend_selected();await capture("panel-%d"%i)
		game._action("animal:open");assert(game.hud.modal_kind=="animal_care")
		game.player.position=Vector3(70,0,70)
		var before:Dictionary=game.state.serialize();game._action("animal:care");assert(game.state.serialize()==before)
		var item:Dictionary=game.state.items[i]
		var at:=Vector2(item.x,item.z+4)
		game.player.position=Vector3(at.x,FarmLandscape.height_at(at)+.1,at.y)
		game.actor.airborne=true;game._action("animal:care");assert(game.state.serialize()==before);game.actor.airborne=false
		var path:String=game.save_path;game.save_path="user://missing_animals/farm.json"
		game._action("animal:care");assert(game.state.serialize()==before,"Care must roll back when disk save fails")
		game.save_path=path;game._action("animal:care")
		assert(game.state.items[i].animal_care.visits==1)
		await capture("care-%d"%i)
		game._action("animal:back");assert(game.hud.modal_kind in ["coop","dairy","pigsty"])
	assert(game._load_game())
	for i in range(3):assert(game.state.items[i].animal_care.visits==1)
	# Safe local motion survives every enclosure orientation and does not push the farmer.
	game.hud.hide();game.hud.close_modal()
	for turn in range(4):
		for item in game.state.items:item.turn=turn
		game.world.rebuild(game.state);game.world.clock=0;game.state.elapsed=0
		var pen:Dictionary=game.world.pigsties[0]
		var starts:Array=[]
		for entry in pen.pigs:starts.append(entry.node.position)
		var travel:=[0.0,0.0,0.0]
		for f in range(3000):
			game.world.animate(.02,Vector3(99,0,99),game.state)
			for entry in pen.pigs:
				var p:Vector3=entry.node.position
				assert(p.is_finite() and absf(p.x)<2.3 and absf(p.z)<1.5)
				travel[entry.slot]=maxf(travel[entry.slot],p.distance_to(starts[entry.slot]))
		for distance in travel:assert(distance>.15,"Each pig needs a real walk")
		game.state.elapsed=240
		var stops:Array=[]
		for entry in pen.pigs:stops.append(entry.node.transform)
		var cow:Dictionary=game.world.cows[0];var stop:Vector3=cow.node.position
		for f in range(500):game.world.animate(.02,Vector3(99,0,99),game.state)
		for entry in pen.pigs:assert(entry.node.transform==stops[entry.slot],"Night rest must stop travel")
		assert(cow.node.position==stop)
		# Raul retains priority over rest and still reaches his milking dock.
		cow.attending=true
		for f in range(1200):game.world.animate(.02,Vector3(99,0,99),game.state)
		assert(cow.dock_ready);cow.attending=false
		# Temporary falls must not be overwritten by the new routines.
		var pig:Node3D=pen.pigs[0].node;pig.set_meta("temporary_down",true)
		var down:=pig.transform;game.state.elapsed=0
		for f in range(100):game.world.animate(.02,Vector3(99,0,99),game.state)
		assert(pig.transform==down);pig.set_meta("temporary_down",false)
	# Final photographs use unrotated enclosures, comfortable animals and fixed clock.
	for item in game.state.items:item.turn=0
	game.world.rebuild(game.state);game.world.update_animals(game.state)
	for f in range(400):game.world.animate(.02,Vector3(99,0,99),game.state)
	for i in range(3):
		var item:Dictionary=game.state.items[i]
		game.camera.position=Vector3(item.x+7,6,item.z+9);game.camera.look_at(Vector3(item.x,.7,item.z))
		await capture("day-%d"%i)
	game.state.elapsed=240;game.world.day_night.update_cycle(240,Vector3(13,0,0))
	for f in range(600):game.world.animate(.02,Vector3(99,0,99),game.state)
	await capture("night-pigs")
	game.hud.show();game.selected=1;game._action("animal:open")
	root.size=Vector2i(1920,1080);await capture("care-1080")
	game.session_started=false;game.audio.set_process(false);game.audio.stop_all();game.queue_free();await process_frame;await create_timer(.2).timeout
	print("ANIMAL_LIFE_OK: nearby on-foot care, save failure rollback, all panels, reload, four rotations, three pigs walking, night rest, Raul and down pose priority")
	quit()
