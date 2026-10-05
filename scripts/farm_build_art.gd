class_name FarmBuildArt
extends RefCounted

const KINDS := ["barn", "house", "fence", "fence_painted", "gate_rustic", "gate_painted", "well", "wash_tub", "raised_bed", "trellis", "orchard_young", "orchard_mature", "compost", "produce_crates"]
var scenes: Dictionary = {}
var shapes: Dictionary = {}
var gates: Array[Dictionary] = []

func handles(kind: String) -> bool:
	return kind in KINDS

func instantiate(item: Dictionary, parent: Node3D) -> Node3D:
	var kind: String = item.kind
	var upgraded: bool = int(item.get("level", 1)) >= 2
	var key := "farm_art_" + kind
	if kind == "house": key = "farm_house_upgrade" if upgraded else "farm_house_starter"
	elif kind == "barn": key = "farm_art_barn_upgrade" if upgraded else "farm_art_barn_starter"
	elif kind == "fence": key = "farm_art_fence_rustic"
	if not scenes.has(key): scenes[key] = load("res://assets/models/%s.glb" % key)
	var visual: Node3D = scenes[key].instantiate()
	parent.add_child(visual)
	visual.set_meta("art_key", key)
	if kind == "house": visual.position.z = -.4
	elif kind == "barn":
		visual.scale = Vector3.ONE * (.70 if upgraded else .87)
		visual.position.z = -.2
	if upgraded and kind in ["house", "barn"]: visual.name = "Level2Details"
	if kind.begins_with("gate_"):
		# The exported sliding latch was static; carry it with the left leaf.
		var hinge := visual.find_child("GateHingeLeft*", true, false) as Node3D
		hinge.name = "GateHingeLeft"
		var right := visual.find_child("GateHingeRight*", true, false) as Node3D
		right.name = "GateHingeRight"
		for child in visual.find_children("*", "MeshInstance3D", true, false):
			if "latch" in child.name.to_lower():
				var relative := _relative_transform(hinge, visual).affine_inverse() * _relative_transform(child, visual)
				child.owner = null
				child.reparent(hinge, false)
				child.transform = relative
	return visual

func _relative_transform(node: Node3D, ancestor: Node3D) -> Transform3D:
	var result := Transform3D.IDENTITY
	var current := node
	while current != ancestor:
		result = current.transform * result
		current = current.get_parent() as Node3D
	return result

func add_collision(item: Dictionary, visual: Node3D, index: int) -> void:
	var kind: String = item.kind
	var key: String = visual.get_meta("art_key")
	_add_body(visual, key, index, kind, true)
	if kind.begins_with("gate_"):
		var left := visual.find_child("GateHingeLeft", true, false) as Node3D
		var right := visual.find_child("GateHingeRight", true, false) as Node3D
		var left_body := _add_body(left, key + "_left", index, kind, false)
		var right_body := _add_body(right, key + "_right", index, kind, false)
		gates.append({"visual": visual, "left": left, "right": right, "left_rest": left.rotation.y, "right_rest": right.rotation.y, "bodies": [left_body, right_body], "amount": 0.0, "hold": 0.0})

func _add_body(root: Node3D, key: String, index: int, kind: String, skip_hinges: bool) -> StaticBody3D:
	if not shapes.has(key):
		var faces := PackedVector3Array()
		_collect_faces(root, Transform3D.IDENTITY, faces, kind, skip_hinges)
		var shape := ConcavePolygonShape3D.new()
		shape.set_faces(faces)
		shapes[key] = shape
	var body := StaticBody3D.new()
	body.name = "ArtCollision"
	body.set_meta("item_index", index)
	var collision := CollisionShape3D.new()
	collision.shape = shapes[key]
	body.add_child(collision)
	root.add_child(body)
	return body

func _collect_faces(node: Node3D, transform: Transform3D, faces: PackedVector3Array, kind: String, skip_hinges: bool) -> void:
	if node is MeshInstance3D:
		var mesh_name := str(node.name).to_lower()
		var foliage := kind.begins_with("orchard_") and ("canopy" in mesh_name or "crown" in mesh_name or "orange" in mesh_name)
		if not foliage:
			for point in node.mesh.get_faces(): faces.append(transform * point)
	for child in node.get_children():
		if child is Node3D and not child is PhysicsBody3D:
			if skip_hinges and str(child.name).begins_with("GateHinge"): continue
			_collect_faces(child, transform * child.transform, faces, kind, skip_hinges)

func update_gates(positions: Array[Vector3], delta: float) -> void:
	for gate in gates:
		if not is_instance_valid(gate.visual): continue
		var near := false
		for position in positions:
			var offset: Vector3 = position - gate.visual.global_position
			if Vector2(offset.x, offset.z).length() < 5.0 and absf(offset.y) < 4.0:
				near = true
				break
		gate.hold = 2.5 if near else maxf(0, float(gate.hold) - delta)
		gate.amount = move_toward(float(gate.amount), 1.0 if gate.hold > 0 else 0.0, delta * 2.5)
		gate.left.rotation.y = float(gate.left_rest) - float(gate.amount) * PI * .5
		gate.right.rotation.y = float(gate.right_rest) + float(gate.amount) * PI * .5
		# Never push a rider or vehicle with a moving leaf. Posts remain solid.
		for body in gate.bodies: body.collision_layer = 0 if gate.hold > 0 or gate.amount > .001 else 1

static func paint_slot(material_name: String, kind: String) -> String:
	if kind == "barn":
		if material_name in ["Weathered honey timber", "Fresh oak", "Barn ochre red", "Barn warm red boards"]: return "paint"
		if material_name in ["Terracotta", "Sunlit clay seams", "Weathered grey roof"]: return "roof_paint"
		if material_name == "Sage painted fittings": return "door_paint"
	if kind in ["fence", "fence_painted", "gate_rustic", "gate_painted"] and material_name in ["Honey aged timber", "Warm exposed end grain", "Chalk cream paint"]: return "paint"
	if kind == "house":
		if material_name in ["Honey weathered wood", "Warm plank variation", "Limewashed warm plaster"]: return "paint"
		if material_name in ["Terracotta roof", "Sunlit terracotta tile", "Old clay roof"]: return "roof_paint"
	return ""
