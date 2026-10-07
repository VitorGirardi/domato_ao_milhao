extends SceneTree
var game:Node3D
func _initialize() -> void:call_deferred("run")
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	game=load("res://scenes/main.tscn").instantiate();game.save_path="user://cave_world.json";root.add_child(game);await process_frame
	game.qa_mode=true;game.set_process(false);game.set_physics_process(false);game.session_started=true;game.build_mode=false
	game.state=FarmState.new_farm("sandbox");game.state.claim(Vector2(4,0));game.world.rebuild(game.state)
	game.hud.close_modal();game.gathering.set_process(false)
	var life:FarmCaveLife=game.resource_view.get_node("CaveLife");life.set_process(false)
	for i in range(3):
		game.player.position=FarmResourceSites.point(FarmCaveCrew.DENS[i])+Vector3(0,.1,1)
		assert(FarmCaveActions.nearby(game).value=="cave:open:%d"%i)
		game._action("cave:open:%d"%i);assert(game.hud.modal_kind=="cave_helper")
		var original:Dictionary=game.state.serialize();var path:String=game.save_path;game.save_path="user://missing_cave/fail.json"
		game._action("cave:recruit:%d"%i);assert(game.state.serialize()==original)
		game.save_path=path;game._action("cave:recruit:%d"%i);assert(game.state.cave_crew[i].joined)
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://test-results/cave-panel-%d.png"%i)
		game.hud.close_modal()
		var actor:=life.creatures[i]
		for step in range(7200):
			FarmCaveCrew.tick(game.state,1.0/60)
			var previous:=actor.root.position
			life._process(1.0/60)
			assert(actor.root.position.distance_to(previous)<=.013,"No teleport during transitions")
			assert(absf(actor.root.position.y-FarmResourceSites.point(Vector2(actor.root.position.x,actor.root.position.z)).y)<.01)
		assert(game.state.cave_crew[i].produced>=1 and actor.root.position.distance_to(FarmResourceSites.point(FarmCaveCrew.DENS[i]))<.2)
	game._action("resources")
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://test-results/cave-stock.png")
	var before:Dictionary=game.state.serialize()
	game.player.position=Vector3.ZERO;game._action("cave:feed:0");assert(game.state.serialize()==before)
	game.session_started=false;game.audio.set_process(false);game.audio.stop_all();game.queue_free();await process_frame
	print("CAVE_WORLD_OK: nearby panels, solo save rollback, continuous grounded work cycles, rare stock UI and remote rejection")
	quit()
