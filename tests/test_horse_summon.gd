extends SceneTree
var game:Node3D
func _initialize() -> void:call_deferred("run")
func summon(start:Vector2,target:Vector2,label:String) -> void:
	var c:FarmCompanions=game.companions;var h:FarmHorse=game.horse
	c.reset();h.restore({"x":start.x,"z":start.y,"angle":0.0})
	game.player.position=Vector3(target.x,FarmLandscape.height_at(target),target.y)
	await physics_frame;await physics_frame
	assert(c.apply(1,"whistle"),"Long whistle rejected")
	var crossed:=false
	var max_step:=0.0
	for i in range(24000):
		var before:=h.position
		c.update_follow(.1);h.life.update(h,.1,true,game.state,game.world.landscape,game.player)
		max_step=maxf(max_step,h.position.distance_to(before))
		assert(h.position.distance_to(before)<1.1,"Horse teleported")
		assert(not FarmRegion.water_blocked(Vector2(h.position.x,h.position.z)),"Horse walked into water")
		if FarmRegion.on_bridge(Vector2(h.position.x,h.position.z)):crossed=true
		if i%500==0:print(label," step ",i," at ",h.position," pending ",c.horse_route.pending," visited ",c.horse_route.closed.size()," path ",h.life.call_path.size()," avoid ",c.horse_avoid.size())
		if c.horse_owner==0 or c.horse_waiting_notice:
			print("ARRIVED ",label," at ",h.position," target ",target," bridge ",crossed," max step ",max_step)
			assert(Vector2(h.position.x,h.position.z).distance_to(c.horse_meeting)<1)
			if label in ["mountain","farm_stream"]:assert(crossed,"Did not cross river bridge")
			return
		if i%60==0:await process_frame
	assert(false,"Horse failed arrival: "+label+" at "+str(h.position))
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	game=load("res://scenes/main.tscn").instantiate();game.save_path="user://long_whistle.json";root.add_child(game);await process_frame
	game.qa_mode=true;game.set_process(false);game.set_physics_process(false);game.companions.set_process(false)
	game.session_started=true;game.build_mode=false;game.hud.close_modal()
	RenderingServer.set_render_loop_enabled(false)
	await summon(Vector2(160,-20),Vector2(705,-325),"mountain")
	await summon(Vector2(game.horse.position.x,game.horse.position.z),Vector2(285,260),"swimmer")
	# After waiting at shore, the original call follows the owner out of water.
	assert(game.companions.horse_owner==1 and game.companions.horse_waiting_notice)
	game.player.position=Vector3(280,FarmLandscape.height_at(Vector2(280,306)),306)
	for i in range(1500):
		game.companions.update_follow(.1);game.horse.life.update(game.horse,.1,true,game.state,game.world.landscape,game.player)
		if game.companions.horse_owner==0:break
		if i%60==0:await process_frame
	assert(game.companions.horse_owner==0,"Waiting horse did not follow owner back onto land")
	await summon(Vector2(game.horse.position.x,game.horse.position.z),Vector2(900,-272),"mine")
	await summon(Vector2(-58,-80),Vector2(-20,-70),"farm_stream")
	var c:FarmCompanions=game.companions;var h:FarmHorse=game.horse
	c.reset();c.last_request.clear();game.player.position=Vector3(160,2,-20)
	assert(c.apply(1,"whistle"));h.mounted=true;c.update_follow(.1)
	assert(c.horse_owner==0 and not h.life.calling and h.life.call_path.is_empty());h.mounted=false
	print("LONG_WHISTLE_OK: mountain, bridge, dry lake shore, mine entrance, no teleport, mounted cancellation")
	game.session_started=false;game.queue_free();await process_frame;quit()
