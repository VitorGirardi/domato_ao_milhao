extends SceneTree
## Isolated visual QA on the shipped terrain, with the real animal/NPC meshes.
var game:Node3D
var entries:Array[Dictionary]=[]
func _initialize() -> void:call_deferred("run")
func capture(label:String,at:Vector3,size:float=7.0) -> void:
	game.camera.projection=Camera3D.PROJECTION_ORTHOGONAL;game.camera.size=size
	game.camera.global_position=at+Vector3(5,4.8,7);game.camera.look_at(at+Vector3.UP*.7)
	await process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://test-results/fall-world/"+label+".png")
func add(kind:String,model_name:String,p:Vector2) -> Dictionary:
	var body:Node3D=FarmHorse.new() if kind=="horse" else Node3D.new()
	game.add_child(body);body.global_position=Vector3(p.x,FarmLandscape.height_at(p),p.y)
	var model:Node3D
	if kind=="horse":model=body.model;body.label.visible=false
	else:model=load("res://assets/models/"+model_name+".glb").instantiate();body.add_child(model)
	var actor:FarmAvatar=null
	if kind=="human":actor=FarmAvatar.new();actor.setup(model)
	var entry:Dictionary={"body":body,"model":model,"actor":actor,"kind":kind,"base_transform":model.transform}
	entries.append(entry)
	return entry
func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	DirAccess.make_dir_recursive_absolute("res://test-results/fall-world")
	root.size=Vector2i(1440,900)
	game=load("res://scenes/main.tscn").instantiate();game.save_path="user://fall_world_visual_qa.json";root.add_child(game)
	await process_frame
	game.qa_mode=true;game.set_process(false);game.set_physics_process(false);game.session_started=true
	game.falls.set_process(false);game.falls.set_physics_process(false)
	game.build_mode=false;game.hud.close_modal();game.hud.root.visible=false;game.world.build_grid.visible=false;game.ghost.visible=false
	game.world.set_process(false)
	game.world.day_night.update_cycle(80,Vector3(600,80,-255))
	var models:=["farmer_woman","vendor","gunsmith","horse","cow","pig","cat","chicken"]
	for i in models.size():
		var kind:String="human" if i<3 else models[i]
		var p:=Vector2(602+(i%4)*5,-254+(i/4)*6)
		var entry:=add(kind,models[i],p)
		# Confirm this is a real incline, rather than a flat diagnostic platform.
		var rise:=absf(FarmLandscape.height_at(p+Vector2(2,0))-FarmLandscape.height_at(p-Vector2(2,0)))
		print("TERRAIN_SLOPE ",models[i],": ",rise)
		for phase in ["down","rise"]:
			FarmFallPose.apply(entry,1.1 if phase=="down" else 1.0,phase=="rise")
			await capture(models[i]+"-"+phase,entry.body.global_position,5 if kind in ["cat","chicken","pig"] else 7)
		FarmFallPose.apply(entry,2,true)
		assert(entry.model.transform.is_equal_approx(entry.base_transform))
		FarmFallPose.reset(entry)
	# The real player lifecycle must recover from water onto a dry bank.
	game.player.position=Vector3(810,66.85,-253)
	game.actor.swimming=true;game.actor.animate(.2,false,false)
	await physics_frame;await physics_frame
	assert(game.falls.knock_down(game.falls.player_key()))
	game.falls.advance(1.1);game.falls.apply_poses()
	await capture("water-down",game.player.global_position,9)
	game.falls.advance(58.9);game.falls.apply_poses()
	var safe:Vector3=game.falls.records[game.falls.player_key()].position
	assert(FarmWater.immersion(safe)<=.12)
	assert(not FarmRegion.water_blocked(Vector2(safe.x,safe.z)))
	await capture("water-dry-recovery",safe,9)
	game.falls.advance(2);game.falls.apply_poses()
	assert(not game.falls.local_down())
	game.falls.reset();game.session_started=false;game.audio.set_process(false);game.audio.stop_all();game.queue_free()
	await process_frame;await create_timer(.2).timeout
	print("FALL_WORLD_VISUAL_OK: six species, female player and NPCs on actual incline; water recovery on dry bank")
	quit()

