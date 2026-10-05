extends SceneTree
## Rebuild catalog thumbnails directly from the approved Blender exports.
func _initialize() -> void:call_deferred("run")
func run() -> void:
	assert(DisplayServer.get_name()!="headless")
	root.size=Vector2i(256,256);root.transparent_bg=true
	var stage:=Node3D.new();root.add_child(stage)
	var environment:=WorldEnvironment.new();var env:=Environment.new()
	env.background_mode=Environment.BG_CLEAR_COLOR
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color("d5e6db");env.ambient_light_energy=.3
	env.reflected_light_source=Environment.REFLECTION_SOURCE_DISABLED
	environment.environment=env;stage.add_child(environment)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-48,-35,0)
	sun.light_color=Color("fff1d5");sun.light_energy=.55;stage.add_child(sun)
	var camera:=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	stage.add_child(camera);camera.current=true
	var paths:Dictionary={"house":"farm_house_starter","barn":"farm_art_barn_starter","fence":"farm_art_fence_rustic"}
	for key in ["fence_painted","gate_rustic","gate_painted","well","wash_tub","raised_bed","trellis","orchard_young","orchard_mature","compost","produce_crates"]:paths[key]="farm_art_"+key
	for key in paths:
		var model:Node3D=load("res://assets/models/%s.glb"%paths[key]).instantiate();stage.add_child(model)
		var bounds:=AABB();var first:=true
		for mesh:MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
			var box:AABB=mesh.global_transform*mesh.get_aabb()
			bounds=box if first else bounds.merge(box);first=false
		var center:=bounds.get_center()
		camera.position=center+Vector3(6,4.5,8).normalized()*20;camera.look_at(center)
		camera.size=maxf(bounds.size.length()*.95,1)
		await process_frame;await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://assets/ui/build/%s.png"%key)
		model.free()
	print("FARM_ART_ICONS_OK: 14 catalog thumbnails")
	quit()
