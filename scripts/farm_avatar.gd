class_name FarmAvatar
extends RefCounted

var root: Node3D
var parts: Dictionary = {}
var can: Node3D
var time := 0.0
var action_time := 0.0
var action_kind := ""

static func prepare_model(node: Node) -> void:
	# Small facial patches should remain readable beneath the hat and moustache.
	if node is MeshInstance3D:
		for surface in range(node.mesh.get_surface_count()):
			var mat:Material=node.mesh.surface_get_material(surface)
			if mat is StandardMaterial3D and (mat.resource_name.ends_with("_White") or mat.resource_name.ends_with("_Eye")):
				var facial:StandardMaterial3D=mat.duplicate()
				facial.disable_receive_shadows=true
				node.set_surface_override_material(surface,facial)
	for child in node.get_children(): prepare_model(child)

func setup(model: Node3D, world: FarmWorld) -> void:
	root=model
	for key in ["LegL","LegR","ArmL","ArmR","Body","Head"]:
		parts[key]=root.find_child(key,true,false)
	if parts.ArmR:
		can=world.model("watering_can",parts.ArmR)
		can.position=Vector3(0,-0.93,0.08)
		can.scale=Vector3.ONE*0.8
		can.visible=false

func play(kind: String) -> void:
	action_kind=kind
	action_time=0.85 if kind=="water" else 0.55

func animate(delta: float, moving: bool, running: bool) -> void:
	time+=delta
	action_time=maxf(0,action_time-delta)
	var stride:=sin(time*(14 if running else 10))*0.55 if moving else 0.0
	var blend:=1-exp(-delta*16)
	var active:=action_time>0
	for key in ["LegL","LegR","ArmL","ArmR"]:
		var part:Node3D=parts.get(key)
		if not part: continue
		var angle:float=stride*(1 if key in ["LegL","ArmR"] else -1)
		if active and key.begins_with("Arm"):
			angle=-0.95 if action_kind=="water" and key=="ArmR" else -0.55
		part.rotation.x=lerpf(part.rotation.x,angle,blend)
	if parts.Body:
		parts.Body.rotation.x=lerpf(parts.Body.rotation.x,0.22 if active and action_kind!="water" else 0.0,blend)
	if parts.Head:
		parts.Head.rotation.x=lerpf(parts.Head.rotation.x,0.13 if active else sin(time*1.4)*0.025,blend)
	root.position.y=abs(sin(time*(14 if running else 10)))*0.055 if moving else 0
	if can:
		can.visible=active and action_kind=="water"
		can.rotation.x=-0.2+sin(time*8)*0.05
