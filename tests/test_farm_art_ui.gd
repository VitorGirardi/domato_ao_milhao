extends SceneTree

var game:Node3D

func _initialize() -> void:
	call_deferred("run")

func capture(key:String) -> void:
	if DisplayServer.get_name()=="headless": return
	game.hud.toast_time=0
	await create_timer(0.15).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/farm-art-ui-"+key+".png")

func mesh_bounds(node:Node,relative:Node3D) -> AABB:
	var result:=AABB()
	for child in node.get_children():
		if child is MeshInstance3D:
			var box:AABB=relative.global_transform.affine_inverse()*child.global_transform*child.get_aabb()
			result=box if result.size==Vector3.ZERO else result.merge(box)
		var descendants:=mesh_bounds(child,relative)
		if descendants.size!=Vector3.ZERO: result=descendants if result.size==Vector3.ZERO else result.merge(descendants)
	return result

func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	game=load("res://scenes/main.tscn").instantiate()
	game.save_path="user://qa_farm_art_ui.json";game.qa_mode=true
	root.add_child(game);await process_frame
	game.set_process(false);game.set_physics_process(false)
	game.session_started=true;game.hud.close_modal();game.build_mode=true
	game.state=FarmState.new_farm("sandbox")
	assert(game.state.claim(Vector2(4,-2)).is_empty())
	game.state.land_size=40
	assert(game.state.place("house",Vector2(0,-4),0).is_empty())
	game.world.rebuild(game.state)
	game.tool="inspect";game.selected=0
	game.camera.position=Vector3(-18,27,35);game.camera.look_at(Vector3(4,0,-2))
	game._update_ui()
	var menu:FarmBuildHUD=game.hud.construction
	var reachable:Dictionary={}
	for title in FarmBuildHUD.CATEGORIES:
		menu._choose_category(title)
		while true:
			for key in menu.cards: reachable[key]=true
			await capture("catalog-"+str(FarmBuildHUD.CATEGORIES.keys().find(title))+"-"+str(menu.page))
			if menu.next_page.disabled: break
			menu._turn_page(1)
	for key in FarmState.ITEMS: assert(reachable.has(key),"Missing catalog item: "+key)
	game.selected=0;game.tool="inspect";game._update_ui()
	assert(menu.open_button.visible)
	game._action("build:open")
	assert(game.hud.modal_kind=="house")
	await capture("house-starter")
	game._action("evolution:0")
	assert(game.hud.modal_kind=="evolution")
	await capture("house-evolution")
	game._action("building_back")
	assert(game.hud.modal_kind=="house" and game.state.items[0].level==1)
	game._action("evolution:0");game._action("evolution_buy:0")
	assert(game.state.items[0].level==2 and game.hud.modal_kind=="house")
	await capture("house-upgraded")
	game.hud.close_modal();game.selected=0;game._action("move")
	game._preview("house")
	assert(game.move_index==0)
	var box:=mesh_bounds(game.ghost,game.ghost)
	assert(box.size.x>7.0 and box.size.x<8.01 and box.size.z<8.01,"Move preview must use upgraded house")
	assert(box.position.z>=-4.01 and box.end.z<=4.01,"Move preview must preserve house ground offset")
	game._action("build:clear")
	game._action("tool:fence_painted")
	assert(menu.cards.has("fence_painted"))
	game.pointer=Vector2(-12,12);game.pointer_valid=true;game.turn=0
	game._begin_route();game.pointer=Vector2(-6,12);game._update_route()
	assert(game.route.size()==4)
	game._finish_route()
	game._action("route_confirm")
	assert(game.state.count_items("fence_painted")==4)
	await capture("painted-fence-route")
	print("FARM_ART_UI_OK: all catalog items, pages, house upgrade/back, upgraded move preview, painted fence route")
	game.session_started=false;game.audio.stop_all();game.queue_free()
	await process_frame;await create_timer(0.2).timeout
	quit()
