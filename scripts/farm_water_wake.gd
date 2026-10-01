class_name FarmWaterWake
extends Node3D
## Pool of surface rings. Call update_at each physics tick; level=-INF dries the wake.
## Uses world coordinates and never changes the actor or water physics.
const POOL_SIZE := 10
const LIFETIME := 1.15
var rings: Array[MeshInstance3D] = []
var ages: PackedFloat32Array = []
var cursor := 0
var emission_wait := 0.0
var previous := Vector3(INF,0,0)

func _ready() -> void:
	_build()

func _build() -> void:
	if not rings.is_empty():return
	var mesh:=ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(40):
		var a:=float(i)*TAU/40.0
		var b:=float(i+1)*TAU/40.0
		var outer_a:=Vector3(cos(a),0,sin(a))
		var outer_b:=Vector3(cos(b),0,sin(b))
		for p in [outer_a*.9,outer_a,outer_b,outer_a*.9,outer_b,outer_b*.9]:
			mesh.surface_set_normal(Vector3.UP);mesh.surface_add_vertex(p)
	mesh.surface_end()
	for i in range(POOL_SIZE):
		var ring:=MeshInstance3D.new();ring.mesh=mesh;ring.visible=false
		var material:=StandardMaterial3D.new()
		material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color=Color(.75,.94,1,.3)
		material.roughness=.6;material.cull_mode=BaseMaterial3D.CULL_DISABLED
		ring.material_override=material;ring.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(ring);rings.append(ring);ages.append(LIFETIME)

func update_at(at:Vector3,level:float,moving:bool,delta:float) -> void:
	_build()
	# A teleport must not leave visual streaks connecting separate water bodies.
	if is_finite(previous.x) and previous.distance_squared_to(at)>144.0:
		for i in range(POOL_SIZE):ages[i]=LIFETIME;rings[i].visible=false
	previous=at
	var dt:=clampf(delta,0.0,.25)
	for i in range(POOL_SIZE):
		ages[i]=minf(LIFETIME,ages[i]+dt)
		var t:=ages[i]/LIFETIME
		rings[i].visible=ages[i]<LIFETIME-.0001
		if not rings[i].visible:continue
		var radius:=lerpf(.28,1.65,t)
		rings[i].scale=Vector3(radius,1,radius)
		var material:StandardMaterial3D=rings[i].material_override
		material.albedo_color.a=sin(t*PI)*.30
	emission_wait=maxf(0.0,emission_wait-dt)
	if not is_finite(level):return
	if emission_wait>0.0:return
	var ring:=rings[cursor]
	ages[cursor]=0.0;ring.global_position=Vector3(at.x,level+.075,at.z)
	ring.scale=Vector3(.28,1,.28);ring.visible=true
	var material:StandardMaterial3D=ring.material_override;material.albedo_color.a=0.0
	cursor=(cursor+1)%POOL_SIZE
	emission_wait=.16 if moving else .7
