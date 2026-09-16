class_name FarmFeedback
extends Node3D
## Short-lived visual effects, independent of simulation time and saved data.

var world: FarmWorld
var rng:=RandomNumberGenerator.new()
var water_mesh:=SphereMesh.new()
var water_material: StandardMaterial3D

func setup(farm_world: FarmWorld) -> void:
	world=farm_world
	rng.seed=104
	water_mesh.radius=0.035
	water_mesh.height=0.11
	water_mesh.radial_segments=6
	water_mesh.rings=3
	water_material=world.material("75d7ec")
	water_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED

func floating_text(at: Vector3, text: String, color: Color) -> void:
	var label:=Label3D.new()
	label.text=text
	label.font_size=46
	label.pixel_size=0.009
	label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate=color
	label.outline_modulate=Color("294739")
	label.outline_size=9
	label.position=at+Vector3(0,1.2,0)
	add_child(label)
	var tween:=create_tween().set_parallel()
	tween.tween_property(label,"position:y",label.position.y+1.3,1.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label,"modulate:a",0.0,0.6).set_delay(0.8)
	tween.tween_property(label,"outline_modulate:a",0.0,0.6).set_delay(0.8)
	tween.finished.connect(label.queue_free)

func water(at: Vector3, origin: Vector3, overhead: bool) -> void:
	floating_text(at,"Regado!",Color("9ee4ef"))
	if overhead:
		var can:=world.model("watering_can",self,at+Vector3(-0.45,1.2,-0.3))
		can.rotation.z=-0.3
		var fade:=create_tween()
		fade.tween_property(can,"scale",Vector3.ONE*0.01,0.2).set_delay(0.65)
		fade.finished.connect(can.queue_free)
		origin=can.position+Vector3(0,0.2,0.5)
	for i in range(26):
		var drop:=MeshInstance3D.new()
		drop.mesh=water_mesh
		drop.material_override=water_material
		drop.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		drop.visible=false
		add_child(drop)
		var end:=at+Vector3(rng.randf_range(-0.8,0.8),0.15,rng.randf_range(-0.8,0.8))
		var start:=origin+Vector3(rng.randf_range(-0.1,0.1),0,0)
		var duration:=rng.randf_range(0.32,0.48)
		var tween:=create_tween()
		tween.tween_interval(i*0.015)
		tween.tween_callback(func(): drop.visible=true)
		tween.tween_method(func(t: float): drop.position=start.lerp(end,t)+Vector3.UP*sin(t*PI)*0.18,0.0,1.0,duration)
		tween.tween_callback(drop.queue_free)

func harvest(at: Vector3, crop: String) -> void:
	floating_text(at,"+3 "+FarmState.CROPS[crop].name,Color("ffde7c"))
	for i in range(3):
		var product:=world.model("harvest_"+crop,self,at+Vector3((i-1)*0.4,0.2,0))
		var start:=product.position
		var end:=at+Vector3((i-1)*0.65,0.4,0.5)
		var tween:=create_tween()
		tween.tween_method(func(t: float):
			product.position=start.lerp(end,t)+Vector3.UP*sin(t*PI)*1.5
			product.rotation.y=t*4+i
			product.scale=Vector3.ONE*(1.0-clampf((t-0.7)/0.3,0,1))
		,0.0,1.0,0.85+i*0.08)
		tween.tween_callback(product.queue_free)

func planted(at: Vector3) -> void:
	floating_text(at,"Sementes no chão",Color("d7ebb4"))
