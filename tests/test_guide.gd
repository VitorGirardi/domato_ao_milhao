extends SceneTree
var game:Node3D
func _initialize() -> void:call_deferred("run")
func find_row(s:FarmState,key:String) -> Dictionary:
	for row in FarmGuide.entries(s):
		if row.key==key:return row
	assert(false,"Missing guide row: "+key);return {}
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	var s:=FarmState.new()
	var before:=JSON.stringify(s.serialize())
	assert(FarmGuide.select_rows(s,"next").size()==3)
	assert(FarmGuide.select_rows(s,"next")[0].key=="start_land")
	assert(not find_row(s,"garage").ready)
	assert(find_row(s,"garage").detail.contains("nível 4"))
	assert(JSON.stringify(s.serialize())==before,"Advice must never mutate farm state")
	s.claimed=true;s.farm_xp=280;s.money=0
	assert(find_row(s,"garage").detail.contains("Faltam $700"))
	s.money=700;assert(find_row(s,"garage").ready)
	s.items.append({"kind":"garage","x":0,"z":0,"turn":0})
	assert(find_row(s,"garage").done)
	assert(not find_row(s,"truck_tires").ready)
	s.resources.stock.copper=8;assert(find_row(s,"truck_tires").ready)
	s.game_mode="sandbox";s.unlimited_money=true
	assert(find_row(s,"truck_engine").ready)
	assert(find_row(s,"truck_engine").detail.contains("Sandbox"))
	s.resources.rod=true;s.resources.caught=1
	assert(find_row(s,"fish").done)
	for row in FarmGuide.select_rows(s,"done"):assert(row.done)
	game=load("res://scenes/main.tscn").instantiate();game.save_path="user://guide.json";root.add_child(game);await process_frame
	game.qa_mode=true;game.set_process(false);game.set_physics_process(false);game.weapons.set_physics_process(false)
	game.session_started=true;game.build_mode=false;game.hud.close_modal()
	game._action("guide");assert(game.hud.modal_kind=="guide")
	assert(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE)
	game._action("guide:pin:garage");assert(game.hud.modal_kind.is_empty())
	assert(game.hud.guide.pinned=="garage" and game.hud.guide.tracker.visible)
	game._action("guide");game._action("guide:tab:all")
	for i in range(12):game._action("guide:page:1")
	assert(game.hud.guide.page==ceili(FarmGuide.entries(game.state).size()/3.0)-1)
	game._action("guide:page:100");assert(game.hud.modal_kind=="guide")
	game._action("guide:tab:next");assert(game.hud.guide.page==0)
	if DisplayServer.get_name()!="headless":
		await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://test-results/guide-next.png")
	game._action("guide:tab:all");game._action("guide:page:3")
	if DisplayServer.get_name()!="headless":
		await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://test-results/guide-workshop.png")
	game._action("guide:open:mine");assert(game.hud.modal_kind.is_empty())
	assert(game.navigator.waypoint==FarmResourceSites.MINE_AT)
	game.state.claimed=true;game.state.farm_xp=280;game.state.money=1000
	var money:int=game.state.money
	game._action("guide");game._action("guide:open:garage")
	assert(game.build_mode and game.tool=="garage")
	assert(game.state.money==money and game.state.count_items("garage")==0,"Guidance must not buy a building")
	game._action("guide");game._action("guide:pin:garage")
	game._action("guide");game._action("guide:pin:garage")
	assert(game.hud.guide.pinned=="garage")
	game.build_mode=false;game._update_ui()
	if DisplayServer.get_name()!="headless":
		await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://test-results/guide-tracking.png")
	game.build_mode=true;game._action("guide");assert(game.hud.modal_kind=="guide")
	game.hud.guide.update(FarmState.new());assert(game.hud.guide.pinned.is_empty())
	game.session_started=false;game.audio.stop_all();await create_timer(.2).timeout
	game.queue_free();await process_frame;await create_timer(.2).timeout
	print("GUIDE_OK: read-only advice, unlocks, money, stock, sandbox, completed, paging, tracking, map, camera and construction")
	quit()

