extends SceneTree
## No player saves: standalone visual stage plus real FarmWorld regression.
var stage:Node3D
var cow:Node3D
var hen:Node3D
var pig:Node3D
var cow_data:Dictionary

func _initialize() -> void:call_deferred("run")

func capture(label:String) -> void:
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/livestock/"+label+".png")

func run() -> void:
	assert(OS.get_user_data_dir().contains("test-results"))
	DirAccess.make_dir_recursive_absolute("res://test-results/livestock")
	root.mode=Window.MODE_WINDOWED;root.size=Vector2i(1280,720)
	stage=Node3D.new();root.add_child(stage)
	var env:=WorldEnvironment.new();env.environment=Environment.new()
	env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("bacdc2")
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color=Color("dee7d4");env.environment.ambient_light_energy=.4
	stage.add_child(env)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-45,-35,0);sun.light_energy=.65;sun.shadow_enabled=true;stage.add_child(sun)
	var ground:=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=Vector2(200,200);ground.mesh=plane
	var mat:=StandardMaterial3D.new();mat.albedo_color=Color("849566");ground.material_override=mat;stage.add_child(ground)
	var camera:=Camera3D.new();stage.add_child(camera);camera.position=Vector3(5,3.2,7);camera.look_at(Vector3(0,.85,.4));camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=6.6
	cow=load("res://assets/models/cow.glb").instantiate();stage.add_child(cow);cow.position=Vector3(-1.55,0,-.3)
	hen=load("res://assets/models/chicken.glb").instantiate();stage.add_child(hen);hen.position=Vector3(.2,0,1.25)
	pig=load("res://assets/models/pig.glb").instantiate();stage.add_child(pig);pig.position=Vector3(1.4,0,.2)
	var bones:Dictionary={}
	for key in ["CowHead","CowNeck","CowTail","LegFL","LegFR","LegBL","LegBR"]:
		var joint:=cow.find_child(key,true,false) as Node3D;assert(joint!=null,key)
		bones[key]={"node":joint,"rest":joint.basis}
	for key in ["CowJaw","CowEarL","CowEarR"]:assert(cow.find_child(key,true,false)!=null,key)
	cow_data={"node":cow,"bones":bones}
	FarmCowMotion.setup(cow_data,stage);cow.position=Vector3(-1.55,0,-.3)
	var coat:=cow.find_child("CowBody",true,false) as MeshInstance3D
	assert(coat.get_active_material(0).vertex_color_use_as_albedo,"Coat colors must survive Godot import")
	var skin:=hen.find_child("HenBody",true,false) as MeshInstance3D
	assert(skin!=null and skin.find_blend_shape_by_name("Peck")>=0)
	var original_hen:=hen.transform;var original_pig:=pig.transform
	for frame in range(360):
		var time:=frame/60.0
		FarmHenMotion.pose(hen,time,1.0/60,false,true)
		FarmLivestockPose.cow(cow,time,0,false);FarmLivestockPose.pig(pig,time)
		assert(hen.transform==original_hen and pig.transform==original_pig,"Presentation must not move authoritative roots")
		for animal in [cow,hen,pig]:
			for node in animal.find_children("*","Node3D",true,false):assert(node.transform.is_finite())
		if frame==0:await capture("idle")
		if frame==127:
			assert(skin.get_blend_shape_value(skin.find_blend_shape_by_name("Peck"))>.65)
			await capture("foraging")
		if frame==240:await capture("rest")
		if "--livestock-film" in OS.get_cmdline_user_args() and frame%2==0:await capture("frame-%03d"%(frame/2))
	FarmHenMotion.pose(hen,6,.5,true,false)
	assert(skin.get_blend_shape_value(skin.find_blend_shape_by_name("Peck"))==0,"Walking releases the forage pose")
	# Real pen navigation and milking approach must still settle correctly.
	cow.position=Vector3(0,0,.35)
	for i in range(2400):
		FarmCowMotion.animate(cow_data,1.0/60,Vector3(99,0,99))
		assert(absf(cow.position.x)<1.2 and absf(cow.position.z)<.5)
	cow_data.attending=true
	for i in range(1200):FarmCowMotion.animate(cow_data,1.0/60,Vector3(99,0,99))
	assert(cow_data.dock_ready,"Milking dock remains reachable")
	stage.queue_free();await process_frame
	await world_regression()
	print("LIVESTOCK_POSE_OK: stable nodes, finite poses, root isolation, forage transition and milking dock")
	quit()

func world_regression() -> void:
	var game:Node3D=load("res://scenes/main.tscn").instantiate();game.save_path="user://qa_livestock.json";root.add_child(game)
	await process_frame;game.set_process(false);game.set_physics_process(false);game.audio.set_process(false)
	game.state=FarmState.new();game.state.unlimited_money=true;game.state.claim(Vector2(4,-2));game.state.land_size=40;game.state.farm_xp=950
	assert(game.state.place("coop",Vector2(0,0),0).is_empty())
	assert(game.state.place("corral",Vector2(12,0),0).is_empty());game.state.items[-1].dairy.owned=true
	game.world.rebuild(game.state);game._action("start");game.build_mode=false;game.hud.hide()
	game.world.clock=0.0
	var chicken:Dictionary=game.world.chickens[0]
	var resting_position:Vector3=chicken.node.position
	# Forage phase stays put; inspect/dance override it immediately.
	for i in range(150):game.world.animate(1.0/60,Vector3(99,0,99),game.state)
	assert(chicken.node.position.is_equal_approx(resting_position),"Hen must stand still to forage")
	game.camera.position=Vector3(6,4.1,9);game.camera.look_at(chicken.node.position+Vector3(0,.4,0))
	await capture("farm-hens")
	for i in range(90):game.world.animate(1.0/60,Vector3(6,0,6),game.state,"inspect")
	assert(chicken.node.position.distance_to(resting_position)>.1,"Inspect must override forage pause")
	var skin:=chicken.node.find_child("HenBody",true,false) as MeshInstance3D
	assert(skin.get_blend_shape_value(skin.find_blend_shape_by_name("Peck"))==0)
	var dairy:Dictionary=game.world.cows[0]
	for i in range(480):game.world.animate(1.0/60,Vector3(99,0,99),game.state)
	game.camera.position=dairy.node.global_position+Vector3(4,2.4,5)
	game.camera.look_at(dairy.node.global_position+Vector3(0,1,0));await capture("farm-cow")
	game.session_started=false;game.queue_free();await process_frame;await create_timer(.2).timeout
