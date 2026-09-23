extends SceneTree
## Visual asset contract and optional six-second preview, no game/save instance.
var pen:Node3D
var camera:Camera3D
var pigs:Array[Node3D]=[]

func _initialize() -> void:call_deferred("run")

func capture(label:String) -> void:
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/pigsty/"+label+".png")

func check_meshes(model:Node3D) -> void:
	var surfaces:=0
	for mesh in model.find_children("*","MeshInstance3D",true,false):
		assert(mesh.transform.is_finite())
		assert(mesh.mesh.get_aabb().size.length()>0)
		surfaces+=mesh.mesh.get_surface_count()
		for i in range(mesh.mesh.get_surface_count()):assert(mesh.mesh.surface_get_material(i)!=null)
	assert(surfaces>0 and surfaces<=55,"Static pieces must be batched for the game")

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://test-results/pigsty")
	root.mode=Window.MODE_WINDOWED;root.size=Vector2i(1440,900)
	var stage:=Node3D.new();root.add_child(stage)
	var env:=WorldEnvironment.new();env.environment=Environment.new()
	env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("b4c7be")
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color=Color("dee7d4");env.environment.ambient_light_energy=.4
	stage.add_child(env)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-48,-32,0)
	sun.light_energy=.65;sun.light_color=Color("fff2d5");sun.shadow_enabled=true;stage.add_child(sun)
	var ground:=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=Vector2(200,200);ground.mesh=plane
	var mat:=StandardMaterial3D.new();mat.albedo_color=Color("82966C");ground.material_override=mat;stage.add_child(ground)
	pen=load("res://assets/models/pigsty.glb").instantiate();stage.add_child(pen);check_meshes(pen)
	for mesh in pen.find_children("*","MeshInstance3D",true,false):
		var bounds:AABB=mesh.mesh.get_aabb()
		for corner in range(8):
			var point:Vector3=pen.to_local(mesh.to_global(bounds.get_endpoint(corner)))
			assert(absf(point.x)<=4.0 and absf(point.z)<=3.0 and point.y<=2.6,"Geometry must fit the reserved footprint and shelter height")
	for name in ["GateHinge","GateLeaf","FeedTrough","FeedFill","WaterTrough","WaterFill","PigShelter","MudPatch","PigSpawn1","PigSpawn2","PigSpawn3","GateApproach"]:
		assert(pen.find_child(name,true,false)!=null,name)
	for key in ["pig_feeder","pig_waterer","pig_mud","pig_shelter"]:
		var model:Node3D=load("res://assets/models/"+key+".glb").instantiate()
		check_meshes(model);model.free()
	for index in range(3):
		var pig:Node3D=load("res://assets/models/pig.glb").instantiate();stage.add_child(pig)
		pig.position=pen.find_child("PigSpawn%d"%(index+1),true,false).global_position
		pig.rotation.y=[-.55,.7,.25][index];pigs.append(pig)
	camera=Camera3D.new();stage.add_child(camera);camera.position=Vector3(10,8.5,12)
	camera.look_at(Vector3(0,.6,0));camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=11.5
	await capture("closed")
	var hinge:=pen.find_child("GateHinge",true,false) as Node3D
	var leaf:=pen.find_child("GateLeaf",true,false) as Node3D
	assert(leaf.get_parent()==hinge)
	var original_pen:=pen.transform
	var feed:=pen.find_child("FeedFill",true,false) as Node3D
	var water:=pen.find_child("WaterFill",true,false) as Node3D
	var film:bool="--pigsty-film" in OS.get_cmdline_user_args()
	for frame in range(180):
		var time:=frame/30.0
		hinge.rotation.y=-smoothstep(.7,2.1,time)*PI*.5
		for index in range(3):FarmLivestockPose.pig(pigs[index],time+index*1.7)
		assert(pen.transform==original_pen,"Gate animation must not move the enclosure")
		if film:await capture("frame-%03d"%frame)
	await capture("open")
	for fill in [feed,water]:fill.scale.y=.15
	await capture("low-supplies")
	for fill in [feed,water]:fill.visible=false
	await capture("empty-supplies")
	assert(pen.find_child("FeedTroughStatic",true,false).visible)
	assert(pen.find_child("WaterTroughStatic",true,false).visible)
	for fill in [feed,water]:fill.visible=true;fill.scale.y=1.0
	camera.position=Vector3(-10,6.5,9);camera.look_at(Vector3(-.3,.7,0));await capture("reverse")
	stage.queue_free();await process_frame
	print("PIGSTY_ASSETS_OK: five imports, batched materials, articulated gate, independent supplies, stable markers and pig preview")
	quit()
