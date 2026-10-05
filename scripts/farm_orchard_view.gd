class_name FarmOrchardView
extends RefCounted
## Both approved Blender stages are kept loaded; only visibility changes at maturity.

static func create(art: FarmBuildArt, parent: Node3D, item: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.name = "OrchardVisual"
	parent.add_child(root)
	var young := art.instantiate({"kind": "orchard_young"}, root)
	young.name = "Young"
	var adult := art.instantiate({"kind": "orchard_mature"}, root)
	adult.name = "Adult"
	var fruits: Array[Node3D] = []
	for mesh in adult.find_children("*", "MeshInstance3D", true, false):
		if "orange" in str(mesh.name).to_lower(): fruits.append(mesh)
	root.set_meta("fruits", fruits)
	var badge := Label3D.new()
	badge.name = "Badge"
	badge.font_size = 27
	badge.pixel_size = .007
	badge.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	badge.outline_modulate = Color("294739")
	badge.outline_size = 9
	root.add_child(badge)
	update(root, item)
	return root

static func update(root: Node3D, item: Dictionary) -> void:
	var data: Dictionary = item.get("orchard", {})
	var mature := float(data.get("growth", 0)) >= FarmOrchard.GROW_SECONDS
	var ready := int(data.get("ready", 0)) > 0
	root.get_node("Young").visible = not mature
	root.get_node("Adult").visible = mature
	for fruit in root.get_meta("fruits", []): fruit.visible = ready
	var badge := root.get_node("Badge") as Label3D
	badge.position = Vector3(0, 4.65 if mature else 2.45, 0)
	badge.text = "LARANJEIRA\n" + FarmOrchard.status(item)
	badge.modulate = Color("ffce70") if ready else Color.WHITE

static func add_collision(root: Node3D, index: int) -> void:
	# A stable trunk leaves the full canopy passable, even when the tree grows.
	var body := StaticBody3D.new()
	body.name = "OrchardTrunk"
	body.set_meta("item_index", index)
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = .27
	cylinder.height = 1.8
	shape.shape = cylinder
	shape.position.y = .9
	body.add_child(shape)
	root.add_child(body)
