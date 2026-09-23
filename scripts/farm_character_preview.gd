class_name FarmCharacterPreview
extends SubViewportContainer
## Full-body 3D portrait with the exact playable model and idle/blink animation.
var character_id:="farmer"
var actor:FarmAvatar
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE;stretch=true
	var viewport:=SubViewport.new();viewport.size=Vector2i(360,400)
	viewport.transparent_bg=true;viewport.own_world_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_WHEN_VISIBLE
	viewport.msaa_3d=Viewport.MSAA_2X;add_child(viewport)
	var stage:=Node3D.new();viewport.add_child(stage)
	var environment:=WorldEnvironment.new();var settings:=Environment.new()
	settings.background_mode=Environment.BG_COLOR;settings.background_color=Color(0,0,0,0)
	settings.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color=Color("fff3df");settings.ambient_light_energy=.65
	settings.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	environment.environment=settings;stage.add_child(environment)
	var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-35,-30,0);light.light_energy=.9;stage.add_child(light)
	var fill:=DirectionalLight3D.new();fill.rotation_degrees=Vector3(-20,145,0);fill.light_energy=.35;stage.add_child(fill)
	var model:=FarmCharacters.instantiate_model(character_id);stage.add_child(model);model.rotation.y=-.20
	actor=FarmAvatar.new();actor.setup(model)
	var camera:=Camera3D.new();stage.add_child(camera)
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=2.85
	camera.position=Vector3(0,1.35,5);camera.look_at(Vector3(0,1.23,0));camera.current=true
func _process(delta:float) -> void:
	if actor and is_visible_in_tree():actor.animate(minf(delta,.05),false,false)
