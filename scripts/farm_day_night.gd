class_name FarmDayNight
extends Node3D
## One saved clock drives the HUD and lighting, including cooperative snapshots.
const SECONDS_PER_HOUR := 20.0
const DAY_SECONDS := 24.0 * SECONDS_PER_HOUR
const MAX_LOCAL_LIGHTS := 6
var environment: Environment
var sky: ProceduralSkyMaterial
var sun: DirectionalLight3D
var moon := DirectionalLight3D.new()
var lamps: Array[Vector3] = []
var local_lights: Array[OmniLight3D] = []
var lantern_material := StandardMaterial3D.new()
var night_amount := 0.0
var displayed_hour := 8.0
var last_position := Vector3.ZERO

static func hour_at(elapsed: float) -> float:
	return fposmod(8.0 + maxf(0, elapsed) / SECONDS_PER_HOUR, 24.0)

static func day_at(elapsed: float) -> int:
	return 1 + int(floor((maxf(0, elapsed) + 8.0 * SECONDS_PER_HOUR) / DAY_SECONDS))

static func clock_text(elapsed: float) -> String:
	var minutes := int(floor(hour_at(elapsed) * 60.0 + 0.00001)) % 1440
	return "DIA %02d   •   %02d:%02d" % [day_at(elapsed), minutes / 60, minutes % 60]

static func daylight(hour: float) -> float:
	return smoothstep(5.5, 7.5, hour) * (1.0 - smoothstep(17.0, 20.0, hour))

func setup(world: FarmWorld, env: Environment, sky_material: ProceduralSkyMaterial, sunlight: DirectionalLight3D) -> void:
	name = "DayNight"
	environment = env; sky = sky_material; sun = sunlight
	moon.name = "Moonlight"
	moon.rotation_degrees = Vector3(-38, 135, 0)
	moon.light_color = Color("9db9ee")
	moon.shadow_enabled = false
	add_child(moon)
	lantern_material.albedo_color = Color("ffe8ad")
	lantern_material.emission_enabled = true
	lantern_material.emission = Color("ffbd65")
	for i in range(MAX_LOCAL_LIGHTS):
		var light := OmniLight3D.new()
		light.name = "StreetLight%d" % i
		light.light_color = Color("ffcb88")
		light.omni_range = 11.5
		light.omni_attenuation = 1.15
		light.shadow_enabled = false
		add_child(light); local_lights.append(light)
	_build_lamps(world)
	update_cycle(0, Vector3.ZERO)

func _color(hex: String) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(hex); mat.roughness = 0.9
	return mat

func _batch(mesh: Mesh, mat: Material, offset: Vector3) -> void:
	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.mesh = mesh
	instances.instance_count = lamps.size()
	for i in range(lamps.size()):
		instances.set_instance_transform(i, Transform3D(Basis.IDENTITY, lamps[i] + offset))
	var node := MultiMeshInstance3D.new()
	node.multimesh = instances; node.material_override = mat
	add_child(node)

func _cylinder(bottom: float, top: float, height: float) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = bottom; mesh.top_radius = top; mesh.height = height
	mesh.radial_segments = 8; mesh.rings = 1
	return mesh

func _build_lamps(world: FarmWorld) -> void:
	var candidates: Array[Vector2] = []
	# Inside the reserved road shoulders, outside the walking/riding centerline.
	for z in [-36.0, -18.0, 0.0, 20.0, 38.0]: candidates.append(Vector2(-28.7, z))
	for x in [-12.0, 8.0, 28.0]: candidates.append(Vector2(x, 29.0))
	for route in FarmTrails.ROUTES:
		var distance_since := 18.0
		for i in range(route.size()-1):
			var a: Vector2 = route[i]; var b: Vector2 = route[i+1]
			var direction := (b-a).normalized()
			var length := a.distance_to(b)
			while distance_since <= length:
				candidates.append(a + direction * distance_since + Vector2(-direction.y, direction.x) * 2.5)
				distance_since += 26.0
			distance_since -= length
	for p in candidates:
		var blocked := false
		for other in lamps:
			if Vector2(other.x, other.z).distance_to(p) < 13: blocked = true
		for key in FarmParcels.LOTS:
			if FarmParcels.area(key).grow(1).has_point(p): blocked = true
		for area in world.landscape.solid_bounds:
			if area.grow(0.8).has_point(p): blocked = true
		for trunk in world.landscape.trunk_points:
			if trunk.distance_to(p) < 1.6: blocked = true
		if blocked: continue
		var pos := Vector3(p.x, FarmLandscape.height_at(p), p.y)
		lamps.append(pos)
		var body := StaticBody3D.new()
		body.position = pos + Vector3(0, 1.75, 0)
		var collision := CollisionShape3D.new()
		var shape := CylinderShape3D.new()
		shape.radius = 0.20; shape.height = 3.5
		collision.shape = shape; body.add_child(collision); add_child(body)
		# Shared collision/placement/horse safety contract; survives nature clearing.
		world.landscape.solid_bounds.append(Rect2(p-Vector2.ONE*0.22, Vector2.ONE*0.44))
	_batch(_cylinder(0.23, 0.20, 0.45), _color("626555"), Vector3(0, 0.225, 0))
	_batch(_cylinder(0.13, 0.10, 3.05), _color("755537"), Vector3(0, 1.95, 0))
	_batch(_cylinder(0.34, 0.27, 0.13), _color("384b40"), Vector3(0, 3.44, 0))
	_batch(_cylinder(0.23, 0.23, 0.49), lantern_material, Vector3(0, 3.73, 0))
	_batch(_cylinder(0.41, 0.10, 0.23), _color("384b40"), Vector3(0, 4.07, 0))
	var rail := BoxMesh.new(); rail.size = Vector3(0.045, 0.55, 0.045)
	for x in [-0.18, 0.18]:
		for z in [-0.18, 0.18]:
			_batch(rail, _color("384b40"), Vector3(x, 3.74, z))

func update_cycle(elapsed: float, observer: Vector3) -> void:
	if environment == null: return
	last_position = observer
	displayed_hour = hour_at(elapsed)
	var day := daylight(displayed_hour)
	night_amount = 1.0 - day
	var dawn := smoothstep(4.8, 6.0, displayed_hour) * (1.0-smoothstep(6.3, 8.2, displayed_hour))
	var dusk := smoothstep(16.0, 18.0, displayed_hour) * (1.0-smoothstep(18.5, 20.5, displayed_hour))
	var warm := maxf(dawn, dusk)
	sky.sky_top_color = Color("111c39").lerp(Color("70b4cd"), day).lerp(Color("66668b"), warm*0.38)
	sky.sky_horizon_color = Color("334465").lerp(Color("cbe2d0"), day).lerp(Color("efa773"), warm*0.85)
	sky.ground_bottom_color = Color("1c2931").lerp(Color("78906b"), day)
	sky.ground_horizon_color = sky.sky_horizon_color
	sky.sun_angle_max = 8.0
	environment.ambient_light_color = Color("9cadcf").lerp(Color("dee7d4"), day)
	environment.ambient_light_energy = lerpf(0.23, 0.4, day)
	environment.fog_light_color = Color("283957").lerp(Color("c9dacc"), day).lerp(Color("c68e72"), warm*0.5)
	sun.light_color = Color("fff2d5").lerp(Color("ffb073"), warm*0.65)
	sun.light_energy = 0.65 * day
	sun.rotation_degrees = Vector3(-maxf(1, sin((displayed_hour-6.0)/12.0*PI)*58), displayed_hour*12-176, 0)
	moon.light_energy = 0.20 * night_amount
	lantern_material.emission_energy_multiplier = 2.5 * smoothstep(0.18, 0.75, night_amount)
	# Fixed pool: distant lanterns glow, only nearby lamps spend real light budget.
	var ordered := lamps.duplicate()
	ordered.sort_custom(func(a: Vector3, b: Vector3): return a.distance_squared_to(observer) < b.distance_squared_to(observer))
	for i in range(local_lights.size()):
		var light := local_lights[i]
		light.visible = i < ordered.size() and night_amount > 0.01
		if i >= ordered.size(): continue
		light.position = ordered[i] + Vector3(0, 3.65, 0)
		var distance := Vector2(ordered[i].x-observer.x, ordered[i].z-observer.z).length()
		light.light_energy = 2.4 * smoothstep(0.18, 0.75, night_amount) * (1.0-smoothstep(30, 46, distance))
