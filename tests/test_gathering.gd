extends SceneTree
var game:Node3D
func _initialize() -> void:call_deferred("run")
func move_to(at:Vector2) -> void:
	game.player.position=Vector3(at.x,FarmLandscape.height_at(at)+.1,at.y)
	game.player.velocity=Vector3.ZERO
func allow() -> void:game.gathering.last_request.clear()
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	game=load("res://scenes/main.tscn").instantiate();game.save_path="user://gathering_solo.json";root.add_child(game);await process_frame
	game.qa_mode=true;game.set_process(false);game.set_physics_process(false)
	game.session_started=true;game.build_mode=false;game.hud.close_modal()
	game.state=FarmState.new();game.state.claim(Vector2(4,0));game.state.unlimited_money=true
	var g:FarmGathering=game.gathering;g.set_process(false);g.reset()
	assert(g.apply(1,"resource:buy:rod").contains("concluída"));allow()
	assert(g.apply(1,"resource:buy:pickaxe").contains("concluída"));allow()
	assert(not g.apply(1,"resource:buy:mine").contains("concluída"));allow()
	move_to(FarmResourceSites.MINE_AT)
	assert(g.apply(1,"resource:buy:mine").contains("concluída"));allow()
	move_to(FarmResourceSites.FISH_SPOTS[0])
	var before:Dictionary=game.state.resources.duplicate(true)
	assert(g.apply(1,"gather:fish:0").is_empty())
	g._process(7.9);assert(game.state.resources==before and g.jobs.has(1))
	g._process(.2);assert(game.state.resources!=before and g.jobs.is_empty())
	var reward:Dictionary=game.state.resources.duplicate(true)
	g._process(100);assert(game.state.resources==reward)
	allow();assert(g.apply(1,"gather:fish:0").is_empty())
	game.player.position.x+=1.5;g._process(10)
	assert(g.jobs.is_empty() and game.state.resources==reward)
	move_to(FarmResourceSites.FISH_SPOTS[0]);allow();assert(g.apply(1,"gather:fish:0").is_empty())
	game.actor.airborne=true;g._process(.1);game.actor.airborne=false
	assert(g.jobs.is_empty() and game.state.resources==reward)
	allow();assert(g.apply(1,"gather:fish:0").is_empty())
	game.hud.modal_kind="menu";g._process(10);game.hud.close_modal()
	assert(g.jobs.is_empty() and game.state.resources==reward)
	move_to(FarmResourceSites.ORE_SPOTS[0]);allow();assert(g.apply(1,"gather:mine:0").is_empty())
	g._process(4.9);assert(game.state.resources==reward)
	g._process(.2);assert(g.jobs.is_empty() and game.state.resources!=reward)
	allow();assert(not g.apply(1,"gather:mine:0").is_empty())
	allow();assert(not g.apply(1,"gather:finish:0").is_empty())
	move_to(FarmResourceSites.FISH_SPOTS[0]);allow();assert(g.apply(1,"gather:fish:0").is_empty())
	reward=game.state.resources.duplicate(true)
	var path:String=game.save_path;game.save_path="user://missing_folder/no.json"
	g._process(9);game.save_path=path
	assert(g.jobs.is_empty() and game.state.resources==reward,"Failed save must roll back reward")
	allow();assert(g.apply(1,"gather:fish:0").is_empty())
	game.state=FarmState.new();g._process(10);assert(g.jobs.is_empty())
	game.session_started=false;game.audio.set_process(false);game.audio.stop_all();await create_timer(.2).timeout
	game.queue_free();await process_frame;await create_timer(.2).timeout
	print("GATHERING_OK: timed rewards, no early/duplicate reward, movement/jump/menu cancellation, ownership/proximity, cooldown, save rollback and state replacement")
	quit()
